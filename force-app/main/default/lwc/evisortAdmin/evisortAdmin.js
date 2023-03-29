import { LightningElement, track, wire } from "lwc";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import verifyAuth from "@salesforce/apex/AdminController.verifyAuth";
import getAuthStatus from "@salesforce/apex/AdminController.getAuthStatus";
import syncFieldDefinitions from "@salesforce/apex/AdminController.syncFieldDefinitions";
import { showToast } from "c/csUtils";
import { getFilteredErrorMessage } from "c/csUtils";
import labels from "c/labelService";

export default class EvisortAdmin extends LightningElement {
    @track activeState = false;
    @track isPulling = false;
    @track pullButtonDisabled = true;

    currentTab;
    evisortSyncData;

    message = "";

    logoPngUrl = Evisort_Resources + "/evisortResources/logo.png";
    logoJpgUrl = Evisort_Resources + "/evisortResources/logo.jpg";
    logoSvgUrl = Evisort_Resources + "/evisortResources/evisortLogo.svg#colorLogo";
    iconSvgUrl = Evisort_Resources + "/evisortResources/evisortIcon.svg#colorIcon";
    apiSetupGifUrl = Evisort_Resources + "/evisortResources/apiKeySetup.gif";
    namedCredentialGifUrl = Evisort_Resources + "/evisortResources/namedCredentialSetup.gif";
    // LABELS //
    label = labels;

    evisortAPIVersion = "X.XX";
    evisortLastPullDate = "XX/XX/XXXX X:XX";
    evisortLastDocSync = "XX/XX/XXXX X:XX";
    evisortAuthDate = "XX/XX/XXXX X:XX";

    @wire(getAuthStatus)
    wiredAuthStatus({ error, data }) {
        if (data) {
            this.error = undefined;
            this.activeState = data.authenticated;
            this.evisortAuthDate = data.authenticationDate || this.evisortAuthDate;
            this.evisortLastDocSync = data.lastDocumentSync || this.evisortLastDocSync;
            this.evisortLastPullDate = data.lastFieldPull || this.evisortLastPullDate;
            this.evisortAPIVersion = data.version || this.evisortAPIVersion;

            if (!data.authenticated) {
                this.pullButtonDisabled = true;
                this.message = data.message || this.label.adminYouAreNotAuthenticated;
                showToast(this, this.label.adminNotAuthenticated, getFilteredErrorMessage(this.message), "ERROR");
            } else {
                this.pullButtonDisabled = false;
                this.message = data.message || this.label.adminYouAreAuthenticated;
                showToast(this, this.label.adminAuthenticated, getFilteredErrorMessage(this.message), "SUCCESS");
            }
        } else if (error) {
            this.error = error;
            let message = error || this.label.adminYouAreNotAuthenticated;
            this.activeState = false;
            this.pullButtonDisabled = true;
            showToast(this, this.label.adminNotAuthenticated, getFilteredErrorMessage(message), "ERROR");
        }
    }

    handleStateChange() {
        // Verify Auth
        verifyAuth()
            .then((result) => {
                if (!result.success) {
                    throw result.message;
                }
                this.activeState = true;
                this.pullButtonDisabled = false;
                this.message = result.message || this.label.adminYouAreAuthenticated;
                showToast(this, this.label.adminAuthenticated, getFilteredErrorMessage(this.message), "SUCCESS");
            })
            .catch((err) => {
                this.activeState = false;
                this.pullButtonDisabled = false;
                this.message = err || this.label.adminYouAreNotAuthenticated;
                showToast(this, this.label.adminNotAuthenticated, getFilteredErrorMessage(this.message), "ERROR");
            });
    }

    handlePullFromEvisort() {
        this.isPulling = true;
        this.pullButtonDisabled = true;
        syncFieldDefinitions({ fieldType: "" })
            .then((result) => {
                this.evisortSyncData = result;
                this.evisortLastPullDate = new Date(); // Place the current datetime in the header
                showToast(
                    this,
                    this.label.adminSuccess,
                    getFilteredErrorMessage(this.label.adminSuccessfulPull),
                    "Success"
                );
                this.refreshDefinitions();
            })
            .catch((err) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(err), "ERROR");
            })
            .finally(() => {
                this.isPulling = false;
                this.pullButtonDisabled = false;
            });
    }

    launchEvisortDocumentation() {
        window.open(
            "https://support.evisort.com/hc/en-us/articles/360060522013-Integration-Overview-Salesforce",
            "_blank"
        );
    }

    handleActive(event) {
        this.currentTab = event.target.value;
        this.refreshDefinitions();
    }

    refreshDefinitions() {
        /* eslint-disable @lwc/lwc/no-async-operation */
        if (this.currentTab === "fields") {
            setTimeout(() => this.template.querySelector("c-evisort-admin-sync-fields").reloadFields());
        } else if (this.currentTab === "provisions") {
            setTimeout(() => this.template.querySelector("c-evisort-admin-sync-provisions").reloadProvisions());
        } else if (this.currentTab === 'export') {
            setTimeout(() => this.template.querySelector('c-evisort-admin-export').refreshPage());
        }
        
    }
}