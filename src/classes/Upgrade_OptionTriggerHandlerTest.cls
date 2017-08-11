/*
 * File Name   : Upgrade_OptionTriggerHandlerTest
 * Description : Test class for Upgrade_OptionTriggerHandler
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 * 1.1 12/07/2015 CRISTINA ANG.	 Clean up code and remove reference to WebPackActionsTestData
 */
@isTest
private class Upgrade_OptionTriggerHandlerTest {

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Insert successfully a Upgrade_Option__c record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
    static testMethod void testUpgradeOptionsTriggerInsertSuccess() {
		TestDataUtility td = new TestDataUtility(1);
		td.createUpgradeOptions();
		
		System.assertEquals([Select count() from Pricing_Options__c], 2);
		System.assertEquals([Select count() from Upgrade_Option__c], 1);	
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - test validation errors when inserting a Upgrade_Option__c record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testMethod void testUpgradeOptionsTriggerInsertError() {
		TestDataUtility td = new TestDataUtility(1);
		Test.startTest();
			td.createUpgradeOptions();
			Pricing_Options__c[] pos = [SELECT Id FROM Pricing_Options__c];
			System.assertEquals(pos.size(), 2);
			Upgrade_Option__c[] upOption = [Select Pricing_Option_To__c,Pricing_Option_From__c from Upgrade_Option__c limit 1];
			System.assertEquals(upOption.size(), 1);
			TestDataUtility.newUpgradeOptions(1, upOption[0].Pricing_Option_From__c, upOption[0].Pricing_Option_To__c);
		Test.stopTest();
		System.assertEquals([Select count() from Upgrade_Option__c], 1);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Update successfully a Upgrade_Option__c record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testMethod void testUpgradeOptionsTriggerUpdateSuccess() {
		TestDataUtility td = new TestDataUtility(3);
		td.createPricingOptions(null);
		Pricing_Options__c[] pos = [SELECT Id FROM Pricing_Options__c];
		System.assertEquals(pos.size(), 3);
		td.createUpgradeOptions();
		
		td.lstUpgradeOptions[0].Pricing_Option_To__c = pos[2].Id;
		update td.lstUpgradeOptions[0];
		
		System.assertEquals([Select Pricing_Option_To__c from Upgrade_Option__c limit 1][0].Pricing_Option_To__c, pos[2].Id);	
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - test validation errors when updating a Upgrade_Option__c record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testMethod void testUpgradeOptionsTriggerUpdateError() {
		TestDataUtility td = new TestDataUtility(3);
		Test.startTest();
			td.createUpgradeOptions();
			Pricing_Options__c[] pos = [SELECT Id FROM Pricing_Options__c];
			System.assertEquals(pos.size(), 6);
			System.assertEquals([SELECT count() FROM Upgrade_Option__c], 3);
			
			td.lstUpgradeOptions[1].Pricing_Option_To__c = pos[1].Id;
			update td.lstUpgradeOptions[0];
			
		Test.stopTest();
		Upgrade_Option__c uo = [SELECT Pricing_Option_From__c, Pricing_Option_To__c FROM Upgrade_Option__c WHERE Id = :td.lstUpgradeOptions[1].Id];
		System.assertNotEquals(uo.Pricing_Option_From__c, pos[2].Id);
		System.assertNotEquals(uo.Pricing_Option_To__c, pos[3].Id);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Undelete successfully a Upgrade_Option__c record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testMethod void testUpgradeOptionsTriggerUndeleteSuccess() {
		TestDataUtility td = new TestDataUtility(1);
		td.createUpgradeOptions();
		
		System.assertEquals([Select count() from Pricing_Options__c], 2);
		System.assertEquals([Select count() from Upgrade_Option__c], 1);
		
		delete td.lstUpgradeOptions[0];
		System.assertEquals([Select count() from Upgrade_Option__c], 0);
		undelete td.lstUpgradeOptions[0];
		System.assertEquals([Select count() from Upgrade_Option__c], 1);	
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - test validation errors when undeleting a Upgrade_Option__c record
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testMethod void testUpgradeOptionsTriggerUndeleteError() {
		TestDataUtility td = new TestDataUtility(1);
		Test.startTest();
			td.createUpgradeOptions();
			Pricing_Options__c[] pos = [Select Id from Pricing_Options__c];
			System.assertEquals(pos.size(), 2);
			System.assertEquals([Select count() from Upgrade_Option__c], 1);
			
			delete td.lstUpgradeOptions[0];
			System.assertEquals([Select count() from Upgrade_Option__c], 0);
			insert TestDataUtility.newUpgradeOptions(1, td.lstUpgradeOptions[0].Pricing_Option_From__c, td.lstUpgradeOptions[0].Pricing_Option_To__c);
			System.assertEquals([Select count() from Upgrade_Option__c], 1);
			Boolean errorCaught = false;
			try{
				undelete td.lstUpgradeOptions[0];
			}catch (Exception ex) {
				errorCaught = true;
			}
		Test.stopTest();
		System.assertEquals([Select count() from Upgrade_Option__c], 1);
		System.assert(errorCaught);	
	}
}