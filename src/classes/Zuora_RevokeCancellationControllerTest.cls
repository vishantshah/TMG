/**
* Author:       Michal Kwika (Accenture)
* Date:         08/09/2015
* Description:  this class is test for controller to the page Zuora_RevokeCancellation
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
@isTest(SeeAllData=true)
private class Zuora_RevokeCancellationControllerTest
{
	//this method tests some correct path and some incorrect path of nonamendment subscription
	static testmethod void invalidPathNonAmendmentSubscription()
	{
		// Given
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createHostedPaymentPageSettings(Constants.CREDIT_CARD_PAYMENT_METHOD);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		PageReference pageRef = Page.Zuora_RevokeCancellation;
		Test.setCurrentPage(pageRef);
		
		Test.startTest();

		ApexPages.currentPage().getParameters().put('accid', testDataUtilityObj.lstBillingAccount[0].Id);
		ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstZuoraSubscriptions[0].Id);

		Zuora_RevokeCancellationController ctrl = new Zuora_RevokeCancellationController();
		ctrl.onLoad();
		ctrl.resetCancellationFields(testDataUtilityObj.lstZuoraSubscriptions[0]);
		ctrl.backToRecord();

		Test.stopTest();
		// Then

	}

	//happy flow
	static testmethod void correctPath(){
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createHostedPaymentPageSettings(Constants.CREDIT_CARD_PAYMENT_METHOD);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		//that should be amendment-simulation
		testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Version__c = 2;
		update testDataUtilityObj.lstZuoraSubscriptions[0];

		PageReference pageRef = Page.Zuora_RevokeCancellation;
		Test.setCurrentPage(pageRef);
		
		Test.startTest();

		ApexPages.currentPage().getParameters().put('accid', testDataUtilityObj.lstBillingAccount[0].Id);
		ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstZuoraSubscriptions[0].Id);

		Zuora_RevokeCancellationController ctrl = new Zuora_RevokeCancellationController();
		ctrl.onLoad();
		ctrl.resetCancellationFields(testDataUtilityObj.lstZuoraSubscriptions[0]);
		ctrl.backToRecord();

		Test.stopTest();
	}

	//imporving class coverage through invoking an error
	static testmethod void throwErrorMessages(){

		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createHostedPaymentPageSettings(Constants.CREDIT_CARD_PAYMENT_METHOD);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		PageReference pageRef = Page.Zuora_RevokeCancellation;
		Test.setCurrentPage(pageRef);

		//do not put any ids there
		Test.startTest();
		Zuora_RevokeCancellationController ctrl = new Zuora_RevokeCancellationController();
		//invoke without instatiating
		ctrl.onLoad();
		ctrl.resetCancellationFields(null);
		//set id and try other methods
		ApexPages.currentPage().getParameters().put('accid', testDataUtilityObj.lstBillingAccount[0].Id);
		ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstZuoraSubscriptions[0].Id);
		ctrl = new Zuora_RevokeCancellationController();
		ctrl.findDeleteAmendment();

		Test.stopTest();

	}
}