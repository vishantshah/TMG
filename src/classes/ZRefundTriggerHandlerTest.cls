/**
* Author:       Michal Kwika (Accenture)
* Date:         28/09/2015
* Description:  TriggerHandlerTest class on Zuora Refund Object
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika		08/10/2015
* Michal Kwika		09/02/2016 - added DDICA path\
* Wiktor Czykin		27/03/2016 - changes to reflect removal of DDICA and ARRUD behaviour in trigger
**/
@isTest(SeeAllData = true)
private class ZRefundTriggerHandlerTest {

	/***************************************************************************************
	Developer - Michal Kwika (Accenture)
	Date - 10/02/2016
	Version - 1.1
	Function - test Method to create Case based on Refund ARUDD code
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			27/03/2016	//changed ARRUD to ADDACS
	****************************************************************************************/
	static testmethod void test_CorrectPath() {
		// Implement test code
		// // Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//TestDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		//Create new Refund
		Zuora__Refund__c ref = TestDataUtility.newRefundRecordForPaymentIssueDD(Constants.CASE_REASONCODE_ADDACS+'-1', Constants.ZUORA_REFUND_REASONCODE_PAYMENTREJECTION, testDataUtilityObj.lstBillingAccount[0].Id);

		Test.startTest();
		insert ref;
		Test.stopTest();

		//check if case is created
		List <Case> lCasePayment = [SELECT Type, Gateway_Reason_code_source__c FROM Case WHERE Refund__c = :ref.Id LIMIT 1];
		System.assertNotEquals(0, lCasePayment.size());
		System.assertEquals(Constants.CASE_REASONCODE_ADDACS, lCasePayment.get(0).Gateway_Reason_code_source__c);

	}

	/***************************************************************************************
	Developer - Michal Kwika (Accenture)
	Date - 10/02/2016
	Version - 1.0
	Function - test Method to create Case based on Refund AUDDIS code
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	static testmethod void test_CorrectPathAUDDIS() {
		// Implement test code
		// // Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//TestDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		//Create new Refund
		Zuora__Refund__c ref = TestDataUtility.newRefundRecordForPaymentIssueDD('AUDDIS- 166', Constants.ZUORA_REFUND_REASONCODE_PAYMENTREJECTION, testDataUtilityObj.lstBillingAccount[0].Id);

		Test.startTest();
		insert ref;
		Test.stopTest();

		//check if case is created
		List <Case> lCasePayment = [SELECT Type, Gateway_Reason_code_source__c, Refund__c FROM Case WHERE Refund__c = :ref.Id LIMIT 1];
		System.assertNotEquals(0, lCasePayment.size());
		System.assertEquals(ref.Id, lCasePayment.get(0).Refund__c);
		System.assertEquals(Constants.CASE_REASONCODE_AUDDIS, lCasePayment.get(0).Gateway_Reason_code_source__c);

	}

	/***************************************************************************************
	Developer - Michal Kwika (Accenture)
	Date - 10/02/2016
	Version - 1.1
	Function - test Method to update Payment Status on related Case object
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			27/03/2016	//changed ARRUD to AUDDIS
	****************************************************************************************/
	static testmethod void test_CorrectPathWithUpdatePaymentField() {
		// Implement test code
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//TestDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		//Create new Refund
		Zuora__Refund__c ref = TestDataUtility.newRefundRecordForPaymentIssueDD(Constants.CASE_REASONCODE_AUDDIS+'-2', Constants.ZUORA_REFUND_REASONCODE_PAYMENTREJECTION, testDataUtilityObj.lstBillingAccount[0].Id);
		insert ref;
		//Create new Payment
		Zuora__Payment__c payment = new Zuora__Payment__c();
		payment.Zuora__Account__c = testDataUtilityObj.lstRegistrants[0].Id;
		payment.Zuora__Amount__c = 140;
		payment.Zuora__BillingAccount__c = testDataUtilityObj.lstBillingAccount[0].Id;
		insert payment;

		Test.startTest();

		ref.Zuora__Payment__c = payment.Id;
		update ref;
		Test.stopTest();

		//check if case has paymentId
		List <Case> lCasePayment = [SELECT Payment__c FROM Case WHERE Payment__c =:payment.Id LIMIT 1];
		System.assertNotEquals(0, lCasePayment.size());
	}

	/***************************************************************************************
	Developer - Michal Kwika (Accenture)
	Date - 10/02/2016
	Version - 1.1
	Function - test Method to create Case based on Refund DDICA code
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			27/03/2016	//changed assertions
	****************************************************************************************/
	static testmethod void test_CorrectPathDDICA() {
		// Implement test code
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		//Create zquote record and this function will create a registrant as well
		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create the custom setting
		//TestDataUtilityObj.CreateCoreApiEventEndPointSetting();
		//Create the zquotes
		testDataUtilityObj.createZquotes();
		testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id, constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);

		//Create new Refund
		Zuora__Refund__c ref = TestDataUtility.newRefundRecordForPaymentIssueDD('DDICA- 5', Constants.ZUORA_REFUND_REASONCODE_PAYMENTREJECTION, testDataUtilityObj.lstBillingAccount[0].Id);

		Test.startTest();
		insert ref;
		Test.stopTest();

		//check if case is created
		List <Case> lCasePayment = [SELECT Type, Gateway_Reason_code__c, Refund__c FROM Case WHERE Refund__c = :ref.Id LIMIT 1];
		
		System.assert(lCasePayment.isEmpty());
	
	}

}