/**
* Author:       Sally ElGhoul (Tquila)
* Date:         29/09/2015
* Description:  Test Class for Zuora_SubscriptionAllAmendmentsCtrl
*
* ******************* Change Log *******************
**/
@isTest
private class Zuora_SubscriptionAllAmendmentsCtrlTest {

    static testMethod void testZuoraAmendments() {
    	// Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    	
    	//Controller of the default value we created to extend zuora
        ZuoraSubscriptionDefaultValues defaultValuesController=new ZuoraSubscriptionDefaultValues();
       	
       	//Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
       	
       	testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
       	
       	Zuora_SubscriptionAllAmendmentsCtrl ext = new Zuora_SubscriptionAllAmendmentsCtrl(new ApexPages.StandardController(testDataUtilityObj.lstZuoraSubscriptions[0]));
       	Test.startTest();
        Test.setCurrentPage(Page.Zuora_SubscriptionAllAmendments); 
        //empty original zuora subscription id
        ext.fetchAllAmendments();
        
        testDataUtilityObj.lstZuoraSubscriptions[0].Original_Zuora_Subscription_ID__c='12234555';
        update testDataUtilityObj.lstZuoraSubscriptions[0];
        ext.fetchAllAmendments();
    }
}