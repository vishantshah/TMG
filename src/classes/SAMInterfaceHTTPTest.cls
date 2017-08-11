/*
 * File Name   : SAMInterfaceHTTPTest
 * Description : Test class for SAMInterfaceHTTP
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         	Modification
 * --- ---------- -------------- 	--------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 	Initial Version 
 * 1.1 03/09/2015 Cristina Anghenie	test getSAMUserDetails
 */ 
 @isTest
public class SAMInterfaceHTTPTest {
	
	//Try to authenticate without custom settings
	static testmethod void testAuthenticateUserNoSettings() {
		
		Test.startTest();
		SAMInterfaceHTTP.authenticateUserResponse authResponse = SAMInterfaceHTTP.callAuthenticateUser('test', 'test');
		Test.stopTest();
		
		System.assertEquals(authResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.INCOMPLETESETTINGS);
		System.assertEquals(authResponse.message, Label.UnknownError);
	}
	
	//Test a successful authentication
	static testmethod void testAuthenticateUserSuccess() {
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('SAMAuthenticationSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		SAMInterfaceHTTP.authenticateUserResponse authResponse = SAMInterfaceHTTP.callAuthenticateUser('test', 'test');
		Test.stopTest();
		
		System.assertEquals(authResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.SUCCESS);
		System.assertEquals(authResponse.message, null);
	}
	
	//Test a successful callout but with wrong credentials
	static testmethod void testAuthenticateUserWrongCredentials() {
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('SAMAuthenticationCredentialsError');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		SAMInterfaceHTTP.authenticateUserResponse authResponse = SAMInterfaceHTTP.callAuthenticateUser('test', 'test');
		Test.stopTest();
		
		System.assertEquals(authResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.FAIL);
		System.assertEquals(authResponse.message, Label.FailedAuthenticationError);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - test getSAMUserDetails
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testmethod void testGetUserDetails() {
		TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
		Test.startTest();
			SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(tdu.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
			SAMInterfaceHTTP.SamUserDetails result = SAMInterfaceHTTP.getUserDetails('test', 'TEST_GUID');
		Test.stopTest();
		System.assertNotEquals(null,result);
	}
	
	//Test a successful callout but with an unknown authentication error in the response
	static testmethod void testAuthenticateUserSAMError() {
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('SAMAuthenticationOtherError');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		SAMInterfaceHTTP.authenticateUserResponse authResponse = SAMInterfaceHTTP.callAuthenticateUser('test', 'test');
		Test.stopTest();
		
		System.assertEquals(authResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.FAIL);
		System.assertEquals(authResponse.message, Label.UnknownSAMAuthenticationError);
	}
	
	////Test a successful callout provoking a generic exception
	static testmethod void testAuthenticateUserUnknownError() {
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		//Provoke generic exception not mocking a response
		Test.startTest();
		SAMInterfaceHTTP.authenticateUserResponse authResponse = SAMInterfaceHTTP.callAuthenticateUser('test', 'test');
		Test.stopTest();
		
		System.assertEquals(authResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.FAIL);
		System.assertEquals(authResponse.message, Label.UnknownCommunicationError);
	}
	
	//Test a successful callout to bulk update
	static testmethod void testBulkUpdate() {
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('SAMAuthenticationCredentialsError');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		SAMInterfaceHTTP.bulkUpdateResponse buResponse = SAMInterfaceHTTP.callBulkUpdate(new Set<String>{'guid1', 'guid2'}, 'test');
		Test.stopTest();
		
		System.assertEquals(buResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.SUCCESS);
		System.assertEquals(buResponse.message, null);
	}
	
	//Try to bulkUpdate without custom settings
	static testmethod void testBulkUpdateNoSettings() {
		
		Test.startTest();
		SAMInterfaceHTTP.bulkUpdateResponse buResponse = SAMInterfaceHTTP.callBulkUpdate(new Set<String>{'guid1', 'guid2'}, 'test');
		Test.stopTest();
		
		System.assertEquals(buResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.INCOMPLETESETTINGS);
		System.assertEquals(buResponse.message, Label.UnknownError);
	}
	
	////Test a successful callout provoking a generic exception
	static testmethod void testBulkUpdateUnknownError() {
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		//Provoke generic exception not mocking a response
		Test.startTest();
		SAMInterfaceHTTP.bulkUpdateResponse buResponse = SAMInterfaceHTTP.callBulkUpdate(new Set<String>{'guid1', 'guid2'}, 'test');
		Test.stopTest();
		
		System.assertEquals(buResponse.statusCode, SAMInterfaceHTTP.ResponseStatusCodes.FAIL);
		System.assertEquals(buResponse.message, Label.UnknownCommunicationError);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - test getSAMUserDetails
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testmethod void testChangeSubscriberPassword() {
		TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
		Test.startTest();
			SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(tdu.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
			String result = SAMInterfaceHTTP.resetPassword('test@test.com', 'TEST_GUID');
		Test.stopTest();
		System.assertNotEquals(Label.Password_change_request_success,result);
	}
}