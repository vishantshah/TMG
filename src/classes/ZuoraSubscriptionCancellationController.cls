/********************************************************************
 * ZuoraSubscriptionCancellationController
 * Author: Kevin Fabregue - Zuora UK
   Updated by Bhargav Kodali - Zuora Atlanta, added code to capture the cancellation reason
 * #############Change Log#############
 * Modified by         Version  Change Date
 * Sally ElGhoul        1.1     22/2/2016   //Modified this class that was provided by zuora only to call the preview cancellation method if we have only one option (no radio buttons) on pageload
 * Sally ElGhoul        1.2     01/4/2016   //Fixed the way we get the date for yesterday because it throws an exception of invalid date value if it runs for example on 1st of april which lead to date value 31/4/ which is invalid
 * Pawel Chrzanowski    1.3     12/04/2016  //Added hard cancellation for migrated subs 
 * Gavin Palmer         1.4     17/06/2016  //Changed go back functionality to go back to subscription 
 * Mantas Grigaliunas   1.5     29/06/2016  //changed constructor to extension, modified the constructor to handle the error in code rather then in button executing the java script
 * Mantas Grigaliunas   1.6     31/01/2017  //modified processMigratedSubscriptionCancellation() after RefundOrder method change in MppInterfaceHTTP
 * Pawel Chrzanowski    1.7     31/01/2017  //modified goBack()
 * Mantas Grigaliunas   1.8     30/03/2017  //modified previewCancellarion(), cancelSubscription(), processMigratedSubscriptionCancellation()
 *                                          //changed variable assignment in all methods after ZuoraSubscriptionCanceller was refactored       
 ********************************************************************/

