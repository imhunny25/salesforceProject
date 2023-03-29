import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { fromExpression } from "c/evsUtils";
import { evaluateFieldWithCondition } from "c/evaluateFieldWithCondition";

/**
 * Converts characters that act as parameters in Custom Labels.
 *
 * Example:
 *
 * let customLabel = 'Good {2}, "{1}". {{0}} doing "{{3}}"?';
 * let valuePosMapAry = ['How are you', 'Jane', 'morning', 'today'];
 * let str = formatParameterizedCustomLabel(customLabel, valuePosMapAry);
 *
 * // returns: 'Good morning, Jane. How are you doing today?'
 *
 * @param  {string} customLabel Initial string that may contain placeholders that match the pattern of "{0}", {0}, "{{0}}", or {{0}}
 * @param  {array}  valuePosMapAry Array of strings that map to the integer value inside each placeholder.
 * @return {string} String replaced with any matching values that exist in valuePosMapAry.
 */
export function formatParameterizedCustomLabel(customLabel = "", valuePosMapAry = []) {
    const regex = /"\{(\d+)\}"|\{\{(\d+)\}\}|"\{\{(\d+)\}\}"|\{(\d+)\}/g;
    const chars = /\{|\}|"\{|\}"/g;
    const matches = customLabel.match(regex);

    if (matches !== null && valuePosMapAry.length > 0) {
        const matchIndices = matches.map((match) => {
            return parseInt(match.replace(chars, ""), 10);
        });

        matches.forEach((valToReplace, i) => {
            customLabel = customLabel.replace(valToReplace, valuePosMapAry[matchIndices[i]]);
        });
    }

    return customLabel;
}

/**
 * Sometimes the backend returns an error message that is nested. This retrieves the message.
 *
 * @param  {object, string} msg Could be an object or a string
 * @return {string} Unpacked message
 */
export function getFilteredErrorMessage(msg = "") {
    if (msg.hasOwnProperty("message")) {
        return msg.message;
    }

    if (msg.hasOwnProperty("body") && msg.body.hasOwnProperty("message")) {
        return msg.body.message;
    }

    return msg;
}
/**
 * Fires platform ShowToastEvent to give users a notification of something that has happened.
 *
 * @param  {object} eventTarget The value of 'this' from the caller
 * @param  {string} title Title of the toast
 * @param  {string} message Message body of the toast
 * @param  {string} variant Possible variants are info, success, warning, and error
 * @param  {string} mode Possible modes are dismissable, sticky, and pester
 * @return {void}
 */
export function showToast(eventTarget, title = "", message = "", variant = "info", mode = "dismissable") {
    const evt = new ShowToastEvent({
        title,
        message: getFilteredErrorMessage(message),
        variant,
        mode
    });

    eventTarget.dispatchEvent(evt);
}

/**
 * Get the index of the matching object property. If the property exists in the
 * array of objects, it will return the index. Otherwise, it will return -1
 *
 * Example:
 *
 * let ary = [{id: 'foo'}, {id: 'bar'}];
 * let index = getObjIndex(ary, 'bar');
 * // returns: 1
 *
 * OR:
 *
 * let ary = [{name: 'foo'}, {name: 'bar'}];
 * let index = getObjIndex(ary, 'bar', 'name');
 * // returns: 1
 *
 * @param  {array} ary Array of objects
 * @param  {object} val Value to be searched in the given array of objects
 * @param  {string} prop Property of object to be searched. This param is not required and will default to 'id'.
 * @return {integer} 0 or greater (the actual index of the array) if true and -1 if false
 */
export function getObjIndex(ary = [], val = "", prop = "id") {
    return ary
        .map((item) => {
            return item[prop];
        })
        .indexOf(val);
}

/**
 * Proxy objects are unreadable in the console. During development, this method will allow
 * one to view Proxy object content in the browser dev console.
 *
 * Note: use this method only during development. Strip it out before going to production.
 *
 * @param {Object} proxyObj Proxy object to be logged
 * @param {String} title Title of log
 * @param {Array} colorConfig Optional to customize color of log (i.e., ['black','orange'])
 */
export function logProxy(proxyObj = {}, title = "Log Proxy", colorConfig = ["#222", "#fff"]) {
    console.info(
        `%c${title}`,
        `background-color: ${colorConfig[0]}; color: ${colorConfig[1]}; padding: 0.5rem;`,
        JSON.parse(JSON.stringify(proxyObj))
    );
}

