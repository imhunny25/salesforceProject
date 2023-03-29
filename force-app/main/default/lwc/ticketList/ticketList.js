import { api, LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getFilteredErrorMessage, formatParameterizedCustomLabel, showToast } from "c/csUtils";
import labels from "c/labelService";
import getEvisortTicketsByParentId from "@salesforce/apex/TicketListController.getEvisortTicketsByParentId";
import submitNextStage from "@salesforce/apex/TicketController.submitNextStage";
import markComplete from "@salesforce/apex/TicketController.markComplete";
import nameSpaceEvisort from "@salesforce/apex/CSUtils.getNameSpace";
import getWorkspaceSettings from "@salesforce/apex/CSUtils.getWorkspaceSettings";

import EVISORT_NAME from "@salesforce/schema/Evisort_Ticket__c.Evisort_Name__c";
import EVISORT_ID from "@salesforce/schema/Evisort_Ticket__c.Evisort_ID__c";
import CREATED_DATE from "@salesforce/schema/Evisort_Ticket__c.CreatedDate";
import SUBMITTED_BY from "@salesforce/schema/Evisort_Ticket__c.Submitted_By__c";
import LAST_MODIFIED from "@salesforce/schema/Evisort_Ticket__c.LastModifiedDate";
import ASSIGNED_TO from "@salesforce/schema/Evisort_Ticket__c.Assigned_To__c";
import STATUS_FIELD from "@salesforce/schema/Evisort_Ticket__c.Status__c";
import STAGE_FIELD from "@salesforce/schema/Evisort_Ticket__c.Stage__c";
import ID_FIELD from "@salesforce/schema/Evisort_Ticket__c.Id";
import { MessageContext, subscribe, unsubscribe, APPLICATION_SCOPE } from "lightning/messageService";
import ticketCreated from "@salesforce/messageChannel/evisortTicketCreated__c";

export default class TicketsList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isViewAll;
    @api navRecordProperty;
    @api objectApiName;
    @api navObjectAPIName;

    @track tickets = [];
    @track showModal = false;
    @track selectedTicket;
    @track hideNextStageBtn = true;
    @track nextStageName;
    @track submitLabel;
    @track isBlocked;
    @track showConfirmationModal = false;
    @track showIsDeletedModal = false;
    @track confirmModalText;
    @track isSubmitting = false;
    @track hasUnsavedChanges = false;
    @track showUnsavedError = false;
    @track isEditState = false;
    @track currentRecord;
    @track currentObjectApiName;

    columns = [
        {
            label: labels.ticketNameColumnHeader,
            fieldName: EVISORT_NAME.fieldApiName,
            sortable: true,
            type: "customName",
            typeAttributes: {
                evisortName: { fieldName: EVISORT_NAME.fieldApiName },
                id: { fieldName: ID_FIELD.fieldApiName },
                submittedBy: { fieldName: SUBMITTED_BY.fieldApiName },
                status: { fieldName: STATUS_FIELD.fieldApiName },
                stage: { fieldName: STAGE_FIELD.fieldApiName },
                evisortId: { fieldName: EVISORT_ID.fieldApiName },
                createdDate: { fieldName: CREATED_DATE.fieldApiName },
                lastModified: { fieldName: LAST_MODIFIED.fieldApiName },
                handleClick: this.openModal.bind(this)
            }
        },
        { label: labels.ticketSubByColumnHeader, fieldName: SUBMITTED_BY.fieldApiName, sortable: true },
        { label: labels.ticketSubOnColumnHeader, fieldName: CREATED_DATE.fieldApiName, sortable: true, type: "date" },
        {
            label: labels.ticketLastModColumnHeader,
            fieldName: LAST_MODIFIED.fieldApiName,
            sortable: true,
            type: "date",
            typeAttributes: {
                month: "numeric",
                day: "numeric",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
                hour12: true,
                second: "2-digit"
            }
        },
        { label: labels.ticketAssignedColumnHeader, fieldName: ASSIGNED_TO.fieldApiName, sortable: true },
        { label: labels.ticketStatusColumnHeader, fieldName: STATUS_FIELD.fieldApiName, sortable: true }
    ];

    subscription = null;
    resourceLoaded = false;
    sortedBy = LAST_MODIFIED.fieldApiName;
    sortedDirection = "desc";
    labels = labels;
    isLoading = true;
    isDesc = true;
    nameSpace = null;
    wSettings;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadTickets();
        this.subscribeToMessageChannel();

        this.template.addEventListener("evs_editing", (event) => {
            this.isEditState = event.detail.isEditing;
        });
        nameSpaceEvisort()
            .then((result) => {
                this.nameSpace = result;
            })
            .catch((error) => {});

        getWorkspaceSettings()
            .then((settings) => {
                this.wSettings = settings;
            })
            .catch((error) => {});
    }

    disconnectedCallback() {
        this.template.removeEventListener("evs_editing");
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                ticketCreated,
                (payload) => this.handleMessage(payload),
                {
                    scope: APPLICATION_SCOPE
                }
            );
        }
    }

    handleMessage(payload) {
        this.loadTickets();
    }

    handleEditingClose(event) {
        this.isEditState = false;
        this.showUnsavedError = false;
        this.hasUnsavedChanges = false;
    }

    handleUnsavedErrorClose() {
        this.showUnsavedError = false;
    }
