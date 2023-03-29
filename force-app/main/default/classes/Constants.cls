public with sharing class Constants {
    // System
    public static final String PACKAGE_NAME = '';

    // Setup
    public static final String PERMSETNAME_EVISORTADMIN = 'Evisort_Admin';
    public static final String PERMSETNAME_EVISORTUSER = 'Evisort_User';

    // Reports
    public static final String EVISORT_FOLDER_NAME = 'Evisort Reports';
    public static final String ERROR_REPORT_NAME = 'Evisort Export Documents with Error';
    public static final String OVERSIZED_REPORT_NAME = 'Evisort Export Documents Oversized';

    // API
    public static final String EVISORT_USERNAME = 'EVISORT-API-KEY';
    public static final String CALLOUT = 'callout:Evisort/v1';
    public static final String API_VERSION = '1.0';
    public static final String TOKEN_URL = '/auth/token';
    public static final String DOCUMENT_URL = '/documents';
    public static final String FIELDS_URL = '/fields?active=true';
    public static final String PROVISIONS_URL = '/provisions';
    public static final String GET_TICKET_URL = '/contracts/tickets/';
    public static final String NEXT_STAGE_URL = '/contracts/tickets/{0}/next-stage';
    public static final String COMPLETE_URL = '/contracts/tickets/{0}/complete';
    public static final String ACTIVITY_LOG_URL = '/contracts/activities?entityType=ticket&entityId={0}';
    public static final String PARTICIPANTS_URL = '/contracts/tickets/{0}/participants';

    // Content Sync Criteria
    public static final Integer RECORD_RETRIEVAL_WAIT_MINUTES = 5;
    public static final Integer SYNC_PAGE_SIZE = 10;
    public static final Set<String> CALLBACK_FILE_TYPES = new Set<String>{ 'PDF', 'WORD_X', 'WORD' };
    public static final Map<String, String> FORM_DATA_MIME_TYPES = new Map<String, String>{
        'CSV' => 'text/csv',
        'EXCEL' => 'application/vnd.ms-excel',
        'EXCEL_X' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'JPEG' => 'image/jpeg',
        'JPG' => 'image/jpeg',
        'PDF' => 'application/pdf',
        'TEXT' => 'text/plain',
        'WORD_X' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'WORD' => 'application/msword'
    };
    // Because the Sync Criteria screen counts WORD and WORD_X as one line item, we map here to the appropriate one
    // for easy processing
    public static final Map<String, String> FILE_TYPE_DUPLICATES = new Map<String, String>{
        'EXCEL' => 'EXCEL_X',
        'JPG' => 'JPEG',
        'WORD' => 'WORD_X'
    };
    // Maps objects that do not have a Name field but something different
    public static final Map<String, String> OBJECT_NAME_FIELDS = new Map<String, String>{
        'Contract' => 'ContractNumber'
    };
    // Maps objects where we want to add an additional name to the file path (possibly configured in the future)
    public static final Map<String, String> OBJECT_DIRECTORY_FIELDS = new Map<String, String>{
        'Opportunity' => 'Account.Name',
        'Contract' => 'Account.Name'
    };
    // No matter what, always exclude these objects from creating Evisort records
    public static final Set<String> OBJECTS_EXCLUDED = new Set<String>{ 'User' };
    // Map of Evisort's status field in the API to the corresponding Evisort__c.Document_Status__c picklist
    public static final Map<String, String> EVISORT_STATUSES = new Map<String, String>{
        'READY' => 'Ready',
        'IN_PROGRESS' => 'In Progress',
        'FAILED' => 'Error'
    };
    // Map of Evisort's type field in the API to the corresponding Evisort_Field_Definition__c.Data_Type__c picklist
    public static final Map<String, String> DATA_TYPES = new Map<String, String>{
        'string' => 'Text',
        'number' => 'Number',
        'boolean' => 'Boolean',
        'datetime' => 'Date',
        'single_select' => 'Picklist',
        'multi_select' => 'Multi Picklist',
        'date' => 'Date',
        'phone'	=> 'Number',
        'multipicklist' => 'Multi Picklist',
        'picklist' => 'Picklist',
        'textarea' => 'Text',
        'currency' => 'MONETARY_VALUE',
        'double' => 'Number',
        'percent' => 'Number'
    };

    // Legacy Files Export
    public static final Integer EXPORTS_PER_MINUTE = 45;
    // Evisort Export Object statuses
    public static final String EXPORT_CALCULATING = 'Calculating';
    public static final String EXPORT_READY = 'Ready';
    public static final String EXPORT_RUNNING = 'Running';
    public static final String EXPORT_COMPLETE = 'Complete';
    public static final String EXPORT_CANCELLED = 'Cancelled';
    public static final String EXPORT_ERRORED = 'Errored';

    public static final Set<String> EXPORT_COMPLETE_STATUSES = new Set<String>{ EXPORT_COMPLETE, EXPORT_CANCELLED, EXPORT_ERRORED };
    public static final Set<String> EXPORT_RESETABLLE_STATUSES = new Set<String>{
        EXPORT_READY,
        EXPORT_COMPLETE,
        EXPORT_CANCELLED,
        EXPORT_ERRORED
    };
    // Ordering by priority of object statuses to find overall status
    public static final List<String> EXPORT_STATUSES = new List<String>{
        EXPORT_COMPLETE,
        EXPORT_CANCELLED,
        EXPORT_READY,
        EXPORT_CALCULATING,
        EXPORT_RUNNING
    };
    // Evisort Export Document statuses
    public static final String EXPORT_QUEUED = 'Queued';
    public static final String EXPORT_COMPLETED = 'Completed';

    public static final Map<String, String> FORM_DATA_TYPES = new Map<String, String>{
        'text/csv' => 'CSV',
        'text/css' => 'CSS',
        'text/xml' => 'XML',
        'text/rtf' => 'RTF',
        'text/html' => 'HTML',
        'text/plain' => 'TEXT',

        'audio/mp4' => 'MP4',
        'audio/mpeg' => 'MPEG',

        'image/jpg' => 'JPG',
        'image/png' => 'PNG',
        'image/gif' => 'GIF',
        'image/jpeg' => 'JPEG',

        'application/rtf' => 'RTF',
        'application/xml' => 'XML',
        'application/zip' => 'ZIP',
        'application/pdf' => 'PDF',
        'application/html' => 'HTML',
        'application/x-sql' => 'SQL',
        'application/x-gzip' => 'ZIP',
        'application/msword' => 'WORD',
        'application/javascript' => 'JS',
        'application/vnd.ms-excel' => 'EXCEL',
        'application/vnd.ms-powerpoint' => 'PPT',
        'application/vnd.google-apps.document' => 'DOC',
        'application/vnd.google-apps.spreadsheet' => 'EXCEL',
        'application/vnd.google-apps.presentation' => 'PPT',
        'application/vnd.oasis.opendocument.text' => 'DOC',
        'application/vnd.oasis.opendocument.spreadsheet' => 'EXCEL',
        'application/vnd.ms-excel.sheet.macroEnabled.12' => 'EXCEL',
        'application/vnd.ms-word.document.macroEnabled.12' => 'DOC',
        'application/vnd.oasis.opendocument.presentation' => 'PPT',
        'application/vnd.ms-powerpoint.presentation.macroEnabled.12' => 'PPT',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'EXCEL_X',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.template' => 'EXCEL_X',
        'application/vnd.openxmlformats-officedocument.presentationml.template' => 'PPT_X',
        'application/vnd.openxmlformats-officedocument.presentationml.slideshow' => 'PPT_X',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.template' => 'WORD_X',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'WORD_X',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'PPT_X'
    };

    /* ------------------ 21-03-2023---------------------*/
    //Map for Find FileType
    public static final Map<String, String> DOCUMENT_FILE_TYPE = new Map<String, String>{ //DOCUMENT_FILE_TYPE
        'doc' => 'WORD',
        'docx' => 'WORD_X',
        'csv' => 'CSV',
        'xlsx' => 'EXCEL_X',
        'pdf' => 'PDF'
    };
}