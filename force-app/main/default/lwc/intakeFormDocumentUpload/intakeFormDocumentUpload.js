import { LightningElement,api,track } from 'lwc';
import removeDocument from "@salesforce/apex/NewIntakeFormController.removeDocument";
import labels from "c/labelService";
import { formatParameterizedCustomLabel, showToast, iconLookup, isBlank, isFileType } from "c/csUtils";

const COLS = [
  { label: 'File Name', fieldName: 'Title', type: 'text' },
  { label: 'FileType', fieldName: 'FileType', type: 'text' },
  { label: 'FileExtension', fieldName: 'FileExtension', type: 'text' }
];

export default class IntakeFormDocumentUpload extends LightningElement {
  labels = labels;
  cols = COLS;
  @api contentDocumentData = [];
  @api maxRowSelection;
  @api multiSelect;
  @api acceptedFileTypes;
  @api acceptedFileFormat;
  @api isMultipleFiles;
  @api objectApiName;
  @api allowedFileTypes;
  @api allowedFileTypeRule;
  @api isrequired = false;
  @api attachmentFiles;
  @api isEditMode;

  @track isMultipleUploaded=false;
  @track modalHeader;
  @track isExisting;
  @track isExistingDocuments = false;
  @track isSystemDocumentUpload = false;
  @track isUploaded = false;
  @track selectedFileValue;
  @track selectedFileName;
  @track documentIds = [];
  @track selectedRecords = [];
  @track selectedRows = [];
  @track selectedFileType;
  @track selectedFileExtension;
  @track multipleFiles = [];
  @track isOnCancel = false;

  tempContentDocuments = []; 
  previousFiles = [];
  contentDocumentIds = [];
  deleteFilesUploaded = [];
  previousContentDocuments = [];

  get showFileTypes() {
    return !!this.acceptedFileTypes?.length;
  }

  get acceptedFormats() {
    return this.acceptedFileFormat;
  }

  get acceptedTypes() {
    return formatParameterizedCustomLabel(this.labels.ticketIntakeFormAcceptedDocs, this.acceptedFileTypes);
  }

  get isMultiSelect() {
    if (this.multiSelect == 'true') {
      return '';
    } else if (this.multiSelect == 'false') {
      return '1';
    }
  }

  get singleDocumentDisabled() {
    if (this.isMultipleFiles == false) {
      if (this.multipleFiles.length == 0) {
        return false;
      } else if (this.multipleFiles.length > 0) {
        return true;
      }
    }
  }

  connectedCallback() {
   
    if(this.isMultiSelect == false)
    {
      this.isExisting = labels.ticketExistingSFDCDocuments;
    }else{
      this.isExisting = labels.ticketExistingSFDCDocument;
      this.isMultipleUploaded = true;
      let removeDotFromFileExtension =[];
      this.acceptedFormats.forEach(ele=>{
        let extensionData = ele.split('.');
        removeDotFromFileExtension.push(extensionData[1]);
      });
      let acceptedFormatsData =[];
      this.contentDocumentData.forEach(ele=>{
        let match = false;
        removeDotFromFileExtension.forEach(element =>{
          if(ele.FileExtension == element)
          {
            match = true;
          }
        })
        if(match == true)
        {
          acceptedFormatsData.push(ele);
        }
      })
      this.contentDocumentData = acceptedFormatsData;
    }

    this.modalHeader = this.objectApiName + ' Files';
      this.tempContentDocuments = this.contentDocumentData;
      this.contentDocumentData.forEach(element => {
        this.previousFiles.push(element.Id);
        this.contentDocumentIds.push(element.Id);
      });
      if (!this.multipleFiles.length > 0) {
        this.multipleFiles = [];
      }

    if (!isBlank(this.attachmentFiles)) {
      var attachment = [];
      attachment = this.multipleFiles;
      if (this.attachmentFiles.hasOwnProperty("valueList")) {
        this.attachmentFiles.valueList.forEach((field) => {
          let fileType;
          let fileIcon = iconLookup(field.fileName + field.fileType);
          let fileextension = field.fileType.split('.');
          fileType = isFileType(fileextension[fileextension.length-1]);
          attachment.push({ 'fileName': field.fileName, 'documentId': field.fileMetadata.document_id, 'fileIcon': fileIcon, 'fileextension':fileextension[fileextension.length-1], 'documentfiletype':fileType});
          this.previousContentDocuments.push(field.fileMetadata.document_id);
          this.documentIds.push(field.fileMetadata.document_id);
          this.previousFiles.push(field.fileMetadata.document_id);
        });
        this.multipleFiles = attachment;
        if (this.multipleFiles.length > 0) {
          this.isUploaded = true;
        }
      }
    }

    if(this.isEditMode == true)
    {
      let evsAttachments =[];
      this.contentDocumentData.forEach(element=>{
          let isMatch = false;
          this.multipleFiles.forEach(ele=>{
            if(element.Id == ele.documentId)
            {
              isMatch = true;
            }
          })
          if(isMatch == false)
          {
            evsAttachments.push(element);
          }
      })
      this.contentDocumentData = evsAttachments;
    }
  }

