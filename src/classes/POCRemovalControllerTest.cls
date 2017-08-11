/**
Name: SubscriptionStatusUpdateBatchTest
* @author Wiktor Czykin
* @date 10/04/2015
* @description 	Split tests into 2 respective classes
##########Change Log##########
Modified by     Version     Change Date 
*/
@isTest
private class POCRemovalControllerTest {

	/*************************************************************************************** 
    Developer - Mateusz Michalczyk (Tquila)
    Date - 12/03/2015
    Version - 1.1
    Function - simple delete test 
    #############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin 	1.1			01/05/2015	//refactored
    ****************************************************************************************/
	private static testMethod void testPOCDeletionScheduling(){
		TestDataUtility td = new TestDataUtility(1);
		td.createPOCs(5);

		Test.startTest();
			POCRemovalController controller = new POCRemovalController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
			controller.deletePOCs();
			System.assertNotEquals(null, controller.goBackToTCode());
		Test.stopTest();
		System.assertEquals(1, Database.countQuery('select count() from CronTrigger where CronJobDetail.Name=\''+td.lstTCodeManagement[0].Id+'POCRemovalBatch\''));
	}

	/*************************************************************************************** 
    Developer - Mateusz Michalczyk (Tquila)
    Date - 12/03/2015
    Version - 1.1
    Function - negative test to prevent scheduling the same delete twice in the same time
    #############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin 	1.1			01/05/2015	//refactored
    ****************************************************************************************/
	private static testMethod void testPOCDeletionOnTheSameTCodeTwice(){
		TestDataUtility td = new TestDataUtility(1);
		td.createPOCs(5);

		Test.startTest();
			POCRemovalController controller = new POCRemovalController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
			DateTime currentTime = System.now().addMinutes(1);
        	String sCRON = currentTime.format('ss mm HH dd MM ? yyyy');
        	POCRemovalBatch batchClass = new POCRemovalBatch(new List<Id> {td.lstTCodeManagement[0].Id} , 200);
			Id batchID = System.schedule(td.lstTCodeManagement[0].Id+'POCRemovalBatch', sCRON, batchClass);
			controller.deletePOCs();
		Test.stopTest();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.POC_Deletion_TCode_Being_Processed));
	}

	/*************************************************************************************** 
    Developer - Mateusz Michalczyk (Tquila)
    Date - 12/03/2015
    Version - 1.1
    Function - 
    #############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin 	1.1			01/05/2015	//refactored
    ****************************************************************************************/
	private static testMethod void testScheduledJobsLimitBasedOnSFDCLimit(){
		TestDataUtility td = new TestDataUtility(1);
		td.createPOCs(10);

		Test.startTest();
			POCRemovalController controller = new POCRemovalController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
			Integer amountOfJobsInProcess = Database.countQuery('select count() from CronTrigger where State!=\'Deleted\'');
			DateTime currentTime = System.now().addMinutes(1);
        	String sCRON = currentTime.format('ss mm HH dd MM ? yyyy');
        	POCRemovalBatch batchClass = new POCRemovalBatch(new List<Id> {td.lstTCodeManagement[0].Id} , 200);
        	POCRemovalBatch.DONT_RUN_BATCH = true;
			for(Integer i= 0; i<100-amountOfJobsInProcess-5;i++){
				System.schedule(td.lstTCodeManagement[0].Id+'POCRemovalBatch'+i, sCRON, batchClass);
			}
			controller.deletePOCs();
		Test.stopTest();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.POC_Deletion_System_Resources_Error));
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 01/05/2015
    Version - 1.0
    Function - 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testScheduledJobsLimitBasedOnInternalLimit(){
		TestDataUtility td = new TestDataUtility(POCRemovalController.MAX_POC_REMOVAL_JOBS+1);
		td.createPOCs(1);

		Test.startTest();
			Integer amountOfJobsInProcess = Database.countQuery('select count() from CronTrigger where State!=\'Deleted\'');
			DateTime currentTime = System.now().addMinutes(1);
        	String sCRON = currentTime.format('ss mm HH dd MM ? yyyy');
        	POCRemovalBatch.DONT_RUN_BATCH = true;
			for(Integer i= 0; i<td.iCounter;i++){
				POCRemovalController controller = new POCRemovalController(new ApexPages.StandardController(td.lstTCodeManagement[i]));
				controller.deletePOCs();
				if(i == td.iCounter - 1 ){
					System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.POC_Deletion_Too_Many_Jobs));
				}else{
					System.assert(!TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.POC_Deletion_Too_Many_Jobs));
				}
			}
		Test.stopTest();
	}

}