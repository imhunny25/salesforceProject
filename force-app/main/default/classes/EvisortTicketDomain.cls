public with sharing class EvisortTicketDomain extends Domain {
    /**
     * Constructor based on Domain.cls constructor with similar signature
     * @param  records List of Records
     */
    public EvisortTicketDomain(List<Evisort_Ticket__c> records) {
        super(records);
    }

    public static void ticketCompletionUpdate(List<Evisort_Ticket__c> evisortTickets, Map<Id, Evisort_Ticket__c> oldMap) {
        List<QueueItem__c> queueItemsToInsert = new List<QueueItem__c>();
        for (Evisort_Ticket__c ev : evisortTickets) {
            if (ev.Status__c == 'Completed' && ev.Status__c != oldMap.get(ev.id).Status__c) {
                QueueItem__c item = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                item.RecordId__c = ev.Evisort_ID__c;
                item.Object__c = 'Evisort_Ticket__c';
                item.Action_Context__c = 'evisortRecordUpdate';
                queueItemsToInsert.add(item);
            }
        }

        // Call Evisort API for Ticket info
        // Ignoring CRUD/FLS because QueueItems can't be edited by users
        if (!queueItemsToInsert.isEmpty() && !Test.isRunningTest()) {
            Data.create(queueItemsToInsert, false, false, false);
        }
    }

    public override void onAfterInsert() {
        List<Evisort_Ticket__c> evisortTickets = (List<Evisort_Ticket__c>) this.records;
        ticketCompletionUpdate(evisortTickets,null);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        List<Evisort_Ticket__c> evisortTickets = (List<Evisort_Ticket__c>) this.records;
        Map<Id, Evisort_Ticket__c> oldEvisortMap = (Map<Id, Evisort_Ticket__c>) oldMap;
        ticketCompletionUpdate(evisortTickets,oldEvisortMap);
    }
}