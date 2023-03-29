@isTest
private class EvisortPreviousFilterRecordsTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {            
            List<Evisort_Export_Object__c> objs = new List<Evisort_Export_Object__c>();
            objs.add(TestFactory.getExportObject('Opportunity', Constants.EXPORT_READY, 'WORD,EXCEL,TEXT,PDF'));
            objs.add(TestFactory.getExportObject('Account', Constants.EXPORT_READY, null));
            insert objs;
            
            List<Evisort_Document_Sync_Criteria__c> criteria = new List<Evisort_Document_Sync_Criteria__c>();
            criteria.add(TestFactory.getSyncCriteriaSettings('Opportunity', null, null));
            criteria.add(TestFactory.getSyncCriteriaSettings('Contract', 'WORD,TEXT,Excel', null));
            insert criteria;  
        }
    }
	@isTest
    static void evisortRecordstest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) { 
            Test.startTest();
            EvisortPreviousFilterRecords.evisortRecords();
            Test.stopTest();	
            
            CSUtils.itShouldNotBe('Number of Evisort export filter records', 0, [SELECT COUNT() FROM Evisort_Export_Filter__c]);
        }
    }
}