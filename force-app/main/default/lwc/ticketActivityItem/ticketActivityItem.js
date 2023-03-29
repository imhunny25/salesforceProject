import { api, LightningElement } from "lwc";
import { getActivityString, TICKET_ACTIVITY_TYPE } from "./activityItemUtils";
import { isBlank } from "c/csUtils";
export default class TicketActivityItem extends LightningElement {
    @api activityItem;
    activityText;

    connectedCallback() {
        const text = getActivityString(this.activityItem);
        if (!isBlank(text)) {
            this.activityText = text.replaceAll("{{", "<b>").replaceAll("}}", "</b>");
        }
    }

    get hasMessage() {
        return !!this.activityItem.data?.body;
    }

    get isJudgmentStatusUpdate() {
        return this.activityItem.action === TICKET_ACTIVITY_TYPE.JUDGMENT_RESULT_STATUS_UPDATE;
    }
}