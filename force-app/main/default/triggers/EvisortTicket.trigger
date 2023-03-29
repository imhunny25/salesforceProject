trigger EvisortTicket on Evisort_Ticket__c(after insert, after update) {
    Domain.triggerHandler(EvisortTicketDomain.class);
}