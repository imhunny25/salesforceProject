@isTest
private class ExportTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            Contract c = TestFactory.getContract(a.Id);
            insert c;

            Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
            status.Authenticated__c = true;
            status.Authentication_Date__c = Datetime.now();
            status.Sync_Criteria__c = false;
            upsert status;

            List<Evisort_Export_Filter__c> evisortExportFilterList = new List<Evisort_Export_Filter__c>();
            
            Evisort_Export_Filter__c eefAcc = TestFactory.getEvisortDocumentSyncFilters('Account');
            eefAcc.is_legacy__c = true;
            evisortExportFilterList.add(eefAcc);
            
            Evisort_Export_Filter__c eefOpp = TestFactory.getEvisortDocumentSyncFilters('Opportunity');
            eefOpp.is_legacy__c = true;
            evisortExportFilterList.add(eefOpp);
            
            insert evisortExportFilterList;

            List<Evisort_Document_Sync_Criteria__c> criteria = new List<Evisort_Document_Sync_Criteria__c>();
            criteria.add(TestFactory.getSyncCriteriaSettings('Opportunity', null, null));
            criteria.add(TestFactory.getSyncCriteriaSettings('Contract', 'WORD,TEXT', null));
            insert criteria;

            List<Evisort_Field_Definition__c> EvisortFieldDefinitionRecord = new List<Evisort_Field_Definition__c>();
            EvisortFieldDefinitionRecord.add(TestFactory.getFieldDefinition('Comments', 'Text', 'Field'));
            EvisortFieldDefinitionRecord.add(TestFactory.getFieldDefinition('Description', 'Text', 'Field'));
            insert EvisortFieldDefinitionRecord;

            List<Document_Field_Sync_Mapping__c> DocumentFieldSyncMappingRecord = new List<Document_Field_Sync_Mapping__c>();
            DocumentFieldSyncMappingRecord.add(TestFactory.getDocumentFieldSyncMapping('Opportunity', 'Name', 'Name', EvisortFieldDefinitionRecord[0].id));
            DocumentFieldSyncMappingRecord.add(TestFactory.getDocumentFieldSyncMapping('Opportunity','Description', 'Description', EvisortFieldDefinitionRecord[1].id));
            insert DocumentFieldSyncMappingRecord;
        }
    }

    @isTest
    static void testGetExportObjects() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            List<Evisort_Export_Filter__c> evisortExportFilterList = [SELECT Id,Object_Filter_Body__c, is_legacy__c, File_Filter_Body__c  FROM Evisort_Export_Filter__c];
            List<Evisort_Export_Object__c> objs = new List<Evisort_Export_Object__c>();
            objs.add(TestFactory.getExportObject('Opportunity', Constants.EXPORT_READY, null ));
            objs.add(TestFactory.getExportObject('Account', Constants.EXPORT_READY,null));
            objs[0].Evisort_Export_Filter__c = evisortExportFilterList[0].Id;
            objs[1].Evisort_Export_Filter__c = evisortExportFilterList[1].Id;
            insert objs;

            List<Evisort_Export_Document__c> docs = new List<Evisort_Export_Document__c>();
            for (Integer i = 0; i < 10; i++) {
                docs.add(
                    TestFactory.getExportDocument(objs[0].Id, Constants.EXPORT_QUEUED, null, null, (i + 1) * 1000)
                );
                docs.add(
                    TestFactory.getExportDocument(objs[1].Id, Constants.EXPORT_QUEUED, null, null, (i + 1) * 1000)
                );
            }
            insert docs;

            Test.startTest();

            ExportMsg.ExportStatus msg = ExportController.getExportObjects();

            Test.stopTest();

            CSUtils.itShouldBe('ExportMsg.ExportStatus should not be empty', msg != null, true);
			CSUtils.itShouldBe('Overall Status', Constants.EXPORT_READY, msg.status);
            CSUtils.itShouldBe('Total File Size', 110000, msg.totalSize);
            CSUtils.itShouldBe('Number of Documents', 20, msg.numberOfDocuments);
            CSUtils.itShouldBe('Estimated Minutes', 1, msg.estimatedMinutes);
            CSUtils.itShouldBe('Number of Objects', 3, msg.objects.size());
            CSUtils.itShouldBe('First Object', 'Account', msg.objects.values()[0].objectLabel);
            CSUtils.itShouldBe('Status of First Object', Constants.EXPORT_READY, msg.objects.values()[0].status);
            CSUtils.itShouldBe('Number of Documents on First Object', 10, msg.objects.values()[0].numberOfDocuments);
            CSUtils.itShouldBe('Total Size of Documents on First Object', 55000, msg.objects.values()[0].totalSize);
           	CSUtils.itShouldBe('Second Object', 'Contract', msg.objects.values()[1].objectLabel);
            CSUtils.itShouldBe('Status of Second Object', null, msg.objects.values()[1].status);
            CSUtils.itShouldBe('Third Object', 'Opportunity', msg.objects.values()[2].objectLabel);
            CSUtils.itShouldBe('Status of Third Object', Constants.EXPORT_READY, msg.objects.values()[2].status);
            CSUtils.itShouldBe('Number of Documents on Third Object', 10, msg.objects.values()[2].numberOfDocuments);
            CSUtils.itShouldBe('Total Size of Documents on Third Object', 55000, msg.objects.values()[2].totalSize);
        }
    }

    @isTest
    static void testCalculateObject() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id, Name, File_Filter_Body__c, Is_Legacy__c, Is_Library__c, Object_Filter_Body__c, Object__c FROM Evisort_Export_Filter__c WHERE Object__c = 'Opportunity' LIMIT 1];                  
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_COMPLETE, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            Evisort_Export_Document__c docs = new Evisort_Export_Document__c();
            docs = TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_QUEUED, null, null, (1) * 1000);
            insert docs;
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            List<ContentVersion> content = new List<ContentVersion>();
            for (Integer i = 0; i < 10; i++) {
                content.add(TestFactory.getContentVersion('Test' + i, 'Data ' + i, o.Id));
            }
            content[0].PathOnClient = 'Test0.txt';
            insert content;

            ExportMsg.ExportObject obj = new ExportMsg.ExportObject();
            obj.objectLabel = 'Opportunity';
            obj.objectFilterBody = eef.Object_Filter_Body__c;
            obj.fileFilterBody = eef.File_Filter_Body__c;
            Test.startTest();

            Boolean result = ExportController.calculateObject(JSON.serialize(obj));

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> objs = [
                SELECT Object__c, Number_of_Documents__c, Total_Size__c, Status__c
                FROM Evisort_Export_Object__c
            ];
            CSUtils.itShouldBe('Number of objects', 2, objs.size());
            CSUtils.itShouldBe('Object Name', 'Opportunity', objs[0].Object__c);
            CSUtils.itShouldBe('Status', Constants.EXPORT_READY, objs[0].Status__c);
            CSUtils.itShouldBe('Number of Documents', 9, objs[0].Number_of_Documents__c);
            CSUtils.itShouldBe('Total Size', 27, objs[0].Total_Size__c);
        }
    }

    @isTest
    static void testCalculateObjectLibraryObject() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {

            ContentWorkspace cw = TestFactory.getContentWorkspace();
            insert cw;
            
            ContentFolder workspaceFolder = [Select Id from ContentFolder where Name =: cw.Id];
            ContentFolder testFolderRecord = new ContentFolder(Name='TEST FOLDER', ParentContentFolderId=workspaceFolder.Id);
    		insert testFolderRecord;
            
            Evisort_Export_Filter__c eef = new Evisort_Export_Filter__c(
                Name = 'Evisort__c',
                Object__c = 'Evisort__c',
                Is_Legacy__c = true,
                Library_Mapping__c = '{"sObjectName":"Evisort__c","isLibraryObjectCheck":true,"libraryName":"05819000000EWbzAAG","customField":"Evisort__c"}'
            );
            insert eef;
            
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Evisort__c', Constants.EXPORT_COMPLETE, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            Evisort_Export_Document__c docs = new Evisort_Export_Document__c();
            docs = TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_QUEUED, null, null, (1) * 1000);
            insert docs;
            
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            Evisort__c evs = TestFactory.getEvisortRecord(o.Id, '1111111');
            insert evs;

            Domain.bypassTriggers(ContentVersionDomain.class);

           	ContentVersion cv = TestFactory.getContentVersion('Test Library Content', 'Data', evs.Id);
            cv.PathOnClient = 'Test Library Content.txt';
            cv.Evisort__c = evs.Id;
            insert cv;
            
    		List<ContentFolderMember> folderMembers = new List<ContentFolderMember>();
            
            ContentVersion conVer = [Select Id, ContentDocumentId from ContentVersion WHERE Id =: cv.Id];
            ContentDocumentLink documentLink = [SELECT Id, ContentDocumentId, LinkedEntityId, Sharetype FROM ContentDocumentLink
                                               	WHERE ContentDocumentId =: conVer.ContentDocumentId LIMIT 1];
            documentLink.Sharetype = 'I';
			update documentLink;
            
            for(ContentFolderMember cfm : [Select Id, ChildRecordId, ParentContentFolderId from ContentFolderMember
                                   where ParentContentFolderId =: workspaceFolder.Id]) {
                cfm.ParentContentFolderId = testFolderRecord.Id;
                folderMembers.add(cfm);
            }        
            update folderMembers;
                        
            ExportMsg.ExportObject obj = new ExportMsg.ExportObject();
            obj.objectLabel = 'Evisort__c';
            obj.libraryMapping = eef.Library_Mapping__c;
            obj.libraryName = cw.Id;
            obj.isLegacy = true;
            obj.enableAddExport = true;
            obj.resetDisabled = true;
            
            Test.startTest();

            Boolean result = ExportController.calculateObject(JSON.serialize(obj));

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> objs = [
                SELECT Object__c, Number_of_Documents__c, Total_Size__c, Status__c
                FROM Evisort_Export_Object__c
            ];
            CSUtils.itShouldBe('Number of objects', 1, objs.size());
            CSUtils.itShouldBe('Object Name', 'Evisort__c', objs[0].Object__c);
            CSUtils.itShouldBe('Status', Constants.EXPORT_READY, objs[0].Status__c);
            CSUtils.itShouldBe('Number of Documents', 0, objs[0].Number_of_Documents__c);
            CSUtils.itShouldBe('Total Size', 0, objs[0].Total_Size__c);
        }
    }

    @isTest
    static void testCalculateObjectLibrary() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {

            ContentWorkspace cw = TestFactory.getContentWorkspace();
            insert cw;
            
            Set<Id> libraryIds = new Set<Id>{cw.Id};
            EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
            List<ContentWorkspace> contentList =  eeoSelector.getLibraryName(libraryIds);
            String libraryName = contentList[0].Name;
            
            ContentFolder workspaceFolder = [Select Id from ContentFolder where Name =: cw.Id];
            ContentFolder testFolderRecord = new ContentFolder(Name='TEST FOLDER', ParentContentFolderId=workspaceFolder.Id);
    		insert testFolderRecord;
            
            Evisort_Export_Filter__c eef = new Evisort_Export_Filter__c(
                Name = libraryName,
                Object__c = cw.Id,
                Is_Library__c = true,
                Is_Legacy__c = true
            );
            insert eef;
            
            Evisort_Export_Object__c eeo = TestFactory.getExportObject(libraryName, Constants.EXPORT_COMPLETE, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            Evisort_Export_Document__c docs = new Evisort_Export_Document__c();
            docs = TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_QUEUED, null, null, (1) * 1000);
            insert docs;

            Domain.bypassTriggers(ContentVersionDomain.class);

           	ContentVersion cv = TestFactory.getContentVersion('Test Library Content', 'Data', cw.Id);
            cv.PathOnClient = 'Test Library Content.txt';
            insert cv;
            
    		List<ContentFolderMember> folderMembers = new List<ContentFolderMember>();
            
            ContentVersion conVer = [Select Id, ContentDocumentId from ContentVersion WHERE Id =: cv.Id];
            ContentDocumentLink documentLink = [SELECT Id, ContentDocumentId, LinkedEntityId, Sharetype FROM ContentDocumentLink
                                               	WHERE ContentDocumentId =: conVer.ContentDocumentId];
            documentLink.Sharetype = 'I';
			update documentLink;
            
            for(ContentFolderMember cfm : [Select Id, ChildRecordId, ParentContentFolderId from ContentFolderMember
                                   where ParentContentFolderId =: workspaceFolder.Id]) {
                cfm.ParentContentFolderId = testFolderRecord.Id;
                folderMembers.add(cfm);
            }        
            update folderMembers;
                        
            ExportMsg.ExportObject obj = new ExportMsg.ExportObject();
            obj.enableAddExport = true;
            obj.enableLibraryFilter = true;
            obj.objectLabel = cw.Id;
            obj.isLegacy = true;
            obj.resetDisabled = true;
            
            Test.startTest();

            Boolean result = ExportController.calculateObject(JSON.serialize(obj));

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> objs = [
                SELECT Object__c, Number_of_Documents__c, Total_Size__c, Status__c
                FROM Evisort_Export_Object__c
            ];
            CSUtils.itShouldBe('Number of objects', 3, objs.size());
            CSUtils.itShouldBe('Object Name', libraryName, objs[0].Object__c);
            CSUtils.itShouldBe('Status', Constants.EXPORT_COMPLETE, objs[0].Status__c);
            CSUtils.itShouldBe('Number of Documents', 1, objs[0].Number_of_Documents__c);
            CSUtils.itShouldBe('Total Size', 1000, objs[0].Total_Size__c);
        }
    }
    
    @isTest
    static void testGetObjectList() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            List<String> objectList= ExportController.getObjectList();
            Test.stopTest();
            CSUtils.itShouldBe('Object List should not be empty', objectList.size() != 0, true);
        }
    } 

    @isTest
    static void testCalculateObjectWithCDLBatch() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id, Name, File_Filter_Body__c, Is_Legacy__c, Is_Library__c, Object_Filter_Body__c, Object__c FROM Evisort_Export_Filter__c WHERE Object__c = 'Opportunity' LIMIT 1];   
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_COMPLETE, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            ContentVersion contentVersion = TestFactory.getContentVersion('Test', 'Data', o.Id);
            insert contentVersion;

            ExportMsg.ExportObject obj = new ExportMsg.ExportObject();
            obj.objectLabel = 'Opportunity';
            obj.objectFilterBody = eef.Object_Filter_Body__c;
            obj.fileFilterBody = eef.File_Filter_Body__c;

            Test.startTest();

            Boolean result = ExportController.calculateObject(JSON.serialize(obj));

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);

            List<Evisort_Export_Object__c> objs = [
                SELECT Object__c, Number_of_Documents__c, Total_Size__c, Status__c
                FROM Evisort_Export_Object__c
            ];
            CSUtils.itShouldBe('Number of objects', 2, objs.size());
            CSUtils.itShouldBe('Object Name', 'Opportunity', objs[0].Object__c);
        }
    }

    @isTest
    static void testExportCDLBatch() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            QueueItemProcessor.enabled = false;

            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_COMPLETE, null);
            insert eeo;

            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            ContentVersion contentVersion = TestFactory.getContentVersion('Test', 'Data', o.Id);
            insert contentVersion;

            List<ContentDocumentLink> cdls = [SELECT ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId = :o.Id];

            CSUtils.itShouldBe('size of ContentDocumentLink', 1, cdls.size());
            CSUtils.itShouldBe('FileType', 'WORD', cdls[0].ContentDocument.FileType);

            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Object__c = 'Evisort_Export_Object__c';
            queueItem.RecordId__c = eeo.Id;
            queueItem.IntegrationID__c = o.Id;
            queueItem.Data__c = JSON.serialize(new List<String>{'WORD'});
            insert queueItem;

            Test.startTest();

            Database.executeBatch(new ExportContentDocumentLinkBatch(queueItem.Id), 5);

            Test.stopTest();

            CSUtils.itShouldBe('Status', 'COMPLETED', [SELECT Status__c FROM QueueItem__c WHERE Id = :queueItem.Id].Status__c);

            List<Evisort_Export_Document__c> evisortExportDocuments = [
                SELECT
                    Evisort_Export_Object__c, Record_ID__c, Record_Name__c, ContentVersion__c, File_Type__c, Title__c
                FROM
                    Evisort_Export_Document__c
            ];

            CSUtils.itShouldBe('size of evisortExportDocuments', 1, evisortExportDocuments.size());
            CSUtils.itShouldBe('EvisortExportObjectID of evisortExportDocuments', eeo.Id, evisortExportDocuments[0].Evisort_Export_Object__c);
            CSUtils.itShouldBe('RecordId of evisortExportDocuments', o.Id, evisortExportDocuments[0].Record_ID__c);
            CSUtils.itShouldBe('RecordName of evisortExportDocuments', 'Unit Test Opportunity', evisortExportDocuments[0].Record_Name__c);
            CSUtils.itShouldBe('ContentVersionId of evisortExportDocuments', contentVersion.Id, evisortExportDocuments[0].ContentVersion__c);
            CSUtils.itShouldBe('FileType of evisortExportDocuments', 'WORD', evisortExportDocuments[0].File_Type__c);
            CSUtils.itShouldBe('Title of evisortExportDocuments', 'Test', evisortExportDocuments[0].Title__c);
        }
    }

    @isTest
    static void testResetObjects() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id FROM Evisort_Export_Filter__c LIMIT 1];
            List<Evisort_Export_Object__c> objs = new List<Evisort_Export_Object__c>();
            objs.add(TestFactory.getExportObject('Opportunity', Constants.EXPORT_READY, 'WORD,EXCEL'));
            objs.add(TestFactory.getExportObject('Account', Constants.EXPORT_READY, null));
            objs[0].Evisort_Export_Filter__c = eef.Id;
            insert objs;

            Test.startTest();

            Boolean result = ExportController.resetObjects(new List<String>{'Account'});

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> newObjs = [SELECT Object__c FROM Evisort_Export_Object__c];
            CSUtils.itShouldBe('Number of objects', 1, newObjs.size());
            CSUtils.itShouldBe('Object Name', 'Opportunity', newObjs[0].Object__c);
        }
    }

    @isTest
    static void testStartExport() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id FROM Evisort_Export_Filter__c LIMIT 1]; 
            List<Evisort_Export_Object__c> objs = new List<Evisort_Export_Object__c>();
            objs.add(TestFactory.getExportObject('Opportunity', Constants.EXPORT_READY, 'WORD,EXCEL'));
            objs.add(TestFactory.getExportObject('Account', Constants.EXPORT_READY, null));
            objs[0].Evisort_Export_Filter__c = eef.Id;
            insert objs;

            Test.startTest();

            Boolean result = ExportController.startExport();

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> newObjs = [
                SELECT Object__c, Status__c
                FROM Evisort_Export_Object__c
                ORDER BY Object__c
            ];
            CSUtils.itShouldBe('Number of objects', 2, newObjs.size());
            CSUtils.itShouldBe('First Object', 'Account', newObjs[0].Object__c);
            CSUtils.itShouldBe('Status of First Object', Constants.EXPORT_RUNNING, newObjs[0].Status__c);
            CSUtils.itShouldBe('Second Object', 'Opportunity', newObjs[1].Object__c);
            CSUtils.itShouldBe('Status of Second Object', Constants.EXPORT_RUNNING, newObjs[1].Status__c);
        }
    }

    @isTest
    static void testCancelExport() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id FROM Evisort_Export_Filter__c LIMIT 1];
            List<Evisort_Export_Object__c> objs = new List<Evisort_Export_Object__c>();
            objs.add(TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, 'WORD,EXCEL'));
            objs.add(TestFactory.getExportObject('Account', Constants.EXPORT_COMPLETE, null));
            objs[0].Evisort_Export_Filter__c = eef.Id;
            insert objs;

            Test.startTest();

            Boolean result = ExportController.cancelExport();

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> newObjs = [
                SELECT Object__c, Status__c
                FROM Evisort_Export_Object__c
                ORDER BY Object__c
            ];
            CSUtils.itShouldBe('Number of objects', 2, newObjs.size());
            CSUtils.itShouldBe('First Object', 'Account', newObjs[0].Object__c);
            CSUtils.itShouldBe('Status of First Object', Constants.EXPORT_COMPLETE, newObjs[0].Status__c);
            CSUtils.itShouldBe('Second Object', 'Opportunity', newObjs[1].Object__c);
            CSUtils.itShouldBe('Status of Second Object', Constants.EXPORT_CANCELLED, newObjs[1].Status__c);
        }
    }

   	@isTest
    static void testGetNextDocumentBatch() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id FROM Evisort_Export_Filter__c LIMIT 1];
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            List<Evisort_Export_Document__c> docs = new List<Evisort_Export_Document__c>();
            for (Integer i = 0; i < 10; i++) {
                docs.add(TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_QUEUED, null, null, (i + 1) * 1000));
            }
            insert docs;

            Test.startTest();

            ExportService.getNextDocumentBatch();

            Test.stopTest();

            List<Log__c> logs = [SELECT Id FROM Log__c];
            CSUtils.itShouldBe('No Logs should have been made', 0, logs.size());
        }
    }

    @isTest
    private static void testCompleteExport() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id FROM Evisort_Export_Filter__c LIMIT 1]; 
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            List<Evisort_Export_Document__c> docs = new List<Evisort_Export_Document__c>();
            for (Integer i = 0; i < 10; i++) {
                docs.add(TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_COMPLETED, null, null, (i + 1) * 1000));
            }
            insert docs;

            Test.startTest();

            ExportService.getNextDocumentBatch();

            Test.stopTest();

            Evisort_Export_Object__c newEEO = [SELECT Status__c FROM Evisort_Export_Object__c WHERE Id = :eeo.Id];
            CSUtils.itShouldBe('Final Status', Constants.EXPORT_COMPLETE, newEEO.Status__c);
        }
    }

    @isTest
    private static void testDoDocumentExportPositive() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
           	Evisort_Export_Filter__c eef = [SELECT Id FROM Evisort_Export_Filter__c LIMIT 1]; 
            
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            ContentVersion cv = TestFactory.getContentVersion('TestContent', 'Test Data Content', o.Id);
            insert cv;

            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;

            Evisort_Export_Document__c eed = TestFactory.getExportDocument(
                eeo.Id,
                Constants.EXPORT_QUEUED,
                cv.Id,
                o.Id,
                null
            );
            eed.Record_Name__c = 'test';
            insert eed;

            CalloutMock mock = new CalloutMock('{"token": "faketokenhere"}');
            mock.addResponse(202, '');
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(eed.Id, 'Evisort_Export_Document__c');
            item.recordId__c = eeo.Id;
            ExportService.doDocumentExport(item);

            Test.stopTest();

            CSUtils.itShouldBe('Final Status', 'COMPLETED', item.Status__c);

        }
    }

    @isTest
    private static void testDoMetadataExport() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Map<Id,QueueItem__c> mapOfQueueStatus = new Map<Id, QueueItem__c>();

            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            Evisort__c evs = TestFactory.getEvisortRecord(o.Id, '1111111');
            evs.External_ID__c = '111111';
            insert evs;
            
            Domain.bypassTriggers(QueueItemProcessor.class);
            Domain.bypassTriggers(ContentVersionDomain.class);
            
            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Object__c = 'MetadataExport';
            queueItem.RecordId__c = evs.Id;
            queueItem.Process_After__c = Datetime.now() +1;
            insert queueItem;
                       
          	String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            mock.addResponse(204, '{"status": "No Content", "StatusCode": "204"}');
            mock.addResponse(400, '{"status": "No Content", "StatusCode": "400"}');
            mock.addResponse(200, '{"status": "No Content", "StatusCode": "200"}');
            mock.addResponse(404, '{"status": "No Content", "StatusCode": "404"}');
            Test.setMock(HttpCalloutMock.class, mock);
                                    
            Test.startTest();
            ExportService.doMetadataExport(queueItem, mapOfQueueStatus, 1, 1, new List<String>()); 
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testDoMetadataExportWithError() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Map<Id,QueueItem__c> mapOfQueueStatus = new Map<Id, QueueItem__c>();

            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            Evisort__c evs = TestFactory.getEvisortRecord(o.Id, '1111111');
            evs.External_ID__c = '111111';
            insert evs;
            
            Domain.bypassTriggers(QueueItemProcessor.class);
            Domain.bypassTriggers(ContentVersionDomain.class);
            
            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Object__c = 'MetadataExport';
            queueItem.RecordId__c = evs.Id;
            queueItem.Status__c = 'NEW';
            queueItem.Process_After__c = Datetime.now();
            insert queueItem;
                       
          	String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            mock.addResponse(204, '{"status": "No Content", "StatusCode": "204"}');
            mock.addResponse(400, '{"status": "No Content", "StatusCode": "400"}');
            mock.addResponse(200, '{"status": "No Content", "StatusCode": "200"}');
            mock.addResponse(404, '{"status": "No Content", "StatusCode": "404"}');
            Test.setMock(HttpCalloutMock.class, mock);
                                    
            Test.startTest();
            ExportService.doMetadataExport(queueItem, mapOfQueueStatus, 1, 1, new List<String>()); 
            Test.stopTest();
            
            List<log__c> errorList = [SELECT Id,ClassName__c,Message__c,ObjectName__c From Log__c Where ClassName__c = 'ExportService.doMetadataExport'];
            CSUtils.itShouldNotBe('Size Of Error Record', 0, errorList.size()); 
        }
    }

    @isTest
    private static void testDoDocumentExportNegative() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            ContentVersion cv = TestFactory.getContentVersion('TestContent', 'Test Data Content', o.Id);
            insert cv;

            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            insert eeo;

            Evisort_Export_Document__c eed = TestFactory.getExportDocument(
                eeo.Id,
                Constants.EXPORT_QUEUED,
                cv.Id,
                o.Id,
                null
            );
            insert eed;

            CalloutMock mock = new CalloutMock('{"token": "faketokenhere"}');
            mock.addResponse(404, '');
            mock.addResponse(400, '{"error": "Could not upload file"}');
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(eeo.Id, 'Evisort_Export_Document__c');
            ExportService.doDocumentExport(item);
            
            eed.Record_Name__c = 'Opportunity';
            update eed;
            
            Evisort_Export_Document__c eed2 = TestFactory.getExportDocument(
                eeo.Id,
                Constants.EXPORT_QUEUED,
                cv.Id,
                o.Id,
                null
            );
            eed2.Record_Name__c = 'document 2';
            insert eed2;
            
            ExportService.doDocumentExport(item);

            Test.stopTest();
            
            CSUtils.itShouldBe('Final Status', 'ERROR', item.Status__c);
        }
    }
    
    @isTest
    static void testGetLibraryName() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String libraryName = '';
            ContentWorkspace cw = TestFactory.getContentWorkspace();
            insert cw;
            
            Set<Id> libraryIds = new Set<Id>{cw.Id};
            EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
            List<ContentWorkspace> contentList =  eeoSelector.getLibraryName(libraryIds);
            libraryName = contentList[0].Name;
            
            CSUtils.itShouldBe('Library Name : ', 'TEST CLASS', libraryName);
        }
    }
	
    
    @isTest
    private static void testEvisortDocumentRestControllerPositive() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            ContentVersion cv = TestFactory.getContentVersion('Test Content', 'Test Data Content', o.Id);
            insert cv;
            
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId=: cv.Id ];

            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            insert eeo;
            
            Evisort_Export_Document__c eed = TestFactory.getExportDocument(
                eeo.Id,
                Constants.EXPORT_QUEUED,
                cv.Id,
                o.Id,
                null
            );
            eed.ContentDocument__c = String.valueOf(cd.Id);
            eed.Record_Name__c = 'Testing';
            insert eed; 
            
            Evisort__c evs = TestFactory.getEvisortRecord(o.Id, '1111111');
            
            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Object__c = 'Evisort_Export_Object__c';
            queueItem.RecordId__c = eeo.Id;
            queueItem.IntegrationID__c = o.Id;
            queueItem.Data__c = JSON.serialize(new List<String>{'WORD'});
            insert queueItem;
            
            String myJSON = '{"status": "Completed", "evisortId": "291", "documentId" : "'+eed.id+'"}';
       
            RestRequest request = new RestRequest();
            request.requestUri ='';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueof(myJSON);
            
            RestContext.request = request;
            Test.startTest();
            EvisortDocumentRestController.updateDocumentstatus();
            Test.stopTest();
            List<Evisort__c> evisortRecord =  [SELECT Id, Name, External_ID__c, Record_ID__c FROM Evisort__c];
            Evisort_Export_Document__c exportDocument = [SELECT Id, Name, Evisort_Export_Object__c, Evisort__c, Status__c FROM Evisort_Export_Document__c];
            CSUtils.itShouldBe('No Of Record ', 1, evisortRecord.size());
            CSUtils.itShouldBe('Evisort Id Not Null ', evisortRecord[0].Id, exportDocument.Evisort__c);
            CSUtils.itShouldBe('Document Status Completed ', 'Completed', exportDocument.Status__c);   
        }
    }
    
    @isTest
    private static void testEvisortDocumentRestControllerNegative() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Domain.bypassTriggers(ContentVersionDomain.class);

            ContentVersion cv = TestFactory.getContentVersion('Test Content', 'Test Data Content', o.Id);
            insert cv;
            
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId=: cv.Id ];

            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            insert eeo;
            
            Evisort_Export_Document__c eed = TestFactory.getExportDocument(
                eeo.Id,
                Constants.EXPORT_QUEUED,
                cv.Id,
                o.Id,
                null
            );
            eed.ContentDocument__c = String.valueOf(cd.Id);
            eed.Record_Name__c = 'Testing';
            insert eed; 
            
            Evisort__c evs = TestFactory.getEvisortRecord(o.Id, '1111111');
            
            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Object__c = 'Evisort_Export_Object__c';
            queueItem.RecordId__c = eeo.Id;
            queueItem.IntegrationID__c = o.Id;
            queueItem.Data__c = JSON.serialize(new List<String>{'WORD'});
            insert queueItem;
            
            String myJSON = '{"status": "Errored", "evisortId": "291", "documentId" : "'+eed.id+'"}';
       
            RestRequest request = new RestRequest();
            request.requestUri ='';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueof(myJSON);
            
            RestContext.request = request;
            Test.startTest();
            EvisortDocumentRestController.updateDocumentstatus();
            Test.stopTest();
            List<Evisort__c> evisortRecord =  [SELECT Id, Name, External_ID__c, Record_ID__c FROM Evisort__c];
            Evisort_Export_Document__c exportDocument = [SELECT Id, Name, Evisort_Export_Object__c, Evisort__c, Status__c FROM Evisort_Export_Document__c];
            CSUtils.itShouldBe('No Of Record ', 1, evisortRecord.size());
            CSUtils.itShouldBe('Evisort Id Not Null ', evisortRecord[0].Id, exportDocument.Evisort__c);
            CSUtils.itShouldBe('Document Status Errored ', 'Errored', exportDocument.Status__c);   
        }
    }
    
    @isTest
    static void testGetObjectListWithLabel() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) { 
            Map<String, object> conVerAssociatedFields = ExportController.getContentVersionAssociatedField('Evisort__c');
            Map<String, object> mapOfobjectsWithLabel = ExportController.getObjectListWithLabel();
            CSUtils.itShouldNotBe('Objects List with LAbel Not Null', null, mapOfobjectsWithLabel);
        }
    }
    

    @isTest
    static void testmappingFields() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Evisort_Field_Definition__c eef = [SELECT Name, Id, Data_Type__c, Field_Type__c, Label__c, Picklist_Values__c, Section_Name__c FROM Evisort_Field_Definition__c WHERE Label__c = 'Comments' LIMIT 1];
            String documentMappingFields = '{ "ObjectName": "Account", "isLegacy": true, "mappings": [ { "id": "", "documentFieldId": "'+eef.Id+'", "name": "Comments", "label": "Comments", "fieldType": "Field", "dataType": "Text", "isActive": true, "documentFieldMappingId": "", "evisortFieldDataType": "Text", "salesforceField": "Name", "fieldLabel": "Name" , "SalesforceDataType": "STRING" }], "newRecord": true }';
            ExportController.mappingFields(documentMappingFields);
            List<Document_Field_Sync_Mapping__c> documentFieldSyncMappingRecord =  [SELECT Id, Name, Field_Label__c, Salesforce_Field_Name__c, Evisort_Document_Field_Id__c, Evisort_Export_Filter__c, Evisort_Document_Field_Name__c, Evisort_Field_Definition__c, Object__c FROM Document_Field_Sync_Mapping__c WHERE Object__c = 'Account'];
            CSUtils.itShouldBe('Size Of Record ', 1, documentFieldSyncMappingRecord.size());
            CSUtils.itShouldBe('Object Name ', 'Account', documentFieldSyncMappingRecord[0].Object__c);
        }
    }

    @isTest
    static void testDocumentFieldSyncMappingRecord() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
                List<AdminMsg.SyncFieldAggregateResultWrapper> result = ExportController.getDocumentFieldSyncMappingRecord();
                CSUtils.itShouldNotBe('Size Of Record ', 0, result.size());
                CSUtils.itShouldNotBe('Object', 0, result.size());
        }
    }

    @isTest
    static void testMappingDataTypes() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Map<String,String> result = ExportController.getMappingDataTypes();
            CSUtils.itShouldNotBe('Map Not Null', null, result.keySet());
        }
    }

    @isTest
    static void testDeleteDocumentFieldSyncMappingRecord() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            List<Document_Field_Sync_Mapping__c> documentMappingRecordBeforeDelete =  [SELECT Id, Name, Field_Label__c, Salesforce_Field_Name__c, Evisort_Document_Field_Id__c, Evisort_Export_Filter__c, Evisort_Document_Field_Name__c, Evisort_Field_Definition__c, Object__c FROM Document_Field_Sync_Mapping__c WHERE Object__c = 'Opportunity'];
            ExportController.deleteDocumentFieldSyncMappingRecord('Opportunity');
            List<Document_Field_Sync_Mapping__c> documentMappingRecordAfterDelete =  [SELECT Id, Name, Field_Label__c, Salesforce_Field_Name__c, Evisort_Document_Field_Id__c, Evisort_Export_Filter__c, Evisort_Document_Field_Name__c, Evisort_Field_Definition__c, Object__c FROM Document_Field_Sync_Mapping__c WHERE Object__c = 'Opportunity'];
            CSUtils.itShouldBe(' Size Of Record Before Delete', 2, documentMappingRecordBeforeDelete.size());
            CSUtils.itShouldBe(' Size Of Record After Delete', 0, documentMappingRecordAfterDelete.size());
        }
    }

    @isTest
    static void testDocumentMappingFields() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            List<AdminMsg.DocumentFieldSyncMappingRecord> result = ExportController.getDocumentMappingFields('Opportunity');
            CSUtils.itShouldBe(' Size Of Record on Edit', 2, result.size());
            CSUtils.itShouldBe(' objectName', 'Opportunity', result[0].objectName);
            CSUtils.itShouldBe(' Document Field Name', 'Description', result[1].evisortDocumentFieldName);

        }
    }

    @isTest
    static void testObjectFieldMetaData() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            List<Map<String, String>> result = sObjectFieldMappingController.getObjectFieldMetaData('Opportunity');
            CSUtils.itShouldNotBe('Map Not Null', null, result.size());
        }
    }

    @isTest
    static void testCalculateObjectAttachement() {
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id, Name, File_Filter_Body__c, Is_Legacy__c, Is_Library__c, Object_Filter_Body__c, Object__c FROM Evisort_Export_Filter__c WHERE Object__c = 'Opportunity' LIMIT 1];                  
            String FileFilterBody='{"rows":[{"fieldName":"FileExtension","fieldLabel":"File Extension","fieldType":"STRING","operator":"Contains","value":"WORD","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1,"indexToShow":1},{"fieldName":"Title","fieldLabel":"Title","fieldType":"STRING","operator":"Contains","value":"test","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":2},{"fieldName":"ContentSize","fieldLabel":"Size","fieldType":"INTEGER","operator":"Greater Than Equals To","value":"0","isPicklist":false,"fieldTypeLabel":"INTEGER","fieldSOAPType":"INTEGER","sequence":3}],"condition":"OR"}';
            eef.File_Filter_Body__c = FileFilterBody;
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_COMPLETE, null);
            eeo.Evisort_Export_Filter__c = eef.Id;
            insert eeo;
            
            Evisort_Export_Document__c docs = new Evisort_Export_Document__c();
            docs = TestFactory.getExportDocument(eeo.Id, Constants.EXPORT_QUEUED, null, null, (1) * 1000);
            insert docs;
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            Domain.bypassTriggers(ContentVersionDomain.class);            
            String body = 'Data';
            Attachment attach=new Attachment();   	
            attach.Name = 'Unit Test Attachment';
            Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
            attach.body = EncodingUtil.base64Decode(body);
            attach.ContentType = 'application/msword';
            attach.parentId=o.Id;
            insert attach;
            
            
            ExportMsg.ExportObject obj = new ExportMsg.ExportObject();
            obj.objectLabel = 'Opportunity';
            obj.objectFilterBody = eef.Object_Filter_Body__c;
            obj.fileFilterBody = eef.File_Filter_Body__c;
            Test.startTest();
            
            Boolean result = ExportController.calculateObject(JSON.serialize(obj));
            
            Test.stopTest();
            
            CSUtils.itShouldBe('Result', true, result);
            List<Evisort_Export_Object__c> objs = [
                SELECT Object__c, Number_of_Documents__c, Total_Size__c, Status__c
                FROM Evisort_Export_Object__c
            ];            
            CSUtils.itShouldBe('Number of objects', 2, objs.size());
            CSUtils.itShouldBe('Object Name', 'Opportunity', objs[0].Object__c);
            CSUtils.itShouldBe('Status', Constants.EXPORT_READY, objs[0].Status__c);
        }
    }

    @isTest
    static void testEvisortAttachmentRestControllerPositive() {
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            
            Domain.bypassTriggers(ContentVersionDomain.class);
            String body = 'Data';
            Attachment attach = new Attachment();   	
            attach.Name = 'Unit Test Attachment';
            Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
            attach.body = EncodingUtil.base64Decode(body);
            attach.ContentType = 'application/msword';
            attach.parentId=o.Id;
            insert attach;
            
            Attachment cd = [SELECT Id FROM Attachment WHERE Id =: attach.Id ];
            
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            insert eeo;
            
            Evisort_Export_Document__c eed = TestFactory.getExportDocument(
                eeo.Id,
                Constants.EXPORT_QUEUED,
                attach.Id,
                o.Id,
                null
            );
            eed.ContentDocument__c = String.valueOf(cd.Id);
            eed.Record_Name__c = 'Testing';
            insert eed; 
            
            Evisort__c evs = TestFactory.getEvisortRecord(o.Id, '1111111');
            
            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Object__c = 'Evisort_Export_Object__c';
            queueItem.RecordId__c = eeo.Id;
            queueItem.IntegrationID__c = o.Id;
            queueItem.Data__c = JSON.serialize(new List<String>{'WORD'});
            insert queueItem;
            
            String myJSON = '{"status": "Completed", "evisortId": "291", "documentId" : "'+eed.id+'"}';
            
            RestRequest request = new RestRequest();
            request.requestUri ='';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueof(myJSON);
            
            RestContext.request = request;
            Test.startTest();
            EvisortDocumentRestController.updateDocumentstatus();
            Test.stopTest();
            List<Evisort__c> evisortRecord =  [SELECT Id, Name, External_ID__c, Record_ID__c FROM Evisort__c];
            Evisort_Export_Document__c exportDocument = [SELECT Id, Name, Evisort_Export_Object__c, Evisort__c, Status__c FROM Evisort_Export_Document__c];
            CSUtils.itShouldBe('No Of Record ', 1, evisortRecord.size());
            CSUtils.itShouldBe('Evisort Id Not Null ', evisortRecord[0].Id, exportDocument.Evisort__c);
            CSUtils.itShouldBe('Document Status Completed ', 'Completed', exportDocument.Status__c);   
        }
    }
}