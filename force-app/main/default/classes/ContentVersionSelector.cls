public with sharing class ContentVersionSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public ContentVersionSelector() {
        super(Schema.ContentVersion.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public ContentVersionSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.ContentVersion.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        return new Set<String>{
            'Id',
            'ContentDocumentId',
            'FileExtension',
            'FileType',
            'Title',
            'VersionData',
            'Evisort__r.Record_ID__c',
            'LastModifiedDate'
        };
    }

    /**
     * Gets ContentVersions by the Id of the Content Document
     * @param  documentIds Set of ContentDocument Ids
     * @return             List of ContentVersions
     */
    public List<ContentVersion> getContentVersionsByDocumentIds(Set<Id> documentIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'documentIds' => documentIds
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentVersion';
        query += ' WHERE ContentDocumentId IN :documentIds';

        return (List<ContentVersion>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets ContentVersions by the Id of the Content Document
     * @param  documentIds Set of ContentDocument Ids
     * @return             List of ContentVersions
     */
    public List<ContentVersion> getLatestContentVersionsByDocumentIds(Set<Id> documentIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'documentIds' => documentIds
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentVersion';
        query += ' WHERE ContentDocumentId IN :documentIds AND IsLatest = true';

        return (List<ContentVersion>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets ContentVersions by the Id of the Content Document
     * @param  documentIds Set of ContentDocument Ids
     * @return             List of ContentVersions
     */
    public ContentVersion getLatestContentVersionByDocumentId(Id contentDocId) {
        Map<String, Object> queryArgs = new Map<String, Object>{ 'contentDocId' => contentDocId };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentVersion';
        query += ' WHERE ContentDocumentId = :contentDocId AND IsLatest = true';

        List<ContentVersion> versions = (List<ContentVersion>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
        return versions.size() > 0 ? versions[0] : null;
    }

    /**
     * Gets ContentVersions by the Id of the Content Document
     * @param  documentIds Set of ContentDocument Ids
     * @return             List of ContentVersions
     */
    public ContentVersion getContentVersionById(Id contentVersionId) {
        Map<String, Object> queryArgs = new Map<String, Object>{ 'contentVersionId' => contentVersionId };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentVersion';
        query += ' WHERE Id = :contentVersionId';

        List<ContentVersion> versions = (List<ContentVersion>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
        return versions.size() > 0 ? versions[0] : null;
    }
}