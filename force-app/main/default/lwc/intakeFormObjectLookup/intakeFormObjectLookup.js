import { LightningElement, api, track } from "lwc";
import { formatParameterizedCustomLabel, RELATIONSHIP_TYPES } from "c/csUtils";
import labels from "c/labelService";

export default class IntakeFormObjectLookup extends LightningElement {
    labels = labels;
    isLoading = false;
    _childObjects;
    _childMap;

    @api
    get childObjects() {
        return this._childObjects;
    }

    set childObjects(value) {
        this._childObjects = this.normalizeChildObjects(JSON.parse(JSON.stringify(value)));
    }

    normalizeChildObjects(data) {
        const _objects = [];
        Object.entries(data).forEach(([key, value]) => {
            const workflowFieldId = key;

            Object.keys(value).forEach((_key) => {
                _objects.push({
                    id: _key,
                    relationshipApi: _key,
                    relationshipType: RELATIONSHIP_TYPES.childLookup,
                    records: value[_key],
                    workflowFieldId,
                    workflowField: value[_key][0]?.workflowField,
                    label: formatParameterizedCustomLabel(this.labels.ticketIntakeFormObjectLookupLabel, [_key])
                });
            });
        });

        return _objects;
    }

    /**
     * Creating a Map of the child objects so that the records
     * received from the back end can be reduced to their common sObject
     */
    connectedCallback() {
        const childMap = new Map();

        this._childObjects.forEach((child) => {
            if (childMap.has(child.relationshipApi)) {
                const data = childMap.get(child.relationshipApi);
                data.workflowFields.push(child.workflowField);
                data.workflowFieldIds.push(child.workflowFieldId);

                childMap.set(child.relationshipApi, data);
            } else {
                const { workflowField, label, records, workflowFieldId } = child;
                childMap.set(child.relationshipApi, {
                    workflowFields: [workflowField],
                    workflowFieldIds: [workflowFieldId],
                    label,
                    records
                });
            }
        });

        this.dispatchLookupTotal(childMap.size);

        this._childMap = childMap;
    }

    get childRecordsForUI() {
        const arr = [];
        for (const [key, value] of this._childMap) {
            const { label, workflowFields, records, workflowFieldIds } = value;
            const wFieldInfo = this.createFieldList(workflowFields);
            arr.push({ key, label, wFieldInfo, records, workflowFields, workflowFieldIds });
        }
        return arr;
    }

    createFieldList(workflowFields) {
        const limit = 3;
        let fArray = [];
        let excessNum;
        let fieldText;

        // Cautiously preventing duplicates with Set
        const fields = new Set(workflowFields);
        fArray = Array.from(fields);

        fArray.sort();

        excessNum = fArray.length - limit;
        if (excessNum > 0) {
            const fieldString = fArray.slice(0, limit).join(", ");
            fieldText = formatParameterizedCustomLabel(this.labels.ticketMappedFieldsWithExcess, [
                fieldString,
                excessNum
            ]);
        } else {
            fieldText = formatParameterizedCustomLabel(this.labels.ticketMappedFieldsForRecord, [fArray.join(", ")]);
        }

        fieldText = fieldText.replaceAll("[[", "<b>").replaceAll("]]", "</b>");

        return fieldText;
    }

    handleRecordSelected(e) {
        const records = this.findChildObject(e.detail);
        this.dispatchEvent(
            new CustomEvent("selectedrecord", {
                detail: records
            })
        );
    }

    handleRecordRemoved(e) {
        const { detail } = e;
        this.dispatchEvent(
            new CustomEvent("removedrecord", {
                detail
            })
        );
    }

    dispatchLookupTotal(num) {
        this.dispatchEvent(
            new CustomEvent("lookuptotal", {
                detail: {
                    lookupTotal: num
                }
            })
        );
    }

    findChildObject(eventDetail) {
        let records = [];
        eventDetail.workflowFieldIds.forEach((wFieldId) => {
            const mapping = this._childObjects.find((item) => item.workflowFieldId === wFieldId);
            const _record = mapping.records.find((item) => item.id === eventDetail.id);
            records.push({
                ..._record,
                workflowFieldId: wFieldId
            });
        });
        return records;
    }

    @api
    checkForSelectedRecords() {
        const comps = this.template.querySelectorAll("c-lookup");
        const isLookupValid = [];
        comps.forEach((comp) => {
            isLookupValid.push(comp.checkForSelectedRecord());
        });

        const isValid = isLookupValid.reduce((validSoFar, validity) => {
            return validSoFar && validity;
        }, true);

        return isValid;
    }
}