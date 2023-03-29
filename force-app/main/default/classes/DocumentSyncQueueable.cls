global with sharing class DocumentSyncQueueable implements Queueable, Database.AllowsCallouts {
    private String nextUrl;

    global DocumentSyncQueueable() {
        this.nextUrl = null;
    }

    // This constructor is not global because we don't want it called from outside of our package
    public DocumentSyncQueueable(String inUrl) {
        this.nextUrl = inUrl;
    }

    global void execute(QueueableContext qc) {
        try {
            DocumentMsg.DocuemntQueueableResponse queueResponse = DocumentQueueableHelper.doDocumentSync(this.nextUrl);

            if (String.isBlank(queueResponse.next)) {
                // We're done. Set the sync time to now and stop chaining.
                Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
                status.Last_Document_Sync__c = Datetime.now();
                upsert status; // Custom Setting, no need for CRUD/FLS check
            } else {
                try {
                    // There's more to do. Chain the next Queueable.
                    System.enqueueJob(new DocumentSyncQueueable(queueResponse.next));
                } catch (AsyncException e) {
                    // This happens in dev orgs, where you can only chain 5 deep.
                    // If this happens, we don't want to reprocess the documents from the previous 5 chains,
                    // So we start up again on the next scheduled run with the datetime of the most recently
                    // processed document.
                    Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
                    status.Last_Document_Sync__c = queueResponse.lastProcessed;
                    upsert status; // Custom Setting, no need for CRUD/FLS check
                }
            }
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('DocumentSyncQueueable', e);
        }
    }
}