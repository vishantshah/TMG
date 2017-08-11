/**
* @author Wiktor Czykin
* @date 17/05/2016
* @description Offer Selection test class
* #############Change Log#############
* Modified by   Version     Date
* Wiktor Czykin 1.1         26/05/2016 //added testTCodeDetailsBulkRemote() test method
* Gavin Palmer  1.2         15/06/2016 // modified testTCodeDetailsBulkRemote() and testTCodeDetailsRemote()
**/

@isTest
private class OfferSelectionControllerTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testConstructor() {
        Test.startTest();
            OfferSelectionController osc = new OfferSelectionController();
        Test.stopTest();
        System.assertEquals(OfferSelectionController.YES, osc.selectedFilter);
        System.assertEquals(false, osc.bProductsSearched);
        System.assert(osc.lstAvailableProducts.isEmpty());
        System.assert(osc.lstPromotionIncentives.isEmpty());
        System.assert(osc.returnedPOCsList.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test AdHoc tcode name getter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAdHocGetter() {
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeManagement();
        General__c gAdHocTCode = new General__c(Name = Constants.GENERAL_ADHOCPRICE_TCODE, Value__c = td.lstTCodeManagement[0].Name);
        insert gAdHocTCode;
        OfferSelectionController osc = new OfferSelectionController();
        Test.startTest();
            System.assertEquals(gAdHocTCode.Value__c, osc.sAdHocTCode);
            delete gAdHocTCode;
            osc.sAdHocTCode = null;
            System.assertEquals( Constants.TCODE_ADHOCPRICE_DEFAULT, osc.sAdHocTCode);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test failure of offerSelector setter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOfferSelectorSetterException() {
        Test.startTest();
            OfferSelectionController osc = new OfferSelectionController();
            try{
                osc.offerSelector = null;
                System.assert(false, 'exception not thrown where it should be');
            }catch(Exception e){}
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test offerSelector setter positive
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOfferSelectorSetter() {
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        Test.startTest();
            OfferSelectionController osc = new OfferSelectionController();
            osc.offerSelector = scci;
            System.assertNotEquals(null, osc.selectionData);
            System.assertNotEquals(null, osc.lstOfferTypes);
            System.assertNotEquals(null, osc.offerSelector);
            System.assertEquals(OfferSelectionController.LIST_SUPPORTED_OFFERS.size(), osc.lstOfferTypes.size());

            //check digital setup
            scci.offerSelection.sSelectedProductType = Constants.PRODUCT_DIGITAL;
            OfferSelectionController osc2 = new OfferSelectionController();
            osc2.offerSelector = scci;
            System.assertNotEquals(null, osc2.lstOfferTypes);
            System.assertEquals(OfferSelectionController.LIST_SUPPORTED_OFFERS.size() - OfferSelectionController.SET_PREMIUM_ONLY_OFFERS.size(), osc2.lstOfferTypes.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test filtered offers getter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOfferSelectionFilter(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        List<String> lstFilter = new List<String>{Constants.OFFER_LOWSTART};
        Test.startTest();
            OfferSelectionController osc = new OfferSelectionController();
            osc.offerSelector = scci;
            osc.lstFilterOffers = lstFilter;
            System.assertEquals(OfferSelectionController.LIST_SUPPORTED_OFFERS.size()-1, osc.lstOfferTypes.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test for minor getters within the class
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testOtherSimplerGetters(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        Test.startTest();
            osc.offerSelector = scci;
            osc.selectionData.sSelectedOffer = Constants.OFFER_LOWSTART;
            System.assert(osc.bIsLowStart);
            System.assert(!osc.getShowOrderDetails());
            System.assert(osc.getShowPromotions());
            System.assertEquals(OfferSelectionController.MAP_OFFER_LABELS.get(Constants.OFFER_LOWSTART), osc.getOfferLabel());
            osc.selectionData.sSelectedOffer = 'nonexisting';
            System.assertEquals('', osc.getOfferLabel());
            System.assert(osc.getIsPremium());

            osc.selectionData.sSelectedOffer = Constants.OFFER_MGM;
            System.assert(!osc.bIsLowStart);
            System.assert(osc.getShowOrderDetails());
            System.assert(!osc.getShowPromotions());
            System.assertEquals(2, osc.lstOrderMethodValues.size());
            System.assertEquals(2, osc.lstFilterOptions.size());
            System.assertEquals(2, OfferSelectionController.getProductTypeOptions().size());
            osc.selectionData.sSelectedProductType = Constants.PRODUCT_DIGITAL;
            System.assert(!osc.getIsPremium());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test tcode products fetching remote method
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         15/06/2016 - added parameter for getTCodeDetails
    ****************************************************************************************/
    private static testMethod void testTCodeDetailsRemote(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();
        delete td.lstTCodeProducts[1];
        delete td.lstTCodeManagement[1];
        Test.startTest();
            List<TCodeProductWrapper> lstTcp = OfferSelectionController.getTCodeDetails(td.lstTCodeManagement[0].Id, null);
            System.assertNotEquals(null, lstTcp);
            System.assertEquals(1, lstTcp.size());

            lstTcp = OfferSelectionController.getTCodeDetails(td.lstTCodeManagement[1].Id, null);
            System.assertEquals(null, lstTcp);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test tcode products fetching remote method - for multiple tcodes
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         15/06/2016 - added parameter for getTCodesDetails()
    ****************************************************************************************/
    private static testMethod void testTCodeDetailsBulkRemote(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        List<Id> lstIds = new List<Id>();
        for(TCodeManagement__c tcm : td.lstTCodeManagement){
            lstIds.add(tcm.Id);
        }

        zqu__ZProduct__c zp = TestDataUtility.newZProduct(3, true);
        insert zp;
        insert TestDataUtility.newTCodeProduct(zp.Id, td.lstTCodeManagement[0].Id);
        Test.startTest();

            Map<Id, List<TCodeProductWrapper>> mapTcp = OfferSelectionController.getTCodesDetails(lstIds, null);
            System.assertNotEquals(null, mapTcp);
            System.assertEquals(2, mapTcp.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test products getter method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetAvailableProducts(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProducts();

        for(zqu__ZProduct__c prod : td.lstZproducts){
            prod.Print_Product__c = false;
        }
        update td.lstZproducts;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        Test.startTest();
             List<TCodeProductWrapper> lst = osc.getAvailableProducts(td.lstTCodeManagement[0].Id, false);
             System.assertEquals(1, lst.size());
             System.assert(osc.bProductsSearched);
             System.assertNotEquals(null, osc.selectionData.productId);
             System.assert(lst[0].selected);
             System.assert(osc.selectSelected);
             System.assert(!osc.filterSelected);

             lst = osc.getAvailableProducts(td.lstTCodeManagement[0].Id, true);
             System.assert(lst.isEmpty(), JSON.serialize(lst));

             lst = osc.getAvailableProducts(td.lstTCodeManagement[0].Id, null);
             System.assert(lst.isEmpty(), JSON.serialize(lst));
             System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_products_for_tcode));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test Low Start offer selection
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumLowStartOfferSelection(){
        TestDataUtility td = new TestDataUtility(4);
        td.createTCodeProductIncentives();

        for(TCodeManagement__c tCode : td.lstTCodeManagement){
            tCode.Type__c = Constants.TCODE_TYPE_LOWSTART;
            tCode.Low_Start_Period__c = Constants.LOW_START_PERIOD+'';
            tCode.Payment_Type__c = Constants.ALLOW_52_WEEK_DD;
        }
        update td.lstTCodeManagement;

        //to check tcode without incentive
        TCodeManagement__c extraTCode = TestDataUtility.newTCodeManagement('LOWS');
        extraTCode.Type__c = Constants.TCODE_TYPE_LOWSTART;
        extraTCode.Low_Start_Period__c = Constants.LOW_START_PERIOD+'';
        extraTCode.Low_Start_Weekly_Price__c = 9;
        extraTCode.Payment_Type__c = Constants.ALLOW_52_WEEK_DD;
        insert extraTCode;

        TCode_Product__c tcp = TestDataUtility.newTCodeProduct(td.lstZproducts[0].Id, extraTCode.Id);
        insert tcp;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_LOWSTART;

        Test.startTest();
            osc.initTcodes();
            System.assert(osc.filterselected);
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.lstFoundAccounts);
            System.assertEquals(5 , osc.lstPromotionIncentives.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test Promotion offer selection - digital filtered out
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumPromotionOfferSelectionWithoutDigital(){
        TestDataUtility td = new TestDataUtility(4);
        td.createTCodeProductIncentives();

        //to check multiple incentives for single tcode
        TCode_Product_Incentive__c tpi = TestDataUtility.newTCodeProductIncentive(100, td.lstIncentives[1].Id, td.lstTCodeProducts[0].Id, '');
        insert tpi;

        //to check tcode without incentive
        TCodeManagement__c extraTCode = TestDataUtility.newTCodeManagement('PRO1');
        insert extraTCode;

        //to check that digital tCode is not counted for
        TCodeManagement__c extraTCodeDigital = TestDataUtility.newTCodeManagement('PRO2');
        extraTCodeDigital.Reporting_Type__c = Constants.TCODE_REPORTTYPE_DIGITALONLY;
        insert extraTCodeDigital;

        TCode_Product__c tcp1 = TestDataUtility.newTCodeProduct(td.lstZproducts[0].Id, extraTCode.Id);
        TCode_Product__c tcp2 = TestDataUtility.newTCodeProduct(td.lstZproducts[0].Id, extraTCodeDigital.Id);
        insert new List<TCode_Product__c>{tcp1, tcp2};

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;

        Test.startTest();
            osc.initTcodes();
            System.assert(osc.filterselected);
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.lstFoundAccounts);
            System.assertEquals(5 , osc.lstPromotionIncentives.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test Promotion offer selection without print filter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumPromotionOfferSelectionWithDigital(){
        TestDataUtility td = new TestDataUtility(4);
        td.createTCodeProductIncentives();

        //to check multiple incentives for single tcode
        TCode_Product_Incentive__c tpi = TestDataUtility.newTCodeProductIncentive(100, td.lstIncentives[1].Id, td.lstTCodeProducts[0].Id, '');
        insert tpi;

        //to check tcode without incentive
        TCodeManagement__c extraTCode = TestDataUtility.newTCodeManagement('PRO1');
        insert extraTCode;

        //to check that digital tCode is not counted for
        TCodeManagement__c extraTCodeDigital = TestDataUtility.newTCodeManagement('PRO2');
        extraTCodeDigital.Reporting_Type__c = Constants.TCODE_REPORTTYPE_DIGITALONLY;
        insert extraTCodeDigital;

        TCode_Product__c tcp1 = TestDataUtility.newTCodeProduct(td.lstZproducts[0].Id, extraTCode.Id);
        TCode_Product__c tcp2 = TestDataUtility.newTCodeProduct(td.lstZproducts[0].Id, extraTCodeDigital.Id);
        insert new List<TCode_Product__c>{tcp1, tcp2};

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;
        osc.selectedFilter = OfferSelectionController.NO;

        Test.startTest();
            osc.initTcodes();
            System.assert(osc.filterselected);
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.lstFoundAccounts);
            System.assertEquals(6, osc.lstPromotionIncentives.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test Promotion offer selection for digital product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testDigitalPromotionOfferSelection(){
        TestDataUtility td = new TestDataUtility(4);
        td.createTCodeProductIncentives();

        for(zqu__ZProduct__c prod : td.lstZproducts){
            prod.Print_Product__c = false;
        }
        update td.lstZproducts;

        for(TCodeManagement__c tCode : td.lstTCodeManagement){
            tCode.Reporting_Type__c = Constants.TCODE_REPORTTYPE_DIGITALONLY;
        }
        update td.lstTCodeManagement;

        //to check tcode non digital
        TCodeManagement__c extraTCode = TestDataUtility.newTCodeManagement('PRO1');
        insert extraTCode;
        TCode_Product__c tcp1 = TestDataUtility.newTCodeProduct(td.lstZproducts[0].Id, extraTCode.Id);
        insert tcp1;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedProductType = Constants.PRODUCT_DIGITAL;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;

        Test.startTest();
            osc.initTcodes();
            System.assert(osc.filterselected);
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.lstFoundAccounts);
            System.assertEquals(4 , osc.lstPromotionIncentives.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date -  05/2016
    Version - 1.0
    Function - test Open Offer selection
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumOpenOfferSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
        update td.lstTCodeManagement;
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_OPENOFFER;

        Test.startTest();
            osc.initTcodes();
            System.assertEquals(td.lstTCodeManagement[0].Id, osc.selectionData.sTCodeId);
            System.assertEquals(td.lstTCodeManagement[0].Name, osc.selectionData.sTCode);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test Open Offer selection error - duplicate tcodes
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumOpenOfferSelectionError(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductIncentives();

        for(TCodeManagement__c tCode : td.lstTCodeManagement){
            tCode.Type__c =  Constants.TCODE_TYPE_OPENOFFER;
        }
        update td.lstTCodeManagement;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_OPENOFFER;
        Test.startTest();
            osc.initTcodes();
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.selectionData.sTCode);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Multiple_open_offer_records_error));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test staff offer selection
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumStaffOfferSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_STAFFOFFER;
        update td.lstTCodeManagement;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_STAFF;

        Test.startTest();
            osc.initTcodes();
            System.assertEquals(td.lstTCodeManagement[0].Id, osc.selectionData.sTCodeId);
            System.assertEquals(td.lstTCodeManagement[0].Name, osc.selectionData.sTCode);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date -  05/2016
    Version - 1.0
    Function - test staff offer selection error - duplicate tcode
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumStaffOfferSelectionError(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductIncentives();

        for(TCodeManagement__c tCode : td.lstTCodeManagement){
            tCode.Type__c =  Constants.TCODE_TYPE_STAFFOFFER;
        }
        update td.lstTCodeManagement;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_STAFF;

        Test.startTest();
            osc.initTcodes();
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.selectionData.sTCode);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Staff_offer_tcode_configuration_error));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test staff offer selection validation error
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testStaffNameValidation(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        Test.startTest();
            osc.enterStaffName();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Staff_name_mandatory));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test mgm offer selection
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumMgmOfferSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_MGM;
        update td.lstTCodeManagement;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_MGM;

        Test.startTest();
            osc.initTcodes();
            System.assertEquals(td.lstTCodeManagement[0].Id, osc.selectionData.sTCodeId);
            System.assertEquals(td.lstTCodeManagement[0].Name, osc.selectionData.sTCode);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test mgm offer selection - duplicate tcodes
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumMgmOfferSelectionFailure(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductIncentives();

        for(TCodeManagement__c tCode : td.lstTCodeManagement){
            tCode.Type__c =  Constants.TCODE_TYPE_MGM;
        }
        update td.lstTCodeManagement;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_MGM;

        Test.startTest();
            osc.initTcodes();
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.selectionData.sTCode);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_MGM_tcode_configuration_error));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test AdHoc offer selection - tcode init
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumAdHocOfferSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        General__c gAdHocTCode = new General__c(Name = Constants.GENERAL_ADHOCPRICE_TCODE, Value__c = td.lstTCodeManagement[0].Name);
        insert gAdHocTCode;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_ADHOCPRICE;

        Test.startTest();
            osc.initTcodes();
            System.assertEquals(td.lstTCodeManagement[0].Id, osc.selectionData.sTCodeId);
            System.assertEquals(td.lstTCodeManagement[0].Name, osc.selectionData.sTCode);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test AdHoc offerselection error - duplicate tcodes
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumAdHocSelectionError(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductIncentives();

        General__c gAdHocTCode = new General__c(Name = Constants.GENERAL_ADHOCPRICE_TCODE, Value__c = td.lstTCodeManagement[0].Name);
        insert gAdHocTCode;

        td.lstTCodeManagement[1].Name = td.lstTCodeManagement[0].Name;
        update td.lstTCodeManagement[1];

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_ADHOCPRICE;
        Test.startTest();
            osc.initTcodes();
            System.assertEquals(null, osc.selectionData.sTCodeId);
            System.assertEquals(null, osc.selectionData.sTCode);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Multiple_open_offer_records_error));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date -  05/2016
    Version - 1.0
    Function - test account search after promotion offer selection - existing account found
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumPromotionOfferSearch(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createTCodeProductIncentives();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;
        osc.initTcodes();
        Test.startTest();
            osc.selectionData.sTCodeId = td.lstTCodeManagement[0].Id;
            osc.selectionData.productId = td.lstZproducts[0].Id;
            osc.selectProductInfo();
            System.assert(osc.selectSelected);
            System.assert(!osc.filterSelected);
            System.assertEquals(td.lstTCodeManagement[0].Name, osc.selectionData.sTCode);
            System.assert(osc.renderCreateExistingAccountBtn);
            osc.selectionData.sSurname = td.lstIndividualSubscribers[0].LastName;
            osc.selectionData.sPostCode = td.lstIndividualSubscribers[0].PersonMailingPostalCode;
            System.assertEquals(null, osc.checkDuplicates());
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Existing_accounts_found));
        System.assertEquals(1, osc.lstFoundAccounts.size(),'Account not found by account search where it should be.');
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test basic failure conditions for account search
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountSearchPreValidation(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        Test.startTest();
            //check no conditions are there
            osc.checkDuplicates();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Subscriber_search_criteria_not_specified), ApexPages.getMessages());

            //check not all conditions are met for last name search
            osc.selectionData.sPostCode = td.lstIndividualSubscribers[0].PersonMailingPostalCode;
            osc.checkDuplicates();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Subscriber_search_last_name_and_post_code_mandatory), ApexPages.getMessages());

            //check that last name search does not support special chars in search
            osc.selectionData.sSurname = td.lstIndividualSubscribers[0].LastName+'213';
            osc.checkDuplicates();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Subscriber_search_last_name_and_post_code_mandatory), ApexPages.getMessages());

