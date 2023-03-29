import { LightningElement, api, track } from 'lwc';
import getRecordTypes from "@salesforce/apex/AdminController.getRecordTypes";
import { showToast, getFilteredErrorMessage, isBlank } from "c/csUtils";
import labels from "c/labelService";

export default class EvisortFilterCriteriaRow extends LightningElement {
    @api fieldsWrappers;
    @api index;
    @track isShowRow = true;
    @api sobjectName;
    @api rowDisable;

    label = labels;

    @track fieldName;
    @track filterFieldsToDisplay;
    @track operator;
    @track indexToShow;
    @track showLabel;
    @api rowFromParent = {};
    @track row = {};
    @track picklistOptions = [];
    @track fieldNameWithFieldWrapperObjMap = new Map();
    @track showDependent = false;
    @track showTextBox = false;
    @track showDate = false;
    @track showDateTime = false;
    @track showCheckbox = false;
    @track showPicklist = false;
    @track showNumber = false;
    @track showFormula = false;
    @track showMultiPicklist = false;
    @track selectedFieldName;
    @track deleteDisableButton = true;
    @track operatorCheck = false;
    @track UPDATE_ROW = 'updaterow';
    @track ADD_ROW = 'addrow';
    @track DELETE_ROW = 'deleterow';
    @track fieldTypeWithLabelValueMap = new Map();
    @track runOnceField = false;
    @track runOnceoperator = false;
    @track runOnceValue = false;
    @track text;
    @track multiPickListValue;
    @track runOncePickList = false;
    @track isShowFields = true;
    @track recordTypes = [];
    @track picklistOption=[];
    @track multiselectEnable = false;
    @track showValuePlaceHolder = this.label.AdminFilterEnterValue;

    @track operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
    { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
    { label: this.label.AdminFilterOperatorContains, value: 'Contains' },
    { label: this.label.AdminFilterOperatorNotContains, value: 'Not Contains' }];

    @track conditionsToShow = [{ label: this.label.AdminFilterOperatorAnd, value: 'AND' },
    { label: this.label.AdminFilterOperatorOr, value: 'OR' },
    { label: this.label.AdminFilterOperatorNone, value: '' }];

    @track booleanOptionsToShow = [{ label: this.label.AdminFilterOperatorTrue, value: 'True' },
    { label: this.label.AdminFilterOperatorFalse, value: 'False' }];


    /*
        @Description : Enabling and disabling the operators according to the conditions
    */
    get isoperatorDisabled() {
        if(!this.rowDisable)
            return !this.operatorCheck;
        return true;
    }

    /*
        @Description : Enabling and disabling the Delete according to the conditions
    */
    get isDeleteDisableButton() {
        if (this.index == 0) {
            return true;
        }
        return false;
    }

