import _ from "c/lodash";
import uuid from "./uuid";
import operatorDefinitions from "./operatorDefinitions";

export const ROOT = "root";
export const FIELD = "field";
export const SECTION = "section";
export const ANDOR = "andor";
export const AND = "AND";
export const OR = "OR";

export const OPEN_BRACKET = "(";
export const CLOSE_BRACKET = ")";

export function createAndOrNode() {
    return {
        id: uuid(),
        type: ANDOR,
        value: AND
    };
}

export function createRootNode() {
    return {
        id: uuid(),
        type: ROOT,
        children: []
    };
}

export function createFieldNode() {
    return {
        id: uuid(),
        type: FIELD,
        fieldId: "",
        operator: "",
        values: []
    };
}

export function createSectionNode() {
    return {
        id: uuid(),
        type: SECTION,
        children: []
    };
}

export function testNodeType(node, nodeType) {
    return node?.type === nodeType;
}

export function testBracket(term) {
    return term === OPEN_BRACKET || term === CLOSE_BRACKET;
}

export function getUniqueFieldsInExpressionTree(tree) {
    const found = new Set();
    const stack = [];
    stack.push(tree);
    while (stack.length > 0) {
        const currentNode = stack.pop();
        switch (currentNode.type) {
            case "root":
            case "section":
                stack.push(...currentNode.children);
                break;
            case "field":
                found.add(currentNode.fieldId);
                break;
            default:
                break;
        }
    }
    return Array.from(found);
}

function fieldHasLoop(fieldId, conditions, fields) {
    const pendingConditionsIds = [];
    if (fields[fieldId].conditionId) {
        pendingConditionsIds.push(fields[fieldId].conditionId);
    }

    while (pendingConditionsIds.length > 0) {
        const conditionId = pendingConditionsIds.pop();
        const fieldIds = getUniqueFieldsInExpressionTree(fromExpression(conditions[conditionId].expression));
        const { loop, newConditions } = fieldIds.reduce(
            function (acc, fieldId) {
                if (!acc.loop) {
                    if (acc.foundFieldIds.has(fieldId)) {
                        acc.loop = true;
                    } else {
                        acc.foundFieldIds.add(fieldId);
                        if (fields[fieldId].conditionId) {
                            acc.newConditions.push(fields[fieldId].conditionId);
                        }
                    }
                }
                return acc;
            },
            {
                loop: false,
                newConditions: [],
                foundFieldIds: (function () {
                    const s = new Set();
                    s.add(fieldId);
                    return s;
                })()
            }
        );
        if (loop) {
            return true;
        }
        pendingConditionsIds.push(...newConditions);
    }
    return false;
}

/**
 * {<cnd_id>: {id: String, expression: [Object]} }
 * {<fld_id>: {id: String, conditionId: String} }
 */
export function hasLoops(conditions, fields) {
    return Object.entries(fields).reduce(function (acc, [fieldId]) {
        acc[fieldId] = fieldHasLoop(fieldId, conditions, fields);
        return acc;
    }, {});
}

/**
 * Converts an array of expression terms into a tree of rules with the following node interfaces:
 *
 * type Node = SectionNode | FieldNode | AndOrNode
 *
 * interface RootNode {
 *  type: 'root';
 *  children: Node[];
 * }
 *
 *
 * interface SectionNode {
 *  type: 'section';
 *  id:  uuid;
 *  children: Node[];
 * }
 *
 * interface FieldNode {
 *  type: 'field';
 *  id: uuid;
 *  fieldId: string;
 *  operator: string;
 *  values: string[];
 * }
 *
 * interface AndOrNode {
 *  type: 'andor';
 *  id: uuid;
 *  value: 'AND' | 'OR'
 * }
 *
 * Throws an error if the expression is malformed.
 *
 * @param {string[]} expression flat array of expression terms
 * @return {Root} structured tree of rules
 */
export function fromExpression(expression = []) {
    const ERROR_MSG = "Expression is malformed";
    const root = createRootNode();
    try {
        const { nodes, rest } = fromExpressionR(expression);
        if (rest.length) {
            throw new Error(ERROR_MSG);
        }
        root.children = nodes;
        return root;
    } catch (e) {
        throw new Error(ERROR_MSG);
    }
}

const isCardinalityForOperator = (operator, cardinality) =>
    operatorDefinitions[operator] && operatorDefinitions[operator].valueCardinality === cardinality;

