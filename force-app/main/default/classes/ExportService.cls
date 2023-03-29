public with sharing class ExportService {
    /**
     * Gets the explicitly and unexplicitly defined Export Object records for the UI and calculates progress
     * @return   ExportStatus msg
     */
    public static ExportMsg.ExportStatus getExportObjects() {
        Set<Id> exportFilterIds = new Set<Id>();
        ExportMsg.ExportStatus msg = new ExportMsg.ExportStatus();

        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Filter__c> objects = eeoSelector.getExportObjects();
        Map<Id, List<Evisort_Export_Object__c>> mapOfIdWithExportObjectAggregateResult = new Map<Id, List<Evisort_Export_Object__c>>();

        for (Evisort_Export_Filter__c eeo : objects) {
            exportFilterIds.add(eeo.id);
        }
        if(!exportFilterIds.isEmpty()){
            List<Evisort_Export_Object__c> schResults = [ SELECT Evisort_Export_Filter__c, Status__c, Total_Size__c, Oversized__c, Number_of_Documents__c,
                            Errored__c,Grouped_Error__c, 
                            Completed__c FROM Evisort_Export_Object__c
                            WHERE Evisort_Export_Filter__c IN: exportFilterIds AND Evisort_Export_Filter__r.Is_legacy__c = true
                        ];
            if(!schResults.isEmpty()){
                for (Evisort_Export_Object__c evisortExport : schResults) {
                    List<Evisort_Export_Object__c> exportList = mapOfIdWithExportObjectAggregateResult.get(evisortExport.Evisort_Export_Filter__c);
                    if (exportList == null) {
                        exportList = new List<Evisort_Export_Object__c>();
                        mapOfIdWithExportObjectAggregateResult.put(evisortExport.Evisort_Export_Filter__c, exportList);
                    }
                    exportList.add(evisortExport);
                }
            }  

            for (Evisort_Export_Filter__c eeo : objects) {
                List<Evisort_Export_Object__c> evisortObject = new List<Evisort_Export_Object__c>();
                if(mapOfIdWithExportObjectAggregateResult.containskey(eeo.id)){
                    evisortObject = mapOfIdWithExportObjectAggregateResult.get(eeo.id);    
                }
                msg.addObject(eeo, evisortObject );
            }
        }

        msg.calculate();

        Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
        if (!settings.Sync_Criteria__c) {
            // Global setting is not set, so grab the values from the Custom Setting
            List<Evisort_Document_Sync_Criteria__c> syncCriteriaList = Evisort_Document_Sync_Criteria__c.getAll()
                .values();

            for (Evisort_Document_Sync_Criteria__c criteria : syncCriteriaList) {
                msg.addObject(criteria);
            }
        }

        msg.sort();

        msg.oversizedReportId = (Test.isRunningTest() ? null : [SELECT Id FROM Report WHERE FolderName = :Constants.EVISORT_FOLDER_NAME AND Name = :Constants.OVERSIZED_REPORT_NAME].Id);
        msg.errorReportId = (Test.isRunningTest() ? null : [SELECT Id FROM Report WHERE FolderName = :Constants.EVISORT_FOLDER_NAME AND Name = :Constants.ERROR_REPORT_NAME].Id);
        return msg;
    }

    /**
     * Run the Calculate Batch job on the object
     * @param  eo ExportObject msg containing name, file types, and record types
     * @return    TRUE if the batch job started, excepton thrown if there is an error
     */
    public static Boolean calculateObject(ExportMsg.ExportObject eo) {
        String libraryName;
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Object__c> objects = eeoSelector.getObjectJobs(new List<String>{eo.objectLabel});
        List<Evisort_Export_Object__c> objectsToRemove = new List<Evisort_Export_Object__c>();

        Set<Id> exportFilterIds = new Set<Id>();
        for (Evisort_Export_Object__c eeo : objects) {
            if (Constants.EXPORT_COMPLETE_STATUSES.contains(eeo.Status__c)) {
                // Previously completed job, so we want to remove the old Object record and its related Documents
                objectsToRemove.add(eeo);
                exportFilterIds.add(eeo.Evisort_Export_Filter__c);
            } else {
                String errorLabel = '';
                errorLabel = eo.enableLibraryFilter == true ? eeo.Evisort_Export_Filter__r.Name : eo.objectLabel;
                throw new ExportServiceException( errorLabel + ' ' + System.Label.Admin_AlreadyCalculated); 
            }
        }

        if(exportFilterIds.size() > 0){
            List<Evisort_Export_Filter__c> eefList = eeoSelector.getExportFilterByIds(exportFilterIds);
            if (!eefList.isEmpty()) {
                Data.remove(eefList);
            }
        }

        if (!objectsToRemove.isEmpty()) {
            Data.remove(objectsToRemove);
        }

        if (String.isNotBlank(eo.objectLabel) && eo.enableLibraryFilter == true) {
           Set<Id> libraryIds = new Set<Id>{eo.objectLabel};
            List<ContentWorkspace> contentList =  eeoSelector.getLibraryName(libraryIds); // [SELECT Id,Name FROM ContentWorkspace WHERE ID =: libraryId LIMIT 1];
            libraryName = contentList[0].Name;
        }

        Evisort_Export_Filter__c exportJob = new Evisort_Export_Filter__c();
        exportJob.Object__c = eo.objectLabel;
        exportJob.Object_Filter_Body__c  = eo.objectFilterBody;
        exportJob.File_Filter_Body__c  = eo.fileFilterBody;
        exportJob.Is_Legacy__c = eo.enableAddExport == true ? true : false;
        exportJob.Is_Library__c = eo.enableLibraryFilter == true ? true : false;
        exportJob.Name = libraryName != null ? libraryName : eo.objectLabel;
        exportJob.Library_Mapping__c = eo.libraryMapping;
        // Ignoring FLS because the user can't edit these fields via the UI
        Data.create(exportJob, true, false, true); 

        ExportCalculationBatch ecb = new ExportCalculationBatch(
            exportJob,
            eo.objectFilterBody,
            eo.fileFilterBody
        );
        Database.executeBatch(ecb, 100);

        return true;
    }

    /**
     * Resets objects by deleting their Export Object records and their Export Document children
     * @param  objectNames API Names of the Objects
     * @return             TRUE if it worked, exception thrown if it didn't
     */
    public static Boolean resetObjects(List<String> objectNames) {
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Filter__c> docObjects = eeoSelector.getSyncDocObjectJobs(objectNames);
        List<Evisort_Export_Object__c> objects = eeoSelector.getObjectJobs(objectNames);

        if (!objects.isEmpty()) {
            Data.remove(objects);
        }

       if (!docObjects.isEmpty()) {
            Data.remove(docObjects);
        } 

        return true;
    }

    /**
     * Starts the Export for all Export Object records in READY status
     * @return   TRUE if it worked, FALSE if there are no READY objects to process
     */
    public static Boolean startExport() {
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Object__c> objects = eeoSelector.getEvisortExportObjects(Constants.EXPORT_READY);

        if (objects.isEmpty()) {
            return false;
        }

        for (Evisort_Export_Object__c eeo : objects) {
            eeo.Status__c = Constants.EXPORT_RUNNING;
        }

        // Ignoring FLS because the user can't edit these fields via the UI
        Data.modify(objects, true, false, true);

        if (!Test.isRunningTest()) {
            getNextDocumentBatch();
        }

        return true;
    }

    /**
     * Cancels the Export for all Export Object records in RUNNING status
     * @return   TRUE if it worked, FALSE if there are no RUNNING objects to process
     */
    public static Boolean cancelExport() {
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Object__c> objects = eeoSelector.getEvisortExportObjects(Constants.EXPORT_RUNNING);

        if (objects.isEmpty()) {
            return false;
        }

        for (Evisort_Export_Object__c eeo : objects) {
            eeo.Status__c = Constants.EXPORT_CANCELLED;
        }

        // Ignoring FLS because the user can't edit these fields via the UI
        Data.modify(objects, true, false, true);  

        return true;
    }

    /**
     * Does the actual API call for a document - similar code to DocumentQueueableHelper.uploadDocument()
     * @param  item QueueScience Item record
     */
    public static void doDocumentExport(QueueItem__c item) {
        List<Evisort_Export_Document__c> evisortExportList = [SELECT Id, Evisort_Export_Object__c,ContentDocument__c, ContentVersion__c, Evisort_Export_Object__r.Id, Evisort_Export_Object__r.Name, Error_Message__c, Is_Oversized__c, Record_ID__c, Record_Name__c, Status__c, Title__c FROM Evisort_Export_Document__c WHERE Evisort_Export_Object__C =: item.RecordId__c ];

        String domain = URL.getOrgDomainUrl().toExternalForm();
        String thisNamespace = ExportService.class.getName().substringBefore('ExportService').removeEnd('.');
        String documentStatusURL = (String.isBlank(thisNamespace))
            ? '/services/apexrest/EvisortDocumentMapping'
            : '/services/apexrest/' + thisNamespace + '/EvisortDocumentMapping';
        String groupStatusURL = (String.isBlank(thisNamespace))
            ? '/services/apexrest/EvisortGroupStatusUpdate'
            : '/services/apexrest/' + thisNamespace + '/EvisortGroupStatusUpdate';
        
        if(evisortExportList.isEmpty()) {
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = 'Evisort_Export_Document__c record not found with Id: ' + item.RecordId__c;
        }else {
            try{
                Integer totalCount = evisortExportList.size();
                String reqBody = '{';
                reqBody += '"documentGroupImportId": "' + item.RecordId__c + '"';
                reqBody += ',"documentStatusCallback" :"'+ domain + documentStatusURL+'"';
                reqBody += ',"groupStatusCallback" :"'+ domain + groupStatusURL+'"';
                reqBody += ' , "records": [';
                Integer count = 1;
                for(Evisort_Export_Document__c eedlist : evisortExportList){ 
                    String uploadPath;
                    DocumentMsg.RecordData recordData = DocumentQueueableHelper.getRecordData(eedlist.Record_ID__c);
                    uploadPath = DocumentQueueableHelper.getUploadPath(recordData);
                    reqBody +=   '{';
                        reqbody +=  ' "documentImportId": "'+eedlist.Id+'",';
                        reqbody +=  ' "sourceInfo": { ';
                        if (String.isNotBlank(eedlist.ContentVersion__c)) {
                            reqbody +=  ' "type": "contentVersion",';
                            reqbody +=  ' "contentDocumentId": "'+eedlist.ContentDocument__c+'",';
                            reqbody +=  ' "contentVersionId": "'+eedlist.ContentVersion__c +'"';
                        }
                        else {
                            reqbody +=  ' "type": "attachment",';
                            reqbody +=  ' "attachmentId": "'+eedlist.ContentDocument__c+'"';
                        }       
                        reqbody +=  '  },';
                        reqbody += '"uploadPath": "/'+uploadPath +'"';
                    if(count == totalCount){
                        reqbody +=  ' }';
                    }else{
                        reqbody +=  ' },'; 
                    }
                    count++;
                }
                reqBody +=  ']';
                reqBody += '}';


                API a = new API();
                String endPoint = '/documents/import-from/salesforce';
                String body = reqBody;
                HttpResponse docInfoResponse = a.doAPICall(endPoint, 'POST', body);

                DocumentMsg.UploadResponse uploadResponse;
                if(docInfoResponse.getBody() != null && docInfoResponse.getBody() != ''){
                    uploadResponse = (DocumentMsg.UploadResponse) JSON.deserialize(docInfoResponse.getBody(), DocumentMsg.UploadResponse.class);
                }
                if (docInfoResponse.getStatusCode() == 202) {
                    item.Status__c = 'COMPLETED';
                }else{
                    item.Status__c = 'ERROR';
                    item.ErrorMessage__c = uploadResponse.error;
                    Logger errorlogger = Logger.getInstance();
                    errorlogger.log(
                        'ExportService.doDocumentExport',
                        '',
                        new List<Id>{ item.RecordId__c },
                        uploadResponse.error
                    );
                }
            }catch(Exception e){
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = e.getMessage();
                Logger errorlogger = Logger.getInstance();
                errorlogger.log('ExportService.doDocumentExport', e);
            }
        }

        // Update the QueueItem record that it has been processed, ignoring CRUD/FLS as it is not accessible to users
        if (!Test.isRunningTest()) {
            Data.modify(item, false, false, false);
        }

    }

    /**
     * Does the actual API call for a document - similar code to DocumentQueueableHelper.uploadDocument()
     * @param  item QueueScience Item record
     */
    public static void doMetadataExport(QueueItem__c item, Map<ID,QueueItem__c> mapOfQueueStatus, Integer count, Integer totalQueueitem, List<String> metaDataSyncError) {
        List<Evisort__c> evisortRecord = [SELECT Id, Name, Document_Status__c, External_ID__c, Original_File_Name__c, Record_ID__c FROM Evisort__c WHERE Id =: item.RecordId__c];
        if(evisortRecord.size() == 0) {
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = 'Evisort__c record not found with Id: ' + item.RecordId__c;
        }
        else {
            try {
                String objectName = EvisortMetadataSyncBatchUtils.getObjectName(Id.valueOf(evisortRecord[0].Record_ID__c));
                
                Map<String, List<Document_Field_Sync_Mapping__c>> mapObjectWithDfsm = EvisortMetadataSyncBatchUtils.getMapObjectNameWithFieldMapping(new Set<String>{objectName});

                Set<String> setObjFields = EvisortMetadataSyncBatchUtils.getFields(mapObjectWithDfsm.get(objectName));
                Set<Id> recordId = new Set<Id>();
                recordId.add(evisortRecord[0].Record_ID__c);
                List<SObject> qr = EvisortMetadataSyncBatchUtils.getObjectFieldValue(mapObjectWithDfsm, setObjFields, objectName, recordId, null);      

                DocumentMsg.SendValuesRequest req = EvisortMetadataSyncBatchUtils.getRequest(objectName, qr[0], mapObjectWithDfsm);
                if (req != null ) {
                    API a = new API();
                    HttpResponse response = a.doAPICall(
                        Constants.DOCUMENT_URL +
                        '/' +
                        evisortRecord[0].External_ID__c,
                        'PATCH',
                        JSON.serialize(req)
                    );

                    evisortRecord[0].Sync_Error__c = '';

                    if (response.getStatusCode() == 204) {
                        item.Status__c = 'COMPLETED';
                        mapOfQueueStatus.put(item.id, item);
                    } else if (response.getStatusCode() != 204) {
                        DocumentMsg.UploadResponse res = (DocumentMsg.UploadResponse) JSON.deserialize(
                            response.getBody(),
                            DocumentMsg.UploadResponse.class
                        );
                        evisortRecord[0].Sync_Error__c = 'ERROR : ' + res.error;

                        item.Status__c = 'ERROR';
                        item.ErrorMessage__c = res.error;
                        mapOfQueueStatus.put(item.id, item);
                    }
                }
            } catch(Exception e){
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = e.getMessage();

                metaDataSyncError.add(e.getMessage());
                mapOfQueueStatus.put(item.id, item);
            }
        }
        
        
        // Update the QueueItem record that it has been processed, ignoring CRUD/FLS as it is not accessible to users
        if (!Test.isRunningTest() && totalQueueitem == count) {
            for(QueueItem__c queueItem : mapOfQueueStatus.values()){
                Data.modify(queueItem, false, false, false);
            }
        }
    }

    /**
     * Kicks off the Export ContentDocumentLink batch for the specified QueueScience Item
     * @param  item QueueScience Item record
     */
    public static void doContentDocumentLinkExport(QueueItem__c queueItem) {
        try {
            // Determine if there is already a job queued or processing a QueueItem__c record.
            // If not, execute the job.

            String[] classNameParts = ExportContentDocumentLinkBatch.class.getName().split('\\.');
            String ns = (classNameParts.size() == 2) ? classNameParts[0] : '';
            String className = ExportContentDocumentLinkBatch.class.getName().removeStart(ns + '.');
            Id apexClassId = [SELECT Id FROM ApexClass WHERE Name = :className AND NamespacePrefix = :ns].Id;

            // Ignoring CRUD/FLS because AsyncApexJob can't be CRUD by users.
            String soql = 'SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId = :apexClassId AND Status IN (\'Queued\', \'Holding\', \'Processing\', \'Preparing\')';
            Map<String, Object> params = new Map<String, Object>{'apexClassId' => apexClassId};
            Integer jobsInProgressCount = Data.countQuery(soql, params, false, false, false);

            if (jobsInProgressCount == 0) {
                queueItem.Status__c = 'IN PROGRESS';
                Data.modify(queueItem, false, false, false);

                if (!Test.isRunningTest()) {
                    Database.executeBatch(new ExportContentDocumentLinkBatch(queueItem.Id), 2000);
                }
            }
        } catch (Exception e) {
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('ExportService.doContentDocumentLinkExport', e);
        }
    }

    /**
     * Gets the next set of documents to process over the next minute
     */
    @TestVisible
    private static void getNextDocumentBatch() {
        EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
        List<Evisort_Export_Object__c> eeoList = eeoSelector.getDocumentsForRunningJob();

        if (eeoList.isEmpty()) {
            return;
        }

        for(Evisort_Export_Object__c eeo : eeoList){
            if ((eeo.Evisort_Export_Documents__r == null) || (eeo.Evisort_Export_Documents__r.isEmpty())) {
                eeo.Status__c = Constants.EXPORT_COMPLETE;
            }
        }

        // Ignoring FLS because the user can't edit these fields via the UI
        Data.modify(eeoList, true, false, true);

        List<QueueItem__c> items = new List<QueueItem__c>();
        Datetime processAfter = Datetime.now();
        for (Evisort_Export_Object__c eed : eeoList) {
            if(!Constants.EXPORT_COMPLETE_STATUSES.contains(eed.Status__c)){
                QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                newItem.RecordId__c = eed.Id;
                newItem.Object__c = 'Evisort_Export_Document__c';
                newItem.Priority__c = 5;
                newItem.Process_After__c = processAfter;
                items.add(newItem);

                Integer delaySeconds = 60 / Constants.EXPORTS_PER_MINUTE;

                processAfter = processAfter.addSeconds(delaySeconds);
            }
        }

        if (!Test.isRunningTest() && !items.isEmpty()) {
            // Mark the last item as the last one so we can process the next batch
            items[items.size() - 1].Action_Context__c = 'LastDocument';

            // Ignoring CRUD/FLS/SHR because QueueScience items are not accessible to users
            Data.create(items, false, false, false);
        }
    }

    public static Map<String, object> getContentVersionAssociatedField( String objectName) {
        SObjectType conObjType = ((SObject) (Type.forName('Schema.' + 'ContentVersion').newInstance())).getSObjectType();
        Map<String, SObjectField> fieldsByName = conObjType.getDescribe().fields.getMap();
        List<String> conVerCustomFields = new List<String>();
        Map<String, object> mapofAssociatedField = new Map<String,object>();
        String referenceTo;
        for (SObjectField field : fieldsByName.values()) {
            if (!field.getDescribe().getReferenceTo().isEmpty()) {
                referenceTo =  String.valueOf(field.getDescribe().getReferenceTo()[0]);
                if(field.getDescribe().isCustom() && referenceTo == objectName) {
                    AdminMsg.ObjectWrapper associatedField = new AdminMsg.ObjectWrapper();
                    associatedField.label = field.getDescribe().getlabel();
                    associatedField.value = field.getDescribe().getName();
                    conVerCustomFields.add(JSON.serialize(associatedField));
                }
            }
        }
        mapofAssociatedField.put('fields', conVerCustomFields );
        return mapofAssociatedField;
    }

    public class ExportServiceException extends Exception {
    }
}