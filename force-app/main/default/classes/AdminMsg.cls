public with sharing class AdminMsg {
    public class AuthStatus {
        @AuraEnabled
        public Boolean authenticated;
        @AuraEnabled
        public DateTime authenticationDate;
        @AuraEnabled
        public DateTime lastDocumentSync;
        @AuraEnabled
        public DateTime lastFieldPull;
        @AuraEnabled
        public String version;

        public AuthStatus(Evisort_Status__c status) {
            this.authenticated = status.Authenticated__c;
            this.authenticationDate = status.Authentication_Date__c;
            this.lastDocumentSync = status.Last_Document_Sync__c;
            this.lastFieldPull = status.Last_Field_Pull__c;
            this.version = Constants.API_VERSION;
        }
    }

    public class VerifyAuthResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;

        public VerifyAuthResponse() {
            this.success = true;
        }

        public VerifyAuthResponse(String inMessage) {
            this.success = false;
            this.message = inMessage;
        }
    }

    public class FieldDefinition {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Datetime createdDate;
        @AuraEnabled
        public Datetime lastModifiedDate;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String dataType;
        @AuraEnabled
        public String fieldType;
        @AuraEnabled
        public Boolean isActive;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean readOnly;

        public FieldDefinition(Evisort_Field_Definition__c efd) {
            this.id = efd.Id;
            this.createdDate = efd.CreatedDate;
            this.lastModifiedDate = efd.LastModifiedDate;
            this.name = efd.Name;
            this.dataType = efd.Data_Type__c;
            this.fieldType = efd.Field_Type__c;
            this.isActive = efd.isActive__c;
            this.label = efd.Label__c;
            this.readOnly = efd.isReadOnly__c;
        }

        public Evisort_Field_Definition__c toRecord() {
            Evisort_Field_Definition__c efd = new Evisort_Field_Definition__c();
            efd.Id = this.id;
            if(this.isActive != null){
                efd.isActive__c = this.isActive;
            }
            if(this.readOnly != null){
                efd.isReadOnly__c = this.readOnly;
            }

            return efd;
        }
    }

    public class ObjectRecordType {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        public ObjectRecordType(String inValue) {
            this.label = inValue;
            this.value = inValue;
        }
    }

    public class SyncCriteria {
        @AuraEnabled
        public String rootFolder;
        @AuraEnabled
        public List<ObjectSetting> objectSettings;
        @AuraEnabled
        public List<String> objectList;
        @AuraEnabled
        public Boolean allObjectsAndTypes;

        public SyncCriteria(Boolean inAllObjects) {
            this.objectSettings = new List<ObjectSetting>();
            this.objectList = new List<String>();
            this.allObjectsAndTypes = inAllObjects;
        }
    }

    public class ObjectSetting implements Comparable {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public String objectFilterBody;
        @AuraEnabled
        public String fileFilterBody;
        @AuraEnabled
        public Boolean newObject;
        @AuraEnabled
        public Boolean isEnableObjFileFilterSection;
        @AuraEnabled
        public Boolean enableAddExport;
        @AuraEnabled
        public Boolean enableLibraryFilter;
        @AuraEnabled
        public String libraryName;
        @AuraEnabled
        public Boolean showlibrarySection;
        @AuraEnabled
        public Boolean isLegacy;
        @AuraEnabled
        public String libraryMapping;

        public ObjectSetting() {
        }

        public ObjectSetting(Evisort_Export_Filter__c criteria) {
            this.id = criteria.Id;
            this.objectLabel = criteria.Object__c;
            this.isLegacy = false;
            if(criteria.Object_Filter_Body__c != null){
                this.objectFilterBody = criteria.Object_Filter_Body__c;
            }else{
                this.objectFilterBody = '';
            }
            if(criteria.File_Filter_Body__c != null){
                this.fileFilterBody = criteria.File_Filter_Body__c;
            }else{
                this.fileFilterBody  = '';
            }
            if(criteria.Library_Mapping__c != null){
                this.libraryMapping = criteria.Library_Mapping__c;
            }else{
                this.libraryMapping = '';
            }
            this.isEnableObjFileFilterSection = true;
            this.newObject = false;
            this.enableAddExport = criteria.Is_Legacy__c;
            this.enableLibraryFilter = criteria.Is_Library__c;
            this.showlibrarySection = true;
        }
        public Evisort_Export_Filter__c toRecord(String name) {
            Evisort_Export_Filter__c criteria = new Evisort_Export_Filter__c();
            if (this.id.length() > 10) {
                criteria.Id = (Id)this.id;
            }
            if(name != null){
                criteria.Name = name;
            }else{
                criteria.Name = this.objectLabel;
            }
            criteria.Object__c = this.objectLabel;
            criteria.Object_Filter_Body__c = this.objectFilterBody;
            criteria.File_Filter_Body__c = this.fileFilterBody;
            criteria.Library_Mapping__c = this.libraryMapping;
            criteria.Is_Legacy__c = false;
            if(this.enableLibraryFilter == true){
                criteria.Is_Library__c = true;
            }else {
                criteria.Is_Library__c = false;
            } 
            return criteria;
        }

        public Integer compareTo(Object o) {
            ObjectSetting os = (ObjectSetting) o;
            if (this.objectLabel > os.objectLabel) {
                return 1;
            } else if (this.objectLabel < os.objectLabel) {
                return -1;
            }
            return 0;
        }
    }
    public class ObjectWrapper{
        public String label { get;set; }
        public String value { get;set; }
    }


    public class DocumentFieldSyncMappingRecord {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String salesforceFieldName;
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public String evisortDocumentFieldId;
        @AuraEnabled
        public String evisortExportFilter;
        @AuraEnabled
        public String evisortDocumentFieldName;
        @AuraEnabled
        public String objectName;
        @AuraEnabled
        public String evisortFieldDataType;

        public DocumentFieldSyncMappingRecord(Document_Field_Sync_Mapping__c dfm) {
            this.id = dfm.Id;
            this.name = dfm.Name;
            this.salesforceFieldName = dfm.Salesforce_Field_Name__c;
            this.fieldLabel = dfm.Field_Label__c;
            this.evisortDocumentFieldId = dfm.Evisort_Field_Definition__c;
            this.evisortExportFilter = dfm.Evisort_Export_Filter__c;
            this.evisortDocumentFieldName = dfm.Evisort_Field_Definition__r.Name;
            this.objectName = dfm.Object__c;
            this.evisortFieldDataType = dfm.Evisort_Field_Definition__r.Data_Type__c;

        }
    }

    public class SyncFieldAggregateResultWrapper{
        @AuraEnabled
        public DateTime createdDate;
        @AuraEnabled
        public DateTime lastModifiedDate;
        @AuraEnabled
        public String objectName;
        @AuraEnabled
        public String objectLabel;

        public SyncFieldAggregateResultWrapper(AggregateResult groupedResults){
            this.createdDate = (DateTime)groupedResults.get('CreatedDate');
            this.lastModifiedDate = (DateTime)groupedResults.get('LastModifiedDate');

            String thisNamespace = AdminMsg.class.getName().substringBefore('AdminMsg').removeEnd('.');
            String objName = (String.isBlank(thisNamespace)) ? 'Object__c' : thisNamespace + '__Object__c';
            String objectApiName = (String)groupedResults.get(objName);
            this.objectName = objectApiName;
            SObjectType sObjType = ((SObject) (Type.forName('Schema.' + objectApiName).newInstance())).getSObjectType();
            DescribeSObjectResult describeObject = sObjType.getDescribe();
            this.objectLabel = describeObject.getLabel();
        }
    }
}