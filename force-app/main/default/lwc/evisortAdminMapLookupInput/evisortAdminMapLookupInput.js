import { LightningElement, api } from "lwc";
import { RELATIONSHIP_TYPES , isBlank} from "c/csUtils";
import labels from "c/labelService";

export default class EvisortAdminMapLookupInput extends LightningElement {
    label = labels;

    @api mappingItem;

    get isInputEnable(){
        if(!isBlank(this.mappingItem)){
            return !this.mappingItem.isRelationshipEnable;
        }
        return false;
    }
    
    get parsePlaceholderLabel() {
        if (this.mappingItem.relationshipType === RELATIONSHIP_TYPES.parentLookup) {
            return this.label.adminMapIntakeFormsRelationship;
        }
        return this.label.adminMapIntakeFormsChildRelationship;
    }

    handleMapping(event) {
        const { name, workflowFieldId, mapping } = event.target.dataset;
        this.dispatchEvent(
            new CustomEvent("updatemapping", {
                detail: {
                    value: event.target.value,
                    relationshipType: this.mappingItem.relationshipType,
                    dataset: {
                        workflowFieldId,
                        mapping,
                        name
                    }
                }
            })
        );
    }

    @api
    setCustomValidity(msg) {
        let input = this.template.querySelector("lightning-input");
        input.setCustomValidity(msg);
    }

    @api
    reportValidity() {
        let input = this.template.querySelector("lightning-input");
        return input.reportValidity();
    }
}