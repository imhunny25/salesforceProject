public with sharing class EvisortTriggerHandler extends Domain {
    /**
     * Constructor based on Domain.cls constructor with similar signature
     * @param  records List of Evisort Records
     */
    public EvisortTriggerHandler(List<Evisort__c> records) {
        super(records);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        List<Evisort__c> evisortRecs = (List<Evisort__c>) this.records;
        Map<Id, Evisort__c> oldEvisortRecs = (Map<Id, Evisort__c>) oldMap;
        Set<Id> setEvisortIds = new Set<Id>();
        Set<Id> recordIds = new Set<Id>();
        Set<Id> evisortExportObjectId = new Set<Id>();
        Set<Id> evisortIds = new Set<Id>();
        if(evisortRecs.size() > 0){
            for (Evisort__c objEvisort : evisortRecs) {
                if (objEvisort.External_ID__c != null && objEvisort.Record_ID__c != null) {
                    if (objEvisort.Record_ID__c != oldEvisortRecs.get(objEvisort.Id).Record_ID__c) {
                        recordIds.add(objEvisort.Record_ID__c);
                        evisortIds.add(objEvisort.Id);
                    }
                }
            }
        }

        if (recordIds.size() > 0) {
            List<Evisort_Export_Document__c> evisortDocumentList = [SELECT Id, Name, Record_ID__c, Evisort_Export_Object__r.Evisort_Export_Filter__r.Is_Library__c, ContentDocument__c,  
                                                                    Evisort__c FROM Evisort_Export_Document__c WHERE Record_ID__c IN: recordIds];
            for(Evisort_Export_Document__c eed: evisortDocumentList){
                if(eed.Evisort_Export_Object__c != null && eed.Evisort_Export_Object__r.Evisort_Export_Filter__c != null  
                    && !eed.Evisort_Export_Object__r.Evisort_Export_Filter__r.Is_Library__c)
                {
                    setEvisortIds.add(eed.Evisort__c);
                }
            }
            AggregateResult[] schResults = [ SELECT Object__c obj FROM Document_Field_Sync_Mapping__c GROUP BY  Object__c ];
            if (setEvisortIds.size() > 0 && schResults.size() > 0) {
                Set<Id> evisortIdsForBatch = new Set<Id>();
                for (Id evsId : evisortIds) {
                    if (setEvisortIds.contains(evsId)) {
                        evisortIdsForBatch.add(evsId);
                    }
                }
                if (evisortIdsForBatch.size() > 0) {
                    EvisortMetadataSyncBatchV2 ecb = new EvisortMetadataSyncBatchV2(evisortIdsForBatch);
                    Database.executeBatch(ecb, 5);
                }
            }
        }
    }
}