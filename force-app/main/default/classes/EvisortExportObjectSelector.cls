public with sharing class EvisortExportObjectSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public EvisortExportObjectSelector() {
        super(Schema.Evisort_Export_Object__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public EvisortExportObjectSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Evisort_Export_Object__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
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
            'Completed__c',
            'Oversized__c',
            'Errored__c',
            'File_Types__c',
            'Name',
            'Number_of_Documents__c',
            'Object__c',
            'Record_Types__c',
            'Status__c',
            'Total_Size__c',
            'Evisort_Export_Filter__c',
            'Evisort_Export_Filter__r.Name',
            'Evisort_Export_Filter__r.Is_Library__c',
            'Evisort_Export_Filter__r.Is_Legacy__c'
        };
    }


    public Set<String> getDefaultExportFilterFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'Name',
            'Is_Library__c',
            'CreatedDate',
            'Is_Legacy__c',
            'Object__c',
            'Object_Filter_Body__c',
            'File_Filter_Body__c',
            'Library_Mapping__c'
        };
    }

    public Set<String> getContentWorkSpaceFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'Name'
        };
    }

    public Set<String> getDocumentFieldSyncMappingFields() {
        // prettier-ignore
        return new Set<String>{
            'Id', 
            'Name', 
            'Evisort_Document_Field_Id__c',
            'Evisort_Field_Definition__r.Name',
            'Evisort_Field_Definition__r.Data_Type__c',
            'Salesforce_Field_Name__c',
            'Field_Label__c',
            'Evisort_Export_Filter__c',
            'Evisort_Document_Field_Name__c',
            'Evisort_Field_Definition__c',
            'Object__c',
            'CreatedDate',
            'LastModifiedDate' 
        };
    }

    /**
     * Gets all of the Export Filter that have been explicitly defined
     * @param  status (Optional) Status
     * @return        List of Evisort Export Filter records
     */
    public List<Evisort_Export_Filter__c> getExportObjects() {
        List<String> queryFields = new List<String>(this.getDefaultExportFilterFields());
        String query = 'SELECT '+ String.join(queryFields, ',') +'  FROM Evisort_Export_Filter__c';
        query += ' ORDER BY Object__c, CreatedDate DESC';

        return (List<Evisort_Export_Filter__c>) Data.read(
            query,
            null,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }


    /**
     * Gets all of the Export Filter that have been explicitly defined
     * @param  exportFilterIds  Evisort Export Filter 
     * @return        List of Evisort Export Filter records
     */
    public List<Evisort_Export_Filter__c> getExportFilterByIds(Set<Id> exportFilterIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'exportFilterIds' => exportFilterIds
        };  
        List<String> queryFields = new List<String>(this.getDefaultExportFilterFields());
        String query = 'SELECT '+ String.join(queryFields, ',') +'  FROM Evisort_Export_Filter__c';
        if (!exportFilterIds.isEmpty()) {
            query += ' WHERE Id IN: exportFilterIds';
        }
        query += ' ORDER BY Object__c, CreatedDate DESC';

        return (List<Evisort_Export_Filter__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets all of the Export Objects that have been explicitly defined
     * @param  status (Optional) Status
     * @return        List of Evisort Export Object records
     */
    public List<Evisort_Export_Object__c> getEvisortExportObjects(String status) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'status' => status
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Export_Object__c';
        if (!String.isBlank(status)) {
            query += ' WHERE Status__c = :status';
        }
        query += ' ORDER BY Object__c, CreatedDate DESC';

        return (List<Evisort_Export_Object__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets all of the Export Object records for a list of Objects
     * @param  objectNames API Names of the Objects
     * @return             List of Evisort Export Object records
     */
    public List<Evisort_Export_Object__c> getObjectJobs(List<String> objectNames) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'objectNames' => objectNames
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Export_Object__c';
        query += ' WHERE Object__c IN :objectNames';
        query += ' ORDER BY CreatedDate DESC';

        return (List<Evisort_Export_Object__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    public List<Evisort_Export_Filter__c> getSyncDocObjectJobs(List<String> objectNames) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'objectNames' => objectNames
        };
        String query = 'SELECT ID, Is_Library__c , Is_Legacy__c, CreatedDate, Name, Object__c, Object_Filter_Body__c, File_Filter_Body__c  FROM Evisort_Export_Filter__c';
        query += ' WHERE Object__c IN :objectNames AND Is_Legacy__c = true';
        query += ' ORDER BY CreatedDate DESC';

        return (List<Evisort_Export_Filter__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets 5 Documents for a running job
     * @return   Evisort Export Object record with Documents subquery
     */
    public List<Evisort_Export_Object__c> getDocumentsForRunningJob() {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'objectStatus' => Constants.EXPORT_RUNNING,
            'documentStatus' => Constants.EXPORT_QUEUED
        };
        // prettier-ignore
        List<String> documentFields = new List<String> {
            'ContentVersion__c',
            'Record_ID__c',
            'Status__c'
        };
        String subQuery = ' (SELECT ' + String.join(documentFields, ', ');
        subQuery += ' FROM Evisort_Export_Documents__r';
        subQuery += ' WHERE Status__c = :documentStatus';
        subQuery += ' LIMIT ' + Constants.EXPORTS_PER_MINUTE + ')';

        List<String> queryFields = new List<String>(this.getDefaultFields());
        queryFields.add(subQuery);

        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Export_Object__c';
        query += ' WHERE Status__c = :objectStatus';
        query += ' ORDER BY Object__c';

        List<Evisort_Export_Object__c> objects = Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );

        return (objects.isEmpty()) ? null : objects;
    }



    /**
     * Gets Name of the Library
     * @param  libraryId  library Id
     * @return        List of ContentWorkspace records
     */
    public List<ContentWorkspace> getLibraryName(Set<Id> libraryIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'libraryIds' => libraryIds
        };

        List<String> queryFields = new List<String>(this.getContentWorkSpaceFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentWorkspace';
        if (!libraryIds.isEmpty()) {
            query += ' WHERE Id = :libraryIds';
        }

        return (List<ContentWorkspace>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    public List<Document_Field_Sync_Mapping__c> getDocumentFieldSyncMappingRecords(String objectNames) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'objectNames' => objectNames
        };
        List<String> queryFields = new List<String>(this.getDocumentFieldSyncMappingFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Document_Field_Sync_Mapping__c';
        query += ' WHERE Object__c =:objectNames';

        return (List<Document_Field_Sync_Mapping__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }
}