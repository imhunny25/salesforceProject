import { LightningElement, api, track} from 'lwc';
import getLibraryOptionList from "@salesforce/apex/AdminController.getLibraryOptionList";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage, isBlank } from "c/csUtils";

export default class EvisortSelectLibraryOption extends LightningElement {
    @track libraryOptions = [];
    @api objectLabel;
    @api itemId;
    @api isDisable;

    label = labels;
    
    connectedCallback(){
        this.getLibraryInfo();
        this.checkValidationsLibraryName = this.objectLabel;
    }

    getLibraryInfo(){
         getLibraryOptionList()
        .then(result => {
                let libraryValArray = [];
                let tempLibraryValArray = [];
                for (var i = 0; i < result.length; i++) {
                    libraryValArray.push({label: result[i].Name, value: result[i].Id, isSelected: false});
                } 

                libraryValArray.forEach(ele => {
                    if(ele.value == this.objectLabel){
                        tempLibraryValArray.push({label: ele.label, value: ele.value, isSelected: true});
                    }else{
                        tempLibraryValArray.push({label: ele.label, value: ele.value, isSelected: false});
                    }
                })
                this.libraryOptions = [...tempLibraryValArray];  
        });
    }

    @track checkValidationsLibraryName;
    libraryHandleChange(event){
        let value = event.currentTarget.value;
        this.checkValidationsLibraryName = value;
        // Creates the event with the data.
        const selectedEvent = new CustomEvent("libraryvaluechange", {
            detail: { libraryValue : value
            }
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    @api checkValidations() {
        var isChildComponentValid = true;
        try {
            if(this.checkValidationsLibraryName == null || this.checkValidationsLibraryName == '' || this.checkValidationsLibraryName == undefined){
                isChildComponentValid = this.checkValidationForInputFields('.fieldNameComp', 'Field Required', this.checkValidationsLibraryName);;
            }
        }catch (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
        return isChildComponentValid;
    }

    checkValidationForInputFields(className, message, value){
        let inputCmp = this.template.querySelector(className);
        var isValid = true;
        if (isBlank(value)) {
          isValid = false;
          inputCmp.setCustomValidity(message);
        } else {
          inputCmp.setCustomValidity("");
        }
        inputCmp.reportValidity();
    
        return isValid;
      }
}