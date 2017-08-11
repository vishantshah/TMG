/**
* @author Wiktor Czykin
* @date 14/05/2015
* @description Test class for SubscriberConsoleController -> methods mostly moved here from old SubscriberConsoleTest method
#############Change Log#############
Modified by     	Version     Change Date
Cristina Popescu 	1.1			25/06/2015	//increase code coverage
Wiktor Czykin		1.2			15/07/2015	//added constants across multiple methods
Wiktor Czykin		1.3			20/07/2015	//added coverarage for new method fixGuidInMPP()
Wiktor Czykin		1.4			14/10/2015	//fixes to test methods failing after TestDataUtility changes
Wiktor Czykin		1.5			25/02/2016	//removed references to old TestDataUtility methods
**/
@isTest
private class SubscriberConsoleControllerTest{
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015
    Version - 1.0
    Function - Replaced old init method with this one. Executes common initializations on TestDataUtility
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static void init(TestDataUtility td){
		td.loadPlaneURL();
		td.loadSubscriberConsoleSettings(null);
		td.loadSAMEntitlements();
		td.loadSAMHTTPSettings();
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date -  Unknown
    Version - 1.1
    Function - Test constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin 	1.1			15/05/2015	//changed initialization of test data
    ****************************************************************************************/
	private static testMethod void testConstructorKindaPositive() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		Test.startTest();	
			ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
			SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		Test.stopTest();		
	} 

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015
    Version - 1.0
    Function - Test constructor - missing custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testConstructorMissingSettings() {
		TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
		td.createIndividualSubscribers();

		Test.startTest();	
			try{
				ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
				SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
				System.assert(false, 'Error not thrown where should be.');
			}catch(Exception e){
				System.assert(e.getMessage().contains(Label.Diagnostic_Console_Missing_custom_settings));
			}
		Test.stopTest();		
	} 
	
