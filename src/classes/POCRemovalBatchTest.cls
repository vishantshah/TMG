/**
Name: SubscriptionStatusUpdateBatchTest
* @author Mateusz Michalczyk
* @date 13/03/2015
* @description 	Tests for POCRemovalBatch & POCRemovalBatchController.
##########Change Log##########
Modified by     Version     Change Date
Wiktor Czykin 	1.1			01/05/2015	//simpliied 
*/
@isTest
private class POCRemovalBatchTest {
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 01/05/2015
    Version - 1.0 
    Function - just check creation of pocs
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void setupBatchDataTest() {
		TestDataUtility td = new TestDataUtility(5);
		Test.startTest();
 			td.createPOCs(5);
		Test.stopTest();
		System.assertEquals(5, Database.countQuery('SELECT COUNT() FROM TCodeManagement__c'));
		System.assertEquals(5, Database.countQuery('SELECT COUNT() FROM POC__c WHERE TCodeManagement__c =\''+td.lstTCodeManagement[0].Id+'\''));
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 01/05/2015
    Version - 1.0 
    Function - test delete of pocs related to 4 different tcodes
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testPOCDeletionBatch(){
		TestDataUtility td = new TestDataUtility(4);
		td.createPOCs(50);
		Test.startTest();
			POCRemovalBatch batchClass = new POCRemovalBatch(new List<Id> {td.lstTCodeManagement[0].Id, td.lstTCodeManagement[1].Id, td.lstTCodeManagement[2].Id, td.lstTCodeManagement[3].Id} , 200);
			Database.executeBatch(batchClass, 200);
		Test.stopTest();
		List<TCodeManagement__c> lstTemp = td.lstTCodeManagement;
		System.assertEquals(0, Database.countQuery('SELECT COUNT() FROM POC__c WHERE TCodeManagement__c in :lstTemp'));		
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 01/05/2015
    Version - 1.0 
    Function - test schedulable for poc delete
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testPOCDeletionScheduledBatch(){
		TestDataUtility td = new TestDataUtility(4);
		td.createPOCs(50);
		Test.startTest();
        	String sCron = System.now().addMinutes(1).format('ss mm HH dd MM ? yyyy');
			POCRemovalBatch batchClass = new POCRemovalBatch(new List<Id> {td.lstTCodeManagement[0].Id, td.lstTCodeManagement[1].Id, td.lstTCodeManagement[2].Id, td.lstTCodeManagement[3].Id} , 200);
			System.schedule(td.lstTCodeManagement[0].Id+'POCRemovalBatch', sCron, batchClass);
		Test.stopTest();
	}
}