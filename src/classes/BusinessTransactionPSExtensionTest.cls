/**
* @author Pawel Chrzanowski
* @date 29/04/2016
* @description Test class for BusinessTransactionPSExtension
##########Change Log##########
Modified by         Version     Change Date
Wiktor Czykin       1.1         31/08/2016  //modified productSwitchPositive()
Vishant Shah		1.2 		05/10/2016	//Added productSwitchPaymentFailure() and added BusinessTransaction Status=Complete for productSwitchPositive()
*/
@isTest
private class BusinessTransactionPSExtensionTest {

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
		BusinessTransactionPSExtension controller;

		PageReference pr = Page.BusinessTransactionProductSwitch;
		Test.setCurrentPage(pr);

		Test.startTest();

			//no Subscription
			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Business_Transaction_Has_No_Related_Subscription));

			//no Zuora Id
			bt.Subscription__c = tdu.lstZuoraSubscriptions[0].Id;
			update bt;
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Has_No_Zuora_Id));

			//no Term End Date
			tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
			update tdu.lstZuoraSubscriptions[0];
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Has_No_TermEndDate));

		Test.stopTest();
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 29/04/2016
    Function - test negative scenarios of Product Switch validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testMethod void validateProductSwitchNegative(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		List<Business_Transaction__c> lstBt = new List<Business_Transaction__c>();
		lstBt.add(new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id));
		lstBt.add(new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id, Alternative_Offers__c='ao-1,ao-2,ao-3'));
		lstBt.add(new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id, Alternative_Offers__c='ao-1,ao-2,ao-3', Alternative_Offers_Names__c='alt offer 1,alt offer 2'));
		insert lstBt;

		ApexPages.StandardController sc;
		BusinessTransactionPSExtension controller;

		PageReference pr = Page.BusinessTransactionProductSwitch;
		Test.setCurrentPage(pr);

		Test.startTest();

			//no Alternative Offers
			sc = new ApexPages.StandardController(lstBt[0]);
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(!controller.hasAlternativeOffers);

			//no Alternative Offers Names
			sc = new ApexPages.StandardController(lstBt[1]);
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Alternative_Offers_No_Names));

			//Alternative Offers don't match Names
			sc = new ApexPages.StandardController(lstBt[2]);
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Alternative_Offers_Names_Mismatch));

		Test.stopTest();
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 29/04/2016
    Function - test positive scenario of Alterntive Offers validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testMethod void validateProductSwitchPositive(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Business_Transaction__c bt = new Business_Transaction__c(Subscription__c=tdu.lstZuoraSubscriptions[0].Id, Alternative_Offers__c='ao-1,ao-2,ao-3', Alternative_Offers_Names__c='alt offer 1,alt offer 2,alt offer 3');
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionPSExtension controller;

		PageReference pr = Page.BusinessTransactionProductSwitch;
		Test.setCurrentPage(pr);

		Test.startTest();

			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionPSExtension(sc);
			System.assert(controller.hasAlternativeOffers);
			System.assertEquals('0', controller.lstAlternativeOffers[0][0]);
			System.assertEquals('ao-1', controller.lstAlternativeOffers[0][1]);
			System.assertEquals('alt offer 1', controller.lstAlternativeOffers[0][2]);

		Test.stopTest();
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 29/04/2016
    Function - test positive scenario of Product Switch
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         31/08/2016  //added coverage for dml on Business Transaction
    Vishant Shah    1.2			05/10/2016  //Added Status for Business Transaction which was missing and Added Assertion
    ****************************************************************************************/
	static testMethod void productSwitchPositive(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.CreateCoreApiEndPointSettings();
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Business_Transaction__c bt = new Business_Transaction__c(Alternative_Offers__c='ao-1,ao-2,ao-3', Alternative_Offers_Names__c='alt offer 1,alt offer 2,alt offer 3', Subscription__c=tdu.lstZuoraSubscriptions[0].Id,
																 Status__c='Complete');
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionPSExtension controller;

		PageReference pr = Page.BusinessTransactionProductSwitch;
		Test.setCurrentPage(pr);

		Test.startTest();

			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionPSExtension(sc);

			System.assertEquals(false, controller.isStatusPaymentFailure, 'Business Transaction Status should not be Payment Failure.');
			System.assertEquals(true, controller.isStatusComplete, 'Business Transaction Status should be Complete.');

			System.assert(controller.hasAlternativeOffers);
			System.assertEquals('0', controller.lstAlternativeOffers[0][0]);
			System.assertEquals('ao-1', controller.lstAlternativeOffers[0][1]);
			System.assertEquals('alt offer 1', controller.lstAlternativeOffers[0][2]);

			controller.selectOffer();
			System.assert(!controller.showOfferList);
			System.assert(controller.showProductSwitchDate);
			System.assert(!controller.showProductSwitchResult);
			System.assert(String.isBlank(controller.selectedDate));
			System.assert(controller.switchBtnDisabled);

			controller.selectDate();
			System.assert(!controller.switchBtnDisabled);

			controller.cancelOffer();
			System.assert(controller.showOfferList);
			System.assert(!controller.showProductSwitchDate);
			System.assert(!controller.showProductSwitchResult);
			System.assert(String.isBlank(controller.selectedDate));

			controller.selectedOffer = '0';
			controller.selectedDate = Constants.OFFER_SWITCH_DATE_IMMEDIATE;
			MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
			Test.setMock(HttpCalloutMock.class, ResponseGenerator);
			controller.productSwitch();
			System.assertEquals(controller.resultMessage, Label.Upgrade_Subscription_Offer_Success);
		Test.stopTest();
        List<Business_Transaction__c> lstBt = [select Id, Agent_Name__c from Business_Transaction__c where Id = :bt.Id];
        System.assert(!lstBt.isEmpty());
        System.assertEquals(UserInfo.getName(), lstBt[0].Agent_Name__c);
	}
	/***************************************************************************************
    Developer - Vishant Shah
    Date - 05/10/2016
    Function - Test Product Switch for Payment Failure
    #############Change Log#############
    Modified by     Version     Change Date
    Vishant Shah    1.2         05/10/2016  //Check if Payment Failure property is set.
    ****************************************************************************************/
	static testMethod void productSwitchPaymentFailure(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.CreateCoreApiEndPointSettings();
		tdu.createRegistrants();
		tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.createZuoraSubscriptionToRegistrant(tdu.lstRegistrants[0].Id);
		tdu.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = '2c92c0f954601c92015462338c075e06';
		tdu.lstZuoraSubscriptions[0].Zuora__TermEndDate__c = Date.today().addDays(5);
		update tdu.lstZuoraSubscriptions[0];

		Business_Transaction__c bt = new Business_Transaction__c(Alternative_Offers__c='ao-1,ao-2,ao-3', Alternative_Offers_Names__c='alt offer 1,alt offer 2,alt offer 3', Subscription__c=tdu.lstZuoraSubscriptions[0].Id,
																 Status__c='Payment Failure');
		insert bt;

		ApexPages.StandardController sc;
		BusinessTransactionPSExtension controller;

		PageReference pr = Page.BusinessTransactionProductSwitch;
		Test.setCurrentPage(pr);

		Test.startTest();

			sc = new ApexPages.StandardController(bt);
			controller = new BusinessTransactionPSExtension(sc);

			System.assertEquals(true, controller.isStatusPaymentFailure, 'Business Transaction Status should be Payment Failure.');
			System.assertEquals(false, controller.isStatusComplete, 'Business Transaction Status should not be Complete.');

		Test.stopTest();
	}
}
