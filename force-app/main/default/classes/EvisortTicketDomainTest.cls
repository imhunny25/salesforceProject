@isTest
public with sharing class EvisortTicketDomainTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;

            Intake_Form__c i = TestFactory.getIntakeForm('Account', '123', 'Test');
            insert i;
        }
    }

    @isTest
    public static void testEvisortTicketInsert() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Account a = [SELECT Id FROM Account LIMIT 1];

            Intake_Form__c i = [SELECT Id FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c et = TestFactory.getEvisortTicket('123', 'Test Name', i.Id, a.Id);

            Test.startTest();
            insert et;
            Test.stopTest();

            Evisort_Ticket__c eti = [SELECT Id, Status__c FROM Evisort_Ticket__c WHERE Id = :et.Id];
            CSUtils.itShouldBe('Ticket Status', null, eti.Status__c);
        }
    }

    @isTest
    public static void testEvisortTicketUpdate() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Account a = [SELECT Id FROM Account LIMIT 1];

            Intake_Form__c i = [SELECT Id FROM Intake_Form__c LIMIT 1];

            Evisort_Ticket__c et = TestFactory.getEvisortTicket('123', 'Test Name', i.Id, a.Id);
            insert et;

            et.Status__c = 'Completed';

            Test.startTest();
            update et;
            Test.stopTest();

            Evisort_Ticket__c eti = [SELECT Id, Status__c FROM Evisort_Ticket__c WHERE Id = :et.Id];
            CSUtils.itShouldBe('Ticket Status', 'Completed', eti.Status__c);
        }
    }
}