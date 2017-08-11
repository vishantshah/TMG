/************************************************************************************
Class Name   : OutboundCallingDDWinbackController
Author       : Vishant Shah
Created Date : 09/06/2017
Function     : Controller for OutboundCallingDDWinback vf Page
Developer       Date        Description
************************************************************************************/

public class OutboundCallingDDWinbackController{

    public Case thisCase                                           { get; set; }
    public Case tempCase                                           { get; set; }
    public Subscription__c thisSubscription                        { get; set; }    
    public Boolean formMsg                                         { get; set; }
    public Boolean caseDetailsMsg                                  { get; set; }
    public Boolean callDetailsTopMsg                               { get; set; }
    public Boolean editScheduleCallback                            { get; set; }
    public Outbound_Call_Rule__c ocRule                            { get; set; } 
    public String saveButtonLabel                                  { get; set; }
    public List<OutboundCallingBean.CallStageMapping> ocParameters { get; set; }
    public Boolean showDebtCollected                               { 
        get {
            if (debtCollectionOutcomes != null && debtCollectionOutcomes.size() > 0 )
                return debtCollectionOutcomes.contains(thisCase.OC_Outcome__c);
            else 
                return false;
        }
    }
    
    
    private Id recordTypeId;
    private Date comparisonDate;
    private DateTime caseLastUpdateTimeStamp;
    private String callDateTimeField;
    private String callType;
    private Boolean alreadySaved;
    private Set<String> debtCollectionOutcomes;

    private String FORM_MSG                 = 'Page Form';
    private String CASE_DETAILS_MSG         = 'Case Details';
    private String CALL_DETAILS_TOP_MSG     = 'Call Details Top'; 

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - Constructor
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public OutboundCallingDDWinbackController(){
        recordTypeId           = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Case.class.getName());
        
        debtCollectionOutcomes = new Set<String>();
        if (Configuration__c.getOrgDefaults().Debt_Collection_Outcome__c != null){
            debtCollectionOutcomes = new Set<String>(Configuration__c.getOrgDefaults().Debt_Collection_Outcome__c.split(','));
        }

        clearPageMessage();
        getOutboundCallSettings();
        
