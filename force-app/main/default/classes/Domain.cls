/**
 * An alternative approach to the Domain pattern advocated by Apex Enterprise Patterns from FF-Lib Commons
 * <p>
 * The domain pattern defines an approach to Apex code organization that advocates placing
 * all logic specific to an object into a "Domain" class for that object. For example,
 * "AccountDomain.cls" would be the only class containing logic for manipulating data
 * from the standard Account object in Salesforce. This promotes code re-use, maintainability,
 * and simpler organization. The Domain class and sub-types extending this class should
 * NOT define methods that perform database queries. Those method should be placed
 * in a separate Selector class.
 * <p>
 * This base Domain class defines data and behavior for all sub-types to implement. Specifically,
 * the base Domain class defines trigger event methods that should be overridden by a sub-class.
 * <p>
 * This class leverages the CRUD/FLS "SecUtil" class for automatic validation of CRUD. If you
 * have a before trigger that modifies a field, then you need to manually check the security of
 * that field.
 * <p>
 * See ExampleAccountDomain and ExampleAccountTrigger for an example of how to use this.
 *
 * @todo: Provide mechanism for bypassing triggers
 *
 * @credit FinancialForce  "Apex Enterprise Patterns". Using some of the ideas in their Domain class here.
 * @author Eddie Blazer, CodeScience
 * @date January 14th, 2015
 */
