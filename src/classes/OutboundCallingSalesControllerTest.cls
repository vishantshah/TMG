/************************************************************************************
Class Name   : OutboundCallingSalesControllerTest
Author       : Mantas Grigaliunas
Created Date : 10/08/2016
Function     : OutboundCallingSalesController class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    			Date      	Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas Grigaliunas	19/08/2016  Renamed constant OC_CALL_STAGE_T2_28DAYS to OC_CALL_STAGE_T2
* Mantas Grigaliunas	30/08/2016	Modified testSaveSub
* Pawel Chrzanowski	    12/09/2016  added coverage
* Mantas Grigaliunas	07/10/2016	Removed Retailer search related variables
* Mantas Grigaliunas	17/10/2016	Added deliveryTypeChangeTest
* Wiktor Czykin			26/10/2016  Fixed tests
* Pawel Chrzanowski     06/12/2016  Modified testRefetchSubscriberEmail()
* Wiktor Czykin			13/12/2016  Added testSaveAndTakePaymentWeeklyPriceCheck()
* Wiktor Czykin			14/12/2016  Modified testSaveSub()
* Pawel Chrzanowski     14/12/2016  Modified testSaveAndTakePayment()
* Wiktor Czykin			14/12/2016  Modified caseScheduledCallbackChangeTest()
* Vishant Shah			20/12/2016	removed hardcoding of Timestamp. caseScheduledCallbackChangeTest() Jira: SUB-6083
* Wiktor Czykin			11/04/2017	Added testSaveAndTakePaymentNoProductForTCodeError() and testOnClickGetCustomerWrongProductForTCode()
* Pawel Chrzanowski     03/05/2017  removed unused Marketing Preferences
*************************************************************************************/

@isTest
private class OutboundCallingSalesControllerTest {

	private static final Integer RECORDS_SIZE = 2;


	/************************************************************************************
	Method Name  : testSetup
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@testSetup static void testSetup(){

		final String DEFAULT_CASE_STATUS = 'Not Started';

		TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);

		/* CREATE OUTBOUND CALL SETTING AND RULES */
		tdu.iCounter = 1;
		tdu.createSalesOutboundCallSetting();
		tdu.createOutboundCallRule();

		/* CUSTOM SETTINGS */
		tdu.loadCountryCodes();		
		TestDataUtility.createOCCaseAutocloseCustomSettingInstance();

		/* CREATE TCODEMANAGEMENT AND TCODE PRODUCTS*/
		//need to create extra subscription to use as previous subscription
		tdu.iCounter = RECORDS_SIZE;
		tdu.createTCodeManagement();
		tdu.createZProduct();
		tdu.createTCodeProducts();
		tdu.createCheques();
		tdu.createSubscriptionIncentiveAssociation();
		tdu.createTCodeProductIncentives();


