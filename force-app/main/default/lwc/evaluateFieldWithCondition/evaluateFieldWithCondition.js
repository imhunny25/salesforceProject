import { applyConditions as _applyConditions } from "./conditions.js";

export const applyConditions = _applyConditions;

export const evaluateFieldWithCondition = (state) => {
    const appliedConditions = applyConditions(state.conditions, state.fields, state.implicitFields);
    return appliedConditions;
};