            //check number validation on discount field for adhoc offer
            osc.selectionData.sSurname = td.lstIndividualSubscribers[0].LastName;
            osc.selectionData.sSelectedOffer = Constants.OFFER_ADHOCPRICE;
            osc.selectionData.sDiscountPrice = null;
            osc.checkDuplicates();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Subscriber_search_discount_price_validation), ApexPages.getMessages());

            osc.selectionData.sDiscountPrice = 'notANumber';
            osc.checkDuplicates();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Subscriber_search_discount_price_characters_validation), ApexPages.getMessages());
       Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test basic failure conditions for account search
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountSearchNoResultsForPromoSwitchError(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Description__c = 'xxx product switching xxx';
        update td.lstTCodeManagement[0];

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;
        osc.initTcodes();
        osc.selectionData.sTCodeId = td.lstTCodeManagement[0].Id;
        osc.selectionData.productId = td.lstZproducts[0].Id;
        Test.startTest();
            osc.selectTcodeinfo();
            osc.selectionData.sSurname = 'someName';
            osc.selectionData.sPostCode = 'somePostCode';
            osc.checkDuplicates();
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Product_switching_subscriber_not_found), ApexPages.getMessages());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test account search where no duplicates are found
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testAccountSearchNoDuplicatesSuccess(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createTCodeProductIncentives();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;
        osc.initTcodes();
        osc.selectionData.sTCodeId = td.lstTCodeManagement[0].Id;
        osc.selectionData.productId = td.lstZproducts[0].Id;
        Test.startTest();
            osc.selectProductInfo();
            osc.selectionData.sSurname = 'myname';
            osc.selectionData.sPostCode =  'mypostcode';
            PageReference pr = osc.checkDuplicates();
        Test.stopTest();

        System.assert(ApexPages.getMessages().isEmpty(), ApexPages.getMessages());
        System.assertNotEquals(null, pr);
        System.assertEquals(td.lstTCodeManagement[0].Name, pr.getParameters().get('tcode'));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test account search where with duplicate selection
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountSearchWithDuplicateSelectionSuccess(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createTCodeProductIncentives();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;
        osc.initTcodes();
        osc.selectionData.sTCode = td.lstTCodeManagement[0].Name;
        osc.selectionData.sTCodeId = td.lstTCodeManagement[0].Id;
        osc.selectionData.productId = td.lstZproducts[0].Id;
        Test.startTest();
            osc.selectProductInfo();
            osc.selectionData.sSurname = td.lstIndividualSubscribers[0].LastName;
            osc.selectionData.sPostCode =  td.lstIndividualSubscribers[0].PersonMailingPostalCode;
            PageReference pr = osc.checkDuplicates();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Existing_accounts_found));
            System.assertEquals(null, pr);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test account search where with duplicate selection
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountSearchWithDuplicateSelectionSuccessSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createTCodeProductIncentives();

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_PROMOTION;
        osc.initTcodes();
        osc.selectionData.sTCode = td.lstTCodeManagement[0].Name;
        osc.selectionData.sTCodeId = td.lstTCodeManagement[0].Id;
        osc.selectionData.productId = td.lstZproducts[0].Id;
        Test.startTest();
            osc.selectProductInfo();
            osc.selectionData.selectedAccountId = td.lstIndividualSubscribers[0].Id;
            PageReference pr = osc.displayDupAccount();
        Test.stopTest();
        System.assertNotEquals(null, pr);
        System.assertEquals(td.lstTCodeManagement[0].Name, pr.getParameters().get(OapSubscriptionTMG.PARAM_TCODE));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test account search where no account is found
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testAccountSearchFailureNoAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        delete td.lstIndividualSubscribers[0];
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        Test.startTest();
            osc.selectionData.selectedAccountId = td.lstIndividualSubscribers[0].Id;
            System.assertEquals(null, osc.displayDupAccount());
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Account_details_not_found_on_submit));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test poc search failure because of missing poc search param
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPOCSearchEmptyFieldFailure(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_POC;
        Test.startTest();
            osc.findCustomerPOC();
        Test.stopTest();
        System.assert(osc.returnedPOCsList.isEmpty());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Missing_POC_string_for_POC_search));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test poc search failure because of missing poc
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPOCSearchNoResultsFailure(){
        TestDataUtility td = new TestDataUtility(1);
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_POC;
        Test.startTest();
            osc.inputPOC = 'somePoc';
            osc.findCustomerPOC();
        Test.stopTest();
        System.assert(osc.returnedPOCsList.isEmpty());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_POC_record_found));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test poc search success with warning on duplicates
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPremiumPOCSearchSuccessWithDuplicatedPOC(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createTCodeProducts();
        td.createPOCs(1);

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_POC;
        osc.selectionData.productId = td.lstZproducts[0].Id;

        List<Account> lstAccount = [select Id, Subscriber_Number__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        POC__c poc = td.mapTCodeManagementToPOCs.get(td.lstTCodeManagement[0].Id)[0];
        poc.Subscriber_Number__c = lstAccount[0].Subscriber_Number__c;
        update poc;

        POC__c poc2 = poc.clone(false, true);
        insert poc2;

        Test.startTest();
            osc.inputPOC = poc.POC_ID__c;
            osc.findCustomerPOC();
            osc.selectPOC();
            System.assert(poc.Id == osc.returnedPOCsList[0].Id || poc2.Id == osc.returnedPOCsList[0].Id);
            System.assertEquals(1, osc.returnedPOCsList.size());
            System.assertEquals(Constants.SUB_ORDER_METHOD_INBOUND, osc.selectionData.sOrderMethod);
            System.assertEquals(poc.POC_ID__c, osc.selectionData.sPocId);
            System.assertEquals(poc.LastName__c, osc.selectionData.sSurname);
            System.assertEquals(poc.PostalCode__c, osc.selectionData.sPostCode);
            System.assert(poc.Id == osc.selectionData.pocSfdcId || poc2.Id == osc.selectionData.pocSfdcId);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test direct mail search failure on search criteria
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testDirectMailSearchFailureOnSearchCriteria(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;

        Test.startTest();
            osc.findCustomerDirectMail();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Direct_mail_customer_search_empty_criteria));
            osc.selectionData.sSurname = 'someName';
            osc.findCustomerDirectMail();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Direct_mail_customer_search_empty_post_code));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test direct mail search failure - no search results
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testDirectMailSearchFailureOnSearchNoResult(){
        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        Test.startTest();
            osc.selectionData.sPostCode = 'eh1 1jg';
            osc.findCustomerDirectMail();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Direct_mail_customer_search_empty_result));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test direct mail search success
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumDirectMailSearchSuccess(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        td.createPOCs(1);

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_DIRECTMAIL;

        List<Account> lstAccount = [select Id, Subscriber_Number__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        POC__c poc = td.mapTCodeManagementToPOCs.get(td.lstTCodeManagement[0].Id)[0];
        poc.Subscriber_Number__c = lstAccount[0].Subscriber_Number__c;
        update poc;

        Test.startTest();
            osc.selectionData.sSurname =  poc.LastName__c;
            osc.selectionData.sPostCode = poc.PostalCode__c;
            osc.findCustomerDirectMail();

            System.assertEquals(poc.Id, osc.returnedPOCsList[0].Id);
            System.assertEquals(1, osc.returnedPOCsList.size());
            System.assertEquals(Constants.SUB_ORDER_METHOD_INBOUND, osc.selectionData.sOrderMethod);
            System.assertEquals(poc.POC_ID__c, osc.selectionData.sPocId);
            System.assertEquals(poc.LastName__c, osc.selectionData.sSurname);
            System.assertEquals(poc.PostalCode__c, osc.selectionData.sPostCode);
            System.assertEquals(poc.Id, osc.selectionData.pocSfdcId);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test mgm offer selection - fail no giver found
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumMgmOfferNoGiverFound(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_MGM;
        update td.lstTCodeManagement;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_MGM;

        osc.initTcodes();
        Test.startTest();
            osc.selectionData.sMgmGiverCode = 'someCode';
            osc.searchMGM();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_MGM_giver_found));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test mgm offer selection - fail no giver's active subscription found
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumMgmOfferNoGiverSubscriptionFound(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_MGM;
        update td.lstTCodeManagement;

        td.checkSubscriptionDependencies();
        td.lstIndividualSubscribers[0].MGMcode__c = 'mgmcode';
        update td.lstIndividualSubscribers;

        Subscription__c sub = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert sub;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.setMGMTcode();
        osc.selectionData.sSelectedOffer = Constants.OFFER_MGM;
        osc.initTcodes();
        Test.startTest();
            osc.selectionData.sMgmGiverCode = td.lstIndividualSubscribers[0].MGMcode__c;
            osc.searchMGM();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_No_active_subscription_found_for_MGM_giver));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test mgm offer selection - success
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testPremiumMgmOfferSuccess(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.createTCodeProductIncentives();
        td.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_MGM;
        update td.lstTCodeManagement;
        td.lstIndividualSubscribers[0].MGMcode__c = 'mgmcode';
        update td.lstIndividualSubscribers;
        td.lstSubscriptions[0].Product__c = td.lstTCodeProducts[0].Product__c;
        System.assertNotEquals(null, td.lstSubscriptions[0].Product__c);
        update td.lstSubscriptions[0];

        for(zqu__ZProduct__c product : td.lstZproducts){
            product.Print_Product__c = true;
        }
        update td.lstZproducts;

        SubscriptionCallCentreInBoundTMG scci = new SubscriptionCallCentreInBoundTMG();
        OfferSelectionController osc = new OfferSelectionController();
        osc.offerSelector = scci;
        osc.selectionData.sSelectedOffer = Constants.OFFER_MGM;
        osc.initTcodes();
        Test.startTest();
            System.assertNotEquals(null, osc.selectionData.sTcodeId);
            osc.selectionData.sMgmGiverCode = td.lstIndividualSubscribers[0].MGMcode__c;
            osc.searchMGM();
            System.assertNotEquals(null, osc.mgmGiverInfo);
            System.assertNotEquals(null, osc.selectionData.productId);
            System.assertNotEquals(null, osc.selectionData.dForcedPrice);
            System.assertEquals(1, osc.lstAvailableProducts.size());
            System.assert(osc.getIsFindAccountShowed());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/2016
    Version - 1.0
    Function - test TCodeWrapper payment types assignment
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    private static testMethod void testWrappers(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();

        Test.startTest();
            td.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_13_WEEK_CCA +';'+Constants.ALLOW_13_WEEK_DD+';'+Constants.ALLOW_26_WEEK_CCA+';'+Constants.ALLOW_26_WEEK_DD+';'+Constants.ALLOW_52_WEEK_CCA+';'+Constants.ALLOW_52_WEEK_DD;
            OfferSelectionController.TCodeWrapper tcw = new  OfferSelectionController.TCodeWrapper(td.lstTCodeManagement[0]);
            System.assert(String.isNotBlank(tcw.allow13Continuous));
            System.assert(String.isNotBlank(tcw.allow26Continuous));
            System.assert(String.isNotBlank(tcw.allow52Continuous));
        Test.stopTest();
    }
}