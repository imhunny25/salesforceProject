public with sharing class ContentDocumentDomain extends Domain {
    /**
     * Constructor based on Domain.cls constructor with similar signature
     * @param  records List of Records
     */
    public ContentDocumentDomain(List<ContentDocument> records) {
        super(records);
    }

    /***********************************
        Business logic
    ************************************/

    /**
     * Sets up a QueueScience worker to send a DELETE call to the Evisort API if an Evisort tracked document is deleted
     * This is done BEFORE DELETE because we need access to the associated ContentVersions to get the associated Evisort record
     * @param  documents List of ContentDocuments (Trigger.old)
     */
    public void deleteContent(List<ContentDocument> documents) {
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocument cd : documents) {
            documentIds.add(cd.Id);
        }

        if (documentIds.isEmpty()) {
            return;
        }

        // Ignoring CRUD/FLS on the read query to check Evisort__c lookup is populated.
        ContentVersionSelector cvSelector = new ContentVersionSelector(false, false, false);
        List<ContentVersion> conVers = cvSelector.getContentVersionsByDocumentIds(documentIds);

        List<QueueItem__c> queueItemsToInsert = new List<QueueItem__c>();

        for (ContentVersion cv : conVers) {
            if (cv.Evisort__c != null) {
                QueueItem__c item = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                item.RecordId__c = cv.Evisort__c;
                item.Object__c = 'Evisort__c';
                item.Action_Context__c = 'DeleteRecord';
                queueItemsToInsert.add(item);
            }
        }

        // Call Evisort upload API to transmit deletion request
        // Ignoring CRUD/FLS because QueueItems can't be edited by users
        if (!queueItemsToInsert.isEmpty() && !Test.isRunningTest()) {
            Data.create(queueItemsToInsert, false, false, false);
        }
    }

    /******************   BUSINESS LOGIC end   **************/

    /*************************************
        Trigger functions
    **************************************/
    public override void onBeforeDelete() {
        List<ContentDocument> documents = (List<ContentDocument>) this.records;

        this.deleteContent(documents);
    }
}