/**
* Author:       Michal Kwika (Accenture)
* Date:         28/09/2015
* Description:  TriggerHandler on Zuora Refund Object
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      08/10/2015
* Michal Kwika      14/10/2015
* Michal Kwika      05/02/2016 - adding DDICA fickle scenario
* Wiktor Czykin     27/03/2016 - removed DDICA and queue setting and methods that got obsolete with it
**/
public class ZRefundTriggerHandler {
    // Boolean to control recursion
    public Boolean isExecuting = false;
    public Boolean bRunAPI = true;
    //triggerhandler instance
    private static ZRefundTriggerHandler instance;
    //static rt id for  failed payment case
    public Id failedPaymentRecTypeId = Constants.getFailedPaymentRT();

    public static ZRefundTriggerHandler getInstance() {
        if (instance == null) instance = new ZRefundTriggerHandler();
        return instance;
    }

    public void OnAfterInsert(List <Zuora__Refund__c> newRefunds) {
        if (!this.isExecuting) {
            this.isExecuting = true;

            this.createCasesRefundsFailed(newRefunds);

            this.isExecuting = false;
        }
    }

    public void OnBeforeInsert(List <Zuora__Refund__c> newRefunds) {}

    public void OnBeforeUpdate(List <Zuora__Refund__c> oldRefunds, List <Zuora__Refund__c> updatedRefunds,  Map<ID, Zuora__Refund__c> NewCaseMap) {}

