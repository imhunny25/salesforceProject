public with sharing class EvisortService {
    /**
     * Gets the Field Values for the selected Evisort Record
     * @param  evisortRecordId Evisort Record ID
     * @return                 Msg with a List of Values
     */
    public static EvisortMsg.EvisortRecord getValues(Id evisortRecordId) {
        EvisortSelector eSelector = new EvisortSelector();
        Evisort__c evisort = eSelector.getEvisortRecordWithValues(evisortRecordId);

        return new EvisortMsg.EvisortRecord(evisort);
    }

    /**
     * Saves a list of Field Values to a specific Evisort record
     * @param  evisortRecordId Evisort Record ID
     * @param  values          Msg List of Values to save (ID and values only)
     * @return                 Msg with a List of Values, rerun (just calls getValues above)
     */
    public static EvisortMsg.EvisortRecord saveValues(Id evisortRecordId, List<EvisortMsg.Value> values) {
        List<Evisort_Field_Value__c> valueRecords = new List<Evisort_Field_Value__c>();

        for (EvisortMsg.Value v : values) {
            valueRecords.add(v.toRecord());
        }

        if (!valueRecords.isEmpty()) {
            Data.modify(valueRecords);

            // Make a QueueItem object to send the changed fields to the API
            // We set the Process After to be one minute earlier because we use that field
            // to determine which values to send over, and we don't want to send all of them
            if (!Test.isRunningTest()) {
                QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                newItem.RecordId__c = evisortRecordId;
                newItem.Object__c = 'Evisort__c';
                newItem.Action_Context__c = 'SendValues';
                newItem.Process_After__c = Datetime.now().addMinutes(-1);
                Data.create(newItem, false, false, false);
            }
        }

        return getValues(evisortRecordId);
    }

    /**
     * Gets Evisort Records for an associated ID (for a related list-like component)
     * This is because we use a virtual lookup so the standard Related List functionality doesn't apply
     * @param  recordId Record ID of associated record (can be any object type)
     * @return          List of Evisort Record msgs
     */
    public static List<EvisortMsg.EvisortRecord> getEvisortRecords(Id recordId) {
        List<EvisortMsg.EvisortRecord> msg = new List<EvisortMsg.EvisortRecord>();

        EvisortSelector eSelector = new EvisortSelector();
        List<Evisort__c> evisortRecords = eSelector.getRecordsByAssociatedId(recordId);

        for (Evisort__c evisort : evisortRecords) {
            msg.add(new EvisortMsg.EvisortRecord(evisort));
        }

        return msg;
    }
}