/**
* Author:       Michal Kwika (Accenture)
* Date:         18/01/2015
* Description:  this class is the controller of the page Zuora_ManageSubscriptionDecisionCtrl page
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Szewczyk   27/01/2016  Provided implementation of empty methods and add new ones
* Pawel Chrzanowski	24/06/2016	Added new methods
*/

@isTest
private class Zuora_ManageSubscriptionDecisionCtrlTest {
	
	static testMethod void noAccountFlowTest(){
			Test.setCurrentPage(Page.Zuora_ManageSubscriptionDecision);
			Zuora_ManageSubscriptionDecisionCtrl ctrl = new Zuora_ManageSubscriptionDecisionCtrl();
			System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
	}

	static testMethod void noActiveSubFlowTest(){
		// Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		 //Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
  		
       	testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
       	testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Status__c = Constants.SUBSCRIBER_INACTIVE_STATUS;
       	update testDataUtilityObj.lstZuoraSubscriptions;

		Test.setCurrentPage(Page.Zuora_ManageSubscriptionDecision);
		// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstRegistrants[0].id);

        Test.startTest();
			Zuora_ManageSubscriptionDecisionCtrl ctrl = new Zuora_ManageSubscriptionDecisionCtrl();
			ctrl.goToQuote();
			ctrl.redirectNewSubscription();
		Test.stopTest();
	}

	static testMethod void manageSubWithActiveSub(){
		// Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		 //Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
  		
       	testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

       	//open Billing Payment method page
		Test.setCurrentPage(Page.Zuora_ManageSubscriptionDecision);
		// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstRegistrants[0].id);

        Test.startTest();
			Zuora_ManageSubscriptionDecisionCtrl ctrl = new Zuora_ManageSubscriptionDecisionCtrl();
			System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR));
			ctrl.goToSubscription();
			ctrl.redirectActiveSubscription();
			ctrl.backToRecord();
		Test.stopTest();
	}

	static testMethod void manageSubWithSubPendingCancel(){
		// Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		 //Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
  		
       	testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
       	testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Status__c = Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS;
       	update testDataUtilityObj.lstZuoraSubscriptions;
       	//open Billing Payment method page
		Test.setCurrentPage(Page.Zuora_ManageSubscriptionDecision);
		// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstRegistrants[0].id);

        Test.startTest();
			Zuora_ManageSubscriptionDecisionCtrl ctrl = new Zuora_ManageSubscriptionDecisionCtrl();
			System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR));
			
			//invoke methods to improve coverage
			ctrl.revokeCancellation();
		Test.stopTest();
	}	

	static testMethod void checkLiteAccountTest(){
       	TestDataUtility tdu = new TestDataUtility(1);
       	tdu.createRegistrants();

	    Test.setCurrentPage(Page.Zuora_ManageSubscriptionDecision);
	    ApexPages.currentPage().getParameters().put('id', tdu.lstRegistrants[0].Id);

        Test.startTest();
			Zuora_ManageSubscriptionDecisionCtrl ctrl = new Zuora_ManageSubscriptionDecisionCtrl();
	       	ctrl.checkLiteAccount();
		Test.stopTest();
	}
}