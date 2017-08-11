/**
* Author:       Unknown
* Date:         Unknown
* Description:  subscriber console helper webservice class tests
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin		23/02/2016	//removed references to old methods from TestDataUtility 
*/
@isTest(SeeAllData=false)
public with sharing class subscriberConsoleWebserviceTest {

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			24/02/2016	//changed TestDataUtility calls to make sure test works as well after try catch removal
    ****************************************************************************************/
	public static testMethod void testSubscriberOverviewDigital() {
		TestDataUtility td = new TestDataUtility();
		td.checkAccountDependencies();
		td.loadSubscriberValidationRuleInfo();
		Account thisAccount = setUpTestDataDigital();	
		subscriberConsoleWebservice.subscriberIdentifier subIdentifier = new subscriberConsoleWebservice.subscriberIdentifier('TSNUMBER','TS9899999');
		Test.startTest();
			subscriberConsoleWebservice.subscriberOverviewResult subscriberOverviewResult = subscriberConsoleWebservice.subscriberOverview(subIdentifier);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			24/02/2016	//changed TestDataUtility calls to make sure test works as well after try catch removal
    ****************************************************************************************/
	public static testMethod void testSubscriberOverviewPrint() {
		TestDataUtility td = new TestDataUtility();
		td.checkAccountDependencies();
		td.loadSubscriberValidationRuleInfo();
		Account thisAccount = setUpTestDataPrint();	
		subscriberConsoleWebservice.subscriberIdentifier subIdentifier = new subscriberConsoleWebservice.subscriberIdentifier('TSNUMBER','TS9899999');
		Test.startTest();
			subscriberConsoleWebservice.subscriberOverviewResult subscriberOverviewResult = subscriberConsoleWebservice.subscriberOverview(subIdentifier);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			24/02/2016	//changed TestDataUtility calls to make sure test works as well after try catch removal
    ****************************************************************************************/
	public static testMethod void testSubscriberOverviewNoData() {
		TestDataUtility td = new TestDataUtility();
		td.checkAccountDependencies();
		td.loadSubscriberValidationRuleInfo();
		Account thisAccount = setUpTestDataDigital();	
		subscriberConsoleWebservice.subscriberIdentifier subIdentifier = new subscriberConsoleWebservice.subscriberIdentifier('TSNUMBER','TS');
		Test.startTest();
			subscriberConsoleWebservice.subscriberOverviewResult subscriberOverviewResult = subscriberConsoleWebservice.subscriberOverview(subIdentifier);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			24/02/2016	//changed TestDataUtility calls
    ****************************************************************************************/
	public static Account setUpTestDataDigital(){
		TestDataUtility td = new TestDataUtility(1);
		td.createDigitalMPPTransactionHistory(Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE);
		return td.lstDigitalSubscribers[0]; 
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			24/02/2016	//changed TestDataUtility calls
    ****************************************************************************************/
	public static Account setUpTestDataPrint() {
		TestDataUtility td = new TestDataUtility(1);
		td.createMPPTransactionHistory(Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE);
		return td.lstIndividualSubscribers[0];
	}  

}