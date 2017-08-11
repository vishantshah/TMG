/**
* Author:       Gavin Palmer (Accenture)
* Date:         25/04/2016
* Description:  Test class for the core api callout from the 
*				Subscription plan upload record. 
*				Unfortunately I am unable to insert attachments in the test method so this area cannot be properly checked
* ******************* Change Log *******************
* Modified by       Change Date     Description
**/
@isTest
private class NotifyZuoraControllerTest{
	
	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         25/04/2016
	* Description:  Set up test data for unit tests
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@testSetup
	static void testDataSetup(){
		TestDataUtility testUtility = new TestDataUtility(1);
		// create the event endpoint URL
        testUtility.CreateCoreApiEndPointSettings();

		// create 2 subscription plan uploads, one in progress and one draft
		testUtility.createSubscriptionPlanUpload(Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_IN_PROGRESS);
		testUtility.createSubscriptionPlanUpload(Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_DRAFT);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         25/04/2016
	* Description:  Test the constructor when an exception is thrown
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	private static void constructorExceptionTest() {
		Test.startTest();
			NotifyZuoraController controller = new NotifyZuoraController(
				new ApexPages.StandardController(
					new Subscription_Plan_Upload__c()
				)
			);
		Test.stopTest();

		System.assertEquals(Label.Notify_Zuora_Error_Getting_Record, controller.pageText);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         25/04/2016
	* Description:  Test a callout that passes
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	private static void calloutPassTest() {
		List<Subscription_Plan_Upload__c> subscriptionPlanUpload = [
			SELECT Id
			FROM Subscription_Plan_Upload__c 
			WHERE Status__c = : Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_DRAFT
			LIMIT 1
		];
		System.assert(!subscriptionPlanUpload.isEmpty(), 'Unit test data not setup correctly');

		Test.setCurrentPage(Page.NotifyZuora);
		ApexPages.currentPage().getParameters().put('id', subscriptionPlanUpload[0].Id);

		Test.startTest();
			NotifyZuoraController controller = new NotifyZuoraController(new ApexPages.StandardController(subscriptionPlanUpload[0]));
			// set the override flag
			controller.canOverrideValidation = true;
			controller.calloutToCoreAPI();
		Test.stopTest();

		// check that the status has been updated and the page message is correct
		Subscription_Plan_Upload__c subscriptionPlanUploadAfterCallout = [
			SELECT Status__c
			FROM Subscription_Plan_Upload__c 
			WHERE Id = :subscriptionPlanUpload[0].Id
			LIMIT 1
		];
		System.assertEquals(Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_NOTIFIED, subscriptionPlanUploadAfterCallout.Status__c);
		System.assertEquals(Label.Notify_Zuora_Message_Sent, controller.pageText);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         25/04/2016
	* Description:  Test the callout with status not set to in progress
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	private static void calloutStatusNotDraftTest() {
		List<Subscription_Plan_Upload__c> subscriptionPlanUpload = [
			SELECT Id
			FROM Subscription_Plan_Upload__c 
			WHERE Status__c = : Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_IN_PROGRESS
			LIMIT 1
		];
		System.assert(!subscriptionPlanUpload.isEmpty(), 'Unit test data not setup correctly');

		Test.setCurrentPage(Page.NotifyZuora);
		ApexPages.currentPage().getParameters().put('id', subscriptionPlanUpload[0].Id);

		Test.startTest();
			NotifyZuoraController controller = new NotifyZuoraController(new ApexPages.StandardController(subscriptionPlanUpload[0]));
			controller.calloutToCoreAPI();
		Test.stopTest();

		System.assertEquals(Label.Notify_Zuora_Validation_Draft, controller.pageText);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         25/04/2016
	* Description:  Test the callout with no attachments
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	private static void calloutNoAttachmentTest() {
		// The query logic needs to filter more so that only objects without attatchments come out
		List<Subscription_Plan_Upload__c> subscriptionPlanUpload = [
			SELECT Id
			FROM Subscription_Plan_Upload__c 
			WHERE Status__c = : Constants.SUBSCRIPTION_PLAN_UPLOAD_STATUS_DRAFT
			LIMIT 1
		];
		System.assert(!subscriptionPlanUpload.isEmpty(), 'Unit test data not setup correctly');

		Test.setCurrentPage(Page.NotifyZuora);
		ApexPages.currentPage().getParameters().put('id', subscriptionPlanUpload[0].Id);

		Test.startTest();
			NotifyZuoraController controller = new NotifyZuoraController(new ApexPages.StandardController(subscriptionPlanUpload[0]));
			controller.calloutToCoreAPI();
		Test.stopTest();

		System.assertEquals(Label.Notify_Zuora_Validation_No_Attachment, controller.pageText);
	}
}