public with sharing class IntakeFormMsg {
    public class IntakeForm {
        @AuraEnabled
        public Id id;

        @AuraEnabled
        public String createdBy;

        @AuraEnabled
        public Datetime createdDate;

        @AuraEnabled
        public Datetime lastModifiedDate;

        @AuraEnabled
        public String name;

        @AuraEnabled
        public String salesforceObject;

        @AuraEnabled
        public String workflowId;

        @AuraEnabled
        public String workflowName;

        @AuraEnabled
        public Boolean mapped;

        @AuraEnabled
        public List<IntakeFormMapping> mappings;

        public IntakeForm(Intake_Form__c form) {
            this.id = form.Id;
            this.createdBy = form.CreatedBy.Name;
            this.createdDate = form.CreatedDate;
            this.lastModifiedDate = form.LastModifiedDate;
            this.name = form.Name;
            this.salesforceObject = form.Salesforce_Object__c;
            this.workflowId = form.Workflow_Id__c;
            this.workflowName = form.Workflow_Name__c;
            //set to true for mapped
            this.mapped = true;
            this.mappings = new List<IntakeFormMapping>();

            if (form.Intake_Form_Mappings__r != null) {
                for (Intake_Form_Mapping__c mapping : form.Intake_Form_Mappings__r) {
                    this.mappings.add(new IntakeFormMapping(mapping));
                }
            }
        }

        public Intake_Form__c toSObject() {
            return new Intake_Form__c(
                Id = this.id,
                Salesforce_Object__c = this.salesforceObject,
                Workflow_Id__c = this.workflowId,
                Workflow_Name__c = this.workflowName
            );
        }
    }

    public class IntakeFormMapping {
        public String objectType;
        public String objectName;

        @AuraEnabled
        public Id id;

        @AuraEnabled
        public String salesforceField;

        @AuraEnabled
        public String workflowFieldName;

        @AuraEnabled
        public String workflowFieldId;

        @AuraEnabled
        public string relationshipType;

        public IntakeFormMapping(Intake_Form_Mapping__c mapping) {
            this.id = mapping.Id;
            this.salesforceField = mapping.Salesforce_Field__c;
            this.workflowFieldName = mapping.Workflow_Field__c;
            this.workflowFieldId = mapping.Workflow_Field_Id__c;
            this.relationshipType = mapping.Salesforce_Object_Type__c;
        }

        public Intake_Form_Mapping__c toSObject() {
            if (this.relationshipType != null && String.isNotBlank(this.salesforceField)) {
                if (this.relationshipType == 'parentLookup') {
                    this.objectType = 'Parent';
                } else if (this.relationshipType == 'childLookup') {
                    this.objectType = 'Child';
                }
                this.objectName = this.salesforceField.SubStringBefore('.');
            }
            return new Intake_Form_Mapping__c(
                Id = this.id,
                Salesforce_Field__c = this.salesforceField,
                Workflow_Field__c = this.workflowFieldName,
                Workflow_Field_Id__c = this.workflowFieldId,
                Salesforce_Object_Type__c = this.objectType,
                Salesforce_Object__c = this.objectName
            );
        }
    }
}