function fromExpressionR(expression = []) {
    const [head, ...tail] = expression;

    switch (head) {
        case undefined:
            return { nodes: [], rest: [] };
        case OPEN_BRACKET:
            return ((expression) => {
                const { nodes, rest } = fromExpressionR(expression);
                const [head, ...tail] = rest;

                if (head !== CLOSE_BRACKET) {
                    throw new Error(`expected closing bracket. got ${head}`);
                }

                const section = createSectionNode();
                section.children = nodes;

                const { nodes: tailNodes, rest: tailRest } = fromExpressionR(tail);
                return { nodes: [section, ...tailNodes], rest: tailRest };
            })(tail);
        case AND:
        case OR:
            return (function (expression) {
                const node = createAndOrNode();
                node.value = head;

                const { nodes, rest } = fromExpressionR(expression);
                return { nodes: [node, ...nodes], rest };
            })(tail);
        default:
            return (function (expression) {
                if (expression[0] === CLOSE_BRACKET) {
                    return { nodes: [], rest: expression };
                }

                let _, values, tail; // eslint-disable-line no-unused-vars
                const [fieldId, operator] = expression;

                const node = createFieldNode();
                node.fieldId = fieldId;
                node.operator = operator;
                if (isCardinalityForOperator(operator, 0)) {
                    values = [];
                    [_, _, ...tail] = expression;
                } else {
                    [_, _, values, ...tail] = expression;
                    if (isCardinalityForOperator(operator, 1)) {
                        values = [values];
                    }
                }
                node.values = values;

                const [head] = tail;
                if (!head) {
                    return { nodes: [node], rest: [] };
                } else if (head === CLOSE_BRACKET) {
                    return { nodes: [node], rest: tail };
                } else if (head === AND || head === OR) {
                    const { nodes: moreNodes, rest } = fromExpressionR(tail);
                    return { nodes: [node, ...moreNodes], rest };
                } else {
                    throw new Error(`expected EOL, closing bracket or AND/OR. got ${head}`);
                }
            })(expression);
    }
}

/**
 * Converts a tree of rules into an array of expression terms.  Refer to the fromExpression method for node interfaces of the tree.
 * @param {Node} node structured tree of rules
 * @return {Array<string>} expression terms
 */
export function toExpression(node = createRootNode(), expression = []) {
    const { fieldId, operator, value, values } = node;
    const isSectionNode = testNodeType(node, SECTION);

    if (testNodeType(node, FIELD)) {
        if (isCardinalityForOperator(operator, 0)) {
            return [fieldId, operator];
        } else if (isCardinalityForOperator(operator, 1)) {
            return [fieldId, operator, values[0]];
        } else {
            return [fieldId, operator, values];
        }
    } else if (testNodeType(node, ANDOR)) {
        return [value];
    } else if (isSectionNode && node.children.length === 0) {
        return [OPEN_BRACKET, CLOSE_BRACKET];
    } else {
        node.children.forEach((child, i) => {
            const preBracket = isSectionNode && i === 0 ? [OPEN_BRACKET] : [];
            const postBracket = isSectionNode && i === node.children.length - 1 ? [CLOSE_BRACKET] : [];
            expression = [...preBracket, ...expression, ...toExpression(child, []), ...postBracket];
        });
    }

    return expression;
}

// TODO: add tests and make more performant with binary search.
export class TreeManager {
    constructor(tree) {
        this.tree = _.cloneDeep(tree);
    }

    search(id, node = this.tree, parent = node, match = null) {
        if (node.id === id) {
            match = [node, parent];
        } else if (node.children) {
            node.children.forEach((child) => {
                if (!match) {
                    match = this.search(id, child, node);
                }
            });
        }
        return match;
    }

    addNode(id, newNode) {
        const match = this.search(id);
        if (match) {
            const [node] = match;
            if (node.children) {
                if (node.children[node.children.length - 1]) {
                    node.children.push(createAndOrNode());
                }
                node.children.push(newNode);
            }
        }
        return this.tree;
    }

    updateNode(id, data = {}) {
        const match = this.search(id);
        if (match) {
            const [node] = match;
            Object.keys(data).forEach((key) => {
                node[key] = data[key];
            });
        }
        return this.tree;
    }

    removeNode(id) {
        const match = this.search(id);
        if (match) {
            const [node, parent] = match;
            if (parent.children) {
                const index = parent.children.findIndex((child) => child.id === node.id);
                const previousSibling = parent.children[index - 1];
                const nextSibling = parent.children[index + 1];
                const isLastChild = index === parent.children.length - 1;

                const start = testNodeType(previousSibling, ANDOR) && isLastChild ? index - 1 : index;
                const deleteCount = testNodeType(nextSibling, ANDOR) || isLastChild ? 2 : 1;
                parent.children.splice(start, deleteCount);
            }
        }
        return this.tree;
    }
}

// TODO: integrate with TreeManager and add tests
export function filter(node, test, filtered = []) {
    if (test(node)) {
        return [node];
    }
    if (node.children) {
        node.children.forEach((child) => {
            filtered = [...filtered, ...filter(child, test)];
        });
    }
    return filtered;
}

export function testEmptyExpression(expression) {
    if (expression.length === 0) {
        return true;
    }
    return !expression.some((term) => ![AND, OR, OPEN_BRACKET, CLOSE_BRACKET].includes(term));
}

export function testHasEmptySections(expression) {
    const tree = fromExpression(expression);

    function testHasEmptySection(node) {
        let hasEmptySection = false;
        const { children } = node;
        if (children) {
            const isCurrentSectionEmpty = testNodeType(node, SECTION) && children.length === 0;
            const isNestedSectionsEmpty = children.reduce((hasEmptySectionR, child) => {
                return hasEmptySectionR || testHasEmptySection(child);
            }, hasEmptySection);
            hasEmptySection = isCurrentSectionEmpty || isNestedSectionsEmpty;
        }
        return hasEmptySection;
    }

    return testHasEmptySection(tree);
}

// TODO: add tests, and also confirm the check for invalid field values.
export function getInvalidFieldNodes(tree) {
    return filter(tree, (node) => {
        return testNodeType(node, FIELD) && (!node.fieldId || !node.operator);
    });
}