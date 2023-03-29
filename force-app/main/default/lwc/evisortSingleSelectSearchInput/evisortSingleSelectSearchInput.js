import { LightningElement, track, api } from 'lwc';
import getIntakeFormOptions from '@salesforce/apex/IntakeFormController.getIntakeFormOptions';
import { EVS_FIELDS } from 'c/csUtils';
import labels from "c/labelService";

export default class EvisortSingleSelectSearchInput extends LightningElement {
    @api workflowId;
    @api question;
    @api isEditMode;
    @api hasTicketId;

    @track isLoading = true;
    @track inputPlaceholder = labels.IntakeFormSearch;
    @track noMatchFound = labels.IntakeFormNoMatchFound;
    @track isRequired = false;
    @track retrievedFieldValueList = [];
    @track searchResultValues = [];
    @track selectedValue = {};
    @track isFieldActive = false;
    @track inputValue = '';
    @track hasSelectedValue = false;
    @track pillIcon = '';
    @track singleSelectedValue = '';
    @track selectedValueBeforeEdit = {};
    @track showDirtyBackground = false;
    get fieldLabel() {
        if (this.question.hasOwnProperty("field")) {
            return this.question.title;
        }
        return this.question.name;
    }

    get computeEditWrapperClasses() {
        const base = "slds-p-around_small slds-p-top_none";
        return this.showDirtyBackground ? `${base} input-wrapper_edit-state` : base;
    }

    get filteredFieldDescription() {
        if (this.question.hasOwnProperty("description")) {
            return this.question.description;
        }
    }

    get filteredFieldId() {
        if (this.question.hasOwnProperty("field")) {
            return this.question.field.id;
        }
        return this.question.fieldId;
    }

    connectedCallback() {
        if (this.question.field.type == EVS_FIELDS.USER)
            this.pillIcon = 'standard:user';
        else
            this.pillIcon = 'standard:account';
        this.isRequired = this.question.isRequired;
        this.loadData();
    }

    @api loadData() {
        this.isLoading = true;
        this.selectedValue = {};
        this.hasSelectedValue = false;
        this.isRequired = this.question.isRequired;
        this.retrievedFieldValueList = [];
        this.searchResultValues = [];
        this.isFieldActive = false;
        this.inputValue = '';
        this.singleSelectedValue = '';
        this.selectedValueBeforeEdit = {};

        getIntakeFormOptions({workflowId: this.workflowId, fieldId: this.question.field.id})
        .then(result => {
            result.forEach(element => {
                if (!this.retrievedFieldValueList.some(retrivedValue => retrivedValue.value == element.value))
                    this.retrievedFieldValueList.push({label : element.label, value : element.value});
                //  Prepopulate selected field on Edit Form if exists
                if (this.question.field.hasOwnProperty("mappedValue") && this.question.field.mappedValue == (element.value) && Object.keys(this.selectedValue).length == 0 && Object.keys(this.selectedValueBeforeEdit).length == 0) {
                    this.selectedValue = {label : element.label, value : element.value};
                    this.hasSelectedValue = true;
                    this.singleSelectedValue = element.label;
                    this.selectedValueBeforeEdit = {label : element.label, value : element.value};
                }
            });
            this.retrievedFieldValueList.sort((a, b) => a.label.localeCompare(b.label));
        })
        .catch(error => {})
        .finally(() => this.isLoading = false);
        this.validateSelectedValue();
    }

    @api reloadFieldValueOnCancel() {
        this.isLoading = true;
        this.selectedValue = {};
        this.hasSelectedValue = false;
        this.searchResultValues = [];
        this.singleSelectedValue = '';
        this.isFieldActive = false;
        this.inputValue = '';

        if (Object.keys(this.selectedValueBeforeEdit).length !== 0) {
            this.selectedValue = {...this.selectedValueBeforeEdit};
            this.hasSelectedValue = true;
            this.singleSelectedValue = this.selectedValueBeforeEdit.label;
        }
        this.isLoading = false;
    }

    @api copySelectedDataOnSuccess() {
        this.isLoading = true;
        this.selectedValueBeforeEdit = {};
        this.hasSelectedValue = false;
        this.searchResultValues = [];
        this.singleSelectedValue = '';
        this.isFieldActive = false;
        this.inputValue = '';

        if (Object.keys(this.selectedValue).length !== 0) {
            this.selectedValueBeforeEdit = {...this.selectedValue};
            this.hasSelectedValue = true;
            this.singleSelectedValue = this.selectedValue.label;
        }
        this.isLoading = false;
    }
    
    handleSingleSelectSearch(event) {
        this.isFieldActive = true;
        this.searchResultValues = [];
        this.inputValue = event.target.value;      
        this.retrievedFieldValueList.forEach(element => {
            if (element.label.toLowerCase().includes(this.inputValue.toLowerCase()) && !this.searchResultValues.some(searchResult => searchResult.value == element.value)) {
                this.searchResultValues.push({label : element.label, value : element.value});
            }
        });
        if (this.searchResultValues == null || this.searchResultValues == '' ) {
            this.searchResultValues.push({label : this.noMatchFound, value : 0});
        }
    }
    
    handleSelectedValue(event){
        let fieldValue = event.currentTarget.dataset.value;
        let fieldLabel = event.currentTarget.dataset.label;

        if(fieldValue != undefined && fieldValue != 0 && Object.keys(this.selectedValue).length == 0) {
            this.selectedValue = {label : fieldLabel, value : fieldValue};
            this.hasSelectedValue = true;
        }
        this.inputValue= '';
        this.isFieldActive = false;
        this.validateSelectedValue();
        this.dispatchEvent(new CustomEvent("selectchange", {
            detail: {
                hasChanged : true
            }
        }));   
    }

    handleFocus(event){
        event.target.placeholder = "";
        event.target.value = '';
    }

    handleBlur(event) {
        this.inputValue = null;
        event.target.placeholder = this.inputPlaceholder;
        event.target.value = '';
        setTimeout(() => {
            this.isFieldActive = false;
        }, 500);
    }

    focusOnSingleSelectSearch(event) {
        this.template.querySelector("input[data-id='singleSelectInput']").focus();
    }

    handleSingleSelectRemove(event) {
        this.selectedValue = {};
        this.hasSelectedValue = false;
        this.validateSelectedValue();
        if (!this.isRequired) {
            this.dispatchEvent(new CustomEvent("selectchange", {
                detail: {
                    hasChanged : true
                }
            }));
        }
    }

    @api
    getSelectedField() {
        if (this.selectedValue.value != undefined && this.selectedValue != {})
            return parseInt(this.selectedValue.value);
        if (this.hasTicketId)
            return "";
        else
            return null;
    }

    validateSelectedValue() {
        if (this.isRequired) {
            this.dispatchEvent(
                new CustomEvent("validatesingleselect", {
                    detail: {
                        hasValue : this.hasSelectedValue,
                        fieldId : this.question.field.id
                    }
                })
            );
        }
    }

    handleEditMode() {
        this.dispatchEvent(
            new CustomEvent("evs_editing", {
                bubbles: true,
                composed: true,
                detail: {
                    isEditing: true
                }
            })
        );
        this.selectedValue = {...this.selectedValueBeforeEdit};
        this.hasSelectedValue = Object.keys(this.selectedValue).length == 0? false : true;
    }
}