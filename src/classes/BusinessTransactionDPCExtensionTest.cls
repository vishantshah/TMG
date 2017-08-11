/**
* @author Pawel Chrzanowski
* @date 29/04/2016
* @description Test class for BusinessTransactionDPCExtension
##########Change Log##########
Modified by         Version     Change Date
Wiktor Czykin       1.1         31/08/2016  //modified discPriceChangePositive()
Vishant Shah		1.2 		05/10/2016	//Added discPricePaymentFailure() and added BusinessTransaction Status=Complete for discPriceChangePositive()
*/
@isTest
private class BusinessTransactionDPCExtensionTest {

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 29/04/2016
    Function - test negative scenarios of Business Transaction validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testMethod void validateBusinessTransactionNegative(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		update tdu.lstZuoraSubscriptions[0];

		Business_Transaction__c bt = new Business_Transaction__c();
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionDPCExtension controller;

		PageReference pr = Page.BusinessTransactionDiscPriceChange;
		Test.setCurrentPage(pr);

		Test.startTest();

			//no Subscription
			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionDPCExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Business_Transaction_Has_No_Related_Subscription));

			//no Zuora Id
			bt.Subscription__c = tdu.lstZuoraSubscriptions[0].Id;
			update bt;
			controller = new BusinessTransactionDPCExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Has_No_Zuora_Id));

			//no Term End Date
			tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
			update tdu.lstZuoraSubscriptions[0];
			controller = new BusinessTransactionDPCExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Has_No_TermEndDate));

		Test.stopTest();
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/05/2016
    Function - test negative scenarios of Discretionary Price Change validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testMethod void validateDiscPriceChangeNegative(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Business_Transaction__c bt = new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id);
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionDPCExtension controller;

		PageReference pr = Page.BusinessTransactionDiscPriceChange;
		Test.setCurrentPage(pr);

		Test.startTest();

			//no Rate Plan Charge
			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionDPCExtension(sc);
			System.assert(!controller.hasEligibleSubscription);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Has_No_Rate_Plan_Charge));

			//Rate Plan Charge missing Period/Product
			Zuora__SubscriptionProductCharge__c subscriptionProductCharge = new Zuora__SubscriptionProductCharge__c(Name='charge', Zuora__BillingPeriod__c='Month', Zuora__Subscription__c=tdu.lstZuoraSubscriptions[0].Id);
			insert subscriptionProductCharge;
			controller = new BusinessTransactionDPCExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Rate_Plan_Charge_No_Period_Product));

		Test.stopTest();
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/05/2016
    Function - test positive scenarios of Discretionary Price Change validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testMethod void validateDiscPriceChangePositive(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Zuora__Product__c zProduct = new Zuora__Product__c(Name='Test Name');
		insert zProduct;

		Zuora__SubscriptionProductCharge__c subscriptionProductCharge = new Zuora__SubscriptionProductCharge__c(Name='charge', Zuora__BillingPeriod__c='Month', Zuora__Product__c=zProduct.Id, Zuora__Subscription__c=tdu.lstZuoraSubscriptions[0].Id);
		insert subscriptionProductCharge;

		Business_Transaction__c bt = new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id);
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionDPCExtension controller;

		PageReference pr = Page.BusinessTransactionDiscPriceChange;
		Test.setCurrentPage(pr);

		Test.startTest();

			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionDPCExtension(sc);
			System.assert(controller.hasEligibleSubscription);

		Test.stopTest();
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/05/2016
    Function - test positive scenario of Discretionary Price Change
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         31/08/2016  //added coverage for dml on Business Transaction
    Vishant Shah    1.2 		05/10/2016  //Added Status for Business Transaction which was missing and Added Assertion
    ****************************************************************************************/
	static testMethod void discPriceChangePositive(){
		MockHttpCoreApiResponseGenerator mockResponse;
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.CreateCoreApiEndPointSettings();
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Zuora__Product__c zProduct = new Zuora__Product__c(Name='Test Name');
		insert zProduct;

		Zuora__SubscriptionProductCharge__c subscriptionProductCharge = new Zuora__SubscriptionProductCharge__c(Name='charge', Zuora__BillingPeriod__c='Month', Zuora__Product__c=zProduct.Id, Zuora__Subscription__c=tdu.lstZuoraSubscriptions[0].Id);
		insert subscriptionProductCharge;

		Business_Transaction__c bt = new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id, Status__c='Complete');
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionDPCExtension controller;

		PageReference pr = Page.BusinessTransactionDiscPriceChange;
		Test.setCurrentPage(pr);

		Test.startTest();

			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionDPCExtension(sc);
			
			System.assertEquals(false, controller.isStatusPaymentFailure, 'Business Transaction Status should not be Payment Failure.');
			System.assertEquals(true, controller.isStatusComplete, 'Business Transaction Status should be Complete.');

			System.assert(controller.hasEligibleSubscription);
			System.assert(controller.showDiscPriceChangeButton);
			System.assert(!controller.showDiscPriceChangeOfferList);
			System.assert(!controller.showDiscPriceChangeSelectedOffer);
			System.assert(!controller.showDiscPriceChangeResult);

			mockResponse = new MockHttpCoreApiResponseGenerator(200, 'GetOffersByProductAndFrequency');
			Test.setMock(HttpCalloutMock.class, mockResponse);
			controller.showDiscPriceChangeOffers();
			System.assert(!controller.showDiscPriceChangeButton);
			System.assert(controller.showDiscPriceChangeOfferList);
			System.assert(!controller.showDiscPriceChangeSelectedOffer);
			System.assert(!controller.showDiscPriceChangeResult);
			System.assert(String.isBlank(controller.selectedDiscPriceChangeOffer));

			controller.selectDiscPriceChangeOffer();
			System.assert(!controller.showDiscPriceChangeButton);
			System.assert(!controller.showDiscPriceChangeOfferList);
			System.assert(controller.showDiscPriceChangeSelectedOffer);
			System.assert(!controller.showDiscPriceChangeResult);

			controller.cancelDiscPriceChangeOffer();
			System.assert(!controller.showDiscPriceChangeButton);
			System.assert(controller.showDiscPriceChangeOfferList);
			System.assert(!controller.showDiscPriceChangeSelectedOffer);
			System.assert(!controller.showDiscPriceChangeResult);
			System.assert(String.isEmpty(controller.selectedDiscPriceChangeOffer));

			mockResponse = new MockHttpCoreApiResponseGenerator(200);
			Test.setMock(HttpCalloutMock.class, mockResponse);
			controller.selectedDiscPriceChangeOffer = '0';
			controller.discPriceChange();
			System.assert(!controller.showDiscPriceChangeButton);
			System.assert(!controller.showDiscPriceChangeOfferList);
			System.assert(!controller.showDiscPriceChangeSelectedOffer);
			System.assert(controller.showDiscPriceChangeResult);
			System.assertEquals(controller.resultMessage, Label.Put_Offer_Success);

		Test.stopTest();
        List<Business_Transaction__c> lstBt = [select Id, Agent_Name__c from Business_Transaction__c where Id = :bt.Id];
        System.assert(!lstBt.isEmpty());
        System.assertEquals(UserInfo.getName(), lstBt[0].Agent_Name__c);
	}

	/***************************************************************************************
    Developer - Vishant Shah
    Date - 05/10/2016
    Function - test scenario of Discretionary Price Change for Payment Failure
    #############Change Log#############
    Modified by     Version     Change Date
    Vishant Shah    1.2         05/10/2016  //Check if Payment Failure property is set.
    ****************************************************************************************/
	static testMethod void discPricePaymentFailure(){
		MockHttpCoreApiResponseGenerator mockResponse;
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.CreateCoreApiEndPointSettings();
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Zuora__Product__c zProduct = new Zuora__Product__c(Name='Test Name');
		insert zProduct;

		Zuora__SubscriptionProductCharge__c subscriptionProductCharge = new Zuora__SubscriptionProductCharge__c(Name='charge', Zuora__BillingPeriod__c='Month', Zuora__Product__c=zProduct.Id, Zuora__Subscription__c=tdu.lstZuoraSubscriptions[0].Id);
		insert subscriptionProductCharge;

		Business_Transaction__c bt = new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id, Status__c='Payment Failure');
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionDPCExtension controller;

		PageReference pr = Page.BusinessTransactionDiscPriceChange;
		Test.setCurrentPage(pr);

		Test.startTest();

			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionDPCExtension(sc);

			System.assertEquals(true, controller.isStatusPaymentFailure, 'Business Transaction Status should not be Payment Failure.');
			System.assertEquals(false, controller.isStatusComplete, 'Business Transaction Status should be Complete.');

		Test.stopTest();

	}

}
