import { LightningElement,track, api, wire } from 'lwc';
import labels from "c/labelService";
import getObjectListWithLabel from "@salesforce/apex/ExportController.getObjectListWithLabel";
import getContentVersionAssociatedField from "@salesforce/apex/ExportController.getContentVersionAssociatedField";
import { showToast, getFilteredErrorMessage, isBlank} from "c/csUtils";


export default class EvisortAdminObjectSetting extends LightningElement {
    label = labels;
    @track item = {};
    @api itemFromParent = {};
    @track filteredList = [];
    @api index;
    @track objectList = [];
    @track fieldsOption = [];
    @track selectLibrary;
    @track selectAssociatedField;
    @track objectLabel = '';
    @track libraryMapping = {
        sObjectName :'',
        isLibraryObjectCheck :false,
        libraryName:'',
        customField:''
    };
    @track objectLibraryData = {};
    @track tempCustomFieldArray;
    @track isShowSpinner = true;
    @api
    init(){
        this.item = Object.assign({}, this.itemFromParent);
    } 

    /**
     * Initializing the component properties
    */
    connectedCallback(){  
        this.init();
        this.loadObjectList();
        if(this.item.libraryMapping != null && this.item.libraryMapping != '' && this.item.libraryMapping != undefined){           
            this.objectLibraryData = JSON.parse(this.item.libraryMapping);

            this.libraryMapping.sObjectName = this.item.objectLabel;
            this.libraryMapping.isLibraryObjectCheck = this.objectLibraryData.isLibraryObjectCheck;
            this.libraryMapping.libraryName = this.objectLibraryData.libraryName;
            this.libraryMapping.customField = this.objectLibraryData.customField;
            this.selectLibrary = this.objectLibraryData.isLibraryObjectCheck;
            this.selectAssociatedField = this.objectLibraryData.customField;
        }
        if(!isBlank(this.item.objectLabel)){
            this.contentReferenceFields(this.item.objectLabel);
        }
    }

    async loadObjectList(){
        await getObjectListWithLabel()
        .then((result) => {
            if (result) {
                this.objectList = result['objectsName'];
                this.isShowSpinner = false;
                for(let i = 0; i < this.objectList.length; i++) {
                    let Obj = JSON.parse(this.objectList[i]);
                    if(Obj.value == this.item.objectLabel){
                        this.objectLabel = Obj.label;
                    }
                }
            } else if (error) {
                this.isShowSpinner = false;
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            }
        });
    }

    /**
    * For the object selection dropdown
    * @param {Event} event
    */
    searchObjects(event) {
        this.objectLabel='';
        this.clearObjectAndFileFilterData();
        const searchText = event.target.value.toLowerCase();
        if (searchText.length >= 3) {
            this.filteredList = [];
            for (let i = 0; i < this.objectList.length; i++) {
                let Obj = JSON.parse(this.objectList[i]);
                if (Obj.label.toLowerCase().indexOf(searchText) >= 0) {
                    this.filteredList.push(Obj);
                }
            }
            if (this.filteredList.length !== 0) {
                this.updateSelectedValues("showdropdown", true);
            }
        }else{
            this.updateSelectedValues("isEnableObjFileFilterSection", false);
        }
    }

    /**
    * Updates an object in the array with a specific value based on its element id
    * @param {String} type
    * @param {Object} value
    */
    updateSelectedValues(type, value) {
        if (this.index > -1) {
            if (type === "objectLabel") {
                this.item.objectLabel = value;
            } else if (type === "isEnableObjFileFilterSection") {
                this.item.isEnableObjFileFilterSection = value;
            } else if (type === "showdropdown") {
                this.item.showdropdown = value;
            } else if (type === "calculateDisabled") {
                this.item.calculateDisabled = value;
            }else if(type === "objectFilterBody"){
                this.item.objectFilterBody = value;
            }else if(type === "fileFilterBody"){
                this.item.fileFilterBody = value;
            }else if(type === "enableAddExport"){
                this.item.enableAddExport = value;
            }else if(type === "libraryMapping"){
                this.item.libraryMapping = value;
            }

            var detailObj = { item: this.item, index: this.index };
            const rowUpdateEvent = new CustomEvent('updateitem', {
                detail: detailObj
            });
    
            this.dispatchEvent(rowUpdateEvent);
        }
    }


    /**
     * Handles the selection of an Object from the dropdown
     */
    handleSelect() {
        let selectedobj;
        this.objectLibraryData = {};
        this.selectLibrary = false;
        this.template.querySelectorAll("c-picklist-value").forEach((element) => {
            if (element.selected) {
                selectedobj = element.value;
                this.objectLabel = element.label;
            }
        });
        this.contentReferenceFields(selectedobj)
        this.libraryMapping.sObjectName = selectedobj;
        this.updateSelectedValues("showdropdown", false);
        this.updateSelectedValues("objectLabel", selectedobj);
        this.updateSelectedValues("calculateDisabled", false);
        this.updateSelectedValues("isEnableObjFileFilterSection", true);
        this.updateSelectedValues("enableAddExport", true);
        this.updateSelectedValues("libraryMapping", JSON.stringify(this.libraryMapping));
        this.filteredList = [];
    }

