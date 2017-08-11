/**
* Author:       Sally ElGhoul (Tquila)
* Date:         30/07/2015
* Description:  this class is the constructor for the Zuora_ManageSubscriptionRedirect page
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
public class Zuora_ManageSubscriptionRedirectCont {
	
	public zqu.NotificationOptions notificationOptions {get;set;}
	
	public Zuora_ManageSubscriptionRedirectCont(){
		
		//Init notification options for the notification component
		notificationOptions = new zqu.NotificationOptions();
	    notificationOptions.isPopup = true;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        30/07/2015
    Function    This function is called to redirect the user to either new  subscription flow, amend subscription flow or revoke cancellation
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	public pageReference RedirectManageSubscription(){
		
		if(!ApexPages.CurrentPage().getParameters().containsKey(constants.SF_ACCOUNT_ID_QUERY_STRING)){
			 notificationOptions.backAction = 'goToListAccountaPage();';
			 //add the message 
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_Missing_Account_ID));
			return null;
		} else {

			string sfcAccountId=ApexPages.currentPage().getParameters().get(constants.SF_ACCOUNT_ID_QUERY_STRING);
			
			if(isValidAccountId(sfcAccountId)){
				//Sub-665 change for pending activation satus
				list<Zuora__Subscription__c> lstSubscriptions=[select Zuora__Status__c,Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,Zuora__Zuora_Id__c,id from Zuora__Subscription__c where (Zuora__Status__c=:constants.SUBSCRIPTION_ACTIVE_STATUS or Zuora__Status__c=:constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS or Zuora__Status__c=:constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS) and Zuora__Account__c=:sfcAccountId limit 1];
				string redirectUrl='';
				if(lstSubscriptions==null || lstSubscriptions.size()==0){
					
					//redirect the user to the quote wizard in new subscription mode
					redirectUrl=string.format(constants.NEW_QUOTE_WIZARD_PAGE_URL,new list<string>{getInstanceURL(),sfcAccountId,sfcAccountId});
			    
			    } else {
			    	//Sub-665 change for pending activation satus
					if(lstSubscriptions[0].Zuora__Status__c==constants.SUBSCRIPTION_ACTIVE_STATUS||lstSubscriptions[0].Zuora__Status__c==constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS){
						
						//redirect the user to the quote wizard in subscription amendment mode
						redirectUrl=string.format(constants.AMEND_SUBSCRIPTION_WIZARD_PAGE_URL,new list<string>{getInstanceURL(),lstSubscriptions[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,sfcAccountId,sfcAccountId,lstSubscriptions[0].Zuora__Zuora_Id__c});
				        
			      	} else if(lstSubscriptions[0].Zuora__Status__c==constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS){
						
						//redirect the user to revoke cancellation mode
						redirectUrl=constants.REVOKE_SUBSCRIPTION_CANCELLATION_PAGE_URL;
					}
				}
				
				//if the redirect url is not empty take the user to the next page
				if(!string.isempty(redirectUrl)){
					PageReference PageRef=new pageReference(redirectUrl);
			        pageRef.setredirect(true);
			        return PageRef;
				}else{
					//no matching condition so show the user error and go to the account page 
					 notificationOptions.backAction = 'goToAccountPage();';
					 
					//add the message 
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_No_Available_Action));
					return null;
				}
			} else{
				notificationOptions.backAction = 'goToListAccountaPage();';
				 //add the message 
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_Invalid_Account_ID));
				return null;
			}
		}
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        31/07/2015
    Function    This function is called to validate that the account id in the query string is correct
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	private boolean isValidAccountId(string sfcAccountId){
		try{
			//try to select the account
			list<account> lstAccounts=[select id from account where id=:sfcAccountId];
			
			//if account was found so it is a valid account id
			if(lstAccounts!=null && lstAccounts.size()>0){
				return true;
			} else{ //if no account was found so it is an invalid account
				return false;
			}
		} catch(exception ex){
			system.debug('Exception occured while getting the account:'+ex.getmessage());
			return false;
		}
		return true;
	}
	
	/*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        31/07/2015
    Function    This function is format
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	private string getInstanceURL(){
		//get the salesforce instance url
        string instanceURL=System.URL.getSalesforceBaseUrl().getHost();
        
        //the gethost() returns  c.cs17.visual.force.com and the submit preview is on  zqu.cs17.visual.force.com
        instanceURL='zqu.'+instanceURL.replace('sales','visual.');	
        
        return instanceURL;
	}
	
	/* Apex methods to expose as javascript through actionFunctions */
	//Return a page reference to the next page to be navigated to
	public PageReference goToAccountPage() {
	   return new PageReference('/'+ApexPages.currentPage().getParameters().get(constants.SF_ACCOUNT_ID_QUERY_STRING));
	}
	
	//Return a page reference to the next page to be navigated to
	public PageReference goToListAccountaPage() {
	   return new PageReference('/001/o');
	}
}