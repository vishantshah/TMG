/**
* Author:       Sally ElGhoul (Accenture)
* Date:         12/10/2015
* Description:  this is testing class for OfferCode_Utility
* ******************* Change Log *******************
* Modified by       Change Date 
* Wiktor Czykin     30/07/2017  //rewritten    
**/
@isTest
private class OfferCode_UtilityTest {
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/05/2017
    Function - test Quote_Offer_Code__c record instance creation
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testAddNewOfferCode() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        td.lstOffers[0].Discount__c = 10;
        td.lstOffers[0].Discount_Duration__c = 1;
        update td.lstOffers[0];
        Test.startTest();
            Quote_Offer_Code__c qoc = OfferCode_Utility.addNewOfferCode(td.lstZQuotes[0].Id, td.lstOffers[0], td.lstQuoteRatePlanCharges[0].Id, Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE);
            System.assertNotEquals(null, qoc);
            System.assertEquals(td.lstOffers[0].Name, qoc.Offer_Code_Value__c);
            System.assertEquals(td.lstOffers[0].Name__c, qoc.Name__c);
            System.assertEquals(td.lstOffers[0].Description__c, qoc.Description__c);
            System.assertEquals(td.lstZQuotes[0].Id, qoc.Quote__c);
            System.assertEquals(td.lstQuoteRatePlanCharges[0].Id, qoc.Quote_Rate_Plan_Charge__c);
            System.assertEquals(td.lstOffers[0].Discount__c, qoc.Discount_Amount__c);
            System.assertEquals(Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE, qoc.Type__c);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/05/2017
    Function - test getAllQuoteOfferCodes()
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testGetAllQuoteOfferCodes() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        Test.startTest();
            Quote_Offer_Code__c qoc = OfferCode_Utility.addNewOfferCode(td.lstZQuotes[0].Id, td.lstOffers[0], td.lstQuoteRatePlanCharges[0].Id, Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE);
            insert qoc;
            List<Quote_Offer_Code__c> lst = OfferCode_Utility.getAllQuoteOfferCodes(td.lstZQuotes[0].Id);
            System.assert(!lst.isEmpty());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/05/2017
    Function - test getAllOfferCodes()
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testGetAllOfferCodes() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();
        Test.startTest();
            Quote_Offer_Code__c qoc = OfferCode_Utility.addNewOfferCode(td.lstZQuotes[0].Id, td.lstOffers[0], td.lstQuoteRatePlanCharges[0].Id, Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE);
            insert qoc;
            List<Quote_Offer_Code__c> lst = OfferCode_Utility.getAllOfferCodes('');
            System.assert(!lst.isEmpty());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/05/2017
    Function - test getAllOfferCodes()
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private static testMethod void testCloneOfferCodes() {
        TestDataUtility td = new TestDataUtility(2);
        td.createQuoteRatePlanCharges();
        Test.startTest();
            Quote_Offer_Code__c qoc = OfferCode_Utility.addNewOfferCode(td.lstZQuotes[0].Id, td.lstOffers[0], td.lstQuoteRatePlanCharges[0].Id, Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE);
            insert qoc;
            
            List<Quote_Offer_Code__c> lstClone = [select Id from Quote_Offer_Code__c where Quote__c = :td.lstZQuotes[1].Id];
            System.assert(lstClone.isEmpty());

            OfferCode_Utility.cloneOfferCodes(new Set<Id>{td.lstZQuotes[0].Id}, new Map<Id, Id>{td.lstZQuotes[0].Id => td.lstZQuotes[1].Id});

            lstClone = [select Id from Quote_Offer_Code__c where Quote__c = :td.lstZQuotes[1].Id];
            System.assert(!lstClone.isEmpty());
        Test.stopTest();
    }
}