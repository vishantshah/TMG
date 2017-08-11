/*
 * File Name   : AutoSubscriberSearchComponentTest
 * Description : Test class for AutoSubscriberSearchComponentController
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 * 1.1 12/07/2015 CRISTINA ANG.	 Clean up code and remove reference to WebPackActionsTestData
 */ 
@isTest
public class AutoSubscriberSearchComponentTest {
	
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Test the open by id remote query with an invalid result
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testmethod void testDoTSNumberAutoCompleteCorrect() {
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();
		List<Id> fixedSearchResults= new List<Id>{td.lstIndividualSubscribers[0].Id};	
		Test.setFixedSearchResults(fixedSearchResults);
		Test.startTest();
			List<Account> resultList = AutoSubscriberSearchComponentController.doAutoCompleteSearch('test');
		Test.stopTest();
		
		System.assertEquals(resultList.size(), 1);
		System.assertEquals(resultList[0].Id, td.lstIndividualSubscribers[0].Id);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Test the open by id remote query with an invalid result
    #############Change Log#############
    Modified by     	Version     Change Date
    ****************************************************************************************/
	static testmethod void testDoTSNumberAutoCompleteError() {

		Test.startTest();
		List<Account> resultList = AutoSubscriberSearchComponentController.doAutoCompleteSearch('test');
		Test.stopTest();
		
		System.assertEquals(resultList, null);
	}
}