/**
 * generates a uuid for use on the client.  i.e. used as keys for list iteration
 */
export function generateUUID() {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
        var r = (Math.random() * 16) | 0,
            v = c === "x" ? r : (r & 0x3) | 0x8;
        return v.toString(16);
    });
}

/**
 * Compare function for standard JS sort
 * Use with Array.sort(compareFunction)
 *
 * @param {Object} a First item for comparison
 * @param {Object} b 2nd item for comparison
 */

export function sortByLabel(a, b) {
    if (a.label < b.label) {
        return -1;
    } else if (a.label > b.label) {
        return 1;
    }
    return 0;
}

/**
 * Compare function to sort Intake Forms in this order:
 * Special Characters, Numeral, Alphabet
 *
 * Notes:
 * Treats underscore as Special Character
 * Use with Array.sort(compareFunction)
 *
 * @param {Object} a First item for comparison
 * @param {Object} b 2nd item for comparison
 */
export function sortIntakeFormName(a, b) {
    const specRegex = /^\W|_/;
    const digRegex = /^\d/;
    const alphaRegex = /^[a-zA-Z]/;

    // Convert everything to a number for comparison below when character is not of same type,
    const scoreA = specRegex.test(a.label) * 1 || digRegex.test(a.label) * 10 || alphaRegex.test(a.label) * 100;
    const scoreB = specRegex.test(b.label) * 1 || digRegex.test(b.label) * 10 || alphaRegex.test(b.label) * 100;

    if (scoreA !== scoreB) {
        return scoreA - scoreB;
    }

    // Otherwise use a regular sort
    if (a.label < b.label) {
        return -1;
    } else if (a.label > b.label) {
        return 1;
    }

    return 0;
}

/**
 * Parses a string representing a name and returns the firt two initials
 *
 * Example:
 * let name = 'R. tyler Malone'
 * let initials = parseInitials(name)
 * // returns 'RT'
 *
 *
 * @param {String} name
 * @returns {String}
 */
export function parseInitials(name = "") {
    return name
        .split(" ")
        .map((item) => item[0]?.toUpperCase())
        .join("")
        .slice(0, 2);
}

/**
 * Intakes a filename and parses the file extension
 * @param {String} fileName
 * @return {String} LDS icon name formatted for LWC
 */
export function iconLookup(fileName = "") {
    const fileExt = fileName.split(".").pop();

    switch (fileExt.toLowerCase()) {
        case "csv":
            return "doctype:csv";
        case "eps":
            return "doctype:eps";
        case "xls":
            return "doctype:excel";
        case "xlsx":
            return "doctype:excel";
        case "html":
            return "doctype:html";
        case "pdf":
            return "doctype:pdf";
        case "ppt":
            return "doctype:ppt";
        case "pptx":
            return "doctype:ppt";
        case "doc":
            return "doctype:word";
        case "docx":
            return "doctype:word";
        case "txt":
            return "doctype:txt";
        case "jpg":
            return "doctype:image";
        case "png":
            return "doctype:image";
        case "webp":
            return "doctype:image";
        case "zip":
            return "doctype:zip";
        case "mp3":
            return "doctype:audio";
        case "wav":
            return "doctype:audio";
        case "flac":
            return "doctype:audio";
        case "aac":
            return "doctype:audio";
        case "mp4":
            return "doctype:video";
        case "mov":
            return "doctype:video";
        case "avi":
            return "doctype:video";
        case "wmv":
            return "doctype:video";
        default:
            return "doctype:unknown";
    }
}

export const RELATIONSHIP_TYPES = {
    parentLookup: "parentLookup",
    childLookup: "childLookup"
};

