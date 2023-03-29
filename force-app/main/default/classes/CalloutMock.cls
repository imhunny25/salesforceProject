/**
 * Generic CalloutMock class that has an array of HttpResponses and are delivered in order when it receives HttpRequests
 */
@isTest
public with sharing class CalloutMock implements HttpCalloutMock {
    private List<HttpResponse> httpResponses = new List<HttpResponse>();
    private Integer responseIndex = 0;

    public CalloutMock(List<HttpResponse> responses) {
        httpResponses.addAll(responses);
    }

    public CalloutMock(HttpResponse response) {
        this.addResponse(response);
    }

    public CalloutMock(String body) {
        this.addResponse(200, body);
    }

    public CalloutMock(Integer code, String body) {
        this.addResponse(code, body);
    }

    public void addResponse(HttpResponse response) {
        httpResponses.add(response);
    }

    public void addResponse(String body) {
        this.addResponse(200, body);
    }

    public void addResponse(Integer code, String body) {
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setBody(body);
        httpResponse.setStatusCode(code);
        httpResponses.add(httpResponse);
    }

    public HttpResponse respond(HttpRequest request) {
        return httpResponses[responseIndex++];
    }
}