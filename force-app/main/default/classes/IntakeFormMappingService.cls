public with sharing class IntakeFormMappingService {
    /**
     * @description service method to retrive child objects of the parent mappings
     * @param  recordId     The id of parend record
     * @param  workflowId   The externalId of the intake form selected
     * @return              A mapp of all child objects related to the parent mappings
     */
    public static Map<String, Map<String, List<IntakeFormMappingService.ChildObjectData>>> getIntakeFormsMappings(
        Id parentId,
        String workFlowId
    ) {
        Map<String, Map<String, List<ChildObjectData>>> childMappings = new Map<String, Map<String, List<ChildObjectData>>>();
        Map<String, List<String>> childObjects = new Map<String, List<String>>();
        Map<String, Map<String, String>> mapChild = new Map<String, Map<String, String>>();
        Map<String, String> workflowField = new Map<String, String>();
        String query = 'SELECT ';
        List<Intake_Form_Mapping__c> intakeFormMappings = new IntakeFormMappingSelector()
            .getChildMappingsByParentId(workFlowId, parentId);

        if (!intakeFormMappings.isEmpty()) {
            String parentObject = String.valueOf(intakeFormMappings.get(0).Intake_Form__r.Salesforce_Object__c);
			Map<String, String> mapRelationWithAPIName = getRelationshipNameByParentId(parentId);

            for (Intake_Form_Mapping__c ifm : intakeFormMappings) {
                String childObject = String.ValueOf(ifm.Salesforce_Object__c).toLowerCase();
                String childField = String.ValueOf(ifm.Salesforce_Field__c).substringAfter('.').toLowerCase();

                if (!mapChild.containsKey(ifm.Workflow_Field_Id__c)) {
                    mapChild.put(ifm.Workflow_Field_Id__c, new Map<String, String>{ childObject => childField });
                    workflowField.put(ifm.Workflow_Field_Id__c, ifm.Workflow_Field__c);
                }
                List<String> newListForFileds = new List<String>();

                if (!childObjects.containsKey(childObject)) {
                    newListForFileds.add(childField);
                    childObjects.put(childObject, newListForFileds);
                } else if (!childObjects.get(childObject).contains(childField)) {
                    newListForFileds = childObjects.get(childObject);
                    newListForFileds.add(childField);
                    childObjects.put(childObject, newListForFileds);
                }
            }

            if (!childObjects.isEmpty()) {
                Map<String, String> mapChildObjectWithName = new Map<String, String>();  
                for (String objectName : childObjects.keySet()) {
                    List<String> queryFields = childObjects.get(objectName);
                    String childObjectName = mapRelationWithAPIName.get(objectName);
                    String nameField = getNameField(childObjectName, queryFields[0]);
                    mapChildObjectWithName.put(objectName, nameField);

                    if (!queryFields.contains(nameField.toLowerCase())) {
                        queryFields.add(nameField);
                    }
                    query += '(SELECT ' + String.join(queryFields, ',') + ' FROM ' + objectName + '),';
                }

                if (parentObject != null || parentObject != '') {
                    query += 'Id FROM ' + parentObject + ' WHERE Id =: parentId';

                    List<SObject> recordsList = Database.query(query);

                    if (!recordsList.isEmpty() && !mapChild.isEmpty()) {
                        for (String keymatch : mapChild.keySet()) {
                            if (!childMappings.containsKey(keymatch)) {
                                Map<String, List<ChildObjectData>> childDataMap = new Map<String, List<ChildObjectData>>();

                                List<ChildObjectData> codList = new List<ChildObjectData>();

                                for (String objectnField : mapChild.get(keymatch).keySet()) {
                                    for (SObject objectRecordsList : recordsList.get(0).getSObjects(objectnField)) {
                                        ChildObjectData cod = new ChildObjectData();
                                        cod.workflowField = String.valueOf(workflowField.get(keymatch));

                                        cod.id = (Id) objectRecordsList.get('Id');
                                        cod.name =  String.valueOf(objectRecordsList.get(mapChildObjectWithName.get(objectnField))); 

                                        String childRelation = mapChild.get(keymatch).get(objectnField);
                                        if(childRelation.contains('.')){
                                            List<String> lstFieldNames = childRelation.split('\\.');
                                            Integer setIndex = 1;
                                            sobject value = objectRecordsList; 
                                            integer len = lstFieldNames.size();                                          
                                            for (String sr : lstFieldNames) {
                                                if(setIndex < lstFieldNames.size()){
                                                    setIndex++;
                                                    value = value.getSObject(sr); 
                                                }else{
                                                    if(value != null){
                                                        cod.fieldValue = value.get(sr);
                                                    }
                                                    
                                                }
                                            }
                                        }else {
                                            cod.fieldValue = objectRecordsList.get(
                                            mapChild.get(keymatch).get(objectnField)
                                            );
                                        }
                                        codList.add(cod);
                                    }
                                    String childObjectLabel;

                                    for (
                                        Schema.ChildRelationship childObj : Schema.getGlobalDescribe()
                                            .get(parentObject)
                                            .getDescribe()
                                            .getChildRelationships()
                                    ) {
                                        if (childObj.getRelationshipName() == objectnField) {
                                            childObjectLabel = childObj.getChildSObject()
                                                .getDescribe()
                                                .getLabelPlural();
                                            break;
                                        }
                                    }
                                    childDataMap.put(childObjectLabel, codList);
                                }
                                childMappings.put(keymatch, childDataMap);
                            }
                        }
                    }
                }
            }
        }
        return childMappings;
    }

    public static Map<String,String> getRelationshipNameByParentId(Id parentId) {
        Map<String, String> mapRelationWithAPIName = new Map<String, String>();
        Schema.DescribeSObjectResult descResult = parentId.getSObjectType().getDescribe();
        
        for(Schema.ChildRelationship cr: descResult.getChildRelationships()){
            if (cr.getRelationshipName() != null) {
                String relationshipName = cr.getRelationshipName();
                String childObjectName = string.valueof(cr.getChildSObject());
                mapRelationWithAPIName.put(relationshipName.toLowerCase(), childObjectName);
            }
        }
        return mapRelationWithAPIName;
    }

    public static String getNameField(String objectName, String selectedField) {
        SObjectType objToken = Schema.getGlobalDescribe().get(objectName);
        if (objToken != null) {
            DescribeSObjectResult objDef = objToken.getDescribe();
            Map<String, SObjectField> fieldsMap = objDef.fields.getMap();
            if (fieldsMap.containsKey('Name'))
            {
            	return 'Name';  
            }
            for (SObjectField fieldToken : fieldsMap.values()) {
                DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                if (fieldDescribe.isNameField()) {
                    return fieldDescribe.getName();
                }
            }
        }
        return selectedField;
    }
    
    public class ChildObjectData {
        @AuraEnabled
        public String workflowField { get; set; }
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Object fieldValue { get; set; }
    }
}