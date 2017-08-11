/**
* @author MIrfan@Appirio, Plane 1.2; . 
* @date 09/05/2012
* @description Schedules a batch job that creates payment schedule in MPP for print continuous subscription renewal
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         10/07/2015  //clean-up
**/
global class MPPBulkPaymentScheduleScheduler implements Schedulable {

      global String query = 'select Name,start_date__c, '+
                    ' Previous_Subscription__c, '+
                    ' total_price__c, '+
                    ' TCode__c, '+
                    ' TCode__r.Name, '+
                    ' Order_Taken_By_Company__c, '+
                    ' Order_Taken_By_User_Department__c, '+
                    ' Order_Taken_Method__c, '+
                    ' PaymentDate__c, '+
                    ' Subscription_Duration_Number__c, '+
                    ' Previous_Subscription__r.End_Date__c, '+
                    ' Subscriber__r.Subscriber_Number__c, '+
                    ' Subscriber__r.IsUsingMPP__c, '+
                    ' Subscriber__r.Subscriber_Digital_Status__c, '+
                    ' Subscriber__r.MPP_CurrentPayScheduleEndDate__c,' + 
                    ' Previous_Subscription__r.Is_Using_MPP__c,' + 
                    ' Previous_Subscription__r.isContinuous__c,' + 
                    ' Previous_Subscription__r.Subscription_Status__c,' +
                    ' Previous_Subscription__r.MPP_Scheduled_First_Payment_Date__c, ' +
                    ' Previous_Subscription__r.Subscription_Duration_Picklist__c, ' +
                    ' Previous_Subscription__r.MPP_DD_Frequency__c, '+
                    ' Previous_Subscription__r.MPP_CC_Frequency__c, '+
                    ' Previous_Subscription__r.Payment_Type__c, '+
                    ' Previous_Subscription__r.PaymentDate__c, '+
                    ' MppDDCalloutAttemptCount__c,MppDDCalloutStage__c,MppDDLastCalloutDateTime__c,MPP_CC_First_Payment_Amount__c ' +
                ' from Subscription__c  '+
                ' where Subscription_Status__c=\''+DDSetupOnMPPBatch.SUBSCRIPTION_STATUS_OFFERED+'\' AND  '+
                ' Previous_Subscription__c!=null AND  '+
                ' Previous_Subscription__r.isContinuous__c = true '+ 
                ' AND  '+
                ' (  '+
                '   ( '+
                '       MppDDCalloutAttemptCount__c<4 AND '+ 
                '       MppDDCalloutAttemptCount__c !=null AND '+ 
                '       Payment_Type__c=\''+DDSetupOnMPPBatch.SUBSCRIPTION_PAYMENT_TYPE_DD+'\' AND  '+
                '       Subscriber__r.IsUsingMPP__c=false AND  '+
                '       (MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_2+'\'  or MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_3_FAILED+'\') '+ 
                '   )  '+
                '   OR  '+
                '   ( '+
                '       (MppDDCalloutAttemptCount__c<4 OR MppDDCalloutAttemptCount__c = null) AND '+ 
                '       Subscriber__r.IsUsingMPP__c=true AND  '+
                '       (MppDDCalloutStage__c = null or MppDDCalloutStage__c =\''+DDSetupOnMPPBatch.MppDDCalloutStage_STAGE_3_FAILED+'\') '+ 
                '   )  '+
                ' )  '+
                ' order by Name ';                                
                
    //this method creates the query string and executes the batch
    global void execute(SchedulableContext sc) {
        try {
            DDSetupOnMPPBatch batchable = new DDSetupOnMPPBatch(query, 'PaymentSchedule');          
            Id accountUpdateBatchId = Database.executeBatch(batchable,Integer.valueOf(Label.MppDDCalloutBatchSize));
        } catch(Exception ex) { //If unable to queue the Batch Class then Schedule self  to run after few seconds (configured in Custom Label).
            Datetime sysTime = System.now();
            sysTime = sysTime.addSeconds(Integer.valueOf(Label.JobSchedulerRetryFailureInSeconds));
            String chron_exp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
            System.debug('############chron_exp#######'+chron_exp);
            MPPBulkPaymentScheduleScheduler  p = new MPPBulkPaymentScheduleScheduler();
            System.schedule('MPPBulkPaymentScheduleScheduler:' + sysTime.getTime(),chron_exp,p);          
        }
    }     
}