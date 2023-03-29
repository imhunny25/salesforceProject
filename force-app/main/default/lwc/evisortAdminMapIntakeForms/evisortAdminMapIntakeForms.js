import { LightningElement, api, track } from "lwc";
import labels from "c/labelService";
import getObjects from "@salesforce/apex/IntakeFormController.getObjects";
import getFields from "@salesforce/apex/IntakeFormController.getFields";
import getIntakeForms from "@salesforce/apex/IntakeFormController.getIntakeForms";
import getIntakeForm from "@salesforce/apex/IntakeFormController.getIntakeForm";
import getRecords from "@salesforce/apex/IntakeFormController.getRecords";
import saveRecords from "@salesforce/apex/IntakeFormController.saveRecords";
import deleteRecord from "@salesforce/apex/IntakeFormController.deleteRecord";
import validate from "@salesforce/apex/IntakeFormController.validate";
import updateIntakeFormWithPermanentLinkId from "@salesforce/apex/IntakeFormController.updateIntakeFormWithPermanentLinkId";
import { showToast, sortByLabel, RELATIONSHIP_TYPES, getFilteredErrorMessage , isBlank} from "c/csUtils";

/**
 * The shape of an intake form
 * mapping, parallel to `IntakeFormMsg.IntakeForm`.
 * Use this to create a new set of mappings;
 * existing mappings will be retrieved by Apex in this shape.
 */
const INTAKE_FORM = {
    id: null,
    createdById: null,
    createdDate: null,
    name: null,
    salesforceObject: null,
    workflowId: null,
    workflowName: null,
    mappings: []
};

/**
 * Action menu configuration for the intake
 * form data table
 */
const ACTIONS = [
    { label: "Edit", name: "edit" },
    { label: "Delete", name: "delete" }
];

/**
 * Data table column headers
 */
const COLUMNS = [
    { label: "Workflow Name", fieldName: "workflowName", type: "text", sortable: true, hideDefaultActions: true },
    {
        label: "Salesforce Object",
        fieldName: "salesforceObject",
        type: "text",
        sortable: true,
        hideDefaultActions: true
    },
    { label: "Created Date", fieldName: "createdDate", type: "date", sortable: true, hideDefaultActions: true },
    {
        label: "Last Modified Date",
        fieldName: "lastModifiedDate",
        type: "date",
        sortable: true,
        hideDefaultActions: true
    },
    { label: "Created By", fieldName: "createdBy", type: "String", sortable: true, hideDefaultActions: true },
    { type: "action", typeAttributes: { rowActions: ACTIONS } }
];

export default class EvisortAdminMapIntakeForms extends LightningElement {
    label = labels;
    columns = COLUMNS;
    evsDocLink = "https://support.evisort.com/hc/en-us/articles/360060522013-Integration-Overview-Salesforce";

    /**
     * Tab config
     */
    @api activestate;
    @api iconsvgurl;
    /**
     * All mappings currently saved to Salesforce.
     * This is effectively an array of `INTAKE_FORM`s
     * and is used to populate the data table.
     */
    @track records = [];

    /**
     * All forms retreived from the Evisort API.
     * This is used for the Intake Form dropdown.
     */
    @track forms;

    /**
     * All SObjects in the Salesforce org.
     * This is used in the Object dropdown.
     */
    @track sObjects;

    /**
     * All fields on the currently chosen SObject.
     */
    @track fields = [];

    /**
     * The current form, retrieved from Evisort
     * via `getIntakeForm`. This will be merged with
     * any existing Salesforce data based on form id
     * into `activeItem` below.
     */
    @track activeForm;

    /**
     * A representation of the Evisort form structure
     * and any existing mappings stored in Salesforce.
     * This is populated by `mergeData` and the shape of
     * the object is represented by `INTAKE_FORM`.
     */
    @track activeItem = null;

    /**
     * UI state management
     */
    @track isLoaded = false;
    @track isModalOpen = false;
    @track showMappings = true;

