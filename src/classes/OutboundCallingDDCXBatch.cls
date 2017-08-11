/**
* Developer - Mantas Grigaliunas
* Date - 09/05/2017
* Description:  Batch to generate DD Cancellation cases from subscriptions.
*
* ******************* Change Log *******************
* Modified by  Change Date
**/

global class OutboundCallingDDCXBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public static final String BATCH_NAME   = OutboundCallingDDCXBatch.class.getName();
    public static final Integer ERROR_LIMIT = 20;

    public String errorString = '';

    private Outbound_Call_Batch_Setting__c configRecord;
    private Id recordTypeId;
    private Id indivSubRecordTypeId;
    private Id ownerId;
    private Set<String> statusToExclude;
    private Integer errorCount = 0;

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 05/05/2017
    Function - Constructor
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global OutboundCallingDDCXBatch() {
        indivSubRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());
        recordTypeId         = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DDCX_CASE_RECORD_TYPE_NAME, Case.class.getName());
        statusToExclude      = new Set<String>();
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 09/05/2017
    Function - Batch execution for Schedule. 
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global void execute(SchedulableContext schedulableContext){
        Database.executeBatch(new OutboundCallingDDCXBatch());
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 09/05/2017
    Function - Define scope for execute, get query from config record if scope set.
    #############Change Log#############
    Modified by     Change Date 
    ****************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {

        configRecord = OutboundCallingBatchUtils.fetchConfigRecord(BATCH_NAME);
        ownerId      = OutboundCallingBatchUtils.getQueueId(configRecord.Outbound_Call_Setting__r.Default_Queue_Name__c);

        for (Outbound_Calling_Configuration__mdt exclusionReasons : [SELECT Reason__c FROM Outbound_Calling_Configuration__mdt WHERE Project__c = :Constants.OC_DDCX_CASE_RECORD_TYPE_NAME]){
            statusToExclude.add(exclusionReasons.Reason__c);
        }

        if(configRecord.Scope__c != null) {
            return Database.getQueryLocator(configRecord.Scope__c);
        } else {

			Configuration__c appConfig = Configuration__c.getOrgDefaults();
        	Date fromDate = Date.today().addDays((Integer)appConfig.OC_DDCXBatch_Subscription_End_Date_From__c);
        	Date toDate   = Date.today().addDays((Integer)appConfig.OC_DDCXBatch_Subscription_End_Date_To__c);

            return Database.getQueryLocator([SELECT Id, Subscriber__c, Cancellation_Date__c, End_Date__c,
                                                    (SELECT Id FROM Cases__r WHERE RecordTypeId = :recordTypeId)
                                               FROM Subscription__c
                                              WHERE Subscriber__r.RecordTypeId = :indivSubRecordTypeId
                                                AND Subscriber__r.Subscription_Status__c = :Constants.SUBSCRIBER_INACTIVE_STATUS
                                                AND Subscriber__r.Test_Record__c != true
                                                AND Subscriber__r.IsDeleted != true
                                                AND isContinuous__c = true
                                                AND Payment_Type__c = :Constants.SUB_PMETHOD_DD
                                                AND Cancellation_Reason__c NOT IN :statusToExclude
                                                AND (Subscription_Status__c = :Constants.SUBSCRIPTION_CANCELLED_STATUS OR
                                                     Subscription_Status__c = :Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS)
                                                AND (Subscriber__r.Phone != null OR 
                                                     Subscriber__r.PersonMobilePhone != null OR 
                                                     Subscriber__r.PersonHomePhone != null)
                                                AND Cancellation_Date__c > :fromDate 
                                                AND Cancellation_Date__c < :toDate]);
        }
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 09/05/2017
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
                insertCase.DD_Cancellation_Outcome__c = Constants.CASE_STATUS_NOT_STARTED;
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
    Developer - Mantas Grigaliunas
    Date - 09/05/2017
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
            throw new TelegraphApplicationException('OutboundCallingDDCXBatch error : ' + e.getMessage());
        }
    }
}