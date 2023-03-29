import _ from "c/lodash";

const isEqual = (x, y) => {
    if (x instanceof Set && y instanceof Set) {
        return RELATIONAL_OPERATORS.CONTAINS_ANY_OF(x, y);
    }

    return x === y;
};

const isNotEqual = (x, y) => {
    if (x instanceof Set && y instanceof Set) {
        return RELATIONAL_OPERATORS.DOES_NOT_CONTAIN(x, y);
    }

    return x !== y;
};

const RELATIONAL_OPERATORS = {
    ">": (x, y) => x > y,
    "<": (x, y) => x < y,
    "<=": (x, y) => x <= y,
    ">=": (x, y) => x >= y,
    "==": isEqual,
    "!=": isNotEqual,
    CONTAINS: (xs, ys) => {
        if (_.isString(xs) && _.isString(ys)) {
            return xs.includes(ys);
        } else if (_.isSet(xs) && _.isSet(ys)) {
            return !Array.from(ys).some((y) => !xs.has(y));
        }
        throw new Error("illegal expression");
    },
    DOES_NOT_CONTAIN: (xs, ys) => !RELATIONAL_OPERATORS["CONTAINS"](xs, ys),
    ALL_OF_THESE_WORDS: (s1, words) => words.split(" ").reduce((acc, word) => acc && s1.includes(word), true),
    ANY_OF_THESE_WORDS: (s1, words) => words.split(" ").reduce((acc, word) => acc || s1.includes(word), false),
    EXACT_PHRASE: (s1, s2) => s1 === s2,
    CONTAINS_ANY_OF: (xs, ys) => Array.from(ys).reduce((acc, y) => acc || (xs.has ? xs.has(y) : xs === y), false),
    CONTAINS_ALL: (xs, ys) => Array.from(ys).reduce((acc, y) => acc && xs.has(y), true),
    BETWEEN: (x, ys) => ys[0] < x && x < ys[1]
};

const UNARY_OPERATORS = {
    IS_BLANK: (x) => {
        const xs = x || [];
        return (xs.trim ? xs.trim() : xs).length === 0;
    },
    IS_NOT_BLANK: (x) => !UNARY_OPERATORS["IS_BLANK"](x)
};

const LOGICAL_OPERATORS = {
    AND: (x, y) => x && y,
    OR: (x, y) => x || y
};

const PRECEDENCE = {
    ">": 3,
    "<": 3,
    "<=": 3,
    ">=": 3,
    "==": 3,
    "!=": 3,
    CONTAINS: 3,
    DOES_NOT_CONTAIN: 3,
    ALL_OF_THESE_WORDS: 3,
    ANY_OF_THESE_WORDS: 3,
    EXACT_PHRASE: 3,
    IS_BLANK: 3,
    IS_NOT_BLANK: 3,
    CONTAINS_ANY_OF: 3,
    CONTAINS_ALL: 3,
    BETWEEN: 3,
    AND: 2,
    OR: 1
};

const toTypeMaybe = (convertRaw, convertValue, x) => {
    if (_.isUndefined(x.value)) {
        return convertRaw(x);
    } else if (!x.value) {
        throw new Error("not calculable");
    } else {
        return convertValue(x);
    }
};
const toString = (x) => (_.isUndefined(x.value) ? String(x) : x.value ? String(x.value) : "");
const toBoolean = (x) => (x.value ? x.value === "True" || x.value === "true" : x === "True" || x === "true");
export const toSet = (x) => {
    const coerceValue = (x) => {
        if (_.isNull(x)) {
            return new Set();
        } else if (_.isArray(x)) {
            return new Set(x);
        } else if (_.isString(x)) {
            return new Set(x.split("||"));
        } else {
            return new Set([x]);
        }
    };

    return _.isUndefined(x?.value) ? coerceValue(x) : coerceValue(x.value);
};
const toDate = (x) =>
    toTypeMaybe(
        (x) => new Date(x),
        (x) => new Date(x.value),
        x
    ).getTime();
const toFloat = (x) =>
    toTypeMaybe(
        (x) => Number.parseFloat(x),
        (x) => Number.parseFloat(x.value),
        x
    );
const toFloatFromMoney = (x) => (x.amount ? Number.parseFloat(x.amount) : Number.parseFloat(x));
const toFileExists = (x) => !!x.value;