public with sharing class ZuoraSubscriptionCancellationController {

    public String zSubscriptionId;
    public String zAccountId;
    public String subscriptionNumber;
    public Boolean eligibleForCancellation;
    public Date subscriptionServiceEndDate;
    public Date subscriptionTermStartDate;
    public Date earliestCancellationDate {get; set;}
    public String datename {get; set;}
    public Decimal previewedCancellationAmount {get; set;}
    public String cancellationReason {get; set;}
    public String sfdcAccountId;
    public Boolean renderPageItems { get; set; }
   
    public String selectedItem {get;set;}
    public Boolean promoBool {get;set;}
    public Boolean selectBool {get;set;}
    public Boolean displayPopUp {get;set;}
    public Boolean isSuccessfullCancellation{get;set;}
    public String popUpText {get;set;}

    public Zuora__Subscription__c subscriptionObj {get;set;}
    public Boolean isSubscriptionInGracePeriod{get;set;}
    public Boolean isSubscriptionMonthly{get;set;}
    public Date subscriptionStartDate;
    public Date subscriptionNextChargeDate{get;set;}
    public Date subscriptionEndDate{get;set;}
    public Date subscroptionInvoiceServiceEndDate;
    public Boolean hasInvoices;

    //hard cancellation for migrated Subscriptions
    public String mppRefundAmount {get;set;}
    public String mppRefundOrderId {get;set;}
    public String mppDeferredRevenue {get;set;}
    public Boolean subscriptionEligibleMigratedHardCancellation {get;set;}

    public Boolean mppReactivationSuccess;
    public Boolean mppHardCancelSuccess;
    public Boolean mppRefundSuccess;
    public Boolean zuoraHardCancelSuccess;
    public Account sfdcAccount;
    public Cancellation__c cancellation;
    public String mppErrorReport;
    public String mppSuccessReport;

    //constants
    @TestVisible final private String SELECT_OPTION_1 = 'Item1';
    @TestVisible final private String SELECT_OPTION_2 = 'Item2';
    @TestVisible final private String SELECT_OPTION_3 = 'Item3';

    public static String strGracePeriodDuration { set;
        get {
            Application_Settings__c gracePeriodSetting = Application_Settings__c.getInstance(Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME);
            return (gracePeriodSetting != null ?  gracePeriodSetting.Value__c : null);
        }
    }

    private Zuora.zApi zApi;
    private  Zuora__Subscription__c zSubscription;
    @TestVisible private Zuora__Subscription__c zSubscriptionRecord;
        
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        1/8/2015
    Function    Return if the subcancellation reason should be mandatory or not
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Boolean getIsSubCancellationRequired(){
        if(!String.isBlank(subscriptionObj.Cancellation_Reason__c) && subscriptionObj.Cancellation_Reason__c == Constants.SUBSCRIPTION_CANCELLATION_REASON_PRICE){
            return true;
        } else{
            return false;
        }
    }

    private static void appendWarningMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
    }

    private static void appendErrorMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    /*************************************************************************************** 
    Developer   Unknown
    Date        Unknown
    Function    Controller for Subscription cancellation page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.1         05/08/2015
    Pawel Chrzanowski   1.2         12/04/2016  //added hard cancellation for migrated subs
    Gavin Palmer        1.3         17/06/2016  // added assignment to sfSubscriptionId
    Mantas Grigaliunas  1.3         29/06/2016  //changed constructor to extension, added the condition to display an error if subscription is cancelled
    ****************************************************************************************/
    public ZuoraSubscriptionCancellationController(ApexPages.StandardController stdController){
        
        zSubscriptionRecord = (Zuora__Subscription__c) stdController.getRecord();

        //used in user interface to populate object fields
        subscriptionObj = new Zuora__Subscription__c();
        
        selectedItem                = 'NotSelected';
        cancellationReason          = '';
        selectBool                  = true;
        promoBool                   = true;
        previewedCancellationAmount = 0;
        displayPopUp                = false;
        isSuccessfullCancellation   = false;
        popUpText                   = '';
        renderPageItems             = true;

        //hard cancellation for migrated Subscriptions
        mppErrorReport                               = '';
        mppSuccessReport                             = '';
        mppRefundAmount                              = '';
        mppRefundOrderId                             = '';
        mppDeferredRevenue                           = '';
        zuoraHardCancelSuccess                       = false;
        mppReactivationSuccess                       = false;
        mppHardCancelSuccess                         = false;
        mppRefundSuccess                             = false;
        subscriptionEligibleMigratedHardCancellation = false;
        eligibleForCancellation                      = false;

        //check if the page contains id parameter
        if(String.isBlank(zSubscriptionRecord.Id)){
            renderPageItems = false;
            appendErrorMessage(Label.Zuora_Subscription_Cancellation_Id_Parameter_Missing_Error);
            return;
        } else if(String.isBlank(strGracePeriodDuration)){
            List<String> labelParameter = new List<String>{Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME};
            appendErrorMessage(String.format(Label.Zuora_Subscription_Canceller_Grace_Period_Not_Set_Error, labelParameter));
            return;
        } else {

            //get subscription record required details
           zSubscription = [ SELECT Id, Name, Zuora__Zuora_Id__c, Zuora__Status__c, Zuora_Subscription_Status__c, Subscription_Rate_Plan_Term_Type__c, 
                             Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__NextChargeDate__c, Zuora__TermStartDate__c, Zuora__Account__c, Zuora__NextRenewalDate__c,
                             Zuora__CustomerAccount__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__SubscriptionEndDate__c, Zuora__SubscriptionStartDate__c
                             FROM Zuora__Subscription__c WHERE Id = :zSubscriptionRecord.Id LIMIT 1 ];                                   

            zSubscriptionId            = zSubscription.Zuora__Zuora_Id__c;
            zAccountId                 = zSubscription.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
            subscriptionNumber         = zSubscription.Name;
            subscriptionNextChargeDate = zSubscription.Zuora__NextChargeDate__c;
            isSubscriptionMonthly      = (zSubscription.Subscription_Rate_Plan_Term_Type__c == Constants.RATE_PLAN_MONTHLY ? true : false);
            subscriptionTermStartDate  = zSubscription.Zuora__TermStartDate__c;
            subscriptionEndDate        = zSubscription.Zuora__SubscriptionEndDate__c;

            zApi = ZuoraUtilities.zuoraApiAccess();

            //check if zuora id exists
            if(String.isBlank(zSubscriptionId)){
                appendErrorMessage(Label.Subscription_Not_Found);
                renderPageItems = false;
                return;
            }     


            //if subsbscription is cancelled or has a pending cancellation status show error message
            if(!ZuoraSubscriptionCanceller.isSubscriptionActive(zApi, subscriptionNumber, zSubscription.Zuora__Status__c, zSubscription.Zuora_Subscription_Status__c)
                || !ZuoraSubscriptionCanceller.isRefundAllowed(zSubscription.Id)){
                appendErrorMessage(ZuoraSubscriptionCanceller.errorMessage);
                renderPageItems = false;
                return;
            } else {

                //check if subscription has invoices
                hasInvoices = ZuoraSubscriptionCanceller.checkZuoraSubscriptionHasInvoices(zApi, subscriptionNumber);

                //check if subscription is migrated
                if(subscriptionNumber.toUpperCase().startsWith('M') && !hasInvoices){
                    subscriptionEligibleMigratedHardCancellation = true;
                    appendWarningMessage(Label.Zuora_Subscription_Canceller_Migrated_Subscription_Eligible_For_MPP_Refund);
                }

                //standard flow for cancellation
                if(!subscriptionEligibleMigratedHardCancellation)
                    eligibleForCancellation = ZuoraSubscriptionCanceller.isAccountBalanceZero(zApi, zSubscription.Zuora__CustomerAccount__r.Zuora__AccountNumber__c);

                if(eligibleForCancellation || subscriptionEligibleMigratedHardCancellation){
                    sfdcAccountId = zSubscription.Zuora__Account__c;
                    subscriptionServiceEndDate = ZuoraUtilities.getEndOfTermValue(isSubscriptionMonthly, subscriptionNextChargeDate, subscriptionEndDate);
                    subscriptionStartDate = zSubscription.Zuora__SubscriptionStartDate__c;
                    isSubscriptionInGracePeriod = ZuoraSubscriptionCanceller.isSubscriptionInGracePeriod(subscriptionStartDate, strGracePeriodDuration);
                    //if we show the user the choose date value, they are allowed to choose date in the past so let's default it to yesterday
                    datename = TMGUtil.convertDateToString(Date.today().addDays(-1));
                    
                    if(!isSubscriptionInGracePeriod) {
                        String warningMessage = String.format(Label.Zuora_Subscription_Canceller_Outside_Grace_Period, new List<String>{strGracePeriodDuration});
                        if (isSubscriptionMonthly) {
                            warningMessage += Label.Zuora_Subscription_Canceller_Monthly_Sub_Warning;
                        } else {
                            warningMessage += String.format(Label.Zuora_Subscription_Canceller_Annual_Sub_Warning, new List<String>{strGracePeriodDuration});
                        }
                        appendWarningMessage(warningMessage);
                    }

                } else {
                    renderPageItems = false;
                    appendErrorMessage(Label.Zuora_Subscription_Canceller_Not_Eligible_For_Cancellation + ZuoraSubscriptionCanceller.errorMessage + 'Please contact your Zuora administrator.');
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer   Zuora
    Date
    Function   
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.0         22/2/2016   //Modified this class that was provided by zuora only to call the preview cancellation method if we have only one option (no radio buttons) on pageload
    Mantas Grigaliunas  1.1         29/06/2016  //Replaced hardcoded values with constants
    ****************************************************************************************/
    public List<SelectOption> getItems(){

        List<SelectOption> options = new List<SelectOption>();
        earliestCancellationDate = Date.today();

        if (eligibleForCancellation || subscriptionEligibleMigratedHardCancellation) {
            
            //if isSubscriptionInGracePeriod , the only option of cancellation available if to cancel on last invoice date
            if(isSubscriptionInGracePeriod){
                if (!hasInvoices) {
                     options.add(new SelectOption(SELECT_OPTION_2, String.format(Label.Zuora_Subscription_Canceller_Cancel_Today_Option, new List<String>{earliestCancellationDate.format()})));
                } else {
                    options.add(new SelectOption(SELECT_OPTION_2, String.format(Label.Zuora_Subscription_Canceller_Cancel_On_Last_Invoice_Option, new List<String>{subscriptionTermStartDate.format()})));
                    earliestCancellationDate = subscriptionTermStartDate;
                }
            } else if(!isSubscriptionInGracePeriod){
                //if is not isSubscriptionInGracePeriod , the user can choose either to cancel end of term of cancel today
                //if is not isSubscriptionInGracePeriod, show the option of choosing a specific date
                options.add(new SelectOption(SELECT_OPTION_1, String.format(Label.Zuora_Subscription_Canceller_Cancel_End_Term_Option, 
                    new List<String>{ZuoraUtilities.getEndOfTermValue(isSubscriptionMonthly, subscriptionNextChargeDate, subscriptionEndDate).format()})));
                options.add(new SelectOption(SELECT_OPTION_2, String.format(Label.Zuora_Subscription_Canceller_Cancel_Today_Option, new List<String>{Date.today().format()})));
                options.add(new SelectOption(SELECT_OPTION_3, Label.Zuora_Subscription_Canceller_Cancel_On_Specific_Date_Option));
            }
        }

        //check if only one option available select it and enable the process cancellation button
        if(options != null && options.size() == 1){
            selectedItem = options[0].getValue();
            changeSelectBool();
            //no radio button will show if only one option is available so we need to call preview cancellation 
            previewCancellation();
        }
        return options;
    }

    public void previewCancellation() {

        try{
        
            Date cancellationDate = null;
            if(selectedItem == SELECT_OPTION_1) { 
                previewedCancellationAmount = 0;
                return;
            } else if(selectedItem == SELECT_OPTION_2) {
                cancellationDate = earliestCancellationDate;
            } else {
                cancellationDate = Date.parse(datename);
                if(cancellationDate > ZuoraUtilities.getEndOfTermValue(isSubscriptionMonthly, subscriptionNextChargeDate, subscriptionEndDate)){
                    previewedCancellationAmount = 0;
                    return;
                }
            }

            if (cancellationDate != null) {
                previewedCancellationAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(zApi, zAccountId, zSubscriptionId, subscriptionNumber, 
                    cancellationDate, subscriptionObj.Cancellation_Reason__c, subscriptionObj.Sub_Cancellation_Reason__c, true, false, false);
            }
        }catch(Exception e){
            appendErrorMessage(e.getMessage());
        }
    }

    /*************************************************************************************** 
    Developer   Unknown
    Date        Unknown
    Function    go back from sub cancellation
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.2         31/01/2017  Redirected TMG Standard User back to Account page
    Mantas Grigaliunas  1.3         24/04/2017  Changed to use Constant to get profile id
    ****************************************************************************************/
    public PageReference goBack(){
        if(UserInfo.getProfileId() == Constants.getTMGStandardUserProfileId()){
            return new PageReference('/' + sfdcAccountId);
        }
        return new PageReference('/' + zSubscriptionRecord.Id);
    }

    /*************************************************************************************** 
    Developer   Pawel Chrzanowski
    Date        12/04/2016
    Function    process migrated Subscription cancellation
    ******************* Change Log *******************
    Modified by             Version   Change Date
    Mantas Grigaliunas    1.1         31/01/2017 //method name changed from RefundOrder to processRefundOrder and returned result changed to list
    ****************************************************************************************/
    public void processMigratedSubscriptionCancellation(Date cancellationDate){
        String tsNumber;
        String serviceId;
        String orderId;

        MPPInterfaceHTTP mpp = new MPPInterfaceHTTP(); 
        MPPInterfaceHTTP.AutoRenewResult mppAutoRenewResult;
        MPPInterfaceHTTP.CancelSubscriptionResult mppHardCancelResult;
        MPPInterfaceHTTP.RefundOrderResult mppRefundResult;

        Decimal refundAmount;

        //check Account info
        Set<String> paymentStatus = new Set<String>{Constants.ORDER_SUCCESS_STATUS_VALUE, Constants.ORDER_PENDING_STATUS_VALUE};
        List<Account> lstAccs = [ SELECT Cancellation_Type__c, MPP_Service_Id__c, RecordTypeId, Subscriber_Number_static__c, Subscriber_Digital_Status__c,
                                  (SELECT Id, Order_Id__c, Payment_status__c 
                                   FROM MPP_Transaction_Histories__r 
                                   WHERE Payment_Status__c IN :paymentStatus AND DD_Transaction_Type__c !=: 'AUDDIS'
                                   ORDER BY CreatedDate DESC LIMIT 1) 
                                FROM Account 
                                WHERE Id = :sfdcAccountId];

        if(lstAccs.isEmpty()){
            appendErrorMessage(Label.Validation_Error + ' ' + Label.No_Account_For_Subscription);
            return;
        }else{
            sfdcAccount = lstAccs[0];
        }
        if(!TMGUtil.isDataValid(sfdcAccount.MPP_Service_Id__c)){
            appendErrorMessage(Label.Validation_Error + ' ' + Label.Wrong_Service_ID);
            return;
        }
        if(sfdcAccount.MPP_Transaction_Histories__r.isEmpty()){
            appendErrorMessage(Label.Validation_Error + ' ' + Label.No_Transaction_History);
            return;
        }
        if(!TMGUtil.isDataValid(sfdcAccount.MPP_Transaction_Histories__r[0].Order_Id__c)){
            appendErrorMessage(Label.Validation_Error + ' ' + Label.No_Order_ID);
            return;
        }

        tsNumber = sfdcAccount.Subscriber_Number_static__c; 
        serviceId = sfdcAccount.MPP_Service_Id__c;
        orderId = sfdcAccount.MPP_Transaction_Histories__r[0].Order_Id__c;

        //hard cancel Zuora Subscription
        try{
            refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(zApi, zAccountId, zSubscriptionId, subscriptionNumber,
                cancellationDate, subscriptionObj.Cancellation_Reason__c, subscriptionObj.Sub_Cancellation_Reason__c, false, false, false);
            if(refundAmount == null){
                appendErrorMessage(Label.Remove_Zuora_Subscription_Error + ' ' + ZuoraSubscriptionCanceller.errorMessage);
                return;
            } else {
                zuoraHardCancelSuccess = true;
            }
            
        }catch(Exception e){
            appendErrorMessage(Label.Remove_Zuora_Subscription_Error + ' ' + e.getMessage());
            return;
        }

        //reactivate MPP Subscription
        try{
            mppAutoRenewResult = mpp.AutoRenewSubscriber(tsNumber, serviceId, 'true', false);
        }catch(Exception e){
            if(Test.isRunningTest() && !zSubscriptionId.contains('123456789_rfail')) {
                mppAutoRenewResult = new MPPInterfaceHTTP.AutoRenewResult();
                mppAutoRenewResult.autoRenewEnabled = true;
            }else{
                mppErrorReport += Label.Reactivate_Subscription_Error + ' ' + e.getMessage() + '<br/>';
                return;
            }
        }
        if(mppAutoRenewResult != null && mppAutoRenewResult.autoRenewEnabled != null && mppAutoRenewResult.autoRenewEnabled){
            mppReactivationSuccess = true;
            mppSuccessReport += Label.Subscription_Successfully_Reactivated_MPP + '<br/>';
        }else{
            mppErrorReport += Label.Reactivate_Subscription_Error + ' ' + mppAutoRenewResult + '<br/>';
            return;
        }

        //hard cancel MPP Subscription
        try{
            mppHardCancelResult = mpp.RemoveSubscription(tsNumber, serviceId);
        }catch(Exception e){
            mppErrorReport += Label.Remove_Subscription_Error + ' ' + e.getMessage() + '<br/>';
            return;
        }
        if(Test.isRunningTest()){
            if(!zSubscriptionId.contains('123456789_hcfail')){
                mppHardCancelResult = new MPPInterfaceHTTP.CancelSubscriptionResult();
                mppHardCancelResult.status = Constants.CANCELLATION_STATUS_REMOVED;
                if(!zSubscriptionId.contains('123456789_norefund')){
                    mppHardCancelResult.deferredRevenue = '10.0000';
                }
            }else{
                mppHardCancelResult = null;
            }
        }
        if(TMGUtil.isDataValid(mppHardCancelResult) && mppHardCancelResult.status == Constants.CANCELLATION_STATUS_REMOVED){
            mppHardCancelSuccess = true;
            mppSuccessReport += Label.Subscription_Successfully_Removed_MPP + '<br/>';
        }else{
            mppErrorReport += Label.Remove_Subscription_Error + ' ' + mppHardCancelResult + '<br/>';
            return;
        }

        //provide MPP refund if possible
        if(mppHardCancelSuccess && TMGUtil.isDataValid(mppHardCancelResult.deferredRevenue) && Decimal.valueOf(mppHardCancelResult.deferredRevenue) > 0){
            try{
                mppDeferredRevenue = mppHardCancelResult.deferredRevenue;
                mppRefundResult = mpp.processRefundOrder(tsNumber, orderId, Decimal.valueOf(mppHardCancelResult.deferredRevenue), false, false);
            }catch(Exception e){
                mppErrorReport += 'MPP deferred revenue: £' + mppDeferredRevenue + '<br/>';
                mppErrorReport += Label.Refund_Error_Msg + ' ' + e.getMessage() + '<br/>';
                return;
            }
            if(Test.isRunningTest()){
                if(!zSubscriptionId.contains('123456789_rffail')){
                    mppRefundResult = new MPPInterfaceHTTP.RefundOrderResult();
                    mppRefundResult.refundOrderId = '12345';
                    mppRefundResult.refundAmount = mppDeferredRevenue;
                    mppDeferredRevenue = mppHardCancelResult.deferredRevenue;
                }else{
                    mppRefundResult = null;
                }
            }
            if(TMGUtil.isDataValid(mppRefundResult) && TMGUtil.isDataValid(mppRefundResult.refundOrderId) && TMGUtil.isDataValid(mppRefundResult.refundAmount) && Decimal.valueOf(mppRefundResult.refundAmount) > 0.0){
                mppRefundSuccess = true;
                mppRefundAmount = String.valueOf(Decimal.valueOf(mppRefundResult.refundAmount).setScale(2));
                mppRefundOrderId = mppRefundResult.refundOrderId;
                mppSuccessReport += 'MPP refund amount: £' + mppRefundAmount + '<br/>';
                mppSuccessReport += Label.Subscription_Successfully_Refunded_MPP + '<br/>';
            }else{
                mppErrorReport += 'MPP deferred revenue: £' + mppDeferredRevenue + '<br/>';
                mppErrorReport += Label.Refund_Error_Msg + ' ' + mppRefundResult + '<br/>';
                return;
            }
        }else{
            mppSuccessReport += 'There was no refund from MPP.<br/>';
        }
    }

    /*************************************************************************************** 
    Developer   Unknown
    Date        Unknown
    Function    cancel subscription method invoking Zuora actions
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         10/09/2015
    Pawel Chrzanowski   1.2         21/04/2016  Added Migrated Subscription flow
    Mantas Grigaliunas  1.3         29/06/2016  Replaced hardcoded values with constants
    Mantas Grigaliunas  1.4         30/03/2017  Fixed cancelation date validation by moving below cancelation date definition logic
    ****************************************************************************************/
    public void cancelSubscription() {
        Date cancellationDate = null;
        Boolean processInvoice = true;
        Boolean refundPossible = false;
        Decimal cancellationAmount = null;
        String dmlSuccessReport = '';
        String dmlErrorReport = '';
        mppSuccessReport = '';
        mppErrorReport = '';
        mppRefundAmount = '';
        mppRefundOrderId = '';
        mppDeferredRevenue = '';
        zuoraHardCancelSuccess = false;
        mppReactivationSuccess = false;
        mppHardCancelSuccess = false;
        mppRefundSuccess = false;
        
        //validate zSubscriptionId
        if(String.isBlank(zSubscriptionId)){
            appendErrorMessage(Label.Subscription_Not_Found);
            return;
        }

        Date endOfTermDate = ZuoraUtilities.getEndOfTermValue(isSubscriptionMonthly, subscriptionNextChargeDate, subscriptionEndDate);
        //set cancellation date
        if(selectedItem == SELECT_OPTION_1) { 
            cancellationDate = endOfTermDate;
            processInvoice = false;
        } else if(selectedItem == SELECT_OPTION_2) {
            cancellationDate = earliestCancellationDate;
        } else {
            cancellationDate = Date.parse(datename);
            processInvoice = (isSubscriptionMonthly && cancellationDate > endOfTermDate ? false : true);
        }

        //validate cancellation reasons and dates
        if(!validForCancellation(cancellationDate)){
            return;
        }
        
        //flow for migrated cancellation
        if(subscriptionEligibleMigratedHardCancellation){

            processMigratedSubscriptionCancellation(cancellationDate);

            if(zuoraHardCancelSuccess){
                //MPP Subscription reactivation success/failure is irrelevant, no Account update needed
                if(mppHardCancelSuccess){
                    Cancellation__c newCancellation = new Cancellation__c();
                    newCancellation.Account__c = sfdcAccountId;
                    newCancellation.Cancellation_Type__c = Constants.HARD_CANCELLATION;
                    newCancellation.Cancelled_By__c = UserInfo.getUserId();
                    newCancellation.Cancelled_Date__c = cancellationDate;
                    newCancellation.MPP_Transaction_History__c = sfdcAccount.MPP_Transaction_Histories__r[0].Id;
                    newCancellation.Cancellation_Reason__c = subscriptionObj.Cancellation_Reason__c;
                    newCancellation.Reason_Details__c = subscriptionObj.Sub_Cancellation_Reason__c;
                    newCancellation.Cancellation_Status__c = Constants.COMPLETE_CANCELLATION_STATUS;

                    sfdcAccount.Subscriber_Digital_Status__c = Constants.SSTATUS_INACTIVE;
                    sfdcAccount.Cancellation_Type__c = Constants.HARD_CANCELLATION;
                    sfdcAccount.Cancelled_By__c = UserInfo.getUserId();
                    sfdcAccount.Cancelled_Date__c = cancellationDate;

                    try{
                        insert newCancellation;
                        dmlSuccessReport += Label.Subscription_Successfully_Removed_MPP_With_Cancellation_Insert + '<br/>';
                    }
                    catch(Exception e){
                        dmlErrorReport += Label.Error_Creating_Cancellation + ' ' + e.getMessage() + ' ' + Label.Manual_Update_Required + '<br/>';
                    }
                }else if(mppReactivationSuccess){
                    //rollback autorenew if MPP hard cancellation fails
                    MPPInterfaceHTTP mpp = new MPPInterfaceHTTP(); 
                    MPPInterfaceHTTP.AutoRenewResult mppAutoRenewResult;

                    try{
                        mppAutoRenewResult = mpp.AutoRenewSubscriber(sfdcAccount.Subscriber_Number_static__c, sfdcAccount.MPP_Service_Id__c, 'false', false);
                    }catch(Exception e){
                    }
                    if(mppAutoRenewResult != null && mppAutoRenewResult.autoRenewEnabled != null && !mppAutoRenewResult.autoRenewEnabled){
                        mppSuccessReport += Label.Subscription_Autorenew_Rollback_Success + '<br/>';
                    }else{
                        mppErrorReport += Label.Subscription_Autorenew_Rollback_Fail + ' ' + mppAutoRenewResult + ' ' + Label.Manual_Update_Required + '<br/>';
                    }
                }

                if(mppRefundSuccess){
                    try{
                        MPPInterfaceHTTP.createRefundTransactionHistory(sfdcAccount, mppRefundAmount, mppRefundOrderId);
                        dmlSuccessReport += Label.Subscription_Successfully_Refunded_MPP_With_Transaction_History_Insert + '<br/>';
                    }
                    catch(Exception e){
                        dmlErrorReport += Label.Error_Creating_Transaction_History + ' ' + e.getMessage() + ' ' + Label.Manual_Update_Required + '<br/>';
                    }
                }

                //update Account last to avoid other triggers overwriting Subscriber Digital Status
                if(mppHardCancelSuccess){
                    try{
                        AccountTriggerHandler.getInstance().bRunAPI = false;
                        update sfdcAccount;
                        AccountTriggerHandler.getInstance().bRunAPI = true;
                        dmlSuccessReport += Label.Subscription_Successfully_Removed_MPP_With_Account_Update + '<br/>';
                    }
                    catch(Exception e){
                        AccountTriggerHandler.getInstance().bRunAPI = true;
                        dmlErrorReport += Label.Subscription_Successfully_Removed_MPP_Without_Account_Update + ' ' + e.getMessage() + ' ' + Label.Manual_Update_Required + '<br/>';
                    }
                }

                displayPopUp = true;
                isSuccessfullCancellation = true;
                popUpText = '<br/><b><font style="font-size:110%;">Subscription cancellation completed ' + (((mppRefundSuccess || (mppHardCancelSuccess && String.isBlank(mppDeferredRevenue))) && String.isBlank(dmlErrorReport)) ? 'without errors' : 'with errors') + '</font></b><br/><br/>';
                popUpText += 'MPP Report:<br/><font style="color:#244AC7;">' + mppSuccessReport + '</font><font style="color:#ED0018;">' + mppErrorReport + '</font><br/>';
                popUpText += 'Salesforce Report:<br/><font style="color:#244AC7;">' + dmlSuccessReport + '</font><font style="color:#ED0018;">' + dmlErrorReport + '</font><br/>';
            }
            return;
        }

        //standard flow for cancellation
        if((cancellationDate != null) && eligibleForCancellation) {
            try{
                Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(zApi, zAccountId, zSubscriptionId, subscriptionNumber, cancellationDate, 
                                                subscriptionObj.Cancellation_Reason__c, subscriptionObj.Sub_Cancellation_Reason__c, false, processInvoice, refundPossible);
                displayPopUp = true;
                isSuccessfullCancellation = true;
                popUpText = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, processInvoice, isSubscriptionMonthly, (cancellationDate > subscriptionServiceEndDate));
            } catch(Exception e){
                 popUpText = Label.Zuora_Subscription_Canceller_Cancellation_Error + ZuoraSubscriptionCanceller.errorMessage + e.getMessage() 
                           + '<br/><br/>' + Label.Zuora_Subscription_Canceller_Contact_Zuora_Admin;
            }
        }
    }

    public void changePromoBool() {
        if(selectedItem == SELECT_OPTION_3) {
            promoBool = false;
            previewedCancellationAmount = 0;
        } else {
            previewCancellation();
            promoBool = true; 
        } 
        
        changeSelectBool();
    }

    public void changeSelectBool() {        
        if(selectedItem == 'NotSelected') {
            selectBool = true;
        } else {
            selectBool = false; 
        } 
    }
    
    public PageReference RefreshControls(){
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        1/8/2015
    Function    check that required fields for cancellations are entered
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Boolean validForCancellation(Date cancellationDate){
        
        //make sure the cancellation reason is entered
        if(String.isempty(subscriptionObj.Cancellation_Reason__c)){
            appendErrorMessage(Label.Cancellation_Reason_Required_Error_Message);
            return false;
        }
        
        //make sure the sub cancellation reason is entered if required
        if(String.isempty(subscriptionObj.Sub_Cancellation_Reason__c) && getIsSubCancellationRequired()){
            appendErrorMessage(Label.Sub_Cancellation_Reason_Required_Error_Message);
            return false;
        }
        
        return validateCancellationDate(cancellationDate);
    }

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        4/8/2015
    Function    check that cancellation date values
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.0         22/06/2015  //removed commented code and modified if condition so it allows to specify today's date,
                                                  replaceds tring error messages with labels  
    ****************************************************************************************/
    private Boolean validateCancellationDate(Date cancellationDate){
        
        //Validation for the cancellation date will happen in case of choosing the third option which is "Cancel on specific date"
        //Need to make sure that renews subscriptions are allowed to be cancelled for last term
        Date cancelFromDate = (zSubscription.Zuora__NextRenewalDate__c != null) ? zSubscription.Zuora__NextRenewalDate__c.addYears(-1) : subscriptionStartDate; 
        if(selectedItem == SELECT_OPTION_3 && (cancellationDate < cancelFromDate || cancellationDate > zSubscription.Zuora__SubscriptionEndDate__c)) {
            String[] labelParameters = new String[]{ TMGUtil.convertDateToString(cancelFromDate), TMGUtil.convertDateToString(zSubscription.Zuora__SubscriptionEndDate__c)};
            appendErrorMessage(String.format(Label.Zuora_Subscription_Canceller_Cancellation_Date_Out_Of_Range, labelParameters));
            return false;
        }
        return true;
    }
}