import { api, LightningElement, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import labels from "c/labelService";
import { formatParameterizedCustomLabel, getFilteredErrorMessage } from "c/csUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { MessageContext, publish } from "lightning/messageService";
import ticketCreated from "@salesforce/messageChannel/evisortTicketCreated__c";
import updateIntakeFormWithPermanentLinkId from "@salesforce/apex/IntakeFormController.updateIntakeFormWithPermanentLinkId";
import intakeSubmitDisabled from "@salesforce/messageChannel/evisortIntakeSubmitDisabled__c";
import getMappings from "@salesforce/apex/NewIntakeFormController.getIntakeFormsMappings";

const VIEW_TYPES = {
    WORKFLOW_TYPE: "workflowType",
    OBJECT_LOOKUP: "objectLookup",
    WORKFLOW_OPTIONS: "workflowOpts"
};
export default class IntakeForm extends LightningElement {
    showWorkflowType = true;
    showWorkflowOptions = false;
    showObjectLookup = false;
    childObjects = [];
    lookupTotal;

    @api recordId;
    @api objectApiName;

    @track relatedRecords = [];
    @track selectedWorkflow;
    @track isSaveDisabled = true;
    @track isSaving = false;
    @track hasSelectedMappedRecords = false;
    labels = labels;
    validityMap = new Map();

    @wire(MessageContext)
    messageContext;

    @wire(MessageContext)
    disableSubmitContext;

    /**
     * Callback uses a JS Map structure to easily set & enforce unique keys.
     * Map Iterator is turned into an Array then ultimately reduced to
     * a single boolean for the Save button to disable against invalid submissions
     */
     async connectedCallback() {
        await updateIntakeFormWithPermanentLinkId();
        this.template.addEventListener("evs_formvalidity", (event) => {
            const { fieldId, isValid } = event.detail;

            this.validityMap.set(fieldId, isValid);

            this.isSaveDisabled = !Array.from(this.validityMap)
                .map((item) => item[1])
                .reduce((validSoFar, validity) => {
                    return validSoFar && validity;
                }, true);

            publish(this.disableSubmitContext, intakeSubmitDisabled, { disableSave: this.isSaveDisabled });
        });
        this.template.addEventListener("evs_formenablesave", (event) => {
            this.isSaveDisabled = false;
        });
    }

    disconnectedCallback() {
        this.template.removeEventListener("evs_formvalidity");
        this.template.removeEventListener("evs_formenablesave");
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    save() {
        this.isSaving = true;
        this.template
            .querySelector("c-intake-form-workflow-options")
            .postDataToEvisort()
            .then(() => {
                publish(this.messageContext, ticketCreated);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.labels.ticketCreationSuccessTitle,
                        message: this.labels.ticketCreationSuccessText,
                        variant: "success",
                        mode: "dismissable"
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                this.isSaveDisabled = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.labels.ticketCreationErrorTitle,
                        message: getFilteredErrorMessage(error),
                        variant: "error",
                        mode: "dismissable"
                    })
                );
            })
            .finally(() => (this.isSaving = false));
    }

    loadMappingRecords() {
        getMappings({ workflowId: this.selectedWorkflow.id, parentId: this.recordId }).then((res) => {
            if (Object.keys(res).length) {
                this.childObjects = res;
                this.activateModalView(VIEW_TYPES.OBJECT_LOOKUP);
            } else {
                this.activateModalView(VIEW_TYPES.WORKFLOW_OPTIONS);
            }
        });
    }

    handleNext() {
        if (this.showWorkflowType) {
            // call for child objects then advance view
            this.loadMappingRecords();
        } else if (this.showObjectLookup) {
            const comp = this.template.querySelector("c-intake-form-object-lookup");
            const result = comp.checkForSelectedRecords();

            if (!result) return;
            this.activateModalView(VIEW_TYPES.WORKFLOW_OPTIONS);
        }
    }

    handleSelectedRecord(e) {
        if (this.relatedRecords.some((item) => item.id === e.detail.id)) return;

        // e.detail is an Array here
        this.relatedRecords.push(...e.detail);
        this.hasSelectedMappedRecords = true;
    }

    handleRemovedRecord(e) {
        const idx = this.relatedRecords.findIndex((item) => item.id === e.detail.id);
        if (idx > -1) {
            this.relatedRecords.splice(idx, 1);
        }

        if (!this.relatedRecords.length) {
            this.hasSelectedMappedRecords = false;
        }
    }

    handleLookupTotal(e) {
        this.lookupTotal = e.detail.lookupTotal;
    }

    activateModalView(view) {
        switch (view) {
            case VIEW_TYPES.WORKFLOW_TYPE:
                this.showWorkflowType = true;
                this.showObjectLookup = false;
                this.showWorkflowOptions = false;
                break;
            case VIEW_TYPES.OBJECT_LOOKUP:
                this.showWorkflowType = false;
                this.showObjectLookup = true;
                this.showWorkflowOptions = false;
                break;
            case VIEW_TYPES.WORKFLOW_OPTIONS:
                this.showWorkflowType = false;
                this.showObjectLookup = false;
                this.showWorkflowOptions = true;
                break;
            default:
                break;
        }
    }

    handleWorkflowNameSelection(e) {
        this.selectedWorkflow = { ...e.detail };
    }

    get isSaveBtnDisabled() {
        return this.isSaving || this.isSaveDisabled;
    }

    get hasCounterpartyPaper() {
        return this.selectedWorkflow.hasCounterpartyPaper;
    }

    get hasCompanyPaper() {
        return this.selectedWorkflow.hasCompanyPaper;
    }

    get isNextDisabled() {
        return !this.selectedWorkflow;
    }

    get headerTitle() {
        return this.selectedWorkflow
            ? formatParameterizedCustomLabel(this.labels.ticketNewIntakeFormHeaderWithName, [
                  this.selectedWorkflow.label
              ])
            : this.labels.ticketNewIntakeFormHeader;
    }

    get workflowName() {
        return this.selectedWorkflow.label;
    }

    get workflowId() {
        return this.selectedWorkflow.id;
    }
}