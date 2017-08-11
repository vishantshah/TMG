/**
* Developer - Mantas Grigaliunas
* Date - 24/05/2017
* Description:  Test class for OutboundCallingDDWinbackBatch
*
* ******************* Change Log *******************
* Modified by   Change Date
**/

@isTest
public class OutboundCallingDDCXBatchTest {
	private static final String SUBS_CREATED = 'There should be 10 subs created.';
	private static final Integer COUNTER = 10;

	@TestSetup
	private static void testSetup(){
		TestDataUtility testUtility = new TestDataUtility();
   		testUtility.loadCountryCodes();

		testUtility.iCounter = 1;
		testUtility.createOutboundCallBatchSetting(OutboundCallingDDCXBatch.BATCH_NAME);
		testUtility.lstOutboundCallBatchSetting[0].Parameters__c = '{ "attributes": { "type": "Case" }, "Status": "Not Started", "Priority": "Normal", "Reason": "Outbound DD Cancellation", "Origin": "Internal Records", "Type": "Outbound Calling DD Cancellation", "Subject": "Outbound DD Cancellation", "DD_Cancellation_Outcome__c": "Not Started", "OC_Outcome__c": "Not Started"}';
		update testUtility.lstOutboundCallBatchSetting;
		
		testUtility.lstOutboundCallSetting[0].Parameters__c = '{ "callStageParameters" : [ { "stagename" : "DD Cancellation", "outcome" : "DD_Cancellation_Outcome__c", "calldatetime" : "DD_Cancellation_Call_Date_Time__c", "offset" : 0 , "tcode" : "", "nosalereason":""} ]}';
		update testUtility.lstOutboundCallSetting;

		testUtility.iCounter = 10;
       	testUtility.loadGeneral();
       	testUtility.createSubscriptions();

        insert Configuration__c.getOrgDefaults();

        User usr = [SELECT Id FROM User WHERE ProfileId = :Constants.getSystemAdministratorProfileId() AND IsActive = TRUE LIMIT 1];

        System.runAs(usr){
			Group g = new Group(Type='Queue', Name='QueueName0');
			insert g;

			QueueSObject q = new QueueSObject(SobjectType='Case', QueueId=g.Id);
			insert q;
		}

	}

	/***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 24/05/2017
    Function - check if cases are created for pending cancellation subs
    #############Change Log#############
    Modified by  Change Date 
    ****************************************************************************************/
	private static testMethod void caseCreated() {

		List<Subscription__c> subs = [SELECT Id FROM Subscription__c];
		List<Account> subscribers  = [SELECT Id FROM Account WHERE RecordType.Name = :Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME];

       	setAccountValues(subscribers, '123242354');

       	System.assertEquals(COUNTER, subs.size(), SUBS_CREATED);
		
		setSubscriptionValues(subs, true, Constants.SUB_PMETHOD_DD);

        Test.startTest();
	    	OutboundCallingDDCXBatch ddcxBatch = new OutboundCallingDDCXBatch();
	    	Database.executeBatch(ddcxBatch, 200);
    	Test.stopTest();

		List<Case> cases = [SELECT Id FROM Case];
	    System.assertEquals(10, cases.size(), 'There should be 10 cases created');
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 24/05/2017
    Function - cases should not be created if the last status change is in past
    #############Change Log#############
    Modified by  Change Date 
    ****************************************************************************************/
    private static testMethod void caseNOTCreatedIfNotContinuos() {
		List<Subscription__c> subs = [SELECT Id FROM Subscription__c];
		List<Account> subscribers  = [SELECT Id FROM Account WHERE RecordType.Name = :Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME];

       	setAccountValues(subscribers, '123242354');

       	System.assertEquals(COUNTER, subs.size(), SUBS_CREATED);

		setSubscriptionValues(subs, false, Constants.SUB_PMETHOD_DD);

        Test.startTest();
	    	OutboundCallingDDCXBatch ddwinbackBatch = new OutboundCallingDDCXBatch();
	    	Database.executeBatch(ddwinbackBatch, 200);
    	Test.stopTest();

		List<Case> cases = [SELECT Id FROM Case];
	    System.assertEquals(0, cases.size(), 'There should be NO cases created');
    }
    
    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 24/05/2017
    Function - cases should not be created if the cancellation method is Phone
    #############Change Log#############
    Modified by  Change Date 
    ****************************************************************************************/
    private static testMethod void caseNOTCreatedIfPaymentNotDD() {
		List<Subscription__c> subs = [SELECT Id FROM Subscription__c];
		List<Account> subscribers  = [SELECT Id FROM Account WHERE RecordType.Name = :Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME];

		setAccountValues(subscribers, '123242354');

       	System.assertEquals(COUNTER, subs.size(), SUBS_CREATED);

		setSubscriptionValues(subs, true, Constants.SUB_PMETHOD_CC);

        Test.startTest();
	    	OutboundCallingDDCXBatch ddwinbackBatch = new OutboundCallingDDCXBatch();
	    	Database.executeBatch(ddwinbackBatch, 200);
    	Test.stopTest();

		List<Case> cases = [SELECT Id FROM Case];
	    System.assertEquals(0, cases.size(), 'There should be NO cases created');
    }
    
    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 24/05/2017
    Function - cases should not be created if the cancellation method is email but no account phone
    #############Change Log#############
    Modified by  Change Date 
    ****************************************************************************************/
    private static testMethod void caseNOTCreatedIFNoAccountPhone() {
		List<Subscription__c> subs = [SELECT Id FROM Subscription__c];
		List<Account> subscribers  = [SELECT Id FROM Account WHERE RecordType.Name = :Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME];

       	setAccountValues(subscribers, null);

       	System.assertEquals(COUNTER, subs.size(), SUBS_CREATED);

		setSubscriptionValues(subs, true, Constants.SUB_PMETHOD_DD);
        
        Test.startTest();
	    	OutboundCallingDDCXBatch ddwinbackBatch = new OutboundCallingDDCXBatch();
	    	Database.executeBatch(ddwinbackBatch, 200);
    	Test.stopTest();

		List<Case> cases = [SELECT Id FROM Case];
	    System.assertEquals(0, cases.size(), 'There should be NO cases created');
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 24/05/2017
    Function - set subscription values and last status change
    #############Change Log#############
    Modified by  Change Date 
    ****************************************************************************************/
    private static void setSubscriptionValues(List<Subscription__c> subs, Boolean isContinuous, String paymentType){

        Date subStartDate = Date.today().addMonths(-9).toStartOfWeek();
        Datetime myDate = datetime.newInstance(subStartDate.year(), subStartDate.month(), subStartDate.day());
        String day = myDate.format('EEEE');
        System.assertEquals('Monday', day, 'Sub should always start on a Monday');

    	for(Subscription__c sub : subs){
       		sub.Subscription_Status__c = Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS;
			sub.Start_Date__c          = subStartDate;
            sub.Cancellation_Date__c   = Date.today().addDays(-7);
			sub.Cancellation_Method__c = 'Phone';
			sub.Cancellation_Reason__c = 'Unknown';
            sub.isContinuous__c        = isContinuous;
            sub.Payment_Type__c        = paymentType;
       	}
		update subs;
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 24/05/2017
    Function - set account phone values
    #############Change Log#############
    Modified by  Change Date 
    ****************************************************************************************/
    private static void setAccountValues(List<Account> accounts, string phone){
    	for(Account acc : accounts){
       		acc.PersonHomePhone = phone;
            acc.PersonMobilePhone = phone;
            acc.Phone = phone;
       	}
       	update accounts;
    }
}