/*
 * File Name   : OpenByIdComponentControllerTest
 * Description : Test class for OpenByIdComponentController
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 * 1.1 12/07/2015 CRISTINA ANG.	 Clean up code and remove reference to WebPackActionsTestData
 */ 
@isTest
public class OpenByIdComponentControllerTest {
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Test the open by id remote query with a valid result
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testmethod void testDoOpenByIdCorrect() {
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();
		Account testAccount = [Select Name from Account where Id = :td.lstIndividualSubscribers[0].Id];
		String searchTopic = testAccount.Id;
		Test.startTest();
			OpenByIdComponentController.resultWrapper result = OpenByIdComponentController.doOpenById(searchTopic);
		Test.stopTest();
		
		System.assertEquals(testAccount.Id, result.resultId);
		System.assertEquals(testAccount.Name, result.resultName);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Test the open by id remote query with a valid result with a case record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testmethod void testDoOpenByIdCorrectCase() {
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();
		Account testAccount = [Select Name from Account where Id = :td.lstIndividualSubscribers[0].Id];
		Case testCase = new Case(AccountId = testAccount.Id);
		insert testCase;
		testCase = [Select CaseNumber, AccountId, Account.Name from Case where Id = :testCase.Id];
		String searchTopic = testCase.Id;
		Test.startTest();
			OpenByIdComponentController.resultWrapper result = OpenByIdComponentController.doOpenById(searchTopic);
		Test.stopTest();
		
		System.assertEquals(testCase.Id, result.resultId);
		System.assertEquals(testCase.CaseNumber, result.resultName);
		System.assertEquals(testAccount.Id, result.accountId);
		System.assertEquals(testAccount.Name, result.accountName);
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Test the open by id remote query with an invalid result
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testmethod void testDoOpenByIdError() {
		String searchTopic = 'INVALID_ID';
		Test.startTest();
			OpenByIdComponentController.resultWrapper result = OpenByIdComponentController.doOpenById(searchTopic);
		Test.stopTest();
		
		System.assertEquals(null, result);
	}
}