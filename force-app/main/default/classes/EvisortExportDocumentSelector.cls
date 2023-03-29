public with sharing class EvisortExportDocumentSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public EvisortExportDocumentSelector() {
        super(Schema.Evisort_Export_Document__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public EvisortExportDocumentSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Evisort_Export_Document__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'ContentVersion__c',
            'Evisort_Export_Object__c',
            'Record_ID__c',
            'Status__c'
        };
    }
}