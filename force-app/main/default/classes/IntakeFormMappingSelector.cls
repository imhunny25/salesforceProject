public with sharing class IntakeFormMappingSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     */
    public IntakeFormMappingSelector() {
        super(Schema.Intake_Form_Mapping__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public IntakeFormMappingSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Intake_Form_Mapping__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'CreatedById',
            'CreatedDate',
            'Intake_Form__c',
            'Name',
            'Salesforce_Field__c',
            'Workflow_Field__c',
            'Workflow_Field_Id__c',
            'Salesforce_Object__c',
            'Salesforce_Object_Type__c'
        };
    }

    public List<Intake_Form_Mapping__c> getByParentId(Id id) {
        Map<String, Object> queryArgs = new Map<String, Object>{ 'id' => id };

        String query = getDefaultQuery() + ' WHERE Intake_Form__c = :id';

        return (List<Intake_Form_Mapping__c>) Data.read(query, queryArgs, true, true, true);
    }

    public List<Intake_Form_Mapping__c> getChildMappingsByParentId(String workFlowId, Id parentId) {
        String objectName = parentId.getSObjectType().getDescribe().getName(); 
        Map<String, Object> queryArgs = new Map<String, Object>{ 'workFlowId' => workFlowId, 'objectName' => objectName };
        List<String> queryFields = new List<String>(this.getDefaultFields());

        String query =
            'SELECT ' +
            String.join(queryFields, ',') +
            ' , Intake_Form__r.Salesforce_Object__c' +
            ' FROM Intake_Form_Mapping__c' +
            ' WHERE Intake_Form__r.Workflow_Id__c = :workFlowId' +
            ' AND Intake_Form__r.Salesforce_Object__c =: objectName' +
            ' AND Salesforce_Object_Type__c =\'Child\'';

        return (List<Intake_Form_Mapping__c>) Data.read(query, queryArgs, true, true, true);
    }
}