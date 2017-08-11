@isTest
private class CreditCardExpiryDateSchedulerTest {
    
    public static String CRON_EXP = '0 0 21 ? * SUN *';
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 17/11/2015
    Version - 1.0
    Function - test scheduling batch to run every sunday at 9PM
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCreditCardExpiryDateScheduler(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.loadGeneral();
        Test.startTest();
            Id jobId = System.schedule('testCreditCardExpiryDateScheduler', CRON_EXP, new CreditCardExpiryDateScheduler());
        Test.stopTest();
        List<CronTrigger> ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assert(!ct.isEmpty());
        System.assertEquals(ct[0].CronExpression, CRON_EXP);
    }
}