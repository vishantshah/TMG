    /**
* Author:       Sally ElGhoul (Tquila)
* Date:         27/05/2015
* Description:  this class for testing Zuora_OfferCodeStepController
*
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin     17/02/2016    //modified testQuoteAmendmentOfferCodeEntered() so that it doesnt fail
* Wiktor Czykin     30/05/2017    //rewritten    
**/
@isTest
private class Zuora_OfferCodeStepControllerTest{

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        27/05/2015
    Function    validate that if no quote selected a friendly error message will be sent back to the user
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin        1.1        04/08/2016 - clean-up
    ****************************************************************************************/
    private static testMethod void testNoIdParamForQuote() {
        zqu__Quote__c quoteObj = new zqu__Quote__c();
        Test.startTest();
            try{ 
                Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(quoteObj));
                System.assert(false, 'exception not thrown where should be');    
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Offer_Selection_Missing_quote_id));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        27/05/2017
    Function    test no quote can be found for specified id
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoQuoteFound() {
        TestDataUtility td = new TestDataUtility(1);
        td.createZquotes();
        Test.startTest();
            delete td.lstZQuotes[0];
            try{
                Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Offer_Selection_No_quote_found));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        27/05/2017
    Function    test no quote rate plan can be found for quote
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoQuoteRatePlanFound() {
        TestDataUtility td = new TestDataUtility(1);
        td.createZquotes();
        Test.startTest() ;
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(!controller.bShowPage);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Campaign_Product_Required_Error_Message));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        30/05/2017
    Function    test no quote rate plan charge can be found for quote rate plan
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoQuoteRatePlanChargeFound() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlans();
        Test.startTest() ;
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(!controller.bShowPage);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Selection_No_rate_plan_charge_for_quote));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        30/05/2017
    Function    test no product based on quote rate plan charge can be found for quote 
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoQuoteRatePlanChargeProductFound() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        Test.startTest();
            td.lstQuoteRatePlans[0].zqu__QuoteProductName__c = null;
            update td.lstQuoteRatePlans;
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(!controller.bShowPage);
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Selection_Unable_to_find_product_based_on_rate_plan));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        30/05/2017
    Function    test error when there is no promotion offer for set of parameters
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testNoTCodeProductOffer() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        Test.startTest();
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Selection_No_promotion_campaign_for_product));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        30/05/2017
    Function    test error with max price
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testWrongProductMaxPrice() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        td.lstZProducts[0].MaxCoverPriceAnnual__c = 'test';
        update td.lstZProducts;

        Test.startTest();
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offer_Selection_Maximum_comparison_price_parse_failure));
        Test.stopTest();
    }
    
    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        30/05/2017
    Function    test positive init promo offer code
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testPositiveInitAndCancell() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        td.createTCodeProductOffers();
        for(Offer__c offer : td.lstOffers){
            offer.Frequency__c = Constants.OFFER_FREQUENCY_ANNUALLY;
        }
        update td.lstOffers;

        Test.startTest();
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(ApexPages.getMessages().isEmpty(), ApexPages.getMessages());
            System.assert(controller.cancel().getUrl().contains(td.lstZQuotes[0].Id));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        30/05/2017
    Function    test all scenarios related to addOfferCode - both positive and negative
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testAddOfferCode() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        td.createTCodeProductOffers();
        for(Offer__c offer : td.lstOffers){
            offer.Frequency__c = Constants.OFFER_FREQUENCY_ANNUALLY;
        }
        update td.lstOffers;

        Test.startTest();
            Zuora_OfferCodeStepController controller = new Zuora_OfferCodeStepController(new ApexPages.StandardController(td.lstZQuotes[0]));
            System.assert(ApexPages.getMessages().isEmpty(), ApexPages.getMessages());
            controller.addOfferCode();
            Map<String, String> mapResponse = (Map<String, String>)JSON.deserialize(controller.sResponse, Map<String, String>.class);
            System.assertEquals('true', mapResponse.get(Zuora_OfferCodeStepController.RESPONSE_ERROR));
            System.assertEquals(Label.Required_Campaign, mapResponse.get(Zuora_OfferCodeStepController.RESPONSE_MESSAGE));

            controller.selectedId = td.lstTCodeProductOffers[0].Id;
            controller.addOfferCode();
            mapResponse = (Map<String, String>)JSON.deserialize(controller.sResponse, Map<String, String>.class);
            System.assertEquals('false', mapResponse.get(Zuora_OfferCodeStepController.RESPONSE_ERROR));
            System.assertEquals(Label.Campaign_Addition_Confirmation_Message, mapResponse.get(Zuora_OfferCodeStepController.RESPONSE_MESSAGE));
            List<zqu__Quote__c> lstQuote = [select Id, Tcode__c from zqu__Quote__c where Id = :td.lstZQuotes[0].Id];
            System.assert(!lstQuote.isEmpty());
            System.assertEquals(td.lstTCodeManagement[0].Id, lstQuote[0].Tcode__c);

            controller.selectedId = td.lstZQuotes[0].Id;
            controller.addOfferCode();
            mapResponse = (Map<String, String>)JSON.deserialize(controller.sResponse, Map<String, String>.class);
            System.assertEquals('true', mapResponse.get(Zuora_OfferCodeStepController.RESPONSE_ERROR));
            System.assertEquals(Label.Required_Campaign, mapResponse.get(Zuora_OfferCodeStepController.RESPONSE_MESSAGE));
        Test.stopTest();
    }
}
