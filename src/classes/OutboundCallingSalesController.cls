/************************************************************************************
Class Name   : OutboundCallingSalesController
Author       : Mantas Grigaliunas
Created Date : 08/08/2016
Function     : Controller class for visualforce page 'OutboundCallingSales'. Logic to find and display
                a customer to call for call agents. Originally derived from OutboundCallingController
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas Grigaliunas    30/08/2016  Moved subscription update functionality from saveSub to onClickSave
*                                   in order to make sure selected product is updated
* Mantas Grigaliunas    30/08/2016  Added variables to store subscription Id and Name so they are always present on page
* Mantas Grigaliunas    01/09/2016  Removed tCodeId variable and replaced with thisSubscription instance TCodeId which is set in onClickGetCustomer method
* Pawel Chrzanowski     02/09/2016  Added Incentive Reason and removed useless code like getSubIncentiveAssociationMap()
* Pawel Chrzanowski     12/09/2016  Added call type counters
* Michal Szewczyk       20/09/2016  Changed onClickSave() method
* Pawel Chrzanowski     22/09/2016  Added isOCRS parameter
* Michal Szewczyk       27/09/2016  Changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
* Pawel Chrzanowski     27/09/2016  Added Scheduled Callback validation
* Pawel Chrzanowski     29/09/2016  Added Retailer dependency
* Michal Szewczyk       29/09/2016  Added Subscription condition to getRelatedIncentive
* Pawel Chrzanowski     03/10/2016  Added tCodeId to fix product switch
* Pawel Chrzanowski     06/10/2016  Modified saveSub to save subscription
* Mantas Grigaliunas    07/10/2016  Removed retrieveAllRetailers() and selectRetailer() methods and their dependancies
* Pawel Chrzanowski     12/10/2016  Added Case load from URL
* Pawel Chrzanowski     17/10/2016  Added subscription type to saveSub
* Mantas Grigaliunas    17/10/2016  Modified deliveryTypeChange()
* Mantas Grigaliunas    18/10/2016  Modified subscription update functionality in saveSub()
* Pawel Chrzanowski     19/10/2016  Modified isScheduledCallbackValid()
* Michal Szewczyk       20/10/2016  Added bOcCaseUpdateSkip flag
* Pawel Chrzanowski     20/10/2016  Modified onClickGetCustomer()
* Pawel Chrzanowski     21/10/2016  Reworked Delivery Type
* Michal Szewczyk       24/10/2016  Modified onClickGetCustomer()
* Pawel Chrzanowski     25/10/2016  Modified isScheduledCallbackValid();
* Wiktor Czykin         25/10/2016  Modified updateIncentivesNew();
* Wiktor Czykin         28/10/2016  Modified productSwitcher instantiation
* Michal Szewczyk       08/11/2016  Modified caseOutcomeChange() and changeProductId()
* Pawel Chrzanowski     14/11/2016  Added 'Show Record Counters' checkbox support
* Pawel Chrzanowski     29/11/2016  Modified deadline in isScheduledCallbackValid()
* Pawel Chrzanowski     29/11/2016  Hid 'No Sale' and 'Cheque Sales' Cases in T2 Catch Up
* Pawel Chrzanowski     01/12/2016  Allowed Cheque Sales in saveAndTakePayment()
* Pawel Chrzanowski     02/12/2016  Modified refetchSubscriberEmail() to update cloned account also
* Wiktor Czykin         09/12/2016  Modified onClickGetCustomer()
* Wiktor Czykin         13/12/2016  Modified saveAndTakePayment()
* Wiktor Czykin         14/12/2016  Modified saveSub(), cancelSubEdit(), getSubscription() - duration fix, modified saveAndTakePayment() - fix for cheque delete
* Pawel Chrzanowski     14/12/2016  Modified saveAndTakePayment()
* Wiktor Czykin         15/12/2016  Added date (batch pick up dates) condition to case queries
* Wiktor Czykin         19/01/2017  Modified saveAndTakePayment() and re-arranged execution of getRelatedIncentive() method
* Wiktor Czykin         11/04/2017  Modified saveAndTakePayment() and onClickGetCustomer() and caseOutcomeChange() - error on not matching product for tcode
* Pawel Chrzanowski     03/05/2017  Removed unused Marketing Preferences
*************************************************************************************/
public class OutboundCallingSalesController implements ProductSwitchSupport{

    //Case
    public Case thisCase {get;set;}
    private Case casefromURL;
    private DateTime caseLastUpdateTimeStamp;
    private Map<String, Integer> mapCallTypeIndex;
    private Id rtId;

    //Account
    public Account thisAccount {get;set;}
    public Account accBeforeEdit;
    public Boolean accEditEnabled {get;set;}
    public Boolean showEmailIFrame {get;set;}

    //Account Permissions
    public Account accountPermissions;

    //Current subscription
    public Subscription__c previousSubscription {get;set;}
    public Boolean hasPreviousSubscription {get;set;}
    public Boolean displayRetailers {get;set;}

    //Product Switch
    public ProductSwitchController productSwitcher {get;set;}
    private Id initialProductId;
    private Decimal dInitialWeeklyPrice;
    private String tCodeName;
    private Id tCodeId;

    //Offered Subscription
    public Subscription__c thisSubscription {get;set;}
    public Subscription__c subBeforeEdit;
    public Id offeredSubId {get;set;}
    public String offeredSubName {get;set;}
    public Boolean subEditEnabled {get;set;}
    public String subscriptionType {get;set;}
    public String selectedSubscriptionDuration {get;set;}

    //Delivery Type
    @TestVisible private Set<String> setDeliveryOptions;
    public Boolean isValidDeliveryType {get;set;}
    public List<SelectOption> lstDeliveryOptions {get;set;}
    public String selectedDelivery {get;
        set{
            selectedDelivery = value;
            if(selectedDelivery == Constants.DELIVERYTYPE_OTC){
                displayRetailers = false;
            }else{
                displayRetailers = true;
            }
        }
    }

    //Incentive
    public String selectedIncentive {get;set;}
    public String selectedIncentiveTemp {get;set;}
    private Map<String, String> mapIncentiveDescription = new Map<String, String>();
    public Boolean hasIncentives {get;set;}
    public List<SelectOption> activeIncentives {get;set;}
    public SubscriptionIncentiveAssociation__c relatedIncentive {get;set;}
    public String incentiveName {get;set;}
    @testVisible private static final String INCENTIVE_PREFIX = 'Renewal for ';
    public Boolean bRelatedIncentiveMatchesAvailable = false;

    //Payment
    public String preferedStartPaymentDate {get;set;}
    public String displayedPaymentType {get;set;}
    public String paymentFrequency {get;set;}

    //Cheque
    public Cheque__c thisCheque {get;set;}
    public Cheque__c chequeBeforeEdit {get;set;}
    public Boolean createNewBatch {get;set;}
    public String chequeBatchSelected {get;set;}
    public String chequeBatchBeforeEdit {get;set;}
    public Boolean chequeEditEnabled {get;set;}

    //Case Comments
    public CaseComment newComment {get;set;}
    public Boolean showNewComment {get;set;}
    public List<CaseComment> caseCommentsList {get;set;}

    //Outbound Call Settings
    public Outbound_Call_Rule__c ocRule {get;set;}
    private Outbound_Call_Setting__c ocSetting;
    public List<OutboundCallingBean.CallStageMapping> ocParameters {get;set;}
    private Map<String, String> stageToStageDatetimeFieldMap;
    @TestVisible private String callStageDateTimeFieldName;
    private Map<String, String> tCodeMap;
    private String currentPageName = TMGUtil.getCurrentPageName();

    //Controller variables
    public List<SelectOption> callTypeOptions {get;set;}
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
    public Boolean subscriberDetailsMsg {get;set;}
    public Boolean accountPermissionsMsg {get;set;}
    public Boolean currentSubscriptionMsg {get;set;}
    public Boolean offeredSubscriptionMsg {get;set;}
    public Boolean chequeMsg {get;set;}
    public Boolean callDetailsBottomMsg {get;set;}

    //Constants
    private ApexPages.Severity INFO = ApexPages.Severity.INFO;
    private ApexPages.Severity ERROR = ApexPages.Severity.ERROR;
    private ApexPages.Severity WARNING = ApexPages.Severity.WARNING;
    private ApexPages.Severity FATAL = ApexPages.Severity.FATAL;
    private ApexPages.Severity CONFIRM = ApexPages.Severity.CONFIRM;
    private String FORM_MSG = 'Page Form';
    private String CALL_DETAILS_MSG = 'Call Details';
    private String CALL_DETAILS_TOP_MSG = 'Call Details Top';
    private String CALL_DETAILS_BOTTOM_MSG = 'Call Details Bottom';
    private String CASE_DETAILS_MSG = 'Case Details';
    private String SUBSCRIBER_DETAILS_MSG = 'Subscriber Details';
    private String ACCOUNT_PERMISIONS_MSG = 'Permissions';
    private String CURRENT_SUBSCRIPTION_MSG = 'Current Subscription';
    private String OFFERED_SUBSCRIPTION_MSG = 'Offered Subscription';
    private String CHEQUE_MSG = 'Cheque Payment Details';

    private Date comparisonDate;

    private static final Id RECID_RET_ACC = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Function - Controller
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        12/09/2016  Added call type counters
    Pawel Chrzanowski  1.2        12/10/2016  Added Case load from URL
    ****************************************************************************************/
    public OutboundCallingSalesController(){
        chequeEditEnabled = true;
        accEditEnabled = false;
        subEditEnabled = false;

        alreadySaved = false;
        hasPreviousSubscription = false;
        showEmailIFrame = false;
        showNewComment = false;
        editScheduleCallback = false;

        selectedIncentive = Constants.OC_NONE;
        selectedIncentiveTemp = Constants.OC_NONE;
        saveButtonLabel = Label.OC_Save_And_Next;

        rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());

        clearPageMessage();
        getOutboundCallSettings();
        updateCallTypeCounters(ocRule);

