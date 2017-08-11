/************************************************************************************
Class Name   : NotificationBannerControllerTest
Author       : Mantas Grigaliunas
Created Date : 25/10/2016
Function     : NotificationBannerController class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    			Date      	Description
* Vishant Shah			19/04/2017	updated test class after changing controller Static references.
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
private class NotificationBannerControllerTest {

	public static final String TEST_MESSAGE = 'This case subject is {0}';
	public static final String TEST_FIELD = 'Subject';
	public static final String TEST_SEVERITY = 'error';
	public static final String TEST_FIELD_VALUE = 'TestSubject';
	public static final String TEST_OBJECT = Case.class.getName();
	public static final String TEST_CONTACT_NAME = 'TestContact';

	/************************************************************************************
	Method Name  : testSetup
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@testSetup static void testSetup(){

		Contact c = new Contact(LastName = TEST_CONTACT_NAME);
		insert c;
		TestDataUtility tdu = new TestDataUtility(2);
		tdu.createCase();
		tdu.lstCases[0].Subject = TEST_FIELD_VALUE;
		tdu.lstCases[0].ContactId = c.Id;
		update tdu.lstCases[0];

		insert new Notification_Banner_Setting__c(
			Name = 'Test',
			Object__c = TEST_OBJECT,
			Message__c = TEST_MESSAGE,
			Fields__c = TEST_FIELD,
			Severity__c = TEST_SEVERITY,
			Active__c = true
		);
	}
	
	/************************************************************************************
	Method Name  : messagesToDisplayTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void messagesToDisplayTest() {

		Case testCase = [ SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		nbc.objectRecordId = testCase.Id;
		Map<String, String> testMessageMap = nbc.messageMap;
		System.assertEquals(1, testMessageMap.size());
		String message = String.format(TEST_MESSAGE, new List<String>{TEST_FIELD_VALUE});
		System.assert(testMessageMap.containsKey(message), testMessageMap);
		System.assertEquals(TEST_SEVERITY, testMessageMap.get(message));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : messagesToDisplayNoFieldsTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void messagesToDisplayNoFieldsTest() {

		Notification_Banner_Setting__c setting = [ SELECT Id FROM Notification_Banner_Setting__c LIMIT 1 ];
		setting.Fields__c = null;
		update setting;
		Case testCase = [ SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		nbc.objectRecordId = testCase.Id;
		System.assertEquals(1, nbc.messageMap.size());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : messagesToDisplayEmptyFieldTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void messagesToDisplayEmptyFieldTest() {
		
		Case testCase = [ SELECT Id FROM Case LIMIT 1 ];
		testCase.Subject = null;
		update testCase;

		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		nbc.objectRecordId = testCase.Id;
		System.assertEquals(0, nbc.messageMap.size());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : messagesToDisplayNoSettingsTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void messagesToDisplayNoSettingsTest() {

		delete [ SELECT Id FROM Notification_Banner_Setting__c ];
		Case testCase = [ SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		nbc.objectRecordId = testCase.Id;
		System.assertEquals(0, nbc.messageMap.size());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getRecordValuesTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getRecordValuesTest() {

		Case testCase = [ SELECT Id, Subject FROM Case LIMIT 1 ];
		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		Map<String, String> testValuesMap = nbc.getRecordValues(testCase.Id, new List<String>{TEST_FIELD}, TEST_OBJECT);
		System.assertEquals(testCase.Subject, testValuesMap.get(TEST_FIELD));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getRecordValuesWithParentFieldTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getRecordValuesWithParentFieldTest() {

		final String THIS_TEST_MESSAGE = 'This case is raised by {0}';
		final String THIS_TEST_FIELD = 'Contact.Name';
		Notification_Banner_Setting__c setting = [ SELECT Id, Fields__c FROM Notification_Banner_Setting__c LIMIT 1 ];
		setting.Fields__c = THIS_TEST_FIELD;
		setting.Message__c = THIS_TEST_MESSAGE;

		Case testCase = [ SELECT Id, Contact.Name FROM Case LIMIT 1 ];
		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		Map<String, String> testValuesMap =  nbc.getRecordValues(testCase.Id, new List<String>{THIS_TEST_FIELD}, TEST_OBJECT);
		System.assertEquals(testCase.Contact.Name, testValuesMap.get(THIS_TEST_FIELD));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getRecordValuesNoFieldsTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getRecordValuesNoFieldsTest() {

		final String THIS_TEST_MESSAGE = 'This case is raised by {0}';
		final String THIS_TEST_FIELD = 'Contact.Name';
		Notification_Banner_Setting__c setting = [ SELECT Id, Fields__c FROM Notification_Banner_Setting__c LIMIT 1 ];
		setting.Fields__c = THIS_TEST_FIELD;
		setting.Message__c = THIS_TEST_MESSAGE;

		Case testCase = [ SELECT Id, Contact.Name FROM Case LIMIT 1 ];
		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		Map<String, String> testValuesMap = nbc.getRecordValues(testCase.Id, new List<String>{THIS_TEST_FIELD}, TEST_OBJECT);
		System.assertEquals(testCase.Contact.Name, testValuesMap.get(THIS_TEST_FIELD));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getRecordValuesWrongFieldTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getRecordValuesWrongFieldTest() {

		
		Case testCase = [ SELECT Id FROM Case LIMIT 1 ];
		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		nbc.getRecordValues(testCase.Id, new List<String>{'Test'}, 'Account');
		System.assertEquals(1, ApexPages.getMessages().size());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getSeverityTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getSeverityTest() {
		NotificationBannerController nbc = new NotificationBannerController();
		String severity = new List<String>(nbc.severity).get(0);
		Test.startTest(); 
		System.assertEquals(severity, nbc.getSeverity(severity.toUpperCase()));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getSeverityWrongParameterTest
	Author       : Mantas Grigaliunas
	Created Date : 25/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getSeverityWrongParameterTest() {
		
		Test.startTest();
		NotificationBannerController nbc = new NotificationBannerController();
		nbc.getSeverity('Test');
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Notification_Banner_Incorrect_Severity), ApexPages.getMessages());
		Test.stopTest();
	}
}