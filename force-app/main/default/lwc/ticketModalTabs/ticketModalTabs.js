import { api, track, LightningElement } from "lwc";
import getTicketInformation from "@salesforce/apex/TicketController.getTicketInformation";
import getActivityLog from "@salesforce/apex/TicketController.getActivityLog";
import getParticipants from "@salesforce/apex/TicketController.getParticipants";
import updateTicket from "@salesforce/apex/TicketController.updateTicket";
import ticketContentDocumentLink from "@salesforce/apex/TicketController.ticketContentDocumentLink";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
    getFilteredErrorMessage,
    EVS_FIELDS,
    showToast,
    formatParameterizedCustomLabel,
    normalizeFieldsForConditions,
    normalizeViewTicketConditions,
    parseConditions,
    handleFieldChangeForConditions as _handleFieldChangeForConditions
} from "c/csUtils";
import labels from "c/labelService";
import _ from "c/lodash";

const STAGE_MAP = new Map([
    ["edit", "Edit"],
    ["review", "Review"],
    ["sign", "Sign"],
    ["finalize", "Finalize"]
]);

const SPECIAL_VALUE_OPTION = "__special_option_value_for_other__";

export default class TicketModalTabs extends LightningElement {
    // The Id of the Evisort_Ticket__c record
    @api ticketRecordId;
    @api showUnsavedError;
    @api objectApiName;
    @api recordId;

    @track hasTicketId;
    @track ticket;
    @track formData;
    @track isLoading = true;
    @track isUpdateable = false;

    // Activity Log properties
    @track activityLoading = false;
    @track activityData = [];
    @track logsError;

    // Contributors properties
    @track isLoadingContributors = false;
    @track contributorsError;
    @track assigneeData = [];
    @track participantData = [];

    // Editing properties
    @track isEditingFormValid = true;
    @track isEditingSaveDisabled = true;
    @track isSavingEdits = false;
    @track currentTicketId;
    @track acceptedFormats = [".docx"];
    @track ticketStatus;

    labels = labels;
    isReadOnly = true;
    error;
    validityMap = new Map();
    isViewTicketComp = true;
    normConditions;
    normFieldsForConditions;
    fieldVisibility;
    originalFieldVisibility;
    implicitFields = {};

    /**
     * Sets up EventListeners for events traveling across DOM
     *
     * evs_formvalidity callback uses a JS Map structure to easily set & enforce unique keys.
     * Map Iterator is turned into an Array then ultimately reduced to
     * a single boolean for the Save button to disable against
     */
    connectedCallback() {
        this.hasTicketId = (this.ticketRecordId != undefined && this.ticketRecordId != null) ? true : false;
        this.loadTicketInfo();
        this.template.addEventListener("evs_editing", (event) => {
            this.isReadOnly = !event.detail.isEditing;
            let comps =  [...this.template.querySelectorAll("c-intake-form-field-mapping")];
            comps.forEach((comp) => {
                comp.reloadMultiSelectData();
                comp.reloadSingleSelectData();
            });
        });
        this.template.addEventListener("evs_formvalidity", (event) => {
            const { fieldId, isValid } = event.detail;
            this.validityMap.set(fieldId, isValid);

            this.isEditingFormValid = !Array.from(this.validityMap)
                .map((item) => {
                    return item[1];
                })
                .reduce((validSoFar, validity) => {
                    return validSoFar && validity;
                }, true);
        });
        this.handleFieldChangeForConditions = _.debounce(this.handleFieldChangeForConditions, 400, { leading: true });
    }

    disconnectedCallback() {
        this.template.removeEventListener("evs_editing");
        this.template.removeEventListener("evs_formvalidity");
    }

