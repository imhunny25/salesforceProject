@isTest
public with sharing class IntakeFormServiceTest {
    @testSetup
    public static void setup() {
        Intake_Form__c form = TestFactory.getIntakeForm('Account', '123', 'Test Form');
        insert form;

        Intake_Form_Mapping__c mapping = TestFactory.getIntakeFormMapping(
            form.Id,
            'Name',
            'Test Field',
            '567',
            'Opportunities',
            ''
        );
        insert mapping;

        Evisort_Workspace_Settings__c settings = new Evisort_Workspace_Settings__c();
        settings.Workspace__c = 'test';
        settings.Subdomain__c = 'clients';

        insert settings;
    }

    @isTest
    public static void getRecords() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            List<IntakeFormMsg.IntakeForm> messages = IntakeFormController.getRecords();
            Test.stopTest();
            CSUtils.itShouldBe('Messages', 1, messages.size());
            CSUtils.itShouldBe('Mappings', 1, messages[0].mappings.size());
        }
    }

    @isTest
    public static void getRecordsByObject() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            List<IntakeFormMsg.IntakeForm> messages = IntakeFormController.getRecordsByObject('Account');
            System.debug(messages);
            Test.stopTest();
            CSUtils.itShouldBe('Messages', 1, messages.size());
        }
    }

    @isTest
    public static void addIntakeForm() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            // 1 intake form, 2 mappings
            String intakeFormJSON = '{"id":null,"createdById":null,"createdDate":null,"name":null,"salesforceObject":"Contact","workflowId":"234","workflowName":"Contract Request Form","mappings":[{"workflowFieldName":"Counterparty Signatory Email","workflowFieldId":"345","salesforceField":"Email"},{"workflowFieldName":"Counterparty Signatory Name","workflowFieldId":"456","salesforceField":"Name"}]}';
            // IntakeFormMsg.IntakeForm form = (IntakeFormMsg.IntakeForm) JSON.deserialize(intakeFormJSON, IntakeFormMsg.IntakeForm.class);
            IntakeFormController.saveRecords(intakeFormJSON);
            Test.stopTest();

            List<Intake_Form__c> intakeForms = [SELECT Id FROM Intake_Form__c];
            List<Intake_Form_Mapping__c> mappings = [SELECT Id FROM Intake_Form_Mapping__c];

            CSUtils.itShouldBe('Number of intake forms', 2, intakeForms.size());
            CSUtils.itShouldBe('Number of mappings', 3, mappings.size());
        }
    }

    @isTest
    public static void updateIntakeForm() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            IntakeFormMsg.IntakeForm message = IntakeFormController.getRecords()[0];
            message.mappings[0].salesforceField = 'Updated Field';

            IntakeFormController.saveRecords(JSON.serialize(message));
            Test.stopTest();

            List<Intake_Form__c> intakeForms = [SELECT Id FROM Intake_Form__c];
            List<Intake_Form_Mapping__c> mappings = [SELECT Id, Salesforce_Field__c FROM Intake_Form_Mapping__c];

            CSUtils.itShouldBe('Number of intake forms', 1, intakeForms.size());
            CSUtils.itShouldBe('Number of mappings', 1, mappings.size());
            CSUtils.itShouldBe('Updated mapping', 'Updated Field', mappings[0].Salesforce_Field__c);
        }
    }

    @isTest
    public static void addNewMapping() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            IntakeFormMsg.IntakeForm message = IntakeFormController.getRecords()[0];
            Intake_Form_Mapping__c newMapping = new Intake_Form_Mapping__c(
                Salesforce_Field__c = 'Test Field 2',
                Workflow_Field__c = 'Name 2',
                Workflow_Field_Id__c = '9234'
            );
            message.mappings.add(new IntakeFormMsg.IntakeFormMapping(newMapping));

            IntakeFormController.saveRecords(JSON.serialize(message));
            Test.stopTest();

            List<Intake_Form__c> intakeForms = [SELECT Id FROM Intake_Form__c];
            List<Intake_Form_Mapping__c> mappings = [SELECT Id, Salesforce_Field__c FROM Intake_Form_Mapping__c];

            CSUtils.itShouldBe('Number of intake forms', 1, intakeForms.size());
            CSUtils.itShouldBe('Number of mappings', 2, mappings.size());
        }
    }

    @isTest
    public static void removeOldMapping() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            IntakeFormMsg.IntakeForm message = IntakeFormController.getRecords()[0];
            message.mappings.remove(0);

            IntakeFormController.saveRecords(JSON.serialize(message));
            Test.stopTest();

            List<Intake_Form__c> intakeForms = [SELECT Id FROM Intake_Form__c];
            List<Intake_Form_Mapping__c> mappings = [SELECT Id, Salesforce_Field__c FROM Intake_Form_Mapping__c];

            CSUtils.itShouldBe('Number of intake forms', 1, intakeForms.size());
            CSUtils.itShouldBe('Number of mappings', 0, mappings.size());
        }
    }

    @isTest
    public static void deleteIntakeForm() {
        User u = UserTest.getEvisortAdminUser();
        List<Intake_Form__c> forms = [SELECT Id FROM Intake_Form__c];

        System.runAs(u) {
            Test.startTest();
            IntakeFormController.deleteRecord(forms[0].Id);
            Test.stopTest();

            List<Intake_Form__c> intakeForms = [SELECT Id FROM Intake_Form__c];
            List<Intake_Form_Mapping__c> mappings = [SELECT Id FROM Intake_Form_Mapping__c];

            CSUtils.itShouldBe('Number of intake forms', 0, intakeForms.size());
            CSUtils.itShouldBe('Number of mappings', 0, mappings.size());
        }
    }

    @isTest
    public static void getIntakeForms() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            // 1 intake form
            String mockJson = '[{"builderId":119,"conditions":{},"createdBy":119,"description":"","fieldLinks":{},"fieldMappings":[],"fields":{},"id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","implicitFields":[{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","place_holder":null,"type":"DATE"},{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","place_holder":null,"type":"DATE"},{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","place_holder":null,"type":"DATE"},{"description":"the name of the workflow","name":"Workflow Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the name of the submitter","name":"Submitter Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they’re in a sub-department","name":"Submitter Department","place_holder":null,"type":"DEPARTMENT"},{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","place_holder":null,"type":"SINGLE_SELECT"}],"isDraft":false,"lastModifiedById":39,"modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"permanentLinkId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","prefilledFormData":"","publishable":true,"published":true,"signers":{},"stages":{"edit":{"coordinator":null,"phases":[]},"finalize":{"coordinator":null,"phases":[]},"review":{"coordinator":null,"phases":[]},"sign":{"coordinator":null,"phases":[]}},"status":"published","versionNumber":0,"versions":[{"activeTickets":0,"id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","number":0,"published":true,"totalTickets":0}]}]';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            String res = IntakeFormController.getIntakeForms();
            Test.stopTest();

            List<Object> intakeForms = (List<Object>) JSON.deserializeUntyped(res);
            CSUtils.itShouldBe('Number of intake forms', 1, intakeForms.size());
        }
    }

    @isTest
    public static void getIntakeFormsError() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            // 1 intake form
            String mockJson = '[{"builderId":119,"conditions":{},"createdBy":119,"description":"","fieldLinks":{},"fieldMappings":[],"fields":{},"id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","implicitFields":[{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","place_holder":null,"type":"DATE"},{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","place_holder":null,"type":"DATE"},{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","place_holder":null,"type":"DATE"},{"description":"the name of the workflow","name":"Workflow Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the name of the submitter","name":"Submitter Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they’re in a sub-department","name":"Submitter Department","place_holder":null,"type":"DEPARTMENT"},{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","place_holder":null,"type":"SINGLE_SELECT"}],"isDraft":false,"lastModifiedById":39,"modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"permanentLinkId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","prefilledFormData":"","publishable":true,"published":true,"signers":{},"stages":{"edit":{"coordinator":null,"phases":[]},"finalize":{"coordinator":null,"phases":[]},"review":{"coordinator":null,"phases":[]},"sign":{"coordinator":null,"phases":[]}},"status":"published","versionNumber":0,"versions":[{"activeTickets":0,"id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","number":0,"published":true,"totalTickets":0}]}]';
            mock.addResponse(500, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            List<AuraHandledException> exceptions = new List<AuraHandledException>();

            Test.startTest();
            try {
                String res = IntakeFormController.getIntakeForms();
            } catch (AuraHandledException e) {
                exceptions.add(e);
            }
            Test.stopTest();

            CSUtils.itShouldBe(
                'AuraHandledException thrown with an empty or malformed request string',
                1,
                exceptions.size()
            );
        }
    }

    @isTest
    public static void getIntakeForm() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"conditions":[],"description":"","id":"5aab291e-3296-4324-82e3-e7d8c3006953","name":"Services Agreement -Pro-Service Provider","sections":[{"description":"","id":"11550295-a9ef-4003-b6d5-f0ecc2a78291","name":"Service Provider Details","position":0,"questions":[{"description":null,"field":{"customSettings":{"defaultValue":{"country":"United States"},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"dc5ab76f-3c14-4356-9359-9b5d54be1a8c","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Service Provider Address","options":{},"placeholder":"Service Provider Address","type":"ADDRESS"},"fieldId":"dc5ab76f-3c14-4356-9359-9b5d54be1a8c","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"}]}],"type":"company","workflow":{"builderId":"1af9e1ea-13cb-4bde-8487-6273c2d3a0fd","clientId":"ae6033c1-a572-41cc-be06-f362024f44a7","createdDate":"2021-08-20T15:56:07.324395Z","description":"","id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","isDraft":false,"lastModifiedById":"defdde7b-3344-4d13-884c-fde772c46179","modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"published":true,"type":"company","versionNumber":0},"workflowId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198"}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            String res = IntakeFormController.getIntakeForm('mockId');
            Test.stopTest();

            Map<String, Object> intakeForm = (Map<String, Object>) JSON.deserializeUntyped(res);
            List<Object> sections = (List<Object>) intakeForm.get('sections');
            Map<String, Object> section = (Map<String, Object>) sections.get(0);
            List<Object> questions = (List<Object>) section.get('questions');
            CSUtils.itShouldBe('Number of intake forms', 1, questions.size());
        }
    }

    @isTest
    public static void getIntakeFormWithMappedDataTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"conditions":[],"description":"","id":"5aab291e-3296-4324-82e3-e7d8c3006953","name":"Services Agreement -Pro-Service Provider","sections":[{"description":"","id":"11550295-a9ef-4003-b6d5-f0ecc2a78291","name":"Service Provider Details","position":0,"questions":[{"description":null,"field":{"customSettings":{"defaultValue":{"country":"United States"},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"567","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Test Field","options":{},"placeholder":"Service Provider Address","type":"SHORT_RESPONSE"},"fieldId":"567","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"}]}],"type":"company","workflow":{"builderId":"1af9e1ea-13cb-4bde-8487-6273c2d3a0fd","clientId":"ae6033c1-a572-41cc-be06-f362024f44a7","createdDate":"2021-08-20T15:56:07.324395Z","description":"","id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","isDraft":false,"lastModifiedById":"defdde7b-3344-4d13-884c-fde772c46179","modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"published":true,"type":"company","versionNumber":0},"workflowId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198"}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Intake_Form__c form = [SELECT Id, Workflow_Id__c FROM Intake_Form__c LIMIT 1];
            Intake_Form_Mapping__c mapping = [SELECT Id, Workflow_Field_Id__c, Workflow_Field__c FROM Intake_Form_Mapping__c LIMIT 1];

            Map<String, Map<Id, Object>> child = new Map<String, Map<Id, Object>>();
            Map<Id, Object> childData = new Map<Id, Object>();
            childData.put(o.Id, o.Name);
            child.put(mapping.Workflow_Field__c, childData);

            Test.startTest();
            Map<String, Object> res = IntakeFormController.getIntakeFormWithData(a.Id, form.Workflow_Id__c, child);
            Test.stopTest();

            List<Object> sections = (List<Object>) res.get('sections');
            Map<String, Object> curSection = (Map<String, Object>) sections[0];
            List<Object> questions = (List<Object>) curSection.get('questions');
            Map<String, Object> curQuestion = (Map<String, Object>) questions[0];
            Map<String, Object> field = (Map<String, Object>) curQuestion.get('field');

            CSUtils.itShouldBe('Number of questions', 1, questions.size());
            CSUtils.itShouldBe('Field Id', mapping.Workflow_Field_Id__c, (String) field.get('id'));
            CSUtils.itShouldBe('Mapped Value', a.Name, (String) field.get('mappedValue'));
        }
    }

    @isTest
    public static void getIntakeFormWithMappedDataChildTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"conditions":[],"description":"","id":"5aab291e-3296-4324-82e3-e7d8c3006953","name":"Services Agreement -Pro-Service Provider","sections":[{"description":"","id":"11550295-a9ef-4003-b6d5-f0ecc2a78291","name":"Service Provider Details","position":0,"questions":[{"description":null,"field":{"customSettings":{"defaultValue":{},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"789","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Test Field","options":{},"placeholder":"Service Provider Address","type":"SHORT_RESPONSE"},"fieldId":"789","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"}]}],"type":"company","workflow":{"builderId":"1af9e1ea-13cb-4bde-8487-6273c2d3a0fd","clientId":"ae6033c1-a572-41cc-be06-f362024f44a7","createdDate":"2021-08-20T15:56:07.324395Z","description":"","id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","isDraft":false,"lastModifiedById":"defdde7b-3344-4d13-884c-fde772c46179","modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"published":true,"type":"company","versionNumber":0},"workflowId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198"}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Intake_Form__c form = [SELECT Id, Workflow_Id__c FROM Intake_Form__c LIMIT 1];

            Intake_Form_Mapping__c mapping1 = TestFactory.getIntakeFormMapping(
                form.Id,
                'Opportunities.Name',
                'Test Field',
                '789',
                'Opportunities',
                'Child'
            );
            insert mapping1;

            Map<String, Map<Id, Object>> child = new Map<String, Map<Id, Object>>();
            Map<Id, Object> childData = new Map<Id, Object>();
            childData.put(o.Id, o.Name);
            child.put(mapping1.Workflow_Field__c, childData);

            Test.startTest();
            Map<String, Object> res = IntakeFormController.getIntakeFormWithData(a.Id, form.Workflow_Id__c, child);
            Test.stopTest();

            List<Object> sections = (List<Object>) res.get('sections');
            Map<String, Object> curSection = (Map<String, Object>) sections[0];
            List<Object> questions = (List<Object>) curSection.get('questions');
            Map<String, Object> curQuestion = (Map<String, Object>) questions[0];
            Map<String, Object> field = (Map<String, Object>) curQuestion.get('field');

            CSUtils.itShouldBe('Number of questions', 1, questions.size());
            CSUtils.itShouldBe('Field Id', mapping1.Workflow_Field_Id__c, (String) field.get('id'));
            CSUtils.itShouldBe('Mapped Value', o.Name, (String) field.get('mappedValue'));
        }
    }

    @isTest
    public static void getIntakeFormWithMappedDataTestMultiple() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            Contact c = new Contact(AccountId = a.Id, LastName = 'Test Last Name', Description = 'Test');
            insert c;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"conditions":[],"description":"","id":"5aab291e-3296-4324-82e3-e7d8c3006953","name":"Services Agreement -Pro-Service Provider","sections":[{"description":"","id":"11550295-a9ef-4003-b6d5-f0ecc2a78291","name":"Service Provider Details","position":0,"questions":[{"description":null,"field":{"customSettings":{"defaultValue":{"country":"United States"},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"789","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Test Field","options":{},"placeholder":"Service Provider Address","type":"SHORT_RESPONSE"},"fieldId":"789","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"},{"description":null,"field":{"customSettings":{"defaultValue":{},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"567","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Unit Test Opportunity","options":{},"placeholder":"Service Provider Address","type":"SHORT_RESPONSE"},"fieldId":"567","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"},{"description":null,"field":{"customSettings":{"defaultValue":{},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"123","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Test Account","options":{},"placeholder":"Service Provider Address","type":"SHORT_RESPONSE"},"fieldId":"123","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"}]}],"type":"company","workflow":{"builderId":"1af9e1ea-13cb-4bde-8487-6273c2d3a0fd","clientId":"ae6033c1-a572-41cc-be06-f362024f44a7","createdDate":"2021-08-20T15:56:07.324395Z","description":"","id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","isDraft":false,"lastModifiedById":"defdde7b-3344-4d13-884c-fde772c46179","modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement-Pro-Service Provider","parentId":null,"published":true,"type":"company","versionNumber":0},"workflowId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198"}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Intake_Form__c form = TestFactory.getIntakeForm('Opportunity', '123', 'Test Form');
            insert form;

            Intake_Form_Mapping__c mapping = TestFactory.getIntakeFormMapping(
                form.Id,
                'Name',
                'Unit Test Opportunity',
                '567',
                '',
                ''
            );
            insert mapping;

            Intake_Form_Mapping__c mapping1 = TestFactory.getIntakeFormMapping(
                form.Id,
                'Contacts.LastName',
                'Test Field',
                '789',
                'Contacts',
                'Child'
            );
            insert mapping1;

            Intake_Form_Mapping__c mapping2 = TestFactory.getIntakeFormMapping(
                form.Id,
                'Account.Name',
                'Test Account',
                '123',
                'Account',
                'Parent'
            );
            insert mapping2;

            Map<String, Map<Id, Object>> child = new Map<String, Map<Id, Object>>();
            Map<Id, Object> childData = new Map<Id, Object>();
            childData.put(c.Id, c.LastName);
            child.put(mapping1.Workflow_Field__c, childData);

            Test.startTest();
            Map<String, Object> res = IntakeFormController.getIntakeFormWithData(o.Id, form.Workflow_Id__c, child);
            Test.stopTest();

            List<Object> sections = (List<Object>) res.get('sections');
            Map<String, Object> curSection = (Map<String, Object>) sections[0];
            List<Object> questions = (List<Object>) curSection.get('questions');
            Map<String, Object> curQuestion = (Map<String, Object>) questions[0];
            Map<String, Object> curQuestion1 = (Map<String, Object>) questions[1];
            Map<String, Object> curQuestion2 = (Map<String, Object>) questions[2];
            Map<String, Object> field = (Map<String, Object>) curQuestion.get('field');
            Map<String, Object> field1 = (Map<String, Object>) curQuestion1.get('field');
            Map<String, Object> field2 = (Map<String, Object>) curQuestion2.get('field');

            CSUtils.itShouldBe('Number of questions', 3, questions.size());
            CSUtils.itShouldBe('Field Id', mapping1.Workflow_Field_Id__c, (String) field.get('id'));
            CSUtils.itShouldBe('Mapped Value', c.LastName, (String) field.get('mappedValue'));
            CSUtils.itShouldBe('Field Id', mapping2.Workflow_Field_Id__c, (String) field2.get('id'));
            CSUtils.itShouldBe('Mapped Value', a.Name, (String) field2.get('mappedValue'));
            CSUtils.itShouldBe('Field Id', mapping.Workflow_Field_Id__c, (String) field1.get('id'));
            CSUtils.itShouldBe('Mapped Value', o.Name, (String) field1.get('mappedValue'));
        }
    }

    @isTest
    public static void getIntakeFormWithMappedDataTestError() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"conditions":[],"description":"","id":"5aab291e-3296-4324-82e3-e7d8c3006953","name":"Services Agreement -Pro-Service Provider","sections":[{"description":"","id":"11550295-a9ef-4003-b6d5-f0ecc2a78291","name":"Service Provider Details","position":0,"questions":[{"description":null,"field":{"customSettings":{"defaultValue":{"country":"United States"},"document_placement":"single_line"},"esignaturePlaceHolder":null,"id":"567","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"Service Provider Address","options":{},"placeholder":"Service Provider Address","type":"ADDRESS"},"fieldId":"567","id":"a27edee1-6620-4cdc-9695-a200cf6fcdef","isRequired":true,"name":"What is the Service Providers address?","position":0,"title":"What is the Service Providers address?"}]}],"type":"company","workflow":{"builderId":"1af9e1ea-13cb-4bde-8487-6273c2d3a0fd","clientId":"ae6033c1-a572-41cc-be06-f362024f44a7","createdDate":"2021-08-20T15:56:07.324395Z","description":"","id":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","isDraft":false,"lastModifiedById":"defdde7b-3344-4d13-884c-fde772c46179","modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"published":true,"type":"company","versionNumber":0},"workflowId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198"}';
            mock.addResponse(500, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Intake_Form__c form = [SELECT Id, Workflow_Id__c FROM Intake_Form__c LIMIT 1];
            Intake_Form_Mapping__c mapping = [SELECT Id, Workflow_Field_Id__c FROM Intake_Form_Mapping__c LIMIT 1];

            Map<String, Map<Id, Object>> child = new Map<String, Map<Id, Object>>();
            Map<Id, Object> childData = new Map<Id, Object>();
            childData.put(o.Id, o.Name);
            child.put(mapping.Workflow_Field_Id__c, childData);

            List<AuraHandledException> exceptions = new List<AuraHandledException>();

            Test.startTest();
            try {
                Map<String, Object> res = IntakeFormController.getIntakeFormWithData(a.Id, form.Workflow_Id__c, child);
            } catch (AuraHandledException e) {
                exceptions.add(e);
            }
            Test.stopTest();

            CSUtils.itShouldBe(
                'AuraHandledException thrown with an empty or malformed request string',
                1,
                exceptions.size()
            );
        }
    }

    @isTest
    public static void createTicketPostTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            ContentVersion contentVersionInsert = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                null
            );

            insert contentVersionInsert;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocument doc = documents[0];

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson =
                '{"data":{"createdDate":"2021-09-27T21:16:09.969932Z","creator":{"email":"ianjones@bryant.com","extId":7974,"id":"96644a93-f8ce-4726-a11b-0061d4ca4368","name":"Mark Kelly"},"currentStage":{"coordinatorId":null,"id":"27ae600c-700e-464c-b96f-271516e79fde","isCompleted":false,"isEnabled":true,"name":"edit","status":"pending"},"fields":[],"id":"864d76cd-590a-4603-b124-13107e336967","isCancelled":false,"isCompleted":false,"modifiedDate":"2021-09-27T21:16:09.969932Z","name":"' +
                form.Workflow_Name__c +
                '","pilotDocHandlerId":null,"stage":"edit","stages":{"edit":{"coordinatorId":null,"isCompleted":false,"isEnabled":true,"status":"pending"},"finalize":{"coordinatorId":null,"isCompleted":false,"isEnabled":true,"status":"pending"},"review":{"coordinatorId":null,"isCompleted":false,"isEnabled":true,"status":"pending"},"sign":{"coordinatorId":null,"isCompleted":false,"isEnabled":true,"status":"pending"}},"status":"editing","workflowId":"f99f5940-65a9-4364-b4f3-a291438c97e2","workflow_id":"0352d889-ab49-487a-a446-e8a9331f41cb"}}';
            mock.addResponse(201, mockJson);

            Test.setMock(HttpCalloutMock.class, mock);

            String mockFormData =
                '{"counterpartyFile":{"documentId":["' +
                String.valueOf(doc.Id) +
                '"]},"6b3a1f71-fb92-47d8-817c-619fe99daf76":{"street_address_1":"3929 SE Adams St","city":"test","state":"test","country":"usa","zip_code":"97212"},"75512037-efa3-4428-b35c-e5413b208f32":{"value":"fastnoid@gmail.com"},"50fa0c2e-fe05-4a8b-8773-70f22da86549":{"value":"2021-11-12"},"b77b7de0-1977-4ece-a447-c707de9fc25b":{"value":["41249","41243"], "4cf761d6-52af-4a6e-8723-5311de501b3e":{"value":["10001"]}}}';

            String fieldType = '{"b77b7de0-1977-4ece-a447-c707de9fc25b" : "USER", "4cf761d6-52af-4a6e-8723-5311de501b3e":"DEPARTMENT"}';
            Test.startTest();
            Map<String, Object> res = IntakeFormController.createEvisortTicket(
                a.Id,
                form.Workflow_Id__c,
                form.Workflow_Name__c,
                mockFormData,
                fieldType
            );
            Test.stopTest();

            Evisort_Ticket__c ticket = [
                SELECT Id, Evisort_ID__c, Evisort_Name__c, Parent_Record_ID__c
                FROM Evisort_Ticket__c
                LIMIT 1
            ];

            System.assert(String.isNotEmpty(ticket.Evisort_ID__c), 'ticket should have an Id provided from API');
            System.assertEquals(form.Workflow_Name__c, ticket.Evisort_Name__c, 'ticket should have workflow name');
            System.assertEquals(
                String.valueOf(a.Id),
                ticket.Parent_Record_ID__c,
                'ticket should have id of parent record'
            );
        }
    }

    @isTest
    public static void getWorkspaceSettings() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            WorkspaceSettingsMsg settings = IntakeFormController.getWorkspaceSettings();
            Test.stopTest();

            CSUtils.itShouldBe('Workspace', 'test', settings.workspace);
            CSUtils.itShouldBe('Subdomain', 'clients', settings.subdomain);
        }
    }

    @isTest
    public static void validateMappingsParent() {
        User u = UserTest.getEvisortAdminUser();
        Map<String, String> fields = new Map<String, String>{};
        fields.put('Account.Name', 'parentLookup');
        fields.put('Account.AccountSource', 'parentLookup');
        fields.put('Account.BillingAddress', 'parentLookup');
        fields.put('Account.Id', 'parentLookup');
        fields.put('Account.Phone', 'parentLookup');
        System.runAs(u) {
            Test.startTest();
            Map<String, Object> response = IntakeFormController.validate('Contact', fields);
            Test.stopTest();
            Map<String, Boolean> validities = (Map<String, Boolean>) response.get('results');
            CSUtils.itShouldBe('Field should be valid', true, validities.get('Account.Name'));
        }
    }

    @isTest
    public static void validateMappingsChild() {
        User u = UserTest.getEvisortAdminUser();
        Map<String, String> fields = new Map<String, String>{};
        fields.put('Contacts.Name', 'childLookup');
        System.runAs(u) {
            Test.startTest();
            Map<String, Object> response = IntakeFormController.validate('Account', fields);
            Test.stopTest();
            Map<String, Boolean> validities = (Map<String, Boolean>) response.get('results');
            CSUtils.itShouldBe('Field should be valid', true, validities.get('Contacts.Name'));
        }
    }

    @isTest
    public static void fieldRetrieval() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');

            insert a;

            Opportunity o = new Opportunity(
                AccountId = a.Id,
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today()
            );

            insert o;
            Test.startTest();
            Opportunity opp = [SELECT Id, Account.Name FROM Opportunity LIMIT 1];
            String name = (String) IntakeFormService.getFieldValue(opp, 'Account.Name');
            String fake = (String) IntakeFormService.getFieldValue(opp, 'Fake.Field');
            Test.stopTest();
            CSUtils.itShouldBe('Opportunity.Account.Name', 'Test Account', name);
            CSUtils.itShouldBe('Opportunity.Fake.Field', null, fake);
        }
    }

    @isTest
    public static void post() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockBody = 'intake_form:uuid';
            mock.addResponse(201, mockBody);
            Test.setMock(HttpCalloutMock.class, mock);

            Account a = new Account(Name = 'Test Account');
            insert a;

            Test.startTest();

            Intake_Form__c intakeForm = [
                SELECT Id, Workflow_Id__c
                FROM Intake_Form__c
                WHERE Salesforce_Object__c = 'Account'
                LIMIT 1
            ];

            Map<String, Object> res = IntakeFormController.postToEvisort(a.Id, intakeForm.Id, 'Account');
            Test.stopTest();

            CSUtils.itShouldBe('Success', true, res.get('success'));
            CSUtils.itShouldBe('Workflow Id', intakeForm.Workflow_Id__c, res.get('workflowId'));
            CSUtils.itShouldBe('Persist Key', 'intake_form:uuid', res.get('persistKey'));
        }
    }

    @isTest
    public static void getObjects() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            List<Map<String, String>> objects = IntakeFormController.getObjects();
            Test.stopTest();

            // basically just testing if we got system information successfully
            // and didn't throw an error
            CSUtils.itShouldBe('Retrieved objects', true, objects.size() > 0);
        }
    }



    @isTest
    public static void getIntakeFormOptions() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '[{"label":"Test","value":41252},{"label":"User User","value":41253}]';
            mock.addResponse(201, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            IntakeFormController.getIntakeFormOptions('123', '234');
            Test.stopTest();
        }
    }

    @isTest
    static void setWorkspaceSettings(){
        List<Evisort_Workspace_Settings__c> evsWorkspaceList = [SELECT Id, Visibility__c FROM Evisort_Workspace_Settings__c LIMIT 1];
        
        System.assertEquals('All' , evsWorkspaceList[0].Visibility__c, 'before visibility was "All"');
        
        String settings = '{"domain":"clients","id":"';
        settings += evsWorkspaceList[0].ID;
        settings += '","subdomain":"clients","visibility":"Mapped","workspace":"test"}';
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            IntakeFormController.setWorkspaceSettings(settings);
            Test.stopTest();
        }
        
        List<Evisort_Workspace_Settings__c> afterUpdateEvsWorkspaceList = [SELECT Id, Visibility__c FROM Evisort_Workspace_Settings__c LIMIT 1];
        System.assertEquals('Mapped', afterUpdateEvsWorkspaceList[0].Visibility__c, 'After Updating Visibility Change to "Mapped"');
    }

    @isTest
    static void updateIntakeFormWithPermanentLinkIdTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c,Workflow_Permanent_Link_Id__c FROM Intake_Form__c LIMIT 1];
            form.Workflow_Permanent_Link_Id__c = '8b6d9662-d383-40a2-bec0-7d49c6fb1198';
            update form;
         
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            // 1 intake form
            String mockJson = getMockJson();
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Test.startTest();
            IntakeFormController.updateIntakeFormWithPermanentLinkId();
            Test.stopTest();
            
            Intake_Form__c updatedIntakeForm = [SELECT Id, Workflow_Id__c, Workflow_Name__c,Workflow_Permanent_Link_Id__c FROM Intake_Form__c LIMIT 1];
            CSUtils.itShouldBe('Workflow Id', '123456',updatedIntakeForm.Workflow_Id__c );
        }
    }
    
    @isTest
    static void updateIntakeFormWithoutPermanentLinkIdTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c,Workflow_Permanent_Link_Id__c FROM Intake_Form__c LIMIT 1];
            CSUtils.itShouldBe('Workflow Permanent Link Id null', null, form.Workflow_Permanent_Link_Id__c );
            
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            // 1 intake form
            String mockJson = getMockJson();
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Test.startTest();
            IntakeFormController.updateIntakeFormWithPermanentLinkId();
            Test.stopTest();
            
            Intake_Form__c updatedIntakeForm = [SELECT Id, Workflow_Id__c, Workflow_Name__c,Workflow_Permanent_Link_Id__c FROM Intake_Form__c LIMIT 1];
            CSUtils.itShouldNotBe('Workflow Permanent Link Id not null', null,updatedIntakeForm.Workflow_Permanent_Link_Id__c );
            CSUtils.itShouldBe('Workflow Permanent Link Id', '8b6d9662-d383-40a2-bec0-7d49c6fb1198',updatedIntakeForm.Workflow_Permanent_Link_Id__c );
        }
    }
    
    static String getMockJson(){
        String mockJson = '[{"builderId":119,"conditions":{},"createdBy":119,"description":"","fieldLinks":{},"fieldMappings":[],"fields":{},"id":"123456","implicitFields":[{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","place_holder":null,"type":"DATE"},{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","place_holder":null,"type":"DATE"},{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","place_holder":null,"type":"DATE"},{"description":"the name of the workflow","name":"Workflow Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the name of the submitter","name":"Submitter Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they’re in a sub-department","name":"Submitter Department","place_holder":null,"type":"DEPARTMENT"},{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","place_holder":null,"type":"SINGLE_SELECT"}],"isDraft":false,"lastModifiedById":39,"modifiedDate":"2021-08-20T15:56:07.324395Z","name":"Services Agreement -Pro-Service Provider","parentId":null,"permanentLinkId":"8b6d9662-d383-40a2-bec0-7d49c6fb1198","prefilledFormData":"","publishable":true,"published":true,"signers":{},"stages":{"edit":{"coordinator":null,"phases":[]},"finalize":{"coordinator":null,"phases":[]},"review":{"coordinator":null,"phases":[]},"sign":{"coordinator":null,"phases":[]}},"status":"published","versionNumber":0,"versions":[{"activeTickets":0,"id":"123","number":0,"published":true,"totalTickets":0}]}]';
    	return mockJson;
    }
    
    @isTest
    static void getContentDocumentAndAttachmentsTest()
    {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
        Account acc = TestFactory.getAccount('Test');
        insert acc;
        ContentVersion cv = TestFactory.getContentVersion('Test ContentDocument','Test ContentDocument', acc.Id);
        insert cv;
        
        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=acc.Id;
        insert attach;
        
        Test.startTest();
        List<IntakeFormService.ContentDocumentsAndAttachments> fileData = IntakeFormController.getContentDocumentAndAttachments(acc.Id);
        Test.stopTest();
        System.assertEquals(2, fileData.size());
        }
    }

}