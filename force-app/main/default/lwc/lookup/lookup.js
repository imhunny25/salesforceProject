import { LightningElement, api, track } from "lwc";
import labels from "c/labelService";

export default class Lookup extends LightningElement {
    @api label = "Search";
    @api hideLabel = false;
    @api workflowFieldIds = null;
    @api fieldApi = null;
    @api icon = "standard:record";

    @track hideErrorMsg = true;

    labels = labels;

    @api
    get tooltip() {
        return this._tooltip;
    }
    set tooltip(value) {
        if (value) {
            this._tooltip = value;
        }
    }
    @api
    get records() {
        return this._records;
    }
    set records(val) {
        const _val = [...val];
        this._records = _val.sort((a, b) => {
            const _a = a.name?.toLowerCase();
            const _b = b.name?.toLowerCase();

            if (_a < _b) {
                return -1;
            }

            if (_a > _b) {
                return 1;
            }

            return 0;
        });
    }
    @api
    get selectedRecord() {
        return this._selectedRecord;
    }

    set selectedRecord(val) {
        this._selectedRecord = val;
    }

    get labelClass() {
        return this.hideLabel === "false" ? "slds-form-element__label" : "slds-form-element__label slds-assistive-text";
    }

    get computedListClasses() {
        return this.hideErrorMsg
            ? "slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
            : "slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid lookup-list_error";
    }

    get recordsList() {
        return this.searchValue.length ? this.filteredRecords : this._records;
    }

    get hasTooltip() {
        return !!this._tooltip;
    }

    // since public properties should not be reassigned, track changes with private property
    _selectedRecord;
    timer = 0;
    focusedIndex = -1;
    focusedNode = null;
    searchValue = "";
    _records = [];
    _tooltip = null;

    /**
     * Each time there is a change on the lookup input, this captures the value
     *
     * @param  {event} e e.target.value holds the value of the input
     */
    handleInputKeyup(e) {
        this.searchValue = e.target.value;

        this.handleScrollList(e);

        // cancel if arrow or enter buttons are pressed
        if (e.keyCode === 13 || e.keyCode === 38 || e.keyCode === 40) {
            return;
        }

        // run only if 1 or more characters
        // don't run when pressing enter
        if (this.searchValue.length > 0) {
            // this.search(this.searchValue);
            this.filteredRecords = this._records.filter((record) => {
                return record.name.toLowerCase().includes(this.searchValue.toLowerCase());
            });
        } else {
            this.filteredRecords = [];
        }
    }

    handleFocus() {
        this.showTypeaheadResults();
    }

    handleBlur() {
        this.hideTypeaheadResults();
    }

    /**
     * Handle typeahead the result record that has been selected.
     * Each typeahead result element stores pertinent information
     * in data attributes on the target element.
     *
     * @param  {event} e e.currentTarget represents the typeahead result element
     */
    selectRecord(e) {
        const target = e.currentTarget.nodeName === "LI" ? e.currentTarget : e.target;
        const data = target.dataset;
        const record = {
            id: data.id,
            name: data.name,
            fieldValue: data.fieldValue,
            workflowFieldIds: this.workflowFieldIds
        };

        // visualize selected record in UI
        this._selectedRecord = record;

        // close typeahead menu and clear typeahead results
        this.hideTypeaheadResults();
        this.clearRecords();

        // notify parent of selected record
        this.broadcastSelectedRecord(record);
    }

    /**
     * Handle the mousedown event on an li item to prevent the input
     * from losing focus.
     *
     * @param {*} e
     */
    preventBlur(e) {
        e.preventDefault();
    }

    showTypeaheadResults() {
        const resultsContainer = this.template.querySelector(".csskills-matrix-lookup-container");

        resultsContainer.classList.add("slds-is-open");
    }

    hideTypeaheadResults() {
        const resultsContainer = this.template.querySelector(".csskills-matrix-lookup-container");

        resultsContainer.classList.remove("slds-is-open");
    }

    clearRecords() {
        this.focusedIndex = -1;
        this.focusedNode = null;
    }

    removeSelectedRecord() {
        this.broadcastSelectedRemoved(this._selectedRecord);
        this._selectedRecord = null;

        // after the record is deselected, add focus back to the input
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.focusInput();
        }, 100);
    }

    focusInput() {
        const el = this.template.querySelector(".lookup-input");

        el.focus();
    }

    handleScrollList(e) {
        const els = this.getResultNodes();

        if (els.length > 0 && this._records.length > 0) {
            // handle up arrow
            if (e.keyCode === 38) {
                this.scrollMenu(els, "up");
            }

            // handle down arrow
            if (e.keyCode === 40) {
                this.scrollMenu(els, "down");
            }

            // enter as long is there is a node that has focus
            if (e.keyCode === 13 && this.focusedNode !== null) {
                this.selectRecord(e);
            }
        }
    }

    scrollMenu(els, dir = "down") {
        const last = els.length - 1;
        let el;
        let focusedEl;

        // reset focus classes
        this.removeFocusClasses();

        if (dir === "down") {
            if (this.focusedIndex === last) {
                this.focusedIndex = 0;
            } else {
                this.focusedIndex++;
            }
        } else {
            if (this.focusedIndex <= 0) {
                this.focusedIndex = last;
            } else {
                this.focusedIndex--;
            }
        }

        // focus the element
        el = els[this.focusedIndex];
        focusedEl = el.querySelector(".slds-listbox__option");

        // add focus class
        el.focus({ preventScroll: true });
        focusedEl.classList.add("slds-has-focus");
        this.focusedNode = focusedEl;
    }

    /**
     * Once a successful search is returned, slds-listbox__items are
     * created in the DOM. This method retrieves them.
     */
    getResultNodes() {
        return this.template.querySelectorAll(".slds-listbox__item");
    }

    /**
     * The slds-has-focus CSS class is applied to the slds-listbox__options.
     * Before adding one, we will need to remove the slds-has-focus class from each.
     */
    removeFocusClasses() {
        const els = this.template.querySelectorAll(".slds-listbox .slds-listbox__option");

        els.forEach((el) => {
            el.classList.remove("slds-has-focus");
        });
    }

    /**
     * The parent of this component may want to know which record was selected.
     *
     * @param  {object} record {id, name, relationshipApi}
     */
    broadcastSelectedRecord(record) {
        const evt = new CustomEvent("lookuprecordselected", {
            detail: record
        });

        this.hideErrorMsg = true;

        this.dispatchEvent(evt);
    }

    /**
     * The parent of this component may want to know which record was removed.
     *
     * @param  {object} record {id, name, relationshipApi}
     */
    broadcastSelectedRemoved(record) {
        const evt = new CustomEvent("lookuprecordremoved", {
            detail: record
        });

        this.dispatchEvent(evt);
    }

    @api
    checkForSelectedRecord() {
        if (!this._selectedRecord) {
            this.hideErrorMsg = false;
        }
        return this.hideErrorMsg;
    }
}