public with sharing class EvisortMetadataSyncBatchUtils {
    private static Map<String, String> mapRecIdPrefixWithObjectName = new Map<String,String>();

    public static String getObjectName(Id recordId) {
        String objectName;

        try {
            String recordIdPrefix = String.valueOf(recordId).substring(0,3);
            if (mapRecIdPrefixWithObjectName.containsKey(recordIdPrefix)) {
                objectName = mapRecIdPrefixWithObjectName.get(recordIdPrefix);
            } else {
                objectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                mapRecIdPrefixWithObjectName.put(recordIdPrefix, objectName);
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getObjectFieldValue: ', e);
        }
        return objectName;
    }

    public static Map<String, List<Document_Field_Sync_Mapping__c>> getMapObjectNameWithFieldMapping(Set<String> setObjectNames) {
        Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm = new Map<String, List<Document_Field_Sync_Mapping__c>>();

        try {
            for (Document_Field_Sync_Mapping__c dfsm : [SELECT Id, Object__c, Salesforce_Field_Name__c, Evisort_Field_Definition__r.Id, 
                Evisort_Field_Definition__r.Data_Type__c, Evisort_Field_Definition__r.Field_Type__c, Evisort_Field_Definition__r.Label__c
                FROM Document_Field_Sync_Mapping__c WHERE Object__c In: setObjectNames]) {
                
                if (!mapObjectWithDfsm.containsKey(dfsm.Object__c)) {
                    mapObjectWithDfsm.put(dfsm.Object__c, new List<Document_Field_Sync_Mapping__c>());
                }
                mapObjectWithDfsm.get(dfsm.Object__c).add(dfsm);
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.mapObjectNameWithFieldMapping: ', e);
        } 

        return mapObjectWithDfsm;
    }

    public static Set<String> getFields(List<Document_Field_Sync_Mapping__c> lstDfsm) {
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
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getFields: ', e);
        }

        return setObjFields;
    }
    
    public static List<sObject> getObjectFieldValue(Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm, Set<String> setObjFields, String objectName, Set<Id> setRecordIds, Datetime lastBatchSyncDate) {
        List<SObject> queryResult = new List<SObject>();
        String lastBatchSyncDateFormat;
        if(lastBatchSyncDate != null){
            lastBatchSyncDateFormat = lastBatchSyncDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }
        try {
            List<SObject> results = new List<SObject>();
            String query = getQuery(setObjFields, objectName, setRecordIds, lastBatchSyncDateFormat, mapObjectWithDfsm);

            Map<String, Object> queryArgs = new Map<String, Object>{
                'setRecordIds' => setRecordIds,
                'lastBatchSyncDate' => lastBatchSyncDateFormat
            };

            results = Data.read(query, queryArgs, true, true, true);
        
            if (results.size() > 0 && !results.isEmpty() && results != null) {
                queryResult = results;
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getObjectFieldValue: ', e);
        }

        return queryResult;
    }

    public static String getQuery(Set<String> setObjFields, String objectName, Set<Id> setRecordIds, String lastBatchSyncDateFormat, Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm) {
        String query = '';
        try {
            Set<String> fieldsToRetrieve = new Set<String>();
            
            for (Document_Field_Sync_Mapping__c dfsm : mapObjectWithDfsm.get(objectName)) {
                if (dfsm.Salesforce_Field_Name__c != null && dfsm.Salesforce_Field_Name__c != '' 
                    && !fieldsToRetrieve.contains(dfsm.Salesforce_Field_Name__c)) {
                    fieldsToRetrieve.add(dfsm.Salesforce_Field_Name__c);
                }
            }
            
  			query += 'SELECT ';
            if(!fieldsToRetrieve.contains('Id')){
                query += 'Id , ';
            }
            if (fieldsToRetrieve.size() > 0) {
              query += String.join(new List<String>(fieldsToRetrieve), ', ');
            }
             query += ' FROM ' + objectName;
                if (lastBatchSyncDateFormat != null) {
                    query += ' WHERE (LastModifiedDate > ' + lastBatchSyncDateFormat;
                    if(setObjFields.size() > 0){
                        for (String queryField : setObjFields) {
                            query += ' OR ' + queryField + '.LastModifiedDate > ' + lastBatchSyncDateFormat;
                        }
                    }
                    query += ') AND Id IN: setRecordIds';
                }
                else {
                    query += ' WHERE Id IN: setRecordIds';
                }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getQuery: ', e);
        }

        return query;
    }
    
    public static List<QueueItem__c> getQueueItem(String status){
        String queueQuery = 'SELECT Id, Name, Object__c, Status__c, RecordId__c FROM QueueItem__c WHERE Object__c = \'MetadataExport\' AND Status__c = \''+status+'\'';
        List<QueueItem__c> lstQueueItems = Data.read(queueQuery, null, false, false, false);
        return lstQueueItems;
    }

    public static DocumentMsg.SendValuesRequest getRequest(String objectName, sObject sObj, Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm) {
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
                    req.fields.add(newField);
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getRequest: ', e);
        }

        return req;
    }
    
    public static String getFieldValue(String sfFieldName, sObject sObj) {
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
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getFieldValue: ', e);
        }

        return fieldValue;
    }
 
    public static String getFieldValueAsString(String field, SObject sObj) {
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
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getAddressAsString: ', e);
        }

        return fieldValue;
    }

    public static String getAddressAsString(Address address) {
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
            Logger.getInstance().log('EvisortMetadataSyncBatchUtils.getAddressAsString: ', e);
        }

        return String.join(lstAddress, ', ');
    }
}