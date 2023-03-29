global with sharing class EvisortMetadataSyncBatchV2 implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    global List<QueueItem__c> queueItemsToDelete = new List<QueueItem__c>();
    global Set<Id> setEvisortIds = new Set<Id>();
    global Datetime lastBatchSyncDate = null;
    global static Boolean isMetaDataExport = false;
	public Set<Id> evisortLegacyRecords = new Set<Id>();
    global EvisortMetadataSyncBatchV2(Set<Id> evsId) {
        this.setEvisortIds = evsId;
    }

    global EvisortMetadataSyncBatchV2() {
        Evisort_Workspace_Settings__c settings = Evisort_Workspace_Settings__c.getInstance();
        if(settings.LastSyncBatchDate__c != null){
            this.lastBatchSyncDate = settings.LastSyncBatchDate__c;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Createddate, Record_ID__c, External_ID__c FROM Evisort__c WHERE External_ID__c != null AND Record_ID__c != null';
        if (this.setEvisortIds.size() > 0) {
            query += ' AND Id IN: setEvisortIds';
        }
        
        String queueQuery = 'SELECT Id, Name, Object__c, Status__c, RecordId__c FROM QueueItem__c WHERE Object__c = \'MetadataExport\' AND Status__c = \'NEW\'';
        List<QueueItem__c> lstQueueItems = Data.read(queueQuery, null, false, false, false); // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
        Set<Id> evsIdsInQueue = new Set<Id>();
        for (QueueItem__c item : lstQueueItems) {
                evsIdsInQueue.add(Id.valueOf(item.RecordId__c));
        }

        if (evsIdsInQueue.size() > 0) {
            query += ' AND Id NOT IN: evsIdsInQueue';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Evisort__c> lstEvisort) {
        Set<Id> evisortRecordIds = new Set<Id>();

        try {
            Map<String, List<Evisort__c>> mapObjNameWithEvisortRecs = new Map<String, List<Evisort__c>>();

            for (Evisort__c evs : lstEvisort) {
                String objectName = EvisortMetadataSyncBatchUtils.getObjectName(Id.valueOf(evs.Record_ID__c));

                if (String.isNotBlank(objectName)) {
                    if (!mapObjNameWithEvisortRecs.containsKey(objectName) && String.isNotBlank(objectName)) {
                        mapObjNameWithEvisortRecs.put(objectName, new List<Evisort__c>());
                    }
                    mapObjNameWithEvisortRecs.get(objectName).add(evs);
                    evisortRecordIds.add(evs.Record_ID__c);
                }
            }

            if (!mapObjNameWithEvisortRecs.isEmpty()) {
                
                Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm = EvisortMetadataSyncBatchUtils.getMapObjectNameWithFieldMapping(mapObjNameWithEvisortRecs.keySet());
                List<SObject> lstMappedObjectResult = new List<SObject>();
                
                if (!mapObjectWithDfsm.isEmpty()) {
                    for (String obj : mapObjNameWithEvisortRecs.keySet()) {

                        if (mapObjectWithDfsm.containsKey(obj)) {
                            Set<String> setObjFields = EvisortMetadataSyncBatchUtils.getFields(mapObjectWithDfsm.get(obj));
                            List<SObject> queryResult = EvisortMetadataSyncBatchUtils.getObjectFieldValue(mapObjectWithDfsm, setObjFields, obj, evisortRecordIds, this.lastBatchSyncDate);

                            if (queryResult.size() > 0) {
                                lstMappedObjectResult.addAll(queryResult);
                            }
                        }
                    }
                }

                for (Evisort__c evs : lstEvisort) {
                    if(evs.Createddate > this.lastBatchSyncDate){
                    String objectName = EvisortMetadataSyncBatchUtils.getObjectName(Id.valueOf(evs.Record_ID__c));
                        if(mapObjectWithDfsm.containskey(objectName)){
                            evisortLegacyRecords.add(evs.Id);
                        }
                    }
                }

                if (lstMappedObjectResult.size() > 0 || this.evisortLegacyRecords.size() > 0) {
                    createQueueItems(lstMappedObjectResult, lstEvisort);
                }
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchV2.execute: ', e);
        }
    }

    global void createQueueItems(List<SObject> lstMappedObjectResult, List<Evisort__c> lstEvisort) {
        try {
            Set<Id> resultRecordIds = (new Map<Id,SObject>(lstMappedObjectResult)).keySet();

            List<QueueItem__c> queueItemsToInsert = new List<QueueItem__c>();
            for (Evisort__c evs : lstEvisort) {
                if(resultRecordIds.contains(evs.Record_ID__c) || (this.evisortLegacyRecords.size() > 0 && this.evisortLegacyRecords.contains(evs.Id))) {
                    QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                    newItem.RecordId__c = evs.Id;
                    newItem.Object__c = 'MetadataExport';
                    newItem.Process_After__c = Datetime.now();
                    if (this.setEvisortIds.size() > 0) {
                        newItem.Priority__c = 0;
                    }else{
                        newItem.Priority__c = 9;
                    }
                    queueItemsToInsert.add(newItem);
                }
            }
            if (!Test.isRunningTest() && queueItemsToInsert.size() > 0) {
                isMetaDataExport = true;
                Data.create(queueItemsToInsert, false, false, false);  // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
                isMetaDataExport = false;
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchV2.createQueueItems: ', e);
        }
    }

    global void finish(Database.BatchableContext bc) {
        try {
            if(this.setEvisortIds.size() == 0 ){
                Evisort_Workspace_Settings__c settings = Evisort_Workspace_Settings__c.getOrgDefaults();
                if (settings.Workspace__c == null) {
                    settings.Workspace__c = 'epigrowthdev2';
                }
                settings.LastSyncBatchDate__c = System.now();
                upsert settings;
            }
            // Delete synced QueueScience items
            String queueQuery = 'SELECT Id, Name, Object__c, Status__c, RecordId__c FROM QueueItem__c WHERE Object__c = \'MetadataExport\' AND (Status__c = \'Completed\') LIMIT 9900';
            queueItemsToDelete = Data.read(queueQuery, null, false, false, false); // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
            if (this.queueItemsToDelete.size() > 0) {
                Data.remove(this.queueItemsToDelete, false, false, false); // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortMetadataSyncBatchV2.finish: ', e);
        }
    }
    
        global void execute(SchedulableContext scon) {
        Database.executeBatch(new EvisortMetadataSyncBatchV2(),2000);
    }
}