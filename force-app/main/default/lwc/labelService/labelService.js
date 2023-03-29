/**
 * To use in your component:
 *
 * yourComponent.js:
 * import labels from {c/labelService}
 *
 * export default class YourComponent extends LightningElement {
 *     label = labels;
 *
 *     console.log(this.label.adminAuthenticated);
 * }
 *
 * yourComponent.html:
 * <button label={label.adminAuthenticated} />
 *
 * WATCH OUT: If you are updating this service AND CustomLabels.labels-meta.xml in the same SFDX transaction, IT WILL FAIL.
 * The Custom Labels must exist BEFORE the LWC transaction takes place, or the entire push will fail.
 * To combat this, run this first:
 *     sfdx force:source:deploy -p force-app/main/default/labels/CustomLabels.labels-meta.xml
 * THEN:
 *     sfdx force:source:push
 */

// Authentication Messaging
import adminAuthenticated from "@salesforce/label/c.Admin_Authenticated";
import adminNotAuthenticated from "@salesforce/label/c.Admin_NotAuthenticated";
import adminNotAuthenticatedInstructions from "@salesforce/label/c.Admin_NotAuthenticatedInstructions";
import adminYouAreAuthenticated from "@salesforce/label/c.Admin_YouAreAuthenticated";
import adminYouAreNotAuthenticated from "@salesforce/label/c.Admin_YouAreNotAuthenticated";

// Admin Authentication
import adminCheckValidation from "@salesforce/label/c.Admin_CheckValidation";
import adminAuthFirstStepTitle from "@salesforce/label/c.Admin_AuthFirstStepTitle";
import adminAuthSecondStepTitle from "@salesforce/label/c.Admin_AuthSecondStepTitle";
import adminAuthFirstStepActionTitle from "@salesforce/label/c.Admin_AuthFirstStepActionTitle";
import adminAuthSecondStepActionTitle from "@salesforce/label/c.Admin_AuthSecondStepActionTitle";
import adminAuthFirstStepImageTitle from "@salesforce/label/c.Admin_AuthFirstStepImageTitle";
import adminAuthSecondStepImageTitle from "@salesforce/label/c.Admin_AuthSecondStepImageTitle";
import adminSuccessfulPull from "@salesforce/label/c.Admin_SuccessfulPull";
import adminAuthenticationBody from "@salesforce/label/c.Admin_AuthenticationBody";

// Sync Critieria and Fields
import adminPullFromEvisort from "@salesforce/label/c.Admin_PullFromEvisort";
import adminSaveAndApply from "@salesforce/label/c.Admin_SaveAndApply";
import adminAddObject from "@salesforce/label/c.Admin_AddObject";
import adminSyncObjectsAndRecordTypes from "@salesforce/label/c.Admin_SyncObjectsAndRecordTypes";
import adminSyncValidFileTypes from "@salesforce/label/c.Admin_SyncValidFileTypes";
import adminFileTypes from "@salesforce/label/c.Admin_FileTypes";
import adminObjectSearchPlaceholder from "@salesforce/label/c.Admin_ObjectSearchPlaceholder";
import adminRecordTypeSearchPlaceholder from "@salesforce/label/c.Admin_RecordTypeSearchPlaceholder";
import adminObjectAndRecordTypeSearchCriteria from "@salesforce/label/c.Admin_ObjectAndRecordTypeSearchCriteria";
import adminSave from "@salesforce/label/c.Admin_Save";
import adminDelete from "@salesforce/label/c.Admin_Delete";
import adminRecordType from "@salesforce/label/c.Admin_RecordType";
import adminObject from "@salesforce/label/c.Admin_Object";
import adminPdfFileType from "@salesforce/label/c.Admin_PdfFileType";
import adminWordDocFileType from "@salesforce/label/c.Admin_WordDocFileType";
import adminLearnMore from "@salesforce/label/c.Admin_LearnMore";
import adminClickHere from "@salesforce/label/c.Admin_ClickHere";
import adminHere from "@salesforce/label/c.Admin_Here";
import adminNewProvisionstoActive from "@salesforce/label/c.Admin_NewProvisionstoActive";
import adminSuccess from "@salesforce/label/c.Admin_Success";
import adminError from "@salesforce/label/c.Admin_Error";
import adminProvisionsUpdated from "@salesforce/label/c.Admin_ProvisionsUpdated";
import adminApiVersion from "@salesforce/label/c.Admin_ApiVersion";
import adminLastFieldPulled from "@salesforce/label/c.Admin_LastFieldPulled";
import adminLastDocSync from "@salesforce/label/c.Admin_LastDocSync";
import adminFieldsUpdated from "@salesforce/label/c.Admin_FieldsUpdated";
import adminEvisortApiVersionHelptext from "@salesforce/label/c.Admin_EvisortApiVersionHelptext";
import adminEvisortLastPullDateHelptext from "@salesforce/label/c.Admin_EvisortLastPullDateHelptext";
import adminEvisortLastDocSyncHelptext from "@salesforce/label/c.Admin_EvisortLastDocSyncHelptext";
import adminRootFolder from "@salesforce/label/c.Admin_RootFolder";
import adminGlobalSettings from "@salesforce/label/c.Admin_GlobalSettings";
import adminAllValidFileTypes from "@salesforce/label/c.Admin_AllValidFileTypes";
import adminSyncCriteriaRootFolderVerbiage from "@salesforce/label/c.Admin_SyncCriteriaRootFolderVerbiage";
import adminAdminGuide from "@salesforce/label/c.Admin_AdminGuide";
import adminSyncCriteriaGlobalSettingsVerbiage from "@salesforce/label/c.Admin_SyncCriteriaGlobalSettingsVerbiage";
import adminSyncCriteriaBody from "@salesforce/label/c.Admin_SyncCriteriaBody";
import adminSyncCriteriaGlobalSettingsActive from "@salesforce/label/c.Admin_SyncCriteriaGlobalSettingActive";
import adminSyncCriteriaObjectSettingsDefault from "@salesforce/label/c.Admin_SyncCriteriaObjectSettingsDefault";
import AdminSyncCriteriaLibrarySettingsDefault from "@salesforce/label/c.Admin_SyncCriteriaLibrarySettingsDefault";
import adminAllRecordTypes from "@salesforce/label/c.Admin_AllRecordTypes";
import adminNoRecordTypesExist from "@salesforce/label/c.Admin_NoRecordTypesExist";
import adminSyncFieldsBody from "@salesforce/label/c.Admin_SyncFieldsBody";
import adminSyncProvisionsBody from "@salesforce/label/c.Admin_SyncProvisionsBody";
import adminUnknownError from "@salesforce/label/c.Admin_UnknownError";
import AdminEvisortSyncFieldNull from "@salesforce/label/c.Admin_EvisortSyncFieldNull";

