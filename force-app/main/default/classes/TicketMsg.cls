/**
 * @description a hard typed message wrapper for Evisort tickets from API response body
 */
public with sharing class TicketMsg {
    @AuraEnabled
    public Ticket data { get; set; }
    @AuraEnabled
    public String stage { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public Boolean isUpdateable { get; set; }
    @AuraEnabled
    public Boolean isReadable { get; set; }

    public class Ticket {
        @AuraEnabled
        public Datetime createdDate { get; set; }
        @AuraEnabled
        public TicketUser creator { get; set; }
        @AuraEnabled
        public TicketStage currentStage { get; set; }
        @AuraEnabled
        public TicketDocument document { get; set; }
        @AuraEnabled
        public List<TicketField> fields { get; set; }
        @AuraEnabled
        public TicketFile file { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Boolean isCancelled { get; set; }
        @AuraEnabled
        public Boolean isCompleted { get; set; }
        @AuraEnabled
        public Datetime modifiedDate { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String paperType { get; set; }
        @AuraEnabled
        public String pilotDocHandlerId { get; set; }
        @AuraEnabled
        public String stage { get; set; }
        @AuraEnabled
        public Map<String, TicketStage> stages { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public Boolean wasManuallyUpdated { get; set; }
        @AuraEnabled
        public IntakeFormService.IntakeFormResponse workflow { get; set; }
        @AuraEnabled
        public String workflowId { get; set; }
    }

    public class TicketUser {
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public Boolean isInternal { get; set; }
    }

    public class InternalTicketUser {
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public Boolean isInternal { get; set; }
    }

    public class TicketStage {
        @AuraEnabled
        public Boolean areAllTasksCompleted { get; set; }
        @AuraEnabled
        public List<TicketUser> coordinators { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public Boolean isCompleted { get; set; }
        @AuraEnabled
        public Boolean isEnabled { get; set; }
        @AuraEnabled
        public List<TicketPhase> phases { get; set; }
    }

    public class TicketPhase {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public Boolean isEnabled { get; set; }
        @AuraEnabled
        public List<TicketJudgementWrapper> judgments { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer position { get; set; }
        @AuraEnabled
        public List<String> risks { get; set; }
        @AuraEnabled
        public String status { get; set; }
    }

    public class TicketDocument {
        @AuraEnabled
        public DocCurrentVersion currentVersion { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Map<String, String> lastModifiedBy { get; set; }
    }

    public class TicketFile {
        @AuraEnabled
        public FileContent content { get; set; }
    }

    public class FileContent {
        @AuraEnabled
        public String ContentDocumentID { get; set; }
        @AuraEnabled
        public String ContentVersionID { get; set; }
    }

    public class DocCurrentVersion {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String modifiedDate { get; set; }
    }

    public class TicketJudgementWrapper {
        @AuraEnabled
        public List<String> activities { get; set; }
        @AuraEnabled
        public List<TicketApproval> approvals { get; set; }
        @AuraEnabled
        public List<String> candidates { get; set; }
        @AuraEnabled
        public List<String> comments { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Boolean isInternal { get; set; }
        @AuraEnabled
        public TicketJudgement judgement { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer position { get; set; }
        @AuraEnabled
        public String status { get; set; }
    }

    public class TicketApproval {
        @AuraEnabled
        public String comment { get; set; }
        @AuraEnabled
        public TicketUser externalUser { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Datetime lastReminderDate { get; set; }
        @AuraEnabled
        public Datetime signatureUploadDate { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public TicketUser user { get; set; }
    }

    public class TicketJudgement {
        @AuraEnabled
        public List<String> approvers { get; set; }
        @AuraEnabled
        public String conditionRule { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Decimal minApprovalCount { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer position { get; set; }
        @AuraEnabled
        public TicketSigner signer { get; set; }
    }

    public class TicketSigner {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String partyId { get; set; }
        @AuraEnabled
        public String type { get; set; }
    }

    public class TicketField {
        @AuraEnabled
        public String fieldId { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public TicketFieldBody value { get; set; }
    }

    public class TicketFieldBody {
        @AuraEnabled
        public List<String> valueList { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public List<FieldAttachmentBody> valueObjList { get; set; }
        @AuraEnabled
        public String street_1 { get; set; }
        @AuraEnabled
        public String city { get; set; }
        @AuraEnabled
        public String state { get; set; }
        @AuraEnabled
        public String country { get; set; }
        @AuraEnabled
        public String zip_code { get; set; }
        @Auraenabled
        public String currency_x { get; set; }
        @AuraEnabled
        public Decimal amount { get; set; }
        @AuraEnabled
        public String period { get; set; }
    }

    public class FieldAttachmentBody {
        @AuraEnabled
        public String ContentVersionId { get; set; }
    }

    public class ActivityLogWrapper {
        @AuraEnabled
        public List<ActivityLog> data { get; set; }
    }

    public class ActivityLog {
        @AuraEnabled
        public String action { get; set; }
        @AuraEnabled
        public ActivityLogData data { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Datetime modifiedDate { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public TicketUser user { get; set; }
        @AuraEnabled
        public String userId { get; set; }
    }

    public class ActivityLogData {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Boolean isAutomatic { get; set; }
        @AuraEnabled
        public String newStage { get; set; }
        @AuraEnabled
        public String oldStage { get; set; }
        @AuraEnabled
        public String oldName { get; set; }
        @AuraEnabled
        public String newName { get; set; }
        @AuraEnabled
        public ActivityLogDocument document { get; set; }
        @AuraEnabled
        public List<InternalTicketUser> internalUsers { get; set; }
        @AuraEnabled
        public List<TicketUser> externalUsers { get; set; }
        @AuraEnabled
        public ActivityVersion version { get; set; }
        @AuraEnabled
        public String fileName { get; set; }
        @AuraEnabled
        public String subject { get; set; }
        @AuraEnabled
        public List<String> emails { get; set; }
        @AuraEnabled
        public String body { get; set; }
        @AuraEnabled
        public TicketUser oldUser { get; set; }
        @AuraEnabled
        public TicketUser newUser { get; set; }
        @AuraEnabled
        public String currentStage { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public String stage { get; set; }
        @AuraEnabled
        public ActivityPhase phase { get; set; }
    }

    public class ActivityPhase {
        @AuraEnabled
        public String name { get; set; }
    }

    public class ActivityVersion {
        @AuraEnabled
        public Integer tag { get; set; }
        @AuraEnabled
        public String id { get; set; }
    }

    public class ActivityLogDocument {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
    }

    public class TicketParticipantWrapper {
        @AuraEnabled
        public List<TicketParticipant> data { get; set; }

        public void sortParticipants() {
            data.sort();
        }
    }

    public class TicketParticipant implements Comparable {
        @AuraEnabled
        public String role { get; set; }
        @AuraEnabled
        public TicketUser participant { get; set; }

        public Integer compareTo(Object compareTo) {
            TicketParticipant compareToParticipant = (TicketParticipant) compareTo;
            if (participant.name == compareToParticipant.participant.name)
                return 0;
            if (participant.name > compareToParticipant.participant.name)
                return 1;
            return -1;
        }
    }

    public class TicketSignDocumentWrapper {
        public String currentTicketId;	
        public String contentVersion;	
        public String contentDocument;	
        public List<String> signerIds;
    }
    
    public class TicketDocReplaceWrapper {
        public String oldDocumentId;	
        public String ticketEvisortRecordId;	
    }
}