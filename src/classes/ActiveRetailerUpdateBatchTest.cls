/**
* @author Unknown
* @date Unknown
* @description Test class for ActiveRetailerUpdateBatch and ActiveRetailerUpdateSchedule
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         13/10/2015  //cleaned up, removed old test data creation, removed unnecessary methods
**/
@isTest(SeeAllData=false)
private class ActiveRetailerUpdateBatchTest {

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test scheduler class
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/10/2015  //cleaned-up
    ****************************************************************************************/
	private static testMethod void testActiveRetailerUpdateSchedule() {
	    Test.startTest();
			String nextYear = String.valueof(date.Today().addYears(1).year());
			String jobId = System.schedule('ActiveRetailerUpdateScheduleTest'+Math.random(), '00 50 16 29 AUG ? '+nextYear, new ActiveRetailerUpdateSchedule());
		    List<CronTrigger> ct = [Select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
		    System.assert(!ct.isEmpty());
		Test.stopTest();    
	} 

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test batch job logic 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/10/2015  //cleaned-up, replaced test data creation, added assertions 
    ****************************************************************************************/
	private static testMethod void testActiveRetailerUpdate() {
		TestDataUtility td = new TestDataUtility(200);
		td.createSubscriptions();

		Test.startTest();
			Date dt = Date.today();
			String query = 'Select Retailer__c, Subscriber__r.Retailer_Active_Sub_Count__c, Subscription_Status__c from Subscription__c where Retailer__c != null and Delivery_Type__c =\'HND\' and (Subscription_Status__c = \'Active\' or Subscription_Status__c = \'InRenewal\' or (Subscription_Status__c = \'Pending Cancellation\' and Cancellation_Date__c>:dt)) limit 200';
			ActiveRetailerUpdateBatch batchable = new ActiveRetailerUpdateBatch(query);					
			Id ActiveRetailerUpdateBatchId = Database.executeBatch(batchable, 200);
		Test.stopTest();		

		List<Account> lstAccounts = [select Retailer_Active_Sub_Count__c from Account where Id in :td.lstRetailers];
		System.assert(!lstAccounts.isEmpty(), 'Retailers query did not return anything when it should.');
		for(Account acc : lstAccounts){
			System.assertEquals(1, acc.Retailer_Active_Sub_Count__c);
		}
	}  	

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 13/10/2015
    Version - 1.0
    Function - test batch job logic - failure 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testActiveRetailerUpdateFailure() {
		TestDataUtility td = new TestDataUtility(200);
		td.createSubscriptions();
		td.loadGeneral();
		Test.startTest();
			Date dt = Date.today();
			String query = 'Select Retailer__c, Subscriber__r.Retailer_Active_Sub_Count__c, Subscription_Status__c from Subscription__c where Retailer__c != null and Delivery_Type__c =\'HND\' and (Subscription_Status__c = \'Active\' or Subscription_Status__c = \'InRenewal\' or (Subscription_Status__c = \'Pending Cancellation\' and Cancellation_Date__c>:dt)) limit 200';
			ActiveRetailerUpdateBatch.TEST_FAIL = true;
			ActiveRetailerUpdateBatch batchable = new ActiveRetailerUpdateBatch(query);					
			Id ActiveRetailerUpdateBatchId = Database.executeBatch(batchable, 200);
		Test.stopTest();		

		List<Account> lstAccounts = [select Retailer_Active_Sub_Count__c from Account where Id in :td.lstRetailers];
		System.assert(!lstAccounts.isEmpty(), 'Retailers query did not return anything when it should.');
		for(Account acc : lstAccounts){
			System.assertEquals(null, acc.Retailer_Active_Sub_Count__c);
		}
	}  
}