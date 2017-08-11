/**
* @author Pawel Chrzanowski
* @date 22/04/2016
* @description Test class for ZuoraSubscriptionCancellationController
*##########Change Log##########
* Modified by         Version   Change Date
* Gavin Palmer          1.1     22/06/2016 - modified cancelSubscriptionPositive()
* Mantas Grigaliunas    1.2     28/06/2016  //replaced strings with constants for SelectedItem controller variable
*                                           added grace period and option 3 selection related tests
* Mantas Grigaliunas    1.3     30/06/2016  //added test method testCancelAlreadyCanceledSubscription(),
*                                           fixed testCancelSubscriptionNegative() test method
* Pawel Chrzanowski     1.4     31/01/2017  added goBackTest()
* Mantas Grigaliunas    1.5     26/04/2017  fixed and added more test after ZuoraSubscriptionCanceller refactoring
*/
@isTest
private class ZuoraSubscriptionCancellationControllerT {

    static final String SUBSCRIPTION_ID     = '123456789'; //don't change - used for MPP
    static final String SUBSCRIPTION_NAME   = 'Migrated-sub-01'; //don't change - used for MPP
    static final Date   NEXT_CHARGE_DATE    = Date.today().addDays(20);
    static final String CANCELLATION_REASON = 'Political';

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - method holds common functions used by the multiple tests, 
               @testSetup is not used because seeAllData anotaion is enabled in most of the set methods
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @TestVisible 
    private static void testSetup(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.deleteApplicationSettings();
        tdu.deleteSAMHTTPSettings();
        tdu.deleteGeneralSettings();
        tdu.deletePlaneURLSettings();
        tdu.CreateGracePeriodValueSetting();
        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();
        tdu.lstZuoraSubscriptions.get(0).Zuora__Zuora_Id__c = SUBSCRIPTION_ID;
        update tdu.lstZuoraSubscriptions[0];
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 30/06/2016
    Function - method to check if the error message is displayed when url id parameter is missing
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void missingUrlParameterErrorMessageTest(){
        Test.startTest();
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        String expectedErrorMessages = Label.Zuora_Subscription_Cancellation_Id_Parameter_Missing_Error;
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(
                                    new ApexPages.StandardController(new Zuora__Subscription__c()));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), expectedErrorMessages));
        Test.stopTest();
    }
    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 30/06/2016
    Function - method to check if the error message is displayed when url id parameter is missing
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @IsTest static void gracePeriodCustomSettingNotSetTest(){

        testSetup();
        
        Test.startTest();
        setGracePeriodValue(null);

        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];

         ZuoraSubscriptionCancellationController controller = 
            new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));

        List<String> labelParameter = new String[]{Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME};
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.format(Label.Zuora_Subscription_Canceller_Grace_Period_Not_Set_Error, labelParameter)), ApexPages.getMessages());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 30/06/2016
    Function - method to check if the error message is displayed when url id parameter is missing
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest static void zuoraIdBlankTest(){
        testSetup();
        
        Test.startTest();
        TestDataUtility tdu = new TestDataUtility(1);

        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        //remove zuora id                                        
        zSubscription.Zuora__Zuora_Id__c = null;
        update zSubscription;

        ZuoraSubscriptionCancellationController controller = 
            new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Subscription_Not_Found), ApexPages.getMessages());
        System.assert(!controller.renderPageItems, 'renderPageItems expected to be false');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to check if correct warninng message is shown
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void monthlySubscriptionWarningMessageTest(){
        testSetup();
        Test.startTest();
        setGracePeriodValue('-1'); //make sure subscription is outside grace period
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Subscription_Rate_Plan_Term_Type__c, Zuora__SubscriptionStartDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Subscription_Rate_Plan_Term_Type__c = 'Monthly';
        update zSubscription;
                        
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Zuora_Subscription_Canceller_Monthly_Sub_Warning), ApexPages.getMessages());
        System.assert(controller.renderPageItems, 'renderPageItems expected to be false');
        Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to check if correct warninng message is shown
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void annualSubscriptionWarningMessageTest(){
        testSetup();
        String gracePeriodDuration = '-1';
        Test.startTest();
        setGracePeriodValue(gracePeriodDuration); //make sure subscription is outside grace period
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Subscription_Rate_Plan_Term_Type__c, Zuora__SubscriptionStartDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Subscription_Rate_Plan_Term_Type__c = 'Annual';
        update zSubscription;
                        
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
            String.format(Label.Zuora_Subscription_Canceller_Annual_Sub_Warning, new List<String>{gracePeriodDuration})), ApexPages.getMessages());
        System.assert(controller.renderPageItems, 'renderPageItems expected to be true');
        Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to check if the error message is displayed when Zuora subscription status in not Active
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void inactiveZuoraSubscriptionTest(){
        testSetup();
        Test.startTest();
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];

        Z_TestFactory.createZuoraSubscriptionTestRecord = false;                                        
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Zuora_Subscription_Canceller_Inactive_On_Zuora), ApexPages.getMessages());
        System.assert(!controller.renderPageItems, 'renderPageItems expected to be false');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to check if the error message is displayed when Zuora subscription is not eligible for cancellation
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void notEligibleErrorMessageTest(){
        testSetup();
        String gracePeriodDuration = '-1';
        Test.startTest();
        setGracePeriodValue(gracePeriodDuration); //make sure subscription is outside grace period
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Subscription_Rate_Plan_Term_Type__c, Zuora__SubscriptionStartDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Subscription_Rate_Plan_Term_Type__c = 'Annual';
        update zSubscription;
                        
        Z_TestFactory.testAccountBalance = 1;
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Zuora_Subscription_Canceller_Not_Eligible_For_Cancellation), ApexPages.getMessages());
        System.assert(!controller.renderPageItems, 'renderPageItems expected to be false');
        Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 27/04/2017
    Function - method to check if correct options are rendered in grace period
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void getItemsInGracePeriodAnnualTest(){
        testSetup();
        Test.startTest();
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Zuora__NextChargeDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        
        Z_TestFactory.createZuoraInvoiceItemTestRecord = false;                
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        List<SelectOption> options = controller.getItems();
        System.assertEquals(1, options.size());
        System.assertEquals(controller.SELECT_OPTION_2, options.get(0).getValue());
        System.assertEquals(options.get(0).getLabel(), String.format(Label.Zuora_Subscription_Canceller_Cancel_Today_Option, new List<String>{controller.earliestCancellationDate.format()}));
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 27/04/2017
    Function - method to check if correct options are rendered in grace period
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void getItemsInGracePeriodMonthlyTest(){
        testSetup();
        Test.startTest();
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
                        
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        List<SelectOption> options = controller.getItems();
        System.assertEquals(1, options.size());
        System.assertEquals(controller.SELECT_OPTION_2, options.get(0).getValue());
        System.assertEquals(String.format(Label.Zuora_Subscription_Canceller_Cancel_On_Last_Invoice_Option, new List<String>{controller.subscriptionTermStartDate.format()}), options.get(0).getLabel());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 27/04/2017
    Function - method to check if correct options are rendered outside grace period
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void getItemsOutsideGracePeriodTest(){
        testSetup();
        Test.startTest();
        setGracePeriodValue('-1');
        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Zuora__NextChargeDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];        
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        List<SelectOption> options = controller.getItems();
        System.assertEquals(3, options.size());
        System.assertEquals(controller.SELECT_OPTION_1, options.get(0).getValue());
        System.assertEquals(controller.SELECT_OPTION_2, options.get(1).getValue());
        System.assertEquals(controller.SELECT_OPTION_3, options.get(2).getValue());
        System.assertEquals(String.format(Label.Zuora_Subscription_Canceller_Cancel_End_Term_Option, new List<String>{zSubscription.Zuora__NextChargeDate__c.format()}), options.get(0).getLabel());
        System.assertEquals(String.format(Label.Zuora_Subscription_Canceller_Cancel_Today_Option, new List<String>{controller.earliestCancellationDate.format()}), options.get(1).getLabel());
        System.assertEquals(Label.Zuora_Subscription_Canceller_Cancel_On_Specific_Date_Option, options.get(2).getLabel());
        Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 22/04/2016
    Function - test negative scenarios of cancelling Subscription
    #############Change Log#############
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1         22/06/2016  //replaced item strings with constants from controller class
    Mantas Grigaliunas  1.2         30/06/2016  //gave access to the data as Zuora WSDL is required for the test execution
                                                  added some fixes to make sure the test is going through the workflow as expected 
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelSubscriptionNegativeTest() {

        TestDataUtility tdu = new TestDataUtility(1);
        //create test data
        tdu.deleteApplicationSettings();
        tdu.deleteSAMHTTPSettings();
        tdu.deleteGeneralSettings();
        tdu.deletePlaneURLSettings();
        tdu.CreateGracePeriodValueSetting();
        tdu.createDigitalMPPTransactionHistory(null);

        tdu.lstDigitalSubscribers[0].MPP_Service_Id__c = '12345';
        update tdu.lstDigitalSubscribers[0];

        Zuora__CustomerAccount__c billingAccount = TestDataUtility.newZuoraCustomerAccount(0, tdu.lstDigitalSubscribers[0].Id);
        insert billingAccount;

        Zuora__Subscription__c zSubscription = createTestZuoraSubscription(SUBSCRIPTION_ID, SUBSCRIPTION_NAME, tdu.lstDigitalSubscribers[0].Id, billingAccount.Id); 
        insert zSubscription;

        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();
        Zuora__SubscriptionProductCharge__c productCharge = new Zuora__SubscriptionProductCharge__c(Id = tdu.lstZuoraSubscriptionProductCharges[0].Id, Zuora__Subscription__c = zSubscription.Id);
        update productCharge;

        ZuoraSubscriptionCancellationController controller;
        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);

        controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        controller.SelectedItem = controller.SELECT_OPTION_1;
        controller.cancelSubscription();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Cancellation_Reason_Required_Error_Message));
        
        Test.startTest();
        //No MPP Transaction History Order Id
        Z_TestFactory.createZuoraInvoiceItemTestRecord = false;
        controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(controller.subscriptionEligibleMigratedHardCancellation, 'subscriptionEligibleMigratedHardCancellation parameter expected to be set to true');
        controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
        controller.earliestCancellationDate = Date.today();
        controller.SelectedItem = controller.SELECT_OPTION_2;
        controller.cancelSubscription();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.No_Order_ID));
        Z_TestFactory.createZuoraInvoiceItemTestRecord = true;

        //No MPP Transaction History
        Account acc = [SELECT MPP_Service_Id__c, 
                      (SELECT Id, Order_Id__c FROM MPP_Transaction_Histories__r) 
                       FROM Account 
                       WHERE Id = :tdu.lstDigitalSubscribers[0].Id LIMIT 1];
        MPP_Transaction_History__c mppTH = acc.MPP_Transaction_Histories__r[0];
        delete mppTH;
        controller.cancelSubscription();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.No_Transaction_History));

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 22/04/2016
    Function - test negative scenarios of cancelling Subscription - No MPP Service Id
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelSubscriptionNegative_NoMPPServiceId() {
        TestDataUtility tdu = new TestDataUtility(1);
        //create test data
        tdu.deleteApplicationSettings();
        tdu.deleteSAMHTTPSettings();
        tdu.deleteGeneralSettings();
        tdu.deletePlaneURLSettings();
        tdu.CreateGracePeriodValueSetting();
        tdu.createDigitalMPPTransactionHistory(null);

        tdu.lstMPPTransactionHistory[0].Order_Id__c = '1234567';
        update tdu.lstMPPTransactionHistory[0];

        Zuora__CustomerAccount__c billingAccount = TestDataUtility.newZuoraCustomerAccount(0, tdu.lstDigitalSubscribers[0].Id);
        insert billingAccount;

        Zuora__Subscription__c zSubscription = createTestZuoraSubscription(SUBSCRIPTION_ID, SUBSCRIPTION_NAME, tdu.lstDigitalSubscribers[0].Id, billingAccount.Id); 
        insert zSubscription;

        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();
        Zuora__SubscriptionProductCharge__c productCharge = new Zuora__SubscriptionProductCharge__c(Id = tdu.lstZuoraSubscriptionProductCharges[0].Id, Zuora__Subscription__c = zSubscription.Id);
        update productCharge;

        Test.setCurrentPage(Page.ZuoraSubscriptionCancellation);
        Z_TestFactory.createZuoraInvoiceItemTestRecord = false;

        Test.startTest();
            ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
            controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
            controller.earliestCancellationDate = Date.today();
            controller.SelectedItem = controller.SELECT_OPTION_2;
            controller.cancelSubscription();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Wrong_Service_ID), ApexPages.getMessages());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 22/04/2016
    Function - test positive scenarios of cancelling Subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         22/06/2016 Added go back assertion
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelSubscriptionPositive() {
        TestDataUtility tdu = new TestDataUtility(1);
        //create test data
        tdu.deleteApplicationSettings();
        tdu.deleteSAMHTTPSettings();
        tdu.deleteGeneralSettings();
        tdu.deletePlaneURLSettings();
        tdu.CreateGracePeriodValueSetting();
        tdu.createDigitalMPPTransactionHistory(null);

        tdu.lstMPPTransactionHistory[0].Order_Id__c = '1234567';
        update tdu.lstMPPTransactionHistory[0];

        tdu.lstDigitalSubscribers[0].MPP_Service_Id__c = '12345';
        update tdu.lstDigitalSubscribers[0];

        Zuora__CustomerAccount__c billingAccount = TestDataUtility.newZuoraCustomerAccount(0, tdu.lstDigitalSubscribers[0].Id);
        insert billingAccount;

        List<Zuora__Subscription__c> lstZSubscriptions = new List<Zuora__Subscription__c>();
        lstZSubscriptions.add(createTestZuoraSubscription(SUBSCRIPTION_ID,             SUBSCRIPTION_NAME,     tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        lstZSubscriptions.add(createTestZuoraSubscription(SUBSCRIPTION_ID+'_norefund', SUBSCRIPTION_NAME+'2', tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        insert lstZSubscriptions;

        TestDataUtility productData = new TestDataUtility(lstZSubscriptions.size());
        productData.createSubscriptionProductCharges();
        productData.createZProducts();

        List<Zuora__SubscriptionProductCharge__c> productChargesToUpdate = new List<Zuora__SubscriptionProductCharge__c>();
        for(Integer i = 0; i < lstZSubscriptions.size(); i++)
            productChargesToUpdate.add(new Zuora__SubscriptionProductCharge__c(Id = productData.lstZuoraSubscriptionProductCharges[i].Id, Zuora__Subscription__c = lstZSubscriptions[i].Id));
        update productChargesToUpdate;

        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);
        Z_TestFactory.createZuoraInvoiceItemTestRecord = false;

        Test.startTest();
        //page init success
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(lstZSubscriptions.get(0)));
        System.assertEquals(SUBSCRIPTION_ID, controller.zSubscriptionId);
        System.assertEquals(tdu.lstDigitalSubscribers[0].Id, controller.sfdcAccountId);
        System.assertEquals(SUBSCRIPTION_NAME, controller.subscriptionNumber);
        System.assertEquals(NEXT_CHARGE_DATE, controller.subscriptionNextChargeDate);
        System.assert(controller.subscriptionEligibleMigratedHardCancellation);

        //Sub reason required
        controller.subscriptionObj.Cancellation_Reason__c = 'Price';
        controller.subscriptionObj.Sub_Cancellation_Reason__c = 'Other';
        controller.earliestCancellationDate = Date.today();
        controller.SelectedItem = controller.SELECT_OPTION_2;
        controller.Datename = '22/04/2016';
        controller.cancelSubscription();
        System.assert(controller.getIsSubCancellationRequired());

        //success with no refund
        pr.getParameters().put('subscriptionId', SUBSCRIPTION_ID+'_norefund');
        controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(lstZSubscriptions.get(1)));
        controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
        controller.earliestCancellationDate = Date.today();
        controller.SelectedItem = controller.SELECT_OPTION_2;
        controller.cancelSubscription();
        System.debug('Messages: ' + ApexPages.getMessages());
        System.assert(controller.mppSuccessReport.contains('There was no refund from MPP.'), controller.mppSuccessReport);

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 22/04/2016
    Function - test positive (with errors) scenarios of cancelling Subscription
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelSubscriptionPositive_WithErrors() {

        TestDataUtility tdu = new TestDataUtility(1);
        //create test data
        tdu.deleteApplicationSettings();
        tdu.deleteSAMHTTPSettings();
        tdu.deleteGeneralSettings();
        tdu.deletePlaneURLSettings();
        tdu.CreateGracePeriodValueSetting();
        tdu.createDigitalMPPTransactionHistory(null);
        tdu.lstMPPTransactionHistory[0].Order_Id__c = '1234567';
        update tdu.lstMPPTransactionHistory[0];

        tdu.lstDigitalSubscribers[0].MPP_Service_Id__c = '12345';
        update tdu.lstDigitalSubscribers[0];

        Zuora__CustomerAccount__c billingAccount = TestDataUtility.newZuoraCustomerAccount(0, tdu.lstDigitalSubscribers[0].Id);
        insert billingAccount;

        List<Zuora__Subscription__c> lstZSubscriptions = new List<Zuora__Subscription__c>();
        lstZSubscriptions.add(createTestZuoraSubscription(null,                       SUBSCRIPTION_NAME,     tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        lstZSubscriptions.add(createTestZuoraSubscription(SUBSCRIPTION_ID+'_zhcfail', SUBSCRIPTION_NAME+'2', tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        lstZSubscriptions.add(createTestZuoraSubscription(SUBSCRIPTION_ID+'_rfail',   SUBSCRIPTION_NAME+'3', tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        lstZSubscriptions.add(createTestZuoraSubscription(SUBSCRIPTION_ID+'_hcfail',  SUBSCRIPTION_NAME+'4', tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        lstZSubscriptions.add(createTestZuoraSubscription(SUBSCRIPTION_ID+'_rffail',  SUBSCRIPTION_NAME+'5', tdu.lstDigitalSubscribers[0].Id, billingAccount.Id));
        insert lstZSubscriptions;

        TestDataUtility productData = new TestDataUtility(lstZSubscriptions.size());
        productData.createSubscriptionProductCharges();
        productData.createZProducts();

        List<Zuora__SubscriptionProductCharge__c> productChargesToUpdate = new List<Zuora__SubscriptionProductCharge__c>();
        for(Integer i = 0; i < lstZSubscriptions.size(); i++)
            productChargesToUpdate.add(new Zuora__SubscriptionProductCharge__c(Id = productData.lstZuoraSubscriptionProductCharges[i].Id, Zuora__Subscription__c = lstZSubscriptions[i].Id));
        update productChargesToUpdate;

        ZuoraSubscriptionCancellationController controller;
        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);
        Z_TestFactory.createZuoraInvoiceItemTestRecord = false;

        Test.startTest();

            //Zuora hard cancel fail
            Z_TestFactory.testAmendmentSuccess = false;
            ZuoraSubscriptionCanceller.errorMessage = '';
            controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(lstZSubscriptions.get(1)));
            controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
            controller.earliestCancellationDate = Date.today();
            controller.SelectedItem = controller.SELECT_OPTION_2;
            controller.cancelSubscription();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Remove_Zuora_Subscription_Error), ApexPages.getMessages());
            Z_TestFactory.testAmendmentSuccess = true;

            //MPP reactivation fail
            controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(lstZSubscriptions.get(2)));
            controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
            controller.earliestCancellationDate = Date.today();
            controller.SelectedItem = controller.SELECT_OPTION_2;
            controller.cancelSubscription();
            System.assert(controller.mppErrorReport.contains(Label.Reactivate_Subscription_Error), controller.mppErrorReport);

            //MPP hard cancel fail
            controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(lstZSubscriptions.get(3)));
            controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
            controller.earliestCancellationDate = Date.today();
            controller.SelectedItem = controller.SELECT_OPTION_2;
            controller.cancelSubscription();
            System.assert(controller.mppSuccessReport.contains(Label.Subscription_Successfully_Reactivated_MPP), controller.mppSuccessReport);
            System.assert(controller.mppErrorReport.contains(Label.Remove_Subscription_Error), controller.mppErrorReport);

            //MPP refund fail
            controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(lstZSubscriptions.get(4)));
            controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
            controller.earliestCancellationDate = Date.today();
            controller.SelectedItem = controller.SELECT_OPTION_2;
            controller.cancelSubscription();
            System.assert(controller.mppSuccessReport.contains(Label.Subscription_Successfully_Reactivated_MPP), controller.mppSuccessReport);
            System.assert(controller.mppSuccessReport.contains(Label.Subscription_Successfully_Removed_MPP), controller.mppSuccessReport);
            System.assert(controller.mppErrorReport.contains(Label.Refund_Error_Msg), controller.mppErrorReport);

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 31/01/2017
    Test Go Back button
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void goBackTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));

        //test for default user
        PageReference pr = controller.goBack();
        System.assert(pr.getURL().contains(controller.zSubscriptionRecord.Id));

        //test for TMG Standard User
        List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = :Constants.PROFILE_TMG_STANDARD_USER];
        User tmgStdUser = TestDataUtility.newUser(0, lstProfile[0].Id);
        System.runAs(tmgStdUser){
            pr = controller.goBack();
            System.assert(pr.getURL().contains(controller.sfdcAccountId));
        }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to make sure that correct message is displayd if cancellation reason is missing
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelZuoraSubscriptionReasonRequiredTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        controller.selectedItem = controller.SELECT_OPTION_1;
        controller.cancelSubscription();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Cancellation_Reason_Required_Error_Message), ApexPages.getMessages());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to make sure that correct message is displayd if cancellation sub-reason is missing
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelZuoraSubscriptionSubReasonRequiredTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        controller.selectedItem = controller.SELECT_OPTION_1;
        controller.subscriptionObj.Cancellation_Reason__c = Constants.SUBSCRIPTION_CANCELLATION_REASON_PRICE;
        controller.cancelSubscription();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Sub_Cancellation_Reason_Required_Error_Message), ApexPages.getMessages());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to test zuora subscription cancellation failure
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelZuoraSubscriptionFailureTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        controller.selectedItem = controller.SELECT_OPTION_1;
        Z_TestFactory.testAmendmentSuccess = false;
        controller.cancelSubscription();
        System.assert(!controller.isSuccessfullCancellation, ApexPages.getMessages()+controller.popUpText);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to test zuora subscription cancellation functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelZuoraSubscriptionEndOfTermTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(controller.eligibleForCancellation, ApexPages.getMessages());
        System.assert(!controller.subscriptionEligibleMigratedHardCancellation, ApexPages.getMessages()+controller.popUpText);
        controller.selectedItem = controller.SELECT_OPTION_1;
        controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
        controller.cancelSubscription();
        System.assert(controller.isSuccessfullCancellation, ApexPages.getMessages()+controller.popUpText);
        System.assert(controller.popUpText.contains(Label.Zuora_Subscription_Canceller_Successful_Cancellation), ApexPages.getMessages()+controller.popUpText);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to test zuora subscription cancellation functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelZuoraSubscriptionTodayTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(controller.eligibleForCancellation, ApexPages.getMessages());
        System.assert(!controller.subscriptionEligibleMigratedHardCancellation, ApexPages.getMessages()+controller.popUpText);
        controller.selectedItem = controller.SELECT_OPTION_2;
        controller.getItems();
        controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
        controller.cancelSubscription();
        System.assert(controller.isSuccessfullCancellation, ApexPages.getMessages()+controller.popUpText);
        System.assert(controller.popUpText.contains(Label.Zuora_Subscription_Canceller_Successful_Cancellation), ApexPages.getMessages()+controller.popUpText);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to test zuora subscription cancellation functionality
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void cancelZuoraSubscriptionSpecificDateTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assert(controller.eligibleForCancellation, ApexPages.getMessages());
        System.assert(!controller.subscriptionEligibleMigratedHardCancellation, ApexPages.getMessages());
        controller.selectedItem = controller.SELECT_OPTION_3;
        controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
        Date dt = Date.today().addDays(1);
        controller.datename = String.valueOf(dt.day()) + '/' + String.valueOf(dt.month()) + '/' + String.valueOf(dt.year());
        controller.cancelSubscription();
        System.assert(controller.isSuccessfullCancellation, ApexPages.getMessages()+controller.popUpText);
        System.assert(controller.popUpText.contains(Label.Zuora_Subscription_Canceller_Successful_Cancellation), ApexPages.getMessages()+controller.popUpText);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method for initial page load with the following parameters
                    @subsscriptionStartDate = today
                    @Application_Setting.GracePeriodDuration = 0
                    NOTE: seeAllData=true is required by Zuora API calls to generate test data
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void testSubscriptionCancelationInGracePeriod_1(){
        testSetup();
        Test.startTest();
        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);
        Date subscriptionStartDate = Date.today();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Zuora__SubscriptionStartDate__c = subscriptionStartDate;
        update zSubscription;
        setGracePeriodValue('0');
        System.assertEquals('0', getGracePeriodValue(), 'Grace period custom setting record was not updated to 0');
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assertEquals(SUBSCRIPTION_ID, controller.zSubscriptionId, 'Subsription id was not set as expected');
        controller.SelectedItem = controller.SELECT_OPTION_3;
        System.assertEquals(TMGUtil.convertDateToString(Date.today().addDays(-1)), controller.datename, 'Initial date is expected to be set as yesterdays day');
        System.assert(controller.isSubscriptionInGracePeriod, 'Subscription is expected to be in grace period');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method for preview functionality once option 3 is selected with the following parameters
                    @subsscriptionStartDate = before a month
                    @Application_Setting.GracePeriodDuration = 14
                    @cancellationDate = today 
                    NOTE: seeAllData=true is required by Zuora API calls to generate test data
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void testSubscriptionCancelationInGracePeriod_2(){
        testSetup();
        Test.startTest();
        //Subscription started month ago, and is outside grace period and canceletion date is set to today
        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);

        Date subscriptionStartDate = Date.today().addMonths(-1);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Zuora__SubscriptionEndDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Zuora__SubscriptionStartDate__c = subscriptionStartDate;
        update zSubscription;

        setGracePeriodValue('14');
        System.assertEquals('14', getGracePeriodValue(), 'Grace period custom setting record was not updated to 14');
        Z_TestFactory.testSubscriptionStartDate = subscriptionStartDate;

        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assertEquals(SUBSCRIPTION_ID, controller.zSubscriptionId, 'Subsription id was not set as expected');
        System.assert(!controller.isSubscriptionInGracePeriod, 'Subscription is expected to be outside grace period');
        controller.SelectedItem = controller.SELECT_OPTION_3;
        System.assertEquals(TMGUtil.convertDateToString(Date.today().addDays(-1)), controller.datename, 'Initial date is expected to be set as yesterdays day');
        
        controller.datename = TMGUtil.convertDateToString(Date.today());
        controller.previewCancellation();

        String notExpectedErrorMessages = getDateRangeErrorMessage(subscriptionStartDate, zSubscription.Zuora__SubscriptionEndDate__c);
        System.assert(!TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), notExpectedErrorMessages),
                            'The following error message should not appear: ' + notExpectedErrorMessages);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method for preview functionality once option 3 is selected with the following parameters
                    @subsscriptionStartDate = before a month
                    @Application_Setting.GracePeriodDuration = 0
                    @cancellationDate = today 
                    NOTE: seeAllData=true is required by Zuora API calls to generate test data
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void testSubscriptionCancelationInGracePeriod_3(){
        testSetup();
        Test.startTest();
        //Subscription is outside grace  period, grace period is equal to 0, subscription start date and cancellation date is set to today

        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);

        Date subscriptionStartDate = Date.today().addMonths(-1);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Zuora__SubscriptionEndDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Zuora__SubscriptionStartDate__c = subscriptionStartDate;
        update zSubscription;

        setGracePeriodValue('0');
        System.assertEquals('0', getGracePeriodValue(), 'Grace period custom setting record was not updated to 0');
        Z_TestFactory.testSubscriptionStartDate = subscriptionStartDate;

        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assertEquals(SUBSCRIPTION_ID, controller.zSubscriptionId, 'Subsription id was not set as expected');
        System.assert(!controller.isSubscriptionInGracePeriod, 'Subscription is expected to be outside grace period');
        controller.SelectedItem = controller.SELECT_OPTION_3;

        System.assertEquals(TMGUtil.convertDateToString(Date.today().addDays(-1)), controller.datename, 'Initial date is expected to be set as yesterdays day');
        controller.datename = TMGUtil.convertDateToString(Date.today());
        controller.previewCancellation();

        String notExpectedErrorMessages = getDateRangeErrorMessage(subscriptionStartDate, zSubscription.Zuora__SubscriptionEndDate__c);

        System.assert(!TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), notExpectedErrorMessages),
                            'The following error message should not appear: ' + notExpectedErrorMessages);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 28/06/2016
    Function - test method for preview functionality once option 3 is selected with the following parameters
                    @subsscriptionStartDate = before a month
                    @Application_Setting.GracePeriodDuration = 14
                    @cancellationDate = tomorrow 
                    NOTE: seeAllData=true is required by Zuora API calls to generate test data
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void testSubscriptionCancelationInGracePeriod_4(){
        testSetup();
        //Subscription cancellation date is set to the future date
        Test.startTest();
        PageReference pr = Page.ZuoraSubscriptionCancellation;
        Test.setCurrentPage(pr);

        Date subscriptionStartDate = Date.today().addMonths(-1);
        Zuora__Subscription__c zSubscription = [ SELECT Id, Zuora__SubscriptionEndDate__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        zSubscription.Zuora__SubscriptionStartDate__c = subscriptionStartDate;
        update zSubscription;

        setGracePeriodValue('14');
        System.assertEquals('14', getGracePeriodValue(), 'Grace period custom setting record was not updated to 14');
        Z_TestFactory.testSubscriptionStartDate = subscriptionStartDate;

        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        System.assertEquals(SUBSCRIPTION_ID, controller.zSubscriptionId, 'Subsription id was not set as expected');
        System.assert(!controller.isSubscriptionInGracePeriod, 'Subscription is expected to be outside grace period');
        controller.SelectedItem = controller.SELECT_OPTION_3;

        controller.datename = TMGUtil.convertDateToString(zSubscription.Zuora__SubscriptionEndDate__c.addDays(1));
        controller.subscriptionObj.Cancellation_Reason__c = CANCELLATION_REASON;
        controller.cancelSubscription();
        String expectedErrorMessages = getDateRangeErrorMessage(subscriptionStartDate, zSubscription.Zuora__SubscriptionEndDate__c);

        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), expectedErrorMessages), ApexPages.getMessages());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 26/04/2017
    Function - method to test changePromoBool method
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void changePromoBoolTest(){
        testSetup();
        Test.startTest();
        Zuora__Subscription__c zSubscription = [ SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :SUBSCRIPTION_ID LIMIT 1 ];
        ZuoraSubscriptionCancellationController controller = new ZuoraSubscriptionCancellationController(new ApexPages.StandardController(zSubscription));
        controller.selectedItem = controller.SELECT_OPTION_3;
        controller.changePromoBool();
        System.assertEquals(0, controller.previewedCancellationAmount, ApexPages.getMessages());
        System.assert(!controller.promoBool, ApexPages.getMessages());
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 30/07/2016
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
    public static String getDateRangeErrorMessage(Date subscriptionStartDate, Date subscriptionEndDate){
        String[] labelParameters = new String[]{TMGUtil.convertDateToString(subscriptionStartDate), TMGUtil.convertDateToString(subscriptionEndDate)};
        return String.format(Label.Zuora_Subscription_Canceller_Cancellation_Date_Out_Of_Range, labelParameters);
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 27/04/2017
    Function - method to create test zuora subscription record
    #############Change Log#############
    Modified by     Version     Change Date   
    ****************************************************************************************/
    public static Zuora__Subscription__c createTestZuoraSubscription(String zuoraId, String subNumber, String accId, String billAccId){
        return new Zuora__Subscription__c(
            Zuora__Zuora_Id__c              = zuoraId, 
            Name                            = subNumber, 
            Zuora__SubscriptionNumber__c    = subNumber, 
            Zuora__NextChargeDate__c        = NEXT_CHARGE_DATE, 
            Zuora__Version__c               = 1, 
            Zuora__Status__c                = 'Active', 
            Zuora__Account__c               = accId, 
            Zuora__CustomerAccount__c       = billAccId, 
            Zuora__InvoiceOwner__c          = billAccId,
            Zuora__SubscriptionStartDate__c = Date.today(),
            Zuora__SubscriptionEndDate__c   = Date.today().addYears(1));
    }
}