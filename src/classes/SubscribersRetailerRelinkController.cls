/**
* @author Wiktor Czykin(Tquila)
* @date 16/02/2015
* @description Controller for SubscribersRetailerRelink
#############Change Log############# 
Modified by     Version     Change Date
Wiktor Czykin	1.1 		18/02/2015	//added SSTATUS_OFFERED and SSTATUS_PENDING as active statuses
**/
public with sharing class SubscribersRetailerRelinkController {

	private Account acc{get;set;}
	
	public Subscription__c subscription{get;set;}
	public Integer iCurrentCount{get;set;}
	public Id retailerRecordTypeId{get;set;}
	public List<String> lstUpdateErrors{get;set;}
	public Boolean bSuccess{get;set;}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/02/2015
    Version - 1.0
    Function - constructor - initialises stuff
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
	public SubscribersRetailerRelinkController(ApexPages.StandardController std) {
		this.acc = (Account)std.getRecord();
		this.subscription = new Subscription__c();

		if(this.acc.Id == null) return;

		this.bSuccess = false;
		this.retailerRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_ACCOUNT_RETAILER, Account.class.getName()); 
		this.resetRecordsCount();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/02/2015
    Version - 1.0
    Function - sets active subcriptions count against retailer
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
	@TestVisible private void resetRecordsCount(){
		this.iCurrentCount = [select count() 	from Subscription__c 
												where Retailer__c =:this.acc.Id 
												and (	Subscription_Status__c = :Constants.SSTATUS_ACTIVE or 
														Subscription_Status__c = :Constants.SSTATUS_IN_RENEWAL or
														Subscription_Status__c = :Constants.SSTATUS_OFFERED or
														Subscription_Status__c = :Constants.SSTATUS_PENDING or
														(Subscription_Status__c = :Constants.SSTATUS_PENDING_CANX and Cancellation_Date__c >:Date.today())
													)];
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 16/02/2015
    Version - 1.0
    Function - relinking logic 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
	public void relinkSubscribers(){
		List<Subscription__c> lstSubscriptionsToUpdate = new List<Subscription__c>();
		this.lstUpdateErrors = new List<String>();
		this.bSuccess = false;

		if(this.subscription.Retailer__c == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Retailer_Target_not_specified));
			return;
		}
		if(this.subscription.Retailer__c == this.acc.Id){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Retailer_Target_has_to_be_different));
			return;
		}


		for(Subscription__c sub : [select Id 	from Subscription__c 
												where Retailer__c =:this.acc.Id 
												and (	Subscription_Status__c = :Constants.SSTATUS_ACTIVE or 
														Subscription_Status__c = :Constants.SSTATUS_IN_RENEWAL or
														Subscription_Status__c = :Constants.SSTATUS_OFFERED or
														Subscription_Status__c = :Constants.SSTATUS_PENDING or
														(Subscription_Status__c = :Constants.SSTATUS_PENDING_CANX and Cancellation_Date__c >:Date.today())
													)]){
			lstSubscriptionsToUpdate.add(new Subscription__c(Id = sub.Id, Retailer__c = this.subscription.Retailer__c));
		}

		if(!lstSubscriptionsToUpdate.isEmpty()){
			Savepoint sp = Database.setSavepoint();
			try{
				//all or nothing approach unless told otherwise
				update lstSubscriptionsToUpdate;
				this.bSuccess = true;
				this.resetRecordsCount();
			}catch(DmlException e){
				ApexPages.addMessages(e);
				Database.rollback(sp);
			}
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Label.Retailer_Nothing_to_relink));
		}
	}
}