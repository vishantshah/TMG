/**
* Author: Michal Szewczyk
* Date: 18/07/2016
* Description:  Batch that generates Outbound Calling Sales cases
*
* ******************* Change Log *******************
* Modified by           Change Date
* Mantas Grigaliunas    19/08/2016  //modified Parameter string in testDataSetup()
* Michal Szewczyk       13/09/2016  //added new test method testExistingCaseNoSales()
* Pawel Chrzanowski     25/10/2016  added testCaseCallStageTransition()
* Pawel Chrzanowski     18/11/2016  added testCaseCallStageTransition_NoSale()
* Pawel Chrzanowski     21/11/2016  modified testCaseCallStageTransition()
* Pawel Chrzanowski     22/11/2016  added testCaseCallStageTransition_RescheduleInFuture()
* Wiktor Czykin         14/12/2016  added assertion for OC_Batch_Updated_Date__c in most of the methods
* Wiktor Czykin         20/12/2016  added testSchoolSubsDoNotTriggerCaseCreation()
**/
@isTest
private class OutboundCallingSalesBatchTest {

	private static final Integer testBatchAmount = 20;


	/***************************************************************************************
	Developer - Michal Szewczyk
	Date - 19/07/2016
	Version - 1.0
	Function - create tasks 28 days before Previous_Subscription_Expiry__c date
	#############Change Log#############
	* Modified by          Version 	Change Date 	
	* Mantas Grigaliunas	1.1		19/08/2016	//renamed T2 28Days to T2 and T2 to T2 Catch Up
  	****************************************************************************************/
	@testSetup
	private static void testDataSetup(){
		TestDataUtility testUtility = new TestDataUtility(testBatchAmount);
   		testUtility.loadCountryCodes();
		testUtility.iCounter = 1 ;

		testUtility.createOutboundCallBatchSetting(OutboundCallingSalesBatch.BATCH_NAME);
		testUtility.lstOutboundCallBatchSetting[0].Parameters__c = '{"attributes":{"type":"Case"},"Status":"New","Priority":"Normal","Reason":"Bad Debt","Origin":"Internal Records","Type":"Outbound Calling"}';
		update testUtility.lstOutboundCallBatchSetting;
		
		testUtility.lstOutboundCallSetting[0].Parameters__c = '{"callStageParameters" : [ { "stagename" : "T2", "outcome" : "OC_Stage_1_Outcome__c", "calldatetime" : "OC_Stage_1_Call_Date_Time__c", "offset"	: -28 }, { "stagename" : "T2 Catch Up", "outcome" : "OC_Stage_2_Outcome__c", "calldatetime" : "OC_Stage_2_Call_Date_Time__c", "offset"	: -14 }, { "stagename" : "TL1", "outcome" : "OC_Stage_3_Outcome__c", "calldatetime" : "OC_Stage_3_Call_Date_Time__c", "offset"	: 7 }, { "stagename" : "TL2", "outcome" : "OC_Stage_4_Outcome__c", "calldatetime" : "OC_Stage_4_Call_Date_Time__c", "offset"	: 21 } ] }';
		update testUtility.lstOutboundCallSetting;

        Profile prof = [Select Id from Profile where Name =:Constants.PROFILE_TMGSYSTEM limit 1];
        User usr = [Select Id from User where ProfileId=:prof.id and IsActive=true limit 1];
        System.runAs(usr){
			Group g = new Group(Type='Queue', Name='QueueName0');
			insert g;
			QueueSObject q = new QueueSObject(SobjectType='Case', QueueId=g.Id);
			insert q;
		}
	}

