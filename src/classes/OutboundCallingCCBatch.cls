/**
* Author:       Michal Szewczyk
* Date:			22/07/2016
* Description:  Get all accounts with CC Expiry Date ends next month and create cases for them
*
* ******************* Change Log *******************
* Modified by       Change Date
**/
public class OutboundCallingCCBatch implements Database.Batchable<sObject>,Database.Stateful, Schedulable  {

	public static String BATCH_NAME = 'OutboundCallingCCBatch';
	public String errorString = '';

	private Outbound_Call_Batch_Setting__c configRecord;
	private List<OutboundCallingBean.CallStageMapping> params;
	private Id recordTypeId;

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - batch class constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public OutboundCallingCCBatch(){
   		configRecord = OutboundCallingBatchUtils.fetchConfigRecord(BATCH_NAME);
   		params = OutboundCallingUtils.getCallStageParametersByOCsettingId(configRecord.Outbound_Call_Setting__c);
   		recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME, Case.class.getName());
	}

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - start method of batch - scope definition
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Integer timeframe = 0;

		if(params.size() >0 && params[0].offset != null) {
			timeframe = params[0].offset;
		}

		if(configRecord.Scope__c != null) {
			return Database.getQueryLocator(configRecord.Scope__c);
		}else {
			return Database.getQueryLocator('SELECT Id, Subscriber_Number_Static__c, Credit_Card_Expiry_Date__c, (SELECT Id,CreatedDate FROM Cases WHERE RecordTypeId =\'' + recordTypeId + '\') FROM Account WHERE Credit_Card_Expiry_Date__c != null	AND Credit_Card_Expiry_Date__c = NEXT_N_MONTHS:' + timeframe);
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
		Database.executeBatch(new OutboundCallingCCBatch());
	}
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - batch logic that takes accounts with Credit_Card_Expiry_Date set for specific month and creates cases for them
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
   	public void execute(Database.BatchableContext batchContext, List<sObject> accounts) {
   		List<Case> caseToInsert = new List<Case>();

   		try{
   			Case templateCase = OutboundCallingBatchUtils.populateCaseValues(configRecord.Parameters__c);
			for(Account acc : (List<Account>) accounts){
				if(acc.Cases.size() > 0  && acc.Cases[0].CreatedDate.month() == Date.today().month()) {
					continue;
				}
				Case tmpCase = templateCase.clone();
				tmpCase.OwnerId = OutboundCallingBatchUtils.getQueueId(configRecord.Outbound_Call_Setting__r.Default_Queue_Name__c);
				tmpCase.AccountId = acc.Id;
				tmpCase.CreatedDate =  Datetime.now();
				tmpCase.RecordTypeId = recordTypeId;
				if(params != null && params.size() > 0) {
					tmpCase.OC_Call_Stage__c = params[0].stagename;
					tmpCase.put(params[0].calldatetime, Datetime.now().addDays(params[0].offset));
				}

				caseToInsert.add(tmpCase);
			}
			insert caseToInsert;
			configRecord.Last_Execution_Error__c = false;

		} catch (Exception e) {
			errorString += e.getMessage() + '/n';
			configRecord.Last_Execution_Error__c = true;
		}
	}

    /**
	* @author Michal Szewczyk
	* @date 07/2016
	* @description required finish method, no implimentation yet...
	*#############Change Log#############
	*Modified by     Version     Change Date
	**/
	public void finish(Database.BatchableContext batchContext) {
		try {
            if(configRecord.Executions__c == null){
                configRecord.Executions__c = 1;
            }else{
                configRecord.Executions__c = configRecord.Executions__c + 1;
            }
			if(configRecord.Last_Execution_Error__c) {
				configRecord.Batch_Job_Notifications__c = errorString;
			}
			update configRecord;

		} catch (Exception e) {
            throw new TelegraphApplicationException('OutboundCallingCCBatch error : ' + e.getMessage());
		}
	}

}
