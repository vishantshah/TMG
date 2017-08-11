/**
* @author Pawel Chrzanowski
* @date 08/07/2016
* @description  Outbound Call Batch Setting's Manage Job Controller Extension
#############Change Log#############
**/
global class OutboundCallManageJobExtension {

    public Outbound_Call_Batch_Setting__c ocbs {get;set;}
    public CronTrigger ct {get;set;}
    public Boolean hasJob {get;set;}
    public Boolean hasJobId {get;set;}
    public Boolean hasBatchClassName {get;set;}
    public Boolean isActive {get;set;}
    public String errorMessage {get;set;}

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        08/07/2016
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public OutboundCallManageJobExtension(ApexPages.StandardController stdController){
        Id ocbsId = stdController.getId();
        hasJob = false;
        hasJobId = false;
        hasBatchClassName = false;
        isActive = false;

        if(ocbsId != null){
            List<Outbound_Call_Batch_Setting__c> lstOcbs = [select Name, Active__c, Batch_Class_Name__c, Batch_Job_Notifications__c, Batch_Status__c, Cron_String__c, Executions__c, Job_Id__c, Last_Execution_Error__c, Outbound_Call_Setting__c, Parameters__c, Scope__c from Outbound_Call_Batch_Setting__c where Id = :ocbsId];
            if(!lstOcbs.isEmpty()){
                if(String.isNotBlank(lstOcbs[0].Batch_Class_Name__c) && String.isNotBlank(lstOcbs[0].Cron_String__c)){
                    ocbs = lstOcbs[0];
                    hasBatchClassName = true;
                    isActive = ocbs.Active__c;
                    checkJobStatus();
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Outbound_Call_Batch_Setting_Batch_Name_Not_Found));
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Outbound_Call_Batch_Setting_Not_Found));
            }
        }
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        08/07/2016
    Function    Method to check job status
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void checkJobStatus(){
        if(String.isNotBlank(ocbs.Job_Id__c)){
            hasJobId = true;
            List<CronTrigger> lstCt = [select CronExpression, TimesTriggered, NextFireTime, CronJobDetail.Name, CronJobDetail.JobType from CronTrigger where Id = :ocbs.Job_Id__c];
            if(!lstCt.isEmpty()){
                ct = lstCt[0];
                hasJob = true;
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Outbound_Call_Batch_Setting_Job_Not_Found));
            }
        }
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        08/07/2016
    Function    Method for JS Remoting to schedule a job
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @RemoteAction
    global static String scheduleJob(String id){
        List<Outbound_Call_Batch_Setting__c> lstOcbs = [select Batch_Class_Name__c, Cron_String__c from Outbound_Call_Batch_Setting__c where Id = :id];
        if(!lstOcbs.isEmpty()){
            if(TMGUtil.isDataValid(lstOcbs[0].Batch_Class_Name__c) && TMGUtil.isDataValid(lstOcbs[0].Cron_String__c)){
                try{
                    Type t = Type.forName(lstOcbs[0].Batch_Class_Name__c);
                    String jobId = System.schedule('Outbound Call Batch (' + id + ')', lstOcbs[0].Cron_String__c, (Schedulable)t.newInstance());
                    lstOcbs[0].Job_Id__c = jobId;
                    update lstOcbs[0];
                    return 'success';
                }catch(Exception e){
                    System.debug('### OutboundCallManageJobExtension.scheduleJob -> Exception: ' + e.getMessage());
                    return Label.Outbound_Call_Batch_Setting_Error + ' ' + e.getMessage();
                }
            }else{
                System.debug('### OutboundCallManageJobExtension.scheduleJob -> Error: ' + Label.Outbound_Call_Batch_Setting_Batch_Name_Not_Found);
                return Label.Outbound_Call_Batch_Setting_Error + ' ' + Label.Outbound_Call_Batch_Setting_Batch_Name_Not_Found;
            }
        }else{
            System.debug('### OutboundCallManageJobExtension.scheduleJob -> Error: ' + Label.Outbound_Call_Batch_Setting_Not_Found);
            return Label.Outbound_Call_Batch_Setting_Error + ' ' + Label.Outbound_Call_Batch_Setting_Not_Found;
        }
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        08/07/2016
    Function    Method for JS Remoting to unschedule a job
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @RemoteAction
    global static String unscheduleJob(String id){
        List<Outbound_Call_Batch_Setting__c> lstOcbs = [select Job_Id__c from Outbound_Call_Batch_Setting__c where Id = :id];
        if(!lstOcbs.isEmpty()){
            if(TMGUtil.isDataValid(lstOcbs[0].Job_Id__c)){
                try{
                    System.abortJob(lstOcbs[0].Job_Id__c);
                    lstOcbs[0].Job_Id__c = null;
                    update lstOcbs[0];
                    return 'success';
                }catch(Exception e){
                    System.debug('### OutboundCallManageJobExtension.unscheduleJob -> Exception: ' + e.getMessage());
                    return Label.Outbound_Call_Batch_Setting_Error + ' ' + e.getMessage();
                }
            }else{
                System.debug('### OutboundCallManageJobExtension.unscheduleJob -> Error: ' + Label.Outbound_Call_Batch_Setting_Job_Id_Not_Found);
                return Label.Outbound_Call_Batch_Setting_Error + ' ' + Label.Outbound_Call_Batch_Setting_Job_Id_Not_Found;
            }
        }else{
            System.debug('### OutboundCallManageJobExtension.unscheduleJob -> Error: ' + Label.Outbound_Call_Batch_Setting_Not_Found);
            return Label.Outbound_Call_Batch_Setting_Error + ' ' + Label.Outbound_Call_Batch_Setting_Not_Found;
        }
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        08/07/2016
    Function    Method for Action Function to display Apex PageMessage
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void showErrorMessage(){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.errorMessage));
    }
}