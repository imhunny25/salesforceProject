public with sharing class EvisortFieldValueSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public EvisortFieldValueSelector() {
        super(Schema.Evisort_Field_Value__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public EvisortFieldValueSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Evisort_Field_Value__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'Checkbox_Field__c',
            'Date_Field__c',
            'Evisort__c',
            'Evisort_Field_Definition__c',
            'External_ID__c',
            'Number_Field__c',
            'Picklist_Value_Selected__c',
            'Text_Field__c'
        };
    }

    /**
     * Get All Field Values assigned to a specific Field Definition
     * @param  definitionIds Set of Evisort Field Definition IDs
     * @return               List of Evisort Field Values
     */
    public List<Evisort_Field_Value__c> getValuesByDefinitionIds(Set<Id> definitionIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'definitionIds' => definitionIds
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Field_Value__c';
        query += ' WHERE Evisort_Field_Definition__c IN :definitionIds';

        return (List<Evisort_Field_Value__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }
}