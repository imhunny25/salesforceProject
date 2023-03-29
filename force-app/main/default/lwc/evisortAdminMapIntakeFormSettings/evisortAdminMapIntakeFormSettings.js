/**
 * Created by rohit on 5/3/22.
 */

import { LightningElement, track } from 'lwc';
import { showToast, getFilteredErrorMessage } from "c/csUtils";
import labels from "c/labelService";

import getWorkspaceSettings from '@salesforce/apex/IntakeFormController.getWorkspaceSettings';
import setWorkspaceSettings from '@salesforce/apex/IntakeFormController.setWorkspaceSettings';

const OPTIONS = [
{label: labels.adminDisplaySettingsAll, value: "All"},
{label: labels.adminDisplaySettingsMapped, value: "Mapped"}
];

//default UI to ALL if visibility is not set.
const DEFAULT_VISIBILITY = 'All';

export default class EvisortAdminMapIntakeFormSettings extends LightningElement {

    showMessage = true;
    options = OPTIONS;
    label = labels;

    @track hasSettings = false;
    @track settings;

    get visibility() {
        return (this.hasSettings && this.settings.visibility) ? this.settings.visibility : DEFAULT_VISIBILITY;
    }

    set visibility(value) {
        if (this.hasSettings) {
            this.settings.visibility = value;
        }
    }

    handleSettingChange(event) {
        this.getSettings();
    }

    handleSave(event) {
        this.setSettings()
    }

    handleCancel(event) {
        this.showMessage = true;
    }

    handleChange(event) {
        this.settings.visibility = event.detail.value;
    }

    /**
     * Aura Calls
     */

    getSettings () {
        return getWorkspaceSettings()
            .then((result) => {
                if (result && result.id) { //check if record has been created
                    this.hasSettings = true;
                    this.settings = result;
                    this.showMessage = false;
                } else {
                    showToast(this, this.label.adminDisplaySettingsTitle, this.label.adminDisplaySettingsError, "ERROR");
                }
            });
    }

    setSettings() {
        setWorkspaceSettings({workspaceSettings: JSON.stringify(this.settings)})
            .then(result => {
                this.showMessage = true;
                showToast(this, this.label.adminSuccess, getFilteredErrorMessage(this.label.adminMappingVisibilityChangeMessage), "SUCCESS");
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            });
    }

}