// Other Options
import adminOtherOptionsNotificationsHeader from "@salesforce/label/c.Admin_OtherOptionsNotificationsHeader";
import adminOtherOptionsNotificationsAction from "@salesforce/label/c.Admin_OtherOptionsNotificationsAction";
import adminOtherOptionsAssignHeader from "@salesforce/label/c.Admin_OtherOptionsAssignHeader";
import adminOtherOptionsAssignAction from "@salesforce/label/c.Admin_OtherOptionsAssignAction";
import adminOtherOptionsAdminSetupGuideHeader from "@salesforce/label/c.Admin_OtherOptionsAdminSetupGuideHeader";
import adminOtherOptionsAdminSetupGuideAction from "@salesforce/label/c.Admin_OtherOptionsAdminSetupGuideAction";
import adminOtherOptionsReportsAndAnalyticsHeader from "@salesforce/label/c.Admin_OtherOptionsReportsAndAnalyticsHeader";
import adminOtherOptionsReportsAndAnalyticsAction from "@salesforce/label/c.Admin_OtherOptionsReportsAndAnalyticsAction";
import adminOtherOptionsBody from "@salesforce/label/c.Admin_OtherOptionsBody";
import adminAdminGuideBody from "@salesforce/label/c.Admin_AdminGuideBody";
import adminAssignUsersBody from "@salesforce/label/c.Admin_AssignUsersBody";
import adminReportsBody from "@salesforce/label/c.Admin_ReportsBody";
import adminNotificationsBody from "@salesforce/label/c.Admin_NotificationsBody";
import adminConfirm from "@salesforce/label/c.Admin_Confirm";

// Legacy Files Export
import adminLegacyFilesExportBody from "@salesforce/label/c.Admin_LegacyFilesExportBody";
import adminAddToExport from "@salesforce/label/c.Admin_AddToExport";
import adminStartMassExport from "@salesforce/label/c.Admin_StartMassExport";
import adminRefresh from "@salesforce/label/c.Admin_Refresh";
import adminCancel from "@salesforce/label/c.Admin_Cancel";
import adminStatus from "@salesforce/label/c.Admin_Status";
import adminOverallStatus from "@salesforce/label/c.Admin_OverallStatus";
import adminDocuments from "@salesforce/label/c.Admin_Documents";
import adminCompleted from "@salesforce/label/c.Admin_Completed";
import adminOversized from "@salesforce/label/c.Admin_Oversized";
import adminErrored from "@salesforce/label/c.Admin_Errored";
import adminSizeOfFiles from "@salesforce/label/c.Admin_SizeOfFiles";
import adminRemaining from "@salesforce/label/c.Admin_Remaining";
import adminEstimatedTime from "@salesforce/label/c.Admin_EstimatedTime";
import adminObjectSettings from "@salesforce/label/c.Admin_ObjectSettings";
import adminReset from "@salesforce/label/c.Admin_Reset";
import adminResetAll from "@salesforce/label/c.Admin_ResetAll";
import AdminAssignToMe from "@salesforce/label/c.Admin_Assign_to_me";
import adminCalculationStarted from "@salesforce/label/c.Admin_CalculationStarted";
import adminClickRefresh from "@salesforce/label/c.Admin_ClickRefresh";
import adminExportInProgress from "@salesforce/label/c.Admin_ExportInProgress";
import adminCancelInProgress from "@salesforce/label/c.Admin_CancelInProgress";
import adminObjectFilter from "@salesforce/label/c.Admin_ObjectFilter";
import adminFileFilter from "@salesforce/label/c.Admin_FileFilter";
import adminAddCondition from '@salesforce/label/c.Admin_AddCondition';
import adminLibrarySectionOnObjectFilter from '@salesforce/label/c.Admin_LibrarySectionOnObjectFilter';
import adminAssociatedSectionOnObjectFilter from '@salesforce/label/c.Admin_AssociatedSectionOnObjectFilter';
import adminReassign from "@salesforce/label/c.Admin_Re_assign";
import noUserFound from "@salesforce/label/c.No_User_Found"
import adminAssign from "@salesforce/label/c.Admin_Assign"

