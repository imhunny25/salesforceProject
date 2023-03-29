import { api, LightningElement, track } from "lwc";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import { currencyOptions, isComplexPayloadObject, formatParameterizedCustomLabel, EVS_FIELDS, isBlank,iconLookup } from "c/csUtils";
import { isTypeWithUserOption, handleDefaultWhenOptionMissing, SPECIAL_VALUE_OPTION } from "./fieldMappingUtils";
import labels from "c/labelService";

export default class IntakeFormFieldMapping extends LightningElement {
    @api isTicketCompleted;
    @api isViewTicket = false;
    @api workflowId;
    @api isAllowMulti;
    @api isAllowSingle;
    @api hasTicketId;
/* ------------------ 21-03-2023---------------------*/
    @api objectApiName;
    @api recordId;

    @track multipleFiles = true;
    @track isVisible = true;
    @track _isUpdateable;
    @track isEditMode = true;
    @track selectedRegions;
    @track _question;
    @track showDirtyBackground = false;
    @track requiredCount = 0;
    @track isOptionRequired = false;
    @track selectedMultiFieldValue = [];
    @track previousField;

    hasRenderedInEditMode = false;

    nameRequired = true;
    /**
     * Property could be an Object, String, Array, of Number
     * But both properties values should always be same
     * Dependent of EVS field type
     *
     * @property originalFieldValue
     * @property newFieldValue
     */
    @track originalFieldValue;
    @track newFieldValue;

    options;
    multiValues;
    countryData;
    selectedRegionData;
    timePeriodVal;
    timePeriod;
    currency;
    amount;
    evsFieldType;
    enableCreateOptions = false;
    enableOtherOption;
    enableOtherOptionForCheckbox;
    isCheckboxSelectionEmpty;
    createOptionsLabel = "";
    createOptionsValue = "";
    labels = labels;
    selectedValueIsOther = null;

    @api
    clearDirtyBg() {
        this.showDirtyBackground = false;
        this.createOptionsValue = "";
    }

    @api
    get question() {
        return this._question;
    }

    set question(value) {
        if (this.isViewTicket) {
            this._question = value;
        } else {
            this._question = this.normalizeDefaultValues(JSON.parse(JSON.stringify(value)));
        }

        this.originalFieldValue = this.getFilteredObjData(value) ? this.getFilteredObjData(value) : "";
        this.evsFieldType = this.filterFieldType(value);
    }

    @api
    get readOnly() {
        return this.isEditMode;
    }

    get fieldLabel(){
        if (this.question.hasOwnProperty("field")) {
            return this.question.title;
        }
        return this.question.name;
    }

    set readOnly(value) {
        this.isEditMode = !value;
    }

    @api
    get isUpdateable() {
        return this._isUpdateable;
    }

    set isUpdateable(value) {
        if (!value) {
            this._isUpdateable = false;
            return;
        }

        this._isUpdateable = value;
    }

    @api
    getNewFieldValue() {
        let data;
        if (this.createOptionsValue && this.evsFieldType === EVS_FIELDS.SINGLE_SELECT) {
            data = this.createOptionsValue;
        } else if (this.createOptionsValue && this.evsFieldType === EVS_FIELDS.MULTI_SELECT) {
            data = this.multiValues.concat(this.createOptionsValue);
        } else if (this.evsFieldType === EVS_FIELDS.CHECKBOX || this.evsFieldType === EVS_FIELDS.RADIO) {
            data = {
                other_value: this.createOptionsValue,
                value: this.newFieldValue || this.multiValues
            };
        } else if (this.evsFieldType === EVS_FIELDS.USER || this.evsFieldType === EVS_FIELDS.DEPARTMENT) {
            if (this.isAllowMulti) {
                data = this.template.querySelector("c-evisort-multi-select-search-input").getSelectedFields();
            }
            if (this.isAllowSingle) {
                data = this.template.querySelector("c-evisort-single-select-search-input").getSelectedField();
            }
        } else {
            if(this.evsFieldType === EVS_FIELDS.MULTI_SELECT){
                let selectedFieldValue = [];
                this.template.querySelector('lightning-dual-listbox').value.forEach((ele)=>{
                    selectedFieldValue.push(ele);
                })
                const field = this.template.querySelector("lightning-input[data-enable-create-opt]");
                if (field && field.value && !isBlank(selectedFieldValue) && !selectedFieldValue.includes(field.value)) {
                    selectedFieldValue.push(field.value);
                }
                    data = selectedFieldValue;
            }else{
            data = this.newFieldValue;
            }
        }
        if (this.evsFieldType === EVS_FIELDS.FILE) {
            this.template.querySelector("c-document-upload").deleteFiles();
        }
        const details = { fieldId: this._question.field.id, type: this.evsFieldType, data };
        
        return details;
    }

    @api
    updateValue() {
        this.originalFieldValue = this.newFieldValue;
        this.newFieldValue = null;
        this.showDirtyBackground = false;
        this.isEditMode = false;
        this.createOptionsValue = "";
        let comps =  [...this.template.querySelectorAll("c-evisort-multi-select-search-input")];
        comps.forEach((comp) => comp.copySelectedDataOnSuccess());
        comps =  [...this.template.querySelectorAll("c-evisort-single-select-search-input")];
        comps.forEach((comp) => comp.copySelectedDataOnSuccess());
    }

    @api
    get fieldVisibility() {
        return this.isVisible;
    }

    set fieldVisibility(visibilityObj) {
        const _fieldId = Object.keys(visibilityObj).find((item) => item === this._question.field.id);
        if (_fieldId) {
            this.isVisible = visibilityObj[_fieldId];
            if (!this.isVisible) {
                // when a field is not rendered, treat it as
                // valid and empty
                this.reportAsValidWhenNotRendered(_fieldId);
                this.reportAsEmptyWhenNotRendered(_fieldId);
            }
        } else {
            throw new Error("Field not found when applying conditional visibility");
        }
    }

    connectedCallback() {
        this.template.addEventListener("evs_editing", (event) => {
            this.handleEditMode();
        });
        let req = new XMLHttpRequest();
        req.open("GET", `${Evisort_Resources}/evisortResources/countryData.json`, false);
        req.send(null);

        this.countryData = JSON.parse(req.responseText);
        if (this.filterFieldType(this._question) === EVS_FIELDS.ADDRESS) {
            this.setRegion(this._question);
        }

        this.createCustomLabel(this.filterFieldType(this._question));
    }

