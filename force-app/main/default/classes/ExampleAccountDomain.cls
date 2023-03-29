public with sharing class ExampleAccountDomain extends Domain {
  /**
   * Constructor - remember to change the List sObject to your object from Account!
   * @param  records List of Records
   */
  public ExampleAccountDomain(List<Account> records) {
    super(records);
  }

  /***********************************
        Business logic
    ************************************/

  /**
   * A sample Account Action
   * @param  records Trigger.new
   * @param  oldMap  Trigger.oldMap
   */
  public void accountAction(List<Account> records, Map<Id, Account> oldMap) {
    // Do something here!
  }

  /*************************************
        Trigger functions
        Remove the ones you don't use
    **************************************/

  public override void onBeforeInsert() {
    List<Account> accounts = (List<Account>) this.records;

    this.accountAction(accounts, null);
  }

  public override void onAfterInsert() {
    List<Account> accounts = (List<Account>) this.records;

    this.accountAction(accounts, null);
  }

  public override void onBeforeUpdate(Map<Id, SObject> oldMap) {
    List<Account> accounts = (List<Account>) this.records;
    Map<Id, Account> accountMap = (Map<Id, Account>) oldMap;

    this.accountAction(accounts, accountMap);
  }

  public override void onAfterUpdate(Map<Id, SObject> oldMap) {
    List<Account> accounts = (List<Account>) this.records;
    Map<Id, Account> accountMap = (Map<Id, Account>) oldMap;

    this.accountAction(accounts, accountMap);
  }

  public override void onBeforeDelete() {
    List<Account> accounts = (List<Account>) this.records;

    this.accountAction(accounts, null);
  }

  public override void onAfterDelete() {
    List<Account> accounts = (List<Account>) this.records;

    this.accountAction(accounts, null);
  }

  public override void onAfterUndelete() {
    List<Account> accounts = (List<Account>) this.records;

    this.accountAction(accounts, null);
  }
}