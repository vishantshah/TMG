/* ------------------------------------------------------------------------------
   Name:        DecommissionSamAccountController.cls
   Description: Controller class for DecommissionSamAccount.page  

   Date         Version Author              Summary of Changes 
   -----------  ------- -----------------   -------------------------------------
   27/08/2015   1.1     Cristina Anghenie 	Search for account with wrong data in SAM    
   16/12/2015	1.2		Wiktor Czykin		Added MPP callout for email changes - partial bulk fix support  
   07/01/2016	1.3		Wiktor Czykin		Modified decommissionAccounts(); 
   08/01/2016	1.4		Wiktor Czykin		Modified the limitation on the loop of accounts with the same guid as guid was made unique. Left the loop itself for time being.
   31/10/2016   1.5     Michal Szewczyk		Added email population for SF account in  decommissionAccounts()
--------------------------------------------------------------------------------- */
public with sharing class DecommissionSamAccountController {
	
	public String email {get;set;}
	public List<Account> existingAccs {get;set;}
	public Boolean displayDecomButton {get;set;}
	public SAMInterfaceHTTP.SamUserDetails samDetailsResponse {get;set;}
	public SamUtil.SAMAccountResult result {get;set;}
	public List<MPPDecommissionResult> lstMPPResults {get;set;} 
	public Boolean bMPPFailure{get;set;}
	
	/*************************************************************************************** 
	Developer - Cristina Anghenie
	Date - 02/08/2015
	Version - 1.1
	Function - constructor
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			16/12/2015	//added 2 new attributes initialization
  	****************************************************************************************/
	public DecommissionSamAccountController(){
		this.existingAccs = new List<Account>();
		this.lstMPPResults = new List<MPPDecommissionResult>();
		this.bMPPFailure = false;
	}
	
	/*************************************************************************************** 
	Developer - Cristina Anghenie
	Date - 02/08/2015
	Version - 1.1
	Function - search records in SAM and return guid to search records in SFDC
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			16/12/2015	//added Id field to soql
  	****************************************************************************************/
	public void searchSAMandSFDC(){
		this.displayDecomButton = false;
		this.bMPPFailure = false;
		this.lstMPPResults = new List<MPPDecommissionResult>();
		
		if (String.isBlank(this.email)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Decommission_NoEmail));    
		}else{
			SamUtil su = new SamUtil();
			this.result = new SamUtil.SAMAccountResult();
			//using email address added by user get guid from SAM
			try{
	            this.result = su.getExistingSAMAccount(this.email);
	        }catch(WebserviceUtil.SamException e){
	            if(e.getError().errorMessage.contains('ACCOUNT_LOCKED')) {
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'SAM account is locked.'));
	            }
	        }
			//if records were found in sam and guid is not null
			if (!String.isBlank(this.result.guid)){
				//display information from SAM related to the specified email address
				this.displaySamInfo(this.email, this.result.guid);
				//search records in SFDC that have the specified guid
				this.existingAccs = [SELECT Id,
											FirstName, 
											LastName, 
											Salutation,
											Subscription_Status__c, 
											Subscriber_Number_static__c, 
											PersonMailingStreet, 
											PersonMailingCity, 
											PersonMailingPostalCode, 
											PersonEmail, 
											RecordType.Name, 
											Subscriber_Digital_Status__c, 
											IsPersonAccount,
											Guid__c, 
											Subscriber_Number__c
								FROM Account
								WHERE Guid__c =: result.guid];
				if (existingAccs.isEmpty()){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Decommission_NoSFDCrecords)); 
				}
			}else{
				 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Decommission_NoSAMrecords));
			}
		}
	} 
	
	/*************************************************************************************** 
	Developer - Cristina Anghenie
	Date - 02/08/2015
	Version - 1.0
	Function - display information about sam account based on the specified email address and guid
	#############Change Log#############
	Modified by     Version     Change Date
  	****************************************************************************************/
	public void displaySamInfo(String email, String samGuid){
    	try{
    		this.samDetailsResponse = SAMInterfaceHTTP.getUserDetails(email, samGuid);
    		if(this.samDetailsResponse == null){
    			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Decommission_NoSAMrecords)); 
    		}else this.displayDecomButton = true;
    	} catch(Exception ex){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
    	}
    }
    
    /*************************************************************************************** 
	Developer - Cristina Anghenie
	Date - 02/08/2015
	Version - 1.0
	Function - decommission sam account and remove guid from all records in SFDC
	#############Change Log#############
	Modified by     Version     Change Date
	Cristina A.     1.1         29/10/2015 	//if there is no sam salutation default to 'Mr'
	                                       and remove entitlements only if there are any
	Wiktor Czykin	1.2			16/12/2015	//added MPP callout
	Wiktor Czykin	1.3			07/01/2016	//added bulk logging support for SAMUtil callout
	Michal Szewczyk	1.4			31/10/2016  //added email population for SF account
  	****************************************************************************************/
    public void decommissionAccounts(){
    	//update sam account details
    	SubscriberPortal.Subscriber subscriber = new SubscriberPortal.Subscriber(null, this.samDetailsResponse.guid, null, null, true, true, null, null, null);
    	Account decommissionAccount = new Account(Salutation = (this.samDetailsResponse!=null ? this.samDetailsResponse.salutation : 'Mr'),
				    							  FirstName = Constants.DECOM_FIRSTNAME, 
				    							  LastName = Constants.DECOM_LASTNAME, 
				    							  PersonEmail = this.samDetailsResponse.emailAddress + Constants.DECOM_EMAIL,
				    							  PersonMailingStreet = Constants.DECOM_STREET,
				    							  PersonMailingCity = Constants.DECOM_CITY,
				    							  PersonMailingPostalCode = Constants.DECOM_POSTCODE);
    	try{
    		//remove sam entitlements
    		SAMInterfaceHTTP.bulkUpdateResponse response;
    		if(this.result.entitlements != null){
    			response = SAMInterfaceHTTP.updateSubscriptionEntitlement(this.email, this.result.guid, new Set<String>(this.result.entitlements), SAMInterfaceHTTP.EntitlementUpdateType.REMOVE);
	            if(response.statusCode != SAMInterfaceHTTP.ResponseStatusCodes.SUCCESS){
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, response.message));
	            }
    		}
    		if(response == null || response.statusCode == SAMInterfaceHTTP.ResponseStatusCodes.SUCCESS){
    			
    			MPPInterfaceHTTP mppRequest = new MPPInterfaceHTTP();
		    	mppRequest.bUseBulkLogging = true;
		    	
    			//remove guid from all accounts in salesforce
		    	for (Account acc : this.existingAccs){
		    		//remove email from salesforce if email address linked to the account is the same as the email decommission
		    		if(acc.PersonEmail == this.email){
		    			try{
			    			mppRequest.UserManageSingleUpdate(acc.Subscriber_Number_static__c, null, acc.PersonEmail, decommissionAccount.Salutation, decommissionAccount.FirstName, decommissionAccount.LastName, null);
		    				this.lstMPPResults.add(new MPPDecommissionResult(true, acc.Subscriber_Number_static__c, acc.Id));
		    			}catch(Exception e){
		    				this.lstMPPResults.add(new MPPDecommissionResult(false, acc.Subscriber_Number_static__c, acc.Id));
		    				this.bMPPFailure = true;
		    			}
		    			acc.PersonEmail = this.samDetailsResponse.emailAddress + Constants.DECOM_EMAIL;
		    		}
		    		acc.Guid__c = null;
		    	}

    			SamUtil sUtil = new SamUtil();
    			sUtil.bUseBulkLogging = true;
    			sUtil.updateSamAccount(subscriber, decommissionAccount, Constants.DECOM_DELETED, this.samDetailsResponse.guid, '', true);
    				    	
	    		AccountTriggerHandler.getInstance().bRunAPI = true;
	    		update existingAccs;
	    		AccountTriggerHandler.getInstance().bRunAPI = false;
    			mppRequest.saveLogBuffer();
    			sUtil.saveLogBuffer();
    			
    			if(this.bMPPFailure){
    				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Decommission_page_Warning_on_MPP_issues)); 
    			}else{
	    			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Decommission_Success));
    			} 
	    		this.displayDecomButton = false;
    		}
    	}catch(Exception ex){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
    	}
    }
    
    /**
	* @author Wiktor Czykin
	* @date 16/12/2015
	* @description Wrapper class for mpp update results
	#############Change Log#############
	Modified by     Version     Change Date
	**/
    public class MPPDecommissionResult{
    	public Boolean bResult{get;set;}
    	public String sTSNumber{get;set;}
    	public Id accountId{get;set;}
    	
    	public MPPDecommissionResult(Boolean bResult, String sTSNumber, Id accountId){
    		this.bResult = bResult;
    		this.sTSNumber = sTSNumber;
    		this.accountId = accountId;
    	}
    }
}