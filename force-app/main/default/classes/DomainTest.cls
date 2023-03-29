@isTest
public class DomainTest {
  private static Boolean isNotSetup = true; // Used to determine if the setup method has been called by other setups

  @TestSetup
  public static void setup() {
    if (isNotSetup) {
      List<Account> acctsToSetup = new List<Account>();
      for (Integer i = 0; i < 200; i++) {
        acctsToSetup.add(new Account(Name = 'Test Customer Account: ' + i));
      }
      insert acctsToSetup;

      isNotSetup = false;
    }
  }

  @isTest
  public static void getSObjectType() {
    AccountDomainTest adt = new AccountDomainTest(
      [SELECT Id, Name FROM Account]
    );

    System.assertEquals(Schema.Account.SObjectType, adt.getSObjectType());
  }

  @isTest
  public static void getSObjectName() {
    AccountDomainTest adt = new AccountDomainTest(
      [SELECT Id, Name FROM Account]
    );

    System.assertEquals('Account', adt.getSObjectName());
  }

  @isTest
  public static void isEnforcing() {
    AccountDomainTest adt = new AccountDomainTest(
      [SELECT Id, Name FROM Account]
    );

    System.assertEquals(true, adt.isEnforcingCRUD());
    System.assertEquals(true, adt.isEnforcingFLS());
    System.assertEquals(true, adt.isEnforcingShr());

    adt.noCRUDFLSShr();
    System.assertEquals(false, adt.isEnforcingCRUD());
    System.assertEquals(false, adt.isEnforcingFLS());
    System.assertEquals(false, adt.isEnforcingShr());
  }

  /**
   * A concrete instance of a selector that uses a standard object
   * so that we can have out-of-the
   */
  public class AccountDomainTest extends Domain {
    public AccountDomainTest(List<Account> records) {
      super(records);
    }

    public void noCRUDFLSShr() {
      // Trigger should run regardless of user's CRUD/FLS/Sharing.
      this.enforceCRUD = false;
      this.enforceFLS = false;
      this.enforceShr = false;
    }
  }
}