export const currencyOptions = [
    { value: "Usd", label: "USD ($) - United States Dollar" },
    { value: "Aud", label: "AUD ($) - Australian Dollar" },
    { value: "Cad", label: "CAD ($) - Canadian Dollar" },
    { value: "Chf", label: "CHF (fr.) - Swiss Franc" },
    { value: "Cny", label: "CNY (¥) - Chinese Yuan (Renminbi)" },
    { value: "Dkk", label: "DKK (kr.) - Danish Krone" },
    { value: "Eur", label: "EUR (€) - European Euro" },
    { value: "Gbp", label: "GBP (£) - Great Britain (UK) Pound" },
    { value: "Hkd", label: "HKD ($) - Hong Kong Dollar" },
    { value: "Ils", label: "ILS (₪) - Israeli Shekel" },
    { value: "Inr", label: "INR (₹) - Indian Rupee" },
    { value: "Jpy", label: "JPY (¥) - Japanese Yen" },
    { value: "Krw", label: "KRW (₩) - South Korean Won" },
    { value: "Mxn", label: "MXN ($) - Mexican Peso" },
    { value: "Nok", label: "NOK (kr) - Norweigian Kroner" },
    { value: "Nzd", label: "NZD ($) - New Zealand Dollar" },
    { value: "Rub", label: "RUB (₽) - Russian Ruble" },
    { value: "Sek", label: "SEK (kr) - Swedish Krona" },
    { value: "Sgd", label: "SGD ($) - Singapore Dollar" },
    { value: "Thb", label: "THB (฿) - Thailand Baht" },
    { value: "Vnd", label: "VND (₫) - Vietnamese dong" }
];

export const EVS_FIELDS = {
    ADDRESS: "ADDRESS",
    CHECKBOX: "CHECKBOX",
    DATE: "DATE",
    DEPARTMENT: "DEPARTMENT",
    EMAIL: "EMAIL",
    FILE: "FILE",
    LONG_RESPONSE: "LONG_RESPONSE",
    MONETARY_VALUE: "MONETARY_VALUE",
    MULTI_SELECT: "MULTI_SELECT",
    NUMBER: "NUMBER",
    PERCENTAGE: "PERCENTAGE",
    RADIO: "RADIO",
    SHORT_RESPONSE: "SHORT_RESPONSE",
    SINGLE_SELECT: "SINGLE_SELECT",
    TIME_PERIOD: "TIME_PERIOD",
    USER: "USER"
};

export const TicketStatusType = {
    Approved: "approved",
    Completed: "completed",
    Editing: "editing",
    Done: "done",
    Pending: "pending",
    PendingCompletion: "pending completion",
    PendingFinalization: "pending finalization",
    PendingSignatures: "pending signatures",
    Queued: "queued",
    Rejected: "rejected",
    Review: "in review",
    SignaturePending: "signature pending",
    SignatureRequestNotSent: "signature request not sent",
    Signed: "signed",
    EmailDeliveryFailed: "email delivery failed"
};

export const TicketStageType = {
    Edit: "edit",
    Review: "review",
    Sign: "sign",
    Finalize: "finalize"
};

// Models the empty state of EVS field types
export const fieldValueModels = {
    ADDRESS: {
        street_1: "",
        street_2: "",
        city: "",
        state: "",
        country: "",
        zip_code: ""
    },
    CHECKBOX: {
        value: []
    },
    DATE: {
        value: ""
    },
    DEPARTMENT: {
        value: ""
    },
    EMAIL: {
        value: ""
    },
    FILE: {
        value: null
    },
    LONG_RESPONSE: {
        value: ""
    },
    MONETARY_VALUE: {
        amount: "",
        currency: ""
    },
    MULTI_SELECT: {
        value: []
    },
    NUMBER: {
        value: ""
    },
    PERCENTAGE: {
        value: ""
    },
    RADIO: {
        value: ""
    },
    SHORT_RESPONSE: {
        value: ""
    },
    SINGLE_SELECT: {
        value: ""
    },
    TIME_PERIOD: {
        period: "",
        amount: ""
    }
};
/**
 * Returns true if Evisort field has a complex
 * field value in payload
 *
 * @param {String} type Evisort field type
 * @returns boolean
 */
export function isComplexPayloadObject(type) {
    const { ADDRESS, MONETARY_VALUE, TIME_PERIOD } = EVS_FIELDS;
    return [ADDRESS, MONETARY_VALUE, TIME_PERIOD].includes(type);
}

export function parseFieldData(field) {
    if (typeof field.value === "object") {
        return { ...field.value };
    }
    return field.value.value ? field.value.value : field.value;
}

