import LightningDatatable from "lightning/datatable";
import customName from "./customName.html";

export default class TicketListTable extends LightningDatatable {
    static customTypes = {
        customName: {
            template: customName,
            standardCellLayout: true,
            typeAttributes: [
                "evisortName",
                "handleClick",
                "status",
                "id",
                "stage",
                "evisortId",
                "submittedBy",
                "createdDate"
            ]
        }
    };
}