	/*************************************************************************************** 
    Developer - Unknown
    Date -  Unknown
    Version - 1.1
    Function - Test getters
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin 	1.1			15/05/2015	//changed initialization of test data, added few more assertions
    ****************************************************************************************/
	private static testMethod void testGetters() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);

		SubscriberConsoleController controller = new SubscriberConsoleController();

		System.assertEquals(null, controller.dataInSF);
		System.assertEquals(null, controller.dataInMPP);
		System.assertEquals(null, controller.dataInSAM);
		System.assert(controller.showConsole);
		System.assert(!controller.problemFixed);
		System.assertEquals(controller.fixProblemReloaded, Label.FixProblemButton);
		controller.reloading = true;
		System.assertEquals(controller.fixProblemReloaded, Label.SuccessReloadingButton);
		System.assertEquals(controller.fixRuleLabel, Label.FixProblemDefaultDialog);
		controller.fixRule = SubscriberConsoleController.Fixes.GUID;
		System.assertEquals(controller.fixRuleLabel, Label.FixGUIDError);
		System.assert(!controller.alternateFixNeeded);
		System.assertEquals(controller.alternateFixLabel, Label.AlternateFixDefaultDialog);
		controller.alternateFixNeeded = true;
		System.assertEquals(controller.alternateFixLabel, Label.alternateFixGUID);
		System.assertEquals(controller.ErrorStyle, SubscriberConsoleController.redStyle);
		System.assertEquals(controller.ConfirmStyle, SubscriberConsoleController.greenStyle);
		System.assertEquals(null, controller.mppGuid);
		System.assertEquals(null, controller.SAMGuid);
		System.assertEquals(null, controller.mppSAMGuid);
		System.assertEquals(null, controller.mppTSNumber);
		System.assertEquals(null, controller.email);
		System.assertEquals(null, controller.ErrorLabel);	
		System.assertEquals(null, controller.EntitlementErrorLabel);
		System.assertEquals(null, controller.confirmMessage);
		System.assertEquals(null, controller.orderIdToFix);
		System.assertEquals(null, controller.paymentDateToFix);
		System.assertEquals(null, controller.netAmount);
		System.assertEquals(null, controller.newEntitlementForFix);
		System.assertEquals(null, controller.ruleName);
		System.assertEquals(null, controller.ruleUserMessage);
		System.assertEquals(null, controller.ruleCode);
		System.assertEquals(null, controller.ruleResultCode);
		System.assertEquals(null, controller.ruleData);
		System.assertEquals(null, controller.mppUserWrapper);
		System.assertEquals(null, controller.reportedTasks);
		System.assertEquals(null, controller.orderHistoryItemWrappers);
		System.assertEquals(null, controller.mppTotalNumberOfOrders);
		System.assertEquals(null, controller.mppTotalNumberOfOrders);

		System.assertEquals(null, controller.mppTransactionHistory);
		System.assertEquals(null, controller.sfTotalNumberOfOrders);
		System.assertEquals(null, controller.resultWrappers);
		System.assertEquals(null, controller.salesforceGUIDstyle);
		System.assertEquals(null, controller.MPPSAMGUIDstyle);
		System.assertEquals(null, controller.salesforceTSNumberStyle);
		System.assertEquals(null, controller.MPPTSNumberStyle);

		controller.setAvailableEntitlements = new Set<String>{'test1', 'test2'};
		List<SelectOption> lstOptions = controller.AvailableEntitlementsForDisplay;
		System.assertEquals(controller.setAvailableEntitlements.size(), lstOptions.size());

		controller.setCurrentEntitlements = new Set<String>{'test1', 'test2'};
		List<SelectOption> lstOptions2 = controller.CurrentEntitlementsForDisplay;
		System.assertEquals(controller.setCurrentEntitlements.size(), lstOptions2.size());
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - Test some minor methods just for coverage
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSimpleMethods() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		Test.startTest();	
			ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
			SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
			controller.refreshAll();
			System.assertEquals(null, controller.report());
			SubscriberConsoleController.ResultWrapper rw = new SubscriberConsoleController.ResultWrapper(null, false, false, 'test');
			System.assert(!rw.isError);
			System.assert(!rw.isReported);
			System.assertEquals(null, rw.subscriberRuleLog);

			SubscriberConsoleController.OrderHistoryItemWrapper ohiw = new SubscriberConsoleController.OrderHistoryItemWrapper(new MPPInterfaceHTTP.OrderHistoryItem());
			System.assertNotEquals(null, ohiw.orderHistoryItem);

			SubscriberConsoleController.MppUserWrapper muw = new SubscriberConsoleController.MppUserWrapper(null);
			System.assertEquals(null, muw.userInfoResult);

			System.assertNotEquals(null, controller.fixOrderHistoryDataInSFDCFromMPP());
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - Test initializationialiseEntitlementsTab() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testInitialiseEntitlementsTab() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		Test.startTest();
			SAMUtil.SAMAccountResult sar = new SAMUtil.SAMAccountResult();
			sar.guid = '1234';
			sar.entitlements = new List<String>{td.lstSAMEntitlements[0].Name, td.lstSAMEntitlements[1].Name};
			sar.entitlementStatus = 'Active';			
			controller.samUserWrapper = new SubscriberConsoleController.SamWrapper(sar);
			controller.initialiseEntitlementsTab();
		Test.stopTest();
		System.assertEquals(sar.entitlements.size(), controller.setCurrentEntitlements.size());
		System.assertEquals(td.lstSAMEntitlements.size(), (controller.setAvailableEntitlements.size()+controller.setCurrentEntitlements.size()));
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - Test adding of entitlements - positive
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testAddEntitlementsPositive() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);

		Test.startTest();
			SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(td.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
			controller.AvailableSelected.add(td.lstSAMEntitlements[0].Name);
			controller.AddEntitlements();
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - Test adding of entitlements - failure - wrong response on authentication
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testAddEntitlementsFailure() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);

		Test.startTest();
			StaticResourceCalloutMock srcm = SAMWebserviceMocks.getSAMEntitlementSuccessUpdateMock();
			Test.setMock(HttpCalloutMock.class, srcm); 
			controller.AvailableSelected.add(td.lstSAMEntitlements[0].Name);
			controller.AddEntitlements();
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - Test removal of entitlements - positive
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testRemoveEntitlementsPositive() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);

		Test.startTest();
			SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(td.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
			controller.CurrentSelected.add(td.lstSAMEntitlements[0].Name);
			controller.RemoveEntitlements();
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - Test removal of entitlements - failure - wrong response on authentication
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testRemoveEntitlementsFailure() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		Test.startTest();
			StaticResourceCalloutMock srcm = SAMWebserviceMocks.getSAMEntitlementSuccessUpdateMock();
			Test.setMock(HttpCalloutMock.class, srcm); 
			controller.CurrentSelected.add(td.lstSAMEntitlements[0].Name);
			controller.RemoveEntitlements();
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - test TSNumber fix - positive scenario 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFixTSNumberInMPPPositive() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();
		td.loadSubscriberValidationRuleInfo();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		controller.resultWrappers = new List<SubscriberConsoleController.ResultWrapper>();
		for(subscriberValidationRuleInfov2__c svr : td.lstSubscriberValidationRuleInfo){
			subscriberConsolesWebserviceHandlers.subscriberRuleLog log = new subscriberConsolesWebserviceHandlers.subscriberRuleLog();
			if(svr.Name == Constants.MPP_RULE_NAME_ID_FIELDS_EXIST){
				log.ruleCode = svr.Name;
				log.ruleResultCode = Constants.MPP_RULE_ID_FIELDS_EXIST_TSNUMBER_FAIL;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log, true, false, 'Link'));
			}else if(svr.Name == Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC){
				log.ruleCode = svr.Name;
				log.ruleResultCode = Constants.MPP_RULE_ID_FIELDS_INSYNC_TSNUMBER_FAIL;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log, true, false, 'Link'));
			}
		}
		Test.startTest();
			StaticResourceCalloutMock srcm = MPPWebserviceMocks.getMPPUserManageSuccessMock();
			Test.setMock(HttpCalloutMock.class, srcm);
			controller.fixTSNumberInMPP();
		Test.stopTest();
		Boolean bCheck = false;
		for(SubscriberConsoleController.ResultWrapper rs : controller.resultWrappers){
			if(	(rs.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_EXIST && rs.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_EXIST_TSNUMBER_FAIL)||
				(rs.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC && rs.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_INSYNC_TSNUMBER_FAIL)){
				System.assert(!rs.isError);
				bCheck = true;
			}	
		}
		System.assert(bCheck, 'Did not even enter the proper assertion.');
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - test TSNumber fix - failure in fix pre-req
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFixTSNumberNegativeNoEmail() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
		ath.bRunAPI = false;
		td.lstIndividualSubscribers[0].PersonEmail = null;
		update td.lstIndividualSubscribers[0];
		Test.startTest();
			ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
			SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
			controller.fixTSNumberInMPP();
		Test.stopTest();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Diagnostic_Console_TSNumber_fix_email_required), ApexPages.getMessages());
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  15/05/2015 
    Version - 1.0
    Function - test TSNumber fix - failure in fix callout test
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFixTSNumberNegativeCannotProcessUpdate() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		Test.startTest();
			StaticResourceCalloutMock srcm = MPPWebserviceMocks.getMPPUserManageFailureMock();
			Test.setMock(HttpCalloutMock.class, srcm);
			controller.fixTSNumberInMPP();
		Test.stopTest();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Diagnostic_Console_TSNumber_fix_unable_to_update_MPP_unknown_response), ApexPages.getMessages());
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date -  Unknown
    Version - 1.1
    Function - Test GUID fix dialog preparation with normal parameters
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			25/02/2016	//removed usage of 	()
    ****************************************************************************************/
	private static testMethod void testFixGUID() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);

		td.createDigitalSubscribers();
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstDigitalSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		
		Test.startTest();
			controller.FixGUID();
		Test.stopTest();
		
		System.assert(!controller.showConsole);
		controller.goBackToConsole();
		System.assert(controller.showConsole);
		System.assert(!controller.reloading);
		System.assertEquals(controller.fixRule, SubscriberConsoleController.Fixes.GUID);
		System.assertEquals(controller.mppSAMGuid, controller.SAMGUID);
	    System.assertEquals(controller.subscriberAccount.Guid__c, controller.SAMGuid);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test GUID fix dialog preparation with empty parameters
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			25/02/2016	//removed usage of insertAccountDigital()
    ****************************************************************************************/
	static testMethod void testFixGUIDEmptyParams() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createDigitalSubscribers();
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstDigitalSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		controller.mppSAMGUID = null;
		controller.mppTSNumber = null;
		
		Test.startTest();
			controller.FixGUID();
		Test.stopTest();
		
		System.assert(!controller.showConsole);
		controller.goBackToConsole();
		System.assert(controller.showConsole);
		System.assert(!controller.reloading);
		System.assertEquals(controller.fixRule, SubscriberConsoleController.Fixes.GUID);
		System.assert(controller.alternateFixNeeded);
		System.assertEquals(controller.mppSAMGuid, null);
	    System.assertEquals(controller.subscriberAccount.Guid__c, null);
	    System.assert(!controller.problemFixed);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date -  Unknown
    Version - 1.1
    Function - test doFixGUID()
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			16/05/2015	//made sure the update actually happens
    ****************************************************************************************/
	static testMethod void testdoFixGUID() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);

		List<Account> lstAcc = [select Id, Subscriber_Number_static__c from Account where Id =:td.lstIndividualSubscribers[0].Id];
		System.assert(lstAcc.size() == 1);
		controller.fixRule = SubscriberConsoleController.Fixes.GUID;
		controller.mppSAMGuid = 'x1';
		controller.mppTSNumber = lstAcc[0].Subscriber_Number_static__c;
		Test.startTest();
			controller.doFix();
		Test.stopTest();

		System.assert(controller.problemFixed);
		System.assert(controller.reloading);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test GUID fix with empty parameters
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			25/02/2016	//removed usage of insertAccountDigital()
    ****************************************************************************************/
	static testMethod void testdoFixGUIDEmptyParams() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createDigitalSubscribers();
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstDigitalSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		controller.fixRule = SubscriberConsoleController.Fixes.GUID;
		controller.mppSAMGUID = null;
		controller.mppTSNumber = null;
			
		Test.startTest();
			controller.doFix();
		Test.stopTest();

		System.assert(controller.problemFixed);
		System.assert(controller.reloading);
		System.assertNotEquals(0, [Select count() from Task]);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - //Test Entitlement fix with populated parameters
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			25/02/2016	//removed usage of insertAccountDigital()
    ****************************************************************************************/
	static testMethod void testdoEntitlementFix() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createDigitalSubscribers();
		td.lstDigitalSubscribers[0].Guid__c = 'someguid1';
		update td.lstDigitalSubscribers[0];
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstDigitalSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		
		Test.startTest();
			controller.newEntitlementForFix = 'TEST_ENTITLEMENT';
			controller.doEntitlementFix();
		Test.stopTest();

		System.assertEquals(controller.confirmMessage, String.format(Label.EntitlementChangeConfirm, new List<String>{'TEST_ENTITLEMENT'}));
		System.assert(String.isEmpty(controller.EntitlementErrorLabel));
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - //Test Entitlement fix with empty GUID
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			25/02/2016	//removed usage of insertAccountDigital()
    ****************************************************************************************/
	static testMethod void testdodoEntitlementFixEmptyGUID() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createDigitalSubscribers();
		Account acct = td.lstDigitalSubscribers[0];
		acct.Guid__c = null;
		update acct;
		ApexPages.StandardController stdController = new ApexPages.StandardController(acct);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
			
		Test.startTest();
			controller.newEntitlementForFix = 'TEST_ENTITLEMENT';
			controller.doEntitlementFix();
		Test.stopTest();

		System.assert(String.isEmpty(controller.confirmMessage));
		System.assertEquals(controller.EntitlementErrorLabel, Label.EntitlementChangeGUIDError);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - //Test Entitlement fix with empty Entitlement
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			25/02/2016	//removed usage of insertAccountDigital()
    ****************************************************************************************/
	static testMethod void testdodoEntitlementFixEmptyEntitlement() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createDigitalSubscribers();
		td.lstDigitalSubscribers[0].Guid__c = 'someguid1';
		update td.lstDigitalSubscribers[0];
		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstDigitalSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
			
		Test.startTest();
			controller.newEntitlementForFix = null;
			controller.doEntitlementFix();
		Test.stopTest();

		System.assert(String.isEmpty(controller.confirmMessage));
		System.assertEquals(controller.EntitlementErrorLabel, Label.EntitlementChangeSelectError);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date -  24/06/2015 
    Version - 1.0
    Function - test entitlement response from sam for digital account
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	static testMethod void testEntitlementsForDigitalSub(){
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.loadEntitlementsSettings();
		td.loadSubscriberValidationRuleInfo();
		SAMUtil.SAMAccountResult successSAMResultDigital = new SAMUtil.SAMAccountResult();
        successSAMResultDigital.guid = 'GUID_TEST';
        successSAMResultDigital.entitlements = new List<String>{'DIGITAL_SUBSCRIBER_ACTIVE'};
        List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog> logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
		SubscriberConsolesWebserviceHandlers ctrl = new SubscriberConsolesWebserviceHandlers();
		//active account - active sam entitlement
		Account accDigital = TestDataUtility.newPersonAccount(1,RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName()));
		accDigital.Subscriber_Digital_Status__c = 'Active';
		insert accDigital;
		Test.startTest();
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForDigitalSub(successSAMResultDigital,accDigital,logs);
			System.assertEquals('100',logs[0].ruleResultCode);
			
			successSAMResultDigital.entitlements = new List<String>{'DIGITAL_SUBSCRIBER_INACTIVE'};
	       	logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
			//inactive account - inactive sam entitlement
			accDigital.Subscriber_Digital_Status__c = 'Inactive'; 
			update accDigital;
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForDigitalSub(successSAMResultDigital,accDigital,logs);
			System.assertEquals('100',logs[0].ruleResultCode);
			
			//active account - inactive sam entitlement
			logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
			accDigital.Subscriber_Digital_Status__c = 'Active'; 
			update accDigital;
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForDigitalSub(successSAMResultDigital,accDigital,logs);
			System.assertEquals('500',logs[0].ruleResultCode);
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date -  24/06/2015 
    Version - 1.2
    Function - test entitlement response code 200 from sam for print account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/07/2015	//added constants
    Wiktor Czykin	1.2			14/10/2015	//changed how account and subscription is created
    ****************************************************************************************/
	static testMethod void testPositiveSAMCodeForPrintSub(){
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.loadEntitlementsSettings();
		td.loadSubscriberValidationRuleInfo();
		SAMUtil.SAMAccountResult successSAMResultPrint = new SAMUtil.SAMAccountResult();
        successSAMResultPrint.guid = 'GUID_TEST';
        successSAMResultPrint.entitlements = new List<String>{'7DAY_SUBSCRIBER_ACTIVE'};
        List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog> logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
		//active subscription - active sam entitlement
		td.checkSubscriptionDependencies();
		Subscription__c subscription = TestDataUtility.newSubscripiton(1, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, System.today());
		insert subscription;
		Account accPrint = [SELECT Id, Subscription_Status__c FROM Account WHERE Id =: td.lstIndividualSubscribers[0].Id];
		Test.startTest();	
			System.assertEquals('Active',accPrint.Subscription_Status__c);
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(successSAMResultPrint,accPrint,logs);
			System.assertEquals(Constants.SAM_ENT_RULE_OK, logs[0].ruleResultCode);
			
			successSAMResultPrint.entitlements = new List<String>{'7DAY_SUBSCRIBER_LAPSED'};
	       	logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
			//Inactive subscription - Inactive sam entitlement
			subscription.Subscription_Status__c = 'Lapsed'; 
			update subscription;
			accPrint = [SELECT Id, Subscription_Status__c FROM Account WHERE Id =: accPrint.Id];
			System.assertEquals('Inactive',accPrint.Subscription_Status__c);
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(successSAMResultPrint,accPrint,logs);
			System.assertEquals(Constants.SAM_ENT_RULE_OK, logs[0].ruleResultCode);
			
			successSAMResultPrint.entitlements = new List<String>{'7DAY_SUBSCRIBER_PENDING'};
	       	logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
			//Pending subscription - Pending sam entitlement
			subscription.Subscription_Status__c = 'Pending'; 
			update subscription;
			accPrint = [SELECT Id, Subscription_Status__c FROM Account WHERE Id =: accPrint.Id];
			System.assertEquals('Pending',accPrint.Subscription_Status__c);
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(successSAMResultPrint,accPrint,logs);
			System.assertEquals(Constants.SAM_ENT_RULE_OK, logs[0].ruleResultCode);
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date -  25/06/2015 
    Version - 1.1
    Function - test entitlement response code 300 from sam for print account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/07/2015	//added constants
    Wiktor Czykin	1.1			14/10/2015	//changed how account and subscription is created
    ****************************************************************************************/
	static testMethod void testActiveAccountLapsedEntitlementSAMCodeForPrintSub(){
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.loadEntitlementsSettings();
		td.loadSubscriberValidationRuleInfo();
		SAMUtil.SAMAccountResult successSAMResultPrint = new SAMUtil.SAMAccountResult();
        successSAMResultPrint.guid = 'GUID_TEST';
        successSAMResultPrint.entitlements = new List<String>{'7DAY_SUBSCRIBER_LAPSED'};
        List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog> logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
		td.createSubscriptions();
		Account accPrint = [SELECT Id, Subscription_Status__c FROM Account WHERE Id =: td.lstIndividualSubscribers[0].Id];
		System.assertEquals('Active',accPrint.Subscription_Status__c);
		Test.startTest();	
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(successSAMResultPrint,accPrint,logs);
		Test.stopTest();
		System.assertEquals(Constants.SAM_ENT_RULE_ACTIVE_ACCOUNT_LAPSED_ENTITLEMENTS, logs[0].ruleResultCode);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date -  25/06/2015 
    Version - 1.2
    Function - test entitlement response from sam code 600 for print account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/07/2015	//added constants
    Wiktor Czykin	1.2			14/10/2015	//changed how account and subscription is created
    ****************************************************************************************/
	static testMethod void testInactiveAccountActiveEntitlementsSAMCodeForPrintSub(){
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.loadEntitlementsSettings();
		td.loadSubscriberValidationRuleInfo();
		SAMUtil.SAMAccountResult successSAMResultPrint = new SAMUtil.SAMAccountResult();
        successSAMResultPrint.guid = 'GUID_TEST';
        successSAMResultPrint.entitlements = new List<String>{'7DAY_SUBSCRIBER_ACTIVE'};
        List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog> logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
		//active subscription - active sam entitlement
		td.checkSubscriptionDependencies();
		Subscription__c subscription = TestDataUtility.newSubscripiton(1,td.lstIndividualSubscribers[0].Id,td.lstRetailers[0].Id, System.today());
		subscription.Subscription_Status__c = 'Lapsed'; 
		insert subscription;
		Account accPrint = [SELECT Id, Subscription_Status__c FROM Account WHERE Id =: td.lstIndividualSubscribers[0].Id];
		System.assertEquals('Inactive',accPrint.Subscription_Status__c);
		Test.startTest();
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(successSAMResultPrint,accPrint,logs);
		Test.stopTest();
		System.assertEquals(Constants.SAM_ENT_RULE_INACTIVE_ACCOUNT_ACTIVE_ENTITLEMENTS, logs[0].ruleResultCode);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date -  25/06/2015 
    Version - 1.2
    Function - test entitlement response from sam code 700 for print account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/07/2015	//added constants
    Wiktor Czykin	1.2			14/10/2015	//changed how account and subscription is created
    ****************************************************************************************/
	static testMethod void testPendingAccountLapsedEntitlementsSAMCodeForPrintSub(){
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.loadEntitlementsSettings();
		td.loadSubscriberValidationRuleInfo();
		SAMUtil.SAMAccountResult successSAMResultPrint = new SAMUtil.SAMAccountResult();
        successSAMResultPrint.guid = 'GUID_TEST';
        successSAMResultPrint.entitlements = new List<String>{'7DAY_SUBSCRIBER_LAPSED'};
        List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog> logs = new List<SubscriberConsolesWebserviceHandlers.SubscriberRuleLog>();
		//active subscription - active sam entitlement
		td.checkSubscriptionDependencies();
		Subscription__c subscription = TestDataUtility.newSubscripiton(1, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, System.today());
		subscription.Subscription_Status__c = 'Pending'; 
		insert subscription;
		Account accPrint = [SELECT Id, Subscription_Status__c FROM Account WHERE Id =: td.lstIndividualSubscribers[0].Id];
		System.assertEquals('Pending',accPrint.Subscription_Status__c);
		Test.startTest();
			logs = SubscriberConsolesWebserviceHandlers.checkEntitlementsForPrintSub(successSAMResultPrint,accPrint,logs);
		Test.stopTest();
		System.assertEquals(Constants.SAM_ENT_RULE_PENDING_ACCOUNT_LAPSED_ENTITLEMENTS, logs[0].ruleResultCode);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date -  25/06/2015 
    Version - 1.1
    Function - test entitlement response from sam code 700 for print account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			14/10/2015	//changed how account and subscription is created
    ****************************************************************************************/
	static testMethod void testCalculateTotalSFOrders(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
		td.createSubscriptions();
		MPP_Transaction_History__c transHistory = TestDataUtility.newMPPTransactionHistory(1, td.lstIndividualSubscribers[0].Id, td.lstSubscriptions[0].Id,'Debit Card');
		insert transHistory;
		List<MPP_Transaction_History__c> transactions = new List<MPP_Transaction_History__c>{transHistory};
		Test.startTest();
			SubscriberConsolesWebserviceHandlers.orderTotals ot = SubscriberConsolesWebserviceHandlers.calculateTotalSFOrders(transactions);
		Test.stopTest();
		System.assertEquals(100,ot.overallPriceTotal);
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  20/07/2015 
    Version - 1.0
    Function - test guid fix - positive scenario 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFixGuidInMPPPositive() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();
		td.loadSubscriberValidationRuleInfo();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		controller.resultWrappers = new List<SubscriberConsoleController.ResultWrapper>();
		for(subscriberValidationRuleInfov2__c svr : td.lstSubscriberValidationRuleInfo){
			
			if(svr.Name == Constants.MPP_RULE_NAME_ID_FIELDS_EXIST){
				subscriberConsolesWebserviceHandlers.subscriberRuleLog log = new subscriberConsolesWebserviceHandlers.subscriberRuleLog();
				log.ruleCode = svr.Name;
				log.ruleResultCode = Constants.MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_MPP;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log, true, false, 'Link'));

				subscriberConsolesWebserviceHandlers.subscriberRuleLog log2 = new subscriberConsolesWebserviceHandlers.subscriberRuleLog();
				log2.ruleCode = svr.Name;
				log2.ruleResultCode = Constants.MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_SFDC_MPP;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log2, true, false, 'Link'));
			}else if(svr.Name == Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC){
				subscriberConsolesWebserviceHandlers.subscriberRuleLog log = new subscriberConsolesWebserviceHandlers.subscriberRuleLog();
				log.ruleCode = svr.Name;
				log.ruleResultCode = Constants.MPP_RULE_ID_FIELDS_INSYNC_GUID_FAIL;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log, true, false, 'Link'));
			}else if(svr.Name == Constants.SFDC_RULE_NAME_GUID_VALIDATION){
				subscriberConsolesWebserviceHandlers.subscriberRuleLog log = new subscriberConsolesWebserviceHandlers.subscriberRuleLog();
				log.ruleCode = svr.Name;
				log.ruleResultCode = Constants.SFDC_RULE_GUID_VALIDATION_NOGUID;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log, true, false, 'Link'));
				
				subscriberConsolesWebserviceHandlers.subscriberRuleLog log2 = new subscriberConsolesWebserviceHandlers.subscriberRuleLog();
				log2.ruleCode = svr.Name;
				log2.ruleResultCode = Constants.SFDC_RULE_GUID_VALIDATION_NOTMATCHINGGUID;
				controller.resultWrappers.add(new SubscriberConsoleController.ResultWrapper(log2, true, false, 'Link'));
			}
		}
		Test.startTest();
			StaticResourceCalloutMock srcm = MPPWebserviceMocks.getMPPUserManageSuccessMock();
			Test.setMock(HttpCalloutMock.class, srcm);
			controller.fixGuidInMPP();
		Test.stopTest();
		Boolean bCheck = false;
		for(SubscriberConsoleController.ResultWrapper rs : controller.resultWrappers){
			if(	(rs.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_EXIST && (rs.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_MPP || rs.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_EXIST_NO_GUID_IN_SFDC_MPP))||
				(rs.subscriberRuleLog.ruleCode == Constants.MPP_RULE_NAME_ID_FIELDS_INSYNC && rs.subscriberRuleLog.ruleResultCode == Constants.MPP_RULE_ID_FIELDS_INSYNC_GUID_FAIL) ||
				(rs.subscriberRuleLog.ruleCode == Constants.SFDC_RULE_NAME_GUID_VALIDATION && (rs.subscriberRuleLog.ruleResultCode == Constants.SFDC_RULE_GUID_VALIDATION_NOGUID ||  rs.subscriberRuleLog.ruleResultCode == Constants.SFDC_RULE_GUID_VALIDATION_NOTMATCHINGGUID))
				){
				System.assert(!rs.isError);
				bCheck = true;
			}	
		}

		List<Account> lstAccount = [select Id, Guid__c from Account where Id =:td.lstIndividualSubscribers];
		System.assert(!lstAccount.isEmpty() && lstAccount.size() == 1);
		System.assert(String.isNotBlank(lstAccount[0].Guid__c));
		System.assert(bCheck, 'Did not even enter the proper assertion.');
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  20/07/2015 
    Version - 1.0
    Function - test guid fix - failure in fix pre-req
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFixGuidNegativeNoEmail() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
		ath.bRunAPI = false;
		td.lstIndividualSubscribers[0].PersonEmail = null;
		update td.lstIndividualSubscribers[0];
		Test.startTest();
			ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
			SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
			controller.fixGuidInMPP();
		Test.stopTest();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Diagnostic_Console_Guid_fix_email_required), ApexPages.getMessages());
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  20/07/2015 
    Version - 1.0
    Function - test guid fix - failure in fix callout test
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testFixGuidNegativeCannotProcessUpdate() {
		TestDataUtility td = new TestDataUtility(1);
		init(td);
		td.createIndividualSubscribers();

		ApexPages.StandardController stdController = new ApexPages.StandardController(td.lstIndividualSubscribers[0]);
		SubscriberConsoleController controller = new SubscriberConsoleController(stdController);
		Test.startTest();
			StaticResourceCalloutMock srcm = MPPWebserviceMocks.getMPPUserManageFailureMock();
			Test.setMock(HttpCalloutMock.class, srcm);
			controller.fixGuidInMPP();
		Test.stopTest();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Diagnostic_Console_GUID_fix_unable_to_update_MPP_unknown_response), ApexPages.getMessages());
	}
}