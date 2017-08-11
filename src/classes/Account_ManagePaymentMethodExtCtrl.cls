/**
* Author:       Michal Kwika (Tquila)
* Date:         28/07/2015
* Description:  this class for testing Account_ManagePaymentMethodExtCtrl
*
* ******************* Change Log *******************
* Modified by       Change Date    
**/

public with sharing class Account_ManagePaymentMethodExtCtrl {

	public boolean isDirectDebitConfirmed	{get;set;} //boolean variable to make sure if the call center ticked the mandate checkbox or no in case of direct debit
	private Zuora__CustomerAccount__c zuoraBillingAcc {get; set;}// current Billing Account obj
    private zqu__Quote__c quoteObj;// current quote
    public String chosenPaymentMethod {get; set;}
	// The Zuora id of the payment page
    public String pageId {
        get {
            if(pageId == null) pageId = '';
            return pageId;
        }
        set;
    }

     //return true is the payment method is Direct Debit
    public boolean isDirectDebit{
            get{  
                if(chosenPaymentMethod==Constants.DIRECT_DEBIT_PAYMENT_METHOD)
                    return true;
                else
                    return false;
            }
            set;
    }

    //return true when we can render the payment iframe in case of credit payment
    //and return true if it is direct debit and the call center ticked the mandate checkbox
    public boolean isRenderPaymentIframe{
        get{
            if(isDirectDebit==false || (isDirectDebit==true && isDirectDebitConfirmed==true)){
                return true;
            } else {
                return false;
            }
        }
        set;
    }

	/*************************************************************************************** 
    Developer   Michal Kwika (Tquila)
    Date        28/07/2015
    Function    Main Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public Account_ManagePaymentMethodExtCtrl(ApexPages.StandardController standardController) {
    	
    	// Retrieve the quote and set the payment method type based on the quote's payment method
        this.zuoraBillingAcc = (Zuora__CustomerAccount__c)standardController.getRecord();

        //check if there is a DD parameter set 
        if(ApexPages.currentPage().getParameters().containskey('pm')){
            this.chosenPaymentMethod = ApexPages.currentPage().getParameters().get('pm');
        }
        
        //get the right payment page ID based on the payment method value
    	GetPaymentPageId();
    }

    /*************************************************************************************** 
    Developer   Michal Kwika (Tquila)
    Date        28/07/2015
    Function    is used to reload payment frame
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public pageReference updatePaymentPageFrame(){
	    
        pageReference pageRef=new pageReference(string.format('https://{0}/apex/Account_Manage_Payment_Methods?id={1}&pm={2}&zId={3}&accountId={4}',new list<string>{System.URL.getSalesforceBaseUrl().getHost(),
                                                                                                                                zuoraBillingAcc.id,this.chosenPaymentMethod, zuoraBillingAcc.Zuora__Zuora_Id__c, zuoraBillingAcc.Zuora__Account__c}));
        pageRef.setredirect(true);
        return pageref;
    }

    /*************************************************************************************** 
    Developer   Michal Kwika(Tquila)
    Date        28/07/2015
    Function    this function is called to get the right payment page id based on the payment method value
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private void GetPaymentPageId(){
    	// Payment method - set credit card as default
        String paymentMethodType = '';

        //try to set paymentmethodType based on passed parameter
        paymentMethodType = this.chosenPaymentMethod;

        if(String.isEmpty(paymentMethodType)){
            paymentMethodType = Constants.CREDIT_CARD_PAYMENT_METHOD;
        }
          
        // Query for settings
        List < zqu__HostedPageLiteSetting__c > settingList = [SELECT zqu__PageId__c, zqu__PaymentMethodType__c, zqu__ComponentName__c FROM zqu__HostedPageLiteSetting__c WHERE zqu__PaymentMethodType__c = :paymentMethodType LIMIT 1];
 	  
        if(settingList != null && !settingList.isEmpty()) {
            pageId = settingList[0].zqu__PageId__c;
        } else {
        	throw new TMGUtil.GenericException(constants.INVALID_PAYMENT_METHOD_VALUE_ERROR_MESSAGE);
        	system.debug('### Account Manage Payments LOG: Invalid Payment Method Value Account_ManagePaymentMethodExtCtrl controller.');
        }
        system.debug('pageId: '+pageId);
    }

     /*************************************************************************************** 
    Developer   Michal Kwika (Tquila)
    Date        29/07/2015
    Function    this function is called to get the payment methods available and return a list of selectOption
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public list<selectOption> getPaymentMethods(){
        
        //the list of select option to return 
        list<selectOption> lstResult=new list<selectOption>();
        
        //get the payment method field 
        Schema.DescribeFieldResult paymentMethodField = zqu__Quote__c.zqu__PaymentMethod__c.getDescribe();
        
        //get the picklist values of the payment method field
        List<Schema.PicklistEntry> paymentMethodValues = paymentMethodField.getPicklistValues();
        
        //loop on the picklist values and fill the list of selectoption
        for(Schema.PicklistEntry entryObj : paymentMethodValues){
            lstResult.add(new selectOption(entryObj.getValue(),entryObj.getLabel()));
        }
        
        //return the available payment methods
        return lstResult;
    }

}