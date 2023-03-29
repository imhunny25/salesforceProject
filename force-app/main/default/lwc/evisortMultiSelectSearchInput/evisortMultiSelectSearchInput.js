import { LightningElement, track, api } from 'lwc';
import getIntakeFormOptions from '@salesforce/apex/IntakeFormController.getIntakeFormOptions';
import { EVS_FIELDS } from "c/csUtils";
import labels from "c/labelService";

export default class EvisortMultiSelectSearchInput extends LightningElement {
    @api workflowId;
    @api question;
    @api isEditMode;
    @api hasTicketId;

    @track isLoading = true;
    @track inputPlaceholder = labels.IntakeFormSearch;
    @track noMatchFound = labels.IntakeFormNoMatchFound;
    @track isRequired = false;
    @track retrievedFieldValueList = [];
    @track unselectedValues = [];
    @track searchResultValues = [];
    @track selectedValuesBeforeEdit = [];
    @track selectedValues = [];
    @track isFieldActive = false;
    @track inputValue = '';
    @track pillIcon = '';
    @track multiSelectedValues = '';
    @track showDirtyBackground = false;
    get fieldLabel(){
        if (this.question.hasOwnProperty("field")) {
            return this.question.title;
        }
        return this.question.name;
    }

    get filteredFieldDescription() {
        if (this.question.hasOwnProperty("description")) {
            return this.question.description;
        }
    }
    
    get computeEditWrapperClasses() {
        const base = "slds-p-around_small slds-p-top_none";
        return this.showDirtyBackground ? `${base} input-wrapper_edit-state` : base;
    }

    get filteredFieldId() {
        if (this.question.hasOwnProperty("field")) {
            return this.question.field.id;
        }
        return this.question.fieldId;
    }

    connectedCallback() {
        if (this.question.field.type == EVS_FIELDS.USER) {
            this.pillIcon = 'standard:user';
        }
        else {
            this.pillIcon = 'standard:account';
        }
        this.isRequired = this.question.isRequired;
        this.loadData();
    }

    @api loadData() {
        this.selectedValues = [];
        this.unselectedValues = [];
        this.selectedValuesBeforeEdit = [];
        this.retrievedFieldValueList = [];
        this.searchResultValues = [];
        this.multiSelectedValues = '';
        this.isFieldActive = false;
        this.inputValue = '';
        
        getIntakeFormOptions({workflowId: this.workflowId, fieldId: this.question.field.id})
        .then(result => {
            result.forEach(element => {
                if (!this.retrievedFieldValueList.some(retrievedValue => retrievedValue.value == element.value))
                    this.retrievedFieldValueList.push({label : element.label, value : element.value});
                //  Prepopulate selected fields on Edit Form
                if (this.question.field.hasOwnProperty("mappedValue")) {
                    if (this.question.field.mappedValue.hasOwnProperty("valueList")) {
                        if (this.question.field.mappedValue.valueList.includes(element.value) && !this.selectedValues.some(selectedValue => selectedValue.value == element.value)) {
                            this.selectedValues.push({label : element.label, value : element.value});
                            this.selectedValuesBeforeEdit.push({label : element.label, value : element.value}); 
                            if (this.multiSelectedValues == '')
                                this.multiSelectedValues += (element.label);
                            else
                                this.multiSelectedValues += ', ' + (element.label);
                        }
                        else {
                            if (!this.unselectedValues.some(unselectedValue => unselectedValue.value == element.value) && !this.selectedValues.some(selectedValue => selectedValue.value == element.value))
                                this.unselectedValues.push({label : element.label, value : element.value});
                        }
                    }
                }
                //  New Intake Form
                if (this.selectedValues.length == 0) {
                    this.unselectedValues = [...this.retrievedFieldValueList];
                }                
                this.retrievedFieldValueList.sort(((a, b) => a.label.localeCompare(b.label)));
                this.selectedValuesBeforeEdit.sort(((a, b) => a.label.localeCompare(b.label)));
                this.selectedValues.sort(((a, b) => a.label.localeCompare(b.label)));
                this.unselectedValues.sort(((a, b) => a.label.localeCompare(b.label)));
            });
        })
        .catch(error => {})
        .finally(() => this.isLoading = false);
        this.validateSelectedValue();
    }

    @api reloadFieldValuesOnCancel() {
        this.isLoading = true;
        this.selectedValues = [];
        this.unselectedValues = [];
        this.searchResultValues = [];
        this.multiSelectedValues = '';
        this.isFieldActive = false;
        this.inputValue = '';

        this.selectedValues = [...this.selectedValuesBeforeEdit];
        this.retrievedFieldValueList.forEach(element => {
            if (!this.unselectedValues.some(unselectedValue => unselectedValue.value == element.value) && !this.selectedValues.some(selectedValue => selectedValue.value == element.value))
                this.unselectedValues.push({label : element.label, value : element.value});
        });
        this.selectedValuesBeforeEdit.forEach(element => {
            if (this.multiSelectedValues == '')
                this.multiSelectedValues += (element.label);
            else
                this.multiSelectedValues += ', ' + (element.label);
        });
        this.isLoading = false;
    }

