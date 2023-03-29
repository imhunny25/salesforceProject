trigger EvisortTrigger on Evisort__c (after update) { 
	if(EvisortDocumentRestController.isLegacyExport == false){
		Domain.triggerHandler(EvisortTriggerHandler.class);
	}
}