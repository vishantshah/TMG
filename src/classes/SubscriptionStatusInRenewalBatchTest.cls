/**
* @author Cristina Anghenie
* @date Unknown
* @description Test class for SubscriptionStatusInRenewalBatch
#############Change Log#############
Modified by         Version     Change Date
Wiktor Czykin       1.1         29/02/2016  //modified testSubscriptionStatusMovedToInRenewal();
Pawel Chrzanowski   1.2         25/05/2016  //modified testSubscriptionStatusMovedToInRenewal();
Wiktor Czykin       1.3         04/01/2017  //modified testSubscriptionStatusMovedToInRenewal() and added testSubscriptionStatusMovedToInRenewalFailure()
Wiktor Czykin       1.4         01/03/2017  //modified testSubscriptionStatusMovedToInRenewal() and testSubscriptionStatusMovedToInRenewalFailure()
**/
@isTest
private class SubscriptionStatusInRenewalBatchTest {

	/************************************************************************************
    Developer - Cristina Anghenie
    Date - 27/11/2015
    Version - 1.4
    Function - test batch
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         29/02/2016  //fixed for leap year
    Pawel Chrzanowski   1.2         25/05/2016  //added coverage
    Wiktor Czykin       1.3         04/01/2017  //fixed the leap year fix
    Wiktor Czykin       1.4         01/03/2017  //fix for the fix for the fix :D
    *************************************************************************************/
    static testMethod void testSubscriptionStatusMovedToInRenewal() {
        TestDataUtility tdu = new TestDataUtility(4);
        tdu.createSubscriptions();

        Boolean bAddDays = Math.mod(System.today().addYears(-1).year(), 4) == 0 && System.today().addYears(-1).month() < 3;

        tdu.lstSubscriptions[0].Start_Date__c = System.today().addYears(-1).addDays(80);
        if(bAddDays){
            tdu.lstSubscriptions[0].Start_Date__c = tdu.lstSubscriptions[0].Start_Date__c.addDays(1);
        }
        tdu.lstSubscriptions[0].isContinuous__c = false;
        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_ACTIVE;
        

        tdu.lstSubscriptions[1].Start_Date__c = System.today().addYears(-1).addDays(45);
        if(bAddDays){
            tdu.lstSubscriptions[1].Start_Date__c = tdu.lstSubscriptions[1].Start_Date__c.addDays(1);
        }
        tdu.lstSubscriptions[1].isContinuous__c = false;
        tdu.lstSubscriptions[1].Payment_Type__c = Constants.SUB_PMETHOD_DD;
        tdu.lstSubscriptions[1].Subscription_Status__c = Constants.SSTATUS_ACTIVE;

        tdu.lstSubscriptions[2].Start_Date__c = System.today().addYears(-1).addDays(45);
        if(bAddDays){
            tdu.lstSubscriptions[2].Start_Date__c = tdu.lstSubscriptions[2].Start_Date__c.addDays(1);
        }
        tdu.lstSubscriptions[2].isContinuous__c = true;
        tdu.lstSubscriptions[2].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[2].Subscription_Status__c = Constants.SSTATUS_ACTIVE;

        List<Subscription__c> lstToUpdate = new List<Subscription__c>{tdu.lstSubscriptions[0],  tdu.lstSubscriptions[1], tdu.lstSubscriptions[2]};
        update lstToUpdate;

        Set<Id> subsToUpdateIds = new Set<Id>{tdu.lstSubscriptions[0].Id,tdu.lstSubscriptions[1].Id,tdu.lstSubscriptions[2].Id};
        Test.startTest();
	        SubscriptionStatusInRenewalBatch batchCls = new SubscriptionStatusInRenewalBatch(0, true);
	        Database.executeBatch(batchCls);
	    Test.stopTest();

	    Subscription__c[] subs = [SELECT Subscription_Status__c FROM Subscription__c WHERE Id IN: subsToUpdateIds];
	    System.assertEquals(3,subs.size());
	    System.assertEquals(Constants.SSTATUS_IN_RENEWAL, subs[0].Subscription_Status__c);
	    System.assertEquals(Constants.SSTATUS_IN_RENEWAL, subs[1].Subscription_Status__c);
	    System.assertEquals(Constants.SSTATUS_IN_RENEWAL, subs[2].Subscription_Status__c);
	    Subscription__c sub = [SELECT Subscription_Status__c FROM Subscription__c WHERE Id =: tdu.lstSubscriptions[3].Id];
	    System.assertEquals(Constants.SSTATUS_ACTIVE, sub.Subscription_Status__c);
    }

    /************************************************************************************
    Developer - Wiktor Czykin   
    Date - 05/11/2015
    Version - 1.1
    Function - test negative - nothing updated even if one succeeded
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         01/03/2017  //fix for the fix 
    *************************************************************************************/
    static testMethod void testSubscriptionStatusMovedToInRenewalFailure() {
        TestDataUtility tdu = new TestDataUtility(4);

        tdu.createSubscriptions();

        Boolean bAddDays = Math.mod(System.today().addYears(-1).year(), 4) == 0 && System.today().addYears(-1).month() < 3;


        tdu.lstSubscriptions[0].Start_Date__c = System.today().addYears(-1).addDays(80);
        if(bAddDays){
            tdu.lstSubscriptions[0].Start_Date__c = tdu.lstSubscriptions[0].Start_Date__c.addDays(1);
        }
        tdu.lstSubscriptions[0].isContinuous__c = false;
        tdu.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_ACTIVE;
        

        tdu.lstSubscriptions[1].Start_Date__c = System.today().addYears(-1).addDays(45);
        if(bAddDays){
            tdu.lstSubscriptions[1].Start_Date__c = tdu.lstSubscriptions[1].Start_Date__c.addDays(1);
        }
        tdu.lstSubscriptions[1].isContinuous__c = false;
        tdu.lstSubscriptions[1].Payment_Type__c = Constants.SUB_PMETHOD_DD;
        tdu.lstSubscriptions[1].Subscription_Status__c = Constants.SSTATUS_ACTIVE;


        List<Subscription__c> lstToUpdate = new List<Subscription__c>{tdu.lstSubscriptions[0],  tdu.lstSubscriptions[1]};
        update lstToUpdate;
        tdu.lstZProducts[0].Voucher_Delivery_Type__c = 'OTC';
        update tdu.lstZProducts;

        Set<Id> subsToUpdateIds = new Set<Id>{tdu.lstSubscriptions[0].Id,tdu.lstSubscriptions[1].Id};
        Test.startTest();
            SubscriptionStatusInRenewalBatch batchCls = new SubscriptionStatusInRenewalBatch(0, true);
            batchCls.bFailTest = true;
            Database.executeBatch(batchCls);
        Test.stopTest();

        Map<Id, Subscription__c> subs = new Map<Id, Subscription__c>([SELECT Subscription_Status__c FROM Subscription__c WHERE Id IN: subsToUpdateIds]);
        System.assertEquals(2,subs.size());
        System.assertEquals(Constants.SSTATUS_ACTIVE, subs.get(tdu.lstSubscriptions[0].Id).Subscription_Status__c);
        System.assertEquals(Constants.SSTATUS_ACTIVE, subs.get(tdu.lstSubscriptions[1].Id).Subscription_Status__c);
    }
}

