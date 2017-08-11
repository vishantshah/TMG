/**
* Author:       Michal Kwika (Accenture)
* Date:         22/01/2016
* Description:  TriggerHandler test class for Case Object
*
* ******************* Change Log *******************
* Modified by       	Change Date
* Mantas Grigaliunas	19/07/2016	//new test method added testUpdateOutboundCallingSalesStageHistoryNoParametersException
* Mantas Grigaliunas	19/08/2016	//replaced string T2 28Days with constant OC_CALL_STAGE_T2
* Mantas Grigaliunas	30/08/2016	//added new test method after No Sale Reason field update functionality was implemented
* Mantas Grigaliunas	01/09/2016	//added new test methods for updateAccountContact method
* Michal Szewczyk		11/10/2016  //added new test method testUpdateAccountContactPersonAccountDecease()
* Mantas Grigaliunas 	19/10/2016	//modified testUpdateOutboundCallingSalesStageHistoryOutcomeNoSaleWithReason()
* Michal Szewczyk		08/11/2016  //added new test method updateProductFieldOnCase()
* Wiktor Czykin			05/12/2016  //modified updateProductFieldOnCase()
* Pawel Chrzanowski     06/12/2016  //added testVerifyOnlyOneOCSCase()
* Wiktor Czykin			07/12/2016  //modified testUpdateOutboundCallingSalesStageHistoryNoParametersException() 
									and testUpdateOutboundCallingSalesStageHistoryOutcomeNoSaleWithReason()
									added testOCCaseInsertPopulationOfRespectiveStageDateTimeFieldNegative()
* Pawel Chrzanowski     14/12/2016  added testUpdateSubscription()
* Wiktor Czykin			21/12/2016	modified updateProductFieldOnCase()
* Pawel Chrzanowski     10/01/2017  added testUpdateOutboundCallingStageHistory_RescheduleChange()
* Pawel Chrzanowski     30/01/2017  added testVerifyOnlyOneOCCase_BalanceReview()
* Konrad Czykin         12/06/2017  added testUpdateOrphanCases()
* Vishant Shah			13/06/2017	added testClassificationUpdateForOCCase()
**/
@isTest
private class CaseTriggerHandlerTest {

	@testSetup static void init(){
        TestDataUtility tdu = new TestDataUtility(4);
        tdu.createGatewayResponseWithShortDescription(Constants.CASE_REASONCODE_ARUDD, '0', 'Sample Description');
        TestDataUtility.createOutboundCallStageMappingSettings(Constants.OC_SALES_RECORD_TYPE_NAME,
        	Constants.OC_SALES_VF_PAGE_NAME, Constants.OC_MAX_NUMBER_OF_STAGES );
        tdu.createCase();
        tdu.createSubscriptions();
        tdu.createZuoraSubscription();
    }

	/***************************************************************************************
    Developer - Michal Szewczyk
    Date - 08/11/2016
    Version - 1.2
    Function -  test population Product Name field on OC Case
    #############Change Log#############
    Modified by         Change Date
    Wiktor Czykin       05/11/2016  //added coverage
    Wiktor Czykin		21/12/2016	//added assertion for account
    ****************************************************************************************/
	@isTest static void updateProductFieldOnCase() {
		Zuora__Subscription__c zuoraSub = [SELECT Id, Subscription_Product__c, Zuora__Account__c FROM Zuora__Subscription__c LIMIT 1];
		zuoraSub.Subscription_Product__c = 'someProduct';
		update zuoraSub;
		Subscription__c printSub = [SELECT Id, Product__r.Name, Subscriber__c FROM Subscription__c LIMIT 1];

		Case ocCase = TestDataUtility.newOCCase(RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName()), Constants.OC_CALL_STAGE_T2, null);		
		ocCase.Print_Subscription__c = printSub.Id;
		insert ocCase;
		List<Case> ocCaseRefetched = [select Id, AccountId, Product__c from Case where Id = :ocCase.Id];
		System.assert(!ocCaseRefetched.isEmpty());
		System.assertEquals(printSub.Subscriber__c, ocCaseRefetched[0].AccountId);
		System.assertEquals(null, ocCaseRefetched[0].Product__c);
		Test.startTest();
			ocCase.OC_Outcome__c = Constants.CASE_OUTCOME_SALE;
			update ocCase;
			List<Case> lstCheckCase = [SELECT Id, Product__c FROM Case WHERE Id= :ocCase.Id LIMIT 1];
			System.assert(!lstCheckCase.isEmpty());
			System.assertEquals(printSub.Product__r.Name, lstCheckCase[0].Product__c);
			System.assertEquals(null, ocCaseRefetched[0].Product__c);

