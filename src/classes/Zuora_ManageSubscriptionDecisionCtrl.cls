/**
* Author:       Michal Kwika (Accenture)
* Date:         18/01/2015
* Description:  controller class for Zuora_ManageSubscriptionDecision page
* ******************* Change Log *******************
* Modified by       Change Date
* MIchal Kwika       17/02/2016 - Added new redirection approach
* Michal Kwika       18/02/2016 - returnURL defect fix
* Pawel Chrzanowski  17/06/2016 - added redirect for Lite Accounts
*/

public class Zuora_ManageSubscriptionDecisionCtrl {

	public Boolean showDecisionPage			{get; set;}
	public String strSelectedAccountId		{get; set;}
	public Zuora__Subscription__c activeSub {get; private set;}
	public zqu__Quote__c activeQuote		{get; private set;}
	public Boolean activeSubExists			{get; set;}
	public Boolean pendingCancelSubExists	{get; set;}
	public Boolean activeQuoteExists		{get; set;}
	public String titleOfPageBlock			{get; set;}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        22/10/2015
	Function    Constructor
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public Zuora_ManageSubscriptionDecisionCtrl() {
		//show the form and set parameters
		this.showDecisionPage = true;
		this.activeSubExists = false;
		this.pendingCancelSubExists = false;
		this.activeQuoteExists = false;
		this.titleOfPageBlock = Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE;

		if(ApexPages.currentPage().getParameters().containskey('id')){
			this.strSelectedAccountId = ApexPages.currentPage().getParameters().get('id');
		}else{
			this.showDecisionPage = false;
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Account);
			ApexPages.addMessage(myMsg);
			return;
		}

		//check if Account has an Active Subscription
		this.activeSub = AccountUtility.getActiveZuoraSubscriptionFromAccount(this.strSelectedAccountId);
		//System.debug('€€€ Checking SUB:  ' + activeSub);
		if(this.activeSub == null){
			//show that there is no account with button
			//create new Subscription - redirect to selectProduct page
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, Label.Manage_Subscription_Active_Subscription_DoesNotExist);
			ApexPages.addMessage(myMsg);

			//check if there is an Active Quote
			activeQuote = AccountUtility.getLatestActiveQuoteFromAccount(this.strSelectedAccountId);
			//System.debug('€€€ Checking QUOTE:  ' + activeQuote);
			if(activeQuote != null){
				this.activeQuoteExists = true;
				ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Manage_Subscription_Active_Quote_Message);
				ApexPages.addMessage(myMsg2);
			}
		}else{
			//decide which status is subscription
			decideWhichStatusHasActiveSub(this.activeSub);
		}
	}

	/***************************************************************************************
	Developer   Pawel Chrzanowski
	Date        17/06/2016
	Function    Action to redirect Lite Accounts
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference checkLiteAccount(){
		if(String.isNotBlank(strSelectedAccountId)){
			Account acc = [select Digital_Status__c from Account where Id = :strSelectedAccountId];
			if(acc.Digital_Status__c == Constants.LITE_ACCOUNT_DIGITAL_STATUS){
		         PageReference pr = Page.NewAccountWizard;
		         pr.getParameters().put('id', strSelectedAccountId);
		         pr.setRedirect(true);
		         return pr;
			}
		}
		return null;
	}

	/***************************************************************************************
	Developer   Michal Kwika
	Date        18/01/2016
	Function    this is method to make some action based on Active Sub status
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private void decideWhichStatusHasActiveSub(Zuora__Subscription__c zuoraSub) {
		if (zuoraSub.Zuora__Status__c.equalsIgnoreCase(Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS)) {
			this.pendingCancelSubExists = true;
			this.titleOfPageBlock = Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS + ' ' + Constants.INVOICE_PROCESSING_OPTION_DEFAULT;
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Manage_Subscription_Pending_Cancellation_Info);
			ApexPages.addMessage(myMsg);
		} else if (zuoraSub.Zuora__Status__c.equalsIgnoreCase(Constants.SUBSCRIPTION_ACTIVE_STATUS) || zuoraSub.Zuora__Status__c.equalsIgnoreCase(Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS)) {
			this.activeSubExists = true;
			this.titleOfPageBlock = zuoraSub.Zuora__Status__c + ' ' + Constants.INVOICE_PROCESSING_OPTION_DEFAULT;
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Manage_Subscription_Active_Subscription_Exists);
			ApexPages.addMessage(myMsg);
		}
	}

	/***************************************************************************************
	Developer   Michal Kwika
	Date        18/01/2016
	Function    this is method to redirect back to record
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference backToRecord () {
		PageReference pageRef = new PageReference('/' + this.strSelectedAccountId);
		pageRef.setRedirect(true);

		return pageRef;
	}

	/***************************************************************************************
	Developer   Michal Kwika
	Date        18/01/2016
	Function    this is method to redirect back to record
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference goToSubscription () {
		PageReference pageRef = new PageReference('/' + this.activeSub.Id);
		pageRef.setRedirect(true);

		return pageRef;
	}

	/***************************************************************************************
	Developer   Michal Kwika
	Date        18/01/2016
	Function    this is method to redirect back to record
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference goToQuote () {
		PageReference pageRef = new PageReference('/' + this.activeQuote.Id);
		pageRef.setRedirect(true);

		return pageRef;
	}

	/***************************************************************************************
	Developer   Michal Kwika
	Date        18/01/2016
	Function    this is method to redirect back to record
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference revokeCancellation () {
		PageReference pageRef = Page.Zuora_RevokeCancellation;

		pageRef.getParameters().put(Constants.ID_QUERY_STRING, this.activeSub.Id);
		pageRef.getParameters().put('accId', this.activeSub.Zuora__CustomerAccount__c);
		pageRef.getParameters().put(Constants.SF_ACCOUNT_ID_QUERY_STRING, this.strSelectedAccountId);
		pageRef.setRedirect(true);

		return pageRef;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        18/01/2016
	Function    this function is called to redict the user to manage subscription screen
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference redirectActiveSubscription() {

		PageReference pageRef = Page.Zuora_AmendSubscriptionRedirect;
		pageRef.getParameters().put(Constants.SF_ACCOUNT_ID_QUERY_STRING, this.strSelectedAccountId);
		pageRef.getParameters().put(Constants.ID_QUERY_STRING, this.activeSub.Id);
		pageRef.setredirect(true);
		return PageRef;
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        18/01/2016
	Function    this function is called to redict the user to manage subscription screen
	******************* Change Log *******************
	Modified by         Version     Change Date
	Michal Kwika		1.1			17/02/2016 - added new redirection approach
	Michal Kwika		1.2			18/02/2016 - returnURL defect fix
	****************************************************************************************/
	public PageReference redirectNewSubscription() {
		String retUrl = '/'+ this.strSelectedAccountId;

		PageReference PageRef = Page.zqu__CreateQuote;
		PageRef.getParameters().put('crmAccountId', this.strSelectedAccountId);
		PageRef.getParameters().put('quoteType', Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
		PageRef.getParameters().put('retUrl', retUrl);
		PageRef.getParameters().put('stepNumber', '1');
		PageRef.setredirect(true);
		return PageRef;
	}

}