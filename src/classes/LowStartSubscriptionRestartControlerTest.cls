/**
* @author Wiktor Czykin
* @date 29/10/2015
* @description Test class for LowStartSubscriptionRestartController
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk	1.1			//removed payment type checkboxes 
**/
@isTest
private class LowStartSubscriptionRestartControlerTest {
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 29/10/2015
    Version - 1.0
    Function - test failure where no Id in the request 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testConstructorFailureNoId(){
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(new Subscription__c());
			LowStartSubscriptionRestartController lss;
			try{
				lss = new LowStartSubscriptionRestartController(std);
				System.assert(false, 'Exception not thrown where should be.');
			}catch(Exception e){
				System.assert(e.getMessage().contains(Label.Low_Start_Restart_feature_missing_subscription_id));
			}
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 29/10/2015
    Version - 1.0
    Function - test failure where id is present but record cannot be found for that Id
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testConstructorFailureNoRecordForId(){
		TestDataUtility td = new TestDataUtility(2);
		td.createSubscriptions();
		delete td.lstSubscriptions[1];
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(td.lstSubscriptions[1]);
			LowStartSubscriptionRestartController lss;
			try{
				lss = new LowStartSubscriptionRestartController(std);
				System.assert(false, 'Exception not thrown where should be.');
			}catch(Exception e){
				System.assert(e.getMessage().contains(Label.Low_Start_Restart_feature_no_subscription_based_on_id));
			}
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 29/10/2015
    Version - 1.0
    Function - test failure where subscription is found but it does not meet the criteria for processing
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testProcessFailureNotValidRecordForProcessing(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(td.lstSubscriptions[0]);
			LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
			System.assertEquals(td.lstSubscriptions[0].Id, lss.subscription.Id);
			System.assert(lss.sError.contains(Label.Low_Start_Feature_validation_required_status));
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 11/11/2015
    Version - 1.0
    Function - test warning when start date past extraction date
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testPastExtractionDateStartDateWarning(){
		TestDataUtility td = new TestDataUtility(1);
		td.checkSubscriptionDependencies();
		Subscription__c sub = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
		sub.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		sub.isContinuous__c = true; 
		sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
		insert sub;
		sub.Start_Date__c = Date.today().addDays(2);
		SubscriptionTriggerHandler.getInstance().isExecuting = true;
		update sub;
		SubscriptionTriggerHandler.getInstance().isExecuting = false;
		
		Test.startTest();
			General__c g = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
			System.assertNotEquals(null, g);
			g.Value__c = 'test';
			update g;
			PageReference pr = Page.LowStartSubscriptionRestart;
			Test.setCurrentPage(pr);
			ApexPages.StandardController std = new ApexPages.StandardController(sub);
			LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
			System.assertEquals(sub.Id, lss.subscription.Id);
			System.assert(lss.bPastSubscriptionWarning);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 29/10/2015
    Version - 1.0
    Function - test failure where mpp subscription id criteria is not met
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testProcessFailureMissingMPPSubscriptionId(){
		TestDataUtility td = new TestDataUtility(1);
		td.checkSubscriptionDependencies();
		Subscription__c sub = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
		sub.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		sub.isContinuous__c = true; 
		sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
		insert sub;
		Test.startTest();
			ApexPages.StandardController std = new ApexPages.StandardController(sub);
			LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
			System.assertEquals(sub.Id, lss.subscription.Id);
			System.assert(lss.sError.contains(Label.Low_Start_Feature_validation_MPP_Subscription_Id_mandatory));
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 30/10/2015
    Version - 1.0
    Function - test failure response from mpp request 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testMPPFailure(){
		TestDataUtility td = new TestDataUtility(1);
		List<PlaneURL__c> lstPlaneUrl = td.loadPlaneURL();
		td.checkSubscriptionDependencies();
		Subscription__c sub = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
		sub.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		sub.isContinuous__c = true; 
		sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
		sub.MPP_Premium_Subscription_Id__c = 'abc123';
		insert sub;
		
		ApexPages.StandardController std = new ApexPages.StandardController(sub);
		LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mppMock = new MPPWebserviceMocks.MPPHttpResponseGenerator(lstPlaneUrl[0].baseURL__c, new Map<String,String>{MPPWebserviceMocks.PARAM_ISFAILURE => 'true'});
			Test.setMock(HttpCalloutMock.class, mppMock);
			lss.processRestart();
			System.assert(lss.sError.contains(Label.Low_Start_Restart_feature_MPP_call_failure));
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 30/10/2015
    Version - 1.0
    Function - test success with DD payment subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSuccessDD(){
		TestDataUtility td = new TestDataUtility(1);
		List<PlaneURL__c> lstPlaneUrl = td.loadPlaneURL();
		td.createSubscriptionIncentiveAssociation();
		td.createTCodemanagement();
		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		td.lstSubscriptions[0].isContinuous__c = true; 
		td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING;
		td.lstSubscriptions[0].MPP_Premium_Subscription_Id__c = 'abc123';
		td.lstSubscriptions[0].TCode__c = td.lstTCodeManagement[0].Id;
		td.lstSubscriptions[0].Order_Taken_Method__c = 'otm';
		td.lstSubscriptions[0].PaymentDate__c = '1';
		update td.lstSubscriptions[0];
		
		ApexPages.StandardController std = new ApexPages.StandardController( td.lstSubscriptions[0]);
		LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mppMock = new MPPWebserviceMocks.MPPHttpResponseGenerator(lstPlaneUrl[0].baseURL__c, new Map<String,String>());
			Test.setMock(HttpCalloutMock.class, mppMock);
			PageReference pr = lss.processRestart();
			System.assertNotEquals(null, pr);
			System.assertEquals(td.lstTCodeManagement[0].Name, pr.getParameters().get('tcode'), pr.getParameters().get('tcode') );
			System.assertEquals(td.lstSubscriptions[0].Order_Taken_Method__c, pr.getParameters().get('orderMethod'));
			System.assertEquals('52'+Constants.KEY_CONTINUOUS, pr.getParameters().get('subscriptionType'));
			System.assertEquals('true',pr.getParameters().get('hasBack'));
			System.assertEquals( Constants.OFFER_LOWSTART, pr.getParameters().get('selectedOffer'));
			System.assertEquals(Constants.PRODUCT_PREMIUM, pr.getParameters().get('selectedProduct'));
			System.assert(String.isBlank(pr.getParameters().get('paymentFrequency')));
			System.assertEquals(Constants.SUB_ACQUISITION_PAYMENT_DD, pr.getParameters().get('paymentType'));
			System.assertEquals(td.lstSubscriptions[0].PaymentDate__c, pr.getParameters().get('paymentStartDate'));
			System.assertEquals(td.lstRetailers[0].RET_ID__c, pr.getParameters().get('retailerid'));
			System.assertEquals(td.lstIncentives[0].Id, pr.getParameters().get('incentiveId'));
		Test.stopTest();
		List<Subscription__c> lstSubscription = [select Id, Subscription_Status__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
		System.assert(!lstSubscription.isEmpty());
		System.assertEquals(Constants.SSTATUS_OFFERED, lstSubscription[0].Subscription_Status__c);
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 30/10/2015
    Version - 1.0
    Function - test success with CC payment subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSuccessCC(){
		TestDataUtility td = new TestDataUtility(1);
		List<PlaneURL__c> lstPlaneUrl = td.loadPlaneURL();
		td.createSubscriptions();
		td.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		td.lstSubscriptions[0].isContinuous__c = true; 
		td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING;
		td.lstSubscriptions[0].MPP_Premium_Subscription_Id__c = 'abc123';
		update td.lstSubscriptions[0];
		
		ApexPages.StandardController std = new ApexPages.StandardController( td.lstSubscriptions[0]);
		LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mppMock = new MPPWebserviceMocks.MPPHttpResponseGenerator(lstPlaneUrl[0].baseURL__c, new Map<String,String>());
			Test.setMock(HttpCalloutMock.class, mppMock);
			PageReference pr = lss.processRestart();
			System.assertEquals(Constants.DIRECTION_INBOUND, pr.getParameters().get('orderMethod'));
			System.assertEquals('52'+Constants.KEY_CONTINUOUS, pr.getParameters().get('subscriptionType'));
			System.assertEquals('true', pr.getParameters().get('hasBack'));
			System.assertEquals( Constants.OFFER_LOWSTART, pr.getParameters().get('selectedOffer'));
			System.assertEquals(Constants.PRODUCT_PREMIUM, pr.getParameters().get('selectedProduct'));
			System.assert(String.isBlank(pr.getParameters().get('paymentFrequency')));
			System.assertEquals(Constants.SUB_ACQUISITION_PAYMENT_CC, pr.getParameters().get('paymentType'));
			System.assertEquals(td.lstSubscriptions[0].PaymentDate__c, pr.getParameters().get('paymentStartDate'));
			System.assertEquals(td.lstRetailers[0].RET_ID__c, pr.getParameters().get('retailerid'));
			System.assert(String.isBlank(pr.getParameters().get('incentiveId')));
		Test.stopTest();
		List<Subscription__c> lstSubscription = [select Id, Subscription_Status__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
		System.assert(!lstSubscription.isEmpty());
		System.assertEquals(Constants.SSTATUS_OFFERED, lstSubscription[0].Subscription_Status__c);
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 30/10/2015
    Version - 1.0
    Function - test simulated failure on dmls
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFailureOnUpdate(){
		TestDataUtility td = new TestDataUtility(1);
		List<PlaneURL__c> lstPlaneUrl = td.loadPlaneURL();
		td.createSubscriptions();
		td.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		td.lstSubscriptions[0].isContinuous__c = true; 
		td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING;
		td.lstSubscriptions[0].MPP_Premium_Subscription_Id__c = 'abc123';
		update td.lstSubscriptions[0];
		
		ApexPages.StandardController std = new ApexPages.StandardController( td.lstSubscriptions[0]);
		LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
		lss.bTestFail = true;
		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mppMock = new MPPWebserviceMocks.MPPHttpResponseGenerator(lstPlaneUrl[0].baseURL__c, new Map<String,String>());
			Test.setMock(HttpCalloutMock.class, mppMock);
			PageReference pr = lss.processRestart();
		Test.stopTest();
		List<Subscription__c> lstSubscription = [select Id, Subscription_Status__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
		System.assert(!lstSubscription.isEmpty());
		System.assertNotEquals(Constants.SSTATUS_OFFERED, lstSubscription[0].Subscription_Status__c);
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 11/11/2015
    Version - 1.0
    Function - test success with DD payment subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSuccessDDWithTCodeChange(){
		TestDataUtility td = new TestDataUtility(2);
		List<PlaneURL__c> lstPlaneUrl = td.loadPlaneURL();
		td.createSubscriptionIncentiveAssociation();
		td.createTCodemanagement();
		td.checkSubscriptionDependencies();
		
		td.lstTCodeManagement[1].Type__c = Constants.TCODE_TYPE_LOWSTART;
		td.lstTCodeManagement[1].Low_Start_Period__c = '13';
		td.lstTCodeManagement[1].Low_Start_Weekly_Price__c = 9;
		td.lstTCodeManagement[1].Payment_Type__c =Constants.ALLOW_52_WEEK_DD;
		update td.lstTCodeManagement[1];
		
		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		td.lstSubscriptions[0].isContinuous__c = true; 
		td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_PENDING;
		td.lstSubscriptions[0].MPP_Premium_Subscription_Id__c = 'abc123';
		td.lstSubscriptions[0].TCode__c = td.lstTCodeManagement[0].Id;
		td.lstSubscriptions[0].Order_Taken_Method__c = 'otm';
		td.lstSubscriptions[0].PaymentDate__c = '1';
		update td.lstSubscriptions[0];
		
		ApexPages.StandardController std = new ApexPages.StandardController( td.lstSubscriptions[0]);
		LowStartSubscriptionRestartController lss = new LowStartSubscriptionRestartController(std);
		Test.startTest();
			lss.bChangeOffer = true;
			lss.subscriptionTemp.Low_Start_Amendment_TCode_Helper__c = td.lstTCodeManagement[1].Id;
		
			MPPWebserviceMocks.MPPHttpResponseGenerator mppMock = new MPPWebserviceMocks.MPPHttpResponseGenerator(lstPlaneUrl[0].baseURL__c, new Map<String,String>());
			Test.setMock(HttpCalloutMock.class, mppMock);
			PageReference pr = lss.processRestart();
			System.assertNotEquals(null, pr);
			System.assertEquals(td.lstTCodeManagement[1].Name, pr.getParameters().get('tcode'), pr.getParameters().get('tcode') );
			System.assertEquals(td.lstSubscriptions[0].Order_Taken_Method__c, pr.getParameters().get('orderMethod'));
			System.assertEquals('52'+Constants.KEY_CONTINUOUS, pr.getParameters().get('subscriptionType'));
			System.assertEquals('true',pr.getParameters().get('hasBack'));
			System.assertEquals( Constants.OFFER_LOWSTART, pr.getParameters().get('selectedOffer'));
			System.assertEquals(Constants.PRODUCT_PREMIUM, pr.getParameters().get('selectedProduct'));
			System.assert(String.isBlank(pr.getParameters().get('paymentFrequency')));
			System.assertEquals(Constants.SUB_ACQUISITION_PAYMENT_DD, pr.getParameters().get('paymentType'));
			System.assertEquals(td.lstSubscriptions[0].PaymentDate__c, pr.getParameters().get('paymentStartDate'));
			System.assertEquals(td.lstRetailers[0].RET_ID__c, pr.getParameters().get('retailerid'));
			System.assertEquals(td.lstIncentives[0].Id, pr.getParameters().get('incentiveId'));
		Test.stopTest();
		List<Subscription__c> lstSubscription = [select Id, Subscription_Status__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
		System.assert(!lstSubscription.isEmpty());
		System.assertEquals(Constants.SSTATUS_OFFERED, lstSubscription[0].Subscription_Status__c);
	}
}