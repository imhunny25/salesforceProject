import { LightningElement, api, track, wire } from "lwc";
import getSyncCriteria from "@salesforce/apex/AdminController.getSyncCriteria";
import saveRootFolder from "@salesforce/apex/AdminController.saveRootFolder";
import saveObjectSettings from "@salesforce/apex/AdminController.saveObjectSettings";
import saveGlobalSettings from "@salesforce/apex/AdminController.saveGlobalSettings";
import Evisort_Resources from "@salesforce/resourceUrl/Evisort";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage } from "c/csUtils";

export default class EvisortAdminSyncCriteria extends LightningElement {
    @api iconsvgurl;
    @api activestate;

    @track objectSettings = [];
    @track objectList = [];
    @track filteredlist = [];
    deletedObjects = [];
    deletedLibrarys = [];

    @track rootFolder;
    @track toggleValue = false;
    @track isLoading = true;
    @track librarySettings = [];

    keyIndex = -1;
    keyIndexforlibrary = -1;
    label = labels;
    noAccessSVG = Evisort_Resources + "/evisortResources/evisortNoAccess.svg";

    @wire(getSyncCriteria)
    loadSyncCriteria({ error, data }) {
        if (data) {
            this.objectSettings = [];
            this.librarySettings = [];
            let tempobjectSettings = [];
            let templibrarySettings = [];
            this.rootFolder = data.rootFolder;
            this.toggleValue = data.allObjectsAndTypes;
            this.objectList = data.objectList;
            data.objectSettings.forEach(ele => {
                if(ele.enableAddExport == false){
                    if(ele.enableLibraryFilter){
                        let thislibrary = JSON.parse(JSON.stringify(ele));
                        templibrarySettings.push(thislibrary);

                    }else{
                        let thisobject = JSON.parse(JSON.stringify(ele));;
                        tempobjectSettings.push(thisobject); 
                    }
                }
            });

            this.objectSettings = tempobjectSettings;
            this.librarySettings = templibrarySettings;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        }
    }

    get noObjectsMessage() {
        return this.objectSettings.length === 0;
    }

    get nolibraryObjectMessage(){
        return this.librarySettings.length === 0;
    }
    onRootFolderChange(event) {
        this.rootFolder = event.detail.value;
    }

    addObjectRow() {
        this.keyIndex++;
        let newItem = [
            {
                id: this.keyIndex.toString(),
                objectLabel: "",
                showdropdown: false,
                newObject: true,
                objectFilterBody: "",
                fileFilterBody: "",
                calculateDisabled: true,
                resetDisabled: true,
                showInfo: false,
                existingObject: false,
                isLegacy : false,
                libraryMapping : ""
            }
        ];
        this.objectSettings = this.objectSettings.concat(newItem);
    }

    addLibraryRow() {
        this.keyIndexforlibrary++;
        let newItem = [
            {
                id: this.keyIndexforlibrary.toString(),
                resetDisabled: true,
                calculateDisabled: true,
                objectLabel: "",
                showInfo: false,
                newObject: true,
                existingObject: false,
                fileFilterBody: "",
                showlibrarySection : false,
                isLegacy : false
            }
        ];
        this.librarySettings = this.librarySettings.concat(newItem);
    }

    removeObjectRow(event) {
        var eventData = event.detail;
        this.objectSettings[eventData.index] = eventData.item;
        if (this.objectSettings[eventData.index].newObject === false) {
            this.deletedObjects.push(this.objectSettings[eventData.index].id);
        }
        this.objectSettings.splice(eventData.index, 1);
        this.objectSettings = [...this.objectSettings];
    }

    resetLibraryRow(event){
        var eventData = event.detail;
        this.librarySettings[eventData.index] = eventData.item;
        if (this.librarySettings[eventData.index].newObject === false) {
            this.deletedLibrarys.push(this.librarySettings[eventData.index].id);
        }
        this.librarySettings.splice(eventData.index, 1);
        this.librarySettings = [...this.librarySettings];
    }

    saveRootFolder() {
        this.isLoading = true;

        saveRootFolder({ rootFolder: this.rootFolder })
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
                this.isLoading = false;
            });
    }

    saveObjectSettings() {
        var isChildVaild = true;
        this.template
            .querySelectorAll("c-evisort-admin-object-setting")
            .forEach(element => {
            if (element.checkValidations() === false ) {
                isChildVaild = false;
            }
        });

        if(isChildVaild){
            this.isLoading = true;
            const tempSettings = JSON.stringify(this.objectSettings);
            this.objectSettings = [];
            saveObjectSettings({ objectSettings: tempSettings, deletedObjectIds: JSON.stringify(this.deletedObjects) })
                .then((result) => {
                    result.forEach(ele => {
                        if(ele.enableAddExport == false){
                            if(ele.enableLibraryFilter == false){
                                let thisobject = ele;
                                this.objectSettings.push(thisobject); 
                            }
                        }
                    });

                this.objectSettings = [...this.objectSettings];
                showToast(this, this.label.adminSuccess, "", "SUCCESS");
            })
            .catch((error) => {
                this.objectSettings = JSON.parse(tempSettings);
                showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
            })
            .finally(() => {
                this.deletedObjects = [];
                this.isLoading = false;
            });
        }
    }

    saveLibrarySettings(event){
        var isChildVaild = true;
        this.template
            .querySelectorAll("c-evisort-admin-library-setting")
            .forEach(element => {
            if (element.checkValidations() === false) {
                isChildVaild = false;
            }
        });

        if(isChildVaild){
            this.isLoading = true;
            const tempSettings = JSON.stringify(this.librarySettings);
            this.librarySettings = [];
                saveObjectSettings({ objectSettings: tempSettings, deletedObjectIds: JSON.stringify(this.deletedLibrarys) })
                    .then((result) => {  
                        result.forEach(ele => {
                            if(ele.enableAddExport == false){
                                if(ele.enableLibraryFilter){
                                    let thislibrary = ele; 
                                    this.librarySettings.push(thislibrary); 
                                }
                            }
                        });
                        this.librarySettings = [...this.librarySettings];
                        showToast(this, this.label.adminSuccess, "", "SUCCESS");
                    })
                    .catch((error) => {
                        this.librarySettings = JSON.parse(tempSettings);
                        showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
                    })
                    .finally(() => {
                        this.deletedLibrarys = [];
                        this.isLoading = false;
                    });
        }
    }

    handleToggle(event) {
        this.toggleValue = event.target.checked;
        this.isLoading = true;
        //save toggle to custom settings
        saveGlobalSettings({ globalSettingType: "Sync Criteria", value: this.toggleValue })
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
                this.isLoading = false;
            });
    }

    handleUpdateObjectItem(event){
        var eventData = event.detail;
        this.objectSettings[eventData.index] = eventData.item;
    }

    handleUpdateLibraryItem(event){
        var eventData = event.detail;
        this.librarySettings[eventData.index] = eventData.item;
    }

}