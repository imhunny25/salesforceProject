public with sharing class EvisortFieldDefinitionService {
    /**
     * Retrives the Field and/or Provisions from the API and sets them in the system
     * Transaction-safe: this will do the API calls before any DML is done
     * @param  fieldType 'Field', 'Provision', or blank if you want to pull Field AND Provision in the same transaction
     */
    public static void retrieveFieldOrProvisionsAPICall(String fieldType) {
        Boolean doFields = false;
        Boolean doProvisions = false;

        // Verify which API calls we need to do
        if (fieldType == 'Field') {
            doFields = true;
        } else if (fieldType == 'Provision') {
            doProvisions = true;
        } else {
            doFields = true;
            doProvisions = true;
        }

        API a = new API();
        EvisortFieldDefinitionMsg.Response response = null;

        if (doFields) {
            HttpResponse res = a.doAPICall(Constants.FIELDS_URL, 'GET', null);
            response = (EvisortFieldDefinitionMsg.Response) JSON.deserialize(
                res.getBody(),
                EvisortFieldDefinitionMsg.Response.class
            );
            if (res.getStatusCode() != 200) {
                throw new EvisortFieldDefinitionServiceException(response.error);
            }
        }

        if (doProvisions) {
            HttpResponse res = a.doAPICall(Constants.PROVISIONS_URL, 'GET', null);
            EvisortFieldDefinitionMsg.Response provisionsResponse = (EvisortFieldDefinitionMsg.Response) JSON.deserialize(
                res.getBody(),
                EvisortFieldDefinitionMsg.Response.class
            );
            if (res.getStatusCode() != 200) {
                throw new EvisortFieldDefinitionServiceException(provisionsResponse.error);
            }
            // If we are only doing Provisions, we just need to put the response into the variable.
            // If we are doing both, we just want to add the provisions to the already existing response.
            // We don't care about the "count" variable in the response
            if (response == null) {
                response = provisionsResponse;
            } else {
                response.provisions = provisionsResponse.provisions;
            }
        }

        if (response.fields != null) {
            processFields(response.fields);
        }
        if (response.provisions != null) {
            processProvisions(response.provisions);
        }

        Evisort_Status__c status = Evisort_Status__c.getOrgDefaults();
        status.Last_Field_Pull__c = Datetime.now();
        upsert status; // Custom Setting, no need for CRUD/FLS check
    }

    /**
     * Process the "Fields" portion of the Field Definition
     * @param  fields Field Msg (parsed from API)
     */
    public static void processFields(List<EvisortFieldDefinitionMsg.Field> fields) {
        Map<String, Evisort_Field_Definition__c> evisortFieldDefMap = getExistingDefinitions('Field');

        List<Evisort_Field_Definition__c> defsToInsert = new List<Evisort_Field_Definition__c>();
        List<Evisort_Field_Definition__c> defsToUpdate = new List<Evisort_Field_Definition__c>();
        Set<String> fieldNamesInAPI = new Set<String>();

        for (EvisortFieldDefinitionMsg.Field field : fields) {
            if (!evisortFieldDefMap.keySet().contains(field.name)) {
                defsToInsert.add(field.toRecord());
            } else {
                fieldNamesInAPI.add(field.name);

                // If this Field Definition exists, we check to see if the Data Type, Allowed Values, or Section Name changed
                // This way we stay up to date with changes on the Evisort side.
                Evisort_Field_Definition__c efd = evisortFieldDefMap.get(field.name);
                String dataType = Constants.DATA_TYPES.get(field.type);
                String values = ((field.allowedValues != null) && (!field.allowedValues.isEmpty()))
                    ? String.join(field.allowedValues, '$@#')
                    : null;
                String sectionName = (field.section != null) ? field.section.name : null;

                if (
                    (efd.Data_Type__c != dataType) ||
                    (efd.Picklist_Values__c != values) ||
                    (efd.Section_Name__c != sectionName)
                ) {
                    Evisort_Field_Definition__c defToUpdate = new Evisort_Field_Definition__c();
                    defToUpdate.Id = efd.Id;
                    defToUpdate.Data_Type__c = dataType;
                    defToUpdate.Picklist_Values__c = values;
                    defToUpdate.Section_Name__c = sectionName;
                    defsToUpdate.add(defToUpdate);
                }
            }
        }

        if (!defsToInsert.isEmpty()) {
            Data.create(defsToInsert, false, false, false);
        }

        if (!defsToUpdate.isEmpty()) {
            Data.modify(defsToUpdate, false, false, false);
        }

        deleteFieldDefinitions(evisortFieldDefMap, fieldNamesInAPI);
    }

    /**
     * Process the "Provisions" portion of the Field Definition
     * @param  provisions Provision Msg (parsed from API)
     */
    public static void processProvisions(List<EvisortFieldDefinitionMsg.Provision> provisions) {
        Map<String, Evisort_Field_Definition__c> evisortFieldDefMap = getExistingDefinitions('Provision');

        Boolean syncNewProvisions = Evisort_Status__c.getOrgDefaults().Sync_New_Provisions__c;
        List<Evisort_Field_Definition__c> defsToInsert = new List<Evisort_Field_Definition__c>();
        Set<String> provisionNamesInAPI = new Set<String>();

        for (EvisortFieldDefinitionMsg.Provision provision : provisions) {
            if (!evisortFieldDefMap.keySet().contains(provision.name)) {
                defsToInsert.add(provision.toRecord(syncNewProvisions));
            } else {
                provisionNamesInAPI.add(provision.name);
            }
        }

        if (!defsToInsert.isEmpty()) {
            Data.create(defsToInsert, false, false, false);
        }

        deleteFieldDefinitions(evisortFieldDefMap, provisionNamesInAPI);
    }

    /**
     * Gets the existing Field Definitions for a Field Type and puts them in a Map
     * @param  fieldType 'Field', 'Provision', or blank for both
     * @return           A Map of Definition Name to Evisort Field Definition records
     */
    private static Map<String, Evisort_Field_Definition__c> getExistingDefinitions(String fieldType) {
        EvisortFieldDefinitionSelector efdSelector = new EvisortFieldDefinitionSelector(false, false, false);
        List<Evisort_Field_Definition__c> existingEvisortFieldDefs = efdSelector.getDefaultFieldsByFieldType(fieldType);

        Map<String, Evisort_Field_Definition__c> evisortFieldDefMap = new Map<String, Evisort_Field_Definition__c>();
        for (Evisort_Field_Definition__c efd : existingEvisortFieldDefs) {
            evisortFieldDefMap.put(efd.Name, efd);
        }

        return evisortFieldDefMap;
    }

    /**
     * Process Field deletions and any values associated with those deletions when they are not returned in the API
     * @param  evisortFieldDefMap Map of Field Names to Definition records
     * @param  namesInAPI         Set of Field Names returned in the API call
     */
    private static void deleteFieldDefinitions(
        Map<String, Evisort_Field_Definition__c> evisortFieldDefMap,
        Set<String> namesInAPI
    ) {
        Map<Id, Evisort_Field_Definition__c> defsToDelete = new Map<Id, Evisort_Field_Definition__c>();
        for (String fieldName : evisortFieldDefMap.keySet()) {
            if (!namesInAPI.contains(fieldName)) {
                Evisort_Field_Definition__c efd = new Evisort_Field_Definition__c();
                efd.Id = evisortFieldDefMap.get(fieldName).Id;
                defsToDelete.put(efd.Id, efd);
            }
        }

        if (!defsToDelete.isEmpty()) {
            EvisortFieldValueSelector efvSelector = new EvisortFieldValueSelector(false, false, false);
            List<Evisort_Field_Value__c> valuesToDelete = efvSelector.getValuesByDefinitionIds(defsToDelete.keySet());

            if (!valuesToDelete.isEmpty()) {
                // Ignoring CRUD/FLS because the user can't delete these from the UI
                Data.remove(valuesToDelete, false, false, false);
            }

            // Ignoring CRUD/FLS because the user can't delete these from the UI
            Data.remove(defsToDelete.values(), false, false, false);
        }
    }

    public class EvisortFieldDefinitionServiceException extends Exception {
    }
}