/**
 * Turns fields within an intake form sections into a single object where the key
 * is the field id and the value is the field item. Returned object is
 * used to determine the visibility of fields based on EVS field conditions.
 * 
 * Note: Implicit fields are fields that contain uneditable (and not visible to User)
 * meta data about the workflow. Conditions can use them. They are keyed with a unique 
 * human readable string.
 * Implicit fields need to be normalized along side regular fields
 * 
 * Implicit Field Ex:
 * { 
 *      "Workflow Name": {
            value: {
                value: "351 test"
            },
            type: "SHORT_RESPONSE",
            placeholder: null,
            name: "Workflow Name",
            description: "the name of the workflow"
        },
        ...
    }
 *
 * Regular field Ex:
 * {
        type: "EMAIL",
        placeholder: null,
        options: {},
        name: "Signer email",
        isSignerField: true,
        isEsignatureTagOptional: false,
        isEsignatureTag: false,
        id: "57693a39-298c-4cad-bacd-9b4d8e22973c",
        esignaturePlaceHolder: null,
        customSettings: {
            options: [],
            email_type: "none",
            defaultValue: {}
        }
    }
 *
 * @param {Array} formSections section data from EVS API response
 * @returns {Object} Object<fieldId, field>
 */

export function normalizeFieldsForConditions(formSections) {
    let fieldRecords = {};

    formSections.forEach((section) => {
        section.questions.forEach((question) => {
            question.field.value = modelValueByType(question.field);
            if (!question.field.conditionRule) {
                question.field.conditionRule = question.conditionRule;
            }
            fieldRecords[question.field.id] = question.field;
        });
    });

    return fieldRecords;
}

export function modelValueByType(field) {
    // mappedValue could be a number with numeric field types;
    // in that case Object.keys().length would be falsey with a value of 0
    const sfDefault =
        !!field.mappedValue && (Object.keys(field.mappedValue).length || typeof field.mappedValue === "number")
            ? field.mappedValue
            : null;

    let evsDefault =
        field.customSettings.defaultValue && Object.keys(field.customSettings.defaultValue).length
            ? field.customSettings.defaultValue
            : null;

    if (field.type === EVS_FIELDS.ADDRESS) {
        const defaultValue = sfDefault || evsDefault;

        if (defaultValue) {
            return defaultValue;
        }

        return fieldValueModels.ADDRESS;
    }

    if (field.type === EVS_FIELDS.MONETARY_VALUE) {
        // Currency was a reserved word in Apex
        // Return structure conditional evaluation can understand
        if (sfDefault) {
            return {
                amount: sfDefault.amount,
                currency: sfDefault.currency_x
            };
        }

        if (evsDefault) {
            return evsDefault;
        }

        return fieldValueModels.MONETARY_VALUE;
    }

    if (field.type === EVS_FIELDS.TIME_PERIOD) {
        const defaultValue = sfDefault || evsDefault;

        if (defaultValue) {
            return defaultValue;
        }

        return fieldValueModels.TIME_PERIOD;
    }

    if (field.type === EVS_FIELDS.FILE) {
        const defaultValue = sfDefault || evsDefault;

        if (defaultValue) {
            return defaultValue;
        }

        return fieldValueModels.FILE;
    }

    if (isStringReturnType(field.type)) {
        const defaultValue = sfDefault || evsDefault;

        if (defaultValue) {
            return defaultValue;
        }

        return {
            value: ""
        };
    }

    if (isNumberReturnType(field.type)) {
        const defaultValue = sfDefault || evsDefault;

        if (defaultValue) {
            return defaultValue;
        }

        return {
            value: ""
        };
    }

    if (isArrayReturnType(field.type)) {
        const defaultValue = sfDefault || evsDefault;

        // Apex typed deserializing forced us to put Array values at valueList
        // Returning a structure field condition evaluations can understand
        if (defaultValue?.valueList) {
            return {
                value: defaultValue.valueList
            };
        } else if (defaultValue) {
            return defaultValue;
        }

        return {
            value: []
        };
    }

    return { value: "" };
}

/**
 * EVS types that return a string at value.value
 * @param {*} type
 * @returns
 */
function isStringReturnType(type) {
    const { DATE, EMAIL, LONG_RESPONSE, RADIO, SHORT_RESPONSE, SINGLE_SELECT } = EVS_FIELDS;
    return [DATE, EMAIL, LONG_RESPONSE, RADIO, SHORT_RESPONSE, SINGLE_SELECT].includes(type);
}

/**
 * EVS types that return a number at value.value
 * @param {*} type
 * @returns
 */
function isNumberReturnType(type) {
    const { PERCENTAGE, NUMBER, DEPARTMENT } = EVS_FIELDS;
    return [PERCENTAGE, NUMBER, DEPARTMENT].includes(type);
}

