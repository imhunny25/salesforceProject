import { LightningElement, api, track, wire } from "lwc";
import getFieldDefinitions from "@salesforce/apex/AdminController.getFieldDefinitions";
import saveFieldDefinitions from "@salesforce/apex/AdminController.saveFieldDefinitions";
import getNewProvisions from "@salesforce/apex/AdminController.getNewProvisions";
import saveGlobalSettings from "@salesforce/apex/AdminController.saveGlobalSettings";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import { showToast, getFilteredErrorMessage } from "c/csUtils";
import labels from "c/labelService";
import { loadStyle } from "lightning/platformResourceLoader";
import { refreshApex } from "@salesforce/apex";

const columns = [
    {
        type: "text",
        fieldName: "label",
        label: "Provision",
        sortable: true
    },
    {
        type: "boolean",
        fieldName: "isActive",
        label: "Active",
        sortable: true,
        editable: true,
        initialWidth: 90
    },
    {
        type: "date",
        fieldName: "createdDate",
        label: "Created Date",
        sortable: true
    },
    {
        type: "date",
        fieldName: "lastModifiedDate",
        label: "Last Modified Date",
        sortable: true
    }
];

export default class EvisortAdminSyncProvisions extends LightningElement {
    @api activestate;
    @api iconsvgurl;
    @track toggleValue;
    label = labels;
    @track sortBy;
    @track sortDirection;
    @track draftValues = [];
    @track provisionData = "";
    columns = columns;
    wiredResult;
    @track loaded = false;
    @track isLoading = true;
    noAccessSVG = Evisort_Resources + "/evisortResources/evisortNoAccess.svg";

    @wire(getFieldDefinitions, { fieldType: "Provision" })
    loadProvisions(result) {
        this.wiredResult = result;
        if (result.data) {
            this.provisionData = result.data;
            //sort data by descending order of createdDate
            this.sortData("createdDate", "desc");
            this.loaded = true;
        } else if (result.error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(result.error), this.label.adminError);
        }
        this.isLoading = false;
    }

    connectedCallback() {
        loadStyle(this, Evisort_Resources + "/evisortResources/evisortSyncFieldsProvisions.css");
    }

    @wire(getNewProvisions)
    loadNewProvisions({ error, data }) {
        if (data) {
            this.toggleValue = data;
        } else if (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
    }

    handleToggleChange(event) {
        this.toggleValue = event.target.checked;
        //save toggle to custom settings
        saveGlobalSettings({ globalSettingType: "Sync Provisions", value: this.toggleValue })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, "", "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            });
    }

    handleSave(event) {
        const updatedValues = event.detail.draftValues;

        saveFieldDefinitions({ fieldDefinitions: JSON.stringify(updatedValues), fieldType: "Provision" })
            .then((result) => {
                //result set from database to reload datatable with updated values
                this.provisionData = result;
                this.sortData("createdDate", "desc");
                //setting draft values to null to clear of inline edit
                this.draftValues = [];
                showToast(this, this.label.adminSuccess, this.label.adminProvisionsUpdated, this.label.adminSuccess);
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), this.label.adminError);
            });
    }

    handleSortData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.provisionData));

        let keyValue = (a) => {
            return a[fieldname];
        };

        // checking reverse direction
        let isReverse = direction === "asc" ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ""; // handling null values
            y = keyValue(y) ? keyValue(y) : "";

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        this.provisionData = parseData;
    }

    @api
    reloadProvisions() {
        //refreshApex fires when it is not initial load
        if (this.loaded) {
            this.isLoading = true;
            refreshApex(this.wiredResult)
                .then(() => {
                    this.isLoading = false;
                })
                .catch(() => {
                    this.isLoading = false;
                });
        }
    }
}