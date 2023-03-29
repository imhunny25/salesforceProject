/*
 * Originally this batch was designed to query ContentDocumentLink records specific to
 * the related entity id. However, the code had to be refactored to query ContentDocument
 * records due to a bug in the Salesforce platform documented in this known issue:
 * 
 * https://trailblazer.salesforce.com/issues_view?id=a1p3A0000018COxQAM
 * 
 * Batching on ContentDocument is not as efficient because every ContentDocument record has
 * to be processed looking to find a ContentDocumentLink record linking it to the specified
 * entity id. Batching on ContentDocumentLink would be much more efficient because it would
 * only find records linked to the specified entity id.
 */
public with sharing class ExportContentDocumentLinkBatch implements Database.Batchable<SObject>, Database.Stateful {

    private QueueItem__c queueItem;

    /**
     * Constructor
     * @param  queueItemId  Record ID of the QueueScience Item record
     */
    public ExportContentDocumentLinkBatch(Id queueItemId) {
        String soql = 'SELECT Action_Context__c, Data__c, IntegrationID__c, RecordId__c FROM QueueItem__c WHERE Id = :id';
        Map<String, Object> params = new Map<String, Object>{'id' => queueItemId};

        List<QueueItem__c> queueItems = (List<QueueItem__c>) Data.read(soql, params, false, false, false);
        queueItem = queueItems[0];
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> fileTypes;
        if (String.isNotBlank(queueItem.Data__c)) {
            fileTypes = (List<String>) JSON.deserialize(queueItem.Data__c, List<String>.class);
        }

        String query = 'SELECT ContentSize, FileType, Title, LatestPublishedVersionId';
        query += ' FROM ContentDocument';
        query += ' WHERE IsArchived = false';
        query += ' AND IsDeleted = false';
        query += ' AND LatestPublishedVersion.Evisort__c = null';
        if (fileTypes != null && fileTypes.size() > 0) {
            query += ' AND FileType IN (\'' + String.join(fileTypes, '\',\'') + '\')';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ContentDocument> contentDocuments) {
        Logger logInstance = Logger.getInstance(true);

        try {
            Set<Id> contentDocumentIds = new Map<Id, SObject>(contentDocuments).keySet();

            Map<Id, List<ContentDocumentLink>> contentDocumentLinks = new ContentDocumentLinkSelector().getLinksByEntityIdAndDocumentIds(queueItem.IntegrationID__c, contentDocumentIds);

            if (contentDocumentLinks.size() > 0) {
                List<Evisort_Export_Document__c> documents = new List<Evisort_Export_Document__c>();

                for (ContentDocument contentDocument : contentDocuments) {
                    List<ContentDocumentLink> contentDocumentLinkList = contentDocumentLinks.get(contentDocument.Id);

                    if (contentDocumentLinkList != null) {
                        for (ContentDocumentLink contentDocumentLink : contentDocumentLinkList) {
                            // Add a document for each ContentDocumentLink on this record
                            Evisort_Export_Document__c document = new Evisort_Export_Document__c();
                            document.Evisort_Export_Object__c = queueItem.RecordId__c;
                            document.Record_ID__c = queueItem.IntegrationID__c;
                            document.Record_Name__c = contentDocumentLink.LinkedEntity.Name;
                            document.ContentVersion__c = contentDocument.LatestPublishedVersionId;
                            document.File_Type__c = contentDocument.FileType;
                            document.File_Size__c = contentDocument.ContentSize;
                            document.Title__c = contentDocument.Title;
                            documents.add(document);
                        }
                    }
                }

                if (documents.size() > 0) {
                    Data.create(documents, true, false, true);
                }
            }
        } catch (Exception e) {
            logInstance.log('ExportContentDocumentLinkBatch.execute', e);
        }

        logInstance.finalize();
    }

    public void finish(Database.BatchableContext bc) {
        try {
            queueItem.Status__c = 'COMPLETED';
            Data.modify(queueItem, false, false, false);

            // Determine if the Export Calculation batch has completed.
            Boolean exportCalculationBatchCompleted = false;

            List<AsyncApexJob> asyncApexJobs = (List<AsyncApexJob>)
                Data.read('SELECT Status FROM AsyncApexJob WHERE Id = :id', new Map<String, Object>{'id' => queueItem.Action_Context__c}, false, false, false);

            if (asyncApexJobs.size() > 0 && asyncApexJobs[0].Status == 'Completed') {
                exportCalculationBatchCompleted = true;
            }

            if (exportCalculationBatchCompleted) {
                // Ignoring CRUD/FLS because QueueItems can't be CRUD by users.
                String soql = 'SELECT COUNT() FROM QueueItem__c WHERE RecordId__c = :recordId AND Status__c != :status';
                Map<String, Object> params = new Map<String, Object>{'recordId' => queueItem.RecordId__c, 'status' => 'COMPLETED'};
                Integer incompleteQueueItemCount = Data.countQuery(soql, params, false, false, false);

                // Update the Status to ready if there aren't any incomplete Queue Items related to the export.
                if (incompleteQueueItemCount == 0) {
                    Evisort_Export_Object__c exportJob = new Evisort_Export_Object__c();
                    exportJob.Id = queueItem.RecordId__c;
                    exportJob.Status__c = Constants.EXPORT_READY;
                    Data.modify(exportJob, true, false, true);
                }
            } else {
                // Kick off the Queue Item processor if it's not already running.
                QueueItemProcessor.execute();
            }
        } catch (Exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('ExportContentDocumentLinkBatch.finish', e);
        }
    }

}