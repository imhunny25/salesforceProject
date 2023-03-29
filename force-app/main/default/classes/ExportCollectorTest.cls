@isTest
public with sharing class ExportCollectorTest {
    @isTest
    public static void testGetObjectList() {
        User u = UserTest.getEvisortAdminUser();

        System.runAs(u) {
            Test.startTest();
            List<String> response = ExportController.getObjectList();
            Test.stopTest();

            CSUtils.itShouldBe('Objects List', false, response.isEmpty());
        }
    }
}