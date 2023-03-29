public with sharing class WorkspaceSettingsMsg {

    @AuraEnabled
    public String id;

    @AuraEnabled
    public String workspace;

    @AuraEnabled
    public String subdomain;

    @AuraEnabled
    public String domain;

    @AuraEnabled
    public String visibility;

    public WorkspaceSettingsMsg(){}

    public WorkspaceSettingsMsg(Evisort_Workspace_Settings__c settings) {
        this.id = settings.Id;
        this.workspace = settings.Workspace__c;
        this.subdomain = settings.Subdomain__c;
        this.domain = settings.Domain__c;
        this.visibility = settings.Visibility__c;
    }

    public Evisort_Workspace_Settings__c toSObject() {
        return new Evisort_Workspace_Settings__c(
                Id = this.id,
                Workspace__c = this.workspace,
                Subdomain__c = this.subdomain,
                Visibility__c = this.visibility
        );
    }
}