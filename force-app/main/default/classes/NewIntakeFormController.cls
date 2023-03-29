/**
 * @description Controller for handling New Intake Form requests
 */
public with sharing class NewIntakeFormController {

    /**
     * @description Communicate with the Evisort API to retrieve all
     * intake forms.
     * @return   A JSON string of intake forms.
     */
    @AuraEnabled
    public static String getIntakeFormsByVisibility(String recordId) {
        try {
            String sObjectName ;
            if(recordId != null){
                sObjectName = String.valueOf( Id.valueOf(recordId).getSObjectType());
            } 
            WorkspaceSettingsMsg workspaceSettingsMsg = IntakeFormService.getWorkspaceSettings();
            String response = IntakeFormService.getIntakeFormList().getBody();
            if (String.isNotBlank(workspaceSettingsMsg.visibility) && workspaceSettingsMsg.visibility.equalsIgnoreCase('Mapped'))
            {

                List<String> mappedWorkflowIds = IntakeFormService.getMappedWorkflowIds(sObjectName);
         
                response = IntakeFormService.getFilteredResponse(response, mappedWorkflowIds);
            }
            return response;
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('NewIntakeFormController.getIntakeFormsByVisibility', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Communicate with the Evisort API to retrieve all
     * intake forms.
     * @return   A JSON string of intake forms.
     */
    @AuraEnabled(cacheable=true)
    public static String getIntakeForms() {
        try {
            return IntakeFormService.getIntakeFormList().getBody();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void removeDocument(List<String> docIds) {
        try {
            IntakeFormService.removeDocument(docIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Map<String, List<IntakeFormMappingService.ChildObjectData>>> getIntakeFormsMappings(
        Id parentId,
        String workflowId
    ) {
        try {
            return IntakeFormMappingService.getIntakeFormsMappings(parentId, workflowId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('NewIntakeFormController.getIntakeFormsMappings', e);
            throw new AuraHandledException(e.getMessage());
        }
    }
/* ------------------ 21-03-2023---------------------*/
    @AuraEnabled
    public static List<ContentDocumentsAndAttachments> getContentDocumentAndAttachments (String recordId){
        List<ContentDocumentsAndAttachments> contentDocumentAndAttachmentsList = new List<ContentDocumentsAndAttachments>();
        List<Attachment> attahmentList = [SELECT Id, ParentId, Name, ContentType
                                         FROM Attachment WHERE ParentId =:recordId];
        for(Attachment  attach : attahmentList){
            ContentDocumentsAndAttachments filesData = new ContentDocumentsAndAttachments();
            filesData.Id = attach.Id;
            String name = attach.Name;  
            List<string> nameList = name.split('\\.');
            filesData.Title = String.valueOf(nameList[0]);
            filesData.FileExtension = String.valueOf(nameList[(nameList.size()-1)]);
            if(Constants.DOCUMENT_FILE_TYPE.containsKey(filesData.FileExtension))
            {
                filesData.FileType = Constants.DOCUMENT_FILE_TYPE.get(filesData.FileExtension);
            }
            contentDocumentAndAttachmentsList.add(filesData);
        }

        List<ContentDocumentLink> cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
		Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdls) {
            documentIds.add(cdl.ContentDocumentId);
        }
        List<ContentDocument> documentsList = [SELECT Id, Title, FileType, FileExtension FROM ContentDocument
                                           WHERE Id IN :documentIds ];
        for(ContentDocument documents :documentsList){
            ContentDocumentsAndAttachments filesData = new ContentDocumentsAndAttachments();  
            filesData.Id =documents.Id;
            filesData.Title = documents.Title;
            filesData.FileExtension =documents.FileExtension;
            filesData.FileType =documents.FileType;
            contentDocumentAndAttachmentsList.add(filesData);
        }
        return contentDocumentAndAttachmentsList; 
    }
    
    public class ContentDocumentsAndAttachments{
        @AuraEnabled 
        public String Title;
        @AuraEnabled 
        public String FileExtension;
        @AuraEnabled 
        public String FileType;
        @AuraEnabled 
        public String Id;
    }
}