const TYPE_CONVERTER = {
    ADDRESS: toString,
    BOOLEAN: toBoolean,
    CHECKBOX: toSet,
    DATE: toDate,
    DATE_SIGNED: toDate,
    DEPARTMENT: toString,
    EMAIL: toString,
    FILE: toFileExists,
    LONG_RESPONSE: toString,
    MONETARY_VALUE: toFloatFromMoney,
    MULTI_SELECT: toSet,
    NUMBER: toFloat,
    PERCENTAGE: toFloat,
    RADIO: toString,
    SHORT_RESPONSE: toString,
    SINGLE_SELECT: toString,
    TIME_PERIOD: toString,
    USER: toSet
};

const infixToPostfix = (expressionItems) => {
    const postfix = [];
    const operatorStack = [];
    for (const item of expressionItems) {
        if (
            UNARY_OPERATORS[item] ||
            RELATIONAL_OPERATORS[item] ||
            item === "(" ||
            item === ")" ||
            LOGICAL_OPERATORS[item]
        ) {
            if (item === ")") {
                let poppedItem = operatorStack.pop();
                while (poppedItem !== "(") {
                    postfix.push(poppedItem);
                    poppedItem = operatorStack.pop();
                }
            } else if (PRECEDENCE[item]) {
                while (
                    !_.isEmpty(operatorStack) &&
                    _.last(operatorStack) !== "(" &&
                    PRECEDENCE[_.last(operatorStack)] > PRECEDENCE[item]
                ) {
                    postfix.push(operatorStack.pop());
                }
                operatorStack.push(item);
            } else {
                operatorStack.push(item);
            }
        } else {
            postfix.push(item);
        }
    }
    while (!_.isEmpty(operatorStack)) {
        let poppedItem = operatorStack.pop();
        if (poppedItem !== "(") {
            postfix.push(poppedItem);
        }
    }
    return postfix;
};

const makeCyclesDetector = (conditions, fields) => {
    const fieldsForCondition = Object.fromEntries(
        Object.entries(conditions).map(([conditionId, condition]) => [
            conditionId,
            _.intersection(condition.expression, Object.keys(fields))
        ])
    );
    const conditionForField = Object.fromEntries(
        Object.entries(fields).map(([fieldId, field]) => [fieldId, field.conditionRule ? field.conditionRule.id : null])
    );

    const hasCyclesR = (alreadyUsed, conditionId) => {
        alreadyUsed = alreadyUsed.concat(conditionId);
        const nextBatchOfConditions = fieldsForCondition[conditionId].reduce(
            (acc, fieldId) => (conditionForField[fieldId] ? acc.concat(conditionForField[fieldId]) : acc),
            []
        );
        if (nextBatchOfConditions.some((conditionId) => alreadyUsed.includes(conditionId))) {
            return true;
        }
        return nextBatchOfConditions.map((condId) => hasCyclesR(alreadyUsed, condId)).some((x) => x);
    };

    return (conditionId) => hasCyclesR([], conditionId);
};

export const hasCircularDefinitions = (conditions, fields) => {
    const hasCycles = makeCyclesDetector(conditions, fields);
    return Object.keys(conditions).reduce((acc, conditionId) => acc || hasCycles(conditionId), false);
};

const makeArgTypeConverter = (operatorName, fieldType, typeConverter) => {
    if (operatorName === "BETWEEN") {
        return (xs) => xs.map((x) => typeConverter(x));
    } else if (operatorName === "CONTAINS_ANY_OF" && fieldType === "SINGLE_SELECT") {
        return toSet;
    } else {
        return typeConverter;
    }
};

