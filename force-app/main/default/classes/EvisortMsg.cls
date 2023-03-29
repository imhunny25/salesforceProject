public with sharing class EvisortMsg {
    public class EvisortRecord {
        @AuraEnabled
        public String evisortRecordId;
        @AuraEnabled
        public String evisortRecordName;
        @AuraEnabled
        public String evisortRecordUrl;
        @AuraEnabled
        public String originalFileName;
        @AuraEnabled
        public String documentStatus;
        @AuraEnabled
        public List<Section> sections;

        /**
         * Creates an Evisort Msg from an Evisort Record
         * @param  evisort Evisort Record
         */
        public EvisortRecord(Evisort__c evisort) {
            this.evisortRecordId = evisort.Id;
            this.evisortRecordName = evisort.Name;
            this.evisortRecordUrl = '/' + evisort.Id;
            this.originalFileName = evisort.Original_File_Name__c;
            this.documentStatus = evisort.Document_Status__c;
            this.sections = new List<Section>();
            Map<String, Section> sectionMap = new Map<String, Section>();

            for (Evisort_Field_Value__c efv : evisort.Evisort_Field_Values__r) {
                String sectionName;

                // If this is a Field, get the section name
                // If this is a Provision, use a hardcoded section name (this may change, hence why this PR is like this)
                if (efv.Evisort_Field_Definition__r.Field_Type__c == 'Field') {
                    sectionName = efv.Evisort_Field_Definition__r.Section_Name__c;
                } else if (efv.Evisort_Field_Definition__r.Field_Type__c == 'Provision') {
                    sectionName = 'Provisions'; // Need guidance on this before making label
                }

                // If the section name is blank, give it a generic section
                if (String.isBlank(sectionName)) {
                    sectionName = 'Other'; // Need guidance on what to call fields with no section
                }

                Section section;

                if (sectionMap.keySet().contains(sectionName)) {
                    section = sectionMap.get(sectionName);
                } else {
                    section = new Section(sectionName);
                    sectionMap.put(sectionName, section);
                    this.sections.add(section);
                }

                section.values.add(new Value(efv));
            }

            // Sort the sections alphabetically
            this.sections.sort();
        }
    }

    public class Section implements Comparable {
        @AuraEnabled
        public String sectionName;
        @AuraEnabled
        public List<Value> values;

        /**
         * Constructor
         * @param  name Name of this Section
         */
        public Section(String name) {
            this.sectionName = name;
            this.values = new List<Value>();
        }

        /**
         * Comparable interface - Alphabetize, except put Provisions always at the end
         * @param  o Incoming Section object
         * @return   1, -1, or 0 based on comparison
         */
        public Integer compareTo(Object o) {
            Section sec = (Section) o;
            if (this.sectionName == 'Provisions') {
                return 1;
            } else if (sec.sectionName == 'Provisions') {
                return -1;
            }

            if (this.sectionName == sec.sectionName) {
                return 0;
            } else if (this.sectionName > sec.sectionName) {
                return 1;
            } else if (this.sectionName < sec.sectionName) {
                return -1;
            }
            return 0;
        }
    }

    public class Value {
        @AuraEnabled
        public String evisortFieldValueId;
        @AuraEnabled
        public String evisortFieldDefinitionId;
        @AuraEnabled
        public String evisortFieldDefinitionName;
        @AuraEnabled
        public String dataType;
        @AuraEnabled
        public String fieldType;
        @AuraEnabled
        public Boolean checkboxField;
        @AuraEnabled
        public Date dateField;
        @AuraEnabled
        public Decimal numberField;
        @AuraEnabled
        public String textField;

        @AuraEnabled
        public Boolean isCheckbox = false;
        @AuraEnabled
        public Boolean isDate = false;
        @AuraEnabled
        public Boolean isNumber = false;
        @AuraEnabled
        public Boolean isPicklist = false;
        @AuraEnabled
        public Boolean isMultiPicklist = false;
        @AuraEnabled
        public Boolean isText = false;
        @AuraEnabled
        public Boolean isProvision = false;

        @AuraEnabled
        public List<Option> picklistValues;
        @AuraEnabled
        public List<String> multiPicklistValueSelected;
        @AuraEnabled
        public String picklistValueSelected;
        @AuraEnabled
        public Boolean readOnly;

        public Value() {
        }

        /**
         * Convert the Evisort Field Value to a Msg
         * @param  efv Evisort Field Value record
         */
        public Value(Evisort_Field_Value__c efv) {
            this.evisortFieldValueId = efv.Id;
            this.evisortFieldDefinitionId = efv.Evisort_Field_Definition__c;
            this.evisortFieldDefinitionName = efv.Evisort_Field_Definition__r.Label__c;
            this.dataType = efv.Evisort_Field_Definition__r.Data_Type__c;
            this.fieldType = efv.Evisort_Field_Definition__r.Field_Type__c;
            this.checkboxField = efv.Checkbox_Field__c;
            this.dateField = efv.Date_Field__c;
            this.numberField = efv.Number_Field__c;
            this.textField = efv.Text_Field__c;
            this.readOnly = efv.Evisort_Field_Definition__r.isReadOnly__c;
            // LWC's template:if-true can't do comparisons so we send booleans here based on the Data Type
            if (this.fieldType == 'Provision') {
                this.isProvision = true;
            } else {
                switch on (this.dataType) {
                    when 'Boolean' {
                        this.isCheckbox = true;
                    }
                    when 'Date' {
                        this.isDate = true;
                    }
                    when 'Number' {
                        this.isNumber = true;
                    }
                    when 'Picklist' {
                        this.isPicklist = true;
                    }
                    when 'Multi Picklist' {
                        this.isMultiPicklist = true;
                    }
                    when 'Text' {
                        this.isText = true;
                    }
                }
            }

            // If this is a picklist or multi picklist, deal with the values
            // Booleans are technically a yes/no picklist in Evisort and not a checkbox like Salesforce
            if ((this.dataType == 'Picklist') || (this.dataType == 'Multi Picklist')) {
                this.handlePicklistValues(
                    efv.Picklist_Value_Selected__c,
                    efv.Evisort_Field_Definition__r.Picklist_Values__c
                );
            } else if (this.dataType == 'Boolean') {
                String value = (this.checkboxField) ? 'Yes' : 'No'; // Should label this, but this mirrors Evisort's UI
                this.handlePicklistValues(value, 'Yes,No');
            }
        }

        /**
         * Sets the selected values, as well as defining the options, for picklists
         * Because some picklists don't have options, we must add the selected values to the available options
         * so the UI can render them
         * @param  selected Comma separated list of selected values
         * @param  options  Comma separated list of options
         */
        private void handlePicklistValues(String selected, String options) {
            this.multiPicklistValueSelected = (String.isEmpty(selected)) ? new List<String>() : selected.split('\\$@#');
            // If there is only one value selected, place it in a different variable for the UI to access easier
            if (this.multiPicklistValueSelected.size() == 1) {
                this.picklistValueSelected = this.multiPicklistValueSelected[0];
            }
            this.picklistValues = new List<Option>();
            Set<String> optionSet = new Set<String>();
            // Add the options ("allowed values") to the msg
            if (!String.isEmpty(options)) {
                List<String> optionList = options.split('\\$@#');
                for (String option : optionList) {
                    this.picklistValues.add(new Option(option));
                    optionSet.add(option);
                }
            }

            // Check the values ("selected values") and if one does not exist as an option, add it as an option
            for (String option : this.multiPicklistValueSelected) {
                if (!optionSet.contains(option)) {
                    this.picklistValues.add(new Option(option));
                }
            }
        }

        /**
         * Converts a Field Msg to an Evisort Field Value record for updating
         * @return   Evisort Field Value record
         */
        public Evisort_Field_Value__c toRecord() {
            Evisort_Field_Value__c efv = new Evisort_Field_Value__c();
            efv.Id = this.evisortFieldValueId;
            if (this.checkboxField != null) {
                efv.Checkbox_Field__c = this.checkboxField;
            }
            efv.Date_Field__c = this.dateField;
            efv.Number_Field__c = this.numberField;
            efv.Picklist_Value_Selected__c = this.picklistValueSelected;
            efv.Text_Field__c = this.textField;
            return efv;
        }
    }

    public class Option {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        /**
         * Constructor to make the options usable by the standard lightning-combobox component
         * @param  name Name of the option to be used as both the label and value
         */
        public Option(String name) {
            this.label = name;
            this.value = name;
        }
    }
}