import { LightningElement, track, api } from 'lwc';
import sendEmailController from "@salesforce/apex/EvisortEmailShare.sendEmailController";
import getCurrentUser from "@salesforce/apex/TicketController.getUserDetails";
import labels from "c/labelService";
import { showToast,getFilteredErrorMessage, isValidateEmail } from "c/csUtils";

export default class EvisortEmailShare extends LightningElement {
    label = labels;
    @api isModalOpen;
    @api fileInfo = {};
    @api ticketRecordId;
    @api document;
    @track file = [];
    @track shareDisable = true;
    @track showCCInput = false;
    @track showBCCInput = false;
    @track areEmailsValid = true;
    @track loading = false;
    toAddress = [];
    ccAddress = [];
    bccAddress = [];
    subject = "";
    body = "";
    noEmailError = false;
    invalidEmails = false;
    formats = [
        'font',
        'size',
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'indent',
        'align',
        'link',
        'clean',
        'table',
        'header',
        'color',
    ];

    get disableShare() {
        if ([...this.toAddress, ...this.ccAddress, ...this.bccAddress].length == 0) {
            return true;
        }
        return (!this.areEmailsValid) || this.shareDisable;
    }

    connectedCallback() {
        this.loading = true;
        this.file = {
            name: this.document?.name, 
            contentVersionId: this.fileInfo?.content?.ContentVersionID
        };
        getCurrentUser()
            .then((result) => {
                let userName = result.userName;;  
                this.subject = 'Document shared: ' + this.file.name + ' from ' + userName;
                this.body = 'Hi,<br><p>Please find documents for your review attached.</p><br/>Sincerely,<br>' + userName;  
                this.loading = false;    
            })
            .catch((err) => {
                this.loading = false;
                showToast(this, this.label.adminError, getFilteredErrorMessage(err), "ERROR");
            });
    }

    handleToAddressChange(event) {
        this.toAddress = event.detail.selectedValues;
        if (![...this.toAddress, ...this.ccAddress, ...this.bccAddress].length > 0) {
            this.invalidEmails = false;
            this.shareDisable = true;
        } else if (!isValidateEmail([...this.toAddress, ...this.ccAddress, ...this.bccAddress])) {
            this.invalidEmails = true;
            this.shareDisable = true;
        } else {
            this.invalidEmails = false;
            this.shareDisable = false;
        }
    }

    handleCcAddressChange(event) {
        this.ccAddress = event.detail.selectedValues;
        if (![...this.toAddress, ...this.ccAddress, ...this.bccAddress].length > 0) {
            this.invalidEmails = false;
            this.shareDisable = true;
        } else if (!isValidateEmail([...this.toAddress, ...this.ccAddress, ...this.bccAddress])) {
            this.invalidEmails = true;
            this.shareDisable = true;
        } else {
            this.invalidEmails = false;
            this.shareDisable = false;
        }
    }

    handleBccAddressChange(event) {
        this.bccAddress = event.detail.selectedValues;
        if (![...this.toAddress, ...this.ccAddress, ...this.bccAddress].length > 0) {
            this.invalidEmails = false;
            this.shareDisable = true;
        } else if (!isValidateEmail([...this.toAddress, ...this.ccAddress, ...this.bccAddress])) {
            this.invalidEmails = true;
            this.shareDisable = true;
        } else {
            this.invalidEmails = false;
            this.shareDisable = false;
        }
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }


    handleShareEmail() {
        this.shareDisable = true;
        this.noEmailError = false;
        this.invalidEmails = false;
        if (![...this.toAddress, ...this.ccAddress, ...this.bccAddress].length > 0) {
            this.noEmailError = true;
            return;
        }
        
        if (!isValidateEmail([...this.toAddress, ...this.ccAddress, ...this.bccAddress])) {
            this.invalidEmails = true;
            return;
        }

        let emailDetails = {
            toAddress: this.toAddress,
            ccAddress: this.ccAddress,
            bccAddress: this.bccAddress,
            subject: this.subject,
            body: this.body
        };
        var conVerId = this.fileInfo?.content?.ContentVersionID;

        sendEmailController({ emailDetailStr: JSON.stringify(emailDetails), conVerId: conVerId })
            .then(() => {
                this.closeModal();
                this.dispatchEvent(new CustomEvent("emailsent"));
            })
            .catch((err) => {
                this.shareDisable = false;
                showToast(this, this.label.adminError, getFilteredErrorMessage(err), "ERROR");
            });
    }

    closeModal() {
        this.isModalOpen = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    handleCloseClick() {
        this.noEmailError = false;
        this.invalidEmails = false;
    }

    handleCcClick() {
        this.showCCInput = true;
    }

    handleBccClick() {
        this.showBCCInput = true;
    }

    handleValidityCheck(event) {
        this.areEmailsValid = event.detail;
    }
}