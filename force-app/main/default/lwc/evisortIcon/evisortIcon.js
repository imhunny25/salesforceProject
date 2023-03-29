import { LightningElement, api} from 'lwc';
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";

export default class EvisortIcon extends LightningElement {
    @api cls;

    iconSvgUrl = Evisort_Resources + "/evisortResources/evisortIcon.svg#colorIcon";
}