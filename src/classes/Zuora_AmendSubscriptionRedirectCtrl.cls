/**
* Author:       Michal Kwika(Accenture)
* Date:         22/10/2015
* Description:  this class is the constructor for the redirection and action for Subs amendments
*
* ******************* Change Log *******************
* Modified by       Change Date  
* Michal Kwika		30/10/2015
* Michal Kwika		17/02/2016 - changed all redirections
* Michal Kwika		18/02/2016 - returnURL defect fix
**/
public class Zuora_AmendSubscriptionRedirectCtrl {

	public String sfcAccountId {get; set;}
	public Account currentAccount {get; set;}
	public String billId {get; set;}
	public List<Zuora__Subscription__c> lstSubscriptions  {get; set;}
	public zqu.NotificationOptions notificationOptions {get; set;}
	public Zuora__Subscription__c lastActiveSub {get; set;}
	public Date earliestCancellationDate {get; set;}
	public String redirectUrl {get; set;}
	public PageReference pageRef {get; set;}
	public zqu__Quote__c currentQuote {get; set;}
	/*Zuora API Instance for calling into Zuora directly */
	static Zuora.zApi api = new Zuora.zApi();
	public Zuora__Subscription__c lastAmendedCancelledSub {get; set;}
	public Boolean isFailureQuoteCreationTest {get; set;}
	public String activeSubSfId {get;set;}

	public Zuora_AmendSubscriptionRedirectCtrl() {

		//Init notification options for the notification component
		notificationOptions = new zqu.NotificationOptions();
		notificationOptions.isPopup = true;
		notificationOptions.successTitle = Constants.ZUORA_NOTIFICATION_SUCCESS;
		notificationOptions.failureTitle = Constants.ZUORA_NOTIFICATION_ERROR;

		//set earliest date today's date
		earliestCancellationDate = Date.today();
		redirectUrl = '';

		//get test quote creation failure custom setting value
		isFailureQuoteCreationTest = Boolean.valueOf(Application_Settings__c.getInstance(Constants.TEST_QUOTE_CREATION_FAILURE_CUSTOM_SETTING).value__c);

		//login to the api using the user configured in "Zuora API Login Setup"
		if ( !Test.isRunningTest() ) {
			api.zlogin();
		}
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        22/10/2015
	Function    Method to check if Account has active subscription (Billing Account related)
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			02/11/2015
	Michal Kwika		1.2			18/02/2016 - returnURL defect fix
	****************************************************************************************/
	public PageReference redirectAmendSubscription() {
		if (!ApexPages.CurrentPage().getParameters().containsKey(constants.SF_ACCOUNT_ID_QUERY_STRING)) {
			notificationOptions.backAction = 'goToListAccountaPage();';
			//add the message
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_Missing_Account_ID));
			return null;
		} else {
			currentAccount = new Account();
			List<Account> lTempsAcc = new List<Account>();
			this.sfcAccountId = ApexPages.currentPage().getParameters().get(constants.SF_ACCOUNT_ID_QUERY_STRING);
			this.activeSubSfId = ApexPages.currentPage().getParameters().get(constants.ID_QUERY_STRING);
			lTempsAcc = [select id, name, Subscriber_Number__c from account where id = :sfcAccountId LIMIT 1];
			if(!lTempsAcc.isEmpty()){
				currentAccount = lTempsAcc.get(0);
			}
			//lstSubscriptions = [select Zuora__Status__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__Zuora_Id__c, Id, Original_Zuora_Subscription_ID__c, Zuora__NextChargeDate__c, Related_Quote__c, Master_Quote__c from Zuora__Subscription__c where (Zuora__Status__c = :constants.SUBSCRIPTION_ACTIVE_STATUS or Zuora__Status__c = :constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS or Zuora__Status__c = :constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS) and Zuora__Account__c = :sfcAccountId limit 1];

			lstSubscriptions = [SELECT Id, Name, Zuora__Status__c, Zuora_Subscription_Status__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, 
									 Zuora__Zuora_Id__c, Related_Quote__c, Subscription_Rate_Plan_Term_Type__c, Zuora__NextChargeDate__c, Zuora__SubscriptionEndDate__c
								FROM Zuora__Subscription__c WHERE Id = :activeSubSfId];
			


			if (lstSubscriptions == null || lstSubscriptions.size() == 0) {
				//SUB-1590 check last cancelled subs
				lastAmendedCancelledSub = getCancelledWithProductSwitchReasonSub();
				if(lastAmendedCancelledSub!= null){
					return createNewQuoteWithDetails();
				}
				

				//create the new quote
				currentQuote = ZuoraQuote_Utility.createZuoraQuote(api, currentAccount, constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE, null);
				if (currentQuote != null) {
					insert currentQuote;
					//redirect the user to the quote wizard in new subscription mode
					this.redirectUrl = '/'+ sfcAccountId;
					this.pageRef = Page.zqu__CreateQuote;
        			this.pageRef.getParameters().put('crmAccountId', sfcAccountId);
        			this.pageRef.getParameters().put('quoteType', Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
        			this.pageRef.getParameters().put('retUrl', this.redirectUrl);
        			this.pageRef.getParameters().put('stepNumber', '1');
        			this.pageRef.setredirect(true);
       
				} else {
					//hadle the notification settings
					notificationOptions.backAction = 'goToAccountPage();';
					notificationOptions.continueAction = '';
					//add the message
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Mid_Term_Discounts_Quote_Creation_Exception));
				}

			} else {
				lastActiveSub = lstSubscriptions[0];
				
				return hardCancelActiveSubscription();
			}

