/**
* Author:       Sally ElGhoul (Tquila)
* Date:         27/04/2015
* Description:  this class for testing Zuora_PaymentRedirectController
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      15/09/2015
**/
@isTest
private class Zuora_PaymentRedirectControllerTest {

  static testMethod void TestPageRedirectWithNoPayment() {
    // Set mock callout class
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    //Create the zquotes
    testDataUtilityObj.createZquotes();
    testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c = constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
    update testDataUtilityObj.lstZQuotes[0];

    //As the payment method is empty this will always return an empty page ID
    ApexPages.StandardController standardControllerObj = new ApexPages.StandardController(testDataUtilityObj.lstZQuotes[0]);
    try {
      Zuora_PaymentRedirectController paymentRedirectController = new Zuora_PaymentRedirectController(standardControllerObj);
    } catch (exception e) {
      system.assertEquals(constants.INVALID_PAYMENT_METHOD_VALUE_ERROR_MESSAGE, e.getmessage());
    }
    //system.AssertEquals(paymentRedirectController.pageId,'');
  }

  static testMethod void TestPageRedirectWithDirectDebit() {
    // Set mock callout class
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    //set page and variable action
    PageReference pageRef = Page.Zuora_PaymentStep;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put(Constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY, Constants.PAYMENT_STEP_PAGE_ACTION_ADD);

    //Create the zquotes
    testDataUtilityObj.createZquotes();
    testDataUtilityObj.lstZQuotes[0].zqu__PaymentMethod__c = Constants.DIRECT_DEBIT_PAYMENT_METHOD;
    update testDataUtilityObj.lstZQuotes[0];
    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
    testDataUtilityObj.createHostedPaymentPageSettings(Constants.DIRECT_DEBIT_PAYMENT_METHOD);

    ApexPages.StandardController standardControllerObj = new ApexPages.StandardController(testDataUtilityObj.lstZQuotes[0]);
    Zuora_PaymentRedirectController paymentRedirectController = new Zuora_PaymentRedirectController(standardControllerObj);

    paymentRedirectController.getPaymentMethods();
    PageReference pr = paymentRedirectController.updatePaymentPageFrame();

    Boolean isDD = paymentRedirectController.isDirectDebit;
    system.assert(isDD);
    Boolean renderFrame = paymentRedirectController.isRenderPaymentIframe;
    system.assert(!renderFrame);

  }

  static testMethod void TestPageRedirectWithCreditCard() {
    // Set mock callout class
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    //Create the zquotes
    testDataUtilityObj.createZquotes();
    testDataUtilityObj.lstZQuotes[0].zqu__PaymentMethod__c = Constants.CREDIT_CARD_PAYMENT_METHOD;
    update testDataUtilityObj.lstZQuotes[0];
    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
    testDataUtilityObj.createHostedPaymentPageSettings(Constants.CREDIT_CARD_PAYMENT_METHOD);

    ApexPages.StandardController standardControllerObj = new ApexPages.StandardController(testDataUtilityObj.lstZQuotes[0]);
    Zuora_PaymentRedirectController paymentRedirectController = new Zuora_PaymentRedirectController(standardControllerObj);

    paymentRedirectController.getPaymentMethods();
    PageReference pr = paymentRedirectController.updatePaymentPageFrame();

    paymentRedirectController.isDirectDebitConfirmed = true;
    Boolean isDD = paymentRedirectController.isDirectDebit;
    system.assert(!isDD);
    Boolean renderFrame = paymentRedirectController.isRenderPaymentIframe;
    system.assert(renderFrame);
  }
}