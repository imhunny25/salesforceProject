@RestResource(urlMapping='/EvisortGroupStatusUpdate')
global with sharing class ExportObjectStatusRestController { 
    @HttpPost
    global static void updateExportObjectStatus() {
        try{
            RestRequest req = RestContext.request;
            String reqBody = req.requestBody.toString();
            RestRequestBody payload = (RestRequestBody) JSON.deserialize(reqBody, RestRequestBody.class);
            
            String status = payload.status;
            Id evisortExportObjectID = payload.evisortExportObjectId;
           
            List<Evisort_Export_Object__c> eeoList = [SELECT Id, Name, Evisort_Export_Filter__c, File_Types__c, Grouped_Error__c, Object__c, Status__c, Completed__c, Number_of_Documents__c FROM Evisort_Export_Object__c WHERE Id =: evisortExportObjectID LIMIT 1 FOR UPDATE];

            for(Evisort_Export_Object__c eeo: eeoList){
                eeo.Status__c = Constants.EXPORT_COMPLETE;  
                if(status == 'Errored'){
                    eeo.Grouped_Error__c = true;
                }
            }
            
            Data.modify(eeoList, true, false, true);
            
        }catch(Exception e){
            Logger errorlogger = Logger.getInstance();
            errorlogger.log('ExportObjectStatusRestController.updateExportObjectStatus :', e);
        }
    }
    
    global class RestRequestBody {
        private String status;
        private Id evisortExportObjectId;
    } 
}