    renderedCallback() {
        if (this.hasRenderedInEditMode) {
            return;
        }

        this.hasRenderedInEditMode = this.isEditMode;
        const isCheckbox = this.filterFieldType(this._question) === EVS_FIELDS.CHECKBOX;
        if (this.isViewTicket && isCheckbox && this.hasRenderedInEditMode) {
            this.checkBoxMultiValuesHelper();
        }
    }

    createCustomLabel(type) {
        switch (type) {
            case EVS_FIELDS.MULTI_SELECT:
                this.createOptionsLabel = formatParameterizedCustomLabel(labels.ticketFieldMappingMultiLabel, [
                    this._question.title
                ]);
                break;
            case EVS_FIELDS.SINGLE_SELECT:
                this.createOptionsLabel = formatParameterizedCustomLabel(labels.ticketFieldMappingSingleLabel, [
                    this._question.field?.name
                ]);
                break;
            default:
                this.createOptionsLabel = formatParameterizedCustomLabel(labels.ticketFieldMappingCheckboxLabel, [
                    this._question.title
                ]);
                break;
        }
    }

    get checkboxSelectedValues() {
        if (this.isViewTicket) {
            return Array.isArray(this.multiValues) ? this.newFieldValue || this.multiValues : [];
        }

        // Allows a lightning-dual-listbox to use SF mapped value from a text field
        return Array.isArray(this.multiValues) ? this.multiValues : [this.multiValues];
    }

    setRegion(_question) {
        const vData = this.getFilteredObjData(_question);
        if(!isBlank(vData) && !isBlank(vData.country)){
            this.selectedRegions = this.findCountryRegions(vData.country);
        }

        const country = this.checkDefaultValue("country");
        if(!isBlank(country)){
            this.selectedRegions = this.findCountryRegions(country);
        }

        if (vData && vData.hasOwnProperty("country")) {
            this.selectedRegions = this.findCountryRegions(vData.country);
        }
    }

    @api
    checkRequiredFile() {
        
        let noMissingFile = true;
        const filecomps = [...this.template.querySelectorAll("[data-fieldfile]")];
        filecomps.forEach((field) => {
            if (!field.requiredFieldUploadedCheck()) {
                noMissingFile = false;
            }
        });
        return noMissingFile;
    }

    findCountryRegions(nameValue) {
        if(!isBlank(nameValue)){
            nameValue = nameValue.toUpperCase();
        }
        let selectedCountry = this.countryData.find((item) => item.countryName.toUpperCase() === nameValue);
        if (!selectedCountry) {
            selectedCountry = this.countryData.find((item) => item.countryShortCode === nameValue);
        }
        if(isBlank(selectedCountry)){
            const country = this.checkDefaultValue("country");
            selectedCountry = this.countryData.find((item) => item.countryName === country);
        }

        if (!isBlank(selectedCountry) && !isBlank(selectedCountry.regions)) { 
            this.selectedRegionData = selectedCountry.regions;
            return selectedCountry.regions.map((region) => {
                return { label: region.name, value: region.name };
            });
        }
        return null;
    }

    get renderCheckboxInput() {
        return this.enableOtherOption || this.enableOtherOptionForCheckbox;
    }

    get isRequired() {
        return this._question.isRequired;
    }

    get isAddress() {
        const fieldType = this.filterFieldType(this._question);
        return fieldType === EVS_FIELDS.ADDRESS;
    }

    get isText() {
        const type = this.filterFieldType(this._question);
        return type === EVS_FIELDS.SHORT_RESPONSE;
    }

    get isFile() {
        return this.filterFieldType(this._question) === EVS_FIELDS.FILE;
    }

    get isDate() {
        return this.filterFieldType(this._question) === EVS_FIELDS.DATE;
    }

    get isEmail() {
        const fieldType = this.filterFieldType(this._question);
        return fieldType === EVS_FIELDS.EMAIL;
    }

    getDefaultcurrency(question){
        if (question.hasOwnProperty("field") && question.field.hasOwnProperty("customSettings") &&
            question.field.customSettings.hasOwnProperty("defaultValue") && 
            question.field.customSettings.defaultValue.hasOwnProperty("currency")){
                return question.field.customSettings.defaultValue.currency;
        }
    }

    get isCurrency() {
        const isCurr = this.filterFieldType(this._question) === EVS_FIELDS.MONETARY_VALUE;
        if (isCurr && this._question.field.mappedValue) {
            if (this.hasTicketId) {
                const { amount = "", currency_x, currency } = this.getFilteredObjData(this._question);
                this.amount = amount;
                this.currency = currency_x || currency;
            }
            else {
                this.amount = this._question.field.mappedValue;
                this.currency = this.getDefaultcurrency(this._question);
            }
        } 
        return isCurr;
    }

    get isNumber() {
        return this.filterFieldType(this._question) === EVS_FIELDS.NUMBER;
    }

    @api
    get isAllowMultipleSearch() {
        if (
            this._question.field.customSettings.allow_multiple &&
            (this._question.field.type == EVS_FIELDS.USER || this._question.field.type == EVS_FIELDS.DEPARTMENT)
        )
            this.isAllowMulti = true;
        else this.isAllowMulti = false;
        return this.isAllowMulti;
    }

    @api
    get isAllowSingleSearch() {
        if (
            this._question.field.customSettings.allow_multiple != true &&
            (this._question.field.type == EVS_FIELDS.USER || this._question.field.type == EVS_FIELDS.DEPARTMENT)
        )
            this.isAllowSingle = true;
        else this.isAllowSingle = false;
        return this.isAllowSingle;
    }

    get fieldId() {
        return this._question.fieldId;
    }

    get isPercent() {
        return this.filterFieldType(this._question) === EVS_FIELDS.PERCENTAGE;
    }