// Map Intake Forms
import adminMapIntakeFormsTitle from "@salesforce/label/c.Admin_MapIntakeFormsTitle";
import adminMapIntakeFormsBody from "@salesforce/label/c.Admin_MapIntakeFormsBody";
import adminMapIntakeFormsEdit from "@salesforce/label/c.Admin_MapIntakeFormsEdit";
import adminMapIntakeFormsNew from "@salesforce/label/c.Admin_MapIntakeFormsNew";
import adminMapIntakeFormsWarning from "@salesforce/label/c.Admin_MapIntakeFormsWarning";
import adminMapIntakeFormsClear from "@salesforce/label/c.Admin_MapIntakeFormsClear";
import adminMapIntakeFormsRelationship from "@salesforce/label/c.Admin_MapIntakeFormsRelationship";
import adminMapIntakeFormsChildRelationship from "@salesforce/label/c.Admin_MapIntakeFormsChildRelationship";
import adminMapIntakeFormsDeleteTitle from "@salesforce/label/c.Admin_MapIntakeFormsDeleteTitle";
import adminMapIntakeFormsDeleteBody from "@salesforce/label/c.Admin_MapIntakeFormsDeleteBody";
import adminMapIntakeFormsDeleteSuccess from "@salesforce/label/c.Admin_MapIntakeFormsDeleteSuccess";
import adminMapIntakeFormsDeleteError from "@salesforce/label/c.Admin_MapIntakeFormsDeleteError";
import adminMapIntakeFormsSaveSuccess from "@salesforce/label/c.Admin_MapIntakeFormsSaveSuccess";
import adminMapIntakeFormsSaveError from "@salesforce/label/c.Admin_MapIntakeFormsSaveError";
import adminMapIntakeFormsFieldError from "@salesforce/label/c.Admin_MapIntakeFormsFieldEror";
import adminMapIntakeFormsPostError from "@salesforce/label/c.Admin_MapIntakeFormsPostError";
import adminMapIntakeFormsWorkflow from "@salesforce/label/c.Admin_MapIntakeFormsWorkflow";
import adminMapIntakeFormsSalesforceObject from "@salesforce/label/c.Admin_MapIntakeFormsSalesforceObject";
import adminMapIntakeFormsWorkflowFields from "@salesforce/label/c.Admin_MapIntakeFormsWorkflowFields";
import adminMapIntakeFormsMappedObjectFields from "@salesforce/label/c.Admin_MapIntakeFormsMappedObjectFields";
import adminMapIntakeFormsHelptip from "@salesforce/label/c.Admin_MapIntakeFormsHelptip";
import adminLaunchIntakeFormsHeader from "@salesforce/label/c.Admin_LaunchIntakeFormsHeader";
import adminLaunchIntakeFormsInfo from "@salesforce/label/c.Admin_LaunchIntakeFormsInfo";
import adminLaunchIntakeFormsMultiple from "@salesforce/label/c.Admin_LaunchIntakeFormsMultiple";
import adminLaunchIntakeFormsSubmit from "@salesforce/label/c.Admin_LaunchIntakeFormsSubmit";
import adminLaunchIntakeFormsNoWorkspaceError from "@salesforce/label/c.Admin_LaunchIntakeFormsNoWorkspaceError";
import adminLaunchIntakeFormsNoOptionsError from "@salesforce/label/c.Admin_LaunchIntakeFormsNoOptionsError";
import adminClose from "@salesforce/label/c.Admin_Close";
import adminChangeDisplaySettings from "@salesforce/label/c.Admin_ChangeDisplaySettings";
import adminChangeDisplaySettingsLink from "@salesforce/label/c.Admin_ChangeDisplaySettingsLink";
import adminDisplaySettings from "@salesforce/label/c.Admin_Display_Settings";
import adminDisplaySettingsTitle from "@salesforce/label/c.Admin_Display_Settings_Title";
import adminDisplaySettingsError from "@salesforce/label/c.Admin_Display_Settings_Error";
import adminDisplaySettingsAll from "@salesforce/label/c.Admin_Display_Settings_All";
import adminDisplaySettingsMapped from "@salesforce/label/c.Admin_Display_Settings_Mapped";
import adminMappingVisibilityChangeMessage from "@salesforce/label/c.Admin_MappingVisibilityChangeMessage";


//  Filters 
import AdminFilterOperatorEqual from "@salesforce/label/c.Admin_FilterOperatorEqual";
import AdminFilterOperatorNotEqualsTo from "@salesforce/label/c.Admin_FilterOperatorNotEqualsTo";
import AdminFilterOperatorStartWith from "@salesforce/label/c.Admin_FilterOperatorStartWith";
import AdminFilterOperatorEndWith from "@salesforce/label/c.Admin_FilterOperatorEndWith";
import AdminFilterOperatorContains from "@salesforce/label/c.Admin_FilterOperatorContains";
import AdminFilterOperatorNotContains from "@salesforce/label/c.Admin_FilterOperatorNotContains";
import AdminFilterOperatorAnd from "@salesforce/label/c.Admin_FilterOperatorAnd";
import AdminFilterOperatorOr from "@salesforce/label/c.Admin_FilterOperatorOr";
import AdminFilterOperatorNone from "@salesforce/label/c.Admin_FilterOperatorNone";
import AdminFilterOperatorTrue from "@salesforce/label/c.Admin_FilterOperatorTrue";
import AdminFilterOperatorFalse from "@salesforce/label/c.Admin_FilterOperatorFalse";
import AdminFilterOperatorIn from "@salesforce/label/c.Admin_FilterOperatorIn";
import AdminFilterOperatorLessThan from "@salesforce/label/c.Admin_FilterOperatorLessThan";
import AdminFilterOperatorGreaterThan from "@salesforce/label/c.Admin_FilterOperatorGreaterThan";
import AdminFilterOperatorLessThanEqualsTo from "@salesforce/label/c.Admin_FilterOperatorLessThanEqualsTo";
import AdminFilterOperatorGreaterThanEqualsTo from "@salesforce/label/c.Admin_FilterOperatorGreaterThanEqualsTo";
import AdminFilterFields from "@salesforce/label/c.Admin_FilterFields";
import AdminFilterOperator from "@salesforce/label/c.Admin_FilterOperator";
import AdminFilterSelectField from "@salesforce/label/c.Admin_FilterSelectField";
import AdminFilterSelectOption from "@salesforce/label/c.Admin_FilterSelect";
import AdminFilterFieldType from "@salesforce/label/c.Admin_FilterFieldType";
import AdminFilterValue from "@salesforce/label/c.Admin_FilterValue";
import AdminFilterAllConditionAreMet from "@salesforce/label/c.Admin_FilterAllConditionAreMet";
import AdminFilterAnyConditionAreMet from "@salesforce/label/c.Admin_FilterAnyConditonAreMet";
import AdminFilterEnterDate from "@salesforce/label/c.Admin_FilterEnterDate";
import AdminFilterEnterSelectvalue from "@salesforce/label/c.Admin_FilterEnterSelectvalue";
import AdminFilterEnterNumber from "@salesforce/label/c.Admin_FilterEnterNumber";
import AdminFilterEnterSometext from "@salesforce/label/c.Admin_FilterEnterSometext";
import AdminFilterRecordTypeValue from "@salesforce/label/c.Admin_FilterRecordTypeValue";
import AdminFilterEnterValue from "@salesforce/label/c.Admin_FilterEnterValue";
import AdminFilterSelectLibrary from "@salesforce/label/c.Admin_FilterSelectLibrary";
import AdminDocumentfieldmappinghasbeensaved from "@salesforce/label/c.Admin_Document_field_mapping_has_been_saved";
import adminUpload from "@salesforce/label/c.Admin_Upload";

