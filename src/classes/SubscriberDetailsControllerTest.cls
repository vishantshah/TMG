/************************************************************************************
Class Name   : Subscriber Details Controller Test
Author       : Konrad Czykin
Created Date : 11/05/2017
Function     : Subscriber Details Controller class unit tests
*************************************************************************************/
@isTest
private class SubscriberDetailsControllerTest {

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
	Method Name  : testEnableEditAccount
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test enable edit account
	*************************************************************************************/
	@isTest static void testEnableEditAccount() {

		setPageUrl();

		Test.startTest();
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		System.assertEquals(null, ocsc.accEditEnabled, 'expected accEditEnabled to be null');
		ocsc.enableEditAccount();
		System.assert(ocsc.accEditEnabled, 'expected accEditEnabled to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testCancelAccountEdit
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test cancel account edit
	*************************************************************************************/
	@isTest static void testCancelAccountEdit() {

		setPageUrl();

		Test.startTest();
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		ocsc.accBeforeEdit = [SELECT Id, FirstName FROM Account Limit 1];
		ocsc.accountId = [SELECT Id FROM Account Limit 1][0].Id;
		ocsc.thisAccount = [SELECT Id, FirstName FROM Account Limit 1];
		ocsc.accEditEnabled = true;
		String nameBeforeChange = ocsc.thisAccount.FirstName;
		ocsc.thisAccount.FirstName = 'Changed Name';
		ocsc.cancelAccountEdit();
		System.assert(!ocsc.accEditEnabled, 'expected accEditEnabled to be set to false');
		System.assert(!ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to false');
		System.assertEquals(nameBeforeChange, ocsc.thisAccount.FirstName);
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testSaveAccount
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test save account
	*************************************************************************************/
	@isTest static void testSaveAccount() {

		setPageUrl();

		final String NAME_CHANGED_TO = 'nameChangedTo';
		Test.startTest();
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		ocsc.thisAccount = [SELECT Id, Salutation, FirstName FROM Account Limit 1];
		ocsc.accEditEnabled = true;
		ocsc.thisAccount.FirstName = NAME_CHANGED_TO;
		ocsc.saveAccount();
		System.assert(ApexPages.getMessages().size() == 0, String.valueOf(ApexPages.getMessages()));
		Account savedAcc = [SELECT Id, FirstName FROM Account WHERE Id = :ocsc.thisAccount.Id LIMIT 1 ];
		System.assertEquals(NAME_CHANGED_TO, savedAcc.FirstName);
		System.assert(!ocsc.accEditEnabled, 'expected accEditEnabled to be set to false');

		ocsc.thisAccount.Title__c = 'Mr';
		ocsc.saveAccount();
		Account savacc = [SELECT Id, Salutation FROM Account Limit 1];
		system.assertEquals('Mr', savacc.Salutation);

		ocsc.thisAccount.FirstName = '1';
		ocsc.saveAccount();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			Label.OC_First_Name_not_valid));

		ocsc.thisAccount = null;
		ocsc.saveAccount();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			Label.OC_Error));

		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testDisplayChangeEmailIFrame
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test email show iframe
	*************************************************************************************/
	@isTest static void testDisplayChangeEmailIFrame() {

		setPageUrl();

		Test.startTest();
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		System.assertEquals(null, ocsc.showEmailIFrame, 'expected showEmailIFrame to be null');
		ocsc.displayChangeEmailIFrame();
		System.assert(ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testHideChangeEmailIFrame
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test change email iframe to hide
	*************************************************************************************/
	@isTest static void testHideChangeEmailIFrame() {

		setPageUrl();

		Test.startTest();
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		ocsc.showEmailIFrame = true;
		ocsc.hideChangeEmailIFrame();
		System.assert(!ocsc.showEmailIFrame, 'expected showEmailIFrame to be set to true');
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : testRefetchSubscriberEmail
	Author       : Mantas Grigaliunas
	Created Date : 11/05/2017
	Function     : test fetch email function
	*************************************************************************************/
	@isTest static void testRefetchSubscriberEmail() {

		setPageUrl();

		final String NEW_EMAIL = '678954345678@test.com';
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		ocsc.thisAccount = [SELECT Id, PersonEmail FROM Account Limit 1];
		ocsc.accBeforeEdit = [SELECT Id, PersonEmail FROM Account Limit 1];

		Account a = [SELECT Id FROM Account WHERE Id = :ocsc.thisAccount.Id];
		a.PersonEmail = NEW_EMAIL;
		update a;

		ocsc.refetchSubscriberEmail();
		System.assertEquals(ocsc.thisAccount.PersonEmail, NEW_EMAIL);
		System.assertEquals(ocsc.accBeforeEdit.PersonEmail, NEW_EMAIL);
	}

	/************************************************************************************
	Method Name  : testGetSetAccountPermissions
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test get and set permissions of the subscriber
	*************************************************************************************/
	@isTest static void testGetSetAccountPermissions(){

		setPageUrl();
		final Date LAST_UPDATED_DATE = Date.Today();

		Test.startTest();
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		ocsc.accountPermissions = [SELECT Id, TMG_Promo_Email__c, TMG_Promo_Phone__c, 
									TMG_Promo_Post__c, TMG_Promo_SMS__c, Permissions_Last_Change_Date__c FROM Account Limit 1];
		
		System.assert(!ocsc.p2ndemail);
        System.assert(!ocsc.p2ndphone);
        System.assert(!ocsc.p2ndpost);
        System.assert(!ocsc.p2ndSMS);

        ocsc.accountPermissions.TMG_Promo_Email__c = null;
        system.assert(!ocsc.p2ndEmail);

        ocsc.accountPermissions.TMG_Promo_Email__c = 1;
        system.assert(ocsc.p2ndEmail);

        ocsc.p2ndEmail = true;
        system.assertEquals(1, ocsc.accountPermissions.TMG_Promo_Email__c);

        ocsc.p2ndEmail = false;
        system.assertEquals(0, ocsc.accountPermissions.TMG_Promo_Email__c);

        ocsc.p2ndphone = true;
        system.assertEquals(1, ocsc.accountPermissions.TMG_Promo_Phone__c);

 		ocsc.p2ndpost = true;
        system.assertEquals(1, ocsc.accountPermissions.TMG_Promo_Post__c);

        ocsc.p2ndSMS = true;
        system.assertEquals(1, ocsc.accountPermissions.TMG_Promo_SMS__c);



        ocsc.saveAccountPermissions();
        system.assertEquals(system.today(), ocsc.accountPermissions.Permissions_Last_Change_Date__c);

        ocsc.accountPermissions.Id = null;
        ocsc.saveAccountPermissions();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
			'Id not specified'));

		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetSubscriberAddress
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : test get subscriber address
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
		SubscriberDetailsController ocsc = new SubscriberDetailsController();
		ocsc.thisAccount = [SELECT Id, RecordTypeId, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode FROM Account Limit 1];
		
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

		ocsc.getCountries();
		System.assertEquals('United Kingdom', ocsc.getCountries().get(0).getLabel());
		System.assertEquals('GB', ocsc.getCountries().get(0).getValue());
		
		ocsc.thisAccount.RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName()); 
		ocsc.getCountries();
		Test.stopTest();
	}
	
	/************************************************************************************
	Method Name  : setPageUrl
	Author       : Konrad Czykin
	Created Date : 11/05/2017
	Function     : sets curent page url to the expected visualforce page
	*************************************************************************************/
	private static void setPageUrl(){
		PageReference pr = Page.RetentionCalling;
		Test.setCurrentPage(pr);
		System.assertEquals(pr.getUrl(), ApexPages.currentPage().getUrl());
	}
}