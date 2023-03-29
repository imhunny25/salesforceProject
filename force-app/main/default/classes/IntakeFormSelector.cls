public with sharing class IntakeFormSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     */
    public IntakeFormSelector() {
        super(Schema.Intake_Form__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public IntakeFormSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Intake_Form__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'CreatedBy.Name',
            'CreatedDate',
            'LastModifiedDate',
            'Name',
            'Salesforce_Object__c',
            'Workflow_Id__c',
            'Workflow_Name__c',
            'Workflow_Permanent_Link_Id__c'
        };
    }

    public Set<String> getSubQueryFields() {
        return new Set<String>{
            'Id',
            'Salesforce_Field__c',
            'Workflow_Field__c',
            'Workflow_Field_Id__c',
            'Salesforce_Object_Type__c'
        };
    }

    public List<Intake_Form__c> getFormsWithMappings(String objectName) {
        List<String> queryFields = new List<String>(this.getDefaultFields());
        List<String> subqueryFields = new List<String>(this.getSubQueryFields());

        String query = 'SELECT ' ;
        query += String.join(queryFields, ',');
        query += ', (SELECT ' ;
        query += String.join(subqueryFields, ', ');
        query += ' FROM Intake_Form_Mappings__r)';
        query += ' FROM Intake_Form__c ';
        if(String.isNotblank(objectName)){
            query += ' WHERE Salesforce_Object__c = \''+objectName + '\' ';
        }
        query += 'ORDER BY CreatedDate DESC';
        return (List<Intake_Form__c>) Data.read(query, new Map<String, Object>(), true, true, true);
    }

    public Intake_Form__c getFormsWithMappingsById(Id id) {
        List<String> queryFields = new List<String>(this.getDefaultFields());
        List<String> subqueryFields = new List<String>(this.getSubQueryFields());

        Map<String, Object> queryArgs = new Map<String, Object>{ 'id' => id };
        String query =
            'SELECT ' +
            String.join(queryFields, ',') +
            ', (SELECT ' +
            String.join(subqueryFields, ', ') +
            ' FROM Intake_Form_Mappings__r)' +
            ' FROM Intake_Form__c' +
            ' WHERE Id = :id' +
            ' ORDER BY CreatedDate DESC';

        List<Intake_Form__c> records = (List<Intake_Form__c>) Data.read(query, queryArgs, true, true, true);

        Intake_Form__c returnValue;
        if (records != null && records.size() == 1) {
            returnValue = records.get(0);
        } else {
            returnValue = null;
        }

        return returnValue;
    }

    public Intake_Form__c getFormsWithMappingsByWorkflowId(String id, String objectApiName) {
        List<String> queryFields = new List<String>(this.getDefaultFields());
        List<String> subqueryFields = new List<String>(this.getSubQueryFields());

        Map<String, Object> queryArgs = new Map<String, Object>{ 'id' => id, 'objectApiName' => objectApiName };
        String query =
            'SELECT ' +
            String.join(queryFields, ',') +
            ', (SELECT ' +
            String.join(subqueryFields, ', ') +
            ' FROM Intake_Form_Mappings__r)' +
            ' FROM Intake_Form__c' +
            ' WHERE Workflow_Id__c = :id' +
            ' AND Salesforce_Object__c = :objectApiName' +
            ' ORDER BY CreatedDate DESC';

        List<Intake_Form__c> records = (List<Intake_Form__c>) Data.read(query, queryArgs, true, true, true);

        Intake_Form__c returnValue;
        if (records != null && records.size() == 1) {
            returnValue = records.get(0);
        } else {
            returnValue = null;
        }

        return returnValue;
    }

    public List<Intake_Form__c> getFormsByObject(String objectApiName) {
        List<String> queryFields = new List<String>(this.getDefaultFields());
        Map<String, Object> queryArgs = new Map<String, Object>{ 'objectApiName' => objectApiName };
        String query =
            'SELECT ' +
            String.join(queryFields, ',') +
            ' FROM Intake_Form__c' +
            ' WHERE Salesforce_Object__c = :objectApiName' +
            ' ORDER BY CreatedDate DESC';

        return (List<Intake_Form__c>) Data.read(query, queryArgs, true, true, true);
    }
}