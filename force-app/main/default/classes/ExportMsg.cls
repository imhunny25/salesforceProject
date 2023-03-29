public with sharing class ExportMsg {
    public class ExportStatus {
        @AuraEnabled
        public Map<String, ExportObject> objects;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Decimal numberOfDocuments;
        @AuraEnabled
        public Decimal completed;
        @AuraEnabled
        public Decimal oversized;
        @AuraEnabled
        public Decimal errored;
        @AuraEnabled
        public Decimal remaining;
        @AuraEnabled
        public Decimal totalSize;
        @AuraEnabled
        public Decimal estimatedMinutes;
        @AuraEnabled
        public Decimal estimatedHours;
        @AuraEnabled
        public Id oversizedReportId;
        @AuraEnabled
        public Id errorReportId;
        @AuraEnabled
        public String objectFilterBody;

        // Calculations on which FE buttons are enabled or disabled
        // Easier to do here than in the FE
        @AuraEnabled
        public Boolean readyDisabled;
        @AuraEnabled
        public Boolean cancelDisabled;

        public ExportStatus() {
            this.objects = new Map<String, ExportObject>();
        }

        /**
         * Add a defined Object to the Map
         * @param  eeo Evisort Export Object record
         */
        public void addObject(Evisort_Export_Object__c eeo) {
            if (!this.objects.keySet().contains(eeo.Object__c)) {
                this.objects.put(eeo.Object__c, new ExportObject(eeo));
            }
        }

        public void addObject(Evisort_Export_Filter__c eef, List<Evisort_Export_Object__c> eeo){
            if (!this.objects.keySet().contains(eef.Object__c) && eef.Is_Legacy__c == true) {
                this.objects.put(eef.Object__c, new ExportObject(eef, eeo));
            }
        } 

        /**
         * Add a Document Sync Criteria to the map
         * @param  criteria Evisort Document Sync Criteria record
         */
        public void addObject(Evisort_Document_Sync_Criteria__c criteria) {
            if (!this.objects.keySet().contains(criteria.Object__c)) {
                this.objects.put(criteria.Object__c, new ExportObject(criteria));
            }
        }

        /**
         * Calculate the progress across all objects
         */
        public void calculate() {
            this.numberOfDocuments = 0;
            this.completed = 0;
            this.errored = 0;
            this.totalSize = 0;
            for (ExportObject eo : this.objects.values()) {
                if (eo.numberOfDocuments != null) {
                    this.numberOfDocuments += eo.numberOfDocuments;
                }
                if (eo.completed != null) {
                    this.completed += eo.completed;
                }
                if (eo.errored != null) {
                    this.errored += eo.errored;
                }
                if (eo.totalSize != null) {
                    this.totalSize += eo.totalSize;
                }

                if (
                    (this.status == null) ||
                    (Constants.EXPORT_STATUSES.indexOf(eo.status) > Constants.EXPORT_STATUSES.indexOf(this.status))
                ) {
                    this.status = eo.status;
                }
            }

            this.remaining = this.numberOfDocuments - this.completed - this.errored;
            Decimal totalMinutesRemaining = (this.remaining / Constants.EXPORTS_PER_MINUTE)
                .round(System.RoundingMode.CEILING);
            this.estimatedHours = (totalMinutesRemaining / 60).round(System.RoundingMode.DOWN);
            this.estimatedMinutes = Math.mod(totalMinutesRemaining.longValue(), 60);

            this.readyDisabled = this.status != Constants.EXPORT_READY;
            this.cancelDisabled = this.status != Constants.EXPORT_RUNNING;
        }

        /**
         * Sort the Map key values alphabetically
         */
        public void sort() {
            List<String> keys = new List<String>(this.objects.keySet());
            keys.sort();

            Map<String, ExportObject> sorted = new Map<String, ExportObject>();
            for (String key : keys) {
                sorted.put(key, this.objects.get(key));
            }

            this.objects = sorted;
        }
    }

    public class ExportObject {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Boolean groupedError;
        @AuraEnabled
        public Decimal numberOfDocuments;
        @AuraEnabled
        public Decimal completed;
        @AuraEnabled
        public Decimal oversized;
        @AuraEnabled
        public Decimal errored;
        @AuraEnabled
        public Decimal totalSize;
        @AuraEnabled
        public List<String> fileTypes;
        @AuraEnabled
        public List<String> recordTypes;
        @AuraEnabled
        public List<AdminMsg.ObjectRecordType> recordTypeList;

        // Calculations on which FE buttons or UI sections are enabled or disabled
        // Easier to do here than in the FE
        @AuraEnabled
        public Boolean showInfo;
        @AuraEnabled
        public Boolean resetDisabled;
        @AuraEnabled
        public Boolean calculateDisabled;
        @AuraEnabled
        public Boolean existingObject; // Always true here, false only with objects created in the FE
        @AuraEnabled
        public String objectFilterBody;    
        @AuraEnabled
        public String fileFilterBody;
        @AuraEnabled
        public Boolean enableAddExport;
        @AuraEnabled
        public Boolean enableLibraryFilter;
        @AuraEnabled
        public String libraryName;
        @AuraEnabled
        public Boolean isLegacy;
        @AuraEnabled
        public String libraryMapping; 
        

        public ExportObject() {
        }

        public ExportObject(Evisort_Export_Object__c eeo) {
            this.id = eeo.Id;
            this.name = eeo.Name;
            this.objectLabel = eeo.Object__c;
            this.status = eeo.Status__c;
            this.numberOfDocuments = eeo.Number_of_Documents__c;
            this.completed = eeo.Completed__c;
            this.errored = eeo.Errored__c;
            this.totalSize = eeo.Total_Size__c;
            this.showInfo = true;
            this.existingObject = true;
            this.resetDisabled = !Constants.EXPORT_RESETABLLE_STATUSES.contains(this.status);
            this.calculateDisabled = !Constants.EXPORT_COMPLETE_STATUSES.contains(this.status);

            this.fileTypes = (String.isEmpty(eeo.File_Types__c)) ? new List<String>() : eeo.File_Types__c.split(',');
            this.recordTypes = (String.isEmpty(eeo.Record_Types__c))
                ? new List<String>()
                : eeo.Record_Types__c.split(',');
            this.recordTypeList = AdminService.getRecordTypes(eeo.Object__c);
        }

        public ExportObject(Evisort_Document_Sync_Criteria__c criteria) {
            this.id = criteria.Id;
            this.objectLabel = criteria.Object__c;
            this.showInfo = false;
            this.calculateDisabled = false;
            this.resetDisabled = true;
            this.existingObject = true;

            this.fileTypes = (String.isEmpty(criteria.File_Type__c))
                ? new List<String>()
                : criteria.File_Type__c.split(',');
            this.recordTypes = (String.isEmpty(criteria.Record_Type__c))
                ? new List<String>()
                : criteria.Record_Type__c.split(',');
            this.recordTypeList = AdminService.getRecordTypes(criteria.Object__c);
        }

        public ExportObject(Evisort_Export_Filter__c criteria, List<Evisort_Export_Object__c> exportObjectList) {
            EvisortExportObjectSelector eeoSelector = new EvisortExportObjectSelector();
            this.numberOfDocuments = 0;
            this.completed = 0;
            this.errored = 0;
            this.totalSize = 0;
            this.status = Constants.EXPORT_CALCULATING;

            this.id = criteria.Id;
            this.name = criteria.Name;
            this.objectLabel = criteria.Object__c;
            this.isLegacy = true;
            this.showInfo = true;
            this.existingObject = true;
            this.groupedError = false;

            Integer numberOfComplete = 0;
            Integer numberOfErrored = 0;
            Integer numberOfCanceled = 0;
            Set<String> statusList = new Set<String>();
            for(Evisort_Export_Object__c exportObject : exportObjectList){
                if(exportObject.Status__c != null){
                    statusList.add(exportObject.Status__c);
                }
                if(exportObject.Status__c == Constants.EXPORT_READY || exportObject.Status__c == Constants.EXPORT_CANCELLED
                || exportObject.Status__c == Constants.EXPORT_RUNNING ){
                    this.status = exportObject.Status__c;
                }
            
                if(exportObject.Number_of_Documents__c != 0){
                    this.numberOfDocuments += exportObject.Number_of_Documents__c;
                    this.completed += exportObject.Completed__c;
                    this.errored += exportObject.Errored__c;
                    this.totalSize += exportObject.Total_Size__c;
                    this.groupedError = exportObject.Grouped_Error__c;

                    if(this.groupedError){
                        numberOfErrored += 1;
                    }else if(this.status == Constants.EXPORT_COMPLETE){
                        numberOfComplete += 1;
                    }
                }
            }

            if(statusList.size() > 0 && !statusList.contains(Constants.EXPORT_RUNNING) && !statusList.contains(Constants.EXPORT_READY)
            && !statusList.contains(Constants.EXPORT_CANCELLED) && !statusList.contains(Constants.EXPORT_CALCULATING)){
                if(numberOfErrored != 0){
                    this.status = Constants.EXPORT_ERRORED;
                }else {
                    this.status = Constants.EXPORT_COMPLETE;
                }
            }
            this.objectFilterBody = criteria.Object_Filter_Body__c;
            this.fileFilterBody = criteria.File_Filter_Body__c; 
            this.resetDisabled = !Constants.EXPORT_RESETABLLE_STATUSES.contains(this.status);
            this.calculateDisabled = !Constants.EXPORT_COMPLETE_STATUSES.contains(this.status);
            if(criteria.Is_Library__c == true){
                Set<Id> libraryIds = new Set<Id>{criteria.Object__c};
                List<ContentWorkspace> contentList =  eeoSelector.getLibraryName(libraryIds);
                this.libraryName = contentList[0].Name;
             }
             this.enableLibraryFilter = criteria.Is_Library__c;
             this.enableAddExport = criteria.Is_Legacy__c;
            this.libraryMapping = criteria.Library_Mapping__c;

        }
    }
    
    public class libraryObjectMapping {
        public String sObjectName;
        public Boolean isLibraryObjectCheck;
        public String libraryName;
        public String customField;
    }
}