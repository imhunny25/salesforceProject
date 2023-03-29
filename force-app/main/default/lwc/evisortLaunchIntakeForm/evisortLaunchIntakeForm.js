import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { showToast } from 'c/csUtils';
import labels from 'c/labelService';
import getWorkspaceSettings from '@salesforce/apex/IntakeFormController.getWorkspaceSettings';
import getRecordsByObject from '@salesforce/apex/IntakeFormController.getRecordsByObject';
import postToEvisort from '@salesforce/apex/IntakeFormController.postToEvisort';

export default class EvisortLaunchIntakeForm extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;
    @api options = [];

    @track isLoading = true;
    @track hasSettings = false;
    @track settings;
    @track selectedForm;


    label = labels;

    get isValid () {
        return !(
            this.objectApiName &&
            this.selectedForm &&
            this.isWorkspaceSet
        );
    }

    get isWorkspaceSet () {
        return (
            this.settings && 
            this.settings.workspace && 
            this.settings.subdomain
        );
    }

    get hasNoOptions () {
        return this.options.length == 0;
    }

    get hasMultipleOptions () {
        return this.options.length > 1;
    }

    /**
     * Event Handlers
     */

    handleChange (evt) {
        this.selectedForm = evt.detail.value;
    }

    handleSubmitClick () {
        this.post();
    }

    handleCancelClick () {
        this.dispatchEvent(
            new CloseActionScreenEvent()
        );
    }

    /**
     * Aura Calls
     */

    getSettings () {
        return getWorkspaceSettings()
            .then((res) => {
                this.hasSettings = true;
                this.settings = res;
            });
    }

    getOptions () {
        return getRecordsByObject({
            objectApiName: this.objectApiName
        }).then((res) => {
            this.options = res.map((record) => {
                return {
                    label: record.workflowName,
                    value: record.id, // salesforce id
                };
            });
            
            if (this.options.length == 1) {
                this.selectedForm = this.options[0].value;
            }

            // only allow this to run once
            this.isRendered = true;
        });
    }

    post () {
        // validation
        if (!this.recordId || !this.selectedForm) {
            return;
        }

        postToEvisort({
            recordId: this.recordId,
            formId: this.selectedForm,
            objectApiName: this.objectApiName
        }).then((res) => {
            if (res.success) {
                const url = `https://${this.settings.subdomain}.evisort.com/${this.settings.workspace}/workflow/${res.workflowId}/intake-form/link?eviPersistKey=${res.persistKey}`;
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: url
                    }
                }, true);
            } else {
                showToast(
                    this,
                    labels.adminError,
                    labels.adminMapIntakeFormsPostError,
                    'ERROR'
                );
            }
        }).catch((err) => {
            showToast(
                this,
                labels.adminError,
                err.body.message,
                'ERROR'
            );
        });
    }

    /**
     * Lifecycle Events
     */

    connectedCallback () {
        // In the context of a quick action, `objectApiName` appears to
        // only be accessible AFTER connected/rendered callbacks run.
        setTimeout(() => {
            Promise.all([
                this.getOptions(),
                this.getSettings()
            ]).then(() => {
                this.isLoading = false;
            });
        });
    }
}