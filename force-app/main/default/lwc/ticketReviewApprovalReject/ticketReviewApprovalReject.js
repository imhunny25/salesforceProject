import { LightningElement,track,api,wire } from 'lwc';
import ticketReviewStatus from "@salesforce/apex/TicketController.ticketReviewStatus";
import {
    getFilteredErrorMessage,
    showToast,
    handleFieldChangeForConditions as _handleFieldChangeForConditions,isBlank
} from "c/csUtils";
import labels from "c/labelService";



export default class TicketReviewApprovalReject extends LightningElement {
    label = labels;
    @api approval;
    @api currentTicketId;
    @api ticketIssueuId;
    @api ticketOwnerId;
    @api currentUserEmailId;
    @api isTicketStatus;
    @api evisortUsersList;

    @track isShowModal = false;
    @track ticketActionLabel = '';
    @track disableResetButton = true;
    @track disableApproveRejectButton = false;
    @track approvedTicket = false;
    @track rejectButtonActive = false;
    @track ticketReject = false;
    @track titleCommentBox = '';
    @track commentReason = '';
    @track disableConfirmButton = false;
    @track updateTicketError = '';
    @track isTicketComplete = false;
    @track disableAssignToMeButton = true;
    @track evisortUser = [];
    searchInput = '';
    @track showClose = true;
    @track isReassignuser = false;
    @track isEvisortUserEnable = false;
    @track isUserNotMatch = false;
    @track reassignDisable = true;
    @track isInputDisabled = false;
    
    ticketStatus = {
        ticketId : '',
        issueId : '',
        status : '',
        comments : {}
    }

    connectedCallback(){
        if(this.isTicketStatus == 'completed'){
            this.isTicketComplete = true;
        }
        this.ticketStatus.ticketId = this.currentTicketId;
        this.ticketStatus.issueId = this.ticketIssueuId;
        this.ticketStatus.comments.comment = '';
        if(this.approval.status == 'approved'){
            this.approvedTicket = true;
            this.disableApproveRejectButton = true;
            this.disableResetButton = false;
        }
        if(this.approval.status == 'rejected'){
            this.ticketReject = true;
            this.commentReason = this.approval.comment;
            this.disableApproveRejectButton = true;
            this.disableResetButton = false;
        }
        if(this.currentUserEmailId != this.approval.user.email){
            this.disableAssignToMeButton = false;
            this.disableResetButton = true;
            this.disableApproveRejectButton = true;
        
        }
    }

    handelTicketApprove(){
        this.refreshSpinner(true);
        this.ticketStatus.status = 'approve';
        this.ticketStatus.comments.comment = '';
        this.updateTicketReviewStatus();
    }

    handelTicketReject(){
        this.rejectButtonActive = true;
        this.disableConfirmButton = true;
        this.isShowModal = true;
        this.ticketActionLabel = labels.ticketRejectTicketStatus;
        this.titleCommentBox = labels.ticketCommentOutliningOnReject;
    }
    
    handleTicketReset(){
        this.isShowModal = true;
        this.ticketActionLabel = labels.ticketResetTicketStatus;
        this.titleCommentBox = labels.ticketCommentOutliningOnReset;
    }

    closeShowModal(){
        this.isShowModal = false;
        this.rejectButtonActive = false;
    }
    
    inputComment(event){
        var comment = event.target.value;
        this.ticketStatus.comments.comment = comment;
        if(this.rejectButtonActive == true){
            if(comment.replace(/\s/g, '').length){
                this.commentReason = comment;
                this.disableConfirmButton = false;
            }else{
                this.disableConfirmButton = true;
            }
        }
    }
            
    confirmApproveComments(){
        this.refreshSpinner(true);
        if(this.rejectButtonActive == true){
            this.ticketStatus.status = 'reject';
            this.isShowModal = false;           
            this.updateTicketReviewStatus();
        }
        else{
            this.ticketStatus.status = 'reset';
            this.isShowModal = false;
            this.resetTicketReviewStatus();
        }
    }

    updateTicketReviewStatus(){
        const ticketStatusDetails = JSON.stringify(this.ticketStatus);
        ticketReviewStatus({ticketStatusDetails})
        .then((res)=>{
            this.setStatus(res);
            
        })
        .catch((error) => {
            this.updateTicketError = getFilteredErrorMessage(error);
            this.refreshSpinner(false);
        })
    }

    refreshComponent(){
        const searchevent = new CustomEvent("updatecomponent");
        this.dispatchEvent(searchevent);
    }

    resetTicketReviewStatus(){
        const ticketStatusDetails = JSON.stringify(this.ticketStatus);
        ticketReviewStatus({ticketStatusDetails})
        .then((res)=>{
            this.setStatus(res);
        })
        .catch((error) => {
            this.updateTicketError = getFilteredErrorMessage(error);
            this.refreshSpinner(false);
        })
    }

    handleTicketAssignToMe(){
        this.refreshSpinner(true);
        this.userReassign()
        this.ticketStatus.comments.new_user = this.ticketOwnerId;
        const ticketStatusDetails = JSON.stringify(this.ticketStatus);
        
        ticketReviewStatus({ticketStatusDetails})
        .then((res)=>{
            this.setStatus(res);
        })
        .catch((error) => {
            this.updateTicketError = getFilteredErrorMessage(error);
            this.refreshSpinner(false);
        })
    }

