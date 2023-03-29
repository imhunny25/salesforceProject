import { LightningElement, track,api } from "lwc";
import labels from "c/labelService";
import { getFilteredErrorMessage } from "c/csUtils";
import getFieldDefinitions from "@salesforce/apex/AdminController.getFieldDefinitions";
import getObjects from "@salesforce/apex/IntakeFormController.getObjects";
import { showToast, sortByLabel } from "c/csUtils";

const INTAKE_FORM = {
    ObjectName:null,
    isLegacy:null,
    mappings: []
};

export default class SObjectFieldMappingForm extends LightningElement {
    @api mappedRecord = [];

    @track objectname;
    @track isLegacy = true;
    @track fieldData = '';
    @track evisortFields = {};
    @track showMappings = true;
    @track fieldLoaded;
    @track isLoadedSobject = false;
    @track sObjects;
    @track objectSelected = false;
    @track objectLoaded = true;

    label = labels;

    /**
     * Initializing the component properties
    */
    async connectedCallback() {
        await getObjects()
        .then((res) => {
            this.sObjects = res.sort(sortByLabel);
            this.isLoaded = true;
            this.objectLoaded = false;
        })
        .catch((error) => {
            showToast(this, labels.adminError, getFilteredErrorMessage(error), "ERROR");
        });
        this.fieldLoaded = true;
        this.activeItem = { ...INTAKE_FORM };
        this.activeItem.ObjectName = this.objectname;
        this.activeItem.isLegacy = this.isLegacy;
        this.getDocumentFieldMapping();
    }

    /**
     * Processing prepopulate records
     */
    getDocumentFieldMapping(){
        let result = JSON.parse(JSON.stringify(this.mappedRecord));
        if (result != null && result != '' && result != undefined) {
            let fields = [];
            this.evisortFields = {};
            
            result.forEach(data => {
                this.objectname = data.objectName;
                let field = {
                    id: data.id,
                    documentFieldId: data.evisortDocumentFieldId,
                    name: data.name,
                    label: data.evisortDocumentFieldName,
                    salesforceField: data.salesforceFieldName,
                    fieldLabel: data.fieldLabel,
                    ObjectName: data.objectName,
                    evisortFieldDataType :data.evisortFieldDataType,
                    SalesforceDataType:''
                };
                fields.push(field);
                this.activeItem.ObjectName = data.objectName;
            });
            this.evisortFields.data = fields;
            this.activeItem.mappings = fields;
            this.activeItem.newRecord = false;   
            this.isLoadedSobject = true;
            this.fieldLoaded = false;
            
            this.objectSelected = true;
        }else{
            this.isLoadedSobject = true;
            this.fieldLoaded = false;
            
        }
    }
    /**
     * Adds a new blank record of object and evisort fields 
     * Firing the event of blank record  
     */
    loadFields(){
      getFieldDefinitions({ fieldType: "Field"})
            .then( (result) => {
            if (result !=null && result != '') {
                if(result.length >= 0){
                    this.showMappings = true;
                    let parsed = JSON.parse(JSON.stringify(result));
                    let fields = [];
                    parsed.forEach((fieldData) => {
                            let field = {
                                id: '',
                                documentFieldId: fieldData.id,
                                name: fieldData.name,
                                label: fieldData.label,
                                fieldType: fieldData.fieldType,
                                dataType: fieldData.dataType,
                                isActive: fieldData.isActive,
                                documentFieldMappingId:'',
                                evisortFieldDataType: fieldData.dataType,
                                salesforceField:'',
                                fieldLabel: '',
                                SalesforceDataType:''
                            };
                            fields.push(field);
                        });
                        this.evisortFields.data = fields;
                        this.evisortFields.newRecord = true;
                        this.activeItem.mappings = fields;
                        this.activeItem.newRecord = true;
                        this.fieldData = result.data;
                        this.isLoadedSobject = true;
                        const rowUpdateEvent = new CustomEvent('updatefieldrow', {
                            detail: (this.activeItem)
                        });
                        this.dispatchEvent(rowUpdateEvent);
                    }else{
                        this.isLoadedSobject = true;
                        this.showMappings = false;
                    } 
                }
        })
    } 

    /**
     * Retrieve an array of fields on a Salesforce object,
     * ordered alphabetically descending.
     * @param {Event} evt Change event
     */
    handleUpdateFieldRow(event){
        let mappedFields = event.detail;
        this.activeItem.mappings.forEach((mapping) =>{   
        if(mapping.label == mappedFields.workFlowFieldName){
                mapping.salesforceField = mappedFields.salesforceField;
                mapping.fieldLabel = mappedFields.fieldLabel;
                mapping.SalesforceDataType = mappedFields.SalesforceDataType;
            }
        });
        const rowUpdateEvent = new CustomEvent('updatefieldrow', {
            detail: (this.activeItem)
        });
        this.dispatchEvent(rowUpdateEvent);
    }

    /**
     * Handle Salesforce object
     */
    handleObjectChange(event){
        this.isLoadedSobject = false;
        this.objectname = event.detail.value;
        this.activeItem = { ...INTAKE_FORM };
        this.activeItem.ObjectName = this.objectname;
        this.activeItem.isLegacy = true;
        this.loadFields();
    }
    /*
        @Description : Checking validations
    */
    @api checkValidations() {
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
            return allValid;
    }

    /*
        @Description : Checking validations
    */
    @api checkFieldValidations(){
        var rows = [...this.template.querySelectorAll("c-s-object-fields")];
        var isChildComponentValid = true;
            for(var index in rows){
                var row = rows[index];
                if(!row.checkFieldValidations()){
                    isChildComponentValid = false;
                }
        }
        return isChildComponentValid;
    }

    /**
     * Handle to reset All
     */
    reset(){
        var rows = [...this.template.querySelectorAll("c-s-object-fields")];
            for(var index in rows){
                var row = rows[index];
                row.clearAllFields();
        }
    }
     /**
     @Description : Hides child List Boxes on the click of this component or the parent component
     */
     @api handleListViewHide () {
        var rows = [...this.template.querySelectorAll("c-s-object-fields")];
        for(var index in rows){
            var row = rows[index];
            row.hideListView();
        }
    }
}