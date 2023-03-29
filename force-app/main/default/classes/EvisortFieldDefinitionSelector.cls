public with sharing class EvisortFieldDefinitionSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public EvisortFieldDefinitionSelector() {
        super(Schema.Evisort_Field_Definition__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public EvisortFieldDefinitionSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Evisort_Field_Definition__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'CreatedDate',
            'LastModifiedDate',
            'Name',
            'Label__c',
            'Data_Type__c',
            'Field_Type__c',
            'isActive__c',
            'Picklist_Values__c',
            'Section_Name__c',
            'isReadOnly__c'
        };
    }

    /**
     * Returns a Map of results using record name as key
     * @return   Map of records that contain the default fields for this object
     * @param    String query arg that filters result set by Field Type, all are provided when null
     */
    public List<Evisort_Field_Definition__c> getDefaultFieldsByFieldType(String fieldTypeFilter) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'fieldType' => fieldTypeFilter
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Field_Definition__c';
        if (fieldTypeFilter != null) {
            query += ' WHERE Field_Type__c = :fieldType';
        }

        query += ' ORDER BY Label__c';

        return (List<Evisort_Field_Definition__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets the current active Field Definitions of both Fields and Provisions
     * @return   List of Evisort Field Definition records
     */
    public List<Evisort_Field_Definition__c> getActiveDefinitions() {
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',');
        query += ' FROM Evisort_Field_Definition__c';
        query += ' WHERE isActive__c = TRUE';

        return (List<Evisort_Field_Definition__c>) Data.read(
            query,
            null,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets Field Definitions by their Name for checking if they exist, whether they are active or not
     * @param  definitionNames Set of Strings containing Name fields to check for
     * @return                 List of Evisort Field Definition records
     */
    public List<Evisort_Field_Definition__c> getDefinitionsByName(Set<String> definitionNames) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'definitionNames' => definitionNames
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Field_Definition__c';
        query += ' WHERE Name IN :definitionNames';

        return (List<Evisort_Field_Definition__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }
}