    get isCheckbox() {
        const isCheckbox = this.filterFieldType(this._question) === EVS_FIELDS.CHECKBOX;
        let _options = isCheckbox ? this._question.field.customSettings.options : [];

        if (isCheckbox && !this.isViewTicket) {
            this.options = _options;
            const { multiValues, enableOtherOption, createOptionsValue } = handleDefaultWhenOptionMissing(
                this._question.field
            );

            this.multiValues = multiValues;
            this.enableOtherOption =
                enableOtherOption && (this.selectedValueIsOther === null || this.selectedValueIsOther);

            if (multiValues?.includes(SPECIAL_VALUE_OPTION) || multiValues === SPECIAL_VALUE_OPTION) {
                this.createOptionsValue = this._question.field?.value;
            } else {
                this.createOptionsValue = createOptionsValue;
            }
        }

        if (isCheckbox && this.isViewTicket) {
            // Normalizes supplied options if a manual value was added previously
            // Adds it to the options array so it's available
            _options = this.normalizeSelectedValues(this._question.field);

            this.enableOtherOption = this.newFieldValue
                ? this.newFieldValue?.includes(SPECIAL_VALUE_OPTION)
                : !!this._question.field.mappedValue?.other_value;
            this.createOptionsValue = this.enableOtherOption
                ? this.createOptionsValue || this._question.field.mappedValue?.other_value
                : "";
        }

        if (isCheckbox && !this.isEditMode) {
            // Create single string of values for readOnly display
            this.multiValues = this.filterFieldValue(this._question)?.join(", ");
        }

        if (isCheckbox && this.isEditMode) {
            this.options = _options;

            // Making sure if a user option was chosen that "Other" appears as correctly selected
            if (this.isViewTicket) {
                this.checkBoxMultiValuesHelper();
            } else if (this._question.field.mappedValue && !this.multiValues) {
                this.multiValues = this.mappedValueHelper(this._question.field.mappedValue);
            }
        }
        return isCheckbox;
    }

    checkBoxMultiValuesHelper() {
        const _multiValues = this.isViewTicket
            ? [...this.filterFieldValue(this._question)]
            : this.filterFieldValue(this._question);

        // Making sure if a user option was chosen that "Other" appears as correctly selected
        if (this._question.field.mappedValue?.other_value && !this.isCheckboxSelectionEmpty) {
            const idx = _multiValues?.indexOf(this._question.field.mappedValue?.other_value);

            if (idx >= 0) {
                _multiValues.splice(idx, 1, SPECIAL_VALUE_OPTION);
            }
        }

        this.multiValues = _multiValues;
    }

    get isMultiSelect() {
        const isMulti = this.filterFieldType(this._question) === EVS_FIELDS.MULTI_SELECT;
        this.enableCreateOptions = this._question.field.customSettings.enable_create_options;

        let _options = isMulti ? this._question.field.customSettings.options : [];

        if (!this.isViewTicket && isMulti) {
            const { createOptionsValue } = handleDefaultWhenOptionMissing(this._question.field);

            // With MULTI_SELECT, because more than one value can be selected, there is a valid case
            // when the SF default value is used as a User provided value and the EVS default is also selected.
            // For that reason, we need to check again if the SF value is in the field options and if so don't
            // populate the user input with the value.
            const foundOpt = this._question.field.customSettings.options?.find(
                (item) => item.label.toLowerCase() === this._question.field?.sfDefault?.toLowerCase()
            );

            this.createOptionsValue = createOptionsValue
                ? createOptionsValue
                : foundOpt
                ? ""
                : this._question.field?.sfDefault;
        }

        // Normalizes supplied options if a manual value was added previously
        // Adds it to the options array so it's available in the dropdown
        if (this.isViewTicket) {
            _options = this.normalizeSelectedValues(this._question.field);
        }

        if (isMulti && !this.isEditMode) {
            // Create single string of values for readOnly display
            this.multiValues = this.filterFieldValue(this._question)?.join(", ");
        }
        if (isMulti && this.isEditMode) {
            this.options = _options;
            var selectedValues = JSON.stringify(this.multiSelectFieldValue).includes(';');
            if(!this.hasTicketId && !isBlank(this.multiSelectFieldValue) && selectedValues){ 
                this.multiValues = this.multiSelectFieldValue.split(';');
            }else{
                this.multiValues = this.filterFieldValue(this._question);
            }
        }
        return isMulti;
    }

    get isSingleSelect() {
        const type = this.filterFieldType(this._question);
        const isSingle = type === EVS_FIELDS.SINGLE_SELECT;
        this.enableCreateOptions = this._question.field.customSettings.enable_create_options;

        let _options = isSingle ? this._question.field.customSettings.options : [];

        if (!this.isViewTicket && isSingle) {
            const { createOptionsValue } = handleDefaultWhenOptionMissing(this._question.field);

            this.createOptionsValue = createOptionsValue ? createOptionsValue : "";
        }
        // Normalizes supplied options if a manual value was added previously
        // Adds it to the options array so it's available in the dropdown
        if (this.isViewTicket) {
            _options = this.normalizeSelectedValues(this._question.field);
        }

        if (isSingle && this.isEditMode) {
            this.options = _options;
        }
        return isSingle;
    }

    get isTimePeriod() {
        const type = this.filterFieldType(this._question);
        const isTime = type === EVS_FIELDS.TIME_PERIOD;

        if (isTime) {
            this.options = this._question.field.customSettings.options;
            if (this.getFilteredObjData(this._question)) {
                const { amount, period } = this.getFilteredObjData(this._question);
                this.amount = amount;
                this.timePeriodVal = period;
                this.timePeriod = period?.charAt().toUpperCase() + period.slice(1);
            }
        }
        return isTime;
    }

    get isTextArea() {
        return this.filterFieldType(this._question) === EVS_FIELDS.LONG_RESPONSE;
    }

    get singleSelectValue() {
        return this.newFieldValue || this.filterFieldValue(this._question);
    }

