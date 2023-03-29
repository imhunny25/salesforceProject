/**
 * @description Service class for retrieving and processing Evisort Tickets
 */
public with sharing class TicketService {
    /**
     * @description Service to retrieve Evisort ticket data from API
     * @param  recordId     The id of Evisort_Ticket__c record
     * @return              Untyped API response
     */
    public static Map<String, Object> getTicketInformation(Id ticketId) {
        Boolean canUpdate = false;
        Boolean canRead = false;
        if (Schema.sObjectType.Evisort_Ticket__c.isUpdateable()) {
            canUpdate = true;
        }

        if (Schema.sObjectType.Evisort_Ticket__c.isAccessible()) {
            canRead = true;
        }
        //Select Ticket
        Evisort_Ticket__c ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);

        //Make callout and deserialize into wrapper
        API a = new API();
        HttpResponse resp = a.doAPICall(Constants.GET_TICKET_URL + ticket.Evisort_ID__c, 'GET', null);

        if (resp.getStatusCode() > 299) {
            throw new TicketServiceException(resp.getStatus());
        }

        String respBody = resp.getBody();

        //replace reserved keywords
        respBody = respBody.replace('"currency":', '"currency_x":');
        respBody = respBody.replace('"default":', '"default_x":');
        //replace value when it is a List for deserialization purposes
        respBody = respBody.replace('"value":[', '"valueList":[');
        respBody = respBody.replace('"value":{"value":[', '"value":{"valueList":[');
        respBody = respBody.replace('"value":{"value":[{', '"value":{"valueObjList":[{');

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(respBody);
        wrapper.put('isUpdateable', canUpdate);
        wrapper.put('isReadable', canRead);

        return wrapper;
    }

    /**
     * @description Service to update form fields. Constructs and sends a PATCH request to API
     * @param  recordId     The id of Evisort_Ticket__c record
     * @param  workflowId   The external Id of the Evisort workflow associated with the ticket
     * @param  formData     All the fields updated in the edit ticket modal
     * @return              A response body including typed data from the PATCH request
     */
    public static Map<String, Object> updateTicket(Id ticketId, String workflowId, String formData) {
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(formData);
        String contentDocumentId;
        String contentVersionId;

        //Select Ticket
        Evisort_Ticket__c ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);

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
                    if(doc.get('documentId') == null){
                        String [] attachmentNull = new List<String>();
                        fields.add(
                        new Map<String, Object>{
                            'fieldId' => key,
                            'value' => new Map<String, Object>{ 'value' => attachmentNull }
                            }
                        ); 
                    }else {
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
                        for(ContentVersion cv : attachmentVersions) {
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
        }

        payload.remove('attachmentFile');

        //Front end should only be sending dirty fields to update
        Set<String> keyset = payload.keySet();
        for (String key : keyset) {
            fields.add(new Map<String, Object>{ 'fieldId' => key, 'value' => payload.get(key) });
        }

        //construct form object
        Map<String, Object> form = new Map<String, Object>();
        form.put('name', ticket.Evisort_Name__c);
        form.put('workflowId', workflowId);
        form.put('fields', fields);

        //construct webhook callback url object
        String domain = URL.getOrgDomainUrl().toExternalForm();
        String thisNamespace = TicketService.class.getName().substringBefore('TicketService').removeEnd('.');
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

        //Make callout and deserialize into wrapper
        API a = new API();
        HttpResponse resp = a.doAPICall(
            Constants.GET_TICKET_URL + ticket.Evisort_ID__c,
            'PATCH',
            JSON.serialize(reqBody),
            userDetails
        );

        if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(
                System.Label.Admin_Status +
                ' ' +
                resp.getStatusCode() +
                ': ' +
                resp.getStatus() +
                ': ' +
                message
            );
        }

        if (resp.getStatusCode() == 201 || resp.getStatusCode() == 200) {
            return new Map<String, Object>{ 'success' => true };
        } else {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(
                System.Label.Admin_Status +
                ' ' +
                resp.getStatusCode() +
                ': ' +
                resp.getStatus() +
                ': ' +
                message
            );
        }
    }

    /**
     * @description Service to move ticket to next stage via API POST request
     * @param  ticketId     The id of Evisort_Ticket__c record
     * @return              A response body including typed data from the POST request
     */
    public static TicketMsg submitNextStage(Id ticketId) {
        //Select Ticket
        Evisort_Ticket__c ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);
        List<Object> params = new List<Object>{ ticket.Evisort_ID__c };

        String url = String.format(Constants.NEXT_STAGE_URL, params);

        //Custom header values for user details
        Map<String, String> userDetails = new Map<String, String>{
            'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
            'X-ACTIVE-USER-NAME' => UserInfo.getName()
        };

        //Make callout and deserialize into wrapper
        API a = new API();
        HttpResponse resp = a.doAPICall(url, 'POST', JSON.serialize(new Map<String, Object>()), userDetails);

        //throw error messages for specific http error codes
        if (resp.getStatusCode() == 404) {
            throw new TicketServiceException(System.Label.API_InvalidTicketId);
        } else if (resp.getStatusCode() == 403) {
            throw new TicketServiceException(System.Label.API_PermissionError);
        } else if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(
                System.Label.Admin_Status +
                ' ' +
                resp.getStatusCode() +
                ': ' +
                resp.getStatus() +
                ': ' +
                message
            );
        }

        String respBody = resp.getBody();

        TicketMsg wrapper = (TicketMsg) JSON.deserialize(resp.getBody(), TicketMsg.class);

        if (!Test.isRunningTest()) {
            String assignees = getTicketAssignees((String) ticketId);
            ticket.Assigned_To__c = assignees;
        }

        ticket.Status__c = wrapper.status.capitalize();
        ticket.Stage__c = wrapper.stage.capitalize();
        Data.modify(ticket);

        return wrapper;
    }

    public static TicketMsg markTicketComplete(Id ticketId) {
        //Select Ticket
        Evisort_Ticket__c ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);
        List<Object> params = new List<Object>{ ticket.Evisort_ID__c };

        String url = String.format(Constants.COMPLETE_URL, params);

        //Custom header values for user details
        Map<String, String> userDetails = new Map<String, String>{
            'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
            'X-ACTIVE-USER-NAME' => UserInfo.getName()
        };

        //Make callout and deserialize into wrapper
        API a = new API();
        HttpResponse resp = a.doAPICall(url, 'POST', JSON.serialize(new Map<String, Object>()), userDetails);

        //throw error messages for specific http error codes
        if (resp.getStatusCode() == 404) {
            throw new TicketServiceException(System.Label.API_InvalidTicketId);
        } else if (resp.getStatusCode() == 403) {
            throw new TicketServiceException(System.Label.API_PermissionError);
        } else if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(
                System.Label.Admin_Status +
                ' ' +
                resp.getStatusCode() +
                ': ' +
                resp.getStatus() +
                ': ' +
                message
            );
        }

        String respBody = resp.getBody();

        TicketMsg wrapper = (TicketMsg) JSON.deserialize(resp.getBody(), TicketMsg.class);

        if (!Test.isRunningTest()) {
            String assignees = getTicketAssignees((String) ticketId);
            ticket.Assigned_To__c = assignees;
        }

        ticket.Status__c = wrapper.status.capitalize();
        ticket.Stage__c = wrapper.stage.capitalize();
        Data.modify(ticket);

        return wrapper;
    }

    /**
     * @description Service to retrieve Activity Log data from Evisort API for associated ticket
     * @param  ticketId     The id of Evisort_Ticket__c record
     * @return              A response body including typed data from the GET request
     */
    public static TicketMsg.ActivityLogWrapper getActivityLog(Id ticketId) {
        //Select Ticket
        Evisort_Ticket__c ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);
        List<Object> params = new List<Object>{ ticket.Evisort_ID__c };

        String url = String.format(Constants.ACTIVITY_LOG_URL, params);

        //Custom header values for user details
        Map<String, String> userDetails = new Map<String, String>{
            'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
            'X-ACTIVE-USER-NAME' => UserInfo.getName()
        };

        //Make callout and deserialize into wrapper
        API a = new API();
        HttpResponse resp = a.doAPICall(url, 'GET', null, userDetails);

        if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(
                System.Label.Admin_Status +
                ' ' +
                resp.getStatusCode() +
                ': ' +
                resp.getStatus() +
                ': ' +
                message
            );
        }

        String respBody = resp.getBody();

        TicketMsg.ActivityLogWrapper wrapper = (TicketMsg.ActivityLogWrapper) JSON.deserialize(
            resp.getBody(),
            TicketMsg.ActivityLogWrapper.class
        );
        return wrapper;
    }

    /**
     * @description Service to retrieve Participant data from Evisort API for associated ticket
     * @param  ticketId     The Evisort_Ticket__c record Id or the Evisor Platform Ticket Id
     * @return              A response body including typed participant data from the GET request
     */
    public static TicketMsg.TicketParticipantWrapper getParticipants(String ticketId) {
        Evisort_Ticket__c ticket;
        List<Object> params;

        //Select Ticket
        if (ticketId instanceof Id) {
            ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);
            params = new List<Object>{ ticket.Evisort_ID__c };
        } else {
            params = new List<Object>{ ticketId };
        }

        String url = String.format(Constants.PARTICIPANTS_URL, params);

        //Custom header values for user details
        Map<String, String> userDetails = new Map<String, String>{
            'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
            'X-ACTIVE-USER-NAME' => UserInfo.getName()
        };

        //Make callout and deserialize into wrapper
        API a = new API();
        HttpResponse resp = a.doAPICall(url, 'GET', null, userDetails);

        if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(
                System.Label.Admin_Status +
                ' ' +
                resp.getStatusCode() +
                ': ' +
                resp.getStatus() +
                ': ' +
                message
            );
        }

        String respBody = resp.getBody();

        TicketMsg.TicketParticipantWrapper wrapper = (TicketMsg.TicketParticipantWrapper) JSON.deserialize(
            resp.getBody(),
            TicketMsg.TicketParticipantWrapper.class
        );

        wrapper.sortParticipants();

        return wrapper;
    }

    /**
     * @description a helper method to separate the Users with the role Assignee in order to
     * add the Users to the Assigned To field on a Evisort_Ticket__c record.
     * @param   ticketId    The Evisort_Ticket__c record Id or the Evisort Platform Ticket Id
     * @return              String of comma separated Ticket Assignees
     */
    public static String getTicketAssignees(String ticketId) {
        TicketMsg.TicketParticipantWrapper participants = getParticipants(ticketId);
        List<String> assignees = new List<String>();

        for (TicketMsg.TicketParticipant item : participants.data) {
            if (item.role == 'assignee') {
                assignees.add(item.participant.name);
            }
        }

        String assignedTo = String.join(assignees, ', ');

        return assignedTo;
    }

    /**
     * @description a service class meant to act as a helper for queueItemWorker. Takes the recordId
     * from the queue item, gets the ticket record, makes a GET for updated data from Evisort, and updates
     * the record.
     * CRUD/FLS is ignored since queue runs in system context.
     * @param   item    QueueItem__c record being processed
     */
    public static void ticketUpdateQueueHelper(QueueItem__c item) {
        try {
            Evisort_Ticket__c ticket = new TicketSelector(false, false, false).getTicketByExternalId(item.RecordId__c);
            //If there is a matching record, make a GET call to Evisort for new information and update the record.
            //Update QueueItem__c record appropriately.
            if (ticket != null) {
                Map<String, Object> ticketWrapper = getTicketInformation(ticket.Id);
                Map<String, Object> tData = (Map<String, Object>) ticketWrapper.get('data');
                Map<String, Object> currentStage = (Map<String, Object>) tData.get('currentStage');
                Map<String, Object> responseFile = (Map<String, Object>) tData.get('file');
                if (!Test.isRunningTest()) {
                    String assignees = getTicketAssignees(ticket.Id);
                    ticket.Assigned_To__c = assignees;
                }

                ticket.Stage__c = (String) currentStage.get('name');
                ticket.Status__c = (String) tData.get('status');
                ticket.Is_Completed__c = (Boolean) tData.get('isCompleted');

                Data.modify(ticket, false, false, false);

                item.Status__c = 'COMPLETED';
                Data.modify(item, false, false, false);

                if(!ticket.Is_Completed__c){
                    createContentDocumentLink( responseFile, ticket.id);
                }  
            } else {
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = System.label.API_TicketQueueNoRecord + ': ' + item.RecordId__c;
                Data.modify(item, false, false, false);

                Logger errorlogger = Logger.getInstance();
                errorlogger.log(
                    'TicketService.ticketUpdateQueueHelper',
                    System.label.API_TicketQueueNoRecord +
                    ': ' +
                    item.RecordId__c
                );
            }
        } catch (Exception e) {
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = e.getMessage();
            Data.modify(item, false, false, false);

            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketService.ticketUpdateQueueHelper', e);
        }
    }


    public static void createContentDocumentLink(Map<String, Object>  responseFile, Id ticketId){ 
        Map<String, Object> responseContent = (Map<String, Object>) responseFile.get('content');
        Id contentDocId = (Id) responseContent.get('ContentDocumentID');
    
        if(contentDocId != null && ticketId != null){
            Map<String, Object> queryArgs = new Map<String, Object>{ 
                'contentDocId' => contentDocId,
                'ticketId' => ticketId
            };

            ContentDocumentLinkSelector cdlSelector = new ContentDocumentLinkSelector();
            List<String> queryFields = new List<String>(cdlSelector.getDefaultFields());
            String query = 'SELECT '+ String.join(queryFields, ',') +' FROM ContentDocumentLink'; 
            query += ' WHERE ContentDocumentId =: contentDocId';
            query += ' AND LinkedEntityId =: ticketId LIMIT 1';
          
            List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) Data.read(
               query,
               queryArgs,
               false,
               false,
               false
            );

            /**
            * We made this false beacuse standard user does not have permission to create a contentdocumentlink.
            * Error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested.
            */
            if(contentDocumentLinks.isEmpty()){  
                ContentDocumentLink cd = new ContentDocumentLink();
                cd.ContentDocumentId = contentDocId;
                cd.LinkedEntityId = ticketId;
                Data.create(cd, false,false,false);
            }
        }
    }

    /**
     * @description a service class meant to act as a helper for queueItemWorker. Takes the recordId
     * from the queue item, gets the ticket record, and marks the ticket as deleted
     * CRUD/FLS is ignored since queue runs in system context.
     * @param   item    QueueItem__c record being processed
     */
    public static void ticketDeleteQueueHelper(QueueItem__c item) {
        try {
            Evisort_Ticket__c ticket = new TicketSelector(false, false, false).getTicketByExternalId(item.RecordId__c);
            if (ticket != null) {
                ticket.Stage__c = 'Deleted';
                ticket.Status__c = 'Deleted';
                ticket.Assigned_To__c = null;

                Data.modify(ticket, false, false, false);

                item.Status__c = 'COMPLETED';
                Data.modify(item, false, false, false);
            } else {
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = System.label.API_TicketQueueNoRecord + ': ' + item.RecordId__c;
                Data.modify(item, false, false, false);

                Logger errorlogger = Logger.getInstance();
                errorlogger.log(
                    'TicketService.ticketUpdateQueueHelper',
                    System.label.API_TicketQueueNoRecord +
                    ': ' +
                    item.RecordId__c
                );
            }
        } catch (Exception e) {
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = e.getMessage();
            Data.modify(item, false, false, false);

            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketService.ticketUpdateQueueHelper', e);
        }
    }

    /**
     * @description a service class meant to act as a helper for queueItemWorker. Takes the recordId
     * from the queue item, gets the ticket record
     * CRUD/FLS is ignored since queue runs in system context.
     * @param   item    QueueItem__c record being processed
     */
    public static void evisortRecordUpdate(QueueItem__c item) {
        try {
            Evisort_Ticket__c ticket = new TicketSelector(false, false, false).getTicketByExternalId(item.RecordId__c);

            if (ticket != null) {
                //Custom header values for user details
                Map<String, String> userDetails = new Map<String, String>{
                    'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
                    'X-ACTIVE-USER-NAME' => UserInfo.getName()
                };

                //Make callout
                API a = new API();
                HttpResponse res = a.doAPICall(
                    Constants.GET_TICKET_URL + ticket.Evisort_ID__c,
                    'GET',
                    null,
                    userDetails
                );
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> responseData = (Map<String, Object>) response.get('data');
                Map<String, Object> responseFile = (Map<String, Object>) responseData.get('file');
                Map<String, Object> responseContent = (Map<String, Object>) responseFile.get('content');
                if (responseData.get('pilotDocHandlerId') != null) {
                    List<Evisort__c> evisortRecords = new EvisortSelector()
                        .getRecordsByExternalIdAndParentId(
                            String.valueOf(responseData.get('pilotDocHandlerId')),
                            ticket.Parent_Record_ID__c
                        );

                    if (evisortRecords.isEmpty()) {
                        ContentVersion cv = new ContentVersionSelector()
                            .getContentVersionById(String.valueOf(responseContent.get('ContentVersionID')));
                        List<ContentVersion> cvToUpdate = new List<ContentVersion>();

                        List<Evisort__c> evisortRecordsToInsert = new List<Evisort__c>();
                        Evisort__c evisortRecord = new Evisort__c();
                        evisortRecord.Record_ID__c = String.valueOf(ticket.Parent_Record_ID__c);
                        evisortRecord.External_ID__c = String.valueOf(responseData.get('pilotDocHandlerId'));
                        evisortRecord.Document_Status__c = 'Unknown';
                        evisortRecord.Original_File_Name__c = cv.Title;
                        evisortRecord.Evisort_Ticket__c = ticket.Id;
                        evisortRecordsToInsert.add(evisortRecord);
                        Data.create(evisortRecordsToInsert);

                        cvToUpdate.add(
                            new ContentVersion(Id = cv.Id, Evisort__c = evisortRecord.Id, Evisort_Ticket__c = ticket.Id)
                        );
                        Data.modify(cvToUpdate);
                    }

                    List<ContentDocumentLink> cdl = new ContentDocumentLinkSelector()
                        .getLinksByDocumentIdAndLinkedEntityId(
                            String.valueOf(responseContent.get('ContentDocumentID')),
                            ticket.Parent_Record_ID__c
                        );
                    if (cdl.isEmpty()) {
                        ContentDocumentLink cd = new ContentDocumentLink();
                        cd.ContentDocumentId = (Id) responseContent.get('ContentDocumentID');
                        cd.LinkedEntityId = ticket.Parent_Record_ID__c;
                        Data.create(cd);
                    }

                    item.Status__c = 'COMPLETED';
                    Data.modify(item, false, false, false);
                } else if (responseData.get('pilotDocHandlerId') == null) {
                    item.Status__c = 'COMPLETED';
                    Data.modify(item, false, false, false);

                    QueueItem__c newItem = (QueueItem__c) QueueItem__c.sObjectType.newSObject(null, true);
                    newItem.RecordId__c = ticket.Evisort_ID__c;
                    newItem.Object__c = 'Evisort_Ticket__c';
                    newItem.Action_Context__c = 'evisortRecordUpdate';
                    newItem.Process_After__c = Datetime.now().addMinutes(15);
                    Data.create(newItem, false, false, false);
                }
            } else {
                item.Status__c = 'ERROR';
                item.ErrorMessage__c = System.label.API_TicketQueueNoRecord + ': ' + item.RecordId__c;
                Data.modify(item, false, false, false);

                Logger errorlogger = Logger.getInstance();
                errorlogger.log(
                    'TicketService.evisortRecordUpdate',
                    System.label.API_TicketQueueNoRecord +
                    ': ' +
                    item.RecordId__c
                );
            }
        } catch (Exception e) {
            item.Status__c = 'ERROR';
            item.ErrorMessage__c = e.getMessage();
            Data.modify(item, false, false, false);

            Logger errorlogger = Logger.getInstance();
            errorlogger.log('TicketService.evisortRecordUpdate', e);
        }
    }

    /**
     * @description Used to create a contentDocumentlink on page load
     * @param  ticketId     The id of Evisort_Ticket__c record
     * @param  fileDetail     All the detail of file
     */
    public static void ticketContentDocumentLink(Id ticketId, String fileDetail) {
        Evisort_Ticket__c ticket = (Evisort_Ticket__c) new TicketSelector().getRecordById(ticketId);
        Map<String,Object> responseFile = (Map<String,Object>) JSON.deserializeUntyped(fileDetail);
        if(!ticket.Is_Completed__c){
            createContentDocumentLink( responseFile, ticket.id);
        }
    }
    public static String ticketReviewStatus(String ticketStatusDetails) {
        String ticketId;
        String issueId;
        String status;
        String comment;

        Map<String, Object> mapOfticketStatusDetails = (Map<String, Object>)JSON.deserializeUntyped(ticketStatusDetails);
        if(mapOfticketStatusDetails.containsKey('ticketId') && mapOfticketStatusDetails.containsKey('issueId') && mapOfticketStatusDetails.containsKey('status') && mapOfticketStatusDetails.containsKey('comments')){
            ticketId = (String) mapOfticketStatusDetails.get('ticketId');
            issueId = (String) mapOfticketStatusDetails.get('issueId');
            status = (String) mapOfticketStatusDetails.get('status');
            Map<String, Object> ticketCommentMap = (Map<String, Object>) mapOfticketStatusDetails.get('comments');
            comment = JSON.serialize(ticketCommentMap);
        } 
        if(String.isNotBlank(ticketId) && String.isNotBlank(issueId) && String.isNotBlank(status) && String.isNotBlank(comment)){       
            String endPointOfApprovedReject = '/contracts/tickets/'+ticketId+'/judgments/'+issueId+'/'+status;
            String ticketActionComment = comment;

            //Custom header values for user details
            Map<String,String> userDetails = new Map<String, String>{
                'X-ACTIVE-USER-EMAIL' => UserInfo.getUserEmail(),
                'X-ACTIVE-USER-NAME' => UserInfo.getName()
            };
            API a = new API();
            HttpResponse resp = a.doApiCall(endPointOfApprovedReject, 'POST',ticketActionComment,userDetails);
            if (resp.getStatusCode() == 404) {
                throw new TicketServiceException(System.Label.API_InvalidTicketId);
            } else if (resp.getStatusCode() > 299) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                String message = (String) response.get('data');
                throw new TicketServiceException(System.Label.Admin_Status + ' ' + resp.getStatusCode() +': ' + resp.getStatus() + ': ' + message);
            }
            return resp.getBody();
       }
       return '';   
    }

    public static Map<String,String> getUserDetails(){
        Map<String,String> userInformation = new Map<String,String>();
        String emailAddress = UserInfo.getUserEmail();
        userInformation.put('userEmail',emailAddress);
        String userName = UserInfo.getName();
        userInformation.put('userName',userName);
        return userInformation;
    }

    public static String uploadTicketSignDocument(String ticketSignDocumentDetails, String replaceDocumentId){
        String signIds = '';
        Map<String,String> headerMap = new Map<String,String>();
        TicketMsg.TicketSignDocumentWrapper ticketSignDocDetails = (TicketMsg.TicketSignDocumentWrapper) JSON.deserialize(
            ticketSignDocumentDetails,
                TicketMsg.TicketSignDocumentWrapper.class
            );
            TicketMsg.TicketDocReplaceWrapper ticketSignDocReplace = (TicketMsg.TicketDocReplaceWrapper) JSON.deserialize(
                replaceDocumentId,
                TicketMsg.TicketDocReplaceWrapper.class
            );

        for(String ids : ticketSignDocDetails.signerIds){
            signIds += (ids.remove('\''))+',';
        }
        signIds = signIds.removeEnd(',');

        headerMap.put('Content-Type','application/x-www-form-urlencoded');
        
        String endpoint = '/contracts/tickets/'+ticketSignDocDetails.currentTicketId+'/upload-signed/';
        String method = 'POST';
        String body = 'text=upload Sign&signerIds="'+signIds+'"&meta={ "source": "salesforce", "data": { "ContentVersionID": "'+ticketSignDocDetails.contentVersion+'", "ContentDocumentID": "'+ticketSignDocDetails.contentDocument+'" } }';
        API a = new API();
        HttpResponse resp = a.doAPICall(endpoint, method, body,headerMap);
        if(resp.getStatusCode() == 200){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = ticketSignDocDetails.contentDocument;
            cdl.LinkedEntityId = ticketSignDocReplace.ticketEvisortRecordId;
            insert cdl;
        }
        else if (resp.getStatusCode() == 404) {
            throw new TicketServiceException(System.Label.API_InvalidTicketId);
        } else if (resp.getStatusCode() == 403) {
            throw new TicketServiceException(System.Label.API_PermissionError);
        } else if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(System.Label.Admin_Status + ' ' + resp.getStatusCode() +': ' + resp.getStatus() + ': ' + message);
        }else if (resp.getStatusCode() == 400) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(System.Label.Admin_Status + ' ' + resp.getStatusCode() +': ' + resp.getStatus() + ': ' + message);
        }
        return resp.getBody();        
    }

    public static String uploadNewVersionDocument(String documentDetails){
        String ticketId;
        String documentId;
        String contentVersionId;
        String contentDocumentId;
        String oldContentDocumentId;
        String evisortRecordId;
        Boolean isCounterparty;
        String newDocumentNote ='';
        Map<String, Object> mapOfDocumentDetails = (Map<String, Object>)JSON.deserializeUntyped(documentDetails);
        ticketId = (String) mapOfDocumentDetails.get('ticketId');
        documentId = (String) mapOfDocumentDetails.get('documentId');
        contentVersionId = (String) mapOfDocumentDetails.get('contentVersionId');
        contentDocumentId = (String) mapOfDocumentDetails.get('contentDocumentId');
        oldContentDocumentId = (String) mapOfDocumentDetails.get('oldContentDocumentId');
        evisortRecordId = (String) mapOfDocumentDetails.get('evisortRecordId');
        String note = (String) mapOfDocumentDetails.get('note');
        isCounterparty = (Boolean) mapOfDocumentDetails.get('isCounterparty');
        if(String.isNotBlank(note)){
            newDocumentNote = note;
        }
        if(String.isNotBlank(ticketId) && String.isNotBlank(documentId)){
            Map<String,String> headerMap = new Map<String,String>();
            headerMap.put('Content-Type','application/x-www-form-urlencoded');
            String endpoint = '/contracts/tickets/'+ticketId+'/documents/'+documentId+'/versions';
            String method = 'POST';
            String body = '';
            if(String.isNotBlank(note)){
                body += 'text='+newDocumentNote+'&';
            }
            body += 'isCounterparty='+isCounterparty+'&';
            body += 'meta={ "source": "salesforce", "data": { "ContentVersionID": "'+contentVersionId+'", "ContentDocumentID": "'+contentDocumentId+'" } }';
            API a = new API();
            HttpResponse resp = a.doAPICall(endpoint, method, body, headerMap);        
            if(resp.getStatusCode() == 201){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = evisortRecordId;
                Data.create(cdl, false, false, false);
                return resp.getBody();
            }
            else{
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                String message = (String) response.get('data');
                throw new TicketServiceException(System.Label.Admin_Status + ' ' + resp.getStatusCode() +': ' + resp.getStatus() + ': ' + message);
            }       
        }
        return '';
    }

    public static String getEvisort(String ticketId){
        List<Evisort__c> evisort = [SELECT Id, Name, Evisort_Ticket__c, Record_ID__c, External_ID__c, Record_Link__c, Evisort_Link__c FROM Evisort__c WHERE Evisort_Ticket__c =: ticketId];
        if(evisort.size() > 0){
            return evisort[0].Id;
        }
        return '';
    }

    public static String getEvisortUsers(){
        API a = new API();
        HttpResponse resp = a.doAPICall('/users','GET',null);
        if (resp.getStatusCode() == 404) {
            throw new TicketServiceException(System.Label.API_InvalidTicketId);
        } else if (resp.getStatusCode() == 403) {
            throw new TicketServiceException(System.Label.API_PermissionError);
        } else if (resp.getStatusCode() > 299) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            String message = (String) response.get('data');
            throw new TicketServiceException(System.Label.Admin_Status + ' ' + resp.getStatusCode() +': ' + resp.getStatus() + ': ' + message);
        }
        return resp.getBody();
    }
    
    public class TicketServiceException extends Exception {
    }
}