/**
* Author:       Michal Szewczyk
* Date:
* Description:  Batch that generates Outbound Calling Sales cases
*
* ******************* Change Log *******************
* Modified by        Version   Change Date
* Michal Szewczyk    1.2       02/08/2016 - added record type selection in the batch
* Michal Szewczyk    1.3       12/09/2016 - fixed SUB-4820
* Michal Szewczyk    1.4       12/09/2016 - implemenention for SUB-4409
* Michal Szewczyk    1.5       06/10/2016 - changed start()
* Pawel Chrzanowski  1.6       25/10/2016   Added SIA removal on Case Callstage transition
* Pawel Chrzanowski  1.7       28/10/2016   Scheduled Callback field is now cleared
* Pawel Chrzanowski  1.8       18/11/2016   Added no Stage transition when outcome='No Sale'
* Pawel Chrzanowski  1.9       21/11/2016   Added Case resetting on Stage transition
* Pawel Chrzanowski  2.0       22/11/2016   Case with Reschedule in future is now not reset
* Pawel Chrzanowski  2.1       29/11/2016   'No Sale' Cases can now advance into T2 Catch Up again
* Wiktor Czykin      2.2       14/12/2016   Added population of OC_Batch_Updated_Date__c
* Wiktor Czykin      2.3       20/12/2016   Added Schools filtering
**/
global class OutboundCallingSalesBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable {

    public static final String BATCH_NAME = OutboundCallingSalesBatch.class.getName();
    public static final Integer ERROR_LIMIT = 800;
    public String errorString = '';

    private Id recordTypeId;
    private Id schoolRecordTypeId;
    private Integer errorCount = 0;
    private Outbound_Call_Batch_Setting__c configRecord;
    private List<OutboundCallingBean.CallStageMapping> params;

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.1
    Function - batch class constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         20/12/2016  //added setting of school record type
    ****************************************************************************************/
    public OutboundCallingSalesBatch(){
       configRecord = OutboundCallingBatchUtils.fetchConfigRecord(BATCH_NAME);
       params = OutboundCallingUtils.getCallStageParametersByOCsettingId(configRecord.Outbound_Call_Setting__c);
       recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
       schoolRecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.4
    Function - start method of batch - scope definition
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk  1.1         13/09/2016  // added some new fields to soql
    Michal Szewczyk  1.2         06/11/2016  // added new condition to soql
    Wiktor Czykin    1.3         14/12/2016  // added field to SOQL OC_Batch_Updated_Date__c
    Wiktor Czykin    1.4         20/12/2016  // modified soql - extra record type AND
    ****************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext batchContext){
        if(configRecord.Scope__c != null) {
            return Database.getQueryLocator(configRecord.Scope__c);
        }else {
            return Database.getQueryLocator([SELECT Previous_Subscription_Expiry__c, Subscriber__c,
                                                (SELECT Status, OC_Outcome__c, OC_No_Sale_Reason__c, OC_Call_Stage__c, OC_Stage_1_Outcome__c, OC_Stage_2_Outcome__c, 
                                                        OC_Stage_3_Outcome__c, OC_Stage_4_Outcome__c, OC_Stage_1_Call_Date_Time__c, OC_Stage_2_Call_Date_Time__c, 
                                                        OC_Stage_3_Call_Date_Time__c, OC_Stage_4_Call_Date_Time__c, OC_Scheduled_Callback__c, OC_Batch_Updated_Date__c 
                                                FROM Cases__r
                                                WHERE RecordTypeId =:recordTypeId), 
                                                (SELECT Subscription__c FROM SubscriptionIncentiveAssociations__r) 
                                            FROM Subscription__c
                                            WHERE Subscription_Status__c =:Constants.SSTATUS_OFFERED
                                            AND isContinuous__c = false
                                            AND Previous_Subscription__c != null
                                            AND Previous_Subscription_Expiry__c != null
                                            AND RecordTypeId != :schoolRecordTypeId
                                            AND (Subscriber__r.Phone != null OR Subscriber__r.PersonMobilePhone != null OR Subscriber__r.PersonHomePhone != null)]);
        }
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - batch execution for schedule
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void execute(SchedulableContext scheduleContext) {
        Database.executeBatch(new OutboundCallingSalesBatch());
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function -  batch execution logic
    #############Change Log#############
    Modified by        Version    Change Date
    Michal Szewczyk    1.1        12/09/2016  - fixed and changed date calculation for calldatetime
    Michal Szewczk     1.2        13/09/2016 - added if statement in order to exclude some same from processing
    Michal Szewczk     1.3        27/09/2016 - fix date calculation
    Pawel Chrzanowski  1.4        25/10/2016   Added SIA removal on Case Callstage transition
    Pawel Chrzanowski  1.5        28/10/2016   Scheduled Callback field is now cleared
    Pawel Chrzanowski  1.6        14/11/2016   Scheduled Callback change commented
    Pawel Chrzanowski  1.7        18/11/2016   Added no Stage transition when outcome='No Sale'
	Pawel Chrzanowski  1.8        21/11/2016   Added Case resetting on Stage transition
    Pawel Chrzanowski  1.9        22/11/2016   Case with Reschedule in future is now not reset
    Pawel Chrzanowski  2.0        29/11/2016   'No Sale' Cases can now advance into T2 Catch Up again
    Wiktor Czykin      2.1        14/12/2016   Added setting of OC_Batch_Updated_Date__c
    ****************************************************************************************/
    public void execute(Database.BatchableContext batchContext, List<sObject> subscriptions){
        List<Case> casesToUpsert = new List<Case>();
        List<Subscription__c> subsToUpdate = new List<Subscription__c>();
        Map<Id, Subscription__c> caseSubscriptionMap = new Map<Id, Subscription__c>();
        List<SubscriptionIncentiveAssociation__c> siaToDelete = new List<SubscriptionIncentiveAssociation__c>();
        Map<Id, List<SubscriptionIncentiveAssociation__c>> caseSIAMap = new Map<Id, List<SubscriptionIncentiveAssociation__c>>();
        Boolean caseToInsert;
        Boolean isNewCase;
        Boolean isPendingReset;
        String originalStage;
        Date t2_28 = System.today().addDays(params[0].offset);
        Date t2 = System.today().addDays(params[1].offset);
        Date tl1 = System.today().addDays(params[2].offset);
        Date tl2 = System.today().addDays(params[3].offset);
        Date batchRunDate = Date.today();
        //loop through all subs
        Case caseTmp = OutboundCallingBatchUtils.populateCaseValues(configRecord.Parameters__c);
        for(Subscription__c subscription : (List<Subscription__c>) subscriptions){
            caseToInsert = false;
            isPendingReset = false;
            Case caseToProcess;
            if(subscription.Cases__r.size() > 0){
                isNewCase = false;
                caseToProcess = subscription.Cases__r[0];
                if(caseToProcess.Status == Constants.CASE_STATUS_COMPLETED &&
                   (caseToProcess.OC_Outcome__c == Constants.OC_NO_SALE_OUTCOME || caseToProcess.OC_Outcome__c == Constants.OC_CHEQUE_SALES) &&
                   !(caseToProcess.OC_No_Sale_Reason__c == 'Serious Illness' || caseToProcess.OC_No_Sale_Reason__c == 'Main Reader Deceased' )) {
                    isPendingReset = true;
                }else if(caseToProcess.Status == Constants.CASE_STATUS_COMPLETED){
                    continue;
                }
            }else{
                isNewCase = true;
                caseToProcess = caseTmp.clone();
                caseToProcess.OwnerId = OutboundCallingBatchUtils.getQueueId(configRecord.Outbound_Call_Setting__r.Default_Queue_Name__c);
                caseToProcess.AccountId = subscription.Subscriber__c;
                caseToProcess.CreatedDate =  Datetime.now();
                caseToProcess.Print_Subscription__c = subscription.Id;
                caseToProcess.OC_Call_Stage__c = params[0].stagename;
                caseToProcess.RecordTypeId = recordTypeId;
                caseToProcess.OC_Batch_Updated_Date__c = batchRunDate;
                
                caseToProcess.put(params[0].outcome,Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[1].outcome,Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[2].outcome,Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[3].outcome,Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[0].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[0].offset * -1));
                caseToProcess.put(params[1].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[1].offset * -1));
                caseToProcess.put(params[2].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[2].offset * -1));
                caseToProcess.put(params[3].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[3].offset * -1));
            }

            originalStage = caseToProcess.OC_Call_Stage__c;
            if(subscription.Previous_Subscription_Expiry__c == t2_28){
                //28 days from today
                caseToProcess.OC_Call_Stage__c = params[0].stagename;
                caseToProcess.put(params[0].outcome, Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[0].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[0].offset * -1));
                caseToInsert = true;
            }else if(subscription.Previous_Subscription_Expiry__c == t2){
                //14 days from today
                caseToProcess.OC_Call_Stage__c = params[1].stagename;
                caseToProcess.put(params[1].outcome, Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[1].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[1].offset * -1));
                caseToInsert = true;
            }else if(subscription.Previous_Subscription_Expiry__c == tl1){
                //7 days ago
                caseToProcess.OC_Call_Stage__c = params[2].stagename;
                caseToProcess.put(params[2].outcome, Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[2].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[2].offset * -1));
                caseToInsert = true;
            }else if(subscription.Previous_Subscription_Expiry__c == tl2){
                //21 days ago
                caseToProcess.OC_Call_Stage__c = params[3].stagename;
                caseToProcess.put(params[3].outcome, Constants.CASE_OUTBOUND_CALL_OUTCOME);
                caseToProcess.put(params[3].calldatetime, subscription.Previous_Subscription_Expiry__c.addDays(params[3].offset * -1));
                caseToInsert = true;
            }

            //Case Callstage transition
            if(!isNewCase && caseToInsert && originalStage != null && originalStage != caseToProcess.OC_Call_Stage__c){
                caseToProcess.Status = Constants.CASE_STATUS_NOT_STARTED;
                caseToProcess.OC_Batch_Updated_Date__c = batchRunDate;

                //reset Case if Scheduled Callback is in the past
                if(caseToProcess.OC_Outcome__c != Constants.CASE_OUTCOME_RESCHEDULE || (caseToProcess.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE && caseToProcess.OC_Scheduled_Callback__c <= Datetime.now())){
                    caseToProcess.OC_Outcome__c = Constants.OC_DEFAULT_OUTCOME;
                    caseToProcess.OC_Scheduled_Callback__c = null;
                    caseToProcess.OC_No_Sale_Reason__c = '';
                }
                caseSubscriptionMap.put(caseToProcess.Id, new Subscription__c(Id = subscription.Id, Incentive_Description__c = null));
                caseSIAMap.put(caseToProcess.Id, subscription.SubscriptionIncentiveAssociations__r);
            }

            if(caseToInsert){
                casesToUpsert.add(caseToProcess);
            }
        }

        //upsert Cases
        if(!casesToUpsert.isEmpty()){
            configRecord.Last_Execution_Error__c = false;
            List<Database.UpsertResult> upsertResults = Database.upsert(casesToUpsert, false);
            for(Integer i = 0; i < upsertResults.size(); i++){
                if(upsertResults[i].success){
                    //Case Callstage transition
                    Id caseId = casesToUpsert[i].Id;
                    Subscription__c sub = caseSubscriptionMap.get(caseId);
                    if(sub != null){
                        subsToUpdate.add(sub);
                        siaToDelete.addAll(caseSIAMap.get(caseId));
                    }
                }else{
                    configRecord.Last_Execution_Error__c = true;
                    if(errorCount <= ERROR_LIMIT){
                        errorString += 'Failed to upsert Case, ' + String.valueOf(upsertResults[i].errors) + '/n';
                        errorCount++;
                    }
                }
            }
        }

        //clear Incentive Description from Subscription
        if(!subsToUpdate.isEmpty()){
            SubscriptionTriggerHandler.getInstance().isExecuting = true;
            List<Database.SaveResult> updateResults = Database.update(subsToUpdate, false);
            SubscriptionTriggerHandler.getInstance().isExecuting = false;

            for(Integer i = 0; i < updateResults.size(); i++){
                if(!updateResults[i].success){
                    configRecord.Last_Execution_Error__c = true;
                    if(errorCount <= ERROR_LIMIT){
                        errorString += 'Failed to clear Incentive Description from Subscription ' + subsToUpdate[i].Id + ', ' + String.valueOf(updateResults[i].errors) + '/n';
                        errorCount++;
                    }
                }
            }
        }

        //delete old Subscription Incentives
        if(!siaToDelete.isEmpty()){
            List<Database.DeleteResult> deleteResults = Database.delete(siaToDelete, false);

            for(Integer i = 0; i < deleteResults.size(); i++){
                if(!deleteResults[i].success){
                    configRecord.Last_Execution_Error__c = true;
                    if(errorCount <= ERROR_LIMIT){
                        errorString += 'Failed to delete related Subscription Incentive(s) from Subscription ' + siaToDelete[i].Subscription__c + ', ' + String.valueOf(deleteResults[i].errors) + '/n';
                        errorCount++;
                    }
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function -
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void finish(Database.BatchableContext BC){
        try {
            if(configRecord.Executions__c == null){
                configRecord.Executions__c = 1;
            }else{
                configRecord.Executions__c = configRecord.Executions__c + 1;
            }
            if(configRecord.Last_Execution_Error__c != null && configRecord.Last_Execution_Error__c) {
                configRecord.Batch_Job_Notifications__c = errorString;
            }
            update configRecord;
        } catch (Exception e) {
            throw new TelegraphApplicationException('OutboundCallingSalesBatch error : ' + e.getMessage());
        }
    }
}