    get isRadio() {
        const isRadio = this.filterFieldType(this._question) === EVS_FIELDS.RADIO;
        let _options = isRadio ? JSON.parse(JSON.stringify(this._question.field.customSettings.options)) : [];

        if (isRadio && !this.isViewTicket && this._question.field.mappedValue) {
            this.options = _options;
            const { multiValues, enableOtherOption, createOptionsValue } = handleDefaultWhenOptionMissing(
                this._question.field
            );
            this.multiValues = multiValues;

            if (!this.handledCheckboxOrRadioChange) {
                this.enableOtherOption =
                    enableOtherOption && (this.selectedValueIsOther === null || this.selectedValueIsOther);
            }

            if (multiValues?.includes(SPECIAL_VALUE_OPTION) || multiValues === SPECIAL_VALUE_OPTION) {
                this.createOptionsValue = this._question.field?.value;
            } else {
                this.createOptionsValue = createOptionsValue;
            }

            if (enableOtherOption && multiValues === SPECIAL_VALUE_OPTION) {
                this._question.field.mappedValue = multiValues;
            }
        }

        if (isRadio && this.isViewTicket) {
            this.enableOtherOption = this.newFieldValue
                ? this.newFieldValue?.includes(SPECIAL_VALUE_OPTION)
                : !!this._question.field.mappedValue?.other_value;
        }

        if (isRadio && !this.isEditMode) {
            this.multiValues = this._question.field.mappedValue?.value;
            this.createOptionsValue = this._question.field.mappedValue?.other_value
                ? this._question.field.mappedValue?.other_value
                : this._question.field.mappedValue?.value;
        }

        if (isRadio && this.isEditMode) {
            this.options = _options;

            // Making sure if a user option was chosen that "Other" appears as correctly selected
            if (this.isViewTicket) {
                this.createOptionsValue = this.enableOtherOption
                    ? this.createOptionsValue || this._question.field.mappedValue?.other_value
                    : "";
                this.radioOptionsHelper(this._question.field);
            }
        }
        return isRadio;
    }

    radioOptionsHelper(field) {
        let optValues = [];
        this.multiValues = this._question.field.mappedValue?.value;
        this.options.forEach((option) => {
            optValues.push(option.value);
        });

        if (field.customSettings.enable_other_option && !optValues.includes(SPECIAL_VALUE_OPTION)) {
            this.options.push({ label: "Other", value: SPECIAL_VALUE_OPTION });
        }
    }

    get parseNumericStep() {
        return this._question.field.customSettings?.allow_decimals ? "0.01" : "1";
    }

    get currencyOptions() {
        return currencyOptions.map(({ label, value }) => {
            return { label, value: value.toUpperCase() };
        });
    }

    // EVENTS: Handling and dispatching

    /**
     * Uses the native onchange event to capture input values
     * of all the fields at the time the Save is clicked.
     */
    @api
    dispatchFieldValue() {
        let fields = [...this.template.querySelectorAll("[data-field]")];
        fields.forEach((field) => {
            const event = new Event("change");
            field.dispatchEvent(event);
        });
    }


    handleMultiFieldChange(event){
        const { id, type, label, enableCreateOpt } = event.target.dataset;
        const { validity } = event.target;
        this.selectedMultiFieldValue = [];
        this.normalizeValue(this.evsFieldType, event).forEach(ele => {
            this.selectedMultiFieldValue.push(ele);
        });

        // Get the value of the User supplied option
        const field = this.template.querySelector("lightning-input[data-enable-create-opt]");
        if (field && field.value && !isBlank(this.selectedMultiFieldValue) && !this.selectedMultiFieldValue.includes(field.value)) {
        // Make the value variable mutable.
            this.selectedMultiFieldValue.push(field.value);     
        }

        this.dispatchValidity(validity.valid, id);

        this.dispatchEvent(
            new CustomEvent("intakefieldchange", {
                detail: {
                    fieldId: id,
                    evisortType: type,
                    value: this.selectedMultiFieldValue == null ? "" : this.selectedMultiFieldValue,
                    enableCreateOpt,
                    label: label || null
                }
            })
        );
    }
    
    handleInputMultiFieldChange(event){
        const { id, type, label, enableCreateOpt } = event.target.dataset;
        const { validity } = event.target;
        if(this.requiredCount == 0){
            this.isOptionRequired = this._question.isRequired;
            this.requiredCount = 1;
        }

        const field = this.template.querySelector("lightning-input[data-enable-create-opt]");

        if (this._isUpdateable != true && enableCreateOpt && this.isOptionRequired) {
            if(field.value.replace(/\s/g, '').length){
                this._question.isRequired = false;
            }else{
                this._question.isRequired = true;
            }
        }

        if(!isBlank(this.previousField) && this.previousField != field.value){
            if(!isBlank(this.selectedMultiFieldValue)){
                this.selectedMultiFieldValue.forEach((element,index)=>{
                    if(!isBlank(this.previousField) && this.previousField == element){
                        this.selectedMultiFieldValue.splice(index, 1);
                    }
                });
            }
        }

        if (field && field.value && !isBlank(this.selectedMultiFieldValue) && !this.selectedMultiFieldValue.includes(field.value)) {
            this.selectedMultiFieldValue.push(field.value);
            this.previousField = field.value;    
        }
        else if(field && field.value && isBlank(this.selectedMultiFieldValue)){
            let inputValue = JSON.parse(JSON.stringify(field.value));
            this.selectedMultiFieldValue.push(inputValue);
            this.previousField = field.value; 
        }
        this.dispatchValidity(validity.valid, id);
        this.dispatchEvent(
            new CustomEvent("intakefieldchange", {
                detail: {
                    fieldId: id,
                    evisortType: type,
                    value: this.selectedMultiFieldValue == null ? "" : this.selectedMultiFieldValue,
                    enableCreateOpt,
                    label: label || null
                }
            })
        );
    }

