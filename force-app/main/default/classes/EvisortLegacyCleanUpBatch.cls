global with sharing class EvisortLegacyCleanUpBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String subQuery = '(SELECT Name, Status__c, Error_Message__c';
        subQuery += ' FROM Evisort_Export_Documents__r WHERE Status__c = \'Queued\')';
        Integer day = Integer.valueof(label.Legacy_TraceExportRunningTime);
        DateTime oneDayBefore = System.Now() - day;
        String query = 'SELECT Name, Status__c, LastModifiedDate, Grouped_Error__c, ' + subQuery;
        query += ' FROM Evisort_Export_Object__c WHERE Id IN (Select Evisort_Export_Object__c from Evisort_Export_Document__c)';
        query += ' AND Status__c =\'Running\'';
        if (!Test.isRunningTest()) {
        	query += ' AND LastModifiedDate <=: oneDayBefore';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Evisort_Export_Object__c> evsExportObjects) {
        try {
            if (evsExportObjects.size() > 0) {
                List<Evisort_Export_Document__c> eedToUpdate = new List<Evisort_Export_Document__c>();
                for (Evisort_Export_Object__c eeo : evsExportObjects) {
                    for (Evisort_Export_Document__c eed : eeo.Evisort_Export_Documents__r) {
                        eed.Status__c = 'Errored';
                        eed.Error_Message__c = Label.Legacy_TraceExportError;
                        eedToUpdate.add(eed);
                    }
                    eeo.Status__c = 'Cancelled';
                    eeo.Grouped_Error__c = true;
                }
                Data.modify(evsExportObjects, true, true, true);
                Data.modify(eedToUpdate, true, true, true);
            }
        } catch (Exception e) {
            Logger.getInstance().log('EvisortLegacyCleanUpBatch.finish: ', e);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }

    global void execute(SchedulableContext scon) {
        Database.executeBatch(new EvisortLegacyCleanUpBatch(),100);
    }
}