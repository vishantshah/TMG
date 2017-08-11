/************************************************************************************
Class Name   : RetentionCallingController
Author       : Konrad Czykin
Created Date : 02/05/2017
Function     : Controller class for visualforce page 'RetentionCalling'. Logic to find and display
                a customer to call for call agents.  
*************************************************************************************/
public class RetentionCallingController {

    //Case
    public Case thisCase {get;set;}
    private DateTime caseLastUpdateTimeStamp;
    @TestVisible private Id rtId;

    //Current subscription
    public Boolean hasActiveSubscription {get;set;}
    public Subscription__c thisSubscription {get;set;}

    //Case Comments
    public CaseComment newComment {get;set;}
    public Boolean showNewComment {get;set;}
    public List<CaseComment> caseCommentsList {get;set;}

    //Outbound Call Settings
    public Outbound_Call_Rule__c ocRule {get;set;}
    @TestVisible private Outbound_Call_Setting__c ocSetting;
    public List<OutboundCallingBean.CallStageMapping> ocParameters {get;set;}
    private Map<String, String> stageToStageDatetimeFieldMap;
    @TestVisible private String callStageDateTimeFieldName;
    private String currentPageName = TMGUtil.getCurrentPageName();

    //Controller variables
    public String callType {get;set;}
    public String saveButtonLabel {get;set;}
    public Boolean editScheduleCallback {get;set;}
    private Boolean alreadySaved;
    private DateTime originalScheduledCallback;
    @TestVisible private List<Case> caseList;

    //Page Message variables
    public Boolean formMsg {get;set;}
    public Boolean callDetailsTopMsg {get;set;}
    public Boolean caseDetailsMsg {get;set;}
    public Boolean currentSubscriptionMsg {get;set;}
    public Boolean callDetailsBottomMsg {get;set;}

    //Constants
    private ApexPages.Severity INFO = ApexPages.Severity.INFO;
    private ApexPages.Severity ERROR = ApexPages.Severity.ERROR;
    private ApexPages.Severity WARNING = ApexPages.Severity.WARNING;
    private ApexPages.Severity FATAL = ApexPages.Severity.FATAL;
    private String FORM_MSG = 'Page Form';
    private String CALL_DETAILS_TOP_MSG = 'Call Details Top';
    private String CALL_DETAILS_BOTTOM_MSG = 'Call Details Bottom';
    private String CASE_DETAILS_MSG = 'Case Details';
    private String CURRENT_SUBSCRIPTION_MSG = 'Current Subscription';

