@isTest
private class AdminTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            List<Evisort_Field_Definition__c> definitions = new List<Evisort_Field_Definition__c>();
            for (Integer i = 0; i < 10; i++) {
                definitions.add(TestFactory.getFieldDefinition('Field ' + i, 'Text', 'Field'));
                definitions.add(TestFactory.getFieldDefinition('Provision ' + i, 'Text', 'Provision'));
            }
            insert definitions;

            Evisort_Export_Filter__c setting1 = TestFactory.getEvisortDocumentSyncFilters('Opportunity');
            insert setting1;
        }
    }

    @isTest
    static void testGetAuthStatus() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
            status.Authenticated__c = true;
            status.Authentication_Date__c = Datetime.now();
            upsert status;

            Test.startTest();

            AdminMsg.AuthStatus msg = AdminController.getAuthStatus();

            Test.stopTest();

            CSUtils.itShouldBe('Custom Setting Authenticated Value', true, msg.authenticated);
            CSUtils.itShouldBe(
                'Custom Setting Authentication Date',
                status.Authentication_Date__c,
                msg.authenticationDate
            );
            CSUtils.itShouldBe('Version Number', Constants.API_VERSION, msg.version);
        }
    }

    @isTest
    static void testVerifyAuthPositive() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            AdminMsg.VerifyAuthResponse msg = AdminController.verifyAuth();

            Test.stopTest();

            CSUtils.itShouldBe('Success', true, msg.success);

            Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
            CSUtils.itShouldBe('Custom Setting Authenticated Status', true, status.Authenticated__c);
            CSUtils.itShouldNotBe('Custom Setting Authentication Date', null, status.Authentication_Date__c);
        }
    }

    @isTest
    static void testVerifyAuthNegative() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockJson = '{ "error": "Forbidden" }';
            CalloutMock mock = new CalloutMock(403, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            AdminMsg.VerifyAuthResponse msg = AdminController.verifyAuth();

            Test.stopTest();

            CSUtils.itShouldBe('Success', false, msg.success);
            CSUtils.itShouldBe('Message Is Not Access Forbidden Label', System.Label.API_AccessForbidden, msg.message);
        }
    }

    @isTest
    static void testGetFieldDefinitions() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            List<AdminMsg.FieldDefinition> definitions = AdminController.getFieldDefinitions('Field');

            Test.stopTest();

            CSUtils.itShouldBe('Number of Field Definitions', 10, definitions.size());
            CSUtils.itShouldBe('Name of First Definition', 'Field 0', definitions[0].name);
            CSUtils.itShouldBe('Data Type of Fifth Definition', 'Text', definitions[4].dataType);
            CSUtils.itShouldBe('Is Active of Last Definition', true, definitions[9].isActive);
        }
    }

    @isTest
    static void testSyncFieldDefinitions() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{ "count": 2, "fields": [ { "label": "Field 0", "name": "Field 0", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } }, { "label": "A New Field", "name": "A New Field", "type": "string", "helpText": "", "active": true, "allowedValues": [], "section": { "name": "General Information" } } ] }';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();

            List<AdminMsg.FieldDefinition> definitions = AdminController.syncFieldDefinitions('Field');

            Test.stopTest();

            CSUtils.itShouldBe('Number of Field Definitions', 2, definitions.size());
            CSUtils.itShouldBe('Name of First Definition', 'A New Field', definitions[0].name);
        }
    }

    @isTest
    static void testSaveFieldDefinitions() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            List<Evisort_Field_Definition__c> definitions = [
                SELECT Id, CreatedDate, LastModifiedDate, Name, Label__c, Data_Type__c, Field_Type__c, isActive__c, isReadOnly__c
                FROM Evisort_Field_Definition__c
                WHERE Name IN ('Field 1', 'Field 4')
                ORDER BY Name
            ];
            CSUtils.itShouldBe('Number of Field Definitions to change', 2, definitions.size());

            List<AdminMsg.FieldDefinition> definitionMsg = new List<AdminMsg.FieldDefinition>();
            for (Evisort_Field_Definition__c efd : definitions) {
                definitionMsg.add(new AdminMsg.FieldDefinition(efd));
            }
            definitionMsg[0].isActive = false;
            definitionMsg[1].isActive = false;

            Test.startTest();

            List<AdminMsg.FieldDefinition> newDefinitions = AdminController.saveFieldDefinitions(
                JSON.serialize(definitionMsg),
                'Field'
            );

            Test.stopTest();

            CSUtils.itShouldBe('Definitions to check', 10, newDefinitions.size());
            CSUtils.itShouldBe('Field 1 is not active', false, newDefinitions[1].isActive);
            CSUtils.itShouldBe('Field 3 is active', true, newDefinitions[3].isActive);
            CSUtils.itShouldBe('Field 4 is not active', false, newDefinitions[4].isActive);
        }
    }

    @isTest
    static void testGetSyncCriteria() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            AdminMsg.SyncCriteria msg = AdminController.getSyncCriteria();

            Test.stopTest();

            CSUtils.itShouldBe('Number of Object Settings', 1, msg.objectSettings.size());
            CSUtils.itShouldBe('Name of first Object', 'Opportunity', msg.objectSettings[0].objectLabel);
            CSUtils.itShouldBe('Number of Objects is larger than 0', true, msg.objectList.size() > 0);
            CSUtils.itShouldBe('All Objects disabled', false, msg.allObjectsAndTypes);
            CSUtils.itShouldBe('No root folder', null, msg.rootFolder);
        }
    }

    @isTest
    static void testGetRecordTypes() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            String thisNamespace = AdminTest.class.getName().substringBefore('AdminTest').removeEnd('.');
            String objectName = (String.isBlank(thisNamespace)) ? 'Evisort__c' : thisNamespace + '__Evisort__c';

            Test.startTest();

            List<AdminMsg.ObjectRecordType> recordTypes = AdminController.getRecordTypes(objectName);

            Test.stopTest();

            // No record types should exist - very hard to test for record types because none are shipped
            // with this package. We should be excluding "Master"
            CSUtils.itShouldBe('Number of Record Types', 0, recordTypes.size());
        }
    }

    @isTest
    static void testGetNewProvisions() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            Boolean newProvisions = AdminController.getNewProvisions();

            Test.stopTest();

            CSUtils.itShouldBe('New Provision status', false, newProvisions);
        }
    }

    @isTest
    static void testSaveRootFolder() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            AdminController.saveRootFolder('Salesforce');

            Test.stopTest();

            CSUtils.itShouldBe('Root Folder', 'Salesforce', Evisort_Status__c.getOrgDefaults().Root_Folder__c);
        }
    }

    @isTest
    static void testSaveGlobalSettings() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            AdminController.saveGlobalSettings('Sync Criteria', true);

            Test.stopTest();

            CSUtils.itShouldBe('Sync criteria status', true, Evisort_Status__c.getOrgDefaults().Sync_Criteria__c);
        }
    }

    @isTest
    static void testSaveGlobalSettingsProvisions() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            AdminController.saveGlobalSettings('Sync Provisions', false);

            Test.stopTest();

            CSUtils.itShouldBe(
                'Sync new Provisions status',
                false,
                Evisort_Status__c.getOrgDefaults().Sync_New_Provisions__c
            );
        }
    }

    @isTest
    static void testSaveObjectSettings() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();

            AdminMsg.ObjectSetting setting = new AdminMsg.ObjectSetting();
            setting.id = '0';
            setting.objectLabel = 'Case';
            setting.newObject = true;
            setting.objectFilterBody = '{"rows":[{"fieldName":"Amount","fieldLabel":"Amount","fieldType":"CURRENCY","operator":"Not Equals To","value":"123","isPicklist":false,"fieldTypeLabel":"CURRENCY","fieldSOAPType":"DOUBLE","sequence":1}],"condition":"AND"}';
            setting.fileFilterBody = '{"rows":[{"fieldName":"FileType","fieldLabel":"File Type","fieldType":"STRING","operator":"Not Equals To","value":"pdf","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1}],"condition":"AND"}';

            String objectFilter = '{"rows":[{"fieldName":"Amount","fieldLabel":"Amount","fieldType":"CURRENCY","operator":"Not Equals To","value":"123","isPicklist":false,"fieldTypeLabel":"CURRENCY","fieldSOAPType":"DOUBLE","sequence":1}],"condition":"AND"}';
            String fileFilter = '{"rows":[{"fieldName":"FileType","fieldLabel":"File Type","fieldType":"STRING","operator":"Not Equals To","value":"pdf","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1}],"condition":"AND"}';
            String settingsStr = JSON.serialize(new List<AdminMsg.ObjectSetting>{ setting });
            
            AdminController.saveObjectSettings(settingsStr, '[]');

            setting.id = '1';
            setting.objectFilterBody = '';
            setting.enableLibraryFilter = true;
            setting.newObject = true;
            ContentWorkspace cw = TestFactory.getContentWorkspace();
            insert cw;
            setting.libraryName = cw.Name;
            setting.objectLabel = cw.Id;
            settingsStr = JSON.serialize(new List<AdminMsg.ObjectSetting>{ setting });
            
            AdminController.saveObjectSettings(settingsStr, '[]');

            List<Evisort_Export_Filter__c> syncCriteriaList = [SELECT Id, Name, Object__c, Is_Library__c, Object_Filter_Body__c, File_Filter_Body__c FROM Evisort_Export_Filter__c];

            Id libraryId;
            for (Evisort_Export_Filter__c eef : syncCriteriaList) {
                if (eef.Is_Library__c == true)
                    libraryId = eef.Id;
            }
       
            setting.id = '2';
            setting.objectLabel = 'Case';
            setting.enableLibraryFilter = false;
            setting.objectFilterBody = objectFilter;
            setting.newObject = false;
            setting.libraryName = '';
            settingsStr = JSON.serialize(new List<AdminMsg.ObjectSetting>{ setting });
            String deletedObjects = '["'+ libraryId +'"]';
            AdminController.saveObjectSettings(settingsStr, deletedObjects);

            Evisort_Export_Filter__c criteria  = [SELECT Id, Name, Object__c, Object_Filter_Body__c, File_Filter_Body__c FROM Evisort_Export_Filter__c WHERE Object__c = 'Case' LIMIT 1];

            CSUtils.itShouldBe('Object label on updated Object settings', 'Case', criteria.Object__c);
            CSUtils.itShouldBe('ObjectFilter on updated ', objectFilter, criteria.Object_Filter_Body__c);
            CSUtils.itShouldBe('FileFilter on updated ', fileFilter, criteria.File_Filter_Body__c); 
            
            Test.stopTest();
        }
    }

    @isTest
    static void testSaveObjectSettingsupdate() {
        User u = UserTest.getEvisortAdminUser();
        String objectFilter = '{"rows":[{"fieldName":"Amount","fieldLabel":"Amount","fieldType":"CURRENCY","operator":"Not Equals To","value":"123","isPicklist":false,"fieldTypeLabel":"CURRENCY","fieldSOAPType":"DOUBLE","sequence":1}],"condition":"AND"}';
        String fileFilter = '{"rows":[{"fieldName":"FileType","fieldLabel":"File Type","fieldType":"STRING","operator":"Not Equals To","value":"pdf","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1}],"condition":"AND"}';

        System.runAs(u) {
            Test.startTest();

            Evisort_Export_Filter__c criteria  = [SELECT Id, Name, Object__c, Object_Filter_Body__c, File_Filter_Body__c FROM Evisort_Export_Filter__c Where Object__c = 'Opportunity'];
            AdminMsg.ObjectSetting setting = new AdminMsg.ObjectSetting();
            setting.id = criteria.Id;
            setting.objectLabel = 'Opportunity';
            setting.objectFilterBody = '{"rows":[{"fieldName":"Amount","fieldLabel":"Amount","fieldType":"CURRENCY","operator":"Not Equals To","value":"123","isPicklist":false,"fieldTypeLabel":"CURRENCY","fieldSOAPType":"DOUBLE","sequence":1}],"condition":"AND"}';
            setting.fileFilterBody = '{"rows":[{"fieldName":"FileType","fieldLabel":"File Type","fieldType":"STRING","operator":"Not Equals To","value":"pdf","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1}],"condition":"AND"}';
            String settingsStr = JSON.serialize(new List<AdminMsg.ObjectSetting>{ setting }); 
            AdminController.saveObjectSettings(settingsStr, '[]');

            Test.stopTest();

			List<Evisort_Export_Filter__c> syncCriteriaList = [SELECT Id, Name, Object__c, Object_Filter_Body__c, File_Filter_Body__c FROM Evisort_Export_Filter__c];           
            CSUtils.itShouldBe('Number of Criteria', 1, syncCriteriaList.size());

            Evisort_Export_Filter__c newCriteria  = [SELECT Id, Name, Object__c, Object_Filter_Body__c, File_Filter_Body__c FROM Evisort_Export_Filter__c Where Object__c = 'Opportunity'];
            CSUtils.itShouldBe('ObjectFilter on updated ', objectFilter, newCriteria.Object_Filter_Body__c);
            CSUtils.itShouldBe('FileFilter on updated ', fileFilter, newCriteria.File_Filter_Body__c);
        }
    }

    @isTest
    static void testGetEvisortFolderId() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            List<Folder> folders = [SELECT Id FROM Folder WHERE Name = :Constants.EVISORT_FOLDER_NAME];

            Test.startTest();

            String folderId = AdminController.getEvisortFolderId();

            Test.stopTest();

            if (folders.size() == 0) {
                // Because we can't really test for the Folder, this will be null
                CSUtils.itShouldBe('Folder ID', null, folderId);
            } else {
                // We can see a folder named Evisort Reports, so check that we get the same ID
                CSUtils.itShouldBe('Folder ID', folders[0].Id, folderId);
            }
        }
    }
     @isTest
    static void testGetAllFieldsDetails() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            List<EvisortFieldWrapper> allFields = AdminController.getAllFieldsDetails('Opportunity');
            Test.stopTest();
            
            CSUtils.itShouldNotBe('Fields Name', null, allFields);
        }
    }
    
    @isTest 
    public static void getObjectsWithLabelsTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            List<Map<String, String>> objNames = AdminService.getObjectsWithLabels();
            Test.stopTest();
            
            CSUtils.itShouldNotBe('Objects With Labels ', 0, objNames.size());
        }
    }
    
    @isTest 
    public static void getObjectFieldNamesTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            String mockTokenJson = '{ "token": "faketokenhere" }';
            CalloutMock mock = new CalloutMock(mockTokenJson);
            String mockJson = '{"acceptedFileTypes":[".doc",".docx"],"conditions":[],"description":"","id":"61526389-95f9-49d1-a5d0-8614a055297b","implicitFields":{"Date Completed":{"description":"date the workflow is completed (finalize step completes)","name":"Date Completed","placeholder":null,"type":"DATE","value":{"value":null}},"Date Signed":{"description":"date the final signature is collected (either DocuSign is completed or all signatures completed offline and uploaded)","name":"Date Signed","placeholder":null,"type":"DATE","value":{"value":null}},"Paper Type":{"customSettings":{"options":[{"label":"Company Template","value":"company"},{"label":"Counterparty Paper","value":"counter"}]},"description":"Counterparty Paper OR Company Template - based on what is submitted in the intake form (if they submit a counterparty paper or choose to generate their own document)","name":"Paper Type","placeholder":null,"type":"SINGLE_SELECT","value":{"value":"counter"}},"Submitter Department":{"description":"the department or departments (can be multiple) that the user belongs to - should extend to parent departments if they\u2019re in a sub-department","name":"Submitter Department","placeholder":null,"type":"DEPARTMENT","value":{"value":[]}},"Submitter Name":{"description":"the name of the submitter","name":"Submitter Name","placeholder":null,"type":"SHORT_RESPONSE","value":{"value":"Praveen Prajapat"}},"Ticket Created Date":{"description":"date the ticket was created (submitted)","name":"Ticket Created Date","placeholder":null,"type":"DATE","value":{"value":null}},"Workflow Name":{"description":"the name of the workflow","name":"Workflow Name","placeholder":null,"type":"SHORT_RESPONSE","value":{"value":"single review"}}},"name":"single review","sections":[{"description":"","id":"3b5b699c-105d-4a70-b9df-a1d9cfe42f08","name":"Form Section 1","position":0,"questions":[{"description":null,"field":{"customSettings":{"defaultValue":{},"options":[]},"esignaturePlaceHolder":null,"id":"cae99049-1d01-4acb-abf3-82d7e976824f","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"text","options":{},"placeholder":null,"type":"SHORT_RESPONSE"},"fieldId":"cae99049-1d01-4acb-abf3-82d7e976824f","id":"dda1a34f-f9a7-48c6-8ea5-293d9d055c3f","isRequired":false,"name":"Text","position":0,"title":"Text"},{"description":null,"field":{"customSettings":{"defaultValue":{"country":"United States","state":"Alaska"},"options":[]},"esignaturePlaceHolder":null,"id":"177b11eb-762b-42c8-9027-7ebffc5e5c86","isEsignatureTag":false,"isEsignatureTagOptional":false,"isSignerField":false,"name":"address","options":{},"placeholder":null,"type":"ADDRESS"},"fieldId":"177b11eb-762b-42c8-9027-7ebffc5e5c86","id":"dc576f5a-edf9-4fc8-b2c7-e1a5b028037f","isRequired":false,"name":"Address","position":1,"title":"Address"}]}],"type":"counter","workflow":{"acceptedFileTypes":[".doc",".docx"],"builderId":"1e674e52-4be9-4527-9143-18b7dd8b0bc8","clientId":"e7608d55-45ca-4b6a-980f-dac6fd2232e1","createdDate":"2022-10-17T09:04:49.684728Z","description":"","id":"123abc","isDraft":false,"lastModifiedById":"665f3e7f-ce6d-44a5-89d6-d9841e71db89","modifiedDate":"2022-10-17T09:04:49.684728Z","name":"single review","parentId":"4b0ad9b0-a2e3-4a81-9ba8-c1009b8b390e","published":true,"type":"counter","versionNumber":9},"workflowId":"123abc"}';
            mock.addResponse(200, mockJson);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Test.startTest();
	 	    HttpResponse resp = IntakeFormService.getIntakeForm('123abc');
           	String res = resp.getBody();
       		workFlowWrapper wf = (workFlowWrapper) System.JSON.deserialize(res, workFlowWrapper.class);
			List<workFlowDetailsWrapper> objWrapper = new List<workFlowDetailsWrapper>();
            for(workflowSection section:wf.sections){
                for(workflowSectionQuestions question:section.questions){
				    objWrapper.add(new workFlowDetailsWrapper(question.name,question.field.id,question.field.name,question.field.type));
                }
        }
            Map<String,List<Map<String, String>>> objFieldNames = IntakeFormController.getFields('Account',objWrapper);
            Test.stopTest();
            CSUtils.itShouldBe('getFields Map Not Empty', false, objFieldNames.isEmpty());
    }
    }
    public static workFlowWrapper parse(String json){
		return (workFlowWrapper) System.JSON.deserialize(json, workFlowWrapper.class);
	}
    
    public class workFlowWrapper{
	//Test All Fields
	public workflowSection[] sections;
    }
	class workflowSection {
		public workflowSectionQuestions[] questions;
	}
	class workflowSectionQuestions {
		public QuestionsField field;
		public String name;	
	}
	class QuestionsField {
		public String id;	
		public String name;	
		public String type;	
	}
    
    class workFlowDetailsWrapper{
       public String workflowFieldName;
       public String workflowFieldId;
       public String questionName;
       public String WorkflowFieldType;
        
        public workFlowDetailsWrapper(String fieldname, String fieldId, String questionName, String fieldtype ){
            this.workflowFieldName = fieldname;
            this.workflowFieldId = fieldId;
            this.questionName = questionName;
            this.WorkflowFieldType = fieldtype;
        }
    }
    
    @isTest 
    public static void getContentWorkspaceTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            Test.startTest();
            
            List<ContentWorkspace> conWkspc = new List<ContentWorkspace>();
            conWkspc = AdminController.getLibraryOptionList();
            ContentWorkspace cw = TestFactory.getContentWorkspace();
            insert cw;
            conWkspc = AdminController.getLibraryOptionList();
            
            Test.stopTest();
            
            CSUtils.itShouldNotBe('ContentWorkspace ', 0, conWkspc.size());
        }
    } 
}