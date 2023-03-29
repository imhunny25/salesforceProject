@isTest
public with sharing class NewIntakeFormControllerTest {
    @testSetup
    public static void setup() {
        Account a = TestFactory.getAccount('Unit Test Account');
        insert a;

        Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
        insert o;

        Contact c = new Contact(AccountId = a.Id, LastName = 'Test Last Name', Description = 'Test');
        insert c;

        Evisort_Workspace_Settings__c evsWorkspaceSettings = new Evisort_Workspace_Settings__c(Visibility__c = 'All', Workspace__c = 'test');
        insert evsWorkspaceSettings;

        Intake_Form__c form = TestFactory.getIntakeForm('Account', '123', 'Test Form');
        insert form;

        Intake_Form_Mapping__c mapping1 = TestFactory.getIntakeFormMapping(
            form.Id,
            'Opportunities.Name',
            'Test Opportunity Field',
            '456',
            'Opportunities',
            'Child'
        );

        insert mapping1;

        Intake_Form_Mapping__c mapping5 = TestFactory.getIntakeFormMapping(
            form.Id,
            'Opportunities.Id',
            'Test Opportunity2 Field',
            '123',
            'Opportunities',
            'Child'
        );

        insert mapping5;

        Intake_Form_Mapping__c mapping2 = TestFactory.getIntakeFormMapping(
            form.Id,
            'Contacts.LastName',
            'Test Contacts2 Field',
            '789',
            'Contacts',
            'Child'
        );

        insert mapping2;

        Intake_Form_Mapping__c mapping3 = TestFactory.getIntakeFormMapping(
            form.Id,
            'Contacts.Description',
            'Test Contact Field',
            '012',
            'Contacts',
            'Child'
        );

        insert mapping3;

        Intake_Form_Mapping__c mapping6 = TestFactory.getIntakeFormMapping(
            form.Id,
            'Contacts.Email',
            'Test Contact3 Field',
            '345',
            'Contacts',
            'Child'
        );

        insert mapping6;

        Intake_Form_Mapping__c mapping4 = new Intake_Form_Mapping__c(Intake_Form__c = form.Id);

        insert mapping4;
    }

    @isTest
    public static void testChildMappingRecords() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            List<Account> account = [SELECT Id FROM Account LIMIT 1];
            List<Intake_Form__c> intakeForm = [SELECT Id, Workflow_Id__c FROM Intake_Form__c LIMIT 1];

            Test.startTest();
            Map<String, Map<String, List<IntakeFormMappingService.ChildObjectData>>> messages = NewIntakeFormController.getIntakeFormsMappings(
                account.get(0).Id,
                String.valueOf(intakeForm.get(0).Workflow_Id__c)
            );
            Test.stopTest();

            CSUtils.itShouldBe('Child Size', 5, messages.keySet().size());
        }
    }

    @isTest
    public static void testGetIntakeForms() {
        List<String> docIds = new List<String>();
        docIds.add('Test');
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            NewIntakeFormController.removeDocument(docIds);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void getIntakeFormsByVisibility() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            String WorkflowId;
            Account acc = [SELECT Id FROM Account LIMIT 1];
            List<Intake_Form__c> intakeForms = [SELECT Id, Workflow_Id__c FROM Intake_Form__c LIMIT 1];
            Evisort_Workspace_Settings__c evisortWorkspaceSetting = [SELECT Id, Visibility__c FROM Evisort_Workspace_Settings__c LIMIT 1];
			evisortWorkspaceSetting.Visibility__c = 'Mapped';
            update evisortWorkspaceSetting; 
    
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '[{"acceptedFileTypes":[],"builderId":41221,"conditions":{},"createdBy":41221,"description":"","fieldLinks":{},"fieldMappings":[],"fields":{},"hasCompanyPaper":false,"hasCounterpartyPaper":true,"id":"';
            mockJson += intakeForms[0].Workflow_Id__c;
            mockJson += '","implicitFields":[{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","place_holder":null,"type":"DATE"},{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","place_holder":null,"type":"DATE"},{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","place_holder":null,"type":"DATE"},{"description":"the name of the workflow","name":"Workflow Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the name of the submitter","name":"Submitter Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they\u2019re in a sub-department","name":"Submitter Department","place_holder":null,"type":"DEPARTMENT"},{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","place_holder":null,"type":"SINGLE_SELECT"}],"isDraft":false,"lastModifiedById":41221,"modifiedDate":"2022-04-22T00:00:58.961874Z","name":"Standard MSA","parentId":null,"permanentLinkId":"377298e1-8edf-44d5-a773-961d69098691","prefilledFormData":"","publishable":true,"published":true,"signers":{},"stages":{"edit":{"coordinator":null,"phases":[]},"finalize":{"coordinator":null,"phases":[]},"review":{"coordinator":null,"phases":[]},"sign":{"coordinator":null,"phases":[]}},"status":"published","versionNumber":0,"versions":[{"activeTickets":0,"id":"377298e1-8edf-44d5-a773-961d69098691","number":0,"published":true,"totalTickets":0}]},{"acceptedFileTypes":[],"builderId":41194,"conditions":{},"createdBy":41194,"description":"","fieldLinks":{},"fieldMappings":[],"fields":{},"hasCompanyPaper":false,"hasCounterpartyPaper":true,"id":"7c61930a-cb25-4c90-a533-f3aa84ec67c0","implicitFields":[{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","place_holder":null,"type":"DATE"},{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","place_holder":null,"type":"DATE"},{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","place_holder":null,"type":"DATE"},{"description":"the name of the workflow","name":"Workflow Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the name of the submitter","name":"Submitter Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they\u2019re in a sub-department","name":"Submitter Department","place_holder":null,"type":"DEPARTMENT"},{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","place_holder":null,"type":"SINGLE_SELECT"}],"isDraft":false,"lastModifiedById":41221,"modifiedDate":"2022-04-15T06:34:51.595422Z","name":"Workflow with User and Department","parentId":"f31374ef-b1e6-4c02-9456-0748b94b2545","permanentLinkId":"f31374ef-b1e6-4c02-9456-0748b94b2545","prefilledFormData":"","publishable":true,"published":true,"signers":{},"stages":{"edit":{"coordinator":null,"phases":[]},"finalize":{"coordinator":null,"phases":[]},"review":{"coordinator":null,"phases":[]},"sign":{"coordinator":null,"phases":[]}},"status":"published","versionNumber":4,"versions":[{"activeTickets":0,"id":"f31374ef-b1e6-4c02-9456-0748b94b2545","number":0,"published":false,"totalTickets":0},{"activeTickets":0,"id":"1f72dcf4-ac95-42a7-9f1f-7f74b4ac8661","number":1,"published":false,"totalTickets":0},{"activeTickets":0,"id":"00a8a5db-852c-43e5-b869-ec56f16c05fc","number":2,"published":false,"totalTickets":0},{"activeTickets":0,"id":"f0da20f7-0000-4f25-8a1d-fe855c3e65f4","number":3,"published":false,"totalTickets":0},{"activeTickets":0,"id":"7c61930a-cb25-4c90-a533-f3aa84ec67c0","number":4,"published":true,"totalTickets":0}]}]';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Test.startTest();
            String response = NewIntakeFormController.getIntakeFormsByVisibility(acc.Id);
            Test.stopTest();
            
            System.assert(response != null, 'response should not be null');
            List<Object> normalizedData = (List<Object>) JSON.deserializeUntyped(response);  
            for(Object res : normalizedData){
                Map < String, Object > mapofWorkflowData = (Map < String, Object > ) res;
                WorkflowId = (String) mapofWorkflowData.get('id');
            }
            System.assertEquals(intakeForms[0].Workflow_Id__c, WorkflowId , 'In Mapped workflowId Id field should match mocked response id'); 
        }
    }
}