    @api
    loadTicketInfo() {
        getTicketInformation({ ticketId: this.ticketRecordId })
            .then((resp) => {
                if (resp.hasOwnProperty("error")) {
                    this.error = getFilteredErrorMessage(resp.error);
                } else {
                    this.isUpdateable = resp.isUpdateable;
                    this.ticket = resp.data;
                    this.currentTicketId = this.ticket.id;
                    this.ticketStatus = this.ticket.status;
                    this.formData = this.prepClonedForm(resp.data.fields, resp.data.workflow.form);
                    this.acceptedFormats = this.ticket.workflow.acceptedFileTypes;
                    this.normConditions = normalizeViewTicketConditions(resp.data.workflow.conditions);
                    this.normFieldsForConditions = normalizeFieldsForConditions(this.formData.sections);
                    this.originalFieldVisibility = parseConditions(
                        this.normConditions,
                        this.normFieldsForConditions,
                        this.implicitFields
                    );

                    this.notifyTicketState(this.ticket);
                    
                    const { currentStage, stages } = this.ticket;
                    this.template.querySelectorAll("c-ticket-tab-workflow").forEach((element) => {
                        element.documentInfo = this.ticket?.document;
                        element.fileInfo = this.ticket?.file;
                        element.currentStage = stages[currentStage.name];
                        element.ticketStatus = this.ticket.status;
                        element.refreshAll();
                    });
                }
            })
            .catch((error) => {
                this.error = getFilteredErrorMessage(error);
            })
            .finally(() => {
                this.isLoading = false;
                this.isSavingEdits = false;
                this.loadActivityLogs();
                this.loadContributors();
                this.loadticketContentDocumentLink();
            });
    }

    /**
     * The Evisort API response for GET /contracts/ticket/{id} does not return a singular complete
     * data structure to render the form UI. We need to take data from two places in the response
     * and merge it together. This function takes the field items, finds them in the form data,
     * then adds the field's value into the form data for that field for rendering.
     *
     * NOTE: Typically the .find() returns an item. In this case we are editing CLONED form data
     * in place so we can render the cloned data. To avoid JS linting errors, return null
     *
     * @param {Array} fields API response: resp.data.fields
     * @param {Object} formData API response: resp.data.workflow.form
     * @returns cloned form data
     */
    prepClonedForm(fields, formData) {
        const clonedForm = JSON.parse(JSON.stringify(formData));

        fields.forEach((field) => {
            // Separate Implicit Fields
            if (!field.id) {
                this.implicitFields[field.fieldId] = field;
            }

            clonedForm.sections
                .flatMap((section) => section.questions)
                .find((question, i, questionArray) => {
                    if (question.field.id === field.fieldId) {
                        if (question.field.type === EVS_FIELDS.CHECKBOX) {
                            const idx = field.value.valueList?.indexOf(SPECIAL_VALUE_OPTION);
                            if (idx >= 0) {
                                field.value.valueList.splice(idx, 1, field.value.other_value);
                            }
                        }

                        if (question.field.type === EVS_FIELDS.RADIO) {
                            questionArray[i].field.mappedValue = field.value;
                        } else {
                            // Sometimes the Evisort API returns `value: {value: 'thing'}` and sometimes not
                            questionArray[i].field.mappedValue = field.value.value ? field.value.value : field.value;
                        }
                    }
                    return null;
                });
        });

        clonedForm.implicitFields = this.implicitFields;

        return clonedForm;
    }

    /** GETTERS/SETTERS */

    get decideVisibility() {
        return this.fieldVisibility || this.originalFieldVisibility;
    }

    get computeClasses() {
        return this.isReadOnly
            ? "slds-m-bottom_small slds-size_1-of-1 slds-col"
            : "slds-m-bottom_small slds-size_1-of-1";
    }

    get isEditSaveDisabled() {
        return this.isEditingSaveDisabled || this.isEditingFormValid;
    }

    get documentInfo() {
        return this.ticket?.document;
    }

    get fileInfo() {
        return this.ticket?.file;
    }

    get currentStage() {
        const { currentStage, stages } = this.ticket;
        return stages[currentStage.name];
    }

    get hasSections() {
        return this.formData?.sections.length;
    }

    get formSections() {
        return this.formData?.sections;
    }

    get isCompleted() {
        return this.ticket?.isCompleted;
    }

    get showContributorsLoading() {
        return this.isLoading || this.isLoadingContributors;
    }

    loadticketContentDocumentLink() {
         ticketContentDocumentLink({ ticketId : this.ticketRecordId, fileDetail : JSON.stringify(this.ticket?.file) });
    }

    async loadContributors() {
        this.isLoadingContributors = true;
        await getParticipants({ ticketId: this.ticketRecordId })
            .then((resp) => {
                const { assignees, participants } = this.groupContributors(resp.data);
                this.assigneeData = assignees;
                this.participantData = participants;
            })
            .catch((error) => {
                this.contributorsError = getFilteredErrorMessage(error);
            })
            .finally(() => {
                this.isLoadingContributors = false;
            });
    }

