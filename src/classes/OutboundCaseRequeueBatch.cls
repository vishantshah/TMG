/**
* @author Michal Szewczyk
* @date 07/09/2016
* @description  Batch class for processing Cases to change Scheduled Callback date
*#############Change Log#############
* Modified by        Change Date
* Michal Szewczyk    6/10/2016   - changed execute() 
* Vishant Shah       09/06/2017  - added DDWinback and DDCX fields to query
**/
global class OutboundCaseRequeueBatch implements Database.Batchable<sObject> {
	
	private final List<String> queryStatusParams;
	private final List<String> queryStageParams;
	private final String caseRecTypeId;
	
	/***************************************************************************************
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Batch class constructor with params
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
	global OutboundCaseRequeueBatch(List<String> statuses,List<String> stages,String buttonSource) {
		queryStatusParams = statuses;
		queryStageParams  = stages; 	

		if(queryStatusParams.isEmpty()) {
			throw new TMGUtil.GenericException('Outcome status was not selected. Please select at least one');
		}

		if(queryStageParams.isEmpty()) {
			throw new TMGUtil.GenericException('Case stage was not selected. Please select at least one');
		}

		caseRecTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType,buttonSource, Case.class.getName());
		
		if (caseRecTypeId==null || caseRecTypeId ==''){
			throw new TMGUtil.GenericException('buttonSource is not valid');
		}
	}
	
	/***************************************************************************************
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - start method of batch - scope definition
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
	global Database.QueryLocator start(Database.BatchableContext BC) {

		return Database.getQueryLocator([SELECT Id,OC_Outcome__c,OC_Scheduled_Callback__c,
												OC_Stage_1_Call_Date_Time__c,OC_Stage_2_Call_Date_Time__c,
												OC_Stage_2_No_Sale_Reason__c,OC_Stage_2_Outcome__c,
												OC_Stage_1_No_Sale_Reason__c,OC_Stage_1_Outcome__c,
												OC_Stage_3_Call_Date_Time__c,OC_Stage_3_No_Sale_Reason__c,
												OC_Stage_3_Outcome__c,OC_Stage_4_Call_Date_Time__c,
												OC_Stage_4_No_Sale_Reason__c,OC_Stage_4_Outcome__c,
												OC_Stage_6_Call_Date_Time__c,OC_Stage_6_Outcome__c,
												OC_Stage_5_Call_Date_Time__c,OC_Stage_5_Outcome__c,
												OC_Call_Stage__c,RecordTypeId,DD_Winback_Call_Date_Time__c,
                                                DD_Cancellation_Call_Date_Time__c
										 FROM Case 
										 WHERE RecordTypeId =:caseRecTypeId 
										 AND OC_Outcome__c IN :queryStatusParams
										 AND OC_Call_Stage__c IN :queryStageParams]);
	}
    
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - batch execution logic
    #############Change Log#############
    Modified by     Change Date
    Michal Szewczyk 1.1         6/10/2016 - clear OC_Scheduled_Callback__c field
    ****************************************************************************************/
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Case> casesForUpdate = new List<Case>();

		OutboundCallingUtils.defineOutboundCallSettingParameters();
        for(Case thisCase : (List<Case>) scope){
            List<OutboundCallingBean.CallStageMapping> thisParamList = OutboundCallingUtils.getCallStageParametersByRecordTypeId(thisCase.RecordTypeId);
            for(OutboundCallingBean.CallStageMapping thisParam : thisParamList){

                if(thisParam.stagename.equals(thisCase.OC_Call_Stage__c) && (Datetime) thisCase.get(thisParam.calldatetime) > Datetime.now()) {
                    thisCase.put(thisParam.calldatetime, Datetime.now());
                    thisCase.OC_Scheduled_Callback__c = null;
                    casesForUpdate.add(thisCase);
                }
            }
        }

	    try{
	          Database.update(casesForUpdate,false);
    	} catch (Exception e){
    		
    	}
	}
	
	/***************************************************************************************
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - finish method of the batch
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
	global void finish(Database.BatchableContext BC) {
		
        String mailBody = Label.OC_Batch_Requeue_Body_Msg;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(Label.OC_Batch_Requeue_Subject);
        email.setTargetObjectId(System.UserInfo.getUserId());
        email.setHTMLBody(mailBody);
        email.setSaveAsActivity(false);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        }
	}
	
}