/************************************************************************************
Class Name   : VoucherActivityRefundControllerExtension
Author       : Mantas Grigaliunas
Created Date : 16/11/2016
Function     : Controller extension class for visualforce page 'VoucherActivityRefund'. Functionality to manage
               voucher refund and refund approval process 
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Vishant Shah          21/03/2017   changed sendEmail. Sending emails after case creation.
* Vishant Shah          18/04/2017   added duration check.
* Konrad Czykin         19/06/2017   changed sendEmail. Added logic to handle daily email limit and create task
*************************************************************************************/
public class VoucherActivityRefundControllerExtension {

    public Voucher_Adjustment__c voucherActivity { get; set; }
    public Boolean isRefundToProcess { get; set; } //action button render controller
    public Boolean showRefundDetails { get; set; } //Refund Details section render controller
    public Boolean isCheque { get; set; } //Create Cheque button rendered
    public Boolean isMpp { get; set; }
    public Boolean isPartialFailure { get; set; }
    public Case futureActionCase { get; set; }
    public Date paymentDate { get; set; } //first or last payment date
    public List<MPP_Transaction_History__c> mppTransactions { get; set; }
    public Decimal totalRefundedAmount { get; set; }
    public Decimal partialFailureRemainingAmount { get; set; }
    public List<Case> voucherCases { get; set; }

    private Decimal thresholdAmount = Configuration__c.getOrgDefaults().Voucher_Refund_Threshold_Amount__c;
    private Boolean isWaitingForApproval;
    private Map<String, Decimal> refundAmountMap;
    private Map<String, String> successfulRefunds;
    private Id caseOwnerId;

    @TestVisible private List<MPPInterfaceHTTP.RefundOrderResult> mppResults;
    @TestVisible private Boolean isTestMailLimit = false;

    //constants
    public Integer QUARTER = 3;
    public Integer MONTH = 1;
    public Integer DD_DAYS_DELAY = 6;
    public Integer CC_DAYS_DELAY = 1;

