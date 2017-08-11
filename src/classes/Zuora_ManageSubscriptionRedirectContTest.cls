/**
* Author:       Sally ElGhoul (Tquila)
* Date:         31/07/2015
* Description:  this class for testing Zuora_ManageSubscriptionRedirectCont
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Michal Kwika      27/08/2015
**/
@isTest
private class Zuora_ManageSubscriptionRedirectContTest {

    static testMethod void testManageSubscriptionRedirect() {
    	
    	// Set mock callout class 
        MockHttpCoreApiResponseGenerator ResponseGenerator=new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        TestDataUtility testDataUtilityObj=new TestDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //Create a registrant
        testDataUtilityObj.createRegistrants();
        
    	PageReference pageRef=Page.Zuora_ManageSubscriptionRedirect;
       	Test.setCurrentPage(pageRef);
       	
       	//test the RedirectManageSubscription before adding query strings and this will throw an exception
       	Zuora_ManageSubscriptionRedirectCont controller=new Zuora_ManageSubscriptionRedirectCont();
       	controller.RedirectManageSubscription();
       	system.assert(CheckMessageExist(ApexPages.getMessages(),Label.Manage_Subscription_Missing_Account_ID));
       	
       	//add an invalid account ID
       	ApexPages.currentPage().getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING,'22222');
       	controller.RedirectManageSubscription();
       	system.assert(CheckMessageExist(ApexPages.getMessages(),Label.Manage_Subscription_Invalid_Account_ID));
       
       	//pass a new account without any subscription 
       	ApexPages.currentPage().getParameters().put(constants.SF_ACCOUNT_ID_QUERY_STRING,testDataUtilityObj.lstRegistrants[0].id);
       	PageReference retPageRef=controller.RedirectManageSubscription();
       	System.assert(retPageRef.getUrl().contains('quoteType=Subscription'));
       	
       	//pass an account with active subscription so the user should be taken to amendment page
       	testDataUtilityObj.createBillingAccountToRegistrant(testDataUtilityObj.lstRegistrants[0].id,constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObj.createZuoraSubscriptionToRegistrant(testDataUtilityObj.lstRegistrants[0].id);
       	retPageRef=controller.RedirectManageSubscription();
       	System.assert(retPageRef.getUrl().contains('quoteType=Amendment'));
       	
       	//validate the fllow when the account passed has pending cancellation subscription
       	testDataUtilityObj.lstZuoraSubscriptions[0].Zuora__Status__c=constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS;
       	update testDataUtilityObj.lstZuoraSubscriptions[0];
       	retPageRef=controller.RedirectManageSubscription();
       	System.assert(retPageRef.getUrl().contains(constants.REVOKE_SUBSCRIPTION_CANCELLATION_PAGE_URL));  	

        //test also additional methods to cover code
        retPageRef = controller.goToListAccountaPage();
        retPageRef = controller.goToAccountPage();
    }
    
    //helper method to check the apex error messages
    public static boolean CheckMessageExist(List<Apexpages.Message> msgs,string ErrorMesage){
    	boolean isMessageExist = false;
	    for(Apexpages.Message msg:msgs){
	        if (msg.getDetail().contains(ErrorMesage)) {
	        	isMessageExist = true;
	        }
	    }
    	return isMessageExist;
    }
}