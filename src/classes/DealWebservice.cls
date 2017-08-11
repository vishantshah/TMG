/**
* @author Unknown
* @date Unknown
* @description 
*				Webservice to handle Active Token
*			    This is the public interface - this is what SalesForce will generate its WSDL from.  
*			    Purpose:	 
*			    Define a new API interface required in Salesforce that will receive a unique ‘Partner Token’ value, 
*			    check if it is currently already in use by an active Subscriber, then return either a ‘TRUE’ or ‘FALSE’ message to the originating system. 
*#############Change Log#############
*Modified by     	Version     Change Date
*Wiktor Czykin   	1.1         04/03/2015  //modified getAccountByToken()
*Wiktor Czykin		1.2 		06/03/2015	//again modified getAccountByToken();
**/


/** 
--------------------------
-   OBJECT DEFINITIONS   -
--------------------------   
**/

// Added change Part of VOD-27 
global class DealWebservice {

    global class Token {
        Webservice String tokenValue;
        Webservice String tokenSource;
        public Token(String tokenValue,String tokenSource){
            this.tokenValue = tokenValue;
            this.tokenSource = tokenSource;
        }
    }
   
   
// Response for isActiveToken API
    global class IsActiveTokenResult {
        webservice Boolean isActive;
        webservice Token token;  
        webservice String responseStatusCode;
        webservice String responseStatusMsg;
        
        public IsActiveTokenResult(){
        }
        
        public IsActiveTokenResult(String responseStatusCode,String responseStatusMsg,Boolean isActive,Token token){
            this.responseStatusCode = responseStatusCode;
            this.responseStatusMsg = responseStatusMsg;
            this.isActive = isActive;
            this.token = token;
        }
    }


// Inbound request for PartnerAction API
    global class PartnerActionRequest {
        webservice String requestCode;
        webservice String requestDetail;
        webservice String requestType;
        public PartnerActionRequest (String requestCode, String requestDetail, String requestType){
        	this.requestCode = requestCode;
            this.requestDetail = requestDetail;
            this.requestType = requestType;
        }
    }
    
// Outbound response for PartnerAction API
    global class PartnerActionResponse {
        webservice String actionCode;
        webservice String actionDetail;
        public PartnerActionResponse (String actionCode, String actionDetail){
        	this.actionCode = actionCode;
            this.actionDetail = actionDetail;
        }
    }

//  
// SubscriberInfo object - created as per design in VOD-496 - MySQL DB v0.6
//    
    global class SubscriberInfo {
        webservice String TSNumber;
        webservice String SubscriptionID;
        webservice String GUID;        
        webservice String TokenSource;        
        webservice String PartnerToken;        
        webservice String WaveID;        
        webservice String GraceStatus;        
        webservice Date GracePeriodStartDate;        
        webservice Date GracePeriodEndDate;        
        webservice String PricingOptionID;
        webservice DateTime BatchJobLastProcessedDateTime;                
        webservice String Status;        
        
        public SubscriberInfo (String TSNumber){
			this.TSNumber = TSNumber;
        }
        
    }
   
// requestDetail object matches the object that is defined when PartnerESB creates JSON and calls Salesforce
    global class requestDetail {
		public String oldStatus;
		public String oldPackageId;
		public String oldGraceStatus;
		public String newStatus;
		public String newPackageId;
		public String newGraceStatus;
        }
      

/**     
--------------------------
- WEBSERVICE DEFINITIONS -
--------------------------   
**/    
    
	  // Check if this Token is already active
	  webservice static IsActiveTokenResult IsActiveToken(Token token){
		     IsActiveTokenResult result;
		     ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'isActiveToken', new Map<String,Object>{'TokenValue' => token});
		          
		    // Search tokenValue against active accounts. If an active account is found return true else false
		     Account accountForToken = getAccountByToken(token);
		     
		     if(accountForToken == null){
		       result= new IsActiveTokenResult('ERROR-001','No Active Token Found',false,null);
		       TMGUtil.logWebServiceDetail(logId, string.valueOf(result));
		      }      
		     else
		       {
		       result= new IsActiveTokenResult('SUCCESS-001','Active Token Found in Salesforce',true,null);     
		       TMGUtil.logWebServiceDetail(logId, string.valueOf(result));
		      }  
		     return result;  
		  } 
  
  
        //
  		// API developed for Vodafone Phase 2. This API is designed to receive a 'requestCode' and 'requestDetail' JSON string following a change or action from a partner integration, and then return  
  		// an actionCode and actionDetail (JSON String) back to Partner systems instructing the partner system how to act.
  		//
  		
	    webservice static PartnerActionResponse PartnerAction(PartnerActionRequest actionRequest, SubscriberInfo subscriberInfo){
		     PartnerActionResponse result;
		     string newPackageId;
		     Boolean graceProcessCompleted;
		     Partner_Action_Requests__c requestResponseValue;
		     
		     system.debug('**** PartnerAction called with actionRequest: ' + actionRequest + ' subscriberInfo: ' + subscriberInfo);
		     system.debug('**** PartnerAction called with actionRequest.RequestCode: ' + actionRequest.requestCode);
		     
		     ID logId = TMGUtil.logWebServiceRequest('Inbound', null, 'PartnerAction', new Map<String,Object>{'actionRequest' => actionRequest});
		      
		     requestResponseValue = Partner_Action_Requests__c.getInstance(actionRequest.requestCode);
		     
		     system.debug('**** requestResponseValue: ' + requestResponseValue);
		     
		     
		     // If Inbound Request requires a Grace Change, then call method to handle this. The control for this value is in the custom setting for Partner Action Requests
		     if(requestResponseValue != null && requestResponseValue.Requires_Grace_Update__c)
		     	graceProcessCompleted = processGrace(actionRequest, subscriberInfo, requestResponseValue, logId);     
			
			result = processRequestAndReturnActionCode(actionRequest, subscriberInfo, requestResponseValue, logId);		     
			
			TMGUtil.logWebServiceDetail(logId, string.valueOf(result));
			
			return result;
	  } 