//Document Field Mapping
import AdminMapobjectfieldswithEvisort from "@salesforce/label/c.Admin_MapobjectfieldswithEvisort";
import AdminNoEvisortFields from "@salesforce/label/c.Admin_NoEvisortFields";

// Ticket Intake Form
import ticketNewIntakeFormHeader from "@salesforce/label/c.Ticket_NewIntakeFormHeader";
import ticketNewIntakeFormHeaderWithName from "@salesforce/label/c.Ticket_NewIntakeFormHeaderWithName";
import ticketNewIntakeFormCancel from "@salesforce/label/c.Ticket_NewIntakeFormCancel";
import ticketNewIntakeFormNext from "@salesforce/label/c.Ticket_NewIntakeFormNext";
import ticketNewIntakeFormSave from "@salesforce/label/c.Ticket_NewIntakeFormSave";
import ticketCreateIntakeFormSuccessTitle from "@salesforce/label/c.Ticket_CreateIntakeFormSuccessTitle";
import ticketCreateIntakeFormSuccessMsg from "@salesforce/label/c.Ticket_CreateIntakeFormSuccessMsg";
import ticketNoSearchResults from "@salesforce/label/c.Ticket_NoSearchResults";
import ticketNoAvailableWorkflows from "@salesforce/label/c.Ticket_NoAvailableWorkflows";
import ticketSearchIntakeFormPlaceholder from "@salesforce/label/c.Ticket_SearchIntakeFormPlaceholder";
import ticketDocumentSelectionLabel from "@salesforce/label/c.Ticket_DocumentSelectionLabel";
import ticketIntakeFormDocumentHeader from "@salesforce/label/c.Ticket_IntakeFormDocumentHeader";
import ticketIntakeFormObjectLookupLabel from "@salesforce/label/c.Ticket_IntakeFormObjectLookupLabel";
import ticketIntakeFormAcceptedDocs from "@salesforce/label/c.Ticket_IntakeFormAcceptedDocs";
import ticketTemplateOptionLabel from "@salesforce/label/c.Ticket_TemplateOptionLabel";
import ticketCounterpartyOptionLabel from "@salesforce/label/c.Ticket_CounterpartyOptionLabel";
import ticketUploadLabel from "@salesforce/label/c.Ticket_UploadLabel";
import ticketUploadRemoveLabel from "@salesforce/label/c.Ticket_UploadRemoveLabel";
import ticketUploadRemoveTitle from "@salesforce/label/c.Ticket_UploadRemoveTitle";
import ticketUploadRemoveErrorTitle from "@salesforce/label/c.Ticket_UploadDocumentRemoveErrorTitle";
import ticketUploadRemoveErrorText from "@salesforce/label/c.Ticket_UploadDocumentRemoveErrorText";
import ticketCreationSuccessTitle from "@salesforce/label/c.Ticket_CreationSuccessTitle";
import ticketCreationSuccessText from "@salesforce/label/c.Ticket_CreationSuccessText";
import ticketCreationErrorTitle from "@salesforce/label/c.Ticket_CreationErrorTitle";
import ticketIntakeFormAttachementError from "@salesforce/label/c.Ticket_IntakeFormAttachementError";
import ticketRequiredFieldsMissing from "@salesforce/label/c.Ticket_RequiredFieldsMissing";
import ticketChildRecordsSelectionHeader from "@salesforce/label/c.Ticket_ChildRecordsSelectionHeader";
import ticketMappedFieldsForRecord from "@salesforce/label/c.Ticket_MappedFieldsForRecord";
import ticketMappedFieldsWithExcess from "@salesforce/label/c.Ticket_MappedFieldsWithExcess";
import ticketChildSelectionError from "@salesforce/label/c.Ticket_ChildSelectionError";
import ticketapprove from "@salesforce/label/c.Admin_Approve";
import ticketReject from "@salesforce/label/c.Admin_Reject";
import ticketRejectTicketStatus from "@salesforce/label/c.Admin_Reject_Ticket_Status";
import ticketAdmin_Rejected from "@salesforce/label/c.Admin_Rejected";
import ticketCommentOutliningOnReject from "@salesforce/label/c.Admin_Comment_outlining_on_reject";
import ticketResetTicketStatus from "@salesforce/label/c.Admin_Reset_Ticket_Status";
import ticketCommentOutliningOnReset from "@salesforce/label/c.Admin_Comment_outlining_on_reset";
import ticketUploadSignedDocument from "@salesforce/label/c.Ticket_upload_sign_document";
import ticketSignedUploadUserCheckBox from "@salesforce/label/c.Ticket_signed_checkbox";
import ticketSigner from "@salesforce/label/c.Ticket_Signer";
import ticketAttachFile from "@salesforce/label/c.Ticket_Attach_File";
import ticketRemoveFile from "@salesforce/label/c.Ticket_Remove_File";
import ticketUploadSigned from "@salesforce/label/c.Ticket_Upload_Signed";
import ticketNewDocumentUploaded from "@salesforce/label/c.Ticket_NewDocumentUploaded";
import ticketSignedUploadSuccessfully from "@salesforce/label/c.Ticket_SignedUploadSuccessfully";
import ticketShareDocument from "@salesforce/label/c.Ticket_Share_Document";
import ticketToRecipients from "@salesforce/label/c.Ticket_To_Recipients";
import ticketShareSubject from "@salesforce/label/c.Ticket_Share_Subject";
import ticketShareMessage from "@salesforce/label/c.Ticket_Share_Message";
import ticketShareAttachments from "@salesforce/label/c.Ticket_Share_Attachments";
import ticketShare from "@salesforce/label/c.Ticket_Share";
import ticketShareEmailError from "@salesforce/label/c.Ticket_Share_Email_Error";
import ticketShareEmailSuccess from "@salesforce/label/c.Ticket_Share_Email_Success";
import ticketGoToEvisortRecord from "@salesforce/label/c.Ticket_GoToEvisortRecord";
import ticketExistingSFDCDocuments from "@salesforce/label/c.Existing_SFDC_Documents";
import ticketExistingSFDCDocument from "@salesforce/label/c.Existing_SFDC_Document";



