@isTest
public with sharing class EvisortEmailShareTest {
    @testSetup
    public static void setup() {
        Intake_Form__c form = TestFactory.getIntakeForm('Account', '123', 'Test Form');
        insert form;
        Account a = new Account(Name = 'Test Account');
        insert a;
        Opportunity opp = TestFactory.getOpportunity('Test Opportunity',a.id);
        insert opp;
        
        List<Contact> listOfContacts = new List<Contact>();
        for(integer i=0;i<2;i++){
            Contact c = new Contact();
            c.LastName = 'Test'+i;
            c.AccountId = a.id;
            c.Email = 'fake'+i+'email@fake.com';
            listOfContacts.add(c);
        }
        insert listOfContacts;
    }
    
    @isTest
    public static void searchTestAccountObject() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            
            Account a = [SELECT Id, Name FROM Account LIMIT 1];
            
            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];
            
            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, a.Id);
            insert ticket;
            Test.startTest();
            List<Contact> contact = EvisortEmailShare.searchContacts(ticket.id);
            System.assertEquals(2, contact.size(), 'Total Contact Size Related to Account');
            Test.stopTest();}
    }
    @isTest
    public static void searchTestOpportunityObject() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {
            
            Opportunity o = [SELECT Id, Name FROM Opportunity LIMIT 1];

            Intake_Form__c form = [SELECT Id, Workflow_Id__c, Workflow_Name__c FROM Intake_Form__c LIMIT 1];
            
            Evisort_Ticket__c ticket = TestFactory.getEvisortTicket('12345', 'test ticket', form.Id, o.Id);
            insert ticket;
            Test.startTest();
            List<Contact> contact = EvisortEmailShare.searchContacts(ticket.id);
            System.assertEquals(2, contact.size(), 'Total Contact Size Related to Account');
            Test.stopTest();}
    }
    @isTest
    public static void sendEmailTest() {
        User u = UserTest.getEvisortAdminUser();
        System.runAs(u) {

            Opportunity o = [SELECT Id, Name FROM Opportunity LIMIT 1];

            ContentVersion cv = TestFactory.getContentVersion('TestContentVersion', 'Test Content Data', o.Id);
            insert cv;
            
            String emailDetails = '{"toAddress":["fake1email@fake.com"],"ccAddress":["fake2email@fake.com"],"bccAddress":[],"subject":"Document shared Test","body":"Test Please find documents for your review attached."}';
            Test.startTest(); EvisortEmailShare.sendEmailController(emailDetails,cv.id);
            Integer beforeInvocations = Limits.getEmailInvocations();
            System.assertEquals(1,beforeInvocations,'one email sent');
            Test.stopTest();
        }
    }
    
}