/**
* @author Michal Szewczyk
* @date 08/09/2016
* @description  Test methods for OutboundCaseRequeueBatch
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class OutboundCaseRequeueBatchTest {
	private static final Integer RECORDS_SIZE = 2;

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 12/09/2016
    Version - 1.0
    Function - Test data setup 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@testSetup
	private static void testDataSetup(){

		final String DEFAULT_CASE_STATUS = 'Not Started';

		TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);

		/* CREATE OUTBOUND CALL SETTING AND RULES */
		tdu.iCounter = 1;
		tdu.createSalesOutboundCallSetting();
		tdu.createOutboundCallRule();

		/* CUSTOM SETTINGS */
		tdu.loadCountryCodes();
		TestDataUtility.createOCCaseAutocloseCustomSettingInstance();

		/* CREATE TCODEMANAGEMENT AND TCODE PRODUCTS*/
		//need to create extra subscription to use as previous subscription
		tdu.iCounter = RECORDS_SIZE;
		tdu.createTCodeManagement();
		tdu.createZProduct();
		tdu.createTCodeProducts();
		tdu.createCheques();
		tdu.createSubscriptionIncentiveAssociation();
		tdu.createTCodeProductIncentives();


		/* CREATE ACCOUNTS, SUBSCRIPTION AND CASES */
		tdu.createIndividualSubscribers();
		tdu.createSubscriptions();
		//use last subscription record as previous subscription
		Integer index = tdu.lstSubscriptions.size() - 1;
		for(Integer i = 0; i < index; i++){
			tdu.lstSubscriptions[i].Subscription_Status__c = Constants.SSTATUS_OFFERED;
			tdu.lstSubscriptions[i].PaymentDate__c = '1';
			tdu.lstSubscriptions[i].TCode__c = tdu.lstTCodeManagement[i].Id;
			tdu.lstSubscriptions[i].Previous_Subscription__c = tdu.lstSubscriptions[index].Id;
		}
		update tdu.lstSubscriptions;
		tdu.iCounter = RECORDS_SIZE - 1;
		tdu.createOCCases(Constants.OC_SALES_RECORD_TYPE_NAME);
	}
	
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 12/09/2016
    Version - 1.0
    Function - Testing method checking constructor of the batch class
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@isTest static void testConstructorOne() {
		List<String> stageParams = new List<String>();
		List<String> statusParams = new List<String>();
		String buttonsrc = '';

		Test.startTest();

		try {
			OutboundCaseRequeueBatch intanceOne = new OutboundCaseRequeueBatch(statusParams,stageParams,buttonsrc);
			System.assert(false,'Code should throw an exception');
		} catch (Exception e) {
			System.assertEquals('Outcome status was not selected. Please select at least one', e.getmessage());
		}

		try {
			statusParams.add('test');
			OutboundCaseRequeueBatch intanceTwo = new OutboundCaseRequeueBatch(statusParams,stageParams,buttonsrc);
			System.assert(false,'Code should throw an exception');
		} catch (Exception e) {
			System.assertEquals('Case stage was not selected. Please select at least one', e.getmessage());
		}
		try {
			statusParams.add('test');
			stageParams.add('test');
			OutboundCaseRequeueBatch intanceThree = new OutboundCaseRequeueBatch(statusParams,stageParams,buttonsrc);
			System.assert(false,'Code should throw an exception');
		} catch (Exception e) {
			System.assertEquals('buttonSource is not valid', e.getmessage());
		}

		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 12/09/2016
    Version - 1.0
    Function - Testing method checking batch logic
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@isTest static void testBatchRun() {
		List<String> queryStatsParams = new List<String>{'Busy','No Sale'};
		List<String> queryStgParams = new List<String>{'T2','T2 Catch Up'};
		String buttonsrc = Constants.OC_SALES_RECORD_TYPE_NAME;

		Case newCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c,OC_Outcome__c,OC_Call_Stage__c FROM Case LIMIT 1];
		newCase.OC_Stage_1_Call_Date_Time__c = newCase.OC_Stage_1_Call_Date_Time__c.addHours(3);
		newCase.OC_Outcome__c = Constants.CASE_OUTCOME_BUSY;
		Datetime oldCaseTime = newCase.OC_Stage_1_Call_Date_Time__c.addHours(3);
		update newCase;

		Test.startTest();

			OutboundCaseRequeueBatch intanceTwo = new OutboundCaseRequeueBatch(queryStatsParams,queryStgParams,buttonsrc);
			Database.executeBatch(intanceTwo, 200);
			newCase = [SELECT Id, OC_Stage_1_Call_Date_Time__c,OC_Outcome__c,OC_Call_Stage__c FROM Case LIMIT 1];
			System.assertNotEquals(oldCaseTime,newCase.OC_Stage_1_Call_Date_Time__c,'Case was not updated with new call time');

		Test.stopTest();
	}
}