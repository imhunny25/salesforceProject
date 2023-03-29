public with sharing class ContentDocumentLinkSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public ContentDocumentLinkSelector() {
        super(Schema.ContentDocumentLink.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public ContentDocumentLinkSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.ContentDocumentLink.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'ContentDocumentId',
            'LinkedEntityId'
        };
    }

    /**
     * @return   Set of Strings that contain the default fields for this object
     */
    public Set<String> getContentWorkSpaceDocFields() {
        return new Set<String>{
            'ContentDocumentId', 
            'Id', 
            'ContentWorkspaceId',
            'CreatedDate', 
            'SystemModstamp'
        };
    }

    /**
     * Gets ContentDocumentLink records by their Document IDs
     * @param  conDocIds Set of ContentDocument IDs
     * @return           List of ContentDocumentLink records
     */
    public List<ContentDocumentLink> getLinksByDocumentIds(Set<Id> conDocIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'conDocIds' => conDocIds
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentDocumentLink';
        query += ' WHERE ContentDocumentId IN :conDocIds';

        return (List<ContentDocumentLink>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     * Gets ContentDocumentLink records by their Entity Id and Document Ids
     * @param  entityId Linked Entity Id
     * @param  conDocIds Set of ContentDocument IDs
     * @return           Map of List of ContentDocumentLink records
     */
    public Map<Id, List<ContentDocumentLink>> getLinksByEntityIdAndDocumentIds(Id entityId, Set<Id> conDocIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'entityId' => entityId,
            'conDocIds' => conDocIds
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        queryFields.add('LinkedEntity.Name');

        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentDocumentLink';
        query += ' WHERE LinkedEntityId = :entityId';
        query += ' AND ContentDocumentId IN :conDocIds';

        List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );

        Map<Id, List<ContentDocumentLink>> contentDocumentContentDocumentLinks = new Map<Id, List<ContentDocumentLink>>();

        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            List<ContentDocumentLink> contentDocumentLinkList = contentDocumentContentDocumentLinks.get(
                contentDocumentLink.ContentDocumentId
            );
            if (contentDocumentLinkList == null) {
                contentDocumentLinkList = new List<ContentDocumentLink>();
                contentDocumentContentDocumentLinks.put(contentDocumentLink.ContentDocumentId, contentDocumentLinkList);
            }

            contentDocumentLinkList.add(contentDocumentLink);
        }

        return contentDocumentContentDocumentLinks;
    }

    /**
     * Gets ContentDocumentLink records by their Document IDs and LinkedEntityId
     * @param contentDocumentId ContentDocument ID
     * @param linkedEntityId LinkedEntity ID
     * @return List of ContentDocumentLink records
     */
    public List<ContentDocumentLink> getLinksByDocumentIdAndLinkedEntityId(
        String contentDocumentId,
        Id linkedEntityId
    ) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'contentDocumentId' => contentDocumentId,
            'linkedEntityId' => linkedEntityId
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentDocumentLink';
        query += ' WHERE ContentDocumentId =:conDocIds';
        query += ' AND LinkedEntityId =:linkedEntityId';

        return (List<ContentDocumentLink>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }

    /**
     *  Gets ContentWorkspacedoc records by their Document IDs
     * @param  contentDocListIds  Content Document Id
     * @return        List of ContentWorkspacedoc records
     */
    public List<ContentWorkspaceDoc> getContentWorkSpaceDocList(Set<Id> contentDocListIds) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{ 
            'contentDocListIds' => contentDocListIds
        };

        List<String> queryFields = new List<String>(this.getContentWorkSpaceDocFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ContentWorkspaceDoc';
        if (!contentDocListIds.isEmpty()) {
            query += ' WHERE ContentDocumentId IN :contentDocListIds';
        }

        return (List<ContentWorkspaceDoc>) Data.read(
            query,
            queryArgs
        );
    }
}