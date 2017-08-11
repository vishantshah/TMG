/**
* Author:       Sally ElGhoul (Accenture)
* Date:         27/01/2016
* Description:  this class for testing Zuora_QuoteBillingPreviewController
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      15/09/2015
* Sally ElGhoul		04/03/2016 - use Zuora_BillingPreviewInvoiceItems 
* Wiktor Czykin		06/06/2017 - removed reference to createZquotesWithProduct()
**/
@isTest (SeeAllData=true)
private class Zuora_QuoteBillingPreviewControllerTest {

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        27/01/2016
    Function    Testing Billing Preview details
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin		06/06/2017 - removed reference to createZquotesWithProduct()
    ****************************************************************************************/
	static testMethod void testBillingPreview() {
		//Create zquote record and this function will create a registrant as well
	    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
	    //Create the zquotes
	    testDataUtilityObj.createQuoteRatePlanCharges();
	    
	    List<Contact> lstContacts = [SELECT Id, Name FROM Contact WHERE Account.Id = :testDataUtilityObj.lstZQuotes[0].zqu__Account__c];         
      	
      	testDataUtilityObj.lstZQuotes[0].zqu__ElectronicPaymentMethodId__c = 'pmid1234';
	    //set the bill to and contact to
	    if  (lstContacts.size() > 0) {             
	      	testDataUtilityObj.lstZQuotes[0].zqu__SoldToContact__c = lstContacts[0].Id;
	   		testDataUtilityObj.lstZQuotes[0].zqu__BillToContact__c = lstContacts[0].Id;
	    }
	    testDataUtilityObj.lstZQuotes[0].zqu__Status__c=constants.QUOTE_STATUS_NEW_VALUE;
	    testDataUtilityObj.lstZQuotes[0].zqu__StartDate__c=Date.Today();
	    update testDataUtilityObj.lstZQuotes[0];
	    
	    
	    //new subscription
	    Zuora_QuoteBillingPreviewController controllerObj=new Zuora_QuoteBillingPreviewController();
	    controllerObj.quoteIDValue=testDataUtilityObj.lstZQuotes[0].id;
	    List<Zuora_BillingPreviewInvoiceItems> lstInvoiceItems=controllerObj.lstInvoiceItems;
	    System.assertEquals(lstInvoiceItems.size(),1);
	    System.assertEquals(lstInvoiceItems[0].invoiceItemAmount,9);
	    
	    //amendment
	    testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c=constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
	    update testDataUtilityObj.lstZQuotes[0];
	    controllerObj.loadBillingPreviewDetails();
	    System.assertEquals(lstInvoiceItems.size(),1);
	    
	    //show the billing information for account
	    controllerObj.accountIDValue=testDataUtilityObj.lstRegistrants[0].id;
	    controllerObj.quoteIDValue=null;
	    controllerObj.loadBillingPreviewDetails();
	    System.assertEquals(lstInvoiceItems.size(),1);
	    
	    //show the billing information for subscription
	    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
	    testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
	    controllerObj.accountIDValue=null;
	    controllerObj.subscriptionIDValue=testDataUtilityObj.lstZuoraSubscriptions[0].id;
	    testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__SubscriptionStartDate__c=Date.Today();
	    update testDataUtilityObj.lstZuoraSubscriptions[0];
	    controllerObj.loadBillingPreviewDetails();
	    System.assertEquals(lstInvoiceItems.size(),1);
    }
}