public with sharing class AdminService {
    /**
     * Checks the current status of Authentication based on last attempt
     * @return   AuthStatus message
     */
    public static AdminMsg.AuthStatus getAuthStatus() {
        Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
        return new AdminMsg.AuthStatus(status);
    }

    /**
     * Verifies if we can authenticate
     * Essentially, we test if we can get an Access Token.
     * Any exception that is thrown is an error
     * @return   VerifyAuthResponse message
     */
    public static AdminMsg.VerifyAuthResponse verifyAuth() {
        try {
            Boolean success = new API().testNamedCredential();

            // success is either TRUE or an exception is thrown
            if (success) {
                Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
                status.Authenticated__c = true;
                status.Authentication_Date__c = Datetime.now();
                upsert status; // Custom Setting, no need for CRUD/FLS check
            }
        } catch (Exception e) {
            return new AdminMsg.VerifyAuthResponse(e.getMessage());
        }

        return new AdminMsg.VerifyAuthResponse();
    }

    /**
     * Gets Field Definitions for FE display
     * @param  fieldType "Field" or "Provision"
     * @return           A Msg class list of Field Definitions
     */
    public static List<AdminMsg.FieldDefinition> getFieldDefinitions(String fieldType) {
        List<AdminMsg.FieldDefinition> definitionList = new List<AdminMsg.FieldDefinition>();

        EvisortFieldDefinitionSelector efdSelector = new EvisortFieldDefinitionSelector();
        List<Evisort_Field_Definition__c> definitions = efdSelector.getDefaultFieldsByFieldType(fieldType);

        for (Evisort_Field_Definition__c efd : definitions) {
            definitionList.add(new AdminMsg.FieldDefinition(efd));
        }

        return definitionList;
    }

    /**
     * Syncs Field Definitions via the Evisort API
     * @param  fieldType "Field" or "Provision"
     * @return           A Msg class list of Field Definitions (from the getFieldDefinitions method)
     */
    public static List<AdminMsg.FieldDefinition> syncFieldDefinitions(String fieldType) {
        EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall(fieldType);

        return getFieldDefinitions(fieldType);
    }

    /**
     * Saves a list of Field Definitions (right now just the Is Active flag)
     * @param  definitionList Serialized MSG of Field Definitions
     * @param  fieldType      "Field" or "Provision"
     * @return                A Msg class list of Field Definitions (from the getFieldDefinitions method)
     */
    public static List<AdminMsg.FieldDefinition> saveFieldDefinitions(
        List<AdminMsg.FieldDefinition> definitionList,
        String fieldType
    ) {
        List<Evisort_Field_Definition__c> definitions = new List<Evisort_Field_Definition__c>();

        for (AdminMsg.FieldDefinition fd : definitionList) {
            definitions.add(fd.toRecord());
        }

        if (!definitions.isEmpty()) {
            Data.modify(definitions);
        }

        return getFieldDefinitions(fieldType);
    }

    /**
     * Gets list of all accessible objects
     * @return   List of Object names
     */
    public static List<String> getObjects() {
        Set<String> allowedSystemObjects = new Set<String>{
            'contentworkspace'
        };

        List<String> objects = new List<String>();
        Map<String, Schema.SObjectType> glblDscrb = Schema.getGlobalDescribe();

        for (Schema.SObjectType sot : glblDscrb.values()) {
            Schema.DescribeSObjectResult dsor = sot.getDescribe();

            Boolean isAllowedObject = (
                !dsor.isCustomSetting() &&
                dsor.getRecordTypeInfos().size() > 0 &&
                dsor.isCreateable() &&
                !dsor.getName().containsignorecase('history') &&
                !dsor.getName().containsignorecase('tag') &&
                !dsor.getName().containsignorecase('share') &&
                !dsor.getName().containsignorecase('feed')
            );

            //remove system objects (that aren't explicitly allowed) from the list
            if ((isAllowedObject || allowedSystemObjects.contains(dsor.getName().toLowerCase())) && dsor.isAccessible()) {
                objects.add(dsor.getName());
            }
        }

        objects.sort();
        return objects;
    }

    public static Map<String, object> getObjectListWithLabel() {
        Set<String> allowedSystemObjects = new Set<String>{
            'contentworkspace'
        };

        List<String> objectsList = new List<String>();
        
        Map<String, object> mapofObject = new Map<String,object>();
        Map<String, Schema.SObjectType> glblDscrb = Schema.getGlobalDescribe();

        for (Schema.SObjectType sot : glblDscrb.values()) {
            Schema.DescribeSObjectResult dsor = sot.getDescribe();

            Boolean isAllowedObject = (
                !dsor.isCustomSetting() &&
                dsor.getRecordTypeInfos().size() > 0 &&
                dsor.isCreateable() &&
                !dsor.getName().containsignorecase('history') &&
                !dsor.getName().containsignorecase('tag') &&
                !dsor.getName().containsignorecase('share') &&
                !dsor.getName().containsignorecase('feed')
            );

            if ((isAllowedObject || allowedSystemObjects.contains(dsor.getName().toLowerCase())) && dsor.isAccessible()) {
                AdminMsg.ObjectWrapper objectName = new AdminMsg.ObjectWrapper();
                objectName.label = dsor.getlabel();
                objectName.value = dsor.getName();
                objectsList.add(JSON.serialize(objectName));
            }
        }

        objectsList.sort();
        mapofObject.put('objectsName', objectsList );
        return mapofObject;
    }

    /**
     * Get list of all accessible objects with their label names
     * @return list of object with their labels
     */
    public static List<Map<String, String>> getObjectsWithLabels() {
        List<Map<String, String>> objects = new List<Map<String, String>>();
        Map<String, Schema.SObjectType> glblDscrb = Schema.getGlobalDescribe();
        for (Schema.SObjectType sot : glblDscrb.values()) {
            Schema.DescribeSObjectResult dsor = sot.getDescribe();
            //remove system objects from the list
            if (
                !dsor.isCustomSetting() &&
                dsor.getRecordTypeInfos().size() > 0 &&
                dsor.isCreateable() &&
                !dsor.getName().containsignorecase('history') &&
                !dsor.getName().containsignorecase('tag') &&
                !dsor.getName().containsignorecase('share') &&
                !dsor.getName().containsignorecase('feed') &&
                dsor.isAccessible()
            ) {
                objects.add(new Map<String, String>{
                    'label' => dsor.getLabel(),
                    'value' => dsor.getName()
                });
            }
        }

        return objects;
    }

    /**
     * @description Gets a list of fields on an object.
     * @param  obj obj description
     * @return     return description
     */
    public static Map<String,List<Map<String, String>>> getObjectFieldNames(String objectApiName,List<Object> workflowFields) {
        Map<String,List<Map<String, String>>> mapOfFieldNames = new Map<String,List<Map<String, String>>>();
        Map<String, Schema.SObjectType> glblDscrb = Schema.getGlobalDescribe();
        if (glblDscrb.containsKey(objectApiName)) {
            Schema.DescribeSObjectResult objectDescribe = glblDscrb.get(objectApiName).getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            for(Object field:workflowFields){
                Map<String, Object> presetValMap= (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(field));
                String workflowFieldType = (String) presetValMap.get('WorkflowFieldType');
                List<Map<String, String>> fieldNames = new List<Map<String, String>>();
                
                for (Schema.SObjectField sof : fieldMap.values()) {
                    Schema.DescribeFieldResult dsfr = sof.getDescribe();
                    Schema.DisplayType salesforceFieldType =  dsfr.getType();
                    Boolean fieldCheck = IntakeFormService.isFieldValidateMapping(workflowFieldType,salesforceFieldType);
                    if(fieldCheck == true){
                        fieldNames.add(new Map<String, String>{
                            'label' => dsfr.getLabel(),
                            'value' => dsfr.getName()
                        });
                    }
                }
                mapOfFieldNames.put((String) presetValMap.get('questionName'),fieldNames);
            }
        }

        return mapOfFieldNames;
    }

    /**
     * Gets list of record types for an object
     * @param  obj Object name
     * @return     List of Object Record Type msgs
     */
    public static List<AdminMsg.ObjectRecordType> getRecordTypes(String obj) {
        List<AdminMsg.ObjectRecordType> objRecordType = new List<AdminMsg.ObjectRecordType>();
        DescribeCache dc = DescribeCache.getDescribeCache(obj);
        Map<String, Schema.RecordTypeInfo> recordTypesMap = dc.objectDescribe.getRecordTypeInfosByName();
        for (Schema.RecordTypeInfo rt : recordTypesMap.values()) {
            if ((!rt.isMaster()) && (rt.isActive()) && (rt.isAvailable())) {
                objRecordType.add(new AdminMsg.ObjectRecordType(rt.getName()));
            }
        }
        return objRecordType;
    }

    /**
     * Gets the data for the Sync Criteria page
     * @return   Msg with the configured objects, the list of all objects, and the global settings checkbox
     */
    public static AdminMsg.SyncCriteria getSyncCriteria() {
        Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
        AdminMsg.SyncCriteria msg = new AdminMsg.SyncCriteria(settings.Sync_Criteria__c);
        msg.rootFolder = settings.Root_Folder__c;
        msg.objectSettings = getObjectSettings();
        msg.objectList = getObjects();

        return msg;
    }

    /**
     * Gets list of default object settings from Evisort_Export_Filter__c custom settings
     * @return  A Msg class list of ObjectSetting
     */
    private static List<AdminMsg.ObjectSetting> getObjectSettings() {
        List<AdminMsg.ObjectSetting> settingsList = new List<AdminMsg.ObjectSetting>();
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Filter__c> eefList = eeoSelector.getExportObjects(); 
        for (Evisort_Export_Filter__c eef : eefList) {
                AdminMsg.ObjectSetting setting = new AdminMsg.ObjectSetting(eef);
                settingsList.add(setting);
        }
        settingsList.sort();
        return settingsList;
    }

    /**
     * Saves a root folder
     * @param  rootFolder  name of the root folder
     * @return             TRUE if it worked, exception thrown if failed
     */
    public static Boolean saveRootFolder(String rootFolder) {
        Evisort_Status__c defaultsetting = Evisort_Status__c.getOrgDefaults();
        defaultsetting.Root_Folder__c = rootFolder;

        //CRUD/FLS check is not required here as we are upserting on custom settings, Evisort_Status__c
        upsert defaultsetting;

        return true;
    }

    /**
     * Saves and deletes object settings
     * @param  objectSettings   List of ObjectSetting msgs to upsert
     * @param  deletedObjectIds List of Custom Setting ID's to delete
     * @return                  Saved list of ObjectSetting msgs (reordered)
     */
    public static List<AdminMsg.ObjectSetting> saveObjectSettings(
        List<AdminMsg.ObjectSetting> objectSettings,
        List<String> deletedObjectIds
    ) {
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Filter__c> settingsList = new List<Evisort_Export_Filter__c>();
        Set<Id> libraryIds = new Set<Id>();
        for (AdminMsg.ObjectSetting obj : objectSettings) {
            if (String.isNotBlank(obj.objectLabel) && obj.enableLibraryFilter == true) {
                libraryIds.add(obj.objectLabel);
            }
        }

        Map<ID,String> mapOfLibraryIdWithName = new Map<Id, String>();
            if(libraryIds.size() > 0){
            List<ContentWorkspace> contentList =  eeoSelector.getLibraryName(libraryIds); // [SELECT Id,Name FROM ContentWorkspace WHERE ID =: libraryId LIMIT 1];

            for(ContentWorkspace cw : contentList){
                mapOfLibraryIdWithName.put(cw.id, cw.name);
            }
        }

        for (AdminMsg.ObjectSetting obj : objectSettings) {
            String name;
            if(!mapOfLibraryIdWithName.isEmpty() && mapOfLibraryIdWithName.containskey(obj.objectLabel)){
                name = mapOfLibraryIdWithName.get(obj.objectLabel);
            }
            if (String.isNotBlank(obj.objectLabel)) {
                settingsList.add(obj.toRecord(name));
            }
        }
        //CRUD/FLS check is not required here as we are upserting on custom settings, Evisort_Export_Filter__c
        if (!settingsList.isEmpty()) {
            upsert settingsList;
        }

        if ((deletedObjectIds != null) && (!deletedObjectIds.isEmpty())) {
            List<Evisort_Export_Filter__c> settingsToRemove = new List<Evisort_Export_Filter__c>();
            for (String id : deletedObjectIds) {
                settingsToRemove.add(new Evisort_Export_Filter__c(Id = id));
            }
            //CRUD/FLS check is not required here as we are deleting on custom settings, Evisort_Export_Filter__c
            delete settingsToRemove;
        }

        return getObjectSettings();
    }

    /**
     * Saves a global setting
     * @param  globalSettingType "Sync Criteria or Sync Provisions"
     * @param  value             TRUE or FALSE
     * @return                   TRUE if it worked, exception thrown if failed
     */
    public static Boolean saveGlobalSettings(String globalSettingType, Boolean value) {
        Evisort_Status__c defaultsetting = Evisort_Status__c.getOrgDefaults();
        if (globalSettingType == 'Sync Criteria') {
            defaultsetting.Sync_Criteria__c = value;
        } else if (globalSettingType == 'Sync Provisions') {
            defaultsetting.Sync_New_Provisions__c = value;
        }
        //CRUD/FLS check is not required here as we are upserting on custom settings, Evisort_Status__c
        upsert defaultsetting;

        return true;
    }

    /**
     * Gets the checkbox for setting all new Provisions to active
     * @return   TRUE or FALSE
     */
    public static Boolean getNewProvisions() {
        Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
        return settings.Sync_New_Provisions__c;
    }

    /**
     * Gets the Folder ID for the Evisort Records folder, if it exists
     * @return   Salesforce ID for the Folder if it exists, NULL if it does not
     */
    public static String getEvisortFolderId() {
        FolderSelector fSelector = new FolderSelector();
        List<Folder> folders = fSelector.getFoldersByName(Constants.EVISORT_FOLDER_NAME);

        if (!folders.isEmpty()) {
            return folders[0].Id;
        }

        return null;
    }

    /**
     * Gets description of all fields
     * @return   field with their description
     */
    @AuraEnabled
    public static List<EvisortFieldWrapper> getAllFieldsDetails(String objectName){
        List<EvisortFieldWrapper> evisortAllFields = EvisortFieldWrapper.getAllFieldsWrapper(objectName);
        
        List<EvisortFieldWrapper> fieldsWrapper = new List<EvisortFieldWrapper>();
        for(EvisortFieldWrapper field : evisortAllFields)
        {
            fieldsWrapper.add(field);
        }
        fieldsWrapper.sort();
        
        return fieldsWrapper;
    }

    
    public static List<ContentWorkspace> getLibraryOptionList(){
        List<ContentWorkspace> libraryRecords = [SELECT Id, Name FROM ContentWorkspace WITH SECURITY_ENFORCED];
        if(!libraryRecords.isEmpty()){
            return libraryRecords;
        }
        return null;
    } 

    public static void mappingFields(String mappingFieldList){
        if(String.isNotBlank(mappingFieldList)){
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(mappingFieldList);
            String objectName = String.valueof(result.get('ObjectName'));
            Boolean isLegacy = Boolean.valueof(result.get('isLegacy'));
            Boolean newRecord = Boolean.valueof(result.get('newRecord'));
            Boolean noDuplicateRecord = true;
            /**Change */
        
            EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
            List<Document_Field_Sync_Mapping__c> duplicateDocumentMappingRecord = eeoSelector.getDocumentFieldSyncMappingRecords(objectName);
           
            if(duplicateDocumentMappingRecord.size()>1 && newRecord == true){
                noDuplicateRecord = false;
            }

            if(noDuplicateRecord == true){

                List<Object> mapFieldList = (List<Object>)result.get('mappings');
                List<Document_Field_Sync_Mapping__c> documentFieldMappingRecord = new List<Document_Field_Sync_Mapping__c>();

                for(Object mappingField : mapFieldList){
                    Map<String,Object> objMap = ( Map<String,Object>) mappingField;
                    Document_Field_Sync_Mapping__c fieldMappingRecord = new Document_Field_Sync_Mapping__c();
                    
                    if(objMap.get('id') != null && objMap.get('id') != ''){
                        fieldMappingRecord.Id = (Id) objMap.get('id');
                    }
                    if(objMap.containskey('salesforceField')){
                        fieldMappingRecord.Salesforce_Field_Name__c = ((String) objMap.get('salesforceField')).removeEnd('.');
                    }
                    if(objMap.containskey('fieldLabel')){
                        fieldMappingRecord.Field_Label__c = ((String) objMap.get('fieldLabel'));
                    }
                    if(objMap.containskey('documentFieldId')){
                        fieldMappingRecord.Evisort_Field_Definition__c = (String) objMap.get('documentFieldId');
                    }
                    fieldMappingRecord.Object__c = (String) result.get('ObjectName');
                    documentFieldMappingRecord.add(fieldMappingRecord);
                }
                upsert documentFieldMappingRecord;
            }
            else{
                throw new ExportServiceException( result.get('ObjectName') + ' ' + 'Already Mapped'); 
            }
        }
    }

    public static List<AdminMsg.SyncFieldAggregateResultWrapper> getDocumentFieldSyncMappingRecord(){
        List<AdminMsg.SyncFieldAggregateResultWrapper> listOfDocumentFieldMappingResults = new List<AdminMsg.SyncFieldAggregateResultWrapper>();

        List<AggregateResult> groupedDocumentFieldMappingResults = [SELECT MIN(CreatedDate) CreatedDate, MIN(LastModifiedDate) LastModifiedDate, Object__c FROM Document_Field_Sync_Mapping__c GROUP BY Object__c ];
        if(groupedDocumentFieldMappingResults.size() > 0){
            for (AggregateResult ar : groupedDocumentFieldMappingResults) {
                listOfDocumentFieldMappingResults.add(new AdminMsg.SyncFieldAggregateResultWrapper(ar));
            }
        }
        return listOfDocumentFieldMappingResults;
    }

    public static Map<String,String> getMappingDataTypes(){
        return Constants.DATA_TYPES;
    }

    public static void deleteDocumentFieldSyncMappingRecord(String objectName){
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Document_Field_Sync_Mapping__c> deleteDocumentFieldSyncMappingRecord = eeoSelector.getDocumentFieldSyncMappingRecords(objectName);
        if(!deleteDocumentFieldSyncMappingRecord.isEmpty()){
            Data.remove(deleteDocumentFieldSyncMappingRecord, false, false, false);
        }
    }

    public static List<AdminMsg.DocumentFieldSyncMappingRecord> getDocumentMappingFields(String objectName){
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Document_Field_Sync_Mapping__c> getDocumentMappingRecord = eeoSelector.getDocumentFieldSyncMappingRecords(objectName);
        
        List<AdminMsg.DocumentFieldSyncMappingRecord> getDocumentFieldSyncMappingRecord = new List<AdminMsg.DocumentFieldSyncMappingRecord>();
        
        for (Document_Field_Sync_Mapping__c dfm : getDocumentMappingRecord) {
            getDocumentFieldSyncMappingRecord.add(new AdminMsg.DocumentFieldSyncMappingRecord(dfm));
        }
        
        return getDocumentFieldSyncMappingRecord;
    }

    public class ExportServiceException extends Exception {
    }
}