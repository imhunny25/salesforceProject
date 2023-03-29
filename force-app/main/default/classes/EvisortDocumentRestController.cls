@RestResource(urlMapping='/EvisortDocumentMapping')
global with sharing class EvisortDocumentRestController { 
  global static Boolean isLegacyExport = false;
    @HttpPost
    global static void updateDocumentstatus() {
      List<Evisort_Export_Document__c> exportDocument;
        try{
          String evisortId;
          RestRequest req = RestContext.request;
          String reqBody = req.requestBody.toString();
          DocumentRestRequestBody payload = (DocumentRestRequestBody) JSON.deserialize(reqBody, DocumentRestRequestBody.class);

          //Check and enqueue request for processing
          String docStatus = payload.status;
          String documentIds = payload.documentId;
          if(String.isNotBlank(payload.evisortId)){
            evisortId = payload.evisortId;
          }
          String errorMsg = payload.Detail;
          Boolean isLegacy = false;
          Boolean isLibrary = false;
          Evisort__c evisortRecord = new Evisort__c();
          evisortRecord.External_ID__c = evisortId;

          exportDocument = [SELECT Id, Name, Record_ID__c, ContentDocument__c, Title__c, Evisort_Export_Object__c, Evisort_Export_Object__r.Evisort_Export_Filter__r.Is_Legacy__c
                            , Evisort_Export_Object__r.Evisort_Export_Filter__r.Is_Library__c, ContentVersion__c, Evisort__c, Status__c FROM Evisort_Export_Document__c WHERE Id =: documentIds LIMIT 1 FOR UPDATE];
          if(docStatus == Constants.EXPORT_ERRORED){
            evisortRecord.Document_Status__c = 'Error';
            if(String.isNotBlank(errorMsg)){
              evisortRecord.Sync_Error__c = errorMsg.length() < 254 ? errorMsg :  errorMsg.substring(0, 254);
            }
          List<Id> errorList = new List<Id>();
            if(!exportDocument.isEmpty()){
                errorList.add(exportDocument[0].Evisort_Export_Object__c);
            }
            Logger errorlogger = Logger.getInstance();
            errorlogger.log(
                'EvisortDocumentRestController.updateDocumentstatus',
                'Evisort__c',
                errorList,
                errorMsg
              );
          }

          Schema.SObjectField externalIdField = Evisort__c.External_ID__c.getDescribe().getSObjectField();
          Data.upsurt(evisortRecord, externalIdField);
        
          if(!exportDocument.isEmpty()){
            String objectName = Id.valueOf(exportDocument[0].ContentDocument__c).getSobjectType().getDescribe().getName();
            isLegacy = exportDocument[0].Evisort_Export_Object__r.Evisort_Export_Filter__r.Is_Legacy__c;
            Evisort__c eviRecord = new Evisort__c();
            eviRecord.Id = evisortRecord.Id;
            eviRecord.Record_ID__c = exportDocument[0].Record_ID__c;
            eviRecord.Original_File_Name__c = exportDocument[0].Title__c;
            if(isLegacy){
              isLegacyExport = true;
              Data.modify(eviRecord, true, true, true);
            }

            String fileType;
            isLegacyExport = false;
            if (objectName == 'Attachment') {
                Attachment__c attach = new Attachment__c();
                String evisortDocumentName = exportDocument[0].Title__c;
                if(String.isNotBlank(evisortDocumentName)){
                    fileType = evisortDocumentName.substringAfter('.').toUpperCase(); 
                    attach.Name = evisortDocumentName.length() < 79 ? evisortDocumentName : evisortDocumentName.substring(0, 79);
                }
                attach.Attachment__c = exportDocument[0].ContentDocument__c;
                attach.Evisort__c = evisortRecord.Id;
                Data.create(attach, false, false, false);
            }
            
            if (objectName == 'ContentDocument') {
                ContentVersionSelector cvs = new ContentVersionSelector();
                ContentVersion  cv = (ContentVersion) cvs.getRecordById(exportDocument[0].ContentVersion__c);
                fileType = cv.FileType;
                ContentVersion conVer = new  ContentVersion();
                conVer.Id = exportDocument[0].ContentVersion__c;
                conVer.Evisort__c = evisortRecord.Id;
                Data.modify(conVer, false, false, false);
            }

            isLibrary = exportDocument[0].Evisort_Export_Object__r.Evisort_Export_Filter__r.Is_Library__c;
            if(Constants.CALLBACK_FILE_TYPES.contains(fileType) && !isLegacy && !isLibrary){
              QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
              newItem.RecordId__c = evisortRecord.Id;
              newItem.Object__c = 'Evisort__c';
              newItem.Action_Context__c = 'CheckRecord';
              newItem.Process_After__c = Datetime.now().addMinutes(Constants.RECORD_RETRIEVAL_WAIT_MINUTES);
              Data.create(newItem, false, false, false);
            }

            exportDocument[0].Status__c = docStatus;
            exportDocument[0].Evisort__c = evisortRecord.Id;
            if(String.isNotBlank(errorMsg)){
              exportDocument[0].Error_Message__c = errorMsg.length() < 254 ? errorMsg :  errorMsg.substring(0, 254);
            }
            Data.modify(exportDocument, true, false, true);

            if(!isLegacy){
              Data.modify(eviRecord, true, true, true);         
            }
          }
        }catch(Exception e){
            if(!exportDocument.isEmpty()){
                String errorMsg = e.getMessage();
                if(errorMsg.contains('UNABLE_TO_LOCK_ROW')){
                  exportDocument[0].Status__c = Constants.EXPORT_COMPLETED;
                  exportDocument[0].Error_Message__c = null;
                  exportDocument[0].Error_Message_Full__c = null;
                  Data.modify(exportDocument, true, false, true);
                }else{
                  exportDocument[0].Status__c = Constants.EXPORT_ERRORED;
                  exportDocument[0].Error_Message__c = errorMsg.length() < 254 ? errorMsg : errorMsg.substring(0, 254);
                  exportDocument[0].Error_Message_Full__c = errorMsg;
                  Data.modify(exportDocument, true, false, true);
                }
            }
    
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('EvisortDocumentRestController.updateDocumentstatus :', e);
        }
    }

    global class DocumentRestRequestBody {
        global String status;
        global String documentId;
        global String evisortId;
        global String Detail;
    }
}