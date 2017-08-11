/**
* Developer - Vishant Shah
* Date - 05/05/2017
* Description:  Batch to generate DD Winback cases from subscriptions .
*
* ******************* Change Log *******************
* Modified by   Change Date
**/

global class OutboundCallingDDWinbackBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public static final String BATCH_NAME   = OutboundCallingDDWinbackBatch.class.getName();
    public static final Integer ERROR_LIMIT = 20;

    public String errorString = '';

    private Outbound_Call_Batch_Setting__c configRecord;
    private Id recordTypeId;
    private Id schoolRecordTypeId;
    private Id ownerId;
    private Set<String> statusToExclude;
    private Integer errorCount = 0;

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 05/05/2017
    Version - 1.1
    Function - Constructor
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global OutboundCallingDDWinbackBatch() {
        recordTypeId       = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Case.class.getName());
        schoolRecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
        statusToExclude    = new Set<String>();
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 05/05/2017
    Version - 1.1
    Function - Batch execution for Schedule. 
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global void execute(SchedulableContext schedulableContext){
        Database.executeBatch(new OutboundCallingDDWinbackBatch());
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 05/05/2017
    Version - 1.1
    Function - Define scope for execute, get query from config record if scope set.
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        configRecord = OutboundCallingBatchUtils.fetchConfigRecord(BATCH_NAME);
        ownerId      = OutboundCallingBatchUtils.getQueueId(configRecord.Outbound_Call_Setting__r.Default_Queue_Name__c);

        for (Outbound_Calling_Configuration__mdt exclusionReasons : [SELECT Reason__c FROM Outbound_Calling_Configuration__mdt WHERE Project__c = :Constants.OC_DD_WINBACK_RECORD_TYPE_NAME]){
            statusToExclude.add(exclusionReasons.Reason__c);
        }

        if(configRecord.Scope__c != null) {
            return Database.getQueryLocator(configRecord.Scope__c);
        } else {
            return Database.getQueryLocator([SELECT Previous_Subscription_Expiry__c, Subscriber__c,
                                                    (SELECT Id FROM Cases__r WHERE RecordTypeId = :recordTypeId), 
                                                    (SELECT Subscription__c FROM SubscriptionIncentiveAssociations__r) 
                                               FROM Subscription__c
                                              WHERE Subscription_Status__c = :Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS
                                                AND Last_Status_Change__c = LAST_WEEK
                                                AND Subscriber__r.Subscription_Status_calc__c = 0               // NO Active OR InRenewal Subs 
                                                AND Subscriber__r.Number_of_Offered_Subscriptions__c = 0        // NO Offered Subs
                                                AND Subscriber__r.Number_of_Pending_Subscriptions__c = 0        // NO Pending Subs
                                                AND RecordTypeId != :schoolRecordTypeId
                                                AND Cancellation_Method__c != 'Phone'
                                                AND Cancellation_Reason__c NOT IN :statusToExclude
                                                AND (Subscriber__r.Phone != null OR 
                                                     Subscriber__r.PersonMobilePhone != null OR 
                                                     Subscriber__r.PersonHomePhone != null)] );
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 05/05/2017
    Version - 1.1
    Function - Execute scope for batch
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global void execute(Database.BatchableContext BC, List<sObject> subscriptions) {
        List<Case> casesToInsert = new List<Case>();

        Case basicCaseRecord = OutboundCallingBatchUtils.populateCaseValues(configRecord.Parameters__c);

        for (Subscription__c sub : (List<Subscription__c>)subscriptions){

            if(sub.Cases__r.size() == 0){
                Case insertCase = OutboundCallingBatchUtils.createCaseRecord(basicCaseRecord, sub, recordTypeId, ownerId);
                casesToInsert.add(insertCase); 
            }
        }

        if(!casesToInsert.isEmpty()){

            configRecord.Last_Execution_Error__c = false;

            List<Database.SaveResult> insertResults = Database.insert(casesToInsert, false);
            
            for(Integer i = 0; i < insertResults.size(); i++){
                if(!insertResults[i].success){
                    configRecord.Last_Execution_Error__c = true;

                    if(errorCount <= ERROR_LIMIT){
                        errorString += 'Failed to Insert Case, ' + String.valueOf(insertResults[i].errors) + '/n';
                        errorCount++;
                    }
                }
            }
        }
    }
    
    
    /***************************************************************************************
    Developer - Vishant Shah
    Date - 05/05/2017
    Version - 1.1
    Function - log errors in finish method against the batch record.
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        try {
            if(configRecord.Executions__c == null){
                configRecord.Executions__c = 1;
            } else {
                configRecord.Executions__c = configRecord.Executions__c + 1;
            }

            if(configRecord.Last_Execution_Error__c != null && configRecord.Last_Execution_Error__c) {
                configRecord.Batch_Job_Notifications__c = errorString;
            }
            
            update configRecord;
        } catch (Exception e) {
            throw new TelegraphApplicationException('OutboundCallingDDWinbackBatch error : ' + e.getMessage());
        }
    }
    
}