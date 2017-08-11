/**
* Author:       Sally ElGhoul (Tquila)
* Date:         09/06/2015
* Description:  this class for testing ZuoraPaymentPageDefaultPlugin
*
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin     24/05/2017  //removed useless references that were impacting totally unrelated functionality 
**/
@isTest
private class ZuoraPaymentPageDefaultPluginTest {

  static testMethod void myUnitTest() {
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

    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstZQuotes[0].id);
    ZuoraPaymentPageDefaultPlugin defaultControllerObj = new ZuoraPaymentPageDefaultPlugin();

    //call the method that set the default value of country by passing the payment method credit card
    Map < String, String > mapRessult = defaultControllerObj.getAdditionalParameters(constants.CREDIT_CARD_PAYMENT_METHOD);
  }

  static testMethod void testDirectDebit() {

    // Set mock callout class
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);

    //Create zquote record and this function will create a registrant as well
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    //Create the custom setting
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    //Create the zquotes
    testDataUtilityObj.createZquotes();

    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE);
    testDataUtilityObj.lstZuoraPaymentMethods[0].Zuora__Type__c = constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
    update testDataUtilityObj.lstZuoraPaymentMethods[0];

    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstZQuotes[0].id);

    //instantiate the controller
    ZuoraPaymentPageDefaultPlugin defaultControllerObj = new ZuoraPaymentPageDefaultPlugin();

    //call the method that set the default value of country by passing the payment method credit card
    Map < String, String > mapRessult = defaultControllerObj.getAdditionalParameters(constants.DIRECT_DEBIT_PAYMENT_METHOD);
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
    testDataUtilityObj.lstRegistrants[0].PersonMailingCountry = Constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE;
    testDataUtilityObj.lstRegistrants[0].PersonMailingState = Constants.COUNTRY_CANADA_TWO_LETTERS_CODE;
    update testDataUtilityObj.lstZuoraPaymentMethods[0];
    update testDataUtilityObj.lstRegistrants[0];

    //put the billing account and account id in the query string
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstBillingAccount[0].id);
    ApexPages.currentPage().getParameters().put('accountId', testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c);

    //instantiate the controller
    ZuoraPaymentPageDefaultPlugin defaultControllerObj = new ZuoraPaymentPageDefaultPlugin();

    //call the method that set the default value of country by passing the payment method credit card
    Map < String, String > mapRessult = defaultControllerObj.getAdditionalParameters(constants.DIRECT_DEBIT_PAYMENT_METHOD);

    Test.startTest();
    //switch payment method
    mapRessult = defaultControllerObj.getAdditionalParameters(constants.CREDIT_CARD_PAYMENT_METHOD);

    //dummy invoke of method
    ZuoraPaymentPageDefaultPlugin.getNameOfObjectBasedOnId('aTest');
    Test.stopTest();
  }
}