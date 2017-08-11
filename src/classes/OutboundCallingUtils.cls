/************************************************************************************
Class Name   : OutboundCallingUtils
Author       : Mantas Grigaliunas
Created Date : 18/07/2016
Function     : Utility class for Outbound Calling functionality
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas G.    25/05/2017	added getOutboundCallSetting, addPageMessage & addSystemLogMessage
* Vishant Shah 13/06/2017   Added caseClassification to update Case fields based on OCS.Case_Field_Map__c
*************************************************************************************/

public class OutboundCallingUtils {

	@TestVisible private static final String OUTBOUND_CALL_SETTINGS_OBJECT_NAME = Outbound_Call_Setting__c.SobjectType.getDescribe().getLabelPlural();
	@TestVisible private static String OUTBOUND_CALL_SETTING_RECORD_NAME;
	@TestVisible private static Set<String> caseFields; 									//set of all case field api names
	@TestVisible private static Set<String> stagePicklistValues; 							//set of Call_Stage__c picklist values
	@TestVisible private static List<Outbound_Call_Setting__c> settingsList;
	@TestVisible private static Map<String, Map<String, String>> caseRecordTypeFieldMap;

	public static Map<Id, List<OutboundCallingBean.CallStageMapping>> recordTypeIdToParametersMap;
	public static Map<Id, List<OutboundCallingBean.CallStageMapping>> settingRecordIdToParametersMap;