    @track isDataTableLoaded = false;
    /**
     * Delete modal
     */
    @track isDeleteModalOpen;

    /**
     * Datatable state management
     */
    @track sortBy;
    @track sortDirection;

    /**
     * Spinner state management
     */
    get optionsLoaded() {
        return this.forms && this.sObjects;
    }

    /**
     * Create a new empty form to edit.
     */
    addForm() {
        this.activeItem = { ...INTAKE_FORM };
        this.isModalOpen = true;
    }

    validateFields() {
        const fields = {};
        this.activeItem.mappings.forEach((mapping) => {
            // ignore empty
            if (mapping.salesforceField) {
                fields[mapping.salesforceField] = mapping.relationshipType || null;
            }
        });

        return validate({
            objectApiName: this.activeItem.salesforceObject,
            fields
        }).then((res) => {
            const validities = res.results;
            this.activeItem.mappings.forEach((mapping) => {
                let input = this.template.querySelector(`[data-workflow-field-id="${mapping.workflowFieldId}"]`);
                input.mapping = mapping;
                if (validities.hasOwnProperty(mapping.salesforceField) && !validities[mapping.salesforceField]) {
                    input.customFieldErrorSet(this.label.adminMapIntakeFormsFieldError);
                } else {
                    input.customFieldErrorSet("");
                }
                input.fieldValidate();
            });

            return res.valid;
        });
    }

    /**
     * Upsert an intake form and its related mappings.
     */
    save() {
        return saveRecords({
            // avoid no-arg constructor error by stringifying
            intakeForm: JSON.stringify(this.activeItem)
        })
            .then((res) => {
                if (res.success) {
                    showToast(this, labels.adminSuccess, labels.adminMapIntakeFormsSaveSuccess, "SUCCESS");
                    this.activeItem.salesforceObject = null;
                    this.fieldOption = [];
                } else {
                    showToast(this, labels.adminError, labels.adminMapIntakeFormsSaveError, "ERROR");
                }
                return getRecords();
            })
            .then((res) => {
                this.records = res;
                this.isDataTableLoaded = true;
            });
    }

    /**
     * Retrieve an array of fields on a Salesforce object,
     * ordered alphabetically descending.
     * @param {String} objectApiName
     */
     @track fieldOption = {};
    getObjectFields(objectApiName) {
        this.fieldOption = {};
        getFields({
            objectApiName: objectApiName,workflowFields:this.activeItem.mappings
        }).then((res) => {
            this.fieldOption = res;
        });
    }

    /**
     * Hit the Evisort API for details about an individual workflow,
     * then parse that response into a useful format for our UI.
     * This runs each time a form is loaded, in case of workflow/field changes.
     * We merge in the values stored in Salesforce, but allow Evisort
     * to dictate the structure of the form.
     * @param {String} id Evisort workflow id
     * @returns Promise
     */
    loadIntakeForm(id) {
        this.showMappings = false;
        return getIntakeForm({
            id: id
        }).then((res) => {
            let parsed = JSON.parse(res);
            let fields = [];

            // the shape of the form may change, i.e. new fields added
            // or old fields removed. So we'll pull the structure of the
            // form from Evisort and then write any matching values in
            // from the Salesforce data we have.
            let existingMappings = JSON.parse(JSON.stringify(this.activeItem.mappings));

            parsed.sections.forEach((section) => {
                section.questions.forEach((question) => {
                    // construct the field from Evisort first
                    let field = {
                        workflowFieldName: question.field.name, // change to question
                        workflowFieldId: question.field.id,
                        questionName: question.name,
                        WorkflowFieldType: question.field.type
                    };

                    // if this field has already been mapped, write in the
                    // value stored in Salesforce
                    existingMappings.forEach((mapping) => {
                        if (mapping.workflowFieldName === field.workflowFieldName.trim()) {
                            field.salesforceField = mapping.salesforceField;

                            // is this a lookup? if so, display as an input
                            // rather than a combobox and add type
                            if (mapping.salesforceField) {
                                field.isRelationship = mapping.salesforceField.indexOf(".") > -1;
                                field.isInputEnable = true;
                                field.isRelationshipEnable = mapping.salesforceField.indexOf(".") > -1;
                                if (field.isRelationship) {
                                    field.relationshipType =
                                        mapping.relationshipType === "Child"
                                            ? RELATIONSHIP_TYPES.childLookup
                                            : RELATIONSHIP_TYPES.parentLookup;
                                }
                            }
                        }
                    });

                    fields.push(field);
                });
            });

            this.activeItem.workflowId = parsed.workflowId;
            this.activeItem.workflowName = parsed.name;
            this.activeItem.mappings = fields;

            this.showMappings = true;
            if(!isBlank(this.activeItem) && this.activeItem.hasOwnProperty('salesforceObject') && !isBlank(this.activeItem.salesforceObject)){
                this.getObjectFields(this.activeItem.salesforceObject) ;
            }
        })
        .catch((error) => {
            this.activeItem = null;
            this.showMappings = true;
            this.isModalOpen = false;
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");   
        });
    }

