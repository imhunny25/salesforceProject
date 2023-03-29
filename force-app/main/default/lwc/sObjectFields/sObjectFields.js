import { LightningElement,track,api } from 'lwc';
import labels from "c/labelService";
import getObjectFieldMetaData from "@salesforce/apex/sObjectFieldMappingController.getObjectFieldMetaData";
import { showToast, sortByLabel, getFilteredErrorMessage } from "c/csUtils";
import getMappingDataTypes from "@salesforce/apex/ExportController.getMappingDataTypes";


export default class SObjectFields extends LightningElement {
    @api objectname = '';
    @api evisortMappedFields;
    @api fieldDataTypeMissMatch;
    @track evisortFields = {};
    @track salesforceFields = [];
    @track selectedObjects;
    @track isfieldListLoaded = false;
    @track searchResultFields = [];
    @track searchInput = '';
    @track showListView = false;
    @track prepareQueryFields = '';
    @track resultFields = [];
    @track isInputDisabled = false;
    @track evisortSalesforceFields ={};
    @track mappingDataTypes;
    @track errorLabel;
    @track selectedLabel;
    @track fieldApiName = '';

    runOnce = 0;
    isEditForm = false;
    label = labels;
    noOfParentObject = 0;
    parentFieldAccessLimit = 5;

    get isDefaultObject() {
        if (this.selectedObjects == this.objectname)
            return false;
        return true;
    }

    get showClose() {
        return this.isDefaultObject || this.searchInput != '';
    }

    /*
     * Initializing the component properties
     *  get evisort support Datatype in Map
    */
    connectedCallback() {
        this.runOnce = 0;
        getMappingDataTypes()
        .then((result)=>{
            this.mappingDataTypes = new Map(Object.entries(result));
        })
        .catch((error) => {
            showToast(this, labels.adminError, getFilteredErrorMessage(error), "ERROR");
        });    

        if(this.evisortMappedFields.salesforceField != null && this.evisortMappedFields.salesforceField != '' && this.evisortMappedFields.salesforceField != undefined){
            if(this.evisortMappedFields.salesforceField.includes('.')){
                    var salesforceFieldName = this.evisortMappedFields.salesforceField.split(/\.(?=[^\.]+$)/);
                    this.selectedObjects = this.objectname+'.'+salesforceFieldName[0];
                    this.fieldApiName = salesforceFieldName[1];
            }else{
                this.selectedObjects = this.objectname;
                this.fieldApiName = this.evisortMappedFields.salesforceField;
            }
            this.isInputDisabled = true;
            this.getObjectFields(this.objectname);
            this.isEditForm = true;
        }
        else{
            this.isEditForm = false;
            this.selectedObjects = this.objectname;
            this.getObjectFields(this.objectname);
        }
    }

