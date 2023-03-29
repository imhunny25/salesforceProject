import { LightningElement,track,api } from 'lwc';
import { showToast, sortByLabel, RELATIONSHIP_TYPES , isBlank} from "c/csUtils";

export default class EvisortMappableFieldsInIntakeForm extends LightningElement {
    @api mapping=[];
    @api activeItem;
    @track fields;
    @track errorValue;

    connectedCallback(){
    }

    @api
    get options() {
        return this.fields;
    }

    set options(fieldOption){
        if(!_.isEmpty(fieldOption)){
            var temp = fieldOption;
                let isValue = JSON.parse(JSON.stringify(temp[this.mapping.questionName]));
                const sortedFields = isValue.sort(sortByLabel);
                sortedFields.unshift(
                {
                    label: "-- Add Parent Lookup --",
                    value: RELATIONSHIP_TYPES.parentLookup
                },
                {
                    label: "-- Add Child Lookup --",
                    value: RELATIONSHIP_TYPES.childLookup
                }
            );
            this.fields = sortedFields;
        }
    }

    /**
     * Parses and event or custom event object to return the dataset key
     * @param {Event} evt Change or Custom event
     */
    parseEventDataset(event) {
        return event.detail?.dataset ? event.detail.dataset : event.target.dataset;
    }

    handleUpdateMapping(evt) {
        const _dataset = this.parseEventDataset(evt);
        const _value = evt.detail.value;
        const _relationshipType = evt.detail.relationshipType;
        const searchevent = new CustomEvent('selectedobjectfield', {
            detail: {
                dataset: _dataset,
                value: _value,
                relationshipType: _relationshipType
            }
        });
        // Dispatches the event.
        this.dispatchEvent(searchevent);
    }

    handleToggleMappingType(evt) {
        const _dataset = this.parseEventDataset(evt);
        const clearsearchevent = new CustomEvent('clearselectedfield', {
            detail: _dataset
        });
        this.dispatchEvent(clearsearchevent);
    }

    @api
    customFieldErrorSet(err){
         this.errorValue = err;
    }

    @api
    fieldValidate(){
        let input = this.template.querySelector(`[data-workflow-field-id="${this.mapping.workflowFieldId}"]`);
        input.setCustomValidity(this.errorValue);
        input.reportValidity();
    }
}