    /************************************************************************************
    Method Name  : RetentionCallingController
    Author       : Konrad Czykin
    Change Date  : 05/05/2017
    Function     : constructor of the class
    *************************************************************************************/
    public RetentionCallingController(){

        editScheduleCallback = false;
        showNewComment = false;
        
        alreadySaved = false;
        hasActiveSubscription = false;
        saveButtonLabel = Label.OC_Save_And_Next;

        rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_RETENTION_RECORD_TYPE_NAME, Case.class.getName());
        callType = Constants.OC_RETENTION_STAGE;
        clearPageMessage();
        getOutboundCallSettings();
    }

    /************************************************************************************
    Method Name  : onClickGetCustomer
    Author       : Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Method decleare Outbound Call Settings for Retention Outbound Call page
    *************************************************************************************/
    private void getOutboundCallSettings(){

        //set parameters from Outbound Call Settings record
        List<Outbound_Call_Setting__c> ocSettings = [SELECT Name, Parameters__c
                                                    FROM Outbound_Call_Setting__c
                                                    WHERE Visualforce_Page__c = :currentPageName
                                                    AND Active__c = true];

        if(ocSettings.size() == 1){
            //get parameters
            ocSetting = ocSettings.get(0);

            if(String.isNotEmpty(ocSetting.Parameters__c)){
                try{
                    //Get JSON defined parameters
                    ocParameters = new List<OutboundCallingBean.CallStageMapping>(OutboundCallingUtils.getCallStageParametersByOCsettingId(ocSetting.Id));
                    stageToStageDatetimeFieldMap = new Map<String, String>();

                    for(OutboundCallingBean.CallStageMapping param : ocParameters){
                        stageToStageDatetimeFieldMap.put(param.stagename, param.calldatetime);
                    }
                } catch(TelegraphApplicationException e){
                    addPageMessage(FORM_MSG, FATAL, e.getMessage());
                }
            }else{
                addPageMessage(FORM_MSG, FATAL, Label.Outbound_Calling_Missing_Setting_Parameters, new List<String>{ocSetting.Name});
                return;
            }

            //get rules
            List<Outbound_Call_Rule__c> ocRules = [SELECT Call_Answered__c, Call_Busy__c, Call_No_Answer__c, Priority_Field__c, Show_Cheques_Section__c, Call_Record_Entry__c, Show_Record_Counters__c
                                                    FROM Outbound_Call_Rule__c
                                                    WHERE Outbound_Call_Setting__c = :ocSetting.Id
                                                    AND Active__c = true];
            if(ocRules.size() == 1){
                ocRule = ocRules.get(0);
            }else{
                addPageMessage(FORM_MSG, FATAL, Label.Outbound_Calling_Missing_Setting_Rule, new List<String>{ocSetting.Name});
            }
        }else{
            addPageMessage(FORM_MSG, FATAL, Label.Outbound_Calling_Missing_Setting_Record, new List<String>{Constants.OC_RETENTION_RECORD_TYPE_NAME});
        }
    }

    /************************************************************************************
    Method Name  : onClickGetCustomer
    Author       : Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Fetch next customer on button click
    *************************************************************************************/
    public void onClickGetCustomer(){

        //limits validation
        Integer limitToCheck = Limits.getLimitQueries() - 11;
        if(Limits.getQueries() > limitToCheck){
            addPageMessage(CALL_DETAILS_TOP_MSG, WARNING, Label.Outbound_Call_System_Busy);
            return;
        }

        thisCase = null;
        thisSubscription = null;
        saveButtonLabel = Label.OC_Save_And_Next;
        alreadySaved = false;
        editScheduleCallback = false;

        try{
            callStageDateTimeFieldName = stageToStageDatetimeFieldMap.get(callType);
            DateTime timeNow = DateTime.now();

                String caseQuery =
                  'SELECT Id, OC_Scheduled_Callback__c, ' + callStageDateTimeFieldName
                + ' FROM Case'
                + ' WHERE CreatedDate = LAST_N_DAYS:14 '  
                + ' AND Status != \'' + Constants.CASE_STATUS_COMPLETED + '\''
                + ' AND OC_Call_Stage__c = \'' + callType + '\''
                + ' AND RecordTypeId = \'' + rtId + '\''
                + ' AND ' + '(' + callStageDateTimeFieldName + ' <= :timeNow' + ' OR ' + callStageDateTimeFieldName + ' = NULL)'
                + ' AND AccountId != NULL '
                + ' AND Account.Number_of_Active_Subscriptions__c = 1'
                + ' AND (OC_Scheduled_Callback__c <= :timeNow OR OC_Scheduled_Callback__c = NULL)';

                if(String.isNotEmpty(ocRule.Priority_Field__c)){

                    caseQuery += ' AND ' + ocRule.Priority_Field__c + ' > -1' +
                                 'ORDER BY ' +  ocRule.Priority_Field__c + ',' + 'Print_Subscription__r.End_Date__c DESC' + ',' + 'OC_Scheduled_Callback__c,' + callStageDateTimeFieldName + ' NULLS LAST LIMIT 101';
                }else{
                    caseQuery += ' ORDER BY Print_Subscription__r.End_Date__c DESC, ' + callStageDateTimeFieldName + ' NULLS LAST LIMIT 101';
                }

                caseList = new List<Case>();
                caseList = (List<Case>)Database.query(caseQuery);

                if(caseList.size() == 0){

                    addPageMessage(CALL_DETAILS_TOP_MSG, INFO, Label.No_Cases_Found, new List<String>{callType});
                    return;
                }

                List<Case> lockedCase = new List<Case>();
                for(Case c : caseList){
                    try{
                        // this query is used purely to lock the record as we work on it
                        Id caseId = c.Id;
                        lockedCase = Database.query('SELECT CaseNumber,Product__c,Account.Id, OC_Viewed_Date__c, '+callStageDateTimeFieldName+', OC_Viewed_Timestamp_Critical__c, OC_Call_Stage__c,Print_Subscription__c, Description, Subject, Status, OC_Outcome__c, OC_No_Sale_Reason__c, OC_Priority_Score__c, OC_Scheduled_Callback__c,  LastModifiedDate, LastModifiedById FROM Case  WHERE Id = :caseId FOR UPDATE') ;

                        if(lockedCase[0].get(callStageDateTimeFieldName) != c.get(callStageDateTimeFieldName)){
                            continue;
                        }
                        break;
                    }catch(Exception e){
                          addSystemLogMessage('Expected Case Lock Exception', ERROR, e.getMessage());
                        continue;
                    }
                }

                if(lockedCase.size() == 0){
                      addPageMessage(CALL_DETAILS_TOP_MSG, INFO, Label.No_Cases_Found, new List<String>{callType});
                    return;
                }

                thisCase = lockedCase[0];
                //date stamp the case record to ensure it is not viewed again within the set period
                thisCase.put(callStageDateTimeFieldName, DateTime.now().addMinutes((Integer)ocRule.Call_Record_Entry__c));
                //assign case to the current user
                thisCase.OwnerId = UserInfo.getUserId();
                //update case status to 'In Progress'
                thisCase.Status = Constants.CASE_STATUS_INPROGRESS;
                //update case with the new date stamp and owner to make sure it is out of open cases list
                Database.SaveResult result = Database.update(thisCase, false);
                if(!result.isSuccess()){
                      addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, result.getErrors());
                    return;
                }
                caseLastUpdateTimeStamp = getTimeStamp();
            
            originalScheduledCallback = thisCase.OC_Scheduled_Callback__c;
            if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE){
                editScheduleCallback = true;
            }

            //set page context variables for subscriber, subscription and case
            thisSubscription = getSubscription();
            caseCommentsList = new List<CaseComment>(thisCase.CaseComments);

            System.debug('Queries after onClickGetCustomer() ' + Limits.getQueries());
        }catch(Exception e){
            addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, Label.OC_Error, e.getMessage());
       }
    }

    /************************************************************************************
    Method Name  : saveCustomer
    Author       : Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Save current case record and relative information
    *************************************************************************************/
    public Boolean saveCustomer(){
        if(this.thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE && !isScheduledCallbackValid()){
            return false;
        }

        try{
            //check if case was modified by another user in the mean time
            if(alreadySaved) return false;
            Case caseBeforeSave = [SELECT Id, LastModifiedDate, LastModifiedById, LastModifiedBy.Name FROM Case WHERE Id = :thisCase.Id];
            if(caseBeforeSave.LastModifiedDate >= caseLastUpdateTimeStamp && caseBeforeSave.LastModifiedById != UserInfo.getUserId()){
                saveButtonLabel = Label.Outbound_Call_Get_Next_Customer_Button;
                alreadySaved = true;
                addPageMessage(CALL_DETAILS_TOP_MSG, WARNING, Label.Outbound_Call_Case_Already_Saved, new List<String>{caseBeforeSave.LastModifiedBy.Name});
                return false;
            }

            //check if outcome field value is blank
            if(this.thisCase.OC_Outcome__c == null){
                addPageMessage(CALL_DETAILS_TOP_MSG, ERROR, Label.OC_Outcome_Warning);
                return false;
            }

            //update call reschedule time based on rules if specific outcome is selected
            DateTime now = DateTime.now();
            if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_BUSY){
                thisCase.OC_Scheduled_Callback__c = now.addMinutes(Integer.valueOf(ocRule.Call_Busy__c));
            }
            if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_NOANSWER){
                thisCase.OC_Scheduled_Callback__c = now.addMinutes(Integer.valueOf(ocRule.Call_No_Answer__c));
            }
            if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_ANSWERPHONE){
                thisCase.OC_Scheduled_Callback__c = now.addMinutes(Integer.valueOf(ocRule.Call_Answered__c));
            }

            //update Subscription field on Case if it is not populated
            if(this.thisCase.Print_Subscription__c == NULL || String.isBlank(this.thisCase.Print_Subscription__c)){
                this.thisCase.Print_Subscription__c = this.thisSubscription.Id;
            }

            //update thisCase
            Database.SaveResult result = Database.update(thisCase, false);
            if(!result.isSuccess()){
                addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, result.getErrors());
                return false;
            }          
        }catch(Exception e){
            addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, Label.OC_Error, e.getMessage());
            return false;
        }
        return true;
    }

    /************************************************************************************
    Method Name  : saveCustomer
    Author       : Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Method to save and get next customer
    *************************************************************************************/
    public void onClickSaveAndGetNextCustomer(){
        if(saveCustomer()){
            onClickGetCustomer();
        }
    }

    /************************************************************************************
    Method Name  : saveCustomer
    Author       : Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Method to manage Case Outcome change
    *************************************************************************************/
    public void caseOutcomeChange(){
        if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE){
            editScheduleCallback = true;
        }else{
            editScheduleCallback = false;
            thisCase.OC_Scheduled_Callback__c = originalScheduledCallback;
        }
    }

    /************************************************************************************
    Method Name  : saveCustomer
    Author       : Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Method to manage Case Scheduled Callback change
    *************************************************************************************/
    public void caseScheduledCallbackChange(){
        if(isScheduledCallbackValid()){
            ApexPages.getMessages().clear();
            clearPageMessage();
        }
    }

    /************************************************************************************
    Method Name  : getSubscription
    Author       : Konrad Czykin
    Created Date : 10/05/2017
    Function     : Retrieves current subscription records
    *************************************************************************************/
    @TestVisible private Subscription__c getSubscription(){

        List<Subscription__c> subLst = [SELECT Id, Name, Subscriber__c, WeeklyPrintPrice__c, Weekly_Price__c, Previous_Price__c,
                                                    FirstRenewal__c, PaymentDate__c, Retailer__c,Duration__c, MPP_CC_Frequency__c, 
                                                    MPP_DD_Frequency__c, Delivery_Type__c, Payment_Type__c, TCode__c, Start_Date__c, 
                                                    End_Date__c, isContinuous__c, Subscription_Status__c, Subscription_Duration_Picklist__c, 
                                                    If_Is_Renewal_Binary__c, TCode_Product__c, Product__c, Product__r.Name 
                                        FROM Subscription__c WHERE Subscription_Status__c = 'Active' AND Subscriber__c =:this.thisCase.AccountId];
                                

        if(subLst.isEmpty()){
              addPageMessage(CURRENT_SUBSCRIPTION_MSG, ERROR, Label.Outbound_Calling_Subscription_Not_Found);
            return null;
        }
        Subscription__c thisSub = subLst[0];
        if(thisSub != null){
            hasActiveSubscription = true;
        }
        return thisSub;
    }

    /************************************************************************************
    Method Name  : isScheduledCallbackValid
    Author       : Konrad Czykin
    Created Date : 10/05/2017
    Function     : Retrieves current subscription records
    *************************************************************************************/
    @TestVisible private Boolean isScheduledCallbackValid(){
        Datetime inputDate = Datetime.newInstanceGmt(thisCase.OC_Scheduled_Callback__c.year(), thisCase.OC_Scheduled_Callback__c.month(), thisCase.OC_Scheduled_Callback__c.day(), thisCase.OC_Scheduled_Callback__c.hour(), thisCase.OC_Scheduled_Callback__c.minute(), thisCase.OC_Scheduled_Callback__c.second());
        Datetime now = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), Datetime.now().minute(), Datetime.now().second());

        //validation - date not in the past
        if(inputDate < now){
              addPageMessage(CASE_DETAILS_MSG, ERROR, Label.OC_Case_Scheduled_Callback_In_Past);
            return false;
        }else{
            return true;
            }
    }

    /************************************************************************************
    Method Name  : isScheduledCallbackValid
    Author       : Konrad Czykin
    Created Date : 10/05/2017
    Function     : get time stamp
    *************************************************************************************/
    private DateTime getTimeStamp(){
        DateTime now = DateTime.now();
        return DateTime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
    }

    /* @ addPageMessage Methods @ **/

    //generic error message passed as a string
    private void addPageMessage(String location, ApexPages.Severity severity, String errorMessage){
        setPageMessage(location);
        ApexPages.addMessage(new ApexPages.Message(severity, errorMessage));
    }

    //user friendly error message to be dispalyed and full error message to be logged in system debug passed as a string
    private void addPageMessage(String location, ApexPages.Severity severity, String pageMessage, String adminMessage){
        addSystemLogMessage(location, severity, adminMessage);
        addPageMessage(location, severity, pageMessage);
    }

    //generic error message passed as a string with additional parameters
    private void addPageMessage(String location, ApexPages.Severity severity, String errorMessage, List<String> errorMessageParameters){
        addPageMessage(location, severity, String.format(errorMessage , errorMessageParameters));
    }

    //DMLException error message passed and converted to the user friendly string message
    private void addPageMessage(String location, ApexPages.Severity severity, List<Database.Error> errorLst){
        for(Database.Error error : errorLst){
            addPageMessage(location, severity, String.valueOf(error.getMessage()), String.valueOf(error));
        }
    }

    /* @ addPageMessage Methods End @ **/
    private void addSystemLogMessage(String location, ApexPages.Severity severity, String errorMessage){
        System.debug('<TMG> OUTBOUND CALLING RETENTION IN ' + location + '. ' + String.valueOf(severity) + ' : ' + errorMessage);
    }

    /************************************************************************************
    Method Name  : addSystemLogMessage
    Author       : Konrad Czykin
    Created Date : 08/05/2017
    Function     : methods to set boolean flags for the page messages based on section name
    *************************************************************************************/
    private void setPageMessage(String sectionName){
        formMsg = sectionName.equals(FORM_MSG);
        caseDetailsMsg = sectionName.equals(CASE_DETAILS_MSG);
        currentSubscriptionMsg = sectionName.equals(CURRENT_SUBSCRIPTION_MSG);
        callDetailsBottomMsg = sectionName.equals(CALL_DETAILS_BOTTOM_MSG);
        callDetailsTopMsg = sectionName.equals(CALL_DETAILS_TOP_MSG);

        if(sectionName.equals(CURRENT_SUBSCRIPTION_MSG)){
            currentSubscriptionMsg = true;
            callDetailsTopMsg = true;
        }
    }

    /************************************************************************************
    Method Name  : clearPageMessage
    Author       : Konrad Czykin
    Created Date : 08/05/2017
    Function     : calling setPageMessage with blank value to set all boolean flags to false
    *************************************************************************************/
    private void clearPageMessage(){
        setPageMessage('');
    }
}