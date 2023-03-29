@isTest
private class ContentVersionDomainTest {
    @testSetup
    static void setup() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            Evisort_Document_Sync_Criteria__c c = TestFactory.getSyncCriteriaSettings('Opportunity', 'WORD,TEXT', null);
            insert c;
            
            ContentWorkspace cw = TestFactory.getContentWorkspace();
            insert cw;
            
            List <Evisort_Export_Filter__c> eefList = new List <Evisort_Export_Filter__c> ();
            
            Evisort_Export_Filter__c eef = TestFactory.getEvisortDocumentSyncFilters('Opportunity');
            eefList.add(eef);
            
            Evisort_Export_Filter__c eef3 = TestFactory.getEvisortDocumentSyncFilters('Account');
            eef3.Is_Library__c = true;
            eef3.Name = cw.Name;
            eef3.Object__c = cw.Id;
            eef3.Object_Filter_Body__c = '';
            eef3.File_Filter_Body__c = '';
            eefList.add(eef3);
            
            insert eefList;
        }
    }

    @isTest
    static void testCreateEvisortRecordWithEvisortPermissionSet() {
        User u = UserTest.getEvisortUser();

        testCreateEvisortRecord(u);
    }

    @isTest
    static void testCreateEvisortRecordWithoutEvisortPermissionSet() {
        User u = UserTest.createStandardUser();

        testCreateEvisortRecord(u);
    }

    static void testCreateEvisortRecord(User u) {
        System.runAs(u) {
            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];

            ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                testOppty.Id
            );

            Test.startTest();

            insert testConVer;

            Test.stopTest();

            Evisort_Export_Document__c exportDocument = [SELECT ContentVersion__c,ContentDocument__c, Title__c, File_Type__c, File_Size__c FROM Evisort_Export_Document__c];
            CSUtils.itShouldNotBe('Evisort Export Document Not null', null, exportDocument);
        }
    }

    @isTest
    static void testDontCreateEvisortRecordFileType() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];

            ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                testOppty.Id
            );
            testConVer.PathOnClient = 'TestContentVersion.pdf';

            Test.startTest();

            insert testConVer;

            Test.stopTest();

            ContentVersion newConVer = [SELECT Evisort__c FROM ContentVersion WHERE Id = :testConVer.Id LIMIT 1];
            CSUtils.itShouldBe('Evisort Record does not exist', null, newConVer.Evisort__c);
        }
    }

    @isTest
    static void testDontCreateEvisortRecordObject() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Account a = [SELECT Id FROM Account LIMIT 1];

            ContentVersion testConVer = TestFactory.getContentVersion('TestContentVersion', 'Test Content Data', a.Id);

            Test.startTest();

            insert testConVer;

            Test.stopTest();

            ContentVersion newConVer = [SELECT Evisort__c FROM ContentVersion WHERE Id = :testConVer.Id LIMIT 1];
            CSUtils.itShouldBe('Evisort Record does not exist', null, newConVer.Evisort__c);
        }
    }

    @isTest
    static void testCreateEvisortRecordSyncAll() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            settings.Sync_Criteria__c = true;
            upsert settings;

            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];

            ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                testOppty.Id
            );

            Test.startTest();

            insert testConVer;

            Test.stopTest();

            ContentVersion newConVer = [SELECT Evisort__c FROM ContentVersion WHERE Id = :testConVer.Id LIMIT 1];
            CSUtils.itShouldNotBe('Content Version record not null', null, newConVer);
        }
    }
    
    @isTest
    static void testContentVersion(){
        User u = UserTest.getEvisortUser();
        
        System.runAs(u) {
            
            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];
            Account objAccount = [SELECT Id FROM Account LIMIT 1];
            
            List<ContentVersion> cvList = new List<ContentVersion>();
            cvList.add(TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                testOppty.Id
            ));
            cvList.add(TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                objAccount.Id
            ));
            
            ContentVersionDomain cvd = new ContentVersionDomain(cvList);
        }
    }
    
    @isTest
    static void testLibraryContentVersion(){
        User u = UserTest.getEvisortUser(); 
        System.runAs(u) {
            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];
            
            ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                testOppty.Id
            );
            insert testConVer;
            
            Account objAccount = [SELECT Id FROM Account LIMIT 1]; 
            
            ContentWorkspace cw = [SELECT Id FROM ContentWorkspace LIMIT 1];
            ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
            
            ContentWorkspaceDoc cwd = new ContentWorkspaceDoc (ContentDocumentId = cd.Id, ContentWorkspaceId = cw.Id);
            
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(200, mockTokenJson);
            String mockJson = '{"status": "IN_PROGRESS", "evisortId": "291"}';
            mock.addResponse(202, mockJson);
            mock.addResponse(200, mockJson);
            mock.addResponse(400, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            ContentVersion newConVer = [SELECT Id FROM ContentVersion WHERE Id = :testConVer.Id LIMIT 1];
            CSUtils.itShouldNotBe('Content Version record not null', null, newConVer);
        }
    }   
}