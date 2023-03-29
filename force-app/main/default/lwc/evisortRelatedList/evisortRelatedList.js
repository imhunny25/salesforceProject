import { LightningElement, api, track, wire } from "lwc";
import getEvisortRecords from "@salesforce/apex/EvisortController.getEvisortRecords";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage } from "c/csUtils";

const columns = [
    {
        type: "url",
        fieldName: "evisortRecordUrl",
        label: "Name",
        typeAttributes: { label: { fieldName: "evisortRecordName" } },
        hideDefaultActions: true
    },
    {
        type: "text",
        fieldName: "originalFileName",
        label: "File Name",
        hideDefaultActions: true
    },
    {
        type: "text",
        fieldName: "documentStatus",
        label: "Status",
        hideDefaultActions: true
    }
];

export default class EvisortRelatedList extends LightningElement {
    @api recordId;
    @api title;
    @track data = [];

    iconSvgUrl = Evisort_Resources + "/evisortResources/evisortIcon.svg#colorIcon";
    label = labels;
    columns = columns;
    loaded = false;

    get isEmpty() {
        return this.loaded === true && this.data.length === 0;
    }

    @wire(getEvisortRecords, { recordId: "$recordId" })
    loadRecords({ error, data }) {
        if (data) {
            this.data = data;
            this.loaded = true;
        } else if (error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
    }
}