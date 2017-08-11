/**
* Author:       Sally ElGhoul (Accenture)
* Date:         29/01/2016
* Description:  this class for testing ZQuoteOfferCodeTrigger 
*
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin     06/06/2017  //simplified - removed usage of "invalid" test data generation method
**/
@isTest
private class ZQuoteOfferCodeTriggerHandlerTest {

    /***************************************************************************************
    Developer   Unknown
    Date        Unknown
    Function    test promo code update on quote
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       08/06/2017 //refactored a bit
    ****************************************************************************************/
    private static testMethod void testTrigger() {
        TestDataUtility td = new TestDataUtility(4);
        td.createZQuotes();
        
        List<Quote_Offer_Code__c> lst = new List<Quote_Offer_Code__c>();
        for(zqu__Quote__c q : td.lstZQuotes){
            lst.add(new Quote_Offer_Code__c(
                                            Quote__c = q.id,
                                            Offer_Code_Value__c = 'TestingPromoCode',
                                            Name__c = 'PromoCodeTestName',
                                            Number_of_Periods__c = 1,
                                            Discount_Amount__c = 2,
                                            Blling_Period__c = Constants.OFFER_FREQUENCY_MONTH,
                                            Type__c = Constants.OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE
            ));
        }
        Test.startTest();
            insert lst;
        
            List<zqu__Quote__c> lstQuotes = [select Id, PromoCode__c from zqu__Quote__c where Id in :td.lstZQuotes];
            for(zqu__Quote__c q : lstQuotes){
                System.assertEquals('TestingPromoCode', q.PromoCode__c);
            }
            
            //check after deleting thw quote offer code the promo quote on quote is cleared
            delete lst;
            lstQuotes = [select id,PromoCode__c from zqu__Quote__c where id in :td.lstZQuotes];
            for(zqu__Quote__c q : lstQuotes){
                System.assertEquals(null, q.PromoCode__c);
            }
        Test.stopTest();
    }
}