/**
 * EVS types that return an Array at value.value
 * @param {*} type
 * @returns
 */
function isArrayReturnType(type) {
    const { CHECKBOX, MULTI_SELECT } = EVS_FIELDS;
    return [CHECKBOX, MULTI_SELECT].includes(type);
}

/**
 * Turns condtions within an intake form into a single object where the key
 * is the condition id and the value is the Condition Tree. Uses an EVS
 * util, fromExpression, to turn a string expression into an object representing
 * the expression (the Condition Tree). Returned object is
 * used to determine the visibility of fields based on EVS field conditions.
 *
 * @param {Array} formSections section data from EVS API response
 * @returns {Object} Object<conditionId, condition>
 */
export function normalizeIntakeConditions(conditions) {
    let conditionRecords = {};
    conditions.forEach((cond) => {
        conditionRecords[cond.id] = {
            ...fromExpression(cond.expression),
            expression: cond.expression
        };
    });

    return conditionRecords;
}

export function normalizeViewTicketConditions(conditions) {
    const cIds = Object.keys(conditions);
    let conditionRecords = {};
    cIds.forEach((id) => {
        conditionRecords[id] = {
            ...fromExpression(conditions[id].expression),
            expression: conditions[id].expression
        };
    });

    return conditionRecords;
}

/**
 * Adds the value of an input onchange event to the normalized field object
 * for checking conditional rendering
 *
 * @returns {Object} normalizedFields
 */
export function addFieldValueToNormalizedFields(normalizedFields, fieldId, value) {
    const _field = normalizedFields[fieldId];
    _field.value.value = value;

    normalizedFields[fieldId] = _field;

    return normalizedFields;
}

/**
 * Sets up the state shape to evaluate a condition against fields
 *
 * @param {object} conditions object of normalized conditions
 * @param {object} fieldsForConditions object of normalized fields
 * @param {object} implicitFields implicit field data from API response
 * @returns {object} A visibility object with key/value pair of field id and boolean
 */
export function parseConditions(conditions, fieldsForConditions, implicitFields) {
    let state = {
        conditions: conditions,
        fields: fieldsForConditions,
        implicitFields: implicitFields
    };

    return evaluateFieldWithCondition(state);
}

/**
 * Helper function to return the correct data shape for 'value'
 * to normalized field records used to evaluate conditions. Should
 * be used to capture the value of an onchange event
 *
 * @param {String} evsType Evisort field type
 * @param {Object} fieldPayload The constructed field value submitted to API
 * @returns
 */
export function handleFieldChangeForConditions(evsType, fieldPayload) {
    // using the payload built for creating ticket to set value of fields for conditions
    if (fieldPayload) {
        return fieldPayload;
    } else if (evsType === EVS_FIELDS.ADDRESS) {
        return Object.assign(fieldValueModels[EVS_FIELDS.ADDRESS], fieldPayload);
    }
    //reset field value to it's base value model
    return fieldValueModels[evsType];
}

/**
 * be used to null check
 *
 * @param  {value } Check value is null or not
 * @return {Boolean} return true false
 */
 export function isBlank (value) {
    if (value == undefined || value == null || value == '') {
        return true;
    }
    return false;
}

/**
 * used to check Email
 * 
 * @param  {value } Check Email is valid or not
 * @return {Boolean} return true false
 */
export function isValidateEmail(emailAddressList) {
    let emailsValid = true;
    const res = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()s[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    if(emailAddressList.length > 1) {
        emailAddressList.forEach((email) => {
            let isValid = res.test(String(email).toLowerCase());
            if (!isValid) {
                emailsValid = false;
            }
        });
    }
    else if(emailAddressList.length > 0) {
        emailsValid = res.test(String(emailAddressList[0]).toLowerCase());
    }

    return emailsValid;
}

/**
 * used to check FileType for Attachments
 * 
 * @param  {value } Check this value exist in this map and return value
 * @return {value} return file type
 */
//Map For Find FileType
export function isFileType(fileExtension){
    const fileTypeMap = new Map();
            fileTypeMap.set('doc','WORD');
            fileTypeMap.set('docx','WORD_X');
            fileTypeMap.set('pdf','PDF');
            fileTypeMap.set('csv','CSV');
            fileTypeMap.set('xlsx','EXCEL_X')
    if(fileTypeMap.has(fileExtension)){
        return fileTypeMap.get(fileExtension)
    }
}