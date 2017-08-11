/************************************************************************************
Class Name   : OutboundCallingDDWinbackControllerTest
Author       : Vishant Shah
Created Date : 16/05/2017
Function     : OutboundCallingDDWinbackControllerTest class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    			Date      	Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/

@isTest
private class OutboundCallingDDWinbackControllerTest {
	
	private static final Integer RECORDS_SIZE  = 2;
	private static final String NO             = 'No';
	private static final String YES            = 'Yes';
	private static final String PRIORITY_FIELD = 'DD_Winback_Priority__c';
	private static final String DD_WINBACK     = 'DD Winback';

	/************************************************************************************
	Method Name  : testSetup
	Description  : testSetup method
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@testSetup static void testSetup(){

		final String DEFAULT_CASE_STATUS = 'Not Started';
		final String ocParameters = '{ "callStageParameters" : [ { "stagename" : "DD Winback", "outcome" : "DD_Winback_Outcome__c", "calldatetime" : "DD_Winback_Call_Date_Time__c", "offset" : 0 , "tcode" : ""} ]}';

		TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);
		tdu.iCounter        = 1;

		tdu.createOCSetting(Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Constants.OC_DD_WINBACK_VF_PAGE_NAME, ocParameters);
		tdu.createOutboundCallRule();
		tdu.lstOutboundCallRule[0].Priority_Field__c = PRIORITY_FIELD;
		update tdu.lstOutboundCallRule[0];
 
		tdu.loadCountryCodes();
		TestDataUtility.createOCCaseAutocloseCustomSettingInstance();

		/* CREATE TCODEMANAGEMENT AND TCODE PRODUCTS*/ 
		tdu.iCounter = RECORDS_SIZE;
		tdu.createTCodeManagement();
		tdu.createZProduct();
		tdu.createTCodeProducts();
		tdu.createCheques();
		tdu.createSubscriptionIncentiveAssociation();
		tdu.createTCodeProductIncentives();

		Profile p   = [SELECT Id FROM Profile WHERE Name = :Constants.PROFILE_TMG_STANDARD_USER];
		User u      = TestDataUtility.newUser(1, p.Id);
		u.FirstName = 'TestUserOC';
		insert u;

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

		String recTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Case.class.getName());
		DateTime dt      = null;

		Case newCase                  = TestDataUtility.newOCCase(recTypeId, DD_WINBACK, dt);
		newCase.OC_Outcome__c         = Constants.OC_DEFAULT_OUTCOME;
		newCase.Status                = Constants.OC_DEFAULT_OUTCOME;
		newCase.Print_Subscription__c = tdu.lstSubscriptions[0].Id;
		insert newCase;
	}

	/************************************************************************************
	Method Name  : ouboundCallSettingDoesNotExist
	Description  : test if OC Settings do not exist
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void ouboundCallSettingDoesNotExist() {

		setPageUrl();

		delete [SELECT Id FROM Outbound_Call_Setting__c];

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			String message = String.format(Label.Outbound_Calling_Missing_Setting_Record, new List<String>{Constants.OC_DD_WINBACK_VF_PAGE_NAME.toLowerCase()});
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message), ApexPages.getMessages());

		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : outboundCallSettingsNoSettingParameter
	Description  : test if OC Settings Paremeters are empty.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void outboundCallSettingsNoSettingParameter() {

		setPageUrl();
		
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c LIMIT 1];
		ocSetting.Parameters__c = null;
		update ocSetting;
 
		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			String message = String.format(Label.Outbound_Calling_Missing_Setting_Parameters, new List<String>{ocSetting.Name});
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message));
			
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsNoSettingRule
	Description  : test if OC Rules are missing.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsNoSettingRule() {

		setPageUrl();

		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1];
		Outbound_Call_Rule__c ocRule       = [SELECT Id FROM Outbound_Call_Rule__c LIMIT 1];
		ocRule.Active__c                   = false;
		update ocRule;
		delete ocRule;

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			String message = String.format(Label.Outbound_Calling_Missing_Setting_Rule, new List<String>{ocSetting.Name});
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message));
			
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingsIncorrectParameter
	Description  : test if incorrect parameter set in OC Settings.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingsIncorrectParameter() {

		setPageUrl();

		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1]; 
		ocSetting.Parameters__c            = 'Incorrect string';
		update ocSetting;

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Unable to extract parameters'));

		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCustomerAndReschedule
	Description  : test reschedule process. also set past and future callback dates.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCustomerAndReschedule() {

		setPageUrl();
		String noMoreCases          = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK});
		DateTime rescheduleCallback = Datetime.now().addHours(1);

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, 'Price Increase');

		List<Case> listCase = [SELECT Id, OC_Scheduled_Callback__c, DD_Winback_Priority__c, Status, OC_Outcome__c FROM Case];

		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'There should be a DD Winback case');

			ocDDc.thisCase.Debt_Collected__c     = NO;
			ocDDc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE;

			ocDDc.caseOutcomeChange();
			System.assertEquals(true, ocDDc.editScheduleCallback, 'Schedule Callback should be editable');
			
			ocDDc.thisCase.OC_Scheduled_Callback__c = Datetime.now().addHours(-2);
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Case_Scheduled_Callback_In_Past));


			ocDDc.thisCase.OC_Scheduled_Callback__c = Datetime.now().addDays(10);
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Case_Scheduled_Callback));

			ocDDc.thisCase.OC_Scheduled_Callback__c = rescheduleCallback;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), noMoreCases), 'There should be no more DD Winback cases.');

		Test.stopTest();

		Case c = [SELECT Id, OC_Outcome__c, Status, OC_Scheduled_Callback__c, Outcome_Changed_On__c FROM Case LIMIT 1];
		System.assertEquals(Constants.CASE_OUTCOME_RESCHEDULE, c.OC_Outcome__c, 'Outcome should be Reschedule');
		System.assertEquals(Constants.CASE_STATUS_INPROGRESS, c.Status, 'Status should be in progress');
		System.assertEquals(rescheduleCallback, c.OC_Scheduled_Callback__c, 'Callback datetime incorrect');
		System.assertEquals(Date.valueof(DateTime.now()), Date.valueof(c.Outcome_Changed_On__c), 'Outcome changed on datetime incorrect');
	}

	/************************************************************************************
	Method Name  : testGetCustomerAndNATC
	Description  : test if NATC was set and the Other NATC reason is set.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCustomerAndNATC() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK});

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, 'Price Increase');

		List<Case> listCase = [SELECT Id, OC_Scheduled_Callback__c, DD_Winback_Priority__c, Status, OC_Outcome__c FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');
			
			ocDDc.thisCase.Debt_Collected__c = NULL;
			ocDDc.thisCase.OC_Outcome__c = Constants.OC_DD_OUTCOME_NATC;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Please enter NATC Reason, If NATC Reason is \'Other\' enter Other NATC Reason'), 'NATC Reason should be selected');
			
			ocDDc.thisCase.NATC_Reason__c = Constants.OC_DD_OTHER_NATC;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Please enter NATC Reason, If NATC Reason is \'Other\' enter Other NATC Reason'), 'OTHER NATC Reason is required');

			ocDDC.thisCase.Other_NATC_Reason__c = Constants.OC_DD_OTHER_NATC;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), noMoreCases), 'There should be no more cases.');
			
		Test.stopTest();

		Case c = [SELECT Id, OC_Outcome__c, Status, OC_Scheduled_Callback__c, Outcome_Changed_On__c, NATC_Reason__c, Other_NATC_Reason__c FROM Case LIMIT 1];
		System.assertEquals(Constants.OC_DD_OUTCOME_NATC, c.OC_Outcome__c, 'Outcome should be NATC');
		System.assertEquals(Constants.OC_DD_OTHER_NATC, c.NATC_Reason__c, 'NATC_Reason__c should be selected');
		System.assertEquals(Constants.OC_DD_OTHER_NATC, c.Other_NATC_Reason__c, 'Other_NATC_Reason__c should be selected');
		System.assertEquals(Date.valueof(DateTime.now()), Date.valueof(c.Outcome_Changed_On__c), 'NATC Outcome changed on datetime incorrect');
	}

	/************************************************************************************
	Method Name  : testGetCustomerAndDebtCollected
	Description  : test if Debt collection picklist and value was set.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCustomerAndDebtCollected() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK}); 

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, 'Price Increase');

		List<Case> listCase = [SELECT Id, OC_Scheduled_Callback__c, DD_Winback_Priority__c, Status, OC_Outcome__c FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');

			ocDDc.thisCase.Debt_Collected__c = null;
			ocDDc.thisCase.OC_Outcome__c = Constants.TOUTCOME_NOSALE;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Please select if Debt Collected')); 
			
			ocDDc.thisCase.Debt_Collected__c = NO;
			ocDDc.thisCase.OC_Outcome__c = null;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.debug(ApexPages.getMessages());
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Outcome_Warning), Label.OC_Outcome_Warning);

			ocDDc.thisCase.OC_Outcome__c = Constants.TOUTCOME_NOSALE;
			ocDDc.thisCase.OC_No_Sale_Reason__c = Constants.OC_NO_SALE_REASON_ILLNESS;
			ocDDc.thisCase.Debt_Collected__c = YES;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Please enter a Debt Collected Amount'));

			ocDDc.thisCase.Debt_Collected_Amount__c = 1234.56;
			ocDDc.onClickSaveAndGetNextCustomer();
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), noMoreCases), 'There should be no more cases.');

		Test.stopTest();

		Case c = [SELECT Id, DD_Winback_Outcome__c, Status, DD_Winback_Scheduled_Callback__c, Outcome_Changed_On__c, Debt_Collected__c, Debt_Collected_Amount__c FROM Case LIMIT 1];
		System.assertEquals(Constants.TOUTCOME_NOSALE, c.DD_Winback_Outcome__c, 'Outcome should be No Answer');
		System.assertEquals(YES, c.Debt_Collected__c, 'Debt collected should be Yes');
		System.assertEquals(1234.56, c.Debt_Collected_Amount__c, 'Debt_Collected_Amount__c should be 1234.56');
		System.assertEquals(Date.valueof(DateTime.now()), Date.valueof(c.Outcome_Changed_On__c), 'Outcome changed on datetime incorrect');
	}

	/************************************************************************************
	Method Name  : testSimulateSaveByOtherUser
	Description  : Simulate the action of another user editing case when open in 
				   dialer for another user
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSimulateSaveByOtherUser() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK});

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, 'Price Increase');

		List<Case> listCase = [SELECT Id, OC_Scheduled_Callback__c, DD_Winback_Priority__c, Status, OC_Outcome__c FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');

			ocDDc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_NOANSWER;
			ocDDc.thisCase.Debt_Collected__c = YES;
			ocDDc.thisCase.Debt_Collected_Amount__c = 1234.56;

			User u = [SELECT Id, Name FROM User WHERE FirstName = 'TestUserOC'];
			System.runAs(u){
				Case c = [SELECT Id FROM Case WHERE Id = :ocDDc.thisCase.Id];
				c.Subject = 'Override Case';
				update c;
			}

			ocDDc.onClickSaveAndGetNextCustomer();
			String error = String.format(Label.Outbound_Call_Case_Already_Saved, new List<String>{u.Name});
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), error), error);
		Test.stopTest();

		Case c = [SELECT Id, OC_Outcome__c, Outcome_Changed_On__c FROM Case LIMIT 1];
		System.assertEquals('Not Started', c.OC_Outcome__c, 'Outcome should be Not Started');
		System.assertEquals(null,c.Outcome_Changed_On__c, 'Outcome changed on should be null');
	}

	/************************************************************************************
	Method Name  : testOutcomeBusy
	Description  : test method for Busy outcome.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOutcomeBusy() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK}); 

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, Constants.OC_NO_SALE_REASON_ILLNESS);

		List<Case> listCase = [SELECT Id FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');

			ocDDc.thisCase.DD_Winback_Outcome__c = Constants.CASE_OUTCOME_BUSY;
			ocDDc.thisCase.Debt_Collected__c = NO;
			ocDDc.onClickSaveAndGetNextCustomer(); 

		Test.stopTest();

		Case c = [SELECT Id, DD_Winback_Outcome__c, Status FROM Case LIMIT 1];
		System.assertEquals(Constants.CASE_OUTCOME_BUSY, c.DD_Winback_Outcome__c, 'Outcome should be Busy'); 
		System.assertEquals(Constants.CASE_STATUS_INPROGRESS, c.Status, 'Status should be in progress'); 
	}

	/************************************************************************************
	Method Name  : testOutcomeAnswerPhone
	Description  : test method for Answerphone outcome.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOutcomeAnswerPhone() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK}); 

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, Constants.OC_NO_SALE_REASON_ILLNESS);

		List<Case> listCase = [SELECT Id FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');

			ocDDc.thisCase.DD_Winback_Outcome__c = Constants.CASE_OUTCOME_ANSWERPHONE;
			ocDDc.thisCase.Debt_Collected__c = NO;
			ocDDc.onClickSaveAndGetNextCustomer(); 

		Test.stopTest();

		Case c = [SELECT Id, DD_Winback_Outcome__c, Status FROM Case LIMIT 1];
		System.assertEquals(Constants.CASE_OUTCOME_ANSWERPHONE, c.DD_Winback_Outcome__c, 'Outcome should be ' + Constants.CASE_OUTCOME_ANSWERPHONE); 
		System.assertEquals(Constants.CASE_STATUS_INPROGRESS, c.Status, 'Status should be in progress'); 
	}

	/************************************************************************************
	Method Name  : testOutcomeDeceased
	Description  : test method for Deceased outcome.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOutcomeDeceased() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK});

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, 'Price Increase');

		List<Case> listCase = [SELECT Id FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');

			ocDDc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_DECEASED;
			ocDDc.thisCase.Debt_Collected__c = NO;
			ocDDc.onClickSaveAndGetNextCustomer(); 

		Test.stopTest();

		Case c = [SELECT Id, DD_Winback_Outcome__c, Status, Contact.Deceased__c FROM Case LIMIT 1];
		System.assertEquals(Constants.CASE_OUTCOME_DECEASED, c.DD_Winback_Outcome__c, 'Outcome should be ' + Constants.CASE_OUTCOME_DECEASED); 
		System.assertEquals('Completed', c.Status, 'Status should be in progress');
		System.assertEquals(true, c.Contact.Deceased__c, 'Contact Deceased__c should be true'); 
	}


	/************************************************************************************
	Method Name  : testOutcomeSale
	Description  : test method for Sale outcome.
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOutcomeSaleNoNewSub() {

		setPageUrl();
		String noMoreCases = String.format(Label.No_Cases_Found, new List<String>{DD_WINBACK}); 

		List<Subscription__c> subs  = [SELECT Id, Start_Date__c FROM Subscription__c WHERE Subscription_Status__c = :Constants.SSTATUS_OFFERED];
		setSubscriptionStatusCancelled(subs, Constants.SSTATUS_PENDING_CANX, 'Price Increase');

		List<Case> listCase = [SELECT Id FROM Case];
		listCase[0].Print_Subscription__c = subs[0].Id; 
		update listCase; 

		Test.startTest();

			OutboundCallingDDWinbackController ocDDc = new OutboundCallingDDWinbackController();
			ocDDc.onClickGetCustomer();
			System.assertEquals(false, ocDDc.thisCase == null, 'Case should not be empty');

			ocDDc.thisCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
			ocDDc.thisCase.Debt_Collected__c = NO;
			ocDDC.tempCase.Print_Subscription__c = null;
			ocDDC.tempCase.Subscription__c = null;

			ocDDc.onClickSaveAndGetNextCustomer(); 
			System.assertEquals(true, TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outcome_is_Sale_New_SUB_Required), Label.Outcome_is_Sale_New_SUB_Required);

		Test.stopTest();

		Case c = [SELECT Id, DD_Winback_Outcome__c, Status FROM Case LIMIT 1]; 
		System.assertEquals(Constants.CASE_STATUS_INPROGRESS, c.Status, 'Status should be in progress'); 

	}



	/************************************************************************************
	Method Name  : setPageUrl
	Description  : Set current page url
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@TestVisible
	private static void setPageUrl(){
		PageReference pr = Page.OutboundCallingDDWinback;
		Test.setCurrentPage(pr);
		System.assertEquals(pr.getUrl(), ApexPages.currentPage().getUrl());
	}

	/************************************************************************************
	Method Name  : setSubscriptionStatusCancelled
	Description  : Set the status and reason of List of subscriptions to a Status passed
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static void setSubscriptionStatusCancelled(List<Subscription__c> subs, String status, String canxReason){
		for (Subscription__c sub : subs){
			sub.Subscription_Status__c = status;
            sub.Cancellation_Date__c = sub.Start_Date__c.addDays(5);
            sub.Cancellation_Reason__c = canxReason;
            sub.Cancellation_Method__c = 'Phone';
		}

		update subs;
	}
	
}