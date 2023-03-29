import { LightningElement, api } from "lwc";
import { parseInitials } from "c/csUtils";
import labels from "c/labelService";

export default class TicketContributors extends LightningElement {
    _assignees = [];
    _participants = [];
    labels = labels;

    @api
    set assignees(data) {
        const _data = JSON.parse(JSON.stringify(data));
        const aArray = [];
        _data?.forEach((item) => {
            item.participant.initials = parseInitials(item.participant.name);
            aArray.push(item.participant);
        });

        this._assignees = aArray;
    }

    get assignees() {
        return this._assignees;
    }

    @api
    set participants(data) {
        const _data = JSON.parse(JSON.stringify(data));
        const pArray = [];
        _data?.forEach((item) => {
            item.participant.initials = parseInitials(item.participant.name);
            pArray.push(item.participant);
        });

        this._participants = pArray;
    }

    get participants() {
        return this._participants;
    }

    get hasParticipants() {
        return this._participants.length;
    }

    get hasAssignees() {
        return this._assignees.length;
    }

    get hasDataToRender() {
        return this._assignees.length || this._participants.length;
    }
}