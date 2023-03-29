public with sharing class EvisortEmailShare {
    /**
* Gets list of Contact for send Email
* @param  evsTicketRecordId EvisortRecordId
* @return     List of Contact Records 
*/
    @AuraEnabled
    public static List<Contact> searchContacts(String evsTicketRecordId) {
        List<Contact> listOfContacts = new List<Contact>();
        try {
            String evisortTicketQuery = 'SELECT Id, Name, Parent_Record_ID__c FROM Evisort_Ticket__c WHERE Id =: evsTicketRecordId';
            Map<String, Object> queryArgs = new Map<String, Object>{ 
                'evsTicketRecordId' => evsTicketRecordId
            };
            List<Evisort_Ticket__c> evisortTicket = Data.read(evisortTicketQuery, queryArgs, true, true, true);
            DescribeSObjectResult descResult = Id.valueOf(evisortTicket[0].Parent_Record_ID__c).getSObjectType().getDescribe();
            String objectName = descResult.getName();
            String accountId;
            Set<String> accountIds = new Set<String>();
            String query = '';
            Schema.SobjectField accountIdField;
            Map<String, Object> accountQueryArgs = new Map<String, Object>(); 
            
            if (objectName == 'Account') {
                accountId = evisortTicket[0].Parent_Record_ID__c;
                accountIds.add(accountId);  
            } else {
                for(Schema.SobjectField objectField: descResult.fields.getMap().Values())
                {
                    if(objectField.getDescribe().getType() == Schema.DisplayType.REFERENCE && objectField.getDescribe().getReferenceTo()[0] == Schema.Account.SObjectType)
                    {
                        query = 'SELECT Id, ' + objectField + ' FROM ' + objectName + ' WHERE Id = \'' + evisortTicket[0].Parent_Record_ID__c +'\'';
                        query += ' LIMIT 1';
                        accountIdField = objectField;
                        accountQueryArgs.put('objectField',objectField);
                        accountQueryArgs.put('objectName',objectName);
                        accountQueryArgs.put('evisortTicketParentRecordID',evisortTicket[0].Parent_Record_ID__c);
                        List<SObject> sobj = Data.read(query, accountQueryArgs, true, true, true);
                		accountId = (String)sobj[0].get(accountIdField);
                        accountIds.add(accountId);  
                    } 
                }
            }
            
            if(accountIds.size() > 0) {
                String contactQuery = 'SELECT Id, Name, Email FROM Contact WHERE AccountId IN: accountIds AND Email != Null';
                Map<String, Object> contactQueryArgs = new Map<String, Object>{ 
                    'accountIds' => accountIds
                };
                List<Contact> contactsList = Data.read(contactQuery, contactQueryArgs, true, true, true);
                if(!contactsList.isEmpty()){
                    for (Contact con: contactsList){
                        listOfContacts.add(con);
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return listOfContacts;
    }
    
    @AuraEnabled
    public static void sendEmailController(String emailDetailStr, String conVerId) {
        
        Messaging.reserveSingleEmailCapacity(1);
        try {
            EmailWrapper emailDetails = (EmailWrapper) JSON.deserialize(emailDetailStr, EmailWrapper.class);
            String query ='SELECT Id, Title, ContentDocumentId,FileExtension, ContentBodyId, FileType, VersionData FROM ContentVersion WHERE Id =: conVerId';
            Map<String, Object> queryArgs = new Map<String, Object>{ 
                'conVerId' => conVerId
            };
            List<ContentVersion> cv = Data.read(query, queryArgs, true, true, true);
            Blob body = cv[0].VersionData;
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(cv[0].Title +'.'+ cv[0].FileExtension);
            efa.setBody(body);
            Messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
            mail.setToAddresses(emailDetails.toAddress);
            mail.setCcAddresses(emailDetails.ccAddress);
            mail.setBccAddresses(emailDetails.bccAddress);
            mail.setReplyTo(UserInfo.getUserEmail());
            mail.setSenderDisplayName(UserInfo.getName());
            mail.setSubject(emailDetails.subject);
            mail.setHtmlBody(emailDetails.body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            mail.setSaveAsActivity(true);
            Messaging.sendEmail(new List<messaging.SingleEmailMessage>{ mail });
        } catch (exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    class EmailWrapper {
        public List<String> toAddress;
        public List<String> ccAddress;
        public List<String> bccAddress;
        public String subject;
        public String body;
    }
}