    handleFieldChange(event) {
        const { id, type, label, enableCreateOpt } = event.target.dataset;
        const { validity } = event.target;
        // Combobox LWC returns selected values differently than other components
        let value = this.normalizeValue(this.evsFieldType, event);

        if(this.requiredCount == 0){
            this.isOptionRequired = this._question.isRequired;
            this.requiredCount = 1;
        }
        // DO NOT add a User created option for SELECT type fields here
        if (this.isViewTicket && this.isEditMode && !enableCreateOpt) {
            let complexFieldPayload;
            let areValuesEqual;

            if (isComplexPayloadObject(this.evsFieldType)) {
                value = this.createNewComplexFieldPayload(value);
                areValuesEqual = this.isFieldValueEqualToPrevious(value, complexFieldPayload);
            } else {
                areValuesEqual = this.isFieldValueEqualToPrevious(value);
            }

            this.newFieldValue = areValuesEqual ? null : value;
            this.showDirtyBackground = !areValuesEqual;
        }

        if ((type === EVS_FIELDS.CHECKBOX || type === EVS_FIELDS.RADIO) && !enableCreateOpt) {
            this.selectedValueIsOther = value?.includes(SPECIAL_VALUE_OPTION) || value === SPECIAL_VALUE_OPTION;
            this.enableOtherOption = this.selectedValueIsOther;
            this.handledCheckboxOrRadioChange = true;

            if (type === EVS_FIELDS.CHECKBOX) {
                this.enableOtherOptionForCheckbox = this.selectedValueIsOther;
                this.isCheckboxSelectionEmpty = this.isViewTicket && !value.length;

                // Empty the input value if Other is removed from selected values
                if (!this.enableOtherOption) {
                    this.createOptionsValue = "";
                }
            }
        }

        // Don't grab the field if it's own blur event fired
        if (type === EVS_FIELDS.MULTI_SELECT && !enableCreateOpt) {
            // Get the value of the User supplied option
            const field = this.template.querySelector("lightning-input[data-enable-create-opt]");
            if (field && field.value && !value.includes(field.value)) {
                // Make the value variable mutable.
                value = JSON.parse(JSON.stringify(value));

                value.push(field.value);
            }
        }

        if (this._isUpdateable != true && type === EVS_FIELDS.SINGLE_SELECT && enableCreateOpt && this.isOptionRequired) {
            if(value.replace(/\s/g, '').length){
                value = JSON.parse(JSON.stringify(value));
                this._question.isRequired = false;
            }else{
                this._question.isRequired = true;
            }
        }

        if (this.isEditMode && isTypeWithUserOption(type) && enableCreateOpt) {
            this.createOptionsValue = value;
            this.showDirtyBackground = this.isViewTicket && value.length;

            if (type === EVS_FIELDS.CHECKBOX) {
                this.enableOtherOptionForCheckbox = true;
            }
        }

        this.dispatchValidity(validity.valid, id);

        if (type === EVS_FIELDS.ADDRESS && label === "country") {
            if (typeof value === "string" && value.length) {
                this.selectedRegions = this.findCountryRegions(value);
            } else if (typeof value === "object") {
                this.selectedRegions = this.findCountryRegions(value.country);
            }
        }

        this.dispatchEvent(
            new CustomEvent("intakefieldchange", {
                detail: {
                    fieldId: id,
                    evisortType: type,
                    value: value == null ? "" : value,
                    enableCreateOpt,
                    label: label || null
                }
            })
        );
    }

    /**
     * Event bubbles past the component shadow DOM so that
     * an listener can catch the event further up the DOM
     * tree than the parent.
     *
     * If two inputs with the same Id are found; reduce the validity
     * to a single value and dispatch that.
     *
     * @param {boolean} isValid
     * @param {String} fieldId
     */
    dispatchValidity(_isValid, fieldId) {
        const inputs = [...this.template.querySelectorAll(`[data-id="${fieldId}"]`)];
        let isValid = _isValid;

        if (inputs.length > 1) {
            isValid = inputs
                .map((input) => input.reportValidity())
                .reduce((validSoFar, validity) => {
                    return validSoFar && validity;
                }, true);
        }

        this.dispatchEvent(
            new CustomEvent("evs_formvalidity", {
                bubbles: true,
                composed: true,
                detail: {
                    fieldId,
                    isValid
                }
            })
        );
    }

    reportAsEmptyWhenNotRendered(fieldId) {
        if (this.isViewTicket) {
            this.newFieldValue = "";
        }

        const inputs = [...this.template.querySelectorAll(`[data-id="${fieldId}"]`)];
        inputs.forEach((input) => {
            this.dispatchEvent(
                new CustomEvent("intakefieldchange", {
                    detail: {
                        fieldId: input.dataset.id,
                        evisortType: input.dataset.type,
                        value: "",
                        enableCreateOpt: input.dataset.enableCreateOpt,
                        label: input.dataset.label || null
                    }
                })
            );
        });
    }

    reportAsValidWhenNotRendered(fieldId) {
        this.dispatchEvent(
            new CustomEvent("evs_formvalidity", {
                bubbles: true,
                composed: true,
                detail: {
                    fieldId,
                    isValid: true
                }
            })
        );
    }

    handleFileUpload(event) {
        const { id, type } = event.target.dataset;
        let updateDocument = {
            documentId:event.detail.documentId
        }
        this.newFieldValue = updateDocument;
        this.dispatchEvent(
            new CustomEvent("attachmentupload", {
                detail: {
                    fieldId: id,
                    evisortType: type,
                    value: "",
                    documentId: event.detail.documentId
                }
            })
        );
    }

    handleEditMode() {
        this.dispatchEvent(
            new CustomEvent("evs_editing", {
                bubbles: true,
                composed: true,
                detail: {
                    isEditing: true
                }
            })
        );
    }

    handleFileRemoved(event) {
        const { id, type } = event.target.dataset;
        let updateDocument = {
            documentId:null
        }
        this.newFieldValue = updateDocument;
        this.dispatchEvent(
            new CustomEvent("attachmentremoved", {
                detail: {
                    fieldId: id,
                    evisortType: type,
                    documentId: null
                }
            })
        );
    }

    @api reloadMultiSelectData() {
        let comps =  [...this.template.querySelectorAll("c-evisort-multi-select-search-input")];
        comps.forEach((comp) => comp.reloadFieldValuesOnCancel());
    }

    @api reloadSingleSelectData() {
        let comps =  [...this.template.querySelectorAll("c-evisort-single-select-search-input")];
        comps.forEach((comp) => comp.reloadFieldValueOnCancel());
    }

    // Methods for readOnly

    /**
     * Pencil icon needs to be hidden in this order:
     * 1) The user does not have permission to edit (isUpdateable)
     * 2) The ticket is complete, OR
     * 3) If ticket is not complete, then refer to isEditMode.
     */
    get hidePencilIcon() {
        if (!this._isUpdateable) {
            return true;
        }

        return this.isTicketCompleted || this.isEditMode;
    }

