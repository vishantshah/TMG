/**
Name: SubscriptionStatusQueueableTest
* @author Wiktor Czykin
* @date 31/03/2015
* @description 	Tests for SubscriptionStatusQueueable
##########Change Log##########
Modified by     Version     Change Date
Wiktor Czykin   1.1         25/07/2016  //modified withdrawal related test methods
*/
@isTest
private class SubscriptionStatusQueueableTest {

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.0
    Function - test constructors logic
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testConstructor(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
		td.createSubscriptions();
		Test.startTest();
			//without any parameters
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			System.assertEquals(SubscriptionStatusQueueable.DEFAULT_QUEUE_SIZE+1, ssq.iQueueSize);
			System.assertNotEquals(null, ssq.mapFailedRecords);
			System.assert(ssq.mapFailedRecords.isEmpty());
			//with existing map of errors
			SubscriptionStatusQueueable.SubscriptionStatusQueueableResult ssqr = new SubscriptionStatusQueueable.SubscriptionStatusQueueableResult(null, null, 'some error string');
			Map<Id, SubscriptionStatusQueueable.SubscriptionStatusQueueableResult> mapErrors = new Map<Id, SubscriptionStatusQueueable.SubscriptionStatusQueueableResult>{td.lstSubscriptions[0].Id => ssqr};
			SubscriptionStatusQueueable ssq2 = new SubscriptionStatusQueueable(null, mapErrors);
			System.assertNotEquals(null, ssq2.mapFailedRecords);
			System.assertEquals(1, ssq2.mapFailedRecords.size());
		Test.stopTest();
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.0
    Function - test End Date scenario
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testLapsedOnEndDate(){
		TestDataUtility td = new TestDataUtility(5);
		td.loadGeneral();
		td.loadSAMHTTPSettings();
        td.loadPlaneURL();
		System.assert(General__c.getInstance(Constants.SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK_SETTING) != null, 'setting for end day scenario does not exist');
		System.assert(General__c.getInstance(Constants.SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK_SETTING) != null, 'setting for withdrawal scenario does not exist');

		Date dEndDate = Date.today().addDays(-Constants.SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK);
		td.createSubscriptionsBasedOnEndDate(dEndDate);
		Set<Id> setSubIds = new Set<Id>();
		for(Subscription__c sub : [select Id, End_Date__c from Subscription__c where Id in :td.lstSubscriptions]){
			System.assertEquals(dEndDate, sub.End_Date__c);
			setSubIds.add(sub.Id);
		}
		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			System.enqueueJob(ssq);
		Test.stopTest();
		for(Subscription__c sub : [select Id, Subscription_Status__c from Subscription__c where Id in :setSubIds]){
			System.assertEquals(Constants.SSTATUS_LAPSED, sub.Subscription_Status__c, 'wrong status');
		}
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.0
    Function - test Start Date scenario - with one exlusion by simulated error passed in
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testActivationOnStartDate(){
		TestDataUtility td = new TestDataUtility(5);
		td.loadGeneral();
		td.loadSAMHTTPSettings();
        td.loadPlaneURL();
		td.createSubscriptions();
		for(Subscription__c s : td.lstSubscriptions){
        	s.Start_Date__c = Date.today().addYears(-1);
        }
        update td.lstSubscriptions;
        //adding previous subscription as then Start_Date__c can be set to current date and it is not overrode by workflow
        List<Subscription__c> lstNewSubs = new List<Subscription__c>();
        Integer i = 0;
        for(Subscription__c s : td.lstSubscriptions){
        	Subscription__c newSub = TestDataUtility.newSubscripiton(i,  td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id,Date.today());
        	newSub.Subscription_Status__c = Constants.SSTATUS_PENDING;
        	newSub.Previous_Subscription__c = td.lstSubscriptions[i].Id;
        	newSub.Payment_Details_Received__c = false;
        	lstNewSubs.add(newSub);
        	i++;
        }
        insert lstNewSubs;

        SubscriptionStatusQueueable.SubscriptionStatusQueueableResult ssqr = new SubscriptionStatusQueueable.SubscriptionStatusQueueableResult(null, null, 'some error string');
		Map<Id, SubscriptionStatusQueueable.SubscriptionStatusQueueableResult> mapErrors = new Map<Id, SubscriptionStatusQueueable.SubscriptionStatusQueueableResult>{lstNewSubs[4].Id => ssqr};

		td.loadSAMHTTPSettings();
        td.loadGeneral();
		td.loadPlaneURL();
		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, mapErrors);
			System.enqueueJob(ssq);
		Test.stopTest();
		Date dToday = Date.today();
		for(Subscription__c sub : [select Id, Start_Date__c, Subscription_Status__c from Subscription__c where Id in :lstNewSubs]){
			System.assertEquals(dToday, sub.Start_Date__c);
			if(sub.Id != lstNewSubs[4].Id){
				System.assertEquals(Constants.SSTATUS_ACTIVE, sub.Subscription_Status__c, 'wrong status');
			}else{
				System.assertEquals(Constants.SSTATUS_PENDING, sub.Subscription_Status__c, 'wrong status');
			}
		}
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.1
    Function - test Withdrawal Date scenario
    #############Change Log#############
	Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/07/2016  //modified Previous_Subscription_Expiry__c to Start_Date__c
    ****************************************************************************************/
	private static testMethod void testWithdrawalScenario(){
		TestDataUtility td = new TestDataUtility(5);
		td.loadGeneral();
		td.loadSAMHTTPSettings();
        td.loadPlaneURL();
		td.createSubscriptions();

		for(Subscription__c sub : td.lstSubscriptions){
			sub.Start_Date__c = Date.today().addDays(-Constants.SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK);
			sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
		}
        AccountTriggerHandler.getInstance().isExecuting = true;
		update td.lstSubscriptions;
        AccountTriggerHandler.getInstance().isExecuting = false;

		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			System.enqueueJob(ssq);
		Test.stopTest();
		for(Subscription__c sub : [select Id, Subscription_Status__c from Subscription__c where Id in :td.lstSubscriptions]){
			System.assertEquals(Constants.SSTATUS_WITHDRAWN, sub.Subscription_Status__c, 'wrong status');
		}
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.1
    Function - test Withdrawal Date scenario with re-queueing
    #############Change Log#############
	Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/07/2016  //modified Previous_Subscription_Expiry__c to Start_Date__c
    ****************************************************************************************/
	private static testMethod void testWithdrawalScenarioWithRequeue(){
		TestDataUtility td = new TestDataUtility(2);
		td.loadGeneral();
		td.createSubscriptions();

		for(Subscription__c sub : td.lstSubscriptions){
			sub.Start_Date__c = Date.today().addDays(-Constants.SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK);
			sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
		}
		update td.lstSubscriptions;

		td.loadSAMHTTPSettings();
        td.loadGeneral();
		td.loadPlaneURL();
		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(1, null);
			System.enqueueJob(ssq);
		Test.stopTest();
		for(Subscription__c sub : [select Id, Subscription_Status__c from Subscription__c where Id = :td.lstSubscriptions[0].Id]){
			System.assertEquals(Constants.SSTATUS_WITHDRAWN, sub.Subscription_Status__c, 'wrong status');
		}
		//as in tests it is only one execution that is checked - so check if the limit on queue size actually worked
		List<Subscription__c> lstNotUpdatedSub = [select Id, Subscription_Status__c from Subscription__c where Id = :td.lstSubscriptions[1].Id];
		System.assert(!lstNotUpdatedSub.isEmpty());
		System.assertNotEquals(Constants.SSTATUS_WITHDRAWN, lstNotUpdatedSub[0].Subscription_Status__c, 'wrong status');
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.0
    Function - test End Date scenario failure
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testLapsedOnEndDateFailure(){
		TestDataUtility td = new TestDataUtility(5);
		td.loadGeneral();
		td.loadSAMHTTPSettings();
        td.loadPlaneURL();
		Date dEndDate = Date.today().addDays(-Constants.SUBSCRIPTION_ENDDATE_CHECK_DAYSBACK);
		td.createSubscriptionsBasedOnEndDate(dEndDate);

		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			ssq.bTestFailure = true;
			System.enqueueJob(ssq);
		Test.stopTest();
		for(Subscription__c sub : [select Id, Subscription_Status__c from Subscription__c where Id in :td.lstSubscriptions]){
			System.assertNotEquals(Constants.SSTATUS_LAPSED, sub.Subscription_Status__c, 'wrong status');
		}
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.0
    Function - test Start Date scenario failure
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testActivationOnStartDateFailure(){
		TestDataUtility td = new TestDataUtility(5);
		td.loadGeneral();
		td.createSubscriptions();
		for(Subscription__c s : td.lstSubscriptions){
        	s.Start_Date__c = Date.today().addYears(-1);
        }
        update td.lstSubscriptions;
        //adding previous subscription as then Start_Date__c can be set to current date and it is not overrode by workflow
        List<Subscription__c> lstNewSubs = new List<Subscription__c>();
        Integer i = 0;
        for(Subscription__c s : td.lstSubscriptions){
        	Subscription__c newSub = TestDataUtility.newSubscripiton(i,  td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id,Date.today());
        	newSub.Subscription_Status__c = Constants.SSTATUS_PENDING;
        	newSub.Previous_Subscription__c = td.lstSubscriptions[i].Id;
        	lstNewSubs.add(newSub);
        	i++;
        }
        insert lstNewSubs;

        //updating with the flag to avoid workflow updating Start Date to the future
       	for(Subscription__c newSub : lstNewSubs){
       		newSub.Payment_Details_Received__c = false;
       	}
       	update lstNewSubs;

		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			ssq.bTestFailure = true;
			System.enqueueJob(ssq);
		Test.stopTest();
		for(Subscription__c sub : [select Id, Subscription_Status__c from Subscription__c where Id in :lstNewSubs]){
			System.assertNotEquals(Constants.SSTATUS_ACTIVE, sub.Subscription_Status__c, 'wrong status');
		}
	}

	/***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 31/03/2015
    Version - 1.0
    Function - test Withdrawal Date scenario failure
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testWithdrawalScenarioFailure(){
		TestDataUtility td = new TestDataUtility(5);
		td.loadGeneral();
		td.loadSAMHTTPSettings();
        td.loadPlaneURL();
		td.createSubscriptions();

		for(Subscription__c sub : td.lstSubscriptions){
			sub.Previous_Subscription_Expiry__c = Date.today().addDays(-Constants.SUBSCRIPTION_WITHDRAWAL_CHECK_DAYSBACK);
			sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
		}
		update td.lstSubscriptions;

		Test.startTest();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			ssq.bTestFailure = true;
			System.enqueueJob(ssq);
		Test.stopTest();
		for(Subscription__c sub : [select Id, Subscription_Status__c from Subscription__c where Id in :td.lstSubscriptions]){
			System.assertNotEquals(Constants.SSTATUS_WITHDRAWN, sub.Subscription_Status__c, 'wrong status');
		}
	}
}
