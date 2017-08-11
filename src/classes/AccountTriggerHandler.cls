/**
* @author Unknown
* @date Unknown
* @description Handler class for Account trigger
#############Change Log#############
Modified by     	Version     Change Date
Wiktor Czykin   	1.1         10/02/2015  //made sure singleton pattern actually works, got rid of two external helper classes
Wiktor Czykin   	1.2         24/06/2015  //modified updateSamUserDetails()
Cristina Anghenie 	1.3         04/08/2015	//create new method for mpp single update
Michal Kwika    	1.4         11/11/2015  //new dependency based Custom setting on Update event
Michal Kwika    	1.5         11/02/2016  //override Salutation field if Given Title is entered
Wiktor Czykin		1.6         22/02/2016	//modified callCoreApiAccountEventCallout() to call bulk safe method, minor clean-up
Wiktor Czykin		1.7         27/02/2016	//added bRunAPI support for CoreApi callout
Sally ElGhoul		1.8         01/04/2016	//Adding Webservice logging for CoreAPi Inbound
Wiktor Czykin		1.9         13/04/2016	//removed updateRegistrantMarketingPreferences() as cannot default flags to true, modified setNewMarketingFlags()
Michal Szewczyk 	2.0         28/04/2016	//modified updateSamUserDetails()
Wiktor Czykin 		2.1         04/11/2016  //modified callCoreApiAccountEventCallout()
Mantas Grigaliunas	2.2         26/10/2016	//added preventMarkingMasterAsDuplicate() method
Wiktor Czykin 		2.3         04/11/2016  //modified callCoreApiAccountEventCallout()
Wiktor Czykin		2.3	    	27/11/2016  //modified updateSamUserDetails() and checkAccountValidity()
Wiktor Czykin		2.4			27/01/2017	//added entitlements logic for Registrants when Force_Entitlement_Update__c field is ticked
Vishant Shah        2.3         09/02/2017  //code improvments to reduce soql queries in execution
Pawel Chrzanowski   2.4         10/04/2017  //removed clearMarketingPreferences()
Pawel Chrzanowski   2.5         03/05/2017  //removed setNewMarketingFlags()
**/
public with sharing class AccountTriggerHandler {
	 
	private static AccountTriggerHandler instance;
	private Id tmgSystemProfileId; 
	private Id tmgWebApiProfileId;
	public Boolean isExecuting = false;
	public Boolean bRunAPI = true;

	public static AccountTriggerHandler getInstance() {
		if (instance == null) instance = new AccountTriggerHandler();
		return instance; 
	}

	public AccountTriggerHandler(){
		this.tmgSystemProfileId = Constants.getTMGSystemProfileId();
		
		//For registrant Account we should not call the Core API when the insert/update is 
		//carried out via an inbound call to SFDC.Inbound calls will run using the Web Api profile
	
		this.tmgWebApiProfileId = Constants.getTMGWebApiProfileId();
	}
	
	public void OnBeforeInsert(Account[] newAccounts){
		if (!this.isExecuting) {
			this.isExecuting = true;

			this.populateCountryAccountTrigger(newAccounts);
			this.formatPostcode(newAccounts);
			this.overrideSalutationWithGivenTitle(newAccounts);
			updateSecondPartyMarketingPreferences(AccountUtility.getRegistrantAccounts(newAccounts));

			this.isExecuting = false;        
		}
	} 
	
	public void OnAfterInsert(Account[] newAccounts){
		//Handle the Registrant record type and call the core Api message endpoint
		List<Account> lstRegistrantAccounts = new List<Account>();
		
		//Get the registrant Account record type
		Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()); 
		
		//filter the accounts with registrant record type
		for(Account accountObj : newAccounts){
			if(accountObj.RecordTypeId == registrantRecordTypeId){
				lstRegistrantAccounts.add(accountObj);
			}
		}
		
		//call "callCoreApiAccountEventCallout" for the registrant accounts which will handle the sync between salesforce , zuora and SAM
		if(!lstRegistrantAccounts.isEmpty()){
			//adding this check to enable Qas test the scenario if the call of coreApi didn't create zbilling Account successfully
			Boolean callCoreApi = Boolean.valueOf(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).Value__c);
			if(callCoreApi && this.bRunAPI){
				callCoreApiAccountEventCallout(Constants.NEW_RECORD_CREATED_ACTION_NAME, lstRegistrantAccounts);
			}
		}

		if (this.bRunAPI){
			addDefaultNewsLetters(null, newAccounts);
		}
	}
	
	public void OnBeforeUpdate(Account[] oldAccounts, Account[] updatedAccounts, Map<ID, Account> AccountMap){
		List<Account> lstRegistrantAccounts			= new List<Account>();
		Map<Id,Account> mapNewRegistrantAccounts	=new Map<Id,Account>();
		Map<Id,Account> OldAccountMap				=new Map<Id,Account>();	
		Map<Id,Account> mapOldRegistrantAccounts	=new Map<Id,Account>();
		
		//fill the old Map Account 
		for(Account accountObj :oldAccounts){
			if(!OldAccountMap.containsKey(accountObj.Id)){
				OldAccountMap.put(accountObj.Id,accountObj);
			}
		}
		
		//Get the registrant Account record type
		Id registrantRecordTypeId 			= RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		
		//filter the accounts with registrant record type
		for(Account accountObj : updatedAccounts){
			if(accountObj.recordTypeid==registrantRecordTypeId){ //Registrant Records
				lstRegistrantAccounts.add(accountObj);
				
				if(!mapOldRegistrantAccounts.containsKey(accountObj.Id)){
					mapOldRegistrantAccounts.put(accountObj.Id,OldAccountMap.get(accountObj.Id));
				}
				if(!mapNewRegistrantAccounts.containsKey(accountObj.Id)){
					mapNewRegistrantAccounts.put(accountObj.Id,AccountMap.get(accountObj.Id));
				}		
			}
		}
		
		if (!this.isExecuting) {
			this.isExecuting = true;
			
			this.populateCountryAccountTrigger(updatedAccounts);
			this.formatPostcode(updatedAccounts);
			this.validateAddressChanges(oldAccounts, AccountMap);
			this.overrideSalutationWithGivenTitle(updatedAccounts);
			this.preventMarkingMasterAsDuplicate(updatedAccounts, OldAccountMap);

			this.isExecuting = false;        
		}       
	}
	
    /***************************************************************************************
    Developer   Sally ElGShoul
    Date        11 May 2015
    Function    Handle the Registrant record type and call the core Api message endpoint and keep the same logic for old record types
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin		1.1			27/02/2016	//added bRunAPI check for callCoreAPI...()
    Wiktor Czykin		1.2			26/01/2017  //added Force_Entitlement_Update__c support for registrants
    ****************************************************************************************/
	public void OnAfterUpdateRouter(Account[] oldAccounts, Account[] updatedAccounts, Map<ID, Account> OldAccountMap, Map<ID, Account> NewAccountMap){
		
			//Adjust the maps
			List<Account> lstOldNonRegistrantAccounts = new List<Account>();
			List<Account> lstNonRegistrantUpdatedAccounts = new List<Account>();
			Map<Id,Account> mapOldNonRegistrantAccounts	= new Map<Id,Account>();
			Map<Id,Account> mapNonRegistrantUpdatedAccounts	= new Map<Id,Account>();
			List<Account> lstRegistrantAccounts	= new List<Account>();
			Set<Id> setRegistrantIdsToSyncEntitlements = new Set<Id>();

			//Get the registrant Account record type
			Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
			
			//filter the accounts with registrant record type
			for(Account accountObj : updatedAccounts){
				if(accountObj.recordTypeid == registrantRecordTypeId){ //Registrant Records
					lstRegistrantAccounts.add(accountObj);
					if(accountObj.Force_Entitlement_Update__c && accountObj.PersonEmail != null){
						setRegistrantIdsToSyncEntitlements.add(accountObj.Id);
					}
				} else { //Non Registrant Records
				   lstOldNonRegistrantAccounts.add(OldAccountMap.get(accountObj.Id));	
				   lstNonRegistrantUpdatedAccounts.add(NewAccountMap.get(accountObj.Id));
				   mapOldNonRegistrantAccounts.put(accountObj.Id, OldAccountMap.get(accountObj.Id));
				   mapNonRegistrantUpdatedAccounts.put(accountObj.Id, NewAccountMap.get(accountObj.Id));	
				}
			}
			
			//call "CallCoreApiAccountEventCallout" for the registrant accounts which will handle the sync between salesforce , zuora and SAM
			if(!lstRegistrantAccounts.isEmpty()){
				if (!this.isExecuting) {
					this.isExecuting = true;
					//adding this check to enable Qas test the scenario if the call of coreApi didn't create zbilling Account successfully
                    Application_Settings__c aSetting = Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION);
					if(aSetting!=null && String.isNotBlank(aSetting.Value__c) && Boolean.valueOf(aSetting.Value__c) && this.bRunAPI){
						callCoreApiAccountEventCallout(Constants.UPDATED_RECORD_ACTION_NAME, lstRegistrantAccounts);
					}
					if(!setRegistrantIdsToSyncEntitlements.isEmpty()){
						//replicated if that is there for non-registrants - dont think this line would ever be executed by the user that we have the prevention for, but just to be sure
						if((Label.ByPassSamUpdatesForUser == null || Label.ByPassSamUpdatesForUser != UserInfo.getUserName()) && (Label.SamUserId == null || Label.SamUserId != UserInfo.getUserName())){
							UpdateSamUserDetailsBatch.callSamForUpdateAsync(setRegistrantIdsToSyncEntitlements, true, true);
						}
					}
					this.isExecuting = false;
				}		
			}
			
		//Handle the non registrant accounts by calling the existing method as IS
		if(lstNonRegistrantUpdatedAccounts !=null && !lstNonRegistrantUpdatedAccounts.isEmpty()){
			OnAfterUpdate(lstOldNonRegistrantAccounts,lstNonRegistrantUpdatedAccounts,mapOldNonRegistrantAccounts,mapNonRegistrantUpdatedAccounts);
		}

		if (this.bRunAPI){
			addDefaultNewsLetters(OldAccountMap, updatedAccounts);
		}
	}
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - call logic on after update 
	#############Change Log#############
	Modified by     Version     Change Date
	Michal Szewczyk   1.1         28/04/2016  // removed check for account size =1  to allow update in bulk
	****************************************************************************************/
	public void OnAfterUpdate(Account[] oldAccounts, Account[] updatedAccounts, Map<ID, Account> oldAccountMap, Map<ID, Account> newAccountMap){
		if (!this.isExecuting) {
			this.isExecuting = true;
			
			if(this.bRunAPI){
				this.handleUserManageRequests(newAccountMap, oldAccountMap);
				this.updateSamUserDetails(oldAccounts, updatedAccounts, newAccountMap.keySet());
			}

			this.isExecuting = false;        
		}
	}
	
	public void OnBeforeDelete(Account[] AccountsToDelete, Map<ID, Account> AccountMap){}
	
	public void OnAfterDelete(Account[] deletedAccounts, Map<ID, Account> AccountMap){}
	
	public void OnUndelete(Account[] restoredAccounts){}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - Make sure the postcode is correctly formatted only if the country is set to GB
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         30/03/2015  //moved here from SubscriptionAccountTriggerHandler
	Wiktor Czykin	1.2			23/02/2016	//replaced value with Constant
	****************************************************************************************/
	public void formatPostcode(List<Account> lstAccounts){
		for(Account acc : lstAccounts){
			if(acc.PersonMailingCountry == Constants.COUNTRY_CODE_GB){
				acc.PersonMailingPostalCode = SubscriberPortal.FormatPostCode(acc.PersonMailingPostalCode);
			}
		}
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - Fix for PP-1346. If a user with "TMG System" profile is setting key address fields to null, revert the change in these field values to old value.
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         30/03/2015  //moved here from SubscriptionAccountTriggerHandler
	****************************************************************************************/
	public void validateAddressChanges(Account[] oldAccounts, Map<Id, Account> accountMap){
		if(UserInfo.getProfileId() == this.tmgSystemProfileId){
			for(Account oldAcc : oldAccounts){
				Account newAcc = accountMap.get(oldAcc.Id);
				
				if((newAcc.PersonMailingCity==null || newAcc.PersonMailingCity=='') && ( oldAcc.PersonMailingCity!=null && oldAcc.PersonMailingCity != '' )){
					newAcc.PersonMailingCity=oldAcc.PersonMailingCity;
				}
				if((newAcc.PersonMailingCountry==null || newAcc.PersonMailingCountry=='') && ( oldAcc.PersonMailingCountry!=null && oldAcc.PersonMailingCountry != '' )){
					newAcc.PersonMailingCountry=oldAcc.PersonMailingCountry;
				}
				if((newAcc.PersonMailingState==null || newAcc.PersonMailingState=='') && ( oldAcc.PersonMailingState!=null && oldAcc.PersonMailingState != '' )){
					newAcc.PersonMailingState=oldAcc.PersonMailingState;
				}
				if((newAcc.PersonMailingStreet==null || newAcc.PersonMailingStreet=='') && ( oldAcc.PersonMailingStreet!=null && oldAcc.PersonMailingStreet != '' )){
					newAcc.PersonMailingStreet=oldAcc.PersonMailingStreet;
				}
				if((newAcc.PersonMailingPostalCode==null || newAcc.PersonMailingPostalCode=='') && ( oldAcc.PersonMailingPostalCode!=null && oldAcc.PersonMailingPostalCode != '' )){
					newAcc.PersonMailingPostalCode=oldAcc.PersonMailingPostalCode;
				}
			}
		}
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.6
	Function - calls SAM update future methods
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         26/02/2015  //modified batch instantiation to future method call
	Wiktor Czykin   1.2         30/03/2015  //moved to AccountTriggerHandler
	Cristina Popescu1.3         10/06/2015  //add CheckAccountValidity from the afterUpdate method and 
											send to SAM only the accounts that have an emai address  
	Wiktor Czykin   1.4         24/06/2015  //removed OverrideSAMUpdate__c custom setting dependency
	Michal Szewczyk 1.5			28/04/2016  //raplace callSamForSingleUpdate with callSamForUpdateAsync
	Wiktor Czykin 	1.6			24/11/2016	//restored behaviour where if multiple accounts then always update SAM
	****************************************************************************************/
	public void updateSamUserDetails(List<Account> oldAccounts, List<Account> updatedAccounts, Set<Id> lstAccountIds){
		System.debug('### AccountTriggerHandler.updateSamUserDetails FUNCTION START');
		Set<Id> accountsWithEmail = new Set<Id>();
		// Don't bother with this if we've been here before or the SAM service isn't active
		if(SubscriberPortal.SUB_TRIGGER_FIRED || SubscriberPortal.SAM_WS_UPDATE)
			return;

		if(System.isBatch() || System.isFuture() || lstAccountIds == null) return;

		Boolean bIsValidUpdate = checkAccountValidity(oldAccounts, updatedAccounts);
		//get only the accounts that have email address to be synced with SAM
		for (Account acc : updatedAccounts){
			if (!String.isBlank(acc.PersonEmail)){
				accountsWithEmail.add(acc.Id);
			}
		}
		
		if((Label.ByPassSamUpdatesForUser == null || Label.ByPassSamUpdatesForUser != UserInfo.getUserName()) && (Label.SamUserId == null || Label.SamUserId != UserInfo.getUserName())){
			if(!accountsWithEmail.isEmpty()){
				if(bIsValidUpdate){
					UpdateSamUserDetailsBatch.callSamForUpdateAsync(accountsWithEmail, true, false);
				}
			}
		}
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - method that checks if SAM update should be done
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         24/11/2015  //modified the conditions to make sure true is returned for multiple records and added Current_Week_Position_Final__c to triggering fields
	Pawel Chrzanowski  1.2      03/05/2017  //removed unused Marketing Preferences
	****************************************************************************************/
	public static Boolean checkAccountValidity(List<Account> oldAcc, List<Account> newAcc){
		Boolean checkValue = false;
		Set<String> setFieldsToCheck = new Set<String>{	'Salutation', 'LastName', 'FirstName', 'PersonEmail',  'PersonMailingStreet', 'PersonMailingCity',
														'PersonMailingPostalCode',  'PersonMailingCountry', 'PersonMailingState', 'TMG_Promo_Email__c', 'TMG_Promo_Phone__c',
														'TMG_Promo_Post__c', 'TMG_Promo_SMS__c'};
 
		if(oldAcc.size() == 1 && newAcc.size() == 1){
			// This is to check for Print Subscribers, next check is for Digital Subscribers, all other record types do not need to be checked for Account Validity.
			if(oldAcc[0].recordTypeId == Constants.PREMIUM_RECORDTYPE || oldAcc[0].recordTypeId == Constants.DIGITAL_RECORDTYPE){
				if(newAcc[0].Force_Entitlement_Update__c){
					checkValue = true;
				}else if(oldAcc[0].recordTypeId == Constants.PREMIUM_RECORDTYPE && oldAcc[0].Subscription_Status__c != newAcc[0].Subscription_Status__c ){
					checkValue = true;
				}else if (oldAcc[0].recordTypeId == Constants.DIGITAL_RECORDTYPE && oldAcc[0].Subscriber_Digital_Status__c != newAcc[0].Subscriber_Digital_Status__c){
					checkValue = true;
				}else{
					for(String sField : setFieldsToCheck){
						if(oldAcc[0].get(sField) != newAcc[0].get(sField)){
							checkValue = true;
							break;
						}
					}
				}
			} else {
				checkValue = true;
			}
		}else if(newAcc.size() > 1){
			checkValue = true;
		}
		return checkValue;
	}

	/*************************************************************************************** 
	Developer - Unknown/Wiktor Czykin
	Date - 01/04/2015
	Version - 1.0
	Function -  sets Country_Name__c based on custom settings - moved here from PopulateCountryAccountTrigger
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private void populateCountryAccountTrigger(List<Account> lstNewAccounts){
		for(Account accRec : lstNewAccounts){
			try{
				if(accRec.PersonMailingCountry != null){
					accRec.Country_Name__c = Country_Codes__c.getValues(accRec.PersonMailingCountry).Country_Name__c;
				}
			}catch(Exception ex){
				System.debug('Country code not found in custom settings :'+ex);
			}
		}
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -  Call the MPP Webservice to update subscriber email.
				Will need to check the MPP flag on subscriber.
				CALLS FUTURE METHOD
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         31/03/2015  //moved here from MPPAccountTriggerHandler
	Cristina Anghenie1.2        04/08/2015  //create new method from MPP single call update
	****************************************************************************************/
	public void handleUserManageRequests(Map<Id, Account> newMap, Map<Id, Account> oldMap){
		System.debug('### AccountTriggerHandler.handleUserManageRequests FUNCTION START');
		if(newMap == null || newMap.isEmpty() || oldMap == null || oldMap.isEmpty() || Constants.MPP_CALLOUT_DISABLED) return;
		Map<Id, String> accMap = new Map<Id, String>(); 
		
		for(Account acc :newMap.values()){
			//Is this Subscriber related to MPP.
			if(acc.IsUsingMPP__c && acc.IsPersonAccount && oldMap.containskey(acc.Id)){
				Account old = oldMap.get(acc.Id);
				//Check if any details have changed.
				if(mppDetailsChanged(acc, old)){
					if (newMap.size() == 1){
						accMap.put(acc.Id,old.PersonEmail);
					}else 
						accMap.put(acc.Id, createUserMap(old));
				}
			}
		}
		
		if(accMap.isEmpty()){
			return;
		}
		
		//Send updated details to MPP.
		if (accMap.size() == 1){
			MPPInterfaceHTTP.invokeSingleFutureUserManageRequest(accMap);
		}else
			MPPBulkSFDCSoapInterface.invokeFutureUserManageRequest(accMap);
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -  helper method for handleBulkUserManageRequests()
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         31/03/2015  //moved here from MPPAccountTriggerHandler
	Crstina Anghenie1.2			01/12/2015	//remove personEmail != null from method
	****************************************************************************************/
	@TestVisible private Boolean mppDetailsChanged(Account a, Account b){
		return (( a.Salutation != null && a.Salutation != b.Salutation)
					|| (a.FirstName != null && a.FirstName != b.FirstName)
					|| (a.LastName != null && a.LastName != b.LastName)
					|| (a.PersonEmail != b.PersonEmail));
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -  helper method for handleBulkUserManageRequests()
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         31/03/2015  //moved here from MPPAccountTriggerHandler
	****************************************************************************************/
	@TestVisible private String createUserMap(Account b){
		return (getValidValue(b.Salutation) + ',' + getValidValue(b.FirstName) + ',' + getValidValue(b.LastName) + ',' + getValidValue(b.PersonEmail));
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -  helper method for createUserMap()
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         31/03/2015  //moved here from MPPAccountTriggerHandler
	****************************************************************************************/
	@TestVisible private String getValidValue(String sValue){
		if(String.isBlank(sValue)){
			return '';
		}else{
			return sValue.trim();
		}
	}
	
	/*************************************************************************************** 
	Developer   Sally ElGhoul (Tquila)
	Date        28/04/2015
	Function    this function is called to return the registrant accounts only from a List of accounts
	******************* Change Log *******************
	Modified by         Version     Change Date
	Sally ElGhoul 		1.1         02/07/2015
	Wiktor Czykin		1.2			22/02/2016 //changed to bulk safe future method
	Sally ElGhoul		1.3			01/04/2016 //add a webservice log for core api call to create an account
	Wiktor Czykin		1.4			04/11/2016 //disabled callout for TMG System profile
	****************************************************************************************/
	public void callCoreApiAccountEventCallout(String strActionName, List<Account> lstAccounts){
		System.debug('### AccountTriggerHandler.callCoreApiAccountEventCallout FUNCTION START');
		//For registrant Account we should not call the Core API when the insert/update is carried out via an inbound call to SFDC.Inbound calls will run using the Web Api profile
		Set<Id> setIds = new Set<Id>();
		for(Account acc : lstAccounts){
			if(acc.Id != null){
				setIds.add(acc.Id);
			}
		}
		Id userProfileId = UserInfo.getProfileId();
		if(userProfileId != this.tmgWebApiProfileId && userProfileId != this.tmgSystemProfileId){
			CoreAPICalloutUtility.sendBulkEvents(strActionName, Account.class.getName(), setIds);
		}else if(userProfileId == this.tmgWebApiProfileId){
			WebService_Log__c webserivceLogObj = TMGUtil.logWebServiceRequestSerialized(Constants.DIRECTION_INBOUND,null,String.format(Constants.LOG_GET_CORE_API_UPSERT_ACCOUNT,new List<String>{strActionName}), setIds); 
		}
	}
	
	/*************************************************************************************** 
	Developer   Sally ElGhoul (Tquila)
	Date        20/07/2015
	Function    this function is called to update the 2nd party marketing preference on Account creation from SF
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public void updateSecondPartyMarketingPreferences(List<Account> lstAccounts){
		for(Account accountObj : lstAccounts){
			if(accountObj.isNewAccountOptIn__c){
				accountObj.TMG_Promo_Email__c=1;
				accountObj.TMG_Promo_Post__c=1;
			}
		}
	}
	
	/*************************************************************************************** 
	Developer   Michal Kwika (Accenture)
	Date        11/02/2016
	Function    this function is called to override Salutation field if Given Title is present
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public void overrideSalutationWithGivenTitle(List <Account> lAccs){
		for(Account acc: lAccs){
			if(String.isNotBlank(acc.Title__c) && acc.IsPersonAccount){
				acc.Salutation = acc.Title__c;
				acc.Title__c = '';
			}
		}
	}

	/*************************************************************************************** 
	Developer   Mantas Grigaliunas
	Date        26/10/2016
	Function    A function to prevent marking the account as duplicate if it already has duplicate accounts linked to it
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public void preventMarkingMasterAsDuplicate(List<Account> updatedAccountsList, Map<Id, Account> oldAccountsMap){

		//check if account is marked as duplicate
		List<Account> updatedDuplicateAccountsList = new List<Account>();
		for(Account acc : updatedAccountsList){
			if(acc.Duplicate_Of__c != null && acc.Duplicate_Of__c != oldAccountsMap.get(acc.Id).Duplicate_Of__c){
				updatedDuplicateAccountsList.add(acc);
			}
		}

		if(updatedDuplicateAccountsList.size() > 0){
			//check if duplicate account actually is not a master account for any other accounts
			Map<Id, List<String>> existingDuplicatesMap = new Map<Id, List<String>>();
			List<Account> existingDuplicateAccountsList = 
				[ SELECT Id, Name, Duplicate_Of__c FROM Account WHERE Duplicate_Of__c IN :updatedDuplicateAccountsList ];

			if(existingDuplicateAccountsList.size() > 0){

				for(Account newAcc : updatedDuplicateAccountsList){
					for(Account existingAcc : existingDuplicateAccountsList){
						if(newAcc.Id == existingAcc.Duplicate_Of__c){
							if(existingDuplicatesMap.get(newAcc.Id) == null)
								existingDuplicatesMap.put(newAcc.Id, new List<String>{existingAcc.Name});
							else
								existingDuplicatesMap.get(newAcc.Id).add(existingAcc.Name);
						}
					}
				}
			}
			//add the error message for the affected account records
			for(Account acc : updatedAccountsList){
				if(existingDuplicatesMap.containsKey(acc.Id))
					acc.addError(String.format(Label.Account_Duplicate_Master_Error, 
						new List<String>{String.join(existingDuplicatesMap.get(acc.Id), ', ')}));
			}
		}
	}

	/*************************************************************************************** 
	Developer   Vishant Shah
	Date        28/02/2017
	Function    method to add default newsletters to accounts. as guid is created from a queue/future call.. 
				we add default newsletter if a guid gets updated on the account too.
	******************* Change Log *******************
	Modified by         Version     Change Date
	Vishant Shah		1.1			20/03/2017	// Added exclusion if execution is from future method.
	****************************************************************************************/
	private void addDefaultNewsLetters(Map<ID, Account> oldAccounts, List<Account> newAccounts){

		if (!System.isFuture()){
			Boolean bAddDefaultNewsLetters = true;

			Application_Settings__c appSetting;
	        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_EVENT_END_POINT_NAME);
	        if(appSetting == null && bAddDefaultNewsLetters) bAddDefaultNewsLetters = false;

	        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_UPGRADE_END_POINT_NAME);
	        if(appSetting == null&& bAddDefaultNewsLetters) bAddDefaultNewsLetters = false;

	        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_PUT_OFFER_END_POINT_NAME);
	        if(appSetting == null && bAddDefaultNewsLetters) bAddDefaultNewsLetters = false;

	        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_GET_OFFERS_BY_PRODUCT_AND_FREQUENCY);
	        if(appSetting == null && bAddDefaultNewsLetters) bAddDefaultNewsLetters = false;

	        if (!bAddDefaultNewsLetters){
	          	return;
	        }

			Id individualSubscriberRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME , Account.class.getName()); 

			List<Account> accountsForDefaultNewsLetters = new List<Account>();

			for(Account acc : newAccounts){

				if (acc.RecordTypeId == individualSubscriberRecordTypeId){
					Account oldAccount;
					if (oldAccounts != null){
						oldAccount = oldAccounts.get(acc.Id);
					}

					if(acc.Guid__c != null && acc.Email__c != null && oldAccounts == null){
						accountsForDefaultNewsLetters.add(acc);
					} else if (acc.Guid__c != null && acc.Email__c != null && oldAccount != null && oldAccount.Guid__c == null ){
						accountsForDefaultNewsLetters.add(acc);
					}
				}
			}

			if (!accountsForDefaultNewsLetters.isEmpty()){
				DefaultNewlettersQueueable defaultNewsletters = new DefaultNewlettersQueueable(accountsForDefaultNewsLetters, null, null);
				System.enqueueJob(defaultNewsletters);
			}
		}
	}
}
