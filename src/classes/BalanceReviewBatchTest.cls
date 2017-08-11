/**
* @author Gavin Palmer
* @date 03/06/2016
* @description Set of unit tests for the BalanceReviewBatch class which will create cases for subscriptions
*#############Change Log#############
*Modified by     Version     Change Date
Michal Szewczyk	 1.1		 11/07/2016  - changed test method to use case and config record
Pawel Chrzanowski 1.2        05/08/2016  //fix for new outstanding balance threshold (30)
Pawel Chrzanowski 1.3        24/01/2017  //added test methods
**/
@isTest
private class BalanceReviewBatchTest {

	private static final Integer testBatchAmount = 20;

	/**
	* @author Gavin Palmer
	* @date 03/06/2016
	* @description setup test data for unit tests
	*#############Change Log#############
	*Modified by     Version     Change Date
	Michal Szewczyk	 1.1		 11/07/2016  - added config record
	Pawel Chrzanowski 1.2        05/08/2016  //fix for new outstanding balance threshold (30)
	**/
	@testSetup
	private static void testDataSetup(){
		TestDataUtility testUtility = new TestDataUtility(testBatchAmount);
		testUtility.createSubscriptionsBasedOnEndDate(Date.today());

		for(Integer i = 0; i < testBatchAmount; i++){
			testUtility.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_OFFERED;
			testUtility.lstSubscriptions[i].Revenue_Write_off_Amount__c = 100;
			testUtility.lstSubscriptions[i].Revenue_Write_off_Reason__c = 'DD error';
		}		
		testUtility.iCounter = 1 ;
		update testUtility.lstSubscriptions;

		testUtility.createOutboundCallBatchSetting(BalanceReviewBatch.BATCH_NAME);
		testUtility.lstOutboundCallBatchSetting[0].Parameters__c = '{"attributes":{"type":"Case"},"Status":"New","Priority":"Normal","Reason":"Bad Debt","Origin":"Internal Records","Type":"Outbound Calling"}';
		update testUtility.lstOutboundCallBatchSetting;
		
		testUtility.lstOutboundCallSetting[0].Parameters__c = '{ "callStageParameters": [{ "stagename": "BR1", "outcome": "OC_Stage_5_Outcome__c", "calldatetime": "OC_Stage_5_Call_Date_Time__c", "nosalereason": "", "tcode": "", "offset": 0 }] }';
		update testUtility.lstOutboundCallSetting;

		List<Subscription__c> subscriptions = [
			SELECT Outstanding_Balance_to_from_Customer__c  
			FROM Subscription__c
		];

        Profile prof = [Select Id from Profile where Name =:Constants.PROFILE_TMGSYSTEM limit 1];
        User usr = [Select Id from User where ProfileId=:prof.id and IsActive=true limit 1];
        System.runAs(usr){ 
			Group g = new Group(Type='Queue', Name='QueueName0');
			insert g;
			QueueSObject q = new QueueSObject(SobjectType='Case', QueueId=g.Id);
			insert q;
		}

		// we assume that all formula fields will calculate the same
		System.assertEquals(111, subscriptions[0].Outstanding_Balance_to_from_Customer__c,
			'Outstanding_Balance_to_from_Customer__c formula not calculated correctly');
	}
	
	/**
	* @author Gavin Palmer
	* @date 03/06/2016
	* @description test the execution of the batch class
	*#############Change Log#############
	*Modified by     Version     Change Date
	Michal Szewczyk	 1.1		 11/07/2016  - changed tasks to cases
	**/
	@isTest
	private static void testExecute() {
		Test.startTest();
			BalanceReviewBatch batchClass = new BalanceReviewBatch();
			Database.executeBatch(batchClass);
			
		Test.stopTest();

		Integer caseCount = [
			SELECT Count()  
			FROM Case 
		];
		List<Case> caseData = [SELECT Status,Reason,Origin FROM Case];
		System.assertEquals(caseData[0].Status,'New', 'Status of the case should be set as New');
		System.assertEquals(caseData[0].Reason,'Bad Debt', 'Reason of the case should be Bad Debt');
		System.assertEquals(caseData[0].Origin,'Internal Records', 'Origin of the case should be Internal Records');
		System.assertEquals(testBatchAmount, caseCount, 'Correct number of cases have not been created during the batch job');
	}
	
	/**
	* @author Gavin Palmer
	* @date 03/06/2016
	* @description test the execution of the batch class
	*#############Change Log#############
	*Modified by     Version     Change Date
	**/
	@isTest
	private static void testScheduling() {
		
		Test.startTest();

			String cronExpresson = '0 0 * * * ?';
			String jobId = System.schedule('TestBatchSchedule', cronExpresson, new BalanceReviewBatch());
			
			List<CronTrigger> scheduledCronJob = [
				SELECT CronExpression, TimesTriggered
         		FROM CronTrigger 
         		WHERE id = :jobId
         	];
         	
         	System.assertEquals(cronExpresson, scheduledCronJob[0].CronExpression);
         	System.assertEquals(0, scheduledCronJob[0].TimesTriggered);
		Test.stopTest();
	}

    /***************************************************************************************
    Author:       Pawel Chrzanowski
    Date:         24/01/2017
    test offset parameter
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	@isTest static void testOffset(){
		Integer offset = 5;
		Integer subSize = 6;
		Date newStartDate = Date.today().addDays(offset).addDays(-(26*7)+1);
		List<Subscription__c> lstSubs = [SELECT Id FROM Subscription__c LIMIT :subSize];
		for(Subscription__c sub : lstSubs){
			sub.Start_Date__c = newStartDate;
		}
		update lstSubs;

		Test.startTest();
			BalanceReviewBatch batchClass = new BalanceReviewBatch(offset, 30);
			Database.executeBatch(batchClass);
		Test.stopTest();

		List<Case> lstCases = [SELECT Id FROM Case];
		System.assertEquals(subSize, lstCases.size());
	}

    /***************************************************************************************
    Author:       Pawel Chrzanowski
    Date:         24/01/2017
    test outstanding balance parameter
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
	@isTest static void testBalance(){
		Test.startTest();
			BalanceReviewBatch batchClass = new BalanceReviewBatch(null, 300);
			Database.executeBatch(batchClass);
		Test.stopTest();

		List<Case> lstCases = [SELECT Id FROM Case];
		System.assert(lstCases.isEmpty());
	}
}