/**
* Author:       Sally ElGhoul (Tquila)
* Date:         21/04/2015
* Description:  this class is the constructor for the 4th step in z-quote wizard steps
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Michal Kwika      17/02/2016      -changed redirect method
**/
public with sharing class Zuora_PaymentRedirectController {
	
	public boolean isDirectDebitConfirmed	{get;set;} //boolean variable to make sure if the call center ticked the mandate checkbox or no in case of direct debit
    private zqu__Quote__c quoteObj; //current quote Obj
    
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
    			if(quoteObj.zqu__PaymentMethod__c==Constants.DIRECT_DEBIT_PAYMENT_METHOD)
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
    Developer   Sally ElGhoul (Tquila)
    Date        21/04/2015
    Function    Constructor, determines the Zuora page Id based on payment method of the quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public Zuora_PaymentRedirectController(ApexPages.StandardController standardController) {
      
       // Ensure the payment method field is populated on the Quote sObject
        if(!Test.isRunningTest()) standardController.addFields(new List < String > {'zqu__PaymentMethod__c'});
         
        // Retrieve the quote and set the payment method type based on the quote's payment method
        quoteObj = (zqu__Quote__c)standardController.getRecord();
        
        //get the right payment page ID based on the payment method value
    	GetPaymentPageId();
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        02/06/2015
    Function    this function is called to refresh the quote payment method based on the picklist and get the right iframe
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         17/02/2016 - changed 
    ****************************************************************************************/
    public pageReference updatePaymentPageFrame(){
    	try{
	    	//update the quote object
	    	update quoteObj;
	    	
	    	//repload the page to get the right payment iframe
	    	String action='';
	    	if(ApexPages.currentPage().getParameters().containskey(constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY)){
	    		action = ApexPages.currentPage().getParameters().get(constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY);
	    	}
            PageReference pageRef = Page.Zuora_PaymentStep;
            pageRef.getParameters().put(Constants.ID_QUERY_STRING, quoteObj.id);
            pageRef.getParameters().put(Constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY, action);

	    	pageRef.setredirect(true);
	    	return pageref;
    	}catch(System.DmlException e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
    	} catch(exception ex){ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error));system.debug('Error Occured to update the quote in function updatePaymentPageFrame: '+ex);}
    	return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        02/06/2015
    Function    this function is called to get the right payment page id based on the payment method value
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    private void GetPaymentPageId(){
    	// Payment method
        String paymentMethodType = '';
        
        //Adjust the paymentMethod because the values are different between Zuora and Salesforce
        if(quoteObj != null) {
        	paymentMethodType=quoteObj.zqu__PaymentMethod__c;
        	
        	//if the payment method is empty [it may be empty in case of quote amendment] default it to credit card
	        if(string.isempty(paymentMethodType) && quoteObj.zqu__SubscriptionType__c==constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE){
	        	paymentMethodType=Constants.CREDIT_CARD_PAYMENT_METHOD;
	       	}
        }
        
     	system.debug('paymentMethodType: '+paymentMethodType);
        // Query for settings
        List < zqu__HostedPageLiteSetting__c > settingList = [SELECT zqu__PageId__c, zqu__PaymentMethodType__c, zqu__ComponentName__c FROM zqu__HostedPageLiteSetting__c WHERE zqu__PaymentMethodType__c = :paymentMethodType LIMIT 1];
 	
        if(settingList != null && !settingList.isEmpty()) {
            pageId = settingList[0].zqu__PageId__c;
        } else {
        	throw new TMGUtil.GenericException(constants.INVALID_PAYMENT_METHOD_VALUE_ERROR_MESSAGE);
        	system.debug('Invalid Payment Method Value Zuora_PaymentRedirectController controller.');
        }
        system.debug('pageId: '+pageId);
    }
    
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        02/06/2015
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