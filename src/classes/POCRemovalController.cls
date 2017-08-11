/**
Name: POCRemovalController
* @author Mateusz Michalczyk
* @date 12/03/2015
* @description  Controller for POCRemoval page.
                In theory batch job executed here could be replaced with queueable now 
##########Change Log##########
Modified by     Version     Change Date 
Wiktor Czykin   1.1         06/05/2015 //modified deletePOCs()
*/
public with sharing class POCRemovalController {

    public static final Integer MAX_POC_REMOVAL_JOBS = 10;
    private static final Integer BATCH_SIZE = 200;
    private static final String CRON_TRIGGER_STATE_DELETED = 'DELETED';
    
	private final TCodeManagement__c tCode;

    /*************************************************************************************** 
    Developer - Mateusz Michalczyk
    Date Created -  12/03/2015
    Version - 1.0 
    Function - Constructor for StandardController extension.
    ############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************/
    public POCRemovalController(ApexPages.StandardController stdController) {
        this.tCode = (TCodeManagement__c)stdController.getRecord();
    }

    /*************************************************************************************** 
    Developer - Mateusz Michalczyk
    Date Created -  12/03/2015
    Version - 1.1
    Function -  Action to delete POCs. First it checks whether there are available resources in Apex Scheduler 
    then if maximum of POC removal jobs has been reached. Finally if the current Tcode's POCs are already scheduled for removal.
    ############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         06/05/20215 //made sure that on successfully scheduled job, message has local time not UTC. 
                                            //added scheduled time push depending on the current active jobs count
    ****************************************************************************************/
    public void deletePOCs(){
        POCRemovalBatch removalBatch = new POCRemovalBatch(new List<Id>{tCode.id} , BATCH_SIZE);
        Integer iAcitveJobsCount = Database.countQuery('SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE \'%POCRemovalBatch\' AND state !=\''+CRON_TRIGGER_STATE_DELETED+'\' ');

        if( Database.countQuery('SELECT COUNT() FROM CronTrigger WHERE state!=\''+CRON_TRIGGER_STATE_DELETED+'\'') > 80){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,Label.POC_Deletion_System_Resources_Error));
        } else if ( Database.countQuery('SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name =\''+tCode.id+'POCRemovalBatch\' AND state !=\''+CRON_TRIGGER_STATE_DELETED+'\'') !=0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,tCode.Name+Label.POC_Deletion_TCode_Being_Processed));
        } else if ( iAcitveJobsCount  >= MAX_POC_REMOVAL_JOBS ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,Label.POC_Deletion_Too_Many_Jobs));
        } else {
            pocDeletedJobsClean();
            Integer iTimeToTheFuture = 2+(5*iAcitveJobsCount);
            DateTime currentTime = System.now().addMinutes(iTimeToTheFuture);
            String sCron = currentTime.format('ss mm HH dd MM ? yyyy');
            Id batchID = System.schedule(tCode.id+'POCRemovalBatch', sCron, removalBatch);
            CronTrigger job = [SELECT Id, NextFireTime FROM CronTrigger WHERE Id=:batchID ];
            ApexPages.addMEssage(new ApexPages.Message(ApexPages.SEVERITY.INFO, Label.POC_Deletion_Scheduled_Message+' '+(job.NextFireTime!=null?job.NextFireTime.format():'')));
        }
    }

    /*************************************************************************************** 
    Developer - Mateusz Michalczyk
    Date Created -  12/03/2015
    Version - 1.0 
    Function -  Method which cleans up Jobs which have status deleted but still show up on Salesforce Schedule Job Monitoring UI.
    It also allows to create new jobs For the same TCode.
    ############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void pocDeletedJobsClean(){
        List<CronTrigger> jobsToBeDeleted = Database.query('SELECT id FROM CronTrigger WHERE CronJobDetail.Name LIKE \'%POCRemovalBatch\' AND state =\''+CRON_TRIGGER_STATE_DELETED+'\'');
            for(CronTrigger trig : jobsToBeDeleted ){
                System.abortJob(trig.id);
            }
    }

    /*************************************************************************************** 
    Developer - Mateusz Michalczyk
    Date Created -  12/03/2015
    Version - 1.0 
    Function -  return to source TCode on Cancel button click
    ############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public PageReference goBackToTCode(){
        return new ApexPages.StandardController(tCode).view();
    }
   
}