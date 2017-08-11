/**
Name: OapSubscriptionTMGTest
* @author Wiktor Czykin
* @date 19/10/2015
* @description Test class for OapSubscriptionTMG - old class fully rewritten
##########Change Log##########
Modified by         Version     Change Date
Cristina Anghenie   1.1         16/11/2015  //add new method to test InitializeDigitalPaymentMap method
Pawel Chrzanowski   1.2         02/03/2016  //added new method to test displayDuplicateErrorMessage()
Pawel Chrzanowski   1.3         22/03/2016  //added tests for iFrame methods
Wiktor Czykin       1.4         12/05/2016  //modified email change iframe related tests to fit with Oap product changes
Pawel Chrzanowski   1.5         25/05/2016  //added missing coverage for new methods
Gavin Palmer        1.6         17/06/2016  //added getAccountFromPOCWithoutEmailOrTSTest() and getAccountFromPOCWithEmailTest()
Wiktor Czykin       1.7         06/09/2016  //added methods related to delivery type; removed/updated ones that used amended methods
Wiktor Czykin       1.8         01/11/2016  //added testChangeProductIdPositive()
Wiktor Czykin       1.9         17/11/2016  //added testSaveAndTakePaymentOnNonLowStartTCode_Positive()
*/
@isTest
private class OapSubscriptionTMGTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/05/2016
    Version - 1.0
    Function - test initialization of parameters
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         25/05/2016  //added missing coverage for new methods
    ****************************************************************************************/
    private static testMethod void testInitialization(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];
        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            //pr.getParameters().put('mgmGiverId', 'giverId');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_RETAILERID, td.lstRetailers[0].RET_ID__c);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            ost.createNewBatch = null;
            ost.chequeBatchSelected = null;
            ost.customerFullName = null;
            ost.customerFullAddress = null;
            ost.emailToPassToCC = null;
            ost.totalPriceToPassToPaymentProvider = null;
            ost.agencyPrice= null;
            ost.incentiveSelection = new List<SelectOption>();
            ost.incentive = null;
            ost.successMessagePart3 = null;
            ost.mgmPrompt = null;
            ost.mgmValue = null;
            ost.digitalMonthlyOpenOfferPrice = null;
            ost.digitalYearlyOpenOfferPrice = null;
            System.assert(!ost.bShowPricesType);
            ost.paymentValues.add(new OapSubscriptionTMG.PaymentValues(10.0, 'test', 52));
            System.assert(ost.bShowPricesType);
            System.assertEquals(td.lstTCodeManagement[0].Name, ost.tCode);
            System.assertEquals(td.lstTCodeManagement[0].Id, ost.currentCampaign.Id);
            System.assert(ost.bRenderForm);
            System.assertEquals(Constants.PRODUCT_PREMIUM, ost.selectedProduct);
            System.assertEquals(td.lstZproducts[0].Id, ost.productId);
            System.assertEquals(td.lstZproducts[0].Id, ost.productId);
            System.assertEquals(Constants.DELIVERYTYPE_HND, ost.selectedDelivery);
            System.assert(!ost.showEmailIFrame);
            System.assert(ost.displayRetailerResults);
            System.assertEquals(td.lstRetailers[0].Name, ost.selectedRetailerName);
            System.assertEquals(td.lstRetailers[0].Id, ost.newselectedRetailer);
            System.assertEquals(td.lstRetailers[0].Id, ost.selectedRetailer);
            System.assertEquals(td.lstRetailers[0].BillingPostalCode, ost.retailerPostalCode);
            System.assert(ost.displayOfferSection);
            System.assertNotEquals(null, ost.subscriber);
            System.assertNotEquals(null, ost.subscription);
            System.assertNotEquals(null, ost.cheque);
            System.assertEquals(2, ost.chequeBatchOptions.size());
            System.assertEquals(UserInfo.getUserId(), ost.agentUserId);
            System.assertEquals(td.lstTCodeProducts[0].Id, ost.currentTCodeProduct.Id);
            System.assertEquals(30, ost.price_13week);
            ost.currentTCodeProduct.X13_Week_Price__c = 15;
            System.assertEquals(ost.currentTCodeProduct.X13_Week_Price__c, ost.price_13week);

            pr.getParameters().remove(OapSubscriptionTMG.PARAM_PRODUCTID);
            General__c g = new General__c(Name=Constants.GENERAL_DEFAULT_PRODUCT_ID, Value__c=null);
            insert g;
            ost = new OapSubscriptionTMG();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Product_Not_Selected_Or_Passed_Message));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 06/09/2016
    Version - 1.0
    Function - test initialization of parameters - auto switch to OTC
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testInitializationWithRetailerWhenProductDoesNotSupportHND(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];

        td.lstZproducts[0].Voucher_Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        update td.lstZproducts;
        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_RETAILERID, td.lstRetailers[0].RET_ID__c);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assertEquals(Constants.PRODUCT_PREMIUM, ost.selectedProduct);
            System.assertEquals(td.lstZproducts[0].Id, ost.productId);
            System.assertEquals(Constants.DELIVERYTYPE_OTC, ost.selectedDelivery);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Not_matching_delivery_type));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 06/09/2016
    Version - 1.0
    Function - test initialization of parameters - default HND where no OTC on product
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testInitializationWithoutRetailerWhenProductDoesNotSupportOTC(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];

        td.lstZproducts[0].Voucher_Delivery_Type__c = Constants.DELIVERYTYPE_HND;
        update td.lstZproducts;
        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assertEquals(Constants.PRODUCT_PREMIUM, ost.selectedProduct);
            System.assertEquals(td.lstZproducts[0].Id, ost.productId);
            System.assertEquals(Constants.DELIVERYTYPE_HND, ost.selectedDelivery);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 06/09/2016
    Version - 1.0
    Function - test initialization of parameters - warning for HND sub where product is otc only
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testInitializationWithSubscriptionAndRetailerWhenProductDoesNotSupportHND(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];
        List<Account> lstAccount = [select Id, Subscriber_Number_static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        System.assert(String.isNotBlank(lstAccount[0].Subscriber_Number_static__c));
        td.lstZproducts[0].Voucher_Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        update td.lstZproducts;

        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_RETAILERID, td.lstRetailers[0].RET_ID__c);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TSNUMBER, lstAccount[0].Subscriber_Number_static__c);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assertEquals(Constants.PRODUCT_PREMIUM, ost.selectedProduct);
            System.assertEquals(td.lstZproducts[0].Id, ost.productId);
            System.assertEquals(Constants.DELIVERYTYPE_OTC, ost.selectedDelivery);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Not_matching_delivery_type));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date -25/05/2016
    Function - test setDefaultValues() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSetDefaultValues(){
        TestDataUtility td = new TestDataUtility(1);
        SubscriptionTriggerHandler.getInstance().isExecuting = true;
        AccountTriggerHandler.getInstance().isExecuting = true;
        td.createSubscriptions();
        SubscriptionTriggerHandler.getInstance().isExecuting = false;
        AccountTriggerHandler.getInstance().isExecuting = false;
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        Test.setCurrentPage(pr);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.subscriptionId = td.lstSubscriptions[0].Id;
        ost.setDefaultValues();
        System.assertEquals(null, ost.lstFrequencies);
        System.assertEquals(null, ost.preferedStartPaymentDate);
        System.assert(ost.bRenderIncentives);

        ost.bIsBack = true;
        ost.setDefaultValues();
        System.assertEquals('52weeks', ost.subscriptionType);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date -24/05/2016
    Version - 1.0
    Function - test default product is picked up from custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testDefaultProduct(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProducts();
        General__c g = new General__c(Name = Constants.GENERAL_DEFAULT_PRODUCT_ID, Value__c = td.lstZproducts[0].Id);
        insert g;
        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assertEquals(Constants.PRODUCT_PREMIUM, ost.selectedProduct);
            System.assert(ApexPages.getMessages().isEmpty(), ApexPages.getMessages());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/10/2015
    Version - 1.0
    Function - test initialization of parameters - error missing tcode param
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testNoTCodeParamFailure(){
        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_tcode_detected));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/10/2015
    Version - 1.0
    Function - test initialization of parameters - error missing tcode data
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testNoTCodeFoundWithParamFailure(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeManagement();
        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put('tcode','notValidTCodeName');
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_TCode_not_available));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 22/03/2016
    Version - 1.1
    Function - test iFrame methods success
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/05/2016  //fixed initialization of the test case to work with new OAP contructor
    ****************************************************************************************/
    private static testMethod void testIFrameMethodsSuccess(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProducts();
        td.createSubscriptions();

        List<Account> lstAcc = [select Subscriber_Number_static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        PageReference pr = Page.OapSubscriptionTMG;
        Map<String, String> mapParams = pr.getParameters();
        mapParams.put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
        mapParams.put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstTCodeProducts[0].Product__c);
        mapParams.put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TSNUMBER, lstAcc[0].Subscriber_Number_static__c);

        Test.startTest();
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            System.assert(!ost.showEmailIFrame);

            ost.displayChangeEmailIFrame();
            System.assert(ost.showEmailIFrame);

            ost.hideChangeEmailIFrame();
            System.assert(!ost.showEmailIFrame);

            ost.showEmailIFrame = true;
            ost.refetchSubscriberEmail();
            System.assert(!ost.showEmailIFrame);
            System.assertEquals(td.lstIndividualSubscribers[0].PersonEmail, ost.subscriber.PersonEmail);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 22/03/2016
    Version - 1.1
    Function - test iFrame methods fail
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/05/2016  //fixed initialization of the test case to work with new OAP contructor
    ****************************************************************************************/
    private static testMethod void testIFrameMethodsFail(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProducts();

        PageReference pr = Page.OapSubscriptionTMG;
        Map<String, String> mapParams = pr.getParameters();
        mapParams.put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
        mapParams.put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstTCodeProducts[0].Product__c);
        mapParams.put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);

        Test.startTest();
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();
            ost.refetchSubscriberEmail();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Account_refetch_error_update));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test getOfferOptions() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetOfferOptions(){
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.orderMethod = Constants.DIRECTION_OUTBOUND;
        System.assertEquals(4, ost.getOfferOptions().size());
        ost.orderMethod = null;
        System.assertEquals(null, ost.getOfferOptions());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test getPromoOutbound() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetPromoOutbound(){
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.orderMethod = Constants.DIRECTION_OUTBOUND;
        System.assertEquals(2, ost.getPromoOutbound().size());
        ost.orderMethod = null;
        System.assertEquals(null, ost.getPromoOutbound());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test retrieveAllRetailers() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testRetrieveAllRetailers(){
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.debug('### testRetrieveAllRetailers: ' + ost.retrieveAllRetailers());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test selectRetailer() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSelectRetailer(){
        TestDataUtility td = new TestDataUtility(1);
        td.createRetailers();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.selectRetailer();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_retailers_found_error));

        ost.selectedRetailer = td.lstRetailers[0].Id;
        ost.selectRetailer();
        System.assertEquals(td.lstRetailers[0].Name, ost.selectedRetailerName);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test getPOCAccount() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetPOCAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createPOCs(1);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        try{
            ost.getPOCAccount(null);
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_POC_code_not_in_URL, e.getMessage());
        }

        try{
            ost.getPOCAccount('test');
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_POC_not_found, e.getMessage());
        }

        Account acc = new Account(Name='test', POC__c='test');
        insert acc;
        try{
            ost.getPOCAccount('test');
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_POC_code_already_used, e.getMessage());
        }

        System.assertEquals(td.lstTCodeManagement[0].Name, ost.getPOCAccount(td.lstPOCs[0].POC_ID__c));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test setSelectedDelivery() method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         06/09/2016  //modified to fit with the code changes
    ****************************************************************************************/
    private static testMethod void testSetSelectedDelivery(){
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.selectedDelivery = Constants.DELIVERYTYPE_OTC;
        System.assert(!ost.displayRetailers);
        ost.selectedDelivery = 'test';
        System.assert(ost.displayRetailers);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test setReadershipValues() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSetReadershipValues(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        Test.setCurrentPage(pr);
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.tmgReadershipFreq = 'test';
        ost.tmgSundayReadershipFreq = 'test';
        ost.oppositionTitle = 'test';
        ost.oppositionSundayTitle = 'test';
        ost.oppositionTitleFrequency = 'test';
        ost.oppositionSundayTitleFrequency = 'test';
        ost.setReadershipValues();

        System.assertEquals('test', ost.subscriber.OppositionTitle__c);
        System.assertEquals('test', ost.subscriber.OppositionSundayTitle__c);
        System.assertEquals(0, ost.subscriber.Opposition_Title_Frequency__c);
        System.assertEquals(0, ost.subscriber.Opposition_Sunday_Title_Frequency__c);
        System.assertEquals(0, ost.subscriber.Telegraph_Sunday_Readership_Frequency__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test checkSelectedOffer() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCheckSelectedOffer(){
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.selectedOfferOptions = 'test';
        ost.checkSelectedOffer();
        System.assertEquals(Label.Offline_Acquisition_Create_subscription_button, ost.saveBtnName);

        ost.selectedOfferOptions = 'None';
        ost.checkSelectedOffer();
        System.assertEquals(Label.Offline_Acquisition_Save_and_take_payment_button, ost.saveBtnName);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test populateFrequencies() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPopulateFrequencies(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.populateFrequencies();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test saveAndTakePayment() method, negative scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveAndTakePayment_Negative(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];
        td.lstTCodeManagement[0].Payment_Type__c = 'Allow 52 Week CCA';
        update td.lstTCodeManagement[0];
        Test.startTest();

            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_RETAILERID, td.lstRetailers[0].RET_ID__c);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();

            //duplicate PersonEmail
            Account acc = new Account(LastName='test', PersonEmail='test@test.com');
            insert acc;
            ost.subscriber.PersonEmail = 'test@test.com';
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Email_duplicate_error));

            //Digital Product and no PersonEmail
            ost.subscriber.PersonEmail = null;
            ost.selectedProduct = Constants.PRODUCT_DIGITAL;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_Email_error));

            //missing subscriber FirstName
            ost.subscriber.PersonEmail = 'unique@test.com';
            ost.subscriber.FirstName = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'An error occurred during payment. Please contact the system administrator'));

            //invalid subscriber FirstName
            ost.subscriber.FirstName = 'test#$%';
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_First_name_validation));

            //invalid subscriber FirstName
            ost.subscriber.FirstName = 'test';
            ost.subscriber.LastName = 'test#$%';
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Last_name_validation));

            //invalid subscriber PersonMobilePhone
            ost.subscriber.LastName = 'test';
            ost.subscriber.PersonMobilePhone = '12345';
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Mobile_number_validation));

            //invalid subscriber PersonHomePhone
            ost.subscriber.PersonMobilePhone = '01234567';
            ost.subscriber.PersonHomePhone = '12345a';
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Phone_number_validation));

            //invalid preferedStartDate
            ost.subscriber.PersonHomePhone = '01234567';
            ost.selectedProduct = Constants.PRODUCT_PREMIUM;
            ost.preferedStartDate = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Voucher_start_date_validation));

            //invalid subscriptionType
            ost.preferedStartDate = ost.preferredStartDatesList.get(1).getValue();
            ost.subscriptionType = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Subscription_duration_validation));

            //invalid paymentFrequency
            ost.subscriptionType = Constants.SUBSCRIPTIONTYPE_26CONTINUOUS;
            ost.paymentType = Constants.SUB_ACQUISITION_PAYMENT_CC;
            ost.paymentFrequency = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Only_monthly_frequency_for_continuous_credit_card_payments));

            //no PersonEmail
            ost.paymentFrequency = Constants.DD_COL_FREQ_MONTHLY;
            ost.selectedOfferOptions = Constants.OFFEROPTION_EMAIL;
            ost.subscriber.PersonEmail = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Email_address_validation_for_offer_options));

            //no paymentType
            ost.subscriber.PersonEmail = 'unique@test.com';
            ost.paymentType = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Payment_type_validation));

            //no paymentFrequency
            ost.paymentType = Constants.SUB_ACQUISITION_PAYMENT_DD;
            ost.selectedProduct = Constants.PRODUCT_PREMIUM;
            ost.paymentFrequency = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Payment_frequency_validation_for_DD_payment));

            //no newselectedRetailer
            ost.paymentFrequency = Constants.DD_COL_FREQ_MONTHLY;
            ost.selectedDelivery = Constants.DELIVERYTYPE_OTC;
            ost.saveAndTakePayment();
            System.assert(String.isBlank(ost.newselectedRetailer));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_payment_config));

            ost.selectedDelivery = Constants.DELIVERYTYPE_HND;
            ost.newselectedRetailer = null;
            ost.saveAndTakePayment();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Retailer_required_for_home_delivery_subscription));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test saveAndTakePayment() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveAndTakePayment_Positive(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];
        td.lstTCodeManagement[0].Payment_Type__c = 'Allow 52 Week CCA';
        update td.lstTCodeManagement[0];
        Test.startTest();

            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_RETAILERID, td.lstRetailers[0].RET_ID__c);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();

            ost.subscriber.PersonEmail = 'test@test.com';
            ost.subscriber.FirstName = 'test';
            ost.subscriber.LastName = 'test';
            ost.subscriber.PersonMobilePhone = '01234567';
            ost.subscriber.PersonHomePhone = '01234567';
            ost.selectedProduct = Constants.PRODUCT_PREMIUM;
            ost.preferedStartDate = ost.preferredStartDatesList.get(1).getValue();
            ost.paymentType = Constants.SUB_ACQUISITION_PAYMENT_CC;
            ost.paymentFrequency = Constants.DD_COL_FREQ_MONTHLY;
            ost.selectedDelivery = Constants.DELIVERYTYPE_OTC;

            System.assertEquals('internal', ost.saveAndTakePayment().getParameters().get('requestorigin'));
            ost.updateAndLinkSAMAccount();
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test setSalutation() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSetSalutation(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.otherTitle = 'test';
        ost.setSalutation();
        System.assertEquals('test', ost.subscriber.Salutation);
        System.assertEquals('test', ost.subscriber.Title__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test setSubscriberEntitlementFlags() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSetSubscriberEntitlementFlags(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.selectedProduct = Constants.PRODUCT_DIGITAL;
        ost.setSubscriberEntitlementFlags();
        System.assert(ost.subscriber.iPadAccess__c);
        System.assert(ost.subscriber.smartphoneAccess__c);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test sendOfferCommunication() method - negative scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSendOfferCommunication_Negative(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);
        OapSubscriptionTMG ost = new OapSubscriptionTMG();

        ost.selectedOffer = Constants.OFFER_LOWSTART;
        ost.subscriber.Salutation = 'Mr';
        ost.subscriber.FirstName = 'test';
        ost.subscriber.LastName = 'test';
        ost.sendOfferCommunication(null, null);

        OapSubscriptionTMG.PaymentValues pValues = new OapSubscriptionTMG.PaymentValues(10.0, 'test', 52);
        OapSubscriptionTMG.PaymentConfig pConfig = new OapSubscriptionTMG.PaymentConfig('config', 10);

        try{
            ost.sendOfferCommunication(new List<OapSubscriptionTMG.PaymentValues>{pValues}, pConfig);
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_Offer_communication_cover_price_error, e.getMessage());
        }

        SubManagementDefaults__c subMD = new SubManagementDefaults__c(DefaultValue__c='test', ID__c='CoverPrice');
        insert subMD;
        try{
            ost.sendOfferCommunication(new List<OapSubscriptionTMG.PaymentValues>{pValues}, pConfig);
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_Offer_communication_cover_price_error, e.getMessage());
        }

        subMD.DefaultValue__c = '10';
        update subMD;
        try{
            ost.sendOfferCommunication(new List<OapSubscriptionTMG.PaymentValues>{pValues}, pConfig);
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_Offer_communication_email_content_error, e.getMessage());
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test sendOfferCommunication() method - positive scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSendOfferCommunication_Positive(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);
        OapSubscriptionTMG ost = new OapSubscriptionTMG();

        ost.selectedOfferOptions = Constants.OFFEROPTION_EMAIL;
        ost.subscriber.Salutation = 'Mr';
        ost.subscriber.FirstName = 'test';
        ost.subscriber.LastName = 'test';
        ost.subscriber.PersonEmail = 'unique@test.com';

        OapSubscriptionTMG.PaymentValues pValues = new OapSubscriptionTMG.PaymentValues(5.0, 'test', 52);
        OapSubscriptionTMG.PaymentValues pValues2 = new OapSubscriptionTMG.PaymentValues(10.0, 'test', 52);
        OapSubscriptionTMG.PaymentValues pValues3 = new OapSubscriptionTMG.PaymentValues(10.0, Label.Offline_Acquisition_Low_Start, 52);
        OapSubscriptionTMG.PaymentConfig pConfig = new OapSubscriptionTMG.PaymentConfig('config', 10);
        pConfig.iLowStartDuration = 5;
        pConfig.dWeeklyLowStartPrice = 5.0;
        pConfig.dWeeklyPrice = 10.0;
        insert new SubManagementDefaults__c(DefaultValue__c='10', ID__c='CoverPrice');
        insert new SubManagementDefaults__c(DefaultValue__c='agency@test.com', ID__c='DefaultAgencyEmail');
        insert new Document(Name='DD Mandate', FolderId=UserInfo.getUserId());

        //lowstart
        ost.selectedOffer = Constants.OFFER_LOWSTART;
        ost.sendOfferCommunication(new List<OapSubscriptionTMG.PaymentValues>{pValues, pValues2}, pConfig);

        //staff
        ost.subscriber.PersonMailingState = 'test';
        ost.selectedOffer = Constants.OFFER_STAFF;
        ost.selectedOfferOptions = Constants.OFFEROPTION_COUPON;
        ost.sendOfferCommunication(new List<OapSubscriptionTMG.PaymentValues>{pValues, pValues2}, pConfig);

        ost.selectedOfferOptions = Constants.OFFEROPTION_BOTH;
        ost.sendOfferCommunication(new List<OapSubscriptionTMG.PaymentValues>{pValues, pValues2}, pConfig);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test getCountries() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetCountries(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadCountryCodes();

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.assert(!ost.getCountries().isEmpty());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test changeProductId() method - negative scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testChangeProductIdNegative(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);
        OapSubscriptionTMG ost = new OapSubscriptionTMG();

        try{
            ost.changeProductId(null);
        }catch(Exception e){
            System.assertEquals('Product switch functionality returned null value.', e.getMessage());
        }

        try{
            ost.changeProductId(td.lstZproducts[1].Id);
        }catch(Exception e){
            System.assertEquals('Failed to identify tcode product configuration.', e.getMessage());
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 01/11/2016
    Function - test changeProductId() method - positive scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testChangeProductIdPositive(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        Test.setCurrentPage(pr);
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.updateIncentives(); 
        TCode_Product__c tp = TestDataUtility.newTCodeProduct(td.lstZproducts[1].Id, td.lstTCodeManagement[0].Id);
        insert tp;

        TCode_Product_Incentive__c tpi = TestDataUtility.newTCodeProductIncentive(3, td.lstIncentives[1].Id, tp.Id, td.lstTCodeProductIncentives[0].Subscription_Type__c);
        insert tpi;

        System.assertEquals(td.lstZproducts[0].Id, ost.productId);
        System.assertEquals(td.lstIncentives[0].Id, ost.lstActiveIncentives[0].getValue());
        Test.startTest();
            ost.changeProductId(td.lstZproducts[1].Id);
            System.assertEquals(td.lstZproducts[1].Id, ost.productId);
            System.assertEquals(td.lstIncentives[1].Id, ost.lstActiveIncentives[0].getValue());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test getInterruptedSubscriptionAndIncentives() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetInterruptedSubscriptionAndIncentives(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_OFFERED;
        update td.lstSubscriptions[0];

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.assertEquals(td.lstSubscriptions[0].Id, ost.getInterruptedSubscriptionAndIncentives(td.lstIndividualSubscribers[0].Id));
        System.assertEquals(td.lstSubscriptions[0].Subscription_Duration_Picklist__c + Constants.KEY_ONEOFF, ost.subscriptionType);
    }


    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test getInterruptedSubscriptionAndIncentives() method - restart scenario
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetInterruptedSubscriptionAndIncentives_bIsRestart(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.createTCodeProductIncentives();
        td.lstSubscriptions[0].isContinuous__c = true;
        td.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_OFFERED;
        update td.lstSubscriptions[0];

        insert new SubscriptionIncentiveAssociation__c(Incentive__c=td.lstIncentives[0].Id, Subscriber__c=td.lstIndividualSubscribers[0].Id, Subscription__c=td.lstSubscriptions[0].Id);

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_RESTART, 'true');
        Test.setCurrentPage(pr);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.assertEquals(td.lstSubscriptions[0].Id, ost.getInterruptedSubscriptionAndIncentives(td.lstIndividualSubscribers[0].Id));
        System.assertEquals(td.lstSubscriptions[0].Subscription_Duration_Picklist__c + Constants.KEY_CONTINUOUS, ost.subscriptionType);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test calculatePaymentStartDate() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCalculatePaymentStartDate(){
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.assertEquals('01/07/2016',ost.calculatePaymentStartDate('06/06/2016', '1'));
        System.assertEquals('15/06/2016',ost.calculatePaymentStartDate('10/06/2016', '15'));
        System.assertEquals('15/07/2016',ost.calculatePaymentStartDate('20/06/2016', '15'));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test show13WeekCheckbox() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testShow13WeekCheckbox(){
        TestDataUtility td = new TestDataUtility(1);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.assert(!ost.show13WeekCheckbox());

        td.loadGeneral();
        System.assert(ost.show13WeekCheckbox());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test restoreParametersOnBack() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testRestoreParametersOnBack(){
        TestDataUtility td = new TestDataUtility(1);
        td.createRetailers();
        td.createTCodeProductIncentives();

        Map<String, String> mapParameters = new Map<String, String>();
        mapParameters.put(OapSubscriptionTMG.PARAM_HASBACK, 'true');
        mapParameters.put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
        mapParameters.put(OapSubscriptionTMG.PARAM_PAYMENT_TYPE, Constants.SUB_ACQUISITION_PAYMENT_CC);
        mapParameters.put(OapSubscriptionTMG.PARAM_PAYMENT_FREQUENCY, Constants.DD_COL_FREQ_MONTHLY);
        mapParameters.put(OapSubscriptionTMG.PARAM_INCENTIVEID, td.lstIncentives[0].Id);
        mapParameters.put(OapSubscriptionTMG.PARAM_PAYMENT_START_DATE, '06/06/2016');
        mapParameters.put(OapSubscriptionTMG.PARAM_SFDC_RETAILERID, td.lstRetailers[0].Id);
        mapParameters.put(OapSubscriptionTMG.PARAM_OTHER_TITLE, td.lstRetailers[0].Id);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        System.assert(ost.restoreParametersOnBack(mapParameters));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test initializeProductAndPricing() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testInitializeProductAndPricing(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Low_Start_Period__c = '5';
        update td.lstTCodeManagement[0];

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '9.99');
        pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '6.99');
        Test.setCurrentPage(pr);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.orderMethod = Constants.ORDER_METHOD_COUPON;
        ost.initializeProductAndPricing();
        System.assert(!ost.displayOfferSection);

        ost.orderMethod = Constants.DIRECTION_INBOUND;
        ost.selectedOffer = Constants.OFFER_LOWSTART;
        ost.selectedProduct = Constants.PRODUCT_DIGITAL;
        ost.bRenderForm = false;
        ost.initializeProductAndPricing();
        System.assertEquals(9.99, ost.weeklyPrice);
        System.assertEquals(6.99, ost.weeklyLowStartPrice);

        try{
            ost.selectedOffer = Constants.OFFER_MGM;
            ost.initializeProductAndPricing();
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_No_MGM_giver_id, e.getMessage());
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test initializeDigitalPaymentMap() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testInitializeDigitalPaymentMap(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        Test.setCurrentPage(pr);

        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.currentCampaign = null;
        try{
            ost.initializeDigitalPaymentMap();
        }catch(Exception e){
            System.assertEquals(Label.Offline_Acquisition_TCode_not_available, e.getMessage());
        }

        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.digitalMonthlyOpenOfferPrice = 10.0;
        ost.digitalYearlyOpenOfferPrice = 150.0;
        ost.initializeProductAndPricing();
        ost.initializeDigitalPaymentMap();

        td.lstTCodeManagement[0].Exclude_Digital_Type_For_Flow__c = Constants.SUBSCRIPTIONTYPE_MONTHLY;
        update td.lstTCodeManagement[0];
        ost.initializeDigitalPaymentMap();

        td.lstTCodeManagement[0].Exclude_Digital_Type_For_Flow__c = Constants.SUBSCRIPTIONTYPE_YEARLY;
        update td.lstTCodeManagement[0];
        ost.initializeDigitalPaymentMap();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test initializePremiumPaymentMap() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testInitializePremiumPaymentMap(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadGeneral();
        td.createTCodeProductIncentives();

        PageReference pr = Page.OapSubscriptionTMG;
        pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
        pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
        Test.setCurrentPage(pr);

        td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_13_WEEK_DD;
        update td.lstTCodeManagement[0];
        OapSubscriptionTMG ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.initializePremiumPaymentMap();
        System.assert(ost.mapPaymentConfig.containsKey(Constants.SUBSCRIPTIONTYPE_13CONTINUOUS));

        td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_26_WEEK_DD;
        update td.lstTCodeManagement[0];
        ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.initializePremiumPaymentMap();
        System.assert(ost.mapPaymentConfig.containsKey(Constants.SUBSCRIPTIONTYPE_26CONTINUOUS));

        td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_52_WEEK_DD;
        update td.lstTCodeManagement[0];
        ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.initializePremiumPaymentMap();
        System.assert(ost.mapPaymentConfig.containsKey(Constants.SUBSCRIPTIONTYPE_52CONTINUOUS));

        td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_ONE_OFF_13_WEEK;
        update td.lstTCodeManagement[0];
        ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.initializePremiumPaymentMap();
        System.assert(ost.mapPaymentConfig.containsKey(Constants.SUBSCRIPTIONTYPE_13WEEKS));

       td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_ONE_OFF_26_WEEK;
        update td.lstTCodeManagement[0];
        ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.initializePremiumPaymentMap();
        System.assert(ost.mapPaymentConfig.containsKey(Constants.SUBSCRIPTIONTYPE_26WEEKS));

       td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_ONE_OFF_52_WEEK;
        update td.lstTCodeManagement[0];
        ost = new OapSubscriptionTMG();
        ost.currentCampaign = td.lstTCodeManagement[0];
        ost.initializePremiumPaymentMap();
        System.assert(ost.mapPaymentConfig.containsKey(Constants.SUBSCRIPTIONTYPE_52WEEKS));
    }




    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test OapSubscriptionTMG.PaymentConfig.populateFrequency() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void test_PaymentConfig_PopulateFrequency(){
        OapSubscriptionTMG.PaymentConfig pConfig = new OapSubscriptionTMG.PaymentConfig('config', 10);
        pConfig.iLowStartDuration = 5;
        pConfig.dWeeklyLowStartPrice = 5.0;
        pConfig.dWeeklyPrice = 10.0;

        pConfig.populateFrequency(true);
        System.assertEquals(Constants.DD_COL_FREQ_MONTHLY, pConfig.sDefaultFrequency);

        pConfig.populateFrequency(false);
        System.assertEquals(Constants.DD_COL_FREQ_QUARTERLY, pConfig.sDefaultFrequency);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Function - test OapSubscriptionTMG.PaymentConfig.getSubscriptionTypeOption() method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void test_PaymentConfig_GetSubscriptionTypeOption(){
        OapSubscriptionTMG.PaymentConfig pConfig = new OapSubscriptionTMG.PaymentConfig('config', 10);
        pConfig.iLowStartDuration = 5;
        pConfig.dWeeklyLowStartPrice = 5.0;
        pConfig.dWeeklyPrice = 10.0;

        System.assert(String.isNotBlank(String.valueOf(pConfig.getSubscriptionTypeOption())));
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 17/06/2016
    Function - test getting an account when POC does not have email or TS number
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void getAccountFromPOCWithoutEmailOrTSTest(){
        TestDataUtility testUtility = new TestDataUtility(1);
        testUtility.createPOCs(1);
        testUtility.createIndividualSubscribers();

        testUtility.lstIndividualSubscribers[0].POC__c = testUtility.lstPOCs[0].POC_ID__c;
        update testUtility.lstIndividualSubscribers[0];

        Test.setCurrentPage(Page.OapSubscriptionTMG);
        ApexPages.currentPage().getParameters().put('pocid', testUtility.lstPOCs[0].POC_ID__c);

        Test.startTest();
            OapSubscriptionTMG controller = new OapSubscriptionTMG();
        Test.stopTest();

        System.assertEquals(testUtility.lstIndividualSubscribers[0].Id, controller.subscriber.Id,
            'The duplicate subscriber was not found');
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 17/06/2016
    Function - test getting an account when POC has email field
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void getAccountFromPOCWithEmailTest(){
        TestDataUtility testUtility = new TestDataUtility(1);
        testUtility.createPOCs(1);
        testUtility.createIndividualSubscribers();

        testUtility.lstIndividualSubscribers[0].POC__c = testUtility.lstPOCs[0].POC_ID__c;
        testUtility.lstIndividualSubscribers[0].PersonEmail = 'discus@creative.net';
        update testUtility.lstIndividualSubscribers[0];

        testUtility.lstPOCs[0].Email__c = 'discus@creative.net';
        update testUtility.lstPOCs[0];

        Test.setCurrentPage(Page.OapSubscriptionTMG);
        ApexPages.currentPage().getParameters().put('pocid', testUtility.lstPOCs[0].POC_ID__c);

        Test.startTest();
            OapSubscriptionTMG controller = new OapSubscriptionTMG();
        Test.stopTest();

        System.assertEquals(testUtility.lstIndividualSubscribers[0].Id, controller.subscriber.Id,
            'The duplicate subscriber was not found');
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/11/2016
    Function - test saveAndTakePayment() method - restore existing sub to non-lowstart
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveAndTakePaymentOnNonLowStartTCode_Positive(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createRetailers();
        td.createTCodeProductIncentives();
        td.createChequeBatches();
        td.lstRetailers[0].RET_ID__c = 'retid';
        update td.lstRetailers[0];
        //td.lstTCodeManagement[0].Payment_Type__c = 'Allow 52 Week CCA';
        //update td.lstTCodeManagement[0];
        td.createSubscriptions();
        td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
        td.lstSubscriptions[0].Low_Start_Weekly_Price__c = 5;
        td.lstSubscriptions[0].Low_Start_Period__c = 13;
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_OFFERED;
        update td.lstSubscriptions[0];
        List<Account> lstAcc = [select Subscriber_Number_static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAcc.isEmpty());

        Test.startTest();
            PageReference pr = Page.OapSubscriptionTMG;
            pr.getParameters().put(OapSubscriptionTMG.PARAM_ORDER_METHOD, 'someOrderMethod');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TCODE, td.lstTCodeManagement[0].Name);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SELECTED_OFFER, Constants.OFFER_OPENOFFER);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_FORCED_LOWSTART_PRICE, '4.5');
            pr.getParameters().put(OapSubscriptionTMG.PARAM_PRODUCTID, td.lstZproducts[0].Id);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_RETAILERID, td.lstRetailers[0].RET_ID__c);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_SUBSCRIPTION_TYPE, Constants.SUBSCRIPTIONTYPE_52CONTINUOUS);
            pr.getParameters().put(OapSubscriptionTMG.PARAM_TSNUMBER, lstAcc[0].Subscriber_Number_static__c);
            Test.setCurrentPage(pr);
            OapSubscriptionTMG ost = new OapSubscriptionTMG();

            ost.subscriber.PersonEmail = 'test@test.com';
            ost.subscriber.FirstName = 'test';
            ost.subscriber.LastName = 'test';
            ost.subscriber.PersonMobilePhone = '01234567';
            ost.subscriber.PersonHomePhone = '01234567';
            ost.selectedProduct = Constants.PRODUCT_PREMIUM;
            ost.preferedStartDate = ost.preferredStartDatesList.get(1).getValue();
            ost.paymentType = Constants.SUB_ACQUISITION_PAYMENT_CC;
            ost.paymentFrequency = Constants.DD_COL_FREQ_MONTHLY;
            ost.selectedDelivery = Constants.DELIVERYTYPE_OTC;

            System.assertEquals('internal', ost.saveAndTakePayment().getParameters().get('requestorigin'));
            List<Subscription__c> lstSubToAssert = [select Id, RecordTypeId, Low_Start_Period__c, Low_Start_Weekly_Price__c, Low_Start_End_Date__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
            System.assertEquals(RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName()), lstSubToAssert[0].RecordTypeId);
            System.assertEquals(null, lstSubToAssert[0].Low_Start_Period__c);
            System.assertEquals(null, lstSubToAssert[0].Low_Start_Weekly_Price__c);
            System.assertEquals(null, lstSubToAssert[0].Low_Start_End_Date__c);
        Test.stopTest();
    }

}