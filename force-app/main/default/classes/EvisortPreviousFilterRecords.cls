public with sharing class EvisortPreviousFilterRecords {
    @AuraEnabled
    public static void evisortRecords() {
        List<Evisort_Export_Object__c> listOfLegacyRecords = [SELECT Id, Name, Object__c,  File_Types__c, Record_Types__c FROM Evisort_Export_Object__c];
        List<Evisort_Document_Sync_Criteria__c> listOfSyncRecords = [SELECT Id, Object__c,Record_Type__c, File_Type__c FROM Evisort_Document_Sync_Criteria__c];
        List<Evisort_Export_Filter__c> listOfExportFilterRecords =[SELECT Id, Name FROM Evisort_Export_Filter__c];
        if(listOfExportFilterRecords.isEmpty()){
            List<Evisort_Export_Filter__c> listOfNewExportFilterRecords = new List<Evisort_Export_Filter__c>();
            if(!listOfLegacyRecords.isEmpty()){
                listOfNewExportFilterRecords = getLegacyRecords(listOfNewExportFilterRecords, listOfLegacyRecords);
            }
            if(!listOfSyncRecords.isEmpty()){
                listOfNewExportFilterRecords = getSyncRecords(listOfNewExportFilterRecords, listOfSyncRecords);
            } 
            
            if(listOfNewExportFilterRecords.size() > 0){
            	insert listOfNewExportFilterRecords;
            }

            updateExportObject(listOfLegacyRecords);
        }
    }

    public static List<Evisort_Export_Filter__c> getLegacyRecords(List<Evisort_Export_Filter__c> listOfNewExportFilterRecords , List<Evisort_Export_Object__c> listOfLegacyRecords){
        for (Evisort_Export_Object__c legacyRecord : listOfLegacyRecords) {
            if(legacyRecord.Object__c != null){
                String objectFilterBody;
                String fileFilterBody;
                String fileTypeValue = '';
                if(legacyRecord.File_Types__c != null){
                    List<String> fileTypesList = legacyRecord.File_Types__c.split(',');
                    for(String fileType : fileTypesList){
                        if(fileType == 'Word'){
                        fileTypeValue += 'Doc,docx,';
                        }
                        else if(fileType == 'Excel'){
                            fileTypeValue += 'xls,xlsx,';
                        }else{
                            fileTypeValue += fileType +',';
                        } 
                    } 
                    fileTypeValue = fileTypeValue.removeEnd(',');
                }
                if(legacyRecord.Record_Types__c != null){
                    objectFilterBody = '{ "rows": [ { "fieldName": "RecordType.Name", "fieldLabel": "Record Type Name", "fieldType": "MULTIPICKLIST", "operator": "IN", "value": "'+legacyRecord.Record_Types__c +'", "isPicklist": false, "fieldTypeLabel": "MULTIPICKLIST", "fieldSOAPType": "STRING", "sequence": 1 } ], "condition": "AND" }';
                }
                if(fileTypeValue != '' && fileTypeValue != null){
                    fileFilterBody = '{"rows":[{"fieldName":"FileExtension","fieldLabel":"File Extension","fieldType":"STRING","operator":"IN","value":"'+ fileTypeValue+'","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1}],"condition":"AND"}';
                }
                Evisort_Export_Filter__c exportlegacyRecord = new Evisort_Export_Filter__c();
                exportlegacyRecord.Object__c = legacyRecord.Object__c;
                exportlegacyRecord.Name = legacyRecord.Object__c;
                exportlegacyRecord.File_Filter_Body__c = fileFilterBody;
                exportlegacyRecord.Object_Filter_Body__c = objectFilterBody;
                exportlegacyRecord.Is_Legacy__c = true;
                listOfNewExportFilterRecords.add(exportlegacyRecord);
            }
        }
        return listOfNewExportFilterRecords;
    }

    public static List<Evisort_Export_Filter__c> getSyncRecords(List<Evisort_Export_Filter__c> listOfNewExportFilterRecords,List<Evisort_Document_Sync_Criteria__c> listOfSyncRecords){
        for (Evisort_Document_Sync_Criteria__c syncRecord : listOfSyncRecords) {
            if(syncRecord.Object__c != null){
                String objectFilterBody;
                String fileFilterBody;
                String fileTypeValue = '';
                if(syncRecord.File_Type__c != null){
                    List<String> fileTypesList = syncRecord.File_Type__c.split(',');
                    for(String fileType : fileTypesList){
                        if(fileType == 'Word'){
                        fileTypeValue += 'Doc,docx,';
                        }
                        else if(fileType == 'Excel'){
                            fileTypeValue += 'xls,xlsx,';
                        }else{
                            fileTypeValue += fileType +',';
                        } 
                    } 
                    fileTypeValue = fileTypeValue.removeEnd(',');
                }
                if(syncRecord.Record_Type__c != null){
                    objectFilterBody = '{ "rows": [ { "fieldName": "RecordType.Name", "fieldLabel": "Record Type Name", "fieldType": "MULTIPICKLIST", "operator": "IN", "value": "'+syncRecord.Record_Type__c +'", "isPicklist": false, "fieldTypeLabel": "MULTIPICKLIST", "fieldSOAPType": "STRING", "sequence": 1 } ], "condition": "AND" }';
                }
                if(fileTypeValue != null && fileTypeValue != ''){
                    fileFilterBody = '{"rows":[{"fieldName":"FileExtension","fieldLabel":"File Extension","fieldType":"STRING","operator":"IN","value":"'+ fileTypeValue +'","isPicklist":false,"fieldTypeLabel":"STRING","fieldSOAPType":"STRING","sequence":1}],"condition":"AND"}';
                }
                Evisort_Export_Filter__c exportsyncRecord = new Evisort_Export_Filter__c();
                exportsyncRecord.Object__c = syncRecord.Object__c;
                exportsyncRecord.Name = syncRecord.Object__c;
                exportsyncRecord.File_Filter_Body__c = fileFilterBody;
                exportsyncRecord.Object_Filter_Body__c = objectFilterBody;
                exportsyncRecord.Is_Legacy__c = false;
                listOfNewExportFilterRecords.add(exportsyncRecord);
            }
        }
        return listOfNewExportFilterRecords;
    }

    public static void updateExportObject(List<Evisort_Export_Object__c> listOfLegacyRecords ){
        List<Evisort_Export_Filter__c> listOfLegacyExportFilterRecords = [SELECT Id, Name, Object__c, Object_Filter_Body__c, File_Filter_Body__c, Is_Library__c, Is_Legacy__c FROM Evisort_Export_Filter__c WHERE Is_Legacy__c = true];            

            Map<String,Evisort_Export_Object__c> mapOfEvisortExportObject = new Map<String,Evisort_Export_Object__c>(); 
            for(Evisort_Export_Object__c exportOnjectRecord :listOfLegacyRecords){
                if(exportOnjectRecord.Object__c != null){
                	mapOfEvisortExportObject.put(exportOnjectRecord.Object__c,exportOnjectRecord);
                }
            }

            List<Evisort_Export_Object__c> listOfUpdateExportObjectRecords = new List<Evisort_Export_Object__c>();
            for(Evisort_Export_Filter__c upatefilterId : listOfLegacyExportFilterRecords){
                if(mapOfEvisortExportObject.containsKey(upatefilterId.Object__c)){
                    Evisort_Export_Object__c exportRecord = mapOfEvisortExportObject.get(upatefilterId.Object__c);
                    Evisort_Export_Object__c updateExportRecord = new Evisort_Export_Object__c();
                    updateExportRecord.Id = exportRecord.id;
                    updateExportRecord.Evisort_Export_Filter__c = upatefilterId.id;
                    listOfUpdateExportObjectRecords.add(updateExportRecord);
                }
            }

            if(listOfUpdateExportObjectRecords.size() > 0){
            	update listOfUpdateExportObjectRecords;
            }
    }
}