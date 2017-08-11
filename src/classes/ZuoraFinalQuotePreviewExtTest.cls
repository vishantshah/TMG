/**
* Author:       Sally ElGhoul (Tquila)
* Date:         27/05/2015
* Description:  this class for testing ZuoraFinalQuotePreviewExt
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
@isTest (SeeAllData=true)
private class ZuoraFinalQuotePreviewExtTest {

   
    @isTest
	  private static void testCustomQuotePreviewSample() {
	    
	    //Create and insert test quote
	    // Set mock callout class
	    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
	    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		
		//Create zquote record and this function will create a registrant as well
	    TestDataUtility testDataUtilityObj = new TestDataUtility(2);
	    
	    //Create the zquotes
	    testDataUtilityObj.createZquotes();
	    
	    List<Contact> lstContacts = [SELECT Id, Name FROM Contact WHERE Account.Id = :testDataUtilityObj.lstZQuotes[0].zqu__Account__c];         
      	
      	testDataUtilityObj.lstZQuotes[0].zqu__ElectronicPaymentMethodId__c = 'pmid1234';
	    //set the bill to and contact to
	    if  (lstContacts.size() > 0) {             
	      	testDataUtilityObj.lstZQuotes[0].zqu__SoldToContact__c = lstContacts[0].Id;
	   		testDataUtilityObj.lstZQuotes[0].zqu__BillToContact__c = lstContacts[0].Id;
	    }
	    testDataUtilityObj.lstZQuotes[0].zqu__Status__c=constants.QUOTE_STATUS_NEW_VALUE;
	    
	    update testDataUtilityObj.lstZQuotes[0];
	
	    ZuoraFinalQuotePreviewExt stzbp = new ZuoraFinalQuotePreviewExt(new ApexPages.StandardController(testDataUtilityObj.lstZQuotes[0]));
	
	    //Verify that no failure message is displayed
	    System.assertEquals(stzbp.previewOptions.disableCreateButton, false);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.failureBody, null);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.isPopup, false);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.backAction, '');
	
	    /* CASE 1: Quote successfully sent to Z-Billing */
		testZBillingResult.success = true;
	
	    //Init custom plugin instance
	    Type customCreateOrderPlugin = Type.forName('ZuoraFinalQuotePreviewExt.CreateOrderPlugin');
	    ZuoraFinalQuotePreviewExt.CreateOrderPlugin pluginInstance = (ZuoraFinalQuotePreviewExt.CreateOrderPlugin) customCreateOrderPlugin.newInstance();
	
	    //User clicks create order
	    PageReference successCreateOrderPage = pluginInstance.CreateOrder(stzbp);
	
	    //Verify success message was posted to current page
	    System.assertEquals(null, successCreateOrderPage);
	    System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.CONFIRM));
	
	    /* CASE 2: Quote not successfully sent to Z-Billing */
	
	    //Set test result success to false
	    testZBillingResult.success = false;
	    testZBillingResult.message = 'test error message';
	
	    //User clicks create order
	    PageReference failureCreateOrderPage = pluginInstance.CreateOrder(stzbp);
	
	    //Verify failure message was posted to current page
	    System.assertEquals(null, failureCreateOrderPage);
	    System.assertEquals(false, ApexPages.hasMessages(ApexPages.Severity.ERROR));
	    
	    ApexPages.currentPage().getParameters().put(constants.REFERESH_QUOTE_METRICS_QUERY_STRING,'true');
	    stzbp.updateQuoteMetrics();
	  }
	
	@isTest
	  private static void testInvalidCustomQuotePreviewSampleStatus() {
	    
	    //Create an invalid test quote with no contancts
	     //Create and insert test quote
	    // Set mock callout class
	    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
	    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		
		//Create zquote record and this function will create a registrant as well
	    TestDataUtility testDataUtilityObj = new TestDataUtility(2);
	    
	    //Create the zquotes
	    testDataUtilityObj.createZquotes();
	    
	    
	     List<Contact> lstContacts = [SELECT Id, Name FROM Contact WHERE Account.Id = :testDataUtilityObj.lstZQuotes[0].zqu__Account__c];         
      	
      	 //set the bill to and contact to
		    if  (lstContacts.size() > 0) {             
		      	testDataUtilityObj.lstZQuotes[0].zqu__SoldToContact__c = lstContacts[0].Id;
		   		testDataUtilityObj.lstZQuotes[0].zqu__BillToContact__c = lstContacts[0].Id;
		    } 
	    update testDataUtilityObj.lstZQuotes[0];

	    ZuoraFinalQuotePreviewExt stzbp = new ZuoraFinalQuotePreviewExt(new ApexPages.StandardController(testDataUtilityObj.lstZQuotes[0]));
	
	    //Verify that failure message is displayed and create order button is disabled
	    System.assertEquals(stzbp.previewOptions.disableCreateButton, true);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.failureBody, Label.Quote_Preview_Status_Error);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.isPopup, true);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.backAction, 'goToAccountPage();');
	
	    //User clicks Go Back on popup error message
	    System.assertEquals(stzbp.goToAccountPage().getUrl(), '/' + testDataUtilityObj.lstZQuotes[0].zqu__Account__c);
	  }
   
	  @isTest
	  private static void testInvalidCustomQuotePreviewSample() {
	    
	    //Create an invalid test quote with no contancts
	     //Create and insert test quote
	    // Set mock callout class
	    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
	    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		
		//Create zquote record and this function will create a registrant as well
	    TestDataUtility testDataUtilityObj = new TestDataUtility(2);
	    
	    //Create the zquotes
	    testDataUtilityObj.createZquotes();
	    
	    testDataUtilityObj.lstZQuotes[0].zqu__SoldToContact__c = null;
	    testDataUtilityObj.lstZQuotes[0].zqu__BillToContact__c = null;
	    update testDataUtilityObj.lstZQuotes[0];
	
	    ZuoraFinalQuotePreviewExt stzbp = new ZuoraFinalQuotePreviewExt(new ApexPages.StandardController(testDataUtilityObj.lstZQuotes[0]));
	
	    //Verify that failure message is displayed and create order button is disabled
	    System.assertEquals(stzbp.previewOptions.disableCreateButton, true);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.failureBody, 'A quote must have a valid bill to contact and sold to contact to be sent to Zuora. Click Go Back to return to the quote\\\'s detail page.');
	    System.assertEquals(stzbp.previewOptions.notificationOptions.isPopup, true);
	    System.assertEquals(stzbp.previewOptions.notificationOptions.backAction, 'goToQuotePage();');
	
	    //User clicks Go Back on popup error message
	    System.assertEquals(stzbp.goToQuotePage().getUrl(), '/' + testDataUtilityObj.lstZQuotes[0].Id);
	  }
	
	  //Mock ZBilling result for testing purposes
	  public static zqu.zQuoteUtil.ZBillingResult testZBillingResult {
	    get {
	      if(testZBillingResult == null) testZBillingResult = new zqu.zQuoteUtil.ZBillingResult();
	      return testZBillingResult;
	    }
	    private set;
	  }
}