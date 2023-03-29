@isTest
private class QueueItemTest {
    @isTest
    static void testQueueProcessor() {
        Account a = TestFactory.getAccount('Test Account');
        insert a;

        QueueItem__c item = TestFactory.getQueueItem(a.Id, 'UnitTest');

        Test.startTest();
        insert item;
        Test.stopTest();

        QueueItem__c newItem = [SELECT Status__c FROM QueueItem__c WHERE Id = :item.Id AND Object__c = 'UnitTest'];
        CSUtils.itShouldBe('Item Status', 'TESTED', newItem.Status__c);
    }

    @isTest
    static void testQueueScheduler() {
        Datetime dt = Datetime.now().addMinutes(5);
        QueueItemScheduler.scheduleMe(dt);

        List<CronTrigger> crons = [
            SELECT Id, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = :QueueItemScheduler.JOBNAME
        ];
        CSUtils.itShouldBe('Number of Jobs', 1, crons.size());
        CSUtils.itShouldbe('Next Fire Time', dt, crons[0].NextFireTime);
    }

    @isTest
    static void testExpireStaleItem() {
        Account a = TestFactory.getAccount('Test Account');
        insert a;

        QueueItem__c item = TestFactory.getQueueItem(a.Id, 'UnitTest');
        Integer hoursToSubtract = QueueItemProcessor.HOURS_BEFORE_ERROR + 1;
        item.Process_After__c = Datetime.now().addHours(-hoursToSubtract);

        Test.startTest();

        insert item;

        Test.stopTest();

        QueueItem__c newItem = [SELECT Status__c FROM QueueItem__c WHERE Id = :item.Id];
        CSUtils.itShouldBe('Item Status', 'EXPIRED', newItem.Status__c);
    }
}