public with sharing class ExportController {
    /**
     * Gets the explicitly and unexplicitly defined Export Object records for the UI and calculates progress
     * @return   ExportStatus msg
     */
    @AuraEnabled(cacheable=true)
    public static ExportMsg.ExportStatus getExportObjects() {
        try {
            return ExportService.getExportObjects();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets the list of available objects for the UI
     * @return   List of Strings
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectList() {
        try {
            return AdminService.getObjects();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, object> getObjectListWithLabel() {
        try {
            return AdminService.getObjectListWithLabel();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Run the Calculate Batch job on the object
     * @param  obj ExportObject msg containing name, file types, and record types
     * @return     TRUE if the batch job started, excepton thrown if there is an error
     */
    @AuraEnabled
    public static Boolean calculateObject(String obj) {
        try {
            ExportMsg.ExportObject eo = (ExportMsg.ExportObject) JSON.deserialize(obj, ExportMsg.ExportObject.class);
            return ExportService.calculateObject(eo);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Resets objects by deleting their Export Object records and their Export Document children
     * @param  objectNames API Names of the Objects
     * @return             TRUE if it worked, exception thrown if it didn't
     */
    @AuraEnabled
    public static Boolean resetObjects(List<String> objectNames) {
        try {
            return ExportService.resetObjects(objectNames);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Starts the Export for all Export Object records in READY status
     * @return   TRUE if it worked, FALSE if there are no READY objects to process
     */
    @AuraEnabled
    public static Boolean startExport() {
        try {
            return ExportService.startExport();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Cancels the Export for all Export Object records in RUNNING status
     * @return   TRUE if it worked, FALSE if there are no RUNNING objects to process
     */
    @AuraEnabled
    public static Boolean cancelExport() {
        try {
            return ExportService.cancelExport();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, object> getContentVersionAssociatedField(String objectName) {
        try {
            return ExportService.getContentVersionAssociatedField(objectName);
        }  catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }  
    }

    @AuraEnabled
    public static void mappingFields(String mappingFieldList) {
        try {
             AdminService.mappingFields(mappingFieldList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<AdminMsg.SyncFieldAggregateResultWrapper> getDocumentFieldSyncMappingRecord() {
        try {
            return AdminService.getDocumentFieldSyncMappingRecord();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String,String> getMappingDataTypes(){
        try{
            return AdminService.getMappingDataTypes();
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteDocumentFieldSyncMappingRecord(String objectName) {
        try {
             AdminService.deleteDocumentFieldSyncMappingRecord(objectName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<AdminMsg.DocumentFieldSyncMappingRecord> getDocumentMappingFields(String objectName) {
        try {
             return AdminService.getDocumentMappingFields(objectName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}