/************************************************************************************
Class Name   : OutboundCallingSalesControllerTest
Author       : Mantas Grigaliunas
Created Date : 18/11/2016
Function     : VoucherActivityRefundCtrlExt class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date        Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Konrad Czykin      19/06/2017     added sendMailLimitTest()
*************************************************************************************/
@isTest
private class VoucherActivityRefundCtrlExtTest {

    static Integer RECORDS_SIZE = 1;

    /************************************************************************************
    Method Name  : testSetup
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @testSetup static void testSetup(){

        TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);
        tdu.createVoucherAdjustments();
        update new Voucher_Adjustment__c(Id = tdu.lstVoucherAdjustment[0].Id, 
            Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN,
            Start_Date__c = tdu.lstSubscriptions[0].Start_Date__c,
            End_Date__c = tdu.lstSubscriptions[0].Start_Date__c.addDays(1));
        insert DefaultSettings.APPLICATION_CONFIGURATIONS;

        /*** MPP Test Data Setup ***/

        List<MPP_Transaction_History__c> lstMppTransactions = new List<MPP_Transaction_History__c>();
        //MPP Sale Payments
        List<Decimal> lstAmount = new List<Decimal>{220, 10, 100};
        for(Decimal amount : lstAmount){
            MPP_Transaction_History__c saleMpp = TestDataUtility.newMPPTransactionHistory(0, tdu.lstIndividualSubscribers[0].Id, 
                tdu.lstSubscriptions[0].Id, Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE); 
            saleMpp.Payment_status__c = Constants.MPPTRANSACTION_PAYMENTSTATUS_SUCCESS;
            saleMpp.Total_Price__c = amount;
            saleMpp.Order_ID__c = String.valueOf(Crypto.getRandomInteger());
            lstMppTransactions.add(saleMpp);
        }

        //MPP Refund Payments
        List<MPP_Transaction_History__c> lstMppRefunds = new List<MPP_Transaction_History__c>();
        for(MPP_Transaction_History__c saleMpp : lstMppTransactions){
             MPP_Transaction_History__c refundMpp = TestDataUtility.newMPPTransactionHistory(0, tdu.lstIndividualSubscribers[0].Id, 
                tdu.lstSubscriptions[0].Id, Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE); 
            refundMpp.Payment_status__c = Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND;
            refundMpp.Total_Price__c    = saleMpp.Total_Price__c / 2;
            refundMpp.Sale_Order_Id__c  = saleMpp.Order_ID__c;
            refundMpp.Sale_Type__c = Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND;
            lstMppRefunds.add(refundMpp);
        }

        //additional refund for one of the payments
        MPP_Transaction_History__c refundMpp = TestDataUtility.newMPPTransactionHistory(0, tdu.lstIndividualSubscribers[0].Id, 
                tdu.lstSubscriptions[0].Id, Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE); 
            refundMpp.Payment_status__c = Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND;
            refundMpp.Total_Price__c    =  1;
            refundMpp.Sale_Order_Id__c  = lstMppTransactions[0].Order_ID__c;
            refundMpp.Sale_Type__c = Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND;
        lstMppRefunds.add(refundMpp);

        lstMppTransactions.addAll(lstMppRefunds);
        insert lstMppTransactions;

        /*** MPP Test Data Setup END ***/