    /**
     * Form field handlers
     */

    /**
     * When the value of the intake form dropdown is changed,
     * use the Evisort API to retrieve the new form's fields.
     * @param {Event} evt Change event
     */
    handleIntakeFormChange(evt) {
        this.loadIntakeForm(evt.detail.value);
    }

    /**
     * When the value of the object dropdown is changed,
     * clear all existing mappings and the fields in the UI,
     * then get the field list for the new object.
     * @param {evt} evt Change event
     */
    handleObjectChange(evt) {
        this.activeItem.salesforceObject = evt.detail.value;
        this.reset();
        if(!isBlank(this.activeItem.workflowId) && !isBlank(this.activeItem.salesforceObject)){
            this.getObjectFields(evt.detail.value);
        }
    }

    /**
     * When a mapping is changed, update interal storage
     * with the new Salesforce field.
     * @param {Event} evt Change event
     */
    handleUpdateMapping(evt) {
        const _dataset = evt.detail.dataset;
        this.activeItem.mappings = this.activeItem.mappings.map((mapping) => {
            if (mapping.workflowFieldId == _dataset.workflowFieldId) {
                if (
                    evt.detail.value == RELATIONSHIP_TYPES.parentLookup ||
                    evt.detail.value == RELATIONSHIP_TYPES.childLookup
                ) {
                    mapping.salesforceField = "";
                    mapping.isRelationship = true;
                    mapping.relationshipType = evt.detail.value;
                    mapping.isRelationshipEnable = true;
                } else {
                    if(mapping.hasOwnProperty("relationshipType") && !isBlank(mapping.relationshipType) && (mapping.relationshipType == RELATIONSHIP_TYPES.parentLookup || 
                        mapping.relationshipType == RELATIONSHIP_TYPES.childLookup )){
                        mapping.isRelationshipEnable = true;
                    }else{
                        mapping.isRelationshipEnable = false;
                    }
                    mapping.salesforceField = evt.detail.value;
                    mapping.relationshipType = evt.detail.relationshipType ? evt.detail.relationshipType : null;
                }
                mapping.isInputEnable = true;
            }
            return mapping;
        });
    }


    /**
     * Reverts a field from a relationship text field back to the standard
     * combobox, clearing its value in the process.
     * @param {Event} evt Click event
     */
    handleToggleMappingType(evt) {
        const _dataset = evt.detail;
        this.activeItem.mappings = this.activeItem.mappings.map((mapping) => {
            if (mapping.workflowFieldId == _dataset.workflowFieldId) {
                mapping.salesforceField = "";
                mapping.relationshipType = "";
                mapping.isRelationship = false;
                mapping.isInputEnable = false;
            }
            return mapping;
        });
    }

