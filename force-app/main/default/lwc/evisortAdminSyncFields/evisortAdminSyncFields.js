import { LightningElement, api, wire, track } from "lwc";
import getFieldDefinitions from "@salesforce/apex/AdminController.getFieldDefinitions";
import saveFieldDefinitions from "@salesforce/apex/AdminController.saveFieldDefinitions";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import { showToast, getFilteredErrorMessage } from "c/csUtils";
import evisortDocumentMapping from "@salesforce/apex/ExportController.mappingFields";
import getDocumentFieldSyncMappingRecord from "@salesforce/apex/ExportController.getDocumentFieldSyncMappingRecord";
import deleteDocumentFieldSyncMappingRecord from "@salesforce/apex/ExportController.deleteDocumentFieldSyncMappingRecord";
import getDocumentMappingFields from "@salesforce/apex/ExportController.getDocumentMappingFields";
import labels from "c/labelService";
import { loadStyle } from "lightning/platformResourceLoader";
import { refreshApex } from "@salesforce/apex";

const columns = [
    {
        type: "text",
        fieldName: "label",
        label: "Label",
        sortable: true
    },
    {
        type: "text",
        fieldName: "dataType",
        label: "Type",
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
    },
    {
        type: "boolean",
        fieldName: "readOnly",
        label: "Read-only in Salesforce",
        sortable: true,
        editable: true,
        initialWidth: 180
    }
];

const ACTIONS = [
    { label: "Edit", name: "edit" },
    { label: "Delete", name: "delete" }
];

const metadataObjectFieldsColumns = [
    {
        type: "text",
        fieldName: "objectLabel",
        fieldApiName:"objectName",
        label: "Object Name",
        sortable: true
    },
    {
        type: "date",
        fieldName: "createdDate",
        label: "Created Date",
        typeAttributes:{
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "2-digit"
        },
        sortable: true
    },
    {
        type: "date",
        fieldName: "lastModifiedDate",
        label: "Last Modified Date",
        typeAttributes:{
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "2-digit"
        },
        sortable: true
    },
    { type: "action", typeAttributes: { rowActions: ACTIONS } }
];

export default class EvisortAdminSyncFields extends LightningElement {
    @api iconsvgurl;
    @api activestate;
    @track fieldData = "";
    @track sortBy;
    @track sortDirection;
    @track draftValues = [];
    @track loaded = false;
    @track isLoading = true;
    @track activeItem = {};
    @track mappingFields;
    @track records;
    @track isDeleteModalOpen;
    @track mappedRecord=[];
    @track singleClick = 0;
    @track isModalOpen = false;
    @track editDataLoaded = true;
    label = labels;
    wiredResult;

    columns = columns;
    metadataObjectFieldsColumns = metadataObjectFieldsColumns;

