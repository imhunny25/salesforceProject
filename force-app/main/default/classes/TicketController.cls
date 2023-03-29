public with sharing class TicketController {
    @AuraEnabled
    public static Map<String, Object> getTicketInformation(Id ticketId) {
        try {
            return TicketService.getTicketInformation(ticketId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketController.getTicketInformation', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static TicketMsg submitNextStage(Id ticketId) {
        try {
            return TicketService.submitNextStage(ticketId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketController.submitNextStage', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static TicketMsg markComplete(Id ticketId) {
        try {
            return TicketService.markTicketComplete(ticketId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketController.markComplete', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static TicketMsg.ActivityLogWrapper getActivityLog(Id ticketId) {
        try {
            return TicketService.getActivityLog(ticketId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketController.getTicketInformation', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static TicketMsg.TicketParticipantWrapper getParticipants(Id ticketId) {
        try {
            return TicketService.getParticipants(ticketId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketController.getTicketInformation', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ContentVersion getTicketDocument(Id contentVersionId) {
        try {
            return new ContentVersionSelector().getContentVersionById(contentVersionId);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketController.getTicketInformation', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> updateTicket(Id recordId, String workflowId, String payload) {
        try {
            return TicketService.updateTicket(recordId, workflowId, payload);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String ticketReviewStatus(String ticketStatusDetails) {
        try {
            return TicketService.ticketReviewStatus(ticketStatusDetails);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String,String> getUserDetails() {
        try {
            return TicketService.getUserDetails();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadTicketSignDocument(String ticketSignDocumentDetails, String replaceDocumentId) {
        try {
            return TicketService.uploadTicketSignDocument(ticketSignDocumentDetails,replaceDocumentId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadNewVersionDocument(String documentDetails) {
        try {
            return TicketService.uploadNewVersionDocument(documentDetails);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void ticketContentDocumentLink(Id ticketId, String fileDetail) 
    {
        try {
            if(ticketId != null && String.isNotBlank(fileDetail)){
                TicketService.ticketContentDocumentLink(ticketId, fileDetail);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getEvisortRecord(String ticketId){
        try {
            return TicketService.getEvisort(ticketId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getEvisortUsers(){
        try {
            return TicketService.getEvisortUsers();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}