			ocCase.Subscription__c= zuoraSub.Id;
			ocCase.Print_Subscription__c = null;
			update ocCase;
			lstCheckCase = [SELECT Id, Product__c, AccountId FROM Case WHERE Id= :ocCase.Id LIMIT 1];
			System.assert(!lstCheckCase.isEmpty());
			System.assertEquals(zuoraSub.Subscription_Product__c, lstCheckCase[0].Product__c);
			System.assertEquals(zuoraSub.Zuora__Account__c, lstCheckCase[0].AccountId);
		Test.stopTest();
	}


	//valid path for failed payment case
	@isTest static void createFailedPaymentCaseWithCorrectGtwayCode() {
		// Implement test code
		Case failedCase = new Case(RecordTypeId=Constants.getFailedPaymentRT());
		failedCase.Gateway_Reason_code__c = '0';
		failedCase.Gateway_Reason_code_source__c = Constants.CASE_REASONCODE_ARUDD;

		insert failedCase;

		Case checkCase = [SELECT Id, Gateway_Reason_Code_detail__c FROM Case WHERE Id= :failedCase.Id LIMIT 1];
		String expectedValue = Constants.CASE_REASONCODE_ARUDD + '-' + '0' + ' Sample Description'; 
		System.assertEquals(expectedValue, checkCase.Gateway_Reason_Code_detail__c);
		
	}
	//invalid path for failed payment case
	@isTest static void createFailedPaymentCaseWithInCorrectGtwayCode() {
		// Implement test code
		Case failedCase = new Case(RecordTypeId=Constants.getFailedPaymentRT());
		failedCase.Gateway_Reason_code__c = '0';
		failedCase.Gateway_Reason_code_source__c = Constants.CASE_REASONCODE_AUDDIS;

		insert failedCase;
		
		Case checkCase = [SELECT Id, Gateway_Reason_Code_detail__c FROM Case WHERE Id= :failedCase.Id LIMIT 1];
		String expectedValue = Constants.CASE_REASONCODE_ARUDD + '-' + '0' + ' Sample Description'; 
		System.assertNotEquals(expectedValue, checkCase.Gateway_Reason_Code_detail__c);
	}

	/************************************************************************************
	Method Name  : testUpdateOutboundCallingSalesStageHistoryOutcomeUpdated
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateOutboundCallingSalesStageHistoryOutcomeUpdated(){

		Case ocCase = TestDataUtility.newOCCase(
			RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName()), 
			Constants.OC_CALL_STAGE_T2, null
		);		
		insert ocCase;

		System.assert([SELECT Id FROM Case WHERE Id = :ocCase.Id].size() == 1, 'The new OC case not inserted');

		String TEST_OUTCOME = 'New Test Outcome';

		update new Case(
			Id = ocCase.Id,
			OC_Outcome__c = TEST_OUTCOME
		);

		Case updatedCase = [ SELECT Id, OC_Stage_1_Outcome__c, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :ocCase.Id LIMIT 1];

		System.assertEquals(TEST_OUTCOME, updatedCase.OC_Stage_1_Outcome__c);
		System.assert(updatedCase.OC_Stage_1_Call_Date_Time__c != null, 'OC_Stage_1_Call_Date_Time__c expected to be updated');
	}

	/************************************************************************************
	Method Name  : testUpdateOutboundCallingSalesStageHistoryScheduledCallbackAdded
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateOutboundCallingSalesStageHistoryScheduledCallbackAdded(){

		Case ocCase = TestDataUtility.newOCCase(
			RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName()), 
			Constants.OC_CALL_STAGE_T2, null
		);
		insert ocCase;

		System.assert([SELECT Id FROM Case WHERE Id = :ocCase.Id].size() == 1, 'The new OC case not inserted');

		DateTime callbackTime = DateTime.now();
		String TEST_OUTCOME = 'New Test Outcome';

		update new Case(
			Id = ocCase.Id,
			OC_Outcome__c = TEST_OUTCOME,
			OC_Scheduled_Callback__c = callbackTime
		);

		Case updatedCase = [ SELECT Id, OC_Stage_1_Outcome__c, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :ocCase.Id LIMIT 1];

		System.assertEquals(TEST_OUTCOME, updatedCase.OC_Stage_1_Outcome__c);
		System.assertEquals(callbackTime, updatedCase.OC_Stage_1_Call_Date_Time__c);
	}

	/************************************************************************************
	Method Name  : testUpdateOutboundCallingSalesStageHistoryNoParametersException
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    		Date         Description
	* Wiktor Czykin		07/12/2016	 Changed to work with on insert scenario
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateOutboundCallingSalesStageHistoryNoParametersException(){

		//empty outbound call setting parameters JSON object so the exception is thrown
		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);
		ocSetting.Parameters__c = '{"callStageParameters" :[]}';
		update ocSetting;
		
		Test.startTest();
			Id salesRecordType = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
			Case ocCase = TestDataUtility.newOCCase(salesRecordType, Constants.OC_CALL_STAGE_T2, null);

			String expectedErrorMessage = String.format(Label.Outbound_Call_Setting_JSON_Object_Empty, 
												new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
																	OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME });
			ocCase.OC_Call_Stage__c = null;
			try{
				insert ocCase;
			}catch(Exception e){
				System.assert(e.getMessage().contains(expectedErrorMessage), 'Expected error message: ' + expectedErrorMessage);
			}
			ocCase.RecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.CASE_RECORDTYPE_GENERALENQUIRY, Case.class.getName()); 
			insert ocCase;
			System.assert([SELECT Id FROM Case WHERE Id = :ocCase.Id].size() == 1, 'The new OC case not inserted');


			try {
				update new Case(
					Id = ocCase.Id,
					OC_Outcome__c = 'New Test Outcome',
					RecordTypeId = salesRecordType,
					OC_Call_Stage__c = Constants.OC_CALL_STAGE_T2

				);
			} catch(Exception e){
				System.assert(e.getMessage().contains(expectedErrorMessage), 'Expected error message: ' + expectedErrorMessage);
			}
		Test.stopTest();
	}

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 10/01/2017
    Method to test if Call Stage history gets updated after changes to Reschedule
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@isTest static void testUpdateOutboundCallingStageHistory_RescheduleChange(){
		DateTime callbackTime = DateTime.now();
		Case ocCase = TestDataUtility.newOCCase(
			RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName()), 
			Constants.OC_CALL_STAGE_T2, null
		);
		insert ocCase;

		//verify Scheduled Callback was saved
		callbackTime = callbackTime.addDays(3);
		update new Case(Id = ocCase.Id, OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE, OC_Scheduled_Callback__c = callbackTime);
		Case updatedCase = [SELECT OC_Stage_1_Outcome__c, OC_Stage_1_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :ocCase.Id];
		System.assertEquals(Constants.CASE_OUTCOME_RESCHEDULE, updatedCase.OC_Stage_1_Outcome__c);
		System.assertEquals(callbackTime, updatedCase.OC_Stage_1_Call_Date_Time__c);
		System.assertEquals(callbackTime, updatedCase.OC_Scheduled_Callback__c);

		//verify Scheduled Callback was updated
		callbackTime = callbackTime.addDays(3);
		update new Case(Id = ocCase.Id, OC_Scheduled_Callback__c = callbackTime);
		updatedCase = [SELECT OC_Stage_1_Call_Date_Time__c, OC_Scheduled_Callback__c FROM Case WHERE Id = :ocCase.Id];
		System.assertEquals(callbackTime, updatedCase.OC_Stage_1_Call_Date_Time__c);
		System.assertEquals(callbackTime, updatedCase.OC_Scheduled_Callback__c);
	}

	/************************************************************************************
	Author       : Wiktor Czykin
	Created Date : 07/12/2016
	Description  : Checks if stage respective date time field is not populated on Case insert if case outcome is Not Started  
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    			Date        Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testOCCaseInsertPopulationOfRespectiveStageDateTimeFieldNegative(){
		Case ocCase = TestDataUtility.newOCCase(
			RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName()), 
			Constants.OC_CALL_STAGE_T2, null
		);
		ocCase.OC_Outcome__c = Constants.OC_DEFAULT_OUTCOME;
		Test.startTest();		
			insert ocCase;
			List<Case> lstCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :ocCase.Id];
			System.assertEquals(1, lstCase.size(), 'The new OC case not inserted');
			System.assertEquals(null, lstCase[0].OC_Stage_1_Call_Date_Time__c);
		Test.stopTest();
	}


	/************************************************************************************
	Method Name  : testUpdateOutboundCallingSalesStageHistoryOutcomeNoSaleWithReason
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    			Date        Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Mantas Grigaliunas	19/10/2016	added the check for No Sales Reason update check with the same Outcome
	* Wiktor Czykin			07/12/2016  added negative assertion  
	*************************************************************************************/
	@isTest static void testUpdateOutboundCallingSalesStageHistoryOutcomeNoSaleWithReason(){

		Case ocCase = TestDataUtility.newOCCase(
			RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName()), 
			Constants.OC_CALL_STAGE_T2, null
		);		
		insert ocCase;
		List<Case> lstCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c FROM Case WHERE Id = :ocCase.Id];
		System.assert(lstCase.size() == 1, 'The new OC case not inserted');
		System.assertNotEquals(null, lstCase[0].OC_Stage_1_Call_Date_Time__c);

		final String NO_SALE_REASON_1 = 'Test Reason 1';
		final String NO_SALE_REASON_2 = 'Test Reason 2';

		update new Case(
			Id = ocCase.Id,
			OC_Outcome__c = Constants.OC_NO_SALE_OUTCOME,
			OC_No_Sale_Reason__c = NO_SALE_REASON_1
		);

		Case updatedCase = [ SELECT Id, OC_Stage_1_Outcome__c, OC_Stage_1_Call_Date_Time__c, OC_Stage_1_No_Sale_Reason__c FROM Case WHERE Id = :ocCase.Id LIMIT 1];

		System.assertEquals(Constants.OC_NO_SALE_OUTCOME, updatedCase.OC_Stage_1_Outcome__c);
		System.assert(updatedCase.OC_Stage_1_Call_Date_Time__c != null, 'OC_Stage_1_Call_Date_Time__c expected to be updated');
		System.assertEquals(NO_SALE_REASON_1, updatedCase.OC_Stage_1_No_Sale_Reason__c);

		//this update is required to test if the time stamp is being updated as well as No Sale Reason
		DateTime timeStamp = DateTime.now().addDays(-1);
		update new Case(
			Id = ocCase.Id,
			OC_Stage_1_Call_Date_Time__c = timeStamp
		);

		//update the reson only
		update new Case(
			Id = ocCase.Id,
			OC_No_Sale_Reason__c = NO_SALE_REASON_2
		);

		updatedCase = [ SELECT Id, OC_Stage_1_Outcome__c, OC_Stage_1_Call_Date_Time__c, OC_Stage_1_No_Sale_Reason__c FROM Case WHERE Id = :ocCase.Id LIMIT 1];

		System.assertEquals(Constants.OC_NO_SALE_OUTCOME, updatedCase.OC_Stage_1_Outcome__c);
		System.assert(updatedCase.OC_Stage_1_Call_Date_Time__c != timeStamp, 'OC_Stage_1_Call_Date_Time__c expected to be updated');
		System.assertEquals(NO_SALE_REASON_2, updatedCase.OC_Stage_1_No_Sale_Reason__c);
	}

	/************************************************************************************
	Method Name  : testUpdateAccountContactNoPersonAccount
	Author       : Mantas Grigaliunas
	Created Date : 01/09/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactNoPersonAccount(){
		Account account = [SELECT Id FROM Account WHERE IsPersonAccount = false LIMIT 1];
		Contact contact = new Contact(LastName = 'Test');
        insert contact;

		Test.startTest();
		Case newCase = new Case(AccountId = account.Id, ContactId = contact.Id, Status = 'New');
		insert newCase;

		Case insertedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(account.Id, insertedCase.AccountId);
		System.assertEquals(contact.Id, insertedCase.ContactId);

		update insertedCase;
		Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];
		System.assertEquals(account.Id, updatedCase.AccountId);
		System.assertEquals(contact.Id, updatedCase.ContactId);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testUpdateAccountContactNoPersonAccountNoConatct
	Author       : Mantas Grigaliunas
	Created Date : 01/09/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactNoPersonAccountNoConatct(){
		Account account = [SELECT Id FROM Account WHERE IsPersonAccount = false LIMIT 1];

		Test.startTest();
		Case newCase = new Case(AccountId = account.Id, Status = 'New');
		insert newCase;

		Case insertedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(account.Id, insertedCase.AccountId);
		System.assertEquals(null, insertedCase.ContactId);

		update insertedCase;
		Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];
		System.assertEquals(account.Id, updatedCase.AccountId);
		System.assertEquals(null, updatedCase.ContactId);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testUpdateAccountContactNoPersonAccountNoAccount
	Author       : Mantas Grigaliunas
	Created Date : 01/09/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactNoPersonAccountNoAccount(){
		Contact contact = new Contact(LastName = 'Test');
        insert contact;

		Test.startTest();
		Case newCase = new Case(ContactId = contact.Id, Status = 'New');
		insert newCase;

		Case insertedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(null, insertedCase.AccountId);
		System.assertEquals(contact.Id, insertedCase.ContactId); 

		update insertedCase;
		Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];
		System.assertEquals(null, updatedCase.AccountId);
		System.assertEquals(contact.Id, updatedCase.ContactId); 
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testUpdateAccountContactPersonAccountNoContact
	Author       : Mantas Grigaliunas
	Created Date : 01/09/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactPersonAccountNoContact(){
		Account account = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true LIMIT 1];

		Test.startTest();
		Case newCase = new Case(AccountId = account.Id, Status = 'New');
		insert newCase;

		Case insertedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(account.Id, insertedCase.AccountId);
		System.assertEquals(account.PersonContactId, insertedCase.ContactId); 

		insertedCase.ContactId = null;
		update insertedCase;
		Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];
		System.assertEquals(account.Id, updatedCase.AccountId);
		System.assertEquals(account.PersonContactId, updatedCase.ContactId); 
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testUpdateAccountContactPersonAccountDecease
	Author       : Michal Szewczyk
	Created Date : 11/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactPersonAccountDecease(){
		Account account = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true LIMIT 1];

		Test.startTest();
		Case newCase = new Case(AccountId = account.Id, Status = 'New', OC_Outcome__c = Constants.CASE_OUTCOME_DECEASED);
		insert newCase;

		Account updatedAcc = [SELECT Id,Deceased__pc FROM Account WHERE Id = :account.Id LIMIT 1];
		System.assertEquals(updatedAcc.Deceased__pc,true);

		Test.stopTest();
	}
	/************************************************************************************
	Method Name  : testUpdateAccountContactPersonAccountNoAccount
	Author       : Mantas Grigaliunas
	Created Date : 01/09/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactPersonAccountNoAccount(){
		Account account = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true LIMIT 1];
		Contact contact = [SELECT Id FROM Contact WHERE Id = :account.PersonContactId LIMIT 1 ];

		Test.startTest();
		Case newCase = new Case(ContactId = contact.Id, Status = 'New');
		insert newCase;

		Case insertedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(account.Id, insertedCase.AccountId);
		System.assertEquals(account.PersonContactId, insertedCase.ContactId); 

		insertedCase.AccountId = null;
		update insertedCase;
		Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];
		System.assertEquals(account.Id, updatedCase.AccountId);
		System.assertEquals(account.PersonContactId, updatedCase.ContactId); 
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testUpdateAccountContactPersonAccountDifferentContact
	Author       : Mantas Grigaliunas
	Created Date : 01/09/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateAccountContactPersonAccountDifferentContact(){
		Account account = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true LIMIT 1];
		Contact contact = new Contact(LastName = 'Test');
        insert contact;

		Test.startTest();
		Case newCase = new Case(ContactId = contact.Id, AccountId = account.Id, Status = 'New');
		insert newCase;

		Case insertedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :newCase.Id LIMIT 1];
		System.assertEquals(account.Id, insertedCase.AccountId);
		System.assertEquals(account.PersonContactId, insertedCase.ContactId); 

		insertedCase.ContactId = contact.Id;
		update insertedCase;
		Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];
		System.assertEquals(account.Id, updatedCase.AccountId);
		System.assertEquals(account.PersonContactId, updatedCase.ContactId); 
		Test.stopTest();
	}
	
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 06/12/2016
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.2        30/01/2017  renamed to testVerifyOnlyOneOCCase_Sales()
    ****************************************************************************************/
	@isTest static void testVerifyOnlyOneOCCase_Sales(){
		Id ocsId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
		Subscription__c sub = [SELECT Id From Subscription__c limit 1];

		//validation - cannot insert two OCS Cases linked to the same print subscription
		Case ocCase1 = TestDataUtility.newOCCase(ocsId, Constants.OC_CALL_STAGE_T2, null);
		Case ocCase2 = TestDataUtility.newOCCase(ocsId, Constants.OC_CALL_STAGE_T2, null);
		ocCase1.Print_Subscription__c = sub.Id;
		ocCase2.Print_Subscription__c = sub.Id;
		List<Case> lstCases = new List<Case>{ocCase1, ocCase2};
		try{
			insert lstCases;
		}catch(Exception e){
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Multiple_Sales_Cases_Trigger));
		}

		//insert new OCS Case
		Case ocCase3 = TestDataUtility.newOCCase(ocsId, Constants.OC_CALL_STAGE_T2, null);
		ocCase3.Print_Subscription__c = sub.Id;
		insert ocCase3;
		System.assertNotEquals(null, ocCase3.Id);

		//update OCS Case
		ocCase3.OC_Call_Stage__c = Constants.OC_T2_CATCH_UP;
		update ocCase3;
		Case c = [SELECT OC_Call_Stage__c FROM Case WHERE Id = :ocCase3.Id];
		System.assertEquals(Constants.OC_T2_CATCH_UP, c.OC_Call_Stage__c);

		//validation - cannot add new OCS Case to the same subscription
		Case ocCase4 = TestDataUtility.newOCCase(ocsId, Constants.OC_CALL_STAGE_T2, null);		
		ocCase4.Print_Subscription__c = sub.Id;
		try{
			insert ocCase4;
		}catch(Exception e){
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Only_One_Sales_Case));
		}

		//validation - cannot update two OCS Cases linked to the same print subscription
		Case ocCase5 = TestDataUtility.newOCCase(ocsId, Constants.OC_CALL_STAGE_T2, null);
		Case ocCase6 = TestDataUtility.newOCCase(ocsId, Constants.OC_CALL_STAGE_T2, null);
		insert ocCase5;
		insert ocCase6;
		ocCase5.Print_Subscription__c = sub.Id;
		ocCase6.Print_Subscription__c = sub.Id;
		List<Case> lstCases2 = new List<Case>{ocCase5, ocCase6};
		try{
			update lstCases2;
		}catch(Exception e){
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Multiple_Sales_Cases_Trigger));
		}

		//validation - can add another case of different record type to the same print subscription
		Id occcId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME, Case.class.getName());
		Case ccCase = TestDataUtility.newOCCase(occcId, 'CCEX1', null);
		ccCase.Print_Subscription__c = sub.Id;
		insert ccCase;
		System.assertNotEquals(null, ccCase.Id);
	}
	
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 06/12/2016
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@isTest static void testVerifyOnlyOneOCCase_BalanceReview(){
		Id ocbrId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME, Case.class.getName());
		Subscription__c sub = [SELECT Id From Subscription__c limit 1];

		//validation - cannot insert two OCBR Cases linked to the same print subscription
		Case ocCase1 = TestDataUtility.newOCCase(ocbrId, Constants.OC_BR1, null);
		Case ocCase2 = TestDataUtility.newOCCase(ocbrId, Constants.OC_BR1, null);
		ocCase1.Print_Subscription__c = sub.Id;
		ocCase2.Print_Subscription__c = sub.Id;
		List<Case> lstCases = new List<Case>{ocCase1, ocCase2};
		try{
			insert lstCases;
		}catch(Exception e){
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Multiple_Balance_Review_Cases_Trigger));
		}

		//insert new OCBR case
		Case ocCase3 = TestDataUtility.newOCCase(ocbrId, Constants.OC_BR1, null);
		ocCase3.Print_Subscription__c = sub.Id;
		insert ocCase3;
		System.assertNotEquals(null, ocCase3.Id);

		//update OCBR Case
		ocCase3.OC_Call_Stage__c = Constants.OC_BR1;
		update ocCase3;
		Case c = [SELECT OC_Call_Stage__c FROM Case WHERE Id = :ocCase3.Id];
		System.assertEquals(Constants.OC_BR1, c.OC_Call_Stage__c);

		//validation - cannot add new OCBR Case to the same subscription
		Case ocCase4 = TestDataUtility.newOCCase(ocbrId, Constants.OC_BR1, null);		
		ocCase4.Print_Subscription__c = sub.Id;
		try{
			insert ocCase4;
		}catch(Exception e){
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Only_One_Balance_Review_Case));
		}

		//validation - cannot update two OCBR Cases linked to the same print subscription
		Case ocCase5 = TestDataUtility.newOCCase(ocbrId, Constants.OC_BR1, null);
		Case ocCase6 = TestDataUtility.newOCCase(ocbrId, Constants.OC_BR1, null);
		insert ocCase5;
		insert ocCase6;
		ocCase5.Print_Subscription__c = sub.Id;
		ocCase6.Print_Subscription__c = sub.Id;
		List<Case> lstCases2 = new List<Case>{ocCase5, ocCase6};
		try{
			update lstCases2;
		}catch(Exception e){
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_Multiple_Balance_Review_Cases_Trigger));
		}

		//validation - can add another case of different record type to the same print subscription
		Id occcId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME, Case.class.getName());
		Case ccCase = TestDataUtility.newOCCase(occcId, 'CCEX1', null);
		ccCase.Print_Subscription__c = sub.Id;
		insert ccCase;
		System.assertNotEquals(null, ccCase.Id);
	}

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 14/12/2016
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@isTest static void testUpdateSubscription(){
		List<Subscription__c> lstSubs = [SELECT Subscriber__c From Subscription__c];
		List<Case> lstCases = [SELECT Id FROM Case];
		Set<Id> setAccountIds = new Set<Id>();

		for(Integer i = 0; i < lstCases.size(); i++){
			lstCases[i].Print_Subscription__c = lstSubs[i].Id;
			lstCases[i].AccountId = lstSubs[i].Subscriber__c;
			lstCases[i].OC_Outcome__c = Constants.CASE_OUTCOME_DECEASED;
			setAccountIds.add(lstSubs[i].Subscriber__c);
		}
		update lstCases;

		lstSubs = [SELECT Subscription_Status__c From Subscription__c];
		for(Subscription__c sub : lstSubs){
			System.assertEquals(Constants.SSTATUS_DECLINED, sub.Subscription_Status__c);
		}

		List<Account> lstAccs = [SELECT Deceased__pc FROM Account WHERE Id IN :setAccountIds];
		for(Account a : lstAccs){
			System.assert(a.Deceased__pc);
		}
	}

	/************************************************************************************
	Method Name  : testUpdateOrphanCases
	Author       : Konrad Czykin
	Created Date : 12/06/2017
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testUpdateOrphanCases(){
		Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.READER_RELATIONS_RECORD_TYPE_NAME, Case.class.getName());
		List<Case> lsc = new List<Case>();
		List<Case> lsc2 = new List<Case>();
		List<Account> lacc = new List<Account>();
		lacc.add(new Account(LastName = 'Test',
								PersonEmail = 'acctestmail@test.com'
								));
		lacc.add(new Account(LastName = 'Testb',
								PersonEmail = 'testemail@test.com'
								));	
		insert lacc;
		insert new Case(SuppliedEmail = 'testemail@test.com',
						RecordTypeId = rtId);
		
		for(Integer i=0; i<2; i++){
			Case nc = new Case(suppliedEmail = 'testemail@test.com',
                   Reason = 'Subscription',
                   RecordTypeId = rtId,
                   subject= 'test'+i
                  );
    		lsc.add(nc);
		}
		Case cacc = new Case(SuppliedEmail = 'acctestmail@test.com',
							Reason = 'Subscription',
							RecordTypeId = rtId,
							Subject = 'testacc');
		lsc.add(cacc);
		insert lsc;
	
		List<Case> lscinsertedp = [SELECT Id, SuppliedEmail, ParentId FROM Case WHERE SuppliedEmail = 'testemail@test.com' AND ParentId = null];
		List<Case> lscinsertedch = [SELECT Id, SuppliedEmail, ParentId FROM Case WHERE SuppliedEmail = 'testemail@test.com' AND ParentId != null];
		List<Account> lsacc = [SELECT Id, (SELECT Id, AccountId FROM Cases) FROM Account WHERE PersonEmail = 'acctestmail@test.com'];

		System.assertEquals(1,lscinsertedp.size());
		System.assertEquals(lscinsertedp[0].Id, lscinsertedch[0].ParentId);
		System.assertEquals(lsacc[0].Id, lsacc[0].Cases[0].AccountId);


	}

	/************************************************************************************
	Method Name  : testClassificationUpdateForOCCase
	Author       : Vishant Shah
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testClassificationUpdateForOCCase(){

		Outbound_Call_Setting__c ocSetting = [SELECT Id, Case_Field_Map__c FROM Outbound_Call_Setting__c LIMIT 1];
		System.assert(ocSetting.Case_Field_Map__c != null, 'Case field map should be populated on Outbound_Call_Setting__c');

		String subject      = 'Outbound Renewal Tracker';
		String outcome      = 'noSale';
		String noSaleReason = 'Price Increase';
		Id salesRecordType  = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
		
		Case ocCase                 = TestDataUtility.newOCCase(salesRecordType,Constants.OC_CALL_STAGE_T2, null);
		ocCase.Subject              = subject;
		ocCase.OC_Outcome__c        = outcome;
		ocCase.OC_No_Sale_Reason__c = noSaleReason;
		insert ocCase;

		List<Case> cases = [SELECT Reason, Type_of_Issue__c, Digital_Details__c, Digital_Details_2__c, OC_Call_Stage__c FROM Case WHERE Id = :ocCase.Id];
		System.assert(cases.size() == 1, 'The new OC case not inserted');

		System.assertEquals('Renewal', cases[0].Reason);
		System.assertEquals(outcome, cases[0].Digital_Details__c);
		System.assertEquals(noSaleReason, cases[0].Digital_Details_2__c);
		System.assertEquals(Constants.OC_CALL_STAGE_T2, cases[0].Type_of_Issue__c);

	}

}