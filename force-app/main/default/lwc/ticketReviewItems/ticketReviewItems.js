import { LightningElement, api,track } from "lwc";
import { parseInitials, formatParameterizedCustomLabel } from "c/csUtils";
import labels from "c/labelService";

const EXTERNAl_USER = "externalUser";
export default class TicketReviewItems extends LightningElement {
    @track _taskItem;
    singleTaskApprovals;
    hasMultipleTasks;
    labels = labels;

    @api reviewItem;
    @api currentTicketId
    @api currentUserEmailId;
    @api currentUserName;
    @api ticketReviewStage;
    @api ticketStatus;    
    @api evisortUsersList
    
    @track ticketOwnerId;
    @track ticketIssueuId;
    @track label = '';
    @track isTicketReviewStage = false;
    @track isShowSpinner = false;
    currentUserName;
    currentUserId = {}
    userDetails = {}

    async connectedCallback() {
        if(this.ticketReviewStage == 'review'){
            this.isTicketReviewStage = true;
        }
        this.userDetails.email = this.currentUserEmailId;
        this.userDetails.name = this.currentUserName;
           await this.init();
        }

       async init(){
        const _data = JSON.parse(JSON.stringify(this.reviewItem));
        if (_data.judgments) {
            _data.judgments.forEach((judgment) => {
                judgment.approvals.forEach((app, i, appArray) => {
                    if (app.hasOwnProperty("user")){
                        this.ticketOwnerId = this.userDetails;
                        if(app.user.email == this.currentUserEmailId){
                            this.currentUserId.id = app.user.id;
                            this.ticketOwnerId = this.currentUserId;
                        }
                    }
                    if (app.hasOwnProperty(EXTERNAl_USER)) {
                        appArray[i].externalUser.initials = parseInitials(app.externalUser.name);
                    } else {
                        if (app.user) {
                            appArray[i].user.initials = parseInitials(app.user.name);
                        }
                    }
                });
            });

            this.hasMultipleTasks = _data.judgments.length > 1;
            if (_data.judgments.length === 1) {
                this.ticketOwnerId = this.userDetails;
                this.ticketIssueuId = _data.judgments[0].id;
                this.singleTaskApprovals = _data.judgments[0].approvals;
            }
        }

        this._taskItem = _data;
        this.pendingLabel();
    }

    get hasTasks() {
        return this.findNumOfPendingTasks(this._taskItem.judgments) > 0;
    }

    pendingLabel() {
        const num = this.findNumOfPendingTasks(this._taskItem.judgments);

        if (num > 1) {
            this.label = formatParameterizedCustomLabel(this.labels.ticketPendingReviews, [num]);
        } else if (num === 1) {
            this.label = formatParameterizedCustomLabel(this.labels.ticketPendingReview, [num]);
        }

    }

    findNumOfPendingTasks(judgements) {
        return judgements.filter((item) => item.status === "pending").length;
    }
    refreshComponent(){
        const searchevent = new CustomEvent("updatecomponent");
        this.dispatchEvent(searchevent);
    }

    @api
    async refreshReviewer(){
        await this.init();
        this.template.querySelectorAll("c-ticket-review-approval-reject").forEach((element) => {
             element.refreshReviewer();
        });
        this.isShowSpinner = false;
    }

    isSpinner(event){
        this.isShowSpinner = event.detail;
    }
}