    setStatus(res){
        let data = JSON.parse(res);
            for(var element in data.approvals){
                if(data.approvals[element].user.email == this.currentUserEmailId){
                    if(data.approvals[element].status == 'approved'){
                        this.ticketReject = false;
                        this.approvedTicket = true;
                        this.disableResetButton = false;
                        this.disableApproveRejectButton = true;

                    } else if(data.approvals[element].status == 'rejected'){
                        this.rejectButtonActive = false;
                        this.approvedTicket = false;
                        this.ticketReject = true;
                        this.disableResetButton = false;
                        this.disableApproveRejectButton = true;

                    }
                    else if(data.approvals[element].status == 'pending'){
                        this.approvedTicket = false;
                        this.ticketReject = false;
                        this.disableResetButton = true;
                        this.disableApproveRejectButton = false;
                    }
                    this.disableAssignToMeButton = true;

                    break ;
                }
                if(data.approvals[element].user.email != this.currentUserEmailId){
                    if(data.approvals[element].status == 'approved'){
                        this.approvedTicket = true;
                    }else if(data.approvals[element].status == 'rejected'){
                        this.ticketReject = true;
                    }else{
                        this.approvedTicket = false;
                        this.ticketReject = false;
                        this.disableResetButton = true;
                        this.disableAssignToMeButton = false;
                        this.disableApproveRejectButton = false;
                    }
                }
             }
             this.updateTicketError = '';
             this.refreshComponent();
    }
    
    @api
    refreshReviewer(){
        this.updateTicketError = '';
    }

    handleTicketReassign(){
        this.isReassignuser = true;
        this.evisortUser = this.evisortUsersList;
    }

    searchFields(inputValue) {
        if (inputValue != '') {
            this.evisortUser = [];
            this.evisortUsersList.forEach((element)=> {
                if (element.label.toLowerCase().includes(inputValue.toLowerCase()) 
                    && !this.evisortUser.some(searchResult => searchResult.label === element.label)) {
                        this.evisortUser.push(element);
                }
            });
            if (this.evisortUser.length == 0 ) {
                this.isUserNotMatch = true;
            }
            else{
                this.isUserNotMatch = false;
            }
        }
        else {
            this.evisortUser = this.evisortUsersList;
        }
    }

    handleFieldSearch(event) {
        this.searchInput = event.target.value;
        this.isfieldListLoaded = false;
        if(this.searchInput.length > 0){
            this.showClose = false;
        }
        this.isUserNotMatch = false;
        this.searchFields(event.target.value);
        if (!this.isEvisortUserEnable) {
            /* 
            * Setting timeout to make sure the list view is visible
            * in case the parent div's onclick event has occurred 
            * causing the list view to hide
            */
            setTimeout(()=> {
                this.isEvisortUserEnable = true;
            }, 5);
        }
    }

    handlerSelectUser(event) {
        this.searchInput = event.currentTarget.dataset.label;
        this.isEvisortUserEnable = false;
        this.reassignDisable = false;
        this.isInputDisabled = true;
        if(isBlank(event.currentTarget.dataset.value)){
            this.reassignDisable = true;
        }
        this.userReassign()
        this.ticketStatus.comments.new_user = {};
        this.ticketStatus.comments.new_user.id = event.currentTarget.dataset.value;
        
        this.showClose = false;
    }

    closeReassignHandler(){
        this.isReassignuser = false;
        this.isEvisortUserEnable = false;
        this.searchInput = '';
        this.showClose = true;
        this.isInputDisabled = false;   
        this.updateTicketError = '';  
        this.reassignDisable = true;   
        
    }

    clearSearchField() {
        this.searchInput = '';
        this.evisortUser = this.evisortUsersList;
        this.showClose = true;
        this.isUserNotMatch = false;
        this.reassignDisable = true;
        this.isInputDisabled = false; 
        this.updateTicketError = '';       
    }

    handleSearchBlur() {
        setTimeout(()=> {
            this.isEvisortUserEnable = false;
        }, 300);
    }
    handleSearchFocus(){
        this.isEvisortUserEnable = true;
    }

    handleReassign(){
        this.refreshSpinner(true);
        const ticketStatusDetails = JSON.stringify(this.ticketStatus);
        this.reassignDisable = true;
        ticketReviewStatus({ticketStatusDetails})
        .then((res)=>{
        this.isReassignuser = false;
        this.searchInput = '';
        this.showClose = true;
        this.setStatus(res);
        })
        .catch((error) => {
            this.refreshSpinner(false);
            this.reassignDisable = false;  
            this.updateTicketError = getFilteredErrorMessage(error);
        })
    }

    get reassignButtonDisable(){
        return this.reassignDisable;
    }

    userReassign(){
        this.ticketStatus.status = 'reassign';
        this.ticketStatus.comments = {};
        this.ticketStatus.comments.current_user = {};
        this.ticketStatus.comments.current_user.id = this.approval.user.id;
    }
    refreshSpinner(isSpinner){
        const searchevent = new CustomEvent("spinnerupdate",{
            detail : isSpinner
        });
        this.dispatchEvent(searchevent);
    }
}