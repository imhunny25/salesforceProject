import { LightningElement, api } from "lwc";
import evisortRecords from "@salesforce/apex/EvisortPreviousFilterRecords.evisortRecords";
import labels from "c/labelService";

export default class EvisortAdminAuth extends LightningElement {
    @api iconsvgurl;
    @api apisetupgifurl;
    @api namedcredentialgifurl;
    @api activestate;
    @api recordtypes;

    label = labels;

    iconSvgUrl = "";
    apiSetupGifUrl = "";
    namedCredentialGifUrl = "";

    connectedCallback() {
        this.iconSvgUrl = this.iconsvgurl;
        this.apiSetupGifUrl = this.apisetupgifurl;
        this.namedCredentialGifUrl = this.namedcredentialgifurl;
        this.checkPreviousFilterRecord();
    }

    checkPreviousFilterRecord(){
        evisortRecords();
    }

    handleAuth() {
        const stateChange = new CustomEvent("statechange");
        this.dispatchEvent(stateChange);
    }

    launchEvisortLogin() {
        window.open("https://clients.evisort.com/", "_blank");
    }
    launchSetupNamedCredentials() {
        window.open("/lightning/setup/NamedCredential/home", "_blank");
    }
}