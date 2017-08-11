/**
* @author Pawel Chrzanowski
* @date 17/01/2017
* @description Test class for QuoteRestrictedOfferWarningExtension
#############Change Log#############
Modified by     Change Date
Wiktor Czykin   31/05/2017  //modified visibility to diplay across tests
**/
@isTest
private class QuoteRestrictedOfferWarningExtensionTest{

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 17/01/2017
    Test negative scenarios of Quote Restricted Offer Warning validation
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   31/05/2017  //modified hidden to none
    ****************************************************************************************/
    @isTest static void extenstionTest_negative(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createRegistrants();
        tdu.createZProducts();
        
        zqu__Quote__c quote = new zqu__Quote__c(zqu__Subscription_Term_Type__c='Termed', zqu__RenewalSetting__c='RENEW_WITH_SPECIFIC_TERM', zqu__ValidUntil__c = Date.today());
        insert quote;
        
        ApexPages.StandardController sc;
        QuoteRestrictedOfferWarningExtension ext;
        
        //no Account
        sc = new ApexPages.StandardController(quote);
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('none', ext.warningVisibility);
        
        //no Quote Rate Plan
        quote.zqu__Account__c = tdu.lstRegistrants[0].Id;
        update quote;
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('none', ext.warningVisibility);
        
        //no Product
        zqu__QuoteAmendment__c quoteA = new zqu__QuoteAmendment__c(zqu__Quote__c = quote.Id, zqu__Type__c = 'NewProduct');
        insert quoteA;
        zqu__QuoteRatePlan__c quoteRP = new zqu__QuoteRatePlan__c(zqu__Quote__c = quote.Id, zqu__QuoteAmendment__c = quoteA.Id, zqu__QuoteProductName__c = 'none');
        insert quoteRP;
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('none', ext.warningVisibility);
        
        //no ROU
        quoteRP.zqu__QuoteProductName__c = tdu.lstZproducts[0].Name;
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('none', ext.warningVisibility);
    }
    
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 17/01/2017
    Test positive scenarios of Quote Restricted Offer Warning validation
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   31/05/2017  //modified hidden to none, visible to block
    ****************************************************************************************/
    @isTest static void extenstionTest_positive(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createRegistrants();
        tdu.createZProducts();
        tdu.createZuoraSubscription();
        
        tdu.lstZproducts[0].RestrictedOfferLockinPeriod__c = '6';
        update tdu.lstZproducts;
        
        tdu.lstZuoraSubscriptions[0].Zuora__SubscriptionEndDate__c = Date.today();
        update tdu.lstZuoraSubscriptions;
        
        zqu__Quote__c quote = new zqu__Quote__c(zqu__Account__c = tdu.lstRegistrants[0].Id, zqu__Status__c=Constants.QUOTE_STATUS_NEW_VALUE, zqu__Subscription_Term_Type__c='Termed', zqu__RenewalSetting__c='RENEW_WITH_SPECIFIC_TERM', zqu__ValidUntil__c = Date.today());
        insert quote;
        
        zqu__QuoteAmendment__c quoteA = new zqu__QuoteAmendment__c(zqu__Quote__c = quote.Id, zqu__Type__c = 'NewProduct');
        insert quoteA;

        zqu__ProductRatePlan__c productRP = [SELECT Id from zqu__ProductRatePlan__c WHERE Name = 'Monthly Open Offer Plan' LIMIT 1];
        zqu__QuoteRatePlan__c quoteRP = new zqu__QuoteRatePlan__c(zqu__Quote__c = quote.Id, zqu__QuoteProductName__c = tdu.lstZproducts[0].Name, zqu__QuoteAmendment__c = quoteA.Id, zqu__ProductRatePlan__c = productRP.Id);
        insert quoteRP;
        
        Restricted_Offer_Usage__c rou = new Restricted_Offer_Usage__c(Account__c = tdu.lstRegistrants[0].Id, Product__c = tdu.lstZproducts[0].Id, Subscription__c = tdu.lstZuoraSubscriptions[0].Id);
        insert rou;
        
        ApexPages.StandardController sc;
        QuoteRestrictedOfferWarningExtension ext;

        //validation positive
        sc = new ApexPages.StandardController(quote);
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('block', ext.warningVisibility);

        //ignore lock-in period
        rou.Ignore_Lock_in_Period__c = true;
        update rou;
        sc = new ApexPages.StandardController(quote);
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('none', ext.warningVisibility);

        //lock expired
        rou.Ignore_Lock_in_Period__c = false;
        update rou;
        tdu.lstZuoraSubscriptions[0].Zuora__SubscriptionEndDate__c = Date.today().addYears(-1);
        update tdu.lstZuoraSubscriptions;
        sc = new ApexPages.StandardController(quote);
        ext = new QuoteRestrictedOfferWarningExtension(sc);
        System.assertEquals('none', ext.warningVisibility);
    }

}