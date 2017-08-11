@isTest
private class LatestSubscriptionControllerTest {

	/************************************************************************************
	Method Name  : testSetup
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@testSetup static void testSetup(){

		String recTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DDCX_CASE_RECORD_TYPE_NAME, Case.class.getName());
		DateTime dt      = null;
		String ocParameters = '{ "callStageParameters" : [ { "stagename" : "DDCX", "outcome" : "DD_Cancellation_Outcome__c", "calldatetime" : "DD_Cancellation_Call_Date_Time__c", "offset" : 0 , "tcode" : ""} ]}';

		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createOCSetting(Constants.OC_DDCX_CASE_RECORD_TYPE_NAME, Constants.OC_DDCX_VF_PAGE_NAME, ocParameters);
		tdu.createOutboundCallRule();
		tdu.createIndividualSubscribers();
		tdu.createSubscriptions();

		Case newCase                  	   = TestDataUtility.newOCCase(recTypeId, 'DDCX', tdu.lstSubscriptions[0].Id, tdu.lstIndividualSubscribers[0].Id);
		newCase.OC_Outcome__c         	   = Constants.OC_DEFAULT_OUTCOME;
		newCase.DD_Cancellation_Outcome__c = Constants.OC_DEFAULT_OUTCOME;
		newCase.Status                     = Constants.OC_DEFAULT_OUTCOME;
		insert newCase;
	}


	/************************************************************************************
	Method Name  : createNewPrintSubscriptionTest
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void createNewPrintSubscriptionTest() {

		List<Case> testCase = [ SELECT Id FROM Case ];

		Test.startTest();

		LatestSubscriptionController ctrl = new LatestSubscriptionController();
		ctrl.thisCase = testCase.get(0);
		ctrl.newSubscriptionType = Constants.PRODUCT_PRINT;
		ctrl.weeklyPrice = 10;
		ctrl.createNewSubscription();
		System.assert(ctrl.newSubscriptionUrl.contains(Constants.OC_DDCX_URL_PARAM), ctrl.newSubscriptionUrl);

		Test.stopTest();
		
	}
	
	/************************************************************************************
	Method Name  : createNewDigitalSubscriptionTest
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void createNewDigitalSubscriptionTest() {

		List<Case> testCase = [ SELECT Id FROM Case ];
		List<Account> testAccount = [SELECT Id FROM Account ];

		Test.startTest();

		LatestSubscriptionController ctrl = new LatestSubscriptionController();
		ctrl.thisCase = testCase.get(0);
		ctrl.newSubscriptionType = Constants.PRODUCT_DIGITAL;
		ctrl.createNewSubscription();
		System.assert(ctrl.newSubscriptionUrl.contains(testAccount.get(0).Id), ctrl.newSubscriptionUrl);

		Test.stopTest();
		
	}

	/************************************************************************************
	Method Name  : createNewSubscriptionCaseNotFoundTest
	Author       : Mantas Grigaliunas
	Created Date : 07/06/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void createNewSubscriptionCaseNotFoundTest() {

		Test.startTest();

		LatestSubscriptionController ctrl = new LatestSubscriptionController();
		ctrl.newSubscriptionType = Constants.PRODUCT_DIGITAL;
		ctrl.createNewSubscription();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Latest_Subscription_Case_Not_Found_Error), ApexPages.getMessages());

		Test.stopTest();
		
	}
	
}