/**
* Author:       Wiktor Czykin
* Date:         12/06/2017
* Description:  tests for TCodeManagementController
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest
private class TCodeManagementControllerTest{

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function -  constructor - record create
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testConstructorInit(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProducts();
        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(new TCodeManagement__c()));
        Test.stopTest();
        System.assertNotEquals(null, tmc.tcode);
        System.assert(tmc.canSeeAvailableProducts);
        System.assertNotEquals(null, tmc.mapAvailableZProducts);
        System.assertEquals(1, tmc.mapAvailableZProducts.size());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function -  constructor - existing record - zOffer and offer with children
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testConstructorExistingRecord(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductOffers();
        td.createTCodeProductIncentives();
        td.createPricingOptions(null);
        td.lstZProducts[0].Print_Product__c = false;
        update td.lstZProducts;

        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
            System.assert(!tmc.canSeeAvailableProducts);
            tmc.toggleAvailableProducts();
            System.assertNotEquals(null, tmc.mapAvailableZProducts);
            System.assertEquals(1, tmc.mapAvailableZProducts.size());
            System.assert(!TCodeManagementController.ZOFFERS_LIMIT_ENABLED);
            System.assert(!tmc.mapAvailableZProducts.get(td.lstZProducts[0].Id).bShowAddOffer);
            System.assert(tmc.mapAvailableZProducts.get(td.lstZProducts[0].Id).bShowAddZOffer);
            System.assertEquals(1, tmc.availableZProductsList.size());
        Test.stopTest();
        System.assertNotEquals(null, tmc.tcode);
        System.assertEquals(td.lstTCodeManagement[0].Id, tmc.tcode.Id);
        System.assert(tmc.canSeeAvailableProducts);
        
        System.assertEquals(1, tmc.mapAvailableZProducts.size());
        System.assertEquals(2, tmc.mapExistingOffersById.size());
        System.assert(tmc.canSeeAvailableProducts);
        System.assertEquals(2, tmc.iCustomIndex);

        TCodeManagementController.Offer offer = tmc.mapExistingOffersById.get(td.lstTCodeProducts[0].Id);
        TCodeManagementController.Offer zoffer = tmc.mapExistingOffersById.get(td.lstTCodeProductOffers[0].Id);
        System.assertNotEquals(null, offer);
        System.assertNotEquals(null, zoffer);
        System.assertEquals(TCodeManagementController.OFFER_RECORDTYPE_ID, offer.tp.RecordTypeId);
        System.assertEquals(TCodeManagementController.ZOFFER_RECORDTYPE_ID, zoffer.tp.RecordTypeId);
        System.assertEquals(1, offer.lstIncentives.size());
        System.assertEquals(1, offer.lstPricingOptions.size());
        System.assertEquals(0, zoffer.lstIncentives.size());
        System.assertEquals(0, zoffer.lstPricingOptions.size());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function -  test exception in getTCode() method when tcode cannot be found
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testGetTCodeException(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeManagement();
        delete td.lstTCodeManagement;
        Test.startTest();
            try{
                TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.TCodeSetup_Error_Getting_TCode));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function -  test clone
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testConstructorExistingRecordClone(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.createPricingOptions(null);
        Test.startTest();
            PageReference pr = Page.TCodeSetup;
            pr.getParameters().put('clone', '1');
            Test.setCurrentPage(pr);
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
        Test.stopTest();
        System.assertEquals(0, tmc.mapExistingOffersById.size());
        System.assertEquals(1, tmc.mapExistingOffersByIndex.size());
        TCodeManagementController.Offer zOffer = tmc.mapExistingOffersByIndex.get(0);
        System.assertNotEquals(null, zOffer);
        System.assertEquals(0, zOffer.iCustomIndex);
        System.assertEquals(null, zOffer.tp.Id);
        System.assertEquals(1, zOffer.lstIncentives.size());
        System.assertEquals(1, zOffer.lstPricingOptions.size());
        System.assertEquals(null, zOffer.lstIncentives[0].Id);
        System.assertEquals(null, zOffer.lstPricingOptions[0].Id);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function - test tcodeproduct add method
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testAddTCodeProduct(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProducts();
        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(new TCodeManagement__c()));
            tmc.selectedProductId = td.lstZProducts[0].Id;
            tmc.addTCodeProduct();
            tmc.sZOffer = 'string';
            tmc.addTCodeProduct();
        Test.stopTest();
        System.assertNotEquals(null, tmc.tcode);
        System.assertNotEquals(null, tmc.lstSelectedOffers);
        System.assertEquals(1, tmc.lstSelectedOffers.size());
        System.assertEquals(1, tmc.lstSelectedZuoraOffers.size());
        System.assertEquals(2, tmc.mapExistingOffersByIndex.size());
        System.assertEquals(TCodeManagementController.OFFER_RECORDTYPE_ID, tmc.mapExistingOffersByIndex.get(0).tp.RecordTypeId);
        System.assertEquals(TCodeManagementController.ZOFFER_RECORDTYPE_ID, tmc.mapExistingOffersByIndex.get(1).tp.RecordTypeId);
        System.assertEquals(2, tmc.iCustomIndex);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function - test all remove tcodeproduct method flows
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testRemoveTCodeProduct(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductOffers();
        td.createTCodeProductIncentives();
        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
            System.assertEquals(2, tmc.mapExistingOffersByIndex.size());
            tmc.iSelectedIndex = 5;
            tmc.removeTCodeProduct();
            System.assertEquals(2, tmc.mapExistingOffersByIndex.size());
            tmc.mapExistingOffersByIndex.put(5, null);
            try{
                tmc.removeTCodeProduct();
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains('Unexpected'));
            }
            tmc.mapExistingOffersByIndex.remove(5);
            tmc.offerInContext = tmc.mapExistingOffersByIndex.get(1);
            tmc.iSelectedIndex = 0;
            tmc.removeTCodeProduct();
            System.assertEquals(1, tmc.mapExistingOffersByIndex.size());
            System.assertNotEquals(null, tmc.offerInContext);
            tmc.iSelectedIndex = 1;
            tmc.removeTCodeProduct();
            System.assertEquals(null, tmc.offerInContext);
            System.assertEquals(0, tmc.mapExistingOffersByIndex.size());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/06/2017
    Function -  incentives/pricing options behaviour
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testExistingRecordIncentivesPricingOptionResave(){
        TestDataUtility td = new TestDataUtility(1);
        td.createTCodeProductIncentives();
        td.createPricingOptions(null);
        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
            System.assertEquals(null, tmc.offerInContext);
            //view incentive
            tmc.iSelectedIndex = 0;
            tmc.viewIncentives();
            System.assert(!tmc.canViewPricingOptions);
            System.assert(tmc.canViewIncentives);
            System.assertNotEquals(null, tmc.offerInContext);
            //add incentive
            tmc.addIncentive();
            System.assertEquals(2, tmc.offerInContext.lstIncentives.size());

            //view pricing option
            tmc.viewPricingOptions();
            System.assert(tmc.canViewPricingOptions);
            System.assert(!tmc.canViewIncentives);
            //add pricing option
            tmc.addPricingOption();
            System.assertEquals(2, tmc.offerInContext.lstPricingOptions.size());

            //remove incentive
            tmc.selectedRow = 0;
            tmc.removeIncentive();
            System.assertEquals(1, tmc.offerInContext.lstIncentives.size());
            System.assertEquals(1, tmc.lstIncentivesToDelete.size());

            //remove pricing option
            tmc.selectedRow = 0;
            tmc.removePricingOption();
            System.assertEquals(1, tmc.offerInContext.lstPricingOptions.size());
            System.assertEquals(1, tmc.lstPricingOptionsToDelete.size());

            //save change
            tmc.offerInContext.lstIncentives[0].Incentive__c = td.lstIncentives[0].Id;
            tmc.offerInContext.lstIncentives[0].Auto_Assign_for_Zuora_Subscription__c = true;
            tmc.offerInContext.lstPricingOptions[0].ServiceId__c = 15;
            tmc.offerInContext.lstPricingOptions[0].Subscription_Type__c = Constants.DD_COL_FREQ_MONTHLY;
            tmc.offerInContext.lstPricingOptions[0].Flow_Type__c = Constants.PRICING_FLOW_TYPE_OPENOFFER;
            tmc.save();
        Test.stopTest();
        List<TCode_Product_Incentive__c> lstTCodeProductIncentives = [SELECT Id FROM TCode_Product_Incentive__c WHERE Id IN :td.lstTCodeProductIncentives];
        System.assert(lstTCodeProductIncentives.isEmpty(), 'records not deleted correctly');
        lstTCodeProductIncentives = [SELECT Id FROM TCode_Product_Incentive__c WHERE TCode_Product__c = :td.lstTCodeProducts[0].Id];
        System.assert(!lstTCodeProductIncentives.isEmpty());

        List<Pricing_Options__c> lstTCodeProductPricingOptions = [SELECT Id FROM Pricing_Options__c WHERE Id IN :td.mapPricingOptions.get(0)];
        System.assert(lstTCodeProductPricingOptions.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/06/2017
    Function - record create test 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveOfNewTCodeProducts(){
        TestDataUtility td = new TestDataUtility(2);
        td.createZProducts();
        td.lstZProducts[0].Print_Product__c = false;
        update td.lstZProducts;
        td.createOffers();

        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(new TCodeManagement__c()));
            System.assertEquals(2, tmc.mapAvailableZProducts.size());
            tmc.tcode.Name = 'som2';
            tmc.tcode.Type__c = Constants.TCODE_TYPE_PROMOTIONAL;
            tmc.tcode.Description__c = 'testDescription';
            tmc.tcode.Valid__c = true;
            tmc.tcode.Payment_Type__c = Constants.ALLOW_ONE_OFF_52_WEEK;

            tmc.selectedProductId = td.lstZProducts[0].Id;
            tmc.sZOffer ='string';
            tmc.addTCodeProduct();

            tmc.selectedProductId = td.lstZProducts[1].Id;
            tmc.sZOffer = '';
            tmc.addTCodeProduct();

            tmc.mapExistingOffersByIndex.get(0).tp.Offer__c = td.lstOffers[0].Id;
            tmc.mapExistingOffersByIndex.get(1).tp.Weekly_Price__c = 10;

            PageReference pr = tmc.saveAndNew();
            System.assertNotEquals(null, pr, 'did fail where it should not');
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/06/2017
    Function - record create test failure 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testSaveOfNewTCodeProductsFailure(){
        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(new TCodeManagement__c()));
            tmc.tcode.Name = 'som2';
            tmc.tcode.Description__c = 'testDescription';
            tmc.tcode.Valid__c = true;
            tmc.tcode.Payment_Type__c = Constants.ALLOW_ONE_OFF_52_WEEK;

            PageReference pr = tmc.saveAndNew();
            System.assertEquals(null, pr, 'did not fail where it should');
            pr = tmc.save();
            System.assertEquals(null, pr, 'did not fail where it should');
        Test.stopTest();    
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/06/2017
    Function - test refresh of offer data on offer selection
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testRefreshOfferSelection(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProducts();
        td.lstZProducts[0].Print_Product__c = false;
        update td.lstZProducts;
        td.createOffers();

        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(new TCodeManagement__c()));
            tmc.selectedProductId = td.lstZProducts[0].Id;
            tmc.sZOffer ='string';
            tmc.addTCodeProduct();

            System.assertEquals(null, tmc.mapExistingOffersByIndex.get(0).offer.Id);
            tmc.iOfferRowToPopulate = null;
            tmc.refreshOfferSelection();
            System.assertEquals(null, tmc.mapExistingOffersByIndex.get(0).offer.Id);
            tmc.iOfferRowToPopulate = 5;
            tmc.refreshOfferSelection();
            System.assertEquals(null, tmc.mapExistingOffersByIndex.get(0).offer.Id);
            tmc.iOfferRowToPopulate = 0;
            tmc.refreshOfferSelection();
            System.assertEquals(null, tmc.mapExistingOffersByIndex.get(0).offer.Id);

            tmc.mapExistingOffersByIndex.get(0).tp.Offer__c = td.lstOffers[0].Id;
            tmc.refreshOfferSelection();
            System.assertNotEquals(null, tmc.mapExistingOffersByIndex.get(0).offer.Id);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 21/06/2017
    Function - test incentive save validation failure
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testIncentiveSaveValidation(){
        TestDataUtility td = new TestDataUtility(2);
        td.createTCodeProductOffers();
        td.createIncentives();
        Test.startTest();
            TCodeManagementController tmc = new TCodeManagementController(new ApexPages.StandardController(td.lstTCodeManagement[0]));
            tmc.iSelectedIndex = 0;
            tmc.viewIncentives();
            tmc.addIncentive();
            tmc.addIncentive();
            tmc.mapExistingOffersByIndex.get(0).lstIncentives[0].Incentive__c = td.lstIncentives[0].Id;
            tmc.mapExistingOffersByIndex.get(0).lstIncentives[0].Auto_Assign_for_Zuora_Subscription__c = true;
            tmc.mapExistingOffersByIndex.get(0).lstIncentives[1].Incentive__c = td.lstIncentives[1].Id;
            tmc.mapExistingOffersByIndex.get(0).lstIncentives[1].Auto_Assign_for_Zuora_Subscription__c = true;
            PageReference pr = tmc.saveAndNew();
            System.assertEquals(null, pr);
            List<String> lstParams = new List<String>{td.lstZProducts[0].Name, td.lstOffers[0].Name};
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), String.format(Label.TCodeSetup_Only_one_auto_incentive_validation, lstParams)));
        Test.stopTest();
    }
}