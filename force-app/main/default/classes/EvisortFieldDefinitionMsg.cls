public with sharing class EvisortFieldDefinitionMsg {
    public class Response {
        public Integer count;
        public List<Field> fields;
        public List<Provision> provisions;
        public String error;
    }

    public class Field {
        public String name;
        public String label;
        public String type;
        public String helpText;
        public Boolean active;
        public List<String> allowedValues;
        public Section section;

        public Evisort_Field_Definition__c toRecord() {
            Evisort_Field_Definition__c efd = new Evisort_Field_Definition__c();
            efd.Name = this.name;
            efd.Label__c = this.label;
            efd.Data_Type__c = Constants.DATA_TYPES.get(this.type);
            if (this.allowedValues != null) {
                efd.Picklist_Values__c = String.join(this.allowedValues, ',');
            }
            if (this.section != null) {
                efd.Section_Name__c = this.section.name;
            }
            efd.Field_Type__c = 'Field';
            efd.isActive__c = true;
            return efd;
        }
    }

    public class Section {
        public String name;
    }

    public class Provision {
        public String name;
        public List<String> provisionTags;

        public Evisort_Field_Definition__c toRecord(Boolean syncNewProvisions) {
            Evisort_Field_Definition__c efd = new Evisort_Field_Definition__c();
            efd.Name = this.name;
            efd.Label__c = this.name;
            efd.Field_Type__c = 'Provision';
            efd.Data_Type__c = 'Text';
            efd.isActive__c = syncNewProvisions;
            return efd;
        }
    }
}