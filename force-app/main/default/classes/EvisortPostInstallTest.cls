@isTest
private class EvisortPostInstallTest {
    @isTest
    static void testEvisortSettingSetup() {
        // Validate fresh install setup
        EvisortPostInstall postinstall = new EvisortPostInstall();
        Test.testInstall(postinstall, null);

        // Validate Evisort Status setup
        Evisort_Status__c evisortStatus = Evisort_Status__c.getOrgDefaults();
        CSUtils.itShouldBe(
            'Evisort Status Sync New Provosions Set Incorrectly',
            true,
            evisortStatus.Sync_New_Provisions__c
        );

        // Modify Evisort Status custom setting to mimic client customization
        evisortStatus.Sync_New_Provisions__c = false;
        upsert evisortStatus; // Custom Setting, no need for CRUD/FLS check

        // Validate post install script doesn't update data during upgrade
        Test.testInstall(postinstall, new Version(1, 0));

        // Validate Evisort Status setup
        evisortStatus = Evisort_Status__c.getOrgDefaults();
        CSUtils.itShouldBe(
            'Evisort Status Sync New Provosions Set Incorrectly',
            false,
            evisortStatus.Sync_New_Provisions__c
        );
    }

    @isTest
    static void testEvisortDocumentSyncCriteriaSetup() {
        // Validate fresh install setup
        EvisortPostInstall postinstall = new EvisortPostInstall();
        Test.testInstall(postinstall, null);

        // Validate Evisort Document Sync Criteria setup
        Map<String, Evisort_Document_Sync_Criteria__c> syncCriteriaMap = new Map<String, Evisort_Document_Sync_Criteria__c>();
        for (Evisort_Document_Sync_Criteria__c edsc : [
            SELECT Name, Object__c, File_Type__c, Record_Type__c
            FROM Evisort_Document_Sync_Criteria__c
        ]) {
            syncCriteriaMap.put(edsc.Object__c, edsc);
        }
        CSUtils.itShouldBe(
            'Evisort Document Sync Criteria Records',
            EvisortPostInstall.SYNC_OBJECTS.size(),
            syncCriteriaMap.size()
        );

        for (String syncObject : EvisortPostInstall.SYNC_OBJECTS) {
            CSUtils.itShouldBe(
                'Evisort Document Sync Criteria Record Not Found: ' + syncObject,
                true,
                syncCriteriaMap.containsKey(syncObject)
            );
            if (!syncCriteriaMap.isEmpty() && syncCriteriaMap.containsKey(syncObject)) {
                Evisort_Document_Sync_Criteria__c edsc = syncCriteriaMap.get(syncObject);
                CSUtils.itShouldBe(
                    'Evisort Document Sync Criteria Record For: ' +
                    syncObject +
                    ' Created With Wrong FileTypes',
                    null,
                    edsc.File_Type__c
                );
            }
        }

        // Modify Evisort Document Sync Criteria custom settings to mimic client customization
        List<Evisort_Document_Sync_Criteria__c> syncCriteriaList = new List<Evisort_Document_Sync_Criteria__c>();
        for (Evisort_Document_Sync_Criteria__c edsc : syncCriteriaMap.values()) {
            edsc.File_Type__c = 'TESTING';
            syncCriteriaList.add(edsc);
        }
        syncCriteriaList.add(
            new Evisort_Document_Sync_Criteria__c(
                Name = 'Test',
                Object__c = 'Test',
                File_Type__c = 'TESTING',
                Record_Type__c = null
            )
        );
        upsert syncCriteriaList; // Custom Setting, no need for CRUD/FLS check

        // Validate post install script doesn't update data during upgrade
        Test.testInstall(postinstall, new Version(1, 0));

        // Validate Evisort Document Sync Criteria
        List<Evisort_Document_Sync_Criteria__c> upgradedSyncCriteriaList = [
            SELECT Name, Object__c, File_Type__c, Record_Type__c
            FROM Evisort_Document_Sync_Criteria__c
            WHERE File_Type__c = 'TESTING'
        ];
        CSUtils.itShouldBe(
            'Evisort Document Sync Criteria Records',
            EvisortPostInstall.SYNC_OBJECTS.size() + 1,
            upgradedSyncCriteriaList.size()
        );
    }
}