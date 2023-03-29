/**
 * This test class should be used as a central place for creating all
 * personas user records, and assigning those user records to any
 * permission sets utilized by the application.
 * <p>
 * This class should be modified to include methods for each persona.
 */
@isTest
public class UserTest {
    private static Integer userNumber = 0;

    public static User createStandardUser() {
        return createUserWithProfile([SELECT Id FROM Profile WHERE Name = 'Standard User'].Id);
    }

    public static User createPlatformUser() {
        return createUserWithProfile([SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id);
    }

    public static User createUserWithProfile(Id profileId) {
        Integer userNum = userNumber++;
        String email = 'unit.test.user+' + userNum + '.' + System.currentTimeMillis() + '@' + UserInfo.getOrganizationId() + '.test.com';
        User u = new User(
            FirstName = 'Test',
            LastName = 'User ',
            Email = email,
            Username = email,
            Alias = ('tuser' + userNum).right(8),
            Phone = '503-555-1212',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        if (Userinfo.isMultiCurrencyOrganization()) {
            ((SObject) u).put('CurrencyIsoCode', 'USD');
        }
        insert u;

        return u;
    }

    /**
     * Default setup for Evisort Admin
     */
    public static User getEvisortAdminUser() {
        List<String> permissionSets = new List<String>{ Constants.PERMSETNAME_EVISORTADMIN };

        User output = getUserByPermissionSet(Constants.PERMSETNAME_EVISORTADMIN);
        if (output == null) {
            output = createUser(permissionSets);
        }

        return output;
    }

    public static User getEvisortUser() {
        List<String> permissionSets = new List<String>{ Constants.PERMSETNAME_EVISORTUSER };

        User output = getUserByPermissionSet(Constants.PERMSETNAME_EVISORTUSER);
        if (output == null) {
            output = createUser(permissionSets);
        }

        return output;
    }

    private static User getUserByPermissionSet(String permissionSetName) {
        User output;
        List<PermissionSetAssignment> assignments = [
            SELECT Id, AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :permissionSetName AND Assignee.Name = 'Test User'
        ];

        if (assignments != null && !assignments.isEmpty()) {
            Id assigneeId = assignments[0].AssigneeId;
            output = new User(Id = assigneeId);
        }

        return output;
    }

    private static User createUser(List<String> permissionSets) {
        User u = createStandardUser();

        // add user to perm sets
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSets]) {
            psas.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id));
        }
        insert psas;

        return u;
    }
}