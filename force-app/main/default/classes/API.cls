public with sharing class API {
    // 120 seconds (in milliseconds) - max allowable timeout
    private static final Integer TIMEOUT = 120 * 1000;

    private String token;

    public API() {
    }

    public API(String inToken) {
        this.token = inToken;
    }

    /**
     * Gets the current access token, which will test if the API key and Named Credential are valid
     * @return   TRUE if we get to that part, but an Exception will be thrown if an error occurs
     */
    public Boolean testNamedCredential() {
        this.getToken();
        return true;
    }

    /**
     * Do a JSON based API call and return the response
     * @param  endpoint URL of the call after the Named Credential and Version
     * @param  method   GET, POST, or PATCH
     * @param  body     Body for POST or PATCH, if needed
     * @param  headers  Custom header values for callout
     * @return          HttpResponse, good or bad
     */
    public HttpResponse doAPICall(String endpoint, String method, String body, Map<String, String> headers) {
        if (String.isBlank(this.token)) {
            this.getToken();
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(Constants.CALLOUT + endpoint);
        req.setMethod(method);
        req.setTimeout(TIMEOUT);
        req.setHeader('Authorization', 'Bearer ' + this.token);

        if (headers != null) {
            Set<String> keyset = headers.keySet();
            for (String key : keyset) {
                req.setHeader(key, headers.get(key));
            }
        }

        if (method == 'POST' || method == 'PATCH') {
            if(headers != null && headers.containsKey('Content-Type') && headers.get('Content-Type') == 'application/x-www-form-urlencoded'){
                req.setBody(body);
            }else{
                req.setHeader('Content-Type', 'application/json');
                req.setBody(body);
            }
        }

        HttpResponse res = new HttpResponse();
        try {
            res = new Http().send(req);
        } catch (System.CalloutException e) {
            //if callout fails retry once
            res = retryApiCall(req);
        }

        // If we get a 401, then the token is no longer valid. Requery for the token.
        if (res.getStatusCode() == 401) {
            res = this.retryWithNewToken(req);
        }

        return res;
    }

    public HttpResponse doAPICall(String endpoint, String method, String body) {
        return doApiCall(endpoint, method, body, null);
    }

    public HttpResponse retryApiCall(HttpRequest req) {
        if (String.isBlank(this.token)) {
            this.getToken();
        }

        try {
            return new Http().send(req);
        } catch (System.CalloutException e) {
            throw new APIException(e.getMessage());
        }
    }

    /**
     * Do a Multipart Form-Data API call and return the response
     * @param  endpoint     URL of the call after the Named Credential and Version
     * @param  mapKeyValues Map of text-based key and value pairs
     * @param  filename     Name of the file with extension
     * @param  conVer       ContentVersion record with FileType and VersionData
     * @return              HttpResponse, Good or Bad
     */
    public HttpResponse doAPICall(
        String endpoint,
        Map<String, String> mapKeyValues,
        String filename,
        ContentVersion conVer
    ) {
        if (String.isBlank(this.token)) {
            this.getToken();
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(Constants.CALLOUT + endpoint);
        req.setMethod('POST');
        req.setTimeout(TIMEOUT);
        req.setHeader('Authorization', 'Bearer ' + this.token);

        String boundary = '----------------------------' + String.valueOf(DateTime.now().getTime());
        Blob body = this.createFormDataValues(mapKeyValues, boundary);
        body = this.addFormDataFile(body, filename, conVer, boundary);
        String footer = '\r\n--' + boundary + '--\r\n';
        String mergeBlobsAsHex = EncodingUtil.convertToHex(body) + EncodingUtil.convertToHex(Blob.valueOf(footer));
        body = EncodingUtil.convertFromHex(mergeBlobsAsHex);

        req.setHeader('Content-Type', 'multipart/form-data; boundary="' + boundary + '"');
        req.setHeader('Content-Length', String.valueOf(body.size()));
        req.setBodyAsBlob(body);

        HttpResponse res = new Http().send(req);

        // If we get a 401, then the token is no longer valid. Requery for the token.
        if (res.getStatusCode() == 401) {
            res = this.retryWithNewToken(req);
        }

        return res;
    }

    /**
     * Do an API call to get document info using external id
     * @param  docId External id of the document to get info for.
     * @return HttpResponse, Good or Bad
     */
    public HttpResponse getDocumentInfo(String docId) {
        if (String.isBlank(this.token)) {
            this.getToken();
        }

        String endpoint = Constants.CALLOUT + Constants.DOCUMENT_URL + '/docid/' + docId;

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod('GET');
        httpRequest.setTimeout(TIMEOUT);
        httpRequest.setHeader('Authorization', 'Bearer ' + this.token);

        HttpResponse httpResponse = new Http().send(httpRequest);

        // If we get a 401, then the token is no longer valid. Requery for the token.
        if (httpResponse.getStatusCode() == 401) {
            httpResponse = this.retryWithNewToken(httpRequest);
        }

        return httpResponse;
    }

    /**
     * Converts the Key/Value pairs into a Blob for Form Data calls
     * @param  mapKeyValues Map of Key and Value pairs
     * @param  boundary     Generated Boundary String
     * @return              Blob with the contents
     */
    private Blob createFormDataValues(Map<String, String> mapKeyValues, String boundary) {
        String formData = '';

        for (String key : mapKeyValues.keySet()) {
            formData += '--' + boundary + '\r\n';
            formData += 'Content-Disposition: form-data; name="' + key + '"\r\n\r\n';
            formData += mapKeyValues.get(key) + '\r\n';
        }

        String mergeBlobsAsHex =
            EncodingUtil.convertToHex(Blob.valueOf('')) + EncodingUtil.convertToHex(Blob.valueOf(formData));
        return EncodingUtil.convertFromHex(mergeBlobsAsHex);
    }

    /**
     * Adds the Binary file to the Blob for a Form Data call
     * @param  body     Already existing Body blob (with the Key/Value pairs)
     * @param  filename Filename with extension
     * @param  conVer   ContentVersion record with FileType and VersionData
     * @param  boundary Generated Boundary String
     * @return          Blob with all of the contents
     */
    private Blob addFormDataFile(Blob body, String filename, ContentVersion conVer, String boundary) {
        String formData = '--' + boundary + '\r\n';
        formData += 'Content-Disposition: form-data; name="file"; filename="' + filename + '"\r\n';
        formData += 'Content-Type: ' + Constants.FORM_DATA_MIME_TYPES.get(conVer.FileType) + '\r\n\r\n';

        String mergeBlobsAsHex =
            EncodingUtil.convertToHex(body) +
            EncodingUtil.convertToHex(Blob.valueOf(formData)) +
            EncodingUtil.convertToHex(conVer.VersionData);
        return EncodingUtil.convertFromHex(mergeBlobsAsHex);
    }

    /**
     * Requery for a new token and reattempt the callout with the new token
     * @param  req HttpRequest object (already filled out)
     * @return     HttpResponse, good or bad
     */
    private HttpResponse retryWithNewToken(HttpRequest req) {
        this.getToken();
        req.setHeader('Authorization', 'Bearer ' + this.token);
        HttpResponse res = new Http().send(req);

        // If we STILL get a 401, then stop here and throw an exception. The API key might be bad.
        if (res.getStatusCode() == 401) {
            this.unsetAuthenticatedStatus();
            throw new APIException(System.Label.API_CantGenerateToken);
        }

        return res;
    }

    /**
     * Gets the Access Token - this only lasts for 15 minutes so its okay to query often for it
     */
    private void getToken() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Constants.CALLOUT + Constants.TOKEN_URL);
        req.setMethod('POST');
        req.setTimeout(TIMEOUT);
        req.setHeader(Constants.EVISORT_USERNAME, '{!$Credential.Password}');
        req.setHeader('Content-Type', 'application/json');
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            if (res.getStatusCode() == 403) {
                this.unsetAuthenticatedStatus();
                throw new APIException(System.Label.API_AccessForbidden);
            } else {
                this.unsetAuthenticatedStatus();
                throw new APIException('Status ' + res.getStatusCode() + ': ' + res.getStatus());
            }
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        this.token = (String) body.get('token');
    }

    /**
     * Unsets our Authentication status in a Custom Setting
     */
    private void unsetAuthenticatedStatus() {
        Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
        status.Authenticated__c = false;
        status.Authentication_Date__c = null;
        upsert status; // Custom Setting, no CRUD/FLS needed
    }

    public class APIException extends Exception {
    }
}