public with sharing class IntakeFormService {
    public static HTTPResponse getIntakeForms() {
        API a = new API();
        return a.doAPICall('/contracts/workflows/available', 'GET', null);
    }

    public static HTTPResponse getIntakeForm(String id) {
        API a = new API();
        HttpResponse resp = a.doAPICall('/contracts/workflows/' + id + '/intake-form', 'GET', null);
        if (resp.getStatusCode() == 404) {
            throw new IntakeFormException(System.Label.API_Unpublished_Workflow_Error);
        } else { 
            return resp;
        }
    }

    public static HTTPResponse getIntakeFormOptions(String workflowId, String fieldId) {
        API a = new API();
        return a.doAPICall(
            '/contracts/workflows/' +
            workflowId +
            '/intake-form/fields/' +
            fieldId +
            '/options',
            'GET',
            null
        );
    }

    public static HTTPResponse getIntakeFormList() {
        HttpResponse resp = getIntakeForms();
        if (resp.getStatusCode() > 299) {
            throw new IntakeFormException(resp.getStatus());
        } else {
            return resp;
        }
    }

    /**
     * @description Service deserializes API response and adds mapped data. Due to the complex and dynamic nature of
     * the conditional logic fields, deserialization must be untyped
     * @param  recordId     The id of record
     * @param  workflowId   The externalId of the intake form selected
     * @param childData     The chosen child records <workflowFieldId, <childRecordId, childRecordName>
     * @return              A response body including intake form metadata, fields, and mapped field data
     */
    @AuraEnabled
    public static Map<String, Object> getIntakeFormWithMappedData(
        Id recordId,
        String workflowId,
        Map<String, Map<Id, Object>> childData
    ) {
        //Get Intake Form and fields from API
        HttpResponse resp = getIntakeForm(workflowId);

        if (resp.getStatusCode() > 299) {
            throw new IntakeFormException(resp.getStatus());
        }
        String responseBody = resp.getBody();
        Map<String, Object> intakeFormData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        String objectApiName = recordId.getSobjectType().getDescribe().getName();

        //Get field mappings
        IntakeFormSelector selector = new IntakeFormSelector();
        Intake_Form__c intakeForm = (Intake_Form__c) selector.getFormsWithMappingsByWorkflowId(
            workflowId,
            objectApiName
        );
        if(!Test.isRunningTest() && intakeForm != null && String.isBlank(intakeForm.Workflow_Permanent_Link_Id__c)){
            updateIntakeFormWithPermanentLinkId();
        }
        Map<String, String> mappings = new Map<String, String>();
        Map<String, String> childMappings = new Map<String, String>();

        // ensure no field is queried twice
        Set<String> fields = new Set<String>();
        Set<String> childFields = new Set<String>();

        if (intakeForm != null) {
            for (Intake_Form_Mapping__c mapping : intakeForm.Intake_Form_Mappings__r) {
                if (mapping.Salesforce_Field__c != null && String.isNotBlank(mapping.Salesforce_Field__c)) {
                    if (mapping.Salesforce_Object_Type__c != 'Child') {
                        mappings.put(mapping.Workflow_Field__c, mapping.Salesforce_Field__c);
                        fields.add(mapping.Salesforce_Field__c.tolowerCase());
                    } else {
                        childMappings.put(mapping.Workflow_Field__c, mapping.Salesforce_Field__c);
                        childFields.add(mapping.Salesforce_Field__c);
                    }
                }
            }
        }
        List<SObject> records = new List<SObject>();

        if (fields.size() > 0) {
            //get mapped data
            String query =
                'SELECT ' +
                String.join(new List<String>(fields), ', ') +
                ' FROM ' +
                intakeForm.Salesforce_Object__c +
                ' WHERE Id = :recordId' +
                ' LIMIT 1';

            Map<String, Object> queryArgs = new Map<String, Object>{
                'recordId' => recordId,
                'objectApiName' => intakeForm.Salesforce_Object__c
            };

            records = Data.read(query, queryArgs, true, true, true);
        }

        SObject record;

        if (records.size() != 1 && childData.size() < 1) {
            return intakeFormData;
        } else if (records.size() == 1) {
            record = records.get(0);
        }

        List<Object> sections = (List<Object>) intakeFormData.get('sections');

        //Using untyped response body, add mapped data to each question
        Boolean areMappingsValid = true;

        for (Object sec : sections) {
            Map<String, Object> curSection = (Map<String, Object>) sec;
            List<Object> questions = (List<Object>) curSection.get('questions');

            for (Object q : questions) {
                Map<String, Object> curQuestion = (Map<String, Object>) q;
                Map<String, Object> field = (Map<String, Object>) curQuestion.get('field');
                String fieldName = (String) field.get('name');

                if (mappings.containsKey(fieldName)) {
                    if (mappings.get(fieldName).contains('.')) {
                        List<String> lstFieldNames = mappings.get(fieldName).split('\\.');
                        String parentobj = mappings.get(fieldName).substringBefore('.');
                        if(lstFieldNames.size() > 1){
                            Integer index = 1;
                            sobject parent = record.getSObject(parentobj);
                            for (String fd : lstFieldNames) {
                                if(parent != null){
                                    if(index == lstFieldNames.size()){
                                        field.put('mappedValue', parent.get(fd));
                                    }else if(index != 1){
                                        parent = parent.getSObject(fd);
                                    }
                                }
                                index++;
                            }
                        }
                    } else {
                        field.put('mappedValue', record.get(mappings.get(fieldName)));
                    }
                    field.put('mappedFieldName', mappings.get(fieldName));
                    areMappingsValid = validateMapping(field, intakeForm.Salesforce_Object__c);

                    if (areMappingsValid == false) {
                        //If any bad mappings are found remove mapped data for question and move on
                        field.put('mappedValue', null);
                        field.put('mappedFieldName', null);
                        continue;
                    }
                }

                if (childMappings.containsKey(fieldName)) {
                    String child;

                    if (childData.containsKey(fieldName)) {
                        for (Id childValues : childData.get(fieldName).keySet()) {
                            child = childValues.getSObjectType().getDescribe().getName();
                            Object childField = childData.get(fieldName).get(childValues);
                            field.put('mappedValue', childField);
                        }
                    }
                    field.put('mappedFieldName', childMappings.get(fieldName).substringAfter('.'));
                    areMappingsValid = validateMapping(field, child);

                    if (areMappingsValid == false) {
                        //If any bad mappings are found remove mapped data for question and move on
                        field.put('mappedValue', null);
                        field.put('mappedFieldName', null);
                        continue;
                    }
                }
            }
        }
        return intakeFormData;
    }

    /**
     * @description validates mapped fields are appropriately matched with Evisort field types.
     * @param question          intake form question with field information
     * @param objectApiName     Api name of the mapped SObject for getting describe information
     * @return                  Boolean representation of validity for question being checked
     */
    private static boolean validateMapping(Map<String, Object> field, String objectApiName) {
        Boolean isValid = true;
        String type = (String) field.get('type');
        String mappedFieldName = (String) field.get('mappedFieldName');

        DescribeUtils dc = DescribeUtils.getCache(objectApiName);
        Schema.DescribeFieldResult fld = dc.getFieldDescribeWithHierarchy(mappedFieldName);
        Schema.DisplayType inputType = fld.getType();

        return isFieldValidateMapping(type,inputType);
    }

    public static Boolean isFieldValidateMapping(String type , Schema.DisplayType inputType){
        Boolean isValid;
        switch on inputType {
            when STRING {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD' ||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when TEXTAREA {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD' ||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when BOOLEAN {
                //No Evisort fields match SF boolean
                isValid = false;
            }
            when PICKLIST {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD' ||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when ADDRESS {
                if (type != 'ADDRESS') {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when INTEGER {
                if (type != 'NUMBER' && type != 'PERCENTAGE' || type == 'ADDRESS') {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when DOUBLE {
                if (type != 'NUMBER' && type != 'PERCENTAGE' || type == 'ADDRESS') {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when PERCENT {
                if (type != 'NUMBER' && type != 'PERCENTAGE' || type == 'ADDRESS') {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when ID {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when REFERENCE {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }                
            when DATE {
                if (type != 'DATE') {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when DATETIME {
                if (type != 'DATE') {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when URL {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when EMAIL {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when PHONE {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when LONG {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when MULTIPICKLIST {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when ENCRYPTEDSTRING {
                if (
                    type == 'DATE' ||
                    type == 'MONETARY_VALUE' ||
                    type == 'NUMBER' ||
                    type == 'PERCENTAGE' ||
                    type == 'TIME_PERIOD'||
                    type == 'ADDRESS'
                ) {
                    isValid = false;
                } else {
                    isValid = true;
                }
            }
            when CURRENCY {
                if(type != 'MONETARY_VALUE'){
                    isValid = false;
                } else {
                    isValid = true;
                }
            }  
            when else {
                isValid = false;
            }
        }
        return isValid;
    }

    public static List<IntakeFormMsg.IntakeForm> getRecords() {
        IntakeFormSelector formSelector = new IntakeFormSelector();
        List<Intake_Form__c> forms = (List<Intake_Form__c>) formSelector.getFormsWithMappings(null);
        List<IntakeFormMsg.IntakeForm> messages = new List<IntakeFormMsg.IntakeForm>();
        for (Intake_Form__c form : forms) {
            messages.add(new IntakeFormMsg.IntakeForm(form));
        }
        return messages;
    }

    public static List<IntakeFormMsg.IntakeForm> getRecordsByObject(String objectApiName) {
        IntakeFormSelector formSelector = new IntakeFormSelector();
        List<Intake_Form__c> forms = (List<Intake_Form__c>) formSelector.getFormsByObject(objectApiName);
        List<IntakeFormMsg.IntakeForm> messages = new List<IntakeFormMsg.IntakeForm>();
        for (Intake_Form__c form : forms) {
            messages.add(new IntakeFormMsg.IntakeForm(form));
        }
        return messages;
    }

    public static List<String> getMappedWorkflowIds(String objectname) {
        IntakeFormSelector formSelector = new IntakeFormSelector();
        List<Intake_Form__c> forms = (List<Intake_Form__c>) formSelector.getFormsWithMappings(objectname);
        List<String> workflowIds = new List<String>();
        for (Intake_Form__c form : forms) {
            workflowIds.add(form.Workflow_Id__c);
        }
        return workflowIds;
    }

    public static String getFilteredResponse(String response, List<String> workflowIds) {
        List<Object> responseObj = (List<Object>) JSON.deserializeUntyped(response);
        List<Object> filteredResponseObj = new List<Object>();

        for (Object obj : responseObj) {
            Map<String, Object> m = (Map<String, Object>) obj;
            String workflowId = m.containsKey('id') ? (String) m.get('id') : null;
            if (workflowIds.contains(workflowId)) {
                filteredResponseObj.add(m);
            }
        }
        return JSON.serialize(filteredResponseObj);
    }

    public static Map<String, Object> saveRecords(IntakeFormMsg.IntakeForm intakeForm) {
        Intake_Form__c formRecordToUpsert = intakeForm.toSObject();

        List<Database.UpsertResult> upsertResults = Data.upsurt(formRecordToUpsert, true, true, true);

        List<Intake_Form_Mapping__c> mappingsToUpsert = new List<Intake_Form_Mapping__c>();
        Set<Id> incomingMappingIds = new Set<Id>();
        for (IntakeFormMsg.IntakeFormMapping mapping : intakeForm.mappings) {
            Intake_Form_Mapping__c mappingRecord = mapping.toSObject();

            // parent the mapping record on insert, but not update
            if (mappingRecord.Id == null) {
                mappingRecord.Intake_Form__c = formRecordToUpsert.Id;
            }
            mappingsToUpsert.add(mappingRecord);

            // keep a list of mapping record ids to compare against
            // existing records - if the form fields have changed on
            // Evisort's end, we might need to toss a few records
            if (mappingRecord.Id != null) {
                incomingMappingIds.add(mappingRecord.Id);
            }
        }

        IntakeFormMappingSelector mappingSel = new IntakeFormMappingSelector(true, true, true);
        List<Intake_Form_Mapping__c> mappingsToDelete = new List<Intake_Form_Mapping__c>();

        // if we're doing an update, check the existing mappings
        // against the records about to be saved and see if there
        // are any evisort form fields that have been removed
        if (formRecordToUpsert.Id != null) {
            List<Intake_Form_Mapping__c> existingMappings = mappingSel.getByParentId(formRecordToUpsert.Id);
            for (Intake_Form_Mapping__c mapping : existingMappings) {
                if (!incomingMappingIds.contains(mapping.Id)) {
                    mappingsToDelete.add(mapping);
                }
            }
        }

        // construct final response
        Map<String, Object> results = new Map<String, Object>{ 'success' => true, 'errors' => new List<String>() };

        if (mappingsToUpsert.size() > 0) {
            upsertResults.addAll(Data.upsurt(mappingsToUpsert, true, true, true));
        }

        for (Database.UpsertResult result : upsertResults) {
            if (!result.isSuccess()) {
                results.put('success', false);
            }
        }

        if (mappingsToDelete.size() > 0) {
            List<Database.DeleteResult> deleteResults = Data.remove(mappingsToDelete, true, true, true);
            for (Database.DeleteResult result : deleteResults) {
                if (!result.isSuccess()) {
                    results.put('success', false);
                }
            }
        }

        return results;
    }

    public static Map<String, Object> deleteRecord(Id id) {
        Intake_Form__c recordToDelete = new Intake_Form__c(Id = id);
        List<Database.DeleteResult> results = Data.remove(recordToDelete, true, true, true);
        return new Map<String, Object>{ 'success' => results[0].isSuccess() };
    }

    public static WorkspaceSettingsMsg getWorkspaceSettings() {
        //Rohit - changed to org defaults as we are not having user based settings. org default will return the id. Instance will not.
        //Evisort_Workspace_Settings__c settings = Evisort_Workspace_Settings__c.getInstance();
        Evisort_Workspace_Settings__c settings = Evisort_Workspace_Settings__c.getOrgDefaults();
        return new WorkspaceSettingsMsg(settings);
    }

    public static void setWorkspaceSettings(WorkspaceSettingsMsg settingsMsg) {
        //no need to check CRUD/FLS as this is for custom settings
        Evisort_Workspace_Settings__c settings = settingsMsg.toSObject();
        upsert settings;
    }

    public static Map<String, Object> postToEvisort(Id recordId, Id formId, String objectApiName) {
        IntakeFormSelector selector = new IntakeFormSelector();
        Intake_Form__c intakeForm = (Intake_Form__c) selector.getFormsWithMappingsById(formId);
        Map<String, String> mappings = new Map<String, String>();

        // ensure no field is queried twice
        Set<String> fields = new Set<String>();

        for (Intake_Form_Mapping__c mapping : intakeForm.Intake_Form_Mappings__r) {
            if (mapping.Salesforce_Field__c != null && String.isNotBlank(mapping.Salesforce_Field__c)) {
                mappings.put(mapping.Workflow_Field_Id__c, mapping.Salesforce_Field__c);
                fields.add(mapping.Salesforce_Field__c);
            }
        }

        String query =
            'SELECT ' +
            String.join(new List<String>(fields), ', ') +
            ' FROM ' +
            objectApiName +
            ' WHERE Id = :recordId' +
            ' LIMIT 1';

        Map<String, Object> queryArgs = new Map<String, Object>{
            'recordId' => recordId,
            'objectApiName' => objectApiName
        };
        List<SObject> records = Data.read(query, queryArgs, true, true, true);

        if (records.size() != 1) {
            throw new IntakeFormException('Error locating record to send to Evisort: ' + recordId);
        }

        SObject record = records.get(0);
        Map<String, Object> data = new Map<String, Object>();
        for (String mapping : mappings.keySet()) {
            data.put(
                mapping, // evisort field id
                getFieldValue(record, mappings.get(mapping)) // salesforce field data
            );
        }

        // https://support.evisort.com/hc/en-us/articles/4406460806039-Using-Public-APIs-to-Integrate-with-Evisort-s-Contract-Workflow
        Map<String, Object> payload = new Map<String, Object>{
            'data' => data,
            'meta' => new Map<String, String>{
                'type' => 'intake_form',
                'workflow_id' => intakeForm.Workflow_Id__c,
                'format' => 'salesforce'
            }
        };

        API a = new API();
        HttpResponse res = a.doAPICall('/contracts/persist', 'POST', JSON.serialize(payload));

        Integer statusCode = res.getStatusCode();
        return new Map<String, Object>{
            'success' => (statusCode == 201),
            'workflowId' => intakeForm.Workflow_Id__c,
            'persistKey' => res.getBody()
        };
    }

    /**
     * @description Service that takes form data from new intake form modal and constructs an http request that
     * is sent to Evisort API via POST. On successful response an Evisort_Ticket__c is created, and a content document
     * link is created if a counter party paper attachment is included.
     * @param  recordId         The id of record
     * @param  workflowId       The externalId of the intake form selected
     * @param  workflowName     The name of selected workflow
     * @param  formData         Form data from the new evisortWorkflowOptions.js
     * @return                  A response body including ticket data from API, success message, and status code
     */
    public static Map<String, Object> createEvisortTicket(
        Id recordId,
        String workflowId,
        String workflowName,
        String formData,
        String formfieldType
    ) {
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(formData);
        Map<String, Object> fieldType = (Map<String, Object>) JSON.deserializeUntyped(formfieldType);
        String contentDocumentId;
        String contentVersionId;

        //get counter party paper attachment details
        if (payload.containsKey('counterpartyFile')) {
            Map<String, Object> counterpartyFile = (Map<String, Object>) payload.get('counterpartyFile');
            List<Object> listOfCounterPartyFiles = (List<Object>)counterpartyFile.get('documentId');
            contentDocumentId = (Id)listOfCounterPartyFiles[0];
            ContentVersion version = new ContentVersionSelector()
                .getLatestContentVersionByDocumentId(contentDocumentId);
            contentVersionId = String.valueOf(version.Id);
            payload.remove('counterpartyFile');
        }

        //Handle field level attachments
        Map<String, Object> attachments = (Map<String, Object>) payload.get('attachmentFile');
        Map<Id, Map<String, String>> docInfoToSend = new Map<Id, Map<String, String>>();

        //Add all form field values and evisort field IDs into request body
        List<Map<String, Object>> fields = new List<Map<String, Object>>();

        if (attachments != null) {
            Set<String> attachmentKeyset = attachments.keySet();

            if (!attachmentKeyset.isEmpty()) {
                for (String key : attachmentKeyset) {
                    Set<Id> contentDocumentIds = new Set<Id>();
                    Map<String, Object> doc = (Map<String, Object>) attachments.get(key);
                    List<Object> mapFieldList = (List<Object>)doc.get('documentId');
                    for(Object docId: mapFieldList){
                        contentDocumentIds.add((Id)docId);
                        docInfoToSend.put(
                            (Id)docId,
                            new Map<String, String>{ 'documentId' => (Id)docId, 'eviFieldId' => key }
                        );
                    }

                List<ContentVersion> attachmentVersions = new ContentVersionSelector()
                    .getLatestContentVersionsByDocumentIds(contentDocumentIds);
                List<Map<String, String>> recordList = new List<Map<String, String>>();
                Map<String, String> docInfo;
                for (ContentVersion cv : attachmentVersions) {
                    docInfo = docInfoToSend.get(cv.ContentDocumentId);
                    recordList.add(
                        new Map<String, String>{
                            'ContentDocumentID' => docInfo.get('documentId'),
                            'ContentVersionID' => String.valueOf(cv.Id)
                        }
                    );
                }

                    fields.add(
                        new Map<String, Object>{
                            'fieldId' => docInfo.get('eviFieldId'),
                            'value' => new Map<String, Object>{ 'value' => recordList }
                        }
                    );
                }
            }
        }

        payload.remove('attachmentFile');

        Set<String> keyset = payload.keySet();
        for (String key : keyset) {
            Map<String, Object> mapOfFieldIdWithValue = new Map<String, Object>();
            if (fieldType.containsKey(key)) {
                Map<String, Object> valueMap = (Map<String, Object>) payload.get(key);
                Set<Integer> setOfValues = new Set<Integer>();
                Integer singleValue;
                if (valueMap.get('value') != null) {
                    if (
                        String.valueof(valueMap.get('value')).startswith('(') ||
                        String.valueof(valueMap.get('value')).endswith(')')
                    ) {
                        List<Object> muiltValueList = (List<Object>) valueMap.get('value');
                        for (object obj : muiltValueList) {
                            Integer val = Integer.valueOf(obj);
                            setOfValues.add(val);
                        }
                        mapOfFieldIdWithValue.put('value', setOfValues);
                    } else {
                        singleValue = Integer.valueof(valueMap.get('value'));
                        mapOfFieldIdWithValue.put('value', singleValue);
                    }
                }
                if (mapOfFieldIdWithValue.size() != 0) {
                    fields.add(new Map<String, Object>{ 'fieldId' => key, 'value' => mapOfFieldIdWithValue });
                }
            } else {
                fields.add(new Map<String, Object>{ 'fieldId' => key, 'value' => payload.get(key) });
            }
        }
        //construct form object
        Map<String, Object> form = new Map<String, Object>();
        form.put('name', workflowName);
        form.put('workflowId', workflowId);
        form.put('fields', fields);

        //construct webhook callback url object
        String domain = URL.getOrgDomainUrl().toExternalForm();
        String thisNamespace = IntakeFormService.class.getName().substringBefore('IntakeFormService').removeEnd('.');
        String url = (String.isBlank(thisNamespace))
            ? '/services/apexrest/TicketsUpdate/'
            : '/services/apexrest/' + thisNamespace + '/TicketsUpdate/';

        Map<String, Object> webhook = new Map<String, Object>{
            'url' => domain + url,
            'auth_scheme' => 'Bearer',
            'provider' => 'SALESFORCE'
        };

        //construct full request body
        Map<String, Object> reqBody = new Map<String, Object>{
            'form' => form,
            'ticket_update_callback' => webhook,
            'meta' => new Map<String, String>{ 'source' => 'salesforce' }
        };

        if (contentDocumentId != null && contentVersionId != null) {
            reqBody.put(
                'file',
                new Map<String, String>{
                    'ContentDocumentID' => contentDocumentId,
                    'ContentVersionID' => contentVersionId
                }
            );
        }

        //Custom header values for user details
        Map<String, String> userDetails = new Map<String, String>{
            'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
            'X-ACTIVE-USER-NAME' => UserInfo.getName()
        };
        String requestBody = JSON.serialize(reqBody);
        //Make POST to create ticket
        API a = new API();
        HttpResponse res = a.doApiCall('/contracts/tickets', 'POST', requestBody, userDetails);
        //If successful, create Evisort_Ticket__c and link to content document
        if (res.getStatusCode() == 201) {
            CreateTicketResponse response = (CreateTicketResponse) JSON.deserialize(
                res.getBody(),
                CreateTicketResponse.class
            );

            Evisort_Ticket__c newTicket = new Evisort_Ticket__c();

            if (!Test.isRunningTest()) {
                String assignees = TicketService.getTicketAssignees(response.data.id);
                newTicket.Assigned_To__c = assignees;
            }

            newTicket.Evisort_ID__c = response.data.id;
            newTicket.Evisort_Name__c = response.data.name;
            newTicket.Is_Completed__c = response.data.isCompleted;
            newTicket.Parent_Record_ID__c = String.valueOf(recordId);
            newTicket.Stage__c = response.data.stage;
            newTicket.Status__c = response.data.status;
            newTicket.Submitted_by__c = UserInfo.getName();
            List<Database.SaveResult> saveResults = Data.create(newTicket, true, true, true);

            if (String.isNotEmpty(contentDocumentId)) {
                ContentDocumentLink conDocLink = new ContentDocumentLink();
                conDocLink.ContentDocumentId = Id.valueOf(contentDocumentId);
                conDocLink.LinkedEntityId = saveResults[0].getId();
                Data.create(conDocLink, true, true, true);
            }

            String objectAPIName = recordId.getSObjectType().getDescribe().getName();

            List<Map<String, String>> salesforceMeta = new List<Map<String, String>>();
            salesforceMeta.add(
                new Map<String, String>{
                    'ticket_id' => String.valueOf(saveResults[0].getId()),
                    'parent_record_id' => String.valueOf(recordId),
                    'parent_record_type' => objectAPIName
                }
            );

            Map<String, Object> meta = new Map<String, Object>{
                'source' => 'salesforce',
                'salesforce' => salesforceMeta
            };

            form = new Map<String, Object>();
            form.put('name', response.data.name);
            form.put('workflowId', workflowId);
            form.put('fields', fields);
            
            //construct full request body
            Map<String, Object> reqBodyPatch = new Map<String, Object>{
                'form' => form,
                'ticket_update_callback' => webhook,
                'meta' => meta
            };

            String request = JSON.serialize(reqBodyPatch);

            if (saveResults[0].isSuccess() && !Test.isRunningTest()) {
                doPatchCall(request, response.data.id);
            }

            return new Map<String, Object>{
                'success' => (res.getStatusCode() == 201),
                'Evisort_Ticket__c' => saveResults[0].getId(),
                'responseBody' => res.getBody()
            };
        } else {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String message = (String) response.get('data');
            throw new IntakeFormException(
                System.Label.Admin_Status +
                ' ' +
                res.getStatusCode() +
                ': ' +
                res.getStatus() +
                ': ' +
                message
            );
        }
    }

    /**
     * @description Service that takes created ticket information  and makes a patch call
     * @param  request  Patch call json request
     */
    @future(callout=true)
    public static void doPatchCall(String request, String evisortTicketId) {
        //Custom header values for user details
        Map<String, String> userDetails = new Map<String, String>{
            'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
            'X-ACTIVE-USER-NAME' => UserInfo.getName()
        };

        //Make PATCH call after create ticket in sf
        API a = new API();
        HttpResponse res = a.doApiCall('/contracts/tickets/' + evisortTicketId, 'PATCH', request, userDetails);
    }

    @TestVisible
    private static Object getFieldValue(SObject obj, String path) {
        String field = path.substringBefore('.');

        try {
            // this is a relationship field
            if (path.contains('.')) {
                // This can throw an exception if `obj.getSObject(field)`
                // is null, and `field` doesn't exist verbatim on the SObject.
                // For example, if you're trying to retrieve Account.Name
                // from Opportunity, the standard field is AccountId.
                // If AccountId is set, the query will return an SObject with
                // an `Account` key, but if AccountId is not set, any checks
                // for `Account` will throw an exception.
                SObject nextObj = (SObject) obj.getSObject(field);

                // if found, drop the first field from the original path
                // (it's now our SObject) and run again one level deeper
                return (nextObj != null ? getFieldValue(nextObj, path.substringAfter('.')) : null);
            } else {
                // this is just a field on an object, no relationship parsing needed
                return obj.get(field);
            }
        } catch (Exception e) {
            // this field doesn't exist
            return null;
        }
    }

    public static void removeDocument(List<String> docIds) {
        //get document
        String query = 'SELECT Id' + ' FROM' + ' ContentDocument' + ' WHERE Id IN :docIds';

        Map<String, Object> queryArgs = new Map<String, Object>{ 'docIds' => docIds };

        List<SObject> records = Data.read(query, queryArgs, true, true, true);
        if(records.size() > 0){
            Data.remove(records);
        }
    }

    public static Map<String, Object> validate(String objectApiName, Map<String, String> fields) {
        Map<String, Boolean> results = new Map<String, Boolean>();
        Boolean allValid = true;

        for (String field : fields.keySet()) {
            if (fields.get(field) == 'childLookup') {
                Schema.DescribeSObjectResult descForSelObj = Schema.getGlobalDescribe()
                    .get(objectApiName)
                    .getDescribe();
                List<Schema.ChildRelationship> childObjects = descForSelObj.getChildRelationships();
                Schema.DescribeFieldResult fld;

                for (Schema.ChildRelationship childObj : childObjects) {
                    if (childObj.getRelationshipName() == field.substringBefore('.')) {
                        DescribeUtils dc = DescribeUtils.getCache(childObj.getChildSObject());
                        fld = dc.getFieldDescribeWithHierarchy(field.substringAfter('.'));
                    }
                }
                results.put(field, (fld != null));
                allValid = allValid && fld != null;
            } else {
                DescribeUtils dc = DescribeUtils.getCache(objectApiName);
                Schema.DescribeFieldResult fld = dc.getFieldDescribeWithHierarchy(field);
                results.put(field, (fld != null));
                allValid = allValid && fld != null;
            }
        }

        return new Map<String, Object>{ 'valid' => allValid, 'results' => results };
    }

    /**
     * @description Handle workflow changes on evisort, when workflow is modified new evisort version is generated. Because of this intake form mapping page was not loaded into the salesforce. 
     * So we fixed this with a Permanent link id. 
     */
    @AuraEnabled
    public static void updateIntakeFormWithPermanentLinkId(){       
        IntakeFormSelector formSelector = new IntakeFormSelector();
        List<Intake_Form__c> mappedIntakeFormList = (List<Intake_Form__c>) formSelector.getFormsWithMappings(null);
        if(mappedIntakeFormList.size() > 0){
            String responseBody = IntakeFormController.getIntakeForms();
            List<IntakeFormRequestBody> getAllWorkflowsList  = (List<IntakeFormRequestBody>) JSON.deserialize(responseBody, List<IntakeFormRequestBody>.class);
            List<Intake_Form__c> updatedWorkflowList = new List<Intake_Form__c>(); 
            for(Intake_Form__c mappedIntakeForm : mappedIntakeFormList){
                updatedWorkflowList.add(updateMappedIntakeForm(mappedIntakeForm, getAllWorkflowsList));
            }

            if(updatedWorkflowList.size() > 0){
                Data.upsurt(updatedWorkflowList, true, true, true);
            }
        }
    }

    private static Intake_Form__c updateMappedIntakeForm(Intake_Form__c mappedIntakeForm, List<IntakeFormRequestBody> getAllWorkflowsList){
        Boolean breakAfterMatch = false;
        for(IntakeFormRequestBody workflow :getAllWorkflowsList ){
            if(mappedIntakeForm.Workflow_Permanent_Link_Id__c != null){
                if(mappedIntakeForm.Workflow_Permanent_Link_Id__c == workflow.permanentLinkId){
                    mappedIntakeForm.Workflow_Id__c = workflow.id;
                    break;
                }
            }else{
                for(cls_versions workflowVersion : workflow.versions){
                    if(workflowVersion.id == mappedIntakeForm.Workflow_Id__c){
                        mappedIntakeForm.Workflow_Id__c = workflow.id;
                        mappedIntakeForm.Workflow_Permanent_Link_Id__c = workflow.permanentLinkId;                         
                        breakAfterMatch = true;        
                        break;                
                    }
                }
            }

            if(breakAfterMatch){
                break;
            }
        }

        return mappedIntakeForm;
    }

    @AuraEnabled
    public static List<ContentDocumentsAndAttachments> getContentDocumentAndAttachments(String recordId){
        List<ContentDocumentsAndAttachments> contentDocumentAndAttachmentsList = new List<ContentDocumentsAndAttachments>();
        List<Attachment> attahmentList = [SELECT Id, ParentId, Name, ContentType
                                         FROM Attachment WHERE ParentId =:recordId];
        for(Attachment  attach : attahmentList){
            ContentDocumentsAndAttachments filesData = new ContentDocumentsAndAttachments();
            filesData.Id = attach.Id;
            String name = attach.Name;  
            List<String> nameList = name.split('\\.');
            filesData.Title = String.valueOf(nameList[0]);
            filesData.FileExtension = String.valueOf(nameList[(nameList.size()-1)]);
            if(Constants.DOCUMENT_FILE_TYPE.containsKey(filesData.FileExtension))
            {
                filesData.FileType = Constants.DOCUMENT_FILE_TYPE.get(filesData.FileExtension);
            }
            contentDocumentAndAttachmentsList.add(filesData);
        }

        List<ContentDocumentLink> cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
		Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdls) {
            documentIds.add(cdl.ContentDocumentId);
        }
        List<ContentDocument> documentsList = [SELECT Id, Title, FileType, FileExtension FROM ContentDocument
                                           WHERE Id IN :documentIds ];
        for(ContentDocument documents :documentsList){
            ContentDocumentsAndAttachments filesData = new ContentDocumentsAndAttachments();  
            filesData.Id =documents.Id;
            filesData.Title = documents.Title;
            filesData.FileExtension =documents.FileExtension;
            filesData.FileType =documents.FileType;
            contentDocumentAndAttachmentsList.add(filesData);
        }
        return contentDocumentAndAttachmentsList; 
    }
    
    public class ContentDocumentsAndAttachments{
        @AuraEnabled 
        public String Title;
        @AuraEnabled 
        public String FileExtension;
        @AuraEnabled 
        public String FileType;
        @AuraEnabled 
        public String Id;
    }

    public class IntakeFormRequestBody{
        @AuraEnabled
        public String id;	
        @AuraEnabled
        public String name;		
        @AuraEnabled
        public String permanentLinkId;
        @AuraEnabled	
        public cls_versions[] versions;
    }
    class cls_versions {
        @AuraEnabled
		public String id;
        @AuraEnabled
		public boolean published;
	}

    public class IntakeFormResponse {
        @AuraEnabled
        public List<String> acceptedFileTypes { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String workflowId { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public IntakeFormResponseForm form { get; set; }
        @AuraEnabled
        public List<IntakeFormResponseSection> sections { get; set; }
    }

    public class IntakeFormResponseForm {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public List<IntakeFormResponseSection> sections { get; set; }
    }

    public class IntakeFormResponseSection {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public Integer position { get; set; }
        @AuraEnabled
        public List<IntakeFormResponseQuestion> questions { get; set; }
    }

    public class IntakeFormResponseQuestion {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public Integer position { get; set; }
        @AuraEnabled
        public Boolean isRequired { get; set; }
        @AuraEnabled
        public IntakeFormResponseField field { get; set; }
    }

    public class IntakeFormResponseField {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Object mappedValue { get; set; }
        public String mappedFieldName { get; set; }
        @AuraEnabled
        public IntakeFormResponseCustomSetting customSettings { get; set; }
    }

    public class IntakeFormResponseCustomSetting {
        @AuraEnabled
        public IntakeFormResponseDefaultValue defaultValue { get; set; }
        @AuraEnabled
        public Boolean enable_create_options { get; set; }
        @AuraEnabled
        public List<IntakeFormResponseOption> options { get; set; }
        @AuraEnabled
        public String format { get; set; }
    }

    public class IntakeFormResponseDefaultValue {
        @AuraEnabled
        public String country { get; set; }
        @AuraEnabled
        public String currency_x { get; set; }
    }

    public class IntakeFormResponseOption {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
    }

    public class CreateTicketResponse {
        public CreateTicketResponseBody data { get; set; }
    }

    public class CreateTicketResponseBody {
        public String createdDate { get; set; }
        // public Map<String, Object> creator { get; set; }
        public String id { get; set; }
        public String name { get; set; }
        public Boolean isCompleted { get; set; }
        public String stage { get; set; }
        public String status { get; set; }
    }

    public class IntakeFormException extends Exception {
    }
}