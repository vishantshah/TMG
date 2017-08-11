/**
* Author:       Sally ElGhoul (Accenture)
* Date:         1/09/2015
* Description:  this class for testing ZQuoteRatePlanTriggerHandler
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/

@isTest
private class ZQuoteRatePlanTriggerHandlerTest {

    static testMethod void myUnitTest() {
        // Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    	
       	//Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
       	
       	//set the quote to be new subscritpion 
       	testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c=constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
    	update testDataUtilityObj.lstZQuotes[0];
    	
    	//create quote amendment
    	zqu__QuoteAmendment__c amendmentObj=new zqu__QuoteAmendment__c();
    	amendmentObj.name=testDataUtilityObj.lstZQuotes[0].name=' Amendment';
    	amendmentObj.zqu__quote__c=testDataUtilityObj.lstZQuotes[0].id;
    	amendmentObj.zqu__Status__c='Draft';
    	amendmentObj.zqu__Status__c='Added Product Website+, RatePlan Open Offer - Monthly';
    	insert amendmentObj;
    	
    	
    	//create quote rate plan
    	zqu__QuoteRatePlan__c ratePlanObj=new zqu__QuoteRatePlan__c();
    	ratePlanObj.name='Open Offer - Monthly';
    	ratePlanObj.zqu__Quote__c=testDataUtilityObj.lstZQuotes[0].id;
    	ratePlanObj.zqu__AmendmentType__c='NewProduct';
    	ratePlanObj.zqu__QuoteProductName__c='Website+';
    	ratePlanObj.zqu__QuoteAmendment__c=amendmentObj.id;
    	insert ratePlanObj;
    	
    	list<zqu__Quote__c> lstUpdatedQuote=[select id,Subscription_Rate_Plan_Term_Type__c from zqu__Quote__c where id=:testDataUtilityObj.lstZQuotes[0].id];
   		system.assertEquals(lstUpdatedQuote[0].Subscription_Rate_Plan_Term_Type__c,constants.RATE_PLAN_MONTHLY);
    }
    
    static testMethod void validateSingleProduct() {
        
        string errorMessage='';
        // Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
    	
       	//Create zquote record and this function will create a registrant as well
       	TestDataUtility testDataUtilityObj=new TestDataUtility(1);
       	//Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create the zquotes
       	testDataUtilityObj.createZquotes();
       	
       	//set the quote to be new subscritpion 
       	testDataUtilityObj.lstZQuotes[0].zqu__SubscriptionType__c=constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
    	update testDataUtilityObj.lstZQuotes[0];
    	
    	//create quote amendment
    	zqu__QuoteAmendment__c amendmentObj=new zqu__QuoteAmendment__c();
    	amendmentObj.name=testDataUtilityObj.lstZQuotes[0].name=' Amendment';
    	amendmentObj.zqu__quote__c=testDataUtilityObj.lstZQuotes[0].id;
    	amendmentObj.zqu__Status__c='Draft';
    	amendmentObj.zqu__Status__c='Added Product Website+, RatePlan Open Offer - Monthly';
    	insert amendmentObj;
    	
    	
    	//create quote rate plan
    	zqu__QuoteRatePlan__c ratePlanObj=new zqu__QuoteRatePlan__c();
    	ratePlanObj.name='Open Offer - Monthly';
    	ratePlanObj.zqu__Quote__c=testDataUtilityObj.lstZQuotes[0].id;
    	ratePlanObj.zqu__AmendmentType__c='NewProduct';
    	ratePlanObj.zqu__QuoteProductName__c='Website+';
    	ratePlanObj.zqu__QuoteAmendment__c=amendmentObj.id;
    	insert ratePlanObj;
    	
    	try{
	    	//create 2nd quote amendment
	    	zqu__QuoteAmendment__c amendmentObj2=new zqu__QuoteAmendment__c();
	    	amendmentObj2.name=testDataUtilityObj.lstZQuotes[0].name=' Amendment';
	    	amendmentObj2.zqu__quote__c=testDataUtilityObj.lstZQuotes[0].id;
	    	amendmentObj2.zqu__Status__c='Draft';
	    	amendmentObj2.zqu__Status__c='Added Product Tablet+, RatePlan Open Offer - Monthly';
	    	insert amendmentObj2;
	    	
	    	zqu__QuoteRatePlan__c ratePlanObj2=new zqu__QuoteRatePlan__c();
	    	ratePlanObj2.name='Open Offer - Monthly';
	    	ratePlanObj2.zqu__Quote__c=testDataUtilityObj.lstZQuotes[0].id;
	    	ratePlanObj2.zqu__AmendmentType__c='NewProduct';
	    	ratePlanObj2.zqu__QuoteProductName__c='Tablet+';
	    	ratePlanObj2.zqu__QuoteAmendment__c=amendmentObj2.id;
	    	insert ratePlanObj2;
	    	
    	}catch(Exception e)
		{
			errorMessage=e.getMessage();
		}
		
		System.AssertEquals(errorMessage.contains(Label.Quote_Single_Product_Error_Message), true);
		 
		
    }
}