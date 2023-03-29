const WorkflowOperatorType = {
    AllOfTheseWords: "ALL_OF_THESE_WORDS",
    AnyOfTheseWords: "ANY_OF_THESE_WORDS",
    Between: "BETWEEN",
    Contains: "CONTAINS",
    ContainsAll: "CONTAINS_ALL",
    ContainsAnyOf: "CONTAINS_ANY_OF",
    DoesNotContain: "DOES_NOT_CONTAIN",
    ExactPhrase: "EXACT_PHRASE",
    Equal: "==",
    GreaterThan: ">",
    GreaterThanEqual: ">=",
    IsBlank: "IS_BLANK",
    IsNotBlank: "IS_NOT_BLANK",
    LessThan: "<",
    LessThanEqual: "<=",
    NotEqual: "!="
};

const {
    AllOfTheseWords,
    AnyOfTheseWords,
    Between,
    Contains,
    ContainsAll,
    ContainsAnyOf,
    DoesNotContain,
    ExactPhrase,
    Equal,
    GreaterThan,
    GreaterThanEqual,
    IsBlank,
    IsNotBlank,
    LessThan,
    LessThanEqual,
    NotEqual
} = WorkflowOperatorType;

export default {
    [AllOfTheseWords]: {
        label: "All of these words",
        value: AllOfTheseWords,
        valueCardinality: 1
    },
    [AnyOfTheseWords]: {
        label: "Any of these words",
        value: AnyOfTheseWords,
        valueCardinality: 1
    },
    [Between]: {
        label: "Between",
        value: Between,
        valueCardinality: 2
    },
    [Contains]: {
        label: "Contains",
        value: Contains,
        valueCardinality: 1
    },
    [ContainsAll]: {
        label: "Contains all",
        value: ContainsAll,
        valueCardinality: Infinity
    },
    [ContainsAnyOf]: {
        label: "Contains any of",
        value: ContainsAnyOf,
        valueCardinality: Infinity
    },
    [DoesNotContain]: {
        label: "Does not contain",
        value: DoesNotContain,
        valueCardinality: 1
    },
    [ExactPhrase]: {
        label: "Exact phrase",
        value: ExactPhrase,
        valueCardinality: 1
    },
    [Equal]: {
        label: "Equals",
        value: Equal,
        valueCardinality: 1
    },
    [GreaterThan]: {
        label: "Greater than",
        value: GreaterThan,
        valueCardinality: 1
    },
    [GreaterThanEqual]: {
        label: "Greater than or equal to",
        value: GreaterThanEqual,
        valueCardinality: 1
    },
    [IsBlank]: {
        label: "Is blank",
        value: IsBlank,
        valueCardinality: 0
    },
    [IsNotBlank]: {
        label: "Is not blank",
        value: IsNotBlank,
        valueCardinality: 0
    },
    [LessThan]: {
        label: "Less than",
        value: LessThan,
        valueCardinality: 1
    },
    [LessThanEqual]: {
        label: "Less than or equal to",
        value: LessThanEqual,
        valueCardinality: 1
    },
    [NotEqual]: {
        label: "Does not equal",
        value: NotEqual,
        valueCardinality: 1
    }
};