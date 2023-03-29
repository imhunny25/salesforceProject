@isTest
private class EvisortMetadataSyncBatchTest {
    @testSetup
    static void setup(){ 
        User u = UserTest.getEvisortUser();
        
        System.runAs(u) {
            
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;
            
            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;
            
            Contract c = TestFactory.getContract(a.Id);
            insert c;
            
            Evisort__c e = TestFactory.getEvisortRecord(o.Id, '123');
            e.Document_Status__c = 'In Progress';
            insert e;
            
            List<Evisort_Field_Definition__c> defs = new List<Evisort_Field_Definition__c>();
            defs.add(TestFactory.getFieldDefinition('Boolean Field', 'Boolean', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Date Field', 'Date', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Multi Picklist Field', 'Multi Picklist', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Number Field', 'Number', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Picklist Field', 'Picklist', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Provision', 'Text', 'Provision'));
            defs.add(TestFactory.getFieldDefinition('Text Field', 'Text', 'Field'));
            insert defs;
            
            List<Document_Field_Sync_Mapping__c> DocumentFieldSyncMappingRecord = new List<Document_Field_Sync_Mapping__c>();
            DocumentFieldSyncMappingRecord.add(TestFactory.getDocumentFieldSyncMapping('Opportunity', 'Account.Name', 'Account Name', defs[6].id));
            DocumentFieldSyncMappingRecord.add(TestFactory.getDocumentFieldSyncMapping('Opportunity', 'CreatedDate', 'Created Date', defs[2].id));
            DocumentFieldSyncMappingRecord.add(TestFactory.getDocumentFieldSyncMapping('Opportunity', 'Description', 'Description', defs[5].id));
            
            insert DocumentFieldSyncMappingRecord;
            
            Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
            status.Authenticated__c = true;
            status.Authentication_Date__c = Datetime.now();
            status.Sync_Criteria__c = true;
            status.Root_Folder__c = 'Salesforce';
            upsert status;
            
            Evisort_Export_Filter__c eef = TestFactory.getEvisortDocumentSyncFilters('Opportunity');
            insert eef; 
            
            Evisort_Workspace_Settings__c settings = new Evisort_Workspace_Settings__c();
            settings.Workspace__c = 'test';
            settings.Subdomain__c = 'clients';
            settings.LastSyncBatchDate__c = System.Now() -1;
            insert settings;
        }  
    }
    
    @isTest
    static void evisortMetadataSyncTest(){
        User u = UserTest.getEvisortUser();
        
        System.runAs(u) {
            Evisort_Workspace_Settings__c ews = [SELECT Id, Name, LastSyncBatchDate__c FROM Evisort_Workspace_Settings__c LIMIT 1];
            List<Evisort__c> ee = [SELECT Id,Record_ID__c, External_ID__c, Original_File_Name__c, Document_Status__c FROM Evisort__c];
            List<Document_Field_Sync_Mapping__c> edsm = [SELECT Id, Name, Field_Label__c, Salesforce_Field_Name__c, Evisort_Document_Field_Id__c, Evisort_Export_Filter__c, Evisort_Document_Field_Name__c, Evisort_Field_Definition__c, Object__c FROM Document_Field_Sync_Mapping__c];
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            ContentVersion cv = TestFactory.getContentVersion('Unit Test Content', 'Content Here', o.Id);
            insert cv;
            
            ContentVersion newCV = [SELECT Evisort__c FROM ContentVersion WHERE Id = :cv.Id];
            
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "fields": [ { "values": [ { "value": "test" } ], "name": "Description" } ] }';
            mock.addResponse(202, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Test.startTest();
            	DataBase.executeBatch(new EvisortMetadataSyncBatch()); 
            Test.stopTest(); 
            
            Evisort_Workspace_Settings__c settings = [SELECT Id, Name, LastSyncBatchDate__c FROM Evisort_Workspace_Settings__c LIMIT 1];
            CSUtils.itShouldNotBe('run successfully, update last batch Sync date', ews.LastSyncBatchDate__c, settings.LastSyncBatchDate__c);
            
        }
    } 
    
    @isTest
    public static void testMetadataSyncSchedule() {
        String cronExpr = '0 0 0 * * ? *';
        String jobId = System.schedule('test-execute', cronExpr, new EvisortMetadataSyncBatch());
    }
    
    @isTest
    static void testSyncMetadataOnInsertFile(){
        User u = UserTest.getEvisortUser();
        System.runAs(u) {
            Evisort_Workspace_Settings__c ews = [SELECT Id, Name, LastSyncBatchDate__c FROM Evisort_Workspace_Settings__c LIMIT 1];
            List<Evisort__c> ee = [SELECT Id,Record_ID__c, External_ID__c, Original_File_Name__c, Document_Status__c FROM Evisort__c];
            List<Document_Field_Sync_Mapping__c> edsm = [SELECT Id, Name, Field_Label__c, Salesforce_Field_Name__c, Evisort_Document_Field_Id__c, Evisort_Export_Filter__c, Evisort_Document_Field_Name__c, Evisort_Field_Definition__c, Object__c FROM Document_Field_Sync_Mapping__c];
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "fields": [ { "values": [ { "value": "test2" } ], "name": "Description" } ] }';
            mock.addResponse(202, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            List<Id> contentsIDs = new List<Id>();
            ContentVersion cv = TestFactory.getContentVersion('Unit Test Content', 'Content Here', o.Id);
            cv.Evisort__c = ee[0].id;
            insert cv;
            
            contentsIDs.add(cv.Id);
            ContentVersion newCV = [SELECT Evisort__c FROM ContentVersion WHERE Id = :cv.Id];
            
            Test.startTest();
            	DataBase.executeBatch(new EvisortMetadataSyncBatch(contentsIDs)); 
            Test.stopTest(); 
            
            Evisort_Workspace_Settings__c settings = [SELECT Id, Name, LastSyncBatchDate__c FROM Evisort_Workspace_Settings__c LIMIT 1];
            CSUtils.itShouldBe('From Evisort trigger, Not Update last batch Sync date', ews.LastSyncBatchDate__c, settings.LastSyncBatchDate__c);
        }
    }
}