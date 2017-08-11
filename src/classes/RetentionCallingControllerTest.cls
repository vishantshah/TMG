/************************************************************************************
Class Name   : RetentionCallingControllerTest
Author       : Konrad Czykin
Created Date : 11/05/2017
Function     : RetentionCallingController class unit tests
*************************************************************************************/
@isTest
private class RetentionCallingControllerTest {

	private static final Integer RECORDS_SIZE = 2;


	/************************************************************************************
	Method Name  : testSetup
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : create records for tests
	*************************************************************************************/
	@testSetup static void testSetup(){

		final String DEFAULT_CASE_STATUS = 'Not Started';

		TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);

		/* CREATE OUTBOUND CALL SETTING AND RULES */

		tdu.iCounter = 1;
		tdu.createRetentionOutboundCallSetting();
		tdu.createRetentionOutboundCallRule();

		/* CUSTOM SETTINGS */
		tdu.loadCountryCodes();		
		TestDataUtility.createOCCaseAutocloseCustomSettingInstance();

		tdu.iCounter = RECORDS_SIZE;

		/* CREATE ACCOUNTS, SUBSCRIPTION AND CASES */
		tdu.createIndividualSubscribers();
		tdu.createSubscriptions();
		tdu.iCounter = RECORDS_SIZE - 1;  
		tdu.createRetCases(Constants.OC_RETENTION_RECORD_TYPE_NAME);

	}

	/************************************************************************************
	Method Name  : testOnClickGetCustomerCaseExist
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test ifcase exist onclick getcustomer 
	*************************************************************************************/
	@isTest static void testOnClickGetCustomerCaseExist() {
		
		setPageUrl();

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.onClickGetCustomer();

		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');
		Test.stopTest();
	}
	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSettingParameter
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test get Outbound Calling Settings - no parameters
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSettingParameter() {

		setPageUrl();
		
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c LIMIT 1];
		ocSetting.Parameters__c = null;
		update ocSetting;
 
		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
		String.format(Label.Outbound_Calling_Missing_Setting_Parameters, new List<String>{ocSetting.Name})));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSetting
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test get Outbound Call Setting - no settings
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSetting() {

		setPageUrl();
		
		delete [SELECT Id FROM Outbound_Call_Setting__c];

		Test.startTest();
		RetentionCallingController ocrc = new RetentionCallingController();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
		String.format(Label.Outbound_Calling_Missing_Setting_Record, new List<String>{Constants.OC_RETENTION_RECORD_TYPE_NAME})));
        
        //Boolean cnb = ocrc.createNewBatch;
        CaseComment cc = ocrc.newComment;
        ocrc.currentSubscriptionMsg = true;
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeChangedToBusy
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test save customer outcome change to busy
	*************************************************************************************/	
	@isTest static void testSaveCustomerOutcomeChangedToBusy() {
		
		setPageUrl();

		Case newCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case LIMIT 1];
		System.assertNotEquals(newCase.Retention_Call_Date_Time__c, inProgressCase.Retention_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_BUSY;
		ocsc.onClickSaveAndGetNextCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, Retention_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(inProgressCase.Retention_Call_Date_Time__c, savedCase.Retention_Call_Date_Time__c);
		System.assertEquals(savedCase.OC_Scheduled_Callback__c, savedCase.Retention_Call_Date_Time__c);
	}

	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeChangedToNoAnswer
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test save customer outcome change to no answer
	*************************************************************************************/
	@isTest static void testSaveCustomerOutcomeChangedToNoAnswer() {
		
		setPageUrl();

		Case newCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(newCase.Retention_Call_Date_Time__c, inProgressCase.Retention_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_NOANSWER;
		ocsc.saveCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, Retention_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(inProgressCase.Retention_Call_Date_Time__c, savedCase.Retention_Call_Date_Time__c);
		System.assertEquals(savedCase.OC_Scheduled_Callback__c, savedCase.Retention_Call_Date_Time__c);
	}
	
	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeChangedToAnswerPhone
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test save customer outcome change to answer phone
	*************************************************************************************/
	@isTest static void testSaveCustomerOutcomeChangedToAnswerPhone() {
		
		setPageUrl();

		Case newCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case WHERE Id = :newCase.Id LIMIT 1];

		System.assertNotEquals(newCase.Retention_Call_Date_Time__c, inProgressCase.Retention_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_ANSWERPHONE;
		ocsc.saveCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, Retention_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertNotEquals(inProgressCase.Retention_Call_Date_Time__c, savedCase.Retention_Call_Date_Time__c);
		System.assertEquals(savedCase.OC_Scheduled_Callback__c, savedCase.Retention_Call_Date_Time__c);
	}

		@isTest static void testSaveCustomerOutcomeChangedToDeceased() {
		
		setPageUrl();

		Case newCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, Retention_Call_Date_Time__c, AccountId FROM Case LIMIT 1];
		System.assertNotEquals(newCase.Retention_Call_Date_Time__c, inProgressCase.Retention_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_DECEASED;
		ocsc.onClickSaveAndGetNextCustomer();
		Test.stopTest();

		Account acc = [SELECT Id, Deceased__pc FROM Account Where Id = :inProgressCase.AccountId];
		System.assert(acc.Deceased__pc);

	}
	
	/************************************************************************************
	Method Name  : testSaveCustomerOutcomeNotChanged
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test save customer outcome not changed
	*************************************************************************************/
	@isTest static void testSaveCustomerOutcomeNotChanged() {
		
		setPageUrl();

		Case newCase = [SELECT Id, Retention_Call_Date_Time__c FROM Case LIMIT 1];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		Case inProgressCase = [SELECT Id, Status, Retention_Call_Date_Time__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(Constants.CASE_STATUS_INPROGRESS, inProgressCase.Status);
		System.assertNotEquals(newCase.Retention_Call_Date_Time__c, inProgressCase.Retention_Call_Date_Time__c);

		ocsc.thisCase.OC_Outcome__c = Constants.OC_DEFAULT_OUTCOME;
		ocsc.saveCustomer();
		Test.stopTest();
		Case savedCase = [SELECT Id, Retention_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assert(savedCase.OC_Scheduled_Callback__c == null, 'OC_Scheduled_Callback__c expected to be null');
		System.assertEquals(inProgressCase.Retention_Call_Date_Time__c, savedCase.Retention_Call_Date_Time__c);
	}
	
	/************************************************************************************
	Method Name  : testSaveCustomerAlreadySaved
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test save customer already saved
	*************************************************************************************/
	@isTest static void testSaveCustomerAlreadySaved() {
		
		setPageUrl();

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(ApexPages.getMessages().size() == 0, 'Unexpected error message');
		System.assert(ocsc.caseList.size() == 1, 'Expected to return one case record');

		//Modify same case by another user
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createUsers(null); //System Administrator profile user

		Case testCase = [SELECT Id, OC_Outcome__c FROM Case LIMIT 1];
		System.assertEquals(ocsc.thisCase.Id, testCase.Id);

		System.runAs(tdu.lstUsers[0]){
			testCase.OC_Outcome__c = Constants.CASE_OUTCOME_BUSY;
			update testCase;
		}

		ocsc.saveCustomer();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.Outbound_Call_Case_Already_Saved, new List<String>{tdu.lstUsers[0].FirstName + ' ' + tdu.lstUsers[0].LastName})),
		ApexPages.getMessages());
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : setPageUrl
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test setPageUrl
	*************************************************************************************/
	@TestVisible
	private static void setPageUrl(){
		PageReference pr = Page.RetentionCalling;
		Test.setCurrentPage(pr);
		System.assertEquals(pr.getUrl(), ApexPages.currentPage().getUrl());
	}

    /*************************************************************************************** 
    Method Name  : aseOutcomeChangeTest
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test Outcome change
    ****************************************************************************************/
    @isTest static void caseOutcomeChangeTest(){
        PageReference pr = Page.RetentionCalling;
        Test.setCurrentPage(pr);
        RetentionCallingController ocsc = new RetentionCallingController();
        ocsc.callType = Constants.OC_RETENTION_STAGE;

        ocsc.onClickGetCustomer();

        ocsc.caseOutcomeChange();

        System.assert(!ocsc.editScheduleCallback);

        ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE;
        ocsc.caseOutcomeChange();
        System.assert(ocsc.editScheduleCallback);
    }

    /*************************************************************************************** 
    Method Name  : caseScheduledCallbackChangeTest
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test for case scheduled call back 
    ****************************************************************************************/
    @isTest static void caseScheduledCallbackChangeTest(){
        PageReference pr = Page.RetentionCalling;
        Test.setCurrentPage(pr);
        RetentionCallingController ocsc = new RetentionCallingController();
        ocsc.callType = Constants.OC_RETENTION_STAGE;
        ocsc.onClickGetCustomer();

        ocsc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE;
        Datetime dt = System.now().addHours(-1);
 
        ocsc.thisCase.OC_Scheduled_Callback__c = dt;
        ocsc.caseScheduledCallbackChange();
        System.assert(ocsc.caseDetailsMsg, ApexPages.getMessages());

        ocsc.thisCase.OC_Scheduled_Callback__c = System.now().addDays(30);
        ocsc.caseScheduledCallbackChange();
        System.assert(ocsc.isScheduledCallbackValid());
    }

	/************************************************************************************
	Method Name  : testOnClickGetCustomerNoCasesFound
	Author       : Konrad Czykin
	Created Date : 13/05/2017
	Function     : test click get customer - no cases found
	*************************************************************************************/
	@isTest static void testOnClickGetCustomerNoCasesFound() {
		
		setPageUrl();
		delete [SELECT Id FROM Case];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.callType = Constants.OC_RETENTION_STAGE;
		ocsc.onClickGetCustomer();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.No_Cases_Found, new List<String>{ocsc.callType}))
		);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSettingRule
	Author       : Konrad Czykin
	Created Date : 13/05/2017
	Function     : test get Outbound Call Settings - no rules
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSettingRule() {

		setPageUrl();
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1];
		Outbound_Call_Rule__c ocRule = [SELECT Id FROM Outbound_Call_Rule__c LIMIT 1];
		ocRule.Active__c = false;
		update ocRule;
		delete ocRule;

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.Outbound_Calling_Missing_Setting_Rule, new List<String>{ocSetting.Name}))
		);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSettingRule
	Author       : Konrad Czykin
	Created Date : 13/05/2017
	Function     : test get customer - no subscription
	*************************************************************************************/
	@isTest static void testNoSubscription(){

		setPageUrl();
		delete [SELECT Id FROM Subscription__c];

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.onClickGetCustomer();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			String.format(Label.No_Cases_Found, new List<String>{'Retention'}))
		);

		ocsc.getSubscription();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			Label.Outbound_Calling_Subscription_Not_Found));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testrtId is Outbound Calling (Retention)
	Author       : Konrad Czykin
	Created Date : 13/05/2017
	Function     : test for correct Record type 
	*************************************************************************************/
	@isTest static void testrtId(){

		setPageUrl();

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		String recName = [SELECT Name FROM recordtype WHERE id = :ocsc.rtId][0].Name;
		System.assertEquals('Outbound Calling (Retention)', recName);
		System.assertnotEquals(null, ocsc.rtId);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : test querie limit
	Author       : Konrad Czykin
	Created Date : 13/05/2017
	Function     : test for query limit
	*************************************************************************************/
	@isTest static void testQueryLimit(){

		setPageUrl();

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		for(Integer j=0; j<Limits.getLimitQueries()-11; j++){
			Case cc = [SELECT Id FROM Case limit 1];
		}
		ocsc.onClickGetCustomer();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			Label.Outbound_Call_System_Busy));

		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : test Priority = null
	Author       : Konrad Czykin
	Created Date : 13/05/2017
	Function     : test for Priority = null 
	*************************************************************************************/
	@isTest static void testPriority(){

		setPageUrl();
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1];
		Outbound_Call_Rule__c ocRule = [SELECT Id, Priority_Field__c FROM Outbound_Call_Rule__c LIMIT 1];
		ocRule.Priority_Field__c = null;
		update ocRule;

		Test.startTest();
		RetentionCallingController ocsc = new RetentionCallingController();
		ocsc.onClickGetCustomer();
		Test.stopTest();
	}
}