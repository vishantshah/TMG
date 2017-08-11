/**
* @author Wiktor Czykin(Tquila)
* @date 16/02/2015
* @description 	Test class for SubscribersRetailerRelinkController
#############Change Log#############
Modified by     Version     Change 
**/
@isTest
private class SubscribersRetailerRelinkControllerTest {

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - test constructor logic
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testConstructor(){
		TestDataUtility td = new TestDataUtility(5);
		td.createSubscriptions();
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(td.lstRetailers[0]);
			SubscribersRetailerRelinkController contr = new SubscribersRetailerRelinkController(std);
		Test.stopTest();	
		System.assert(!contr.bSuccess);
		System.assertEquals(1, contr.iCurrentCount);
		System.assertNotEquals(null, contr.subscription);

	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - test positive relinking
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testRelinkingPositive(){
		TestDataUtility td = new TestDataUtility(2);
		td.createSubscriptions();
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(td.lstRetailers[0]);
			SubscribersRetailerRelinkController contr = new SubscribersRetailerRelinkController(std);

			System.assert(!contr.bSuccess);
			System.assertEquals(1, contr.iCurrentCount);
			System.assertNotEquals(null, contr.subscription);

			contr.subscription.Retailer__c = td.lstRetailers[1].Id;
			contr.relinkSubscribers();

			System.assert(contr.bSuccess, ApexPages.getMessages());
			System.assertEquals(0, contr.iCurrentCount);
			
			contr.acc.Id = td.lstRetailers[1].Id;
			contr.resetRecordsCount();
			System.assertEquals(2, contr.iCurrentCount);
		Test.stopTest();	
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - test negative - exception
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testRelinkingException(){
		TestDataUtility td = new TestDataUtility(2);
		td.createSubscriptions();
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(td.lstRetailers[0]);
			SubscribersRetailerRelinkController contr = new SubscribersRetailerRelinkController(std);

			System.assert(!contr.bSuccess);
			System.assertEquals(1, contr.iCurrentCount);
			System.assertNotEquals(null, contr.subscription);

			contr.subscription.Retailer__c = td.lstSubscriptions[1].Id;
			contr.relinkSubscribers();
			System.assert(ApexPages.hasMessages());
			
		Test.stopTest();	
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - test negative scenarios:
    			- no retailer
    			- same retailer
    			- nothing to relink
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testRelinkingNegative(){
		TestDataUtility td = new TestDataUtility(2);
		td.createRetailers();
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(td.lstRetailers[0]);
			SubscribersRetailerRelinkController contr = new SubscribersRetailerRelinkController(std);

			System.assert(!contr.bSuccess);
			System.assertEquals(0, contr.iCurrentCount);
			System.assertNotEquals(null, contr.subscription);

			contr.subscription.Retailer__c = null;
			contr.relinkSubscribers();
			TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Retailer_Target_not_specified);

			contr.subscription.Retailer__c = td.lstRetailers[0].Id;
			contr.relinkSubscribers();
			TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Retailer_Target_has_to_be_different);

			contr.subscription.Retailer__c = td.lstRetailers[1].Id;
			contr.relinkSubscribers();
			TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Retailer_Target_has_to_be_different);

			System.assert(!contr.bSuccess);
			System.assertEquals(0, contr.iCurrentCount);
		Test.stopTest();	
	}

	
}