    get isDisabled() {
        return !this.isEditMode;
    }

    /**
     * When it comes to Addresses, if a workflow is mapped to an Address field
     * on a SF record the individual field names differ in some respects to
     * what the EVS API will return. eg. SF: "street" vs EVS: "street_1"
     * If a SF address is mapped to a workflow field that takes priority.
     * Therefore that value returns first if truthy.
     *
     * See also formattedZip
     */
    get formattedStreet1() {
        const _mappedValues = this.filterFieldValue(this._question);
        const street = _mappedValues?.street ? _mappedValues?.street : "";
        const street_1 = _mappedValues?.street_1 ? _mappedValues?.street_1 : "";

        return street || street_1;
    }

    get formattedStreet2() {
        const _mappedValues = this.filterFieldValue(this._question);
        const street_2 = _mappedValues?.street_2 ? _mappedValues?.street_2 : "";

        return street_2;
    }

    get combinedStreets() {
        const _mappedValues = this.filterFieldValue(this._question);
        const street = _mappedValues?.street ? _mappedValues?.street : "";
        const street_2 = _mappedValues?.street_2 ? _mappedValues?.street_2 : "";
        const street_1 = _mappedValues?.street_1 ? _mappedValues?.street_1 : "";

        const _street_1 = street || street_1;

        // Salesforce record address takes priority;
        // If the SF name 'street' is truthy no need to use the EVS 'street_2'
        // becasuse SF does not have this field
        const _street_2 = street ? "" : street_2;

        return `${_street_1} ${_street_2}`;
    }

    get formattedState() {
        const _mappedValues = this.filterFieldValue(this._question);
        let state = _mappedValues?.state ? _mappedValues?.state : "";        
        let country = _mappedValues?.country ? _mappedValues?.country : "";
        let selectedCountry; 
        let checkCountry;
        if(!isBlank(_mappedValues)){
            checkCountry = _mappedValues.hasOwnProperty("country");
            if(checkCountry){
                selectedCountry = this.countryData.find((item) => item.countryName.toUpperCase() ===  country.toUpperCase());
                if(isBlank(selectedCountry)){
                    selectedCountry = this.countryData.find((item) => item.countryShortCode === country.toUpperCase());
                }
            }
        }

        if(isBlank(state) || !checkCountry || isBlank(selectedCountry)){
            state = this.checkDefaultValue("state");
            if(!isBlank(state)){
                this.selectedRegions = this.findCountryRegions(this._question.field.customSettings.defaultValue.country);
            }
        }

        if (!this.selectedRegionData) {
            return state;
        }

        let selectedState = this.selectedRegionData.find((item) => item.name.toUpperCase() === state.toUpperCase());
        if (!selectedState) {
            selectedState = this.selectedRegionData.find((item) => item.shortCode === state.toUpperCase());
        }

        if (!selectedState) {
            return "";
        }

        return selectedState.name;
    }

    get formattedCity() {
        const _mappedValues = this.filterFieldValue(this._question);
        const city = _mappedValues?.city ? _mappedValues?.city : "";

        return city;
    }

    get formattedCountry() {
        const _mappedValues = this.filterFieldValue(this._question);
        let country = _mappedValues?.country ? _mappedValues?.country : "";

        let selectedCountry = this.countryData.find((item) => item.countryName.toUpperCase() === country.toUpperCase());
        if (!selectedCountry) {
            selectedCountry = this.countryData.find((item) => item.countryShortCode === country.toUpperCase());
        }

        if(isBlank(selectedCountry)){
            country = this.checkDefaultValue("country");
            selectedCountry = this.countryData.find((item) => item.countryName === country)
        }
        if (!selectedCountry) {
            return "";
        }

        return selectedCountry.countryName;
    }

    /**
     * This method is used to check the Evisort field default value.
     * default values exist or not.
     */
    checkDefaultValue(value){
        let defaultValue = '';
        if(this._question.hasOwnProperty("field") && this._question.field.hasOwnProperty("customSettings") && 
        this._question.field.customSettings.hasOwnProperty("defaultValue") && this._question.field.customSettings.defaultValue.hasOwnProperty(value)){
            for(var keys in this._question.field.customSettings.defaultValue){
                if(keys == value){
                    defaultValue =  this._question.field.customSettings.defaultValue[keys];
                }
            }
        }
        return defaultValue;
    }

    /**
     * See note at formattedStreet1
     */
    get formattedZip() {
        const _mappedValues = this.filterFieldValue(this._question);
        const postalCode = _mappedValues?.postalCode ? _mappedValues?.postalCode : "";
        const zip_code = _mappedValues?.zip_code ? _mappedValues?.zip_code : "";

        return postalCode || zip_code;
    }

    get computedFormClass() {
        return this.isEditMode ? "slds-form-element" : "slds-form-element_readonly";
    }

    /**
     * Helper Utils for Mapping
     * These methods for filtering help parse the different data shape
     * between fields during new intake forms or in the ticket modal
     */

    get filteredFieldId() {
        if (this._question.hasOwnProperty("field")) {
            return this._question.field.id;
        }

        return this._question.fieldId;
    }

    get filteredFieldType() {
        if (this._question.hasOwnProperty("field")) {
            return this._question.field.type;
        }

        return this._question.type;
    }

    get filteredFieldValue() {
        const { mappedValue: _mappedValue } = this._question.field;
        if (this._question.hasOwnProperty("field")) {
            if (_mappedValue?.hasOwnProperty("value")) {
                return _mappedValue.value;
            }
            return _mappedValue;
        }

        return this._question.value.value;
    }
    get attachmentFilesOnEdit(){
        if (this._question.hasOwnProperty("field") && this._question.field.hasOwnProperty("value")) {
            return this._question.field.value;
        }
    }

    get showAttachmentFiles(){
        let multipleFilesNames = [];
        if (this._question.hasOwnProperty("field") && this._question.field.hasOwnProperty("value") && this._question.field.value.hasOwnProperty("valueList")) {
            this._question.field.value.valueList.forEach((field) => {
                let fileIcon = iconLookup(field.fileName +field.fileType);
                multipleFilesNames.push({'fileName':field.fileName +field.fileType,'fileIcon':fileIcon});
            });
        }
        return multipleFilesNames;
    }

