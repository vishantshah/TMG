/**
* @author Wiktor Czykin
* @date 15/06/2017
* @description Test class for QuoteAmendmentTriggerHandler
#############Change Log#############
Modified by     Change Date
**/

@isTest
private class QuoteAmendmentTriggerHandlerTest {

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        15/06/2017
    Function    test update action adjustQuoteAmendmentDescription()
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/ 
    private static testMethod void testDescriptionUpdate(){
        TestDataUtility td = new TestDataUtility(3);
        td.createQuoteAmendments();

        for(zqu__Quote__c q : td.lstZQuotes){
            q.zqu__SubscriptionType__c = Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE;
        }
        update td.lstZQuotes;

        Test.startTest();
            for(zqu__QuoteAmendment__c qa : td.lstQuoteAmendments){
                qa.zqu__Type__c = Constants.RATE_PLAN_NEW_PRODUCT_AMENDMENT_TYPE;
                qa.zqu__Description__c = Constants.SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE;
                
            }
            update td.lstQuoteAmendments;
        Test.stopTest();
        List<zqu__QuoteAmendment__c> lstAmendments = [SELECT Id, zqu__Description__c FROM zqu__QuoteAmendment__c];
        Map<Id, zqu__QuoteAmendment__c> mapAmendments = new Map<Id, zqu__QuoteAmendment__c>(td.lstQuoteAmendments);
        System.assert(!lstAmendments.isEmpty());
        for(zqu__QuoteAmendment__c qa : lstAmendments){
            System.assertEquals(mapAmendments.get(qa.Id).zqu__Description__c+' '+Label.Amendment_Description_Mid_Term_Discount_Text, qa.zqu__Description__c, 'description value not updated correctly');
        }
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        15/06/2017
    Function    test update action deleteSalesforceOfferCodes()
                -to check if respective quote is updated correctly
                -quote offer codes are removed
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/ 
    private static testMethod void testDeleteAction(){
        TestDataUtility td = new TestDataUtility(3);
        td.createTCodeManagement();
        td.createQuoteRatePlanCharges();

        List<Quote_Offer_Code__c> lstQoc = new List<Quote_Offer_Code__c>();
        for(Integer i = 0; i < td.iCounter; i++){
            td.lstZQuotes[i].Tcode__c = td.lstTCodeManagement[i].Id;
            lstQoc.add(OfferCode_Utility.addNewOfferCode(td.lstZQuotes[i].Id, td.lstOffers[i], td.lstQuoteRatePlanCharges[i].Id, Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE));
        }
        update td.lstZQuotes;
        insert lstQoc;

        Test.startTest();
            delete td.lstQuoteAmendments;
        Test.stopTest();

        List<Quote_Offer_Code__c> lstQocRefetch = [SELECT Id FROM Quote_Offer_Code__c];
        System.assert(lstQocRefetch.isEmpty(), 'records not deleted as they should');
        List<zqu__Quote__c> lstQuotes = [SELECT Id, Tcode__c, PromoCode__c FROM zqu__Quote__c];
        System.assert(!lstQuotes.isEmpty());
        for(zqu__Quote__c q : lstQuotes){
            System.assertEquals(null, q.PromoCode__c, 'promo code not blanked out as it should be');
            System.assertEquals(null, q.Tcode__c, 'tcode not blanked out as it should be');
        }
    }
}