/* ------------------ 21-03-2023---------------------*/
    loadTickets() {
        var currentRecordId;
        var limit;
        if (this.navRecordProperty) {
            currentRecordId = this.navRecordProperty;
            this.currentRecord = this.navRecordProperty;
            this.currentObjectApiName = this.navObjectAPIName;
            limit = 0;
        } else {
            currentRecordId = this.recordId;
            this.currentRecord = this.recordId;
            this.currentObjectApiName = this.objectApiName;
            limit = 5;
        }
        return getEvisortTicketsByParentId({ parentId: currentRecordId, limitTo: limit })
            .then((data) => {
                this.tickets = this.normalizeTickets(data);
            })
            .catch((error) => {
                showToast(this, this.labels.ticketGetRelatedTicketsError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => (this.isLoading = false));
    }

    normalizeTickets(rawData) {
        const normalizedTickets = [];

        rawData.forEach(({ LastModifiedDate, Assigned_To__c, ...rest }) => {
            normalizedTickets.push({
                LastModifiedDate: new Date(LastModifiedDate).getTime(),
                Assigned_To__c: Assigned_To__c?.length ? Assigned_To__c : "---",
                ...rest
            });
        });

        return normalizedTickets.sort((a, b) => b.LastModifiedDate - a.LastModifiedDate);
    }

    get showFooter() {
        if (this.isViewAll) {
            return false;
        } else {
            return this.tickets?.length >= 5;
        }
    }

    get hasTickets() {
        return !!this.tickets?.length;
    }

    get isSubmitDisabled() {
        return this.isEditState || this.isBlocked;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        const cloneData = [...this.tickets];

        cloneData.sort(this.sortBy(fieldName, sortDirection === "asc" ? 1 : -1));

        // After the entire data is sorted,
        // this sort will perform more like a grouping by placing all Status__c === null
        // at the end without disturbing the sort order of the rest
        if (fieldName === STATUS_FIELD.fieldApiName) {
            cloneData.sort((a, b) => {
                if (a.Status__c == null) {
                    return 1;
                } else if (typeof a.Status__c === typeof b.Status__c) {
                    return 0;
                }
                return -1;
            });
        }

        this.tickets = cloneData;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
    }

    closeModalFn() {
        if (this.hasUnsavedChanges) {
            this.showUnsavedError = true;
            return;
        }

        if (!this.isSubmitting) {
            this.showModal = false;
        }
    }

    closeModal = this.closeModalFn.bind(this);

    confirmCallbackFn() {
        this.showModal = false;
    }

    closeConfirmationModalFn() {
        this.showConfirmationModal = false;
    }

    closeConfirmationModal = this.closeConfirmationModalFn.bind(this);

    closeIsDeletedModalFn() {
        this.showIsDeletedModal = false;
    }

    closeIsDeletedModal = this.closeIsDeletedModalFn.bind(this);

    openModal(event) {
        event.preventDefault();
        const { evisortName, id, status, stage, evisortId, submittedBy, createdDate } = event.target.dataset;

        const evsTicketUrl = this.formatEVSUrl(evisortId);
        this.selectedTicket = {
            evisortName,
            evsTicketUrl,
            id,
            status,
            stage,
            evisortId,
            submittedBy,
            createdDate
        };

        if (this.selectedTicket.status === "Deleted") {
            this.showIsDeletedModal = true;
        } else {
            this.showModal = true;
        }
    }

    formatEVSUrl(evisortId) {
        let _wSettings = {};

        if (this.nameSpace) {
            //Remove nameSpace from keys and values
            for (const [key, value] of Object.entries(this.wSettings)) {
                const _key = key.replace(`${this.nameSpace}__`, "");
                const _value = typeof value === "string" ? value.replace(`${this.nameSpace}__`, "") : value;
                _wSettings[_key] = _value;
            }
        } else {
            const { Subdomain__c, Domain__c, Workspace__c } = this.wSettings;
            _wSettings = { Subdomain__c, Domain__c, Workspace__c };
        }

        return `https://${_wSettings.Subdomain__c}.evisort.${_wSettings.Domain__c}/${_wSettings.Workspace__c}/workflow/tickets/${evisortId}`;
    }

    handleSubmitNextStage() {
        this.showConfirmationModal = true;
    }

    handleSubmit() {
        let formattedLabel;
        this.showConfirmationModal = false;
        this.isSubmitting = true;

        if (this.submitLabel === labels.ticketMarkCompletedBtn) {
            formattedLabel = formatParameterizedCustomLabel(labels.ticketModalSubmitCompletedSuccess, [
                this.selectedTicket.evisortName
            ]);

            markComplete({ ticketId: this.selectedTicket.id })
                .then((resp) => {
                    this.loadTickets();
                })
                .then(() => {
                    this.template.querySelector("c-ticket-modal-tabs").loadTicketInfo();
                    showToast(this, null, showToast(this, null, formattedLabel, "SUCCESS"), "SUCCESS");
                })
                .catch((error) => {
                    showToast(this, null, getFilteredErrorMessage(error), "ERROR");
                })
                .finally(() => {
                    this.isSubmitting = false;
                    this.showModal = false;
                });
        } else {
            formattedLabel = formatParameterizedCustomLabel(labels.ticketModalSubmitStageSuccess, [
                this.selectedTicket.evisortName,
                this.nextStageName.toLowerCase()
            ]);

            submitNextStage({ ticketId: this.selectedTicket.id })
                .then((resp) => {
                    this.loadTickets();
                })
                .then(() => {
                    this.template.querySelector("c-ticket-modal-tabs").loadTicketInfo();
                    showToast(this, null, showToast(this, null, formattedLabel, "SUCCESS"), "SUCCESS");
                })
                .catch((error) => {
                    showToast(this, null, getFilteredErrorMessage(error), "ERROR");
                })
                .finally(() => {
                    this.isSubmitting = false;
                    this.showModal = false;
                });
        }
    }

    handleTicketState(event) {
        const { isCompleted, areAllTasksCompleted, nextStageName, hasUnsavedChanges } = event.detail;
        this.hasUnsavedChanges = hasUnsavedChanges;
        this.hideNextStageBtn = isCompleted;
        this.nextStageName = nextStageName;
        this.isBlocked = !areAllTasksCompleted;
        this.submitLabel = this.createSubmitLabels(event.detail);
    }

    handleViewAll(event) {
        event.preventDefault();
        let cmpName;
        cmpName = "c__ticketListWrapper";
        if (this.nameSpace != null) {
            cmpName = this.nameSpace + "__ticketListWrapper";
        }

        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                componentName: cmpName
            },
            state: {
                c__navRecordProperty: this.recordId,
                c__isViewAll: true,
                c__isObjectApiName: this.objectApiName
            }
        });
    }

    createSubmitLabels({ nextStageName, currentStageName, areAllTasksCompleted }) {
        if (nextStageName.length && areAllTasksCompleted) {
            this.confirmModalText = formatParameterizedCustomLabel(labels.ticketSubmitNextStageModal, [
                nextStageName.toLowerCase()
            ]);

            return formatParameterizedCustomLabel(labels.ticketNextStageBtn, [nextStageName]);
        } else if (!areAllTasksCompleted) {
            return formatParameterizedCustomLabel(labels.ticketPendingTask, [currentStageName]);
        }

        this.confirmModalText = labels.ticketMarkCompletedModal;
        return labels.ticketMarkCompletedBtn;
    }

    openEvisortDocumentation() {
        window.open(this.selectedTicket.evsTicketUrl, "_blank");
    }
}