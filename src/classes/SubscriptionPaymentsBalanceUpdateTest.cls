/************************************************************************************
Class Name   : SubscriptionPaymentsBalanceUpdateTest
Author       : Mantas Grigaliunas
Created Date : 16/01/2017
Function     : Unit Test class for SubscriptionPaymentsBalanceUpdateBatch and SubscriptionPaymentsBalanceUpdtScheduler
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
private class SubscriptionPaymentsBalanceUpdateTest {
	
   	//CRON expression: midnight on March 15.
   	public static String CRON_EXP = '0 0 0 15 3 ? 2022';
   	public static Integer RECORDS_SIZE = 3;

    /************************************************************************************
    Method Name  : testSetup
    Author       : Mantas Grigaliunas
    Created Date : 16/01/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
   	@testSetup static void testSetup(){
   		TestDataUtility td = new TestDataUtility(RECORDS_SIZE);
        td.createMPPTransactionHistory(TestDataUtility.PAYMENTMETHOD_DD);
   	}


    /************************************************************************************
    Method Name  : subscriptionPaymentBalanceUpdateTest
    Author       : Mantas Grigaliunas
    Created Date : 16/01/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
   	@isTest static void subscriptionPaymentBalanceUpdateTest(){

   		Test.startTest();

   		//check if MPP Historic Transaction records inserted
   		List<MPP_Transaction_History__c> lstMpp = [ SELECT Id, Payment_Date__c, Total_Price__c, Subscription__c FROM MPP_Transaction_History__c];
   		System.assertEquals(RECORDS_SIZE, lstMpp.size());

   		//declare subscription with mpp payment amount map
   		Map<Id, Decimal> totalPriceMap = new Map<Id, Decimal>();
   		for(MPP_Transaction_History__c mpp : lstMpp){
   			totalPriceMap.put(mpp.Subscription__c, mpp.Total_Price__c);
   			//set the payment day to five days back
   			mpp.Payment_Date__c = Date.today().addDays(-5);
   		}

      	//Verify subscriptions are updated with expected sums
   	    for(Subscription__c sub : [ SELECT Id, DD_Not_Completed_Payments_Sum__c FROM Subscription__c WHERE Id IN :totalPriceMap.keySet()]){
   			System.assertEquals(totalPriceMap.get(sub.Id), sub.DD_Not_Completed_Payments_Sum__c);
   		}

   		//update mpp payments with the new payment date so these records are picked up by batch job
   		update lstMpp;

	    //Schedule the test job
	    String jobId = System.schedule('SubscriptionPaymentsBalanceUpdtSchedulerTest', CRON_EXP, new SubscriptionPaymentsBalanceUpdtScheduler());

      	// Because this is a test, job executes immediately after Test.stopTest().
      	Test.stopTest();

      	//check if DD_Not_Completed_Payments_Sum__c was updated with a new balance
      	for(Subscription__c sub : [ SELECT Id, DD_Not_Completed_Payments_Sum__c FROM Subscription__c WHERE Id IN :totalPriceMap.keySet()]){
   			System.assertEquals(0, sub.DD_Not_Completed_Payments_Sum__c);
   		}
   	}
	
}