public abstract with sharing class Domain {
  private static final Map<Type, Integer> TRIGGER_BYPASS = new Map<Type, Integer>();
  private static final Map<String, TriggerSettings__c> TRIGGER_SETTINGS = TriggerSettings__c.getAll();

  private TriggerSettings__c mySettings;
  private Type myType;
  private SObjectType mySOType;
  private Schema.DescribeSObjectResult mySODescribe;
  protected Boolean enforceCRUD;
  protected Boolean enforceFLS;
  protected Boolean enforceShr;
  protected Boolean stateful;
  public List<SObject> records { get; private set; } //

  protected Domain(List<SObject> records) {
    init(records);
  }

  protected virtual void init(List<SObject> records) {
    this.enforceCRUD = true;
    this.enforceFLS = true;
    this.enforceShr = true;
    this.stateful = true;
    this.records = records;
    this.mySOType = records.getSObjectType();
    this.mySODescribe = this.mySOType.getDescribe();
  }

  /**
   * @return The SObjectType of the object that this Domain works with.
   */
  public Schema.SObjectType getSObjectType() {
    return this.mySOType;
  }

  /**
   * @return The API name of the object that this Domain works with.
   */
  public String getSObjectName() {
    return this.mySODescribe.getName();
  }

  /**
   * @return The API name of this domain class.
   */
  public String getDomainLayerName() {
    return this.myType.getName();
  }

  /**
   * @return true if this Domain should enforce CRUD by default.
   */
  public Boolean isEnforcingCRUD() {
    return this.enforceCRUD;
  }

  /**
   * @return true if this Domain should enforce FLS by default.
   */
  public Boolean isEnforcingFLS() {
    return this.enforceFLS;
  }

  /**
   * @return true if this Domain should enforce Sharing Rules by default.
   */
  public Boolean isEnforcingShr() {
    return this.enforceShr;
  }

  /*
		Sub-Types should override the following methods as needed
	*/
  public virtual void onApplyDefaults() {
  }
  public virtual void onValidate() {
  }

  public virtual void onBeforeInsert() {
  }
  public virtual void onBeforeUpdate(Map<Id, SObject> oldMap) {
  }
  public virtual void onBeforeDelete() {
  }

  public virtual void onAfterInsert() {
  }
  public virtual void onAfterUpdate(Map<Id, SObject> oldMap) {
  }
  public virtual void onAfterDelete() {
  }
  public virtual void onAfterUndelete() {
  }

  private void handleBeforeInsert() {
    onApplyDefaults();
    onBeforeInsert();
  }
  private void handleBeforeUpdate() {
    onBeforeUpdate(Trigger.oldMap);
  }
  private void handleBeforeDelete() {
    onBeforeDelete();
  }
  private void handleAfterInsert() {
    onValidate();
    onAfterInsert();
  }
  private void handleAfterUpdate() {
    onValidate();
    onAfterUpdate(Trigger.oldMap);
  }
  private void handleAfterDelete() {
    onAfterDelete();
  }
  private void handleAfterUndelete() {
    onAfterUndelete();
  }

  /**
   * Invoke the trigger handler framework.
   * <p>
   * This method can only be called by a Trigger. The trigger should specify the
   * Apex class that implements the trigger logic.
   *
   * @param handler
   *
   */
  public static void triggerHandler(Type handler) {
    if (handler == null || !Trigger.isExecuting) {
      return;
    }

    List<SObject> data = Trigger.isDelete ? Trigger.old : Trigger.new;

    Domain d = (Domain) JSON.deserialize('{}', handler); // Ugly hack to instantiate an object instance that has no default constructor
    d.init(data);
    d.myType = handler;
    d.mySettings = TRIGGER_SETTINGS.get(d.myType.getName());
    if (d.mySettings == null) {
      d.mySettings = new TriggerSettings__c(
        IsDisabled__c = false,
        IsBeforeInsertDisabled__c = false,
        IsBeforeUpdateDisabled__c = false,
        IsBeforeDeleteDisabled__c = false,
        IsAfterInsertDisabled__c = false,
        IsAfterUpdateDisabled__c = false,
        IsAfterDeleteDisabled__c = false,
        IsAfterUndeleteDisabled__c = false
      );
    }
    if (!TRIGGER_BYPASS.containsKey(handler)) {
      TRIGGER_BYPASS.put(handler, 0);
    }

    LimitsSnapshot ls = new LimitsSnapshot(d.myType.getName());

    if (Trigger.isBefore) {
      if (Trigger.isInsert && !d.isBypassed('BeforeInsert')) {
        d.handleBeforeInsert();
      } else if (Trigger.isUpdate && !d.isBypassed('BeforeUpdate')) {
        d.handleBeforeUpdate();
      } else if (Trigger.isDelete && !d.isBypassed('BeforeDelete')) {
        d.handleBeforeDelete();
      }
    } else if (Trigger.isAfter) {
      if (Trigger.isInsert && !d.isBypassed('AfterInsert')) {
        d.handleAfterInsert();
      } else if (Trigger.isUpdate && !d.isBypassed('AfterUpdate')) {
        d.handleAfterUpdate();
      } else if (Trigger.isDelete && !d.isBypassed('AfterDelete')) {
        d.handleAfterDelete();
      } else if (Trigger.isUnDelete && !d.isBypassed('AfterUndelete')) {
        d.handleAfterUnDelete();
      }
    }

    ls.toLog();
  }

  public static void bypassTriggers(Type t) {
    if (!TRIGGER_BYPASS.containsKey(t)) {
      TRIGGER_BYPASS.put(t, 0);
    }
    Integer i = TRIGGER_BYPASS.get(t) + 1;
    TRIGGER_BYPASS.put(t, i);
  }

  public static void clearBypass(Type t) {
    if (!TRIGGER_BYPASS.containsKey(t)) {
      TRIGGER_BYPASS.put(t, 0);
      return;
    }
    Integer i = Math.max(TRIGGER_BYPASS.get(t) - 1, 0);
    TRIGGER_BYPASS.put(t, i);
  }

  @TestVisible
  private Boolean isBypassed(String tContext) {
    System.debug(LoggingLevel.ERROR, TRIGGER_BYPASS);
    return TRIGGER_BYPASS.get(this.myType) > 0 ||
      mySettings.IsDisabled__c ||
      ((Boolean) mySettings.get('Is' + tContext + 'Disabled__c'));
  }
}