/***************************************************************************************
* @author Cristina Popescu
* @date 16/10/2015
* @description
#############Change Log#############
Modified by     Change Date
Wiktor Czykin   30/12/2016  //added coverage for new constructor
****************************************************************************************/
@isTest
private class SubscriptionStatusInRenewalSchedulerTest {

    public static String CRON_EXP = '0 0 00 ? * SAT *';

    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 27/11/2015
    Version - 1.0
    Function - test scheduling batch to run every saturday at 00 AM
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testSubscriptionStatusInRenewalScheduler(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        Test.startTest();
            Id jobId = System.schedule('testSubscriptionStatusInRenewalScheduler', CRON_EXP, new SubscriptionStatusInRenewalScheduler());
        Test.stopTest();
        List<CronTrigger> ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assert(!ct.isEmpty());
        System.assertEquals(ct[0].CronExpression, CRON_EXP);
    }

    /************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/12/2016
    Version - 1.0
    Function - test scheduling batch with different constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testSubscriptionStatusInRenewalSchedulerOtherConstructor(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        Test.startTest();
            Id jobId = System.schedule('testSubscriptionStatusInRenewalScheduler', CRON_EXP, new SubscriptionStatusInRenewalScheduler(1, 1, true));
            Id jobId2 = System.schedule('testSubscriptionStatusInRenewalScheduler2', CRON_EXP, new SubscriptionStatusInRenewalScheduler(1, null, true));
        Test.stopTest();
        List<CronTrigger> ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id in : new Set<Id>{jobId, jobId2}];
        System.assert(!ct.isEmpty());
        System.assertEquals(ct[0].CronExpression, CRON_EXP);
    }
}
