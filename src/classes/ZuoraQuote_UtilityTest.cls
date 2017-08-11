/**
* Author:       Sally ElGhoul (Accenture)
* Date:         30/10/2015
* Description:  this class for testing ZuoraQuote_Utility
*
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin     06/06/2017 //modified to minimize usage of "nasty" methods from TestDataUtility. Not wasting time on full refactor.
**/

@isTest(SeeAllData=true)
private class ZuoraQuote_UtilityTest {

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        30/10/2015
    Function    
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       08/06/2017  //minor clean-up
    ****************************************************************************************/
    private static testMethod void myUnitTest() {
        TestDataUtility td = new TestDataUtility(1);
        td.createRegistrants();
        
        Test.startTest();
            zqu__Quote__c quoteObj = ZuoraQuote_Utility.createZuoraQuote(null, td.lstRegistrants[0], Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE,null);
            insert quoteObj;
            
            List<zqu__Quote__c> lstQuotes = [select Id from zqu__Quote__c where zqu__Account__c = :td.lstRegistrants[0].Id and zqu__SubscriptionType__c = :Constants.QUOTE_SUBSCRIPTION_TYPE_NEW_VALUE];
            System.assertEquals(1, lstQuotes.size());
            
            //create billing account
            td.createBillingAccountToRegistrant(td.lstRegistrants[0].Id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
            
            //subscription creation
            td.createZuoraSubscriptionToRegistrant(td.lstRegistrants[0].id);
            td.lstZuoraSubscriptions[0].Zuora__NextChargeDate__c=Date.Today().addMonths(1);
            td.lstZuoraSubscriptions[0].Zuora__SubscriptionStartDate__c=date.today();
            td.lstZuoraSubscriptions[0].Original_Zuora_Subscription_ID__c='1234555';
            td.lstZuoraSubscriptions[0].Master_Quote__c=quoteObj.id;
            td.lstZuoraSubscriptions[0].Related_Quote__c=quoteObj.id;
            update td.lstZuoraSubscriptions[0];
            
            zqu__Quote__c amendmentQuoteObj=ZuoraQuote_Utility.createZuoraQuote(null, td.lstRegistrants[0], Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE, td.lstZuoraSubscriptions[0]);
            insert amendmentQuoteObj;
            Integer cycle = ZuoraQuote_Utility.getBillCycleDay(1989, 11,11);
            cycle = ZuoraQuote_Utility.getBillCycleDay(2015, 2,30);
        Test.stopTest();
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        30/10/2015
    Function    
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       08/06/2017  //minor clean-up, changed the data creation methods used
    ****************************************************************************************/
    private static testMethod void testingMethod() {
        TestDataUtility td = new TestDataUtility(1);
        td.createQuoteRatePlanCharges();

        Test.startTest();
            ZuoraQuote_Utility.getQuoteProductRatePlan(td.lstZQuotes[0].Id);

            List<zqu__QuoteRatePlan__c> lstAllQuoteRatePlans = ZuoraQuote_Utility.getQuoteAllRatePlans(td.lstZQuotes[0].Id);
            Map<Id, List<zqu__QuoteRatePlanCharge__c>> mapQuoteRatePlanCharges = ZuoraQuote_Utility.getQuoteRatePlanCharges(lstAllQuoteRatePlans);
            
            try{
                zqu__Quote__c quoteObj = ZuoraQuote_Utility.getQuoteRecord(null);
                System.assert(false, 'error not thrown where should be');
            }catch(Exception e){
                System.assertEquals('Quote Id must be passed.', e.getMessage());
            }
            
            zqu__Quote__c quoteObj = ZuoraQuote_Utility.getQuoteRecord(td.lstZQuotes[0].Id);
            List<zqu__QuoteAmendment__c> lstQuoteAmendments=ZuoraQuote_Utility.getQuoteAllAmendments(td.lstZQuotes[0].id);
            Map<id,List<zqu__QuoteRatePlan__c>> mapQuoteAmendmentsRatePlan = ZuoraQuote_Utility.getQuoteAmendmentRatePlans(lstQuoteAmendments);
            for( Id key: mapQuoteAmendmentsRatePlan.keySet()){
                Map<id,List<zqu__QuoteRatePlanCharge__c>> mapQuoteAmendmentRatePlanCharges = ZuoraQuote_Utility.getQuoteAmendmentRatePlanCharges(mapQuoteAmendmentsRatePlan.get(key));
            }
        Test.stopTest();
    }
}