/**
* Author:       Sally ElGhoul (Tquila)
* Date:         15/07/2015
* Description:  this class for testing Zuora_sendToZBillingController
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      15/09/2015
* Michal Kwika      04/02/2016
* Wiktor Czykin     22/09/2016  //quick clean up across all methods related to logic changes in main class
**/
@isTest
private class Zuora_sendToZBillingControllerTest {

  static testMethod void testSendToZBilling() {
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    testDataUtilityObj.CreateGracePeriodValueSetting();
    testDataUtilityObj.createRegistrants();
    testDataUtilityObj.createZquotes();

    PageReference pageRef = Page.Zuora_sendToZBilling;
    Test.setCurrentPage(pageRef);
    pageRef.getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].zqu__Account__c);
    pageRef.getParameters().put(constants.PAYMENT_METHOD_ID_QUERY_STRING, 'testId');
    Zuora_sendToZBillingController controller = new Zuora_sendToZBillingController();
    System.assert(checkMessageExist(ApexPages.getMessages(), constants.ZUORA_ZBILLING_MISSING_QUERY_STRING_ERROR_MESSAGE));

    pageRef.getParameters().put(constants.QUOTE_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].id);
    controller = new Zuora_sendToZBillingController();
    controller.sendToZbilling();
    controller.goToAccountPage();
    //prepare a map of key and message to test the handlesendtoZbillingResult function
    Map<Boolean, String> mapTempValues = new Map<Boolean, String>();
    mapTempValues.put(true, 'Success Message');

    zqu.zQuoteUtil.zBillingResult billingResult = new zqu.zQuoteUtil.zBillingResult();
    billingResult.success = true;
    billingResult.sfdcQuoteId = testDataUtilityObj.lstZQuotes[0].Id;
    billingResult.zSubscriptionId = 'thisisarandomid123';
    List<zqu.zQuoteUtil.zBillingResult> lstBillingResults = new List<zqu.zQuoteUtil.zBillingResult>{billingResult};

    controller.handleSendtoZbillingResult(mapTempValues, lstBillingResults);
    System.assert(CheckMessageExist(ApexPages.getMessages(), 'Success Message'));

    mapTempValues = new map<boolean, string>();
    mapTempValues.put(false, 'Failure Message');
    controller.handleSendtoZbillingResult(mapTempValues, lstBillingResults);
    System.assert(CheckMessageExist(ApexPages.getMessages(), 'Failure Message'));
    //increase the code coverage and call gotoQuotePage
    PageReference retPageRef = controller.goToQuotePage();
    System.assert(retPageRef.getUrl().contains(testDataUtilityObj.lstZQuotes[0].id));
  }

  static testMethod void testSendToZBillingInvalidFirst() {
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    testDataUtilityObj.CreateGracePeriodValueSetting();
    testDataUtilityObj.createRegistrants();
    testDataUtilityObj.createZquotes();

    //update zquote to increase code coverage
    testDataUtilityObj.lstZQuotes[0].zqu__Previewed_Delta_MRR__c = -10;
    testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c = constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
    testDataUtilityObj.lstZQuotes[0].Previous_Subscription_RatePlan_Term_Type__c = '';
    update testDataUtilityObj.lstZQuotes[0];

    PageReference pageRef = Page.Zuora_sendToZBilling;
    Test.setCurrentPage(pageRef);
    //add the query strings
    pageRef.getParameters().put(constants.QUOTE_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].id);
    pageRef.getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].zqu__Account__c);
    pageRef.getParameters().put(constants.PAYMENT_METHOD_ID_QUERY_STRING, 'testId');

    //test the send to zbilling before adding query strings and this will throw an exception
    Zuora_sendToZBillingController controller = new Zuora_sendToZBillingController();
    controller.sendToZbilling();
    PageReference retPageRef = controller.goToQuotePage();
    System.assert(retPageRef.getUrl().contains(testDataUtilityObj.lstZQuotes[0].id));
  }

  static testMethod void testSendToZBillingInvalidMonthly() {
    // Set mock callout class
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    testDataUtilityObj.CreateGracePeriodValueSetting();
    testDataUtilityObj.createRegistrants();
    testDataUtilityObj.createZquotes();

    //update zquote to increase code coverage
    testDataUtilityObj.lstZQuotes[0].zqu__Previewed_Delta_MRR__c = -10;
    testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c = constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
    testDataUtilityObj.lstZQuotes[0].Previous_Subscription_RatePlan_Term_Type__c = constants.RATE_PLAN_MONTHLY;
    testDataUtilityObj.lstZQuotes[0].Subscription_Next_Charge_Date__c = Date.Today().addDays(5);
    update testDataUtilityObj.lstZQuotes[0];

    PageReference pageRef = Page.Zuora_sendToZBilling;
    Test.setCurrentPage(pageRef);
    //add the query strings
    pageRef.getParameters().put(constants.QUOTE_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].id);
    pageRef.getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].zqu__Account__c);
    pageRef.getParameters().put(constants.PAYMENT_METHOD_ID_QUERY_STRING, 'testId');

    //test the send to zbilling before adding query strings and this will throw an exception
    Zuora_sendToZBillingController controller = new Zuora_sendToZBillingController();

    //test the send to zbilling
    controller.sendToZbilling();

    //increase the code coverage and call gotoQuotePage
    PageReference retPageRef = controller.goToQuotePage();
    System.assert(retPageRef.getUrl().contains(testDataUtilityObj.lstZQuotes[0].id));
  }

  static testMethod void testSendToZBillingInvalidAnnual() {
    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
    testDataUtilityObj.CreateCoreApiEventEndPointSetting();
    testDataUtilityObj.CreateGracePeriodValueSetting(-15);
    testDataUtilityObj.createRegistrants();
    testDataUtilityObj.createZquotes();

    //update zquote to increase code coverage
    testDataUtilityObj.lstZQuotes[0].zqu__Previewed_Delta_MRR__c = -10;
    testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c = constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
    testDataUtilityObj.lstZQuotes[0].Previous_Subscription_RatePlan_Term_Type__c = constants.RATE_PLAN_ANNUAL;
    //testDataUtilityObj.lstZQuotes[0].Master_Quote__c = testDataUtilityObj.lstZQuotes[0].Id;
    update testDataUtilityObj.lstZQuotes[0];

    PageReference pageRef = Page.Zuora_sendToZBilling;
    Test.setCurrentPage(pageRef);
    //add the query strings
    pageRef.getParameters().put(constants.QUOTE_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].id);
    pageRef.getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstZQuotes[0].zqu__Account__c);
    pageRef.getParameters().put(constants.PAYMENT_METHOD_ID_QUERY_STRING, 'testId');
    //test the send to zbilling before adding query strings and this will throw an exception
    Zuora_sendToZBillingController controller = new Zuora_sendToZBillingController();
    controller.sendToZbilling();

    //increase the code coverage and call gotoQuotePage
    PageReference retPageRef = controller.goToQuotePage();
    retPageRef = controller.goToSummaryPage();
    System.assert(retPageRef.getUrl().contains(testDataUtilityObj.lstZQuotes[0].id));
  }

  //helper method to check the apex error messages
  public static Boolean checkMessageExist(List<Apexpages.Message> msgs, string ErrorMesage) {
    boolean isMessageExist = false;
    for (Apexpages.Message msg : msgs) {
      if (msg.getDetail().contains(ErrorMesage)) {
        isMessageExist = true;
      }
    }
    return isMessageExist;
  }
}