    noAccessSVG = Evisort_Resources + "/evisortResources/evisortNoAccess.svg";
    @wire(getFieldDefinitions, { fieldType: "Field" })
    loadFields(result) {
        this.wiredResult = result;
        if (result.data) {
            this.fieldData = result.data;
            //sort data by descending order of createdDate
            this.sortData("createdDate", "desc");
            this.loaded = true;
        } else if (result.error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(result.error), "ERROR");
        }
        this.isLoading = false;
    }

    /*
     * Initializing the component properties
    */
    connectedCallback() {
        loadStyle(this, Evisort_Resources + "/evisortResources/evisortSyncFieldsProvisions.css");
        this.getDocumentFieldMapping();  
    }

    /**
     * Retrieve Mapped Records of evisort field And Saleforce field,
     */
    getDocumentFieldMapping(){
        getDocumentFieldSyncMappingRecord()
        .then((result) => {
            this.records = result;
        })
        .catch((error) => {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        });
    }

      /**
     * Grabs updated Fields and save the record
     * If there is an error, we throw a toast message
     * @param {Event} evt Change event
     */
    handleSave(event) {
        const updatedValues = event.detail.draftValues;

        saveFieldDefinitions({ fieldDefinitions: JSON.stringify(updatedValues), fieldType: "Field" })
            .then((result) => {
                //result set from database to reload datatable with updated values
                this.fieldData = result;
                this.sortData("createdDate", "desc");
                //setting draft values to null to clear of inline edit
                this.draftValues = [];
                showToast(this, this.label.adminSuccess, this.label.adminFieldsUpdated, "SUCCESS");
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            });
    }

    handleSortData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.fieldData));

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

        this.fieldData = parseData;
    }

    @api
    reloadFields() {
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

    addForm() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
        this.singleClick = 0;
    }

    /**
     * Retrieve updated input data of evisort and salesforce fields
     * @param {inputValue} event Change or Custom event
     */
    handleUpdateFieldRow(event){
        this.mappingFields = JSON.stringify(event.detail);
    }

    confirmCallback = this.confirmCallbackFunction();

    /*
        @Description : Checking validations
    */
    confirmCallbackFunction() {
        
        return function () {
            let isChildVaild = true;
            this.template
            .querySelectorAll("c-s-object-field-mapping-form")
            .forEach(element => {
                if (element.checkValidations() === false) {
                    isChildVaild = false;
                }
                if (element.checkFieldValidations() === false) {
                    isChildVaild = false;
                }
            });            
        if (isChildVaild) {
            if(this.singleClick == 0){
             this.save();
            } 
        }
        }.bind(this);
    }

    cancelCallback = this.cancelCallbackFunction();
    /*
        @Description : close popup modal 
    */
    cancelCallbackFunction() {
        return function () {
            this.isModalOpen = false;
            this.mappedRecord =[];
            this.mappingFields = '';
        }.bind(this);
    }

    /*
        @Description : save records
    */
    save() {
        if(this.mappingFields != undefined && this.mappingFields != '' && this.mappingFields != null){
         evisortDocumentMapping({mappingFieldList:this.mappingFields})
            .then(() => {
                    this.singleClick = 1;
                    showToast(this, this.label.adminSuccess, this.label.adminDocumentmappinghasbeensaved, "SUCCESS");
                    this.isModalOpen = false;
                    this.getDocumentFieldMapping();
                    this.mappedRecord =[];
            })
            .catch((error) => {
                this.singleClick = 0;
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
        }else{
            this.singleClick = 0;
            showToast(this, this.label.AdminEvisortSyncFieldNull,"", "ERROR");
        }
    }
    /**
     * Data table handlers
     */
    handleRowAction(evt){
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
    /*
        @Description : Handle delete row records 
    */
    deleteRow(row) {
        this.activeItem = {};
        this.activeItem = row;
        this.isDeleteModalOpen = true;
    }

    deleteConfirmCallback = this.deleteConfirmCallbackFunction();

    /*
        @Description : Delete row records 
    */
    deleteConfirmCallbackFunction() {
        return function () {
            deleteDocumentFieldSyncMappingRecord({
                objectName: this.activeItem.objectName
            })
                .then(() => {
                    showToast(this, this.label.adminSuccess, this.label.adminMappinghasbeensuccessfullydeleted, "SUCCESS");
                   this.getDocumentFieldMapping();
                })
                .catch((error) => {
                    showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
                })
            this.isDeleteModalOpen = false;
        }.bind(this);
    }

    deleteCancelCallback = this.deleteCancelCallbackFunction();
    
    /*
        Handle delete row popup modal  
    */
    deleteCancelCallbackFunction() {
        return function () {
            this.isDeleteModalOpen = false;
        }.bind(this);
    }

    /*
        @Description : Edit row records 
    */
    editRow(row) {
        this.editDataLoaded = false;
        this.singleClick = 0;
        // changes later
        getDocumentMappingFields({
            objectName: row.objectName
        })
        .then((result) => {
            this.mappedRecord = result;
            this.editDataLoaded = true;
        })
        .catch((error) => {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        });
        this.isModalOpen = true;
    }

    /*
        @Description : Hides sObject Field List in child component on the click of modal component.
    */
    handleModalClick() {
        this.template.querySelectorAll("c-s-object-field-mapping-form")
        .forEach(element => {
            element.handleListViewHide();
        });
    }
}