	/************************************************************************************
	Method Name  : getCallStageParametersByRecordTypeId
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return JSON defined parameters list mapped to case record type specified in Outbound_Call_Setting__c
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	public static List<OutboundCallingBean.CallStageMapping> getCallStageParametersByRecordTypeId(Id recTypeId){
		if(recordTypeIdToParametersMap != null){
			return recordTypeIdToParametersMap.get(recTypeId);
		} else {		
			defineOutboundCallSettingParameters();
			return recordTypeIdToParametersMap.get(recTypeId);
		}
	}

	/************************************************************************************
	Method Name  : getCallStageParametersByOCsettingId
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return JSON defined parameters list mapped to Outbound_Call_Setting__c record id
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	public static List<OutboundCallingBean.CallStageMapping> getCallStageParametersByOCsettingId(Id ocSettingId){
		if(settingRecordIdToParametersMap != null){
			return settingRecordIdToParametersMap.get(ocSettingId);
		} else {		
			defineOutboundCallSettingParameters();
			return settingRecordIdToParametersMap.get(ocSettingId);
		}
	}

	/************************************************************************************
	Method Name  : defineOutboundCallSettingParameters
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to define JSON parameters object maps
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	public static void defineOutboundCallSettingParameters(){
		
		if(settingsList == null){
			settingsList = getOutboundCallSettingsList();
		}

		if(!settingsList.isEmpty()){
			Map<String, String> rtNametoIdMap = new Map<String, String>(getRecordTypeToIdMap());
			recordTypeIdToParametersMap = new Map<Id, List<OutboundCallingBean.CallStageMapping>>();
			settingRecordIdToParametersMap = new Map<Id, List<OutboundCallingBean.CallStageMapping>>();

			//define validation data
			caseFields = Schema.SObjectType.Case.fields.getMap().keySet();
			stagePicklistValues = getCallStagePicklistValues();

			for(Outbound_Call_Setting__c ocs : settingsList){
				String parameters = ocs.Parameters__c;
				if(!String.isEmpty(parameters)){
					List<OutboundCallingBean.CallStageMapping> parametersObject = getCallStageParameters(parameters, ocs.Name);
					recordTypeIdToParametersMap.put(rtNametoIdMap.get(ocs.Case_Record_Type__c), parametersObject);
					settingRecordIdToParametersMap.put(ocs.Id, parametersObject);
				}
			}
		}
	}

	/************************************************************************************
	Method Name  : getCallStageParameters
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return a list of JSON object parameter
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static List<OutboundCallingBean.CallStageMapping> getCallStageParameters(String parameters, String settingName){

		OUTBOUND_CALL_SETTING_RECORD_NAME = settingName;
		OutboundCallingBean ocb = getOutboundCallSettingParameters(parameters);

		if(ocb.callStageParameters != null){

			List<OutboundCallingBean.CallStageMapping> callStageParametersList = 
					new List<OutboundCallingBean.CallStageMapping>(ocb.callStageParameters);

			Boolean isJSONvalid = true;

			if(!callStageParametersList.isEmpty()){

				for(OutboundCallingBean.CallStageMapping param : callStageParametersList){
					Boolean anyParameterEmpty = checkIfAnyParameterIsEmpty(param);
					Boolean isDataValid = validateParametersData(param);
					if(anyParameterEmpty && !isDataValid)
						isJSONvalid = false;
				}

				if(isJSONvalid) return ocb.callStageParameters;
				else return null;

			} else {

				throwException(Label.Outbound_Call_Setting_JSON_Object_Empty, 
							new List<String>{OUTBOUND_CALL_SETTINGS_OBJECT_NAME, OUTBOUND_CALL_SETTING_RECORD_NAME, 
											 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME});
				return null;
			}

		} else {
			throwException(Label.Outbound_Call_Setting_JSON_Object_Not_Defined, 
							new List<String>{OUTBOUND_CALL_SETTINGS_OBJECT_NAME, OUTBOUND_CALL_SETTING_RECORD_NAME, 
											 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME});
			return null;
		}
	}

	/************************************************************************************
	Method Name  : getOutboundCallSettingParameters
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to deserialize JSON object to Apex readable class instance
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static OutboundCallingBean getOutboundCallSettingParameters(String parameters){
	
		try{
			return (OutboundCallingBean) System.JSON.deserializeStrict(parameters, OutboundCallingBean.class);
		} catch(JSONException e){
			throwException(Label.Outbound_Call_Setting_JSON_Deserialize_Exception, 
					new List<String>{OUTBOUND_CALL_SETTINGS_OBJECT_NAME, OUTBOUND_CALL_SETTING_RECORD_NAME, e.getMessage()});
			return null;
		}
	}

	/************************************************************************************
	Method Name  : checkIfAnyParameterIsEmpty
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to check if any JSON specified paramter is empty (empty is considered as "")
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static Boolean checkIfAnyParameterIsEmpty(OutboundCallingBean.CallStageMapping param){

		if( String.isEmpty(param.stagename) || String.isEmpty(param.outcome) 
			|| String.isEmpty(param.calldatetime) || param.offset == null){
			throwException(Label.Outbound_Call_Setting_JSON_Object_Empty_Parameter, 
							new List<String>{OUTBOUND_CALL_SETTINGS_OBJECT_NAME, OUTBOUND_CALL_SETTING_RECORD_NAME, 
											 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME});
			return true;
		} else {
			return false;
		}
	}

	/************************************************************************************
	Method Name  : validateParametersData
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to check if the JSON specified parameter is valid, meaning that given value and field name exists in org
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static Boolean validateParametersData(OutboundCallingBean.CallStageMapping param){

		if(stagePicklistValues.contains(param.stagename)
			&& caseFields.contains(param.calldatetime.toLowerCase()) 
			&& caseFields.contains(param.outcome.toLowerCase()) ){
			return true;
		} else {
			throwException(Label.Outbound_Call_Setting_Invalid_JSON_Parameter, 
							new List<String>{OUTBOUND_CALL_SETTINGS_OBJECT_NAME, OUTBOUND_CALL_SETTING_RECORD_NAME, 
											 OutboundCallingBean.OUTBOUND_CALL_SETTINGS_CALL_STAGE_PARAMETER_NAME, String.valueOf(param)});
			return false;
		}
	}

	/************************************************************************************
	Method Name  : throwException
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to throw the exception with a message which is build using parameters 
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static void throwException(String errorMessage, List<String> messageParameters){
		throw new TelegraphApplicationException(String.format(errorMessage, messageParameters));
	}

	/************************************************************************************
	Method Name  : getCallStagePicklistValues
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return a set of Case OC_Call_Stage__c picklist values
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@TestVisible
	private static Set<String> getCallStagePicklistValues(){

		Schema.DescribeFieldResult fieldResult = Case.OC_Call_Stage__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		Set<String> plvSet = new Set<String>();
		for(Schema.PicklistEntry p : ple){
			plvSet.add(p.getLabel());
		}
		return plvSet;
	}

	/************************************************************************************
	Method Name  : getRecordTypeToIdMap
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return all case record types to id map
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static Map<String, String> getRecordTypeToIdMap(){

		Set<String> rtNameSet = new Set<String>();
		for(Outbound_Call_Setting__c ocs : settingsList){
			rtNameSet.add(ocs.Case_Record_Type__c);
		}

		Map<String, String> rtNametoIdMap = new Map<String, String>();
		for(String rtName : rtNameSet){
			rtNametoIdMap.put(rtName, RecordTypeUtility.getRecordTypeId(Case.SObjectType, rtName, Case.class.getName()));
		}
		return rtNametoIdMap;
	}

	/************************************************************************************
	Method Name  : getOutboundCallingCaseRecordTypesIds
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return a set of case record types ids that are defined in Outbound Call Setting records
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Vishant Shah 13/06/2017   Added caseClassification to update Case fields based on OCS.Case_Field_Map__c
	*************************************************************************************/
	public static Set<String> getOutboundCallingCaseRecordTypesIds(){

		Set<String> caseRecordTypeIds = new Set<String>();
		caseRecordTypeFieldMap        = new Map<String, Map<String, String>>();

		settingsList = getOutboundCallSettingsList();

		for(Outbound_Call_Setting__c ocs : settingsList){
			Id caseRecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, ocs.Case_Record_Type__c, Case.class.getName());
			Map<String, String> caseClassification;

			if (!String.isBlank(ocs.Case_Field_Map__c)){
				caseClassification = (Map<String, String>) JSON.deserializeStrict(ocs.Case_Field_Map__c, Map<String, String>.class);
			}

			caseRecordTypeFieldMap.put(caseRecordTypeId, caseClassification);
			caseRecordTypeIds.add(caseRecordTypeId);
		}
		return caseRecordTypeIds;
	}

	/************************************************************************************
	Method Name  : getOutboundCallSettingsList
	Author       : Mantas Grigaliunas
	Created Date : 18/07/2016
	Function     : Method to return queried active Outbound Call setting records
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	private static List<Outbound_Call_Setting__c> getOutboundCallSettingsList(){

		return new List<Outbound_Call_Setting__c>([ SELECT Id, Name, Case_Record_Type__c, Parameters__c , Case_Field_Map__c
													  FROM Outbound_Call_Setting__c 
													 WHERE Active__c = true ]
												);
	}

	/************************************************************************************
	Method Name  : getOutboundCallSetting
	Author       : Mantas Grigaliunas
	Created Date : 25/05/2017
	Function     : Method to return map of Id to parameters of specific oc setting record
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	public static Map<Outbound_Call_Setting__c, OutboundCallingBean.CallStageMapping> getOutboundCallSetting(String vfPageName){

		OutboundCallingBean.CallStageMapping param;
		Outbound_Call_Setting__c ocSetting;


		List<Outbound_Call_Setting__c> ocSettings = [SELECT Name, Parameters__c,
                                                            (SELECT Call_Answered__c, Call_Busy__c, Call_No_Answer__c, Priority_Field__c, Show_Cheques_Section__c, Call_Record_Entry__c, Show_Record_Counters__c 
                                                              FROM Outbound_Call_Rules__r 
                                                             WHERE Active__c = true)
                                                      FROM Outbound_Call_Setting__c 
                                                     WHERE Visualforce_Page__c = :vfPageName 
                                                       AND Active__c = true];

        if(ocSettings.size() == 1){
            ocSetting = ocSettings.get(0);

            if(String.isNotEmpty(ocSetting.Parameters__c)){
                try{

                    List<OutboundCallingBean.CallStageMapping> ocParameters = new List<OutboundCallingBean.CallStageMapping>(getCallStageParametersByOCsettingId(ocSetting.Id));
                    param = ocParameters[0];

                } catch(TelegraphApplicationException e){
                    addPageMessage(Constants.FATAL, 'Unable to extract parameters. ' + e.getMessage());
                    return null;
                }
            } else {
                addPageMessage(Constants.FATAL, Label.Outbound_Calling_Missing_Setting_Parameters, new List<String>{ocSetting.Name});
                return null;
            }

            if (ocSettings[0].Outbound_Call_Rules__r.size() != 1){
                addPageMessage(Constants.FATAL, Label.Outbound_Calling_Missing_Setting_Rule, new List<String>{ocSetting.Name});
                return null;
            }

            return new Map<Outbound_Call_Setting__c, OutboundCallingBean.CallStageMapping>{ocSetting => param};
            
        } else{
            addPageMessage(Constants.FATAL, Label.Outbound_Calling_Missing_Setting_Record, new List<String>{vfPageName});
            return null;
        }
    }

    /************************************************************************************
    Class Name   : addPageMessage
    Author       : Mantas Grigaliunas
    Created Date : 25/05/2017
    Function     : methods to add page message
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/

    /* @ addPageMessage Methods @ **/

    //generic error message passed as a string
    public static void addPageMessage(ApexPages.Severity severity, String errorMessage){
        ApexPages.addMessage(new ApexPages.Message(severity, errorMessage));
    }

    //user friendly error message to be dispalyed and full error message to be logged in system debug passed as a string
    public static void addPageMessage(ApexPages.Severity severity, String pageMessage, String adminMessage){
        addSystemLogMessage(severity, adminMessage);
        addPageMessage(severity, pageMessage);
    }

    //generic error message passed as a string with additional parameters
    public static void addPageMessage(ApexPages.Severity severity, String errorMessage, List<String> errorMessageParameters){
        addPageMessage(severity, String.format(errorMessage , errorMessageParameters));
    }

    //DMLException error message passed and converted to the user friendly string message
    public static void addPageMessage(ApexPages.Severity severity, List<Database.Error> errorLst){
        List<ApexPages.Message> pageMsgLst = new List<ApexPages.Message>();
        for(Database.Error error : errorLst){
            addPageMessage(severity, String.valueOf(error.getMessage()), String.valueOf(error));
        }
    }

    /************************************************************************************
    Class Name   : addSystemLogMessage
    Author       : Mantas Grigaliunas
    Created Date : 25/05/2017
    Function     : methods used to add system debug messages
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static void addSystemLogMessage(ApexPages.Severity severity, String errorMessage){
        System.debug('<TMG> OUTBOUND CALLING ' + String.valueOf(severity) + ' : ' + errorMessage);
    }

    /************************************************************************************
    Class Name   : getCaseClassificationMapByRecordTypeId
    Author       : Vishant Shah
    Created Date : 13/06/2017
    Function     : methods used to return Map of recordtype with Map of Case classification map
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Map<String, Map<String, String>> getCaseClassificationMapByRecordTypeId(){
		if (caseRecordTypeFieldMap == null){
			getOutboundCallingCaseRecordTypesIds();
		}

		return caseRecordTypeFieldMap;
	}
}