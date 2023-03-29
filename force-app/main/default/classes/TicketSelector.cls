/**
 * @description Selector class for retrieving Evisort_Ticket__c records
 */
public with sharing class TicketSelector extends Selector {
    public TicketSelector() {
        super(Schema.Evisort_Ticket__c.SObjectType);
    }

    /**
     * Constructor that allows us to specify the CRUD/FLS/SHR for this instance
     * @param  enforceCRUD Enforce CRUD
     * @param  enforceFLS  Enforce FLS
     * @param  enforceShr  Enforce Sharing Rules
     */
    public TicketSelector(Boolean enforceCRUD, Boolean enforceFLS, Boolean enforceShr) {
        super(Schema.Evisort_Ticket__c.SObjectType, enforceCRUD, enforceFLS, enforceShr);
    }

    /**
     * Returns a Set that has all of the default fields. Great for using with getRecordById() and it's ilk
     * @return   Set of Strings that contain the default fields for this object
     */
    public override Set<String> getDefaultFields() {
        // prettier-ignore
        return new Set<String>{
            'Id',
            'Evisort_ID__c',
            'Evisort_Name__c',
            'Intake_Form__c',
            'Is_Completed__c',
            'Parent_Record_ID__c',
            'Assigned_To__c',
            'Stage__c',
            'Status__c'
        };
    }

    /**
     * @description a selector to get a ticket record by Evisort Id
     * @param   evisortId   External Id value
     * @return  An Evisort_Ticket__c record
     */
    public Evisort_Ticket__c getTicketByExternalId(String evisortId) {
        Map<String, Object> queryArgs = new Map<String, Object>{ 'evisortId' => evisortId };
        List<String> queryFields = new List<String>(this.getDefaultFields());
        String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Evisort_Ticket__c';
        query += ' WHERE Evisort_ID__c = :evisortId';

        List<Evisort_Ticket__c> tickets = (List<Evisort_Ticket__c>) Data.read(
            query,
            queryArgs,
            this.isEnforcingCRUD(),
            this.isEnforcingFLS(),
            this.isEnforcingShr()
        );
        return tickets.size() > 0 ? tickets[0] : null;
    }
}