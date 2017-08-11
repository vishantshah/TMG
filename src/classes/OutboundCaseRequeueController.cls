/**
* @author Michal Szewczyk
* @date 05/09/2016
* @description Controller for OutboundCaseRequeue page
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk	1.1			6/10/2016 - changed recalculateQueue()
**/
public with sharing class OutboundCaseRequeueController {
	
	private final Outbound_Call_Setting__c  outboundSetting;
	private String[] statusSelections = new String[]{};
	private String[] stageSelections = new String[]{};
	private String recTypeName;
	private String recTypeId;
	private String retUrl;

	public Boolean buttonClicked {get;set;}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Constructor for OutboundCaseRequeue page
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public OutboundCaseRequeueController(ApexPages.StandardController stdController) {
		this.outboundSetting = (Outbound_Call_Setting__c) stdController.getRecord();
		recTypeName = Apexpages.currentpage().getparameters().get('recTypeName');
		retUrl = Apexpages.currentpage().getparameters().get('retURL');
		recTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType,recTypeName,Case.class.getName());
		buttonClicked = false;

	}

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Getter for Case Outcome Status
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public List<SelectOption> getCallStatus(){
		List<SelectOption> options = new List<SelectOption>();

		options.add(new SelectOption(Constants.CASE_OUTCOME_ANSWERPHONE,Constants.CASE_OUTCOME_ANSWERPHONE));
		options.add(new SelectOption(Constants.CASE_OUTCOME_NOANSWER,Constants.CASE_OUTCOME_NOANSWER));
		options.add(new SelectOption(Constants.TOUTCOME_BUSY,Constants.TOUTCOME_BUSY));

		return options;
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Getter for Case Stage option
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public List<SelectOption> getCaseStage(){
		List<SelectOption> options = new List<SelectOption>();

		OutboundCallingUtils.defineOutboundCallSettingParameters();
        List<OutboundCallingBean.CallStageMapping> thisParamList = OutboundCallingUtils.getCallStageParametersByRecordTypeId(recTypeId);
		
		for(OutboundCallingBean.CallStageMapping thisParam : thisParamList){
			options.add(new SelectOption(thisParam.stagename,thisParam.stagename));
        }

		return options;
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Setter for Case Outcome Status
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public void setStatusSelections(String[] selections){
		this.statusSelections = selections;
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Setter for Case Stage options
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public void setStageSelections(String[] selections){
		this.stageSelections = selections;
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Getter for Case Outcome
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public String[] getStatusSelections(){
		return statusSelections;
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Getter for Case Stage options
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public String[] getStageSelections(){
		return stageSelections;
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 05/09/2016
    Version - 1.0
    Function - Button logic that runs batch job
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1			6/10/2106 - changed return value
    ****************************************************************************************/
	public PageReference recalculateQueue () {
		try{
			OutboundCaseRequeueBatch batchWork = new OutboundCaseRequeueBatch(statusSelections,stageSelections,recTypeName);
			Id batchJobId = Database.executeBatch(batchWork, 200);
			buttonClicked = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.OC_Batch_Requeue_Submit_Msg));
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
		}
		return new PageReference(retUrl);
	}
}