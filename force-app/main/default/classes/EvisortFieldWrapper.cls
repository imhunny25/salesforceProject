public with sharing class EvisortFieldWrapper implements Comparable {
    @AuraEnabled
    public String fieldName  { get; set;}
    
    @AuraEnabled
    public String fieldLabel {get; set;}
    
    @AuraEnabled
    public String fieldType { get; set;}
    
	@AuraEnabled
    public String fieldTypeLWC { get; set;}

    @AuraEnabled
    public String fieldSOAPType { get; set;}

    @AuraEnabled
    public String formulaFieldType { get; set;}
    
    @AuraEnabled
    public String fieldRelationshipName { get; set; }
    
    @AuraEnabled
    public string fieldReferenceObjectApiName { get; set; }
    
	@AuraEnabled
	public string controllingFieldApiName { get; set; }

    @AuraEnabled
    public String fieldHelpText { get; set; }
    
    @AuraEnabled
    public Boolean isFieldAccessible { get; set; }

    @AuraEnabled
    public Boolean isFieldFilterable { get; set; }

	@AuraEnabled
	public Boolean isNameField { get; set; }
    
    @AuraEnabled
    public String fieldLabelStandard { get; set; }
    
	@AuraEnabled
	public Boolean isEditable { get; set; }

    @AuraEnabled
    public Boolean isRequired { get; set; }
    
    @AuraEnabled
    public Boolean isHtmlFormatted{ get; set; }
    
	@AuraEnabled
    public Boolean isDependentPicklist{ get; set; }
    
    @AuraEnabled
	public Map<String, List<PicklistEntryWrapper>> controllingValueWithDependnetValues{ get; set; }

    @AuraEnabled
    public Map<String, String> options { get; set; }

    @AuraEnabled
    public List<PicklistEntryWrapper> optionsWrapper{get; set;}
    
    @AuraEnabled
    public String defaultPLEValue { get; set; }

    @AuraEnabled
    public Boolean maskField{ get; set; }
        
    @AuraEnabled
    public Boolean isAUniqueKey { get; set; }
        
    public EvisortFieldWrapper( String fn, String fl, string ft ){
        fieldName = fn;
        fieldLabel = fl;
        fieldType = ft;
        fieldSOAPType = ft;
		fieldTypeLWC = '';
    }
    
    public Integer compareTo(Object objToCompare) {
                //Sort by BookName Alphabetically
        return fieldLabelStandard.compareTo(((EvisortFieldWrapper)objToCompare).fieldLabelStandard.toUpperCase());
    } 
        
   @AuraEnabled
   public static List<EvisortFieldWrapper> getAllFieldsWrapper(String objectName)
    {
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        DescribeSObjectResult dsr = schemaMap.get(objectName).getDescribe();
        if (objectName == 'ContentVersion') {
            List<String> fields = new List<String>{'Title', 'FileExtension', 'ContentSize', 'CreatedDate', 'LastModifiedDate'};
            return getFieldWrappers(dsr, fields);
        }
        else {
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
            List<String> allFieldNames = new List<String>();

            for(Schema.SObjectField sfield : fieldMap.Values())
            {
                Schema.DescribeFieldResult dfield = sfield.getDescribe();
                allFieldNames.add(dfield.getname());
            }

            return getFieldWrappers(dsr, allFieldNames);
        }
    }

    public static List<EvisortFieldWrapper> getFieldWrappers( String objectName, List<String> fields )
    {
		List<EvisortFieldWrapper> wrappers = new List<EvisortFieldWrapper>();        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        if( schemaMap != null && !schemaMap.isEmpty() ){
            Schema.SObjectType objSchema = schemaMap.get(objectName);
            if( objSchema != null ){
               	wrappers = getFieldWrappers( objSchema.getDescribe(), fields );
            }
        }
        return wrappers;
    }
    
    public static List<EvisortFieldWrapper> getFieldWrappers(  DescribeSObjectResult dsr, List<String> fields ){
		List<EvisortFieldWrapper> wrappers = new List<EvisortFieldWrapper>();               
        Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();      
        for (String fieldName: fields) {
            if( fieldName != null && fieldName != ''){
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe(); 
                EvisortFieldWrapper fw = new EvisortFieldWrapper( fieldName, dfr.getLabel(), String.valueOf(dfr.getType()));
                fw.isFieldAccessible = dfr.isAccessible();
                fw.isFieldFilterable = dfr.isFilterable();
                fw.isEditable = dfr.isUpdateable();
                fw.isRequired = !dfr.isNillable();
                fw.isNameField = dfr.isNameField();
                fw.fieldHelpText = dfr.getInlineHelpText();
                fw.fieldLabelStandard = fw.fieldLabel;
                fw.maskField = false;
                fw.fieldSOAPType = dfr.getSOAPType() + '';
                if( fw.fieldType == String.valueOf(Schema.DisplayType.TEXTAREA)){
                    if( dfr.isHtmlFormatted() ){
                        fw.fieldType = 'RICHTEXTAREA';
                    }
                }
                if( dfr.isCalculated()){
                    fw.fieldType = 'FORMULA';
                    fw.formulaFieldType = String.valueOf(dfr.getType());
                }
                if(fw.fieldName == 'ContentSize'){
                    fw.fieldLabel = System.Label.Filter_SizeInKB;
                }
                if( fw.fieldType == String.valueOf(Schema.DisplayType.REFERENCE)){
                    Schema.DescribeSObjectResult objD ;
                    if( fw.fieldName == 'OwnerId' && dfr.getReferenceTo().size() > 1){
                        objD = dfr.getReferenceTo()[1].getDescribe();
                    }else{
                        objD = dfr.getReferenceTo()[0].getDescribe();
                    }
                    fw.fieldReferenceObjectApiName = objD.getName();
                    fw.fieldRelationshipName = dfr.getRelationshipName();
                    if( fw.fieldName == 'CreatedById' ){
                        fw.fieldLabel = 'Created By';
                    }else if( fw.fieldName == 'LastModifiedById' ){
                        fw.fieldLabel = 'Last Modified By';
                    }else if(fw.fieldName == 'RecordTypeId'){
                        fw.fieldLabel = 'Record Type Name';
                        fw.fieldType = 'MULTIPICKLIST';
                        fw.fieldName = 'RecordType.Name';
                    }
                }
                if( fw.fieldType == String.valueOf(Schema.DisplayType.PICKLIST) || 
                    fw.fieldType == String.valueOf( Schema.DisplayType.MULTIPICKLIST)){
                        Map<String, String> optionsMap = new Map<String, String>();

                        List<PicklistEntryWrapper> picklistOptions = new List<PicklistEntryWrapper>();
                        for( Schema.PicklistEntry ple : dfr.getpicklistvalues() ){
                            if( dsr.getName() == 'AccountTeamMember' && (
                                fw.fieldName == 'AccountAccessLevel' || 
                                fw.fieldName == 'ContactAccessLevel' || 
                                fw.fieldName == 'CaseAccessLevel' || 
                                fw.fieldName == 'OpportunityAccessLevel')){                                        
                                    if( !((fw.fieldName == 'AccountAccessLevel' && ple.label == 'Private' )|| ple.label == 'Owner' )){
                                        optionsMap.put( ple.value, ple.label ) ; 
                                        picklistOptions.add(new PicklistEntryWrapper(ple.value, ple.label));   
                                    }
                                }else{
                                    if( ple.active ){
                                        optionsMap.put( ple.value, ple.label ) ;     
                                        picklistOptions.add(new PicklistEntryWrapper(ple.value, ple.label));                        
                                    }
                                    if(ple.defaultvalue){
                                    fw.defaultPLEValue = ple.value;
                                    }
                                }
                        }
                        fw.options = optionsMap;
                        fw.optionsWrapper = picklistOptions;
                    }   
                if( fw.fieldType != null ){
                    if( fw.fieldType == 'STRING'){
                        fw.fieldTypeLWC = 'text';
                    }
                    if( fw.fieldType == 'TEXTAREA'){
                        fw.fieldTypeLWC = 'textarea';
                    }
                    else{
                        fw.fieldTypeLWC = fw.fieldType.toLowerCase() ;
                    }
                }else{ 
                    fw.fieldTypeLWC = '';
                }
                wrappers.add( fw );      
            }
        }   
        return wrappers;
    }
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper{

        @AuraEnabled
        public Boolean selected {get;set;}
        @AuraEnabled
        public String active {get;set;}
        @AuraEnabled
        public String defaultValue {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }

        public PicklistEntryWrapper(String value, String label){
            this.value = value;
            this.label = label;   
            this.selected = false;         
        }
        
    }
}