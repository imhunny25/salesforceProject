import { api, LightningElement,track} from 'lwc';
import labels from "c/labelService";
import uploadTicketSignDocument from "@salesforce/apex/TicketController.uploadTicketSignDocument";
import removeDocument from "@salesforce/apex/NewIntakeFormController.removeDocument";
import { showToast, getFilteredErrorMessage, isBlank } from "c/csUtils";

const EXTERNAl_USER = "externalUser";
const USER = "user";
export default class TicketUploadSigned extends LightningElement {
    labels = labels;

    @api currentStage;
    @api currentTicketId;
    @api fileInfo;
    @api documentIds;

    @track isShowModal = false;
    @track isUploaded = false;
    @track fileName;
    @track disableUploadButton = true;
    @track options = [];
    @track value = [];
    @track signedCompleteValue = [];
    @track isShowSpinner = false;

    ticketDocumentDetails = {
        currentTicketId:'',
        contentVersion:'',
        contentDocument:'',
        signerIds:''
    }

    connectedCallback(){
        this.ticketDocumentDetails.currentTicketId = this.currentTicketId;
        var assinerEmail = [];
        let signUser = [];
        this.currentStage.phases.forEach((phase)=>{
            phase.judgments.forEach((judgment)=>{
                judgment.approvals.forEach((e)=>{
                    if(judgment.status == 'signed'){
                        if(e.hasOwnProperty(USER) == true){
                            this.signedCompleteValue.push('\''+e.user.id+'\'');
                        }
                        if(e.hasOwnProperty(EXTERNAl_USER) == true){
                            this.signedCompleteValue.push('\''+e.externalUser.id+'\'');
                        }
                    }
                    if(e.hasOwnProperty(USER) == true){
                        if(!assinerEmail.includes(e.user.email)){
                            signUser.push({label:e.user.name, value:'\''+e.user.id+'\''})
                            assinerEmail.push(e.user.email);
                        }
                    }
                    if(e.hasOwnProperty(EXTERNAl_USER) == true){
                        signUser.push({label:e.externalUser.name+'('+e.externalUser.email+')', value:'\''+e.externalUser.id+'\''})
                    }
                });
            });
        });
        if(this.signedCompleteValue.length > 0){
            this.ticketDocumentDetails.signerIds = this.signedCompleteValue;
        }
        this.options = signUser;
    }

    
    closeShowModal(){
        const evt = new CustomEvent('closeshowmodal',{
           detail:false
        });
        this.dispatchEvent(evt);
    }

    handleUploadFinished(event){
        const uploadedFiles = event.detail.files;
        this.fileName = uploadedFiles[0].name;
        this.ticketDocumentDetails.contentVersion = uploadedFiles[0].contentVersionId;
        this.ticketDocumentDetails.contentDocument = uploadedFiles[0].documentId;
        
        this.isUploaded = true;
        this.uploadButtonDisable();
    }

    handleRemove(){
        let deleteSelectedFiles = [this.ticketDocumentDetails.contentDocument];

        removeDocument({ docIds: deleteSelectedFiles })
        .then(() => {
            this.isUploaded = false;
            this.fileName = "";
            this.disableUploadButton = true;
        })
        .catch((error) => {
            showToast(
                this,
                this.labels.ticketUploadRemoveErrorTitle,
                this.labels.ticketUploadRemoveErrorText,
                "ERROR"
            );
        });
    }

    handleUserChange(event){
        this.value = event.detail.value;
        
        this.ticketDocumentDetails.signerIds = this.value;
        this.uploadButtonDisable();
    }
    
    uploadButtonDisable(){
        if(this.value.length > 0 && this.isUploaded == true || !isBlank(this.ticketDocumentDetails.signerIds) && this.isUploaded == true ){
            this.disableUploadButton = false;
        }
        else{
            this.disableUploadButton = true;
        }
    }

    uploadDocument(){
        this.isShowSpinner = true;
        const ticketSignDocDetails = JSON.stringify(this.ticketDocumentDetails);
        const ticketEvisortAndDocumentIds = JSON.stringify(this.documentIds);
        uploadTicketSignDocument({ticketSignDocumentDetails:ticketSignDocDetails,replaceDocumentId:ticketEvisortAndDocumentIds})
        .then(()=>{
            showToast(this, this.labels.adminSuccess,this.labels.ticketSignedUploadSuccessfully, "SUCCESS");
            this.refreshComponent();
        })
        .catch((error) => {
            showToast(this, this.labels.adminError, getFilteredErrorMessage(error), "ERROR");
            this.isShowSpinner = false;
        })
    }

    refreshComponent(){
        const searchevent = new CustomEvent("updatecomponent");
        this.dispatchEvent(searchevent);
    }

    @api
    refreshSpinner(){
        this.isShowSpinner = false;
        this.closeShowModal();
    }
}