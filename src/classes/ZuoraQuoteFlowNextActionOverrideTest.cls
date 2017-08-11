/**
* Author:       Wiktor Czykin
* Date:         10/03/2016
* Description:  test class for ZuoraQuoteFlowNextActionOverride
* ******************* Change Log *******************
* Modified by       Change Date
* Lynette Lim         27-04-2016   Added testOldPrintInRenewalDateValidation()
**/
@isTest
private class ZuoraQuoteFlowNextActionOverrideTest {

	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        14/03/2016
	Function    Test validation for non registrants
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private static testMethod void testErrorForNonRegistrant(){
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('crmAccountId', td.lstIndividualSubscribers[0].Id);
			ZuoraQuoteFlowNextActionOverride updateController = new ZuoraQuoteFlowNextActionOverride();
			PageReference pr = updateController.doUpdate(new zqu__Quote__c(zqu__Account__c = td.lstIndividualSubscribers[0].Id), null);
			System.assertEquals(null, pr);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Quote_Flow_Non_registrant_account_error));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        14/03/2016
	Function    Test validation for ative old digital subscription
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private static testMethod void testErrorForActiveOldDigital(){
		TestDataUtility td = new TestDataUtility(1);
		td.createRegistrants();
		td.lstRegistrants[0].Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
		update td.lstRegistrants;

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('crmAccountId', td.lstRegistrants[0].Id);
			ZuoraQuoteFlowNextActionOverride updateController = new ZuoraQuoteFlowNextActionOverride();
			PageReference pr = updateController.doUpdate(new zqu__Quote__c(zqu__Account__c = td.lstRegistrants[0].Id), null);
			System.assertEquals(null, pr);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Quote_Flow_Active_subscription_error));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        14/03/2016
	Function    Test no error
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private static testMethod void testNoError(){
		TestDataUtility td = new TestDataUtility(1);
		td.createRegistrants();
		td.lstRegistrants[0].Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE;
		update td.lstRegistrants;

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('crmAccountId', td.lstRegistrants[0].Id);
			ZuoraQuoteFlowNextActionOverride updateController = new ZuoraQuoteFlowNextActionOverride();
			PageReference pr = updateController.doUpdate(new zqu__Quote__c(zqu__Account__c = td.lstRegistrants[0].Id), null);
			System.assertEquals(null, pr);
		Test.stopTest();
	}
	
	
	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        14/03/2016
	Function    Test validation activation date has to be at least +1 day cancellation date
	******************* Change Log *******************
	Modified by         Version     Change Date
	*******************************************************************************************/
	private static testMethod void testOldPrintPendingCancellationDateValidation(){
		TestDataUtility td = new TestDataUtility(1);
		td.checkRegistrantAccountDependencies();
		td.createSubscriptions();
		td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING_CANX;
		td.lstSubscriptions[0].Cancellation_Date__c = td.lstSubscriptions[0].Start_Date__c.addDays(10);
		td.lstSubscriptions[0].Cancellation_Reason__c = 'test';
		td.lstSubscriptions[0].Cancellation_Method__c = 'test';
		update td.lstSubscriptions;
		td.lstIndividualSubscribers[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		update td.lstIndividualSubscribers;

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('crmAccountId', td.lstIndividualSubscribers[0].Id);
			ZuoraQuoteFlowNextActionOverride updateController = new ZuoraQuoteFlowNextActionOverride();
			zqu__Quote__c quote = new zqu__Quote__c(zqu__Account__c = td.lstIndividualSubscribers[0].Id, zqu__Service_Activation_Date__c = td.lstSubscriptions[0].Cancellation_Date__c );
			PageReference pr = updateController.doUpdate(quote, null);
			System.assertEquals(null, pr);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Quote_Flow_Pending_cancellation_print_subscription_to_digital_wrong_date));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer   Lynette Lim
	Date        27/04/2016
	Function    Test validation activation date has to be at least +1 day end date
	******************* Change Log *******************
	Modified by         Version     Change Date
	*******************************************************************************************/
	private static testMethod void testOldPrintInRenewalDateValidation(){
		TestDataUtility td = new TestDataUtility(1);
		td.checkRegistrantAccountDependencies();
		td.checkSubscriptionDependencies();
		Subscription__c sub = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id,  UtilitySelectOptionsSubscriptions.getFirstStartDate(5));
		sub.Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
		insert sub;

		sub = [select Id, Start_Date__c, End_Date__c from Subscription__c where Id =:sub.id];

		td.lstIndividualSubscribers[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		update td.lstIndividualSubscribers;

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('crmAccountId', td.lstIndividualSubscribers[0].Id);
			ZuoraQuoteFlowNextActionOverride updateController = new ZuoraQuoteFlowNextActionOverride();
			zqu__Quote__c quote = new zqu__Quote__c(zqu__Account__c = td.lstIndividualSubscribers[0].Id, zqu__Service_Activation_Date__c = sub.End_Date__c );
			PageReference pr = updateController.doUpdate(quote, null);
			System.assertEquals(null, pr);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Quote_Flow_InRenewal_print_subscription_to_digital_wrong_date));
		Test.stopTest();
	}
	
}