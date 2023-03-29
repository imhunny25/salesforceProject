public with sharing class ContentVersionDomain extends Domain {
    /**
     * Constructor based on Domain.cls constructor with similar signature
     * @param  records List of Records
     */
    public ContentVersionDomain(List<ContentVersion> records) {
        super(records);
    }

    /***********************************
        Business logic
    ************************************/

    /**
     * Evaluates new content added to system
     * @param  contentVersions       Trigger.new
     */
    public void evalContentCreation(List<ContentVersion> contentVersions) {
        ContentDocumentLinkSelector cdlSelector = new ContentDocumentLinkSelector();
        List<ContentVersion> contentVersionsForQueueItems = new List<ContentVersion>();
        Set<Id> contentDocListIds = new Set<Id>();
        Set<Id> contentVersionIds = new Set<Id>();
        Map<String ,List<Id>> referenceObjectIds = new Map<String ,List<Id>>();
        Map<String,Id> mapOfLibraryIdWithObjectRecordId = new Map<String,Id>();
        Set<Id> linkedEntityIds = new Set<Id>();

        for (ContentVersion cv : contentVersions) {
            if (cv.Evisort__c == null) {
                contentVersionsForQueueItems.add(cv);   // unsynced file records
                contentDocListIds.add(cv.ContentDocumentId); //all unsynced ids
                contentVersionIds.add(cv.Id);
            }
        }
  
        if (!contentVersionsForQueueItems.isEmpty()) {  // id unsynced
            Map<Id,Id> mapofContentDocumentIDwithWorkSpace = new   Map<Id,Id>();
            List<ContentWorkspaceDoc> contentWorkDocList = cdlSelector.getContentWorkSpaceDocList(contentDocListIds);
            for(ContentWorkspaceDoc cwsd : contentWorkDocList){
                mapofContentDocumentIDwithWorkSpace.put(cwsd.ContentDocumentId, cwsd.ContentWorkspaceId);
            }
            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            Boolean syncAll = settings.Sync_Criteria__c;    //check last sync status from custom settings

            Map<String, Evisort_Export_Filter__c> allowedObjects = new Map<String, Evisort_Export_Filter__c>();

            Map<String, Evisort_Export_Filter__c> allowedLibraryWithObject = new Map<String, Evisort_Export_Filter__c>();
            List<String> contentVersionReferences = new List<String>();

            for(Evisort_Export_Filter__c evisortDoc :  [SELECT Id, IsDeleted, Name, File_Filter_Body__c, Object_Filter_Body__c, Object__c, Is_Library__c, Is_Legacy__c,Library_Mapping__c FROM Evisort_Export_Filter__c WHERE Is_Legacy__c = false]){
                allowedObjects.put(evisortDoc.Object__c, evisortDoc);   // all objects/ library with their filter bodies
              
                if(String.isNotBlank(evisortDoc.Library_Mapping__c)){
                    libraryObjectMapping libraryObjectMappingData  = (libraryObjectMapping) JSON.deserialize(evisortDoc.Library_Mapping__c, libraryObjectMapping.class);
                    if(libraryObjectMappingData.isLibraryObjectCheck == true  && evisortDoc.Object__c == libraryObjectMappingData.sObjectName){
                        allowedLibraryWithObject.put(libraryObjectMappingData.libraryName,evisortDoc);
                        contentVersionReferences.add(libraryObjectMappingData.customField);
                    }
                }

            }
            for (ContentVersion cv : contentVersions) {
                for(String contentRef:  contentVersionReferences){
                    if(cv.getSobjectType().getDescribe().fields.getMap().keySet().contains(contentRef.toLowerCase())){
                        if (referenceObjectIds.containsKey(contentRef)) {
                            List<Id> referenceFieldIds = referenceObjectIds.get(contentRef);
                            if(cv.get(contentRef) != null){
                                referenceFieldIds.add((ID)cv.get(contentRef));
                            }
                            referenceObjectIds.put(contentRef, referenceFieldIds);    
                        } else {
                            if(cv.get(contentRef) != null){
                                referenceObjectIds.put(contentRef, new List<Id>{ (ID)cv.get(contentRef) });
                            }
                        }
                    }
                }
            }
            if(!allowedObjects.isEmpty()){  // if exists, objects/library with filters
                Map<String, List<ContentDocumentLink>> mapOfObjectTypeWithDocumentLink = new Map<String, List<ContentDocumentLink>>();
                Map<String,Set<Id>> mapOfObjectNameWithlinkedEntityId = new Map<String,Set<Id>>();
                List<ContentDocumentLink> links = cdlSelector.getLinksByDocumentIds(contentDocListIds);
                for (ContentDocumentLink conDocLink : links) {
                    String objectType;
                    if(mapofContentDocumentIDwithWorkSpace.containsKey(conDocLink.ContentDocumentId)){
                        objectType = mapofContentDocumentIDwithWorkSpace.get(conDocLink.ContentDocumentId);
                    }else{
                        objectType = conDocLink.linkedEntityId.getSobjectType().getDescribe().getName();
                    }

                    if (mapOfObjectTypeWithDocumentLink.containsKey(objectType)) {
                        List<ContentDocumentLink> cdls = mapOfObjectTypeWithDocumentLink.get(objectType);
                        cdls.add(conDocLink);
                        mapOfObjectTypeWithDocumentLink.put(objectType, cdls);    //map of object/ library API name with content document link
                    } else {
                        mapOfObjectTypeWithDocumentLink.put(objectType, new List<ContentDocumentLink>{ conDocLink });
                    }

                    if (mapOfObjectNameWithlinkedEntityId.containsKey(objectType)) {
                        Set<Id> lnkIds = mapOfObjectNameWithlinkedEntityId.get(objectType);
                        lnkIds.add(conDocLink.LinkedEntityId);
                        mapOfObjectNameWithlinkedEntityId.put(objectType, lnkIds); 
                    } else {
                        mapOfObjectNameWithlinkedEntityId.put(objectType, new Set<Id>{ conDocLink.LinkedEntityId });
                    }
                }

                for(String objKey : mapOfObjectTypeWithDocumentLink.keyset()){
                    if(allowedObjects.containskey(objKey)){
                        linkedEntityIds = mapOfObjectNameWithlinkedEntityId.get(objKey);
                        Evisort_Export_Filter__c evisortDoc = allowedObjects.get(objKey);
                        String fileWhereClause = getFileWhereClause(evisortDoc.File_Filter_Body__c);
                        List<Sobject> recordIds;
                        Set<Id> contentDocumentIds = new Set<Id>();
                        contentDocumentIds = getContentDocumentIdsUsingFileFilter(fileWhereClause, contentVersionIds,contentDocumentIds, null,null);
                        if(linkedEntityIds.size() > 0){
                            recordIds  = getObjectOrLibraryRecords(evisortDoc,referenceObjectIds, linkedEntityIds);
                        }
                        
                        if(recordIds.size()> 0 && contentDocumentIds.size() > 0){
                            Map<ID,String> mapofObjectIdWithName =  createMapUsingRecordIDs(recordIds);
                            Set<Id> entityIds = new Map<Id, SObject>(recordIds).keySet();

                            createQueueItemWithFilterItem(entityIds, contentDocumentIds, evisortDoc, mapofObjectIdWithName, mapOfLibraryIdWithObjectRecordId);
                        }
                    }
                     
                    if(allowedLibraryWithObject.containskey(objKey)){
                        linkedEntityIds = mapOfObjectNameWithlinkedEntityId.get(objKey);
                        Id objectId;
                        Evisort_Export_Filter__c evisortDoc = allowedLibraryWithObject.get(objKey);
                        libraryObjectMapping libraryObjectMappingData  = (libraryObjectMapping) JSON.deserialize(evisortDoc.Library_Mapping__c, libraryObjectMapping.class);
                        String fileWhereClause = getFileWhereClause(evisortDoc.File_Filter_Body__c);
                        List<Sobject> recordIds;
                        if(linkedEntityIds.size() > 0){
                            recordIds = getObjectOrLibraryRecords(evisortDoc,referenceObjectIds, linkedEntityIds);
                        }

                        if(recordIds.size() > 0){
                            Map<ID,String> mapofObjectIdWithName = createMapUsingRecordIDs(recordIds);
                            Set<Id> entityIds = new Map<Id, SObject>(recordIds).keySet();

                            Set<Id> contentDocumentIds = new Set<Id>();
                            if(entityIds.size() > 0){
                                for(Id obj:entityIds){
                                    objectId = obj;
                                }
                                mapOfLibraryIdWithObjectRecordId.put(libraryObjectMappingData.libraryName,objectId);
                                contentDocumentIds = getContentDocumentIdsUsingFileFilter(fileWhereClause, contentVersionIds, entityIds, contentVersionReferences ,libraryObjectMappingData.customField);
                            }
                            Set<Id> libraryIDs = new Set<Id>();
                            for(String libraryId: allowedLibraryWithObject.keySet()){
                                libraryIDs.add(libraryId);
                            }
                            if(libraryIDs.size() > 0 && contentDocumentIds.size() > 0){
                                createQueueItemWithFilterItem(libraryIDs, contentDocumentIds, evisortDoc,mapofObjectIdWithName,mapOfLibraryIdWithObjectRecordId);
                            }
                        }
                    }
                }
            }
        }
    }

    /******************   BUSINESS LOGIC end   **************/

    /*************************************
        Trigger functions
    **************************************/
    public override void onAfterInsert() {
        EvisortPreviousFilterRecords.evisortRecords();
        List<ContentVersion> contentVersions = (List<ContentVersion>) this.records;
        this.evalContentCreation(contentVersions);
    }
    
    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        List<ContentVersion> contentVersions = (List<ContentVersion>) this.records;        
        this.evalContentCreation(contentVersions);
    } 

    public Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'ContentDocumentId',
            'LinkedEntityId'
        };
    }

    public Set<Id> getContentDocumentIdsUsingFileFilter(String fileWhereClause, Set<Id> contentVersionIds, Set<Id> entityIds, List<String> fieldNames, String customField){
        Set<Id> contentDocumentIds = new Set<Id>();
        String referenceCustomField =  ''; //'Account__c';
        if(fieldNames != null && fieldNames.size()> 0){
            for(String custom: fieldNames){
                  if(customField == custom){
                    referenceCustomField += custom;
                    referenceCustomField = referenceCustomField.removeEnd('c');
                    referenceCustomField += 'r.id';
                  }
                }
            }
        String queryconVersion = 'SELECT Id, ContentDocumentId';
        if(referenceCustomField != ''){
            queryconVersion += ',' + referenceCustomField;
        }
        queryconVersion += ' FROM ContentVersion';
        if(fileWhereClause != null){
            queryconVersion += ' WHERE ' + fileWhereClause + ' AND Id IN: contentVersionIds';
        }
        else {
            queryconVersion += ' WHERE Id IN: contentVersionIds';
        }
        if(entityIds.size() > 0 && referenceCustomField != ''){                       
            queryconVersion += ' AND '+referenceCustomField+' IN: entityIds ';
        }
        List<ContentVersion> contentVersionList = Database.query(queryconVersion);
      
        for(ContentVersion conDocId : contentVersionList){
            contentDocumentIds.add(conDocId.ContentDocumentId);
        }
        return contentDocumentIds;
    }

    public List<Sobject> getObjectOrLibraryRecords(Evisort_Export_Filter__c evisortDoc, Map<String ,List<Id>> referenceObjectIds, Set<Id> linkedEntityIds){
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        Boolean isLibrary = evisortDoc.Is_Library__c;
        String customFieldName;
        Boolean selectedCustomField = false ;
        if(String.isNotBlank(evisortDoc.Library_Mapping__c)){
            libraryObjectMapping libraryObjectMappingData  = (libraryObjectMapping) JSON.deserialize(evisortDoc.Library_Mapping__c, libraryObjectMapping.class);
            if(libraryObjectMappingData.isLibraryObjectCheck == true){
                customFieldName = libraryObjectMappingData.customField;
                selectedCustomField = true;
            }
        }
        EvisortWhereClause eviWhereClause = new EvisortWhereClause();
        String objectWhereClause ;
        if(String.isNotBlank(evisortDoc.Object_Filter_Body__c)){
            objectWhereClause = eviWhereClause.whereClause(evisortDoc.Object_Filter_Body__c);
        }

        System.debug('objectWhereClause  :: <>'+objectWhereClause);

        String objectQuery = 'SELECT Id, Name';
        objectQuery += ' FROM '; 
        if(isLibrary == true ){
            Set<Id> libraryIds = new Set<Id>{evisortDoc.Object__c};
            List<ContentWorkspace> libraryRecord =  eeoSelector.getLibraryName(libraryIds);
            String libraryName =  libraryRecord[0].Name;
            objectQuery += 'ContentWorkspace WHERE Name = '+ '\''  + libraryName + '\'';
            if(String.isNotBlank(objectWhereClause)){
                objectQuery += 'AND '+ objectWhereClause;
            }
            objectQuery += ' AND Id IN: linkedEntityIds';
        }else{
            objectQuery += evisortDoc.Object__c;
            if(String.isNotBlank(objectWhereClause)){
                objectQuery += ' WHERE '+objectWhereClause + ' AND';
            }else{
                objectQuery += ' WHERE ';
            }
            if(referenceObjectIds.containsKey(customFieldName) == true){
                List<Id> listofReferenceIds = referenceObjectIds.get(customFieldName);
                if(listofReferenceIds.size()> 0){
                    objectQuery += ' Id IN: listofReferenceIds';
                }
            }else{
                objectQuery += ' Id IN: linkedEntityIds';
            }
        }
        System.debug('objectQuery.....'+objectQuery);
        List<Sobject> recordIds = Database.query(objectQuery);
        return recordIds;
    }

    public List<ContentDocumentLink> getFilterContentDocLinks(Set<Id> entityIds, Set<Id> contentDocumentIds, Evisort_Export_Filter__c evisortDoc){       
        List<String> queryFields = new List<String>(this.getDefaultFields());
        queryFields.add('ContentDocument.ContentSize');
        queryFields.add('ContentDocument.FileType');
        queryFields.add('ContentDocument.Title');
        queryFields.add('ContentDocument.LatestPublishedVersion.Evisort__c');

        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'entityIds' => entityIds,
            'contentDocumentIds' => contentDocumentIds
        };  

        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentDocumentLink';
        query += ' WHERE LinkedEntityId IN :entityIds';
        query += ' AND ContentDocumentId IN :contentDocumentIds';
        query += ' AND ContentDocument.IsArchived = false';
        query += ' AND ContentDocument.IsDeleted = false';

        List<ContentDocumentLink> contentDocumentLinks = Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        ); 
        return contentDocumentLinks;
    }

    public static Id createExportObj(ID evisortExportFilterID) {
        //  create evisort export object to link evisort export documents
        Evisort_Export_Object__c evsObj = new Evisort_Export_Object__c();
        evsObj.Evisort_Export_Filter__c = evisortExportFilterID;
        try {
            Data.create(evsObj, false, false, false);
        } catch (DMLException e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('ContentVersionDomain.createExportObj', e);
        }

        return evsObj.Id;
    }

    public static void createExportDocWithExportObj(List<ContentDocumentLink> contentDocumentLinks, Id exportObjId, Map<Id,String> mapofObjectIdWithName,Map<String,Id> mapOfLibraryIdWithObjectRecordId) {
        //create evisort export document
        List <Evisort_Export_Document__c> eedList = new List <Evisort_Export_Document__c>();
        for(ContentDocumentLink l : contentDocumentLinks ){

            Evisort_Export_Document__c eed = new Evisort_Export_Document__c();
            eed.Evisort_Export_Object__c = exportObjId;
            if(mapOfLibraryIdWithObjectRecordId.containskey(l.LinkedEntityId)){
                eed.Record_ID__c = mapOfLibraryIdWithObjectRecordId.get(l.LinkedEntityId);
            }else {
                eed.Record_ID__c = l.LinkedEntityId;
            }

            if(mapofObjectIdWithName.containsKey(l.LinkedEntityId)){
                eed.Record_Name__c = mapofObjectIdWithName.get(l.LinkedEntityId);
            }
            
            eed.ContentDocument__c = l.ContentDocumentId;
            eed.ContentVersion__c = l.ContentDocument.LatestPublishedVersionId;
            eed.Title__c = l.ContentDocument.Title;
            eed.File_Type__c = l.ContentDocument.FileType;
            eed.File_Size__c = l.ContentDocument.ContentSize;
            eedList.add(eed);
        }

        try {
            Data.create(eedList, false, false, false);
        } catch (DMLException e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('ContentVersionDomain.createExportDocWithExportObj', e);
            return;
        }
    }

    public static void createQueueItem(Id exportObjId) {
       try{
            Datetime processAfter = Datetime.now();
            QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
            newItem.RecordId__c = exportObjId;
            newItem.Object__c = 'ContentVersion';
            newItem.Process_After__c = processAfter;
            Integer delaySeconds = 60 / Constants.EXPORTS_PER_MINUTE;
            processAfter = processAfter.addSeconds(delaySeconds);

            if (!Test.isRunningTest() && newItem != null) {
                // Mark the last item as the last one so we can process the next batch
                newItem.Action_Context__c = 'LastDocument';
                // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
                Data.create(newItem, false, false, false);
            }
        } catch (DMLException e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('ContentVersionDomain.createQueueItem', e);
            return;
        }
    }
    public static String getFileWhereClause(String fileFilterBody){
        EvisortWhereClause eviWhereClause = new EvisortWhereClause();
        String fileWhereClause;
        if(String.isNotBlank(fileFilterBody)){
            fileWhereClause = eviWhereClause.whereClause(fileFilterBody);
        }
        return fileWhereClause;
    }

    public static Map<ID,String> createMapUsingRecordIDs(List<Sobject> recordIds){
        Map<ID,String> mapofObjectIdWithName = new Map<ID,String>();
        for(SObject obj : recordIds){
            mapofObjectIdWithName.put(obj.Id, (String) obj.get('Name'));
        }
        return mapofObjectIdWithName;
    }

    public void createQueueItemWithFilterItem(Set<Id> entityIds,Set<Id> contentDocumentIds, Evisort_Export_Filter__c evisortDoc,Map<ID,String> mapofObjectIdWithName,Map<String,Id> mapOfLibraryIdWithObjectRecordId){
        List<ContentDocumentLink> contentDocumentLinks;
        if(!entityIds.isEmpty() && !contentDocumentIds.isEmpty()){
            contentDocumentLinks = getFilterContentDocLinks(entityIds, contentDocumentIds, evisortDoc);
        }

        if(contentDocumentLinks != null && !contentDocumentLinks.isEmpty()){
            Id exportObjId = createExportObj(evisortDoc.Id);
            createExportDocWithExportObj(contentDocumentLinks, exportObjId, mapofObjectIdWithName, mapOfLibraryIdWithObjectRecordId);
           // createQueueItem(exportObjId);
        }
    }


    public class libraryObjectMapping {
        public String sObjectName;
        public Boolean isLibraryObjectCheck;
        public String libraryName;
        public String customField;
    }
}