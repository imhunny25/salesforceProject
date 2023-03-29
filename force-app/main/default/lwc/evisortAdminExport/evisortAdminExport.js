import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import getExportObjects from "@salesforce/apex/ExportController.getExportObjects";
import getObjectList from "@salesforce/apex/ExportController.getObjectList";
import calculateObject from "@salesforce/apex/ExportController.calculateObject";
import resetObjects from "@salesforce/apex/ExportController.resetObjects";
import startExport from "@salesforce/apex/ExportController.startExport";
import cancelExport from "@salesforce/apex/ExportController.cancelExport";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage } from "c/csUtils";
import { refreshApex } from "@salesforce/apex";

export default class EvisortAdminExport extends NavigationMixin(LightningElement) {
    @api iconsvgurl;
    @api activestate;

    @track jobStatus = {};
    @track objects = [];
    @track librarys = [];

    label = labels;
    keyIndex = -1;
    keyIndexforlibrary = -1;
    wiredResult;
    exportLoading = true;
    objectLoading = true;
    noAccessSVG = Evisort_Resources + "/evisortResources/evisortNoAccess.svg";

    get isLoading() {
        return this.exportLoading || this.objectLoading;
    }

    get showStatus() {
        return this.jobStatus !== undefined && this.jobStatus.status !== undefined && this.jobStatus.status !== null;
    }

    get totalFileSize() {
        return this.fileSizeLabel(this.jobStatus.totalSize);
    }

    get estimatedTime() {
        return this.label.formatLabel(this.label.adminEstimatedTime, [
            this.jobStatus.estimatedHours,
            this.jobStatus.estimatedMinutes
        ]);
    }

    get resetAllRowsDisabled() {
        return (this.objects.length == 0);
    }

    get resetAllLibraryRowsDisabled() {
        return (this.librarys.length == 0);
    }


    fileSizeLabel(totalSize) {
        return this.label.formatLabel(this.label.adminSizeOfFiles, [totalSize.toLocaleString()]);
    }

    @wire(getExportObjects)
    loadExportObjects(result) {
        this.wiredResult = result;
        if (result.data) {
            this.jobStatus = result.data;
            this.getObjectsFromMap();
        } else if (result.error) {
            showToast(this, this.label.adminError, getFilteredErrorMessage(result.error), "ERROR");
        }
        this.exportLoading = false;
    }

