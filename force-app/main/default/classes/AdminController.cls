public with sharing class AdminController {
    /**
     * Checks the current status of Authentication based on last attempt
     * @return   AuthStatus message
     */
    @AuraEnabled(cacheable=true)
    public static AdminMsg.AuthStatus getAuthStatus() {
        try {
            return AdminService.getAuthStatus();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Verifies if we can authenticate
     * @return   VerifyAuthResponse message
     */
    @AuraEnabled
    public static AdminMsg.VerifyAuthResponse verifyAuth() {
        try {
            return AdminService.verifyAuth();
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.verifyAuth', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets Field Definitions for FE display
     * @param  fieldType "Field" or "Provision"
     * @return           A Msg class list of Field Definitions
     */
    @AuraEnabled(cacheable=true)
    public static List<AdminMsg.FieldDefinition> getFieldDefinitions(String fieldType) {
        try {
            return AdminService.getFieldDefinitions(fieldType);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Syncs Field Definitions via the Evisort API
     * @param  fieldType "Field" or "Provision"
     * @return           A Msg class list of Field Definitions (from the getFieldDefinitions method)
     */
    @AuraEnabled
    public static List<AdminMsg.FieldDefinition> syncFieldDefinitions(String fieldType) {
        try {
            return AdminService.syncFieldDefinitions(fieldType);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.syncFieldDefinitions', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Saves a list of Field Definitions (right now just the Is Active flag)
     * @param  definitionList Serialized MSG of Field Definitions
     * @param  fieldType      "Field" or "Provision"
     * @return                A Msg class list of Field Definitions (from the getFieldDefinitions method)
     */
    @AuraEnabled
    public static List<AdminMsg.FieldDefinition> saveFieldDefinitions(String fieldDefinitions, String fieldType) {
        try {
            List<AdminMsg.FieldDefinition> definitionList = (List<AdminMsg.FieldDefinition>) JSON.deserialize(
                fieldDefinitions,
                List<AdminMsg.FieldDefinition>.class
            );
            return AdminService.saveFieldDefinitions(definitionList, fieldType);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.saveFieldDefinitions', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets list of record types for an object
     * @param  obj Object name
     * @return     List of Object Record Type msgs
     */
    @AuraEnabled
    public static List<AdminMsg.ObjectRecordType> getRecordTypes(String obj) {
        try {
            return AdminService.getRecordTypes(obj);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.getRecordTypes', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets the data for the Sync Criteria page
     * @return   Msg with the configured objects, the list of all objects, and the global settings checkbox
     */
    @AuraEnabled(cacheable=true)
    public static AdminMsg.SyncCriteria getSyncCriteria() {
        try {
            return AdminService.getSyncCriteria();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets the checkbox for setting all new Provisions to active
     * @return   TRUE or FALSE
     */
    @AuraEnabled(cacheable=true)
    public static Boolean getNewProvisions() {
        try {
            return AdminService.getNewProvisions();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Saves a root folder
     * @param  rootFolder  name of the root folder
     * @return             TRUE if it worked, exception thrown if failed
     */
    @AuraEnabled
    public static Boolean saveRootFolder(String rootFolder) {
        try {
            return AdminService.saveRootFolder(rootFolder);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.saveRootFolder', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Saves a list of object settings
     * @param  objectSettings Serialized MSG of ObjectSetting
     */
    @AuraEnabled
    public static List<AdminMsg.ObjectSetting> saveObjectSettings(String objectSettings, String deletedObjectIds) {
        try {
            List<AdminMsg.ObjectSetting> objectSettingList = (List<AdminMsg.ObjectSetting>) JSON.deserialize(
                objectSettings,
                List<AdminMsg.ObjectSetting>.class
            );
            List<String> objectsDeletedList = (List<String>) JSON.deserialize(deletedObjectIds, List<String>.class);
            return AdminService.saveObjectSettings(objectSettingList, objectsDeletedList);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.saveObjectSettings', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Saves a global setting
     * @param  globalSettingType "Sync Criteria or Sync Provisions"
     * @param  value             TRUE or FALSE
     * @return                   TRUE if it worked, exception thrown if failed
     */
    @AuraEnabled
    public static Boolean saveGlobalSettings(String globalSettingType, Boolean value) {
        try {
            return AdminService.saveGlobalSettings(globalSettingType, value);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.saveGlobalSettings', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets the Folder ID for the Evisort Records folder, if it exists
     * @return   Salesforce ID for the Folder if it exists, NULL if it does not
     */
    @AuraEnabled(cacheable=true)
    public static String getEvisortFolderId() {
        try {
            return AdminService.getEvisortFolderId();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets description of all fields
     * @return   field with their description
     */
    @AuraEnabled
    public static List<EvisortFieldWrapper> getAllFieldsDetails(String objectName){
        try {
            return AdminService.getAllFieldsDetails(objectName);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('AdminController.saveGlobalSettings', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentWorkspace> getLibraryOptionList() {
        try {
            return AdminService.getLibraryOptionList();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}