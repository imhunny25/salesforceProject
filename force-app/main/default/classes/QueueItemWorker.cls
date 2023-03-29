/**
 * Without Sharing is necessary due to the Queue Item object not being accessible by users.
 */
public without sharing class QueueItemWorker implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private integer rowLimit;

    public QueueItemWorker(){
        rowLimit = 1;
    }


    public void execute(QueueableContext context) {
        List<QueueItem__c> queueItemsToProcess = new List<QueueItem__c>();
        // No CRUD/FLS/SHR because the user won't have access to this object
        queueItemsToProcess = getQueueitems(rowLimit);
       
        if(!queueItemsToProcess.isEmpty() && queueItemsToProcess[0].Object__c == 'MetadataExport' ){
            queueItemsToProcess = new List<QueueItem__c>();
            queueItemsToProcess = getQueueitems(10);
        }
        Map<Id,QueueItem__c> mapOfMetaDataQueueitems = new Map<Id,QueueItem__c>();
        Integer count = 0;
        Integer totalQueueitem = queueItemsToProcess.size();
        List<String> metaDataSyncError = new List<String>();
        for (QueueItem__c item : queueItemsToProcess) {
            if (item.Object__c == 'ContentVersion' || item.Object__c == 'Attachment') {
                ExportService.doDocumentExport(item);
            } else if (item.Object__c == 'MetadataExport') {
                count += 1;
                ExportService.doMetadataExport(item,mapOfMetaDataQueueitems,count, totalQueueitem, metaDataSyncError);
            } else if (item.Object__c == 'Evisort__c') {
                if (item.Action_Context__c == 'CheckRecord') {
                    DocumentQueueableHelper.checkEvisortRecord(item);
                } else if (item.Action_Context__c == 'SendValues') {
                    DocumentQueueableHelper.sendValues(item);
                } else if (item.Action_Context__c == 'DeleteRecord') {
                    DocumentQueueableHelper.deleteDocument(item);
                }
            } else if (item.Object__c == 'Evisort_Export_Document__c') {
                ExportService.doDocumentExport(item);
            } else if (item.Object__c == 'Evisort_Export_Object__c') {
                ExportService.doContentDocumentLinkExport(item);
            } else if (item.Object__c == 'Evisort_Ticket__c') {
                if (item.Action_Context__c == 'update') {
                    TicketService.ticketUpdateQueueHelper(item);
                } else if (item.Action_Context__c == 'delete') {
                    TicketService.ticketDeleteQueueHelper(item);
                } else if (item.Action_Context__c == 'evisortRecordUpdate') {
                    TicketService.evisortRecordUpdate(item);
                }
            } else if (item.Object__c == 'UnitTest') {
                // This is for a Unit Test so we want to act like it did something
                item.Status__c = 'TESTED';
                Data.modify(item, false, false, false);
            }
        }

        //logger for MetadataExport Error
        if(!metaDataSyncError.isEmpty()){
            List<LoggerMsg.Log> loggerMsgList = new List<LoggerMsg.Log>();
            for(String message : metaDataSyncError){
                LoggerMsg.Log loggerMsg = new LoggerMsg.Log(
                    'ExportService.doMetadataExport',
                    'ERROR',
                    null,
                    null,
                    message,
                    null,
                    null,
                    null
                );
                loggerMsgList.add(loggerMsg);
            }

            Logger errorlogger = Logger.getInstance();
            errorlogger.write(loggerMsgList);
        }

        // determine if there are more items in the queue
        // No CRUD/FLS/SHR because the user won't have access to this object
        List<QueueItem__c> pendingItems = [
            SELECT Process_After__c,Object__c
            FROM QueueItem__c
            WHERE Status__c = 'NEW'
            ORDER BY  Process_After__c, Priority__c
            LIMIT 1
        ];

        // work to be done, queue the job up again
        if (pendingItems.size() > 0) {
            if (pendingItems[0].Process_After__c == null || pendingItems[0].Process_After__c < Datetime.now()) {
                try {
                    System.enqueueJob(new QueueItemWorker());
                } catch (AsyncException e) {
                    // We've reached the max chain depth (scratch orgs and dev orgs)
                    // Queue job for one minute in the future to continue processing workers
                    QueueItemScheduler.scheduleMe(Datetime.now().addMinutes(1));
                }
            } else {
                // Queue job in the future
                QueueItemScheduler.scheduleMe(pendingItems[0].Process_After__c.addMinutes(1));
            }
        } else {
            QueueItemScheduler.unscheduleMe();
        }
    }

    public static List<QueueItem__c> getQueueitems(Integer rowLimit){
        List<QueueItem__c> queueItemsToProcess = new List<QueueItem__c>();
        DateTime processingTimeBoundary = DateTime.now();

        String query = 'SELECT Action_Context__c, Data__c, IntegrationID__c, Object__c, Process_After__c, RecordId__c';
        query += ' FROM QueueItem__c';
        query += ' WHERE Process_After__c <= : processingTimeBoundary AND Status__c =\'NEW\'';
        if(rowLimit == 10){
            query += ' AND Object__c = \'MetadataExport\'';
        }
        query += ' ORDER BY Priority__c, Process_After__c';
        query += ' LIMIT '+ rowLimit;

        queueItemsToProcess = Database.query(query);  
       
        return queueItemsToProcess;
    }
}