@isTest
private class EvisortFieldWrapperTest {
	@isTest static void getAllFieldsWrapperTest() {
        Test.startTest();
        EvisortFieldWrapper kfw = new EvisortFieldWrapper('Test1','Test2','Test3');
    	kfw.fieldName  = 'Test';
        kfw.fieldLabel = 'Test';
        kfw.fieldType = 'Test';
        kfw.fieldTypeLWC= 'Test';
        kfw.formulaFieldType= 'Test';
        kfw.fieldRelationshipName= 'Test';
        kfw.fieldReferenceObjectApiName= 'Test';
        kfw.controllingFieldApiName= 'Test';
        kfw.fieldHelpText= 'Test';
        kfw.isFieldAccessible= true;
        kfw.isFieldFilterable= true;
        kfw.isNameField= true;
        kfw.fieldLabelStandard= 'Test';
        kfw.isRequired = true;
        kfw.isHtmlFormatted= true;
        kfw.isAUniqueKey = true;
        
        kfw.controllingValueWithDependnetValues= new Map<String, List<EvisortFieldWrapper.PicklistEntryWrapper>>();
        kfw.options = new Map<String, String>();
        List<EvisortFieldWrapper.PicklistEntryWrapper> optionsWrapper = new List<EvisortFieldWrapper.PicklistEntryWrapper>();
        String defaultPLEValue = 'Test';
        Boolean maskField= true;
        Boolean isAUniqueKey= true;
        
        EvisortFieldWrapper kfw1 = new EvisortFieldWrapper('Test1','Test2','Test3');
        List<EvisortFieldWrapper> gafw = EvisortFieldWrapper.getAllFieldsWrapper('Opportunity');
        CSUtils.itShouldBe('', true, !gafw.isEmpty());

    }
}