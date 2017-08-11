/**
* Author:       Gavin Palmer (Accenture)
* Date:         20/04/2016
* Description:  Test class for the PricePlanRulesSetupController
*
* ******************* Change Log *******************
* Modified by       Change Date     Description
**/
@isTest
private class PricePlanRulesSetupControllerTest{

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Method to set up the test data for the unit test
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @testSetup
    static void testDataSetup(){
        TestDataUtility testUtility = new TestDataUtility(10);

        testUtility.createPricePlanDefaultOffers(5);
        testUtility.createPricePlanOffers(5);

        // make 10 zProducts
        testUtility.iCounter = 10;
        testUtility.createZProduct();

        testUtility.CreateCoreApiAllOfferCodesEndPointSetting();
        testUtility.CreateCoreApiEndPointSettings();
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Setup the test page that will be called at the beginning of each unit test
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    private static String setupTestPage(){
        // query for price plan record
        String planId = [
            SELECT Id
            FROM Plan__c
            LIMIT 1
        ].Id;

        Test.setCurrentPage(Page.PricePlanRulesSetup);
        // pass in the id for the price plan record
        ApexPages.currentPage().getParameters().put('id', planId);

        // set the mock callout response
        Test.setMock(HttpCalloutMock.class, new GetAllOfferCodesHTTPResponceMock());

        return planId;
    }


    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages constructor
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void constructorTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
        Test.stopTest();

        System.assertEquals(8, controller.allOffersObj.offers.size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test various methods which drive the page functionality
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void pageFunctionalityTest() {

        String planId = setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.AddNewPricePlanRule();
            List<SelectOption> selectOptions = controller.getPossibleFrequencyValues();
            String endURL = controller.returnToDetailPage().getURL();
        Test.stopTest();

        // check that the price plan section would dislay
        System.assertEquals(true, controller.displayEditSection);
        System.assertEquals(true, controller.pricePlanDefaultOffer.Default_Offer__c);
        System.assertEquals(planId, controller.pricePlanRuleObj.Plan__c);

        // close the price plan section and check it
        controller.CancelPricePlanRuleChanges();
        System.assertEquals(false, controller.displayEditSection);

        // check that the picklist was populated
        System.assertEquals(3, selectOptions.size());

        // check that the page has successfully redirected to the record detail page
        PageReference expectedPageRefrence = new PageReference('/' + planId);
        System.assertEquals(expectedPageRefrence.getURL(), endURL);
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages getZuoraProducts method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void getZuoraProductsTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            List<SelectOption> selectOptions = controller.getZuoraProducts();
        Test.stopTest();

        // there should be 10 zuora products in the list and 1 '--none--'
        System.assertEquals(11, selectOptions.size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages EditPricePlanRule method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void editPricePlanRuleTest() {

        setupTestPage();
        Id pricePlanId = getPricePlan().Id;

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.selectedPricePlanRuleId = pricePlanId;
            controller.editPricePlanRule();
        Test.stopTest();

        // check that the correct objects were retrieved when the edit method is called
        System.assertEquals(5, controller.lstAlternativeOffers.size());
        System.assertNotEquals(null, controller.pricePlanDefaultOffer);
        System.assertEquals(pricePlanId, controller.pricePlanRuleObj.Id);
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages ClonePricePlanRule method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void clonePricePlanRuleTest() {

        setupTestPage();
        Price_Plan__c pricePlan = getPricePlan();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.selectedPricePlanRuleId = pricePlan.Id;
            controller.clonePricePlanRule();
        Test.stopTest();

        // assert that the record was cloned correctly
        System.assertEquals(5, controller.lstAlternativeOffers.size());
        System.assertNotEquals(null, controller.pricePlanDefaultOffer);
        System.assertEquals(pricePlan.Email_Template__c, controller.pricePlanRuleObj.Email_Template__c);
        System.assertEquals(pricePlan.Frequency__c, controller.pricePlanRuleObj.Frequency__c);
        System.assertEquals(pricePlan.High_Price__c, controller.pricePlanRuleObj.High_Price__c);
        System.assertEquals(pricePlan.Low_Price__c, controller.pricePlanRuleObj.Low_Price__c);
        System.assertEquals(pricePlan.Product_From__c, controller.pricePlanRuleObj.Product_From__c);
        System.assertEquals(pricePlan.Plan__c, controller.pricePlanRuleObj.Plan__c);
        System.assertNotEquals(pricePlan.Id, controller.pricePlanRuleObj.Id);
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages DeletePricePlanRule method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void deletePricePlanRuleTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            Price_Plan__c pp = getPricePlan();
            controller.selectedPricePlanRuleId = pp.Id;
            controller.DeletePricePlanRule();
        Test.stopTest();

        System.assertNotEquals(pp.Id, getPricePlan().Id);
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         21/04/2016
    * Description:  get the price plan id that was created in test setup
    *                Used by the price plan rule manipulation tests
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    private static Price_Plan__c getPricePlan(){
        List<Price_Plan__c> pricePlans = [
            SELECT
                Id,
                Email_Template__c,
                Frequency__c,
                High_Price__c,
                Low_Price__c,
                Product_From__c,
                Plan__c
            FROM Price_Plan__c
            LIMIT 1
        ];
        if(pricePlans.size() == 0) return null;
        return pricePlans[0];
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages SavePricePlanRuleChanges method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void savePricePlanRuleChangesTest() {

        Id zProductId = getZProductId();
        Id planId = [
            SELECT Id
            FROM Plan__c
            LIMIT 1
        ].Id;

        setupTestPage();

        PricePlanRulesSetupController.AlternativeOfferClass alternativeOffer = new PricePlanRulesSetupController.AlternativeOfferClass();
        alternativeOffer.alternativeOfferCode = 'Test Offer code';

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.pricePlanRuleObj = new Price_Plan__c();
            controller.pricePlanRuleObj.Product_From__c = zProductId;
            controller.pricePlanRuleObj.Plan__c = planId;
            controller.pricePlanRuleObj.Frequency__c = 'Monthly';
            controller.pricePlanRuleObj.Low_Price__c = 3;
            controller.pricePlanRuleObj.High_Price__c = 5;
            controller.pricePlanDefaultOffer = new Price_Plan_Offer__c();
            controller.pricePlanDefaultOffer.Offer_Code__c = 'Test Offer code';
            controller.lstAlternativeOffers = new List<PricePlanRulesSetupController.AlternativeOfferClass>();
            controller.lstAlternativeOffers.add(alternativeOffer);
            controller.mapOfferCodeOfferName.put('Test Offer code', 'string');
            controller.SavePricePlanRuleChanges();
        Test.stopTest();

        // check that the record has saved correctly
        List<Price_Plan__c> pricePlans = [
            SELECT Id,
            (
                SELECT Id
                FROM Price_Plan_Offers__r
            )
            FROM Price_Plan__c
            WHERE Product_From__c = :zProductId
        ];
        System.assertEquals(1, pricePlans.size());
        System.assertEquals(2, pricePlans[0].Price_Plan_Offers__r.size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         03/05/2016
    * Description:  Test the pages SavePricePlanRuleChanges method when an exception is thrown
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void savePricePlanRuleChangesExceptionTest() {

        Id zProductId = getZProductId();
        Id planId = [
            SELECT Id
            FROM Plan__c
            LIMIT 1
        ].Id;

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.pricePlanRuleObj = new Price_Plan__c();
            controller.pricePlanRuleObj.Product_From__c = zProductId;
            controller.pricePlanRuleObj.Plan__c = planId;
            controller.pricePlanRuleObj.Frequency__c = 'Monthly';
            controller.pricePlanRuleObj.Low_Price__c = 3;
            controller.pricePlanRuleObj.High_Price__c = 5;
            controller.pricePlanRuleObj.No_Price_Change__c = true;
            controller.SavePricePlanRuleChanges();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages());
        System.assertEquals(1, ApexPages.getMessages().size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages SavePricePlanRuleChanges method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void saveWithValidationFailureTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.pricePlanRuleObj = new Price_Plan__c();
            controller.pricePlanRuleObj.Product_From__c = getZProductId();
            controller.pricePlanRuleObj.Frequency__c = '';
            controller.pricePlanRuleObj.Low_Price__c = 1;
            controller.pricePlanRuleObj.High_Price__c = 0;
            controller.pricePlanRuleObj.No_Price_Change__c = false;
            controller.pricePlanDefaultOffer = new Price_Plan_Offer__c();
            controller.pricePlanDefaultOffer.Offer_Code__c = '';
            controller.SavePricePlanRuleChanges();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages());
        System.assertEquals(3, ApexPages.getMessages().size());
    }

    private static String getZProductId(){
        return [
            SELECT Id
            FROM zqu__ZProduct__c
            LIMIT 1
        ].Id;
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages getlstPricePlanRules method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void getlstPricePlanRulesTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            List<Price_Plan__c> pricePlanRules = controller.getlstPricePlanRules();
        Test.stopTest();

        System.assertEquals(1, pricePlanRules.size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages getlstDefaultOfferCodes method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void getlstDefaultOfferCodesTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.pricePlanRuleObj = new Price_Plan__c();
            controller.pricePlanRuleObj.Product_From__c = getZProductId();
            controller.pricePlanRuleObj.Frequency__c = 'Monthly';
            List<SelectOption> selectOptions = controller.getlstDefaultOfferCodes();
        Test.stopTest();

        // will only contain the --none-- option
        System.assertEquals(1, selectOptions.size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages getlstAllAvailableOffers method
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void getlstAllAvailableOffersTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            controller.pricePlanRuleObj = new Price_Plan__c();
            controller.pricePlanRuleObj.Product_From__c = getZProductId();
            controller.mapProductNameProductRegion.put(Constants.TABLET_UK_PRODUCT_NAME, 'testString');
            List<SelectOption> selectOptions = controller.getlstAllAvailableOffers();
        Test.stopTest();

        // will only contain the --none-- option
        System.assertEquals(1, selectOptions.size());
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         20/04/2016
    * Description:  Test the pages getlstAllAvailableOffers and removeAlternativeOffer methods
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    @isTest
    private static void addRemoveAvailableOffersTest() {

        setupTestPage();

        Test.startTest();
            PricePlanRulesSetupController controller = new PricePlanRulesSetupController();
            System.assertEquals(0, controller.lstAlternativeOffers.size());
            // add 2 records and check they are created, then delete one and check it was deleted
            controller.AddAlternativeOffer();
            controller.lstAlternativeOffers[0].isDeleted = true;
            controller.AddAlternativeOffer();
            System.assertEquals(2, controller.lstAlternativeOffers.size());

            controller.removeAlternativeOffer();
            System.assertEquals(1, controller.lstAlternativeOffers.size());
        Test.stopTest();
    }
}
