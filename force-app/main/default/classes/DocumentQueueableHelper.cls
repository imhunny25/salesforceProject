public with sharing class DocumentQueueableHelper {
    /**
     * Uploads a ContentVersion to Evisort
     * @param  item QueueScience Item Record
     */
    public static void uploadDocument(QueueItem__c item) {
        ContentVersionSelector cvs = new ContentVersionSelector();
        ContentVersion cv = (ContentVersion) cvs.getRecordById(item.RecordId__c);

        Boolean success = true;

        try {
            Id recordId = (Id) cv.Evisort__r.Record_ID__c;
            DocumentMsg.RecordData recordData = getRecordData(recordId);

            boolean canProcess = true;
            if (String.isNotBlank(recordData.recordTypeName)) {
                canProcess = canProcessDocument(recordData);

                if (!canProcess) {
                    // This record should not be sent via the API, so we should delete the already
                    // existing Evisort record from the system. The QueueItem object is marked as completed,
                    // however we say this isn't a success, so we won't spin up a new Queue to get the values.

                    // This ignores FLS so we can update the Evisort__c value to null
                    ContentVersion cvToUpdate = new ContentVersion(Id = cv.Id, Evisort__c = null);
                    Data.modify(cvToUpdate, true, false, true);

                    // This ignores CRUD/FLS because the user cannot delete the record from the UI
                    Evisort__c recordToDelete = new Evisort__c(Id = cv.Evisort__c);
                    Data.remove(recordToDelete, false, false, false);

                    item.Status__c = 'COMPLETED';
                    success = false;
                }
            }

            if (canProcess) {
                String uploadPath = getUploadPath(recordData);

                // prettier-ignore
                Map<String, String> mapKeyValues = new Map<String, String>{ 
                    'docId' => cv.Id, 
                    'uploadPath' => uploadPath 
                };
                String filename = cv.Title + '.' + cv.FileExtension;

                API a = new API();
                HttpResponse response = a.doAPICall(Constants.DOCUMENT_URL, mapKeyValues, filename, cv);

                DocumentMsg.UploadResponse res = (DocumentMsg.UploadResponse) JSON.deserialize(
                    response.getBody(),
                    DocumentMsg.UploadResponse.class
                );

                Evisort__c eviRec = new Evisort__c(Id = cv.Evisort__c);
                if (response.getStatusCode() == 202) {
                    eviRec.External_ID__c = res.evisortId;
                    if (Constants.EVISORT_STATUSES.keySet().contains(res.status)) {
                        eviRec.Document_Status__c = Constants.EVISORT_STATUSES.get(res.status);
                    } else {
                        eviRec.Document_Status__c = 'Unknown';
                    }
                    item.Status__c = 'COMPLETED';
                } else {
                    eviRec.Document_Status__c = 'Error';
                    item.Status__c = 'ERROR';
                    item.ErrorMessage__c = res.error;
                    Logger errorlogger = Logger.getInstance();
                    errorlogger.log(
                        'DocumentQueueableHelper.uploadDocument',
                        'Evisort__c',
                        new List<Id>{ item.RecordId__c },
                        res.error
                    );
                    success = false;
                }

                // Ignoring FLS as the user shouldn't edit these values from the record
                Data.modify(eviRec, true, false, true);
            }
        } catch (Exception e) {
            // There was some other error with the callout or modification
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = e.getMessage() + ' -- ' + e.getStackTraceString();
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('DocumentQueueableHelper.uploadDocument', e);
            success = false;
        }

        // Update the QueueItem record that it has been processed, ignoring CRUD/FLS as it is not accessible to users
        if (!Test.isRunningTest()) {
            Data.modify(item, false, false, false);

            // Make a QueueItem object to check the fields 5 minutes later if it is of certain file types
            if (success && Constants.CALLBACK_FILE_TYPES.contains(cv.FileType)) {
                QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                newItem.RecordId__c = cv.Evisort__c;
                newItem.Object__c = 'Evisort__c';
                newItem.Action_Context__c = 'CheckRecord';
                newItem.Process_After__c = Datetime.now().addMinutes(Constants.RECORD_RETRIEVAL_WAIT_MINUTES);
                Data.create(newItem, false, false, false);
            }
        }
    }

    /**
     * Gets the Record Data for this record, including Parent and Record Type names
     * @param  recordId Salesforce ID of any record
     * @return          RecordData Msg
     */
    public static DocumentMsg.RecordData getRecordData(Id recordId) {
        // prettier-ignore
        Map<String, Object> queryArgs = new Map<String, Object>{
            'recordId' => recordId
        };
        String objectName = recordId.getSObjectType().getDescribe().getName();

        DocumentMsg.RecordData rd = new DocumentMsg.RecordData();
        rd.id = recordId;
        rd.objectName = objectName;

        String query = 'SELECT ';

        // Sets the default name field to Name unless it's defined in the Constants file
        // (Contract doesn't have a Name field, it's ContractNumber, for instance)
        // "Name" isn't stored as a constant because if Salesforce ever changes this then we've got bigger problems
        String nameField = 'Name';
        if (Constants.OBJECT_NAME_FIELDS.keySet().contains(objectName)) {
            nameField = Constants.OBJECT_NAME_FIELDS.get(objectName);
        }
        query += nameField;

        // If this object has Record Types, get this record's Record Type
        Boolean hasRT = hasRecordTypes(objectName);
        if (hasRT) {
            query += ', RecordType.Name';
        }

        // If this object has another name to look up to, get it here
        String directoryField = null;
        if (Constants.OBJECT_DIRECTORY_FIELDS.keySet().contains(objectName)) {
            directoryField = Constants.OBJECT_DIRECTORY_FIELDS.get(objectName);
            query += ', ' + directoryField;
        }

        query += ' FROM ' + objectName + ' WHERE Id = :recordId';

        List<SObject> objs = Data.read(query, queryArgs);

        if (!objs.isEmpty()) {
            SObject o = objs[0];
            rd.name = (String) o.get(nameField);
            if (hasRT) {
                if(o.getSObject('RecordType') != null){
                    rd.recordTypeName = (String) o.getSObject('RecordType').get('Name');
                }
            }
            if (directoryField != null) {
                // This section will be explained as if we are processing "Account.Name"
                // First we split it into its parts, {'Account', 'Name'}
                List<String> fieldNames = directoryField.split('\\.');
                // Temporary variable to store the SOBject. We start at the root.
                SObject tempObject = o;
                for (Integer i = 0; i < fieldNames.size(); i++) {
                    if (i < (fieldNames.size() - 1)) {
                        // We are parsing through the SObject relationships, so we store the
                        // SObject (in this scenario, an Account object) to our temporary variable
                        tempObject = o.getSObject(fieldNames[i]);
                    } else {
                        // We are at the end, so we get the final field and return as a String
                        // In this scenario, this is the Name field on the related Account SObject
                        rd.parentDirectory = (String) tempObject.get(fieldNames[i]);
                    }

                    // If our temporary variable is null, that means there is no relationship to be read
                    // In this scenario, this would be if the Account field was left blank on this record.
                    if (tempObject == null) {
                        break;
                    }
                }
            }
        }

        return rd;
    }

    /**
     * Generates the Upload Path based on the information in the Record Data
     * Will append a first directory if dictated by config
     * @param  recordData RecordData Msg Object
     * @return            Upload Path
     */
    public static String getUploadPath(DocumentMsg.RecordData recordData) {
        Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();

        String uploadPath = '';

        if (String.isNotBlank(status.Root_Folder__c)) {
            uploadPath += status.Root_Folder__c + '/';
        }

        if (String.isNotBlank(recordData.parentDirectory)) {
            uploadPath += recordData.parentDirectory + '/';
        }

        // Replace any forward slashes in the record name with hyphens so
        // that the forward slashes don't turn into folders in Evisort.
        String recordName = recordData.name.replace('/', '-');

        uploadPath += recordName + '/';

        return uploadPath;
    }

    /**
     * Checks to see if there are Record Types on this Object
     * @param  objectName Object Developer Name
     * @return            TRUE or FALSE
     */
    private static Boolean hasRecordTypes(String objectName) {
        DescribeCache dc = DescribeCache.getDescribeCache(objectName);
        Map<String, Schema.RecordTypeInfo> recordTypesMap = dc.objectDescribe.getRecordTypeInfosByName();

        // Return TRUE if:
        // 1. There are more than one record type on the object (including inactive or inaccessible)
        // --OR--
        // 2. There is a single Record Type that is NOT considered a "Master" record type
        return ((recordTypesMap.size() > 1) ||
        ((recordTypesMap.size() == 1) && (!recordTypesMap.values()[0].isMaster())));
    }

    /**
     * Checks to see if we can process this Document based on its Record Types and our Sync Criteria
     * @param  recordData RecordData Msg
     * @return            TRUE or FALSE
     */
    @TestVisible
    private static Boolean canProcessDocument(DocumentMsg.RecordData recordData) {
        Evisort_Status__c settings = Evisort_Status__c.getOrgDefaults();
        if (settings.Sync_Criteria__c) {
            // Global settings set - process everything
            return true;
        }

        Evisort_Document_Sync_Criteria__c criteria = Evisort_Document_Sync_Criteria__c.getInstance(
            recordData.objectName
        );
        if (!String.isBlank(criteria.Record_Type__c)) {
            List<String> recordTypes = criteria.Record_Type__c.split(',');
            for (String rt : recordTypes) {
                if (recordData.recordTypeName == rt) {
                    // Record Type is in the list
                    return true;
                }
            }
        } else {
            // All Record Types are allowed
            return true;
        }

        // Record Type not allowed
        return false;
    }

    /**
     * QueueItem version of checkEvisortRecord that updates the QueueItem and logs any exceptions
     * @param  item QueueScience Item Record
     * @return      Always true - needed for overloaded method
     */
    public static Boolean checkEvisortRecord(QueueItem__c item) {
        try {
            Boolean result = checkEvisortRecord(item.RecordId__c);
            if (result) {
                item.Status__c = 'COMPLETED';
            } else {
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = 'Call Failed - Check Logs';
            }
        } catch (Exception e) {
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = e.getMessage() + ' -- ' + e.getStackTraceString();
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('DocumentQueueableHelper.checkEvisortRecord', e);
        }

        // Update the QueueItem record that it has been processed, ignoring CRUD/FLS as it is not accessible to users
        if (!Test.isRunningTest()) {
            Data.modify(item, false, false, false);
        }

        return true;
    }

    /**
     * Initial check of a single Evisort record to initially create the data
     * This is separated out for a possible future story where a button can be pressed to do an immediate sync
     * 
     * NOTE:
     * This code can get initiated by a user without an Evisort permission set when a ContentVersion record is inserted.
     * The ContentVersion insert will cause a QueueItem__c to be created and ultimately process as that user without the
     * permission set. Because of that, CRUD/FLS needs to be ignored to ensure the check process can function even though
     * it was initiated by a user without an Evisort permission set.
     * @param  evisortRecordId Evisort__c Record Id
     * @return                 TRUE if it worked, FALSE if there was an error along the way that was already logged
     */
    public static Boolean checkEvisortRecord(Id evisortRecordId) {
        EvisortSelector eSelector = new EvisortSelector(false, false, false);
        Evisort__c evisortRecord = eSelector.getEvisortRecordWithValues(evisortRecordId);

        if (evisortRecord == null) {
            throw new DocumentQueueableHelperException('Evisort Record Doesn\'t Exist: ' + evisortRecordId);
        }

        API a = new API();
        HttpResponse res = a.doAPICall(Constants.DOCUMENT_URL + '/' + evisortRecord.External_ID__c, 'GET', null);
        DocumentMsg.Document response = (DocumentMsg.Document) JSON.deserialize(
            res.getBody(),
            DocumentMsg.Document.class
        );

        if (res.getStatusCode() != 200) {
            throw new DocumentQueueableHelperException(response.error);
        }

        if (response.status == 'READY' || response.status == 'FAILED') {
            // Grab all of the Field and Provision names to check if they exist
            Set<String> fieldNames = new Set<String>();
            Set<String> provisionNames = new Set<String>();
            for (DocumentMsg.Field field : response.fields) {
                fieldNames.add(field.name);
            }
            for (DocumentMsg.Provision provision : response.provisions) {
                provisionNames.add(provision.name);
            }

            Boolean checkResult = checkForNewFields(fieldNames, provisionNames);
            if (checkResult) {
                // Create the Evisort Field Value records and upsert them
                List<Evisort_Field_Value__c> fieldValues = parseEvisortRecord(evisortRecordId, response);
                Boolean upsertResult = upsertFieldValues(fieldValues);

                if (upsertResult) {
                    // Delete null or non-existing field values
                    List<Evisort_Field_Value__c> valuesToDelete = checkForDeletedFields(
                        evisortRecord.Evisort_Field_Values__r,
                        response.fields
                    );
                    if (!valuesToDelete.isEmpty()) {
                        // Ignoring CRUD/FLS because the user can't delete these records from the UI
                        Data.remove(valuesToDelete, false, false, false);
                    }

                    // If the Document Status has changed, update the Evisort record
                    if (evisortRecord.Document_Status__c != Constants.EVISORT_STATUSES.get(response.status)) {
                        Evisort__c recordToUpdate = new Evisort__c();
                        recordToUpdate.Id = evisortRecordId;
                        recordToUpdate.Document_Status__c = Constants.EVISORT_STATUSES.get(response.status);
                        // Ignoring CRUD/FLS because user can't edit these fields on the UI
                        Data.modify(recordToUpdate, false, false, false);
                    }
                }

                return upsertResult;
            }

            return checkResult;
        } else if (Constants.EVISORT_STATUSES.keySet().contains(response.status)) {
            if (evisortRecord.Document_Status__c != Constants.EVISORT_STATUSES.get(response.status)) {
                Evisort__c recordToUpdate = new Evisort__c();
                recordToUpdate.Id = evisortRecordId;
                recordToUpdate.Document_Status__c = Constants.EVISORT_STATUSES.get(response.status);
                // Ignoring CRUD/FLS because user can't edit these fields on the UI
                Data.modify(recordToUpdate, false, false, false);
            }
        } else {
            throw new DocumentQueueableHelperException(
                'Unhandled status on Evisort ID ' +
                evisortRecord.External_ID__c +
                ': ' +
                response.status
            );
        }

        return true;
    }

    /**
     * Parses an API return into Evisort Field Value records (no DML)
     * @param  evisortRecordId Evisort__c Record ID
     * @param  docMsg          DocumentMsg deserialized from the API response
     * @return                 List of Evisort Field Value records
     */
    private static List<Evisort_Field_Value__c> parseEvisortRecord(Id evisortRecordId, DocumentMsg.Document docMsg) {
        EvisortFieldDefinitionSelector efdSelector = new EvisortFieldDefinitionSelector(false, false, false);
        List<Evisort_Field_Definition__c> definitions = efdSelector.getActiveDefinitions();

        if (definitions.isEmpty()) {
            return null;
        }

        Map<String, Evisort_Field_Definition__c> fieldsMap = new Map<String, Evisort_Field_Definition__c>();
        Map<String, Evisort_Field_Definition__c> provisionsMap = new Map<String, Evisort_Field_Definition__c>();
        for (Evisort_Field_Definition__c efd : definitions) {
            if (efd.Field_Type__c == 'Field') {
                fieldsMap.put(efd.Name, efd);
            } else if (efd.Field_Type__c == 'Provision') {
                provisionsMap.put(efd.Name, efd);
            }
        }

        List<Evisort_Field_Value__c> fieldValues = new List<Evisort_Field_Value__c>();

        for (DocumentMsg.Field field : docMsg.fields) {
            // If this is a field that is active...
            if (fieldsMap.keySet().contains(field.name)) {
                Evisort_Field_Definition__c efd = fieldsMap.get(field.name);
                // If the values array is not empty...
                if (!field.values.isEmpty()) {
                    String value = field.values[0].value;
                    // If the first value in the array is not blank...
                    if (!String.isEmpty(value)) {
                        Evisort_Field_Value__c efv = new Evisort_Field_Value__c();
                        efv.Evisort__c = evisortRecordId;
                        efv.Evisort_Field_Definition__c = efd.Id;
                        efv.External_ID__c = evisortRecordId + '-' + efd.Id;
                        switch on efd.Data_Type__c {
                            when 'Text' {
                                efv.Text_Field__c = value;
                            }
                            when 'Number' {
                                efv.Number_Field__c = Decimal.valueOf(value);
                            }
                            when 'Boolean' {
                                efv.Checkbox_Field__c = (value == 'Yes');
                            }
                            when 'Date' {
                                efv.Date_Field__c = Date.valueOf(value);
                            }
                            when 'Picklist' {
                                efv.Picklist_Value_Selected__c = value;
                            }
                            when 'Multi Picklist' {
                                String multiValues = '';
                                for (DocumentMsg.Value picklistValue : field.values) {
                                    if (!String.isBlank(multiValues)) {
                                        multiValues += '$@#';
                                    }
                                    multiValues += picklistValue.value;
                                }
                                efv.Picklist_Value_Selected__c = multiValues;
                            }
                        }
                        fieldValues.add(efv);
                    }
                }
            }
        }

        for (DocumentMsg.Provision provision : docMsg.provisions) {
            // If this is a Provision that is active...
            if (provisionsMap.keySet().contains(provision.name)) {
                Evisort_Field_Definition__c efd = provisionsMap.get(provision.name);
                // If the content array is not empty...
                if (!provision.content.isEmpty()) {
                    List<String> values = new List<String>();

                    for (DocumentMsg.Content content : provision.content) {
                        if (String.isNotBlank(content.text)) {
                            // Add values in reverse order because the API returns them in reverse order.
                            if (values.isEmpty()) {
                                values.add(content.text);
                            } else {
                                values.add(0, content.text);
                            }
                        }
                    }

                    // If there are values...
                    if (values.size() > 0) {
                        Evisort_Field_Value__c efv = new Evisort_Field_Value__c();
                        efv.Evisort__c = evisortRecordId;
                        efv.Evisort_Field_Definition__c = efd.Id;
                        efv.External_ID__c = evisortRecordId + '-' + efd.Id;
                        efv.Text_Field__c = String.join(values, '\n\n\n');
                        fieldValues.add(efv);
                    }
                }
            }
        }

        return fieldValues;
    }

    /**
     * Upserts the Evisort Field Values array
     * @param  fieldValues List of Evisort Field Value records
     * @return             TRUE if it worked, FALSE if an exception was thrown and saved to the Log
     */
    private static Boolean upsertFieldValues(List<Evisort_Field_Value__c> fieldValues) {
        if (fieldValues != null && fieldValues.size() > 0) {
            try {
                Schema.SObjectField externalIdField = Evisort_Field_Value__c.External_ID__c.getDescribe().getSObjectField();
                // Ignoring CRUD/FLS because user can't edit these fields on the UI
                Data.upsurt(fieldValues, externalIdField, false, false, false, new Set<String>());
            } catch (Exception e) {
                Logger errorlogger = Logger.getInstance();
                errorlogger.log('DocumentQueueableHelper.upsertFieldValues', e);
                return false;
            }
        }

        return true;
    }

    /**
     * Checks to see if we received Fields or Provisions that we don't yet have a Field Definition for
     * If we don't yet have a Field or Provision, we make the necessary API call to refresh our database
     * NOTE: This should be the end of the callouts for the transaction, and should occur before any DML!
     * @param  fieldNames     Set of Field Names from API Call
     * @param  provisionNames Set of Provision Names from API Call
     * @return                TRUE if it worked, FALSE if there was a failure and we logged an Exception
     */
    @TestVisible
    private static Boolean checkForNewFields(Set<String> fieldNames, Set<String> provisionNames) {
        Boolean checkFields = false;
        Boolean checkProvisions = false;

        // Combine the two sets into one for the Selector
        Set<String> selectNames = new Set<String>(fieldNames);
        selectNames.addAll(provisionNames);
        EvisortFieldDefinitionSelector efdSelector = new EvisortFieldDefinitionSelector(false, false, false);
        List<Evisort_Field_Definition__c> defs = efdSelector.getDefinitionsByName(selectNames);

        // Grab the Names of Definitions in our system
        Set<String> fieldDefs = new Set<String>();
        for (Evisort_Field_Definition__c efd : defs) {
            fieldDefs.add(efd.Name);
        }

        // Check the inbound fields to see if they exist in our system
        Set<String> newFields = new Set<String>();
        for (String field : fieldNames) {
            if (!fieldDefs.contains(field)) {
                newFields.add(field);
            }
        }
        // If the newFields set is not empty, there is a field definition we don't have
        if (!newFields.isEmpty()) {
            checkFields = true;
        }

        // Check the inbound fields to see if they exist in our system
        Set<String> newProvisions = new Set<String>();
        for (String provision : provisionNames) {
            if (!fieldDefs.contains(provision)) {
                newProvisions.add(provision);
            }
        }
        // If the newProvisions set is empty, there is a field definition we don't have
        if (!newProvisions.isEmpty()) {
            checkProvisions = true;
        }

        // If either is not true, we want to get the right parameter and call their API to update field definitions
        // Because Fields and Provisions are separate API calls, we don't want to process Provisions if they all exist
        // Hence why we separate things out
        if (checkFields || checkProvisions) {
            String param = '';
            if (checkFields && !checkProvisions) {
                param = 'Field';
            } else if (!checkFields && checkProvisions) {
                param = 'Provision';
            }

            try {
                EvisortFieldDefinitionService.retrieveFieldOrProvisionsAPICall(param);
            } catch (Exception e) {
                Logger errorlogger = Logger.getInstance();
                errorlogger.log('DocumentQueueableHelper.checkForNewFields', e);
                return false;
            }
        }

        return true;
    }

    /**
     * Checks to see if any fields are deleted or blanked out since our last sync
     * @param  currentValues List of current Evisort Field Value records with Name and Field Type
     * @param  fields        List of Fields from the API response
     * @return               List of Evisort Field Value records to delete
     */
    private static List<Evisort_Field_Value__c> checkForDeletedFields(
        List<Evisort_Field_Value__c> currentValues,
        List<DocumentMsg.Field> fields
    ) {
        List<Evisort_Field_Value__c> valuesToDelete = new List<Evisort_Field_Value__c>();

        Map<String, Id> valueNameToIdMap = new Map<String, Id>();
        for (Evisort_Field_Value__c efv : currentValues) {
            if (efv.Evisort_Field_Definition__r.Field_Type__c == 'Field') {
                valueNameToIdMap.put(efv.Evisort_Field_Definition__r.Name, efv.Id);
            }
        }

        if (!valueNameToIdMap.isEmpty()) {
            Set<String> namesFound = new Set<String>();

            for (DocumentMsg.Field field : fields) {
                namesFound.add(field.name);
                // Check if the field value is empty, but exists in the API response
                if (
                    ((field.values == null) || (field.values.isEmpty())) &&
                    (valueNameToIdMap.keySet().contains(field.name))
                ) {
                    valuesToDelete.add(new Evisort_Field_Value__c(Id = valueNameToIdMap.get(field.name)));
                }
            }

            for (String fieldName : valueNameToIdMap.keySet()) {
                // Check if the field value no longer exists in the API response
                if (!namesFound.contains(fieldName)) {
                    valuesToDelete.add(new Evisort_Field_Value__c(Id = valueNameToIdMap.get(fieldName)));
                }
            }
        }

        return valuesToDelete;
    }

    /**
     * Do a sync of the Field Values on Evisort Documents
     * @param  nextUrl If not null, then this is the "next page" URL given by the API
     * @return         A Msg class containing the next URL (if needed) and the Datetime of the last processed document
     */
    public static DocumentMsg.DocuemntQueueableResponse doDocumentSync(String nextUrl) {
        Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
        if (!status.Authenticated__c) {
            throw new DocumentQueueableHelperException('Not Authenticated - Queueable Cannot Run');
        }

        // Get the endpoint
        String url = Constants.DOCUMENT_URL;
        if (String.isBlank(nextUrl)) {
            // This is the first call, so either get the time of the Last Document Sync
            // If this is the FIRST Document Sync, get the time that we successfully authenticated
            Datetime dateToSync = (status.Last_Document_Sync__c != null)
                ? status.Last_Document_Sync__c
                : status.Authentication_Date__c;
            String isoDate = CSUtils.formatDateTimeUTC(dateToSync);
            url += '?pageSize=' + Constants.SYNC_PAGE_SIZE + '&modifiedSince=' + isoDate;
        } else {
            // This is a subsequent call, but we want to form the callout URL ourselves, as it comes back with the entire endpoint
            // and we only want the part after /documents
            url += '?' + nextUrl.substringAfter('?');
        }

        API a = new API();
        HttpResponse res = a.doAPICall(url, 'GET', null);
        DocumentMsg.SyncResponse response = (DocumentMsg.SyncResponse) JSON.deserialize(
            res.getBody(),
            DocumentMsg.SyncResponse.class
        );

        if (res.getStatusCode() != 200) {
            throw new DocumentQueueableHelperException(response.error);
        }

        DocumentMsg.DocuemntQueueableResponse queueResponse = new DocumentMsg.DocuemntQueueableResponse(response.next);

        // Gets the Evisort ID's in this callback
        Set<String> evisortIds = new Set<String>();
        for (DocumentMsg.Document document : response.documents) {
            evisortIds.add(document.evisortId);
            // Store the Datetime of this document into our response.
            // The API returns documents in ascending order, so at the end of this for loop, this will be
            // the dateModified of the most recently modified object in this page of results
            // We do this just in case we come up with an AsyncException limit when chaining the next queueable,
            // We will just pick up where we left off when the queueable runs again.
            queueResponse.lastProcessed = (Datetime) JSON.deserialize(
                '"' +
                document.dateModified +
                '"',
                Datetime.class
            );
        }

        if (evisortIds.isEmpty()) {
            return queueResponse;
        }

        // Checks our system for the Evisort ID's that came from Salesforce
        // This way, we ignore documents in our Evisort workspace that were uploaded by other means
        EvisortSelector eSelector = new EvisortSelector();
        List<Evisort__c> evisortRecords = eSelector.getRecordsByEvisortIds(evisortIds);

        if (evisortRecords.isEmpty()) {
            return queueResponse;
        }

        // Map the Evisort External ID to the Evisort Record for parsing
        Map<String, Evisort__c> foundEvisortRecords = new Map<String, Evisort__c>();
        for (Evisort__c evisortRecord : evisortRecords) {
            foundEvisortRecords.put(evisortRecord.External_ID__c, evisortRecord);
        }

        Set<String> fieldNames = new Set<String>();
        Set<String> provisionNames = new Set<String>();
        List<Evisort_Field_Value__c> fieldValues = new List<Evisort_Field_Value__c>();
        List<Evisort_Field_Value__c> valuesToDelete = new List<Evisort_Field_Value__c>();
        List<Evisort__c> recordsToUpdate = new List<Evisort__c>();

        // Only process documents we have in our system
        for (DocumentMsg.Document document : response.documents) {
            if (foundEvisortRecords.keySet().contains(document.evisortId)) {
                Evisort__c evisortRecord = foundEvisortRecords.get(document.evisortId);

                // These are for checking to see if there are new fields or provisions to add
                for (DocumentMsg.Field field : document.fields) {
                    fieldNames.add(field.name);
                }
                for (DocumentMsg.Provision provision : document.provisions) {
                    provisionNames.add(provision.name);
                }

                // This creates the list of values to upsert if the document status is READY
                if (document.status == 'READY' || document.status == 'FAILED') {
                    List<Evisort_Field_Value__c> values = parseEvisortRecord(evisortRecord.Id, document);
                    fieldValues.addAll(values);

                    List<Evisort_Field_Value__c> removedValues = checkForDeletedFields(
                        evisortRecord.Evisort_Field_Values__r,
                        document.fields
                    );
                    if (!removedValues.isEmpty()) {
                        valuesToDelete.addAll(removedValues);
                    }
                }

                // This creates the list of Evisort records to update their status
                Evisort__c recordToUpdate = new Evisort__c();
                recordToUpdate.Id = evisortRecord.Id;
                recordToUpdate.Document_Status__c = Constants.EVISORT_STATUSES.get(document.status);
                recordsToUpdate.add(recordToUpdate);
            }
        }

        if ((fieldValues.isEmpty()) && (valuesToDelete.isEmpty()) && (recordsToUpdate.isEmpty())) {
            return queueResponse;
        }

        // Do the check for new fields, which requires a callout. A DML is done at the conclusion of this call.
        Boolean checkResult = checkForNewFields(fieldNames, provisionNames);
        if (checkResult) {
            // Attempt to upsert the values
            if (!fieldValues.isEmpty()) {
                Boolean upsertResult = upsertFieldValues(fieldValues);
                if (!upsertResult) {
                    throw new DocumentQueueableHelperException('Value Upsert failed - Check Logs');
                }
            }

            if (!valuesToDelete.isEmpty()) {
                // Ignoring CRUD/FLS because the user can't delete these records from the UI
                Data.remove(valuesToDelete, false, false, false);
            }

            if (!recordsToUpdate.isEmpty()) {
                // Ignoring FLS because user can't edit these fields on the UI
                Data.modify(recordsToUpdate, true, false, true);
            }
        }

        return queueResponse;
    }

    /**
     * Sends the values to the Evisort API
     * @param  item QueueScience Item Record
     */
    public static void sendValues(QueueItem__c item) {
        EvisortSelector eSelector = new EvisortSelector();
        Evisort__c evisortRecord = eSelector.getEvisortRecordWithChangedValues(item.RecordId__c, item.Process_After__c);
        item.Status__c = 'COMPLETED'; // Assume it worked, because null values don't mean failure

        if (
            (evisortRecord != null) &&
            (evisortRecord.Evisort_Field_Values__r != null) &&
            (!evisortRecord.Evisort_Field_Values__r.isEmpty())
        ) {
            DocumentMsg.SendValuesRequest req = new DocumentMsg.SendValuesRequest();

            try {
                for (Evisort_Field_Value__c efv : evisortRecord.Evisort_Field_Values__r) {
                    DocumentMsg.Field newField = new DocumentMsg.Field(efv.Evisort_Field_Definition__r.Name);

                    switch on efv.Evisort_Field_Definition__r.Data_Type__c {
                        when 'Text' {
                            if (efv.Text_Field__c != null) {
                                newField.values.add(new DocumentMsg.Value(efv.Text_Field__c));
                            }
                        }
                        when 'Number' {
                            if (efv.Number_Field__c != null) {
                                newField.values.add(new DocumentMsg.Value(String.valueOf(efv.Number_Field__c)));
                            }
                        }
                        when 'Boolean' {
                            if (efv.Checkbox_Field__c != null) {
                                newField.values.add(new DocumentMsg.Value((efv.Checkbox_Field__c) ? 'Yes' : 'No'));
                            }
                        }
                        when 'Date' {
                            if (efv.Date_Field__c != null) {
                                newField.values.add(
                                    new DocumentMsg.Value(CSUtils.formatDate(efv.Date_Field__c, 'YYYY-MM-dd'))
                                );
                            }
                        }
                        when 'Picklist' {
                            if (efv.Picklist_Value_Selected__c != null) {
                                newField.values.add(new DocumentMsg.Value(efv.Picklist_Value_Selected__c));
                            }
                        }
                        when 'Multi Picklist' {
                            if (efv.Picklist_Value_Selected__c != null) {
                                List<String> multiValues = efv.Picklist_Value_Selected__c.split(',');
                                for (String val : multiValues) {
                                    newField.values.add(new DocumentMsg.Value(val));
                                }
                            }
                        }
                    }

                    req.fields.add(newField);
                }

                if (!req.fields.isEmpty()) {
                    API a = new API();
                    HttpResponse response = a.doAPICall(
                        Constants.DOCUMENT_URL +
                        '/' +
                        evisortRecord.External_ID__c,
                        'PATCH',
                        JSON.serialize(req)
                    );

                    if (response.getStatusCode() == 204) {
                        // A 204 status code with no body means it worked
                        item.Status__c = 'COMPLETED';
                    } else {
                        // Any other response should be logged
                        // Since the body is just a string titled "error" we are reusing the Upload Response JSON
                        DocumentMsg.UploadResponse res = (DocumentMsg.UploadResponse) JSON.deserialize(
                            response.getBody(),
                            DocumentMsg.UploadResponse.class
                        );
                        item.Status__c = 'ERROR';
                        item.ErrorMessage__c = res.error;
                        Logger errorlogger = Logger.getInstance();
                        errorlogger.log(
                            'DocumentQueueableHelper.sendValues',
                            Logger.Level.ERROR,
                            'Evisort__c',
                            new List<Id>{ item.RecordId__c },
                            res.error,
                            null,
                            JSON.serialize(req)
                        );
                    }
                }
            } catch (Exception e) {
                // There was some other error with the callout
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = e.getMessage() + ' -- ' + e.getStackTraceString();
                Logger errorlogger = Logger.getInstance();
                errorlogger.log('DocumentQueueableHelper.sendValues', e, JSON.serialize(req));
            }
        }

        // Update the QueueItem record that it has been processed, ignoring CRUD/FLS as it is not accessible to users
        if (!Test.isRunningTest()) {
            Data.modify(item, false, false, false);
        }
    }

    /**
     * Triggered on a BEFORE DELETE of a ContentDocument, this deletes the document in Evisort and removes the Evisort record
     * Removing the Evisort record also removes all associated Field Values (due to M/D relationship)
     * @param  item QueueScience Item record
     */
    public static void deleteDocument(QueueItem__c item) {
        EvisortSelector eSelector = new EvisortSelector();
        Evisort__c evisortRecord = (Evisort__c) eSelector.getRecordById(item.RecordId__c);

        try {
            API a = new API();
            HttpResponse response = a.doAPICall(
                Constants.DOCUMENT_URL +
                '/' +
                evisortRecord.External_ID__c,
                'DELETE',
                null
            );

            if (response.getStatusCode() == 204) {
                // A 204 status code with no body means it worked, so delete the record
                // This will also remove all the associated Evisort Field Values
                // This is already inside a try/catch block so the exception will be logged if error
                // We are ignoring CRUD/FLS because the user should not be able to delete via the UI
                Data.remove(evisortRecord, false, false, false);
                item.Status__c = 'COMPLETED';
            } else {
                // Any other response should be logged
                // Since the body is just a string titled "error" we are reusing the Upload Response JSON
                DocumentMsg.UploadResponse res = (DocumentMsg.UploadResponse) JSON.deserialize(
                    response.getBody(),
                    DocumentMsg.UploadResponse.class
                );
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = res.error;
                Logger errorlogger = Logger.getInstance();
                errorlogger.log(
                    'DocumentQueueableHelper.deleteDocument',
                    'Evisort__c',
                    new List<Id>{ item.RecordId__c },
                    res.error
                );
            }
        } catch (Exception e) {
            // There was some other error with the callout or delete
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = e.getMessage() + ' -- ' + e.getStackTraceString();
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('DocumentQueueableHelper.deleteDocument', e);
        }

        // Update the QueueItem record that it has been processed, ignoring CRUD/FLS as it is not accessible to users
        if (!Test.isRunningTest()) {
            Data.modify(item, false, false, false);
        }
    }

    public class DocumentQueueableHelperException extends Exception {
    }
}