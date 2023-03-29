public with sharing class sObjectFieldMappingController {
    /**
     * @description Gets a list of fields on an object.
     * @param  obj obj description
     * @return     return description
     */
    @AuraEnabled
    public static List<Map<String, String>> getObjectFieldMetaData(String objectApiName) {
        List<Map<String, String>> fieldMetaData = new List<Map<String, String>>();
        Map<String, Schema.SObjectType> glblDscrb = Schema.getGlobalDescribe();

        if (glblDscrb.containsKey(objectApiName)) {
            Schema.DescribeSObjectResult objectDescribe = glblDscrb.get(objectApiName).getDescribe();

            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();

            for (String fieldData: fieldMap.keySet()) {
                String fieldLabel = fieldMap.get(fieldData).getDescribe().getLabel();
                String fieldName = fieldMap.get(fieldData).getDescribe().getName();
                Schema.DisplayType dataType = fieldMap.get(fieldData).getDescribe().getType();
                String fieldDataType = String.valueOf(dataType);
                
                String referenceTo = '';
                String relationshipName = fieldMap.get(fieldData).getDescribe().getRelationshipName();
                if (!fieldMap.get(fieldData).getDescribe().getReferenceTo().isEmpty()) {
                    referenceTo = String.valueOf(fieldMap.get(fieldData).getDescribe().getReferenceTo()[0]);
                }

                fieldMetaData.add(new Map<String, String> {
                    'label' => fieldLabel,
                    'value' => fieldName,
                    'datatype' => fieldDataType,
                    'relationshipName' => relationshipName,
                    'referenceTo' => referenceTo,
                    'isReference' => (fieldDataType == 'REFERENCE' && relationshipName != null ? 'Yes' : '')
                });
            }
        }
        return fieldMetaData;
    }

    @AuraEnabled
    public static List<SObject> getFieldValue(String query){
        try {
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}