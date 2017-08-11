/************************************************************************************
Class Name   : LatestSubscriptionController
Author       : Mantas Grigaliunas
Created Date : 07/06/2017
Function     : LatestSubscription component controller class
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Vishant Shah 10/08/2017	Added orderMethod pagereference param SUB-7482
* Vishant Shah 11/08/2017	added subscription origin.
* Vishant Shah 11/08/2017	added input for price & defaulted to product from old sub
*************************************************************************************/
public class LatestSubscriptionController {

	public String newSubscriptionUrl  { get; set; }
	public String tCodeName			  { get; set; }
	public String newSubscriptionType { get; set; }
	public String productId			  { get; set; }
	public Decimal weeklyPrice 		  { get; set; }
	public Boolean windowOpen		  { get; set; }

	public Case thisCase { get; set {
			if((value != null && this.thisCase == null) || (value != null && value != this.thisCase) ){
	            this.thisCase = value;	
	            newSubscriptionType = null;
	        }
		}
	}

	public LatestSubscriptionController(){}

	/************************************************************************************
	Method Name  : createNewSubscription
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Function     : Method to generate redirect url based on specified subscription type
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer     Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Vishant Shah  29/06/2017	 Removed PARAM_PRODUCTID parameter, so acquistion page uses the default product set in the org.
	* Vishant Shah	10/08/2017	 Added orderMethod ticket SUB-7482
	* Vishant Shah  11/08/2017	 added subscription origin.
	* Vishant Shah  11/08/2017	 added input for price & defaulted to product from old sub
	*************************************************************************************/
   	public void createNewSubscription(){
		
		try{	
			Id caseRecordId = (thisCase != null ? thisCase.Id : ApexPages.currentPage().getParameters().get('id'));
			Case caseRecord = getCaseRecord(caseRecordId);
			if(thisCase != null)  thisCase.Print_Subscription__c = null;
			if(tCodeName == null) tCodeName = getTCodeName();

			if(caseRecord != null){

			    if(newSubscriptionType == Constants.PRODUCT_PRINT){

			    	if (weeklyPrice == null || weeklyPrice == 0){
						ApexPages.addMessage(new ApexPages.Message(Constants.FATAL, 'Please enter a Weekly Price for the new Print Subscription.'));
						windowOpen = false;
			    	} else {
			    		ApexPages.getMessages().clear();
						windowOpen = true;
			    		
			    		PageReference pr = Page.OapSubscriptionTMG;
				        pr.getParameters().put(Constants.PARAM_AGENCYID, Constants.AGENT_TMG);
				        pr.getParameters().put(Constants.PARAM_AGENT_USERID, UserInfo.getUserId());
				        pr.getParameters().put(Constants.PARAM_ORDER_METHOD, Constants.SUB_ORDER_METHOD_INBOUND);
				        pr.getParameters().put(Constants.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
				        pr.getParameters().put(Constants.PARAM_SELECTED_PRODUCT, Constants.PRODUCT_PREMIUM);
				        pr.getParameters().put(Constants.TCODE_FILTER_PARAM, tCodeName);
				        pr.getParameters().put(Constants.MPP_PARAMETER_TSNUMBER, caseRecord.Account.Subscriber_Number__c);
				        pr.getParameters().put('isOCDDCX', 'true');
				        pr.getParameters().put('orderMethod', 'Outbound');
				        pr.getParameters().put('weeklyPrice', String.valueOf(weeklyPrice));
				        pr.getParameters().put('productId', productId);
			        	pr.getParameters().put('forcedPrice', String.valueOf(weeklyPrice));

				        newSubscriptionUrl = pr.getUrl();
			    	}
			    } else if(newSubscriptionType == Constants.PRODUCT_DIGITAL){
			        PageReference pr = Page.Account_ConvertToRegistrant;
			        pr.getParameters().put('Id', caseRecord.AccountId);
			        pr.getParameters().put('origin', 'Outbound');
			        newSubscriptionUrl = pr.getUrl();
			    }
			} else {
				ApexPages.addMessage(new ApexPages.Message(Constants.FATAL, Label.Latest_Subscription_Case_Not_Found_Error));
			}
		}catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(Constants.FATAL, e.getMessage()));
		}
	}

	/************************************************************************************
	Method Name  : getCaseRecord
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Function     : Method to get specific Case record 
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
   	private Case getCaseRecord(Id caseId){
   		List<Case> caseLst = [ SELECT Id, Print_Subscription__r.Product__c, Account.Subscriber_Number__c, AccountId FROM Case WHERE Id = :caseId ];
   		return (caseLst.size() > 0 ? caseLst[0] : null);
   	}

	/************************************************************************************
	Method Name  : getTCodeName
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Function     : Method to generate redirect url based on specified subscription type
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
   	private String getTCodeName(){

   		Map<Outbound_Call_Setting__c, OutboundCallingBean.CallStageMapping> ocSettingMap = OutboundCallingUtils.getOutboundCallSetting(Constants.OC_DDCX_VF_PAGE_NAME);
        if(ocSettingMap != null){
            OutboundCallingBean.CallStageMapping param = ocSettingMap.values().get(0);
            return param.tCode;
        } else return null;
   	}
}