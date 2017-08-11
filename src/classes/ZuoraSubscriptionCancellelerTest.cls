/********************************************************************
 * ZuoraSubscriptionCancellelerTest
 *
 * Author: Kevin Fabregue - Zuora UK
  #############Change Log#############
 * Modified by          Version     Change Date    
 * Mantas Grigaliunas   1.1         28/06/2016  //added grace period related test methods
 * Mantas Grigaliunas   1.2         02/05/2017  //refactored test class after ZuoraSubscriptionCanceller class was refactored
 ********************************************************************/

@isTest
private class ZuoraSubscriptionCancellelerTest{

    static final String SUBSCRIPTION_ID   = '123456789';
    static final String CANCEL_INVOICE_ID = 'C123';
    static final String INVOICE_ID        = 'I123';
    static final String PAYMENT_ID        = 'P123';

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - method holds common functions used by the multiple tests, 
               @testSetup is not used because seeAllData anotaion is enabled in most of the set methods
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    public static void testSetup(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.deleteApplicationSettings();
        tdu.deleteSAMHTTPSettings();
        tdu.deleteGeneralSettings();
        tdu.deletePlaneURLSettings();
        tdu.createRegistrants();
        Id registrantId = tdu.lstRegistrants.get(0).Id;
        tdu.createBillingAccountToRegistrant(registrantId);
        tdu.createZuoraSubscriptionToRegistrant(registrantId);
        tdu.lstZuoraSubscriptions.get(0).Zuora__Zuora_Id__c = SUBSCRIPTION_ID;
        update tdu.lstZuoraSubscriptions;
        tdu.CreateGracePeriodValueSetting();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - method holds common functions used by the multiple tests
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    public static void gracePeriodTestSetup(){
        TestDataUtility tdu = new TestDataUtility();
        //delete all existing Application Settings records in test context
        tdu.deleteApplicationSettings();
        //create grace period custom setting record with default (14) value
        tdu.CreateGracePeriodValueSetting();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for checkZuoraSubscriptionEligibleMigratedHardCancellation
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void checkZuoraSubscriptionHasInvoicesTest(){
        Test.startTest();
        System.assert(ZuoraSubscriptionCanceller.checkZuoraSubscriptionHasInvoices(ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for checkZuoraSubscriptionEligibleMigratedHardCancellation
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void checkZuoraSubscriptionHasInvoicesNoInvoicesTest(){
        Test.startTest();
        Z_TestFactory.createZuoraInvoiceItemTestRecord = false;
        System.assert(!ZuoraSubscriptionCanceller.checkZuoraSubscriptionHasInvoices(ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for checkZuoraSubscriptionEligibleMigratedHardCancellation
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void checkZuoraSubscriptionEligibleCancellationTest(){

        Test.startTest();
         //add product
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();
        
        System.assert(ZuoraSubscriptionCanceller.checkZuoraSubscriptionEligibleCancellation(
            ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID, SUBSCRIPTION_ID, tdu.lstZuoraSubscriptions[0].Id, Constants.SUBSCRIPTION_ACTIVE_STATUS, Constants.SUBSCRIPTION_ACTIVE_STATUS), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for isSubscriptionActive
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void isSubscriptionActiveInactiveZuoraSubscriptionTest(){
        Test.startTest();
        Z_TestFactory.createZuoraSubscriptionTestRecord = false;
        ZuoraSubscriptionCanceller.checkZuoraSubscriptionEligibleCancellation(
            ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID, SUBSCRIPTION_ID, SUBSCRIPTION_ID, Constants.SUBSCRIPTION_ACTIVE_STATUS, Constants.SUBSCRIPTION_ACTIVE_STATUS);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Canceller_Inactive_On_Zuora), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for isSubscriptionActive
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void isSubscriptionActiveZuoraSubscriptionActiveTest(){
        Test.startTest();
        ZuoraSubscriptionCanceller.checkZuoraSubscriptionEligibleCancellation(
            ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID, SUBSCRIPTION_ID, SUBSCRIPTION_ID, Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS, Constants.SUBSCRIPTION_CANCELLED_STATUS);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Canceller_Active_On_Zuora), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for isSubscriptionActive
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void isSubscriptionActiveCancelledTest(){
        Test.startTest();
        Z_TestFactory.createZuoraSubscriptionTestRecord = false;
        ZuoraSubscriptionCanceller.checkZuoraSubscriptionEligibleCancellation(
            ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID, SUBSCRIPTION_ID, SUBSCRIPTION_ID, Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS, Constants.SUBSCRIPTION_CANCELLED_STATUS);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Cancellation_Already_Cancelled_Error_Message), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for isSubscriptionActive
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void isAccountBalanceZeroInvoiceBalanceZeroTest(){
        Test.startTest();
        Z_TestFactory.testAccountBalance = 1;
        System.assert(!ZuoraSubscriptionCanceller.isAccountBalanceZero(ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method to make sure grace period custom setting is set
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
     @isTest static void isSubscriptionInGracePeriodPositiveTest(){

        Test.startTest();
        gracePeriodTestSetup();
        //Grace period value is set to positive integer
        System.assert(ZuoraSubscriptionCanceller.isSubscriptionInGracePeriod(Date.today(), '14'),
            'isSubscriptionInGracePeriod didn\'t return true as expected when grace period is set to positive value');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method to make sure that grace period custom setting blank value is handled
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
     @isTest static void isSubscriptionInGracePeriodNullTest(){

        Test.startTest();
        gracePeriodTestSetup();
        setGracePeriodValue(null);
        //Grace period value is set to positive integer
        System.assert(!ZuoraSubscriptionCanceller.isSubscriptionInGracePeriod(Date.today(), null),
            'isSubscriptionInGracePeriod didn\'t return false as expected when grace period is set to null');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method to make sure grace period custom setting inexistence is handled
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void isSubscriptionInGracePeriodBlankTest(){

        String BLANK = '';
        Test.startTest();
        gracePeriodTestSetup();
        //Grace period value is set to positive integer
        System.assert(!ZuoraSubscriptionCanceller.isSubscriptionInGracePeriod(Date.today(), BLANK),
            'isSubscriptionInGracePeriod didn\'t return false as expected when grace period is set to null');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 02/05/2017
    Function - test method fo isRefundAllowed() functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void isRefundAllowedNoChargeProductTest(){

        Test.startTest();
        System.assert(!ZuoraSubscriptionCanceller.isRefundAllowed(SUBSCRIPTION_ID), ZuoraSubscriptionCanceller.errorMessage);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Canceller_Charge_Product_Not_Found), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 02/05/2017
    Function - test method fo isRefundAllowed() functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void isRefundAllowedZuoraIdBlankTest(){

        Test.startTest();
        //add product
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptionProductCharges();
        Zuora__Product__c subProduct = new Zuora__Product__c(Name = 'Test', Zuora__External_Id__c = null);
        insert subProduct;
        update new Zuora__SubscriptionProductCharge__c(Id = tdu.lstZuoraSubscriptionProductCharges[0].Id,  Zuora__Product__c = subProduct.Id);

        System.assert(!ZuoraSubscriptionCanceller.isRefundAllowed(tdu.lstZuoraSubscriptions[0].Id), ZuoraSubscriptionCanceller.errorMessage);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Canceller_Prduct_Zuora_Id_Blank), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 02/05/2017
    Function - test method fo isRefundAllowed() functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void isRefundAllowedZProductNotFoundTest(){

        String ZUORA_ID = 'NotFound';
        Test.startTest();
        //add product
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptionProductCharges();
        Zuora__Product__c subProduct = new Zuora__Product__c(Name = 'Test', Zuora__External_Id__c = ZUORA_ID);
        insert subProduct;
        update new Zuora__SubscriptionProductCharge__c(Id = tdu.lstZuoraSubscriptionProductCharges[0].Id,  Zuora__Product__c = subProduct.Id);

        System.assert(!ZuoraSubscriptionCanceller.isRefundAllowed(tdu.lstZuoraSubscriptions[0].Id), ZuoraSubscriptionCanceller.errorMessage);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(String.format(Label.Zuora_Subscription_Canceller_ZProduct_Not_Found, new List<String>{ZUORA_ID})), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 02/05/2017
    Function - test method fo isRefundAllowed() functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void isRefundAllowedNotAllowedTest(){

        Test.startTest();
         //add product
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();
        update new zqu__ZProduct__c(Id = tdu.lstZproducts[0].Id, RefundsAllowed__c = 'No');

        System.assert(!ZuoraSubscriptionCanceller.isRefundAllowed(tdu.lstZuoraSubscriptions[0].Id), ZuoraSubscriptionCanceller.errorMessage);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(String.format(Label.Zuora_Subscription_Canceller_Cancellation_Not_Allowed, new List<String>{tdu.lstZproducts[0].Name})), 
                        ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, successful refund
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationPreviewTest(){
        Test.startTest();
        System.assertEquals(-Z_TestFactory.testAmendmentAmount, ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING,
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, true, false, false),
            ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, successful refund
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationFailedAmendmenTest(){
        Test.startTest();
        Z_TestFactory.testAmendmentSuccess = false;
        System.assertEquals(null, ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING,
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, true, false, false),
            ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, successful credit card refund
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationWithCreditCardRefundTest(){

        String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentId                 = PAYMENT_ID;

        Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(-Z_TestFactory.testAmendmentAmount, refundAmount, ZuoraSubscriptionCanceller.errorMessage);

        String testMessage = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, true, true, false);
        System.assert(testMessage.contains(String.format(Label.Zuora_Subscription_Canceller_Refund_Amount, new List<String>{String.valueOf(-Z_TestFactory.testAmendmentAmount)})),    
            ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, successful BankTransfer refund
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationWithDirectDebitRefundTest(){
        
        String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };
        
        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.testPaymentMethod             = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
        Z_TestFactory.testPaymentGatewayState       = Constants.ZUORA_PAYMENT_GATEWAY_STATE_SETTLED;
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testTaxationItemInvoiceItemId = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentId                 = PAYMENT_ID; 
        
        Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(-Z_TestFactory.testAmendmentAmount, refundAmount, ZuoraSubscriptionCanceller.errorMessage);

        String testMessage = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, true, true, false);
        System.assert(testMessage.contains(String.format(Label.Zuora_Subscription_Canceller_Refund_Amount, new List<String>{String.valueOf(-Z_TestFactory.testAmendmentAmount)})),    
            ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, future date
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationFutureDateTest(){

        String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentId                 = PAYMENT_ID; 

        Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today().addMonths(1), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(-Z_TestFactory.testAmendmentAmount, refundAmount, ZuoraSubscriptionCanceller.errorMessage);

        String testMessage = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, true, true, true);
        System.assert(testMessage.contains(String.format(Label.Zuora_Subscription_Canceller_Refund_Amount, new List<String>{String.valueOf(-Z_TestFactory.testAmendmentAmount)})),    
            ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, external payment
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationExternalPaymentTest(){

        String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentType               = Constants.ZUORA_REFUND_TYPE_EXTERNAL;
        Z_TestFactory.testPaymentId                 = PAYMENT_ID;


        Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(0, refundAmount, ZuoraSubscriptionCanceller.errorMessage);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Canceller_External_Payment_Error), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, BankTransfer payment cancellation
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationPaymentCancellationTest(){
        
        String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.testPaymentMethod             = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testTaxationItemInvoiceItemId = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentId                 = PAYMENT_ID;
        
        Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(0, refundAmount, ZuoraSubscriptionCanceller.errorMessage);
        
        String testMessage = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, true, true, false);
        System.assert(testMessage.contains(Label.Zuora_Subscription_Canceller_No_Outstanding_Payments), ZuoraSubscriptionCanceller.errorMessage);
        System.assert(testMessage.contains(Label.Zuora_Subscription_Canceller_Last_Payment_Cancelled), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, BankTransfer payment cancellation failed
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationPaymentCancellationFailedTest(){
        
        String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.testPaymentMethod             = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testTaxationItemInvoiceItemId = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentVoided             = false;
        Z_TestFactory.testPaymentId                 = PAYMENT_ID;
        
        Decimal testRefundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(-Z_TestFactory.testAmendmentAmount, testRefundAmount, ZuoraSubscriptionCanceller.errorMessage);
        System.assert(ZuoraSubscriptionCanceller.errorMessage.contains(Label.Zuora_Subscription_Canceller_Payment_Cancellation_Failed), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/04/2017
    Function - test method for processSubscriptionCancellation, payment invoice adjustment test
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true) 
    static void processSubscriptionCancellationPaymentInvoiceAdjustmentTest(){
        
        String CANCEL_INVOICE_AMOUNT = '-5';
        String PAYMENT_AMOUNT        = '10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-4', '-1'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Test.startTest();
        Z_TestFactory.testPaymentMethod             = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testTaxationItemInvoiceItemId = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = Decimal.valueOf(PAYMENT_AMOUNT);
        Z_TestFactory.testPaymentId                 = PAYMENT_ID;
        
        Decimal refundAmount = ZuoraSubscriptionCanceller.processSubscriptionCancellation(ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, 
            Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Date.today(), Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, false, true, false);
        System.assertEquals(0, refundAmount, ZuoraSubscriptionCanceller.errorMessage);

        String testMessage = ZuoraSubscriptionCanceller.generateCancellationMessage(refundAmount, true, true, false);
        System.assert(testMessage.contains(Label.Zuora_Subscription_Canceller_No_Outstanding_Payments), ZuoraSubscriptionCanceller.errorMessage);
        System.assert(testMessage.contains(Label.Zuora_Subscription_Canceller_Last_Payment_Cancelled), ZuoraSubscriptionCanceller.errorMessage);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - method to get Application_Setting.GracePeriodDuration custom setting record
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    public static String getGracePeriodValue(){
        Application_Settings__c gracePeriodCustomSetting = Application_Settings__c.getInstance(Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME);
        return (gracePeriodCustomSetting != null ?  gracePeriodCustomSetting.Value__c : null);
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - method to update Application_Setting.GracePeriodDuration custom setting record value
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    public static void setGracePeriodValue(String value){
        Application_Settings__c appSetting = Application_Settings__c.getInstance(Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME); 
        appSetting.Value__c = value;
        update appSetting;
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - method to build a specific error message from the lable which is used in test assertion
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    public static String getExpectedGracePeriodErrorMessage(){
        List<String> labelParameter = new String[]{Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME};
        return String.format(Label.Zuora_Subscription_Canceller_Grace_Period_Not_Set_Error, labelParameter);
    }
}