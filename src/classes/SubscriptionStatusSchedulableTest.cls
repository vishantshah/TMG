/**
Name: SubscriptionStatusSchedulableTest
* @author Wiktor Czykin
* @date 31/03/2015
* @description 	Tests for SubscriptionStatusSchedulable
##########Change Log##########
Modified by     Version     Change Date
Wiktor Czykin	1.1			13/04/2015 //added testGoWithParam()
*/
@isTest
private class SubscriptionStatusSchedulableTest {

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 01/04/2015
    Version - 1.0
    Function - test that job is scheduled correctly
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testGo(){
		Test.startTest();
			SubscriptionStatusSchedulable.go();
		Test.stopTest();	
		String sJobName = 'Test'+SubscriptionStatusSchedulable.JOBNAME;
		List<CronJobDetail> lstJobs = [select Id from CronJobDetail where Name = :sJobName];
		System.assert(!lstJobs.isEmpty());
		System.assertEquals(1, lstJobs.size());
		List<CronTrigger> lstCron = [select Id, CronExpression from CronTrigger where CronJobDetailId = :lstJobs[0].Id];
		System.assert(!lstCron.isEmpty());
		System.assertEquals(SubscriptionStatusSchedulable.CRON, lstCron[0].CronExpression);
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 13/04/2015
    Version - 1.0
    Function - test that job is scheduled correctly with param
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testGoWithParam(){
		Test.startTest();
			SubscriptionStatusSchedulable.go(5);
		Test.stopTest();	
		String sJobName = 'Test'+SubscriptionStatusSchedulable.JOBNAME+'_5';
		List<CronJobDetail> lstJobs = [select Id from CronJobDetail where Name = :sJobName];
		System.assert(!lstJobs.isEmpty());
		System.assertEquals(1, lstJobs.size());
		List<CronTrigger> lstCron = [select Id, CronExpression from CronTrigger where CronJobDetailId = :lstJobs[0].Id];
		System.assert(!lstCron.isEmpty());
		System.assertEquals(SubscriptionStatusSchedulable.CRON, lstCron[0].CronExpression);
	}
}