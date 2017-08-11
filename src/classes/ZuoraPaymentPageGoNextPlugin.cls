/**
* Author:       Sally ElGhoul (Tquila)
* Date:         05/06/2015
* Description:  this is the plugin to extend the next button of payment page component of Zuora
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Michal Kwika      03/08/2015
**/
global class ZuoraPaymentPageGoNextPlugin extends zqu.PaymentPageController.DefaultHostedPageLiteGoNextPlugin {
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        4/06/2015
    Function    this function will be called when the user press on the next button of the payment page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         04/08/2015
    ****************************************************************************************/
    global override PageReference navigateNext(String paymentMethodType, Map < String, String > callbackParameters) {
       
       // If the transaction was not successful, display the error message to the user
       Boolean success = Boolean.valueOf(callbackParameters.get('success'));
       String objId = ''; //to check if the object Id is Quote's or BillingAccount's
       String typeOfTheObject=''; //variable to set type of the object after
       String accountId=''; //Account object related in Salesforce 

       //temporary apiNames of quote and billing account
        String zquoteApiName =zqu__Quote__c.class.getName();
        String billingAccountApiName = Zuora__CustomerAccount__c.class.getName();
      
       if(!success) {
           String errorMessage = callbackParameters.get('errorMessage');
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
           return null;
        }
        //if there is a Id parameter - check which object is it
        if(ApexPages.currentPage().getParameters().containsKey('id')){
            objId = ApexPages.currentPage().getParameters().get('Id');
            typeOfTheObject = ZuoraPaymentPageDefaultPlugin.getNameOfObjectBasedOnId(objId);
        }

        //if there is a accountId parameter get it
        if(ApexPages.currentPage().getParameters().containsKey('accountId')){
            accountId=ApexPages.currentPage().getParameters().get('accountId');
        }

        //get action parameter
        String action = ApexPages.currentPage().getParameters().get(constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY);
        
        //Object is Billing Account
        if(typeOfTheObject.equalsIgnoreCase(billingAccountApiName)){

            //redirect to Summary page
            PageReference summaryPageRef = new PageReference('/apex/Account_BillingPM_Summary?id='+accountId);
            summaryPageRef.setredirect(true);
            return summaryPageRef;

        }

        //Object is Quote
        else{
             // Get the quote based on the id in the url
            String quoteId = ApexPages.currentPage().getParameters().get('Id');
           
            //update the quote record to arePaymentDetailsEntered__c is true now as the user entered their payment details
            zqu__Quote__c quoteObj=[select zqu__ElectronicPaymentMethodId__c,zqu__PaymentMethod__c,arePaymentDetailsEntered__c,zqu__Account__c,zqu__SubscriptionType__c from zqu__Quote__c where id=:quoteId];
            if(quoteObj.arePaymentDetailsEntered__c==false){
                quoteObj.arePaymentDetailsEntered__c=true;
            } 
            
             quoteObj.zqu__PaymentMethod__c=paymentMethodType;
             //update the electronic payment method id field with the zuora payment just created
             quoteObj.zqu__ElectronicPaymentMethodId__c=callbackParameters.get('refId');
             update quoteObj;
            
           //if the action is only to add the payment so redirect the user to the quote page
           if(action==constants.PAYMENT_STEP_PAGE_ACTION_ADD){
                
                //redirect to the quote page
                pageReference quoteRefPage=new Pagereference('/'+quoteId);
                quoteRefPage.setredirect(true);
                return quoteRefPage;
            } else if (action==constants.PAYMENT_STEP_PAGE_ACTION_SEND){ //if the action is to submit the quote so redirect the user to the submit preview screen
                
                //redirect the user to send to submit to zbilling page
                PageReference pageRef=Page.Zuora_sendToZBilling;
                pageRef.setredirect(true);
                
                //put the quote id as query string parameter
                pageRef.getParameters().put(constants.QUOTE_ID_QUERY_STRING,quoteId);
                
                //put the salesforce account id of the quote as a query string parameter 
                pageRef.getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING,quoteObj.zqu__Account__c);
                
                //pass the payment method id
                pageRef.getParameters().put(constants.PAYMENT_METHOD_ID_QUERY_STRING,callbackParameters.get('refId'));
                
                return pageRef;
            }
        }
       
        return null;
        
    }
}