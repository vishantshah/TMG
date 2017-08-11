/**
* @author Wiktor Czykin
* @date 27/10/2015
* @description Controller for low start subscription button - subscription restart - the only way to modify the start date
#############Change Log#############
Modified by     Version     Change Date
**/
public with sharing class LowStartSubscriptionRestartController {
	
	@TestVisible private Boolean bTestFail = false;
	@TestVisible private Subscription__c subscription{get;set;}
	public Subscription__c subscriptionTemp{get;set;}
	public Boolean bPastSubscriptionWarning{get;set;}
	public String sError{get;set;}
	public Boolean bChangeOffer{get;set;}
	public Boolean bShowFeature{get;set;}
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 27/10/2015
    Version - 1.0
    Function - Constructor - just fetch the record 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public LowStartSubscriptionRestartController(ApexPages.StandardController ctrl){
		Id subscriptionId = ctrl.getId();
		if(subscriptionId == null) throw new TelegraphApplicationException(Label.Low_Start_Restart_feature_missing_subscription_id);
		this.subscriptionTemp = new Subscription__c();
		this.bChangeOffer = false;
		this.bPastSubscriptionWarning = false;
		this.bShowFeature = true;
		Set<String> setExtraFields = new Set<String>{	'TCode__r.Name',
														'Retailer__r.RET_ID__c',
														'Subscriber__r.Subscriber_Number__c'};
		String sQuery = 'select ' + GlobalQueries.generateFieldsListForQuery(Subscription__c.class.getName(), setExtraFields, null) + ' from Subscription__c where Id =:subscriptionId';
		List<Subscription__c> lstSubscription = Database.query(sQuery);
		if(lstSubscription.isEmpty()) throw new TelegraphApplicationException(Label.Low_Start_Restart_feature_no_subscription_based_on_id);
		
		this.subscription = lstSubscription[0];
		//hacky way to validate extraction date - without code duplication. Basically we are simulating attempt to change the start date. If it turn out that 
		Subscription__c cloneToValidate = this.subscription.clone(true, true);
		cloneToValidate.Start_Date__c = Date.today().addYears(-10);
		SubscriptionTriggerHandler.getInstance().startDateValidation(new List<Subscription__c>{cloneToValidate}, new Map<Id, Subscription__c>{this.subscription.Id => this.subscription});
		if(ApexPages.hasMessages()){
			bPastSubscriptionWarning = true;
		}
		
		if(RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()) != this.subscription.RecordTypeId 
		|| this.subscription.Subscription_Status__c != Constants.SSTATUS_PENDING 
		|| !this.subscription.isContinuous__c 
		|| this.subscription.Previous_Subscription__c != null){
			this.bShowFeature = false;
			this.sError = Label.Low_Start_Feature_validation_required_status;
			
		}else if(String.isBlank(this.subscription.MPP_Premium_Subscription_ID__c)){
			this.bShowFeature = false;
			this.sError = Label.Low_Start_Feature_validation_MPP_Subscription_Id_mandatory;
		}
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 27/10/2015
    Version - 1.0
    Function - method that does the actual redirection
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public PageReference processRestart(){
		PageReference pr = null;
		try{
			MPPInterfaceHTTP mppInterface = new MPPInterfaceHTTP();
			mppInterface.cancelPaymentSchedule(this.subscription.MPP_Premium_Subscription_ID__c);
		}catch(Exception e){
			this.sError = Label.Low_Start_Restart_feature_MPP_call_failure +' '+ e.getMessage();
			return pr;
		}
		
		Savepoint sp = Database.setSavepoint();
		try{
			this.subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			update this.subscription;
				
			//fetch subscription incentives records and delete them afterwars
			List<SubscriptionIncentiveAssociation__c> lstSubscriptionIncentives = [select Id, Incentive__c from SubscriptionIncentiveAssociation__c where Subscription__c =:this.subscription.Id];
			Id incentiveId = null;
			if(!lstSubscriptionIncentives.isEmpty()){
				incentiveId = lstSubscriptionIncentives[0].Incentive__c;
			}
			delete lstSubscriptionIncentives;
			
			String sPaymentMethod = Constants.SUB_ACQUISITION_PAYMENT_DD;
			if(this.subscription.Payment_Type__c == Constants.SUB_PMETHOD_CC){
				sPaymentMethod = Constants.SUB_ACQUISITION_PAYMENT_CC;
			}
			//build url parameters
			pr = Page.OapSubscriptionTMG;
			Map<String, String> mapParams = pr.getParameters();
			mapParams.put('restart', 'true');
			mapParams.put('hasBack', 'true');
			mapParams.put('subscriptionType', this.subscription.Subscription_Duration_Number__c + Constants.KEY_CONTINUOUS);
			mapParams.put('tcode', this.subscription.TCode__r.Name);
			if(this.bChangeOffer && this.subscriptionTemp != null && this.subscriptionTemp.Low_Start_Amendment_TCode_Helper__c != null){
				List<TCodeManagement__c> lstTCode = [select Id, Name from TCodeManagement__c where Id = :this.subscriptionTemp.Low_Start_Amendment_TCode_Helper__c];
				if(!lstTCode.isEmpty()){
					mapParams.put('tcode', lstTCode[0].Name);
				}
			}
			mapParams.put('orderMethod', String.isBlank(this.subscription.Order_Taken_Method__c)?Constants.DIRECTION_INBOUND:this.subscription.Order_Taken_Method__c);
			mapParams.put('selectedOffer', Constants.OFFER_LOWSTART);
			mapParams.put('selectedProduct', Constants.PRODUCT_PREMIUM);
			mapParams.put('tsnumber', this.subscription.Subscriber__r.Subscriber_Number__c);
			mapParams.put('paymentType', sPaymentMethod);
			mapParams.put('paymentFrequency', (sPaymentMethod == Constants.SUB_ACQUISITION_PAYMENT_DD?this.subscription.MPP_DD_Frequency__c:this.subscription.MPP_CC_Frequency__c));
			mapParams.put('paymentStartDate', this.subscription.PaymentDate__c);
			if(this.subscription.Retailer__c != null){
				mapParams.put('retailerid', this.subscription.Retailer__r.RET_ID__c);
			}
			if(incentiveId != null){
				mapParams.put('incentiveId', incentiveId);
			}
			if(bTestFail && Test.isRunningTest()){
				throw new TelegraphApplicationException('test fail');
			}
		}catch(Exception e){
			Database.rollback(sp);
			this.sError = Label.Low_Start_Restart_feature_MPP_call_failure + ' ' + e.getMessage();
			pr = null;
		}
		return pr;
	}
}