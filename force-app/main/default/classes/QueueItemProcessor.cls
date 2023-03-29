/**
 * Without Sharing is necessary due to the Queue Item object not being accessible by users.
 */
public without sharing class QueueItemProcessor {
    @TestVisible
    private static Boolean enabled = true;

    @TestVisible
    private static final Integer HOURS_BEFORE_ERROR = 1;

    public QueueItemProcessor() {
        throw new QueueItemProcessorException('This class should not be constructed');
    }

    public static void execute() {
        if (!enabled) return;

        // determine if there is already a job queued or processing QueueItem__c records
        // enqueue if there is no job currently executing to process records

        String[] classNameParts = QueueItemProcessor.class.getName().split('\\.');
        String ns = (classNameParts.size() == 2) ? classNameParts[0] : '';

        List<String> classNames = new List<String>{
            QueueItemProcessor.class.getName().removeStart(ns + '.'),
            QueueItemWorker.class.getName().removeStart(ns + '.')
        };

        // get class details for querying the job table
        // Running in the system context so no CRUD/FLS/SHR
        Map<Id, ApexClass> classMap = new Map<Id, ApexClass>(
            [SELECT Id, Name, NamespacePrefix FROM ApexClass WHERE Name IN :classNames AND NamespacePrefix = :ns]
        );

        // determine if there are any queueable jobs executing in my namespace's classes
        // Running in the system context so no CRUD/FLS/SHR
        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE
                JobType = 'Queueable'
                AND (Status = 'Queued'
                OR Status = 'Holding'
                OR Status = 'Processing'
                OR Status = 'Preparing')
                AND ApexClassId IN :classMap.keyset()
        ];

        if (jobs.size() == 0) {
            expireStaleItem();
            System.enqueueJob(new QueueItemWorker());
        }
    }

    /**
     * Checking for a job that has been queued up for hours in the past
     * This usually is the result of an uncatchable exception being thrown while processing an item
     * (LimitExceptions are not catchable!) causing the transaction to be rolled back.
     * If a job is more than the specified hours old, we mark it as expired so we don't keep processing it.
     */
    private static void expireStaleItem() {
        Datetime processAfter = Datetime.now().addHours(-HOURS_BEFORE_ERROR);

        // No CRUD/FLS/SHR because the user won't have access to this object
        List<QueueItem__c> queueItemsToProcess = [
            SELECT Id, Process_After__c
            FROM QueueItem__c
            WHERE Process_After__c <= :processAfter AND Status__c = 'NEW'
            ORDER BY Process_After__c ASC
            LIMIT 1
        ];

        if (!queueItemsToProcess.isEmpty()) {
            queueItemsToProcess[0].Status__c = 'EXPIRED';
            // No CRUD/FLS/SHR because the user won't have access to this object
            Data.modify(queueItemsToProcess[0], false, false, false);
        }
    }

    public class QueueItemProcessorException extends Exception {
    }
}