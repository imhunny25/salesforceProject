public with sharing class EvisortController {
    /**
     * Gets the Field Values for the selected Evisort Record
     * @param  evisortRecordId Evisort Record ID
     * @return                 Msg with a List of Values
     */
    @AuraEnabled(cacheable=true)
    public static EvisortMsg.EvisortRecord getValues(String evisortRecordId) {
        try {
            return EvisortService.getValues(evisortRecordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Saves a list of Field Values to a specific Evisort record
     * @param  evisortRecordId Evisort Record ID
     * @param  values          Msg List of Values to save (ID and values only)
     * @return                 Msg with a List of Values, rerun (just calls EvisortService.getValues)
     */
    @AuraEnabled
    public static EvisortMsg.EvisortRecord saveValues(String evisortRecordId, String values) {
        try {
            List<EvisortMsg.Value> valueMsg = (List<EvisortMsg.Value>) JSON.deserialize(
                values,
                List<EvisortMsg.Value>.class
            );
            return EvisortService.saveValues(evisortRecordId, valueMsg);
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('EvisortController.saveValues', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets Evisort Records for an associated ID (for a related list-like component)
     * This is because we use a virtual lookup so the standard Related List functionality doesn't apply
     * @param  recordId Record ID of associated record (can be any object type)
     * @return          List of Evisort Record msgs
     */
    @AuraEnabled(cacheable=true)
    public static List<EvisortMsg.EvisortRecord> getEvisortRecords(String recordId) {
        try {
            return EvisortService.getEvisortRecords(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}