    /**
     * Retrieve an array of fields on a Salesforce object,
     * ordered alphabetically descending.
     * @param {String} objectApiName
     */
    async getObjectFields(objectApiName) {
        this.isfieldListLoaded = false;
        this.showListView = false;
        this.salesforceFields = [];

        await getObjectFieldMetaData({objectApiName: objectApiName
            }).then((res) => {
                const sortedFields = res.sort(sortByLabel);
                this.salesforceFields = sortedFields;
            })
            .catch(error => {
                    showToast(this, labels.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(()=>{
                this.noOfParentObject++;
                this.isfieldListLoaded = true;
                if (this.noOfParentObject >= this.parentFieldAccessLimit) {
                    this.salesforceFields.forEach((element) => element.isReference = '');
                }
                this.searchResultFields = this.salesforceFields;
                if (this.isEditForm && this.runOnce == 0){
                    this.runOnce = 1;
                    this.searchInput = this.evisortMappedFields.fieldLabel;
                }
            });  
    }

    /**
     * Parses and event or custom event object to return the dataset key
     * @param {Event} event Change or Custom event
     */
    handleFieldSearch(event) {
        this.isfieldListLoaded = false;
        this.searchInput = event.target.value;

        this.searchFields(event.target.value);
        
        this.isfieldListLoaded = true;
        if (!this.showListView) {
            /* 
            * Setting timeout to make sure the list view is visible
            * in case the parent div's onclick event has occurred 
            * causing the list view to hide
            */
            setTimeout(()=> {
        this.showListView = true;
            }, 5);
        }
    }

    /**
     * Retrieve Relavent fields of input search
     * @param {inputValue} event Change or Custom event
     */

    searchFields(inputValue) {
        if (inputValue != '') {
            this.searchResultFields = [];
            this.salesforceFields.forEach((element)=> {
                if (element.label.toLowerCase().includes(inputValue.toLowerCase()) 
                    && !this.searchResultFields.some(searchResult => searchResult.label === element.label)) {
                        this.searchResultFields.push(element);
                }
            });
            if (this.searchResultFields.length == 0 ) {
                this.searchResultFields.push({label: labels.IntakeFormNoMatchFound, value: '', datatype: '', relationshipName: '', referenceTo: '', isReference: ''});
            }
        }
        else {
            this.searchResultFields = this.salesforceFields;
        }
    }


    /*
     @Description : Input Field Disable
    */
    handleSearchFocus() {
        this.isInputDisabled = false;
    }
    
    /*
     * @Description : Handle search input and Firing the event
    */
    clearSearchField() {
        this.isInputDisabled = false;
        this.noOfParentObject = 0;
        this.selectedObjects = this.objectname;
        this.showListView = false;
        this.searchInput = '';
        this.prepareQueryFields = '';
        this.errorLabel = '';
        this.evisortSalesforceFields.workFlowFieldId = this.evisortMappedFields.documentFieldId;
            this.evisortSalesforceFields.workFlowFieldName = this.evisortMappedFields.label;
            this.evisortSalesforceFields.salesforceField = ''; 
            this.evisortSalesforceFields.fieldLabel = '';
            this.evisortSalesforceFields.SalesforceDataType = '';
            const rowUpdateEvent = new CustomEvent('updatefieldrow', {
                detail: (this.evisortSalesforceFields)
            });
    
        this.dispatchEvent(rowUpdateEvent);
        this.getObjectFields(this.objectname);
    }

    /*
       @Description : Firing the event to update list
    */
    handleFieldSelection(event) {
        this.searchInput = '';
        this.selectedLabel = event.currentTarget.dataset.label;
        let selectedFieldValue = event.currentTarget.dataset.selectedfieldvalue;
        let selectedType = event.currentTarget.dataset.selectedtype;
        let relationshipName = event.currentTarget.dataset.relationshipName;
        let referenceTo = event.currentTarget.dataset.referenceTo;
        if (selectedType != '' && selectedFieldValue != '' && this.selectedLabel != 'No result!') {
            this.isInputDisabled = true;
            if (selectedType == 'REFERENCE' && this.noOfParentObject < this.parentFieldAccessLimit) {
                this.getObjectFields(referenceTo);
                this.prepareQueryFields += relationshipName + '.'
                this.selectedObjects += '.' + referenceTo; 
                this.isInputDisabled = false;
            }
            else {
                this.searchInput = this.selectedLabel;
                this.isInputDisabled = true;
                this.prepareQueryFields += selectedFieldValue;
            }
            this.evisortSalesforceFields.workFlowFieldId = this.evisortMappedFields.documentFieldId;
            this.evisortSalesforceFields.workFlowFieldName = this.evisortMappedFields.label;
            this.evisortSalesforceFields.salesforceField = this.prepareQueryFields;
            this.evisortSalesforceFields.fieldLabel = this.selectedLabel;
            this.evisortSalesforceFields.SalesforceDataType = selectedType;
            const rowUpdateEvent = new CustomEvent('updatefieldrow', {
                detail: (this.evisortSalesforceFields)
            });
    
            this.dispatchEvent(rowUpdateEvent);
        }
    }

    /*
       @Description : Checking validations
    */
    @api checkFieldValidations(){
        let isChildValid = true;
        this.errorLabel = null;
            if(this.evisortSalesforceFields.SalesforceDataType != '' && this.evisortSalesforceFields.SalesforceDataType != null && this.evisortSalesforceFields.SalesforceDataType != undefined && this.evisortMappedFields.evisortFieldDataType != null && this.evisortMappedFields.evisortFieldDataType != '' && this.evisortMappedFields.evisortFieldDataType != undefined && this.evisortSalesforceFields.SalesforceDataType != 'REFERENCE'){
                var salesforceDataType = this.evisortSalesforceFields.SalesforceDataType.toLowerCase();
                if(this.evisortMappedFields.evisortFieldDataType == 'Multi Picklist' || 
                    this.evisortMappedFields.evisortFieldDataType == 'Picklist' || 
                    this.evisortMappedFields.evisortFieldDataType == 'Text'){
                    isChildValid = true;
                    this.errorLabel = null;
                }else{
                    if(this.mappingDataTypes.get(salesforceDataType) != this.evisortMappedFields.evisortFieldDataType){
                        isChildValid = false;
                        this.errorLabel = ' Please Select Valid Field. '+this.selectedLabel+' is Type "'+salesforceDataType+'" And '+this.evisortMappedFields.label+ ' Type is "' + this.evisortMappedFields.evisortFieldDataType +'".' ;
                    }
                }
            }
            
            return isChildValid;
        }

    /*
       @Description : clear input fields and Firing the event
    */
    @api clearAllFields(){
        this.isInputDisabled = false;
        this.noOfParentObject = 0;
        this.selectedObjects = this.objectname;
        this.showListView = false;
        this.searchInput = '';
        this.prepareQueryFields = '';
        this.errorLabel = '';
        this.evisortSalesforceFields.workFlowFieldId = this.evisortMappedFields.documentFieldId;
            this.evisortSalesforceFields.workFlowFieldName = this.evisortMappedFields.label;
            this.evisortSalesforceFields.salesforceField = ''; 
            this.evisortSalesforceFields.fieldLabel = '';
            this.evisortSalesforceFields.SalesforceDataType = '';
            const rowUpdateEvent = new CustomEvent('updatefieldrow', {
                detail: (this.evisortSalesforceFields)
            });

            this.dispatchEvent(rowUpdateEvent);
            this.getObjectFields(this.objectname);
    }
    
    /*
       @Description : Hides list box on the click of parent component
    */
       @api hideListView () {
        this.showListView = false;
    }
}