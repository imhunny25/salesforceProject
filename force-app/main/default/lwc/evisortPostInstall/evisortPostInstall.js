import { LightningElement, track, api } from 'lwc';
import updateEvisortWorkspaceSetting from "@salesforce/apex/PostInstallationController.updateEvisortWorkspaceSetting";
import saveScheduler from "@salesforce/apex/PostInstallationController.saveScheduler";
import deleteScheduler from "@salesforce/apex/PostInstallationController.deleteScheduler";
import init from "@salesforce/apex/PostInstallationController.init";
import labels from "c/labelService";
import { showToast, getFilteredErrorMessage, isBlank } from "c/csUtils";

export default class EvisortPostInstall extends LightningElement {
  label = labels;
  @track domain;
  @track subDomain;
  @track workspace;
  @track updateEnable = false;
  @track isAuthenticate = false;
  @track deleteInformation;
  @track deleteHeader;
  @track AuthenticateStatus;
  @track isSchedule = false;
  @track isDeleteJobSchedulerModel = false;
  @track loaded = false;
  @track loadedEdit = false;
  @track deleteSchedule;
  @track jobSchedule;
  @track isSpinner = true;
  @track isScheduleMetaData = false;
  @track isScheduleExportLegacy = false;
  @track isAppPermission;
  @track isTurnOnLog;
  @track turnLogId;
  status;
  accordianSection = '';
  evisortAdminPermissionSetId;
  adminUserPermissionSetId;
  @track isModalOpen = false;

  @api
  handleChange(status) {
    if (status == true) {
      this.AuthenticateStatus = true;
    }
  }

  connectedCallback() {
    this.isSpinner = true
    this.evisortWorkSpaceSettingsUpdate();

    init().then((result) => {
      this.isAuthenticate = JSON.parse(result.namedCredential);
      this.isAppPermission = JSON.parse(result.AppPermission);
      this.AuthenticateStatus = JSON.parse(result.Authenticate);
      if (JSON.parse(JSON.stringify(result.TurnOnLog)) == 'true') {
        this.isTurnOnLog = true;
      } else {
        this.turnLogId = result.TurnOnLog;
      }
      if (JSON.parse(result.isDocumentSyncValue) == false) {
        this.isSchedule = true;
      }
      if (JSON.parse(result.isEvisortMetadataValue) == false) {
        this.isScheduleMetaData = true;
      }
      if (JSON.parse(result.isExportLegacyValue) == false) {
        this.isScheduleExportLegacy = true;
      }
      if (result.adminPermissionSetId != '') {
        this.evisortAdminPermissionSetId = result.adminPermissionSetId;
      }
      if (result.userPermissionsetId != '') {
        this.adminUserPermissionSetId = result.userPermissionsetId;
      }

      this.isSpinner = false;
    }).catch((error) => {
      showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
      this.isSpinner = false;
    });
  }

  evisortWorkSpaceSettingsUpdate() {
    updateEvisortWorkspaceSetting({ domain: this.domain, subDomain: this.subDomain, workspace: this.workspace })
      .then((result) => {
        this.domain = result.domain;
        this.subDomain = result.subdomain;
        this.workspace = result.workspace;

      }).catch((error) => {
        this.updateEnable = false;
        showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
      });
  }


  handleAuth() {
    const stateChange = new CustomEvent("statechange");
    this.dispatchEvent(stateChange);
  }

  handleToggleSection(event) {
    if (this.accordianSection.length === 0) {
      this.accordianSection = '';
    }
  }

  openEvisortPermissionSet() {
    let sfdxBaseUrl = window.location.origin;
    let url = sfdxBaseUrl + '/lightning/setup/PermSets/' + this.evisortAdminPermissionSetId + '/PermissionSetAssignment/home';
    window.open(url, "_blank");
  }

  openEvisortUserPermissionSet() {
    let sfdxBaseUrl = window.location.origin;
    let url = sfdxBaseUrl + '/lightning/setup/PermSets/' + this.adminUserPermissionSetId + '/PermissionSetAssignment/home';
    window.open(url, "_blank");
  }

  openTurnOnLogSettings() {
    let sfdxBaseUrl = window.location.origin;
    let url = sfdxBaseUrl + '/' + this.turnLogId;
    window.open(url, "_blank");
  }

  handlerDomain(event) {
    this.domain = event.target.value;
    this.updateEnable = this.checkWorkspaceButton();
  }

  handlerSubDomain(event) {
    this.subDomain = event.target.value;
    this.updateEnable = this.checkWorkspaceButton();
  }

  handlerWorkspace(event) {
    this.workspace = event.target.value;
    this.updateEnable = this.checkWorkspaceButton();
  }

  checkWorkspaceButton() {
    var check = false;
    if (!isBlank(this.domain) && !isBlank(this.subDomain) && !isBlank(this.workspace)) {
      check = true;
    }
    return check;
  }

