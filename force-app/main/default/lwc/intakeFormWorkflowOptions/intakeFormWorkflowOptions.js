import { LightningElement, track, api, wire } from "lwc";
import labels from "c/labelService";
import {
    getFilteredErrorMessage,
    EVS_FIELDS,
    isComplexPayloadObject,
    normalizeFieldsForConditions,
    normalizeIntakeConditions,
    parseConditions,
    handleFieldChangeForConditions as _handleFieldChangeForConditions
} from "c/csUtils";
import _ from "c/lodash";
import getIntakeFormWithMappedData from "@salesforce/apex/IntakeFormController.getIntakeFormWithData";
import createEvisortTicket from "@salesforce/apex/IntakeFormController.createEvisortTicket";
import { CurrentPageReference } from "lightning/navigation";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import { MessageContext, subscribe, unsubscribe, APPLICATION_SCOPE } from "lightning/messageService";
import intakeSubmitDisabled from "@salesforce/messageChannel/evisortIntakeSubmitDisabled__c";

const COMPANY = "company",
    COUNTERPARTY = "counterparty";

export default class IntakeFormWorkflowOptions extends LightningElement {
    contractOptions = [
        { label: labels.ticketTemplateOptionLabel, value: COMPANY },
        { label: labels.ticketCounterpartyOptionLabel, value: COUNTERPARTY }
    ];
    labels = labels;
    isLoading = true;
    recordId;
    error;
    formSubmissionPayload = {};
    acceptedFormats = [".docx"];
    subscription = null;
    normConditions;
    normFieldsForConditions;
    fieldVisibility;

    @track multipleFiles = false;
    @track renderOptions = false;
    @track isUserSelection = false;
    @track userHasChoice = false;
    @track contractValue;
    @track formData;
    @track disableCreateEvsTicket;

    @api workflowName;
    @api workflowId;
    @api hasCompanyPaper;
    @api hasCounterpartyPaper;
    @api isSaving;

    /* ------------------ 21-03-2023---------------------*/
    @api recordId;
    @api objectApiName;

    /**
     * Records that provide a value for field mapping
     * via a child or parent relationship
     */
    @api relatedRecords = null;

    @wire(CurrentPageReference)
    pageRef(pageRef) {
        this.recordId = pageRef.state.recordId;
    }

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        console.log('object api name 1 ::'+ this.objectApiName);
        this.subscribeToMessageChannel();

        if (this.hasCompanyPaper && this.hasCounterpartyPaper) {
            this.userHasChoice = true;
            this.renderOptions = true;
            this.contractValue = COUNTERPARTY;
        } else if (this.hasCompanyPaper && !this.hasCounterpartyPaper) {
            this.contractValue = COMPANY;
        } else if (!this.hasCompanyPaper && this.hasCounterpartyPaper) {
            this.contractValue = COUNTERPARTY;
        }

        this.formSubmissionPayload.attachmentFile = {};

