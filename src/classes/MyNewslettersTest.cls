/************************************************************************************
Class Name   : MyNewslettersTest
Author       : Vishant Shah
Created Date : 02/12/2016
Function     : Test Class for MyNewsletters page controller
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
private class MyNewslettersTest {

	@TestSetup private static void setupData(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.CreateCoreApiEndPointSettings();
        tdu.createMyNewslettersEndPointSettings();
        tdu.loadCountryCodes();
        tdu.createIndividualSubscribers();
    }

	/************************************************************************************
    Method Name  : testNewletterFeatures
    Author       : Vishant Shah
    Created Date : 02/12/2016
    Function     : Test features to get, add and remove newsletters. did it in one method so we have access to id token and access token.
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	private static testMethod void testNewletterFeatures() {

		String categoryLifestyle = 'Lifestyle & Entertainment';
		String categoryLuxury = 'Luxury, Fashion & Beauty'; 
		String myNewsletters = ' My Newsletters';
        
		Account acc = [SELECT Id, Name, Subscriber_Number__c, PersonMailingPostalCode, Guid__c FROM Account LIMIT 1];

		Test.startTest();
        
		Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(IdentityUtilityTest.IDENTITY_RESPONSE_JSON, new Map<String, String>() ));
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        MyNewsletters myNLController = new MyNewsletters(controller);
        
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(MyNewslettersUtilityTest.generateMockNewsletters(), IdentityUtilityTest.HEADER_MAP));
		myNLController.getMyNewsletters();
		Map<String, List<MyNewsletterWrapper.Newsletters>> myNL = myNLController.categoryNewsletterMap;

		//Number of news letters will be 3 as we add My Newsletters in code.
		System.assertEquals(3, myNL.size());
		System.assertEquals(true, myNL.keySet().contains(myNewsletters));

		MyNewsletterWrapper.Newsletters nl;

		for (MyNewsletterWrapper.Newsletters news : myNL.get(categoryLuxury)){
			if (news.customerStatus == 'Active' ){
				nl = news;
				break;
			}
		}

		nl.customerStatus = 'Inactive';
		
		String jsonBody = JSON.serializePretty(nl);
        
		Test.setMock(HttpCalloutMock.class, new MockResponseGenerator(200, 'OK', jsonBody, IdentityUtilityTest.HEADER_MAP));
		myNLController.newsletterIdAction = 'Remove';
		myNLController.newsletterId = nl.id;
		myNLController.newsletterAction();

		myNLController.newsletterIdAction = 'Add';
		myNLController.newsletterId = nl.id;
		myNLController.newsletterAction();

		System.assertEquals('<tr width="100%">', myNLController.startTableRow);
		System.assertEquals('</tr>', myNLController.endTableRow);

        Test.stopTest();
	}
}