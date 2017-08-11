/*
* MIrfan@Appirio, Plane 1.2; 090512. 
* Apex batch job to   
*/  
global class MPPBulkUserManageScheduler implements Schedulable {
/*
     global String query = 'Select Name,Subscriber__r.PersonBirthdate, '+
                    ' Subscriber__r.FirstName, '+
                    ' Subscriber__r.LastName, '+
                    ' Subscriber__r.Gender__pc, '+
                    ' Subscriber__r.PersonMailingCountry, '+
                    ' Subscriber__r.PersonMailingState, '+
                    ' Subscriber__r.PersonMailingStreet, '+
                    ' Subscriber__r.PersonMailingCity, '+
                    ' Subscriber__r.PersonMailingPostalCode, '+
                    ' Subscriber__r.PersonHomePhone, '+
                    ' Subscriber__r.PersonMobilePhone, '+
                    ' Subscriber__r.Subscriber_Number__c, '+
                    ' Subscriber__r.Guid__c, '+
                    ' Subscriber__r.PersonEmail, '+
                    ' MppDDCalloutAttemptCount__c,MppDDCalloutStage__c,MppDDLastCalloutDateTime__c,MPP_CC_First_Payment_Amount__c ' +
                ' from Subscription__c  '+
                ' where Subscription_Status__c=\'Offered\' '+
                ' and Payment_Type__c=\'Direct Debit\' and Subscriber__r.IsUsingMPP__c=false '+
                ' and (MppDDCalloutAttemptCount__c<4 or MppDDCalloutAttemptCount__c=null) '+
                ' and (MppDDCalloutStage__c =null or MppDDCalloutStage__c =\'UserManage-Failed\') '+
                ' and Previous_Subscription__c!=null and Previous_Subscription__r.isContinuous__c = true order by Name';
*/

     global String query = 'Select Name,Subscriber__r.PersonBirthdate, '+
                    ' Subscriber__r.FirstName, '+
                    ' Subscriber__r.LastName, '+
                    ' Subscriber__r.Gender__pc, '+
                    ' Subscriber__r.PersonMailingCountry, '+
                    ' Subscriber__r.PersonMailingState, '+
                    ' Subscriber__r.PersonMailingStreet, '+
                    ' Subscriber__r.PersonMailingCity, '+
                    ' Subscriber__r.PersonMailingPostalCode, '+
                    ' Subscriber__r.PersonHomePhone, '+
                    ' Subscriber__r.PersonMobilePhone, '+
                    ' Subscriber__r.Subscriber_Number__c, '+
                    ' Subscriber__r.Guid__c, '+
                    ' Subscriber__r.PersonEmail, '+
                    ' MppDDCalloutAttemptCount__c,MppDDCalloutStage__c,MppDDLastCalloutDateTime__c,MPP_CC_First_Payment_Amount__c ' +
                ' from Subscription__c  '+
                ' where Subscription_Status__c=\''+DDSetupOnMPPBatch.SUBSCRIPTION_STATUS_OFFERED+'\' '+
                ' and Payment_Type__c=\''+DDSetupOnMPPBatch.SUBSCRIPTION_PAYMENT_TYPE_DD+'\' and Subscriber__r.IsUsingMPP__c=false '+
                ' and (MppDDCalloutAttemptCount__c<4 or MppDDCalloutAttemptCount__c=null) '+
                ' and (MppDDCalloutStage__c =null or MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_1_FAILED+'\') '+
                ' and Previous_Subscription__c!=null and Previous_Subscription__r.isContinuous__c = true order by Name';


//this method creates the query string and executes the batch
    global void execute(SchedulableContext sc) {

//If required in future uncomment and try implementing using Custom setting to clear the previous Jobs from cronTrigger
/*
for(CronTrigger CT:[select Id from CronTrigger where State = 'DELETED']){
        System.abortjob(CT.Id);        
    }
*/  
        try {
            //create the batch and execute it
            DDSetupOnMPPBatch batchable = new DDSetupOnMPPBatch(query, 'UserManage');           
            Id accountUpdateBatchId = Database.executeBatch(batchable,Integer.valueOf(Label.MppDDCalloutBatchSize));
        } catch(Exception ex) { //If unable to queue the Batch Class then Schedule self  to run after few seconds (configured in Custom Label).
                Datetime sysTime = System.now();
                sysTime = sysTime.addSeconds(Integer.valueOf(Label.JobSchedulerRetryFailureInSeconds));
                String chron_exp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
                system.debug('############chron_exp#######'+chron_exp);
                MPPBulkUserManageScheduler  p = new MPPBulkUserManageScheduler();
                System.schedule('MPPBulkUserManageScheduler:' + sysTime.getTime(),chron_exp,p);          
        }
    }     
}