    get multiSelectFieldValue(){
        if (this._question.hasOwnProperty("field") && this._question.field.hasOwnProperty("value")) {
            if(this._question.field.value.hasOwnProperty("value")){
                return this._question.field.value.value;
            }else{
                return this._question.field.value;
            }
        }
    }

    get filteredFieldLabel() {
        if (this._question.hasOwnProperty("field")) {
            return this._question.title;
        }

        return this._question.name;
    }

    get filteredFieldDescription() {
        if (this._question.hasOwnProperty("description")) {
            return this._question.description;
        }
    }

    get allowedFileTypeRule(){
        if(this._question.field.customSettings.hasOwnProperty("allowed_file_type_rule")){
            return this._question.field.customSettings.allowed_file_type_rule;
        }else {
            return null;
        }
    }

    get allowedFileTypes(){
        if(this._question.field.customSettings.hasOwnProperty("allowed_file_types")){
            return this._question.field.customSettings.allowed_file_types;
        }else{
            return null;
        }

    }

    filterFieldType(fieldItem) {
        const item = this.getFilteredFieldItem(fieldItem);
        return item?.type;
    }

    filterFieldValue(fieldItem) {
        if (fieldItem.hasOwnProperty("field")) {
            if (fieldItem.field.type === EVS_FIELDS.CHECKBOX || fieldItem.field.type === EVS_FIELDS.MULTI_SELECT) {
                if (this.isViewTicket) {
                    return fieldItem.field.mappedValue?.valueList;
                }
                let valueString;
                if(fieldItem.field.type === EVS_FIELDS.CHECKBOX){
                    valueString = Array.isArray(fieldItem.field.mappedValue)
                        ? fieldItem.field.mappedValue
                        : [fieldItem.field.mappedValue];
                }
                if (valueString && this.isViewTicket) {
                    return valueString.split(";");
                }

                if(fieldItem.field.type === EVS_FIELDS.MULTI_SELECT){
                    valueString = this.selectedMultiFieldValue;
                    return valueString;
                }
                return valueString;
            }
            return this.mappedValueHelper(fieldItem.field.mappedValue);
        }

        return fieldItem.value.value;
    }

    get countryPicklistOptions() {
        const options = this.countryData.map((item) => {
            return { label: item.countryName, value: item.countryName };
        });

        return options;
    }

    /**
     * Parses the question to sniff out the valid data
     * @param {Object} fieldItem The question data object
     * @returns
     */

    getFilteredFieldItem(fieldItem) {
        if (fieldItem?.hasOwnProperty("field")) {
            return fieldItem.field;
        }

        return fieldItem;
    }

    /**
     * Parses the question to return the valid address data.
     * ADDRESS Field type is the ONLY type returned by EVISORT API,
     * when there is not a 'field' key, that the value object is
     * not nested like other fields. eg: fieldItem.value.value
     *
     * @param {Object} fieldItem The question data object
     * @returns
     */
    getFilteredObjData(fieldItem) {
        if (fieldItem.hasOwnProperty("field")) {
            return fieldItem.field.mappedValue;
        }

        return fieldItem.value;
    }

    /** Methods for Edit State */

    get computeEditWrapperClasses() {
        const base = "slds-p-around_small slds-p-top_none";
        return this.showDirtyBackground ? `${base} input-wrapper_edit-state` : base;
    }

    createNewComplexFieldPayload() {
        let fields;
        let payloadObj = {};
        switch (this.evsFieldType) {
            case EVS_FIELDS.ADDRESS:
                fields = [...this.template.querySelectorAll("[data-address]")];

                fields.forEach((field) => {
                    if (Object.keys(this.originalFieldValue).includes(field.dataset.label)) {
                        payloadObj[field.dataset.label] = field.value;
                    }
                });

                // Sort the Object keys for comparing later
                payloadObj = this.sortObjectByKeys(payloadObj);

                return payloadObj;

            case EVS_FIELDS.MONETARY_VALUE:
                fields = [...this.template.querySelectorAll("[data-currency]")];
                fields.forEach((field) => {
                    payloadObj[field.dataset.label] = field.value;
                });

                payloadObj = this.sortObjectByKeys(payloadObj);

                return payloadObj;

            case EVS_FIELDS.TIME_PERIOD:
                fields = [...this.template.querySelectorAll("[data-time]")];
                fields.forEach((field) => {
                    payloadObj[field.dataset.label] = field.value;
                });

                payloadObj = this.sortObjectByKeys(payloadObj);

                return payloadObj;

            default:
        }
    }

    isFieldValueEqualToPrevious(_newFieldValue, complexPayload) {
        if (isComplexPayloadObject(this.evsFieldType)) {
            // Free the data of the LWC Locker Service so stringified objects mattch
            const _originalFieldValue = Object.assign({}, this.originalFieldValue);

            if (typeof this.originalFieldValue === "object") {
                for (const [key, value] of Object.entries(_originalFieldValue)) {
                    _originalFieldValue[key] = value.toString();
                }
            }
            if (this.stringifyAndCompare(_originalFieldValue, complexPayload)) {
                this.newFieldValue = null;
                return true;
            }
        }

        if (this.evsFieldType === EVS_FIELDS.RADIO && this.originalFieldValue.length === 0) {
            if (_newFieldValue === undefined) {
                return true;
            }
        }

        if (this.evsFieldType === EVS_FIELDS.DATE && this.originalFieldValue.length === 0) {
            if (_newFieldValue === null) {
                return true;
            }
        }

        if (Array.isArray(_newFieldValue)) {
            const normOrigValueList = this.originalFieldValue.valueList ? this.originalFieldValue.valueList : [];
            const isEqual =
                _newFieldValue.length === normOrigValueList.length &&
                _newFieldValue.every(function (element) {
                    return normOrigValueList.includes(element);
                });

            if (isEqual) {
                this.newFieldValue = null;
                return true;
            }
        }
        if (_newFieldValue === this.originalFieldValue) {
            this.newFieldValue = null;
            return true;
        }

        return false;
    }

    stringifyAndCompare(value1, value2) {
        return JSON.stringify(value1) === JSON.stringify(value2);
    }

