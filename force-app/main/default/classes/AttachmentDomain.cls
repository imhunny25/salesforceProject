public with sharing class AttachmentDomain extends Domain{
    /**
     * Constructor based on Domain.cls constructor with similar signature
     * @param  records List of Records
     */
    public AttachmentDomain(List<Attachment> records) {
        super(records);
    }

    /***********************************
        Business logic
    ************************************/

    /**
     * Evaluates new attachment added to system
     * @param  attachments       Trigger.new
     */
    public void evalAttachmentCreation(List<Attachment> attachments) {
        
        List<Attachment> attachmentsForQueueItems = new List<Attachment>();
        Set<Id> evsAttachmentIds = new Set<Id>();
        Set<Id> attachmentIds = new Set<Id>();
        
        for (Attachment attachment : attachments) {
            attachmentIds.add(attachment.Id);
        }

        for (Attachment__c obj : [SELECT Attachment__c, Evisort__c 
            FROM Attachment__c WHERE Attachment__c IN: attachmentIds]) {
            evsAttachmentIds.add(obj.Attachment__c);
        }
        
        for (Attachment attachment : attachments) {         // get unsync attachments
            if (!evsAttachmentIds.contains(attachment.Id)) {
                attachmentsForQueueItems.add(attachment);
            }
        }

        if (!attachmentsForQueueItems.isEmpty()) {
            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            Boolean syncAll = settings.Sync_Criteria__c;    //check last sync status from custom settings

            Map<String, List<Evisort_Export_Filter__c>> mapObjectWithFilters = new Map<String, List<Evisort_Export_Filter__c>>();
            for(Evisort_Export_Filter__c eef :  [SELECT Id, IsDeleted, Name, File_Filter_Body__c, Object_Filter_Body__c, 
                Object__c, Is_Library__c, Is_Legacy__c, Library_Mapping__c 
                FROM Evisort_Export_Filter__c WHERE Is_Legacy__c = false AND Is_Library__c = false]){
                if (!mapObjectWithFilters.containsKey(eef.Object__c)) {
                    mapObjectWithFilters.put(eef.Object__c, new List<Evisort_Export_Filter__c>());
                }
                mapObjectWithFilters.get(eef.Object__c).add(eef);   // all objects with their filter bodies
            }
			
            if(!mapObjectWithFilters.isEmpty()){  // if exists, objects with filters
                for (Attachment attachment : attachmentsForQueueItems) {
                    String objKey = attachment.ParentId.getSobjectType().getDescribe().getName();
                    Boolean recordSynced = false;

                    if(mapObjectWithFilters.containskey(objKey)){
                        for (Evisort_Export_Filter__c filter : mapObjectWithFilters.get(objKey)) {
                            
                            if (recordSynced == false) {
                                Boolean fitFileFilter = true;
                        
                                if(String.isNotBlank(filter.File_Filter_Body__c)){
                                    fitFileFilter = checkFileFilter(filter.File_Filter_Body__c, attachment);
                                }
                                if (fitFileFilter == true) {
                                    List<SObject> records = getFilteredRecords(filter, attachment.ParentId); 
                                    if (records.size()> 0) {
                                        Set<Id> entityIds = new Map<Id, SObject>(records).keySet();
                                        Id exportObjId = createExportObj(filter.Id, objKey);
                                        createExportDocWithExportObj(exportObjId, objKey, attachment);
                                        createQueueItem(exportObjId);
                                        recordSynced = true;
                                    }
                                }
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
        List<Attachment> attachments = (List<Attachment>) this.records;
        try{
            this.evalAttachmentCreation(attachments);
        } catch (DMLException e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('AttachmentDomain.onAfterInsert', e);
        } catch(Exception e){
            Logger logInstance = Logger.getInstance();
            logInstance.log('AttachmentDomain.onAfterInsert', e);
        }
    }
    
    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        List<Attachment> attachments = (List<Attachment>) this.records;  
        try{      
            this.evalAttachmentCreation(attachments);
        } catch (DMLException e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('AttachmentDomain.onAfterUpdate', e);
        }  catch(Exception e){
            Logger logInstance = Logger.getInstance();
            logInstance.log('AttachmentDomain.onAfterInsert', e);
        }
    } 

    public List<Sobject> getFilteredRecords(Evisort_Export_Filter__c filter, Id parentId){
        EvisortWhereClause eviWhereClause = new EvisortWhereClause();
        String objectWhereClause ;

        if(String.isNotBlank(filter.Object_Filter_Body__c)){
            objectWhereClause = eviWhereClause.whereClause(filter.Object_Filter_Body__c);
        }

        String objectQuery = 'SELECT Id FROM ' + filter.Object__c + ' WHERE Id = \'' + parentId + '\'';
        
        if(String.isNotBlank(objectWhereClause)){
            objectQuery += ' AND ' + objectWhereClause;
        }
        List<Sobject> recordIds = Database.query(objectQuery);
        return recordIds;
    }

    public static Id createExportObj(ID evisortExportFilterID, String objectType) {
        //  create evisort export object to link evisort export documents
        Evisort_Export_Object__c evsObj = new Evisort_Export_Object__c();
        evsObj.Evisort_Export_Filter__c = evisortExportFilterID;
        //evsObj.Object__c = objectType;  Removed because the Object__c Fields we only used on Legacy.
        Data.create(evsObj, false, false, false);

        return evsObj.Id;
    }

    public static void createExportDocWithExportObj(Id exportObjId, String objectName, Attachment attachment) {
        String fileType = '';
        if(attachment.ContentType != null){
            if (Constants.FORM_DATA_TYPES.containsKey(attachment.ContentType)) {
                fileType = Constants.FORM_DATA_TYPES.get(attachment.ContentType);
            }
            else {
                fileType = attachment.ContentType.substringAfter('/');
            }
        }

        Evisort_Export_Document__c eed = new Evisort_Export_Document__c(
            Evisort_Export_Object__c = exportObjId,
            Record_ID__c = String.valueOf(attachment.parentId),
            Record_Name__c = objectName,
            Title__c = attachment.Name,
            File_Type__c = fileType,
            File_Size__c = attachment.BodyLength,
            ContentDocument__c = attachment.Id
        );

        Data.create(eed, false, false, false);
    }

    public static void createQueueItem(Id exportObjId) {
        Datetime processAfter = Datetime.now();
        QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
        newItem.RecordId__c = exportObjId;
        newItem.Object__c = 'Attachment';
        newItem.Process_After__c = processAfter;
        Integer delaySeconds = 60 / Constants.EXPORTS_PER_MINUTE;
        processAfter = processAfter.addSeconds(delaySeconds);

        if (!Test.isRunningTest() && newItem != null) {
            newItem.Action_Context__c = 'LastDocument'; // Mark the last item as the last one so we can process the next batch
            Data.create(newItem, false, false, false);  // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
        }
    }

    public static Boolean checkFileFilter(String fileFilterBody, Attachment attachment) {
        Boolean eligible = true;
        EvisortWhereClause eviWhereClause = new EvisortWhereClause(); 
        String attachmentFileFilter = eviWhereClause.replaceFieldNames(fileFilterBody);
        
        if (String.isNotBlank(attachmentFileFilter)) {
            String fileWhereClause = eviWhereClause.whereClause(attachmentFileFilter);            
            String query = 'SELECT Id FROM Attachment WHERE Id =: attachmentId AND ' + fileWhereClause + 'LIMIT 1';        
            
            Map<String, Object> queryArgs = new Map<String, Object>{ 
                'attachmentId' => attachment.Id
            };
                        
            List<Attachment> result = Data.read(query, queryArgs, true, true, true);
            if (result.isEmpty()) {
                eligible = false;
            }
        }
        return eligible;
    }
    
    /**
     * Sets up a QueueScience worker to send a DELETE call to the Evisort API if an Evisort tracked document is deleted
     * This is done BEFORE DELETE because we need access to the associated ContentVersions to get the associated Evisort record
     * @param  documents List of ContentDocuments (Trigger.old)
     */
    public void deleteContent(List<Attachment> attachments) {
        Set<Id> attachmentIds = new Set<Id>();
        
        for (Attachment attach : attachments) {
            attachmentIds.add(attach.Id);
        }

        if (attachmentIds.isEmpty()) {
            return;
        }

        List<Attachment__c> attachmentList = [SELECT Id, Attachment__c, Evisort__c FROM Attachment__c 
            WHERE Attachment__c IN: attachmentIds AND Evisort__c != Null];
        List<QueueItem__c> queueItemsToInsert = new List<QueueItem__c>();

        for (Attachment__c attach : attachmentList) {
            QueueItem__c item = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
            item.RecordId__c = attach.Evisort__c;
            item.Object__c = 'Evisort__c';
            item.Action_Context__c = 'DeleteRecord';
            queueItemsToInsert.add(item);
        }

        // Call Evisort upload API to transmit deletion request
        // Ignoring CRUD/FLS because QueueItems can't be edited by users
        if (!queueItemsToInsert.isEmpty() && !Test.isRunningTest()) {
            Data.create(queueItemsToInsert, false, false, false);
        }
        
        //delete related records
        if (!attachmentList.isEmpty()) {
            Data.remove(attachmentList, true, true, true);
        }
    }

    /******************   BUSINESS LOGIC end   **************/

    /*************************************
        Trigger functions
    **************************************/
    public override void onBeforeDelete() {
       // If we delete file from Salesforce then it will not get deleted From Evisort
       //List<Attachment> attachments = (List<Attachment>) this.records;
       //this.deleteContent(attachments); 
    }

    public class libraryObjectMapping {
        public String sObjectName;
        public Boolean isLibraryObjectCheck;
        public String libraryName;
        public String customField;
    }
}