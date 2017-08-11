/**
* Author:       Sally ElGhoul (Tquila)
* Date:         08/06/2015
* Description:  this class for testing ZuoraPaymentPageGoBackPlugin
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      05/08/2015
**/
@isTest
private class ZuoraPaymentPageGoBackPluginTest {

  static testMethod void myUnitTest() {

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
    ZuoraPaymentPageGoBackPlugin controller = new ZuoraPaymentPageGoBackPlugin();

    //user should be redirected to the quote page
    PageReference retPageRef = controller.navigateBack('test');
    System.Assert(retPageRef.getUrl().contains(testDataUtilityObj.lstZQuotes[0].id));
  }

  //Michal Kwika SUB-100 04/08/2015
  //New method to handle Billing Account
  static testMethod void myUnitTestBillingAcc() {

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

    //Create Billing Acc
    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);

    //put the billing account and account id in the query string
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstBillingAccount[0].id);
    ApexPages.currentPage().getParameters().put('accountId', testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c);

    //call the navigatenext from the extended plugin
    ZuoraPaymentPageGoBackPlugin controller = new ZuoraPaymentPageGoBackPlugin();

    //user should be redirected to the summary page
    PageReference retPageRef = controller.navigateBack('test');
    System.Assert(retPageRef.getUrl().contains('Account_BillingPM_Summary'));
    System.Assert(retPageRef.getUrl().contains(testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c));
  }

  //Michal Kwika SUB-100 05/08/2015
  //New method to handle other object - mixed parameters
  static testMethod void myUnitTestUnhandledObject() {

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

    //Create Billing Acc
    testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);

    //put the billing account and account id in the query string
    ApexPages.currentPage().getParameters().put('accountId', testDataUtilityObj.lstBillingAccount[0].id);
    ApexPages.currentPage().getParameters().put('Id', testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c);

    //call the navigatenext from the extended plugin
    ZuoraPaymentPageGoBackPlugin controller = new ZuoraPaymentPageGoBackPlugin();

    //user should be redirected to the summary page
    PageReference retPageRef = controller.navigateBack('test');
    System.assertEquals(retPageRef, null);
  }
}