const calculateCondition = (fieldVisibility, fields, implicitFields, postfixExpression) => {
    const valueStack = [];
    for (const item of postfixExpression) {
        if (LOGICAL_OPERATORS[item]) {
            const y = valueStack.pop();
            const x = valueStack.pop();
            valueStack.push(LOGICAL_OPERATORS[item](x, y));
        } else if (RELATIONAL_OPERATORS[item]) {
            const y = valueStack.pop();
            const x = valueStack.pop();

            if (fieldVisibility[x] === false) {
                valueStack.push(false);
                continue;
            }

            const field = implicitFields[x] || fields[x];
            const typeConverter = TYPE_CONVERTER[field.type];
            if (!typeConverter) {
                throw new Error("unknown type");
            }
            try {
                const argTypeConverter = makeArgTypeConverter(item, field.type, typeConverter);
                const fieldTypeConverter = (x) => {
                    if (x === null) {
                        throw new Error("not calculable");
                    }
                    return typeConverter(x);
                };
                valueStack.push(RELATIONAL_OPERATORS[item](fieldTypeConverter(field.value), argTypeConverter(y)));
            } catch (e) {
                if (e.message === "not calculable") {
                    valueStack.push(false); // condition considered unmet if not calculable
                } else {
                    throw e;
                }
            }
        } else if (UNARY_OPERATORS[item]) {
            const x = valueStack.pop();

            if (fieldVisibility[x] === false) {
                valueStack.push(false);
                continue;
            }

            const field = implicitFields[x] || fields[x];
            const typeConverter = TYPE_CONVERTER[field.type];
            if (!typeConverter) {
                throw new Error("unknown type");
            }
            try {
                valueStack.push(UNARY_OPERATORS[item](typeConverter(field.value)));
            } catch (e) {
                if (e.message === "not calculable") {
                    return false; // condition considered unmet if not calculable
                }
                throw e;
            }
        } else {
            valueStack.push(item);
        }
    }
    if (valueStack.length > 1) {
        throw new Error("malformed postfix expression");
    }
    return valueStack.pop();
};

const evaluateCondition = (state, conditions, fields, implicitFields, fieldsForCondition, conditionId) => {
    // recursively evaluate condition here
    const fieldIdConditionPairs = fieldsForCondition[conditionId].map((fieldId) => [
        fieldId,
        fields[fieldId].conditionRule
    ]);
    fieldIdConditionPairs.forEach(([fieldId, fieldCondition]) => {
        state.fieldVisibility[fieldId] = true;
        if (fieldCondition) {
            if (_.isUndefined(state.conditionsValues[fieldCondition.id])) {
                // check if condition or field already calculated
                // calculate condition
                const { value } = evaluateCondition(
                    state,
                    conditions,
                    fields,
                    implicitFields,
                    fieldsForCondition,
                    fieldCondition.id
                );
                state.conditionsValues[fieldCondition.id] = { value };
                state.fieldVisibility[fieldId] = shouldShow(value, fieldCondition);
            } else {
                const { value } = state.conditionsValues[fieldCondition.id];
                state.fieldVisibility[fieldId] = shouldShow(value, fieldCondition);
            }
        }
    });

    return {
        value: calculateCondition(
            state.fieldVisibility,
            fields,
            implicitFields,
            infixToPostfix(conditions[conditionId].expression)
        )
    };
};

const evaluateConditions = (conditions, fields, implicitFields) => {
    const fieldsForCondition = Object.fromEntries(
        Object.entries(conditions).map(([conditionId, condition]) => [
            conditionId,
            _.intersection(condition.expression, Object.keys(fields))
        ])
    );
    const _evaluateConditions = (state, conditions, fields) => {
        return Object.keys(conditions).reduce((acc, conditionId) => {
            const { value } = evaluateCondition(
                state,
                conditions,
                fields,
                implicitFields,
                fieldsForCondition,
                conditionId
            );
            acc[conditionId] = { value };
            return acc;
        }, {});
    };
    const state = { fieldVisibility: {}, conditionsValues: {} };
    return _evaluateConditions(state, conditions, fields);
};

const shouldShow = (conditionMet, condRule) =>
    !condRule ||
    (conditionMet &&
        ((condRule.satisfiedWhenCondMet && condRule.enabledWhenSatisfied) ||
            (!condRule.satisfiedWhenCondMet && !condRule.enabledWhenSatisfied))) ||
    (!conditionMet &&
        ((!condRule.satisfiedWhenCondMet && condRule.enabledWhenSatisfied) ||
            (condRule.satisfiedWhenCondMet && !condRule.enabledWhenSatisfied)));

export const applyConditions = (conditions, fields, implicitFields = {}) => {
    // 1. no circular definitions please
    if (hasCircularDefinitions(conditions, fields)) {
        // BOOM! circular definition
        throw new Error("circular definition"); // TODO: define what should be thrown here
    } else {
        // 2. if everything ok -> evaluate conditions
        const evaluatedConditions = evaluateConditions(conditions, fields, implicitFields);
        // 3. and apply them to fields
        return Object.entries(fields).reduce((acc, [fieldId, field]) => {
            const fieldCondRule = field.conditionRule;
            acc[fieldId] =
                !fieldCondRule || shouldShow(evaluatedConditions[field.conditionRule.id].value, field.conditionRule);
            return acc;
        }, {});
    }
};