    /**
     * Triggers when the Salesforce object is changed.
     * Clear all mappings in the UI and in internal storage.
     */
    reset() {
        // clear inputs
        let fields = [...this.template.querySelectorAll("[data-mapping]")];
        fields.forEach((field) => {
            field.value = "";
        });

        // clear data storage
        this.activeItem.mappings = this.activeItem.mappings.map((mapping) => {
            mapping.salesforceField = "";
            mapping.relationshipType = null;
            mapping.isRelationship = false;
            mapping.isInputEnable = false;
            return mapping;
        });
    }

    /**
     * Data table handlers
     */

    handleRowAction(evt) {
        const action = evt.detail.action;
        const row = evt.detail.row;
        switch (action.name) {
            case "edit":
                this.editRow(row);
                break;
            case "delete":
                this.deleteRow(row);
                break;
        }
    }
    @track isEditRow = false;
    editRow(row) {
        // deep clone row, in case we want to discard
        // changes later
        this.activeItem = JSON.parse(JSON.stringify(row));
        this.isEditRow = true;
        this.loadIntakeForm(row.workflowId);
        this.isModalOpen = true;
    }

    deleteRow(row) {
        this.activeItem = row;
        this.isDeleteModalOpen = true;
    }

    updateColumnSorting(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.data = this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, sortDirection) {
        let parseData = JSON.parse(JSON.stringify(this.records));

        let keyValue = (a) => {
            return a[fieldName];
        };

        // checking reverse direction
        let isReverse = sortDirection === "asc" ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ""; // handling null values
            y = keyValue(y) ? keyValue(y) : "";

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        this.records = parseData;
    }

    /**
     * Modal handlers
     */

    confirmCallback = this.confirmCallbackFunction();

    confirmCallbackFunction() {
        return function () {
            let fields = [...this.template.querySelectorAll("[data-field]")];
            let allValid = true;
            fields.forEach((field) => {
                if ("reportValidity" in field) {
                    // Trim whitespace before validating.
                    field.value = field.value?.trim();

                    if (!field.reportValidity()) {
                        allValid = false;
                    }
                }
            });

            if (!allValid) {
                return;
            }
            this.validateFields().then((valid) => {
                if (valid) {
                    this.save();
                    this.isModalOpen = false;
                }
            });
        }.bind(this);
    }

    cancelCallback = this.cancelCallbackFunction();

    cancelCallbackFunction() {
        return function () {
            this.activeItem.salesforceObject = null;
            this.fieldOption = [];
            this.isModalOpen = false;
        }.bind(this);
    }

    deleteConfirmCallback = this.deleteConfirmCallbackFunction();

    deleteConfirmCallbackFunction() {
        return function () {
            deleteRecord({
                id: this.activeItem.id
            })
                .then((res) => {
                    if (res.success) {
                        showToast(this, labels.adminSuccess, labels.adminMapIntakeFormsDeleteSuccess, "SUCCESS");
                    } else {
                        showToast(this, labels.adminError, labels.adminMapIntakeFormsDeleteError, "ERROR");
                    }
                    return getRecords();
                })
                .then((res) => {
                    this.records = res;
                    this.isDataTableLoaded = true;
                });
            this.isDeleteModalOpen = false;
        }.bind(this);
    }

    deleteCancelCallback = this.deleteCancelCallbackFunction();

    deleteCancelCallbackFunction() {
        return function () {
            this.isDeleteModalOpen = false;
        }.bind(this);
    }

    /**
     * Lifecycle Events
     */

    async connectedCallback() {
        await updateIntakeFormWithPermanentLinkId().then((res)=> {
            this.isDataTableLoaded = true;
        });
        // Get all existing mappings saved to Salesforce
        // and populate the data table
        getRecords().then((res) => {
            this.records = res;
        });

        // Callout to Evisort to retrieve intake forms
        getIntakeForms().then((res) => {
            this.forms = JSON.parse(res)
                .map((item) => {
                    // format as dropdown options
                    return {
                        value: item.id,
                        label: item.name
                    };
                })
                .sort(sortByLabel);
        });

        // Retrieve sObject API names for use in the object combobox
        getObjects().then((res) => {
            this.sObjects = res.sort(sortByLabel);
            this.isLoaded = true;
        });
    }
}