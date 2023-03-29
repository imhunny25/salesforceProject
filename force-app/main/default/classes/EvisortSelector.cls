public with sharing class EvisortSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public EvisortSelector() {
        super(Schema.Evisort__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public EvisortSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Evisort__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'Name',
            'Document_Status__c',
            'External_ID__c',
            'Original_File_Name__c',
            'Record_ID__c'
        };
    }

    /**
     * Gets an Evisort Record ID with the Field Values join
     * We do this to encapsulate the call to this.getRecordById() due to the nature of the inner query
     * @param  evisortRecordId Evisort Record ID
     * @return                 Evisort Record
     */
    public Evisort__c getEvisortRecordWithValues(Id evisortRecordId) {
        // prettier-ignore
        List<String> valueFields = new List<String> {
            'Checkbox_Field__c',
            'Date_Field__c',
            'Number_Field__c',
            'Picklist_Value_Selected__c',
            'Text_Field__c',
            'Evisort_Field_Definition__r.Name',
            'Evisort_Field_Definition__r.Data_Type__c',
            'Evisort_Field_Definition__r.Field_Type__c',
            'Evisort_Field_Definition__r.Label__c',
            'Evisort_Field_Definition__r.Picklist_Values__c',
            'Evisort_Field_Definition__r.Section_Name__c',
            'Evisort_Field_Definition__r.isReadOnly__c'
        };
        String subQuery = ' (SELECT ' + String.join(valueFields, ', ');
        subQuery += ' FROM Evisort_Field_Values__r';
        subQuery += ' ORDER BY Evisort_Field_Definition__r.Field_Type__c, Evisort_Field_Definition__r.Section_Name__c, Evisort_Field_Definition__r.Label__c)';

        // Interesting bug in our CRUD/FLS library - the inner query cannot be the first element in the SOQL query
        // So, we put in the default fields first, then add the subquery
        // If we used getRecordById with the third parameter as true, it would put the subquery in first
        // and THEN add the default fields, causing an exception
        Set<String> queryFields = new Set<String>(this.getDefaultFields());
        queryFields.add(subQuery);

        return (Evisort__c) this.getRecordById(evisortRecordId, queryFields, false);
    }

    /**
     * Gets an Evisort Record with just the field values changed after the submitted date
     * This is done instead of getRecordById() because of the where clause in the subQuery
     * @param  evisortRecordId Evisort Record ID
     * @param  modifiedSince   Datetime to check for values
     * @return                 Evisort record
     */
    public Evisort__c getEvisortRecordWithChangedValues(Id evisortRecordId, Datetime modifiedSince) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{
            'evisortRecordId' => evisortRecordId,
            'modifiedSince' => modifiedSince
        };
        // prettier-ignore
        List<String> valueFields = new List<String> {
            'Checkbox_Field__c',
            'Date_Field__c',
            'Number_Field__c',
            'Picklist_Value_Selected__c',
            'Text_Field__c',
            'Evisort_Field_Definition__r.Name',
            'Evisort_Field_Definition__r.Data_Type__c',
            'Evisort_Field_Definition__r.isActive__c',
            'LastModifiedDate'
        };
        String subQuery = ' (SELECT ' + String.join(valueFields, ', ');
        subQuery += ' FROM Evisort_Field_Values__r';
        subQuery += ' WHERE LastModifiedDate >= :modifiedSince';
        subQuery += '   AND Evisort_Field_Definition__r.isActive__c = true)';

        List<String> queryFields = new List<String>(this.getDefaultFields());
        queryFields.add(subQuery);

        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort__c';
        query += ' WHERE Id = :evisortRecordId';

        List<Evisort__c> records = (List<Evisort__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );

        if (!records.isEmpty()) {
            return records[0];
        }

        return null;
    }

    /**
     * Gets Evisort records by their Evisort IDs (which acts as an External ID)
     * @param  evisortIds Set of External IDs
     * @return            List of Evisort records
     */
    public List<Evisort__c> getRecordsByEvisortIds(Set<String> evisortIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'evisortIds' => evisortIds
        };
        // prettier-ignore
        List<String> valueFields = new List<String> {
            'Evisort_Field_Definition__r.Name',
            'Evisort_Field_Definition__r.Field_Type__c'
        };
        String subQuery = ' (SELECT ' + String.join(valueFields, ', ');
        subQuery += ' FROM Evisort_Field_Values__r)';

        List<String> queryFields = new List<String>(this.getDefaultFields());
        queryFields.add(subQuery);

        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort__c';
        query += ' WHERE External_ID__c IN :evisortIds';

        return (List<Evisort__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets a list of Evisort records for a specific associated record's virtual lookup
     * @param  recordId Record ID of associated record
     * @return          List of Evisort records
     */
    public List<Evisort__c> getRecordsByAssociatedId(Id recordId) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'recordId' => recordId
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort__c';
        query += ' WHERE Record_ID__c = :recordId';
        query += ' ORDER BY Original_File_Name__c';

        return (List<Evisort__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets a list of Evisort records
     * @param recordId parent record id
     * @param externalId external id
     * @return List of Evisort records
     */
    public List<Evisort__c> getRecordsByExternalIdAndParentId(String externalId, String parentId) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'externalId' => externalId,
            'parentId' => parentId
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort__c';
        query += ' WHERE Record_ID__c = :parentId';
        query += ' AND External_ID__c = :externalId';

        return (List<Evisort__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }
}