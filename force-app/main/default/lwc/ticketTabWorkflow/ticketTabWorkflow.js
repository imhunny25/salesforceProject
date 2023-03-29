import { LightningElement, api, track } from "lwc";
import { iconLookup, parseInitials, isBlank } from "c/csUtils";
import labels from "c/labelService";
import { formatParameterizedCustomLabel,sortByLabel,showToast} from "c/csUtils";
import { NavigationMixin } from "lightning/navigation";
import getcurrentUserEmail from "@salesforce/apex/TicketController.getUserDetails";
import getEvisortRecord from "@salesforce/apex/TicketController.getEvisortRecord";
import getEvisortUsers from "@salesforce/apex/TicketController.getEvisortUsers";

const EXTERNAl_USER = "externalUser";
const USER = "user";
export default class TicketTabWorkflow extends NavigationMixin(LightningElement) {
    labels = labels;

    @track showIsCompletedModal = false;
    @track evisortTicketId;

    @api documentInfo;
    @api fileInfo;
    @api ticketEvisortRecordId;
    @api currentTicketId;
    @api ticketRecordId;
    @api acceptedFileTypes;
    @api ticketStatus;

    @track _currentStage;
    @track stageHeader;

    @track currentUserEmailId;
    @track currentUserName;
    @track getUserInfo = false;
    @track disableUploadSign = false;
    @track showSignUploadButton = false;
    @track isShowModal = false;
    @track isNewVersionModalOpen = false;
    @track documentId;
    @track contentDocumentId;
    @track isShareModalOpen = false;
    @track isNewVersionDocument = false;
    @track evisortUsersList = [];
    @track documentIds = {
        oldDocumentId:'',
        ticketEvisortRecordId:''
    }

    @api
    get currentStage() {
        return this._currentStage;
    }

    set currentStage(stage) {
        const _stage = JSON.parse(JSON.stringify(stage));

        if (_stage) {
            _stage.coordinators?.forEach((coordinator, i, array) => {
                array[i].initials = parseInitials(coordinator.name);
            });

            const capStageName = _stage.name?.charAt().toUpperCase() + _stage.name?.slice(1);
            this._currentStage = _stage;
            this.stageHeader = capStageName;

            if(this._currentStage.name == 'edit' || this._currentStage.name == 'review'){
                this.isNewVersionDocument = true;
            }
            this.coordinatorHeader = formatParameterizedCustomLabel(this.labels.ticketWorkflowCoordinatorHeader, [
                capStageName
            ]);
        }
    }

    get documentIcon() {
        return iconLookup(this.documentInfo?.name);
    }

    get documentName() {
        return this.documentInfo?.name;
    }

    get docModifiedDate() {
        return this.documentInfo?.currentVersion.modifiedDate;
    }

    get isCompleted() {
        return this._currentStage?.isCompleted;
    }

    handleShareClick(){
        this.isShareModalOpen = true;
    }

    closeShareModal(event){
        this.isShareModalOpen = false;
    }

    handleEmailSent() {
        showToast(this, this.labels.adminSuccess,this.labels.ticketShareEmailSuccess, "SUCCESS");
    }

    
   async connectedCallback() {
    if(this._currentStage.name == 'edit' || this._currentStage.name == 'review'){
        if(this.ticketStatus == 'completed'){
            this.isNewVersionDocument = false;
        }else{
            this.isNewVersionDocument = true;
        }
    }
        getcurrentUserEmail()
        .then((result)=>{
            this.currentUserEmailId = result.userEmail;
            this.currentUserName = result.userName
            if(this._currentStage.name == 'review'){
                this.evisortuser();
            }else{
            this.getUserInfo = true;
            }
        });
        this.documentIds.oldDocumentId = this.fileInfo.content.ContentDocumentID;
        this.documentIds.ticketEvisortRecordId = this.ticketEvisortRecordId;
        this.documentId = this.documentInfo.id;
        this.contentDocumentId = this.fileInfo.content.ContentDocumentID;
        this.init();
        if (this._currentStage.isCompleted == true) {
            this.getEvisort();
        }
    }

   async evisortuser(){
        await getEvisortUsers()
        .then((res)=>{
            let userData = JSON.parse(res);
            userData.forEach((ele)=>{
                this.evisortUsersList.push({label: ele.full_name, value: ele.id});
            });
            const sortedFields = this.evisortUsersList.sort(sortByLabel);
            this.evisortUsersList = sortedFields;
            this.getUserInfo = true;
        });
    }

    init(){
        if((this._currentStage.phases).length >0){
            var numberOfJudgment = 0;
            var numberOfsigned = 0;
            var numberofActiveSigners = 0;
            this._currentStage.phases.forEach((phase)=>{
                
                    phase.judgments.forEach((judgement)=>{
                        if((judgement.judgment.signer).hasOwnProperty('partyId')){
                            this.showSignUploadButton = true;
                        }else{
                            this.showSignUploadButton = false;
                        }
                        numberOfJudgment++;
                        if(judgement.status == 'signed'){
                            numberOfsigned++;
                        }
                        judgement.approvals.forEach((e)=>{
                           if(e.hasOwnProperty(USER) == true){
                            numberofActiveSigners++;
                           }
                           if(e.hasOwnProperty(EXTERNAl_USER) == true){
                            numberofActiveSigners++;
                           }
                        })    
                    })              
                });
                if(numberOfJudgment != numberofActiveSigners || numberOfJudgment == numberOfsigned){
                    this.disableUploadSign = true
                }
            }else{
                this.showSignUploadButton = false;
        }
        if(this.ticketStatus == 'completed'){
            this.showSignUploadButton = false;
        }
    }

    handleDownload(event) {
        const docId = this.fileInfo.content.ContentDocumentID;
        this[NavigationMixin.Navigate](
            {
                type: "standard__webPage",
                attributes: {
                    url: `/sfc/servlet.shepherd/document/download/${docId}`
                }
            },
            false
        );
    }

    handleNewVersionClick(){
        this.isNewVersionModalOpen = true;
    }

    closeNewVersionModal(event){
        this.isNewVersionModalOpen = false;
    }

    refreshComponent(){
        const searchevent = new CustomEvent("updatecomponent");
        this.dispatchEvent(searchevent);
    }

    uploadSignedhandle(){
        this.isShowModal = true;
    }

    closeShowModal(event){
        this.isShowModal = event.detail;
    }

    @api
    refreshAll(){
        this.init();
        this._currentStage.phases.forEach((ele) => {
            var reviewItemIndex = 0;
            this.template.querySelectorAll("c-ticket-review-items").forEach((element) => {
                if(ele.hasOwnProperty("position") && ele.position == reviewItemIndex){
                    element.reviewItem = ele;
                    element.ticketReviewStage = this._currentStage.name;
                    element.refreshReviewer();
                }
                reviewItemIndex += 1;
            });
        });
        this.template.querySelectorAll("c-evisort-upload-new-version").forEach((element) => {
            element.refreshAll();
        });
        this.template.querySelectorAll("c-ticket-upload-signed").forEach((element) => {
            element.refreshSpinner();
        });
    }

    getEvisort() {
        getEvisortRecord({ ticketId: this.ticketRecordId })
            .then((result) => {
                this.evisortTicketId = result;
                if (isBlank(this.evisortTicketId)) {
                    this.showIsCompletedModal = false;
                } else {
                    this.showIsCompletedModal = true;
                }
            })
    }

    openEvisortPage() {
        window.open('/' + this.evisortTicketId, "_blank");
    }
}