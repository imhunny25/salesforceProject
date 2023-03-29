trigger ContentVersion on ContentVersion (after insert, after update) {
	Domain.triggerHandler(ContentVersionDomain.class);
}