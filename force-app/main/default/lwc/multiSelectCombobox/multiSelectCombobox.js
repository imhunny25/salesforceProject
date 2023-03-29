import { LightningElement, api, track } from "lwc";

export default class MultiSelectCombobox extends LightningElement {
    @api set options(value) {
        if (value !== undefined) {
            this._options = [...value];
        }
    }
    get options() {
        return this._options;
    }
    @api values = [];
    @api picklistlabel = "General Information";
    @api placeholder = "Select an Option...";

    @track _values = [];
    @track _options = [];

    @api rowDisable = false;
    showDropdown = false;
    mouseInComponent = false;

    /**
     * Checks to see if the mouse has entered this component
     */
    handleMouseEnter() {
        this.mouseInComponent = true;
    }

    /**
     * Checks to see if the mouse has exited this component
     */
    handleMouseLeave() {
        this.mouseInComponent = false;
    }

    /**
     * If one of the items was selected, return focus to the main input element to handle blur event
     */
    handleSelect() {
        this.template.querySelector("input").focus();
        this.fetchSelectedValues();
        this.sendEvent();
    }

    /**
     * If the mouse is clicked outside of our component, close the dropdown and process the selected values
     */
    handleBlur() {
        if (this.showDropdown && !this.mouseInComponent) {
            this.showDropdown = false;
            this.fetchSelectedValues();
            this.sendEvent();
        }
    }

    /**
     * Sends a Custom Event to propagate picklist values to parent component
     */
    sendEvent() {
        const selectedEvent = new CustomEvent("multiselectchange", {
            detail: this._values
        });
        this.dispatchEvent(selectedEvent);
    }

    connectedCallback() {
        this._values = this.values;
        this.refreshList();
    }

    fetchSelectedValues() {
        this._values = [];

        //get all the selected values
        this.template.querySelectorAll("c-picklist-value").forEach((element) => {
            if (element.selected) {
                this._values.push(element.value);
            }
        });

        //refresh original list
        this.refreshList();
    }

    refreshList() {
        //update the original value array to shown after close

        const picklistvalues = this._options.map((eachvalue) => ({
            ...eachvalue
        }));

        picklistvalues.forEach((element, index) => {
            picklistvalues[index].selected = this._values.includes(element.value);
        });

        this._options = picklistvalues;
    }

    handleShowdropdown() {
        this.showDropdown = !this.showDropdown;
    }

    get selectedmessage() {
        if (this._values.length === 0) {
            return this.placeholder;
        } else if (this._values.length === 1) {
            const index = this._options.findIndex((element) => element.value === this._values[0]);
            return this._options[index].label;
        }

        return this._values.length + " values are selected";
    }
}