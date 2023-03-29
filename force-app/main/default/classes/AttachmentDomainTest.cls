@isTest
private with sharing class AttachmentDomainTest {
    @testSetup
    static void setup() {
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;
            
            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;
            
            List <Evisort_Export_Filter__c> eefList = new List <Evisort_Export_Filter__c> ();
            
            Evisort_Export_Filter__c eef = TestFactory.getEvisortDocumentSyncFilters('Opportunity');
            String FileFilterBody='{"rows":[{"fieldName":"FileExtension","fieldLabel":"File Extension","fieldType":"STRING","operator":"Contains","value":"WORD","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1,"indexToShow":1}],"condition":"OR"}';
            eef.File_Filter_Body__c = FileFilterBody;
            eefList.add(eef);
            
            insert eefList;
        }
    }
    
    @isTest
    static void testCreateEvisortRecordWithoutEvisortPermissionSet() {
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            Evisort_Export_Filter__c eef = [SELECT Id, Name, File_Filter_Body__c, Is_Legacy__c, Is_Library__c, Object_Filter_Body__c, Object__c FROM Evisort_Export_Filter__c WHERE Object__c = 'Opportunity' LIMIT 1];                  
            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];
            
            String body = 'Data';
            Attachment attach = new Attachment();   	
            attach.Name = 'Unit Test Attachment';
            attach.body = EncodingUtil.base64Decode(body);
            attach.ContentType = 'application/msword';
            attach.parentId=testOppty.Id;
            
            Test.startTest();
            insert attach;
            Test.stopTest();
            
            Evisort_Export_Document__c exportDocument = [SELECT ContentVersion__c,ContentDocument__c, Title__c, File_Type__c, File_Size__c FROM Evisort_Export_Document__c];
            CSUtils.itShouldNotBe('Evisort Export Document Not null', null, exportDocument);
        }
    }   
    
    @isTest
    static void testDontCreateEvisortRecordFileType() {
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            Opportunity testOppty = [SELECT Id FROM Opportunity LIMIT 1];
            String body = 'Data';
            Attachment attach = new Attachment();   	
            attach.Name = 'Unit Test Attachment';
            attach.body = EncodingUtil.base64Decode(body);
            attach.ContentType = 'text/plain';
            attach.parentId=testOppty.Id;
            insert attach;
            
            attach.ContentType = 'text/csv';           
            
            Test.startTest();
            update attach;
            Test.stopTest();
                        
            List<Attachment__c> newAttachmen = [SELECT Attachment__c, Evisort__c FROM Attachment__c ];
            CSUtils.itShouldBe('Evisort Record does not exist', true, newAttachmen.isEmpty());
        }
    }
    
    @isTest
    static void testDeleteAttachment() {
        User u = UserTest.getEvisortAdminUser();
        
        System.runAs(u) {
            Opportunity testOppty = [SELECT Id, Name FROM Opportunity LIMIT 1];
            
            Attachment attach = new Attachment(
                Name = 'Delete Test Attachment.pdf',
                Body = EncodingUtil.base64Decode('Data'),
                ContentType = 'text',
                parentId=testOppty.Id
            );   	
            insert attach;      
            
            Evisort_Export_Object__c eeo = TestFactory.getExportObject('Opportunity', Constants.EXPORT_RUNNING, null);
            insert eeo;
            
            Evisort_Export_Document__c eed = new Evisort_Export_Document__c(
                Evisort_Export_Object__c = eeo.Id,
                Status__c = Constants.EXPORT_QUEUED,
                ContentDocument__c = String.valueOf(attach.Id),
                Record_ID__c = testOppty.Id,
                Record_Name__c = testOppty.Name,
                File_Size__c = null,
                Title__c = attach.Name
            );
            insert eed; 
            
            String myJSON = '{"status": "Completed", "evisortId": "1111111", "documentId" : "'+eed.id+'"}';
       
            RestRequest request = new RestRequest();
            request.requestUri ='';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueof(myJSON);
            
            RestContext.request = request;
            
            EvisortDocumentRestController.updateDocumentstatus();
            
            Test.startTest();
            
            List<Attachment__c> attachmentList = [SELECT Id FROM Attachment__c];
            CSUtils.itShouldBe('Attachment__c record created ', 1, attachmentList.size());
            
            delete attach;
            
            attachmentList = [SELECT Id FROM Attachment__c];
           // CSUtils.itShouldBe('Attachment__c record should not exist', true, attachmentList.isEmpty());
            
            Test.stopTest();
        }
    }
}