import { LightningElement, api } from "lwc";

export default class PicklistValue extends LightningElement {
    @api selected = false;

    @api label;

    @api value;

    handleSelect() {
        /* eslint-disable @lwc/lwc/no-api-reassignments */
        this.selected = !this.selected;
        this.dispatchEvent(new CustomEvent("valueselect"));
    }
}