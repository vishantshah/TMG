/**
* Author:       Michal Szewczyk
* Date:         21/01/2016
* Description:  this class for testing ZQuoteTriggerHandler
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Sally ElGhoul		18/2/2016	- test that term date is set correctly
* Michal KWika		29/02/2016	- changed the way of setting Expiration Date Time field
**/
@isTest
private class ZQuoteTriggerHandlerTest {

	static testMethod void fillQuoteExpirationFieldTest() {
        // Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();

		testDataUtilityObj.createZquotes();
		List<zqu__Quote__c> testQuoteslst = [SELECT Expiration_Date_Time__c FROM zqu__Quote__c WHERE id =:testDataUtilityObj.lstZQuotes[0].id];
		System.assertEquals(Date.today().addDays(1),testQuoteslst[0].Expiration_Date_Time__c);

	}	

	static testMethod void copyValuesForServiceActivationDateTest() {
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		testDataUtilityObj.createZquotes();
		List<zqu__Quote__c> testQuoteslst = [SELECT zqu__TermStartDate__c,zqu__Customer_Acceptance_Date__c,zqu__Service_Activation_Date__c FROM zqu__Quote__c WHERE id =:testDataUtilityObj.lstZQuotes[0].id];
		System.assertEquals(testQuoteslst[0].zqu__Customer_Acceptance_Date__c,testQuoteslst[0].zqu__Service_Activation_Date__c);
		
		//test that term start date = service activation date
		System.assertEquals(testQuoteslst[0].zqu__TermStartDate__c,testQuoteslst[0].zqu__Service_Activation_Date__c);
		
		//update the service activation date and make sure is term start date is updated correctly 
		testQuoteslst[0].zqu__Service_Activation_Date__c=Date.today().addMonths(2);
		update testQuoteslst[0];
		List<zqu__Quote__c> testUpdatedQuoteslst = [SELECT zqu__TermStartDate__c,zqu__Customer_Acceptance_Date__c,zqu__Service_Activation_Date__c FROM zqu__Quote__c WHERE id =:testDataUtilityObj.lstZQuotes[0].id];
		//test that term start date = service activation date
		System.assertEquals(testUpdatedQuoteslst[0].zqu__TermStartDate__c,testUpdatedQuoteslst[0].zqu__Service_Activation_Date__c);
		
	}

	static testMethod void extendTheQuoteTest() {

        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
		testDataUtilityObj.createZquotes();

		testDataUtilityObj.lstZQuotes[0].Extend_Quote_14_days__c = true;
		testDataUtilityObj.lstZQuotes[0].zqu__Status__c = Constants.QUOTE_STATUS_NEW_VALUE;
		testDataUtilityObj.lstZQuotes[0].Expiration_Date_Time__c = System.today();
		update testDataUtilityObj.lstZQuotes[0];
		List<zqu__Quote__c> testQuoteslst = [SELECT Expiration_Date_Time__c,zqu__ValidUntil__c FROM zqu__Quote__c WHERE id =:testDataUtilityObj.lstZQuotes[0].id];
		
		System.assertEquals(testQuoteslst[0].Expiration_Date_Time__c,System.today().addDays(Constants.QUOTE_NUMBER_OF_DAYS_EXTENDED_QUOTE));
	}
}