    @api copySelectedDataOnSuccess() {
        this.isLoading = true;
        this.selectedValueBeforeEdit = [];
        this.unselectedValues = [];
        this.searchResultValues = [];
        this.multiSelectedValues = '';
        this.isFieldActive = false;
        this.inputValue = '';

        this.selectedValuesBeforeEdit = [...this.selectedValues];
        this.selectedValues.forEach(element => {
            if (this.multiSelectedValues == '')
                this.multiSelectedValues += (element.label);
            else
                this.multiSelectedValues += ', ' + (element.label);
        });

        this.isLoading = false;
    }

    handleMultiSelectSearch(event) {
        this.isFieldActive = true;
        this.searchResultValues = [];
        this.inputValue = event.target.value;
        if (this.inputValue == null || this.inputValue == '') {
            if (event.key == "Backspace") {
                if (this.selectedValues.length > 0) {
                    let index = this.selectedValues.length-1;
                    let _item = this.selectedValues;
                    let fieldValue = _item[index].value;
                    let fieldLabel = _item[index].label;
                    _item.splice(index, 1);
                    this.selectedValues = [..._item];
                    if (!this.unselectedValues.some(unselectedValue => unselectedValue.value == fieldValue))
                        this.unselectedValues.push({label : fieldLabel, value : fieldValue});
                    this.isFieldActive = false;
                    this.template.querySelector("input[data-id='multiSelectInput']").focus();
                }
            }
            this.unselectedValues.sort(((a, b) => a.label.localeCompare(b.label)));
            this.searchResultValues = [...this.unselectedValues];
        }
        else {
            this.unselectedValues.sort(((a, b) => a.label.localeCompare(b.label)));
            this.unselectedValues.forEach(element => {
                if (element.label.toLowerCase().includes(this.inputValue.toLowerCase()) && !this.searchResultValues.some(searchResult => searchResult.value == element.value)) {
                    this.searchResultValues.push({label : element.label, value : element.value});
                }
            });
        }
        if (this.searchResultValues.length == 0 || this.searchResultValues == [] ) {
            this.searchResultValues.push({label : this.noMatchFound, value : 0});
        }
    }

    handleSelectedValues(event){
        this.inputValue ='';
        let fieldValue = event.currentTarget.dataset.value;
        let fieldLabel = event.currentTarget.dataset.label;

        if (this.question.field.type == EVS_FIELDS.USER)
            this.pillIcon = 'standard:user';
        else
            this.pillIcon = 'standard:account';
        if (fieldValue != undefined && fieldValue != 0) {
            if (!this.selectedValues.some(selectedValue => selectedValue.value == fieldValue))
                this.selectedValues.push({label : fieldLabel, value : fieldValue});
            for (let i = 0; i < this.unselectedValues.length; i++) {
                if (this.unselectedValues[i].value == fieldValue) {
                    let _item = [...this.unselectedValues];
                    _item.splice(i, 1);
                    this.unselectedValues = [..._item];
                }
            }
            this.unselectedValues.sort(((a, b) => a.label.localeCompare(b.label)));
            this.searchResultValues = [...this.unselectedValues];
        }
        this.inputValue= '';
        this.isFieldActive = false;
        this.template.querySelector("input[data-id='multiSelectInput']").focus();
        this.validateSelectedValue();
        this.dispatchEvent(new CustomEvent("selectchange", {
            detail: {
                hasChanged : true
            }
        }));
    }

    compareLabel(firstValue, secondValue) {
        if (firstValue.label > secondValue.label) return 1;
        if (secondValue.label > firstValue.label) return -1;
        return 0;
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
    
    focusOnMultiSelectSearch(event) {
        this.template.querySelector("input[data-id='multiSelectInput']").focus();
    }

    handleMultiSelectRemove(event) {
        const index = event.detail.name;
        let fieldValue = this.selectedValues[index].value;
        let fieldLabel = this.selectedValues[index].label;
        const _item = this.selectedValues;
        _item.splice(index, 1);
        this.selectedValues = [..._item];

        if (!this.unselectedValues.some(unselectedValue => unselectedValue.value == fieldValue)) {
            this.unselectedValues.push({label : fieldLabel, value : fieldValue});
        }
        this.searchResultValues = [...this.unselectedValues];
        this.template.querySelector("input[data-id='multiSelectInput']").focus();
        this.validateSelectedValue();
        this.dispatchEvent(new CustomEvent("selectchange", {
            detail: {
                hasChanged : true
            }
        }));
    }

    @api
    getSelectedFields() {
        let valueList = [];
        this.selectedValues.forEach(ele=> {
            if (!valueList.includes(parseInt(ele.value)))
            valueList.push(parseInt(ele.value));
        });
        if(valueList.length != 0 && valueList != []) {
            return valueList;
        }
        else if (this.hasTicketId)
            return [];
        else
            return null;

    }

    validateSelectedValue() {
        if (this.isRequired) {
            this.dispatchEvent(
                new CustomEvent("validatemultiselect", {
                    detail: {
                        hasValue : this.selectedValues.length>0 ? true : false,
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
    }
}