        //load Case from url
        casefromURL = null;
        String idFromURL = ApexPages.currentPage().getParameters().get('id');
        if(!String.isBlank(idFromURL)){
            List<Case> lstCases = [SELECT CaseNumber,Product__c,Account.Id, OC_Viewed_Date__c, OC_Viewed_Timestamp_Critical__c, OC_Call_Stage__c, Print_Subscription__c, Description,
                                        Subject, Status, OC_Outcome__c, OC_No_Sale_Reason__c, OC_Priority_Score__c, OC_Scheduled_Callback__c, LastModifiedDate, LastModifiedById
                                    FROM Case WHERE Id = :idFromURL];
            if(!lstCases.isEmpty()){
                casefromURL = lstCases[0];
                callType = casefromURL.OC_Call_Stage__c;
                onClickGetCustomer();
            }else{
                addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, Label.OC_Case_Not_Found);
            }
        }
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 08/08/2016
    Function - Method decleare Outbound Call Settings for Sales Outbound Call page
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        14/11/2016  Added 'Show Record Counters' checkbox support
    Wiktor Czykin      1.2        14/12/2016  Added days back setting
    ****************************************************************************************/
    private void getOutboundCallSettings(){
        //defaulting to -7, just incase of any parsing/reading value from label exception
        Integer iDaysBack = Constants.OC_BACKDATE_DEFAULT_WHEN_NO_SETTINGS;
        General__c daysBack = General__c.getInstance(Constants.OC_CASES_AVAILABILITY_SETTING);
        if(daysBack != null && String.isNotBlank(daysBack.Value__c) && daysBack.Value__c.isNumeric()){
            iDaysBack = Integer.valueOf(daysBack.Value__c);
        }
        comparisonDate = Date.today().addDays(-iDaysBack);

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

                    //define call type options and tcode codes from parameters
                    callTypeOptions = new List<SelectOption>();
                    stageToStageDatetimeFieldMap = new Map<String, String>();
                    tCodeMap = new Map<String, String>();

                    for(OutboundCallingBean.CallStageMapping param : ocParameters){
                        callTypeOptions.add(new SelectOption(param.stagename, param.stagename));
                        stageToStageDatetimeFieldMap.put(param.stagename, param.calldatetime);
                        tCodeMap.put(param.stagename, param.tcode);
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
            addPageMessage(FORM_MSG, FATAL, Label.Outbound_Calling_Missing_Setting_Record, new List<String>{Constants.OC_SALES_RECORD_TYPE_NAME});
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 12/09/2016
    Method to parse case counter
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public String parseCaseCounter(Integer i){
        if(i == null) return null;

        if(i == 101) return ' (100+ Cases)';
        if(i > 1 && i < 101) return ' (' + i + ' Cases)';
        if(i == 1) return ' (1 Case)';
        if(i == 0) return ' (no Cases)';
        return null;
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 12/09/2016
    Method to update call type counters
    #############Change Log#############
    Modified by        Version    Change Date
    Michal Szewczyk    1.1        27/09/2016  Changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
    Pawel Chrzanowski  1.2        14/11/2016  Added 'Show Record Counters' checkbox support
    Pawel Chrzanowski  1.3        29/11/2016  Hid 'No Sale' and 'Cheque Sales' Cases in T2 Catch Up
    Wiktor Czykin      1.4        14/12/2016  Modified to include OC_Batch_Updated_Date__c date condition
    ****************************************************************************************/
    public void updateCallTypeCounters(Outbound_Call_Rule__c ocRule){
        if(ocRule == null) return;
        if(!ocRule.Show_Record_Counters__c) return;

        mapCallTypeIndex = new Map<String, Integer>();
        List<SelectOption> callTypeOptionsUpdated = new List<SelectOption>();
        for(Integer i=0; i<callTypeOptions.size(); i++){
            DateTime timeNow = DateTime.now();
            String callTypeName = callTypeOptions[i].getValue();
            callStageDateTimeFieldName = stageToStageDatetimeFieldMap.get(callTypeName);
            mapCallTypeIndex.put(callTypeName, i);
            Date localComparisonDate = this.comparisonDate;
            String query = 'SELECT COUNT() FROM Case'
            + ' WHERE  Status != \'' + Constants.CASE_STATUS_COMPLETED + '\''
            + ' AND OC_Call_Stage__c = \'' + callTypeName + '\''
            + ' AND RecordTypeId = \'' + rtId + '\''
            + ' AND ' + callStageDateTimeFieldName + ' <= :timeNow'
            + ' AND Print_Subscription__c != NULL'
            + ' AND AccountId != NULL'
            + (localComparisonDate!=null?' AND OC_Batch_Updated_Date__c != NULL AND OC_Batch_Updated_Date__c > :localComparisonDate':'')
            + (callTypeName == Constants.OC_T2_CATCH_UP ? ' AND OC_Stage_1_Outcome__c != \'' + Constants.OC_NO_SALE_OUTCOME + '\' AND OC_Stage_1_Outcome__c != \'' + Constants.OC_CHEQUE_SALES + '\'' : '');

            if(String.isNotEmpty(ocRule.Priority_Field__c)){
                query += ' AND ' + ocRule.Priority_Field__c + ' > -1';
            }
            query += ' LIMIT 101';

            callTypeOptionsUpdated.add(new SelectOption(callTypeName, callTypeName + parseCaseCounter(Database.countQuery(query))));
        }
        callTypeOptions = callTypeOptionsUpdated;
    }

    /************************************************************************************
    Method Name  : onClickGetCustomer
    Refactored by: Mantas Grigaliunas
    Change Date  : 08/08/2016
    Function     : Fetch next customer on button click
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Wiktor Czykin     23/02/2015  //added Start_Date__c fetching
    * Wiktor Czykin     27/02/2015  //modified CreatedDate condition value fetching
    * Wiktor Czykin     29/04/2015  //removed next available start date fetching
    * Wiktor Czykin     21/10/2015  //added Renewal_Price_Override__c for previous seubscription soql
    * Sally ElGhoul     22/03/2016  //get the TCode_Product__c field for the subscription
    * Wiktor Czykin     26/07/2016  //added support for product switcher
    * Pawel Chrzanowski 12/09/2016  Added call type counters
    * Michal Szewczyk   27/09/2016  // changed CASE_STATUS_CLOSED to CASE_STATUS_COMPLETED
    * Pawel Chrzanowski 29/09/2016  Added Retailer dependency
    * Pawel Chrzanowski 12/10/2016  Added Case load from URL
    * Pawel Chrzanowski 20/10/2016  Added Scheduled Callback editable check
    * Pawel Chrzanowski 21/10/2016  Reworked Delivery Type
    * Michal Szewczyk   24/10/2016  Added order based on callStageDateTimeFieldName
    * Wiktor Czykin     28/10/2016  Modified productSwitcher instantiation
    * Pawel Chrzanowski 14/11/2016  Added 'Show Record Counters' checkbox support
    * Pawel Chrzanowski 29/11/2016  Hid 'No Sale' and 'Cheque Sales' Cases in T2 Catch Up
    * Wiktor Czykin     09/12/2016  Added comparison to make sure the concurent fetch works as expected
    * Wiktor Czykin     14/12/2016  Modified to include OC_Batch_Updated_Date__c date condition
    * Wiktor Czykin     19/12/2017  Removed getRelatedIncentive() call as it was moved to updateIncentivesNew() method
    * Wiktor Czykin     11/04/2017  Added clearing of page messages section flags. Added enabling of error section for error related to product switcher.
    *************************************************************************************/
    public void onClickGetCustomer(){
        System.debug('Queries BEFORE onClickGetCustomer() ' + Limits.getQueries());
        this.clearPageMessage();

        //limits validation
        Integer limitToCheck = Limits.getLimitQueries() - 11;
        if(Limits.getQueries() > limitToCheck){
            addPageMessage(CALL_DETAILS_TOP_MSG, WARNING, Label.Outbound_Call_System_Busy);
            return;
        }

        thisCase = null;
        thisAccount = null;
        thisSubscription = null;
        saveButtonLabel = Label.OC_Save_And_Next;
        alreadySaved = false;
        editScheduleCallback = false;

        //call type validation
        if(callType == null){
            addPageMessage(CALL_DETAILS_TOP_MSG, ERROR, Label.OC_Call_Type_Not_Selected);
            return;
        }

        try{
            callStageDateTimeFieldName = stageToStageDatetimeFieldMap.get(callType);
            DateTime timeNow = DateTime.now();
            Date localComparisonDate = this.comparisonDate;

            if(casefromURL == null){
                //scenario 1: user gets next Case
                String caseQuery =
                  'SELECT Id, ' + callStageDateTimeFieldName +
                + ' FROM Case'
                + ' WHERE  Status != \'' + Constants.CASE_STATUS_COMPLETED + '\''
                + ' AND OC_Call_Stage__c = \'' + callType + '\''
                + ' AND RecordTypeId = \'' + rtId + '\''
                + ' AND ' + callStageDateTimeFieldName + ' <= :timeNow'
                + ' AND Print_Subscription__c != NULL'
                + ' AND AccountId != NULL'
                + (localComparisonDate!=null?' AND OC_Batch_Updated_Date__c != NULL AND OC_Batch_Updated_Date__c > :localComparisonDate':'')
                + (callType == Constants.OC_T2_CATCH_UP ? ' AND OC_Stage_1_Outcome__c != \'' + Constants.OC_NO_SALE_OUTCOME + '\' AND OC_Stage_1_Outcome__c != \'' + Constants.OC_CHEQUE_SALES + '\'' : '');

                if(String.isNotEmpty(ocRule.Priority_Field__c)){
                    caseQuery += ' AND ' + ocRule.Priority_Field__c + ' > -1' +
                                 'ORDER BY ' + ocRule.Priority_Field__c + ','+ callStageDateTimeFieldName +' NULLS LAST LIMIT 101';
                }else{
                    caseQuery += ' ORDER BY ' + callStageDateTimeFieldName + ' NULLS LAST LIMIT 101';
                }

                caseList = new List<Case>();
                caseList = (List<Case>)Database.query(caseQuery);

                //update current call type counter
                if(ocRule.Show_Record_Counters__c){
                    callTypeOptions.remove(mapCallTypeIndex.get(callType));
                    if(mapCallTypeIndex.get(callType) == callTypeOptions.size()){
                        callTypeOptions.add(new SelectOption(callType, callType + parseCaseCounter(caseList.size())));
                    }else{
                        callTypeOptions.add(mapCallTypeIndex.get(callType), new SelectOption(callType, callType + parseCaseCounter(caseList.size())));
                    }
                }

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
            }else{
                //scenario 2: Case is fetched from URL
                thisCase = casefromURL;
                casefromURL = null;
                caseLastUpdateTimeStamp = thisCase.LastModifiedDate;
            }

            originalScheduledCallback = thisCase.OC_Scheduled_Callback__c;
            if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE){
                editScheduleCallback = true;
            }

            //set page context variables for subscriber, subscription and case
            tCodeName = tCodeMap.get(callType);
            thisAccount = getAccount();
            thisSubscription = getSubscription();
            thisCheque = (ocRule.Show_Cheques_Section__c ? getCheque() : null);
            caseCommentsList = new List<CaseComment>(thisCase.CaseComments);

            //delivery type
            initDeliveryOptions();

            //incentives
            updateIncentivesNew();

            try{
                productSwitcher = new ProductSwitchController(this, initialProductId, this.tCodeId, true, true);
                if(ApexPages.hasMessages()) this.formMsg = true;
            }catch(ProductSwitchController.ProductSwitchControllerException e){
                addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, e.getMessage());
            }

            System.debug('Queries after onClickGetCustomer() ' + Limits.getQueries());
        }catch(Exception e){
            addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, Label.OC_Error, e.getMessage());
       }
    }

    /************************************************************************************
    Method Name  : saveCustomer
    Refactored by: Mantas Grigaliunas
    Change Date  : 08/08/2016
    Function     : Save current case record and relative information
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    30/08/2016  Added subscription update functionality to make sure selected product is updated
    * Michal Szewczyk       20/09/2016  Added subscription status changed based on case outcome and no sales reason
    * Pawel Chrzanowski     27/09/2016  Added Scheduled Callback validation
    * Pawel Chrzanowski     12/10/2016  Removed fetching of next customer
    * Pawel Chrzanowski     21/10/2016  Reworked Delivery Type
    * Pawel Chrzanowski     25/10/2016  Modified Scheduled Callback validation
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

            if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_DECEASED || thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_TABLET_PLUS || thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_WEBSITE_PLUS){
                thisSubscription.Subscription_Status__c = Constants.SSTATUS_DECLINED;
            }
            if(thisCase.OC_Outcome__c == Constants.OC_NO_SALE_OUTCOME && (thisCase.OC_No_Sale_Reason__c == Constants.OC_NO_SALE_REASON_ILLNESS || thisCase.OC_No_Sale_Reason__c == Constants.OC_NO_SALE_REASON_DECEASED)){
                thisSubscription.Subscription_Status__c = Constants.SSTATUS_DECLINED;
            }

            //update thisCase
            Database.SaveResult result = Database.update(thisCase, false);
            if(!result.isSuccess()){
                addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, result.getErrors());
                return false;
            }

            //update thisSubscription
            SubscriptionTriggerHandler.getInstance().bOcCaseUpdateSkip = true;
            Database.SaveResult subResult = Database.update(thisSubscription, false);
            if(!subResult.isSuccess()){
                addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, subResult.getErrors());
                return false;
            }
        }catch(Exception e){
            addPageMessage(CALL_DETAILS_TOP_MSG, FATAL, Label.OC_Error, e.getMessage());
            return false;
        }
        return true;
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 12/10/2016
    Method to save and get next customer
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public void onClickSaveAndGetNextCustomer(){
        if(saveCustomer()){
            onClickGetCustomer();
        }
    }

    /************************************************************************************
    Method Name  : saveAndTakePayment
    Refactored by: Mantas Grigaliunas
    Change Date  : 08/08/2016
    Function     : Validating inputs. Checking SAM. Saving Account (and Subscription for Premium).  Redirecting to MPP payment page
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Wiktor Czykin     24/02/2015  //added Start_Date__c validation. Binned  is4thMondayAtLeast validation
    * Wiktor Czykin     03/09/2015  //removed ErrorMessages__c setting reference
    * Wiktor Czykin     11/2015     //changed order taken details fetching method (moved to MppUtil) and wrapper class these details use
    * Wiktor Czykin     22/12/2015  //changed how return url is built and synced sam validation with offline renewal as was causing issues for call centre
    * Wiktor Czykin     25/05/2016  //added entitlements settin for SAM CREATE scenario
    * Gavin Palmer      13/06/2016  // some refactoring, removal of unused variables and conditions that always return false
    * Pawel Chrzanowski 22/09/2016  //added isOCRS parameter
    * Pawel Chrzanowski 12/10/2016  //added ocrsCase parameter, removed recursion with fetching Customers
    * Pawel Chrzanowski 21/10/2016  Reworked Delivery Type
    * Pawel Chrzanowski 01/12/2016  Allowed Cheque Sales as sale
    * Wiktor Czykin     13/12/2016  //Added weekly price validation
    * Pawel Chrzanowski 14/12/3016  Added Sale outcome validation
    * Wiktor Czykin     14/12/2016  //Added fix for cheque delete if there is not cheque
    * Wiktor Czykin     18/01/2016  //Added passing of incentive description
    * Wiktor Czykin     11/04/2017  //Added validation for selected product in product switcher
    *************************************************************************************/
    public PageReference saveAndTakePayment(){
        if(productSwitcher.selectedProduct == null){
            addPageMessage(CALL_DETAILS_MSG, ERROR, Label.OC_Product_not_available_for_tcode);
            return null;
        }

        //validate Sale outcome
        if(String.isBlank(thisCase.OC_Outcome__c) || thisCase.OC_Outcome__c != Constants.CASE_OUTCOME_SALE){
            addPageMessage(CALL_DETAILS_MSG, ERROR, Label.OC_ensure_agentOutboundCommision);
            return null;
        }

        //validate Sale payment type
        if(thisSubscription.Payment_Type__c == Constants.SUB_PMETHOD_CHEQUE){
            addPageMessage(CALL_DETAILS_MSG, ERROR, Label.OC_Update_Payment_Type);
            return null;
        }

		try{
			accEditEnabled = false;
			subEditEnabled = false;

			Account subscriber = thisAccount;

			validateDeliveryType();
			if(!isValidDeliveryType){
				return null;
			}

			if(!this.validatePrice()){
				addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, Label.OC_Weekly_Price_Validation);
				return null;
			}

			// Get the Guid if set on the Existing Account (= Already Linked with SAM)
			SAMUtil samUtil = new SAMUtil();
			String Guid = String.isBlank(ApexPages.CurrentPage().getParameters().get('Guid')) ? thisAccount.Guid__c : ApexPages.CurrentPage().getParameters().get('Guid');

			//No email = no Digital
			if(!String.isBlank(subscriber.PersonEmail)){
				try{
					SAMUtil.SAMAccountResult samAccount = samUtil.getExistingSAMAccount(subscriber.PersonEmail);

					if(samAccount.entitlementStatus != null && samAccount.entitlementStatus.equals(Constants.SAM_ENTITLEMENT_STATUS_ACTIVE)){
						List<Account> accSAMList = [
							SELECT Id, PersonEmail, Account.Guid__c
							FROM Account
							WHERE PersonEmail = :subscriber.PersonEmail
							AND Account.Guid__c = NULL
						];

						if(accSAMList.size() != 1
							&& thisSubscription.Start_Date__c <= System.today()
							&& !(thisSubscription.Subscription_Status__c.equals(Constants.SSTATUS_ACTIVE)
								|| thisSubscription.Subscription_Status__c.equals(Constants.SSTATUS_PENDING)) ){

							addPageMessage(CALL_DETAILS_MSG, FATAL, Label.OC_Active_Sub, new List<String>{samAccount.guid});
							return null;
						}
					}

					Guid = samAccount.guid;
				}catch(System.CalloutException ce){
					System.debug('### saveAndTakePayment ERROR. ' + ce);
					addPageMessage(CALL_DETAILS_MSG, FATAL, Label.OC_SAM_Email_Error, new List<String>{subscriber.PersonEmail});
					return null;
				}catch(WebserviceUtil.SamException e){
					if(e.getError().errorMessage.contains(Constants.SAM_ACCOUNT_LOCKED)) {
						addPageMessage(CALL_DETAILS_MSG, FATAL, Label.SAM_Account_locked_error, e.getError().errorMessage);
					} else {
						addPageMessage(CALL_DETAILS_MSG, FATAL, Label.OC_SAM_Email_Error, new List<String>{subscriber.PersonEmail});
					}
					return null;
				}
			}

			subscriber.Guid__c = Guid;

			//Get order taken fields for passing back to MPP.
			MppUtil.OrderTakenDetails mppFieldMap = MppUtil.getOrderTakenFieldMap(UserInfo.getUserId(), Constants.CONST_DSOSOrderTakenCompany , Constants.DIRECTION_OUTBOUND);
			thisSubscription.Order_Taken_Date__c = Date.today();
			thisSubscription.Order_Taken_By_Company__c = mppFieldMap.byCompany;
			thisSubscription.Order_Taken_By_User_Department__c = mppFieldMap.byUser;
			thisSubscription.Order_Taken_Method__c = mppFieldMap.orderMethod;

			//update thisSubscription;
			SubscriptionTriggerHandler.getInstance().bOcCaseUpdateSkip = true;
			Database.SaveResult result = Database.update(thisSubscription, false);
			if (!result.isSuccess()) {
				addPageMessage(CALL_DETAILS_MSG, FATAL, result.getErrors());
				return null;
			}

			String paymentStartDate;//required for MPP call, but not in renewal
			String tsNumber = thisAccount.Subscriber_Number_static__c;
			Double weekly_price = thisSubscription.Weekly_Price__c;
			Date preferedStartDate = SubscriptionTriggerHandler.findNextStartDate(thisSubscription);
			Id subid = thisSubscription.id;
			String paymentType;

			if(thisSubscription.Payment_Type__c == Constants.SUB_PMETHOD_CC){
				paymentType = Constants.SUB_ACQUISITION_PAYMENT_CC;
			}else if(thisSubscription.Payment_Type__c == Constants.SUB_PMETHOD_DD){
				paymentType = Constants.SUB_ACQUISITION_PAYMENT_DD;
			}else{
				paymentType = thisSubscription.Payment_Type__c;
			}
			preferedStartPaymentDate = thisSubscription.PaymentDate__c;
			displayedPaymentType = thisSubscription.Payment_Type__c;

			if(thisSubscription.Payment_Type__c == Constants.SUB_PMETHOD_DD){
				thisSubscription.MPP_DD_Frequency__c = paymentFrequency;
				thisSubscription.MPP_CC_Frequency__c = null;
			}else{
				thisSubscription.MPP_CC_Frequency__c = paymentFrequency;
				thisSubscription.MPP_DD_Frequency__c = null;
			}

			if(!thisSubscription.isContinuous__c){
				thisSubscription.MPP_DD_Frequency__c = null;
				thisSubscription.MPP_CC_Frequency__c = null;
			}

			//Set payment details (this also calls updateIncentivesNew)
			checkPaymentState();

			//On offered record preferred start date is Start_Date__c
			//For adhoc renewal use End_Date__c.addDays(1)
			//This process only deals with Individual (non-digital) subscription
			String digiRecTypeId = UtilityLookupSubscriptionVariables.getRecordType(Constants.RECTYPE_DIGISUB);

			subscriber.RecordTypeID = UtilityLookupSubscriptionVariables.getRecordType(Constants.RECTYPE_INDIVSUB);

			String subscriberStatus = (subscriber.RecordTypeID == digiRecTypeId ? subscriber.Subscriber_Digital_Status__c : subscriber.Subscription_Status__c);
			// Subscription bought offline
			subscriber.Origin__c = Constants.SUBSCRIBER_ORIGIN_FLOW_OFFLINE;
			// The Tcode associated
			subscriber.Wave_ID__c = tCodeName;

			// The Customer could have an active Account already
			if(subscriber.Subscriber_Digital_Status__c == null){
				subscriber.Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE;
			}

			subscriber.TMG_Promo_Email__c = Integer.valueOf(accountPermissions.TMG_Promo_Email__c);
            subscriber.TMG_Promo_Phone__c = Integer.valueOf(accountPermissions.TMG_Promo_Phone__c);
            subscriber.TMG_Promo_Post__c = Integer.valueOf(accountPermissions.TMG_Promo_Post__c);
            subscriber.TMG_Promo_SMS__c = Integer.valueOf(accountPermissions.TMG_Promo_SMS__c);

			//This is a test to see if a subscriber exists with the Guid that's been created - not relevant to renewal
			if(TMGUtil.isDataValid(subscriber.Guid__c) && !TMGUtil.isDataValid(subscriber.Id) || TMGUtil.isDataValid(subscriber.Guid__c) && subscriberStatus == Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE){
				try{
					List<Account> accSAMList = Database.query('SELECT Id, Name, PersonEmail, Account.Guid__c FROM Account '
															+ ' WHERE Account.Guid__c = \'' + subscriber.Guid__c + '\''
															+ (TMGUtil.isDataValid(tsNumber) ? ' AND Subscriber_Number_static__c != \'' + tsNumber + '\'' : ''));

					if(!accSAMList.isEmpty()){
						addPageMessage(CALL_DETAILS_MSG, ERROR, 'There is already a subscriber with the GUID: {0} SFDC Link: <a href="/{1}">{2}</a>',
											new List<String>{subscriber.Guid__c, accSAMList[0].Id, accSAMList[0].Name});
						return null;
					}

				}catch(System.Exception e){
					addPageMessage(CALL_DETAILS_MSG, FATAL, 'No Accounts found for SAM GUID:' + subscriber.Guid__c);
				}
			}

			// We get the selcted price:
			String selectedPrice;

			// Continuous and 52 weeks are both weekly price * 52
			selectedPrice = (subscriptionType == Constants.SUBSCRIPTIONTYPE_26WEEKS) ? (String.valueOf(weekly_Price * 26)): (String.valueOf(weekly_Price * 52));
			// Get Preferred Payment date should already be filled in if this is an offered subscription renewal
			// Interestingly it isn't actually a date at all, rather a 2 character text field holding the preferred payment day - 1 or 15
			preferedStartPaymentDate = thisSubscription.PaymentDate__c;
			displayedPaymentType = thisSubscription.Payment_Type__c;

			if (thisSubscription.Payment_Type__c == Constants.SUB_PMETHOD_DD){
				paymentFrequency = thisSubscription.MPP_DD_Frequency__c;
			}else{
				paymentFrequency = thisSubscription.MPP_CC_Frequency__c;
			}

			// Calculate the Payment start date
			Date tmpStartDate = calculatePaymentStartDate(preferedStartDate, preferedStartPaymentDate,thisSubscription.isContinuous__c);
			paymentStartDate = tmpStartDate.format();
			//Preserve Scheduled Payment date for future MPP to MPP Renewals.
			thisSubscription.MPP_Scheduled_First_Payment_Date__c = tmpStartDate;

			// Check Price configuration
			if(String.isBlank(selectedPrice)){
				addPageMessage(CALL_DETAILS_MSG, ERROR, Label.OC_Price_Not_Correct);
				return null;
			}
			// This identifies the message that should be displayed in the confirmation page
			String action;
			String paymentMethod = paymentType == Constants.SUB_ACQUISITION_PAYMENT_CC ? Constants.MPP_PAYMENTMETHOD_CC : Constants.MPP_PAYMENTMETHOD_DD;

			// Next page is MPP if payment is needed. Prepare the values for MPP
			PageReference pr = Page.MppPaymentFrame;
			pr.getParameters().put('selectedProduct', Constants.PRODUCT_PREMIUM);
			pr.getParameters().put('email',  (subscriber.personEmail == null ? '':subscriber.personEmail));
			pr.getParameters().put('title', (subscriber.Salutation == null ? '':subscriber.Salutation));
			pr.getParameters().put('firstName', (subscriber.firstName == null ? '':subscriber.firstName));
			pr.getParameters().put('lastName', (subscriber.lastName == null ? '':subscriber.lastName));
			pr.getParameters().put('price', (selectedPrice == null ? '':selectedPrice));
			pr.getParameters().put('subscriptionType', (subscriptionType == null ? '':subscriptionType));
			pr.getParameters().put('PaymentMethod', (paymentMethod == null ? '':paymentMethod));
			pr.getParameters().put('PaymentFrequency', (paymentFrequency == null ? '':paymentFrequency));
			pr.getParameters().put('paymentStartDate', (paymentStartDate == null ? '':paymentStartDate));
			pr.getParameters().put('TCode', (tCodeName == null ? '':tCodeName));
			pr.getParameters().put('incentiveId',  '');
            pr.getParameters().put('incentiveDescription', ((String.isBlank(selectedIncentiveTemp) || selectedIncentiveTemp == Constants.OC_NONE)? '':this.getIncentiveDescription()));
			pr.getParameters().put('Guid', (Guid == null ? '':Guid));
			pr.getParameters().put('isOCRS', 'true');
			pr.getParameters().put('ocrsCase', thisCase.Id);

			//This logic checks to see if a payment has already been made by a new subscriber - not relevant for renewal
			//No payment for Active Account
			if((TMGUtil.isDataValid(subscriberStatus) && subscriberStatus.equalsIgnoreCase('active'))){
				// We check if we received a GUID from SAM
				if(String.isNotBlank(subscriber.Guid__c)){
					// UPDATE (AND LINK) SAM ACCOUNT
					samUtil.updateSamAccount(subscriber, subscriber.Subscriber_Number_static__c, Guid, Constants.PRODUCT_PREMIUM.toLowerCase(), false);
					action = Constants.SAM_UPDATE_SAM;
				}else{
					// CREATE SAM ACCOUNT
					subscriber.Guid__c = samUtil.createSamAccount(subscriber, subscriber.Subscriber_Number_static__c, Constants.PRODUCT_PREMIUM.toLowerCase(), false, true);
					action = Constants.SAM_CREATE_SAM;
				}
				// End of Flow: re direct to a confirmation page with a link to the Account

				// this could be done in a nicer way as in using the put method?
				pr = new PageReference(Page.MppPaymentConfirm.getUrl()+'?accId='+subscriber.id +'&subId='+thisSubscription.id + '&paymentStatus=SuccessWithoutPayment&action='+action+'&isOCRS=true');
				if (String.isNotBlank(tsNumber)){
					update subscriber;
				}
				if(action == Constants.SAM_CREATE_SAM){
					SubscriptionsWebservicesHandlers.setEntitlements(subscriber.Id);
				}
				return pr;
			}

			try{
				upsertSubscriptionIncentive();
			}catch(Exception e){
				addPageMessage(CALL_DETAILS_MSG, FATAL, Label.OC_Error, e.getMessage());
				return null;
			}

			//If Cheque was linked earlier then delete, to recalculate amount via triggers
			if(thisCheque != null){
				if(displayedPaymentType.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE)){
					try{
						TMGUtil.processChequePayment(thisSubscription.Id, chequeBatchSelected, createNewBatch, Integer.valueOf(thisSubscription.Subscription_Duration_Picklist__c), thisCheque, thisSubscription.Weekly_Price__c);
					}catch(Exception e){
						addPageMessage(CALL_DETAILS_MSG, FATAL, Label.OC_Cheque_Error, e.getMessage());
						return null;
					}
                    }else if(thisCheque != new Cheque__c() && thisCheque.Id != null){
					Database.DeleteResult deleteResult = Database.delete(thisCheque, false);
					if (!deleteResult.isSuccess()) {
						addPageMessage(CALL_DETAILS_MSG, FATAL, deleteResult.getErrors());
						return null;
					}
					thisCheque = new Cheque__c();
				}
			}
			//Cheque End

			//Save Open Case details as well
			saveCustomer();

			if(thisSubscription != null){
				upsertSubscriptionIncentive();
			}

			pr.getParameters().put('accId', subscriber.id);
			pr.getParameters().put('TSNumber', tsNumber);

			pr.getParameters().put('orderTakenMethod', (TMGUtil.isDataValid(mppFieldMap.orderMethod) ? mppFieldMap.orderMethod : ''));
			pr.getParameters().put('orderTakenByCompany', (TMGUtil.isDataValid(mppFieldMap.byCompany) ? mppFieldMap.byCompany : ''));
			pr.getParameters().put('orderTakenbyUser', (TMGUtil.isDataValid(mppFieldMap.byUser) ? mppFieldMap.byUser : ''));

			if(TMGUtil.isDataValid(subId)){
				pr.getParameters().put('subId', subId);
			}
			//Cheque stuff
			if(paymentType.toLowerCase().equals('cheque')){
				if(TMGUtil.isDataValid(subscriber.PersonEmail)){
					// We check if we received a GUID from SAM
					if(subscriber.Guid__c != null && subscriber.Guid__c!= ''){
						action = Constants.SAM_UPDATE_SAM;
					} else{
						action = Constants.SAM_CREATE_SAM;
					}
				}else{
					action = '';
				}

				if(!ApexPages.hasMessages()){
					pr = new PageReference(Page.MppPaymentConfirm.getUrl() + '?accId=' + subscriber.id+'&subId='+thisSubscription.id + '&PaymentStatus=Success&action='
						+ action + '&offeredMsg=<br/><br/>Subscription created successfully.&emailTrigger=true&isOCRS=true');
				}else{
					pr = null;
				}
			}

			SubscriberPortal.SUB_TRIGGER_FIRED = true;
			Constants.MPP_CALLOUT_DISABLED = true;

			//update subscriber;
			Database.SaveResult subscriberResult = Database.update(subscriber, false);
			if (!result.isSuccess()) {
				addPageMessage(CALL_DETAILS_MSG, FATAL, subscriberResult.getErrors());
				return null;
			}

			return pr;

		} catch(Exception e){
			addPageMessage(CALL_DETAILS_MSG, FATAL, Label.OC_Error, e.getMessage());
			return null;
		}
    }


    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 27/09/2016
    Method to manage Case Outcome change
    #############Change Log#############
    Modified by        Version    Change Date
    Michal Szewczyk    1.1        08/11/2016 added Product__c field population
    Wiktor Czykin      1.2        11/04/2017 added != null check for switcher selection
    ****************************************************************************************/
    public void caseOutcomeChange(){
        if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_RESCHEDULE){
            editScheduleCallback = true;
        }else{
            editScheduleCallback = false;
            thisCase.OC_Scheduled_Callback__c = originalScheduledCallback;
        }

        if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_SALE && productSwitcher.selectedProduct != null) {
            thisCase.Product__c = productSwitcher.selectedProduct.sProductName;
        } else {
            thisCase.Product__c = '';
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 27/09/2016
    Method to manage Case Scheduled Callback change
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        25/10/2016  Removed error handling from this method
    ****************************************************************************************/
    public void caseScheduledCallbackChange(){
        if(isScheduledCallbackValid()){
            ApexPages.getMessages().clear();
            clearPageMessage();
        }
    }


/**
--------------------------------------------------------------------------------- ACCOUNT
**/

    /************************************************************************************
    Method Name  : getAccount
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to retrieve related Account record and decleare Account Marketing Permissions
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private Account getAccount(){

        List<Account> accLst = new List<Account>([
            SELECT Name,RecordTypeId,Subscriber_Number__c,PersonTitle, Title__c,
                Salutation, Preferred_Phone_Contact__pc, Phone, PersonMobilePhone,
                PersonHomePhone, Subscriber_Number_static__c, PersonContactId,
                LastName, FirstName, IsPersonAccount, PersonMailingStreet,
                PersonMailingCity, PersonMailingState, PersonMailingPostalCode,
                PersonEmail, PersonMailingCountry, Permissions_Last_Change_Date__c,
                TMG_Promo_SMS__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Promo_Email__c,
                Guid__c, Teleappended_Date__c
            FROM Account
            WHERE Id = :thisCase.Account.Id
            LIMIT 1
        ]);

       if(accLst.isEmpty()){
            addPageMessage(SUBSCRIBER_DETAILS_MSG, ERROR, Label.Outbound_Calling_Subscription_Not_Found);
            return null;
       } else {

            Account thisAcc = accLst[0];

            accountPermissions = new Account(
                Id = thisAcc.Id,
                Permissions_Last_Change_Date__c = thisAcc.Permissions_Last_Change_Date__c,
                TMG_Promo_Email__c = thisAcc.TMG_Promo_Email__c,
                TMG_Promo_Phone__c = thisAcc.TMG_Promo_Phone__c,
                TMG_Promo_Post__c = thisAcc.TMG_Promo_Post__c,
                TMG_Promo_SMS__c = thisAcc.TMG_Promo_SMS__c,
                Guid__c = thisAcc.Guid__c
            );

            accBeforeEdit = thisAcc.clone(true);

            return thisAcc;
        }
    }

    /************************************************************************************
    Method Name  : enableEditAccount
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Used in visualforce page to render subscriber details section on edit mode
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void enableEditAccount(){
        accEditEnabled = true;
    }

    /************************************************************************************
    Method Name  : cancelAccountEdit
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Used in visualforce page to rerender subscriber details section on edit mode cancellation
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer             Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    16/08/2016  //added showEmailIFrame parameter to hide email change iframe on edit mode cancellation
    *************************************************************************************/
    public void cancelAccountEdit(){
        thisAccount = accBeforeEdit.clone(true);
        showEmailIFrame = false;
        accEditEnabled = false;
    }

    /************************************************************************************
    Method Name  : saveAccount
    Refactored by: Mantas Grigaliunas
    Change Date  : 08/08/2016
    Function     : Method to save subscriber record
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Wiktor Czykin     19/01/2016  //added salutation override
    *************************************************************************************/
    public void saveAccount(){
        try{

            if(String.isNotBlank(this.thisAccount.Title__c)){
                this.thisAccount.Salutation = this.thisAccount.Title__c;
            }

             // Checking that First is only Letters (suggested to remove SUB-4355)
            Pattern MyPattern = Pattern.compile('^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$');
            Matcher MyMatcher = MyPattern.matcher(thisAccount.FirstName);
            if (!MyMatcher.matches()){
                addPageMessage(SUBSCRIBER_DETAILS_MSG, FATAL, Label.OC_First_Name_not_valid);
                return;
            }

            //update thisAccount
            Database.SaveResult result = Database.update(thisAccount, false);
            if (!result.isSuccess()){
                addPageMessage(SUBSCRIBER_DETAILS_MSG, FATAL, result.getErrors());
                return;
            }

            accBeforeEdit = thisAccount.clone(true);
            accEditEnabled = false;

        }catch(Exception e){
            addPageMessage(SUBSCRIBER_DETAILS_MSG, FATAL, Label.OC_Error, e.getMessage());
            return;
        }
    }

    /************************************************************************************
    Method Name  : displayChangeEmailIFrame
    Author       : Pawel Chrzanowski
    Created Date : 15/03/2016
    Function     : display add/change email iFrame
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void displayChangeEmailIFrame(){
        this.showEmailIFrame = true;
    }

    /************************************************************************************
    Method Name  : hideChangeEmailIFrame
    Author       : Pawel Chrzanowski
    Created Date : 15/03/2016
    Function     : hide add/change email iFrame
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void hideChangeEmailIFrame(){
        this.showEmailIFrame = false;
    }

    /************************************************************************************
    Method Name  : refetchSubscriberEmail
    Author       : Pawel Chrzanowski
    Created Date : 15/03/2016
    Function     : refetch subscriber email and close add/change email iFrame
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Pawel Chrzanowski  02/12/2016  update cloned account also
    *************************************************************************************/
    public void refetchSubscriberEmail(){
        List<Account> lstAcc = [SELECT PersonEmail FROM Account WHERE Id = :thisAccount.Id];
        if(!lstAcc.isEmpty()){
            thisAccount.PersonEmail = lstAcc[0].PersonEmail;
            accBeforeEdit.PersonEmail = lstAcc[0].PersonEmail;
            showEmailIFrame = false;
        }else{
            addPageMessage(ACCOUNT_PERMISIONS_MSG, FATAL, Label.Offline_Acquisition_Account_refetch_error_update);
        }
    }

/**
---------------------------------------------------------------------------- SUBSCRIPTION
**/

    /************************************************************************************
    Method Name  : getSubscription
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Retrieves current and offered subscription records and defines visualforce page related data input variables
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer             Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    30/08/2016  Added offeredSubId and offeredSubName assignemnt
    * Pawel Chrzanowski     03/10/2016  Added tCodeId
    * Pawel Chrzanowski     21/10/2016  Reworked Delivery Type
    * Michal Szewczyk       08/11/2016  Added fields to soql
    * Wiktor Czykin         14/12/2016  Added populateSubscriptionType() rather than duplicated code
    *************************************************************************************/
    private Subscription__c getSubscription(){

        List<Subscription__c> subLst = [
            SELECT Name, Subscriber__c, Weekly_Price__c, Previous_Price__c,FirstRenewal__c, PaymentDate__c,
            Retailer__c,Duration__c, MPP_CC_Frequency__c, MPP_DD_Frequency__c, Delivery_Type__c,
            Payment_Type__c, TCode__c, Start_Date__c, End_Date__c, isContinuous__c, Subscription_Status__c,
            Subscription_Duration_Picklist__c, If_Is_Renewal_Binary__c, TCode_Product__c, Product__c, Product__r.Name,
            Previous_Subscription_Expiry__c,
            Previous_Subscription__c,
            Previous_Subscription__r.Name,
            Previous_Subscription__r.Start_Date__c,
            Previous_Subscription__r.End_Date__c,
            Previous_Subscription__r.Weekly_Price__c,
            Previous_Subscription__r.Renewal_Price_Override__c,
            Previous_Subscription__r.Product__c,
            Previous_Subscription__r.TCode__c
            FROM Subscription__c
            WHERE Id = :thisCase.Print_Subscription__c LIMIT 1];

        if(subLst.isEmpty()){
            addPageMessage(OFFERED_SUBSCRIPTION_MSG, ERROR, Label.Outbound_Calling_Offered_Subscription_Not_Found);
            return null;
        }

        Subscription__c thisSub = subLst[0];

        /* set vf parameters */
        if(thisSub.Previous_Subscription__c != null){
            previousSubscription = thisSub.Previous_Subscription__r;
            hasPreviousSubscription = true;
        }

        offeredSubId = thisSub.Id;
        offeredSubName = thisSub.Name;
        initialProductId = thisSub.Product__c;
        selectedDelivery = thisSub.Delivery_Type__c;
        dInitialWeeklyPrice = thisSub.Weekly_Price__c;
        displayedPaymentType = thisSub.Payment_Type__c;
        preferedStartPaymentDate = thisSub.PaymentDate__c;
        selectedSubscriptionDuration = thisSub.Subscription_Duration_Picklist__c;

        //set payment frequency
        if(thisSub.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            paymentFrequency = thisSub.MPP_DD_Frequency__c;
        }else{
            paymentFrequency = thisSub.MPP_CC_Frequency__c;
        }

        //set subscription type
        this.populateSubscriptionType(thisSub);

        //set tcode
        TCodeManagement__c tCode = getTCodeManagement(tCodeName);
        if(tCode != null){
            this.tCodeId = tCode.Id;
            thisSub.TCode__c = tCode.Id;
            thisSub.Order_Taken_Wave__c = tCode.Name;
        }

        System.debug('### getSubscription -> tCode: ' + tCode);
        subBeforeEdit = thisSub.clone(true);

        return thisSub;
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 21/10/2016
    Method to Init delivery type options based on subscription related product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void initDeliveryOptions(){
        if(thisSubscription == null) throw new TelegraphApplicationException('Wrong method call. Insufficient data to process.');
        String sParam;
        if(thisSubscription.Product__c != null){
            List<zqu__ZProduct__c> lstProductVoucherDelivery = [select Voucher_Delivery_Type__c from zqu__ZProduct__c where Id = :thisSubscription.Product__c and Voucher_Delivery_Type__c != null];
            if(!lstProductVoucherDelivery.isEmpty()){
                sParam = lstProductVoucherDelivery[0].Voucher_Delivery_Type__c;
            }
        }
        lstDeliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(sParam);
        if(lstDeliveryOptions == null) throw new TelegraphApplicationException('Offline_Acquisition_Renewal_Not_able_to_detect_delivery_types');
        setDeliveryOptions = new Set<String>();
        for(SelectOption so : lstDeliveryOptions){
            setDeliveryOptions.add(so.getValue());
        }
        validateDeliveryType();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/10/2016
    Method to validate weekly price explicitly rather than general failure because of trigger validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private Boolean validatePrice(){
        if(this.thisSubscription != null && (this.thisSubscription.Weekly_Price__c == null || this.thisSubscription.Weekly_Price__c <= 0)){
            return false;
        }
        return true;

    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 21/10/2016
    Method to validate delivery type vs product available delivery types
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void validateDeliveryType(){
        if(thisSubscription != null && String.isNotBlank(selectedDelivery) && !setDeliveryOptions.isEmpty() && setDeliveryOptions.contains(selectedDelivery)){
            isValidDeliveryType = true;
            return;
        }
        isValidDeliveryType = false;
        addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, Label.Offline_Renewal_Not_supported_delivery_type_for_selected_product);
    }

    /************************************************************************************
    Method Name  : enableSubEdit
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Used in visualforce page to render offered subscription details section on edit mode
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer           Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Pawel Chrzanowski   21/10/2016  Reworked Delivery Type
    *************************************************************************************/
    public void enableSubEdit(){
        try{
            validateDeliveryType();
        }catch(Exception e){
            System.debug('### enableSubEdit: ' + e);
            addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, e.getMessage(), e.getMessage());
            return;
        }
        subEditEnabled = true;
    }

    /************************************************************************************
    Method Name  : cancelSubEdit
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Used in visualforce page to rerender offered subscription details section on edit mode cancellation
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer             Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    30/08/2016  Added logic to sustain the product code if it was changes using Product Switch component
    * Pawel Chrzanowski     05/09/2016  fix for selected incentive
    * Pawel Chrzanowski     21/10/2016  Reworked Delivery Type
    * Wiktor Czykin         14/12/2016  Added setting of subscription type
    *************************************************************************************/
    public void cancelSubEdit(){
        //reset temporary changes to selected incentive
        selectedIncentiveTemp = selectedIncentive;

        if(thisSubscription.Product__c != subBeforeEdit.Product__c){
            subBeforeEdit.Product__c = thisSubscription.Product__c;
        }
        thisSubscription = subBeforeEdit.clone(true);
        selectedSubscriptionDuration = thisSubscription.Subscription_Duration_Picklist__c;
        populateSubscriptionType(thisSubscription);
        thisSubscription.Id = offeredSubId;
        preferedStartPaymentDate = thisSubscription.PaymentDate__c;
        displayedPaymentType = thisSubscription.Payment_Type__c;
        selectedDelivery = thisSubscription.Delivery_Type__c;
        thisCheque = (chequeBeforeEdit == null ? new Cheque__c() : chequeBeforeEdit.clone(true));
        chequeBatchSelected = chequeBatchBeforeEdit;
        subEditEnabled = false;
    }

    /************************************************************************************
    Method Name  : populateSubscriptionType
    Author       : Wiktor Czykin
    Created Date : 14/12/2016
    Function     : Extracted duplicated code to common method
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer             Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void populateSubscriptionType(Subscription__c sub){
        if(sub.isContinuous__c){
            subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        }else if(sub.Subscription_Duration_Picklist__c == Constants.SUB_DURATION_52){
            subscriptionType = Constants.SUBSCRIPTIONTYPE_52WEEKS;
        }else{
            subscriptionType = Constants.SUBSCRIPTIONTYPE_26WEEKS;
        }
    }

    /************************************************************************************
    Method Name  : saveSub
    Refactored by: Mantas Grigaliunas
    Change Date  : 08/08/2016
    Function     : Method to save Subscription record and validate cheque
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Wiktor Czykin         24/02/2015  added start date validation
    * Wiktor Czykin         26/07/2016  added support for product switcher
    * Mantas Grigaliunas    30/08/2016  Removed subscription update functionality
    * Pawel Chrzanowski     06/10/2016  Added subscription update
    * Mantas Grigaliunas    07/10/2016  Removed retailer search related functionality
    * Pawel Chrzanowski     17/10/2016  Added subscription type
    * Mantas Grigaliunas    18/10/2016  Added the Database.SaveResult definition to display validation error message on save
    * Pawel Chrzanowski     21/10/2016  Reworked Delivery Type
    * Wiktor Czykin         28/10/2016  Modified productSwitcher instantiation
    * Wiktor Czykin         14/12/2016  Modified order of execution to make sure the contexts subscriptionType is refreshed after duration is updated
    * Wiktor Czykin         19/12/2017  Removed getRelatedIncentive() call as it was moved to updateIncentivesNew() method
    *************************************************************************************/
    public void saveSub(){
        try{
            if(displayedPaymentType.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE.toLowerCase())){
                if(!validateChequeFields()) return;
            }

            //delivery type
            if(selectedDelivery == Constants.DELIVERYTYPE_OTC){
                thisSubscription.Retailer__c = null;
            }
            if(selectedDelivery == Constants.DELIVERYTYPE_HND && thisSubscription.Retailer__c == null){
               addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, Label.OC_Retailer_Not_Specified_Home_Delivery);
               return;
            }
            validateDeliveryType();
            if(!isValidDeliveryType){
                return;
            }

            thisSubscription.Delivery_Type__c = selectedDelivery;
            thisSubscription.Subscription_Duration_Picklist__c = this.selectedSubscriptionDuration;

            this.populateSubscriptionType(thisSubscription);
            if(thisSubscription.isContinuous__c){
                thisSubscription.PaymentDate__c = preferedStartPaymentDate;
            }


            thisSubscription.Payment_Type__c = displayedPaymentType;

            if(displayedPaymentType == Constants.SUB_PMETHOD_DD){
                thisSubscription.MPP_DD_Frequency__c=paymentFrequency;
                thisSubscription.MPP_CC_Frequency__c=null;
            }else{
                thisSubscription.MPP_CC_Frequency__c=paymentFrequency;
                thisSubscription.MPP_DD_Frequency__c=null;
            }

            if(!thisSubscription.isContinuous__c){
                thisSubscription.MPP_DD_Frequency__c=null;
                thisSubscription.MPP_CC_Frequency__c=null;
            }

            dInitialWeeklyPrice = thisSubscription.Weekly_Price__c;
            initialProductId = thisSubscription.Product__c;

            SubscriptionTriggerHandler.getInstance().bOcCaseUpdateSkip = true;
            Database.SaveResult result = Database.update(thisSubscription, false);
            if (!result.isSuccess()) {
                addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, result.getErrors());
                return;
            }
            subBeforeEdit = thisSubscription.clone(true);

            //cheque
            if(thisCheque != null) chequeBeforeEdit = thisCheque.clone(true);
            chequeEditEnabled = false;

            productSwitcher = new ProductSwitchController(this, initialProductId, this.tCodeId, true, true);
            upsertSubscriptionIncentive();
            updateIncentivesNew();

            subEditEnabled = false;
        }catch(Exception e){
            addPageMessage(OFFERED_SUBSCRIPTION_MSG, FATAL, Label.OC_Error, e.getMessage());
            return;
        }
    }

    /************************************************************************************
    Method Name  : getSubscriptionDurations
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to return Subscription Duration picklist values
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public List<SelectOption> getSubscriptionDurations(){
        List<SelectOption> subsDurationValues = new List<SelectOption>();
        if(thisSubscription.isContinuous__c){
            subsDurationValues.add(new SelectOption(Constants.SUB_DURATION_52, Constants.SUB_DURATION_52));
        }else{
            for(Schema.PicklistEntry value : Subscription__c.Subscription_Duration_Picklist__c.getDescribe().getPickListValues()){
                subsDurationValues.add(new SelectOption(value.getLabel(), value.getValue()));
            }
        }
        return subsDurationValues;
    }

/**
---------------------------------------------------------------------------------- CHEQUE
**/

    /************************************************************************************
    Method Name  : getCheque
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to retrieve cheque record
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private Cheque__c getCheque(){

        List<Cheque__c> cheque = new List<Cheque__c>([
            SELECT Cheque_Batch__c, Cheque_Batch__r.Name, Name_on_Cheque__c, Account_Number__c, Sort_Code__c,
                  Ref_Number_on_Cheque__c,Type__c, Cheque_Amount__c,Cheque_Banking_Status__c, Subscription__c
            FROM Cheque__c
            WHERE Subscription__c = :thisCase.Print_Subscription__c LIMIT 1
        ]);

        if(cheque.size() == 1){
            chequeBeforeEdit = cheque[0].clone(true);
            if(cheque[0].Cheque_Batch__r != null){
                chequeBatchSelected = cheque[0].Cheque_Batch__r.Name;
                chequeBatchBeforeEdit = chequeBatchSelected;
            }
            return cheque.get(0);
        } else {
            chequeBeforeEdit = new Cheque__c();
            return chequeBeforeEdit;
        }
    }


    /************************************************************************************
    Method Name  : clearCheque
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to set cheque record to blank if the cheque edit was cancelled
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void clearCheque(){
        if(displayedPaymentType.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE)){
            thisCheque = new Cheque__c();
        }
    }

    /************************************************************************************
    Method Name  : getChequeBatchOptions
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to retrieve available cheque batches records
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public List<SelectOption> getChequeBatchOptions(){
        List<SelectOption> chequeBatchOptions = new List<SelectOption>();
        chequeBatchOptions.add(new SelectOption('', ''));
        for (Cheque_Batch__c eachChequeBatch : [ SELECT Name From Cheque_Batch__c WHERE Batch_Closed_Date__c = NULL ORDER BY Name]){
            chequeBatchOptions.add(new SelectOption(eachChequeBatch.Name, eachChequeBatch.Name));
        }
        return chequeBatchOptions;
    }

    /************************************************************************************
    Method Name  : validateChequeFields
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to prevent from saving cheque if any of the required fields is empty
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @TestVisible
    private Boolean validateChequeFields(){
        Boolean isDataValid = true;

        if(String.isBlank(thisCheque.Name_on_Cheque__c)){
            addPageMessage(CHEQUE_MSG, ERROR, Label.OC_Blank_Field, new List<String>{TMGUtil.getFieldLabel(thisCheque.getSObjectType(), 'Name_on_Cheque__c')});
            isDataValid = false;
        }
        if(String.isBlank(thisCheque.Account_Number__c)){
           addPageMessage(CHEQUE_MSG, ERROR, Label.OC_Blank_Field, new List<String>{TMGUtil.getFieldLabel(thisCheque.getSObjectType(), 'Account_Number__c')});
           isDataValid = false;
        }
        if(String.isBlank(thisCheque.Sort_Code__c)){
            addPageMessage(CHEQUE_MSG, ERROR, Label.OC_Blank_Field, new List<String>{TMGUtil.getFieldLabel(thisCheque.getSObjectType(), 'Sort_Code__c')});
            isDataValid = false;
        }
        if(String.isBlank(thisCheque.Ref_Number_on_Cheque__c)){
            addPageMessage(CHEQUE_MSG, ERROR, Label.OC_Blank_Field, new List<String>{TMGUtil.getFieldLabel(thisCheque.getSObjectType(), 'Ref_Number_on_Cheque__c')});
            isDataValid = false;
        }

        return isDataValid;
    }



/**
---------------------------------------------------------------------------------- INCENTIVE
**/

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 05/09/2016
    Function - Method to get related Subscription Incentive Association
    #############Change Log#############
    Modified by        Version    Change Date
    Michal Szewczyk    1.1        29/09/2016  - added offeredSubId to the query
    ****************************************************************************************/
    public void getRelatedIncentive(){
        List<SubscriptionIncentiveAssociation__c> lstSia = [SELECT Reason__c, Incentive_Description__c, Incentive__r.Name
                                                            FROM SubscriptionIncentiveAssociation__c
                                                            WHERE Subscriber__c = :thisCase.Account.Id AND Subscription__c =:offeredSubId AND Incentive__r.Is_Valid_For_Renewal__c = true AND Incentive__r.Validity_Status__c = true
                                                            ORDER BY CreatedDate DESC LIMIT 1];
        if(!lstSia.isEmpty()){
            relatedIncentive = lstSia[0];
        }else{
            relatedIncentive = null;
        }
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 09/06/2016
    Function - Method to get selected incentive description
    #############Change Log#############
    Modified by        Version    Change Date
    ****************************************************************************************/
    public String getIncentiveDescription(){
        return mapIncentiveDescription.get(selectedIncentiveTemp)!=null?mapIncentiveDescription.get(selectedIncentiveTemp):'';
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 02/09/2016
    Function - Incentive Reason getter
    #############Change Log#############
    Modified by        Version    Change Date
    Wiktor Czykin      1.1        19/01/2017    //added bRelatedIncentiveMatchesAvailable check
    ****************************************************************************************/
    public String getIncentiveReason(){
        if(!subEditEnabled){
            if(relatedIncentive == null || !bRelatedIncentiveMatchesAvailable){
                return '';
            }else{
                return relatedIncentive.Reason__c;
            }
        }else{
            if(relatedIncentive != null && selectedIncentiveTemp == selectedIncentive){
                return relatedIncentive.Reason__c;
            }
            if(selectedIncentiveTemp != Constants.OC_NONE && selectedIncentiveTemp != selectedIncentive){
                return INCENTIVE_PREFIX + callType;
            }
        }
        return '';
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Function - preparation of custom incentives list
    #############Change Log#############
    Modified by        Version    Change Date
    Wiktor Czykin      1.1        14/07/2015  added extra condition to Incentives soql to match lookup filter
    Sally ElGhoul      1.2        22/03/2016  get the incentives from the tcdoe product incentive
    Pawel Chrzanowski  1.3        02/09/2016  added current incentive selection
    Wiktor Czykin      1.4        25/10/2016  modified the method called to retrieve incentives
    Wiktor Czykin      1.5        19/01/2017  added here getRelatedIncentive() call and boolean recalculation to determine if incentive reason should be shown
    ****************************************************************************************/
    public void updateIncentivesNew(){
        getRelatedIncentive();
        activeIncentives = new List<SelectOption>{new SelectOption(Constants.OC_NONE, Constants.OC_NONE)};
        hasIncentives = true;

        //This if else statement can be removed later on after all data migration is done and complete but now to avoid any issues we agreed to leave the old logic for now
        if(this.tcodeId != null && thisSubscription.Product__c != null){
            //get the incentive based on the subscription tcode and subscription product
            List<TCode_Product_Incentive__c> lstProductTcodeIncentives = GlobalQueries.getProductTcodeIncentives(this.tcodeId, thisSubscription.Product__c);
            for(TCode_Product_Incentive__c incentiveProdObj : lstProductTcodeIncentives){

                if(incentiveProdObj.Is_Incentive_Valid_For_Renewal__c){
                    activeIncentives.add(new SelectOption(incentiveProdObj.Incentive__c, incentiveProdObj.Incentive_Name__c));
                    mapIncentiveDescription.put(incentiveProdObj.Incentive__c, incentiveProdObj.Incentive_Description__c);
                }
            }
        }else{
            for(Incentive__c inc: [SELECT Name, Incentive_Description__c FROM Incentive__c
                                   WHERE Is_Valid_For_Renewal__c = true AND Validity_Status__c = true]){

              activeIncentives.add(new SelectOption(inc.id, inc.name));
              mapIncentiveDescription.put(inc.id, inc.Incentive_Description__c);
            }
        }

        incentiveName = activeIncentives[0].getLabel();
        selectedIncentive = activeIncentives[0].getValue();
        selectedIncentiveTemp = activeIncentives[0].getValue();

        //select relative incentive if it exists
        bRelatedIncentiveMatchesAvailable = false;
        if(relatedIncentive != null){
            for(SelectOption s : activeIncentives){
                if(s.getLabel() == relatedIncentive.Incentive__r.Name){
                    incentiveName = relatedIncentive.Incentive__r.Name;
                    selectedIncentive = relatedIncentive.Incentive__c;
                    selectedIncentiveTemp = relatedIncentive.Incentive__c;
                    bRelatedIncentiveMatchesAvailable = true;
                    break;
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 10/06/2016
    Function - Moved the validation into its own method to simplify the saveSub method
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        02/09/2016  reworked code to use related incentive
    ****************************************************************************************/
    public void upsertSubscriptionIncentive(){
        //create new incentive
        if(relatedIncentive == null && selectedIncentiveTemp != Constants.OC_NONE){
            SubscriptionIncentiveAssociation__c sia = new SubscriptionIncentiveAssociation__c();
            sia.Incentive__c = selectedIncentiveTemp;
            sia.Subscriber__c = thisAccount.Id;
            sia.Subscription__c = thisSubscription.Id;
            sia.Reason__c = INCENTIVE_PREFIX + callType;
            insert sia;
        }

        //update current incentive
        if(relatedIncentive != null && selectedIncentiveTemp != Constants.OC_NONE && selectedIncentiveTemp != relatedIncentive.Incentive__c){
            relatedIncentive.Incentive__c = selectedIncentiveTemp;
            relatedIncentive.Reason__c = INCENTIVE_PREFIX + callType;
            update relatedIncentive;
        }

        //delete current incentive
        if(relatedIncentive != null && selectedIncentiveTemp == Constants.OC_NONE){
            delete relatedIncentive;
        }

        //trigger on sia to update account(!) disable?
    }

 /**
-------------------------------------------------------------------------- PRODUCT SWITCH
**/

    /************************************************************************************
    Method Name  : changeProductId
    Author       : Gavin Palmer
    Created Date : 10/06/2016
    Function     : implementation of ProductSwitchSupport interface method - changes product Id in context and sets new pricing
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer           Date         Description
    * Pawel Chrzanowski   03/10/2016   Added tCodeId
    * Michal Szewczyk     07/11/2016   Added Case Product populaton if Outcome is Sale
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void changeProductId(Id productId){
        if(productId == null) throw new TelegraphApplicationException('Product switch functionality returned null value.');
        thisSubscription.Product__c = productId;
        if(thisCase.OC_Outcome__c == Constants.CASE_OUTCOME_SALE) {
            thisCase.Product__c =  productSwitcher.selectedProduct.sProductName;
        }
        if(thisSubscription.Product__c != this.initialProductId){
            TCode_Product__c tproduct = GlobalQueries.getTCodeProduct(this.tCodeId, thisSubscription.Product__c);
            thisSubscription.Weekly_Price__c = tproduct.Weekly_Price__c;
        }else{
            thisSubscription.Weekly_Price__c = this.dInitialWeeklyPrice;
        }
        initDeliveryOptions();
        updateIncentivesNew();
    }


    /************************************************************************************
    Method Name  : prepareProductListBeforeView
    Author       : Gavin Palmer
    Created Date : 10/06/2016
    Function     : implementation of ProductSwitchSupport interface method - makes sure forced price updates initially selected product
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void prepareProductListBeforeView(List<TCodeProductWrapper> lstProducts){
        if(this.dInitialWeeklyPrice != null && lstProducts != null && !lstProducts.isEmpty()){
            for(TCodeProductWrapper tpw : lstProducts){
                if(tpw.productId == this.initialProductId){
                    tpw.premiumPrice = this.dInitialWeeklyPrice;
                    break;
                }
            }
        }
    }



 /**
-------------------------------------------------------------------------- MARKETING PERMISSIONS
**/


    //Marketing perms variables end and Marketing perms properties start
    public Boolean p2ndEmail {
        get { return getBooleanFromInt('TMG_Promo_Email__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_Email__c'); }
    }

    public Boolean p2ndPhone {
        get { return getBooleanFromInt('TMG_Promo_Phone__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_Phone__c'); }
    }

    public Boolean p2ndPost {
        get { return getBooleanFromInt('TMG_Promo_Post__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_Post__c'); }
    }

    public Boolean p2ndSMS {
        get { return getBooleanFromInt('TMG_Promo_SMS__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_SMS__c'); }
    }

    @TestVisible public String lastUpdateDate {
        get {
            if (accountPermissions.Permissions_Last_Change_Date__c != null) {

                return accountPermissions.Permissions_Last_Change_Date__c.format();
            }
            return null;
        }
    }

    /************************************************************************************
    Method Name  : getBooleanFromInt
    Author       : Gavin Palmer
    Created Date : 07/06/2016
    Function     : get the value for boolean getters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer     Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Gavin Palmer  22/06/2016  //minor improvements to method
    *************************************************************************************/
    private Boolean getBooleanFromInt(String fieldName){

        if(accountPermissions.get(fieldName) == null){
            accountPermissions.put(fieldName, 0);
        }

        if (accountPermissions.get(fieldName) == 1) return true;
        return false;
    }

    /************************************************************************************
    Method Name  : setAccountBoolean
    Author       : Gavin Palmer
    Created Date : 07/06/2016
    Function     : update account details fields depending on the value being set
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer     Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void setAccountBoolean(Boolean booleanFlag, String fieldName){
        if (booleanFlag) accountPermissions.put(fieldName, 1);
        else accountPermissions.put(fieldName, 0);
    }

    /************************************************************************************
    Method Name  : savePerms
    Refactored by: Mantas Grigaliunas
    Change Date  : 08/08/2016
    Function     : Update account record with account permission changes
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void savePerms() {

        accountPermissions.Permissions_Last_Change_Date__c = System.today();
        //update accountPermissions;
        Database.SaveResult result = Database.update(accountPermissions, false);
        if (!result.isSuccess()) {
            addPageMessage(ACCOUNT_PERMISIONS_MSG, FATAL, result.getErrors());
        }
    }


 /**
----------------------------------------------------------------------------------- UTILS
**/

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 27/09/2016
    Method to validate Case Scheduled Callback
    #############Change Log#############
    Modified by        Version    Change Date
    Pawel Chrzanowski  1.1        19/10/2016   Changed dates to GMT
    Pawel Chrzanowski  1.2        25/10/2016   Added date in past validation
    Pawel Chrzanowski  1.3        29/11/2016   Modified deadline to 1pm
    ****************************************************************************************/
    private Boolean isScheduledCallbackValid(){
        Datetime inputDate = Datetime.newInstanceGmt(thisCase.OC_Scheduled_Callback__c.year(), thisCase.OC_Scheduled_Callback__c.month(), thisCase.OC_Scheduled_Callback__c.day(), thisCase.OC_Scheduled_Callback__c.hour(), thisCase.OC_Scheduled_Callback__c.minute(), thisCase.OC_Scheduled_Callback__c.second());
        Datetime now = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), Datetime.now().minute(), Datetime.now().second());

        //validation - date not in the past
        if(inputDate < now){
            addPageMessage(CASE_DETAILS_MSG, ERROR, Label.OC_Case_Scheduled_Callback_In_Past);
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
            addPageMessage(CASE_DETAILS_MSG, ERROR, Label.OC_Case_Scheduled_Callback);
            return false;
        }
    }

    /************************************************************************************
    Method Name  : getSubscriberAddress
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to display address in a single line on visualforce page
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public String getSubscriberAddress(){
        return (thisAccount.PersonMailingStreet != null ? thisAccount.PersonMailingStreet : '')
               + (thisAccount.PersonMailingCity  != null ?
                 (thisAccount.PersonMailingStreet != null ? ', ' : '') + thisAccount.PersonMailingCity : '')
               + (thisAccount.PersonMailingState != null ?
                 (thisAccount.PersonMailingStreet != null || thisAccount.PersonMailingCity != null ? ', ' : '')
               + thisAccount.PersonMailingState : '')
               + (thisAccount.PersonMailingStreet == null && thisAccount.PersonMailingCity == null && thisAccount.PersonMailingState == null ?
                 thisAccount.PersonMailingPostalCode : ' ' + thisAccount.PersonMailingPostalCode);
    }

    /************************************************************************************
    Method Name  : getTCodeManagement
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : Method to retrieve related TCode
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private TCodeManagement__c  getTCodeManagement(String tCodeName){
        List<TCodeManagement__c> tCode = new List<TCodeManagement__c>([SELECT Id, Name FROM TCodeManagement__c WHERE Name = :tCodeName LIMIT 1]);
        if(tCode.size() > 0) return tCode.get(0);
        else return null;
    }

    /************************************************************************************
    Method Name  : getCountries
    Author       : Unknown
    Created Date : Unknown
    Function     : Read Countries with code from Custom Settings
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public List<SelectOption> getCountries(){
        List<SelectOption> liOptions = new List<SelectOption>();

        if(thisAccount.RecordTypeId == RECID_RET_ACC ){
            liOptions.add(new SelectOption(
                Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE,
                Constants.UNITED_KINGDOM_COUNTRY_NAME_VALUE
            ));
        }else{
            for(Country_Codes__c country:[SELECT Name, Country_Name__c FROM Country_Codes__c ORDER BY Display_Order__c, Country_Name__c ASC]){
                liOptions.add(new SelectOption(country.Name, country.Country_Name__c));
            }
        }
        return liOptions;
    }


    /************************************************************************************
    Method Name  : calculatePaymentStartDate
    Author       : Unknown
    Created Date : Unknown
    Function     : Returns the Payment Start Date. User input: 1 or 15,
                   1 : always next date mont 1st day
                   15: if today before 15 then its this month's 15th
                   else Next month's 15th
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public Date calculatePaymentStartDate(Date preferedStartDate, String oneOrFifteen, Boolean isContinuous){
        Date paymentDate = preferedStartDate;
        Date dateStartDate = preferedStartDate;
        if(isContinuous){
            if(oneOrFifteen == '1'){
                paymentDate = Date.newinstance(dateStartDate.year(), dateStartDate.month()+1, 1);
            }else{
                if(dateStartDate.day() < 15){
                    paymentDate = Date.newinstance(dateStartDate.year(), dateStartDate.month(), 15);
                }
                else{
                    paymentDate = Date.newinstance(dateStartDate.year(), dateStartDate.month()+1, 15);
                }
            }

            //If PaymentDate is previous to Sub start then move it to next month
            if(paymentDate<dateStartDate){
                paymentDate = paymentDate.addMonths(1);
            }
        }
        return paymentDate;
    }

    /************************************************************************************
    Method Name  : checkPaymentState
    Author       : Unknown
    Created Date : Unknown
    Function     : Sets payment variables to null based on condition
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- --    -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void checkPaymentState(){
        preferedStartPaymentDate = null;
        if(subscriptionType != Constants.SUBSCRIPTIONTYPE_CONTINUOUS){
            paymentFrequency = null;
        }
    }

    /************************************************************************************
    Class Name   : addPageMessage
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : methods to add page message
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/

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

    //user friendly error message full error message passed as a string with additional comments
    private void addPageMessage(String location, ApexPages.Severity severity, String errorMessage, List<String> errorMessageParameters, String adminMessage){
        addPageMessage(location, severity, String.format(errorMessage , errorMessageParameters), String.format(adminMessage , errorMessageParameters));
    }

    //DMLException error message passed and converted to the user friendly string message
    private void addPageMessage(String location, ApexPages.Severity severity, List<Database.Error> errorLst){
        for(Database.Error error : errorLst){
            addPageMessage(location, severity, String.valueOf(error.getMessage()), String.valueOf(error));
        }
    }

    /* @ addPageMessage Methods End @ **/

    /************************************************************************************
    Class Name   : addSystemLogMessage
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : methods used to add system debug messages
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void addSystemLogMessage(String location, ApexPages.Severity severity, String errorMessage){
        System.debug('<TMG> OUTBOUND CALLING SALES IN ' + location + '. ' + String.valueOf(severity) + ' : ' + errorMessage);
    }

    /************************************************************************************
    Class Name   : addSystemLogMessage
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : methods to set boolean flags for the page messages based on section name
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void setPageMessage(String sectionName){
        formMsg = sectionName.equals(FORM_MSG);
        caseDetailsMsg = sectionName.equals(CASE_DETAILS_MSG);
        subscriberDetailsMsg = sectionName.equals(SUBSCRIBER_DETAILS_MSG);
        accountPermissionsMsg = sectionName.equals(ACCOUNT_PERMISIONS_MSG);
        currentSubscriptionMsg = sectionName.equals(CURRENT_SUBSCRIPTION_MSG);
        chequeMsg = sectionName.equals(CHEQUE_MSG);
        callDetailsBottomMsg = sectionName.equals(CALL_DETAILS_BOTTOM_MSG);
        callDetailsTopMsg = sectionName.equals(CALL_DETAILS_TOP_MSG);

        if(sectionName.equals(OFFERED_SUBSCRIPTION_MSG)){
            offeredSubscriptionMsg = true;
            callDetailsTopMsg = true;
        }

        if(sectionName.equals(CALL_DETAILS_MSG)){
            callDetailsBottomMsg = true;
            callDetailsTopMsg = true;
        }
    }

    /************************************************************************************
    Class Name   : clearPageMessage
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Function     : calling setPageMessage with blank value to set all boolean flags to false
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void clearPageMessage(){
        setPageMessage('');
    }

    /************************************************************************************
    Class Name   : getTimeStamp
    Author       : Mantas Grigaliunas
    Created Date : 17/08/2016
    Function     : method to return current date time without miliseconds
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/

    private DateTime getTimeStamp(){
        DateTime now = DateTime.now();
        return DateTime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
    }

}