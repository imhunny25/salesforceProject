import { LightningElement, track, wire, api } from "lwc";
import labels from "c/labelService";
import getIntakeFormsByVisibility from "@salesforce/apex/NewIntakeFormController.getIntakeFormsByVisibility";

import { sortIntakeFormName, getFilteredErrorMessage } from "c/csUtils";

export default class IntakeFormWorkflowType extends LightningElement {
    @track workflowTypeId = "";
    @track workflowTypeOptions;

    @api recordId;
    isLoading = true;
    searchValue = "";
    labels = labels;
    filteredWorkflows = [];
    error;

    get workflows() {
        return this.searchValue.length ? this.filteredWorkflows : this.workflowTypeOptions;
    }

    get hasWorkflows() {
        return !!this.workflowTypeOptions?.length;
    }

    get searchWithNoResults() {
        return !!this.searchValue && !this.filteredWorkflows.length;
    }

    connectedCallback(){
        this.wiredIntakeForms();
    }

    wiredIntakeForms(){
        getIntakeFormsByVisibility({recordId : this.recordId}) 
            .then((data) => {
                const parsedData = JSON.parse(data);
                if (parsedData.hasOwnProperty("error")) {
                    this.workflowTypeOptions = [];
                } else {
                    const normalizedData = parsedData.map((item) => {
                        const {name, hasCompanyPaper = true, hasCounterpartyPaper = true } = item;
                        let id = item.mapped ? item.workflowId : item.id;
                        return {
                            id,
                            hasCompanyPaper,
                            hasCounterpartyPaper,
                            label: item.mapped ? item.workflowName : name
                        };
                    });
                    this.workflowTypeOptions = normalizedData.sort(sortIntakeFormName);
                }
                this.isLoading = false;
            }).catch(error => {
                this.error = getFilteredErrorMessage(error);
                this.isLoading = false;
            })
    }

    handleSearch(e) {
        this.searchValue = e.currentTarget.value;

        if (this.searchValue.length) {
            this.filteredWorkflows = this.workflowTypeOptions.filter((type) => {
                return type.label.toLowerCase().includes(this.searchValue.toLowerCase());
            });
        } else {
            this.filteredWorkflows = [];
        }
    }

    handleOptionSelected(e) {
        const workflowId = e.currentTarget.dataset.option;
        const selectedWorkflow = this.workflowTypeOptions.find((item) => item.id === workflowId);

        this.workflowTypeName = selectedWorkflow.label;
        // fire event to parent to set workflow type selection
        this.dispatchEvent(
            new CustomEvent("typeselected", {
                detail: {
                    ...selectedWorkflow
                }
            })
        );

        // select clicked option in UI
        for (let option of this.workflowTypeOptions) {
            if (option.id === selectedWorkflow.id) {
                option.selected = true;
            } else {
                option.selected = false;
            }
        }
    }
}