  handlerPostInstallation() {
    if (!isBlank(this.domain) && !isBlank(this.subDomain) && !isBlank(this.workspace)) {
      this.updateEnable = true;
      updateEvisortWorkspaceSetting({ domain: this.domain, subDomain: this.subDomain, workspace: this.workspace })
        .then((result) => {
          this.domain = result.domain;
          this.subDomain = result.subdomain;
          this.workspace = result.workspace;
          this.updateEnable = false;
          showToast(this, this.label.adminSuccess, getFilteredErrorMessage("Mapping has been Save Successfully"), "SUCCESS");
        })
        .catch((error) => {
          this.updateEnable = false;
          showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        });
    }
  }

  launchSetupNamedCredentials() {
    window.open("/lightning/setup/NamedCredential/home", "_blank");
  }

  closeModal = this.handleClickCancel.bind(this);

  handleClickCancel() {
    this.isDeleteJobSchedulerModel = false;
    this.isModalOpen = false;
  }

  scheduleHandler(event) {
    this.isModalOpen = true;
    this.template.querySelector("c-evisort-post-install-Schedule-Job").newSchedule();
    this.jobSchedule = event.target.value;
  }

  metadataHourlyHandler(event) {
    this.isModalOpen = true;
    this.template.querySelector("c-evisort-post-install-Schedule-Job").newSchedule();
    this.jobSchedule = event.target.value;
  }


  ExportLegacyHandler(event) {
    this.isModalOpen = true;
    this.template.querySelector("c-evisort-post-install-Schedule-Job").newSchedule();
    this.jobSchedule = event.target.value;
  }

  isModalClose(event) {
    this.isModalOpen = event.detail;
  }

  handleClick(event) {
    this.isSpinner = true;
    var details = event.detail;
    saveScheduler({ scheduleData: JSON.stringify(details), jobName: this.jobSchedule })
      .then((result) => {
        this.isModalOpen = false;
        if (result == this.label.adminDocumentSyncJob) {
          this.isSchedule = false;
        } else if (result == this.label.adminMetaDataSyncJob) {
          this.isScheduleMetaData = false;
        } else if (result == this.label.adminExportLegacyLeanupJob) {
          this.isScheduleExportLegacy = false;
        }
        this.isSpinner = false;
        showToast(
          this,
          this.label.adminSuccess,
          getFilteredErrorMessage("Job Schedualed Successfully"),
          "Success"
        );
      }).catch((error) => {
        this.isSpinner = false;
        showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
      });
  }

  editScheduleHandler(event) {
    var editshedularRef = event.target.value;
    this.jobSchedule = editshedularRef;
    this.isModalOpen = true;
    this.template.querySelector("c-evisort-post-install-Schedule-Job").newSchedule();
    this.template.querySelector("c-evisort-post-install-Schedule-Job").editSchedule(this.jobSchedule);
  }

  deleteHandler = this.handleDelete.bind(this);

  handleDelete() {
    this.isSpinner = true;
    deleteScheduler({ deleteSchedulerJob: this.deleteSchedule })
      .then(result => {
        this.isDeleteJobSchedulerModel = false;
        if (result == this.label.adminDocumentSyncJob) {
          this.isSchedule = true;
          this.isDeleteJobSchedulerModel = false;
        } else if (result == this.label.adminMetaDataSyncJob) {
          this.isDeleteJobSchedulerModel = false;
          this.isScheduleMetaData = true;
        } else if (result == this.label.adminExportLegacyLeanupJob) {
          this.isDeleteJobSchedulerModel = false;
          this.isScheduleExportLegacy = true;
        }
        this.isSpinner = false;
        showToast(
          this,
          this.label.adminSuccess,
          getFilteredErrorMessage("Job Deleted Successfully"),
          "Success"
        );
      }).catch((error) => {
        this.isSpinner = false;
        showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
      });
  }

  isDeleteJobShedular(event) {
    this.deleteSchedule = event.target.value;
    this.isDeleteJobSchedulerModel = true;
    this.deleteInformation = 'Are you sure you want to delete this Document Sync Job?';
    this.deleteHeader = 'Delete Document Sync Job';
  }

  metadataHourlyDeleteHandler(event) {
    this.deleteSchedule = event.target.value;
    this.isDeleteJobSchedulerModel = true;
    this.deleteInformation = 'Are you sure you want to delete this Metadata Sync Job?';
    this.deleteHeader = 'Delete Evisort Metadata Job';

  }

  exportLegacyDeleteHandler(event) {
    this.deleteSchedule = event.target.value;
    this.isDeleteJobSchedulerModel = true;
    this.deleteInformation = 'Are you sure you want to delete the Export Legacy CleanUp Job?';
    this.deleteHeader = 'Delete Export Legacy CleanUp Job';
  }
}