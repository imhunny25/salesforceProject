global with sharing class DocumentSyncSchedulable implements Schedulable {

    global void execute(SchedulableContext sc) {
        try {
            // Determine if there is already a job queued. If not, queue the job.
            String[] classNameParts = DocumentSyncQueueable.class.getName().split('\\.');
            String namespacePrefix = (classNameParts.size() == 2) ? classNameParts[0] : '';
            String className = DocumentSyncQueueable.class.getName().removeStart(namespacePrefix + '.');
            Id apexClassId = [SELECT Id FROM ApexClass WHERE Name = :className AND NamespacePrefix = :namespacePrefix].Id;

            // Ignoring CRUD/FLS because AsyncApexJob can't be CRUD by users.
            String soql = 'SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId = :apexClassId AND Status IN (\'Queued\', \'Holding\', \'Processing\', \'Preparing\')';
            Map<String, Object> params = new Map<String, Object>{'apexClassId' => apexClassId};
            Integer inProgressCount = Data.countQuery(soql, params, false, false, false);

            if (inProgressCount == 0) {
                System.enqueueJob(new DocumentSyncQueueable());
            }
        } catch (Exception e) {
            Logger.getInstance().log('DocumentSyncSchedulable.execute', e);
        }
    }

}