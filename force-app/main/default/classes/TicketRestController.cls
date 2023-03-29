/**
 * @description An exposed Rest service class that routes requests related to Evisort_Ticket__c records
 */
@RestResource(urlMapping='/TicketsUpdate/')
global with sharing class TicketRestController {
    @HttpPost
    global static void updateTicketRequest() {
        //Get request body
        RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
        List<RestRequestBody> payload = (List<RestRequestBody>) JSON.deserialize(reqBody, List<RestRequestBody>.class);

        //Check and enqueue request for processing
        TicketRestService.updateTicket(payload);

        //Send and forget - Always return success message and handle/log errors within the platform
        RestResponse res = RestContext.response;
        res.statusCode = 204;
    }

    global class RestRequestBody {
        global String ticketId;
        global String targetType;
        global String targetId;
        global String action;
        global Datetime timestamp;
    }
}