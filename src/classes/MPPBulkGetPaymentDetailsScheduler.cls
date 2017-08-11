/*
* rKura@TMG, Plane 1.2; 190612. 
* Apex batch job to    
*/  
global class MPPBulkGetPaymentDetailsScheduler implements Schedulable {
/*
     global String query = 'Select Name,Payment_Start_Date__c,MPP_Premium_Subscription_ID__c,MPP_DD_First_Payment_Amount__c,MPP_DD_Next_Payment_Date__c,'+
                    ' Subscriber__r.Subscriber_Number__c,Subscriber__c,MppDDCalloutStage__c,MppDDCalloutAttemptCount__c '+
                ' from Subscription__c  '+
                ' where Subscription_Status__c=\'Pending\' '+
                //' and Payment_Type__c=\'Direct Debit\' and Subscriber__r.IsUsingMPP__c=false '+
                ' and (MPP_Premium_Subscription_ID__c = null or MPP_DD_First_Payment_Amount__c=null or MPP_DD_Next_Payment_Date__c=null ) '+
                ' and MppDDCalloutAttemptCount__c<4 and MppDDCalloutAttemptCount__c !=null '+
                ' and (MppDDCalloutStage__c !=null and ( MppDDCalloutStage__c =\'PaymentSchedule\' OR  MppDDCalloutStage__c =\'LapsedSubPaymentSchedule\' )) order by Name';
*/

     global String query = 'Select Name,Payment_Start_Date__c,MPP_Premium_Subscription_ID__c,MPP_DD_First_Payment_Amount__c,MPP_DD_Next_Payment_Date__c,'+
                    ' Subscriber__r.Subscriber_Number__c,Subscriber__c,MppDDCalloutStage__c,MppDDCalloutAttemptCount__c '+
                ' from Subscription__c  '+
                ' where Subscription_Status__c in (\''+DDSetupOnMPPBatch.SUBSCRIPTION_STATUS_PENDING+'\', \''+DDSetupOnMPPBatch.SUBSCRIPTION_STATUS_OFFERED+'\') '+
                //' and (MPP_Premium_Subscription_ID__c = null or MPP_DD_First_Payment_Amount__c=null or MPP_DD_Next_Payment_Date__c=null ) '+
                ' and Previous_Subscription__r.isContinuous__c = true and Previous_Subscription__r.Is_Using_MPP__c = \'False\'' + // added for PP-1615
                ' and MppDDCalloutAttemptCount__c<4 and MppDDCalloutAttemptCount__c !=null '+
                ' and (MppDDCalloutStage__c !=null and ( MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_3+'\' '+
                ' OR  MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_5+'\' '+
                ' OR  MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_5_FAILED+'\' '+
                ' OR  MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_6_FAILED+'\' )) order by Name';                


//this method creates the query string and executes the batch
    global void execute(SchedulableContext sc) {
        try {
        //create the batch and execute it
        DDSetupOnMPPBatch batchable = new DDSetupOnMPPBatch(query, 'GetPayment');          
            Id accountUpdateBatchId = Database.executeBatch(batchable,Integer.valueOf(Label.MppDDCalloutBatchSize));
        } catch(Exception ex) { //If unable to queue the Batch Class then Schedule self  to run after few seconds (configured in Custom Label).
                Datetime sysTime = System.now();
                sysTime = sysTime.addSeconds(Integer.valueOf(Label.JobSchedulerRetryFailureInSeconds));
                String chron_exp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
                system.debug('############chron_exp#######'+chron_exp);
                MPPBulkGetPaymentDetailsScheduler  p = new MPPBulkGetPaymentDetailsScheduler();
                System.schedule('MPPBulkGetPaymentDetailsScheduler:' + sysTime.getTime(),chron_exp,p);          
        }
    }     
}