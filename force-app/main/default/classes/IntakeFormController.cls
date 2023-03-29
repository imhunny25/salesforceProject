public with sharing class IntakeFormController {
    /**
     * @description Communicate with the Evisort API to retrieve all
     * intake forms.
     * @return   A JSON string of intake forms.
     */
    @AuraEnabled
    public static String getIntakeForms() {
        try {
            return IntakeFormService.getIntakeFormList().getBody();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Communicate with the Evisort API to retrieve
     * a single intake form by id.
     * @param  id The id of the intake form
     * @return    A JSON string representation of the intake form.
     */
    @AuraEnabled
    public static String getIntakeForm(String id) {
        try {
            return IntakeFormService.getIntakeForm(id).getBody();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Retrieves an intake form from Evisort API by Id, and includes mapped field data
     * for provided recordId if any exists
     * @param  recordId     The id of record
     * @param  workflowId   The externalId of the intake form selected
     * @return              A response body including intake form metadata, fields, and mapped field data
     */
    @AuraEnabled
    public static Map<String, Object> getIntakeFormWithData(
        Id recordId,
        String workflowId,
        Map<String, Map<Id, Object>> childData
    ) {
        try {
            return IntakeFormService.getIntakeFormWithMappedData(recordId, workflowId, childData);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Retrieve SObject names for use in mapping comboboxes.
     * @return   A list of SObject names
     */
    @AuraEnabled
    public static List<Map<String, String>> getObjects() {
        try {
            return AdminService.getObjectsWithLabels();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Retrieve API names for all fields on an SObject.
     * @param  objectApiName The developer name of an SObject.
     * @return               A list of field API names.
     */
    @AuraEnabled
    public static Map<String,List<Map<String, String>>> getFields(String objectApiName,List<Object> workflowFields) {
        try {
            return AdminService.getObjectFieldNames(objectApiName,workflowFields);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<IntakeFormMsg.IntakeForm> getRecords() {
        try {
            return IntakeFormService.getRecords();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<IntakeFormMsg.IntakeForm> getRecordsByObject(String objectApiName) {
        try {
            return IntakeFormService.getRecordsByObject(objectApiName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> saveRecords(String intakeForm) {
        try {
            return IntakeFormService.saveRecords(
                (IntakeFormMsg.IntakeForm) JSON.deserialize(intakeForm, IntakeFormMsg.IntakeForm.class)
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> deleteRecord(Id id) {
        try {
            return IntakeFormService.deleteRecord(id);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static WorkspaceSettingsMsg getWorkspaceSettings() {
        try {
            return IntakeFormService.getWorkspaceSettings();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void setWorkspaceSettings(String workspaceSettings) {
        try {
            WorkspaceSettingsMsg updatedSettingsMsg = (WorkspaceSettingsMsg) JSON.deserialize(workspaceSettings, WorkspaceSettingsMsg.class);
            IntakeFormService.setWorkspaceSettings(updatedSettingsMsg);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('IntakeFormController.setWorkspaceSettings', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> postToEvisort(Id recordId, Id formId, String objectApiName) {
        try {
            return IntakeFormService.postToEvisort(recordId, formId, objectApiName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> validate(String objectApiName, Map<String, String> fields) {
        try {
            return IntakeFormService.validate(objectApiName, fields);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> createEvisortTicket(
        Id recordId,
        String workflowId,
        String workflowName,
        String payload,
        String fieldType
    ) {
        try {
            return IntakeFormService.createEvisortTicket(recordId, workflowId, workflowName, payload, fieldType);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List <Object>  getIntakeFormOptions(String workflowId, String fieldId) {
        try {
            httpResponse res = IntakeFormService.getIntakeFormOptions(workflowId, fieldId);
            List <Object> responseValuesList = (List <Object> ) JSON.deserializeUntyped(res.getBody());
           
            return responseValuesList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateIntakeFormWithPermanentLinkId() {
        try {
            IntakeFormService.updateIntakeFormWithPermanentLinkId();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<IntakeFormService.ContentDocumentsAndAttachments> getContentDocumentAndAttachments(String recordId){
        try {
            return IntakeFormService.getContentDocumentAndAttachments(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}