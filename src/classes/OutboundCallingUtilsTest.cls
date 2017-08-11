/************************************************************************************
Class Name   : OutboundCallingUtilsTest
Author       : Mantas Grigaliunas
Created Date : 18/07/2016
Function     : OutboundCallingUtils class unit test
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    		Date        Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas/Vishant	26/05/2017  Added methods below
								getOutboundCallingCaseRecordTypesIdsTest
								getOutboundCallingSettingTest
								outboundCallSettingsNoSettingParameterTest
								ouboundCallSettingDoesNotExistTest
								getOutboundCallSettingsNoSettingRuleTest
								getOutboundCallSettingIncorrectParameterTest
								addPageMessageTest
								addPageMessageWithSystemDebugTest
								addPageMessageStringFormatTest
								addPageMessageDatabaseErrorTest
								generateErrorMessage
*************************************************************************************/

@isTest
private class OutboundCallingUtilsTest {

	public static final String TEST_MESSAGE = 'Test';

	/************************************************************************************
	Method Name  : testSetup
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@testSetup static void testSetup(){

		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createSalesOutboundCallSetting();
		tdu.createOutboundCallRule();
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersByRecordTypeIdMapDefined
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersByRecordTypeIdMapDefined() {
		
		Test.startTest();
			OutboundCallingUtils.defineOutboundCallSettingParameters();
			System.assert(OutboundCallingUtils.recordTypeIdToParametersMap.size() == 1, 'OutboundCallingUtils.recordTypeIdToParametersMap is empty');
			System.assert(OutboundCallingUtils.settingRecordIdToParametersMap.size() == 1, 'OutboundCallingUtils.settingRecordIdToParametersMap is empty');
			System.assertEquals(
				Constants.OC_MAX_NUMBER_OF_STAGES,
				OutboundCallingUtils.getCallStageParametersByRecordTypeId(
					RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName())).size()
			);
		Test.stopTest();		
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersByRecordTypeIdMapNotDefined
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersByRecordTypeIdMapNotDefined() {
		
		Test.startTest();
			System.assert(OutboundCallingUtils.recordTypeIdToParametersMap == null, 'OutboundCallingUtils.recordTypeIdToParametersMap expected to be null');
			System.assert(OutboundCallingUtils.settingRecordIdToParametersMap == null, 'OutboundCallingUtils.settingRecordIdToParametersMap expected to be null');
			System.assertEquals(
				Constants.OC_MAX_NUMBER_OF_STAGES,
				OutboundCallingUtils.getCallStageParametersByRecordTypeId(
					RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName())).size()
			);
		Test.stopTest();		
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersByOCsettingIdMapDefined
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersByOCsettingIdMapDefined() {
	
		Test.startTest();
			OutboundCallingUtils.defineOutboundCallSettingParameters();
			System.assert(OutboundCallingUtils.recordTypeIdToParametersMap.size() == 1, 'OutboundCallingUtils.recordTypeIdToParametersMap is empty');
			System.assert(OutboundCallingUtils.settingRecordIdToParametersMap.size() == 1, 'OutboundCallingUtils.settingRecordIdToParametersMap is empty');
			System.assertEquals(
				Constants.OC_MAX_NUMBER_OF_STAGES,
				OutboundCallingUtils.getCallStageParametersByOCsettingId([SELECT Id FROM Outbound_Call_Setting__c].Id).size()
			);
		Test.stopTest();		
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersByOCsettingIdMapNotDefined
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersByOCsettingIdMapNotDefined() {

		Test.startTest();
			System.assert(OutboundCallingUtils.recordTypeIdToParametersMap == null, 'OutboundCallingUtils.recordTypeIdToParametersMap expected to be null');
			System.assert(OutboundCallingUtils.settingRecordIdToParametersMap == null, 'OutboundCallingUtils.settingRecordIdToParametersMap expected to be null');
			System.assertEquals(
				Constants.OC_MAX_NUMBER_OF_STAGES,
				OutboundCallingUtils.getCallStageParametersByOCsettingId([SELECT Id FROM Outbound_Call_Setting__c].Id).size()
			);
		Test.stopTest();		
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersJSONObjectEmpty
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersJSONObjectEmpty(){

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);

		ocSetting.Parameters__c = '{"callStageParameters" :[]}';
		update ocSetting;

		Test.startTest();
			try{

				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');

			} catch(TelegraphApplicationException e){	
				System.assertEquals(
						generateErrorMessage(Label.Outbound_Call_Setting_JSON_Object_Empty, 
							new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
												 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME }),
						e.getMessage()
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersExpectedJSONParameterNotDefined
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersExpectedJSONParameterNotDefined(){

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);

		ocSetting.Parameters__c = '{}';
		update ocSetting;

		Test.startTest();
			try{
				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');
			} catch(TelegraphApplicationException e){	
				System.assertEquals(
						generateErrorMessage(Label.Outbound_Call_Setting_JSON_Object_Not_Defined, 
							new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
												 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME }),
						e.getMessage()
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetOutboundCallSettingParametersJSONException
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetOutboundCallSettingParametersJSONException() {

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);


		ocSetting.Parameters__c = '{ "callStageParameters" : ['+
		+		'{ 	"incorrect" 	: "T2",'	
		+		'	"outcome" 		: "OC_Stage_1_Outcome__c",'
		+		'	"calldatetime" 	: "OC_Stage_1_Call_Date_Time__c",'
		+       '	"offset"		: -28 } ] }';
		update ocSetting;

		Test.startTest();
			try{
				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');
			} catch(TelegraphApplicationException e){
				System.assert(e.getMessage().contains(generateErrorMessage(Label.Outbound_Call_Setting_JSON_Deserialize_Exception, 
									new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, ''}))
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersJSONEmptyParamter
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersJSONEmptyParamter(){

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);

		ocSetting.Parameters__c = '{ "callStageParameters" : ['+
		+		'{ 	"stagename" 	: "",'	
		+		'	"outcome" 		: "OC_Stage_1_Outcome__c",'
		+		'	"calldatetime" 	: "OC_Stage_1_Call_Date_Time__c",'
		+       '	"offset"		: -28 } ] }';
		update ocSetting;

		Test.startTest();
			try{
				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');
			} catch(TelegraphApplicationException e){	
				System.assertEquals(
						generateErrorMessage(Label.Outbound_Call_Setting_JSON_Object_Empty_Parameter, 
							new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
												 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME }),
						e.getMessage()
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersJSONInvalidStagename
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersJSONInvalidStagename(){

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);

		ocSetting.Parameters__c = '{ "callStageParameters" : ['+
		+		'{ 	"stagename" 	: "Wrong Stage Name",'	
		+		'	"outcome" 		: "OC_Stage_1_Outcome__c",'
		+		'	"calldatetime" 	: "OC_Stage_1_Call_Date_Time__c",'
		+       '	"offset"		: -28 } ] }';
		update ocSetting;

		System.assert(OutboundCallingUtils.settingsList == null, 'OutboundCallingUtils.settingsList expected to be null');

		Test.startTest();
			try{
				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');
			} catch(TelegraphApplicationException e){	
				System.debug('testGetCallStageParametersJSONInvalidParamter :::' + e.getMessage());
				System.assert(e.getMessage().contains(generateErrorMessage(Label.Outbound_Call_Setting_Invalid_JSON_Parameter, 
							new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
												 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME, ''}))
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersJSONInvalidOutcome
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersJSONInvalidOutcome(){

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);

		ocSetting.Parameters__c = '{ "callStageParameters" : ['+
		+		'{ 	"stagename" 	: "T2",'	
		+		'	"outcome" 		: "Wrong_Outcome__c",'
		+		'	"calldatetime" 	: "OC_Stage_1_Call_Date_Time__c",'
		+       '	"offset"		: -28 } ] }';
		update ocSetting;

		System.assert(OutboundCallingUtils.settingsList == null, 'OutboundCallingUtils.settingsList expected to be null');

		Test.startTest();
			try{
				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');
			} catch(TelegraphApplicationException e){	
				System.debug('testGetCallStageParametersJSONInvalidParamter :::' + e.getMessage());
				System.assert(e.getMessage().contains(generateErrorMessage(Label.Outbound_Call_Setting_Invalid_JSON_Parameter, 
							new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
												 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME, ''}))
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCallStageParametersJSONInvalidDatetime
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCallStageParametersJSONInvalidDatetime(){

		List<Outbound_Call_Setting__c> ocSettings = new List<Outbound_Call_Setting__c>([SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c]);
		System.assert(ocSettings.size() == 1, 'Outbound_Call_Setting__c list is empty');
		Outbound_Call_Setting__c ocSetting = ocSettings.get(0);

		ocSetting.Parameters__c = '{ "callStageParameters" : ['+
		+		'{ 	"stagename" 	: "T2",'	
		+		'	"outcome" 		: "OC_Stage_1_Outcome__c",'
		+		'	"calldatetime" 	: "Wrong_Date_Time__c",'
		+       '	"offset"		: -28 } ] }';
		update ocSetting;

		System.assert(OutboundCallingUtils.settingsList == null, 'OutboundCallingUtils.settingsList expected to be null');

		Test.startTest();
			try{
				OutboundCallingUtils.defineOutboundCallSettingParameters();
				System.assert(false, 'Exception expected');
			} catch(TelegraphApplicationException e){	
				System.assert(e.getMessage().contains(generateErrorMessage(Label.Outbound_Call_Setting_Invalid_JSON_Parameter, 
							new List<String>{ OutboundCallingUtils.OUTBOUND_CALL_SETTINGS_OBJECT_NAME, ocSetting.Name, 
												 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME, ''}))
				);
			}
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getOutboundCallingCaseRecordTypesIdsTest
	Author       : Mantas Grigaliunas
	Created Date : 26/05/2017
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getOutboundCallingCaseRecordTypesIdsTest(){
		Test.startTest();
		System.assertEquals(1, OutboundCallingUtils.getOutboundCallingCaseRecordTypesIds().size());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getOutboundCallingSettingTest
	Author       : Mantas Grigaliunas
	Created Date : 26/05/2017
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getOutboundCallingSettingTest(){
		Test.startTest();
		System.assertEquals(1, OutboundCallingUtils.getOutboundCallSetting(Constants.OC_SALES_VF_PAGE_NAME).size(), ApexPages.getMessages());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : outboundCallSettingsNoSettingParameterTest
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void outboundCallSettingsNoSettingParameterTest() {
		
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name, Parameters__c FROM Outbound_Call_Setting__c LIMIT 1];
		ocSetting.Parameters__c = null;
		update ocSetting;
 
		Test.startTest();
		OutboundCallingUtils.getOutboundCallSetting(Constants.OC_SALES_VF_PAGE_NAME);
		String message = String.format(Label.Outbound_Calling_Missing_Setting_Parameters, new List<String>{ocSetting.Name});
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : ouboundCallSettingDoesNotExistTest
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void ouboundCallSettingDoesNotExistTest() {

		delete [SELECT Id FROM Outbound_Call_Setting__c];

		Test.startTest();
		OutboundCallingUtils.getOutboundCallSetting(Constants.OC_SALES_VF_PAGE_NAME);
		String message = String.format(Label.Outbound_Calling_Missing_Setting_Record, new List<String>{Constants.OC_SALES_VF_PAGE_NAME});
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message), ApexPages.getMessages());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getOutboundCallSettingsNoSettingRuleTest
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getOutboundCallSettingsNoSettingRuleTest() {

		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1];
		Outbound_Call_Rule__c ocRule       = [SELECT Id FROM Outbound_Call_Rule__c LIMIT 1];
		ocRule.Active__c                   = false;
		update ocRule;

		Test.startTest();
		OutboundCallingUtils.getOutboundCallSetting(Constants.OC_SALES_VF_PAGE_NAME);
		String message = String.format(Label.Outbound_Calling_Missing_Setting_Rule, new List<String>{ocSetting.Name});
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : getOutboundCallSettingIncorrectParameterTest
	Author       : Vishant Shah
	Created Date : 16/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void getOutboundCallSettingIncorrectParameterTest() {

		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1]; 
		ocSetting.Parameters__c            = 'Incorrect string';
		update ocSetting;

		Test.startTest();
		OutboundCallingUtils.getOutboundCallSetting(Constants.OC_SALES_VF_PAGE_NAME);
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Unable to extract parameters'));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : addPageMessageTest
	Description  : test if incorrect parameter set in OC Settings.
	Author       : Mantas Grigaliunas
	Created Date : 26/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void addPageMessageTest() {

		Test.startTest();
		OutboundCallingUtils.addPageMessage(Constants.ERROR, TEST_MESSAGE);
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), TEST_MESSAGE));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : addPageMessageWithSystemDebugTest
	Author       : Mantas Grigaliunas
	Created Date : 26/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void addPageMessageWithSystemDebugTest() {

		Test.startTest();
		OutboundCallingUtils.addPageMessage(Constants.ERROR, TEST_MESSAGE, TEST_MESSAGE);
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), TEST_MESSAGE));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : addPageMessageStringFormatTest
	Author       : Mantas Grigaliunas
	Created Date : 26/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void addPageMessageStringFormatTest() {

		String formatTestMessage = TEST_MESSAGE + '{0}';

		Test.startTest();
		OutboundCallingUtils.addPageMessage(Constants.ERROR, formatTestMessage, new List<String>{TEST_MESSAGE});
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), TEST_MESSAGE+TEST_MESSAGE));
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : addPageMessageDatabaseErrorTest
	Author       : Mantas Grigaliunas
	Created Date : 26/05/2017
	Change Log:
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void addPageMessageDatabaseErrorTest() {
		Test.startTest();
		OutboundCallingUtils.addPageMessage(Constants.ERROR, new List<Database.Error>());
		System.assertEquals(0, ApexPages.getMessages().size());
		Test.stopTest();
	}


	/************************************************************************************
	Method Name  : generateErrorMessage
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	public static String generateErrorMessage(String errorMessage, List<String> messageParameters){
		return String.format(errorMessage, messageParameters);
	}
}