/**     
--------------------------
-   WEBSERVICE METHODS   -
--------------------------   
**/   
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Method to return the details of an account for a given Token
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1 		04/03/2015	//modified soql - added limit 1 as either way it was returning 1 row
    Wiktor Czykin	1.2 		06/03/2015	//modified if condition to check blank string (and whitespace) as well
    ****************************************************************************************/
    public static Account getAccountByToken(Token token){
        Account a;
        List<Account> accounts;
        if(String.isNotBlank(token.tokenValue)){
         	accounts = [SELECT 	Id,
         						Subscriber_Number_static__c,
         						Partner_Token__c,
         						Token_Source__c,
         						GUID__c, 
         						Salutation, 
         						FirstName, 
         						LastName
                          	FROM   Account 
                            WHERE  (Subscription_Status__c ='Active' or Subscriber_Digital_Status__c = 'Active') 
                            AND Partner_Token__c = :token.tokenValue limit 1];
        }

        if( accounts != null && !accounts.isEmpty()){
            return accounts[0];
        } 
        return null;
    }

    // method to return the details of entitlement values for a given Pricing Option Id
    public static Entitlements__c getEntitlementDataByPricingOption(String PricingOptionName){
        
        system.debug('**** getEntitlementDataByPricingOption has been called with : ' + PricingOptionName);
		string productType;
		
		Pricing_Options__c pricingOption = [SELECT id,Product_Type__c,Name
                                  FROM   Pricing_Options__c 
                                  WHERE  Name=:PricingOptionName];
		
		
		productType = pricingOption.Product_Type__c;
		
		Entitlements__c currentEntitlement = [Select Active_Entitlement_Value__c, Inactive_Entitlement_Value__c, InRenewal_Entitlement_Value__c, Pending_Entitlement_value__c, Pricing_Option_Product_Type__c, Recently_Inactive_Entitlement_Value__c from Entitlements__c where Pricing_Option_Product_Type__c =: productType];
		
		system.debug('**** getEntitlementDataByPricingOption exiting and returning : ' + currentEntitlement);
		return currentEntitlement;
    }    
    

    // method to cancel a DigitalSubscription in Salesforce (note: does not cancel a subscription in MPP)
    public static Account deactivateDigitalSubscription(String TSNumber){
 
 		system.debug('**** deactivateDigitalSubscription has been called for : ' + TSNumber);      
 		
        // select subscriber to be updated
		Account subscriberAccount = [SELECT Subscriber_Number_Static__c, Subscriber_Digital_Status__c from Account where Subscriber_Number_Static__c = :TSNumber];
	
		subscriberAccount.Subscriber_Digital_Status__c = 'Inactive';
		update subscriberAccount;	
	    
		return subscriberAccount;
    }      

    
    // method to change a Subscriber to be a on a new Pricing Option
    public static Pricing_Options__c changeSubscriberPricingOptionByPackageID(String newPackageID, string TSNumber){
 
 		system.debug('**** changeSubscriberPricingOptionByPackageID has been called with : ' + newPackageID + ' TSNumber: ' + TSNumber);      
 		
        // select subscriber to be updated
		Account subscriberAccount = [SELECT Subscriber_Number_Static__c, Pricing_Option__c, Promotion_Name__c, Promo_Code__c from Account where Subscriber_Number_Static__c = :TSNumber];
		
		Pricing_Options__c pricingOption = [SELECT Id, Name, Product_Type__c, Partner_Unique_ID__c, Package_Name__c, Multi_User_Discount_Voucher__c
                                  FROM   Pricing_Options__c 
                                  WHERE  Partner_Unique_ID__c=:newPackageID];
	
		subscriberAccount.Pricing_Option__c = pricingOption.Id;
		
		// **HYGIENE** - there is definite overlap in the use of Promotion_Name and Package_Name. Hygiene should consolidate these fields and make the below code redundant
		subscriberAccount.Promotion_Name__c = pricingOption.Package_Name__c;
		subscriberAccount.Promo_Code__c = pricingOption.Multi_User_Discount_Voucher__c;
		
		update subscriberAccount;	
	    system.debug('**** pricingOption from changeSubscriberPricingOptionByPackageID : ' + pricingOption);
	    
		return pricingOption;
    }   
    
    // update Grace Period information in Salesforce following partner request - returns TRUE or FALSE depending on success/fail.
    public static Boolean processGrace(PartnerActionRequest actionRequest, SubscriberInfo subscriberInfo, Partner_Action_Requests__c requestResponseValue, ID LogId){
 
 		Boolean result;
 		requestDetail requestDetailValues;
 		Integer graceTotal;
 		
 		system.debug('**** starting Process Grace');      
 		
 		 // select subscriber to be updated
		Account subscriberAccount = [SELECT Subscriber_Number_Static__c, Grace_Period_Start_Date__c, Grace_Period_End_Date__c, Grace_Status__c, Pricing_Option__c, Grace_Period_Duration_1__c, Grace_Period_Duration_2__c from Account where Subscriber_Number_Static__c = :subscriberInfo.TSNumber];
 		
 		// Read JSON Detail into array for further processing - TO DO: should be made into a standard and repeatable method as is duplicated below
		requestDetailValues = (requestDetail)JSON.deserializeStrict(actionRequest.requestDetail,requestDetail.class);
 		
 		// Update Grace Status on Account if it is not correct
 		if(subscriberAccount.Grace_Status__c != requestDetailValues.newGraceStatus)
 			subscriberAccount.Grace_Status__c = requestDetailValues.newGraceStatus; 


		// Subscriber is in grace period and is still active
		if(subscriberAccount.Grace_Status__c == 'InGrace')
		{
	 		// Update Grace Start Date on Account if it is not already populated
	 		if(subscriberAccount.Grace_Period_Start_Date__c == NULL)
	 			subscriberAccount.Grace_Period_Start_Date__c = date.today(); 	

	 		// Update Grace END Date on Account based on Grace Duration 2 (i.e. TMG grace period only, not partner grace period) 
	 		if(subscriberAccount.Grace_Period_End_Date__c == NULL && actionRequest.requestCode == 'PC_SG')
	 			subscriberAccount.Grace_Period_End_Date__c = subscriberAccount.Grace_Period_Start_Date__c.addDays(subscriberAccount.Grace_Period_Duration_2__c.intValue());
	 			
	 		// Update Grace END Date on Account based on Grace Duration Total (i.e. TMG grace period and partner grace period combined)
	 		if(subscriberAccount.Grace_Period_End_Date__c == NULL && actionRequest.requestCode != 'PC_SG')
	 		{
	 		    graceTotal = subscriberAccount.Grace_Period_Duration_1__c.intValue() + subscriberAccount.Grace_Period_Duration_2__c.intValue();
	 			subscriberAccount.Grace_Period_End_Date__c = subscriberAccount.Grace_Period_Start_Date__c.addDays(graceTotal); 		
	 		}
    	}
    	
    	// Subscriber is not grace period (or grace period has been removed) and thus should not have a value in the start and end dates
    	if(subscriberAccount.Grace_Status__c == 'NotInGrace' || (actionRequest.requestCode == 'RG' || actionRequest.requestCode == 'PC_RG'))
		{
			subscriberAccount.Grace_Period_Start_Date__c = null;
			subscriberAccount.Grace_Period_End_Date__c = null;
    	}
    	
    	// Subscribers grace period has expired, and thus should have the end date populated
    	if(subscriberAccount.Grace_Status__c == 'GraceExpired')
		{
	 		// Update Grace End Date on Account if it is not already populated
	 		if(subscriberAccount.Grace_Period_End_Date__c == NULL)
				subscriberAccount.Grace_Period_End_Date__c = date.today();
    	}
 		
 		try{
 			update subscriberAccount;
			result = TRUE;
 		}
 		catch(Exception e)
 		{
 			system.debug('**** Error updating Grace Information. Exception: ' + e);
			result = FALSE;
		}
	    
		return result;
    } 
	
	//
	// Prepare response back to partner system based on 'actionCode' value, derived from Partner_Action_Requests__c custom setting
	//
    public static PartnerActionResponse processRequestAndReturnActionCode(PartnerActionRequest actionRequest, SubscriberInfo subscriberInfo, Partner_Action_Requests__c requestResponseValue, ID LogId){
 
 			requestDetail requestDetailValues;
 			string responseString;
 			PartnerActionResponse result;
 					     
		     if(requestResponseValue.actionCode__c != '0')
		     {
				     // Product Change
				     if((requestResponseValue.actionCode__c == '1' || requestResponseValue.actionCode__c == '3' ) && subscriberInfo.PricingOptionId != null)
				     {
				     	
				     	 // Read JSON Detail into array for further processing - TO DO: should be made into a standard and repeatable method as is duplicated above
						 requestDetailValues = (requestDetail)JSON.deserializeStrict(actionRequest.requestDetail,requestDetail.class);
				     	 
				     	 // if we have the JSON request information
				     	 if(requestDetailValues != null)
					     	{
					     	try{
					     	 // Get Current Entitlement Data from custom setting
					     	 Entitlements__c currentEntitlement = getEntitlementDataByPricingOption(subscriberInfo.PricingOptionId);
					     	 system.debug('**** getEntitlementDataByPricingOption completed OK - ' + currentEntitlement);
					     	 
					     	 // Change subscriber to be on new Pricing Option
					     	 Pricing_Options__c newPricingOption = changeSubscriberPricingOptionByPackageID(requestDetailValues.newPackageId, subscriberInfo.TSNumber);
					     	 system.debug('**** changeSubscriberPricingOptionByPackageID completed OK - ' + newPricingOption);
					     	 
					         // Get Entitlement data for new Pricing Option				     	 
					     	 Entitlements__c newEntitlement = getEntitlementDataByPricingOption(newPricingOption.Name);
					     	 system.debug('**** pricingOption from getEntitlementDataByPricingOption : ' + newEntitlement);
					     	 
					     	 // Get the Active or Inactive entitlement value based on the information from requestDetails JSON string
					         if(requestDetailValues.newStatus == 'INACTIVE')
					         	    responseString = newEntitlement.Inactive_Entitlement_Value__c;    					         
					         if(requestDetailValues.newStatus == 'ACTIVE')
					              	responseString = newEntitlement.Active_Entitlement_Value__c;
				 	    	} 
				 	    	catch(Exception e)
				 	    	{
				 	    	   system.debug('**** Error processing request. Entitlement, Pricing Option or Account not found. Exception: ' + e);
					           result = new PartnerActionResponse('Error processing request. Entitlement, Pricing Option or Account not found', e.getMessage());
					           TMGUtil.logWebServiceDetail(logId,e.getMessage()+'stackTrace: '+e.getStackTraceString());

							   return result;
				 	    	}
					     	}
				    	 }
				     // Cancel Subscription
				     if(requestResponseValue.actionCode__c == '2' || requestResponseValue.actionCode__c == '3')
				     {
	   				      responseString = '';	
		                  Account updatedAccount = deactivateDigitalSubscription(subscriberInfo.TSNumber);
				     }
		    }

			// actionCode is 0, and no action is required by partners
			else
				responseString = '';
				        		    
		    result= new PartnerActionResponse(requestResponseValue.actionCode__c,responseString);
		    return result; 
    }


}