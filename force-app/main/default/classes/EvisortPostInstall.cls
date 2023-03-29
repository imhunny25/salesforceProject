/**
* @description : This post install class is responsible for setting up business logic.
	             CRUD/FLS/Sharing are bypassed within this class because all the operations
	             need to run in the system context to ensure various application functionality.
*/
global without sharing class EvisortPostInstall implements InstallHandler {
    public static final List<String> SYNC_OBJECTS = new List<String>{ 'Opportunity', 'Contract' };

    global void onInstall(InstallContext context) {
        // Only add data when the package is being installed for the first time
        if (context != null && context.previousVersion() == null) {
            // Evisort Document Sync Criteria Setup
            List<Evisort_Document_Sync_Criteria__c> syncCriteriaList = new List<Evisort_Document_Sync_Criteria__c>();
            for (String syncObject : SYNC_OBJECTS) {
                syncCriteriaList.add(
                    new Evisort_Document_Sync_Criteria__c(
                        Name = syncObject,
                        Object__c = syncObject,
                        File_Type__c = null,
                        Record_Type__c = null
                    )
                );
            }
            insert syncCriteriaList; // Custom Setting, no need for CRUD/FLS check

            // Evisort Status Custom Setting Setup
            Evisort_Status__c evisortStatus = Evisort_Status__c.getOrgDefaults();
            evisortStatus.Sync_New_Provisions__c = true;
            upsert evisortStatus; // Custom Setting, no need for CRUD/FLS check
        }
    }
}