// Tab Titles and Headers
import adminAuthenticationTab from "@salesforce/label/c.Admin_AuthenticationTab";
import adminOtherOptionsTab from "@salesforce/label/c.Admin_OtherOptionsTab";
import adminSyncCriteriaTab from "@salesforce/label/c.Admin_SyncCriteriaTab";
import adminSyncCriteriaHeader from "@salesforce/label/c.Admin_SyncCriteriaHeader";
import adminSyncFieldsTab from "@salesforce/label/c.Admin_SyncFieldsTab";
import adminEvisortIconAltText from "@salesforce/label/c.Admin_EvisortIconAltText";
import adminEvisortDocumentation from "@salesforce/label/c.Admin_EvisortDocumentation";
import adminEvisortConfig from "@salesforce/label/c.Admin_EvisortConfig";
import adminEvisortFields from "@salesforce/label/c.Admin_EvisortFields";
import adminSyncProvisionsTab from "@salesforce/label/c.Admin_SyncProvisionsTab";
import adminLegacyFilesExportTab from "@salesforce/label/c.Admin_LegacyFilesExportTab";
import adminMapIntakeFormsTab from "@salesforce/label/c.Admin_MapIntakeFormsTab";
import adminSyncObjectMappingTab from "@salesforce/label/c.Admin_SyncObjectMappingTab";
import adminSyncObjectMappingBody from "@salesforce/label/c.Admin_SyncObjectMappingBody";
import adminSetObjectMapping from "@salesforce/label/c.Admin_SetObjectMapping";
import adminMetadataObjectfieldsSyncedDeleteBody from "@salesforce/label/c.Admin_MetadataObjectfieldsSyncedDeleteBody";
import adminLoading from "@salesforce/label/c.Admin_Loading";
import adminRemoveSelectedOption from "@salesforce/label/c.Admin_RemoveSelectedOption";
import adminMappinghasbeensuccessfullydeleted from "@salesforce/label/c.Admin_Mappinghasbeensuccessfullydeleted";
import adminDocumentmappinghasbeensaved from "@salesforce/label/c.Admin_Documentmappinghasbeensaved";

// Related List Component
import relatedListEmpty from "@salesforce/label/c.RelatedList_Empty";
import ticketRelatedListEmpty from "@salesforce/label/c.Ticket_RelatedListEmpty";
import ticketGetRelatedTicketsError from "@salesforce/label/c.Ticket_GetRelatedTicketsError";
import ticketRelatedListHeader from "@salesforce/label/c.Ticket_RelatedListHeader";
import ticketAllRelatedListHeader from "@salesforce/label/c.Ticket_AllRelatedListHeader";
import ticketRelatedListViewAll from "@salesforce/label/c.Ticket_RelatedListViewAll";
import ticketNameColumnHeader from "@salesforce/label/c.Ticket_NameColumnHeader";
import ticketSubByColumnHeader from "@salesforce/label/c.Ticket_SubByColumnHeader";
import ticketSubOnColumnHeader from "@salesforce/label/c.Ticket_SubOnColumnHeader";
import ticketLastModColumnHeader from "@salesforce/label/c.Ticket_LastModColumnHeader";
import ticketAssignedColumnHeader from "@salesforce/label/c.Ticket_AssignedColumnHeader";
import ticketStatusColumnHeader from "@salesforce/label/c.Ticket_StatusColumnHeader";
import ticketStageLabel from "@salesforce/label/c.Ticket_Stage";
import ticketEvisortIdLabel from "@salesforce/label/c.Ticket_EvisortId";