			//if the redirect url is not empty take the user to the next page
			if(this.pageRef!=null){
				this.pageRef.setredirect(true);
				return this.pageRef;
			} else {
				//no matching condition so show the user error and go to the account page
				notificationOptions.backAction = 'goToAccountPage();';

				//add the message
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_No_Available_Action));
				return null;
			}
		}
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        23/10/2015
	Function    This function is format
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private string getInstanceURL() {
		//get the salesforce instance url
		string instanceURL = System.URL.getSalesforceBaseUrl().getHost();

		//the gethost() returns  c.cs17.visual.force.com and the submit preview is on  zqu.cs17.visual.force.com
		instanceURL = 'zqu.' + instanceURL.replace('sales', 'visual.');

		return instanceURL;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        26/10/2015
	Function    This function is used to hard cancel subscription
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference hardCancelActiveSubscription() {
		Boolean processInvoice = true;
		Date cancellationDate = earliestCancellationDate;
		String popUpText = '';
		Boolean isSubscriptionMonthly = (lstSubscriptions[0].Subscription_Rate_Plan_Term_Type__c == Constants.RATE_PLAN_MONTHLY ? true : false);
		Boolean isFutureDate = (cancellationDate > ZuoraUtilities.getEndOfTermValue(isSubscriptionMonthly, lstSubscriptions[0].Zuora__NextChargeDate__c, lstSubscriptions[0].Zuora__SubscriptionEndDate__c));

		Boolean validForCancellation = false;

		validForCancellation = ZuoraSubscriptionCanceller.checkZuoraSubscriptionEligibleCancellation(api, 
			lstSubscriptions[0].Zuora__CustomerAccount__r.Zuora__AccountNumber__c, lstSubscriptions[0].Name,
			lstSubscriptions[0].Id, lstSubscriptions[0].Zuora__Status__c, lstSubscriptions[0].Zuora_Subscription_Status__c);

		if (cancellationDate != null && validForCancellation){

			try{
				String zAccountId = lstSubscriptions[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
				String zSubId     = lstSubscriptions[0].Zuora__Zuora_Id__c;
				String zSubName   = lstSubscriptions[0].Name;
				String reason     = Constants.SUBSCRIPTION_CANCELLATION_REASON_PRODUCTSWITCH;
				
				notificationOptions.backAction = '';
				notificationOptions.continueAction = 'createNewQuoteWithDetails();';

                Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(api, zAccountId, zSubId, zSubName, cancellationDate, reason, null, false, processInvoice, true);
            	
            	popUpText = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, processInvoice, isSubscriptionMonthly, isFutureDate);
            	
            } catch(Exception e){
                 popUpText = Label.Zuora_Subscription_Canceller_Cancellation_Error + ZuoraSubscriptionCanceller.errorMessage + e.getMessage() + '\r\n\r\n' + Label.Zuora_Subscription_Canceller_Contact_Zuora_Admin;
                 notificationOptions.backAction = 'goToAccountPage();';
            }
			//add the message
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, popUpText));
		} else if (!validForCancellation){
			popUpText = Label.Zuora_Subscription_Canceller_Cancellation_Error + ZuoraSubscriptionCanceller.errorMessage + '\r\n\r\n' + Label.Zuora_Subscription_Canceller_Contact_Zuora_Admin;
            notificationOptions.backAction = 'goToAccountPage();';

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, popUpText));
		}


		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        26/10/2015
	Function    This function is used to redirect user to manage quote
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			30/10/2015
	Michal Kwika		1.2			17/02/2016
	****************************************************************************************/
	public PageReference createNewQuoteWithDetails() {
		//if functionality of fail creation is tested go back to AccountPage
		if(isFailureQuoteCreationTest){
			return goToAccountPage();
		}

		//login to the api using the user configured in "Zuora API Login Setup"
		if ( !Test.isRunningTest() ) {api.zlogin();}

		//create the new quote
		//currentQuote = ZuoraQuote_Utility.createZuoraQuote(api, currentAccount, constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE, lastActiveSub);
		currentQuote = ZuoraQuote_Utility.createZuoraQuote(api, currentAccount, constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE, lastActiveSub);
		if (currentQuote != null) {

			currentQuote.arePaymentDetailsEntered__c = true;
			if(lastActiveSub==null && lastAmendedCancelledSub !=null){
				currentQuote.Previous_Subscription__c = lastAmendedCancelledSub.Id;
			}
			else {
				currentQuote.Previous_Subscription__c = lastActiveSub.Id;	
			}	
			insert currentQuote;
			//redirect the user to the quote wizard in new subscription mode
			this.redirectUrl = '/'+ sfcAccountId;
			this.pageRef = Page.zqu__SelectProducts;
        	this.pageRef.getParameters().put('Id', currentQuote.Id);
        	this.pageRef.getParameters().put('quoteType', Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
        	this.pageRef.getParameters().put('retUrl', this.redirectUrl);
        	this.pageRef.getParameters().put('stepNumber', '2');
        	this.pageRef.setredirect(true);
		} else {
			//hadle the notification settings
			notificationOptions.backAction = 'goToAccountPage();';
			notificationOptions.continueAction = '';
			//add the message
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Mid_Term_Discounts_Quote_Creation_Exception));
			return null;
		}
		return this.pageRef;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        30/10/2015
	Function    This function is used to get last Cancelled Subscription with Reason 'Product switch'
				Is used to pass this sub Id to new Quote in case of Quote creation failure
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public Zuora__Subscription__c getCancelledWithProductSwitchReasonSub(){
		List <Zuora__Subscription__c> lCancelledSubWithProductSwitch =  new List <Zuora__Subscription__c>();
		//get latest one sub with status cancelled and cancellation reason product switch
		lCancelledSubWithProductSwitch = [select Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__Zuora_Id__c, Id from Zuora__Subscription__c where (Zuora__Status__c = :Constants.SUBSCRIPTION_CANCELLED_STATUS) and Cancellation_Reason__c =:Constants.SUBSCRIPTION_CANCELLATION_REASON_PRODUCTSWITCH and Zuora__Account__c = :sfcAccountId limit 1];

		if(lCancelledSubWithProductSwitch.size()>0){
			return lCancelledSubWithProductSwitch.get(0);
		}
		
		return null;
	}

	/* Apex methods to expose as javascript through actionFunctions */
	//Return a page reference to the next page to be navigated to
	public PageReference goToAccountPage() {
		return new PageReference('/' + ApexPages.currentPage().getParameters().get(constants.SF_ACCOUNT_ID_QUERY_STRING));
	}

	//Return a page reference to the next page to be navigated to
	public PageReference goToListAccountaPage() {
		return new PageReference('/001/o');
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        30/10/2015
	Function    Return a page Revoke Cancellation
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika 		1.1			17/02/2016- changed approach of redirection
	****************************************************************************************/
	public PageReference goToRevokeCancellationPage() {
		PageReference revokePageRef = Page.Zuora_RevokeCancellation;
        revokePageRef.getParameters().put(Constants.ID_QUERY_STRING, lstSubscriptions[0].Id);
        revokePageRef.getParameters().put('accId', billId);
        revokePageRef.setredirect(true);
        return revokePageRef;
	}
}