    contentReferenceFields(selectedobj){
        getContentVersionAssociatedField({objectName: selectedobj})
        .then((result) => {
            this.tempCustomFieldArray = [];
            let customFieldArray = [];
            result['fields'].forEach(ele => {
            let associatedField = JSON.parse(ele);
            this.tempCustomFieldArray.push({label: associatedField.label, value: associatedField.value , isSelected: false});   
        });
        this.tempCustomFieldArray.forEach(ele => {
            if(ele.value == this.objectLibraryData.customField){
                customFieldArray.push({label: ele.label, value: ele.value, isSelected: true});
            }else{
                customFieldArray.push({label: ele.label, value: ele.value, isSelected: false});
            }
        });
        this.fieldsOption = [...customFieldArray];
    });
    }

    /**
     * Handles the selection of an object filter dropdown
     * @param {Event} event
     */
    handleObjectUpdatedRow(event){
        this.updateSelectedValues("objectFilterBody", JSON.stringify(event.detail));
    }

    /**
     * Handles the selection of an file filter dropdown
     * @param {Event} event
     */
    handleFileUpdatedRow(event){
        this.updateSelectedValues("fileFilterBody", JSON.stringify(event.detail));
    }

    /**
     * Fire event to Admin Export Component with validation check
     */
    calculateRow(){    
        var isChildVaild = true;
        this.template
        .querySelectorAll("c-evisort-filter-criteria-section")
        .forEach(element => {
            if (element.checkValidations() === false) {
                isChildVaild = false;
            }
        });
        isChildVaild = this.checkValidations()
        if(isChildVaild){
            var detailObj = { item: this.item, index: this.index };
                const addObjectItem = new CustomEvent('addobjectitem', {
                    detail: detailObj
                });
        
            this.dispatchEvent(addObjectItem);
        }
    }

    /**
     * Remove Row, effectively removing them
     */
    resetRow(){
        var detailObj = { item: this.item, index: this.index };
        const removeObjectItem = new CustomEvent('removeobjectitem', {
            detail: detailObj
        });

        this.dispatchEvent(removeObjectItem);
    }

    /**
     * Validation check
     */
    @api checkValidations() {
        var rows = [...this.template.querySelectorAll("c-evisort-filter-criteria-section")];
        var isChildComponentValid = true;
        try {
            for(var index in rows){
                var row = rows[index];
                if(!row.checkValidations()){
                    isChildComponentValid = false;
                }
            }
            if(this.selectLibrary == true){
                let fields = [...this.template.querySelectorAll("[data-field]")];
                fields.forEach((field) => {
                        // Trim whitespace before validating.
                        if (this.selectAssociatedField == null || this.selectAssociatedField == '' || this.selectAssociatedField == undefined) {
                            isChildComponentValid = this.checkValidationForInputFields('.fieldNameComp', 'Field Required', this.selectAssociatedField);
                        }
                });
            }
            if(this.selectLibrary == true){
                let libraryValidation = [...this.template.querySelectorAll("c-evisort-select-library-option")];
                libraryValidation.forEach((element) => {
                    if (element.checkValidations() === false ) {
                        isChildComponentValid = false;
                    }
                });
            }

        } catch (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
        return isChildComponentValid;
    }  
    
    checkValidationForInputFields(className, message, value){
        let inputCmp = this.template.querySelector(className);
        var isValid = true;
        if (value == null || value == '' || value == undefined) {
          isValid = false;
          inputCmp.setCustomValidity(message);
        } else {
          inputCmp.setCustomValidity("");
        }
        inputCmp.reportValidity();
    
        return isValid;
      }

    handleSelectLibraryOnObject(event) {
        this.selectLibrary = event.target.checked;
        this.libraryMapping.sObjectName = this.item.objectLabel;
        if(this.selectLibrary == false){
            this.libraryMapping = {};
            this.objectLibraryData.libraryName = '';
            this.selectAssociatedField = '';
            this.fieldsOption = [...this.tempCustomFieldArray];
        }
        this.libraryMapping.isLibraryObjectCheck = this.selectLibrary;
        this.updateSelectedValues("libraryMapping", JSON.stringify(this.libraryMapping));
    }

    handlelibraryChange(event){
        this.libraryMapping.libraryName = event.detail.libraryValue;
        this.updateSelectedValues("libraryMapping", JSON.stringify(this.libraryMapping));
    }

    customFiledHandleChange(event){
        this.selectAssociatedField = event.currentTarget.value;
        this.libraryMapping.customField = this.selectAssociatedField;
        this.updateSelectedValues("libraryMapping", JSON.stringify(this.libraryMapping));
    }

    handleClear(event) {
        if (!event.target.value.length) {
            this.clearObjectAndFileFilterData();
        }
    }

    clearObjectAndFileFilterData(){
        this.updateSelectedValues("isEnableObjFileFilterSection", false);
        this.updateSelectedValues("objectFilterBody", null);
        this.updateSelectedValues("fileFilterBody", null);
        this.libraryMapping = {
            sObjectName :'',
            isLibraryObjectCheck :false,
            libraryName:'',
            customField:''
        };
        this.updateSelectedValues("libraryMapping", this.libraryMapping); 
    }
}