        tempCase = new Case();
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - Clear Page messages
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    private void clearPageMessage(){
        setPageMessageLocation('');
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - Set where to show the page message
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    private void setPageMessageLocation(String sectionName){
        formMsg                = sectionName.equals(FORM_MSG);
        caseDetailsMsg         = sectionName.equals(CASE_DETAILS_MSG);
        callDetailsTopMsg      = sectionName.equals(CALL_DETAILS_TOP_MSG);
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - get call settings
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    private void getOutboundCallSettings(){

        setPageMessageLocation(FORM_MSG);
        Map<Outbound_Call_Setting__c, OutboundCallingBean.CallStageMapping> ocSettingMap = OutboundCallingUtils.getOutboundCallSetting(TMGUtil.getCurrentPageName());
        if(ocSettingMap != null){
            List<Outbound_Call_Setting__c> ocSetting = new List<Outbound_Call_Setting__c>(ocSettingMap.keySet());
            if(!ocSetting.get(0).Outbound_Call_Rules__r.isEmpty())
                ocRule = ocSetting.get(0).Outbound_Call_Rules__r[0];

            OutboundCallingBean.CallStageMapping param = ocSettingMap.values().get(0);
            callType                                   = param.stagename;
            callDateTimeField                          = param.calldatetime;
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - get case, subscriber and lock the case record.
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public void onClickGetCustomer(){
        
        clearPageMessage();
        setPageMessageLocation(CALL_DETAILS_TOP_MSG);
        alreadySaved = false;
        Datetime timeNow = Datetime.now();

        //limits validation
        Integer limitToCheck = Limits.getLimitQueries() - 11;
        if(Limits.getQueries() > limitToCheck){
            OutboundCallingUtils.addPageMessage(Constants.WARNING, Label.Outbound_Call_System_Busy);
            return;
        }

        thisCase = null; 
        thisSubscription = null;

        //call type validation
        if(callType == null){
            OutboundCallingUtils.addPageMessage(Constants.ERROR, Label.OC_Call_Type_Not_Selected);
            return;
        }

        try{
            //scenario 1: user gets next Case
            String caseQuery =
              ' SELECT Id, ' + callDateTimeField +
            + ' FROM Case'
            + ' WHERE  Status != \'' + Constants.CASE_STATUS_COMPLETED + '\''
            + ' AND RecordTypeId = \'' + recordTypeId + '\''
            + ' AND AccountId != NULL'
            + ' AND (' + callDateTimeField + ' <= :timeNow' + ' OR ' + callDateTimeField + ' = NULL)'
            + ' AND (OC_Scheduled_Callback__c <= :timeNow OR OC_Scheduled_Callback__c = NULL)';

            if(String.isNotEmpty(ocRule.Priority_Field__c)){
                caseQuery += ' AND ' + ocRule.Priority_Field__c + ' > -1' +
                             ' ORDER BY ' + ocRule.Priority_Field__c + ','+ callDateTimeField +' NULLS LAST LIMIT 101';
            }else{
                caseQuery += ' ORDER BY ' + callDateTimeField + ' NULLS LAST LIMIT 101';
            }

            List<Case> caseList = (List<Case>)Database.query(caseQuery);

            if(caseList.size() == 0){
                OutboundCallingUtils.addPageMessage(Constants.INFO, Label.No_Cases_Found, new List<String>{callType});
                return;
            }

            List<Case> lockedCase = new List<Case>();
            for(Case c : caseList){
                try{
                    // this query is used purely to lock the record as we work on it
                    Id caseId = c.Id;
                    lockedCase = Database.query('SELECT CaseNumber,Product__c,Account.Id, OC_Viewed_Date__c, '+callDateTimeField+', OC_Viewed_Timestamp_Critical__c, '
                        + 'OC_Call_Stage__c,Print_Subscription__c, Description, Subject, Status, OC_Outcome__c, DD_Winback_Outcome__c, OC_No_Sale_Reason__c, OC_Priority_Score__c, '
                        + 'OC_Scheduled_Callback__c,  LastModifiedDate, LastModifiedById, Debt_Collected_Amount__c, Debt_Collected__c FROM Case  WHERE Id = :caseId FOR UPDATE') ;

                    if(lockedCase[0].get(callDateTimeField) != c.get(callDateTimeField)){
                        continue;
                    }

                    break;
                }catch(Exception e){
                    OutboundCallingUtils.addSystemLogMessage(Constants.ERROR, 'Expected Case Lock Exception. ' + e.getMessage());
                    continue;
                }
            }

            if(lockedCase.size() == 0){
                OutboundCallingUtils.addPageMessage(Constants.INFO, Label.No_Cases_Found, new List<String>{callType});
                return;
            }

            thisCase = lockedCase[0];
            //date stamp the case record to ensure it is not viewed again within the set period
            thisCase.put(callDateTimeField, DateTime.now().addMinutes((Integer)ocRule.Call_Record_Entry__c));
            //assign case to the current user
            thisCase.OwnerId = UserInfo.getUserId();
            //update case status to 'In Progress'
            thisCase.Status = Constants.CASE_STATUS_INPROGRESS;
            //update case with the new date stamp and owner to make sure it is out of open cases list
            Database.SaveResult result = Database.update(thisCase, false);
            if(!result.isSuccess()){
                OutboundCallingUtils.addPageMessage(Constants.FATAL, result.getErrors());
                return;
            }
            caseLastUpdateTimeStamp = getTimeStamp();
        
            editScheduleCallback = (thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE ? true : false);

            thisSubscription = getSubscription();
            tempCase = new Case();

            System.debug('Queries after onClickGetCustomer() ' + Limits.getQueries());
        }catch(Exception e){
            OutboundCallingUtils.addPageMessage(Constants.FATAL, Label.OC_Error, e.getMessage());
       }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - get time stamp
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    private DateTime getTimeStamp(){
        DateTime now = DateTime.now();
        DateTime newNow = DateTime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
        if (Test.isRunningTest())
            return newNow.addHours(-1);
        else 
            return newNow;
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - get subscription record
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    private Subscription__c getSubscription(){

        List<Subscription__c> subLst = [
                                        SELECT  Name, Subscriber__c, Weekly_Price__c, Previous_Price__c,FirstRenewal__c, PaymentDate__c,
                                                Retailer__c,Duration__c, MPP_CC_Frequency__c, MPP_DD_Frequency__c, Delivery_Type__c,
                                                Payment_Type__c, TCode__c, Start_Date__c, End_Date__c, isContinuous__c, Subscription_Status__c,
                                                Subscription_Duration_Picklist__c, If_Is_Renewal_Binary__c, TCode_Product__c, Product__c, Product__r.Name,
                                                Renewal_Price_Override__c, Cancellation_Date__c, Cancellation_Reason__c
                                          FROM  Subscription__c
                                         WHERE  Id = :thisCase.Print_Subscription__c LIMIT 1];

        if(subLst.isEmpty()){
            OutboundCallingUtils.addPageMessage(Constants.ERROR, Label.Outbound_Calling_Offered_Subscription_Not_Found);
            return null;
        }

        return subLst[0];
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - save and get next customer
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public void onClickSaveAndGetNextCustomer(){
        if(saveCustomer()){
            onClickGetCustomer();
        }
    }
    
    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - show schedule callback field
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public void caseOutcomeChange(){
        editScheduleCallback = (thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE ? true : false);
        thisCase.OC_Scheduled_Callback__c = null;
        thisCase.NATC_Reason__c= null;
        thisCase.Other_NATC_Reason__c= null;
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - check value when call back datetime changed
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public void caseScheduledCallbackChange(){
        if(isScheduledCallbackValid()){
            ApexPages.getMessages().clear();
            clearPageMessage();
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - check value when call back datetime changed
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    private Boolean isScheduledCallbackValid(){
        setPageMessageLocation(CASE_DETAILS_MSG);
        Datetime inputDate = Datetime.newInstanceGmt(thisCase.OC_Scheduled_Callback__c.year(), thisCase.OC_Scheduled_Callback__c.month(), thisCase.OC_Scheduled_Callback__c.day(), thisCase.OC_Scheduled_Callback__c.hour(), thisCase.OC_Scheduled_Callback__c.minute(), thisCase.OC_Scheduled_Callback__c.second());
        Datetime now = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), Datetime.now().minute(), Datetime.now().second());

        //validation - date not in the past
        if(inputDate < now){
            OutboundCallingUtils.addPageMessage(Constants.ERROR, Label.OC_Case_Scheduled_Callback_In_Past);
            return false;
        }

        //validation - date before 1pm this Saturday
        Date weekStart = Date.today().toStartOfWeek();
        Datetime thisSunday;
        Datetime thisSaturday1pm;

        if(Datetime.newInstanceGmt(weekStart.year(), weekStart.month(), weekStart.day()).format('EEEE') == 'Monday') thisSunday = Datetime.newInstanceGmt(weekStart.year(), weekStart.month(), weekStart.day() + 6);
        else thisSunday = Datetime.newInstanceGmt(weekStart.year(), weekStart.month(), weekStart.day() + 7);
        thisSaturday1pm = thisSunday.addHours(-11);

        if(inputDate < thisSaturday1pm){
            return true;
        }else{
            OutboundCallingUtils.addPageMessage(Constants.ERROR, Label.OC_Case_Scheduled_Callback);
            return false;
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 09/06/2017
    Function - save case record
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public Boolean saveCustomer(){

        setPageMessageLocation(CALL_DETAILS_TOP_MSG);
        //check if outcome field value is blank
        if(this.thisCase.OC_Outcome__c == null){
            OutboundCallingUtils.addPageMessage(Constants.ERROR, Label.OC_Outcome_Warning);
            return false;
        }

        if(this.thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE && !isScheduledCallbackValid()){
            return false;
        }

        if (thisCase.OC_Outcome__c == 'Sale'){
            if (tempCase.Print_Subscription__c == null && tempCase.Subscription__c == null){
                OutboundCallingUtils.addPageMessage(Constants.FATAL, Label.Outcome_is_Sale_New_SUB_Required);
                return false;
            } else if (tempCase.Print_Subscription__c != null && tempCase.Subscription__c != null){
                OutboundCallingUtils.addPageMessage(Constants.FATAL, 'Select either Print Subscription or Digital Subscription, NOT both');
                return false;
            } else if (tempCase.Print_Subscription__c != null){
                thisCase.Print_Subscription__c = tempCase.Print_Subscription__c;
                thisCase.Subscription__c = null;
            } else if (tempCase.Subscription__c != null){
                thisCase.Subscription__c = tempCase.Subscription__c;
                thisCase.Print_Subscription__c = null;
            }
        }

        try{
            //check if case was modified by another user in the mean time
            if (alreadySaved) 
                return false;
            
            Case caseBeforeSave = [SELECT Id, LastModifiedDate, LastModifiedById, LastModifiedBy.Name
                                     FROM Case WHERE Id = :thisCase.Id];

            if(caseBeforeSave != null && caseBeforeSave.LastModifiedDate >= caseLastUpdateTimeStamp && caseBeforeSave.LastModifiedById != UserInfo.getUserId()){
                saveButtonLabel = Label.Outbound_Call_Get_Next_Customer_Button;
                alreadySaved = true;
                OutboundCallingUtils.addPageMessage(Constants.WARNING, Label.Outbound_Call_Case_Already_Saved, new List<String>{caseBeforeSave.LastModifiedBy.Name});
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

            //update thisCase
            Database.SaveResult result = Database.update(thisCase, false);
            if(!result.isSuccess()){
                OutboundCallingUtils.addPageMessage(Constants.FATAL, result.getErrors());
                return false;
            }
        }catch(Exception e){
            OutboundCallingUtils.addPageMessage(Constants.FATAL, Label.OC_Error, e.getMessage());
            return false;
        }
        return true;
    }
}