    sortObjectByKeys(objToSort) {
        return Object.keys(objToSort)
            .sort()
            .reduce((obj, key) => {
                obj[key] = objToSort[key];
                return obj;
            }, {});
    }

    normalizeValue(evsType, event) {
        const { value } = event.target;
        const { label } = event.target.dataset;

        switch (evsType) {
            case EVS_FIELDS.DATE:
                // Date field returns null when emptied
                return value === null ? "" : value;

            case EVS_FIELDS.MONETARY_VALUE:
                // If string, convert to number
                return label === "amount" ? value * 1 : value;

            case EVS_FIELDS.TIME_PERIOD:
                return label === "amount" ? value * 1 : value;

            case EVS_FIELDS.PERCENTAGE:
                return value * 1;

            case EVS_FIELDS.NUMBER:
                return value * 1;

            default:
                return value;
        }
    }

    /**
     * Determines if there is a value provided by a SF record (`sfDefault`)
     * or a default value provided by the EVS platform (`evsDefault`).
     * `sfDefault` takes precedence over `evsDefault`. The correct default value
     * then overwrites or sets `mappedValue`
     *
     * @param {*} question the entire question data object
     * @returns question data object
     */
    normalizeDefaultValues(question) {
        const { mappedValue, customSettings } = question.field;
        const hasUserOption = !!customSettings.enable_create_options || !!customSettings.enable_other_option;
        const _isTypeWithUserOption = isTypeWithUserOption(this.evsFieldType);
        const sfDefault =
            !!mappedValue && (Object.keys(mappedValue).length || typeof mappedValue === "number") ? mappedValue : null;

        let evsDefault =
            customSettings.defaultValue && Object.keys(customSettings.defaultValue).length
                ? customSettings.defaultValue
                : null;

        // With the exception of ADDRESS, Evisort default values are keyed at `value`
        if (evsDefault && evsDefault.hasOwnProperty("value")) {
            evsDefault = evsDefault.value;
        }

        const defaultValue = hasUserOption ? sfDefault || evsDefault : sfDefault ? sfDefault : evsDefault;

        if (defaultValue || typeof defaultValue === "number") {
            // At this point the correct default value should be valid; Add it as mappedValue.
            // If a field has options find confirm the default value is in the options.
            if (_isTypeWithUserOption) {
                question.field.mappedValue = this.findOption(defaultValue, evsDefault, customSettings);
                question.field.sfDefault = sfDefault;
            } else {
                question.field.mappedValue = this.findOption(defaultValue, evsDefault, customSettings);
            }
        }

        return question;
    }

    findOption(defaultValue, evsDefault, customSettings) {
        const _options = customSettings.options;
        const hasUserOption = !!customSettings.enable_create_options || !!customSettings.enable_other_option;

        if (Array.isArray(defaultValue)) {
            const common = _options?.filter((item) => {
                return defaultValue.map((_item) => _item.toLowerCase()).includes(item.value.toLowerCase());
            });

            return common.map((item) => item.value);
        }

        if (typeof defaultValue === "string" && _options?.length) {
            const foundOpt = _options?.find((item) => item.label.toLowerCase() === defaultValue?.toLowerCase());

            return foundOpt ? foundOpt.value : hasUserOption ? defaultValue : evsDefault;
        }

        return defaultValue;
    }

    mappedValueHelper(mappedValue) {
        if (!isBlank(mappedValue) && mappedValue.hasOwnProperty("value")) {
            return mappedValue.value;
        }

        return mappedValue;
    }

    /**
     * Parses a field item when the EVS type is SELECT or MULTI_SELECT
     * If the field value is not in the options provided:
     * For SINGLE_SELECT add it to the options array so it's available in the dropdown
     * For MULTI_SELECT add the diff to the valuesList for display as a selected value
     *
     * @param {Object} fieldItem
     * @returns {Array} options for a dropdown
     */
    normalizeSelectedValues(fieldItem) {
        const fieldValue = fieldItem.mappedValue;
        const _options = fieldItem.customSettings.options ? [...fieldItem.customSettings.options] : [];

        if (fieldItem.type === EVS_FIELDS.SINGLE_SELECT) {
            const _item = _options.filter((item) => item.value === fieldValue);

            if (_item && _item.length === 0) {
                _options.push({ label: fieldValue, value: fieldValue });
            }

            return _options;
        }

        if (fieldItem.type === EVS_FIELDS.MULTI_SELECT) {
            let _valueList = fieldItem.mappedValue?.valueList;

            const objLabels = _options.map((item) => item.label);

            if (_valueList) {
                const diff = _valueList.filter((item) => !objLabels.includes(item));

                if (diff && diff.length) {
                    diff.forEach((value) => {
                        _options.push({ label: value, value });
                    });
                }
            }

            return _options;
        }

        if (fieldItem.type === EVS_FIELDS.CHECKBOX) {
            if (fieldItem.mappedValue && fieldItem.mappedValue.other_value) {
                _options.push({ label: "Other", value: SPECIAL_VALUE_OPTION });
            }

            return _options;
        }
    }

    @api
    retrieveSelectedValues(event) {
        var selectedValues = [];
        if (this.isAllowMulti) {
            let multiSelect = this.template.querySelector("c-evisort-multi-select-search-input").getSelectedFields();
            selectedValues.push({ question: this.question, value: multiSelect });
        }
        if (this.isAllowSingle) {
            let singleSelect = this.template.querySelector("c-evisort-single-select-search-input").getSelectedField();
            selectedValues.push({ question: this.question, value: singleSelect });
        }
        return selectedValues;
    }

    handleValidateSelected(event) {
        this.dispatchValidity(event.detail.hasValue, event.detail.fieldId) ;
    }

    handleSelectionChange(event) {
        this.dispatchEvent(
            new CustomEvent("intakefieldchange", {
                detail: {
                    fieldId: this.filteredFieldId,
                    evisortType: this.filteredFieldType,
                    value: "",
                    enableCreateOpt: this._question.field.customSettings.enable_create_options,
                    label: this.createOptionsLabel
                }
            })
        );
        this.dispatchValidity(event.detail.hasChanged, this.filteredFieldId) ;
    }
}