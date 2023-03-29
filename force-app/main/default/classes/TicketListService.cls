public with sharing class TicketListService {
    /**
     * @description Queries for Evisort Ticket records by parent Id
     * @param  parentId     The id of parent record associated with tickets
     * @param  limitTo      Number of records to return
     * @return              List of Evisort Tickets
     */
    @AuraEnabled
    public static List<Evisort_Ticket__c> getEvisortTicketsByParentId(String parentId, String limitTo) {
        List<String> fields = new List<String>{
            'Id',
            'Evisort_Name__c',
            'Evisort_ID__c',
            'Submitted_By__c',
            'Status__c',
            'Stage__c',
            'Assigned_To__c',
            'CreatedDate',
            'LastModifiedDate'
        };

        Integer numRecords = 0;
        String query =
            'SELECT ' +
            String.join(new List<String>(fields), ', ') +
            ' FROM ' +
            ' Evisort_Ticket__c' +
            ' WHERE Parent_Record_ID__c = :parentId' +
            ' ORDER BY CreatedDate DESC';

        if (Integer.valueOf(limitTo) > 0) {
            query += ' LIMIT :numRecords';
            numRecords = Integer.valueOf(limitTo);
        }

        Map<String, Object> queryArgs = new Map<String, Object>{ 'parentId' => parentId, 'numRecords' => numRecords };

        List<Evisort_Ticket__c> records = Data.read(query, queryArgs, true, true, true);

        return records;
    }
}