@isTest
public with sharing class TicketServiceTest {
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
            'Child'
        );
        insert mapping;

        Evisort_Workspace_Settings__c settings = new Evisort_Workspace_Settings__c();
        settings.Workspace__c = 'test';
        settings.Subdomain__c = 'clients';

        insert settings;
    }

   @isTest
    public static void getTicketInformationTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                null
            );
            
            insert testConVer;
            
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            ContentVersion cv = [SELECT Id ,FirstPublishLocationId, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'TestContentVersion' ];

            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "data": { "file": { "content": { "ContentDocumentID": "' + cv.ContentDocumentId + '", "ContentVersionID": " '+ cv.Id +'" } } } }';

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            Map<String, Object> response = TicketController.getTicketInformation(ticket.Id);
            Test.stopTest();

            String resJson = JSON.serialize(response);
            TicketMsg msg = (TicketMsg) JSON.deserialize(resJson, TicketMsg.class);

            System.assert(msg != null, 'message should be populated');
            System.assert(msg.isUpdateable = true, 'user should have edit access');
            System.assertEquals(cv.ContentDocumentId, msg.data.file.content.ContentDocumentID, 'ContentDocument Id field should match mocked response id');
        }
    }

    @isTest
    public static void submitNextStageTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            ContentVersion contentVersionInsert = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                a.Id
            );

            insert contentVersionInsert;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocument doc = documents[0];

            Map<String, Map<String, String>> reqData = new Map<String, Map<String, String>>();
            reqData.put('counterpartyFile', new Map<String, String>{ 'documentId' => String.valueOf(doc.Id) });
            reqData.put('0f7ccf69-6325-487f-a05f-30c5b536e35f', new Map<String, String>{ 'value' => 'Test' });

            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigTicketPayload(testTicketId);
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            TicketMsg msg = TicketController.submitNextStage(ticket.Id);
            Test.stopTest();

            System.assert(msg != null, 'message should be populated');
            System.assertEquals(testTicketId, msg.data.id, 'message Id field should match mocked response id');
        }
    }

    @isTest
    public static void updateTicketTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;
			List<ContentVersion> listOfContentVersions = new List<ContentVersion>();
            for(integer i=0;i<4;i++){
                ContentVersion contentVersionInsert = TestFactory.getContentVersion(
                    'TestContentVersion',
                    'Test Content Data',
                    a.Id
                );
                listOfContentVersions.add(contentVersionInsert);
            }

            insert listOfContentVersions;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

            String reqData = '{ "attachmentFile": { "a5d801cd-1c61-43f0-b832-bdb78d530a4a": { "documentId": ["'+String.valueOf(documents[0].Id)+'"] }, "eaad356d-1960-4132-b7b1-b466da5fb84f": { "documentId":["'+String.valueOf(documents[1].Id)+'"] } }, "counterpartyFile": { "documentId": ["'+String.valueOf(documents[2].Id)+'"] }, "9648abd4-1581-4824-8c98-75be9cb2de73": { "value": "Test" } }';

            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigTicketPayload(testTicketId);

            mock.addResponse(201, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            Map<String, Object> msg = TicketController.updateTicket(
                ticket.id,
                form.Workflow_Id__c,
                reqData
            );
            Test.stopTest();

            System.assert(msg.get('success') == true, 'controller should return success value');
        }
    }

    @isTest
    public static void markCompleteTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            ContentVersion contentVersionInsert = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                a.Id
            );

            insert contentVersionInsert;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocument doc = documents[0];

            Map<String, Map<String, String>> reqData = new Map<String, Map<String, String>>();
            reqData.put('counterpartyFile', new Map<String, String>{ 'documentId' => String.valueOf(doc.Id) });
            reqData.put('0f7ccf69-6325-487f-a05f-30c5b536e35f', new Map<String, String>{ 'value' => 'Test' });

            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigTicketPayload(testTicketId);

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            TicketMsg msg = TicketController.markComplete(ticket.Id);
            Test.stopTest();

            System.assert(msg != null, 'message should be populated');
            System.assertEquals(testTicketId, msg.data.id, 'message Id field should match mocked response id');
        }
    }

    @isTest
    public static void getActivityLogTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            String testAction = 'testAction1';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigActivityLogPayload(testAction);

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            TicketMsg.ActivityLogWrapper msg = TicketController.getActivityLog(ticket.Id);
            Test.stopTest();

            System.assert(msg.data.size() > 0, 'Activity logs should be populated');
            System.assertEquals(
                testAction,
                msg.data[0].action,
                'Activity Log items should be populated by API response'
            );
            System.assert(msg.data[2].data.document != null, 'Optional document data should populate if available');
        }
    }

    @isTest
    public static void getParticipantTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            String testEmail = 'test@test.com';
            String testName = 'Test Tester';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigParticipantPayload(testEmail, testName);

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            TicketMsg.TicketParticipantWrapper msg = TicketController.getParticipants(ticket.Id);
            Test.stopTest();

            System.assert(msg.data.size() > 0, 'message should be populated');
            System.assertEquals(testEmail, msg.data[0].participant.email, 'email should be populated');
            System.assertEquals(testName, msg.data[0].participant.name, 'name should be populated');
        }
    }
    @isTest
    public static void getTicketAssigneesSFIdTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            String testEmail = 'test@test.com';
            String testName = 'Test Tester';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigParticipantPayload(testEmail, testName, true);

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            String msg = TicketService.getTicketAssignees(ticket.Id);
            Test.stopTest();

            System.assertEquals(msg, 'Test Tester, Test Tester1', 'response should be string of usernames');
        }
    }
    @isTest
    public static void getTicketAssigneesEVSIdTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);

            String testEmail = 'test@test.com';
            String testName = 'EVS ID Tester';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = TestFactory.getPreSigParticipantPayload(testEmail, testName, true);

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            String msg = TicketService.getTicketAssignees(ticket.Evisort_ID__c);
            Test.stopTest();

            System.assertEquals(msg, 'EVS ID Tester, EVS ID Tester1', 'response should be string of usernames');
        }
    }

    @isTest
    public static void getTicketDocumentTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            ContentVersion contentVersionInsert = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                a.Id
            );

            insert contentVersionInsert;

            Test.startTest();
            ContentVersion doc = TicketController.getTicketDocument(contentVersionInsert.Id);
            Test.stopTest();

            System.assert(doc != null, 'There should be a document retrieved');
        }
    }

    @isTest
    public static void enqueueTicketUpdateValidTest() {
        List<TicketRestController.RestRequestBody> reqs = new List<TicketRestController.RestRequestBody>();
        TicketRestController.RestRequestBody req = new TicketRestController.RestRequestBody();
        req.action = 'next stage';
        req.targetType = 'ticket';
        reqs.add(req);

        Test.startTest();
        TicketRestService.updateTicket(reqs);
        Test.stopTest();

        List<QueueItem__c> queueItems = [SELECT id FROM QueueItem__c];
        System.assert(queueItems.size() > 0, 'A queue Item should have been inserted');
    }

    @isTest
    public static void enqueueTicketUpdateInvalidTest() {
        List<TicketRestController.RestRequestBody> reqs = new List<TicketRestController.RestRequestBody>();
        TicketRestController.RestRequestBody req = new TicketRestController.RestRequestBody();
        req.action = 'bad value';
        req.targetType = 'bad value';
        reqs.add(req);

        Test.startTest();
        TicketRestService.updateTicket(reqs);
        Test.stopTest();

        List<QueueItem__c> queueItems = [SELECT id FROM QueueItem__c];
        System.assert(queueItems.size() <= 0, 'No queue items should exist');
    }

    @isTest
    public static void ticketUpdateHelperTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
           ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                null
            );
            
            insert testConVer;
            
            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            //ticket created with null values for status and stage
            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            QueueItem__c queueItem = new QueueItem__c();
            queueItem.Action_Context__c = 'update';
            queueItem.Object__c = 'Evisort_Ticket__c';
            queueItem.RecordId__c = '12345';
            insert queueItem;

            ContentVersion cv = [SELECT Id ,FirstPublishLocationId, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'TestContentVersion' ];

            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "data": { "currentStage": { "coordinators": [], "id": "9d016a50-7340-4283-bfaa-4089f1492d9e", "isCompleted": false, "isEnabled": true, "name": "edit", "phases": [], "status": "pending" }, "status": "editing", "stage": "edit", "isCompleted": false, "file": { "content": { "ContentDocumentID": "' + cv.ContentDocumentId + '", "ContentVersionID": " '+ cv.Id +'" } } } }';

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            TicketService.ticketUpdateQueueHelper(queueItem);
            Test.stopTest();

            Evisort_Ticket__c updatedTicket = [SELECT id, Stage__c, Status__c FROM Evisort_Ticket__c LIMIT 1];
            System.assert(updatedTicket.Stage__c != null, 'Stage field should be populated by GET');
            System.assert(updatedTicket.Status__c != null, 'Status field should be populated by GET');
        }

    }

    @isTest
    public static void ticketDeleteHelperTest() {
        Account a = new Account(Name = 'Test Account');
        insert a;

        Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

        //ticket created with null values for status and stage
        Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
        insert ticket;

        QueueItem__c queueItem = new QueueItem__c();
        queueItem.Action_Context__c = 'delete';
        queueItem.Object__c = 'Evisort_Ticket__c';
        queueItem.RecordId__c = '12345';

        Test.startTest();
        insert queueItem;
        Test.stopTest();

        Evisort_Ticket__c updatedTicket = [SELECT id, Stage__c, Status__c FROM Evisort_Ticket__c LIMIT 1];

        System.assertEquals('Deleted', updatedTicket.Stage__c, 'Stage field should be set to Deleted');
        System.assertEquals('Deleted', updatedTicket.Status__c, 'Status field should be set to Deleted');
    }

    @isTest
    static void ticketReviewStatusTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"approvals":[{"id":"12345","position":0,"status":"approved","userId":41253}],"description":"","id":"96565664","isInternal":true,"name":"Review Task 1","status":"approved"}';

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            String ticketStatus = '{"ticketId":"54321","issueId":"12345","status":"approve","comments":{}}';
            Test.startTest();
            String response = TicketController.ticketReviewStatus(ticketStatus);
            Test.stopTest();            
            String resJson = response;
            TicketMsg msg = (TicketMsg) JSON.deserialize(resJson, TicketMsg.class);
            System.assert(msg != null, 'message should be not Null');
            System.assertEquals('approved', msg.status, 'message Status should match mocked response status');
        }
    }
    
    @isTest
    static void getUserDetailsTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            Map<String,String> response = TicketController.getUserDetails();
            Test.stopTest();  
			System.assertEquals(false, response.isEmpty(), 'User details Map in not Empty');
        }
    }
    @isTest
    static void uploadTicketSignDocumentTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;
            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;
            Evisort__c e = TestFactory.getEvisortRecord(o.Id, '123');
            insert e;
            
            String yourFiles = 'RUFfQ/Om86XIM6kzpgxMTMJzqHOn86Uzp==';
            List<ContentVersion> con = new List<ContentVersion>();
            Set<Id> ids = new Set<Id>();
            for(integer i=1;i<3;i++){
            ContentVersion conVer = new ContentVersion();
            conVer.PathOnClient = 'ionicLogo.doc';
            conVer.Title = i+'Test File';
            conVer.VersionData = EncodingUtil.base64Decode(yourFiles);
			con.add(conVer);
            }
            insert con;
            
            for(ContentVersion cv : con){
                ids.add(cv.id);
            }            
            List<ContentVersion> conDoc = [SELECT id,ContentDocumentId FROM ContentVersion WHERE Id IN: ids];
            
            ContentDocumentLink cDLink = new ContentDocumentLink();
            cDLink.ContentDocumentId = conDoc[0].ContentDocumentId;
            cDLink.LinkedEntityId = e.id;
            cDLink.ShareType = 'I';
            cDLink.Visibility = 'AllUsers';
            insert cDLink;
            String ticketSignDocumentDetails = '{"currentTicketId":"123456","contentVersion":"'+conDoc[1].id+'","contentDocument":"'+conDoc[1].ContentDocumentId+'","signerIds":["163087","163084"]}';
			String replaceDocumentId = '{"oldDocumentId":"'+conDoc[0].ContentDocumentId+'","ticketEvisortRecordId":"'+e.id+'"}';
            
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"activities":[],"approvals":[{"externalUser":null,"id":"123456987","position":0,"signatureUploadDate":"2022-09-27T10:01:58.282503Z","status":"signed","userId":163084}],"candidates":[],"comments":[],"description":"","id":"987654321","isInternal":true,"name":"","position":1,"status":"signed"}';
            
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
			Test.startTest();
            String response = TicketController.uploadTicketSignDocument(ticketSignDocumentDetails,replaceDocumentId);
            Test.stopTest();            
            List<ContentDocumentLink> cdl =  [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:e.id];
            System.assertEquals( 2, cdl.size(), 'after sign upload --> content document Records size');
        }
    }

    @isTest
    static void uploadNewVersionDocumentTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;
            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;
            Evisort__c e = TestFactory.getEvisortRecord(o.Id, '123');
            insert e;
            
            String versionData = 'RUFfQ/Om86XIM6kzpgxMTMJzqHOn86Uzp==';
            List<ContentVersion> con = new List<ContentVersion>();
            Set<Id> ids = new Set<Id>();
            for(integer i=1;i<3;i++){
            ContentVersion conVer = new ContentVersion();
            conVer.PathOnClient = 'ionicLogo.doc';
            conVer.Title = i+'Test File';
            conVer.VersionData = EncodingUtil.base64Decode(versionData);
			con.add(conVer);
            }
            insert con;
            
            for(ContentVersion cv : con){
                ids.add(cv.id);
            }            
            List<ContentVersion> conDoc = [SELECT id,ContentDocumentId FROM ContentVersion WHERE Id IN: ids];
            
            ContentDocumentLink cDLink = new ContentDocumentLink();
            cDLink.ContentDocumentId = conDoc[0].ContentDocumentId;
            cDLink.LinkedEntityId = e.id;
            cDLink.ShareType = 'I';
            cDLink.Visibility = 'AllUsers';
            insert cDLink;
            String ticketDocumentDetails = '{"ticketId":"123456","documentId":"987654","oldContentDocumentId":"'+conDoc[0].ContentDocumentId+'","evisortRecordId":"'+e.id+'","isCounterparty":true,"contentVersionId":"'+conDoc[1].id+'","contentDocumentId":"'+conDoc[1].ContentDocumentId+'","note":"Test"}';            
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"activities":[],"approvals":[{"externalUser":null,"id":"123456987","position":0,"signatureUploadDate":"2022-09-27T10:01:58.282503Z","status":"signed","userId":163084}],"candidates":[],"comments":[],"description":"","id":"987654321","isInternal":true,"name":"","position":1,"status":"signed"}';
            
            mock.addResponse(201, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
			Test.startTest();
            String response = TicketController.uploadNewVersionDocument(ticketDocumentDetails);
            Test.stopTest();            
            List<ContentDocumentLink> cdl =  [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:e.id];
			System.assertEquals(2 , cdl.size(), 'After Update LinkedEntityId of Evisort Record size');
        }
    }

    @isTest
    public static void ticketContentDocumentLinkTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            ContentVersion testConVer = TestFactory.getContentVersion(
                'TestContentVersion',
                'Test Content Data',
                null
            );
            
            insert testConVer;

            Account a = new Account(Name = 'Test Account');
            insert a;

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;

            ContentVersion cv = [SELECT Id ,FirstPublishLocationId, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'TestContentVersion' ];

            String testTicketId = '54321';
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "content": { "ContentDocumentID": "' + cv.ContentDocumentId + '", "ContentVersionID": " '+ cv.Id +'" } }';

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            TicketController.ticketContentDocumentLink(ticket.Id, mockJson);
            Test.stopTest();

            List<ContentDocumentLink> contentDocumentList = [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId =: cv.ContentDocumentId AND LinkedEntityId =: ticket.id LIMIT 1];

            System.assert(contentDocumentList.size() > 0, ' A Content Document link should have been created');
            System.assertEquals(contentDocumentList[0].LinkedEntityId, ticket.id, 'New content document link with Evisort ticket id');
        }
    }

    @isTest
    static void getEvisortRecordTest(){
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Account a = new Account(Name = 'Test Account');
            insert a;
    
            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', null, a.Id);
            insert ticket;
    
            Evisort__c  evisortRecord =TestFactory.getEvisortRecord(a.Id, '12345');
            evisortRecord.Evisort_Ticket__c =ticket.Id;
            insert evisortRecord;
    
            Test.startTest();
            String evisortId = TicketController.getEvisortRecord(ticket.Id);
            System.assertEquals(evisortRecord.Id, evisortId,'Both Evisort Ids are same');
            Test.stopTest();
        }
    }
    
    @isTest
    static void getEvisortUsers() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '[ { "client": 3219, "id": 163084, "first_name": "Praveen", "full_name": "Praveen Prajapat", "last_name": "Prajapat", "email": "praveen.prajapat@epigrowth.com", "role": 3, "position_name": "Admin", "last_login": "2022-12-23T07:05:42.771448Z", "departments": [], "job_title": "Salesforce Developer", "is_workflow_admin": true, "is_automation_admin": false }, { "client": 3219, "id": 41253, "first_name": "Ankur", "full_name": "Ankur Bhargava", "last_name": "Bhargava", "email": "ankur@epigrowth.com", "role": 3, "position_name": "Admin", "last_login": "2022-12-22T12:48:35.695901Z", "departments": [], "job_title": "Software Developer", "is_workflow_admin": true, "is_automation_admin": false } ]';

            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            String response = TicketController.getEvisortUsers();
            Test.stopTest();
            System.assert(response != null, 'response should be not Null');
        }
    }
}