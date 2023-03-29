public  with sharing class PostInstallationController {
    @AuraEnabled
    public static Map<String, String> init(){
        Map<String, String> mapOfEvisortData = new Map<String, String>();
        try{  
            List<NamedCredential> namedCredentialList =[SELECT Id, DeveloperName FROM NamedCredential where DeveloperName='Evisort' LIMIT 1];
            String namedCredential = namedCredentialList.size()>0 ? 'true' : 'false';
            mapOfEvisortData.put('namedCredential', namedCredential);

            List<Evisort_Status__c> evisortStatus =[SELECT Id, Name, Authenticated__c, Authentication_Date__c FROM Evisort_Status__c LIMIT 1];
            String authStatus = evisortStatus.size()>0 ? evisortStatus[0].Authenticated__c == true ? 'true' : 'false':'false';
            mapOfEvisortData.put('Authenticate', authStatus);
            
            String isEvisortAdminPermission; 
            Id currentUserId = UserInfo.getUserId();
            List<String> permissionSets = new List<String>{ Constants.PERMSETNAME_EVISORTADMIN };
            List<PermissionSetAssignment> assignments = [SELECT Id, AssigneeId
                                                             FROM PermissionSetAssignment
                                                             WHERE PermissionSet.Name = :permissionSets AND AssigneeId =: currentUserId LIMIT 1];
            isEvisortAdminPermission = assignments.size()>0 ? 'true' : 'false';
            mapOfEvisortData.put('AppPermission', isEvisortAdminPermission);
            
            String isLog;
            List <Log_Settings__mdt> turnOnLogList = [SELECT Id, Enable_Logging__c, Log_to_System_Debug__c, Max_Number_Of_Logs__c FROM Log_Settings__mdt LIMIT 1];
            if(turnOnLogList[0].Enable_Logging__c == true){
                mapOfEvisortData.put('TurnOnLog', 'true');
            }else{
                mapOfEvisortData.put('TurnOnLog', String.valueOf(turnOnLogList[0].Id));
            }

            List<CronTrigger> cronTriggerList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: Label.Admin_MetaDataSyncJob LIMIT 1];
            String evisortMetaData = cronTriggerList.size() > 0 ? 'true' : 'false';
            mapOfEvisortData.put('isEvisortMetadataValue',evisortMetaData);

            List<CronTrigger> cronTriggerDocument = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: Label.Admin_DocumentSyncJob LIMIT 1];
            String evisortDocumenSync = cronTriggerDocument.size() > 0 ? 'true' : 'false';
            mapOfEvisortData.put('isDocumentSyncValue',evisortDocumenSync);

            List<CronTrigger> cronTriggerLegcyExport = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: Label.Admin_ExportLegacyLeanupJob LIMIT 1];
            String evisortLegcyExport = cronTriggerLegcyExport.size() > 0 ? 'true' : 'false';
            mapOfEvisortData.put('isExportLegacyValue',evisortLegcyExport);

            List<PermissionSetAssignment> adminPermissionSet = [SELECT Id, PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name =: Constants.PERMSETNAME_EVISORTADMIN]; 
            String adminPermissionSetId = '';
            if(adminPermissionSet.size() > 0){
                adminPermissionSetId = adminPermissionSet[0].PermissionSetId;
            }
            mapOfEvisortData.put('adminPermissionSetId',adminPermissionSetId);

            List<PermissionSetAssignment> userPermissionset = [SELECT Id, PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name =: Constants.PERMSETNAME_EVISORTUSER];
            String userPermissionsetId = '';
            if(userPermissionset.size() > 0) {
                userPermissionsetId = userPermissionset[0].PermissionSetId;
            }
            mapOfEvisortData.put('userPermissionsetId',userPermissionsetId);

            return mapOfEvisortData;
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());  
        } 
    }
    
    @AuraEnabled
    public static Map<String,String> updateEvisortWorkspaceSetting(String domain, String subDomain, String workspace){ 
        Map<String,String> mapOfEvisortWorkspaceSetting = new Map<String,String>();
        try {
            Evisort_Workspace_Settings__c  evisortSettings = Evisort_Workspace_Settings__c.getOrgDefaults();
            if(String.isNotBlank(domain) && String.isNotBlank(subDomain) && String.isNotBlank(workspace)){
                evisortSettings.Domain__c = domain;
                evisortSettings.subdomain__c = subDomain;
                evisortSettings.Workspace__c = workspace;
                upsert evisortSettings;
            }
            if(evisortSettings != null){
                mapOfEvisortWorkspaceSetting.put('domain',evisortSettings.Domain__c);
                mapOfEvisortWorkspaceSetting.put('subdomain',evisortSettings.subdomain__c);
                mapOfEvisortWorkspaceSetting.put('workspace',evisortSettings.Workspace__c);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }  
        return mapOfEvisortWorkspaceSetting;
    }
    
    @AuraEnabled
    public static String saveScheduler(String scheduleData, String jobName)  
    {
        try{       
            String cornExpression = createCornExpression(scheduleData);
            List<CronTrigger> ScheduleJobList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: jobName  LIMIT 1];
            if(jobName == Label.Admin_DocumentSyncJob){
                DocumentSyncSchedulable documentSyncObj = new DocumentSyncSchedulable();
                if(ScheduleJobList.size() <= 0){
                    System.schedule(Label.Admin_DocumentSyncJob, cornExpression, documentSyncObj); 
                }else if(ScheduleJobList.size() >= 0){
                    System.abortJob(ScheduleJobList[0].Id);
                    System.schedule(Label.Admin_DocumentSyncJob, cornExpression, documentSyncObj);  
                }
            }else if(jobName == Label.Admin_MetaDataSyncJob)
            {
                EvisortMetadataSyncBatch evisortMetadataObj = new EvisortMetadataSyncBatch();
                if(ScheduleJobList.size() <= 0){
                    System.schedule(Label.Admin_MetaDataSyncJob, cornExpression, evisortMetadataObj);  
                }else if(ScheduleJobList.size() >= 0){
                    System.abortJob(ScheduleJobList[0].Id);
                    System.schedule(Label.Admin_MetaDataSyncJob, cornExpression, evisortMetadataObj);  
                }
            }else if(jobName == Label.Admin_ExportLegacyLeanupJob)
            {
                EvisortLegacyCleanUpBatch elb = new EvisortLegacyCleanUpBatch();
                if(ScheduleJobList.size() <= 0){  
                    System.schedule(Label.Admin_ExportLegacyLeanupJob, cornExpression, elb); 
                }else if(ScheduleJobList.size() >= 0 )
                {
                    System.abortJob(ScheduleJobList[0].Id);
                    System.schedule(Label.Admin_ExportLegacyLeanupJob, cornExpression, elb); 
                }
            }
            return jobName;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String editScheduler(String editScheduleJob){
        return createJSONtoCronExpression(editScheduleJob);
    }
    
    @AuraEnabled
    public static String deleteScheduler( String deleteSchedulerJob){
        List<CronTrigger> job =[SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: deleteSchedulerJob LIMIT 1];
            System.abortJob(job[0].Id);        
        return deleteSchedulerJob;
    }
    
    public static String createCornExpression(String scheduleData){  
        String cornExpression = '0'+' '+'0'+' '; 
        Map<String, Object> mapOfSchduleData = (Map<String, Object>)JSON.deserializeUntyped(scheduleData); 
        String tempTime = getSplitTimeValue(mapOfSchduleData.get('time'));
        Map<String, Object> monthlyMap= (Map<String, Object>)mapOfSchduleData.get('monthly');
        Map<String, Object> dayMonthMap = (Map<String, Object>)monthlyMap.get('dayMonth');
        Map<String, Object> weekDayMonthMap=(Map<String, Object>)monthlyMap.get('weekDayMonth');
        Map<String, Object> weeklyMap = (Map<String, Object>)mapOfSchduleData.get('weekly');
        cornExpression += temptime;
        String singleDayOfMonth = String.valueof(dayMonthMap.get('day'));
        String weekMonthMap = String.valueof(weekDayMonthMap.get('week'));
        String dayWeekMonthMap = String.valueof(weekDayMonthMap.get('day'));

        if(weeklyMap != null && weeklyMap.size()>0 ){
            String dayOfWeek='';
            for(String s :weeklyMap.keySet())
            {
                if(weeklyMap.containsKey(s) && weeklyMap.get(s) == true){
                    dayOfWeek += s+',';
                }
            }
            cornExpression +=' '+'?'+' '+'*'+' '+dayOfWeek.removeEnd(',')+' '+'*';
            return cornExpression;
        }
        else if(dayMonthMap !=null && dayMonthMap.size()>0 && dayMonthMap.get('day') !='' && String.isNotEmpty(singleDayOfMonth))
        {
            cornExpression +=' '+SingleDayOfMonth+' '+'1/1'+' '+'?'+' '+'*';
            return cornExpression; 
        }else if(weekDayMonthMap !=null && weekDayMonthMap.size()>0 && String.isNotEmpty(weekMonthMap) && String.isNotEmpty(dayWeekMonthMap)){ 
            cornExpression +=' '+'?'+' '+'1/1'+' '+ dayWeekMonthMap.removeEnd(',') +'#'+weekMonthMap+' '+'*';
            return cornExpression;     
        }
        return null;
    }
    
    public static String getSplitTimeValue(Object splitTime){
        String scheduleTime = String.valueOf(splitTime); 
        String [] tempTime = scheduleTime.split(':');  
        if(tempTime[1].contains('PM')){
            String standardTime = String.valueof( Integer.ValueOf(tempTime[0].trim()) + 12);
            if(standardTime == '24')
            {
                return '0';
            }
            return standardTime;
        }
        return tempTime[0].trim();
    }
        
     public static string createJSONtoCronExpression(String jobName)
    {
        List<CronTrigger> cronTriggerList = [SELECT Id, CronJobDetailId, NextFireTime, PreviousFireTime, State, StartTime, EndTime, TimesTriggered, CronExpression, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name =: jobName];     
        String editCronExpression = String.valueOf(cronTriggerList[0].CronExpression);  
        List<String> cronExpList = editCronExpression.split(' ');
        String jobTime =jobTimeConveter(String.valueOf(cronExpList[2]));
        if(cronExpList[3]=='?' && cronExpList[6]=='*' && cronExpList[4] !='1/1'){
            String weekly = ''; 
            List<String> nameOfDayList = String.valueOf(cronExpList[5]).split(',');
            for(Integer i=0; i<nameOfDayList.size(); i++ )
            {
                String day = nameOfDayList[i].toLowerCase();
                weekly += '"' + day.capitalize() +'"' + ':true,';
            }
            weekly = weekly.removeEnd(',');

            String jobDetail = '{' +'"weekly":{'+weekly+'},' +'"monthly":{"dayMonth":{"day":""},"weekDayMonth":{"week":"","day":""}},"time":"' + jobTime + '"'+ '}';
            return jobDetail;
        }else if(cronExpList[5] =='?' && cronExpList[6] =='*')
        {
            String jobDetailJson ='{"weekly":{},"monthly":{"dayMonth":{"day":"'+cronExpList[3]+'"},"weekDayMonth":{"week":"","day":""}},"time":"' + jobTime + '"'+ '}';
            return jobDetailJson;
        }else if(cronExpList[3]=='?' && cronExpList[6]=='*' && cronExpList[4] =='1/1')
        { 
            List<String> dayAndWeek = String.valueOf(cronExpList[5]).split('#');
            String day = String.valueOf(dayAndWeek[0]).toLowerCase();
            day = day.capitalize();
            String jobDetail = '{"weekly":{},"monthly":{"dayMonth":{"day":""},"weekDayMonth":{"week":"'+String.valueOf(dayAndWeek[1])+'","day":"'+ day +'"}},"time":"' + jobTime + '"'+ '}';
            return jobDetail;
        }
        
        return null;
    }
    
    public static String jobTimeConveter(String jobTime)
    {
        if(Integer.valueOf(jobTime) <= 12)
        {
            return jobTime +' : 00 AM';
        }else if(Integer.valueOf(jobTime) > 12 && Integer.valueOf(jobTime) < 24)
        {
           
            return String.valueOf(Integer.valueOf(jobTime)-12) + ' : 00 PM';     
        }
        return null;
    }  
}