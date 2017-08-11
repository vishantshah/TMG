/*
@author Gavin Palmer
@date 03/06/2016
@description Get all subscriptions that end today and add tasks to them
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk	 1.1		7/7/2016  - changed tasks to cases and added config record to set up data
Michal Szewczyk	 1.2		2/8/2016  - added record type selection in the batch
Pawel Chrzanowski 1.3       05/08/2016 //changed outstanding balance threshold to 30
Pawel Chrzanowski 1.4       24/01/2017 //added parameters to constructor
Pawel Chrzanowski 1.5       26/01/2017 //added partial success on Cases insert
Wiktor Czykin     1.6       04/04/2017 //modified so that parameters are re-initialized every time batch runs
*/
public class BalanceReviewBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public static final String BATCH_NAME = 'BalanceReviewBatch';
    public static final Integer DEFAULT_BALANCE_AMOUNT = 30;
    public static final Integer ERROR_CHAR_LIMIT = 131072;
    public String errorString = '';

    private Outbound_Call_Batch_Setting__c configRecord;
    private List<OutboundCallingBean.CallStageMapping> params;
    private Id recordTypeId;
    private Decimal customBalance;
    private Boolean isError = false;
    private Integer iOffset;
    /*
    @author Gavin Palmer
    @date 03/06/2016
    @description get the system user based on name in a custom setting
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk	 1.1		7/7/2016  - added config record
    Pawel Chrzanowski 1.2       24/01/2017 overloaded the constructor
    */
    public BalanceReviewBatch(){
        this(null, null);
    }

    /***************************************************************************************
    Author:       Pawel Chrzanowski
    Date:         24/01/2017
    Function      Constructor with parameters
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         04/04/2017  //moved date init to start
    ****************************************************************************************/
    public BalanceReviewBatch(Integer offset, Decimal balance){
        this.iOffset = offset;
        this.customBalance = (balance != null ? balance : DEFAULT_BALANCE_AMOUNT);
        this.recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME, Case.class.getName());
        this.configRecord = OutboundCallingBatchUtils.fetchConfigRecord(BATCH_NAME);
        this.params = OutboundCallingUtils.getCallStageParametersByOCsettingId(configRecord.Outbound_Call_Setting__c);
    }

    /*
    @author Gavin Palmer
    @date 03/06/2016
    @description get all subs that end today and have outstanding balance > 30
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk	 1.1		7/7/2016  - added config record to set up data
    Pawel Chrzanowski 1.2       05/08/2016 //changed outstanding balance threshold to 30
    Pawel Chrzanowski 1.3       24/01/2017 //added parameters
    Wiktor Czykin     1.4       04/04/2017 //added re-init
    */
    public Database.QueryLocator start(Database.BatchableContext batchContext){
        this.configRecord = OutboundCallingBatchUtils.fetchConfigRecord(BATCH_NAME);
        this.params = OutboundCallingUtils.getCallStageParametersByOCsettingId(configRecord.Outbound_Call_Setting__c);
        if(this.configRecord.Scope__c != null){
            return Database.getQueryLocator(this.configRecord.Scope__c);
        }else{
            Date customDate = (this.iOffset != null ? Date.today().addDays(this.iOffset) : Date.today());
            return Database.getQueryLocator([SELECT Name, Subscriber__r.Name, Subscriber__r.PersonContactId
                                                FROM Subscription__c
                                                WHERE End_Date__c = :customDate
                                                AND (Outstanding_Balance_to_from_Customer__c > :this.customBalance OR Outstanding_Balance_to_from_Customer__c < :this.customBalance*-1)]
                                                );
        }
    }

    /*
    @author Gavin Palmer
    @date 03/06/2016
    @description schedulable execute method
    #############Change Log#############
    Modified by     Version     Change Date
    */
    public void execute(SchedulableContext scheduleContext){
        Database.executeBatch(this);
    }

    /*
    @author Gavin Palmer
    @date 03/06/2016
    @description create the tasks for all the found subscriptions
    #############Change Log#############
    Modified by       Version   Change Date
    Michal Szewczyk	  1.1       07/07/2016  changed tasks to cases
    Pawel Chrzanowski 1.2       26/01/2017  added partial success on Cases insert
    */
   	public void execute(Database.BatchableContext batchContext, List<sObject> subscriptions){
        List<Case> casesToInsert = new List<Case>();
        try{
            Case templateCase = OutboundCallingBatchUtils.populateCaseValues(configRecord.Parameters__c);
            for(Subscription__c subscription : (List<Subscription__c>) subscriptions){
                Case tmpCase = templateCase.clone();
                tmpCase.OwnerId = OutboundCallingBatchUtils.getQueueId(configRecord.Outbound_Call_Setting__r.Default_Queue_Name__c);
                tmpCase.AccountId = subscription.Subscriber__c;
                tmpCase.Print_Subscription__c = subscription.Id;
                tmpCase.CreatedDate =  Datetime.now();
                tmpCase.RecordTypeId = recordTypeId;
                if(params != null && params.size() > 0) {
                    tmpCase.OC_Call_Stage__c = params[0].stagename;
                    tmpCase.put(params[0].calldatetime, Datetime.now().addDays(params[0].offset));
                }
                casesToInsert.add(tmpCase);
            }
            if(!casesToInsert.isEmpty()){
                Database.SaveResult[] lstResults = Database.insert(casesToInsert, false);
                for(Integer i=0; i<lstResults.size(); i++){
                    if(!lstResults[i].isSuccess()){
                        isError = true;
                        for(Database.Error er : lstResults[i].getErrors()){
                            System.debug('The following error has occurred. ' + er.getStatusCode() + ': ' + er.getMessage());
                            errorString += er.getMessage() + '. ';
                        }
                    }
                }
            }
        }catch(Exception e){
            isError = true;
            errorString += e.getMessage() + '. ';
        }
    }

    /*
    @author Michal Szewczyk
    @date 07/2016
    @description finish method
    #############Change Log#############
    Modified by       Version   Change Date
    Pawel Chrzanowski 1.2       26/01/2017  added error handling
    */
    public void finish(Database.BatchableContext batchContext){
        try{
            if(configRecord.Executions__c == null){
                configRecord.Executions__c = 1;
            }else{
                configRecord.Executions__c = configRecord.Executions__c + 1;
            }

            //log errors
            if(isError){
                errorString = (errorString.length() > ERROR_CHAR_LIMIT ? errorString.substring(0, ERROR_CHAR_LIMIT) : errorString);
                configRecord.Batch_Job_Notifications__c = errorString;
                configRecord.Last_Execution_Error__c = true;
            }else{
                configRecord.Last_Execution_Error__c = false;
            }
            update configRecord;
        }catch(Exception e){
            throw new TelegraphApplicationException('BalanceReviewBatch error: ' + e.getMessage());
        }
    }
}
