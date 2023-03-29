/** 
* We couldn't change it so we stopped using it. 
* In start it returns List<Evisort__c> but we need to change this into Database.QueryLocator. But It showed an Error when creating a new package because we couldn't remove it.
* Error:  Global/WebService identifiers cannot be removed from managed application: Method List<evisort__Evisort__c> start
*/
global with sharing class EvisortMetadataSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts,Schedulable, Database.Stateful {

    private Map<Id, List<Evisort__c>> mapRecIdWithEvisort = new Map<Id, List<Evisort__c>>();
    private Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm = new Map<String, List<Document_Field_Sync_Mapping__c>>();
    private Map<String, List<Evisort__c>> mapObjNameWithEvisortRecs = new Map<String, List<Evisort__c>>();
    private List<SObject> lstObjsWithFieldValue;
    private List<Id> lstEvisortId = new List<Id>();
    private Datetime lastBatchSyncDate = null;

    global EvisortMetadataSyncBatch(List<Id> evsId) {
        lstEvisortId = evsId;
    }

    global EvisortMetadataSyncBatch() {
        lstEvisortId = new List<Id>();
        Evisort_Workspace_Settings__c settings = Evisort_Workspace_Settings__c.getInstance();
        if(settings.LastSyncBatchDate__c != null){
            this.lastBatchSyncDate = settings.LastSyncBatchDate__c;
        }
    }

    global List<Evisort__c> start(Database.BatchableContext bc) {
        List<Evisort__c> lstEvisortForAPI = new List<Evisort__c>();

        try {
            List<Evisort__c> lstEvisort = new List<Evisort__c>();

            String query = 'SELECT Id, Record_ID__c, External_ID__c FROM Evisort__c WHERE External_ID__c != null AND Record_ID__c != null';
            
            if (this.lstEvisortId.size() > 0) {
                Map<String, Object> queryArgs = new Map<String, Object>{ 
                    'evisortId' => this.lstEvisortId
                };
                query += ' AND Id IN :evisortId';
                lstEvisort = Data.read(query, queryArgs, true, true, true);
            }
            else {
                lstEvisort = Data.read(query, null, true, true, true);
            }

            lstObjsWithFieldValue = getRecords(lstEvisort);

            if (!lstObjsWithFieldValue.isEmpty()) {
                for (SObject sObj : lstObjsWithFieldValue) {
                    for (Evisort__c evs : mapRecIdWithEvisort.get(sObj.Id)) {
                        lstEvisortForAPI.add(evs);
                    }
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.start: ', e);
        }

        return lstEvisortForAPI;
    }

    global void execute(Database.BatchableContext bc, List<Evisort__c> lstEvisort) {

        try {
            if (lstObjsWithFieldValue.size() > 0) {
                sendMappedValuesToEvisort();
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.execute: ', e);
        }
    } 

    global List<SObject> getRecords(List<Evisort__c> lstEvisort) {  
        List<SObject> lstMappedObjectResult = new List<SObject>();    
        
        try {
            for (Evisort__c evs : lstEvisort) {
                String objectName = Id.valueOf(evs.Record_ID__c).getSObjectType().getDescribe().getName();
                
                if (!mapObjNameWithEvisortRecs.containsKey(objectName) && String.isNotBlank(objectName)) {
                    mapObjNameWithEvisortRecs.put(objectName, new List<Evisort__c>());
                }
                mapObjNameWithEvisortRecs.get(objectName).add(evs);
                
                if (!mapRecIdWithEvisort.containsKey(evs.Record_ID__c) && String.isNotBlank(objectName)) {
                    mapRecIdWithEvisort.put(evs.Record_ID__c, new List<Evisort__c>());
                }
                mapRecIdWithEvisort.get(evs.Record_ID__c).add(evs);
            }

            if (!mapObjNameWithEvisortRecs.isEmpty()) {
                
                mapObjectWithDfsm = mapObjectNameWithFieldMapping(mapObjNameWithEvisortRecs);
                
                if (!mapObjectWithDfsm.isEmpty()) {
                    for (String obj : mapObjNameWithEvisortRecs.keySet()) {

                        if (mapObjectWithDfsm.containsKey(obj)) {
                            Set<String> setObjFields = getFields(mapObjectWithDfsm.get(obj));
                            List<SObject> qr = getObjectFieldValue(mapObjectWithDfsm, setObjFields, obj, mapRecIdWithEvisort.keySet());

                            if (qr != null && !qr.isEmpty()) {
                                for (SObject sObj : qr) {
                                    lstMappedObjectResult.add(sObj);
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.start: ', e);
        }
        
        return lstMappedObjectResult;
    }
    
    global Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectNameWithFieldMapping(Map<String,List<Evisort__c>> mapObjNameWithEvisortRecs) {
        Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm = new Map<String, List<Document_Field_Sync_Mapping__c>>();

        try {
            for (Document_Field_Sync_Mapping__c dfsm : [SELECT Id, Object__c, Salesforce_Field_Name__c, Evisort_Field_Definition__r.Id, 
                Evisort_Field_Definition__r.Data_Type__c, Evisort_Field_Definition__r.Field_Type__c, Evisort_Field_Definition__r.Label__c
                FROM Document_Field_Sync_Mapping__c WHERE Object__c In: mapObjNameWithEvisortRecs.keySet()]) {
                    
                    if (!mapObjectWithDfsm.containsKey(dfsm.Object__c)) {
                        mapObjectWithDfsm.put(dfsm.Object__c, new List<Document_Field_Sync_Mapping__c>());
                    }
                    mapObjectWithDfsm.get(dfsm.Object__c).add(dfsm);
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.mapObjectNameWithFieldMapping: ', e);
        } 

        return mapObjectWithDfsm;
    }

    private Set<String> getFields(List<Document_Field_Sync_Mapping__c> lstDfsm) {
        Set<String> setObjFields = new Set<String>();
        try {
            for (Document_Field_Sync_Mapping__c dfsm : lstDfsm) {
                String fieldName = '';
                Integer setIndex = 1;
                
                if (dfsm.Salesforce_Field_Name__c != null) {
                    if (dfsm.Salesforce_Field_Name__c.contains('.')) {
                        List<String> lstFieldNames = dfsm.Salesforce_Field_Name__c.split('\\.');

                        for (String field : lstFieldNames) {
                            if (setIndex < lstFieldNames.size()) {
                                setIndex++;
                                fieldName += (fieldName != '' ? '.' + field : field);
                            }
                        }
                    }
                }

                if (fieldName != '') {
                    setObjFields.add(fieldName);
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getFields: ', e);
        }

        return setObjFields;
    }

    global List<sObject> getObjectFieldValue(Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm, Set<String> setObjFields, String objectName, Set<Id> setRecordId) {
        List<SObject> queryResult = new List<SObject>();
        String lastBatchSyncDateFormat;
        if(this.lastBatchSyncDate != null){
            lastBatchSyncDateFormat = this.lastBatchSyncDate.formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
        try {
            List<SObject> results = new List<SObject>();
            String query = getQuery(setObjFields, objectName, setRecordId, lastBatchSyncDateFormat);

            Map<String, Object> queryArgs = new Map<String, Object>{
                'setRecordId' => setRecordId,
                'lastBatchSyncDate' => lastBatchSyncDateFormat
            };

            results = Data.read(query, queryArgs, true, true, true);
        
            if (results.size() > 0 && !results.isEmpty() && results != null) {
                queryResult = results;
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getObjectFieldValue: ', e);
        }

        return queryResult;
    }

    global String getQuery(Set<String> setObjFields, String objectName, Set<Id> setRecordId, String lastBatchSyncDateFormat) {
        String query = '';
        try {
            List<String> fieldsToRetrieve = new List<String>();
            
            for (Document_Field_Sync_Mapping__c dfsm : mapObjectWithDfsm.get(objectName)) {
                if (dfsm.Salesforce_Field_Name__c != null && dfsm.Salesforce_Field_Name__c != '' 
                    && !fieldsToRetrieve.contains(dfsm.Salesforce_Field_Name__c)) {
                    fieldsToRetrieve.add(dfsm.Salesforce_Field_Name__c);
                }
            }
            
  			query += 'SELECT Id';
            if (fieldsToRetrieve.size() > 0) {
              query += ',' + String.join(fieldsToRetrieve, ', ');
            }
             query += ' FROM ' + objectName;
                if (lastBatchSyncDateFormat != null) {
                    query += ' WHERE (LastModifiedDate > ' + lastBatchSyncDateFormat;
                    if(setObjFields.size() > 0){
                        for (String queryField : setObjFields) {
                            query += ' OR ' + queryField + '.LastModifiedDate > ' + lastBatchSyncDateFormat;
                        }
                    }
                    query += ') AND Id IN: setRecordId';
                }
                else {
                    query += ' WHERE Id IN: setRecordId';
                }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getQuery: ', e);
        }

        return query;
    }

    global void sendMappedValuesToEvisort() {

        try {
            List <Evisort__c> evisortToUpdate = new List <Evisort__c>();

            if (lstObjsWithFieldValue.size() > 0) {
                
                if (!lstObjsWithFieldValue.isEmpty()) {
                    for(sObject sObj : lstObjsWithFieldValue){
                        String objectName = sObj.Id.getSObjectType().getDescribe().getName();
                        Map<String, DocumentMsg.SendValuesRequest> mapExternalIdWithRequestBody = new Map<String, DocumentMsg.SendValuesRequest>();
                        Map<String, Evisort__c> mapExternalIdWithEvisort = new Map<String, Evisort__c>();
                        List<Evisort__c> lstEvisort = mapRecIdWithEvisort.get(sObj.Id);       

                        for (Evisort__c evisortRecord : lstEvisort) {
                            DocumentMsg.SendValuesRequest req = getRequest(objectName, sObj);

                            if (req.fields.size() > 0) {
                                if (!mapExternalIdWithRequestBody.containsKey(evisortRecord.External_Id__c)) {
                                    mapExternalIdWithRequestBody.put(evisortRecord.External_ID__c, req);
                                    mapExternalIdWithEvisort.put(evisortRecord.External_ID__c, evisortRecord);
                                }
                            }
                        }        
                        evisortToUpdate = makeAPIcall(mapExternalIdWithRequestBody, mapExternalIdWithEvisort);
                    }
                }
            if (evisortToUpdate.size() > 0) {
                update evisortToUpdate;
            }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.sendMappedValuesToEvisort: ', e);
        }
    }

    public DocumentMsg.SendValuesRequest getRequest(String objectName, sObject sObj) {
        DocumentMsg.SendValuesRequest req = new DocumentMsg.SendValuesRequest();
        try {
                                    
            for (Document_Field_Sync_Mapping__c dfsm : mapObjectWithDfsm.get(objectName)) {
                Evisort_Field_Definition__c efd = (Evisort_Field_Definition__c) dfsm.getSObject('Evisort_Field_Definition__r');
                String sfFieldName = (dfsm.Salesforce_Field_Name__c != null && dfsm.Salesforce_Field_Name__c != '') ? dfsm.Salesforce_Field_Name__c : '';

                String fieldValue = getFieldValue(sfFieldName, sObj);
                DocumentMsg.Field newField = new DocumentMsg.Field(efd.Label__c);

                if (String.isNotBlank(fieldValue)) {
                    if (efd.Data_Type__c == 'Multi Picklist' && fieldValue.contains(';')) {
                        for (String str : fieldValue.split(';')) {
                            newField.values.add(new DocumentMsg.Value(str));
                        }
                    }
                    else {
                        newField.values.add(new DocumentMsg.Value(fieldValue));
                    }   
                }
                req.fields.add(newField);
               
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getRequest: ', e);
        }

        return req;
    }
  
    public List<Evisort__c> makeAPIcall(Map<String, DocumentMsg.SendValuesRequest> mapExternalIdWithRequestBody, Map<String, Evisort__c> mapExternalIdWithEvisort) {
        List<Evisort__c> evisortToUpdate = new List<Evisort__c>();
        
        try {
            if (!mapExternalIdWithRequestBody.isEmpty()) {
                for (String externalId : mapExternalIdWithRequestBody.keySet()) {
                    
                    API a = new API();
                    HttpResponse response = a.doAPICall(
                        Constants.DOCUMENT_URL +
                        '/' +
                        externalId,
                        'PATCH',
                        JSON.serialize(mapExternalIdWithRequestBody.get(externalId))
                    );

                    mapExternalIdWithEvisort.get(externalId).Sync_Error__c = '';

                    if (response.getStatusCode() != 204) {
                        DocumentMsg.UploadResponse res = (DocumentMsg.UploadResponse) JSON.deserialize(
                            response.getBody(),
                            DocumentMsg.UploadResponse.class
                        );
                        mapExternalIdWithEvisort.get(externalId).Sync_Error__c = 'ERROR : ' + res.error;
                        evisortToUpdate.add(mapExternalIdWithEvisort.get(externalId));
                        Logger errorlogger = Logger.getInstance();
                        errorlogger.log(
                            'EvisortMetadataSyncBatch.sendMappedValuesToEvisort',
                            Logger.Level.ERROR,
                            'Evisort__c',
                            new List<Id>{ mapExternalIdWithEvisort.get(externalId).Record_ID__c },
                            res.error,
                            null,
                            JSON.serialize(mapExternalIdWithRequestBody.get(externalId))
                        );
                    }
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getRequest: ', e);
        }

        return evisortToUpdate;
    }

    global String getFieldValue(String sfFieldName, sObject sObj) {
        String fieldValue = '';
        
        try {
            if (sfFieldName != '') {
                Integer setIndex = 1;
                List<String> lstFieldNames = sfFieldName.split('\\.');

                for (String field : lstFieldNames) {
                    if (setIndex < lstFieldNames.size()) {
                        sObj = sObj.getSObject(field);
                        setIndex++;
                    }
                    else if (sObj == null) {
                        fieldValue = '';
                    }
                    else {
                        fieldValue = getFieldValueAsString(field, sObj);
                    }
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getFieldValue: ', e);
        }

        return fieldValue;
    }
 
    global String getFieldValueAsString(String field, SObject sObj) {
        String fieldValue;

        try {
            Schema.DescribeSObjectResult objectDescribe = sObj.getSObjectType().getDescribe();
            Schema.SObjectField fld = objectDescribe.fields.getMap().get(field);
                            
            if (fld != null) {
                Schema.DescribeFieldResult fieldDescribe = fld.getDescribe();

                if(fieldDescribe.getType() == Schema.DisplayType.Phone) {
                    fieldValue = String.valueOf(sObj.get(field));
                }
                else if(fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
                    fieldValue = ((Datetime)sObj.get(field)).year() + '-' + ((Datetime) sObj.get(field)).month() + '-' + ((Datetime) sObj.get(field)).day();
                }
                else if(fieldDescribe.getType() == Schema.DisplayType.Address) {
                    fieldValue = getAddressAsString((Address) sObj.get(field));
                }
                else {
                    fieldValue = String.valueOf(sObj.get(field));
                }
            }
            else {
                fieldValue = String.valueOf(sObj.get(field));
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getAddressAsString: ', e);
        }

        return fieldValue;
    }

    global String getAddressAsString(Address address) {
        List <String> lstAddress = new List <String> ();

        try {
            if (String.isNotBlank(address.getStreet())) {
                lstAddress.add(address.getStreet());
            }
            if (String.isNotBlank(address.getCity())) {
                lstAddress.add(address.getCity());
            }
            if (String.isNotBlank(address.getState())) {
                lstAddress.add(address.getState());
            }
            if (String.isNotBlank(address.getStateCode())) {
                lstAddress.add(address.getStateCode());
            }
            if (String.isNotBlank(address.getPostalCode())) {
                lstAddress.add(address.getPostalCode());
            }
            if (String.isNotBlank(address.getGeocodeAccuracy())) {
                lstAddress.add(address.getGeocodeAccuracy());
            }
            if (String.isNotBlank(address.getCountry())) {
                lstAddress.add(address.getCountry());
            }
            if (String.isNotBlank(address.getCountryCode())) {
                lstAddress.add(address.getCountryCode());
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.getAddressAsString: ', e);
        }

        return String.join(lstAddress, ', ');
    }

    global void finish(Database.BatchableContext bc) {
        try {
           if(this.lstEvisortId.size() == 0 ){
                Evisort_Workspace_Settings__c settings = Evisort_Workspace_Settings__c.getOrgDefaults();
                settings.LastSyncBatchDate__c = System.now();
                upsert settings;
           }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatch.finish: ', e);
        }
    }
    
     global void execute(SchedulableContext scon) {
        /** 
         * Create a new version because we couldn't change it.
         * Error: Global/WebService identifiers cannot be removed from managed application 
        */
       //Database.executeBatch(new EvisortMetadataSyncBatch(),200); 
        Database.executeBatch(new EvisortMetadataSyncBatchV2(),2000);
    }
}