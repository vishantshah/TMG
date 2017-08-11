/**
* @author Pawel Chrzanowski
* @date 13/01/2017
* @description  Quote Restricted Offer Warning Extension
#############Change Log#############
Modified by     Change Date
Wiktor Czykin   31/05/2017  //modified constructor
**/
public class QuoteRestrictedOfferWarningExtension {

    public String warningVisibility {get;set;}
    public String lockPeriod {get;set;}
    private Id quoteId;

    /***************************************************************************************
    Developer   Pawel Chrzanowski
    Date        13/01/2017
    Function    Constructor
    ******************* Change Log *******************
    Modified by     Change Date
    Wiktor Czykin   31/05/2017  //replace visibility css with display  
    ****************************************************************************************/
    public QuoteRestrictedOfferWarningExtension(ApexPages.StandardController stdController){
        warningVisibility = 'none';
        quoteId = stdController.getId();
        
        //get related Account
        List<zqu__Quote__c> lstQuotes = [SELECT zqu__Account__c FROM zqu__Quote__c WHERE zqu__Status__c = :Constants.QUOTE_STATUS_NEW_VALUE AND Id = :quoteId];
        if(lstQuotes.isEmpty() || lstQuotes[0].zqu__Account__c == null) return;
        
        //get related Quote Rate Plan
        String discountRatePlanName='%'+Constants.DISCOUNT_RATE_PLAN_NAME.tolowerCase()+'%';
        List<zqu__QuoteRatePlan__c> lstQRP = [SELECT zqu__QuoteProductName__c FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__c = :quoteId AND (NOT zqu__ProductRatePlan__r.Name LIKE :discountRatePlanName)];
        if(lstQRP.isEmpty() || lstQRP[0].zqu__QuoteProductName__c == null) return;
        
        //get related Product
        List<zqu__ZProduct__c> lstProduct = [SELECT Id FROM zqu__ZProduct__c WHERE Name = :lstQRP[0].zqu__QuoteProductName__c];
        if(lstProduct.isEmpty()) return;
        
        //get related ROU
        List<Restricted_Offer_Usage__c> lstROU = [SELECT Lock_in_Expiry_Date__c, Ignore_Lock_in_Period__c, Product__r.RestrictedOfferLockinPeriod__c FROM Restricted_Offer_Usage__c WHERE Account__c = :lstQuotes[0].zqu__Account__c AND Product__c = :lstProduct[0].Id ORDER BY CreatedDate DESC];
        if(lstROU.isEmpty() || lstROU[0].Lock_in_Expiry_Date__c == null || (lstROU[0].Ignore_Lock_in_Period__c != null && lstROU[0].Ignore_Lock_in_Period__c)){
            return;
        }else if(Date.today() <= lstROU[0].Lock_in_Expiry_Date__c){
            warningVisibility = 'block';
            lockPeriod = lstROU[0].Product__r.RestrictedOfferLockinPeriod__c != null ? lstROU[0].Product__r.RestrictedOfferLockinPeriod__c : '0';
        }
    }
}