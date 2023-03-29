public with sharing class ExportCalculationBatchUtils {
    public static void updateEvisortStatus(Id exportId, ID contentExportId, Evisort_Export_Filter__c evisortExportFilterId){
        if(exportId == null || contentExportId == null){
            Evisort_Export_Object__c exportJob = new Evisort_Export_Object__c();
            exportJob.Object__c = evisortExportFilterId.Object__c;
            exportJob.Evisort_Export_Filter__c = evisortExportFilterId.id;
            exportJob.Status__c = Constants.EXPORT_READY;             
            // Ignoring FLS because the user can't edit these fields via the UI
            Data.create(exportJob, true, false, true);  
        }
        
        if(exportId != null || contentExportId != null){
            List<Evisort_Export_Object__c> eeoList = [SELECT OwnerId, Id, Name, Status__c, File_Types__c, Object__c, Evisort_Export_Filter__c FROM Evisort_Export_Object__c WHERE Object__c =: evisortExportFilterId.Object__c AND 
            Status__c =: Constants.EXPORT_CALCULATING AND Evisort_Export_Filter__c =: evisortExportFilterId.id ];

            for(Evisort_Export_Object__c eeo: eeoList){
                eeo.Status__c = Constants.EXPORT_READY;
            }
            Data.modify(eeoList, true, false, true); 
        }
    }

    public static String objectFilterQuery(Set<Id> recordIds, Boolean enableLibrary, String objWhereClauseValue, String objectName){
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        String subquery = 'SELECT Id';
        subquery += recordIds.size() > 0 ? ', Name' : '';
        subquery += ' FROM '; 
        if(enableLibrary == true ){
            Set<Id> libraryIds = new Set<Id>{objectName};
            List<ContentWorkspace> libraryRecords =  eeoSelector.getLibraryName(libraryIds);
            String library =  libraryRecords[0].Name;
            subquery += 'ContentWorkspace WHERE Name = '+ '\''  + library + '\'';
            if(String.isNotBlank(objWhereClauseValue)){
                subquery += 'AND '+ objWhereClauseValue;
            }
            if(recordIds.size() > 0){
                subquery += ' AND Id IN: recordIds';
            }
        }else{
            subquery += objectName;
            if(String.isNotBlank(objWhereClauseValue)){
                subquery += ' WHERE '+objWhereClauseValue;
                subquery +=  recordIds.size() > 0 ? ' AND' : '';
            }else{
                subquery +=  recordIds.size() > 0 ? ' WHERE' : '';  
            }

            if(recordIds.size() > 0){
                subquery +=  ' Id IN: recordIds';
            }
        }
        return subquery;
    }

    public static String getObjectWhereClause(String objectFilterBody){
        String objWhereClauseValue;
        EvisortWhereClause eviWhereClause = new  EvisortWhereClause();
        if(String.isNotBlank(objectFilterBody)){
            objWhereClauseValue = eviWhereClause.whereClause(objectFilterBody);
        }
        return objWhereClauseValue;
    }

    public static String getFileWhereClause(String fileFilterBody){
        String fileWhereClauseValue;
        EvisortWhereClause eviWhereClause = new  EvisortWhereClause();
        if(String.isNotBlank(fileFilterBody)){
            fileWhereClauseValue = eviWhereClause.whereClause(fileFilterBody);
        }

        return fileWhereClauseValue;
    }
}