    /**
     * Actvitiy log data is retrieved after the first two tabs have their
     * callout resolved. So show spinner when those tabs are loading
     * and when the activity log callout is loading.
     */
    get showActivityLoading() {
        return this.isLoading || this.activityLoading;
    }

    async loadActivityLogs() {
        this.activityLoading = true;
        await getActivityLog({ ticketId: this.ticketRecordId })
            .then((resp) => {
                this.activityData = resp.data;
            })
            .catch((error) => {
                this.logsError = getFilteredErrorMessage(error);
            })
            .finally(() => {
                this.activityLoading = false;
            });
    }

    notifyTicketState(ticketData = this.ticket) {
        const { isCompleted, currentStage } = ticketData;
        const { name } = currentStage;
        const { areAllTasksCompleted } = ticketData.stages[name];
        const nextStageName = this.parseNextStage(name, ticketData.stages);

        this.dispatchEvent(
            new CustomEvent("ticketstate", {
                detail: {
                    hasUnsavedChanges: !this.isEditingSaveDisabled,
                    isCompleted,
                    areAllTasksCompleted,
                    nextStageName,
                    currentStageName: STAGE_MAP.get(currentStage.name)
                }
            })
        );
    }

    /** HANDLERS */

    handleFieldChangeForConditions = (fieldId, evsType) => {
        const fieldEl = this.template.querySelector(`c-intake-form-field-mapping[data-field-id="${fieldId}"]`);
        const { data: fieldValue, type } = fieldEl.getNewFieldValue();
        let fieldPayload = {};
        if (fieldValue != undefined || fieldValue != null) {
            fieldPayload = this.normalizeDataforAPI(fieldPayload, fieldId, fieldValue, type);
            this.normFieldsForConditions[fieldId].value = _handleFieldChangeForConditions(
                evsType,
                fieldPayload[fieldId]
            );

            this.fieldVisibility = parseConditions(
                this.normConditions,
                this.normFieldsForConditions,
                this.formData.implicitFields
            );
        }
    };

    handleCloseError() {
        this.dispatchEvent(new CustomEvent("errorclose"));
    }

    handleEditingCancel() {
        this.isReadOnly = true;
        this.isEditingSaveDisabled = true;
        this.dispatchEvent(new CustomEvent("editingcancel"));
        const fields = [...this.template.querySelectorAll("c-intake-form-field-mapping")];
        fields.forEach((field) => field.clearDirtyBg());

        this.fieldVisibility = null;
    }

    handleEditingSave() {
        this.isSavingEdits = true;
        const field = this.template.querySelector(".form-wrapper.slds-p-around_medium");
        field.scrollIntoView(true);

        const fields = [...this.template.querySelectorAll("c-intake-form-field-mapping")];
        let fieldPayload = {};
        fieldPayload.attachmentFile = {};
       
        fields.forEach((fieldEl) => {
            const { fieldId, data, type } = fieldEl.getNewFieldValue();
            if (this.isVisibleField(fieldId) && (data != undefined || data != null)) {

                fieldPayload = this.normalizeDataforAPI(fieldPayload, fieldId, data, type);

            }
        });
/* ------------------ 21-03-2023---------------------*/
        let noMissingFiles = true;
        fields.forEach(field=>{
            if (!field.checkRequiredFile()) {
                noMissingFiles = false;
            }
        });

        if(!noMissingFiles){
            this.isSavingEdits = false;
            Promise.reject(new Error(labels.ticketRequiredFieldsMissing)).then(() => {},
                (error) => {
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title: labels.ticketRequiredFieldsMissing,
                        message: getFilteredErrorMessage(error),
                        variant: "error",
                        mode: "dismissable"
                    }));
                });

            return;
        }
