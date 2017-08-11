/**
* Author:       Sally ElGhoul (Tquila)
* Date:         08/06/2015
* Description:  this class for testing ZuoraPaymentPageGoNextPlugin
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      05/08/2015
**/
@isTest
private class ZuoraPaymentPageGoNextPluginTest {

  static testMethod void testNegativeScenario() {

    //set the mockup for sendObject callout
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);

    //set the testing page
    PageReference pageRef = Page.Zuora_PaymentStep;
    Test.setCurrentPage(pageRef);

    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);

    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();

    //Create the zquotes
    testDataUtilityObj.createZquotes();

    //put the quote id in the query string
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstZQuotes[0].id);

    //call the navigatenext from the extended plugin
    ZuoraPaymentPageGoNextPlugin controller = new ZuoraPaymentPageGoNextPlugin();
    map<string, string> callbackParameters = new map<string, string>();
    callbackParameters.put('success', 'false');
    callbackParameters.put('errorMessage', 'errorMessage Test');

    //null pageReference should be returned
    PageReference retPageRef = controller.navigateNext('test', callbackParameters );
    System.AssertEquals(retPageRef, null);
  }

  static testMethod void testPositiveAddScenario() {

    //set the mockup for sendObject callout
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);

    //set the testing page
    PageReference pageRef = Page.Zuora_PaymentStep;
    Test.setCurrentPage(pageRef);

    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);

    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();

    //Create the zquotes
    testDataUtilityObj.createZquotes();

    //put the quote id in the query string
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstZQuotes[0].id);
    ApexPages.currentPage().getParameters().put(constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY, constants.PAYMENT_STEP_PAGE_ACTION_ADD);

    //call the navigatenext from the extended plugin
    ZuoraPaymentPageGoNextPlugin controller = new ZuoraPaymentPageGoNextPlugin();
    map<string, string> callbackParameters = new map<string, string>();
    callbackParameters.put('success', 'true');

    //user should be redirected to the quote page
    PageReference retPageRef = controller.navigateNext('test', callbackParameters );
    System.Assert(retPageRef.getUrl().contains(testDataUtilityObj.lstZQuotes[0].id));
  }

  static testMethod void testPositiveSendScenario() {

    //set the mockup for sendObject callout
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);

    //set the testing page
    PageReference pageRef = Page.Zuora_PaymentStep;
    Test.setCurrentPage(pageRef);

    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);

    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();

    //Create the zquotes
    testDataUtilityObj.createZquotes();

    //put the quote id in the query string
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstZQuotes[0].id);
    ApexPages.currentPage().getParameters().put(constants.PAYMENT_STEP_PAGE_ACTION_QUERY_STRING_KEY, constants.PAYMENT_STEP_PAGE_ACTION_SEND);

    //call the navigatenext from the extended plugin
    ZuoraPaymentPageGoNextPlugin controller = new ZuoraPaymentPageGoNextPlugin();
    map<string, string> callbackParameters = new map<string, string>();
    callbackParameters.put('success', 'true');

    //user should be redirected to the submit preview page
    PageReference retPageRef = controller.navigateNext('test', callbackParameters );
  }

  //Michal Kwika SUB 100 04/08/2015
  //new unit test method includes Billing Account Case
  static testMethod void billingAccountAddPayment() {

    // Set mock callout class
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);

    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    //Create the zquotes
    testDataUtilityObj.createZquotes();

    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
    testDataUtilityObj.lstZuoraPaymentMethods[0].Zuora__Type__c = constants.PAYMENT_METHOD_CREDIT_CARD_TYPE;
    update testDataUtilityObj.lstZuoraPaymentMethods[0];

    PageReference pageRef = Page.Zuora_PaymentStep;
    Test.setCurrentPage(pageRef);

    //put the billing account and account id in the query string
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstBillingAccount[0].id);
    ApexPages.currentPage().getParameters().put('accountId', testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c);

    //call the navigatenext from the extended plugin
    ZuoraPaymentPageGoNextPlugin controller = new ZuoraPaymentPageGoNextPlugin();
    map<string, string> callbackParameters = new map<string, string>();
    callbackParameters.put('success', 'true');

    //user should be redirected to the submit preview page
    PageReference retPageRef = controller.navigateNext('test', callbackParameters );
  }
}