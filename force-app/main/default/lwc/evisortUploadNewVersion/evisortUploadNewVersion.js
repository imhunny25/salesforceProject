import { LightningElement, api, track } from 'lwc';
import uploadNewVersionDocument from "@salesforce/apex/TicketController.uploadNewVersionDocument";
import removeDocument from "@salesforce/apex/NewIntakeFormController.removeDocument";
import { formatParameterizedCustomLabel } from "c/csUtils";
import { showToast } from "c/csUtils";
import labels from "c/labelService";


export default class EvisortUploadNewVersion extends LightningElement {
    label= labels

    @api isModalOpen;
    @api ticketId;
    @api documentId;
    @api contentDocumentId;
    @api ticketRecordId;
    @api acceptedFileTypes;

    @track isAddNotes = false;
    @track isAddNotesDisable = false;
    @track commentInputValue = '';
    @track commentValue;
    @track isUploaded = false;
    @track uploadDisable = true;
    @track isShowSpinner = false;
    @track fileTypes;
    fileFormat;
    documentDetails={};
    MAX_CHAR_LENGTH = 4096;

    connectedCallback() {
        this.commentValue = this.commentInputValue;
        this.documentDetails.ticketId = this.ticketId;
        this.documentDetails.documentId = this.documentId;
        this.documentDetails.oldContentDocumentId = this.contentDocumentId;
        this.documentDetails.evisortRecordId = this.ticketRecordId;
        this.documentDetails.isCounterparty = true;
    }

    handleKeyUp(event) {
        this.commentInputValue = event.target.value;
        this.documentDetails.note = this.commentInputValue; 
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        const custEvent = new CustomEvent(
            'closemodal', {
                detail: false
            });
        this.dispatchEvent(custEvent);
    }
    
    get acceptedFileType() {
        return this.acceptedFileTypes;
    }

    get acceptFileTypes(){
        this.fileTypes = this.acceptedFileTypes
        if (this.acceptedFileTypes.length > 1) {
            this.fileFormat = [this.fileTypes.join(" ")];
        }else{
            this.fileFormat = this.fileTypes
        }
        return formatParameterizedCustomLabel(this.label.ticketIntakeFormAcceptedDocs, this.fileFormat);
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.fileName = uploadedFiles[0].name;
        this.fileName = uploadedFiles[0].name;
        this.isUploaded = true;
        this.uploadDisable = false;
        var contentVersion = uploadedFiles[0].contentVersionId;
        var contentDocument = uploadedFiles[0].documentId;
        this.documentDetails.contentVersionId = contentVersion;
        this.documentDetails.contentDocumentId = contentDocument;
    }
    
    handleRemove(){
        let deleteSelectedFiles = [this.documentDetails.contentDocumentId];
        removeDocument({ docIds: deleteSelectedFiles })
        .then(() => {
            this.isUploaded = false;
            this.uploadDisable = true;
            this.fileName = "";
            this.documentDetails = {};
        })
        .catch((error) => {
            showToast(
                this,
                this.label.ticketUploadRemoveErrorTitle,
                this.label.ticketUploadRemoveErrorText,
                "ERROR"
            );
        });
    }
    counterpartyDocumentHandler(event){
        this.documentDetails.isCounterparty = event.target.checked;
    }


    submitDetails(){
        this.isShowSpinner = true;

        var docDetails = JSON.stringify(this.documentDetails);
        uploadNewVersionDocument({documentDetails:docDetails})
        .then((res)=>{
            showToast(this, this.label.adminSuccess,this.label.ticketNewDocumentUploaded, "SUCCESS");
            this.refreshComponent();
        })
        .catch((error) => {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            this.isShowSpinner = false;
            this.closeModal();
        })
        
    }
    refreshComponent(){
        const searchevent = new CustomEvent("updatecomponent");
        this.dispatchEvent(searchevent);
    }

    @api
    refreshAll(){
        this.isShowSpinner = false;
        this.closeModal();
    }
}