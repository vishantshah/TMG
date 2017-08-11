/**
* Author:       Michal Szewczyk
* Date:         27/01/2016
* Description:  this class is the controller of the page MakeRefund page
* ******************* Change Log *******************
* Modified by       Version   	Change Date
* Wiktor Czykin		1.1			15/02/2016	//added testQueryPaymentMethod()
* Pawel Chrzanowski 1.2         24/01/2017  //added commentTest()
*/
@isTest(SeeAllData=true)
private class MakeRefundTest {

	private static testMethod void noAccountFlowTest() {
		// Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		 //Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
  		
       	testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].Id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].Id);
		Test.setCurrentPage(Page.Make_Refund);
		
		ApexPages.StandardController stdBillingAccountCtrl = new ApexPages.StandardController(testDataUtilityObj.lstBillingAccount[0]);
		MakeRefund ctrl = new MakeRefund(stdBillingAccountCtrl);

		ctrl.getRefundTypeOptions();
		ctrl.getMethodTypeOptions();
		ctrl.getRefundReasonOptions();
		ctrl.cancel();
		ctrl.submit();
		ctrl.externalRefund();
		ctrl.creditCardRefund();
		ctrl.updateRefundTotal();
		ctrl.updateValues();
		ctrl.updateDate();
		ctrl.backToRefundTool();
		ctrl.confirmError();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 15/02/2016
    Version - 1.0
    Function - Added test coverage to queryPaymentMethod(). Covers different payment methods returned from sample responses.
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testQueryPaymentMethod(){
		TestDataUtility td = new TestDataUtility(1);
		Application_Settings__c appSetting = Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION);
		if(appSetting != null && String.isNotBlank(appSetting.Value__c) && Boolean.valueOf(appSetting.Value__c)){
			appSetting.Value__c = 'false';
			update appSetting;
		}

		td.createZuoraCustomerAccount();
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstBillingAccount[0]);
		MakeRefund ctrl = new MakeRefund(stdController);
		Test.startTest();
			//test credit card payment
			Zuora__PaymentMethod__c zpm = ctrl.queryPaymentMethod();
			System.assertNotEquals(null, zpm);
			System.assert(MakeRefund.mapTestObjects.containsKey(MakeRefund.REQUEST_QUERY_PAYMENT_METHOD));
			System.assertNotEquals(null, zpm.Zuora__CreditCardHolderName__c);

			//ach payment method check
			Zuora.zObject zObject = MakeRefund.mapTestObjects.get(MakeRefund.REQUEST_QUERY_PAYMENT_METHOD);
			zObject.setValue('Type', Constants.PAYMENT_METHOD_ACH_TYPE);
			zpm = ctrl.queryPaymentMethod();
			System.assertNotEquals(null, zpm);
			System.assertEquals(null, zpm.Zuora__CreditCardHolderName__c);
			
			//direct debit check
			zObject.setValue('Type', Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE);
			zpm = ctrl.queryPaymentMethod();
			System.assertNotEquals(null, zpm);
			System.assertEquals(null, zpm.Zuora__CreditCardHolderName__c);

			//paypal check
			zObject.setValue('Type', Constants.PAYMENT_METHOD_PAYPAL_TYPE);
			zpm = ctrl.queryPaymentMethod();
			System.assertNotEquals(null, zpm);
			System.assertEquals(null, zpm.Zuora__CreditCardHolderName__c);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 24/01/2017
    Comment test
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	@isTest static void commentTest(){
		TestDataUtility td = new TestDataUtility(1);
		Application_Settings__c appSetting = Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION);
		if(appSetting != null && String.isNotBlank(appSetting.Value__c) && Boolean.valueOf(appSetting.Value__c)){
			appSetting.Value__c = 'false';
			update appSetting;
		}

		td.createZuoraCustomerAccount();
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstBillingAccount[0]);
		MakeRefund ctrl = new MakeRefund(stdController);

		ctrl.refundAvailable = 20;
		ctrl.amount = 10;
		ctrl.refundReason = 'reason';
		ctrl.refundType = 'external';

		//comment too long
		ctrl.comment = 'aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa aaaaaaaaaaa about 300';
		ctrl.submit();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Comment_Too_Long));

		//comment ok
		ctrl.comment = 'comment';
		ctrl.submit();
	}
}