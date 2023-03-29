@isTest
private class EvisortFieldDefinitionServiceTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            Evisort__c e = TestFactory.getEvisortRecord(o.Id, '123');
            insert e;
        }
    }

    @isTest
    static void testPullNewFields() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 6, "fields": [ { "label": "Test Datetime", "name": "Test Datetime", "type": "datetime", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test String", "name": "Test String", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Number", "name": "Test Number", "type": "number", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Multi Select", "name": "Test Multi Select", "type": "multi_select", "helpText": null, "active": true, "allowedValues": [ "Value1", "Value2" ], "section": { "name": "General Information" } }, { "label": "Test Single Select", "name": "Test Single Select", "type": "single_select", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Checkbox", "name": "Test Checkbox", "type": "boolean", "helpText": null, "active": true, "allowedValues": [], "section": null } ] }';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Field');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testFieldDefs = [
                SELECT Id, Name, Data_Type__c, Picklist_Values__c, Section_Name__c
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Field'
                ORDER BY Name
            ];

            CSUtils.itShouldBe('Evisort Field Definition Records', 6, testFieldDefs.size());
            CSUtils.itShouldBe('Boolean is Checkbox', 'Boolean', testFieldDefs[0].Data_Type__c);
            CSUtils.itShouldBe('Checkbox Section Not Set', null, testFieldDefs[0].Section_Name__c);
            CSUtils.itShouldBe('Datetime is Date', 'Date', testFieldDefs[1].Data_Type__c);
            CSUtils.itShouldBe('Multi Select is Multi Picklist', 'Multi Picklist', testFieldDefs[2].Data_Type__c);
            CSUtils.itShouldBe('Multi Select Values', 'Value1,Value2', testFieldDefs[2].Picklist_Values__c);
            CSUtils.itShouldBe('Number is Number', 'Number', testFieldDefs[3].Data_Type__c);
            CSUtils.itShouldBe('Single Select is Picklist', 'Picklist', testFieldDefs[4].Data_Type__c);
            CSUtils.itShouldBe('String is Text', 'Text', testFieldDefs[5].Data_Type__c);
            CSUtils.itShouldBe('String Section Set', 'General Information', testFieldDefs[5].Section_Name__c);
        }
    }

    @isTest
    static void testPullNewProvisionsPositive() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"count": 5,"provisions": [{"name": "Change of Control","provisionTags": []},{"name": "Confidentiality","provisionTags": []},{"name": "Data Breach","provisionTags": []},{"name": "Excluded Information","provisionTags": []},{"name": "Governing Law","provisionTags": []}]}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Provision');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testProvisionDefs = [
                SELECT Id, Name, isActive__c
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Provision'
            ];

            CSUtils.itShouldBe('Evisort Provision Records', 5, testProvisionDefs.size());
        }
    }

    @isTest
    static void testPullNewFieldsAndProvisions() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 6, "fields": [ { "label": "Test Datetime", "name": "Test Datetime", "type": "datetime", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test String", "name": "Test String", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Number", "name": "Test Number", "type": "number", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Multi Select", "name": "Test Multi Select", "type": "multi_select", "helpText": null, "active": true, "allowedValues": [ "Value1", "Value2" ], "section": { "name": "General Information" } }, { "label": "Test Single Select", "name": "Test Single Select", "type": "single_select", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Checkbox", "name": "Test Checkbox", "type": "boolean", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } } ] }';
            mock.addResponse(200, mockJson);
            String mockJson2 = '{"count": 5,"provisions": [{"name": "Change of Control","provisionTags": []},{"name": "Confidentiality","provisionTags": []},{"name": "Data Breach","provisionTags": []},{"name": "Excluded Information","provisionTags": []},{"name": "Governing Law","provisionTags": []}]}';
            mock.addResponse(200, mockJson2);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testFieldDefs = [
                SELECT Id, Name
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Field'
            ];

            CSUtils.itShouldBe('Evisort Field Definition Records', 6, testFieldDefs.size());

            List<Evisort_Field_Definition__c> testProvisionDefs = [
                SELECT Id, Name, isActive__c
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Provision'
            ];

            CSUtils.itShouldBe('Evisort Provision Records', 5, testProvisionDefs.size());

            Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();

            CSUtils.itShouldNotBe('Date of Last Field Pull not null', null, status.Last_Field_Pull__c);
        }
    }

    @isTest
    static void testPullUpdatedFields() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 6, "fields": [ { "label": "Test Datetime", "name": "Test Datetime", "type": "datetime", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test String", "name": "Test String", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "New Information" } }, { "label": "Test Number", "name": "Test Number", "type": "string", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Multi Select", "name": "Test Multi Select", "type": "multi_select", "helpText": null, "active": true, "allowedValues": [ "Value1", "Value2", "Value3" ], "section": { "name": "General Information" } }, { "label": "Test Single Select", "name": "Test Single Select", "type": "single_select", "helpText": null, "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "Test Checkbox", "name": "Test Checkbox", "type": "boolean", "helpText": null, "active": true, "allowedValues": [], "section": null } ] }';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Field');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testFieldDefs = [
                SELECT Id, Name, Data_Type__c, Picklist_Values__c, Section_Name__c
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Field'
                ORDER BY Name
            ];

            CSUtils.itShouldBe('Evisort Field Definition Records', 6, testFieldDefs.size());
            CSUtils.itShouldBe('Multi Select is Multi Picklist', 'Multi Picklist', testFieldDefs[2].Data_Type__c);
            CSUtils.itShouldBe('Multi Select Values', 'Value1,Value2,Value3', testFieldDefs[2].Picklist_Values__c);
            CSUtils.itShouldBe('Number is Now Text', 'Text', testFieldDefs[3].Data_Type__c);
            CSUtils.itShouldBe('Single Select is Picklist', 'Picklist', testFieldDefs[4].Data_Type__c);
            CSUtils.itShouldBe('String is Text', 'Text', testFieldDefs[5].Data_Type__c);
            CSUtils.itShouldBe('String Section Changed', 'New Information', testFieldDefs[5].Section_Name__c);
        }
    }

    @isTest
    static void testDeleteFields() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            List<Evisort_Field_Definition__c> defs = new List<Evisort_Field_Definition__c>();
            defs.add(TestFactory.getFieldDefinition('Field To Exist', 'Text', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Field To Not Exist', 'Text', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Provision To Exist', 'Text', 'Provision'));
            insert defs;

            List<Evisort_Field_Value__c> values = new List<Evisort_Field_Value__c>();
            values.add(TestFactory.getFieldValue(evisortId, defs[0].Id));
            values[0].Text_Field__c = 'Existing';
            values.add(TestFactory.getFieldValue(evisortId, defs[1].Id));
            values[1].Text_Field__c = 'Not Existing';
            insert values;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 1, "fields": [ { "label": "Field To Exist", "name": "Field To Exist", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } } ] }';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Field');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testFieldDefs = [
                SELECT Id, Name
                FROM Evisort_Field_Definition__c
                ORDER BY Name
            ];

            CSUtils.itShouldBe('Evisort Field Definition Records', 2, testFieldDefs.size());
            CSUtils.itShouldBe('Name of Field Definition', 'Field To Exist', testFieldDefs[0].Name);
            CSUtils.itShouldBe('Name of Provision', 'Provision To Exist', testFieldDefs[1].Name);

            List<Evisort_Field_Value__c> newValues = [
                SELECT Id, Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortId
            ];
            CSUtils.itShouldBe('Number of Values', 1, newValues.size());
            CSUtils.itShouldBe('Field Value Exists', 'Existing', newValues[0].Text_Field__c);
        }
    }

    @isTest
    static void testDeleteProvisions() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            List<Evisort_Field_Definition__c> defs = new List<Evisort_Field_Definition__c>();
            defs.add(TestFactory.getFieldDefinition('Field To Exist', 'Text', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Provision To Exist', 'Text', 'Provision'));
            defs.add(TestFactory.getFieldDefinition('Provision To Not Exist', 'Text', 'Provision'));
            insert defs;

            List<Evisort_Field_Value__c> values = new List<Evisort_Field_Value__c>();
            values.add(TestFactory.getFieldValue(evisortId, defs[1].Id));
            values[0].Text_Field__c = 'Existing';
            values.add(TestFactory.getFieldValue(evisortId, defs[2].Id));
            values[1].Text_Field__c = 'Not Existing';
            insert values;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 1, "provisions": [ { "name": "Provision To Exist", "provisionTags": [] } ] }';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Provision');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testFieldDefs = [
                SELECT Id, Name
                FROM Evisort_Field_Definition__c
                ORDER BY Name
            ];

            CSUtils.itShouldBe('Evisort Field Definition Records', 2, testFieldDefs.size());
            CSUtils.itShouldBe('Name of Field Definition', 'Field To Exist', testFieldDefs[0].Name);
            CSUtils.itShouldBe('Name of Provision', 'Provision To Exist', testFieldDefs[1].Name);

            List<Evisort_Field_Value__c> newValues = [
                SELECT Id, Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortId
            ];
            CSUtils.itShouldBe('Number of Values', 1, newValues.size());
            CSUtils.itShouldBe('Provision Value Exists', 'Existing', newValues[0].Text_Field__c);
        }
    }

    @isTest
    static void testSyncNewProvisonsTrue() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            settings.Sync_New_Provisions__c = true;
            upsert settings;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"count": 5,"provisions": [{"name": "Change of Control","provisionTags": []},{"name": "Confidentiality","provisionTags": []},{"name": "Data Breach","provisionTags": []},{"name": "Excluded Information","provisionTags": []},{"name": "Governing Law","provisionTags": []}]}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Provision');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testProvisionDefs = [
                SELECT Id, Name, isActive__c
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Provision'
            ];

            CSUtils.itShouldBe('Check First record for isActive field ', true, testProvisionDefs[0].isActive__c);
        }
    }

    @isTest
    static void testSyncNewProvisonsFalse() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
            settings.Sync_New_Provisions__c = false;
            upsert settings;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"count": 5,"provisions": [{"name": "Change of Control","provisionTags": []},{"name": "Confidentiality","provisionTags": []},{"name": "Data Breach","provisionTags": []},{"name": "Excluded Information","provisionTags": []},{"name": "Governing Law","provisionTags": []}]}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall('Provision');

            Test.stopTest();

            List<Evisort_Field_Definition__c> testProvisionDefs = [
                SELECT Id, Name, isActive__c
                FROM Evisort_Field_Definition__c
                WHERE Field_Type__c = 'Provision'
            ];

            CSUtils.itShouldBe('Check First record for isActive field ', false, testProvisionDefs[0].isActive__c);
        }
    }
}