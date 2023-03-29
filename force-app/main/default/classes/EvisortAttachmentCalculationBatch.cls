global with sharing class EvisortAttachmentCalculationBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String objectName;
    private Id exportId;
    private String objectFilterBody;
    private String fileFilterBody;
    private String syncfilterId;
    private Map<Id,String> mapofObjectIDWithName;
    private Evisort_Export_Filter__c exportFilter;
    private Id contentExportId;

    /**
     * Constructor
     * @param  objectFilter            Object Filter data
     * @param  fileFilter              File Filter data
     * @param  exportJob               Evisort Export Filter
    */
    global EvisortAttachmentCalculationBatch(Evisort_Export_Filter__c exportJob, String objectFilter, String fileFilter, Id contentVersionExportId) {
        this.objectName = exportJob.Object__c;
        this.exportId = null;
        this.contentExportId = contentVersionExportId;
        this.objectFilterBody = objectFilter;
        this.fileFilterBody = fileFilter;
        this.syncfilterId = exportJob.Id;
        this.exportFilter = exportJob;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String attachmentQuery = getAttachmentQuery(this.objectFilterBody, this.fileFilterBody, this.objectName);
        return Database.getQueryLocator(attachmentQuery);
    }

    global void execute(Database.BatchableContext bc, List<sobject> attachments) {
        String objWhereClauseValue = ExportCalculationBatchUtils.getObjectWhereClause(this.objectFilterBody);
        mapofObjectIdWithName = new Map<Id,String>();
        Set<Id> recordIds = new Map<Id, sObject>(attachments).keySet();

        List<Attachment__c> customAttachmentList = getCustomAttachmentRecords(recordIds);

        Set<id> syncAttachment = new Set<Id>();
        for(Attachment__c obj : customAttachmentList){
            syncAttachment.add(obj.Attachment__c);
        }
        Map<String, Object> queryArg = new Map<String, Object>{ 
            'recordIds' => recordIds,
            'syncAttachment' => syncAttachment
        };

        String query = 'SELECT ' + String.join(getDefaultFields(), ',') + ' FROM Attachment';
        query += ' WHERE ID IN: recordIds AND Id NOT IN: syncAttachment';

        List<Attachment> attachmentList =  Data.read(
            query,
            queryArg
        );

        Set<Id> objRecordIds = new Set<Id>();
        Set<id> attachmentIds = new Set<Id>();
        for(Attachment attach : attachmentList){
            objRecordIds.add(attach.ParentId);
            attachmentIds.add(attach.Id);
        }

        if (attachmentList.size() > 0) {
            List<sObject> objectRecords = objectFilterQuery(objRecordIds, this.objectName);

            for(SObject obj : objectRecords){
                mapofObjectIdWithName.put(obj.Id, (String) obj.get('Name'));
            }
            Logger logInstance = Logger.getInstance(true);
            try {
                Evisort_Export_Object__c exportJob = new Evisort_Export_Object__c();
                exportJob.Object__c = this.objectName ;
                exportJob.Evisort_Export_Filter__c = this.syncfilterId;
                exportJob.Status__c = Constants.EXPORT_CALCULATING;
                // Ignoring FLS because the user can't edit these fields via the UI
                Data.create(exportJob, true, false, true); 

                this.exportId = exportJob.Id;

                List<Evisort_Export_Document__c> documents = new List<Evisort_Export_Document__c>();
                for (Attachment attachment : attachmentList) {
                    Evisort_Export_Document__c doc = new Evisort_Export_Document__c(
                        Title__c = attachment.Name,
                        Evisort_Export_Object__c = exportId,
                        Record_ID__c = attachment.ParentId,
                        Record_Name__c = mapofObjectIDWithName.get(attachment.ParentId),
                        File_Type__c = Constants.FORM_DATA_TYPES.get(attachment.ContentType),
                        File_Size__c = attachment.BodyLength,
                        ContentDocument__c = attachment.Id
                    );
                    documents.add(doc);
                }

                if (documents.size() > 0) {
                    Data.create(documents, true, false, true);
                }
            } catch (Exception e) {
                logInstance.log('ExportCalculationBatch.execute', e);
            }

            logInstance.finalize();
        }
    }

    global void finish(Database.BatchableContext bc) {
        try {
            ExportCalculationBatchUtils.updateEvisortStatus(exportId, contentExportId, exportFilter);
        } catch (Exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('ExportCalculationBatch.finish', e);
        }
    }

    private static String getAttachmentQuery(String objectFilterBody, String fileFilterBody, String objectName){
        String fileWhereClauseValue;
        EvisortWhereClause eviWhereClause = new  EvisortWhereClause();

        String objWhereClauseValue = ExportCalculationBatchUtils.getObjectWhereClause(objectFilterBody);

        if(String.isNotBlank(fileFilterBody)){
            String attachmentFileFilter = eviWhereClause.replaceFieldNames(fileFilterBody);
            if(String.isNotBlank(attachmentFileFilter)){
            fileWhereClauseValue = eviWhereClause.whereClause(attachmentFileFilter);
            }
        }

        String subquery = 'SELECT Id FROM ' + objectName;
        if(String.isNotBlank(objWhereClauseValue)){
            subquery += ' WHERE ' + objWhereClauseValue;
        }

        String query = '';
        query += 'SELECT ' + String.join(getDefaultFields(), ',') + ' FROM Attachment WHERE';
        if (String.isNotBlank(fileWhereClauseValue)) {
            query += fileWhereClauseValue;
        }
        query += query.endsWith('WHERE') ? ' ' : ' AND';
        query += ' ParentId IN ( '+ subQuery + ')';
        query = query.removeEnd('WHERE');

        return query;
    }

    private static List<sObject> objectFilterQuery(Set<Id> recordIds, String objectName){
        String query = 'SELECT Id,Name FROM ' + objectName;
        if(recordIds.size() > 0){
            query += ' Where Id IN: recordIds';
        }
        return DataBase.query(query);
    }

    private static List<Attachment__c> getCustomAttachmentRecords(Set<Id> recordIds){
        String query =  'SELECT Attachment__c, Evisort__c FROM Attachment__c WHERE Attachment__c != Null';
        if(recordIds.size() > 0){
            query += ' AND Attachment__c IN: recordIds';
        }
        return DataBase.query(query);
    } 

    global static List<String> getDefaultFields(){
        List<String> queryFields = new List<String>();
        queryFields.add('Id');
        queryFields.add('Name');
        queryFields.add('OwnerId');
        queryFields.add('ParentId');
        queryFields.add('BodyLength');
        queryFields.add('ContentType');
        queryFields.add('CreatedDate');
        queryFields.add('LastModifiedDate');

        return queryFields;
    }
}