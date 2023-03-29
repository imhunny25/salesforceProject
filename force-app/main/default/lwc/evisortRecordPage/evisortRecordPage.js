import { LightningElement, api, track, wire } from "lwc";
import getValues from "@salesforce/apex/EvisortController.getValues";
import saveValues from "@salesforce/apex/EvisortController.saveValues";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage } from "c/csUtils";

export default class EvisortRecordPage extends LightningElement {
    @api recordId;
    @track data;
    @track isSaving = false; // for the spinner
    @track activeSections = []; // for auto-expanding all sections

    iconSvgUrl = Evisort_Resources + "/evisortResources/evisortIcon.svg#colorIcon";
    label = labels;

    // Map of Field Value Record ID to Field Record object
    dirtyFields = new Map();
    numOfDirtyFields = 0;

    // Map of Field Value Record ID to Value (loosely typed) for comparison to see if dirty
    originalValues = new Map();

    get saveDisabled() {
        return this.numOfDirtyFields === 0;
    }

    @wire(getValues, { evisortRecordId: "$recordId" })
    loadValues({ error, data }) {
        if (data) {
            this.data = JSON.parse(JSON.stringify(data));
            this.expandSections();
            this.splitProvisionValues();
            this.createOriginalValueMap();
        } else if (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
    }

    /**
     * Splits provision values into multiple parts if that's how they came from API.
     */
     splitProvisionValues() {
        this.data.sections.forEach(function(section) {
            section.values.forEach(function(value) {
                if (value.isProvision) {
                    let parts = value.textField.split('\n\n\n');

                    value.parts = [];

                    parts.forEach((part, index) => {
                        value.parts.push({
                            value: part,
                            index: index
                        });
                    });
                }
            });
        });
    }

    /**
     * Resets the Dirty Field map and maps out the current values for comparison later
     */
    createOriginalValueMap() {
        this.dirtyFields = new Map();
        this.numOfDirtyFields = 0;

        // "this" isn't visible inside the forEach functions so we work in a local variable and assign at the end
        let originalValues = new Map();
        this.data.sections.forEach(function (section) {
            section.values.forEach(function (value) {
                switch (value.dataType) {
                    case "Boolean":
                        originalValues.set(value.evisortFieldValueId, value.checkboxField);
                        break;
                    case "Date":
                        originalValues.set(value.evisortFieldValueId, value.dateField);
                        break;
                    case "Multi Picklist":
                        originalValues.set(value.evisortFieldValueId, value.multiPicklistValueSelected.join(","));
                        break;
                    case "Number":
                        originalValues.set(value.evisortFieldValueId, value.numberField);
                        break;
                    case "Picklist":
                        originalValues.set(value.evisortFieldValueId, value.picklistValueSelected);
                        break;
                    case "Text":
                        originalValues.set(value.evisortFieldValueId, value.textField);
                        break;
                    default:
                        break;
                }
            });
        });
        this.originalValues = originalValues;
    }

    /**
     * Grab all section names and set them to activeSections so that we can tell the lwc accordion to expand all sections by default
     */
    expandSections() {
        if (this.data) {
            this.activeSections = this.data.sections.map((section) => section.sectionName);
        }
    }

    /**
     * Checks to see if the value is different from what was originally in the database
     * @param {String} id    Field Value Record ID (the key)
     * @param {Object} value New Value (loosely typed)
     * @return               TRUE if the values do not match, FALSE if they match
     */
    checkIfNew(id, value) {
        return this.originalValues.get(id) !== value;
    }

    /**
     * Handles the change of a Boolean/Checkbox field (which is really a Yes/No picklist)
     * @param {Object} event Event object
     */
    handleCheckboxChange(event) {
        const updatedField = {
            evisortFieldValueId: event.target.dataset.id,
            checkboxField: event.target.value === "Yes"
        };
        this.modifyDirtyFields(updatedField, updatedField.checkboxField);
    }

    /**
     * Handles the change of a Date field
     * @param {Object} event Event object
     */
    handleDateChange(event) {
        const updatedField = {
            evisortFieldValueId: event.target.dataset.id,
            dateField: event.target.value
        };
        this.modifyDirtyFields(updatedField, updatedField.dateField);
    }

    /**
     * Handles the change of a Multi Picklist field
     * @param {Object} event Event object
     */
    handleMultiPicklistChange(event) {
        const updatedField = {
            evisortFieldValueId: event.target.dataset.id,
            picklistValueSelected: event.detail.join(",")
        };
        this.modifyDirtyFields(updatedField, updatedField.picklistValueSelected);
    }

    /**
     * Handles the change of a Number field
     * @param {Object} event Event object
     */
    handleNumberChange(event) {
        const updatedField = {
            evisortFieldValueId: event.target.dataset.id,
            numberField: Number(event.target.value)
        };
        this.modifyDirtyFields(updatedField, updatedField.numberField);
    }

    /**
     * Handles the change of a Picklist (lightning-combobox) field
     * @param {Object} event Event object
     */
    handlePicklistChange(event) {
        const updatedField = {
            evisortFieldValueId: event.target.dataset.id,
            picklistValueSelected: event.target.value
        };
        this.modifyDirtyFields(updatedField, updatedField.picklistValueSelected);
    }

    /**
     * Handles the change of a Text field
     * @param {Object} event Event object
     */
    handleTextChange(event) {
        const updatedField = {
            evisortFieldValueId: event.target.dataset.id,
            textField: event.target.value
        };
        this.modifyDirtyFields(updatedField, updatedField.textField);
    }

    /**
     * Modifies the Dirty Fields Map if the values changed from what's in the database
     * If they are the same, remove the field from the Map
     * @param {Object} updatedField Updated field object
     * @param {Object} value        Changed value object for comparison (loosely typed)
     */
    modifyDirtyFields(updatedField, value) {
        if (this.checkIfNew(updatedField.evisortFieldValueId, value)) {
            this.dirtyFields.set(updatedField.evisortFieldValueId, updatedField);
        } else {
            this.dirtyFields.delete(updatedField.evisortFieldValueId);
        }
        this.numOfDirtyFields = this.dirtyFields.size;
    }

    /**
     * Grabs all of the Dirty Fields and sends them to the BE
     * BE sends back the same results as the wire call after a save, which saves a trip
     * If there is an error, we throw a toast message
     */
    handleSave() {
        let values = [];
        this.dirtyFields.forEach(function (value) {
            values.push(value);
        });
        this.isSaving = true;

        saveValues({ evisortRecordId: this.data.evisortRecordId, values: JSON.stringify(values) })
            .then((result) => {
                this.data = result;
                this.createOriginalValueMap();
                showToast(this, this.label.adminSuccess, "", "SUCCESS");
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.isSaving = false;
            });
    }
}