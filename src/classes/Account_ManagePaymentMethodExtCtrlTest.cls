/**
* Author:       Michal Kwika (Tquila)
* Date:         28/07/2015
* Description:  this class for testing Account_ManagePaymentMethodExtCtrl
*
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest
private class Account_ManagePaymentMethodExtCtrlTest {

	//this method represents valid path
	static testmethod void validTest() {

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
		testDataUtilityObj.createHostedPaymentPageSettings(Constants.CREDIT_CARD_PAYMENT_METHOD);

		PageReference pageRef = Page.Account_Manage_Payment_Methods;
		Test.setCurrentPage(pageRef);

		Test.startTest();
		
		ApexPages.currentPage().getParameters().put('accountId', testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c);
		//As the payment method is empty this will always return an empty page ID
		ApexPages.StandardController standardControllerObj = new ApexPages.StandardController(testDataUtilityObj.lstBillingAccount[0]);

		try {
			//initiate controller
			Account_ManagePaymentMethodExtCtrl billingPMctrl = new Account_ManagePaymentMethodExtCtrl(standardControllerObj);
			//get list of payment method
			billingPMctrl.getPaymentMethods();
			Boolean isDD = billingPMctrl.isDirectDebit;
			Boolean isDDchecked = billingPMctrl.isDirectDebitConfirmed;
			Boolean isFrameOn = billingPMctrl.isRenderPaymentIframe;

			System.assertNotEquals(isDD, true);
			System.assertNotEquals(isDDchecked, true);
			System.assertEquals(isFrameOn, true);
			//change payment method to Direct Debit
			billingPMctrl.chosenPaymentMethod = Constants.DIRECT_DEBIT_PAYMENT_METHOD;
			billingPMctrl.updatePaymentPageFrame();

			isDD = billingPMctrl.isDirectDebit;
			isDDchecked = billingPMctrl.isDirectDebitConfirmed;
			isFrameOn = billingPMctrl.isRenderPaymentIframe;

			//frame should not be on because flag is not checked
			System.assertNotEquals(isDDchecked, true);
			System.assertEquals(isFrameOn, false);
			//set flag to check
			billingPMctrl.isDirectDebitConfirmed=true;

		} catch (exception e) {
			system.assertEquals(constants.INVALID_PAYMENT_METHOD_VALUE_ERROR_MESSAGE, e.getmessage());
		}
		Test.stopTest();

	}

	//this method represents invalid path with different parameter
	static testmethod void invalidTest() {

		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes - we are not creating hostedpagesetting to raise an error
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		
		PageReference pageRef = Page.Account_Manage_Payment_Methods;
		Test.setCurrentPage(pageRef);

		Test.startTest();
		ApexPages.currentPage().getParameters().put('pm', constants.DIRECT_DEBIT_PAYMENT_METHOD);
		ApexPages.currentPage().getParameters().put('accountId', testDataUtilityObj.lstBillingAccount[0].Zuora__Account__c);
		//As the payment method is empty this will always return an empty page ID
		ApexPages.StandardController standardControllerObj = new ApexPages.StandardController(testDataUtilityObj.lstBillingAccount[0]);

		try {
			//initiate controller and invoke error
			Account_ManagePaymentMethodExtCtrl billingPMctrl = new Account_ManagePaymentMethodExtCtrl(standardControllerObj);

		}catch (exception e) {
			system.assertEquals(constants.INVALID_PAYMENT_METHOD_VALUE_ERROR_MESSAGE, e.getmessage());
		}
		Test.stopTest();

	}
}