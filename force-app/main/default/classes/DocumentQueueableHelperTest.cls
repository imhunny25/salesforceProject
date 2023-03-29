@isTest
private class DocumentQueueableHelperTest {
    @TestSetup
    static void testSetup() {
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

            Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
            status.Authenticated__c = true;
            status.Authentication_Date__c = Datetime.now();
            status.Sync_Criteria__c = true;
            status.Root_Folder__c = 'Salesforce';
            upsert status;
        }
    }

    /**
     * Create the Field Values based on the Definitions in the testSetup method
     * This is not wanted by all methods, so we don't actually do it in the testSetup
     * This is intended to be called inside a System.runAs() block and use the definition list above
     * @param  evisortId Evisort Record ID
     */
    static void createFieldValues(Id evisortId) {
        List<Evisort_Field_Definition__c> defs = [SELECT Id, Name FROM Evisort_Field_Definition__c ORDER BY Name];
        CSUtils.itShouldBe('Number of Field Definitions', 7, defs.size());

        List<Evisort_Field_Value__c> values = new List<Evisort_Field_Value__c>();
        values.add(TestFactory.getFieldValue(evisortId, defs[0].Id));
        values[0].Checkbox_Field__c = true;
        values.add(TestFactory.getFieldValue(evisortId, defs[1].Id));
        values[1].Date_Field__c = Date.newInstance(2020, 5, 12);
        values.add(TestFactory.getFieldValue(evisortId, defs[2].Id));
        values[2].Picklist_Value_Selected__c = 'NewValue1$@#NewValue2';
        values.add(TestFactory.getFieldValue(evisortId, defs[3].Id));
        values[3].Number_Field__c = 42;
        values.add(TestFactory.getFieldValue(evisortId, defs[4].Id));
        values[4].Picklist_Value_Selected__c = 'NewValue1';
        values.add(TestFactory.getFieldValue(evisortId, defs[5].Id));
        values[5].Text_Field__c = 'Provision Text';
        values.add(TestFactory.getFieldValue(evisortId, defs[6].Id));
        values[6].Text_Field__c = 'Field Text';
        insert values;
    }

    @isTest
    static void testUploadDocumentPositive() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            ContentVersion cv = TestFactory.getContentVersion('Unit Test Content', 'Content Here', o.Id);
            insert cv;

            ContentVersion newCV = [SELECT Evisort__c FROM ContentVersion WHERE Id = :cv.Id];

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"status": "IN_PROGRESS", "evisortId": "291"}';
            mock.addResponse(202, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(cv.Id, 'ContentVersion');
            DocumentQueueableHelper.uploadDocument(item);

            Test.stopTest();

        }
    }

    @isTest
    static void testUploadDocumentNegative() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            ContentVersion cv = TestFactory.getContentVersion('Unit Test Content', 'Content Here', o.Id);
            insert cv;

            ContentVersion newCV = [SELECT Evisort__c FROM ContentVersion WHERE Id = :cv.Id];
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"error": "Could not upload file"}';
            mock.addResponse(400, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(cv.Id, 'ContentVersion');
            DocumentQueueableHelper.uploadDocument(item);

            Test.stopTest();

        }
    }

    @isTest
    static void testGetRecordData() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];

            Test.startTest();

            DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(o.id);

            Test.stopTest();

            CSUtils.itShouldBe('Object Name', 'Opportunity', recordData.objectName);
            CSUtils.itShouldBe('Record Name', 'Unit Test Opportunity', recordData.name);
            CSUtils.itShouldBe('Parent Directory', 'Unit Test Account', recordData.parentDirectory);
        }
    }

    @isTest
    static void testGetUploadPathOpportunity() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            o.Name = 'Slashes 1/15';
            update o;

            DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(o.id);

            Test.startTest();

            String uploadPath = DocumentQueueableHelper.getUploadPath(recordData);

            Test.stopTest();

            CSUtils.itShouldbe('Upload Path', 'Salesforce/Unit Test Account/Slashes 1-15/', uploadPath);
        }
    }

    @isTest
    static void testGetUploadPathContract() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Contract c = [SELECT Id, ContractNumber FROM Contract LIMIT 1];
            DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(c.id);

            Test.startTest();

            String uploadPath = DocumentQueueableHelper.getUploadPath(recordData);

            Test.stopTest();

            CSUtils.itShouldbe('Upload Path', 'Salesforce/Unit Test Account/' + c.ContractNumber + '/', uploadPath);
        }
    }

    @isTest
    static void testGetUploadPathAccount() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Account a = [SELECT Id FROM Account LIMIT 1];
            DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(a.id);

            Test.startTest();

            String uploadPath = DocumentQueueableHelper.getUploadPath(recordData);

            Test.stopTest();

            CSUtils.itShouldbe('Upload Path', 'Salesforce/Unit Test Account/', uploadPath);
        }
    }

    @isTest
    static void testCanProcessDocumentPositive() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(o.id);
            recordData.recordTypeName = 'Record Type 2';

            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            settings.Sync_Criteria__c = false;
            upsert settings;

            Evisort_Document_Sync_Criteria__c criteria = TestFactory.getSyncCriteriaSettings(
                'Opportunity',
                null,
                'Record Type 1,Record Type 2'
            );
            insert criteria;

            Test.startTest();

            Boolean result = DocumentQueueableHelper.canProcessDocument(recordData);

            Test.stopTest();

            CSUtils.itShouldBe('Can Process Record', true, result);
        }
    }

    @isTest
    static void testCanProcessDocumentNegative() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
            DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(o.id);
            recordData.recordTypeName = 'Record Type 3';

            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            settings.Sync_Criteria__c = false;
            upsert settings;

            Evisort_Document_Sync_Criteria__c criteria = TestFactory.getSyncCriteriaSettings(
                'Opportunity',
                null,
                'Record Type 1,Record Type 2'
            );
            insert criteria;

            Test.startTest();

            Boolean result = DocumentQueueableHelper.canProcessDocument(recordData);

            Test.stopTest();

            CSUtils.itShouldBe('Cannot Process Record', false, result);
        }
    }

    @isTest
    static void testCheckEvisortRecord() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "status": "READY", "evisortId": "123", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [ { "value": "Yes" } ] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" }';
            mock.addResponse(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(evisortRecords[0].Id, 'Evisort__c');
            DocumentQueueableHelper.checkEvisortRecord(item);

            Test.stopTest();

            List<Evisort_Field_Value__c> values = [
                SELECT
                    Id,
                    Evisort_Field_Definition__r.Name,
                    Checkbox_Field__c,
                    Date_Field__c,
                    Number_Field__c,
                    Picklist_Value_Selected__c,
                    Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortRecords[0].Id
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Field Values', 7, values.size());
            CSUtils.itShouldBe('Boolean Field', true, values[0].Checkbox_Field__c);
            CSUtils.itShouldBe('Date Field', Date.newInstance(2020, 3, 31), values[1].Date_Field__c);
            CSUtils.itShouldBe('Multi Picklist Field', 'Value1$@#Value2', values[2].Picklist_Value_Selected__c);
            CSUtils.itShouldBe('Number Field', 100, values[3].Number_Field__c);
            CSUtils.itShouldBe('Picklist Field', 'Value1', values[4].Picklist_Value_Selected__c);
            CSUtils.itShouldBe(
                'Provision',
                'For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.',
                values[5].Text_Field__c
            );
            CSUtils.itShouldBe(
                'Text Field',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                values[6].Text_Field__c
            );

            List<Evisort__c> newEvisort = [SELECT Id, Document_Status__c FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldbe('Number of Evisort Records after call', 1, newEvisort.size());
            CSUtils.itShouldBe('Status of Evisort Record', 'Ready', newEvisort[0].Document_Status__c);
        }
    }

    @isTest
    static void testCheckEvisortRecordWithRemovedField() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "status": "READY", "evisortId": "123", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" }';
            mock.addResponse(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());

            createFieldValues(evisortRecords[0].Id);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(evisortRecords[0].Id, 'Evisort__c');
            DocumentQueueableHelper.checkEvisortRecord(item);

            Test.stopTest();

            List<Evisort_Field_Value__c> values = [
                SELECT
                    Id,
                    Evisort_Field_Definition__r.Name,
                    Checkbox_Field__c,
                    Date_Field__c,
                    Number_Field__c,
                    Picklist_Value_Selected__c,
                    Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortRecords[0].Id
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Field Values', 6, values.size());
            CSUtils.itShouldBe(
                'First field is Date Field, not Boolean Field',
                'Date Field',
                values[0].Evisort_Field_Definition__r.Name
            );
        }
    }

    @isTest
    static void testCheckForNewFields() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 7, "fields": [ { "label": "Date Field", "name": "Date Field", "type": "datetime", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Text Field", "name": "Text Field", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "New Text Field", "name": "New Text Field", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Number Field", "name": "Number Field", "type": "number", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Multi Picklist Field", "name": "Multi Picklist Field", "type": "multi_select", "helpText": null, "active": true, "allowedValues": [ "Value1", "Value2" ], "section": { "name": "General Information" } }, { "label": "Picklist Field", "name": "Picklist Field", "type": "single_select", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Boolean Field", "name": "Boolean Field", "type": "boolean", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } } ] }';
            mock.addResponse(200, mockJson);
            String mockJson2 = '{ "count": 2, "provisions": [ { "name": "Provision", "provisionTags": [] }, { "name": "New Provision", "provisionTags": [] } ] }';
            mock.addResponse(200, mockJson2);
            Test.setMock(HttpCalloutMock.class, mock);

            Set<String> fieldNames = new Set<String>{ 'Text Field', 'New Text Field' };
            Set<String> provisionNames = new Set<String>{ 'Provision', 'New Provision' };

            Test.startTest();

            Boolean checkResult = DocumentQueueableHelper.checkForNewFields(fieldNames, provisionNames);

            Test.stopTest();

            CSUtils.itShouldBe('Result', true, checkResult);

            List<Evisort_Field_Definition__c> testFieldDefs = [
                SELECT Id, Name
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Field'
                ORDER BY Name
            ];
            CSUtils.itShouldBe('Evisort Field Definition Records', 7, testFieldDefs.size());
            CSUtils.itShouldBe('New Text Field Added', 'New Text Field', testFieldDefs[3].Name);

            List<Evisort_Field_Definition__c> testProvisionDefs = [
                SELECT Id, Name
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Provision'
                ORDER BY Name
            ];
            CSUtils.itShouldBe('Evisort Provision Records', 2, testProvisionDefs.size());
            CSUtils.itShouldBe('New Provision Added', 'New Provision', testProvisionDefs[0].Name);
        }
    }

    @isTest
    static void testDoDocumentSync() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 2, "next": null, "previous": null, "documents": [ { "status": "READY", "evisortId": "123", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [ { "value": "Yes" } ] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" }, { "status": "READY", "evisortId": "456", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [ { "value": "Yes" } ] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" } ] }';
            mock.addResponse(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());

            Test.startTest();

            System.enqueueJob(new DocumentSyncQueueable());

            Test.stopTest();

            List<Evisort_Field_Value__c> values = [
                SELECT
                    Id,
                    Evisort_Field_Definition__r.Name,
                    Checkbox_Field__c,
                    Date_Field__c,
                    Number_Field__c,
                    Picklist_Value_Selected__c,
                    Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortRecords[0].Id
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Field Values', 7, values.size());
            CSUtils.itShouldBe('Boolean Field', true, values[0].Checkbox_Field__c);
            CSUtils.itShouldBe('Date Field', Date.newInstance(2020, 3, 31), values[1].Date_Field__c);
            CSUtils.itShouldBe('Multi Picklist Field', 'Value1$@#Value2', values[2].Picklist_Value_Selected__c);
            CSUtils.itShouldBe('Number Field', 100, values[3].Number_Field__c);
            CSUtils.itShouldBe('Picklist Field', 'Value1', values[4].Picklist_Value_Selected__c);
            CSUtils.itShouldBe(
                'Provision',
                'For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.',
                values[5].Text_Field__c
            );
            CSUtils.itShouldBe(
                'Text Field',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                values[6].Text_Field__c
            );
        }
    }

    @isTest
    static void testDoDocumentSyncWithNextURL() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 2, "next": null, "previous": null, "documents": [ { "status": "READY", "evisortId": "123", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [ { "value": "Yes" } ] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" }, { "status": "READY", "evisortId": "456", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [ { "value": "Yes" } ] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" } ] }';
            mock.addResponse(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());

            Test.startTest();

            System.enqueueJob(
                new DocumentSyncQueueable(
                    'https://api-portal-developers.evisort.com/v1/documents?modifiedSince=2020-11-01T18:29:58Z&pageSize=10&page=2'
                )
            );

            Test.stopTest();

            List<Evisort_Field_Value__c> values = [
                SELECT
                    Id,
                    Evisort_Field_Definition__r.Name,
                    Checkbox_Field__c,
                    Date_Field__c,
                    Number_Field__c,
                    Picklist_Value_Selected__c,
                    Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortRecords[0].Id
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Field Values', 7, values.size());
            CSUtils.itShouldBe('Boolean Field', true, values[0].Checkbox_Field__c);
            CSUtils.itShouldBe('Date Field', Date.newInstance(2020, 3, 31), values[1].Date_Field__c);
            CSUtils.itShouldBe('Multi Picklist Field', 'Value1$@#Value2', values[2].Picklist_Value_Selected__c);
            CSUtils.itShouldBe('Number Field', 100, values[3].Number_Field__c);
            CSUtils.itShouldBe('Picklist Field', 'Value1', values[4].Picklist_Value_Selected__c);
            CSUtils.itShouldBe(
                'Provision',
                'For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.',
                values[5].Text_Field__c
            );
            CSUtils.itShouldBe(
                'Text Field',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                values[6].Text_Field__c
            );

            List<Evisort__c> newEvisort = [SELECT Id, Document_Status__c FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldbe('Number of Evisort Records after call', 1, newEvisort.size());
            CSUtils.itShouldBe('Status of Evisort Record', 'Ready', newEvisort[0].Document_Status__c);
        }
    }

    @isTest
    static void testCheckForRemovedField() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            // This JSON has "Boolean Field" completely removed
            String mockJson = '{ "count": 1, "next": null, "previous": null, "documents": [ { "status": "READY", "evisortId": "123", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" } ] }';
            mock.addResponse(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());

            createFieldValues(evisortRecords[0].Id);

            Test.startTest();

            System.enqueueJob(new DocumentSyncQueueable());

            Test.stopTest();

            List<Evisort_Field_Value__c> values = [
                SELECT
                    Id,
                    Evisort_Field_Definition__r.Name,
                    Checkbox_Field__c,
                    Date_Field__c,
                    Number_Field__c,
                    Picklist_Value_Selected__c,
                    Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortRecords[0].Id
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Field Values', 6, values.size());
            CSUtils.itShouldBe(
                'First field is Date Field, not Boolean Field',
                'Date Field',
                values[0].Evisort_Field_Definition__r.Name
            );
        }
    }

    @isTest
    static void testCheckForBlankField() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            // This JSON has "Boolean Field" with an empty value
            String mockJson = '{ "count": 1, "next": null, "previous": null, "documents": [ { "status": "READY", "evisortId": "123", "docId": "0681k000001a8GvAAI", "dateModified": "2020-11-20T23:33:28.593914+00:00", "fields": [ { "name": "Multi Picklist Field", "values": [ { "value": "Value1" }, { "value": "Value2" } ] }, { "name": "Picklist Field", "values": [ { "value": "Value1" } ] }, { "name": "Text Field", "values": [ { "value": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." } ] }, { "name": "Date Field", "values": [ { "value": "2020-03-31" } ] }, { "name": "Number Field", "values": [ { "value": 100 } ] }, { "name": "Boolean Field", "values": [] } ], "provisions": [ { "name": "Provision", "content": [ { "text": "For any and all Open Source Software (OSS) specified in Section 2.4, provide a link to the applicable license.", "score": 1 } ] } ], "name": "test_40.docx", "path": "Documents/Test Account/Test Opportunity" } ] }';
            mock.addResponse(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());

            createFieldValues(evisortRecords[0].Id);

            Test.startTest();

            System.enqueueJob(new DocumentSyncQueueable());

            Test.stopTest();

            List<Evisort_Field_Value__c> values = [
                SELECT
                    Id,
                    Evisort_Field_Definition__r.Name,
                    Checkbox_Field__c,
                    Date_Field__c,
                    Number_Field__c,
                    Picklist_Value_Selected__c,
                    Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortRecords[0].Id
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Field Values', 6, values.size());
            CSUtils.itShouldBe(
                'First field is Date Field, not Boolean Field',
                'Date Field',
                values[0].Evisort_Field_Definition__r.Name
            );
        }
    }

    @isTest
    static void testSendValuesPositive() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            mock.addResponse(204, '');
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            createFieldValues(evisortId);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(evisortId, 'Evisort__c');
            item.Process_After__c = Datetime.now().addMinutes(-1);
            DocumentQueueableHelper.sendValues(item);

            Test.stopTest();

            List<Log__c> logs = [SELECT Id FROM Log__c];
            CSUtils.itShouldBe('No Logs should have been made', 0, logs.size());
        }
    }

    @isTest
    static void testSendValuesNegative() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            mock.addResponse(500, '{ "error": "Unit Test Faked Error" }');
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            createFieldValues(evisortId);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(evisortId, 'Evisort__c');
            item.Process_After__c = Datetime.now().addMinutes(-1);
            DocumentQueueableHelper.sendValues(item);

            Test.stopTest();

            List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
            CSUtils.itShouldBe('Error logs created', 1, logs.size());
            CSUtils.itShouldBe('Error message correct', 'Unit Test Faked Error', logs[0].Message__c);
        }
    }

    @isTest
    static void testDeleteDocumentPositive() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            mock.addResponse(204, '');
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            createFieldValues(evisortId);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(evisortId, 'Evisort__c');
            DocumentQueueableHelper.deleteDocument(item);

            Test.stopTest();

            List<Evisort__c> newEvisort = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Evisort Record Deleted', 0, newEvisort.size());

            List<Evisort_Field_Value__c> values = [SELECT Id FROM Evisort_Field_Value__c];
            CSUtils.itShouldBe('Evisort Field Values Deleted', 0, values.size());
        }
    }

    @isTest
    static void testDeleteDocumentNegative() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            mock.addResponse(500, '{ "error": "Unit Test Faked Error" }');
            Test.setMock(HttpCalloutMock.class, mock);

            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            createFieldValues(evisortId);

            Test.startTest();

            QueueItem__c item = TestFactory.getQueueItem(evisortId, 'Evisort__c');
            DocumentQueueableHelper.deleteDocument(item);

            Test.stopTest();

            List<Evisort__c> newEvisort = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Evisort Record Not Deleted', 1, newEvisort.size());

            List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
            CSUtils.itShouldBe('Error logs created', 1, logs.size());
            CSUtils.itShouldBe('Error message correct', 'Unit Test Faked Error', logs[0].Message__c);
        }
    }
}