// Ticket Information Modal
import ticketTabWorkflow from "@salesforce/label/c.Ticket_WorkflowTab";
import ticketTabFormInfo from "@salesforce/label/c.Ticket_FormInfoTab";
import ticketTabActivity from "@salesforce/label/c.Ticket_ActivityLogTab";
import ticketTabContributors from "@salesforce/label/c.Ticket_ContributorsTab";
import ticketPendingReviews from "@salesforce/label/c.Ticket_PendingReviews";
import ticketPendingReview from "@salesforce/label/c.Ticket_PendingReview";
import ticketModalClose from "@salesforce/label/c.Ticket_ModalClose";
import ticketNextStageBtn from "@salesforce/label/c.Ticket_NextStageBtn";
import ticketViewTicketBtnText from "@salesforce/label/c.Ticket_ViewTicketBtnText";
import ticketWorkflowDocumentHeader from "@salesforce/label/c.Ticket_WorkflowDocumentHeader";
import ticketWorkflowPreviewText from "@salesforce/label/c.Ticket_WorkflowPreviewText";
import ticketWorkflowDownloadText from "@salesforce/label/c.Ticket_WorkflowDownloadText";
import ticketWorkflowReviewHeader from "@salesforce/label/c.Ticket_WorkflowReviewHeader";
import ticketWorkflowCoordinatorHeader from "@salesforce/label/c.Ticket_WorkflowCoordinatorHeader";
import ticketAssigneesHeader from "@salesforce/label/c.Ticket_AssigneesHeader";
import ticketParticipantsHeader from "@salesforce/label/c.Ticket_ParticipantsHeader";
import ticketNoContributorData from "@salesforce/label/c.Ticket_NoContributorData";
import ticketMarkCompletedBtn from "@salesforce/label/c.Ticket_MarkCompletedBtn";
import ticketMarkCompletedModal from "@salesforce/label/c.Ticket_MarkCompletedModal";
import ticketSubmitNextStageModal from "@salesforce/label/c.Ticket_SubmitNextStageModal";
import ticketTicketCompletedBtn from "@salesforce/label/c.Ticket_TicketCompletedBtn";
import ticketPendingTask from "@salesforce/label/c.Ticket_PendingTask";
import ticketConfirmationModalSubmit from "@salesforce/label/c.Ticket_ConfirmationModalSubmit";
import ticketConfirmationModalBack from "@salesforce/label/c.Ticket_ConfirmationModalBack";
import ticketModalIsSubmitting from "@salesforce/label/c.Ticket_ModalIsSubmitting";
import ticketModalSubmitStageSuccess from "@salesforce/label/c.Ticket_ModalSubmitStageSuccess";
import ticketModalSubmitCompletedSuccess from "@salesforce/label/c.Ticket_ModalSubmitCompletedSuccess";

// Ticket Information Modal - Editing
import ticketModalUnsavedEdits from "@salesforce/label/c.Ticket_ModalUnsavedEdits";
import ticketModalUnsavedEditsHeader from "@salesforce/label/c.Ticket_ModalUnsavedEditsHeader";
import ticketModalSavedSuccessfully from "@salesforce/label/c.Ticket_ModalSavedSuccessfully";
import ticketModalCancelEditBtnLabel from "@salesforce/label/c.Ticket_ModalCancelEditBtnLabel";
import ticketModalSaveEditBtnLabel from "@salesforce/label/c.Ticket_ModalSaveEditBtnLabel";
import ticketModalUnsuccessfulEditHeader from "@salesforce/label/c.Ticket_ModalUnsuccessfulEditHeader";
import ticketFieldMappingSingleLabel from "@salesforce/label/c.Ticket_FieldMappingSingleLabel";
import ticketFieldMappingMultiLabel from "@salesforce/label/c.Ticket_FieldMappingMultiLabel";
import ticketFieldMappingCheckboxLabel from "@salesforce/label/c.Ticket_FieldMappingCheckboxLabel";
import ticketUploadNewVersion from "@salesforce/label/c.ticket_UploadNewVersion";
import ticketMarkAsCounterpartyDocument from "@salesforce/label/c.ticket_MarkAsCounterpartyDocument";
import ticketNotes from "@salesforce/label/c.ticket_Notes";
import ticketNewVersionDocument from "@salesforce/label/c.ticket_NewVersion";

//  Intake Form
import IntakeFormSearch from "@salesforce/label/c.Intake_Form_Search";
import IntakeFormNoMatchFound from "@salesforce/label/c.Intake_Form_No_match_found";

//Evisort PostInstallation
import adminDocumentSyncJob from "@salesforce/label/c.Admin_DocumentSyncJob";
import adminMetaDataSyncJob from "@salesforce/label/c.Admin_MetaDataSyncJob";
import adminExportLegacyLeanupJob from "@salesforce/label/c.Admin_ExportLegacyLeanupJob";