    public void OnAfterUpdate(List <Zuora__Refund__c> oldRefunds, List <Zuora__Refund__c> updatedRefunds, Map<ID, Zuora__Refund__c> OldCaseMap, Map<ID, Zuora__Refund__c> NewCaseMap) {
        if (!this.isExecuting) {
            this.isExecuting = true;
            System.debug('######## ZRefundTriggerHandler OnAfterUpdate Start ###########');

            //invoke update on all cases related if Payment is changed
            this.updatePaymentOnRelatedCase(OldCaseMap, NewCaseMap);

            this.isExecuting = false;
        }
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 28/09/2015
    Version - 1.2
    Function -  When a Zuora__Refund__c RT is Failed we need to create another case for that
                This apply only for Direct Debit Payment issues
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         09/02/2016 - improvements to method (new DDICA)
    Wiktor Czykin   1.2         27/03/2016 - made sure case is not added to list if it is null
    ****************************************************************************************/
    private void createCasesRefundsFailed(List <Zuora__Refund__c> lRefunds) {
        List <Case> lCasesToCreate = new List <Case>();
        Set <Zuora__Refund__c> sWorkRefunds = new Set <Zuora__Refund__c>();
        Map <Id, Id> mBillingAccIdOnSubId = new Map <Id, Id>();

        for (Zuora__Refund__c ref : lRefunds) {
            if (ref.Zuora__Type__c ==  Constants.ZUORA_REFUND_TYPE_EXTERNAL && ref.Zuora__RefundMethodType__c == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE
                    && (ref.Zuora__ReasonCodeName__c == Constants.ZUORA_REFUND_REASONCODE_PAYMENTREJECTION || ref.Zuora__ReasonCodeName__c == Constants.ZUORA_REFUND_REASONCODE_PAYMENTREVERSAL)) {

                sWorkRefunds.add(ref);
            }
        }
        //assign correct subscription to the billing account ID
        if (sWorkRefunds != null) {
            mBillingAccIdOnSubId = getSubscriptionMap(sWorkRefunds);
        }

        for (Zuora__Refund__c zref : sWorkRefunds) {
            //fill case and add to list
            Case c = this.fillAndCreateCaseBasedOnRefund(zref, mBillingAccIdOnSubId);
            if(c != null){
                lCasesToCreate.add(c);
            }
        }

        if (lCasesToCreate != null && lCasesToCreate.size() > 0) {
            insert lCasesToCreate;
        }
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 28/09/2015
    Version - 1.0
    Function -  get Reason source based on String
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         05/02/2016 - adding DDICA and ADDACS reasonCodes checking
    ****************************************************************************************/
    private String getReasonSource(String reasonCode) {
        String reasonSource = '';

        if (reasonCode != null && String.isNotEmpty(reasonCode)) {
            if (reasonCode.contains(Constants.CASE_REASONCODE_ARUDD)) {
                reasonSource = Constants.CASE_REASONCODE_ARUDD;
            } else if (reasonCode.contains(Constants.CASE_REASONCODE_AUDDIS)) {
                reasonSource = Constants.CASE_REASONCODE_AUDDIS;
            } else if (reasonCode.contains(Constants.CASE_REASONCODE_ADDACS)) {
                reasonSource = Constants.CASE_REASONCODE_ADDACS;
            } else if (reasonCode.contains(Constants.CASE_REASONCODE_DDICA)) {
                reasonSource = Constants.CASE_REASONCODE_DDICA;
            }
        }
        return reasonSource;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 28/09/2015
    Version - 1.0
    Function -  get Reason number based on String
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         09/02/2016 - enhancement for DDICA code
    ****************************************************************************************/
    private String getReasonNumber(String reasonCode) {
        List <String> reasonNum = new List <String>();
        System.debug('### Full reason code is: ' + reasonCode);
        reasonCode = reasonCode.deleteWhitespace();
        if (reasonCode.contains('-')) {
            reasonNum = reasonCode.split('-');
        } else if (reasonCode.isNumeric()) {
            return reasonCode;
        }

        return reasonNum[1];
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 28/09/2015
    Version - 1.0
    Function -  get latest subscription on Billing Account which was realted to refund
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         14/10/2015
    ****************************************************************************************/
    private Map <Id, Id>  getSubscriptionMap(Set <Zuora__Refund__c> sRefunds) {
        Map <Id, Id> mBillingAccIdOnSubId = new Map <Id, Id>();
        Set <Id> sBillIds = new Set <Id>();
        List <Zuora__Subscription__c> lAllSubs = new List <Zuora__Subscription__c>();
        Map < Id, List<Zuora__Subscription__c> > mSubs;

        for (Zuora__Refund__c zref : sRefunds) {
            sBillIds.add(zref.Zuora__BillingAccount__c);
        }

        lAllSubs = [SELECT Id, Name, Zuora__CustomerAccount__c, Zuora__Status__c FROM Zuora__Subscription__c
                    WHERE Zuora__CustomerAccount__c IN :sBillIds
                    ORDER BY LastModifiedDate DESC];

        System.debug('### lAllSubs ' + lAllSubs);

        for (Zuora__Subscription__c sub : lAllSubs) {
            if (!mBillingAccIdOnSubId.containsKey(sub.Zuora__CustomerAccount__c)) {
                mBillingAccIdOnSubId.put(sub.Zuora__CustomerAccount__c, sub.Id);
            }
        }

        System.debug('### mapIdonIdSubBA ' + mBillingAccIdOnSubId);
        return mBillingAccIdOnSubId;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 08/10/2015
    Version - 1.0
    Function -  When a Zuora__Refund__c Payment field is changed - update all cases related
                to this Refund record
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         09/02/2016 -added condition for payment reversal
    ****************************************************************************************/
    private void updatePaymentOnRelatedCase(Map <Id, Zuora__Refund__c> mOldRefunds, Map<Id, Zuora__Refund__c> mNewRefunds) {
        List <Case> lCasesToUpdate = new List <Case>();
        Map <Id, Zuora__Refund__c> mFilteredRefunds = new Map <Id, Zuora__Refund__c>();

        //filter Refunds - if this refund is
        for (Zuora__Refund__c ref : mNewRefunds.values()) {
            if (ref.Zuora__Type__c ==  Constants.ZUORA_REFUND_TYPE_EXTERNAL && ref.Zuora__RefundMethodType__c == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE
                    && (ref.Zuora__ReasonCodeName__c == Constants.ZUORA_REFUND_REASONCODE_PAYMENTREJECTION || ref.Zuora__ReasonCodeName__c.equalsIgnoreCase(Constants.ZUORA_REFUND_REASONCODE_PAYMENTREVERSAL))) {

                //check which of filtered Refunds has new Payment
                if (ref.Zuora__Payment__c != mOldRefunds.get(ref.Id).Zuora__Payment__c ) {
                    mFilteredRefunds.put(ref.Id, ref);
                }
            }
        }
        System.debug('### mFilteredRefunds ' + mFilteredRefunds);

        //get all cases related to Refunds
        if (mFilteredRefunds != null) {
            Set <Id> sRefundsIds = mFilteredRefunds.keySet();

            lCasesToUpdate = [SELECT Id, Refund__c, Payment__c FROM Case WHERE Refund__c IN :sRefundsIds];

            for (Case c : lCasesToUpdate) {
                if (mFilteredRefunds.containsKey(c.Refund__c)) {
                    c.Payment__c = mFilteredRefunds.get(c.Refund__c).Zuora__Payment__c;
                }
            }
        }

        System.debug('### ZRefundTriggerHandler: updatePaymentOnRelatedCase: lCasesToUpdate: ' + lCasesToUpdate);

        if (lCasesToUpdate != null) {
            update lCasesToUpdate;
        }
    }


    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 09/02/2016
    Version - 1.0
    Function -  Helper method to create case with proper values based on reason of refund
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/03/2016  //changed DDICA/ARUDD logic and removed fixed queue assignments
    ****************************************************************************************/
    public Case fillAndCreateCaseBasedOnRefund(Zuora__Refund__c zref, Map <Id, Id> mBillingAccIdOnSubId) {
        if (zref != null) {
            String reasonNum = '';
            String reasonSource = '';
            //get the reason code on refund
            if (String.isNotEmpty(zref.Zuora__GatewayResponseCode__c)) {
                reasonNum = getReasonNumber(zref.Zuora__GatewayResponseCode__c);
                reasonSource = getReasonSource(zref.Zuora__GatewayResponseCode__c);
            }

            if(reasonSource == Constants.CASE_REASONCODE_ARUDD || reasonSource == Constants.CASE_REASONCODE_DDICA || zref.Zuora__ReasonCodeName__c.equalsIgnoreCase(Constants.ZUORA_REFUND_REASONCODE_PAYMENTREVERSAL)){
                return null;
            }

            //create new Case and fill with correct requirements (universal values)
            Case failedCase = new Case();
            failedCase.RecordTypeId = failedPaymentRecTypeId;
            failedCase.Origin = Constants.CASE_ORIGIN_ZUORA_DD;
            failedCase.Reason = Constants.CASE_REASON_PAYMENT_ISSUE;
            failedCase.AccountId = zref.Zuora__Account__c;
            failedCase.ContactId = zref.Person_Contact_Reference__c;
            failedCase.Status = Constants.CASE_STATUS_NEW;
            failedCase.Type = Constants.CASE_TYPE_PROBLEM;
            failedCase.Type_Of_Issue__c = Constants.CASE_TYPEOFISSUE_FAILED_DDREC_PAYMENT;
            failedCase.Bank_Reference_Number__c = zref.Zuora__PaymentMethod__c;
            failedCase.Subscription__c = mBillingAccIdOnSubId.get(zref.Zuora__BillingAccount__c);
            failedCase.Payment_Gateway_Name__c = Constants.CASE_GATEWAYNAME_GOCARDLESS;
            failedCase.Payment__c = zref.Zuora__Payment__c;
            failedCase.Description = zref.Zuora__GatewayResponse__c;
            failedCase.Refund__c = zref.Id;
            failedCase.BACS_Report_Date__c = Date.today();
            failedCase.Subject = Constants.CASE_SUBJECT_FAILED_DDREC + ' ' + reasonNum;
            failedCase.Payment_Status__c = Constants.CASE_PAYMENTSTATUS_FAILED_DDPAYMENT;
            failedCase.Gateway_Reason_code_source__c = reasonSource;
            failedCase.Gateway_Reason_code__c = reasonNum;

            return failedCase;
        }
        return null;
    }
}