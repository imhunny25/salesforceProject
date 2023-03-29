import { LightningElement, track, api } from 'lwc';
import searchContacts from "@salesforce/apex/EvisortEmailShare.searchContacts";
import { isBlank, isValidateEmail } from "c/csUtils";
import labels from "c/labelService";


export default class EvisortEmailInput extends LightningElement {
    label = labels;
    @api ticketRecordId;
    @track items = [];
    @track isValidInput = true;
    @track inputFocus = false;
    searchTerm = '';
    blurTimeout;
    boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
    _selectedValues = [];
    retrievedContacts = [];
    streak = false;
    

    get inputPlaceholder() {
        if (this.selectedValues.length > 0) {
            return '';
        }
        return this.label.IntakeFormSearch;
    }

    get searchBoxClasses() {
        if (this.isValidInput) {
            if (this.inputFocus) {
                return 'slds-box slds-theme_default slds-var-m-top_x-small search-bar valid-input';
            }
            return 'slds-box slds-theme_default slds-var-m-top_x-small search-bar';
        }
        return 'slds-box slds-theme_default slds-var-m-top_x-small search-bar invalid-input';
    }

    get selectedValues() {
        return this._selectedValues;
    }

    set selectedValues(value) {
        this._selectedValues = value;
        const selectedValuesEvent = new CustomEvent("selection", { detail: { selectedValues: this._selectedValues} });
        this.dispatchEvent(selectedValuesEvent);
    }

    connectedCallback() {
        searchContacts({ evsTicketRecordId: this.ticketRecordId })
        .then((result) => {
            this.retrievedContacts = result;
        })
        .catch((error) => {
        });
    }

    handleSearch(event) {
        this.items = [];
        this.searchTerm = event.target.value;
        this.retrievedContacts.forEach(element => {
                let name = element.Name.toLowerCase();
                if (element.Email.includes(this.searchTerm.toLowerCase()) || name.includes(this.searchTerm.toLowerCase())) {
                if ((this.selectedValues == [] || !this.selectedValues.some(svalue => svalue.toLowerCase() == element.Email.toLowerCase())) && !this.items.some(item => item == element)) {
                    this.items.push(element);
                }
                if (this.items.length > 0) {
                    this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open";
                }
            }
        });
    }

    handleFocus() {
        this.inputFocus = true;
    }

    handleBlur() {
        this.inputFocus = false;
        this.blurTimeout = setTimeout(() => {
            this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
        }, 300);
    }

    get hasItems() {
        return this.items.length > 0;
    }

    handleKeyPress(event) {
        if (event.keyCode === 13) {
            event.preventDefault();
            
            if (!isBlank(event.currentTarget.value)) {
                if (!this.selectedValues.some(svalue => svalue.toLowerCase() == event.target.value.toLowerCase())) {
                    this.selectedValues = [...this.selectedValues, event.target.value];
                }
                event.currentTarget.value = "";
            }
            this.isValidInput = isValidateEmail(this.selectedValues);
        }
        else if (event.keyCode == 8 && (event.target.value == null || event.target.value == '')) {
            if (this.selectedValues.length > 0) {
                let _item = this.selectedValues;
                _item.splice(-1);
                this.selectedValues = [..._item];
            }
            this.isValidInput = isValidateEmail(this.selectedValues);
        }
        else {
            this.handleSearch();
        }
    }

    handleRemove(event) {
        let index = this.selectedValues.findIndex(obj => obj === event.target.label);
        let _item = this.selectedValues;
        _item.splice(index, 1);
        this.selectedValues = [..._item];
        this.isValidInput = isValidateEmail(this.selectedValues);
    }

    onSelect(event) {
        this.template.querySelector('input.input').value = "";
        let ele = event.currentTarget;
        let selectedId = ele.dataset.id;
        let selectedValue = this.items.find((record) => record.Id === selectedId);
        this.selectedValues = [...this.selectedValues, selectedValue.Email];
        this.isValidInput = isValidateEmail(this.selectedValues);

        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
    }

    focusOnSearchInput(event) {
        this.template.querySelector("input[data-id='searchInput']").focus();
    }
}