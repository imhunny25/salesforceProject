@isTest
private class ExportObjectStatusRestControllerTest {
	@isTest
    static void updateExportObjectStatusTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            insert eeo;
            
            String body = '{"status": "Completed" , "evisortExportObjectId": "'+eeo.id+'" }';
       
            RestRequest request = new RestRequest();
            request.requestUri ='';
            request.httpMethod = 'PATCH';
            request.requestBody = Blob.valueof(body);
            
            RestContext.request = request;
            Test.startTest();
            ExportObjectStatusRestController.updateExportObjectStatus();
            Test.stopTest();
            
            List<Evisort_Export_Object__c> updateExportObject = [SELECT Id, Name, Status__c FROM Evisort_Export_Object__c];
            CSUtils.itShouldBe('No of Record ', 1, updateExportObject.size());
            CSUtils.itShouldBe('Object Status Completed ', Constants.EXPORT_COMPLETE, updateExportObject[0].Status__c);   
        }
    }
}