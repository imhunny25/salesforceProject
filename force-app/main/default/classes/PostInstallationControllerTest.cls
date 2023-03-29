@isTest
private  with sharing  class PostInstallationControllerTest {
    @testSetup()
    static void setup()
    {	
        String cronExpression ='0 0 15 ? * MON,TUE,WED *';
        String jobNameDocumentSync ='DocumentSync';
        String jobNameMetaData ='EvisortMetadata';
        String jobNameExportLegacy ='ExportLegacy';

        Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
        status.Authenticated__c = true;
        upsert status;
        
        DocumentSyncSchedulable documentSyncObj = new DocumentSyncSchedulable();
        System.schedule(jobNameDocumentSync, cronExpression, documentSyncObj);
        
        EvisortMetadataSyncBatch evisortMetadataObj=new EvisortMetadataSyncBatch();
        System.schedule(jobNameMetaData, cronExpression, evisortMetadataObj);
        
        EvisortLegacyCleanUpBatch exportLegacyObj=new EvisortLegacyCleanUpBatch();
        System.schedule(jobNameExportLegacy, cronExpression, exportLegacyObj); 
    }
    
    @isTest
    static void initTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            List<NamedCredential> nameCridentialList =[SELECT Id, DeveloperName FROM NamedCredential where DeveloperName='Evisort' LIMIT 1];
            List<CronTrigger> cronTriggerDocument = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'DocumentSync' LIMIT 1];
            List<CronTrigger> cronTriggerMetaData = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'EvisortMetadata' LIMIT 1];
            List<CronTrigger> cronTriggerExportLegacy = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'ExportLegacy' LIMIT 1];
            List<Evisort_Status__c> evisortStatusList = [SELECT Id FROM Evisort_Status__c WHERE Authenticated__c = true];
            Test.startTest();
            Map<String, String> mapOfEvisortData = PostInstallationController.init();
            Test.stopTest();
            System.assertEquals(9, mapOfEvisortData.size());
        }
    }
    
    @isTest
    static void saveSchedulerWeeklyTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String scheduleData ='{"weekly":{"Sun":true,"Tue":true,"Thu":true},"monthly":{"dayMonth":{"day":""},"weekDayMonth":{"week":"","day":""}},"time":"1 : 00 PM"}';
            Test.startTest();
            String jobSchedule = PostInstallationController.saveScheduler(scheduleData, Label.Admin_DocumentSyncJob);
            Test.stopTest();
            System.assertEquals(jobSchedule, Label.Admin_DocumentSyncJob);
        }
    }
    
    @isTest
    static void saveSchedulerMonthlyTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String scheduleDataMonthly ='{"weekly":{},"monthly":{"dayMonth":{"day":"8"},"weekDayMonth":{"week":"","day":""}},"time":"1 : 00 PM"}';
            Test.startTest();
            String jobScheduleMonthly = PostInstallationController.saveScheduler(scheduleDataMonthly, Label.Admin_MetaDataSyncJob);
            Test.stopTest();
            System.assertEquals(jobScheduleMonthly, Label.Admin_MetaDataSyncJob);
        }
    }
    
    @isTest
    static void saveSchedulerWeekDayMonthlyTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String scheduleDataMonthly ='{"weekly":{},"monthly":{"dayMonth":{"day":""},"weekDayMonth":{"week":"2","day":"Wed"}},"time":"2 : 00 PM"}';
            Test.startTest();
            String jobScheduleMonthly = PostInstallationController.saveScheduler(scheduleDataMonthly, Label.Admin_ExportLegacyLeanupJob);
            Test.stopTest();
            System.assertEquals(jobScheduleMonthly, Label.Admin_ExportLegacyLeanupJob);
        }
    }
    
    @isTest
    private static void editSchedulerWeeklyTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String cronExpression ='0 0 15 ? * MON,TUE,WED *';
            
            Test.startTest();
            DocumentSyncSchedulable documentSyncObj = new DocumentSyncSchedulable();
            String jobId = System.schedule('TestJob', cronExpression, documentSyncObj);  
            String editSchedulerName = PostInstallationController.editScheduler('TestJob');
            Test.stopTest();
            
            System.assertNotEquals(null, editSchedulerName);
        }
    }
    
    @isTest
    static void editSchedulerMonthlyTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String cronExpression ='0 0 12 4 1/1 ? *';
            if(Test.isRunningTest()){
                Test.startTest();
                DocumentSyncSchedulable documentSyncObj = new DocumentSyncSchedulable();
                String jobId = System.schedule('TestDayOfMonth', cronExpression, documentSyncObj);
                String editSchedulerJson = PostInstallationController.editScheduler('TestDayOfMonth');
                Test.stopTest();
                System.assertNotEquals(null, editSchedulerJson);
            }
        }
    }
    
    @isTest
    static void editSchedulerWeekDayMonthlyTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String cronExpression ='0 0 12 ? 1/1 WED#2 *';
            if(Test.isRunningTest()){
                Test.startTest();
                DocumentSyncSchedulable documentSyncObj = new DocumentSyncSchedulable();
                String jobId = System.schedule('TestWeekDayOfMonth', cronExpression, documentSyncObj);
                String editSchedulerJson = PostInstallationController.editScheduler('TestWeekDayOfMonth');
                Test.stopTest();
                System.assertNotEquals(null, editSchedulerJson);
            }
        }
    }
    
    @isTest
    static void deleteSchedulerTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String cronExpression ='0 0 12 ? 1/1 WED#2 *';
            if(Test.isRunningTest()){
                Test.startTest();
                DocumentSyncSchedulable documentSyncObj = new DocumentSyncSchedulable();
                String jobId = System.schedule('TestDelete', cronExpression, documentSyncObj);
                String deleteJobName = PostInstallationController.deleteScheduler('TestDelete');
                Test.stopTest();
                System.assertEquals('TestDelete', deleteJobName);
            }
        }
    }
    
    @isTest
    static void updateEvisortWorkspaceSettingTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u){
            String domain ='Test';
            String subDomain = 'TestValue';
            String workspace = 'TestWorkspace';
            Test.startTest();
            Map<String,String> mapOfEvisortWorkspaceSettings = PostInstallationController.updateEvisortWorkspaceSetting(domain, subDomain, workspace);
            Test.stopTest();
            System.assertEquals(mapOfEvisortWorkspaceSettings.get('domain') , domain);
            System.assertEquals(mapOfEvisortWorkspaceSettings.get('subdomain') , subDomain);
            System.assertEquals(mapOfEvisortWorkspaceSettings.get('workspace') , workspace);
        }
    }
}