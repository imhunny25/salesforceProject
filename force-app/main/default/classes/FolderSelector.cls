public with sharing class FolderSelector extends Selector {
    /**
     * Constructor that assumes we are enforcing CRUD/FLS/SHR
     * Remember to change the sObject name in here from Account to your object!
     */
    public FolderSelector() {
        super(Schema.Folder.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * Remember to change the sObject name in here from Account to your object!
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public FolderSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Folder.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'Name'
        };
    }

    public List<Folder> getFoldersByName(String name) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{
            'name' => name
        };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Folder';
        query += ' WHERE Name = :name';

        return (List<Folder>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
    }
}