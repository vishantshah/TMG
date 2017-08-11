/**
* Author:       Sally ElGhoul (Tquila)
* Date:         04/06/2015
* Description:  this is the plugin to extend the back button of payment page component of Zuora
*
* ******************* Change Log *******************
* Modified by       Change Date  
* Michal Kwika      03/08/2015   
**/
global class ZuoraPaymentPageGoBackPlugin implements zqu.PaymentPageController.IHostedPageLiteGoBackPlugin{
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        4/06/2015
    Function    this function will be called when the user press on the back button of the payment page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         03/08/2015
    ****************************************************************************************/ 
    global PageReference navigateBack(String paymentMethodType) {
      	
        // Michal Kwika DS100 03/08/2015
      	// Get the Id and check which kind of object is that
        String sId = ApexPages.currentPage().getParameters().get('Id');
        String accountId = '';
        //check which kind of object do you have
        String currObjectName=ZuoraPaymentPageDefaultPlugin.getNameOfObjectBasedOnId(sId);

        //temporary apiNames of quote and billing account
        String zquoteApiName =zqu__Quote__c.class.getName();
        String billingAccountApiName = Zuora__CustomerAccount__c.class.getName();

        //if there is a accountId parameter get it
        if(ApexPages.currentPage().getParameters().containsKey('accountId')){
            accountId=ApexPages.currentPage().getParameters().get('accountId');
        }

        //redirect quote to zQuote detail page
        if(currObjectName.equalsIgnoreCase(zquoteApiName)){
             //redirect the user to the quote page based on object
            pageReference quoteRefPage=new Pagereference('/'+sId);
            quoteRefPage.setredirect(true);
            return quoteRefPage;
        }

        //redirect from BillingAccount back to the summary page
        else if(currObjectName.equalsIgnoreCase(billingAccountApiName)){
            //redirect the user to the quote page based on object
            PageReference summaryPageRef = new PageReference('/apex/Account_BillingPM_Summary?id='+accountId);
            summaryPageRef.setRedirect(true);
            return summaryPageRef;
        }

        return null;
       
    }
}