        this.loadFormWithMappedData();
        this.handleFieldChangeForConditions = _.debounce(this.handleFieldChangeForConditions, 400, { leading: true });
    }

    get retrieveWorkflowId() {
        return this.formData.workflowId;
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                intakeSubmitDisabled,
                (payload) => this.handleMessage(payload),
                {
                    scope: APPLICATION_SCOPE
                }
            );
        }
    }

    handleMessage(payload) {
        this.disableCreateEvsTicket = payload?.disableSave;
    }

    async loadFormWithMappedData() {
        let _childData = {};

        this.relatedRecords.forEach((item) => {
            const { fieldValue = null } = item;
            _childData[item.workflowField] = { [item.id]: fieldValue };
        });

        await getRecordNotifyChange([{ recordId: this.recordId }]);
        getIntakeFormWithMappedData({
            recordId: this.recordId,
            workflowId: this.workflowId,
            childData: _childData
        })
            .then((data) => {
                this.formData = data;
                this.acceptedFormats = data.acceptedFileTypes;

                this.normConditions = normalizeIntakeConditions(data.conditions);
                this.normFieldsForConditions = normalizeFieldsForConditions(data.sections);
                this.fieldVisibility = parseConditions(
                    this.normConditions,
                    this.normFieldsForConditions,
                    data.implicitFields
                );

                this.dispatchEvent(
                    new CustomEvent("evs_formenablesave", {
                        bubbles: true,
                        composed: true
                    })
                );
            })
            .catch((error) => {
                this.error = getFilteredErrorMessage(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get acceptedFileTypes() {
        if (this.acceptedFormats.length > 1) {
            return [this.acceptedFormats.join(" ")];
        }
        return this.acceptedFormats;
    }

    get retrieveFormSections() {
        if (this.formData?.sections) {
            return this.formData.sections;
        }

        return [];
    }

    get retrieveWorkflowId() {
        return this.formData.workflowId;
    }

    handleContractValueChange(event) {
        this.isUserSelection = true;
        if(event.detail.value == COMPANY){
            this.formSubmissionPayload.counterpartyFile = null;
        }
        const selectedOption = event.detail.value;
        this.contractValue = selectedOption;
    }

    get showSpinner() {
        return this.isSaving || this.isLoading;
    }

    get computedClass() {
        return this.hasCounterpartyPaper ? "" : "slds-m-bottom_medium";
    }

    get showDocSection() {
        const isCounterparty = this.contractValue === COUNTERPARTY;
        const companySelection = this.isUserSelection && this.contractValue === COMPANY;

        return !!(isCounterparty || companySelection);
    }

    get showFileUpload() {
        if (this.userHasChoice) {
            return !!(this.isUserSelection && this.contractValue === COUNTERPARTY);
        }
        return this.contractValue === COUNTERPARTY;
    }

    /** HANDLERS */

    handleFieldChangeForConditions = (fieldId, evsType, fieldPayload) => {
        this.normFieldsForConditions[fieldId].value = _handleFieldChangeForConditions(evsType, fieldPayload);

        this.fieldVisibility = parseConditions(
            this.normConditions,
            this.normFieldsForConditions,
            this.formData.implicitFields
        );
    };

    /**
     * At the moment the native onchange method is utilized within
     * intakeFormFieldMapping.dispatchFieldValue(). Meaning, when a User
     * empties an input an empty string can come through the event. We
     * don't want to send this method will delete fields from the payload
     * which previously held value.
     *
     * @param {*} event
     * @returns
     */
    handleIntakeFieldChange(event) {
        const { fieldId, value, evisortType, label, enableCreateOpt } = event.detail;
        const validateCheckboxOrSingleSelect =
            (evisortType === EVS_FIELDS.CHECKBOX || evisortType === EVS_FIELDS.SINGLE_SELECT) &&
            typeof value === "string";
        const validateExisitng = this.formSubmissionPayload.hasOwnProperty(fieldId) && value.length === 0;

        if (validateExisitng && !validateCheckboxOrSingleSelect) {
            if (evisortType === EVS_FIELDS.ADDRESS) {
                this.formSubmissionPayload[fieldId] = Object.assign(this.formSubmissionPayload[fieldId], {
                    [label]: ""
                });
                this.handleFieldChangeForConditions(fieldId, evisortType, this.formSubmissionPayload[fieldId]);
            } else {
                delete this.formSubmissionPayload[fieldId];
                this.handleFieldChangeForConditions(fieldId, evisortType, null);
            }
            return;
        }

        if (value) {
            if (evisortType === EVS_FIELDS.CHECKBOX || evisortType === EVS_FIELDS.RADIO) {
                if (!enableCreateOpt) {
                    this.formSubmissionPayload[fieldId] = {
                        value: value
                    };
                } else {
                    this.formSubmissionPayload[fieldId].other_value = value;
                }
                this.handleFieldChangeForConditions(fieldId, evisortType, this.formSubmissionPayload[fieldId]);
                return;
            }

            if (evisortType === EVS_FIELDS.MULTI_SELECT) {
                const hasFieldId = this.formSubmissionPayload.hasOwnProperty(fieldId);

                if (value?.length === 1 && typeof value[0] === "undefined") {
                    value.shift();
                }

                if (typeof value === "string") {
                    if (hasFieldId && this.formSubmissionPayload[fieldId].value.includes(value)) {
                        return;
                    }

                    if (hasFieldId && !this.formSubmissionPayload[fieldId].value.includes(value)) {
                        this.formSubmissionPayload[fieldId] = {
                            value: this.formSubmissionPayload[fieldId].value.concat(value)
                        };
                    } else {
                        this.formSubmissionPayload[fieldId] = {
                            value: [value]
                        };
                    }
                    this.handleFieldChangeForConditions(fieldId, evisortType, this.formSubmissionPayload[fieldId]);
                    return;
                }

                this.formSubmissionPayload[fieldId] = {
                    value: value
                };

                this.handleFieldChangeForConditions(fieldId, evisortType, this.formSubmissionPayload[fieldId]);
                return;
            }

            if (this.formSubmissionPayload.hasOwnProperty(fieldId) && isComplexPayloadObject(evisortType)) {
                this.formSubmissionPayload[fieldId] = Object.assign(this.formSubmissionPayload[fieldId], {
                    [label]: value
                });
            } else if (isComplexPayloadObject(evisortType)) {
                this.formSubmissionPayload[fieldId] = { [label]: value };
            } else if (evisortType === "DATE") {
                // EVS API expects only the date portion of the JS ISO8601 string
                this.formSubmissionPayload[fieldId] = { value: value.substring(0, 10) };
            } else {
                this.formSubmissionPayload[fieldId] = { value: value };
            }

            // debounced method set up in connectedCallback
            this.handleFieldChangeForConditions(fieldId, evisortType, this.formSubmissionPayload[fieldId]);
        }

        if(evisortType === EVS_FIELDS.ADDRESS && value.length === 0){
            this.formSubmissionPayload[fieldId] =  {[label]: "" }; 
            this.handleFieldChangeForConditions(fieldId, evisortType, this.formSubmissionPayload[fieldId]);
        }
        // Catch any case value is empty without an early return execution above
        if (!value) {
            this.handleFieldChangeForConditions(fieldId, evisortType, value);
        }
    }

    handleFileUpload(event) {
        const { documentId } = event.detail;
        this.formSubmissionPayload.counterpartyFile = {
            documentId
        };
    }

    handleFileRemoved(event) {
        this.formSubmissionPayload.counterpartyFile = null;
    }

    handleAttachmentUpload(event) {
        const { documentId, fieldId } = event.detail;
        this.formSubmissionPayload.attachmentFile[fieldId] = {
            documentId
        };

        // Proper FILE type payload for API is formed in Apex;
        // For parsing conditions, the logic will accept an empty array as valid value
        this.handleFieldChangeForConditions(fieldId, EVS_FIELDS.FILE, { value: [] });
    }

    handleAttachmentRemoved(event) {
        const { documentId, fieldId } = event.detail;
        delete this.formSubmissionPayload.attachmentFile[fieldId];

        this.handleFieldChangeForConditions(fieldId, EVS_FIELDS.FILE, { value: null });
    }

    @api
    postDataToEvisort() {
        var fieldTypeWithfieldId = {};
        const comps = [...this.template.querySelectorAll("c-intake-form-field-mapping")];
        comps.forEach((comp) => {
            comp.dispatchFieldValue();
            var selectedValues = comp.retrieveSelectedValues();
            selectedValues.forEach((ele) => {
                var fieldValue = ele.value;
                const hasFieldId = ele.question.hasOwnProperty("fieldId");
                if (
                    hasFieldId &&
                    (ele.question.field.type == EVS_FIELDS.USER || ele.question.field.type == EVS_FIELDS.DEPARTMENT)
                ) {
                    this.formSubmissionPayload[ele.question.fieldId] = {
                        value: fieldValue
                    };
                    fieldTypeWithfieldId[ele.question.fieldId] = ele.question.field.type;
                }
            });
        });

        let noMissingFiles = true;

        comps.forEach((field) => {
            if (!field.checkRequiredFile()) {
                noMissingFiles = false;
            }
        });

        const hasCounterpartyFile = !!this.formSubmissionPayload.counterpartyFile;
        if (this.contractValue === COUNTERPARTY && !hasCounterpartyFile) {
            return Promise.reject(new Error(labels.ticketIntakeFormAttachementError));
        }

        if (this.disableCreateEvsTicket) {
            return Promise.reject(new Error(labels.ticketRequiredFieldsMissing));
        }

        if (!noMissingFiles) {
            return Promise.reject(new Error(labels.ticketRequiredFieldsMissing));
        }
        const formPayload = JSON.stringify(this.formSubmissionPayload);
        const formfieldType = JSON.stringify(fieldTypeWithfieldId);
        return createEvisortTicket({
            recordId: this.recordId,
            workflowId: this.workflowId,
            workflowName: this.workflowName,
            payload: formPayload,
            fieldType: formfieldType
        });
    }
}