	/***************************************************************************************
	Developer - Michal Szewczyk
	Date - 19/07/2016
	Version - 1.0
	Function - create tasks 28 days before Previous_Subscription_Expiry__c date
	#############Change Log#############
	Modified by     Version     Change Date
  	****************************************************************************************/
	static testMethod void testScheduling() {

		Test.startTest();

			String cronExpresson = '0 0 * * * ?';
			String jobId = System.schedule('TestBatchSchedule', cronExpresson, new OutboundCallingSalesBatch());

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
	Developer - Michal Szewczyk
	Date - 19/07/2016
	Version - 1.0
	Function - create tasks 28 days before Previous_Subscription_Expiry__c date
	#############Change Log#############
	Modified by     Version     Change Date
  	****************************************************************************************/
    static testMethod void test28DaysBeforeExpiryDate() {

       	TestDataUtility tdu = new TestDataUtility(10);
       	tdu.loadGeneral();
       	tdu.createSubscriptions();

       	for(Account acc : tdu.lstIndividualSubscribers){
       		acc.PersonHomePhone = '123242354';
       	}

       	update tdu.lstIndividualSubscribers;

       	System.assertEquals(10,tdu.lstSubscriptions.size());
       	for(Integer i=0;i<10;i++){
       		tdu.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_LAPSED;
			tdu.lstSubscriptions[i].Start_Date__c = Date.newInstance(2014,07,07);
       	}
		update tdu.lstSubscriptions;

		List<Subscription__c> subs = new List<Subscription__c>();
		for(Integer i=0;i<10;i++){
			Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[i].Id,null,Date.newInstance(2015,07,06));
			subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			subOffered.isContinuous__c = false;
			subOffered.PaymentDate__c = '15';
			subOffered.Previous_Subscription__c = tdu.lstSubscriptions[i].Id;
			subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
			i = i+1;
			subs.add(subOffered);
		}

       	insert subs;
       	System.assertEquals(15,[SELECT Id FROM Subscription__c].size());
       	subs = [SELECT Id,Previous_Subscription_Expiry__c,Subscriber__r.PersonHomePhone FROM Subscription__c WHERE Subscription_Status__c =: 'Offered'];
       	System.assertEquals(5,subs.size());

       	for(Integer i=0;i<subs.size();i++){
       		subs[i].Previous_Subscription_Expiry__c = System.today().addDays(-28);
    	}
    	update subs;
    	Test.startTest();
	    	OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
	    	Database.executeBatch(outCallSalesBatch);
    	Test.stopTest();

    }

    /***************************************************************************************
	Developer - Michal Szewczyk
	Date - 19/07/2016
	Version - 1.0
	Function - create tasks 7 days after Previous_Subscription_Expiry__c date
	#############Change Log#############
	Modified by     Version     Change Date
  	****************************************************************************************/
    static testMethod void test7DaysAfterExpiryDate() {

       	TestDataUtility tdu = new TestDataUtility(10);
       	tdu.loadGeneral();
       	tdu.createSubscriptions();
       	for(Account acc : tdu.lstIndividualSubscribers){
       		acc.PersonHomePhone = '123242354';
       	}

       	update tdu.lstIndividualSubscribers;

       	System.assertEquals(10,tdu.lstSubscriptions.size());
       	for(Integer i=0;i<10;i++){
       		tdu.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_LAPSED;
			tdu.lstSubscriptions[i].Start_Date__c = Date.newInstance(2014,07,07);
       	}
		update tdu.lstSubscriptions;

		List<Subscription__c> subs = new List<Subscription__c>();
		for(Integer i=0;i<10;i++){
			Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[i].Id,null,Date.newInstance(2015,07,06));
			subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			subOffered.isContinuous__c = false;
			subOffered.PaymentDate__c = '15';
			subOffered.Previous_Subscription__c = tdu.lstSubscriptions[i].Id;
			subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
			i = i+1;
			subs.add(subOffered);
		}

       	insert subs;
       	System.assertEquals(15,[SELECT Id FROM Subscription__c].size());
       	subs = [SELECT Id,Previous_Subscription_Expiry__c,Subscriber__r.PersonHomePhone FROM Subscription__c WHERE Subscription_Status__c =:Constants.SSTATUS_OFFERED];
       	System.assertEquals(5,subs.size());

