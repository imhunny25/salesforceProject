/**
 * Generic Modal component
 * Able to accept another component/html/string as content
 * Footer actions are passed in as callbacks via higher order function
 */

import { LightningElement, api, track } from "lwc";

export default class Modal extends LightningElement {
    @api
    isOpen;

    @api
    title;

    @api
    confirmCallback;

    @api
    cancelCallback;

    @api
    closeLabel;

    @api
    cancelLabel;

    @api
    confirmLabel;

    @api
    innerClasses = "";

    @api 
    increaseModelWidth;

    @track setWidth;
    @track hasFooterSlot = false;

    get bodyClasses() {
        return `slds-modal__content slds-p-around_medium ${this.innerClasses}`;
    }

    connectedCallback(){
        if(this.increaseModelWidth == 'true'){
            this.setWidth = 'max-width: 80rem !important; width: 60% !important';
        }else{
            this.setWidth = '';
        }
    }

    handleSlotChange() {
        this.hasFooterSlot = true;
    }

    /**
     * calls close callback from parent component
     */
    close() {
        this.cancelCallback();
    }

    /**
     * calls confirm callback from parent component
     */
    confirm() {
        this.confirmCallback();
    }
}