const labels = {
    formatLabel: function (label, args) {
        return label.replace(/{(\d+)}/gm, (match, index) => {
            return args[index] === undefined ? "" : `${args[index]}`;
        });
    },

    adminAuthenticated,
    adminNotAuthenticated,
    adminYouAreAuthenticated,
    adminYouAreNotAuthenticated,
    adminAuthenticationTab,
    adminOtherOptionsTab,
    adminSyncCriteriaTab,
    adminSyncFieldsTab,
    adminCheckValidation,
    adminAuthFirstStepTitle,
    adminAuthSecondStepTitle,
    adminAuthFirstStepActionTitle,
    adminAuthSecondStepActionTitle,
    adminAuthFirstStepImageTitle,
    adminAuthSecondStepImageTitle,
    adminSyncCriteriaHeader,
    adminEvisortIconAltText,
    adminNotAuthenticatedInstructions,
    adminSaveAndApply,
    adminPullFromEvisort,
    adminAddObject,
    adminSyncObjectsAndRecordTypes,
    adminSyncValidFileTypes,
    adminFileTypes,
    adminObject,
    adminObjectSearchPlaceholder,
    adminRecordTypeSearchPlaceholder,
    adminRecordType,
    adminSave,
    adminDelete,
    adminObjectAndRecordTypeSearchCriteria,
    adminPdfFileType,
    adminWordDocFileType,
    adminLearnMore,
    adminClickHere,
    adminHere,
    adminOtherOptionsNotificationsHeader,
    adminOtherOptionsNotificationsAction,
    adminOtherOptionsAssignHeader,
    adminOtherOptionsAssignAction,
    adminEvisortDocumentation,
    adminEvisortConfig,
    adminEvisortFields,
    adminOtherOptionsAdminSetupGuideHeader,
    adminOtherOptionsAdminSetupGuideAction,
    adminOtherOptionsReportsAndAnalyticsHeader,
    adminOtherOptionsReportsAndAnalyticsAction,
    adminSyncProvisionsTab,
    adminNewProvisionstoActive,
    adminSuccess,
    adminError,
    adminProvisionsUpdated,
    adminApiVersion,
    adminLastFieldPulled,
    adminLastDocSync,
    adminSuccessfulPull,
    adminFieldsUpdated,
    adminEvisortApiVersionHelptext,
    adminEvisortLastPullDateHelptext,
    adminEvisortLastDocSyncHelptext,
    adminRootFolder,
    adminGlobalSettings,
    adminAllValidFileTypes,
    adminSyncCriteriaRootFolderVerbiage,
    adminAdminGuide,
    adminSyncCriteriaGlobalSettingsVerbiage,
    adminSyncCriteriaBody,
    adminSyncCriteriaGlobalSettingsActive,
    adminSyncCriteriaObjectSettingsDefault,
    AdminSyncCriteriaLibrarySettingsDefault,
    relatedListEmpty,
    adminAllRecordTypes,
    adminSyncFieldsBody,
    adminSyncProvisionsBody,
    adminNoRecordTypesExist,
    adminAuthenticationBody,
    adminOtherOptionsBody,
    adminAdminGuideBody,
    adminAssignUsersBody,
    adminReportsBody,
    adminNotificationsBody,
    adminConfirm,
    adminUnknownError,
    adminLegacyFilesExportTab,
    adminLegacyFilesExportBody,
    adminMapIntakeFormsTab,
    adminSyncObjectMappingTab,
    adminSyncObjectMappingBody,
    adminMetadataObjectfieldsSyncedDeleteBody,
    adminLoading,
    adminRemoveSelectedOption,
    adminMappinghasbeensuccessfullydeleted,
    adminDocumentmappinghasbeensaved,
    adminSetObjectMapping,
    adminMapIntakeFormsTitle,
    adminMapIntakeFormsBody,
    adminMapIntakeFormsEdit,
    adminMapIntakeFormsNew,
    adminMapIntakeFormsWarning,
    adminMapIntakeFormsClear,
    adminMapIntakeFormsRelationship,
    adminMapIntakeFormsChildRelationship,
    adminMapIntakeFormsDeleteTitle,
    adminMapIntakeFormsDeleteBody,
    adminMapIntakeFormsDeleteSuccess,
    adminMapIntakeFormsDeleteError,
    adminMapIntakeFormsSaveSuccess,
    adminMapIntakeFormsSaveError,
    adminMapIntakeFormsFieldError,
    adminMapIntakeFormsPostError,
    adminMapIntakeFormsWorkflow,
    adminMapIntakeFormsSalesforceObject,
    adminMapIntakeFormsWorkflowFields,
    adminMapIntakeFormsMappedObjectFields,
    adminMapIntakeFormsHelptip,
    adminLaunchIntakeFormsHeader,
    adminLaunchIntakeFormsInfo,
    adminLaunchIntakeFormsMultiple,
    adminLaunchIntakeFormsSubmit,
    adminLaunchIntakeFormsNoWorkspaceError,
    adminLaunchIntakeFormsNoOptionsError,
    adminAddToExport,
    adminStartMassExport,
    adminRefresh,
    adminCancel,
    adminClose,
    adminStatus,
    adminOverallStatus,
    adminDocuments,
    adminCompleted,
    adminOversized,
    adminErrored,
    adminSizeOfFiles,
    adminRemaining,
    adminEstimatedTime,
    adminObjectSettings,
    adminReset,
    adminResetAll,
    AdminAssignToMe,
    adminReassign,
    noUserFound,
    adminAssign,
    adminCalculationStarted,
    adminClickRefresh,
    adminExportInProgress,
    adminCancelInProgress,
    adminChangeDisplaySettings,
    adminChangeDisplaySettingsLink,
    adminDisplaySettings,
    adminDisplaySettingsTitle,
    adminDisplaySettingsError,
    adminDisplaySettingsAll,
    adminDisplaySettingsMapped,
    adminMappingVisibilityChangeMessage,
    adminObjectFilter,
    adminFileFilter,
    AdminFilterOperatorEqual,
    AdminFilterOperatorNotEqualsTo,
    AdminFilterOperatorStartWith,
    AdminFilterOperatorEndWith,
    AdminFilterOperatorContains,
    AdminFilterOperatorNotContains,
    AdminFilterOperatorAnd,
    AdminFilterOperatorOr,
    AdminFilterOperatorNone,
    AdminFilterOperatorTrue,
    AdminFilterOperatorFalse,
    AdminFilterOperatorIn,
    AdminFilterOperatorLessThan,
    AdminFilterOperatorGreaterThan,
    AdminFilterOperatorLessThanEqualsTo,
    AdminFilterOperatorGreaterThanEqualsTo,
    AdminFilterFields,
    AdminFilterOperator,
    AdminFilterSelectField,
    AdminFilterSelectOption,
    AdminFilterFieldType,
    AdminFilterValue,
    AdminFilterAllConditionAreMet,
    AdminFilterAnyConditionAreMet,
    AdminFilterEnterDate,
    AdminFilterEnterSelectvalue,
    AdminFilterEnterNumber,
    AdminFilterEnterSometext,
    AdminFilterRecordTypeValue,
    AdminFilterEnterValue,
    adminAddCondition,
    adminLibrarySectionOnObjectFilter,
    adminAssociatedSectionOnObjectFilter,
    AdminFilterSelectLibrary,
    AdminDocumentfieldmappinghasbeensaved,
    adminUpload,
    AdminMapobjectfieldswithEvisort,
    AdminNoEvisortFields,
    AdminEvisortSyncFieldNull,
    ticketNewIntakeFormHeader,
    ticketNewIntakeFormCancel,
    ticketNewIntakeFormNext,
    ticketNewIntakeFormSave,
    ticketNewIntakeFormHeaderWithName,
    ticketCreateIntakeFormSuccessTitle,
    ticketCreateIntakeFormSuccessMsg,
    ticketNoSearchResults,
    ticketNoAvailableWorkflows,
    ticketSearchIntakeFormPlaceholder,
    ticketDocumentSelectionLabel,
    ticketIntakeFormDocumentHeader,
    ticketIntakeFormObjectLookupLabel,
    ticketIntakeFormAcceptedDocs,
    ticketTemplateOptionLabel,
    ticketCounterpartyOptionLabel,
    ticketChildRecordsSelectionHeader,
    ticketRelatedListEmpty,
    ticketGetRelatedTicketsError,
    ticketAllRelatedListHeader,
    ticketRelatedListHeader,
    ticketRelatedListViewAll,
    ticketNameColumnHeader,
    ticketSubByColumnHeader,
    ticketSubOnColumnHeader,
    ticketLastModColumnHeader,
    ticketAssignedColumnHeader,
    ticketStatusColumnHeader,
    ticketUploadLabel,
    ticketUploadRemoveLabel,
    ticketUploadRemoveTitle,
    ticketUploadRemoveErrorTitle,
    ticketUploadRemoveErrorText,
    ticketCreationSuccessTitle,
    ticketCreationSuccessText,
    ticketCreationErrorTitle,
    ticketIntakeFormAttachementError,
    ticketTabWorkflow,
    ticketTabFormInfo,
    ticketTabActivity,
    ticketTabContributors,
    ticketPendingReviews,
    ticketPendingReview,
    ticketModalClose,
    ticketNextStageBtn,
    ticketViewTicketBtnText,
    ticketWorkflowDocumentHeader,
    ticketWorkflowPreviewText,
    ticketWorkflowDownloadText,
    ticketWorkflowReviewHeader,
    ticketWorkflowCoordinatorHeader,
    ticketAssigneesHeader,
    ticketParticipantsHeader,
    ticketNoContributorData,
    ticketMarkCompletedBtn,
    ticketMarkCompletedModal,
    ticketSubmitNextStageModal,
    ticketTicketCompletedBtn,
    ticketPendingTask,
    ticketConfirmationModalSubmit,
    ticketConfirmationModalBack,
    ticketModalIsSubmitting,
    ticketModalSubmitStageSuccess,
    ticketModalSubmitCompletedSuccess,
    ticketStageLabel,
    ticketEvisortIdLabel,
    ticketModalUnsavedEdits,
    ticketModalUnsavedEditsHeader,
    ticketModalSavedSuccessfully,
    ticketModalCancelEditBtnLabel,
    ticketModalSaveEditBtnLabel,
    ticketModalUnsuccessfulEditHeader,
    ticketFieldMappingSingleLabel,
    ticketFieldMappingMultiLabel,
    ticketRequiredFieldsMissing,
    ticketFieldMappingCheckboxLabel,
    ticketMappedFieldsForRecord,
    ticketMappedFieldsWithExcess,
    IntakeFormSearch,
    IntakeFormNoMatchFound,
    ticketChildSelectionError,
    ticketapprove, 
    ticketReject, 
    ticketRejectTicketStatus, 
    ticketAdmin_Rejected,
    ticketCommentOutliningOnReject, 
    ticketResetTicketStatus, 
    ticketCommentOutliningOnReset,
    ticketSignedUploadUserCheckBox,
    ticketUploadSignedDocument,
    ticketSigner,
    ticketAttachFile,
    ticketRemoveFile,
    ticketUploadSigned,
    ticketUploadNewVersion,
    ticketMarkAsCounterpartyDocument,
    ticketNotes,
    ticketNewDocumentUploaded,
    ticketNewVersionDocument,
    ticketSignedUploadSuccessfully,
    ticketShareDocument,
    ticketToRecipients,
    ticketShareSubject,
    ticketShareMessage,
    ticketShareAttachments,
    ticketShare,
    ticketShareEmailError,
    ticketShareEmailSuccess,
    ticketGoToEvisortRecord,
    ticketExistingSFDCDocuments,
    ticketExistingSFDCDocument,
    adminDocumentSyncJob,
    adminMetaDataSyncJob,
    adminExportLegacyLeanupJob

};

export default labels;