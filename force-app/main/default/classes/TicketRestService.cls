/**
 * @description service class for handling incoming http requests related to Evisort_Ticket__c records.
 */
public with sharing class TicketRestService {
    /**
     * @description validates that incoming request is of certain hard coded values, and if so enqueues
     * a job to get the ticket info and update it
     */
    public static void updateTicket(List<TicketRestController.RestRequestBody> reqs) {
        //validate ticket and enque a job if update is needed
        List<String> validTargetType = new List<String>{ 'ticket', 'ticket stage' };
        List<String> validActions = new List<String>{
            'intake form edit',
            'next stage',
            'previous stage',
            'rename ticket',
            'status update',
            'ticket completion',
            'delete ticket'
        };
        List<QueueItem__c> queueItems = new List<QueueItem__c>();

        for (TicketRestController.RestRequestBody req : reqs) {
            //If target type OR action are valid, process ticket update, otherwise do nothing
            if (validTargetType.contains(req.targetType) || validActions.contains(req.action)) {
                QueueItem__c queueItem = new QueueItem__c();
                if (req.action == 'delete ticket') {
                    queueItem.Action_Context__c = 'delete';
                    queueItem.Object__c = 'Evisort_Ticket__c';
                    queueItem.RecordId__c = req.ticketId;
                    queueItems.add(queueItem);
                } else {
                    queueItem.Action_Context__c = 'update';
                    queueItem.Object__c = 'Evisort_Ticket__c';
                    queueItem.RecordId__c = req.ticketId;
                    queueItems.add(queueItem);
                }
            }
        }

        //Ignore CRUD/FLS for queue items
        Data.create(queueItems, false, false, false);
    }
}