        //Future Action Case
        insert new Case(
            Subject = Constants.CASE_SUBJECT_DELAYED_REFUND,
            Origin = Constants.CASE_ORIGIN_LETTER,
            Reason = Constants.CASE_REASON_VOUCHER_ENQUIRY,
            Future_Action_Date__c = Date.today(),
            RecordTypeId = RecordTypeUtility.getRecordTypeId(
                Case.SObjectType, Constants.CASE_RECORDTYPE_GENERALENQUIRY, Case.class.getName()),
            Voucher_Activity__c = tdu.lstVoucherAdjustment[0].Id,
            Print_Subscription__c = tdu.lstSubscriptions[0].Id,
            AccountId = tdu.lstIndividualSubscribers[0].Id
        );


    }
    
    /************************************************************************************
    Method Name  : eligibleToProcessRefundBelowThresholdTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void eligibleToProcessRefundBelowThresholdTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];
        //updated threshold value to be more then refund amount
        TestDataUtility.updateThresholdValue(testVoucher.Refund_Amount__c + 1);

        Test.startTest();
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        Test.stopTest();
        System.assert(vace.isRefundToProcess, 'Expected isRefundToProcess to be set to true');
    }

    /************************************************************************************
    Method Name  : eligibleToProcessRefundAboveThresholdTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void eligibleToProcessRefundAboveThresholdTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];
        //updated threshold value to be more then refund amount
        TestDataUtility.updateThresholdValue(testVoucher.Refund_Amount__c - 1);
        insertCurrentUserToApproversGroup();

        Test.startTest();
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        Test.stopTest();
        System.assert(vace.isRefundToProcess, 'Expected isRefundToProcess to be set to true');
    }

    /************************************************************************************
    Method Name  : notEligibleToProcessRefundAboveThresholdTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void notEligibleToProcessRefundAboveThresholdTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];
        //updated threshold value to be less then refund amount
        TestDataUtility.updateThresholdValue(testVoucher.Refund_Amount__c - 1);

        Test.startTest();
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        Test.stopTest();
        System.assert(!vace.isRefundToProcess, 'Expected isRefundToProcess to be set to false');
        System.assert(vace.showRefundDetails, 'Expected showRefundDetails to be set to true');
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
            Label.Voucher_Activity_Is_More_Then_Threshold), ApexPages.getMessages());

    }

    /************************************************************************************
    Method Name  : eligibleToApproveAndProcessRefundAboveThresholdTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void eligibleToApproveAndProcessRefundAboveThresholdTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];
        //add current user to the Voucher Refund Approvers group
        insertCurrentUserToApproversGroup();

        Test.startTest();
        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
            Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL);
        //updated threshold value to be less then refund amount
        TestDataUtility.updateThresholdValue(testVoucher.Refund_Amount__c - 1);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(vace.isRefundToProcess, 'Expected isRefundToProcess to be set to true');
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : submitForApprovalTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void submitForApprovalTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];

        Test.startTest();
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.submitForApproval();
        Voucher_Adjustment__c updatedVoucher = [ SELECT Id, Refund_Status__c, Refund_Method__c, Fulfilled_Date__c, Fulfilled_By__c 
            FROM Voucher_Adjustment__c WHERE Id = :testVoucher.Id LIMIT 1 ];

        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL, updatedVoucher.Refund_Status__c);
        System.assertEquals(null, updatedVoucher.Refund_Method__c);
        System.assertEquals(Date.today(), updatedVoucher.Fulfilled_Date__c);
        System.assertEquals(UserInfo.getUserId(), updatedVoucher.Fulfilled_By__c);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
            Label.Voucher_Activity_Successful_Approval_Submition), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : ccRefundSuccessfulWithApprovalTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void ccRefundSuccessfulWithApprovalTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c,
            Start_Date__c, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];

        Test.startTest();
        delete [ SELECT Id FROM MPP_Transaction_History__c WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND ];
        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
            Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL);

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.refund();

        List<MPP_Transaction_History__c> refundTransaction = new List<MPP_Transaction_History__c>(
            [ SELECT Id, Total_Price__c, Expected_Amount__c, Order_ID__c, Payment_Type__c
              FROM MPP_Transaction_History__c WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND
              AND  Payment_status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND
              AND Subscription__c = :testVoucher.Subscription__c
              AND Subscriber__c = :testVoucher.Subscription__r.Subscriber__c LIMIT 1 ] );

        Test.stopTest();

        System.assertEquals(1, refundTransaction.size());

        System.assertEquals(testVoucher.Refund_Amount__c, refundTransaction[0].Total_Price__c);
        System.assertEquals(testVoucher.Refund_Amount__c, refundTransaction[0].Expected_Amount__c);
        System.assertEquals(vace.mppResults[0].refundOrderId, refundTransaction[0].Order_ID__c);
        System.assertEquals(Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE, refundTransaction[0].Payment_Type__c);

        Voucher_Adjustment__c updatedVoucher = [ SELECT Id, Refund_Status__c, Refund_Method__c, Approval_Date__c, Approved_By__c,
            Refund_Amount__c, Fulfilled_Date__c, Fulfilled_By__c FROM Voucher_Adjustment__c WHERE Id = :testVoucher.Id LIMIT 1 ];
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED, updatedVoucher.Refund_Status__c);
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_METHOD_CARD, updatedVoucher.Refund_Method__c);
        System.assertEquals(null, updatedVoucher.Fulfilled_Date__c);
        System.assertEquals(null, updatedVoucher.Fulfilled_By__c);
        System.assertEquals(Date.today(), updatedVoucher.Approval_Date__c);
        System.assertEquals(UserInfo.getUserId(), updatedVoucher.Approved_By__c);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.valueOf(updatedVoucher.Refund_Amount__c)), ApexPages.getMessages());
    }

    /************************************************************************************
    Method Name  : chequeRefundSuccessfulWithApprovalTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void chequeRefundSuccessfulWithApprovalTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c
            FROM Voucher_Adjustment__c LIMIT 1 ];

        Test.startTest();
        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
            Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL);

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.createCheque();

        Id chequeBatchRecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName());
        List<Cheque_Batch__c> chequeBatch = new List<Cheque_Batch__c>([ SELECT Id, Name FROM Cheque_Batch__c 
            WHERE RecordTypeId = :chequeBatchRecordTypeId AND  Batch_Closed_Date__c = null LIMIT 1 ] );
        Test.stopTest();

        Voucher_Adjustment__c updatedVoucher = [ SELECT Id, Refund_Status__c, Refund_Method__c, Approval_Date__c, Approved_By__c,
            Fulfilled_Date__c, Fulfilled_By__c FROM Voucher_Adjustment__c WHERE Id = :testVoucher.Id LIMIT 1 ];
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING, updatedVoucher.Refund_Status__c);
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_METHOD_SYSTEM_CHEQUE, updatedVoucher.Refund_Method__c);
        System.assertEquals(null, updatedVoucher.Fulfilled_Date__c);
        System.assertEquals(null, updatedVoucher.Fulfilled_By__c);
        System.assertEquals(Date.today(), updatedVoucher.Approval_Date__c);
        System.assertEquals(UserInfo.getUserId(), updatedVoucher.Approved_By__c);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
            String.format(Label.Voucher_Activity_Successful_Cheque_Creation, 
            new List<String>{chequeBatch[0].Name})), 
            ApexPages.getMessages());
    }

    /************************************************************************************
    Method Name  : ccRefundSuccessfulWithoutApprovalTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void ccRefundSuccessfulWithoutApprovalTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c
            FROM Voucher_Adjustment__c LIMIT 1 ];

        Test.startTest();
        delete [ SELECT Id FROM MPP_Transaction_History__c WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND ];
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.refund();

        List<MPP_Transaction_History__c> refundTransaction = new List<MPP_Transaction_History__c>(
            [ SELECT Id, Total_Price__c, Expected_Amount__c, Order_ID__c, Payment_Type__c
              FROM MPP_Transaction_History__c WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND
              AND  Payment_status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND
              AND Subscription__c = :testVoucher.Subscription__c
              AND Subscriber__c = :testVoucher.Subscription__r.Subscriber__c LIMIT 1 ] );
        Test.stopTest();

        System.assertEquals(1, refundTransaction.size());
        System.assertEquals(testVoucher.Refund_Amount__c, refundTransaction[0].Total_Price__c);
        System.assertEquals(testVoucher.Refund_Amount__c, refundTransaction[0].Expected_Amount__c);
        System.assertEquals(vace.mppResults[0].refundOrderId, refundTransaction[0].Order_ID__c);
        System.assertEquals(Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE, refundTransaction[0].Payment_Type__c);

        Voucher_Adjustment__c updatedVoucher = [ SELECT Id, Refund_Status__c, Refund_Method__c, Refund_Amount__c, Approval_Date__c, 
        Approved_By__c, Fulfilled_Date__c, Fulfilled_By__c FROM Voucher_Adjustment__c WHERE Id = :testVoucher.Id LIMIT 1 ];
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED, updatedVoucher.Refund_Status__c);
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_METHOD_CARD, updatedVoucher.Refund_Method__c);
        System.assertEquals(Date.today(), updatedVoucher.Fulfilled_Date__c);
        System.assertEquals(UserInfo.getUserId(), updatedVoucher.Fulfilled_By__c);
        System.assertEquals(null, updatedVoucher.Approval_Date__c);
        System.assertEquals(null, updatedVoucher.Approved_By__c);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.valueOf(updatedVoucher.Refund_Amount__c)), ApexPages.getMessages());
    }

    /************************************************************************************
    Method Name  : chequeRefundSuccessfulWithoutApprovalTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void chequeRefundSuccessfulWithoutApprovalTest() {
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c
            FROM Voucher_Adjustment__c LIMIT 1 ];

        Test.startTest();
        update new Subscription__c(Id = testVoucher.Subscription__c, Sum_of_Payments__c = testVoucher.Refund_Amount__c);
        TestDataUtility.updateThresholdValue(testVoucher.Refund_Amount__c + 1);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.createCheque();

        Voucher_Adjustment__c updatedVoucher = [ SELECT Id, Refund_Status__c, Refund_Method__c, Approval_Date__c, Approved_By__c,
            Fulfilled_Date__c, Fulfilled_By__c FROM Voucher_Adjustment__c WHERE Id = :testVoucher.Id LIMIT 1 ];
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING, updatedVoucher.Refund_Status__c);
        System.assertEquals(Constants.VOUCHERADJUSTMENT_REFUND_METHOD_SYSTEM_CHEQUE, updatedVoucher.Refund_Method__c);
        System.assertEquals(Date.today(), updatedVoucher.Fulfilled_Date__c);
        System.assertEquals(UserInfo.getUserId(), updatedVoucher.Fulfilled_By__c);
        System.assertEquals(null, updatedVoucher.Approval_Date__c);
        System.assertEquals(null, updatedVoucher.Approved_By__c);

        List<Cheque_Batch__c> chequeBatchList = [ SELECT Id, Name FROM Cheque_Batch__c ];
        System.assertEquals(1, chequeBatchList.size());
        List<Cheque__c> chequeList = [ SELECT Id FROM Cheque__c WHERE Cheque_Batch__c = :chequeBatchList[0].Id ];
        System.assertEquals(1, chequeList.size());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
            String.format(Label.Voucher_Activity_Successful_Cheque_Creation, 
            new List<String>{chequeBatchList[0].Name})), 
            ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : chequeRefundSuccessfulWithoutApprovalTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void chequeRefundSuccessfulExistingChequeBatchTest() {
        Id chequeBatchRecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName());
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c
            FROM Voucher_Adjustment__c LIMIT 1 ];
        insert new Cheque_Batch__c(RecordTypeId = chequeBatchRecordTypeId, Batch_Closed_Date__c = null);

        Test.startTest();
        delete [ SELECT Id FROM MPP_Transaction_History__c ];
        TestDataUtility.updateThresholdValue(testVoucher.Refund_Amount__c + 1);
        update new Subscription__c(Id = testVoucher.Subscription__c, Sum_of_Payments__c = testVoucher.Refund_Amount__c);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.createCheque();

        List<Cheque_Batch__c> chequeBatchList = [ SELECT Id, Name FROM Cheque_Batch__c ];
        System.assertEquals(1, chequeBatchList.size());
        List<Cheque__c> chequeList = [ SELECT Id FROM Cheque__c WHERE Cheque_Batch__c = :chequeBatchList[0].Id ];
        System.assertEquals(1, chequeList.size());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
            String.format(Label.Voucher_Activity_Successful_Cheque_Creation, 
            new List<String>{chequeBatchList[0].Name})), 
            ApexPages.getMessages());

        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : isEligibleToApproveNoGroupFoundTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void isEligibleToApproveNoGroupFoundTest(){
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            delete [ SELECT Id FROM Group WHERE DeveloperName = :Constants.VOUCHERADJUSTMENT_APPROVERS_GROUP_DEV_NAME ];
            Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c
                FROM Voucher_Adjustment__c LIMIT 1 ];
            update new Voucher_Adjustment__c(Id = testVoucher.Id, 
                Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL);
            VoucherActivityRefundControllerExtension vace = 
                new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
                String.format(Label.Voucher_Activity_Approval_Group_Not_Found, 
                new List<String>{Constants.VOUCHERADJUSTMENT_APPROVERS_GROUP_NAME})), ApexPages.getMessages());
        }
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : isEligibleToApproveInsufficientPrivillegesTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void isEligibleToApproveInsufficientPrivillegesTest(){
        
        Test.startTest();
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, Subscription__c, Subscription__r.Subscriber__c
            FROM Voucher_Adjustment__c LIMIT 1 ];
        removeMemebersFromApprovalGroup();

        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
            Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
            Label.Voucher_Activity_Already_Submited_For_Approval), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : checkIfValidForRefundInvalidTypeTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void checkIfValidForRefundInvalidTypeTest(){
        Voucher_Adjustment__c testVoucher = [ SELECT Id FROM Voucher_Adjustment__c LIMIT 1 ];
        Test.startTest();
        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
            Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_VOUCHERRETURN);

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
                String.format(Label.Voucher_Activity_Invalid_Type_For_Refund, 
                new List<String>{Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN})), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : checkIfValidForRefundThresholdNotSetTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void checkIfValidForRefundThresholdNotSetTest(){
        Voucher_Adjustment__c testVoucher = [ SELECT Id FROM Voucher_Adjustment__c LIMIT 1 ];
        TestDataUtility.updateThresholdValue(null);

        Test.startTest();
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            Label.Voucher_Activity_Threshold_Value_Not_Set), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : checkIfValidForRefundAlreadyProcessedTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void checkIfValidForRefundAlreadyProcessedTest(){
        Voucher_Adjustment__c testVoucher = [ SELECT Id FROM Voucher_Adjustment__c LIMIT 1 ];
        Test.startTest();
        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
            Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            Label.Voucher_Activity_Refund_Already_Processed), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : checkIfValidForRefundPendingChequeTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void checkIfValidForRefundPendingChequeTest(){
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Subscription__c FROM Voucher_Adjustment__c LIMIT 1 ];
        Test.startTest();
        update new Voucher_Adjustment__c(Id = testVoucher.Id, 
        Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING, 
        Refund_Method__c = Constants.VOUCHERADJUSTMENT_REFUND_METHOD_SYSTEM_CHEQUE);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            Label.Voucher_Activity_Pending_Cheque), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : checkIfSubscritionAmountIsHigherTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void checkIfSubscritionAmountIsHigherTest(){
        Test.startTest();
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Subscription__c, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];
        update new Subscription__c(Id = testVoucher.Subscription__c, Sum_of_Payments__c = -100);
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            Label.Voucher_Activity_Refund_Is_Higher_Than_Payment), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : cancelTest
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void cancelTest(){
        Voucher_Adjustment__c testVoucher = [ SELECT Id FROM Voucher_Adjustment__c LIMIT 1 ];
        Test.startTest();
        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assertEquals('/'+testVoucher.Id, vace.cancel().getURL());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : multipleRefundsTest
    Author       : Mantas Grigaliunas
    Created Date : 31/01/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void multipleRefundsTest(){

        Test.startTest();
        delete [ SELECT Id FROM MPP_Transaction_History__c WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND ];
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Subscription__r.Subscriber__c, Subscription__c, Refund_Amount__c, End_Date__c
            FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testVoucher.End_Date__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.refund();

        List<MPP_Transaction_History__c> lstMppResults = [SELECT Id, Total_Price__c, Product_name__c, Sale_Type__c FROM MPP_Transaction_History__c 
            WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND
            AND Payment_status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND
            AND Subscription__c = :testVoucher.Subscription__c
            AND Subscriber__c = :testVoucher.Subscription__r.Subscriber__c ];

        Voucher_Adjustment__c updatedVoucher = [ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c LIMIT 1 ];
        System.assert(!vace.isPartialFailure);    
        System.assertEquals(updatedVoucher.Refund_Amount__c, calculateTotalSumOfPayments(lstMppResults));
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : multipleRefundsWithExistingRefundsTest
    Author       : Mantas Grigaliunas
    Created Date : 31/01/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void multipleRefundsWithExistingRefundsTest(){

        Test.startTest();
        Voucher_Adjustment__c testVoucher = [ SELECT Id, Refund_Amount__c, End_Date__c, Subscription__c, Subscription__r.Subscriber__c 
            FROM Voucher_Adjustment__c LIMIT 1 ];

        //add one more refund for existing sale payment
        Map<Id, MPP_Transaction_History__c> existingRefunds = new Map<Id, MPP_Transaction_History__c>([ SELECT Id, Payment_Type__c, Order_ID__c FROM MPP_Transaction_History__c 
            WHERE Subscription__c = :testVoucher.Subscription__c AND Payment_Status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND
            AND Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND]);

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        vace.refund();

        List<MPP_Transaction_History__c> lstMppResults = [SELECT Id, Total_Price__c, Product_name__c FROM MPP_Transaction_History__c 
            WHERE Sale_Type__c = :Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND
            AND Payment_status__c = :Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND
            AND Subscription__c = :testVoucher.Subscription__c
            AND Subscriber__c = :testVoucher.Subscription__r.Subscriber__c 
            AND Id NOT IN :existingRefunds.keySet() ];

        System.assert(!vace.isPartialFailure);    
        System.assertEquals(testVoucher.Refund_Amount__c, calculateTotalSumOfPayments(lstMppResults));
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : createCaseTest
    Author       : Mantas Grigaliunas
    Created Date : 06/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void createCaseTest(){

        delete [ SELECT Id FROM Case ];
        Test.startTest();
        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Paid_Until__c, isContinuous__c, PaymentDate__c FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c = true;
        testSubscription.MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Voucher_Activity_Refund_Not_Enough_Funds), ApexPages.getMessages());
        vace.createCase();
        List<Case> lstTestCase = [ SELECT Id, Future_Action_Date__c FROM Case ];
        System.assertEquals(1, lstTestCase.size());
        Date expectedFutureActionDate = Date.newInstance(
            testVoucher.End_Date__c.year(), 
            testVoucher.End_Date__c.month() + 1, //the following month after voucher end as it is monthly DD
            Integer.valueOf(testSubscription.PaymentDate__c) + vace.DD_DAYS_DELAY //for DD payments it need to wait for 6 days for money to be in account
        );
        //System.assertEquals(expectedFutureActionDate, lstTestCase[0].Future_Action_Date__c);
        Test.stopTest();
        
    }

    /************************************************************************************
    Method Name  : createCaseFutureActioDateInPastTest
    Author       : Mantas Grigaliunas
    Created Date : 06/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void createCaseFutureActioDateInPastTest(){

        delete [ SELECT Id FROM Case ];
        Test.startTest();
        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Paid_Until__c, isContinuous__c, PaymentDate__c FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c = true;
        testSubscription.MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Voucher_Activity_Refund_Not_Enough_Funds), ApexPages.getMessages());
        vace.futureActionCase.Future_Action_Date__c = Date.today().addDays(-1);
        vace.createCase();
        List<Case> lstTestCase = [ SELECT Id, Future_Action_Date__c FROM Case ];
        System.assertEquals(3, ApexPages.getMessages().size());
        System.assertEquals(0, lstTestCase.size());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : futureActionCaseAlreadyExistTest
    Author       : Mantas Grigaliunas
    Created Date : 06/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void futureActionCaseAlreadyExistTest(){

        Test.startTest();
        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Paid_Until__c, isContinuous__c, PaymentDate__c FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c = true;
        testSubscription.MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));

        System.assertEquals(1, vace.voucherCases.size());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Voucher_Activity_Refund_Case_Already_Created), ApexPages.getMessages());

        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : calculateFutureActionDateFirstDDPaymentTest
    Author       : Mantas Grigaliunas
    Created Date : 06/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void calculateFutureActionDateFirstDDPaymentTest(){

        Test.startTest();
        delete [ SELECT Id FROM MPP_Transaction_History__c ];
        delete [ SELECT Id FROM Case ];
        Date today = Date.today();
        Date firstPaymentDate = Date.newInstance(today.year(), today.month() + 1, 1); //first day of next month

        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Paid_Until__c, isContinuous__c, PaymentDate__c FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c = true;
        testSubscription.MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        testSubscription.MPP_DD_Next_Payment_Date__c = firstPaymentDate;
        testSubscription.MPP_DD_First_Payment_Amount__c = 100;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));

        //System.assertEquals(firstPaymentDate.addDays(vace.DD_DAYS_DELAY), vace.futureActionCase.Future_Action_Date__c);

        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : calculateFutureActionDateFirstCCPaymentTest
    Author       : Mantas Grigaliunas
    Created Date : 06/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void calculateFutureActionDateFirstCCPaymentTest(){

        Test.startTest();
        delete [ SELECT Id FROM MPP_Transaction_History__c ];
        delete [ SELECT Id FROM Case ];
        Date today = Date.today();
        Date firstPaymentDate = Date.newInstance(today.year(), today.month() + 1, 1); //first day of next month

        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Payment_Type__c, Paid_Until__c, isContinuous__c, PaymentDate__c 
                                             FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c             = true;
        testSubscription.Payment_Type__c             = Constants.SUB_PMETHOD_CC;
        testSubscription.MPP_CC_Frequency__c         = Constants.DD_COL_FREQ_QUARTERLY;
        testSubscription.MPP_CC_Next_Payment_Date__c = firstPaymentDate;
        testSubscription.MPP_CC_First_Payment_Amount__c = 100;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));

        //System.assertEquals(firstPaymentDate.addDays(vace.CC_DAYS_DELAY), vace.futureActionCase.Future_Action_Date__c);

        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : calculateFutureActionDateFirstCCPaymentTest
    Author       : Mantas Grigaliunas
    Created Date : 06/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void calculateFutureActionDateQuarterlyPaymentTest(){

        Test.startTest();
        delete [ SELECT Id FROM Case ];

        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Payment_Type__c, Paid_Until__c, isContinuous__c, PaymentDate__c 
                                             FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c             = true;
        testSubscription.Payment_Type__c             = Constants.SUB_PMETHOD_CC;
        testSubscription.MPP_CC_Frequency__c         = Constants.DD_COL_FREQ_QUARTERLY;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));

        Date today = Date.today();
        Date nextPaymentDate = Date.newInstance(today.year(), today.month() + vace.QUARTER, 1); //first day of next quarter month
        //System.assertEquals(nextPaymentDate.addDays(vace.CC_DAYS_DELAY), vace.futureActionCase.Future_Action_Date__c);

        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : sendEmailNoCustomSettingTest
    Author       : Mantas Grigaliunas
    Created Date : 15/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void sendEmailNoCustomSettingTest(){
        
        Voucher_Adjustment__c testVoucher = [ SELECT Id FROM Voucher_Adjustment__c LIMIT 1 ];    

        Test.startTest();
        //remove custom setting
        Configuration__c c = Configuration__c.getOrgDefaults();
        c.MPP_Refund_Email_Template_Name__c = null;
        update c;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));

        vace.sendEmail(null, vace.voucherActivity.Subscription__r.Subscriber__r.PersonContactId, vace.voucherActivity.Id, true);

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            Label.Voucher_Activity_Email_Template_Custom_Setting_Not_Set), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : sendEmailNoCustomSettingTest
    Author       : Mantas Grigaliunas
    Created Date : 15/02/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void sendEmailNoEmailTemplateTest(){
        
        Voucher_Adjustment__c testVoucher = [ SELECT Id FROM Voucher_Adjustment__c LIMIT 1 ]; 
        String emailTemplateDevName = Configuration__c.getOrgDefaults().MPP_Refund_Email_Template_Name__c;   

        Test.startTest();
        //remove template
        delete [ SELECT Id FROM EmailTemplate WHERE DeveloperName = :emailTemplateDevName ];

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));

        vace.sendEmail(emailTemplateDevName, vace.voucherActivity.Subscription__r.Subscriber__r.PersonContactId, vace.voucherActivity.Id, true);

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.format(Label.Voucher_Activity_Email_Template_Not_Exist, new List<String>{emailTemplateDevName})), ApexPages.getMessages());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : sendMailLimitTest
    Author       : Konrad Czykin
    Created Date : 19/06/2017
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/ 
    @isTest static void sendMailLimitTest(){

        delete [ SELECT Id FROM Case ];
        Test.startTest();
        //updated subscription to conituous
        Subscription__c testSubscription = [ SELECT Id, Paid_Until__c, isContinuous__c, PaymentDate__c FROM Subscription__c LIMIT 1 ];
        testSubscription.isContinuous__c = true;
        testSubscription.MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        update testSubscription;

        //amend voucher to set end date more than Paid Until date
        Voucher_Adjustment__c testVoucher = [ SELECT Id, End_Date__c FROM Voucher_Adjustment__c LIMIT 1 ];
        testVoucher.End_Date__c = testSubscription.Paid_Until__c.addDays(7);
        update testVoucher;

        VoucherActivityRefundControllerExtension vace = 
            new VoucherActivityRefundControllerExtension(new ApexPages.StandardController(testVoucher));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Voucher_Activity_Refund_Not_Enough_Funds), ApexPages.getMessages());
        
        vace.isTestMailLimit = true;
        vace.createCase();
        List<Case> lstTestCase = [ SELECT Id FROM Case ];
        System.assertEquals(1, lstTestCase.size());

        List<Task> lsTasks = [SELECT Id, Subject FROM Task LIMIT 1];
        System.assertEquals(1, lsTasks.size());
        System.assertEquals('Email: Delayed refund', lsTasks[0].Subject);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            Label.Task_Creation), ApexPages.getMessages());
        Test.stopTest();
        
    }

    /************************************************************************************
    Method Name  : insertCurrentUserToApproversGroup
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Function     : add user to approvers group
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static void insertCurrentUserToApproversGroup(){
        //runAs is used to avoid MIXED_DML_OPERATION exception on Group Member insert
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group approvalGroup = [ SELECT Id FROM Group 
                WHERE DeveloperName = :Constants.VOUCHERADJUSTMENT_APPROVERS_GROUP_DEV_NAME LIMIT 1 ];
            insert new GroupMember(GroupId = approvalGroup.Id, UserOrGroupId = UserInfo.getUserId());
        }
    }

    /************************************************************************************
    Method Name  : removeMemebersFromApprovalGroup
    Author       : Mantas Grigaliunas
    Created Date : 18/11/2016
    Function     : remove all users from approvers group
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static void removeMemebersFromApprovalGroup(){
        Group approvalGroup = [ SELECT Id FROM Group 
            WHERE DeveloperName = :Constants.VOUCHERADJUSTMENT_APPROVERS_GROUP_DEV_NAME LIMIT 1 ];
        delete [SELECT Id FROM GroupMember WHERE GroupId = :approvalGroup.Id];
    }

    /************************************************************************************
    Method Name  : calculateTotalSumOfPayments
    Author       : Mantas Grigaliunas
    Created Date : 03/02/2017
    Function     : calculates sum of Mpp payments
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static Decimal calculateTotalSumOfPayments(List<MPP_Transaction_History__c> lstMpp){
        Decimal totalRefundSum = 0;
        for(MPP_Transaction_History__c mpp : lstMpp){
            totalRefundSum += mpp.Total_Price__c;
        }
        return totalRefundSum;  
    }   
}