global with sharing class ExportCalculationBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String objectName;
    private Id exportId;
    private String objectFilterBody;
    private String fileFilterBody;
    private String documentSyncFiltersId;
    private Boolean enableLibrary;
    private Map<Id,String> mapofObjectIdWithName;
    private String libraryMapping;
    private Evisort_Export_Filter__c exportFilter;
    private Set<Id> filterObjetRecords;
    private List<Evisort_Export_Document__c> documents;
    private Evisort_Export_Object__c evisortExportObject;

    /**
     * Constructor
     * @param  exportJob               Evisort Export Filter data
     * @param  objectFilter            Object Filter data
     * @param  fileFilter              File Filter data
    */
    global ExportCalculationBatch( Evisort_Export_Filter__c exportJob, String objectFilter, String fileFilter) {
        this.objectName = exportJob.Object__c;
        this.exportId = null;
        this.objectFilterBody = objectFilter;
        this.fileFilterBody = fileFilter;
        this.documentSyncFiltersId = exportJob.Id;
        this.enableLibrary = exportJob.Is_Library__c;
        this.libraryMapping = exportJob.Library_Mapping__c;
        this.exportFilter = exportJob;
        documents = new List<Evisort_Export_Document__c>();
        evisortExportObject = new Evisort_Export_Object__c();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        filterObjetRecords = new Set<Id>();
        String objWhereClauseValue = ExportCalculationBatchUtils.getObjectWhereClause(this.objectFilterBody);
        String query = ExportCalculationBatchUtils.objectFilterQuery(filterObjetRecords, enableLibrary, objWhereClauseValue, objectName);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        Logger logInstance = Logger.getInstance(true);
        try {
            Set<Id> recordIds = new Map<Id, sObject>(scope).keySet();
            String objWhereClauseValue = ExportCalculationBatchUtils.getObjectWhereClause(this.objectFilterBody);
            String fileWhereClauseValue = ExportCalculationBatchUtils.getFileWhereClause(this.fileFilterBody);

            String fileSubquery = fileFilterQuery(fileWhereClauseValue);  
            String documentLinkQuery = getFilterContentDocumentLink(recordIds, fileSubquery);   

            List<ContentDocumentLink> contentDocumentLinkList = Database.query(documentLinkQuery);
            mapofObjectIdWithName = new Map<Id,String>();

            EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();

            String customFieldName;
            String libraryId;
            Boolean libraryCheckBox = false;
            List<ContentDocumentLink> contentDocumentQuery = new List<ContentDocumentLink>();
            List<Sobject> documentLinkIds;

            if(String.isNotBlank(this.libraryMapping)){
                ExportMsg.libraryObjectMapping libraryObjectMappingData  = (ExportMsg.libraryObjectMapping) JSON.deserialize(this.libraryMapping, ExportMsg.libraryObjectMapping.class);
                if(libraryObjectMappingData.isLibraryObjectCheck == true){
                    customFieldName = libraryObjectMappingData.customField;
                    libraryId = libraryObjectMappingData.libraryName;
                    libraryCheckBox = libraryObjectMappingData.isLibraryObjectCheck;
                }
            }

            if(contentDocumentLinkList.size() > 0){
                Set<Id> objectList = new Set<Id>();
                for(ContentDocumentLink con : contentDocumentLinkList){
                    objectList.add(con.LinkedEntityId);
                }

                if(objectList.size() > 0){
                    String  objectRecord = ExportCalculationBatchUtils.objectFilterQuery(objectList, enableLibrary, objWhereClauseValue, objectName);
                    List<Sobject> objRecordIds = Database.query(objectRecord);

                    mapofObjectIdWithName = new Map<Id,String>();
                    if(objRecordIds.size() > 0){
                        for(SObject obj : objRecordIds){
                            mapofObjectIdWithName.put(obj.Id, (String) obj.get('Name'));
                        } 
                    }
                }

                if(libraryCheckBox && objectList.size() > 0){
                    List<ContentVersion> libraryContentVersionList = getContentVersionRecord(fileWhereClauseValue,libraryId,customFieldName,objectList);
                    Set<Id> libraryContentDocumentIds = new Set<Id>(); 
                    for(ContentVersion conDocId : libraryContentVersionList){
                        libraryContentDocumentIds.add(conDocId.ContentDocumentId);
                    } 
                    Set<Id> libraryIds = new Set<Id>();
                    libraryIds.add(libraryId);
                    List<ContentWorkspace> libraryRecord =  eeoSelector.getLibraryName(libraryIds);
                    String libName =  libraryRecord[0].Name;
                    mapofObjectIdWithName.put(libraryId, libName);

                    List<ContentDocumentLink> conLink = getContentDocumentLinkRecord(libraryContentDocumentIds, libraryIds);
                    if(conLink.size() > 0){
                        contentDocumentLinkList.addall(conLink);
                    }
                }
                if(contentDocumentLinkList.size() > 0){

                    evisortExportObject = new Evisort_Export_Object__c();
                    evisortExportObject.Object__c = this.objectName ;
                    evisortExportObject.Evisort_Export_Filter__c = documentSyncFiltersId;
                    evisortExportObject.Status__c = Constants.EXPORT_CALCULATING;
                    // Ignoring FLS because the user can't edit these fields via the UI
                    Data.create(evisortExportObject, true, false, true);
                    
                    this.exportId = evisortExportObject.Id;
                    
                    for (ContentDocumentLink l : contentDocumentLinkList) {
                        // This is checked in the query because of this the export object, It was creating with 0 records.
                        /* 
                        if (l.ContentDocument.LatestPublishedVersion.Evisort__c != null) {
                            continue;
                        }
                        */
                        Evisort_Export_Document__c doc = new Evisort_Export_Document__c();
                        doc.Evisort_Export_Object__c = exportId;
                        doc.Record_ID__c = l.LinkedEntityId;

                        if(mapofObjectIdWithName.containsKey(l.LinkedEntityId)){
                            doc.Record_Name__c = mapofObjectIdWithName.get(l.LinkedEntityId);
                        }
                        doc.ContentDocument__c = l.ContentDocumentId;
                        doc.ContentVersion__c = l.ContentDocument.LatestPublishedVersionId;
                        doc.File_Size__c = l.ContentDocument.ContentSize;
                        doc.Title__c = l.ContentDocument.Title; 
                        documents.add(doc);

                        if (documents.size() == 100) {  
                            Data.create(documents, true, false, true);
                            documents = new List<Evisort_Export_Document__c>(); 
                            
                            evisortExportObject = new Evisort_Export_Object__c();
                            evisortExportObject.Object__c = this.objectName ;
                            evisortExportObject.Evisort_Export_Filter__c = documentSyncFiltersId;
                            evisortExportObject.Status__c = Constants.EXPORT_CALCULATING;
                            // Ignoring FLS because the user can't edit these fields via the UI
                            Data.create(evisortExportObject, true, false, true); 
                            this.exportId = evisortExportObject.Id;
                        }
                    }
                }
            }
        } catch (Exception e) {
            documents = new List<Evisort_Export_Document__c>(); 
            logInstance.log('ExportCalculationBatch.execute', e);
        }

        logInstance.finalize();
    }

    global void finish(Database.BatchableContext bc) {
        if (documents.size()  > 0) {
            Data.create(documents, true, false, true);
        }

        if(enableLibrary == false){
            EvisortAttachmentCalculationBatch eacb = new EvisortAttachmentCalculationBatch(
                this.exportFilter,
                this.objectFilterBody,
                this.fileFilterBody,
                this.exportId
            );
            Database.executeBatch(eacb, 100); 
        }else{
            ExportCalculationBatchUtils.updateEvisortStatus(this.exportId, null, exportFilter);
        }
    }

    global List<String> getDefaultFields(){
        List<String> queryFields = new List<String>();
        queryFields.add('ContentDocument.ContentSize');
        queryFields.add('ContentDocument.FileType');
        queryFields.add('ContentDocument.Title');
        queryFields.add('ContentDocument.LatestPublishedVersion.Evisort__c');
        queryFields.add('ID');
        queryFields.add('ContentDocumentId');
        queryFields.add('LinkedEntityId');

        return queryFields;
    }

    private static String fileFilterQuery(String fileWhereClauseValue){
        String queryContent = 'SELECT Id FROM ContentDocument';
        if(fileWhereClauseValue != null){
            queryContent += ' WHERE ' + fileWhereClauseValue;
        }
       return queryContent;
    }

    private static List<ContentVersion> getContentVersionRecord(String fileWhereClauseValue, String libraryId, String customFieldName,Set<Id> entityIds ){
        String queryContent = 'SELECT Id, ContentDocumentId FROM ContentVersion';
          queryContent += ' WHERE Evisort__c = null ';
          if(fileWhereClauseValue != null){
              queryContent += ' AND ' + fileWhereClauseValue;
          }
          if(libraryId != null){
              queryContent += ' AND (ContentDocument.parentid = '+'\''  + libraryId + '\''+' AND '+ customFieldName +' IN: entityIds )';
          }  

          return Database.query(queryContent); 
      }

    private String getFilterContentDocumentLink(Set<Id> recordIds, String fileSubquery){      
        String contentDocQuery = 'SELECT ' + String.join(getDefaultFields(), ',') + ' FROM ContentDocumentLink';
        contentDocQuery += ' WHERE LinkedEntityId IN :recordIds';
        contentDocQuery += ' AND ContentDocumentId IN (' +fileSubquery+ ')';
        contentDocQuery += ' AND ContentDocument.IsArchived = false';
        contentDocQuery += ' AND ContentDocument.IsDeleted = false ';
        contentDocQuery += ' AND ( ContentDocument.LatestPublishedVersion.Evisort__c = null';
        contentDocQuery += ' OR ContentDocument.LatestPublishedVersion.Evisort__r.External_ID__c = null )';
        return contentDocQuery;
    }   
    
    
    private List<ContentDocumentLink> getContentDocumentLinkRecord(Set<Id> contentDocumentIds,Set<Id> entityIds){      
        Map<String, Object> queryArgs = new Map<String, Object>{ 
             'entityIds' => entityIds,
             'contentDocumentIds' => contentDocumentIds
         };    
         String contentDocQuery = 'SELECT ' + String.join(getDefaultFields(), ',') + ' FROM ContentDocumentLink';
         contentDocQuery += ' WHERE LinkedEntityId IN: entityIds';
         contentDocQuery += ' AND ContentDocumentId IN: contentDocumentIds';
         contentDocQuery += ' AND ContentDocument.IsArchived = false';
         contentDocQuery += ' AND ContentDocument.IsDeleted = false ';
 
         List<sObject> filterContentDocumentList = new List<sObject>();
         filterContentDocumentList = Data.read(
             contentDocQuery,
             queryArgs,
             true,
             true,
             true
         ); 
 
         return Database.query(contentDocQuery);
     }  
}