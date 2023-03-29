trigger ContentDocument on ContentDocument(before delete) {
    // If we delete file from Salesforce then it will not get deleted From Evisort
    //Domain.triggerHandler(ContentDocumentDomain.class);
}