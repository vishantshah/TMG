/**
* @author Unknown
* @date Unknown
* @description The test class for SubscriptionsCancellationBatch and SubscriptionsCancellationScheduler
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin	1.1			08/01/2016	//modified to fully use TestDataUtility
**/
@isTest(SeeAllData=false)
private class TestSubscriptionsCancellationBatch {

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 08/01/2016
    Version - 1.0
    Function - test init for all methods - replaced old init method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @testSetup static void init(){
    	TestDataUtility tdu = new TestDataUtility(2);
    	tdu.checkSubscriptionDependencies();
    	Subscription__c s1 = TestDataUtility.newSubscripiton(0, tdu.lstIndividualSubscribers[0].Id, tdu.lstRetailers[0].Id, null);
    	Subscription__c s2 = TestDataUtility.newSubscripiton(0, tdu.lstIndividualSubscribers[1].Id, tdu.lstRetailers[1].Id, null);
    	tdu.lstSubscriptions = new List<Subscription__c>{s1, s2};
		for(Subscription__c sub : tdu.lstSubscriptions){
            sub.Cancellation_Reason__c = 'Failed payment';
            sub.Cancellation_Method__c = 'DD Reject';
            sub.Is_MPP_DDCCA_Letter_Extracted__c = false;
            sub.Start_Date__c = Date.today().addDays(-10);
            sub.Cancellation_Date__c = Date.today();
            sub.Current_Week_Position_Final__c = 0;
            sub.isContinuous__c = true;
		}
		tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING_CANX;
		tdu.lstSubscriptions[1].Subscription_Status__c = Constants.SSTATUS_CANX;
		insert tdu.lstSubscriptions; 
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test the normal batch scenario.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			08/01/2016	//removed assertions as had no sense, with enabled workflows there is no way to actually simulate the scenario,
    										as Current_Week_Position_Final__c will always be updated by the workflow first
    ****************************************************************************************/
    private static testmethod void testBatchNormal() {
        Test.startTest();
	        String query = 'SELECT Id, Subscription_Status__c, Current_Week_Position__c, Cancellation_Date__c, Start_Date__c'
	                         + ' FROM Subscription__c'
	                         + ' WHERE Subscription_Status__c IN (\'Pending Cancellation\', \'Cancelled\')'
	                         + ' AND Cancellation_Date__c <= TODAY'; 
	                         
	        List<sObject> scope = Database.query(query + ' limit 2');
	        System.assertEquals(2, scope.size());
       		SubscriptionsCancellationBatch batch = new SubscriptionsCancellationBatch(query);
	        batch.start(null);
	        batch.execute(null, scope);
	        batch.finish(null);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -Test the fail batch scenario.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			08/01/2016	//remove assertions as had no sense, with enabled workflows there is no way to actually simulate the scenario
    ****************************************************************************************/
    private static testmethod void testBatchFail() {
        Test.startTest();
	        String query = 'SELECT Id, Subscription_Status__c, Current_Week_Position__c, Cancellation_Date__c, Start_Date__c'
	                         + ' FROM Subscription__c'
	                         + ' WHERE Subscription_Status__c IN (\'Pending Cancellation\', \'Cancelled\')'
	                         + ' AND Cancellation_Date__c <= TODAY'; 
	                         
	        Map<String, Object> customParams = new Map<String, Object>{'TEST_EXCEPTION' => 'TRUE'};
	        List<sObject> scope = Database.query(query + ' limit 2');
	        SubscriptionsCancellationBatch batch = new SubscriptionsCancellationBatch(query, customParams);
	        try {
	            batch.start(null);
	            batch.execute(null, scope);
	        } catch (Exception e) {
	            system.debug('Caught exception in test class. Re-scheduling ..');
	        } finally {
	            batch.finish(null);
	        }
        Test.stopTest();
    }
}