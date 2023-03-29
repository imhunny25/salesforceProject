import { LightningElement, api, wire } from "lwc";
import getEvisortFolderId from "@salesforce/apex/AdminController.getEvisortFolderId";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage } from "c/csUtils";

export default class EvisortAdminOtherOptions extends LightningElement {
    @api iconsvgurl;
    @api activestate;

    label = labels;
    folderId;

    noAccessSVG = Evisort_Resources + "/evisortResources/evisortNoAccess.svg";

    @wire(getEvisortFolderId)
    loadFolderId({ error, data }) {
        if (data) {
            this.folderId = data;
        } else if (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
    }

    launchSetupNotifications() {
        window.open("/lightning/setup/CustomNotifications/home", "_blank");
    }

    launchSetupPerms() {
        window.open("/lightning/setup/PermSets/home", "_blank");
    }

    launchAnalytics() {
        if (this.folderId !== undefined && this.folderId !== null) {
            window.open("/lightning/r/Folder/" + this.folderId + "/view", "_blank");
        } else {
            window.open("/lightning/o/Report/home", "_blank");
        }
    }

    launchAdminSetupGuide() {
        window.open(
            "https://support.evisort.com/hc/en-us/articles/360060522013-Integration-Overview-Salesforce",
            "_blank"
        );
    }
}