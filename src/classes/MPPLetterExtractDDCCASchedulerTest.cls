/**
* @author Unknown
* @date Unknown
* @description Test scheduler for DDCCA MPP letter extract
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         27/10/2015  //simplified, rewritten mostly
**/
@isTest
private class MPPLetterExtractDDCCASchedulerTest{
		
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 27/10/2015
    Version - 1.0
    Function - test run without custom settings available
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSchedulerWithoutCustomSettings(){
		Test.startTest();
			Id jobId = System.schedule('mppLettersSchedulerTest', '00 50 * * * ? *', new MPPLetterExtractDDCCAScheduler());
		Test.stopTest();
		List<CronTrigger> ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
		System.assert(!ct.isEmpty());
		System.assertEquals(ct[0].CronExpression, '00 50 * * * ? *');
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 27/10/2015
    Version - 1.0
    Function - test run with custom settings available
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSchedulerWithCustomSettings(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadGeneral();
		Test.startTest();
			Id jobId = System.schedule('mppLettersSchedulerTest', '00 50 * * * ? *', new MPPLetterExtractDDCCAScheduler());
		Test.stopTest();
		List<CronTrigger> ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
		System.assert(!ct.isEmpty());
		System.assertEquals(ct[0].CronExpression, '00 50 * * * ? *');
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 27/10/2015
    Version - 1.0
    Function - test run with forced error
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSchedulerWithCustomSettingsIssue(){
		Test.startTest();
			MPPLetterExtractDDCCAScheduler.bTestError = true;
			Id jobId = System.schedule('mppLettersSchedulerTest', '00 50 * * * ? *', new MPPLetterExtractDDCCAScheduler());
			System.assertNotEquals(null, jobId);
			List<CronTrigger> ct = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
			System.assert(!ct.isEmpty());
		Test.stopTest();
	}
}