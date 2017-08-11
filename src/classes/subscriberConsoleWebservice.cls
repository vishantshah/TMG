/**
* @author Unknown
* @date Unknown
* @description 	Webservice to pool, call and invoke subscriber information from various systems,
				so that analysis can be done on the state of a subscriber, and any anomalies can be identified across TMG systems 
#############Change Log#############
Modified by     	Version     Change Date
Wiktor Czykin   	1.1         13/05/2015  //minor changes in code formatting, few Constants added, fix to which messages are stored in ruleLog in TSNumber and GUID verifications against MPP
Mantas Grigaliunas	1.2			08/06/2016	//removed ipad related code
**/
global class subscriberConsoleWebservice {

    // in first release on type of 'TSNUMBER' and EMAIL will be supported
    global class subscriberIdentifier {
        Webservice String idType;
        Webservice String idValue;

        public subscriberIdentifier(String idType,String idValue){
            this.idValue = idValue;
            this.idType = idType;
        }
    }
    
	// Response for subscriberOverview API
    global class subscriberOverviewResult {
        webservice subscriberIdentifier subscriberIdentifier;  
        webservice Account sfAccountInformation; 
        webservice List<MPP_Transaction_History__c> sfOrderInformation;     
        webservice MPPInterfaceHTTP.UserInfoResult mppUserInfo;   
        webservice SAMUtil.SAMAccountResult samAccountAndEntitlementInfo;
        webservice MPPInterfaceHTTP.UserOrderHistoryResult mppUserOrderHistory;
        webservice subscriberConsolesWebserviceHandlers.subscriberRuleLog[] subscriberRuleLog;
        webservice String TSNumber;
        webservice String Email;  
        webservice String SAMGuid;
        webservice String MPPGuid;   
        webservice Boolean dataAvailableInMPP;
        webservice Boolean dataAvailableInSF;
        webservice Boolean dataAvailableInSAM;
        webservice ValidateMPPWrapper validateMPPResult;          
         
    }
    
    global class subscriberRuleSummary{
    	webservice string ruleGroup;
    	webservice subscriberConsolesWebserviceHandlers.subscriberRuleLog[] subscriberRuleLog;
    }

	global class ValidateMPPWrapper {
		webservice String mppTSNumber {get;set;}
		webservice String mppSAMGuid {get;set;}
		
		public ValidateMPPWrapper(){}
		public ValidateMPPWrapper(String mppTSNumberIn, String mppSAMGuidIn) {
			mppTSNumber = mppTSNumberIn;
			mppSAMGuid = mppSAMGuidIn;
		}

	}

/**      
--------------------------
- WEBSERVICE DEFINITION  -
--------------------------   
**/    
    
	webservice static subscriberOverviewResult subscriberOverview(subscriberIdentifier subscriberIdentifier){
 
        subscriberOverviewResult result = lookupAndEvaluateSubscriberInformation(subscriberIdentifier);		          
		return result;  
		}

/**      
--------------------------
-    PUBLIC METHODS      -
--------------------------   
**/   
		  
	public static subscriberOverviewResult lookupAndEvaluateSubscriberInformation(subscriberIdentifier subscriberIdentifier){
		subscriberOverviewResult result = new subscriberOverviewResult();  
    	result.subscriberIdentifier = subscriberIdentifier;
    	MppInterfaceHTTP.UserServicesResult mppUserServicesInfo = new MppInterfaceHTTP.UserServicesResult();
        
		result.subscriberRuleLog = new List<subscriberConsolesWebserviceHandlers.subscriberRuleLog>();
		/*    Gather Data from Salesforce, MPP and SAM    */
		if(subscriberIdentifier.idType == 'TSNUMBER' && subscriberIdentifier.idValue != null){
			result.TSNumber = result.subscriberIdentifier.idValue;     			
			result = gatherAllDataForTSNumber(result);
		}
    		
     	/*    Validate data gathered using 'performValidationChecks'   */
		result = performValidationChecks(result);
			    		
		/*    Populate error log with user friendly error messages based on custom settings mapping  */
		result.subscriberRuleLog = subscriberConsolesWebserviceHandlers.populateSubscriberIssueLogWithRuleDetail(result.subscriberRuleLog);
		return result;
	} 

	public static subscriberOverviewResult gatherAllDataForTSNumber(subscriberOverviewResult result){
		String currentRule;
		String currentRuleResult;  		 		

		// call SF and populate dataAvailableInSF
		result = getSFAccountInformationByTSNumber(result);//get the account record and populate result.sfAccountInformation with it
		if(result.dataAvailableInSF){	
			result = getSFOrderInformationByAccountId(result);//get the related MPP Transaction History records
    	}

 		// if we don't have email yet, then derive from Salesforce if possible
		if(result.Email != null){ 
			result.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(result.subscriberRuleLog, Constants.MPP_RULE_EMAILCHECK, '400'); 
		}else if(result.Email == null && result.sfAccountInformation.PersonEmail != null){
			result.Email = result.sfAccountInformation.PersonEmail;//just copy email from sfdc record
	 		result.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(result.subscriberRuleLog, Constants.MPP_RULE_EMAILCHECK, '200');
	 	}
	 			      	
    	// call MPPUserInfo and populate dataAvailableInMPP
    	result = attemptToGetMppUserInfoByTsNumberThenEmail(result);    
    	if(result.MPPGuid != null){		 		
			result = retrieveUserOrderHistoryResultForMppGuid(result);
		}
 
		// if we don't have email yet, then derive from MPP if possible - if not then error
	   	if(result.Email == NULL && result.mppUserInfo.EmailAddress != NULL){ 
	   		result.Email = result.mppUserInfo.EmailAddress;
	   	   	result.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(result.subscriberRuleLog, Constants.MPP_RULE_EMAILCHECK, '300'); 
	   	}else if(result.Email == NULL){ 
	   		result.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(result.subscriberRuleLog, Constants.MPP_RULE_EMAILCHECK, '500', JSON.serialize('Could not derive email address')); 
	   	}

		result = getSamGuidAndEntitlementsByEmail(result);
    		    	
    	// derive SAM Guid from SAM call
   		if(result.SAMGuid == NULL && result.samAccountAndEntitlementInfo.guid != NULL)
   			result.SAMGuid = result.samAccountAndEntitlementInfo.guid;  
	   	result = setupDataFlags(result); 	
	   	
	   	return result; 	
	}

	public static subscriberOverviewResult setupDataFlags(subscriberOverviewResult thisSubscriber)
	{ 		 		
			if(thisSubscriber.mppUserInfo.MPPGuid != null){
				thisSubscriber.dataAvailableInMPP = true;
			}else{
				thisSubscriber.dataAvailableInMPP = false;
			}
				
			if(thisSubscriber.sfAccountInformation.Subscriber_Number_Static__c != null){
				thisSubscriber.dataAvailableInSF = true;
			}else{
				thisSubscriber.dataAvailableInSF = false;
			}
				
			if(thisSubscriber.samAccountAndEntitlementInfo.guid != null){
				thisSubscriber.dataAvailableInSam = true;
			}else{
				thisSubscriber.dataAvailableInSam = false;			
			}
			
		   	return thisSubscriber; 	
	}

	public static subscriberOverviewResult performValidationChecks(subscriberOverviewResult result){
	   	// 1 - Setup info. Is the subscriber created/existing correctly in MPP, Salesforce and SAM?
	   	// 1a - check that MPP has both Guid and TS Number
		if(result.dataAvailableInMPP && result.dataAvailableInSAM){
			result.validateMPPResult = validateMppStoringTSNumberAndGuid(result);
	 		validateMppHasCorrectTSNumberAndGuid(result);	
	 	}
	 	
	   	// 1b - check that Salesforce has Guid
	   	if(result.dataAvailableInSAM && result.dataAvailableInSF){
	   		validateSfAccountHasCorrectGuid(result); 
	   	}
	   	
	   	// 2 - Entitlement Info. Does the subscriber have a consistent entitlement status across all systems?
	 	if(result.dataAvailableInSF && result.dataAvailableInSAM){
	   	 	checkEntitlementInfo(result); 			     		
	 	}
	 	
	   // 3 - Financial Info. Does the subscriber have order information correctly persisted across Salesforce and MPP?
  	   if(result.sfOrderInformation != null & result.mppUserOrderHistory != null){
	   	 	checkOrderInfo(result); 	
  	   }
  	   
	   return result; 	
	}
 
/**      
--------------------------
-    PRIVATE METHODS     -
--------------------------   
**/    

	private static subscriberOverviewResult getSFAccountInformationByTSNumber(subscriberOverviewResult thisSubscriber){
		String currentRule = 'sfAccountData';   // this rule will get Salesforce Account Data
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;  	
	        thisSubscriber.sfAccountInformation = new Account();  
	   		try{ 
	   			currentRuleResult = '100'; // success
    		  	thisSubscriber.sfAccountInformation = subscriberConsolesWebserviceHandlers.retrieveSfAccountInformationForTSNumber(thisSubscriber.TSNumber);//just fetches the record
    		  	thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
    		  	thisSubscriber.dataAvailableInSF = true; 
	    	}catch(Exception e){
	    		currentRuleResult = '500'; // error
	    		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e)); 
	    		thisSubscriber.dataAvailableInSF = false; 
	    	}
		}	  
		return thisSubscriber;
	}
	
	private static subscriberOverviewResult getSFOrderInformationByAccountId(subscriberOverviewResult thisSubscriber){
		String currentRule = 'sfOrderData';   // this rule will get Salesforce Order Data
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;  				
        	thisSubscriber.sfOrderInformation = new List<MPP_Transaction_History__c>();  
	    	try{ 
	    		currentRuleResult = '100'; // success
	    		thisSubscriber.sfOrderInformation = subscriberConsolesWebserviceHandlers.retrievesfOrderInformationByAccountID(thisSubscriber.sfAccountInformation.Id);//just fetches related MPP Transaction History record
	    		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
	    	} catch(Exception e){ 
	    		currentRuleResult = '500'; // error
	    		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e)); 
	    	}
	    }
		return thisSubscriber;
	}

	public static subscriberOverviewResult attemptToGetMppUserInfoByTsNumberThenEmail(subscriberOverviewResult thisSubscriber){
		string currentRule = 'mppUserInfoCallData';   // this rule will get MPP User Info by TS Number
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
		
			String currentRuleResult;  		
        	thisSubscriber.mppUserInfo = new MPPInterfaceHTTP.UserInfoResult();  
	     	try{
	    		 currentRuleResult = '100'; // success using TS Number
	    		 thisSubscriber.mppUserInfo = subscriberConsolesWebserviceHandlers.retrieveUserInfoResultForTsNumberAndDoNotLogWebserviceCall(thisSubscriber.TSNumber);
	    		 thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
	 	 		 thisSubscriber.MPPGuid = thisSubscriber.mppUserInfo.MPPGuid;  
	 	  	} catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
	 	  		if(e.getErrorCode().contains('1009')){
	    				try{
	    					if(thisSubscriber.Email != null){
		    					currentRuleResult = '300'; // success using email address
			    				thisSubscriber.mppUserInfo = subscriberConsolesWebserviceHandlers.retrieveUserInfoResultForEmailAndDoNotLogWebserviceCall(thisSubscriber.Email);
		  	 					thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);
		  	 					thisSubscriber.MPPGuid = thisSubscriber.mppUserInfo.MPPGuid;
	    					}
	    				} catch(MPPInterfaceHTTP.MPPInterfaceHTTPException exceptionInfo){
	    					
    						currentRuleResult = '600'; // an exception occured when calling MPP User Info with email address
			    			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e));
    					}
	    			}
	    		  else{
	    		  	currentRuleResult = '500'; // an exception occured when calling MPP User Info
	       		    thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e)); }
	    		}  
		}
    	return thisSubscriber;
	}

	private static subscriberOverviewResult getSamGuidAndEntitlementsByEmail(subscriberOverviewResult thisSubscriber){
		String currentRule = 'samGetExistingSAMAccountData';   // this rule will get SAM account data
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;  
			SAMUtil samUtil = new SAMUtil();		
	        thisSubscriber.samAccountAndEntitlementInfo = new SAMUtil.SAMAccountResult();	
		   	try{
		   		// call SAM with Subscriber.Email value
				thisSubscriber.samAccountAndEntitlementInfo = SAMUtil.getExistingSAMAccount(thisSubscriber.Email);
		   		
		   		if(thisSubscriber.samAccountAndEntitlementInfo.Guid == null){
			   			 currentRuleResult = '600'; // error - no record found in SAM
				   		 thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('No record returned from SAM: ' + thisSubscriber.samAccountAndEntitlementInfo)); 
				   		 thisSubscriber.dataAvailableInSAM = FALSE; 	   			
			   	}else if(thisSubscriber.samAccountAndEntitlementInfo.Guid != null){
						 currentRuleResult = '200'; // success - guid found
				   		 thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
				   		 thisSubscriber.dataAvailableInSAM = TRUE; 
			   	}	   
		   	}catch(Exception e){
		   		currentRuleResult = '500'; // error - exception occured
				thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e)); 
				 thisSubscriber.dataAvailableInSAM = FALSE; 
			}
		}
		return thisSubscriber;
	}

	public static MppInterfaceHTTP.UserServicesResult getMppUserServicesInfoByTSNumber(subscriberOverviewResult thisSubscriber){
		String currentRule = 'mppUserServicesInfoCallData';   // this rule will call MPP UserServices to get active services
		MppInterfaceHTTP.UserServicesResult mppUserServicesInfo = new MppInterfaceHTTP.UserServicesResult();
		
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;  
			try{	
				MppInterfaceHTTP mppCallout = new MppInterfaceHTTP();
				mppUserServicesInfo = mppCallout.getUserServicesByMppGuid(thisSubscriber.mppGuid); 
				currentRuleResult = '200'; // success - data returned OK				
		     	thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);
		    }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
		       	currentRuleResult = '500'; // error - exception occured
	    		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e));
	    	}    
		}
		return mppUserServicesInfo;
	}

	public static subscriberOverviewResult retrieveUserOrderHistoryResultForMppGuid(subscriberOverviewResult thisSubscriber){
		string currentRule = 'mppUserOrderHistoryCallData';   // this rule will get MPP Orders for this user
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c)	 // check if the rule is active, before running it
		{
			String currentRuleResult;  		
	        thisSubscriber.mppUserOrderHistory = new MPPInterfaceHTTP.UserOrderHistoryResult();
		    try
		    	{  	MppInterfaceHTTP mppCallout = new MppInterfaceHTTP(); 
					thisSubscriber.mppUserOrderHistory = mppCallout.callUserOrderHistoryByMppGuid(thisSubscriber.mppGuid);
					currentRuleResult = '200'; // success - orders retrieved OK
		    	    thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, '200'); }
			catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e)
	    		{   currentRuleResult = '500'; // error - an exception occured
	    			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e)); }
		}
		return thisSubscriber;
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Generates rule engine instances for TSNumber and GUID existence in MPP
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/05/2015  //fixed messages returned, re-arranged code a bit, added constants
    ****************************************************************************************/
	private static ValidateMPPWrapper validateMppStoringTSNumberAndGuid(subscriberOverviewResult thisSubscriber){			
		String currentRule = Constants.MPP_RULE_NAME_ID_FIELDS_EXIST;   // this rule will check if MPP is storing a TS Number and GUID for the subscriber (it should always)
		Boolean mppHasTSNumber = false;
		Boolean mppHasGuid = false;
		ValidateMPPWrapper result = new ValidateMPPWrapper();
		
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;  			
			try{
		        for(MPPInterfaceHTTP.AccountDetailParameters accDetails : thisSubscriber.mppUserInfo.AccountDetailParameters){ 
		         	if(accDetails.ParameterName == Constants.MPP_PARAMETER_TSNUMBER){
		         		 result.mppTSNumber = accDetails.ParameterValue;
		        		 mppHasTsNumber = true;
		        		 currentRuleResult = '100'; // OK - MPP has a Subscriber TS Number
		        		 thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
		        	}
		        	if(accDetails.ParameterName == Constants.MPP_PARAMETER_SAMGUID && String.isNotBlank(accDetails.ParameterValue)){	
		        		result.mppSAMGuid = accDetails.ParameterValue;
		        		mppHasGuid = true;
		        		currentRuleResult = '200'; // OK - MPP has a SAM GUID
		        		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
		        	} 
		        }   			
				
				if(!mppHasTsNumber){
					currentRuleResult = '500'; // error - MPP does not have a TS Number
					thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('MPP Account does not have TS Number value: ' + thisSubscriber.mppUserInfo.AccountDetailParameters));
				}
				if(!mppHasGuid && thisSubscriber.SAMGuid != null){
					currentRuleResult = '600'; // error - MPP does not have a SAM GUID, but it should do as a SAM GUID does exist for this user
					thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('MPP does not have a SAM Guid value, but SAM does: ' + thisSubscriber.mppUserInfo.AccountDetailParameters + ' SAM Guid:' + thisSubscriber.SAMGuid));
				}else if(!mppHasGuid && thisSubscriber.SAMGuid == null && thisSubscriber.sfAccountInformation.Guid__c == null) {
					currentRuleResult = '300'; // OK - MPP does not have a SAM Guid but neither does SAM or SF so it is OK
					thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('MPP does not have a SAM Guid but neither does SAM or SF'));	 
				}else if(!mppHasGuid && thisSubscriber.SAMGuid != null && thisSubscriber.sfAccountInformation.Guid__c == null){ // MPP and SF do not have a SAM Guid but SAM does
					currentRuleResult = '700'; // error - MPP and Salesforce do not have a SAM GUID, but they should do as SAM did return a GUID
					thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);	 	
				}
			}catch(exception e){
				currentRuleResult = '800'; // error - an exception occurred
				thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured: ' + e));
			}  
		}  		  
		return result;
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Generates rule engine instances for TSNumber and GUID comparison result between SFDC and MPP
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/05/2015  //re-organised code, added constants
    ****************************************************************************************/
	private static void validateMppHasCorrectTSNumberAndGuid(subscriberOverviewResult thisSubscriber){
		String currentRule = Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC;   // this rule will check if MPP 
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;	
			Boolean mppHasCorrectTSNumber = false;
			Boolean mppHasCorrectGuid = false;
			String mppErrorGuid;
			String mppErrorTSNumber;		
			
			try{
				for(MPPInterfaceHTTP.AccountDetailParameters accDetails : thisSubscriber.mppUserInfo.AccountDetailParameters){
				  	if(accDetails.ParameterName == Constants.MPP_PARAMETER_TSNUMBER && accDetails.ParameterValue == thisSubscriber.TSNumber){
			        	mppHasCorrectTSNumber = true;
			        }else if(accDetails.ParameterName == Constants.MPP_PARAMETER_TSNUMBER && accDetails.ParameterValue != thisSubscriber.TSNumber){
			        	mppHasCorrectTSNumber = false;
			        	mppErrorTSNumber = accDetails.ParameterValue;
			        }
			        		
			        if(accDetails.ParameterName == Constants.MPP_PARAMETER_SAMGUID && accDetails.ParameterValue == thisSubscriber.SAMGuid){
			        	mppHasCorrectGuid = true;
			        }else if(accDetails.ParameterName == Constants.MPP_PARAMETER_SAMGUID && accDetails.ParameterValue != thisSubscriber.SAMGuid){	
			        	mppHasCorrectGuid = false;  
			        	mppErrorGuid = accDetails.ParameterValue;
			        }	
			   	}   			
			  
			  	if(mppHasCorrectTSNumber){
			  		currentRuleResult = '100'; // ok - MPP TS Number matches the Subscriber TS Number
			  		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);   
			  	}else if(!mppHasCorrectTSNumber && mppErrorTSNumber != null){   
			  		currentRuleResult = '500'; // error - MPP TS Number does not match the Subscriber TS Number
			  		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('SFDC TS Number: ' + thisSubscriber.TSNumber + ' MPP TS Number: ' + mppErrorTSNumber));  
			  	}		
			  	
			  	if(mppHasCorrectGuid){	
			  		currentRuleResult = '200'; // ok - MPP SAM Guid matches the SAM guid value
			  		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);    
			  	}else if (!mppHasCorrectGuid && mppErrorGuid != null){	
			  		currentRuleResult = '600'; // error - MPP SAM Guid does not match the SAM guid value
			  		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('SAM GUID: ' + thisSubscriber.SAMGuid + ' MPP SAM Guid: ' + mppErrorGuid));      	
			  	}
			}catch(exception e){
				currentRuleResult = '700'; // error - an exception occurred
				thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('An exception occured : ' + e));
			}
		}
	}  
	
	private static void validateSfAccountHasCorrectGuid(subscriberOverviewResult thisSubscriber){
		String currentRule = 'sfAccountGuidValidation';   // this rule will check if MPP 
		if(subscriberValidationRuleInfoV2__c.getInstance(currentRule).Active__c){	 // check if the rule is active, before running it
			String currentRuleResult;
			if(thisSubscriber.sfAccountInformation.Guid__c == thisSubscriber.SAMGuid && thisSubscriber.sfAccountInformation.Guid__c != null){
				currentRuleResult = '100';  // ok - salesforce Account has the correct GUID value
	  			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult); 
			} else if(thisSubscriber.sfAccountInformation.Guid__c == null && thisSubscriber.SAMGuid != null){   
	  			currentRuleResult = '600'; // error - salesforce account does not have a SAM GUID value, but SAM did return one
	  			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);	
	  		}else if(thisSubscriber.sfAccountInformation.Guid__c == null && thisSubscriber.sfAccountInformation.RecordTypeId == Constants.PREMIUM_RECORDTYPE && thisSubscriber.SAMGuid == null){	
	  			currentRuleResult = '200'; // ok - salesforce account does not have a SAM GUID value, but it is OK as the subscriber is a print subscriber, and not all print subscribers have a SAM user
	  			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRule(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult);	  				  			
	  		}else{	
	  			currentRuleResult = '500'; // error - salesforce guid and sam guid values do not match
	  			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.logNewSubscriberRuleWithData(thisSubscriber.subscriberRuleLog, currentRule, currentRuleResult, JSON.serialize('sfAccount GUID: ' + thisSubscriber.sfAccountInformation.Guid__c + ' does not match SAM GUID: ' +  thisSubscriber.SAMGuid));	  		
	  		}
		}
	}	
	
	private static void checkEntitlementInfo(subscriberOverviewResult thisSubscriber){
   		if(thisSubscriber.sfAccountInformation.RecordTypeId == Constants.DIGITAL_RECORDTYPE)
   			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.checkEntitlementsForDigitalSub(thisSubscriber.samAccountAndEntitlementInfo, thisSubscriber.sfAccountInformation, thisSubscriber.subscriberRuleLog);  					
   		else if(thisSubscriber.sfAccountInformation.RecordTypeId == Constants.PREMIUM_RECORDTYPE)		     	
   			thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(thisSubscriber.samAccountAndEntitlementInfo, thisSubscriber.sfAccountInformation, thisSubscriber.subscriberRuleLog);  			     		
	}		

	private static void checkOrderInfo(subscriberOverviewResult thisSubscriber){
 		thisSubscriber.subscriberRuleLog = subscriberConsolesWebserviceHandlers.compareMppToSfOrders(thisSubscriber.sfOrderInformation, thisSubscriber.mppUserOrderHistory, thisSubscriber.subscriberRuleLog);
	}	
}