		/* CREATE ACCOUNTS, SUBSCRIPTION AND CASES */
		tdu.createIndividualSubscribers();
		tdu.createSubscriptions();
		//use last subscription record as previous subscription
		Integer index = tdu.lstSubscriptions.size() - 1;
		for(Integer i = 0; i < index; i++){
			tdu.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_OFFERED;
			tdu.lstSubscriptions[i].PaymentDate__c = '1';
			tdu.lstSubscriptions[i].TCode__c = tdu.lstTCodeManagement[i].Id;
			tdu.lstSubscriptions[i].Previous_Subscription__c = tdu.lstSubscriptions[index].Id;
		}
		update tdu.lstSubscriptions;
		tdu.iCounter = RECORDS_SIZE - 1;
		tdu.createOCCases(Constants.OC_SALES_RECORD_TYPE_NAME);
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSetting
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Mantas Grigaliunas	07/10/2016	 Removed retailers related test data 
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSetting() {

		setPageUrl();
		
		delete [SELECT Id FROM Outbound_Call_Setting__c];

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
		String.format(Label.Outbound_Calling_Missing_Setting_Record, new List<String>{Constants.OC_SALES_RECORD_TYPE_NAME})));
        Boolean cnb = ocsc.createNewBatch;
        CaseComment cc = ocsc.newComment;
        ocsc.offeredSubscriptionMsg = true;
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSettingParameter
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSettingParameter() {

		setPageUrl();
		
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c LIMIT 1];
		ocSetting.Parameters__c = null;
		update ocSetting;
 
		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.Outbound_Calling_Missing_Setting_Parameters, new List<String>{ocSetting.Name}))
		);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSettingRule
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	Pawel Chrzanowski	09/09/2016	de-activated ocRule before deleting
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSettingRule() {

		setPageUrl();
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1];
		Outbound_Call_Rule__c ocRule = [SELECT Id FROM Outbound_Call_Rule__c LIMIT 1];
		ocRule.Active__c = false;
		update ocRule;
		delete ocRule;

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.Outbound_Calling_Missing_Setting_Rule, new List<String>{ocSetting.Name}))
		);
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testOnClickGetCustomerNoCasesFound
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOnClickGetCustomerNoCasesFound() {
		
		setPageUrl();
		delete [SELECT Id FROM Case];

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.No_Cases_Found, new List<String>{ocsc.callType}))
		);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testOnClickGetCustomerCaseExist
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOnClickGetCustomerCaseExist() {
		
		setPageUrl();
		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testOnClickGetCustomerWrongProductForTCode
	Author       : Wiktor Czykin	
	Created Date : 11/04/2017
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOnClickGetCustomerWrongProductForTCode() {
		setPageUrl();

		List<TCode_Product__c> lstTcodeProducts = [SELECT Id FROM TCode_Product__c];
		delete lstTcodeProducts;

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;

		ocsc.onClickGetCustomer();
		System.assert(ocsc.formMsg);
		System.assert(ApexPages.getMessages().size() == 1, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeChangedToBusy
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/	
	@isTest static void testSaveCustomerOutcomeChangedToBusy() {
		
		setPageUrl();

		Case newCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case LIMIT 1];
		System.assertNotEquals(newCase.OC_Stage_1_Call_Date_Time__c, inProgressCase.OC_Stage_1_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_BUSY;
		ocsc.onClickSaveAndGetNextCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(inProgressCase.OC_Stage_1_Call_Date_Time__c, savedCase.OC_Stage_1_Call_Date_Time__c);
		System.assertEquals(savedCase.OC_Scheduled_Callback__c, savedCase.OC_Stage_1_Call_Date_Time__c);
	}

	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeChangedToNoAnswer
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveCustomerOutcomeChangedToNoAnswer() {
		
		setPageUrl();

		Case newCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(newCase.OC_Stage_1_Call_Date_Time__c, inProgressCase.OC_Stage_1_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_NOANSWER;
		ocsc.saveCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(inProgressCase.OC_Stage_1_Call_Date_Time__c, savedCase.OC_Stage_1_Call_Date_Time__c);
		System.assertEquals(savedCase.OC_Scheduled_Callback__c, savedCase.OC_Stage_1_Call_Date_Time__c);
	}
	
	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeChangedToAnswerPhone
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveCustomerOutcomeChangedToAnswerPhone() {
		
		setPageUrl();

		Case newCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(newCase.OC_Stage_1_Call_Date_Time__c, inProgressCase.OC_Stage_1_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_ANSWERPHONE;
		ocsc.saveCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(inProgressCase.OC_Stage_1_Call_Date_Time__c, savedCase.OC_Stage_1_Call_Date_Time__c);
		System.assertEquals(savedCase.OC_Scheduled_Callback__c, savedCase.OC_Stage_1_Call_Date_Time__c);
	}
	
	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeNotChanged
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveCustomerOutcomeNotChanged() {
		
		setPageUrl();

		Case newCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, Status, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(Constants.CASE_STATUS_INPROGRESS, inProgressCase.Status);
		System.assertNotEquals(newCase.OC_Stage_1_Call_Date_Time__c, inProgressCase.OC_Stage_1_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.OC_DEFAULT_OUTCOME;
		ocsc.saveCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assert(savedCase.OC_Scheduled_Callback__c == null, 'OC_Scheduled_Callback__c expected to be null');
		System.assertEquals(inProgressCase.OC_Stage_1_Call_Date_Time__c, savedCase.OC_Stage_1_Call_Date_Time__c);
	}
	
	/************************************************************************************
	Method Name  : testSaveCustomerAlreadySaved
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveCustomerAlreadySaved() {
		
		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		//Modify same case by another user
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createUsers(null); //System Administrator profile user

		Case testCase = [SELECT Id, OC_Outcome__c FROM Case LIMIT 1];
		System.assertEquals(ocsc.thisCase.Id, testCase.Id);

		System.runAs(tdu.lstUsers[0]){
			testCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
			update testCase;
		}

		ocsc.saveCustomer();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.Outbound_Call_Case_Already_Saved, new List<String>{tdu.lstUsers[0].FirstName + ' ' + tdu.lstUsers[0].LastName})),
		ApexPages.getMessages());
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testSaveAndTakePayment
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Currently calls the method and only checks if there are no exceptions, further test methods are required
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer          Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Pawel Chrzanowski  14/12/2016   Added Sale outcome validation
	*************************************************************************************/
	@isTest static void testSaveAndTakePayment() {
		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();

		//validate Sale outcome
		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_BUSY;
		ocsc.saveAndTakePayment();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_ensure_agentOutboundCommision));

		//validate Sale payment type
		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
		ocsc.thisSubscription.Payment_Type__c = Constants.SUB_PMETHOD_CHEQUE;
		ocsc.saveAndTakePayment();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Update_Payment_Type));

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
		ocsc.thisSubscription.Payment_Type__c = Constants.SUB_ACQUISITION_PAYMENT_CC;
		PageReference pr = ocsc.saveAndTakePayment();
		System.assertNotEquals(null, pr, 'Returned page reference expected not to be empty');
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testSaveAndTakePaymentNoProductForTCodeError
	Author       : Wiktor Czykin
	Created Date : 11/04/2017
	Function     : test error message on missing product for current tcode
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer          Date         Description
	*************************************************************************************/
	@isTest static void testSaveAndTakePaymentNoProductForTCodeError(){
		setPageUrl();

		List<TCode_Product__c> lstTcodeProducts = [SELECT Id FROM TCode_Product__c];
		delete lstTcodeProducts;

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
		ocsc.thisSubscription.Payment_Type__c = Constants.SUB_ACQUISITION_PAYMENT_CC;
		PageReference pr = ocsc.saveAndTakePayment();
		System.assertEquals(null, pr, 'Returned page reference expected to be empty');
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Product_not_available_for_tcode));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testSaveAndTakePaymentWeeklyPriceCheck
	Author       : Wiktor Czykin
	Created Date : 13/12/2016
	Function     : test weekly price validation
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveAndTakePaymentWeeklyPriceCheck() {
		setPageUrl();
		Test.startTest();
			OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
			ocsc.callType = Constants.OC_CALL_STAGE_T2;
			ocsc.onClickGetCustomer();
			ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
			ocsc.thisSubscription.Weekly_Price__c = 0;
			PageReference pr = ocsc.saveAndTakePayment();
			System.assertEquals(1, ApexPages.getMessages().size());
			System.assertEquals(null, pr);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Weekly_Price_Validation));
			ocsc.thisSubscription.Weekly_Price__c = null;
			System.assertEquals(1, ApexPages.getMessages().size());
			System.assertEquals(null, pr);
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Weekly_Price_Validation));
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testEnableEditAccount
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testEnableEditAccount() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(!ocsc.accEditEnabled, 'expected accEditEnabled to be set to false');
		ocsc.enableEditAccount();
		System.assert(ocsc.accEditEnabled, 'expected accEditEnabled to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testCancelAccountEdit
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    			Date      	Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Mantas Grigaliunas    16/08/2016 	//added showEmailIFrame assertion after adding it to controller function
	*************************************************************************************/
	@isTest static void testCancelAccountEdit() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.accEditEnabled = true;
		String nameBeforeChanmge = ocsc.thisAccount.FirstName;
		ocsc.thisAccount.FirstName = 'Changed Name';
		ocsc.cancelAccountEdit();
		System.assert(!ocsc.accEditEnabled, 'expected accEditEnabled to be set to false');
		System.assert(!ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to false');
		System.assertEquals(nameBeforeChanmge, ocsc.thisAccount.FirstName);
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testSaveAccount
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveAccount() {

		setPageUrl();

		final String NAME_CHANGED_TO = 'nameChangedTo';
		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.accEditEnabled = true;
		ocsc.thisAccount.FirstName = NAME_CHANGED_TO;
		ocsc.saveAccount();
		System.assert(ApexPages.getMessages().size() == 0, String.valueOf(ApexPages.getMessages()));
		Account savedAcc = [SELECT Id, FirstName FROM Account WHERE Id = :ocsc.thisAccount.Id LIMIT 1 ];
		System.assertEquals(NAME_CHANGED_TO, savedAcc.FirstName);
		System.assert(!ocsc.accEditEnabled, 'expected accEditEnabled to be set to false');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testDisplayChangeEmailIFrame
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testDisplayChangeEmailIFrame() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assert(!ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to false');
		ocsc.displayChangeEmailIFrame();
		System.assert(ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testHideChangeEmailIFrame
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testHideChangeEmailIFrame() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.showEmailIFrame = true;
		ocsc.hideChangeEmailIFrame();
		System.assert(!ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testRefetchSubscriberEmail
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer           Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Pawel Chrzanowski   06/12/2016   Modified to follow class changes
	*************************************************************************************/
	@isTest static void testRefetchSubscriberEmail() {

		setPageUrl();

		final String NEW_EMAIL = '678954345678@test.com';
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();

		Account a = [SELECT Id FROM Account WHERE Id = :ocsc.thisAccount.Id];
		a.PersonEmail = NEW_EMAIL;
		update a;

		ocsc.refetchSubscriberEmail();
		System.assertEquals(ocsc.thisAccount.PersonEmail, NEW_EMAIL);
		System.assertEquals(ocsc.accBeforeEdit.PersonEmail, NEW_EMAIL);
	}
	
	/************************************************************************************
	Method Name  : testEnableSubEdit
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testEnableSubEdit() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(!ocsc.subEditEnabled, 'expected accEditEnabled to be set to false');
		ocsc.enableSubEdit();
		System.assert(ocsc.subEditEnabled, 'expected accEditEnabled to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testCancelSubEdit
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCancelSubEdit() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.accEditEnabled = true;
		ocsc.cancelSubEdit();
		System.assert(!ocsc.subEditEnabled, 'expected accEditEnabled to be set to false');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testSaveSub
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    			Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Mantas Grigaliunas	30/08/2016	Added extra method saveCustomer call to save subscription after controller was changed
	* Wiktor Czykin			14/12/2016 	Added assertion for duration fix
	*************************************************************************************/
	@isTest static void testSaveSub() {
		setPageUrl();
		Double WEEKLY_PRICE_CHANGED_TO = 299.11;
		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.subEditEnabled = true;
		ocsc.thisSubscription.Weekly_Price__c = WEEKLY_PRICE_CHANGED_TO;
		
		ocsc.selectedSubscriptionDuration = 52+'';
		ocsc.saveSub();
		System.assertEquals(Constants.SUBSCRIPTIONTYPE_52WEEKS, ocsc.subscriptionType);

		ocsc.selectedSubscriptionDuration = 26+'';
		ocsc.saveSub();
		System.assertEquals(Constants.SUBSCRIPTIONTYPE_26WEEKS, ocsc.subscriptionType);

		Id subId = ocsc.thisSubscription.Id;
		ocsc.saveCustomer();
		Subscription__c savedSub = [SELECT Id, Weekly_Price__c FROM Subscription__c WHERE Id = :subId LIMIT 1 ];
		System.assertEquals(WEEKLY_PRICE_CHANGED_TO, savedSub.Weekly_Price__c);
		System.assert(!ocsc.subEditEnabled, 'expected subEditEnabled to be set to false');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testGetSubscriptionDurationsIsContinuous
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetSubscriptionDurationsIsContinuous() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.thisSubscription.isContinuous__c = true;
		System.assertEquals(1, ocsc.getSubscriptionDurations().size(), 'Expected to have only one option');
		System.assertEquals(ocsc.getSubscriptionDurations()[0].getLabel(), Constants.SUB_DURATION_52);
		Test.stopTest();

	}
	
	/************************************************************************************
	Method Name  : testGetSubscriptionDurationsIsNotContinuous
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetSubscriptionDurationsIsNotContinuous() {

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.thisSubscription.isContinuous__c = false;
		System.assertEquals(ocsc.getSubscriptionDurations().size(), 
								Subscription__c.Subscription_Duration_Picklist__c.getDescribe().getPickListValues().size());
		Test.stopTest();

	}
	
	/************************************************************************************
	Method Name  : testUpdateIncentivesNewValidForRenewal
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateIncentivesNewValidForRenewal() {

		setPageUrl();
		List<Incentive__c> incentives = new List<Incentive__c>(
			[ SELECT Id, Is_Valid_For_Renewal__c FROM Incentive__c ]);

		for(Incentive__c incentive : incentives){
			incentive.Is_Valid_For_Renewal__c = true;
		}
		update incentives;

		Integer EXPECTED_INCENTIVE_SIZE = 2; //None and one subscription related incentive 

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assertEquals(EXPECTED_INCENTIVE_SIZE, ocsc.activeIncentives.size());
		Test.stopTest();

	}
	
	/************************************************************************************
	Method Name  : testUpdateIncentivesNewNoTCodeProduct
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* Wiktor Czykin 1.2	        26/10/2016  removed products to test all incentives are fetched (condition in class was changed)
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateIncentivesNewNoTCodeProduct() {

		setPageUrl();

		delete [ SELECT Id FROM TCode_Product__c ];

		List<Incentive__c> incentives = new List<Incentive__c>(
			[ SELECT Id, Is_Valid_For_Renewal__c FROM Incentive__c ]);

		for(Incentive__c incentive : incentives){
			incentive.Is_Valid_For_Renewal__c = true;
			incentive.Valid_From__c = Date.today().addDays(-1);
			incentive.Valid_To__c = Date.today().addDays(1);
		}
		update incentives;

		delete [SELECT Id FROM zqu__ZProduct__c];


		Integer EXPECTED_INCENTIVE_SIZE = RECORDS_SIZE + 1; //including 'None' option

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assertEquals(EXPECTED_INCENTIVE_SIZE, ocsc.activeIncentives.size());
		Test.stopTest();

	}
	
    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 18/07/2016
    Function - test upsertSubscriptionIncentive()
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        06/09/2016  reworked code
    Wiktor Czykin	   1.2	      26/10/2016  removed products to test all incentives are fetched (condition in class was changed)
    ****************************************************************************************/
	@isTest static void testUpsertSubscriptionIncentive(){
        setPageUrl();

        delete [SELECT Id FROM TCode_Product__c];
        delete [SELECT Id FROM SubscriptionIncentiveAssociation__c];

        List<Incentive__c> lstIncentives = [SELECT Is_Valid_For_Renewal__c FROM Incentive__c];
        for(Incentive__c i : lstIncentives){
            i.Is_Valid_For_Renewal__c = true;
            i.Valid_From__c = Date.today().addDays(-1);
            i.Valid_To__c = Date.today().addDays(1);
        }
        update lstIncentives;

        delete [SELECT Id FROM zqu__ZProduct__c];

        Test.startTest();
            OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
            ocsc.callType = Constants.OC_CALL_STAGE_T2;
            ocsc.onClickGetCustomer();

            //create new sia
            ocsc.selectedIncentiveTemp = lstIncentives[0].Id;
            ocsc.upsertSubscriptionIncentive();
            ocsc.getRelatedIncentive();
            ocsc.updateIncentivesNew();

            List<SubscriptionIncentiveAssociation__c> lstSia = [SELECT Incentive__r.Name, Reason__c FROM SubscriptionIncentiveAssociation__c];
            System.assertEquals('Test', ocsc.getIncentiveDescription());
            System.assertEquals(OutboundCallingSalesController.INCENTIVE_PREFIX + ocsc.callType, ocsc.getIncentiveReason());
            System.assertEquals(lstIncentives[0].Id, lstSia[0].Incentive__c);
            System.assertEquals(1, lstSia.size());

            //update current sia
            ocsc.selectedIncentiveTemp = lstIncentives[1].Id;
            ocsc.upsertSubscriptionIncentive();
            ocsc.getRelatedIncentive();
            ocsc.updateIncentivesNew();

            lstSia = [SELECT Incentive__c FROM SubscriptionIncentiveAssociation__c];
            System.assertEquals(lstIncentives[1].Id, lstSia[0].Incentive__c);

            //delete current sia
            ocsc.selectedIncentiveTemp = Constants.OC_NONE;
            ocsc.upsertSubscriptionIncentive();
            ocsc.getRelatedIncentive();

            lstSia = [SELECT Incentive__c FROM SubscriptionIncentiveAssociation__c];
            System.assert(lstSia.isEmpty());
            System.assertEquals(null, ocsc.relatedIncentive);
        Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testGetIncentiveDescription
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetIncentiveDescription() {

		setPageUrl();

		List<Incentive__c> incentives = new List<Incentive__c>(
			[ SELECT Id, Is_Valid_For_Renewal__c FROM Incentive__c ]);

		for(Incentive__c incentive : incentives){
			incentive.Is_Valid_For_Renewal__c = true;
			incentive.Valid_From__c = Date.today().addDays(-1);
			incentive.Valid_To__c = Date.today().addDays(1);
		}
		update incentives;

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();

		ocsc.selectedIncentive = ocsc.activeIncentives[1].getValue();
		List<Incentive__c> incentive = new List<Incentive__c>([SELECT Id, Incentive_Description__c 
															   FROM Incentive__c WHERE Id = :ocsc.selectedIncentive]);
		System.assertEquals(incentive[0].Incentive_Description__c, ocsc.getIncentiveDescription());
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testGetCheque
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCheque(){

		setPageUrl();

		Outbound_Call_Rule__c ocRule = [ SELECT Id, Show_Cheques_Section__c FROM Outbound_Call_Rule__c LIMIT 1 ];
		ocRule.Show_Cheques_Section__c = true;
		update ocRule;

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		System.assert(ocsc.thisCheque != null, 'Cheque expected not to be null');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testClearCheque
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testClearCheque(){

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assert(ocsc.thisCheque == null, 'Cheque expected to be null');
		ocsc.displayedPaymentType = Constants.SUB_PMETHOD_CHEQUE;
		ocsc.clearCheque();
		System.assert(ocsc.thisCheque == new Cheque__c(), 'Cheque expected not to be a new instance');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testGetChequeBatchOptions
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetChequeBatchOptions() {

		setPageUrl();
		final Integer EXPECTED_BATCH_SIZE = RECORDS_SIZE + 1; //including empty value
		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assertEquals(EXPECTED_BATCH_SIZE, ocsc.getChequeBatchOptions().size(), 
													'Expected to have ' + EXPECTED_BATCH_SIZE + 'cheque batches');
		Test.stopTest();

	}
	
	/************************************************************************************
	Method Name  : testValidateChequeFields
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testValidateChequeFields(){

		setPageUrl();

		Outbound_Call_Rule__c ocRule = [ SELECT Id, Show_Cheques_Section__c FROM Outbound_Call_Rule__c LIMIT 1 ];
		ocRule.Show_Cheques_Section__c = true;
		update ocRule;

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.thisCheque.Name_on_Cheque__c = null;
		ocsc.thisCheque.Account_Number__c = null;
		ocsc.thisCheque.Sort_Code__c = null;
		ocsc.thisCheque.Ref_Number_on_Cheque__c = null;
		System.assert(!ocsc.validateChequeFields(), 'Expected method to return false');
		System.assertEquals(4, ApexPages.getMessages().size(), 'Expected to display four error messages');
		Test.stopTest();

	}
	
	/************************************************************************************
	Method Name  : testGetSetAccountPermissions
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetSetAccountPermissions(){

		setPageUrl();
		final Date LAST_UPDATED_DATE = Date.Today();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		
		ocsc.accountPermissions.Permissions_Last_Change_Date__c = LAST_UPDATED_DATE;
		System.assertEquals(LAST_UPDATED_DATE.format(), ocsc.lastUpdateDate);

		System.assert(!ocsc.p2ndemail);
        System.assert(!ocsc.p2ndphone);
        System.assert(!ocsc.p2ndpost);
        System.assert(!ocsc.p2ndSMS);
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testSavePerms
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSavePerms(){

		setPageUrl();
		final Date LAST_UPDATED_DATE = Date.Today();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.accountPermissions.Permissions_Last_Change_Date__c = LAST_UPDATED_DATE.addDays(-1);
		ocsc.savePerms();
		Account savedAcc = [ SELECT Id, Permissions_Last_Change_Date__c FROM Account WHERE Id =:ocsc.thisAccount.Id LIMIT 1 ];
		System.assertEquals(LAST_UPDATED_DATE, savedAcc.Permissions_Last_Change_Date__c);
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testCalculatePaymentStartDateFirstDayOfMonth
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCalculatePaymentStartDateFirstDayOfMonth(){

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assertEquals(Date.newinstance(Date.today().year(), Date.today().month()+1, 1), 
								ocsc.calculatePaymentStartDate(Date.today(), '1', true));
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testCalculatePaymentStartDateFifteenthDayOfMonth
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCalculatePaymentStartDateFifteenthDayOfMonth(){

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assertEquals(Date.newinstance(Date.today().year(), Date.today().month(), 15), 
							ocsc.calculatePaymentStartDate(Date.newinstance(Date.today().year(), Date.today().month(), 14), '15', true));
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testCalculatePaymentStartDateFifteenthOfNextMonth
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCalculatePaymentStartDateFifteenthOfNextMonth(){

		setPageUrl();

		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assertEquals(Date.newinstance(Date.today().year(), Date.today().month()+1, 15), 
							ocsc.calculatePaymentStartDate(Date.newinstance(Date.today().year(), Date.today().month(), 16), '15', true));
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testGetSubscriberAddress
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetSubscriberAddress(){

		setPageUrl();
		List<Country_Codes__c> countries = new List<Country_Codes__c>([SELECT Name, Country_Name__c FROM Country_Codes__c]);
		final String STREET = '1 Test Street';
		final String CITY = 'Test City';
		final String STATE = 'Test State';
		final String POSTCODE = 'TT1 1XX';
		final String COMMA = ', ';
		final String SPACE = ' ';


		Test.startTest();
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		ocsc.callType = Constants.OC_CALL_STAGE_T2;
		ocsc.onClickGetCustomer();
		ocsc.thisAccount.PersonMailingStreet = STREET;
		ocsc.thisAccount.PersonMailingCity = CITY;
		ocsc.thisAccount.PersonMailingState = STATE;
		ocsc.thisAccount.PersonMailingPostalCode = POSTCODE;
		System.assertEquals(STREET + COMMA + CITY + COMMA + STATE + SPACE + POSTCODE, ocsc.getSubscriberAddress());

		ocsc.thisAccount.PersonMailingStreet = null;
		ocsc.thisAccount.PersonMailingCity = CITY;
		ocsc.thisAccount.PersonMailingState = STATE;
		ocsc.thisAccount.PersonMailingPostalCode = POSTCODE;
		System.assertEquals(CITY + COMMA + STATE + SPACE + POSTCODE, ocsc.getSubscriberAddress());

		ocsc.thisAccount.PersonMailingStreet = null;
		ocsc.thisAccount.PersonMailingCity = CITY;
		ocsc.thisAccount.PersonMailingState = null;
		ocsc.thisAccount.PersonMailingPostalCode = POSTCODE;
		System.assertEquals(CITY + SPACE + POSTCODE, ocsc.getSubscriberAddress());

		ocsc.thisAccount.PersonMailingStreet = null;
		ocsc.thisAccount.PersonMailingCity = null;
		ocsc.thisAccount.PersonMailingState = STATE;
		ocsc.thisAccount.PersonMailingPostalCode = POSTCODE;
		System.assertEquals(STATE + SPACE + POSTCODE, ocsc.getSubscriberAddress());

		ocsc.thisAccount.PersonMailingStreet = STREET;
		ocsc.thisAccount.PersonMailingCity = null;
		ocsc.thisAccount.PersonMailingState = null;
		ocsc.thisAccount.PersonMailingPostalCode = POSTCODE;
		System.assertEquals(STREET + SPACE + POSTCODE, ocsc.getSubscriberAddress());

		ocsc.thisAccount.PersonMailingStreet = null;
		ocsc.thisAccount.PersonMailingCity = null;
		ocsc.thisAccount.PersonMailingState = null;
		ocsc.thisAccount.PersonMailingPostalCode = POSTCODE;
		System.assertEquals(POSTCODE, ocsc.getSubscriberAddress());

		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : setPageUrl
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : sets curent page url to the expected visualforce page
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@TestVisible
	private static void setPageUrl(){
		PageReference pr = Page.OutboundCallingSales;
		Test.setCurrentPage(pr);
		System.assertEquals(pr.getUrl(), ApexPages.currentPage().getUrl());
	}

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        12/09/2016
    Function    test for parseCaseCounter
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	@isTest static void parseCaseCounterTest(){
		PageReference pr = Page.OutboundCallingSales;
		Test.setCurrentPage(pr);
		OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
		System.assertEquals(null, ocsc.parseCaseCounter(-5));
		System.assertEquals(' (no Cases)', ocsc.parseCaseCounter(0));
		System.assertEquals(' (1 Case)', ocsc.parseCaseCounter(1));
		System.assertEquals(' (100 Cases)', ocsc.parseCaseCounter(100));
		System.assertEquals(' (100+ Cases)', ocsc.parseCaseCounter(101));
	}
	
    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        27/09/2016
    Function    test for caseOutcomeChange
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @isTest static void caseOutcomeChangeTest(){
        PageReference pr = Page.OutboundCallingSales;
        Test.setCurrentPage(pr);
        OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
        ocsc.callType = Constants.OC_CALL_STAGE_T2;
        ocsc.onClickGetCustomer();

        ocsc.caseOutcomeChange();
        System.assert(!ocsc.editScheduleCallback);

        ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE;
        ocsc.caseOutcomeChange();
        System.assert(ocsc.editScheduleCallback);
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        27/09/2016
    Function    test for caseScheduledCallbackChange
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin		1.1			14/12/2016	//disable test run for validation lock dates
    Vishant Shah		1.2 		20/12/2016	//removed hardcoding of Timestamp. Jira: SUB-6083
    ****************************************************************************************/
    @isTest static void caseScheduledCallbackChangeTest(){
        PageReference pr = Page.OutboundCallingSales;
        Test.setCurrentPage(pr);
        OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
        ocsc.callType = Constants.OC_CALL_STAGE_T2;
        ocsc.onClickGetCustomer();

        ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE;
        Datetime dt = System.now().addHours(-1);
        String sDay = dt.format('EEEE');
        if(sDay == 'Sunday' || (sDay == 'Saturday' && Datetime.now().hour() >= 14)){
			return; //do not test - temporar fix
		}
        ocsc.thisCase.OC_Scheduled_Callback__c = dt;
        ocsc.caseScheduledCallbackChange();
        System.assert(ocsc.caseDetailsMsg, ApexPages.getMessages());

        ocsc.thisCase.OC_Scheduled_Callback__c = System.now().addDays(30);
        ocsc.caseScheduledCallbackChange();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        18/10/2016
    Function    test for loading Case from url
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @isTest static void loadCaseFromURLTest_positive(){
    	Id caseId = [SELECT Id FROM Case][0].Id;
        PageReference pr = Page.OutboundCallingSales;
        pr.getParameters().put('id', caseId);
        Test.setCurrentPage(pr);
        OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
        System.assertEquals(ocsc.thisCase.Id, caseId);
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        18/10/2016
    Function    test for loading Case from url
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @isTest static void loadCaseFromURLTest_negative(){
        PageReference pr = Page.OutboundCallingSales;
        pr.getParameters().put('id', '00001234');
        Test.setCurrentPage(pr);
        OutboundCallingSalesController ocsc = new OutboundCallingSalesController();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Case_Not_Found));
    }

}