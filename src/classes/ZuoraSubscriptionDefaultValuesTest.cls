/**
* Author:       Sally ElGhoul (Tquila)
* Date:         23/04/2015
* Description:  this class for testing ZuoraSubscriptionDefaultValues
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      15/09/2015
* Wiktor Czykin		14/03/2016	//added test coverage for added functionality
* Lynette Lim       27-04-2016   Added testOldPrintInRenewalDateValidation()
**/
@isTest
private class ZuoraSubscriptionDefaultValuesTest {

	private  static testMethod void testDefaultValues() {
		TestDataUtility td = new TestDataUtility(1);
		td.createZquotes();
		td.lstZQuotes[0].Subscription_Rate_Plan_Term_Type__c = Constants.QUOTE_SUBSCRIPTION_TERM_TYPE_FIELD;
		update td.lstZQuotes[0];
		//create another subscription and assign
		td.createBillingAccountToRegistrant(td.lstRegistrants[0].Id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
		td.createZuoraSubscriptionToRegistrant(td.lstRegistrants[0].Id);
		td.lstZuoraSubscriptions[0].Related_Quote__c = td.lstZQuotes[0].Id;
		td.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = td.lstZuoraSubscriptions[0].Id;
		td.lstZuoraSubscriptions[0].Zuora__NextChargeDate__c = Date.today().addDays(1);
		update td.lstZuoraSubscriptions[0];

		ApexPages.currentPage().getParameters().put('subscriptionId', td.lstZuoraSubscriptions[0].Id);

		//set the quote to be new subscritpion
		td.lstZQuotes[0].zqu__SubscriptionType__c = Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE;
		update td.lstZQuotes[0];

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);

			//Controller of the default value we created to extend zuora
			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			//call the function that will set the default values
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.INITIAL_TERM_FIELD), Constants.INITIAL_TERM_VALUE_DEFAULT);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.RENEWAL_TERM_FIELD), Constants.RENEWAL_TERM_VALUE_DEFAULT);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.START_DATE_FIELD), Date.today());
			System.AssertEquals(td.lstZQuotes[0].get(Constants.VALID_UNTI_DATE_FIELD), Date.today());

			//quote amendment type
			td.lstZQuotes[0].zqu__SubscriptionType__c = Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
			update td.lstZQuotes[0];
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);

			td.createBillingAccountToRegistrant(td.lstRegistrants[0].id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);

			td.lstZuoraPaymentMethods[0].Zuora__Type__c = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
			update td.lstZuoraPaymentMethods[0];
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);
		Test.stopTest();
	}

	//test this case with Direct Debit
	private static testMethod void testDefaultValuesDirectDebit() {
		TestDataUtility td = new TestDataUtility(1);
		td.createZquotes();
		td.lstZQuotes[0].Subscription_Rate_Plan_Term_Type__c = Constants.QUOTE_SUBSCRIPTION_TERM_TYPE_FIELD;
		update td.lstZQuotes[0];
		//create another subscription and assign
		td.createBillingAccountToRegistrant(td.lstRegistrants[0].id, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE);
		td.createZuoraSubscriptionToRegistrant(td.lstRegistrants[0].id);
		td.lstZuoraSubscriptions[0].Related_Quote__c = td.lstZQuotes[0].Id;
		td.lstZuoraSubscriptions[0].Zuora__Zuora_Id__c = td.lstZuoraSubscriptions[0].Id;
		td.lstZuoraSubscriptions[0].Zuora__NextChargeDate__c = Date.today().addDays(1);
		td.lstZuoraSubscriptions[0].Master_Quote__c = td.lstZQuotes[0].Id;
		update td.lstZuoraSubscriptions[0];

		ApexPages.currentPage().getParameters().put('subscriptionId', td.lstZuoraSubscriptions[0].Id);

		//set the quote to be new subscritpion
		td.lstZQuotes[0].zqu__SubscriptionType__c = Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE;
		update td.lstZQuotes[0];

		Test.startTest();
			PageReference pageRef = Page.Zuora_PaymentStep;
			Test.setCurrentPage(pageRef);

			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			//call the function that will set the default values
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.INITIAL_TERM_FIELD), Constants.INITIAL_TERM_VALUE_DEFAULT);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.RENEWAL_TERM_FIELD), Constants.RENEWAL_TERM_VALUE_DEFAULT);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.START_DATE_FIELD), Date.today());
			//System.AssertEquals(td.lstZQuotes[0].get(Constants.PAYMENT_METHOD_FIELD),Constants.CREDIT_CARD_PAYMENT_METHOD);
			System.AssertEquals(td.lstZQuotes[0].get(Constants.VALID_UNTI_DATE_FIELD), Date.today());

			//quote amendment type
			td.lstZQuotes[0].zqu__SubscriptionType__c = Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
			update td.lstZQuotes[0];
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);

			td.createBillingAccountToRegistrant(td.lstRegistrants[0].id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);

			td.lstZuoraPaymentMethods[0].Zuora__Type__c = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
			update td.lstZuoraPaymentMethods[0];
			defaultValuesController.populateDefaultFieldValue(td.lstZQuotes[0], null);

		Test.stopTest();
	}

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
			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			defaultValuesController.populateDefaultFieldValue(new zqu__Quote__c(zqu__Account__c = td.lstIndividualSubscribers[0].Id), null);
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
			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			defaultValuesController.populateDefaultFieldValue(new zqu__Quote__c(zqu__Account__c = td.lstRegistrants[0].Id), null);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Quote_Flow_Active_subscription_error));
		Test.stopTest();
	}
	
	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        14/03/2016
	Function    Test activation date is +1 day cancellation date
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private static testMethod void testOldPrintPendingCancellationDateAsDefault(){
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
			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			zqu__Quote__c quote = new zqu__Quote__c(zqu__Account__c = td.lstIndividualSubscribers[0].Id);
			defaultValuesController.populateDefaultFieldValue(quote, null);
			System.assertEquals(td.lstSubscriptions[0].Cancellation_Date__c.addDays(1), quote.zqu__Service_Activation_Date__c);
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer   Wiktor Czykin
	Date        14/03/2016
	Function    Test activation date is +1 day cancellation date
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private static testMethod void testOldPrintPendingCancellationDateAsNotDefaultWhenOverriden(){
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
			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			Date dToCheck = td.lstSubscriptions[0].Cancellation_Date__c.addDays(100);
			zqu__Quote__c quote = TestDataUtility.newZquote(td.lstIndividualSubscribers[0].Id);
			quote.zqu__Service_Activation_Date__c = dToCheck;
			insert quote;
			
			defaultValuesController.populateDefaultFieldValue(quote, null);
			System.assertEquals(dToCheck, quote.zqu__Service_Activation_Date__c);
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer   Lynette Lim
	Date        14/03/2016
	Function    Test activation date is +1 day end date
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private static testMethod void testOldPrintInRenewalDateAsDefault(){
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
			ZuoraSubscriptionDefaultValues defaultValuesController = new ZuoraSubscriptionDefaultValues();
			zqu__Quote__c quote = new zqu__Quote__c(zqu__Account__c = td.lstIndividualSubscribers[0].Id);
			defaultValuesController.populateDefaultFieldValue(quote, null);
			
			System.assertEquals(sub.End_Date__c.addDays(1), quote.zqu__Service_Activation_Date__c);
		Test.stopTest();
	}
}