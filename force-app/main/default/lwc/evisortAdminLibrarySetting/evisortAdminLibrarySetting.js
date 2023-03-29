import { LightningElement,api, track } from 'lwc';
import { showToast, getFilteredErrorMessage } from "c/csUtils";
import labels from "c/labelService";

export default class EvisortAdminLibrarySetting extends LightningElement {
    @api itemFromParent = {};
    @api index;

    label = labels;
    @track item = {};

    @api 
    init(){ 
        this.item = Object.assign({}, this.itemFromParent);
    }

    /**
     * Initializing the component properties
    */
    connectedCallback(){
        this.init();
    }
    
    /**
     * fire event to the Admin Export component with validation check
    */
    calculateLibraryRow(){
        var isChildVaild = true;
        this.template
        .querySelectorAll("c-evisort-filter-criteria-section")
        .forEach(element => {
            if (element.checkValidations() === false) {
                isChildVaild = false;
            }
        });
        if(isChildVaild){
            var detailObj = { item: this.item, index: this.index };
            const calculateLibraryRow = new CustomEvent('calculatelibraryrow', {
                detail: detailObj
            });
            // Dispatches the event.
            this.dispatchEvent(calculateLibraryRow);
        }

    }

     /**
     * Remove library, effectively removing them
     * @param {Event} event
     */
    removeLibrary(){
        var detailObj = { item: this.item, index: this.index };
        const removeLibraryItem = new CustomEvent('removelibraryitem', {
            detail: detailObj
        });
        // Dispatches the event.
        this.dispatchEvent(removeLibraryItem);
    }

    /**
     * Updates an library in the object with a specific value 
     * @param {String} type
     * @param {Object} value
     */
    updatelibrarySelectedValues(type, value) {
        if (this.index > -1) {
            if (type === "objectLabel") {
                this.item.objectLabel = value;
            }else if(type === "fileFilterBody"){
                this.item.fileFilterBody = value;
            }else if(type === "showlibrarySection"){
                this.item.showlibrarySection = value;
            }else if (type === "calculateDisabled") {
                this.item.calculateDisabled = value;
            }else if(type === "enableLibraryFilter"){
                this.item.enableLibraryFilter = value;
            }else if(type === "enableAddExport"){
                this.item.enableAddExport = value;
            }

            var detailObj = { item: this.item, index: this.index };
            const rowUpdateEvent = new CustomEvent('updateitem', {
                detail: detailObj
            });
    
            this.dispatchEvent(rowUpdateEvent);
        }
    }

    /**
     * Fires when the File Filter Name has a selection
     * @param {Event} event
     */
    handleLibraryFileUpdatedRow(event){
        this.updatelibrarySelectedValues("fileFilterBody", JSON.stringify(event.detail));
    }

    /**
     * Fires when the Library Name has a selection
     * @param {Event} event
     */
    handlelibraryChange(event){
        let libraryValue = event.detail.libraryValue;
        this.updatelibrarySelectedValues("objectLabel", libraryValue);
        this.updatelibrarySelectedValues("calculateDisabled",  false);
        this.updatelibrarySelectedValues("showlibrarySection",  true);
        this.updatelibrarySelectedValues("enableLibraryFilter",  true);   
        this.updatelibrarySelectedValues("enableAddExport", true);     
    }

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
            let selectLibrary = this.template.querySelector("c-evisort-select-library-option");
            if(!selectLibrary.checkValidations()) {
                isChildComponentValid = false;
            }
        } catch (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");

        }
        return isChildComponentValid;
    }
}