    /************************************************************************************
    Method Name  : Constructor
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Class constructor
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
      Vishant Shah      18/04/2017   Added Duration warning message.
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public VoucherActivityRefundControllerExtension(ApexPages.StandardController stdController) {

        //get activity record
        Voucher_Adjustment__c voucher = (Voucher_Adjustment__c)stdController.getRecord();
        voucherActivity = [ SELECT Id, Name, Refund_Status__c, Refund_Amount__c, Refund_Method__c, Subscription__c, 
                            Subscription__r.Subscriber__c, Subscription__r.Subscriber__r.Name, Subscription__r.isContinuous__c, 
                            Adjustment_Type__c, Voucher_Value_Calc__c, Subscription__r.Total_of_All_Payments__c, Warning_Message__c,
                            Subscription__r.Paid_Until__c, Subscription__r.PaymentDate__c, Subscription__r.End_Date__c,
                            Subscription__r.Subscriber__r.Subscriber_Number_Static__c, Subscription__r.MPP_DD_Frequency__c, End_Date__c,
                            Subscription__r.Payment_Type__c, Subscription__r.Start_Date__c, Subscription__r.MPP_CC_Frequency__c,
                            Subscription__r.MPP_DD_Next_Payment_Date__c, Subscription__r.MPP_CC_Next_Payment_Date__c,
                            Subscription__r.Subscriber__r.PersonContactId, Subscription__r.Subscriber__r.PersonEmail, Subscription__r.MPP_DD_First_Payment_Amount__c,
                            Subscription__r.MPP_CC_First_Payment_Amount__c 
                            FROM Voucher_Adjustment__c WHERE Id = :voucher.Id LIMIT 1 ];

        //get related cases
        voucherCases = [ SELECT Id, CaseNumber, Subject, Origin, Reason, Voucher_Activity__c, Subscription__c, AccountId, Future_Action_Date__c 
                         FROM Case WHERE Voucher_Activity__c = :voucher.Id 
                         AND Subject = :Constants.CASE_SUBJECT_DELAYED_REFUND 
                         AND Origin = :Constants.CASE_ORIGIN_LETTER
                         AND Reason = :Constants.CASE_REASON_VOUCHER_ENQUIRY 
                         AND Status != :Constants.CASE_STATUS_CLOSED ];

        mppTransactions = new List<MPP_Transaction_History__c>(getMppSaleTransactions());

        List<Group> ownerGroup = [SELECT Id FROM Group WHERE DeveloperName = 'CustomerRelationsTeam' and Type = 'Queue' limit 1];
        if (!ownerGroup.isEmpty()){
            caseOwnerId = ownerGroup[0].Id;
        } else {
            caseOwnerId = UserInfo.getUserId();
        }

        //check if Voucher Activity meets the criteria for refund
        if(!isValidForRefund()) return;

        //set the flags
        isRefundToProcess = false;
        showRefundDetails = true;
        isPartialFailure = false;

        isCheque = (mppTransactions.size() == 0 ? true : false);
        isMPP = (mppTransactions.size() == 0 ? false : true);

        Boolean isEligibleToApprove = isEligibleToApprove();
        isWaitingForApproval = (voucherActivity.Refund_Status__c != null 
            && voucherActivity.Refund_Status__c.equals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL) 
            ? true : false);

        if(isWaitingForApproval && !isEligibleToApprove){
            addMessage(ApexPages.Severity.INFO, Label.Voucher_Activity_Already_Submited_For_Approval);
        }else if(isWaitingForApproval){
            isRefundToProcess = true;
        } else if(voucherActivity.Refund_Amount__c <= thresholdAmount){
            isRefundToProcess = true;
        } else if(isEligibleToApprove){
            isRefundToProcess = true;   
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Voucher_Activity_Is_More_Then_Threshold));
        }
        
        if (voucherActivity.Adjustment_Type__c == Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN && !isEligibleToApprove){
            if(voucherActivity.Warning_Message__c == Label.Duration_Exceeds_3_Weeks){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,  Label.Duration_Exceeds_3_Weeks));
                isRefundToProcess = false;
            } else if(voucherActivity.Warning_Message__c == Label.Duration_Exceeds_6_Weeks){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,  Label.Duration_Exceeds_6_Weeks));
                isRefundToProcess = false;
            }
        }

        if(mppTransactions.size() == 0 && isRefundToProcess){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Voucher_Activity_No_Credit_Card_Payment_Found));
        }
    }

    /************************************************************************************
    Method Name  : submitForApproval
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to update Voucher Activity record with Waiting For Approval status
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void submitForApproval(){
        updateVoucherActivity(null, Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL, 
            Date.today(), UserInfo.getUserId());
        addMessage(ApexPages.Severity.CONFIRM, Label.Voucher_Activity_Successful_Approval_Submition);
    }

    /************************************************************************************
    Method Name  : refund
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to process refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void refund(){
        //process payment
        if(!processMPPRefund() && !isPartialFailure){
            isCheque = true;
            isMPP = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Voucher_Activity_Refund_Failure));
            return;
        } else if(isPartialFailure){
            isCheque = true;
            isMPP = false;
            showRefundDetails = true;
        } 

        try{
            //update voucher activity
            String refundMethod = Constants.VOUCHERADJUSTMENT_REFUND_METHOD_CARD;
            String refundStatus = (isPartialFailure ? Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PARTIALLY_PROCESSED 
                                   : Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED);
            
            if(isWaitingForApproval){
                updateVoucherActivityApproveAndRefund(refundMethod, refundStatus);
            } else {
                updateVoucherActivityFullfilled(refundMethod, refundStatus);
            }

        } catch(Exception e){
            addMessage(ApexPages.Severity.WARNING, Label.Voucher_Activity_Record_Update_Failure, new List<String>{e.getMessage()});
        }
    }

    /************************************************************************************
    Method Name  : processMPPRefund
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to process MPP refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Vishant Shah      21/03/2017   // added logic to check for email template name. 
                                     // and used parameterised sendEmail method.
    *************************************************************************************/
    public Boolean processMPPRefund(){
        try{
            Decimal remainingAmount = voucherActivity.Refund_Amount__c;
            List<MPPInterfaceHTTP.RefundOrder> refundOrdersList = new List<MPPInterfaceHTTP.RefundOrder>();

            //define Refund Orders list to be processed by MPP
            for(MPP_Transaction_History__c mppTrans : mppTransactions){
                if(remainingAmount == 0) break; //exit loop
                Decimal refundAmount = 0;
                //check if existing mpp sales has any refunds already done
                if(refundAmountMap != null && refundAmountMap.containsKey(mppTrans.Order_ID__c)){
                    //calculate if there are any funds available for another refund
                    Decimal amountAvailableToRefund = mppTrans.Total_Price__c - refundAmountMap.get(mppTrans.Order_ID__c);
                    if(amountAvailableToRefund >= remainingAmount){
                        refundAmount = remainingAmount;
                        remainingAmount = 0;
                    } else {
                        refundAmount = amountAvailableToRefund;
                        remainingAmount -= amountAvailableToRefund;
                    }
                } else if(remainingAmount <= mppTrans.Total_Price__c){  
                    refundAmount = remainingAmount;
                    remainingAmount = 0;
                } else {
                    refundAmount = mppTrans.Total_Price__c;
                    remainingAmount -= mppTrans.Total_Price__c;
                }

                //refund is valid only if the amount is more than 0
                if(refundAmount > 0){
                    refundOrdersList.add(new MPPInterfaceHTTP.RefundOrder(mppTrans.Order_ID__c, refundAmount, mppTrans.Payment_Type__c));
                }
            }
            //process refunds
            MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
            try{
             mppResults = mpp.processRefundOrder(voucherActivity.Subscription__r.Subscriber__r.Subscriber_Number_Static__c, 
                voucherActivity.Subscription__c, refundOrdersList, true, true);
            } catch(MPPInterfaceHTTP.MPPInterfaceHTTPException mppEx){}

            //process mpp payment results
            successfulRefunds = new Map<String, String>();
            for(MPPInterfaceHTTP.RefundOrderResult result : mppResults){
                if(result.refundAmount != null && result.refundOrderId != null){
                    successfulRefunds.put(result.refundOrderId, result.refundAmount);
                }
            }

            //all payments failed, return false to continue with cheque creation
            if(successfulRefunds.size() == 0){
                return false;
            } else if(successfulRefunds.size() > 0 && successfulRefunds.size() != mppResults.size()){
                //if some transactions failed and some didn't, log a partial failure
                isPartialFailure = true;
                addMessage(ApexPages.Severity.ERROR,  Label.Voucher_Activity_Partially_Processed_Refund + processMppResults());
                return true;
            } else { //all transactions were successful
                addMessage(ApexPages.Severity.CONFIRM, processMppResults());
                //notify customer if email exists
                if(!String.isEmpty(voucherActivity.Subscription__r.Subscriber__r.PersonEmail)){

                    String emailTemplateDevName = Configuration__c.getOrgDefaults().MPP_Refund_Email_Template_Name__c;
                    if(String.isEmpty(emailTemplateDevName)){
                        addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Email_Template_Custom_Setting_Not_Set);
                        return false;
                    }
                    sendEmail(emailTemplateDevName, voucherActivity.Subscription__r.Subscriber__r.PersonContactId, voucherActivity.Id, true);
                }
                return true;
            }

        } catch (Exception e){
            addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Refund_Exception + e.getMessage());
            return false;
        }
    }

    /************************************************************************************
    Method Name  : createCheque
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to create cheque for refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void createCheque(){

        try{
            Cheque_Batch__c chequeBatch;
            Id chequeBatchRecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName());
            //check if there is an open cheque batch
            List<Cheque_Batch__c> chequeBatchLst = [ SELECT Id, Name FROM Cheque_Batch__c 
                WHERE RecordTypeId = :chequeBatchRecordTypeId AND Batch_Closed_Date__c = NULL ];
            if(chequeBatchLst.size() > 0){
                chequeBatch = chequeBatchLst[0]; 
            } else{
                chequeBatch = new Cheque_Batch__c(RecordTypeId = chequeBatchRecordTypeId);
                insert chequeBatch; 
                chequeBatch = [ SELECT Id, Name FROM Cheque_Batch__c WHERE Id = :chequeBatch.Id ];
            }


            //create cheque record
            insert new Cheque__c(
                Cheque_Amount__c = (isPartialFailure ? partialFailureRemainingAmount : voucherActivity.Refund_Amount__c),
                Cheque_Batch__c = chequeBatch.Id,
                Cheque_Refund_Reason__c = Constants.CHEQUE_REFUND_REASON_HOLIDAY_REFUND,
                Type__c = Constants.CHEQUE_TYPE_REFUND,
                Cheque_Banking_Status__c = Constants.CHEQUE_BANKINGSTATUS_ISSUED,
                Name_on_Cheque__c = voucherActivity.Subscription__r.Subscriber__r.Name,
                Subscriber__c = voucherActivity.Subscription__r.Subscriber__c,
                Subscription__c = voucherActivity.Subscription__c,
                Voucher_Activity__c = voucherActivity.Id,
                RecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque__c.sObjectType, 
                    Constants.VOUCHER_REFUND_CHEQUE_RECORD_TYPE_NAME, Cheque__c.class.getName())
            );

            //update voucher activity
            String refundMethod = Constants.VOUCHERADJUSTMENT_REFUND_METHOD_SYSTEM_CHEQUE;
            String refundStatus = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING;
            if(isWaitingForApproval){
                updateVoucherActivityApproveAndRefund(refundMethod, refundStatus);
            } else {
                updateVoucherActivityFullfilled(refundMethod, refundStatus);
            }

            addMessage(ApexPages.Severity.CONFIRM, Label.Voucher_Activity_Successful_Cheque_Creation, new List<String>{chequeBatch.Name});
        } catch(Exception e){
            addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Cheque_Creation_Failure,
                new List<String>{e.getMessage()});
        }
    }

    /************************************************************************************
    Method Name  : getMppSaleTransaction
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to return historical MPP Sale transaction if exists
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private List<MPP_Transaction_History__c> getMppSaleTransactions(){

        refundAmountMap = new Map<String, Decimal>();//map to hold amount of refund for each sale payment
        List<MPP_Transaction_History__c> saleMppTransactions = new List<MPP_Transaction_History__c>();
        
        //retrieve all Sale and Refund successful transactions
        List<MPP_Transaction_History__c> allMppTransactions = [ SELECT Id, Order_Id__c, Subscriber__c, Payment_Type__c, Total_Price__c,
            Subscription__r.Subscriber__r.Subscriber_Number_Static__c, Sale_Order_Id__c, Sale_Type__c, Payment_Date__c FROM MPP_Transaction_History__c 
            WHERE Subscription__c = :voucherActivity.Subscription__c 
            AND (Payment_Status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_SUCCESS 
            OR Payment_Status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND) ORDER BY Payment_Date__c DESC ];

        for(MPP_Transaction_History__c mpp : allMppTransactions){
            //add all sale payment transactions in a list
            if(mpp.Sale_Type__c == Constants.MPPTRANSACTION_PAYMENT_TYPE_SALE){
                saleMppTransactions.add(mpp);
            //add all refund transactions payment amounts in map with original Sale Order Id
            } else if(mpp.Sale_Type__c != null && mpp.Sale_Type__c == Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND
                && mpp.Sale_Order_Id__c != null){
                Decimal refundAmount = 0;
                if(refundAmountMap.size() > 0 && refundAmountMap.get(mpp.Sale_Order_Id__c) != null){
                    refundAmount = refundAmountMap.get(mpp.Sale_Order_Id__c);
                }
                if(refundAmount == 0){
                    refundAmount = mpp.Total_Price__c;
                } else {
                    refundAmount += mpp.Total_Price__c;
                }
                refundAmountMap.put(mpp.Sale_Order_ID__c, refundAmount);
            }
        }
        return saleMppTransactions;
    }

    /************************************************************************************
    Method Name  : cancel
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method called on 'Cancel' button click to redirect to voucher activity standard page 
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public PageReference cancel(){
        return new PageReference('/'+voucherActivity.Id);
    }

    /************************************************************************************
    Method Name  : createCase
    Developer    : Mantas Grigaliunas
    Created Date : 23/01/2017
    Function     : Method to create insert case on button click
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public PageReference createCase(){

        Database.SaveResult result = Database.insert(futureActionCase, false);

        sendEmail('Delayed_Refund_Email_VF', voucherActivity.Subscription__r.Subscriber__r.PersonContactId, futureActionCase.Id, true);

        if(!result.isSuccess()){
            for(Database.Error error : result.getErrors()){
                addMessage(ApexPages.Severity.FATAL, error.getMessage());
            }
            return null;
        } else {
            return new PageReference('/'+result.getId());
        }
    }

    /************************************************************************************
    Method Name  : updateVoucherActivityFullfilled
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to update Voucher Activity with status 'Processed'
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void updateVoucherActivityFullfilled(String refundMethod, String refundStatus){
        updateVoucherActivity(refundMethod, refundStatus, Date.today(), UserInfo.getUserId());
    }

    /************************************************************************************
    Method Name  : updateVoucherActivityApproved
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to update Voucher Activity with status 'Processed' and approver details 
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void updateVoucherActivityApproveAndRefund(String refundMethod, String refundStatus){
        update new Voucher_Adjustment__c(
            Id = voucherActivity.Id,
            Refund_Method__c = refundMethod,
            Refund_Status__c = refundStatus,
            Approval_Date__c = Date.today(),
            Approved_By__c = UserInfo.getUserId()
        );
    }

    /************************************************************************************
    Method Name  : updateVoucherActivity
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Generic method to update Voucher Activity with refund details
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void updateVoucherActivity(String refundMethod, String refundStatus, Date fulfilledDate, Id fullfilledBy){
        update new Voucher_Adjustment__c(
            Id = voucherActivity.Id,
            Refund_Method__c = refundMethod,
            Refund_Status__c = refundStatus,
            Fulfilled_Date__c = fulfilledDate,
            Fulfilled_By__c = fullfilledBy
        );
    }

    /************************************************************************************
    Method Name  : isEligibleToApprove
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to check if user is eligible to approve a refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private Boolean isEligibleToApprove(){
        List<Group> approvalGroup = new List<Group>([ SELECT Id FROM Group 
            WHERE DeveloperName = :Constants.VOUCHERADJUSTMENT_APPROVERS_GROUP_DEV_NAME LIMIT 1 ]);

        if(approvalGroup.size() > 0){
            List<GroupMember> groupMemeber = new List<GroupMember>([ SELECT Id FROM GroupMember 
                WHERE UserOrGroupId = :UserInfo.getUserId() AND GroupId = :approvalGroup[0].Id LIMIT 1 ]);
            if(groupMemeber.size() == 0){
                return false;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                String.format(Label.Voucher_Activity_Approval_Group_Not_Found, 
                    new List<String>{Constants.VOUCHERADJUSTMENT_APPROVERS_GROUP_NAME})));
            return false;
        }
        return true;      
    }

    /************************************************************************************
    Method Name  : checkIfValidForRefund
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to check if Voucher Activity record is valid for a refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private Boolean isValidForRefund(){
        //only specific VA Types are allowed for refund
        if(!voucherActivity.Adjustment_Type__c.equals(Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN)){
            addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Invalid_Type_For_Refund, 
                new List<String>{Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN});
            return false;
        }
        //Threshold value in Custom Settings must be set
        if(thresholdAmount == null){
           addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Threshold_Value_Not_Set);
           return false;
        }
        //Refund is not allowed for already refunded VAs
        if(voucherActivity.Refund_Status__c != null && (voucherActivity.Refund_Status__c.equals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED)
            || voucherActivity.Refund_Status__c.equals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PARTIALLY_PROCESSED))){
            addMessage(ApexPages.Severity.INFO, Label.Voucher_Activity_Refund_Already_Processed);
            return false;
        }
        //Prevent refund for Cheque payments that already were submited for refund but not processed yet
        if(voucherActivity.Refund_Status__c != null && voucherActivity.Refund_Status__c.equals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING)
            && voucherActivity.Refund_Method__c != null && voucherActivity.Refund_Method__c.equals(Constants.VOUCHERADJUSTMENT_REFUND_METHOD_SYSTEM_CHEQUE)){
            addMessage(ApexPages.Severity.INFO, Label.Voucher_Activity_Pending_Cheque);
            return false;
        }
        //Prevent refund if no sufficient funds available on Continuos Subscription
        if( (voucherActivity.End_Date__c > voucherActivity.Subscription__r.Paid_Until__c || voucherActivity.Subscription__r.Total_of_All_Payments__c < voucherActivity.Refund_Amount__c)
            && voucherActivity.Subscription__r.isContinuous__c){
            if(voucherCases.size() == 0){
                //create new case
                futureActionCase = createNewFutureActionCase();
                addMessage(ApexPages.Severity.WARNING, Label.Voucher_Activity_Refund_Not_Enough_Funds);
            } else {
                //use existing case
                futureActionCase = voucherCases[0];
                addMessage(ApexPages.Severity.WARNING, Label.Voucher_Activity_Refund_Case_Already_Created);
            }

            if (voucherActivity.Subscription__r.Subscriber__r.PersonEmail == null){
                addMessage(ApexPages.Severity.WARNING, Label.Delayed_Refund_No_Subscriber_Email);
            }

            return false;
        }

        //Prevent refund if VA refund amount is more then Non-Continuos Subscription Amount
        if(voucherActivity.Subscription__r.Total_of_All_Payments__c < voucherActivity.Refund_Amount__c
            && !voucherActivity.Subscription__r.isContinuous__c){
            addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Refund_Is_Higher_Than_Payment);
            return false;
        }

        return true;
    }


    /************************************************************************************
    Method Name  : addMessage
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to display message on screen with parameters
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void addMessage(ApexPages.Severity severity, String message, List<String> parameters){
        showRefundDetails = false;
        ApexPages.addMessage(new ApexPages.Message(severity, String.format(message, parameters)));
    }

    /************************************************************************************
    Method Name  : addMessage
    Developer    : Mantas Grigaliunas
    Created Date : 16/11/2016
    Function     : Method to display message on screen
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private void addMessage(ApexPages.Severity severity, String message){
        addMessage(severity, message, new List<String>());
    }

    /************************************************************************************
    Method Name  : calculateFutureActionDate
    Developer    : Mantas Grigaliunas
    Created Date : 23/01/2017
    Function     : Method to calculate the date when nex subscription payment is happening so it can be used in the related case record
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private date calculateFutureActionDate(){
        Subscription__c sub                 = voucherActivity.Subscription__r;
        Date paidUntilDate                  = sub.Paid_Until__c;
        Date subStartDate                   = sub.Start_Date__c;
        Date voucherEndDate                 = voucherActivity.End_Date__c;
        Date futureActionDate               = sub.End_Date__c;
        Integer maxIterations               = 12;
        Integer monthsToAdd                 = 1;
        Integer daysToAdd                   = 0;
        Decimal mppFirstPaymentAmount       = 0;
        Decimal voucherRefundAmount         = voucherActivity.Refund_Amount__c;
        Map<Date, Date> paymentPaidUntilMap = new Map<Date, Date>();

        Date mppNextPaymentDate, iterativeDate, iterativePaidUntilDate, mppLatestPaymentDate;

        String frequency;
        
        if (sub.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            mppNextPaymentDate = sub.MPP_DD_Next_Payment_Date__c;
            frequency = sub.MPP_DD_Frequency__c;
            daysToAdd = DD_DAYS_DELAY;
            mppFirstPaymentAmount = sub.MPP_DD_First_Payment_Amount__c;
        } else {
            mppNextPaymentDate = sub.MPP_CC_Next_Payment_Date__c;
            frequency = sub.MPP_CC_Frequency__c;
            daysToAdd = CC_DAYS_DELAY;
            mppFirstPaymentAmount = sub.MPP_CC_First_Payment_Amount__c;
        }

        if(mppTransactions.size() > 0){
            mppLatestPaymentDate = TMGDateExtension.toDate(mppTransactions[0].Payment_Date__c);
        }

        if (frequency == Constants.DD_COL_FREQ_QUARTERLY){
            maxIterations = 4;
            monthsToAdd   = 3;
        }

        for (Integer i = 0; i < maxIterations; i++){
            if (mppNextPaymentDate != null){
                if (i == 0){
                    iterativeDate = mppNextPaymentDate;
                    iterativePaidUntilDate = subStartDate.addMonths(monthsToAdd);
                } else {
                    iterativeDate = iterativeDate.addMonths(monthsToAdd);
                    iterativePaidUntilDate = iterativePaidUntilDate.addMonths(monthsToAdd);
                }
                
                if (iterativePaidUntilDate.month() ==  paidUntilDate.month() && iterativePaidUntilDate.year() ==  paidUntilDate.year() ){
                    iterativePaidUntilDate = paidUntilDate;
                }

                paymentPaidUntilMap.put(iterativeDate, iterativePaidUntilDate);
            }
        }
        System.debug(JSON.serializePretty(paymentPaidUntilMap) );
        
        Date lastPayDate;
        Decimal appxPaymentAmount = mppFirstPaymentAmount;
        for (Date payDate : paymentPaidUntilMap.keySet()){

            Date appxPaidUntilDate = paymentPaidUntilMap.get(payDate);
        
            if (appxPaidUntilDate >= voucherEndDate && paydate > Date.today() && voucherRefundAmount <= appxPaymentAmount){
                futureActionDate = payDate;
                break;
            }
            
            appxPaymentAmount += mppFirstPaymentAmount;
            lastPayDate = payDate;
        }
        
        if (voucherEndDate >= sub.End_Date__c && futureActionDate == sub.End_Date__c && lastPayDate > Date.today()){
            futureActionDate = lastPayDate;
        }
        
        futureActionDate = futureActionDate.addDays(daysToAdd);
                
        return futureActionDate;
    }

    /************************************************************************************
    Method Name  : createNewFutureActionCase
    Developer    : Mantas Grigaliunas
    Created Date : 23/01/2017
    Function     : Method to define new Case record with related information
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private Case createNewFutureActionCase(){
        Date nextPaymentDate = calculateFutureActionDate();
        return new Case(
            Subject = Constants.CASE_SUBJECT_DELAYED_REFUND,
            Origin = Constants.CASE_ORIGIN_LETTER,
            Reason = Constants.CASE_REASON_VOUCHER_ENQUIRY,
            Future_Action_Date__c = nextPaymentDate,
            RecordTypeId = RecordTypeUtility.getRecordTypeId(
            Case.SObjectType, Constants.CASE_RECORDTYPE_GENERALENQUIRY, Case.class.getName()),
            Voucher_Activity__c = voucherActivity.Id,
            Print_Subscription__c = voucherActivity.Subscription__c,
            AccountId = voucherActivity.Subscription__r.Subscriber__c,
            OwnerId = caseOwnerId
        );
    }

    /************************************************************************************
    Method Name  : createNewFutureActionCase
    Developer    : Mantas Grigaliunas
    Created Date : 23/01/2017
    Function     : Method to define new Case record with related information
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    private String processMppResults(){

        String message = 'See processed refund details below.</br></br>';
        totalRefundedAmount = 0;
        for(String orderId : successfulRefunds.keySet()){
            Decimal refundAmount = Decimal.valueOf(successfulRefunds.get(orderId)).setScale(2);
            message += '<b>Refund Order Id:</b> ' + orderId + '<br/><b>Amount:</b> ' + refundAmount + '<br/></br>';
            totalRefundedAmount += refundAmount;
        }
        if(totalRefundedAmount > 0 && successfulRefunds.size() > 1){
            message += 'Total amount refunded:' + String.valueOf(totalRefundedAmount) + '<br/><br/>';
        } 
        if(isPartialFailure){
            partialFailureRemainingAmount = voucherActivity.Refund_Amount__c - totalRefundedAmount;
            if(partialFailureRemainingAmount > 0){
                message += 'The remaining amount of £' + partialFailureRemainingAmount + ' failed to process.<br/>'
                        +  'This amount can be refunded by clicking \'Create Cheque\' button to refund via cheque.';
            }
        }
        return message;
    }

    /************************************************************************************
    Method Name  : sendEmail
    Developer    : Mantas Grigaliunas
    Created Date : 23/01/2017
    Function     : Notify subscriber about successful refund
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Vishant Shah      21/03/2017   changed method to be parameterised.. and calling utility method to generate email
    *************************************************************************************/
    public void sendEmail(String emailTemplateDevName, Id targetId, Id whatId, Boolean saveAsActivity){

        Boolean sendMail = true;
        Boolean createTask = true;

        if(Test.isRunningTest() && isTestMailLimit) sendMail = false;

        try{

            if(String.isEmpty(emailTemplateDevName)){
                addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Email_Template_Custom_Setting_Not_Set);
                return;
            }

            List<EmailTemplate> refundTemplate = [ SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = :emailTemplateDevName LIMIT 1 ];
            if(refundTemplate.size() == 0){
                addMessage(ApexPages.Severity.FATAL, String.format(Label.Voucher_Activity_Email_Template_Not_Exist, new List<String>{emailTemplateDevName}));
                return;
            }

            //set org-wide address
            Id orgWideEmailAddressId;

            for(OrgWideEmailAddress owa : [ SELECT Id, DisplayName FROM OrgWideEmailAddress]) {
                if(owa.DisplayName.equalsIgnoreCase(Constants.ORG_WIDE_NAME_CUSTOMER_SERVICE)) {
                    orgWideEmailAddressId = owa.id;
                    break;
                }
            }

            TMGUtil.EmailUtil tmgUtil = new TMGUtil.EmailUtil(null);
            tmgUtil.buildEmailFromTemplate(refundTemplate[0].Id, targetId, whatId, saveAsActivity, orgWideEmailAddressId);
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { tmgUtil.getEmailMessage() };
            
            try{
                if(!Test.isRunningTest()) Messaging.reserveSingleEmailCapacity(1);
            } catch(Exception e){
                sendMail = false;
                addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Refund_Email_Failed + ' ' + e.getMessage());
            }

            if(sendMail){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
                    if(results[0].success){
                        addMessage(ApexPages.Severity.CONFIRM, Label.Voucher_Activity_Refund_Email_Sent_Successfully);
                    } else {
                        addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Refund_Email_Failed + ' ' + results.get(0).getErrors()[0].getMessage());
                    
                }
            } else {
                try{
                    insert createTask(targetId, whatId);
                } catch(DmlException de){
                    createTask = false;
                    addMessage(ApexPages.Severity.FATAL, de.getMessage());
                }
                if(createTask) addMessage(ApexPages.Severity.CONFIRM, Label.Task_Creation);  
            }

        } catch(Exception e){
            addMessage(ApexPages.Severity.FATAL, Label.Voucher_Activity_Refund_Email_Failed + ' ' + e.getMessage());
        }
    }

    /************************************************************************************
    Method Name  : createTask
    Developer    : Konrad Czykin
    Created Date : 20/06/2017
    Function     : create task when email cannot be sent
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public Task createTask(Id taId, Id whId){
        return new Task (Subject = Constants.VOUCHER_ADJUSTMENT_TASK_SUBJECT,
                        Status = Constants.VOUCHER_ADJUSTMENT_TASK_STATUS,
                        Priority = Constants.VOUCHER_ADJUSTMENT_TASK_PRIORITY,
                        IsReminderSet = true,
                        ReminderDateTime = System.now()+1,
                        WhoId = taId,
                        WhatId = whId
                                        );
    }
}