  rowSelectionHandler(event) {
    let currentRows = event.detail.selectedRows;
    if (this.selectedRows.length > 0) {
        let selectedIds = currentRows.map(row => row.id);
    }
    this.selectedRows = currentRows;
  }

  removeSelectedFiles(){
     let noRemovableData =[];
    if(this.multipleFiles.length > 0){
    this.contentDocumentData.forEach(element=>{
      let isMatch = false;
      this.multipleFiles.forEach(ele=>{
        if(element.Id == ele.documentId)
        {
          isMatch = true;
        }
      })
      if(isMatch == false)
      {
        if(!noRemovableData.includes(element)){
            noRemovableData.push(element);
        }
      }
    })  

    this.contentDocumentData = noRemovableData;
  }else{
    this.contentDocumentData = this.tempContentDocuments;
  }

  }

  existingDocumentHandler() {
    this.removeSelectedFiles();
    this.isExistingDocuments = true;
    this.isSystemDocumentUpload = false;
  }

  uploadDocumentHandler() {
    this.isExistingDocuments = false;
    this.isSystemDocumentUpload = true;
  }

  @track sfdcFiles =[];
  handleSearch(event) {
    this.isOnCancel = true;
    const searchKey = event.target.value.toLowerCase();
    this.sfdcFiles =[];
        if(this.multipleFiles.length == 0){
          this.sfdcFiles = this.tempContentDocuments;
        }else{
              this.tempContentDocuments.forEach(element=>{
                let match = false;
                this.multipleFiles.forEach(ele => {
                  if(ele.documentId == element.Id){
                    match = true;
                  }  
                  })
                  if(match == false){
                    this.sfdcFiles.push(element);
                  }
                });
              }

        if(this.sfdcFiles.length >0){
              if (searchKey) {
                          if (this.sfdcFiles) {
                            let searchFiles = [];
                            for (let record of this.sfdcFiles) {
                              let valuesArray = Object.values(record);
                              for (let val of valuesArray) {
                                let strVal = String(val);
                                if (strVal) {
                                  if (strVal.toLowerCase().includes(searchKey)) {
                                    searchFiles.push(record);
                                    break;
                                  }
                                }
                              }
                            }
                            this.contentDocumentData = searchFiles;
                          }
              } else {
                            let isMatchFiles = []
                            if(this.multipleFiles.length == 0){
                              this.contentDocumentData =[];
                              this.contentDocumentData = this.tempContentDocuments;
                            }else{
                              this.tempContentDocuments.forEach(element=>{
                                let filesTemp = false;
                                  this.multipleFiles.forEach(ele => {
                                    if(ele.documentId == element.Id){
                                      filesTemp = true;
                                    }
                                  });
                                  if(filesTemp == false)
                                  {
                                    isMatchFiles.push(element);
                                  }

                                });
                              this.contentDocumentData =[];  
                              this.contentDocumentData = isMatchFiles;
                            }
              }
        }
  }

  confirmSaveHandler()  {
      this.selectedRecords = [];
      if(!isBlank(this.selectedRows)){
      this.selectedRows.forEach(ele => {
        var fileName = ele.Title;
        var fileDocumentId = ele.Id;
        var documentfiletype = ele.FileType;
        var fileextension = ele.FileExtension;
        let fileIcon = iconLookup(ele.Title + '.' + ele.FileExtension);
        this.selectedRecords.push({ 'fileName': fileName, 'documentId': fileDocumentId, 'fileIcon': fileIcon, 'documentfiletype': documentfiletype, 'fileextension': fileextension });
        this.documentIds.push(fileDocumentId);
      });
    }
      let removeFilesFromContentDoc = [];
      this.contentDocumentData.forEach(ele=>{
            let match = false;
            this.selectedRows.forEach(element =>{
              if(ele.Id == element.Id)
              {
                match = true;
              }
            })
            if(match == false)
            {
              removeFilesFromContentDoc.push(ele);
            }
      });

      this.contentDocumentData =[];
      this.contentDocumentData = removeFilesFromContentDoc;
      this.isExistingDocuments = false;
      if (this.isMultipleFiles == false) {
        this.multipleFiles = [];
        if(!isBlank(this.selectedRecords)){
          this.multipleFiles = this.selectedRecords;
          this.isUploaded = true;
        }else{
          this.isUploaded = false;
        }
       
      } else {
        if(this.multipleFiles.length>0)
        {
          this.isUploaded = true;
        }else {
          this.isUploaded = false;
        }
                if (this.multipleFiles.length > 0 && !isBlank(this.selectedRecords)) {
                        
                          this.selectedRecords.forEach(ele => {
                              if (this.multipleFiles.find(temp => temp.documentId == ele.documentId) == null) {
                                this.multipleFiles.push(ele);
                              }
                          });
                           
                        
                } else {
                  if(!isBlank(this.selectedRecords)){
                    this.multipleFiles = this.selectedRecords;
                    this.isUploaded = true;
                  }
                  
                }
      }
      
      if(this.isOnCancel == true)
      {
        this.contentDocumentData =[];
        this.contentDocumentData = this.sfdcFiles;
      }
      this.selectedRows =[];
      if(this.documentIds.length > 0){
      this.dispatchEvent(
        new CustomEvent("fileuploaded", {
          detail: {
            documentId: this.documentIds
          }
        })
      );
    }
      
  }

