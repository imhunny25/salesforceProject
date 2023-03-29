/**
 * Example Selector class for Accounts.
 *
 * Usage in code:
 * ExampleAccountSelector selector = new ExampleAccountSelector();  // Use false, false, false to ignore CRUD/FLS/SHR
 * Account oneAccount = (Account)selector.getRecordById('001whatever');
 * List<Account> twoAccounts = (List<Account>)selector.getRecordsByIds(new Set<Id>{'001whatever', '001another'});
 * List<Account> ownedAccounts = selector.getAccountsByOwnership('Public');
 *
 * // Add Ownership to existing default query getting by Id
 * Account ownerAccountWithName = (Account)selector.getRecordById('001whatever', new Set<String>{'Ownership'}, true);
 *
 * // Get JUST Ownership by Id
 * Account ownerAccountOnly = (Account)selector.getRecordById('001whatever', new Set<String>{'Ownership'});
 */

public with sharing class ExampleAccountSelector extends Selector {
  /**
   * Constructor that assumes we are enforcing CRUD/FLS/SHR
   * Remember to change the sObject name in here from Account to your object!
   */
  public ExampleAccountSelector() {
    super(Schema.Account.SObjectType);
  }

  /**
   * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
   * Remember to change the sObject name in here from Account to your object!
   * @param  enforceCRUD Enforce CRUD
   * @param  enforceFLS  Enforce FLS
   * @param  enforceShr  Enforce Sharing Rules
   */
  public ExampleAccountSelector(
    Boolean enforceCRUD,
    Boolean enforceFLS,
    Boolean enforceShr
  ) {
    super(Schema.Account.SObjectType, enforceCRUD, enforceFLS, enforceShr);
  }

  /**
   * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
   * @return   Set of Strings that contain the default fields for this object
   */
  public override Set<String> getDefaultFields() {
    return new Set<String>{ 'Id', 'Name', 'OwnerId' };
  }

  /**
   * Custom Method example - getting Accounts by checking against their Ownership.
   * Create methods like this when you want to do more than just get records by their ID's
   * Use getRecordById() and getRecordsByIds() for those simple queries
   * @param  ownerships Set of Ownership Strings
   * @return            List of Accounts sorted by LastModifiedDate, maximum 100.
   */
  public List<Account> getAccountsByOwnership(Set<String> ownerships) {
    Map<String, Object> queryArgs = new Map<String, Object>{
      'ownerships' => ownerships
    };

    List<String> queryFields = new List<String>(this.getDefaultFields());
    queryFields.add('Ownership');
    queryFields.add('LastModifiedDate');

    String query = 'SELECT ' + String.join(queryFields, ',');
    query += ' FROM Account';
    query += ' WHERE Ownership IN :ownerships';
    query += ' ORDER BY LastModifiedDate DESC';
    query += ' LIMIT 100';

    return (List<Account>) Data.read(
      query,
      queryArgs,
      this.isEnforcingCRUD(),
      this.isEnforcingFLS(),
      this.isEnforcingShr()
    );
  }
  public List<Account> getAccountsByOwnership(String ownership) {
    return getAccountsByOwnership(new Set<String>{ ownership });
  }
}