    fetchRecordTypes() {
        getRecordTypes({ obj: this.sobjectName })
            .then((result) => {
                if(result != null && result != undefined){
                    this.multiselectEnable = true;
                    this.picklistOption = result;
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            });
    }

    /*
        @Description : Initializing the component properties
    */
    connectedCallback() {
        try {
            this.fetchRecordTypes();
            this.indexToShow = this.index + 1;
            if (this.indexToShow == 1) {
                this.showLabel = true;
            }
            this.row = Object.assign({}, this.rowFromParent);
            this.filterFieldsToDisplay = [];

            for (var idx in this.fieldsWrappers) {
                var fieldObj = this.fieldsWrappers[idx];

                if (fieldObj.isFieldFilterable && fieldObj.isFieldAccessible) {
                    this.filterFieldsToDisplay.push({ label: fieldObj.fieldLabel, value: fieldObj.fieldName });
                    this.fieldNameWithFieldWrapperObjMap.set(fieldObj.fieldName, fieldObj);
                }
            }
            
            this.prepareFieldTypeWithLabelValueMap();
            this.chooseOperators();
            
        } catch (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }  
    }

    /*
        @Description : Filling the Data in the Criteria Row 
    */
    renderedCallback(){
        this.isShowFields = true;
        if(this.row.operator != undefined && this.selectedFieldName != undefined && this.runOnceField && !this.runOnceoperator){
            this.template.querySelectorAll('.operatorClass').forEach( operatorObj => {
                if(operatorObj.value == this.row.operator){
                    operatorObj.selected= true;
                    this.runOnceoperator =true;
                    if (this.row.fieldType == 'PICKLIST') {
                        this.runOncePickList = true;
                    }else if(this.row.fieldType == 'MULTIPICKLIST'){
                        const recordtypeValue = this.row.value;
                        if(recordtypeValue === undefined || recordtypeValue === ''){
                            this.recordTypes = [];
                        }else{
                            this.recordTypes = recordtypeValue.split(',');
                        }
                    }else{
                        this.text = this.row.value;
                    }
                }
            });
        }

        if(this.row.value != undefined && this.selectedFieldName != undefined && this.runOncePickList){
            this.template.querySelectorAll('.picklistOptionClass').forEach( selectObj => {
                if(selectObj.value == this.row.value){
                    selectObj.selected= true;
                }
            })
        }

        if(this.row.fieldName != undefined && this.selectedFieldName == undefined && !this.runOnceField){
            this.template.querySelectorAll('.selectField').forEach( selectObj => {
                if(selectObj.value == this.row.fieldName){
                    this.runOnceField= true;
                    selectObj.selected= true;
                    this.selectedFieldName = selectObj.value;
                    this.operatorCheck = true;
                    try {
                        var fielddetailObj = Object.assign({}, this.fieldNameWithFieldWrapperObjMap.get(this.selectedFieldName));

                        this.row.fieldType = fielddetailObj.fieldType == 'FORMULA' ? fielddetailObj.formulaFieldType : fielddetailObj.fieldType;
                        this.row.fieldTypeLabel = this.fieldTypeWithLabelValueMap.has(this.row.fieldType) ? this.fieldTypeWithLabelValueMap.get(this.row.fieldType) : this.row.fieldType;
                        this.row.fieldSOAPType = fielddetailObj.fieldSOAPType;
                        this.row.fieldLabel = fielddetailObj.fieldLabelStandard;
                        this.row.formulaFieldType = fielddetailObj.formulaFieldType;
                        this.row.fieldName = this.selectedFieldName;
                        this.row.indexToShow = this.indexToShow;
                        
                        if (this.row.fieldType == 'PICKLIST' || this.row.fieldType == 'MULTIPICKLIST') {
                            this.picklistOptions = fielddetailObj.optionsWrapper;

                        }
                        this.chooseOperators();
                    } catch (error) {
                        showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
                    }
                }
            });
        }

        if(this.showPicklist && this.row.value != undefined && this.selectedFieldName != undefined && this.runOnceField){
            this.template.querySelectorAll('.picklistOptionClass').forEach( opObj => {
                if(opObj.value == this.row.value){
                    opObj.selected= true;
                }
            });
        }
    }

    /*
        @Description : Preparing the map of fields with label to show 
    */
    prepareFieldTypeWithLabelValueMap() {
        this.fieldTypeWithLabelValueMap.set('REFERENCE', 'ID');
    }

    /*
        @Description : updating the data for the multiselect
    */
    handleOnItemSelected(event) {
        try {

            var yourSelectedValues = '';
            var self = this;

            if (event.detail) {
                yourSelectedValues = '';
                event.detail.forEach(function (eachItem) {
                    yourSelectedValues += eachItem + ',';   
                });

                yourSelectedValues = yourSelectedValues.length > 0 ? yourSelectedValues.slice(0, -1) : yourSelectedValues;
            }
            this.row.value = yourSelectedValues;
            this.fireUpdateRowEvent(this.UPDATE_ROW);
        } catch (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");

        }

    }

    
    /*
        @Description : Calling when picklist values got change
    */
    handlePicklistValueChange(event) {
        
        if(this.row.fieldType == 'PICKLIST'){
            this.row.value = event.currentTarget.value;
            
            for(var idx in this.picklistOptions){
                if(this.picklistOptions[idx].value == this.row.value){
                    this.row.labelValue = this.picklistOptions[idx].label;
                    break;
                }
            }
            
            this.row.isPicklist = true;

        }else{
            this.row.isPicklist = false;
            this.row.value = event.currentTarget.value;
        }
        this.fireUpdateRowEvent(this.UPDATE_ROW);
    }

    /*
        @Description : Calling when input field values got change
    */
    handleStringChange(event) {
        this.row.value = event.currentTarget.value;
        this.fireUpdateRowEvent(this.UPDATE_ROW); 
    }

    /*
        @Description : Calling when operator values got change
    */
    handleOperatorChange(event) {
        this.row.operator = event.currentTarget.value;
        
        if(this.row.operator == 'IN'){
            this.showValuePlaceHolder = this.label.AdminFilterRecordTypeValue;
        }else{
            this.showValuePlaceHolder = this.label.AdminFilterEnterValue; 
        }
        this.fireUpdateRowEvent(this.UPDATE_ROW);
    }

    /*
        @Description : Calling when fields Names got change and intializing the details according to field name
    */
    handleFilterFieldsChange(event) {
        this.showValuePlaceHolder = this.label.AdminFilterEnterValue;
        this.isShowFields = false;
        this.row.isPicklist = false;
        this.selectedFieldName = event.currentTarget.value;
        
        
        if(!isBlank(this.selectedFieldName)){
            this.operatorCheck = true;

            try {
                var fielddetailObj = Object.assign({}, this.fieldNameWithFieldWrapperObjMap.get(this.selectedFieldName));
    
                this.row.fieldType = fielddetailObj.fieldType == 'FORMULA' ? fielddetailObj.formulaFieldType : fielddetailObj.fieldType;
                this.row.fieldTypeLabel = this.fieldTypeWithLabelValueMap.has(this.row.fieldType) ? this.fieldTypeWithLabelValueMap.get(this.row.fieldType) : this.row.fieldType;
                this.row.fieldSOAPType = fielddetailObj.fieldSOAPType;
                this.row.fieldLabel = fielddetailObj.fieldLabelStandard;
                this.row.formulaFieldType = fielddetailObj.formulaFieldType;
                this.row.fieldName = this.selectedFieldName;
                this.row.sequence = this.indexToShow;
                this.row.value = '';
                this.row.operator = '';
                this.text = '';
                
                if (this.row.fieldType == 'PICKLIST' || this.row.fieldType == 'MULTIPICKLIST') {

                    this.picklistOptions = fielddetailObj.optionsWrapper;
                }
                this.chooseOperators();
                this.fireUpdateRowEvent(this.UPDATE_ROW);
            } catch (error) {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            }

        }else{
            this.operatorCheck = false;
            this.clearRowDetails();
        }
    
    }

    clearRowDetails(){
        this.row.fieldType = '';
        this.row.fieldTypeLabel = '';
        this.row.fieldSOAPType = '';
        this.row.fieldLabel = '';
        this.row.formulaFieldType = '';
        this.row.fieldName = '';
        this.row.sequence = this.indexToShow;
        this.row.value = '';
        this.multipicklistvalue = '';
        this.text = null;

        this.showTextBox = true;
        this.showDate =false;
        this.showMultiPicklist = false;
        this.showDateTime = false;
        this.showCheckbox= false;
        this.showPicklist = false;
        this.showNumber = false;
        this.showFormula = false;
        this.showReference = false;
    }

    clearValues(className, defaultValue){
        try {
          var select = this.template.querySelectorAll(className);
          var length = select.length;
          for (var i = length-1; i >= 0; i--) {
            select[i].value = defaultValue;
          } 
        } catch (error) {
          showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
         
    }

    /*
        @Description : Setting properties to show the input section and operators according to the field type 
    */
    chooseOperators() {
        
        this.deSelectAllInputFields();    
        
        if (this.row.fieldType == 'PICKLIST') {
            this.showPicklist = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' }];

        } else if (this.row.fieldType == 'MULTIPICKLIST' ) {
            this.showMultiPicklist = true;
            if( this.row.fieldName == 'RecordType.Name'){
                this.operatorsToShow = [{ label: this.label.AdminFilterOperatorIn, value: 'IN'}];
            }else{
                this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
                { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
                { label: this.label.AdminFilterOperatorContains, value: 'Contains' },
                { label: this.label.AdminFilterOperatorNotContains, value: 'Not Contains' },
                { label: this.label.AdminFilterOperatorIn, value: 'IN'}];
            }
        } else if (this.row.fieldType == 'BOOLEAN') {
            this.showCheckbox = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' }];

        } else if (this.row.fieldType == 'FORMULA') {
            this.showFormula = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' }];

        } else if (this.row.fieldType == 'REFERENCE' || this.row.fieldType == 'ID') {
            this.showReference = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' }];
     
        } else if (this.row.fieldType == 'INTEGER' || this.row.fieldType == 'CURRENCY' || this.row.fieldType == 'NUMBER' || this.row.fieldType == 'PERCENT' ||  this.row.fieldType == 'DOUBLE') {
            this.showNumber = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
            { label: this.label.AdminFilterOperatorLessThan, value: 'Less Than' },
            { label: this.label.AdminFilterOperatorGreaterThan, value: 'Greater Than' },
            { label: this.label.AdminFilterOperatorLessThanEqualsTo, value: 'Less Than Equals To' },
            { label: this.label.AdminFilterOperatorGreaterThanEqualsTo, value: 'Greater Than Equals To' }];

        } else if (this.row.fieldType == 'DATE' || this.row.fieldType == 'DATETIME' || this.row.fieldType == 'TIME') {
            this.showDate = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
            { label: this.label.AdminFilterOperatorLessThan, value: 'Less Than' },
            { label: this.label.AdminFilterOperatorGreaterThan, value: 'Greater Than' },
            { label: this.label.AdminFilterOperatorLessThanEqualsTo, value: 'Less Than Equals To' },
            { label: this.label.AdminFilterOperatorGreaterThanEqualsTo, value: 'Greater Than Equals To' }];

        } else if (this.row.fieldType == 'DATETIME') {
            this.showDateTime = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
            { label: this.label.AdminFilterOperatorLessThan, value: 'Less Than' },
            { label: this.label.AdminFilterOperatorGreaterThan, value: 'Greater Than' },
            { label: this.label.AdminFilterOperatorLessThanEqualsTo, value: 'Less Than Equals To' },
            { label: this.label.AdminFilterOperatorGreaterThanEqualsTo, value: 'Greater Than Equals To' }];

        } else if (this.sobjectName = 'ContentVersion' && this.row.fieldName == 'FileExtension' ){
            this.showTextBox = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorStartWith, value: 'Start With' },
            { label: this.label.AdminFilterOperatorEndWith, value: 'End With' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
            { label: this.label.AdminFilterOperatorContains, value: 'Contains' },
            { label: this.label.AdminFilterOperatorNotContains, value: 'Not Contains' },
            { label: this.label.AdminFilterOperatorIn, value: 'IN'}];

        }
        else {
            this.showTextBox = true;
            this.operatorsToShow = [{ label: this.label.AdminFilterOperatorEqual, value: 'Equals' },
            { label: this.label.AdminFilterOperatorStartWith, value: 'Start With' },
            { label: this.label.AdminFilterOperatorEndWith, value: 'End With' },
            { label: this.label.AdminFilterOperatorNotEqualsTo, value: 'Not Equals To' },
            { label: this.label.AdminFilterOperatorContains, value: 'Contains' },
            { label: this.label.AdminFilterOperatorNotContains, value: 'Not Contains' }];

        }
    }

    /*
        @Description : reseting all input fields sections
    */
    deSelectAllInputFields(row) {
        this.showTextBox = false;
        this.showReference = false;
        this.showFormula = false;
        this.showMultiPicklist = false;
        this.showPicklist = false;
        this.showNumber = false;
        this.showDate = false;
        this.showDateTime = false;
        this.showCheckbox = false;
        this.showDependent = false;
        this.operatorsToShow = [];
    }

    /*
        @Description : Calling Delete row event
    */
    handleDeleteRow() {
        this.fireUpdateRowEvent(this.DELETE_ROW);
    }

    /*
        @Description : Calling add row event
    */
    handleAddMore() {
        this.fireUpdateRowEvent(this.ADD_ROW);
    }

    /*
        @Description : Firing the event to update criteria list
    */
    fireUpdateRowEvent(operation) { 
        var detailObj = { row: this.row, index: this.index, operation: operation };
        const rowUpdateEvent = new CustomEvent('updaterow', {
            detail: detailObj
        });

        this.dispatchEvent(rowUpdateEvent);
    }

    /*
        @Description : Checking validations
    */
    @api checkValidations() {

        var returnValue = true;
        var operatorsToExclude = ["Equals", "Not Equals To", "Contains", "Not Contains"];

        if(isBlank(this.row.fieldName)){
            returnValue = this.checkValidationForInputFields('.fieldNameComp', 'Field Name Required', this.row.fieldName);
        }else if (isBlank(this.row.operator)){
            returnValue = this.checkValidationForInputFields('.operatorsPicklistComp', 'Operator Required', this.row.operator);
        }else if (this.row && !operatorsToExclude.includes(this.row.operator)) {
            if(isBlank(this.row.operator)){
                returnValue = this.checkValidationForInputFields('.operatorsPicklistComp', 'Operator Required', this.row.operator);
            }else if (isBlank(this.row.value)){
                if(this.row.fieldType == 'MULTIPICKLIST' && this.row.operator == 'IN'){
                    returnValue = true;
                }else{
                    returnValue = this.checkValidationForInputFields('.ValueCmp', this.row.operator + ' Operator Not Allowed With Blank Value', this.row.value);
                }            
            }
        }else if (this.row.fieldType == 'ID' || this.row.fieldType == 'REFERENCE'){
            var fieldValue =  this.row.value;
            var validEmailRegEx = /[a-zA-Z0-9]{18}|[a-zA-Z0-9]{15}/i;
            if(fieldValue.length == 18 || fieldValue.length == 15){
                var isValidId = validEmailRegEx.test(fieldValue.trim());
                if(isValidId == false){
                    returnValue = this.checkValidationForInputFields('.ValueCmp', 'Enter Valid Field Id', '');
                }
            }else{
                returnValue = this.checkValidationForInputFields('.ValueCmp', 'Enter Valid Field Id', '');
            }
        }

        return returnValue;  
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