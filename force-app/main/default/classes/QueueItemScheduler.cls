public with sharing class QueueItemScheduler implements Schedulable {
    @TestVisible
    private static final String JOBNAME = 'QueueItemScheduler';

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueItemWorker());
    }

    public static void scheduleMe(Datetime runTime) {
        unscheduleMe();

        String cronTime = runTime.format('s m H d M \'?\' yyyy');
        System.schedule(JOBNAME, cronTime, new QueueItemScheduler());
    }

    public static void unscheduleMe() {
        // Running in System Context so no CRUD/FLS/SHR
        List<CronTrigger> crons = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :JOBNAME];
        for (CronTrigger ct : crons) {
            System.abortJob(ct.Id);
        }
    }
}