       	for(Integer i=0;i<subs.size();i++){
       		subs[i].Previous_Subscription_Expiry__c = System.today().addDays(7);
    	}
    	update subs;
    	Test.startTest();
	    	OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
	    	Database.executeBatch(outCallSalesBatch);
    	Test.stopTest();
    }

    /***************************************************************************************
	Developer - Michal Szewczyk
	Date - 19/07/2016
	Version - 1.0
	Function - create tasks 21 days after Previous_Subscription_Expiry__c date
	#############Change Log#############
	Modified by     Version     Change Date
  	****************************************************************************************/
    static testMethod void test21DaysAfterExpiryDate() {

       	TestDataUtility tdu = new TestDataUtility(10);
       	tdu.loadGeneral();
       	tdu.createSubscriptions();
       	for(Account acc : tdu.lstIndividualSubscribers){
       		acc.PersonHomePhone = '123242354';
       	}

       	update tdu.lstIndividualSubscribers;

       	System.assertEquals(10,tdu.lstSubscriptions.size());
       	for(Integer i=0;i<10;i++){
       		tdu.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_LAPSED;
			tdu.lstSubscriptions[i].Start_Date__c = Date.newInstance(2014,07,07);
       	}
		update tdu.lstSubscriptions;

		List<Subscription__c> subs = new List<Subscription__c>();
		for(Integer i=0;i<10;i++){
			Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[i].Id,null,Date.newInstance(2015,07,06));
			subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			subOffered.isContinuous__c = false;
			subOffered.PaymentDate__c = '15';
			subOffered.Previous_Subscription__c = tdu.lstSubscriptions[i].Id;
			subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
			i = i+1;
			subs.add(subOffered);
		}

       	insert subs;
       	System.assertEquals(15,[SELECT Id FROM Subscription__c].size());
       	subs = [SELECT Id,Previous_Subscription_Expiry__c,Subscriber__r.PersonHomePhone FROM Subscription__c WHERE Subscription_Status__c =:Constants.SSTATUS_OFFERED];
       	System.assertEquals(5,subs.size());

       	for(Integer i=0;i<subs.size();i++){
       		subs[i].Previous_Subscription_Expiry__c = System.today().addDays(21);
    	}
    	update subs;

    	Test.startTest();
	    	OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
	    	Database.executeBatch(outCallSalesBatch);
    	Test.stopTest();
    }
  
    /***************************************************************************************
	Developer - Michal Szewczyk
	Date - 13/09/2016
	Version - 1.0
	Function - test case when no sale conditions are meet
	#############Change Log#############
	Modified by     Version     Change Date
  	****************************************************************************************/
    static testMethod void testExistingCaseNoSales() {
		String recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
       	TestDataUtility tdu = new TestDataUtility(10);
       	tdu.loadGeneral();
       	tdu.createSubscriptions();
       	for(Account acc : tdu.lstIndividualSubscribers){
       		acc.PersonHomePhone = '123242354';
       	}

       	update tdu.lstIndividualSubscribers;

       	System.assertEquals(10,tdu.lstSubscriptions.size());
       	for(Integer i=0;i<10;i++){
       		tdu.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_LAPSED;
			tdu.lstSubscriptions[i].Start_Date__c = Date.newInstance(2014,07,07);
       	}
		update tdu.lstSubscriptions;

		List<Subscription__c> subs = new List<Subscription__c>();
		for(Integer i=0;i<10;i++){
			Subscription__c subOffered = TestDataUtility.newSubscripiton(1,tdu.lstIndividualSubscribers[i].Id,null,Date.newInstance(2015,07,06));
			subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			subOffered.isContinuous__c = false;
			subOffered.PaymentDate__c = '15';
			subOffered.Previous_Subscription__c = tdu.lstSubscriptions[i].Id;
			subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
			i = i+1;
			subs.add(subOffered);
		}

       	insert subs;
       	System.assertEquals(15,[SELECT Id FROM Subscription__c].size());
       	subs = [SELECT Id,Previous_Subscription_Expiry__c,Subscriber__r.PersonHomePhone FROM Subscription__c WHERE Subscription_Status__c =:Constants.SSTATUS_OFFERED];
       	System.assertEquals(5,subs.size());

       	for(Integer i=0;i<subs.size();i++){
       		subs[i].Previous_Subscription_Expiry__c = System.today().addDays(21);
    	}
    	update subs;

    	Case newCase = TestDataUtility.newOCCase(recordTypeId,Constants.OC_CALL_STAGE_T2, subs[1].Id,tdu.lstIndividualSubscribers[1].Id);
		newCase.Status = Constants.CASE_STATUS_COMPLETED;
		newCase.OC_No_Sale_Reason__c = 'Serious Illness';
		newCase.OC_Outcome__c = Constants.OC_NO_SALE_OUTCOME;
		insert newCase;

    	Test.startTest();
	    	OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
	    	Database.executeBatch(outCallSalesBatch);
    	Test.stopTest();
    }

    /***************************************************************************************
	Developer - Pawel Chrzanowski
	Date - 25/10/2016
	Version - 1.0
	Method to test SIA removal on Case Callstage transition
	#############Change Log#############
	Modified by     Version     Change Date
	Pawel Chrzanowski 1.1       21/11/2016  Added Case resetting on Stage transition
  	****************************************************************************************/
    static testMethod void testCaseCallStageTransition(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createSubscriptions();
        tdu.createIncentives();

        tdu.lstIndividualSubscribers[0].PersonHomePhone = '123242354';
        update tdu.lstIndividualSubscribers;

        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_LAPSED;
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions;

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, null, Date.newInstance(2015,07,06));
        subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subOffered.isContinuous__c = false;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        subOffered.Incentive_Description__c = tdu.lstIncentives[0].Incentive_Description__c;
        subOffered.Previous_Subscription_Expiry__c = System.today().addDays(21);
        insert subOffered;

        Id ocsId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        Case ocCase = new Case(RecordTypeId = ocsId, AccountId = tdu.lstIndividualSubscribers[0].Id, Print_Subscription__c = subOffered.Id, OC_Call_Stage__c = 'TL1');
        insert ocCase;

        SubscriptionIncentiveAssociation__c sia = new SubscriptionIncentiveAssociation__c();
        sia.Incentive__c = tdu.lstIncentives[0].Id;
        sia.Subscriber__c = tdu.lstIndividualSubscribers[0].Id;
        sia.Subscription__c = subOffered.Id;
        sia.Reason__c = 'Renewal for TL1';
        insert sia;

    	Test.startTest();
	    	OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
	    	Database.executeBatch(outCallSalesBatch);
    	Test.stopTest();

        //verify Case Callstage transition
        List<Case> lstCases = [SELECT Status, OC_Outcome__c, OC_Scheduled_Callback__c, OC_No_Sale_Reason__c, OC_Call_Stage__c, OC_Batch_Updated_Date__c FROM Case];
        System.assertEquals(Constants.CASE_STATUS_NOT_STARTED, lstCases[0].Status);
        System.assertEquals(Constants.OC_DEFAULT_OUTCOME, lstCases[0].OC_Outcome__c);
        System.assertEquals(null, lstCases[0].OC_Scheduled_Callback__c);
        System.assert(String.isBlank(lstCases[0].OC_No_Sale_Reason__c));
        System.assertEquals('TL2', lstCases[0].OC_Call_Stage__c);
        System.assertEquals(Date.today(), lstCases[0].OC_Batch_Updated_Date__c);
        //verify SIA removal
        List<SubscriptionIncentiveAssociation__c> lstSia = [SELECT Id FROM SubscriptionIncentiveAssociation__c];
        System.assert(lstSia.isEmpty());

        //verify Incentive Description removal
        List<Subscription__c> lstSubs = [SELECT Incentive_Description__c FROM Subscription__c];
        System.assertEquals(null, lstSubs[0].Incentive_Description__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/11/2016
    Version - 1.0
    Method to test Case Callstage transition when outcome='No Sale' and next stage is T2 Catch Up
    #############Change Log#############
    Modified by       Version     Change Date
    Pawel Chrzanowski 1.1         29/11/2016  Modified to allow transition
    ****************************************************************************************/
    static testMethod void testCaseCallStageTransition_NoSaleTransitionToT2CatchUp(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createSubscriptions();
        tdu.createIncentives();

        tdu.lstIndividualSubscribers[0].PersonHomePhone = '123242354';
        update tdu.lstIndividualSubscribers;

        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_LAPSED;
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions;

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, null, Date.newInstance(2015,07,06));
        subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subOffered.isContinuous__c = false;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        subOffered.Incentive_Description__c = tdu.lstIncentives[0].Incentive_Description__c;
        subOffered.Previous_Subscription_Expiry__c = System.today().addDays(-14);
        insert subOffered;

        Id ocsId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        Case ocCase = new Case(OC_Outcome__c = Constants.OC_NO_SALE_OUTCOME, RecordTypeId = ocsId, AccountId = tdu.lstIndividualSubscribers[0].Id, Print_Subscription__c = subOffered.Id, OC_Call_Stage__c = 'T2');
        insert ocCase;

        Test.startTest();
          OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
          Database.executeBatch(outCallSalesBatch);
        Test.stopTest();

        //verify Case Callstage transition
        List<Case> lstCases = [SELECT OC_Call_Stage__c, OC_Outcome__c, OC_Batch_Updated_Date__c FROM Case];
        System.assertEquals(Constants.OC_T2_CATCH_UP, lstCases[0].OC_Call_Stage__c);
        System.assertEquals(Constants.OC_DEFAULT_OUTCOME, lstCases[0].OC_Outcome__c);
        System.assertEquals(Date.today(), lstCases[0].OC_Batch_Updated_Date__c);

    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/11/2016
    Version - 1.0
    Method to test Case Callstage transition when outcome='No Sale' and next stage is not T2 Catch Up
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testCaseCallStageTransition_NoSaleTransitionToTL2(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createSubscriptions();
        tdu.createIncentives();

        tdu.lstIndividualSubscribers[0].PersonHomePhone = '123242354';
        update tdu.lstIndividualSubscribers;

        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_LAPSED;
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions;

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, null, Date.newInstance(2015,07,06));
        subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subOffered.isContinuous__c = false;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        subOffered.Incentive_Description__c = tdu.lstIncentives[0].Incentive_Description__c;
        subOffered.Previous_Subscription_Expiry__c = System.today().addDays(21);
        insert subOffered;

        Id ocsId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        Case ocCase = new Case(OC_Outcome__c = Constants.OC_NO_SALE_OUTCOME, RecordTypeId = ocsId, AccountId = tdu.lstIndividualSubscribers[0].Id, Print_Subscription__c = subOffered.Id, OC_Call_Stage__c = 'T2');
        insert ocCase;

        Test.startTest();
          OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
          Database.executeBatch(outCallSalesBatch);
        Test.stopTest();

        //verify Case Callstage transition
        List<Case> lstCases = [SELECT OC_Call_Stage__c, OC_Batch_Updated_Date__c FROM Case];
        System.assertEquals('TL2', lstCases[0].OC_Call_Stage__c);
        System.assertEquals(Date.today(), lstCases[0].OC_Batch_Updated_Date__c);

    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 22/11/2016
    Version - 1.0
    Method to test no Case Callstage reset when Scheduled Callback is in the future
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testCaseCallStageTransition_RescheduleInFuture(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createSubscriptions();
        tdu.createIncentives();

        tdu.lstIndividualSubscribers[0].PersonHomePhone = '123242354';
        update tdu.lstIndividualSubscribers;

        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_LAPSED;
        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2014,07,07);
        update tdu.lstSubscriptions;

        Subscription__c subOffered = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, null, Date.newInstance(2015,07,06));
        subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subOffered.isContinuous__c = false;
        subOffered.PaymentDate__c = '15';
        subOffered.Previous_Subscription__c = tdu.lstSubscriptions[0].Id;
        subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        subOffered.Incentive_Description__c = tdu.lstIncentives[0].Incentive_Description__c;
        subOffered.Previous_Subscription_Expiry__c = System.today().addDays(21);
        insert subOffered;

        Datetime futureDate = Datetime.now().addDays(30);
        Id ocsId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        Case ocCase = new Case(OC_Outcome__c = Constants.CASE_OUTCOME_RESCHEDULE, RecordTypeId = ocsId, AccountId = tdu.lstIndividualSubscribers[0].Id, Print_Subscription__c = subOffered.Id, OC_Call_Stage__c = 'TL1', OC_Scheduled_Callback__c = futureDate);
        insert ocCase;

        Test.startTest();
          OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
          Database.executeBatch(outCallSalesBatch);
        Test.stopTest();

        //verify no Case reset on Callstage transition
        List<Case> lstCases = [SELECT OC_Call_Stage__c, OC_Outcome__c, OC_Scheduled_Callback__c, OC_Batch_Updated_Date__c FROM Case];
        System.assertEquals('TL2', lstCases[0].OC_Call_Stage__c);
        System.assertEquals(Constants.CASE_OUTCOME_RESCHEDULE, lstCases[0].OC_Outcome__c);
        System.assertEquals(futureDate, lstCases[0].OC_Scheduled_Callback__c);
        System.assertEquals(Date.today(), lstCases[0].OC_Batch_Updated_Date__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/12/2016
    Version - 1.0
    Test cases are not created for school subscriptions
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testSchoolSubsDoNotTriggerCaseCreation(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createSubscriptions();

        for(Account a : tdu.lstIndividualSubscribers){
           a.PersonHomePhone = '0123242354';
        }
        update tdu.lstIndividualSubscribers;

        for(Subscription__c sub : tdu.lstSubscriptions){
            sub.Subscription_Status__c = Constants.SSTATUS_LAPSED;
            sub.Start_Date__c = Date.newInstance(2014,07,07);
        }
        Id schoolRecordType = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
        tdu.lstSubscriptions[0].RecordTypeId = schoolRecordType;
        update tdu.lstSubscriptions;

        List<Subscription__c> lstToInsert = new List<Subscription__c>();
        for(Integer i = 0; i<tdu.iCounter; i++){
            Subscription__c subOffered = TestDataUtility.newSubscripiton((i+5), tdu.lstIndividualSubscribers[i].Id, null, Date.newInstance(2015,07,06));
            subOffered.Subscription_Status__c = Constants.SSTATUS_OFFERED;
            subOffered.isContinuous__c = false;
            subOffered.PaymentDate__c = '15';
            subOffered.Previous_Subscription__c = tdu.lstSubscriptions[i].Id;
            subOffered.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
            subOffered.Previous_Subscription_Expiry__c = System.today().addDays(21);
            lstToInsert.add(subOffered);
        }
        lstToInsert[0].RecordTypeId = schoolRecordType;
        insert lstToInsert;

        Test.startTest();
            OutboundCallingSalesBatch outCallSalesBatch = new OutboundCallingSalesBatch();
            Database.executeBatch(outCallSalesBatch);
        Test.stopTest();
        List<Case> lstCases = [SELECT OC_Call_Stage__c, OC_Outcome__c, OC_Scheduled_Callback__c, OC_Batch_Updated_Date__c FROM Case];
        System.assert(!lstCases.isEmpty());
        System.assertEquals(1, lstCases.size(), lstCases.size());
    }
}