@isTest
private with sharing class EvisortLegacyCleanUpBatchTest {
    @testSetup
    static void setup(){ 
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Account', Constants.EXPORT_RUNNING, 'WORD,EXCEL,TEXT,PDF');
            insert eeo;

            List<Evisort_Export_Document__c> docs = new List<Evisort_Export_Document__c>();
            for (Integer i = 0; i < 5; i++) {
                docs.add(
                    TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_QUEUED, null, null, (i + 1) * 1000)
                );
            }
            insert docs;
        }  
    }
    
    @isTest
    static void testEvisortLegacyCleanUpBatch(){
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            	
            DataBase.executeBatch(new EvisortLegacyCleanUpBatch()); 
            
            Test.stopTest(); 

            List<Evisort_Export_Object__c> eeoList = [SELECT Id, Status__c, Grouped_Error__c,
                                                      (SELECT Name, Status__c, Error_Message__c FROM Evisort_Export_Documents__r) 
                                                      FROM Evisort_Export_Object__c];
            
            CSUtils.itShouldBe('Evisort export object 1 status', Constants.EXPORT_CANCELLED, eeoList[0].Status__c);
            CSUtils.itShouldBe('Updated Export Document 1 Status', 'Errored', eeoList[0].Evisort_Export_Documents__r[0].Status__c);
            CSUtils.itShouldBe('Updated Export Document 2 Status', 'Errored', eeoList[0].Evisort_Export_Documents__r[1].Status__c);
        }
    } 
    
    @isTest
    public static void testEvisortLegacyCleanUpBatchSchedule() {
        String cronExpr = '0 0 0 * * ? *';
        String jobId = System.schedule('test-migrate-execute', cronExpr, new EvisortLegacyCleanUpBatch());
    }
}