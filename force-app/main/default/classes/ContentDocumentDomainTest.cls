@isTest
private class ContentDocumentDomainTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            ContentVersion cv = TestFactory.getContentVersion('TestContentVersion', 'Test Content Data', o.Id);
            insert cv;
        }
    }

    @isTest
    static void testDeleteDocument() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            List<ContentDocument> documents = [SELECT Id FROM ContentDocument];
            CSUtils.itShouldBe('Number of ContentDocuments', 1, documents.size());

            Test.startTest();

            delete documents[0];

            Test.stopTest();

            List<ContentDocument> newDocuments = [SELECT Id FROM ContentDocument];
            CSUtils.itShouldBe('Number of ContentDocuments After Delete', 0, newDocuments.size());
        }
    }
}