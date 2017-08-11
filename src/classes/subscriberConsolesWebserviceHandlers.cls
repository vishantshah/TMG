/**
* @author Unknown
* @date Unknown
* @description helper class for subscriberConsole
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         28/05/2015  //removed retrieveUserOrderHistoryResultForMppGuid as not used anywhere
Cristina Popescu1.2			24.06.2015	//update entitlement messages based on salesforce subscriber_status__c and Sam status
Wiktor Czykin	1.3			15/07/2015	//update to checkEntitlementsForPrintSub()
Cristina Anghenie1.4		28/07/2015	//prevent diagnostic console fail to display results if mpp order history are not in sync with salesforce
Cristina Anghenie1.5  		29/07/2015  //prevent diagnostic console fail to display results if sam entitlement for digital account are null
**/
global class subscriberConsolesWebserviceHandlers {

	/**     
	--------------------------
	-   WEBSERVICE METHODS   -
	--------------------------   
	**/    

    global class subscriberRuleLog { 
		webservice String ruleCode {get;set;} //rule identifier - can have multiple log entries per ruleCode	
		webservice String ruleResultCode {get;set;}	//the number value that shows which result of the rule was achieved	
	    webservice String ruleUserMessage {get;set;}
	    webservice String ruleData {get;set;}
	    webservice String ruleGroup {get;set;}
	    webservice String ruleName {get;set;}
	}
	
	public class orderTotals{ 
		public Integer overallPriceTotal;
		public Integer countOfOrders;
	}

	public class orderComparisonResult{
		public MPPInterfaceHTTP.OrderHistoryItem[] mppOrders;
		public List<MPP_Transaction_History__c> sfOrders;
		public String matchStatus;
	}
	

    public static List<MPP_Transaction_History__c> retrievesfOrderInformationByAccountID(String id)
    {
   	    List<MPP_Transaction_History__c> sfOrderInformation = [SELECT Id, Total_Price__c, Order_Id__c, Sale_Type__c, Payment_Date__c, Digital_Subscription_ID__c, Premium_Subscription_ID__c, Name, DD_Transaction_Type__c, Payment_Status__c, Payment_Type__c from MPP_Transaction_History__c where Subscriber__c = :id];
		return sfOrderInformation;
    }

    public static Account retrieveSfAccountInformationForTSNumber(String tsNumber)
    {
   	    Account sfAccountInformation = [SELECT Id, Subscriber_Number_Static__c, Subscription_Status__c, Subscriber_Digital_Status__c, RecordTypeId, PersonEmail, Guid__c, Digital_Product_Type__c from Account where Subscriber_Number_Static__c = :tsNumber];
		return sfAccountInformation;
    }
    
    public static MppInterfaceHTTP.UserServicesResult retrieveUserServicesResultForTSNumberAndDoNotLogWebserviceCall(String tsNumber)
    {
    	MppInterfaceHTTP mppCallout = new MppInterfaceHTTP();
		MppInterfaceHTTP.UserServicesResult userServicesRes = mppCallout.getUserServices(tsNumber, FALSE);
		
		return userServicesRes;
    }

    public static MppInterfaceHTTP.UserInfoResult retrieveUserInfoResultForTSNumberAndDoNotLogWebserviceCall(String tsNumber)
    {
    	MppInterfaceHTTP mppCallout = new MppInterfaceHTTP();
		MppInterfaceHTTP.UserInfoResult userInfoRes = mppCallout.callUserInfoByTSNumber(tsNumber);
		return userInfoRes;
    }  
    
    public static MppInterfaceHTTP.UserInfoResult retrieveUserInfoResultForEmailAndDoNotLogWebserviceCall(String email)
    { 
    	MppInterfaceHTTP mppCallout = new MppInterfaceHTTP();
		MppInterfaceHTTP.UserInfoResult userInfoRes = mppCallout.callUserInfoByEmail(email); 
	 
		return userInfoRes;
    }       
    
    /*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.0
	Function -  
	#############Change Log#############
	Cristina Anghenie 	1.1  	22/07/2015  //return subscriberRuleLog only if there is entitlement in sam otherwise return null
	****************************************************************************************/ 
    public static List<subscriberRuleLog> checkEntitlementsForDigitalSub(SAMUtil.SAMAccountResult samAccountAndEntitlementInfo, Account sfAccountInformation, subscriberRuleLog[] subscriberRuleLog)
    {
		string currentRule = 'samEntitlementMatch';   // this rule will check if MPP is storing a TS Number and GUID for the subscriber (it should always)
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c && samAccountAndEntitlementInfo.Entitlements != null)	 // check if the rule is active, before running it
		{   
			string currentRuleResult;
	    	List<Entitlements__c> entitlementList = [Select Active_Entitlement_Value__c, Inactive_Entitlement_Value__c, InRenewal_Entitlement_Value__c, Pending_Entitlement_value__c, Recently_Inactive_Entitlement_Value__c from Entitlements__c];
	    	for (Entitlements__c thisEntitlement : entitlementList)
	    	{
		    	for (String samEntitlement : samAccountAndEntitlementInfo.Entitlements)
		    	{
			    	if ((samEntitlement == thisEntitlement.Active_Entitlement_Value__c && sfAccountInformation.Subscriber_Digital_Status__c == 'Active') || (samEntitlement == thisEntitlement.Inactive_Entitlement_Value__c && sfAccountInformation.Subscriber_Digital_Status__c == 'Inactive'))
			    	{	currentRuleResult = '100'; // OK - SAM Entitlement is correct given the Salesforce Digital Status
			    		subscriberRuleLog = logNewSubscriberRuleWithData(subscriberRuleLog, currentRule, currentRuleResult,JSON.serialize('SAM Entitlement: ' + samEntitlement + 'SF Digital Status: ' + sfAccountInformation.Subscriber_Digital_Status__c)); 
			    	}
			    	if ((samEntitlement == thisEntitlement.Active_Entitlement_Value__c && sfAccountInformation.Subscriber_Digital_Status__c != 'Active') || (samEntitlement == thisEntitlement.Inactive_Entitlement_Value__c && sfAccountInformation.Subscriber_Digital_Status__c != 'Inactive'))
		    		{	currentRuleResult = '500'; // error - SAM Entitlement is incorrect given the Salesforce Digital Status
			    		subscriberRuleLog = logNewSubscriberRuleWithData(subscriberRuleLog, currentRule, currentRuleResult,JSON.serialize('SAM Entitlement: ' + samEntitlement + 'SF Digital Status: ' + sfAccountInformation.Subscriber_Digital_Status__c)); 	
		    		}
		    	}
	    	}
		}
		return subscriberRuleLog;
    }  
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.2
	Function -  
	#############Change Log#############
	Cristina Popescu 	1.1  	24/06/2015  //fixed messages returned, re-arranged code a bit, added constants
	Wiktor Czykin		1.2		15/07/2015	//replaced 300 with 800 so that X is shown rather then tick on vf page - replaced with constants
	Cristina Anghenie 	1.3  	29/07/2015  //return subscriberRuleLog only if there is entitlement in sam otherwise return null
	Cristina Anghenie 	1.4  	30/07/2015  //check if entitlements are null instead of empty since empty is making the code fail
	****************************************************************************************/
    public static List<subscriberRuleLog> checkEntitlementsForPrintSub(SAMUtil.SAMAccountResult samAccountAndEntitlementInfo, Account sfAccountInformation, subscriberRuleLog[] subscriberRuleLog){
    	List<Subscription__c> subscriptionDetails = [SELECT Previous_Subscription__c, Subscription_Status__c,Previous_Subscription__r.Subscription_Status__c 
													 FROM Subscription__c
													 WHERE Subscriber__c =: sfAccountInformation.Id
													 AND Subscription_Status__c =: Constants.SSTATUS_OFFERED
													 AND Previous_Subscription__c != null 
													 AND Previous_Subscription__r.Subscription_Status__c =: Constants.SSTATUS_LAPSED limit 1];
		String currentRule = 'samEntitlementMatch';   // this rule will check if MPP is storing a TS Number and GUID for the subscriber (it should always)
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c && samAccountAndEntitlementInfo.Entitlements!=null){	 // check if the rule is active and there are entitlements in sam, before running it
			   	
	    	List<Entitlements__c> entitlementList = [Select Active_Entitlement_Value__c, Inactive_Entitlement_Value__c, InRenewal_Entitlement_Value__c, Pending_Entitlement_value__c, Recently_Inactive_Entitlement_Value__c from Entitlements__c];
	    	for (Entitlements__c thisEntitlement : entitlementList){
		    	for (String samEntitlement : samAccountAndEntitlementInfo.Entitlements){     		
			    	String sCurrentRuleResult = null;
			    	if ((sfAccountInformation.Subscription_Status__c == Constants.SSTATUS_ACTIVE && (samEntitlement == thisEntitlement.Active_Entitlement_Value__c || 
			    																	 				 samEntitlement == thisEntitlement.InRenewal_Entitlement_Value__c)) || 
			    	   (sfAccountInformation.Subscription_Status__c == Constants.SSTATUS_INACTIVE && ((samEntitlement == thisEntitlement.Inactive_Entitlement_Value__c && subscriptionDetails.isEmpty())|| 
			    	   																  				  (samEntitlement == thisEntitlement.Recently_Inactive_Entitlement_Value__c && subscriptionDetails.size()>0))) || 
			    	   (sfAccountInformation.Subscription_Status__c == Constants.SSTATUS_PENDING && (samEntitlement == thisEntitlement.Pending_Entitlement_value__c || 
			    	   																 				 samEntitlement == thisEntitlement.Active_Entitlement_Value__c))){
		    			
		    			sCurrentRuleResult = Constants.SAM_ENT_RULE_OK; // OK - SAM Entitlement is correct given the Salesforce Subscription Status
			    	} else if (sfAccountInformation.Subscription_Status__c == Constants.SSTATUS_ACTIVE && (samEntitlement == thisEntitlement.Recently_Inactive_Entitlement_Value__c || samEntitlement == thisEntitlement.Inactive_Entitlement_Value__c)){
			    		sCurrentRuleResult = Constants.SAM_ENT_RULE_ACTIVE_ACCOUNT_LAPSED_ENTITLEMENTS; // error - Salesforce account is active, but SAM entitlement is recently lapsed or lapsed
			    	} else if (sfAccountInformation.Subscription_Status__c == Constants.SSTATUS_INACTIVE && (samEntitlement == thisEntitlement.Pending_Entitlement_value__c || samEntitlement == thisEntitlement.Active_Entitlement_value__c || samEntitlement == thisEntitlement.InRenewal_Entitlement_Value__c)){
		    			sCurrentRuleResult = Constants.SAM_ENT_RULE_INACTIVE_ACCOUNT_ACTIVE_ENTITLEMENTS; // error - Salesforce account is lapsed, but SAM entitlement is active, pending or in renewal
			    	} else if (sfAccountInformation.Subscription_Status__c == Constants.SSTATUS_PENDING && (samEntitlement == thisEntitlement.Inactive_Entitlement_Value__c || samEntitlement == thisEntitlement.Recently_Inactive_Entitlement_Value__c)){
						sCurrentRuleResult = Constants.SAM_ENT_RULE_PENDING_ACCOUNT_LAPSED_ENTITLEMENTS; // error - Salesforce account is pending, but SAM entitlement is inactive, or recently inactive
			    	}

			    	if(String.isNotBlank(sCurrentRuleResult)){
			    		subscriberRuleLog = logNewSubscriberRuleWithData(subscriberRuleLog, currentRule, sCurrentRuleResult,JSON.serialize('SAM Entitlement: ' + samEntitlement + 'SF Subscriber Status: ' + sfAccountInformation.Subscription_Status__c)); 
			    	}
		    	}
	    	}
		}
		return subscriberRuleLog;
    }  
    
    /*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.0
	Function -  
	#############Change Log#############
	Cristina Anghenie	1.1		29/07/2015	//prevent diagnostic console fail to display results if mpp order history are not in sync with salesforce
	****************************************************************************************/
    public static List<subscriberRuleLog> compareMppToSfOrders(List<MPP_Transaction_History__c> sfOrderInformation, MPPInterfaceHTTP.UserOrderHistoryResult mppUserOrderHistory, subscriberRuleLog[] subscriberRuleLog)  
    {
		string currentRule = 'mppOrderIdsInSfdcCheck';   // this rule will check if MPP is storing a TS Number and GUID for the subscriber (it should always)
        Map<String, MPPInterfaceHTTP.OrderHistoryItem> mppOrdersThatExistInSF = new Map<String, MPPInterfaceHTTP.OrderHistoryItem>();
 
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c)	 // check if the rule is active, before running it
		{
			string currentRuleResult;
			                   
	        if(sfOrderInformation != null && mppUserOrderHistory.OrderHistoryItems !=null)   
	        for(MPP_Transaction_History__c thisSFOrder : sfOrderInformation){
	        	for(MPPInterfaceHTTP.OrderHistoryItem thisMppOrder : mppUserOrderHistory.OrderHistoryItems){
	        		if(thisSfOrder.Order_ID__c == thisMppOrder.OrderId){
	        			currentRuleResult = '200'; 	// order id is in Salesforce 
	                	subscriberRuleLog = logNewSubscriberRuleWithData(subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize(thisMppOrder));
	                    mppOrdersThatExistInSF.put(thisMppOrder.OrderId, thisMPPOrder);
	                }
	            }
	        }
	
	        if(mppUserOrderHistory.OrderHistoryItems != null)
	        for(MPPInterfaceHTTP.OrderHistoryItem thisMppOrder : mppUserOrderHistory.OrderHistoryItems)    
	        {
	            if(thisMppOrder.GrossAmount != '0.0000') // it is OK if blank orders are not in SFDC
	                if(mppOrdersThatExistInSF.get(thisMppOrder.OrderId) == NULL)
	                {		currentRuleResult = '500';  // order is not in Salesforce
	                        subscriberRuleLog = logNewSubscriberRuleWithData(subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize(thisMppOrder));
	                }              
	        }
		}
		
        return subscriberRuleLog;
    }
  	
  	public static  orderTotals calculateTotalSFOrders(List<MPP_Transaction_History__c> sfOrderInformation)   
  	{
  		orderTotals result = new orderTotals();
  		result.overallPriceTotal = 0;
  		result.countOfOrders = 0;
  		
  		for(MPP_Transaction_History__c thisOrder : sfOrderInformation)
  		{ result.overallPriceTotal = thisOrder.Total_Price__c.intValue() + result.overallPriceTotal; 
  		  result.countOfOrders = result.countOfOrders + 1; }
  		return result;
  	}
  	
  	public static  orderTotals calculateTotalMPPOrders(MPPInterfaceHTTP.UserOrderHistoryResult mppUserOrderHistory)   
  	{
  		orderTotals result = new orderTotals();
  		integer i = 0;
  		result.overallPriceTotal = 0;
  		result.countOfOrders = 0;
  		
  		for(MPPInterfaceHTTP.OrderHistoryItem thisOrder : mppUserOrderHistory.OrderHistoryItems)
  		{ 	
  			i = integer.valueOf(thisOrder.GrossAmount);
  			result.overallPriceTotal = result.overallPriceTotal + i; 
  		}
  		result.countOfOrders = integer.valueOf(mppUserOrderHistory.TotalNumberOfOrders);
  		return result;
  	}
  	
	/**     
	-------------------------------
	-   ISSUE CAPTURE/REPORTING   -
	-------------------------------   
	**/  
    
    public static List<subscriberRuleLog> logNewSubscriberRule(List<subscriberRuleLog> currentRuleLog, String ruleCode, String ruleResultCode)
    {
    	subscriberRuleLog tempLogRow = new subscriberRuleLog();
    	tempLogRow.ruleCode = ruleCode;
    	tempLogRow.ruleResultCode = ruleResultCode;
    	
		currentRuleLog.add(tempLogRow);
				
		return currentRuleLog;
    }   

    public static List<subscriberRuleLog> logNewSubscriberRuleWithData(List<subscriberRuleLog> currentRuleLog, String ruleCode, String ruleResultCode, String ruleData){
    	subscriberRuleLog tempLogRow = new subscriberRuleLog();
    	tempLogRow.ruleCode = ruleCode;
    	tempLogRow.ruleResultCode = ruleResultCode;
    	tempLogRow.ruleData = ruleData;    	
		currentRuleLog.add(tempLogRow);
		return currentRuleLog;
    }   
    
    public static List<subscriberRuleLog> populateSubscriberIssueLogWithRuleDetail(List<subscriberRuleLog> currentRuleLog)
    {
    	List<String> ruleCodes = new List<String>();
    	
    	for (subscriberRuleLog rl : currentRuleLog)
    	{ ruleCodes.add(rl.ruleCode);	}
    	
  //  	List<subscriberValidationRuleInfoV2__c> subscriberRuleValues = [Select Name, ruleGroup__c, ruleName__c, X100__c, X200__c, X300__c, X400__c, X500__c, X600__c, X700__c, X800__c, X900__c from subscriberValidationRuleInfov2__c where ruleCode__c in :ruleCodes];
    	
		for (subscriberRuleLog log : currentRuleLog)
		{
			if(log.ruleResultCode == '100')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X100__c;
			else if(log.ruleResultCode == '200')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X200__c;
			else if(log.ruleResultCode == '300')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X300__c;
			else if(log.ruleResultCode == '400')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X400__c;
			else if(log.ruleResultCode == '500')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X500__c;
			else if(log.ruleResultCode == '600')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X600__c;
			else if(log.ruleResultCode == '700')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X700__c;	
			else if(log.ruleResultCode == '800')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X800__c;
			else if(log.ruleResultCode == '900')
				log.ruleUserMessage = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).X900__c;										
			
			log.ruleGroup = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).ruleGroup__c;
			log.ruleName = subscriberValidationRuleInfoV2__c.getInstance(log.ruleCode).ruleName__c;					

		} 
 
		return currentRuleLog;
    }  
    
    public static List<subscriberConsoleWebservice.subscriberRuleSummary> evaluateRulesAndGenerateSummary(List<subscriberRuleLog> currentRuleLog) 
    {
    	    	
    	AggregateResult[] subscriberRuleValues = [Select ruleGroup__c from subscriberValidationRuleInfo__c group by ruleGroup__c];
   	List<subscriberConsoleWebservice.subscriberRuleSummary> ruleSummaryFullList = new List<subscriberConsoleWebservice.subscriberRuleSummary>();    	
    	
    	for(AggregateResult thisRuleGroup : subscriberRuleValues)
    	{

    	subscriberConsoleWebservice.subscriberRuleSummary ruleSummarySingleItem = new subscriberConsoleWebservice.subscriberRuleSummary();
    	ruleSummarySingleItem.subscriberRuleLog = new List<subscriberConsolesWebserviceHandlers.subscriberRuleLog>();     
        		
    		ruleSummarySingleItem.ruleGroup = (String)thisRuleGroup.get('ruleGroup__c');
    	
    		for(subscriberRuleLog thisLogItem : currentRuleLog)
	    		{
    			
	    		if(thisLogItem.ruleGroup == ruleSummarySingleItem.ruleGroup)
	    			{  				
	    			ruleSummarySingleItem.subscriberRuleLog.add(thisLogItem);
	    			}
	    		}
	    	ruleSummaryFullList.add(ruleSummarySingleItem); 	
    	}   	
    	return ruleSummaryFullList;  
    }  
    
    
}