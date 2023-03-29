import { EVS_FIELDS } from "c/csUtils";

export const SPECIAL_VALUE_OPTION = "__special_option_value_for_other__";

/**
 * Determines if the type is one of the EVS fields which a User
 * can supply their own value to. CHECKBOX and RADIO utilize
 * enable_other_option boolean and the SELECTS
 * utilize enable_create_options boolean within customSettings in
 * the question data.
 *
 * @param {*} type question field type
 * @returns boolean
 */
export function isTypeWithUserOption(type) {
    return [EVS_FIELDS.SINGLE_SELECT, EVS_FIELDS.MULTI_SELECT, EVS_FIELDS.CHECKBOX, EVS_FIELDS.RADIO].includes(type);
}

/**
 * If there is a value supplied by a SF record, it takes precedence as a default value.
 * When the field type has options for values, check to see if the defualt value
 * is present and if it is not put the default value in the input for custom values if
 * the field allows that feature.
 *
 * @param {object} qField question field
 * @returns object
 */
export function handleDefaultWhenOptionMissing(qField) {
    const _qField = { ...qField };
    let { customSettings, mappedValue, type: evsFieldType } = _qField;

    mappedValue = Array.isArray(mappedValue) && !mappedValue?.length ? "" : mappedValue;

    // Series of early returns as safegaurds
    if (!isTypeWithUserOption(evsFieldType)) return _qField;
    if (typeof mappedValue !== "string") return _qField;

    const foundOpt = customSettings.options?.find((item) => item.label.toLowerCase() === mappedValue.toLowerCase());

    // If sfDefault is valid but not in the available field options,
    // there is a special case to handle with certain EVS field types
    if ((mappedValue || typeof mappedValue === "number") && !foundOpt) {
        // Add as a User supplied custom value
        // const { mappedValue: _mappedValue } = question.field;

        switch (evsFieldType) {
            case EVS_FIELDS.CHECKBOX:
            case EVS_FIELDS.RADIO:
                // Determine if mappedValue is already setup with other_value
                if (!mappedValue.hasOwnProperty("other_value")) {
                    _qField.mappedValue = mappedValue;
                }
                return {
                    _qField,
                    multiValues: SPECIAL_VALUE_OPTION,
                    enableOtherOption: customSettings.enable_other_option,
                    createOptionsValue: mappedValue
                };
            case EVS_FIELDS.MULTI_SELECT:
            case EVS_FIELDS.SINGLE_SELECT:
                return {
                    createOptionsValue: mappedValue
                };
            default:
                break;
        }
    }
    return _qField;
}