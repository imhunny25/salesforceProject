import { api, LightningElement, track } from "lwc";
import getContentDocumentAndAttachments from "@salesforce/apex/IntakeFormController.getContentDocumentAndAttachments";
import labels from "c/labelService";
import { formatParameterizedCustomLabel,showToast,iconLookup,isBlank } from "c/csUtils";

export default class DocumentUpload extends LightningElement {
    labels = labels;
    @api acceptedFileTypes;
    @api acceptedFileFormat;
    @api isrequired = false;
    @api isMultipleFiles;
    @api attachmentFiles;
    @api recordId;
    @api isEditMode;
    @api contentdocid;
    @api objectApiName;
    @api allowedFileTypeRule;
    @api allowedFileTypes;
    @api filesData=[];

    @track isfilesData = false;
    

    get showFileTypes() {
        return !!this.acceptedFileTypes?.length;
    }

    get acceptedFormats() {
        return this.acceptedFileFormat;
    }
    
    get acceptedTypes() {
        return formatParameterizedCustomLabel(this.labels.ticketIntakeFormAcceptedDocs, this.acceptedFileTypes);
    }

    connectedCallback(){
       
        if(!isBlank(this.recordId ))
        {
            this.getFiles(this.recordId);
        }
    }
  
    @api
    deleteFiles(){
        const filecomps = [...this.template.querySelectorAll("[data-fieldfile]")];
        filecomps.forEach((field) => {
            if (field.deleteFiles()) {
              
            }
        });
    }

    dispatchDocumentEvent(event){
        this.dispatchEvent(
            new CustomEvent("fileuploaded", {
                detail: {
                    documentId: event.detail.documentId
                }
            })
        );
    }

    removefileHandler(event){
        this.dispatchEvent(
            new CustomEvent("fileremoved")
        );
    }

    @api
    requiredFieldUploadedCheck() {
        let noMissingFile = true;
        const filecomps = [...this.template.querySelectorAll("[data-fieldfile]")];
        filecomps.forEach((field) => {
            if (!field.requiredFieldUploadedCheck()) {
                noMissingFile = false;
            }
        });
        return noMissingFile;
    }

    getFiles(recordId)
    {
        
        if(!isBlank(this.recordId)){
        getContentDocumentAndAttachments({recordId :recordId})
        .then(result =>{
            this.filesData = result;
            this.isfilesData = true;
        }).catch((error) => {
            showToast(
                this,
                "ERROR"
            );
        });
        }
    }
}