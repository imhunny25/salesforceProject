trigger Attachment on Attachment (after insert, after update, before delete) {
	Domain.triggerHandler(AttachmentDomain.class);
}