    @wire(getObjectList)
    loadObjectList({ error, data }) {
        if (data) {
            this.objectList = JSON.parse(JSON.stringify(data));
            this.objectLoading = false;
        } else if (error) {
            this.objectLoading = false;
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
    }

    /**
     * Converts the object map received by the BE into an array and converts the values to objects we can add elements to
     */
    getObjectsFromMap() {
        this.objects = [];
        this.librarys = [];
        let tempObjects = [];
        let tempLibrarys = [];
        if (this.jobStatus.objects !== undefined) {
            /* eslint-disable guard-for-in */
            for (let key in this.jobStatus.objects) {
                // Parse and stringify so we can add new elements to the object
                let objectValue = JSON.parse(JSON.stringify(this.jobStatus.objects[key]));
                if(objectValue.enableAddExport){
                    if(objectValue.enableLibraryFilter == false){
                        let thisObject = objectValue;
                        thisObject.fileSize =
                        thisObject.totalSize === undefined ? "" : this.fileSizeLabel(thisObject.totalSize);
                        thisObject.hasErrors = (thisObject.errored > 0);
                        thisObject.isEnableObjFileFilterSection = true;
                        tempObjects.push(thisObject); 
                    }else{
                        let thisLibrary = objectValue;    
                        thisLibrary.fileSize =
                        thisLibrary.totalSize === undefined ? "" : this.fileSizeLabel(thisLibrary.totalSize);
                        thisLibrary.hasErrors = (thisLibrary.errored > 0);
                        thisLibrary.isEnableObjFileFilterSection = true;
                        thisLibrary.showlibrarySection = true;
                        tempLibrarys.push(thisLibrary); 
                    }
                }
            }
        }
        this.objects = tempObjects;
        this.librarys = tempLibrarys;
    }

    /**
     * Adds a new blank row to the object list
     */
    addRow() {
        this.keyIndex++;
        let newItem = [
            {
                id: this.keyIndex.toString(),
                objectLabel: "",
                showdropdown: false,
                resetDisabled: true,
                calculateDisabled: true,
                showInfo: false,
                existingObject: false,
                objectFilterBody: "",
                fileFilterBody: "",
                isLegacy : true
            }
        ];
        this.objects = this.objects.concat(newItem);
    }

    /**
     * Resets all rows, effectively removing them
     */
    resetAllRows() {
        let objectNames = [];

        this.objects.forEach((object) => {
            objectNames.push(object.objectLabel);
        });

        this.exportLoading = true;
        resetObjects({ objectNames: objectNames })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, "", "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Resets a row, effectively removing it
     * @param {Event} event
     */
     resetObjectRow(event) {
        var eventData = event.detail;
        let objectNames = [];
        objectNames.push(this.objects[eventData.index].objectLabel);

        this.exportLoading = true;
        resetObjects({ objectNames: objectNames })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, "", "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Starts off the batch job to calculate how many documents are to be exported for a certain row
     * @param {Event} event
     */
    calculateObjectRow(event) {
        var eventData = event.detail;
        this.objects[eventData.index] = eventData.item;

        this.exportLoading = true;
        calculateObject({ obj: JSON.stringify(this.objects[eventData.index]) })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, this.label.adminCalculationStarted, "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    onStartJobClick() {
            this.startJob();
    }



    /**
     * Starts the overall Legacy Files Export job
     */
    startJob() {
        this.exportLoading = true;
        startExport()
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, this.label.adminExportInProgress, "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Cancels the Legacy Files Export job
     */
    cancelJob() {
        this.exportLoading = true;
        cancelExport()
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, this.label.adminCancelInProgress, "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Refreshes the page when the button is clicked to check status since we do not have Platform Events
     */
    @api
    refreshPage() {
        this.exportLoading = true;
        refreshApex(this.wiredResult)
            .then(() => {
                this.template.querySelectorAll('c-evisort-admin-object-setting').forEach((element) => {
                    element.init();
                });
                this.template.querySelectorAll('c-evisort-admin-library-setting').forEach((element) => {
                    element.init();
                });
                this.exportLoading = false;
            })
            .catch(() => {
                this.exportLoading = false;
            });
    }

    /**
     * Opens error report in a new tab when an Errored count is clicked
     */
    onErroredClick(event) {
        event.preventDefault();

        let index = event.currentTarget.dataset.index;
        let object = this.objects[index];

        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.jobStatus.errorReportId,
                objectApiName: 'Report',
                actionName: 'view'
            },
            state: {
                fv0: object.name
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    /**
     * Resets all rows, effectively removing them
     */
    resetAllLibraryRows(){
        let objectNames = [];

        this.librarys.forEach((l) => {
            objectNames.push(l.objectLabel);
        });

        this.exportLoading = true;
        resetObjects({ objectNames: objectNames })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, "", "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Resets a row, effectively removing it
     * @param {Event} event
     */
    resetLibraryRow(event) {
      var eventData = event.detail;
      let objectNames = [];
      objectNames.push(this.librarys[eventData.index].objectLabel);

        this.exportLoading = true;
        resetObjects({ objectNames: objectNames })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, "", "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Adds a new blank row to the Library list
     */
    addRowforLibrary() {
        this.keyIndexforlibrary++;
        let newItem = [
            {
                id: this.keyIndexforlibrary.toString(),
                resetDisabled: true,
                calculateDisabled: true,
                showInfo: false,
                existingObject: false,
                fileFilterBody: "",
                showlibrarySection : false,
                isLegacy: true,
                objectLabel: ""
            }
        ];
        this.librarys = this.librarys.concat(newItem);
    }

    /**
     * Starts off the batch job to calculate how many documents are to be exported for a certain row
     * @param {Event} event
     */
    calculateLibraryRow(event){
        var eventData = event.detail;
        this.exportLoading = true;
        calculateObject({ obj: JSON.stringify(this.librarys[eventData.index]) })
            .then((result) => {
                if (result === true) {
                    showToast(this, this.label.adminSuccess, this.label.adminCalculationStarted, "SUCCESS");
                } else {
                    showToast(this, this.label.adminError, this.label.adminUnknownError, "ERROR");
                }
            })
            .catch((error) => {
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.refreshPage();
            });
    }

    /**
     * Handle Object Update
     */
    handleUpdateObjectItem(event){
        var eventData = event.detail;
        this.objects[eventData.index] = eventData.item;
    }

    /**
     * Handle Library Update
     */
    handleUpdateLibraryItem(event){
        var eventData = event.detail;
        this.librarys[eventData.index] = eventData.item;
    }
   
}