/* ------------------ 21-03-2023---------------------*/
        updateTicket({
            recordId: this.ticketRecordId,
            workflowId: this.ticket.workflowId,
            payload: JSON.stringify(fieldPayload)
        })
            .then(() => {
                showToast(
                    this,
                    null,
                    formatParameterizedCustomLabel(labels.ticketModalSavedSuccessfully, [this.ticket.name]),
                    "SUCCESS"
                );
                this.cleanupEditingOnSuccess(fields);
            })
            .catch((error) => {
                showToast(this, labels.ticketModalUnsuccessfulEditHeader, getFilteredErrorMessage(error), "ERROR");
                this.isSavingEdits = false;
            });
    }

    handleFieldChange(event) {
        const { fieldId, value, evisortType } = event.detail;

        this.isEditingSaveDisabled = false;
        this.notifyTicketState();
        this.handleFieldChangeForConditions(fieldId, evisortType, value);
    }

    handleAttachmentUpload(event){
        this.isEditingSaveDisabled = false;
        this.isEditingFormValid = false;
        this.notifyTicketState();
    }

    isVisibleField(fieldId) {
        const visObj = this.decideVisibility;
        return Object.keys(visObj)
            .filter((key) => visObj[key] === true)
            .includes(fieldId);
    }

    retrieveFieldValue(fieldPayload, fieldEl) {
        const { fieldId, data, type } = fieldEl.getNewFieldValue();
        if (data != undefined || data != null) {
            return this.normalizeDataforAPI(fieldPayload, fieldId, data, type);
        }
        return fieldPayload;
    }

    cleanupEditingOnSuccess(fields) {
        this.isReadOnly = true;
        this.isEditingSaveDisabled = true;
        this.dispatchEvent(new CustomEvent("editingsave"));
        fields.forEach((field) => {
            field.updateValue();
        });
        this.loadTicketInfo();
    }

    /**
     * Determines next stage based on current stage
     * If next stage is skipped (!isEnabled), recursively find next stage
     * If a next stage can't be found, returns empty string
     *
     * @param {String} stageName Name of the current stage
     * @returns String
     */

    parseNextStage(stageName, stages) {
        const keys = STAGE_MAP.keys();
        const array = Array.from(keys);
        const next = array[array.indexOf(stageName) + 1];
        const nextStageName = STAGE_MAP.get(next);

        if (nextStageName && !stages[next].isEnabled) {
            return this.parseNextStage(next, stages);
        }
        if (nextStageName) {
            return nextStageName;
        }

        return "";
    }

    groupContributors(data) {
        const assignees = [],
            participants = [];

        data.forEach((item) => (item.role === "assignee" ? assignees.push(item) : participants.push(item)));

        return { assignees, participants };
    }

    /**
     * EVS API does not expect the ADDRESS, TIME_PERIOD, MONETARY_VALUE
     * payloads to be nested in a Obj keyed at value. All other fields
     * have that expectation though.
     * */

    normalizeDataforAPI(payload, fieldId, fieldData, fieldType) {
        switch (fieldType) {
            case EVS_FIELDS.ADDRESS:
                payload[fieldId] = fieldData;
                return payload;

            case EVS_FIELDS.MONETARY_VALUE:
                // Make sure amount is a number
                fieldData.amount = fieldData.amount * 1;
                payload[fieldId] = fieldData;
                return payload;

            case EVS_FIELDS.TIME_PERIOD:
                fieldData.amount = fieldData.amount * 1;
                payload[fieldId] = fieldData;
                return payload;

            case EVS_FIELDS.PERCENTAGE:
                fieldData = fieldData * 1;
                payload[fieldId] = { value: fieldData };
                return payload;

            case EVS_FIELDS.NUMBER:
                fieldData = fieldData * 1;
                payload[fieldId] = { value: fieldData };
                return payload;

            case EVS_FIELDS.CHECKBOX:
                if (!fieldData.other_value) {
                    payload[fieldId] = {
                        value: fieldData.value
                    };
                } else {
                    payload[fieldId] = fieldData;
                }
                return payload;
            case EVS_FIELDS.RADIO:
                if (fieldData?.value == undefined) return payload;

                if (!fieldData.other_value) {
                    payload[fieldId] = {
                        value: fieldData.value
                    };
                } else {
                    payload[fieldId] = fieldData;
                }
                return payload;
                case EVS_FIELDS.FILE:                
                payload.attachmentFile[fieldId] = fieldData;
                return payload;

            default:
                payload[fieldId] = { value: fieldData };

                return payload;
        }
    }
    get retrieveWorkflowId(){
        return this.ticket.workflowId;
    }
    
    refreshComponent(){ 
        this.loadTicketInfo();
    }
}