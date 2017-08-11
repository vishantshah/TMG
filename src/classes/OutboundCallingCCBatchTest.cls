/**
* Author:       Michal Szewczyk
* Date:			25/07/2016
* Description:  Test class for OutboundCallingCCBatch
*
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest
public with sharing class OutboundCallingCCBatchTest {

	private static final Integer testBatchAmount = 20;

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@testSetup
	private static void testDataSetup(){
		Id recordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME, Case.class.getName());
		TestDataUtility testUtility = new TestDataUtility(testBatchAmount);
		testUtility.createIndividualSubscribers();
		testUtility.loadCountryCodes();
		for(Account acc : testUtility.lstIndividualSubscribers){
			acc.Credit_Card_Expiry_Date__c = System.today().addMonths(1);
		}
		
		update testUtility.lstIndividualSubscribers;

		Case existingCase = TestDataUtility.newOCCase(recordTypeId,'CCEX1',Datetime.now());
		existingCase.AccountId = testUtility.lstIndividualSubscribers[0].Id;
		existingCase.Reason = Constants.CASE_OUTBOUND_CALL_REASON;
		existingCase.Origin = Constants.CASE_OUTBOUND_CALL_ORGIN;
		insert existingCase;

		testUtility.iCounter = 1;
		testUtility.createOutboundCallBatchSetting(OutboundCallingCCBatch.BATCH_NAME);
		testUtility.lstOutboundCallBatchSetting[0].Parameters__c = '{"attributes":{"type":"Case"},"Status":"New","Priority":"Normal","Reason":"Credit Card Expiry","Origin":"Internal Records","Type":"Outbound Calling"}';
		update testUtility.lstOutboundCallBatchSetting;
		
		testUtility.lstOutboundCallSetting[0].Parameters__c = '{ "callStageParameters": [{ "stagename": "CCEX1", "outcome": "OC_Stage_1_Outcome__c", "calldatetime": "OC_Stage_1_Call_Date_Time__c", "offset": 1 }] }';
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
	}
	
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @isTest
	private static void testExecute() {

		Test.startTest();
			OutboundCallingCCBatch batchClass = new OutboundCallingCCBatch();
			Database.executeBatch(batchClass);
		Test.stopTest();

		Integer caseCount = [SELECT Count() FROM Case];
		List<Case> caseData = [SELECT Status,Reason,Origin FROM Case];
		System.assertEquals(caseData[0].Status,'New', 'Status of the case should be set as New');
		System.assertEquals(caseData[0].Reason,'Credit Card Expiry', 'Reason of the case should be Credit Card Expiry');
		System.assertEquals(caseData[0].Origin,'Internal Records', 'Origin of the case should be Internal Records');
		System.assertEquals(20, caseCount, 'Correct number of cases have not been created during the batch job');
	}
	
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 12/07/2016
    Version - 1.0
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @isTest
	private static void testScheduling() {
		
		Test.startTest();

			String cronExpresson = '0 0 * * * ?';
			String jobId = System.schedule('TestBatchSchedule', cronExpresson, new OutboundCallingCCBatch());
			
			List<CronTrigger> scheduledCronJob = [
				SELECT CronExpression, TimesTriggered
         		FROM CronTrigger 
         		WHERE id = :jobId
         	];
         	
         	System.assertEquals(cronExpresson, scheduledCronJob[0].CronExpression);
         	System.assertEquals(0, scheduledCronJob[0].TimesTriggered);
		Test.stopTest();
	}
}