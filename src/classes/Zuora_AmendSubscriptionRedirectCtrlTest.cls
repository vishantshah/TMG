/**
* Author:       Michal Kwika(Accenture)
* Date:         22/10/2015
* Description:  this class is the testing class for AmendSubscription
*
* ******************* Change Log *******************
* Modified by       Change Date  
* Michal Kwika		30/10/2015
**/
@isTest
private class Zuora_AmendSubscriptionRedirectCtrlTest {

	@isTest(seeAllData=true)
	static void testAmendSubscription() {
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		// Call method to test.
		// This causes a fake response to be sent
		// from the class that implements HttpCalloutMock.
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create a registrant
		testDataUtilityObj.createRegistrants();
		testDataUtilityObj.deleteApplicationSettings();
		testDataUtilityObj.CreateGracePeriodValueSetting(14);
		testDataUtilityObj.createTestQuoteCreationFailureCS(false);
		PageReference pageRef = Page.Zuora_AmendSubscriptionRedirect;
		Test.setCurrentPage(pageRef);

		//test the RedirectManageSubscription before adding query strings and this will throw an exception
		Zuora_AmendSubscriptionRedirectCtrl controller = new Zuora_AmendSubscriptionRedirectCtrl();
		controller.redirectAmendSubscription();

		//pass a new account without any subscription
		ApexPages.currentPage().getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstRegistrants[0].id);
		PageReference retPageRef = controller.redirectAmendSubscription();
		System.assert(retPageRef.getUrl().contains('quoteType=Subscription'));

		//pass an account with active subscription
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
		ApexPages.currentPage().getParameters().put(constants.ID_QUERY_STRING, testDataUtilityObj.lstZuoraSubscriptions[0].Id);
		retPageRef = controller.redirectAmendSubscription();

		//try to hard cancel subscription
		retPageRef = controller.hardCancelActiveSubscription();
		//change grace period and try again
		testDataUtilityObj.deleteApplicationSettings();
		testDataUtilityObj.CreateGracePeriodValueSetting(0);
		retPageRef = controller.hardCancelActiveSubscription();
		//check page
		List<Apexpages.Message> pageMessages = ApexPages.getMessages();
		System.assertNotEquals(pageMessages, null);

		//try to create new quote
		retPageRef = controller.createNewQuoteWithDetails();

		//add details from cancelled SUB
		testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Status__c = constants.SUBSCRIPTION_CANCELLED_STATUS;
		testDataUtilityObj.lstZuoraSubscriptions[0].Cancellation_Reason__c = Constants.SUBSCRIPTION_CANCELLATION_REASON_PRODUCTSWITCH;
		update testDataUtilityObj.lstZuoraSubscriptions[0];
		retPageRef = controller.redirectAmendSubscription();

		//validate the fllow when the account passed has pending cancellation subscription
		testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Status__c = constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS;
		update testDataUtilityObj.lstZuoraSubscriptions[0];
		retPageRef = controller.redirectAmendSubscription();

		//improve code coverage
		PageReference pr = controller.goToRevokeCancellationPage();
		pr = controller.goToListAccountaPage();
		pr = controller.goToAccountPage();
	}

	static testmethod void testOtherFlowSub() {
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		// Call method to test.
		// This causes a fake response to be sent
		// from the class that implements HttpCalloutMock.
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		testDataUtilityObj.createTestQuoteCreationFailureCS(false);
		//Create a registrant
		testDataUtilityObj.createRegistrants();
		testDataUtilityObj.CreateGracePeriodValueSetting(14);
		
		PageReference pageRef = Page.Zuora_AmendSubscriptionRedirect;
		Test.setCurrentPage(pageRef);

		//test the RedirectManageSubscription before adding query strings and this will throw an exception
		Zuora_AmendSubscriptionRedirectCtrl controller = new Zuora_AmendSubscriptionRedirectCtrl();
		ApexPages.currentPage().getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, '12345');
		controller.redirectAmendSubscription();

		//test correct
		ApexPages.currentPage().getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstRegistrants[0].id);
		controller.redirectAmendSubscription();

		//test quote failure
		testDataUtilityObj.createTestQuoteCreationFailureCS(true);
		ApexPages.currentPage().getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING, testDataUtilityObj.lstRegistrants[0].id);
		controller.redirectAmendSubscription();

		//pass an account with active subscription
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
		PageReference retPageRef = controller.redirectAmendSubscription();

		//failed quote
		controller.currentAccount = null;
		retPageRef = controller.createNewQuoteWithDetails();
	}

}