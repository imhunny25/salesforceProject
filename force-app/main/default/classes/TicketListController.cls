public with sharing class TicketListController {
    /**
     * @description Retrive ticket records by Parent_Record_Id__c
     * intake forms.
     * @return   A JSON string of intake forms.
     */
    @AuraEnabled
    public static List<Evisort_Ticket__c> getEvisortTicketsByParentId(String parentId, String limitTo) {
        try {
            return TicketListService.getEvisortTicketsByParentId(parentId, limitTo);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Evisort_Ticket__c> getEvisortTicketsByParentId(String parentId) {
        try {
            return TicketListService.getEvisortTicketsByParentId(parentId, null);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}