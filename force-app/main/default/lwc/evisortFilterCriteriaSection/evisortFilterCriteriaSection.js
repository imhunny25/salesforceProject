import { LightningElement, api, track } from 'lwc';
import labels from "c/labelService";
import getAllFieldsWrapper from "@salesforce/apex/AdminController.getAllFieldsDetails";
import { showToast, getFilteredErrorMessage } from "c/csUtils";

export default class EvisortFilterCriteriaSection extends LightningElement {
    @api sobjectName;
    @api fieldsWrapper;
    @api fieldsWrapperMap;
    @api rowsDisable;
    
    @track cheboxValue = false;
    @track libraryValue;

    @track rows = [];
    @track displayFilters = false;
    @track UPDATE_ROW = 'updaterow';
    @track ADD_ROW = 'addrow';
    @track DELETE_ROW = 'deleterow';
    @api rowsData=[];
    @track refreshList= true;

    @track isShowAndOrCondition = true;
    @track conditionValue = 'AND';
    @track isAddRow = false;

    label = labels;
    
    set selectedrows(value) {
        this.rows = value;
    }
    get selectedrows() {
        return this.rows;
    }

    get conditonOptions() {
        return [
            { label: this.label.AdminFilterAllConditionAreMet, value: 'AND' },
            { label: this.label.AdminFilterAnyConditionAreMet, value: 'OR' },
        ];
    }
    
    connectedCallback() {
        if(this.rowsData != undefined && this.rowsData != ''){
            var resultData = this.rowsData;
            resultData = resultData.replace(/\\/g, "");
            var Data = JSON.parse(resultData);  
            this.conditionValue = Data.condition;
            let i=1;     
            Data.rows.forEach(rowObj => {  
                    let row = Object.assign({},rowObj);
                    row.sequence = i;
                    this.rows.push(row);
                    i++;
            });

            this.isAddRow = true;
            this.updateRowsData(); 
        }
        this.getAllFieldWrappers();
    }

    /*
        @Description : Getting all field wrappers details
    */
    @api 
    getAllFieldWrappers() {   
        this.displayFilters = false;
        getAllFieldsWrapper({ objectName: this.sobjectName })
            .then(result => {
                this.displayFilters = true;
                this.fieldsWrapper = result.sort(this.sortBy('fieldLabel', false));
            })
    }

    sortBy (field, reverse, primer){

        var key = function (x) {return primer ? primer(x[field]) : x[field]};
     
        return function (a,b) {
            var A = key(a), B = key(b);

            if (A === undefined) A = '';
            if (B === undefined) B = '';
        
            return (A.toLowerCase() < B.toLowerCase() ? -1 : (A.toLowerCase() > B.toLowerCase() ? 1 : 0)) * [1,-1][+!!reverse];                  
        }
    }

    /*
        @Description : Adding blank Row
    */
    addBlankRow() {
        this.rows.push({
            fieldName: '',
            fieldLabel: '',
            fieldType: '',
            operator: '',
            value: '',
        });
    }

    @api modifyRowsData(rowsData){
        this.rows = [...rowsData];
        this.fieldsWrapper = this.rows;
    }

    /*
        @Description : Use to update the rows data
    */
    handleRowUpdate(event) {
        var eventData = event.detail;

        if (eventData.operation == this.ADD_ROW) {
            this.addBlankRow();

        } else if (eventData.operation == this.UPDATE_ROW) {
            this.rows[eventData.index] = eventData.row;

        } else if (eventData.operation == this.DELETE_ROW) {
            
            this.refreshList = false;
            var rowsData = [];
            let i = 0;
            this.rows.forEach( row => {
                if(eventData.index != i){
                    rowsData.push(row);
                }
                i++;
            });
            this.rows = [];
            rowsData.forEach( row => {
                this.rows.push(row);
            });
        }
        this.updateRowsData();
    }

    renderedCallback(){
        this.refreshList = true;
    } 
    /*
        @Description : Use to call the event to update the rows data
    */
    updateRowsData() {
        if(this.rows.length <= 1){
            this.isShowAndOrCondition = false;
        }else{
            this.isShowAndOrCondition = true;
        }
        var detailCondition = this.conditionValue; 
        var detailObj = { rows: this.rows, condition : detailCondition  };
        const closemodel = new CustomEvent('updaterows', {
            detail: detailObj
        });
        this.dispatchEvent(closemodel);
    }

    /*
        @Description : Use to add blank row
    */
    handleAddMore() { 
        this.isAddRow = true;
        if(this.rows.length == 0){
            this.isShowAndOrCondition = false;
        }else{
            this.isShowAndOrCondition = true;
        }
        this.addBlankRow();
        
    }
    
    /*
        @Description : Checking the validations on the component
    */
    @api checkValidations() {
        var rows = [...this.template.querySelectorAll("c-evisort-filter-criteria-row")];
        var isChildComponentValid = true;
        try {
            for(var index in rows){
                var row = rows[index];
                if(!row.checkValidations()){
                    isChildComponentValid = false;
                }
            }
        } catch (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
        return isChildComponentValid;
    }

    handleConditonChange(event){
        this.conditionValue = event.detail.value;
        this.updateRowsData();
    }

    handleCheckboxChange(event){
        this.cheboxValue = event.target.checked;;
        if(this.cheboxValue == false){
            this.libraryValue ='';
        }
    }
}