  cancelCallback () {
      this.selectedRows = [];
      this.removeSelectedFiles();
      this.isExistingDocuments = false;
      this.isSystemDocumentUpload = false;
      if(this.isOnCancel == true){
        this.contentDocumentData = this.sfdcFiles;
      }
        this.isOnCancel = false;
  }

  handleUploadFinished(event) {
    this.selectedRecords = [];
    if (this.isMultipleFiles == false) {
      this.isMultipleUploaded = false;
    }
    let newMultipleFiles = event.detail.files;
    if (newMultipleFiles.length > 0) {
      newMultipleFiles.forEach(element => {
        let fileIcon = iconLookup(element.name);
        let fileName = element.name.split('.').slice(0, -1).join('.');
        this.selectedRecords.push({ 'fileName': fileName, 'documentId': element.documentId, 'fileIcon': fileIcon });
        this.documentIds.push(element.documentId);
      });
      if (this.isMultipleFiles == false) {
        this.multipleFiles = [];
        this.multipleFiles = this.selectedRecords;
      } else {
        var uplodMultipalFiles = this.multipleFiles;
        this.selectedRecords.forEach(ele => {
          if (this.multipleFiles.find(temp => temp.documentId == ele.documentId) == null) {
            uplodMultipalFiles.push(ele);
          }
        });
        this.multipleFiles = uplodMultipalFiles;
      }
      if (this.multipleFiles.length > 0) {
        this.isUploaded = true;
      } else {
        this.isUploaded = false;
      }
      this.isSystemDocumentUpload = false;
    }
    
    this.dispatchEvent(
      new CustomEvent("fileuploaded", {
        detail: {
          documentId: this.documentIds
        }
      })
    );
  }


  handleRemove(event) {
    this.selectedFileValue = event.target.dataset.documentid;
    this.selectedFileName = event.target.dataset.documentname;
    this.selectedFileType = event.target.dataset.documentfiletype;
    this.selectedFileExtension = event.target.dataset.fileextension;
    if (this.previousFiles.includes(this.selectedFileValue)) {
      console.log('this.selectedFileValue.... in if...::>>'+ JSON.stringify(this.selectedFileValue));
      this.removeFiles();
      var obj = {};
      obj["Id"] = this.selectedFileValue;
      obj["Title"] = this.selectedFileName;
      obj["FileType"] = this.selectedFileType;
      obj["FileExtension"] = this.selectedFileExtension;
      this.contentDocumentData.push(obj);
    } else {
      console.log('this.selectedFileValue.... in else...::>>'+ JSON.stringify(this.selectedFileValue));
      let deleteSelectedFiles = [this.selectedFileValue];
              if (this.isEditMode == true) {
                    this.removeFiles();
                    if (!this.previousContentDocuments.includes(this.selectedFileValue) && !this.contentDocumentIds.includes(this.selectedFileValue)) {
                        this.deleteFilesUploaded.push(this.selectedFileValue);
                    }
              } else {
                      this.removeFiles();
                      removeDocument({ docIds: deleteSelectedFiles })
                        .then(() => {
                          this.removeFiles();
                        })
                        .catch((error) => {
                          showToast(
                            this,
                            this.labels.ticketUploadRemoveErrorTitle,
                            this.labels.ticketUploadRemoveErrorText,
                            "ERROR"
                          );
                        });
              }
      }
  }

  removeFiles() {
    let deleteFiles = this.multipleFiles;
    for (var i = 0; i < this.multipleFiles.length; i++) {
      if (deleteFiles[i].documentId === this.selectedFileValue) {
        deleteFiles.splice(i, 1);
        this.multipleFiles = [];
        this.documentIds.splice(i, 1);
        this.multipleFiles = deleteFiles;
      }
    }
    if (this.multipleFiles.length == 0) {
      this.isUploaded = false;
    }

    if (this.isMultipleFiles == false) {
      this.isMultipleUploaded = true;
    }
    if (this.documentIds.length > 0) {
      this.dispatchEvent(
        new CustomEvent("fileuploaded", {
          detail: {
            documentId: this.documentIds
          }
        })
      );
    } else {
      this.dispatchEvent(
        new CustomEvent("fileremoved")
      );
    }
    console.log('this.multipalFiles......'+ this.multipleFiles.length);
  }

  @api
  requiredFieldUploadedCheck() {
    let res = true;
    if (this.multipleFiles.length == 0 && this.isrequired) {
      res = false;
    }
    return res;
  }

  @api
  deleteFiles() {
    if (!isBlank(this.deleteFilesUploaded)) {
      removeDocument({ docIds: this.deleteFilesUploaded })
        .then(() => {

        });
    }
  }
}