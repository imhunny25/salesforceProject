@isTest
public class TestFactory {
    public static Account getAccount(String name) {
        return new Account(Name = name);
    }

    public static Contract getContract(Id accountId) {
        return new Contract(AccountId = accountId);
    }

    public static ContentWorkspace getContentWorkspace() {
        return new ContentWorkspace(Name='TEST CLASS', DeveloperName='TEST_CLASS');
    }
    
    public static ContentDocumentLink getContentDocumentLink() {
        Account a = getAccount('Unit Test Account');
        insert a;

        Opportunity o = getOpportunity('Unit Test Opportunity', a.Id);
        insert o;
            
        ContentWorkspace ws = getContentWorkspace();
        insert ws;
            
        ContentVersion cv = getContentVersion('TestContentVersion', 'Test Content Data', o.Id);
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            ShareType = 'I',
            Visibility = 'AllUsers',
            LinkedEntityId = ws.Id);
        return cdl;
    }

    public static Opportunity getOpportunity(String name, Id accountId) {
        // prettier-ignore
        return new Opportunity(
            Name = name, 
            AccountId = accountId, 
            StageName = 'Prospecting', 
            CloseDate = Date.today()
        );
    }
    
     public static Evisort_Export_Filter__c getEvisortDocumentSyncFilters(String name) {
        String objectFilterBody = '{ "rows": [ { "fieldName": "Name", "fieldLabel": "Name", "fieldType": "STRING", "operator": "Equals", "value": "Unit Test Opportunity", "isPicklist": false, "fieldTypeLabel": "STRING", "fieldSOAPType": "STRING", "sequence": 1 } ], "condition": "OR" }';
        String fileFilterBody = '{"rows":[{"fieldName":"FileExtension","fieldLabel":"File Extension","fieldType":"STRING","operator":"Contains","value":"doc","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1,"indexToShow":1}],"condition":"OR"}';
        
        return new Evisort_Export_Filter__c(Name = name,Object__c = name, Object_Filter_Body__c = objectFilterBody, File_Filter_Body__c = fileFilterBody);
    }

    public static ContentVersion getContentVersion(String title, String body, Id linkedId) {
        return new ContentVersion(
            Title = title,
            Description = title,
            PathOnClient = title + '.doc',
            VersionData = EncodingUtil.base64Decode(body),
            IsMajorVersion = true,
            FirstPublishLocationId = linkedId
        );
    }

    public static Evisort__c getEvisortRecord(Id recordId, String evisortId) {
        // prettier-ignore
        return new Evisort__c(
            Record_ID__c = recordId,
            External_ID__c = evisortId,
            Original_File_Name__c = 'UnitTest',
            Document_Status__c = 'Ready'
        );
    }

    public static Evisort_Field_Definition__c getFieldDefinition(String name, String dataType, String fieldType) {
        return new Evisort_Field_Definition__c(
            Name = name,
            Label__c = name,
            Data_Type__c = dataType,
            Field_Type__c = fieldType,
            isActive__c = true,
            Section_Name__c = 'Unit Test'
        );
    }

    public static Document_Field_Sync_Mapping__c getDocumentFieldSyncMapping(String objectName, String objectField, String objectLabel, String evisortFieldDefinitionId) {
        return new Document_Field_Sync_Mapping__c(
            Object__c = objectName,
            Salesforce_Field_Name__c = objectField,
            Field_Label__c = objectLabel,
            Evisort_Field_Definition__c = evisortFieldDefinitionId
        );
    }

    public static Evisort_Field_Value__c getFieldValue(Id evisortRecordId, Id fieldDefinitionId) {
        return new Evisort_Field_Value__c(
            Evisort__c = evisortRecordId,
            Evisort_Field_Definition__c = fieldDefinitionId,
            External_ID__c = evisortRecordId + '-' + fieldDefinitionId
        );
    }

    public static QueueItem__c getQueueItem(Id recordId, String objectName) {
        QueueItem__c item = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
        item.RecordId__c = recordId;
        item.Object__c = objectName;
        return item;
    }

    public static Evisort_Document_Sync_Criteria__c getSyncCriteriaSettings(
        string objectLabel,
        String fileType,
        String recordType
    ) {
        return new Evisort_Document_Sync_Criteria__c(
            Name = objectLabel,
            Object__c = objectLabel,
            File_Type__c = fileType,
            Record_Type__c = recordType
        );
    }

    public static Evisort_Export_Object__c getExportObject(String objectName, String status, String fileTypes) {
        return new Evisort_Export_Object__c(Object__c = objectName, Status__c = status, File_Types__c = fileTypes);
    }

    public static Evisort_Export_Document__c getExportDocument(
        id exportObjectId,
        String status,
        String contentId,
        String recordId,
        Decimal fileSize
    ) {
        return new Evisort_Export_Document__c(
            Evisort_Export_Object__c = exportObjectId,
            Status__c = status,
            ContentVersion__c = contentId,
            Record_ID__c = recordId,
            File_Size__c = fileSize
        );
    }

    public static Intake_Form__c getIntakeForm(String sObjectName, String workflowId, String workflowName) {
        return new Intake_Form__c(
            Salesforce_Object__c = sObjectName,
            Workflow_Id__c = workflowId,
            Workflow_Name__c = workflowName
        );
    }

    public static Intake_Form_Mapping__c getIntakeFormMapping(
        Id formId,
        String fieldName,
        String workflowFieldName,
        String workflowFieldId,
        String salesforceObject,
        String salesforceObjectType
    ) {
        return new Intake_Form_Mapping__c(
            Intake_Form__c = formId,
            Salesforce_Field__c = fieldName,
            Workflow_Field__c = workflowFieldName,
            Workflow_Field_Id__c = workflowFieldId,
            Salesforce_Object__c = salesforceObject,
            Salesforce_Object_Type__c = salesforceObjectType
        );
    }

    public static Evisort_Ticket__c getEvisortTicket(
        String evisortId,
        String evisortName,
        Id intakeFormId,
        Id parentRecordId
    ) {
        return new Evisort_Ticket__c(
            Evisort_ID__c = evisortId,
            Evisort_Name__c = evisortName,
            Intake_Form__c = intakeFormId,
            Parent_Record_ID__c = String.valueOf(parentRecordId)
        );
    }

    public static String getPreSigTicketPayload(String testTicketId) {
        return '{"stage": "finalize", "status":"pending finalization", "data":{"createdDate":"2021-11-19T15:13:59.936361Z","creator":{"email":"test.tester@testing.com","id":22973,"name":"Test User"},"currentStage":{"coordinatorId":null,"id":"5a57edae-bb52-4ef5-af14-8c3932095662","isCompleted":false,"isEnabled":true,"name":"finalize","phases": [ { "description": "", "id": "851a4726-e285-44dd-8cb2-42d9dc75cbe7", "isEnabled": true, "judgments": [ { "activities": [], "approvals": [ { "comment": "TestCo integration was removed.", "externalUser": { "email": "Test.Tester+internal@TestCo.com", "id": "9fc2d3ea-db12-4d36-b57b-b3bcc3463708", "name": "Test Tester", "title": "" }, "id": "507f7d4a-1042-46b0-9f19-21ff53d140bf", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "2ee19a30-f570-473c-a54c-cb6f762553a7", "isInternal": true, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "0e206486-a1d7-4f8d-832d-f0b01db3a850", "minApprovalCount": null, "name": "", "position": 0, "signer": { "default": null, "id": "961442f4-d08b-4e1d-882e-635b67b01886", "name": "Signer 1", "partyId": "46e0af2f-61e8-4ab2-b03a-780b70071fee", "type": "company" } }, "name": "", "position": 0, "status": "signature request not sent" }, { "activities": [], "approvals": [ { "comment": "TestCo integration was removed.", "externalUser": { "email": "Test.Tester+counterparty@TestCo.com", "id": "2388f33c-3a72-40e7-bafc-b6ca0780345d", "name": "Test Tester", "title": "" }, "id": "3236b0ad-dfca-4947-a9bd-b96bb163b901", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "6baa70a9-b325-40cb-a07c-270d94461c5f", "isInternal": false, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "021d8d36-113f-442e-a333-26483a5a0f58", "minApprovalCount": null, "name": "", "position": 1, "signer": { "default": null, "id": "dfbd5a3e-c5cc-428f-85d9-0ac00a50409c", "name": "Signer 2", "partyId": "d476eaa7-f638-43a9-a9d1-3da422789531", "type": "counter" } }, "name": "", "position": 1, "status": "signature request not sent" } ], "name": "Signing Phase 1", "position": 0, "risks": [], "status": "signature request not sent" } ],' +
            ' "status":"pending"},"document":{"currentVersionId":"3aeeda94-b6c1-4163-9aeb-556e45e22565","id":"27909f4b-2d77-4d3a-b811-4e25ec4a071c","lastModifiedBy":{"email":"test.tester@test.com","id":22973,"name":"Test Tester"},"name":".gitignore.bin"},"fields":[{"fieldId":"b0d00b93-6033-449c-84fd-d48cea261896","id":"c588eb46-51d5-4993-957f-a013e312369c","value":{"value":"Test"}}],"id":"' +
            testTicketId +
            '","isCancelled":false,"isCompleted":false,"modifiedDate":"2021-11-19T15:13:59.936361Z","name":"Tests minimal workflow_2021-11-19","paperType":"counter","pilotDocHandlerId":null,"stage":"finalize","stages":{"edit":{"coordinatorId":null,"id":"b2190260-07e6-40e7-b78e-82d5fcded20e","isCompleted":true,"isEnabled":false,"name":"edit","phases": [ { "description": "", "id": "851a4726-e285-44dd-8cb2-42d9dc75cbe7", "isEnabled": true, "judgments": [ { "activities": [], "approvals": [ { "comment": "TestCo integration was removed.", "externalUser": { "email": "Test.Tester+internal@TestCo.com", "id": "9fc2d3ea-db12-4d36-b57b-b3bcc3463708", "name": "Test Tester", "title": "" }, "id": "507f7d4a-1042-46b0-9f19-21ff53d140bf", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "2ee19a30-f570-473c-a54c-cb6f762553a7", "isInternal": true, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "0e206486-a1d7-4f8d-832d-f0b01db3a850", "minApprovalCount": null, "name": "", "position": 0, "signer": { "default": null, "id": "961442f4-d08b-4e1d-882e-635b67b01886", "name": "Signer 1", "partyId": "46e0af2f-61e8-4ab2-b03a-780b70071fee", "type": "company" } }, "name": "", "position": 0, "status": "signature request not sent" }, { "activities": [], "approvals": [ { "comment": "TestCo integration was removed.", "externalUser": { "email": "Test.Tester+counterparty@TestCo.com", "id": "2388f33c-3a72-40e7-bafc-b6ca0780345d", "name": "Test Tester", "title": "" }, "id": "3236b0ad-dfca-4947-a9bd-b96bb163b901", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "6baa70a9-b325-40cb-a07c-270d94461c5f", "isInternal": false, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "021d8d36-113f-442e-a333-26483a5a0f58", "minApprovalCount": null, "name": "", "position": 1, "signer": { "default": null, "id": "dfbd5a3e-c5cc-428f-85d9-0ac00a50409c", "name": "Signer 2", "partyId": "d476eaa7-f638-43a9-a9d1-3da422789531", "type": "counter" } }, "name": "", "position": 1, "status": "signature request not sent" } ], "name": "Signing Phase 1", "position": 0, "risks": [], "status": "signature request not sent" } ],' +
            ' "status":"pending"},"finalize":{"coordinatorId":22973,"id":"5a57edae-bb52-4ef5-af14-8c3932095662","isCompleted":false,"isEnabled":true,"name":"finalize","phases": [ { "description": "", "id": "851a4726-e285-44dd-8cb2-42d9dc75cbe7", "isEnabled": true, "judgments": [ { "activities": [], "approvals": [ { "comment": "testco integration was removed.", "externalUser": { "email": "Test.Tester+internal@testco.com", "id": "9fc2d3ea-db12-4d36-b57b-b3bcc3463708", "name": "Test Tester", "title": "" }, "id": "507f7d4a-1042-46b0-9f19-21ff53d140bf", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "2ee19a30-f570-473c-a54c-cb6f762553a7", "isInternal": true, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "0e206486-a1d7-4f8d-832d-f0b01db3a850", "minApprovalCount": null, "name": "", "position": 0, "signer": { "default": null, "id": "961442f4-d08b-4e1d-882e-635b67b01886", "name": "Signer 1", "partyId": "46e0af2f-61e8-4ab2-b03a-780b70071fee", "type": "company" } }, "name": "", "position": 0, "status": "signature request not sent" }, { "activities": [], "approvals": [ { "comment": "testco integration was removed.", "externalUser": { "email": "Test.Tester+counterparty@testco.com", "id": "2388f33c-3a72-40e7-bafc-b6ca0780345d", "name": "Test Tester", "title": "" }, "id": "3236b0ad-dfca-4947-a9bd-b96bb163b901", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "6baa70a9-b325-40cb-a07c-270d94461c5f", "isInternal": false, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "021d8d36-113f-442e-a333-26483a5a0f58", "minApprovalCount": null, "name": "", "position": 1, "signer": { "default": null, "id": "dfbd5a3e-c5cc-428f-85d9-0ac00a50409c", "name": "Signer 2", "partyId": "d476eaa7-f638-43a9-a9d1-3da422789531", "type": "counter" } }, "name": "", "position": 1, "status": "signature request not sent" } ], "name": "Signing Phase 1", "position": 0, "risks": [], "status": "signature request not sent" } ],' +
            ' "status":"pending"},"review":{"coordinatorId":null,"id":"8436820d-0253-4082-9140-f9c9a3dc00f4","isCompleted":true,"isEnabled":false,"name":"review","phases": [ { "description": "", "id": "851a4726-e285-44dd-8cb2-42d9dc75cbe7", "isEnabled": true, "judgments": [ { "activities": [], "approvals": [ { "comment": "testco integration was removed.", "externalUser": { "email": "Test.Tester+internal@testco.com", "id": "9fc2d3ea-db12-4d36-b57b-b3bcc3463708", "name": "Test Tester", "title": "" }, "id": "507f7d4a-1042-46b0-9f19-21ff53d140bf", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "2ee19a30-f570-473c-a54c-cb6f762553a7", "isInternal": true, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "0e206486-a1d7-4f8d-832d-f0b01db3a850", "minApprovalCount": null, "name": "", "position": 0, "signer": { "default": null, "id": "961442f4-d08b-4e1d-882e-635b67b01886", "name": "Signer 1", "partyId": "46e0af2f-61e8-4ab2-b03a-780b70071fee", "type": "company" } }, "name": "", "position": 0, "status": "signature request not sent" }, { "activities": [], "approvals": [ { "comment": "testco integration was removed.", "externalUser": { "email": "Test.Tester+counterparty@testco.com", "id": "2388f33c-3a72-40e7-bafc-b6ca0780345d", "name": "Test Tester", "title": "" }, "id": "3236b0ad-dfca-4947-a9bd-b96bb163b901", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "6baa70a9-b325-40cb-a07c-270d94461c5f", "isInternal": false, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "021d8d36-113f-442e-a333-26483a5a0f58", "minApprovalCount": null, "name": "", "position": 1, "signer": { "default": null, "id": "dfbd5a3e-c5cc-428f-85d9-0ac00a50409c", "name": "Signer 2", "partyId": "d476eaa7-f638-43a9-a9d1-3da422789531", "type": "counter" } }, "name": "", "position": 1, "status": "signature request not sent" } ], "name": "Signing Phase 1", "position": 0, "risks": [], "status": "signature request not sent" } ],' +
            ' "status":"pending"},"sign":{"coordinatorId":null,"id":"1a9f4c9b-d93b-460e-b8b2-5b3b85a83be4","isCompleted":true,"isEnabled":false,"name":"sign","phases": [ { "description": "", "id": "851a4726-e285-44dd-8cb2-42d9dc75cbe7", "isEnabled": true, "judgments": [ { "activities": [], "approvals": [ { "comment": "testco integration was removed.", "externalUser": { "email": "Test.Tester+internal@testco.com", "id": "9fc2d3ea-db12-4d36-b57b-b3bcc3463708", "name": "Test Tester", "title": "" }, "id": "507f7d4a-1042-46b0-9f19-21ff53d140bf", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "2ee19a30-f570-473c-a54c-cb6f762553a7", "isInternal": true, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "0e206486-a1d7-4f8d-832d-f0b01db3a850", "minApprovalCount": null, "name": "", "position": 0, "signer": { "default": null, "id": "961442f4-d08b-4e1d-882e-635b67b01886", "name": "Signer 1", "partyId": "46e0af2f-61e8-4ab2-b03a-780b70071fee", "type": "company" } }, "name": "", "position": 0, "status": "signature request not sent" }, { "activities": [], "approvals": [ { "comment": "TestCo integration was removed.", "externalUser": { "email": "Test.Tester+counterparty@TestCo.com", "id": "2388f33c-3a72-40e7-bafc-b6ca0780345d", "name": "Test Tester", "title": "" }, "id": "3236b0ad-dfca-4947-a9bd-b96bb163b901", "lastReminderDate": null, "modifiedDate": "2021-11-03T16:17:05.058493Z", "position": 0, "signatureUploadDate": null, "status": "signature request not sent", "userId": null } ], "candidates": [], "comments": [], "description": "", "id": "6baa70a9-b325-40cb-a07c-270d94461c5f", "isInternal": false, "judgment": { "approvers": [], "conditionRule": null, "description": "", "id": "021d8d36-113f-442e-a333-26483a5a0f58", "minApprovalCount": null, "name": "", "position": 1, "signer": { "default": null, "id": "dfbd5a3e-c5cc-428f-85d9-0ac00a50409c", "name": "Signer 2", "partyId": "d476eaa7-f638-43a9-a9d1-3da422789531", "type": "counter" } }, "name": "", "position": 1, "status": "signature request not sent" } ], "name": "Signing Phase 1", "position": 0, "risks": [], "status": "signature request not sent" } ],' +
            ' "status":"pending"}},"status":"pending finalization","wasManuallyUpdated":true,"workflow":{"acceptedFileTypes":[".doc",".docx"],"conditions":{},"fieldLinks":{},"fields":{},"form":{"sections":[]},"id":"fca4a546-fd5b-4202-9f6d-b26fa54f7cfe","implicitFields":[{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","place_holder":null,"type":"DATE"},{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","place_holder":null,"type":"DATE"},{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","place_holder":null,"type":"DATE"},{"description":"the name of the workflow","name":"Workflow Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the name of the submitter","name":"Submitter Name","place_holder":null,"type":"SHORT_RESPONSE"},{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they\u2019re in a sub-department","name":"Submitter Department","place_holder":null,"type":"DEPARTMENT"},{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","place_holder":null,"type":"SINGLE_SELECT"}],"signers":{},"type":"counter"},"workflowId":"fca4a546-fd5b-4202-9f6d-b26fa54f7cfe"}}';
    }

    public static String getPreSigActivityLogPayload(String testAction) {
        return '{"data":[{ "action": "' +
            testAction +
            '", "data": { "id": "3153ff49-27e3-408d-b013-47d11d581f45", "isAutomatic": false, "newStage": "Sign", "oldStage": "Review" }, "id": "7954fc46-1f8c-4d16-846b-f1aa2800fe50", "modifiedDate": "2021-11-16T21:49:47.658429Z", "type": "ticket stage", "user": { "email": "sean.super@evisort.com", "id": 100011, "isInternal": true, "name": "Sean Super" } }, { "action": "next stage", "data": { "id": "76b975f6-5eef-4903-b45e-cf451705cfdd", "isAutomatic": false, "newStage": "Review", "oldStage": "Edit" }, "id": "a96f3156-3257-48cd-8ffd-d2a852b48f91", "modifiedDate": "2021-11-16T21:49:44.269672Z", "type": "ticket stage", "user": { "email": "sean.super@evisort.com", "id": 100011, "isInternal": true, "name": "Sean Super" } }, { "action": "create ticket", "data": { "document": { "id": "19e02125-003b-4762-9c0b-f61dffa098d7", "name": "EKP-6011_2021-11-16" } }, "id": "eb1d7ad5-d5b4-4cfe-8f63-91232c6a8e40", "modifiedDate": "2021-11-16T21:49:02.100522Z", "type": "ticket", "user": { "email": "sean.super@evisort.com", "id": 100011, "isInternal": true, "name": "Sean Super" } } ]}';
    }

    public static String getPreSigParticipantPayload(String email, String name) {
        return getPreSigParticipantPayload(email, name, false);
    }

    public static String getPreSigParticipantPayload(String email, String name, Boolean multi) {
        String payload;

        if (multi) {
            payload =
                '{"data":[{"participant":{"email":"' +
                email +
                '","id":26402,"name":"' +
                name +
                '"},"role":"assignee"},' +
                '{"participant":{"email":"' +
                email +
                '1' +
                '","id":26403,"name":"' +
                name +
                '1' +
                '"},"role":"assignee"}]}';
        } else {
            payload =
                '{"data":[{"participant":{"email":"' +
                email +
                '","id":26402,"name":"' +
                name +
                '"},"role":"assignee"}]}';
        }
        return payload;
    }
}