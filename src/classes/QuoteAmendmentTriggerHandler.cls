/**
* Author:       Sally ElGhoul (Tquila)
* Date:         15/06/2015
* Description:  this is the handler class for the trigger on zqu__QuoteAmendment__c object
*
* ******************* Change Log *******************
* Modified by       Change Date   
* Wiktor Czykin     10/05/2017  //modified setQuoteRatePlanIds() 
* Wiktor Czykin     15/06/2017  //cosmetic changes 
**/
public class QuoteAmendmentTriggerHandler {
    
    private static QuoteAmendmentTriggerHandler quoteAmendmentTriggerHandlerInstance;
    
    public static QuoteAmendmentTriggerHandler getInstance() {
        if (quoteAmendmentTriggerHandlerInstance == null) quoteAmendmentTriggerHandlerInstance = new QuoteAmendmentTriggerHandler();
        return quoteAmendmentTriggerHandlerInstance; 
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        15/01/2016
    Function    This function is called to handle the before update action on quote amendment
                I didn't use the before insert in this case because the values gets overriden
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/ 
    public void OnBeforeUpdate(zqu__QuoteAmendment__c[] newQuoteAmendments){
        adjustQuoteAmendmentDescription(newQuoteAmendments);
    }
        
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        19/10/2015
    Function    handle the before delete action on quote product feature
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/ 
    public void OnBeforeDelete(zqu__QuoteAmendment__c[] deleteQuoteAmendments, Map<Id,zqu__QuoteAmendment__c> deleteQuoteAmendmentsMap){
        //soft delete salesforce offer codes using the rate plan Ids
        //this will apply only to the offers added to the current quote
        //if offers added in previous quote they can't be deleted
        deleteSalesforceOfferCodes(deleteQuoteAmendmentsMap);
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        19/10/2015
    Function    get the rate plan Ids for this quote amendments we are trying to delete
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/ 
    private set<id> getQuoteRatePlanIds(Set<Id> setQuoteAmendmentIds){
        Set<Id> setQuoteRatePlanIds = new Set<Id>();
        for(zqu__QuoteRatePlan__c quoteRatePlanObj : [select Id from zqu__QuoteRatePlan__c where zqu__QuoteAmendment__c in : setQuoteAmendmentIds]){
            if(!setQuoteRatePlanIds.contains(quoteRatePlanObj.Id)){
                setQuoteRatePlanIds.add(quoteRatePlanObj.Id);
            }
        }
        return setQuoteRatePlanIds;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        19/10/2015
    Function    This function is called to delete salesforce offer code records (we do soft deletion by marking the field to be inactive)
                we had to add the logic on quote amendment object instead of qute rate plan charge object delete due to the data model 
                of zuora objects because quote rate plans charge has a master details relation with quote rate plan
                and quote rate plan has master detail relation with quote amendments
                so we needed to add the logic to the master object which is the quote amendments
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       10/05/2017  //modified query builder call (from SoqlUtility to GlobalQueries)
    ****************************************************************************************/ 
    private void deleteSalesforceOfferCodes(Map<Id,zqu__QuoteAmendment__c> mapQuoteAmendments){
        Set<Id> setQuoteRatePlanIds = getQuoteRatePlanIds(mapQuoteAmendments.keyset());

        String whereCondition='Quote_Rate_Plan_Charge__r.zqu__QuoteRatePlan__c in :setQuoteRatePlanIds';
        String offerCodesQueryString = GlobalQueries.queryBuilderSelectAll(Quote_Offer_Code__c.class.getName(), new Set<string>{'Quote_Rate_Plan_Charge__r.zqu__QuoteRatePlan__c'},whereCondition,null,'5000');
        
        //set of quote Ids
        Set<Id> setQuoteIds = new Set<Id>();
        
        //get the offer codes using the rate plan ids
        List<Quote_Offer_Code__c> lstDeleteOfferCodes = Database.query(offerCodesQueryString);
        
        if(lstDeleteOfferCodes!=null && lstDeleteOfferCodes.size()>0){
            //fill the set quote Ids for offer codes that will be deleted if of type acquisition or default offer code
            for(Quote_Offer_Code__c  offerObj: lstDeleteOfferCodes){
                if((offerObj.Type__c == Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE || offerObj.Type__c == Constants.OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE) && !setQuoteIds.contains(offerObj.Quote__c)){
                    setQuoteIds.add(OfferObj.Quote__c);
                }
            }
            //delete offers
            delete lstDeleteOfferCodes;
            //clear the tcode lookup and campaign code feilds on the quote records
            if(setQuoteIds!=null && setQuoteIds.size()>0){
                List<zqu__Quote__c> lstQuotes = [select Tcode__c,id from zqu__Quote__c where id in:setQuoteIds];
                if(lstQuotes!=null && lstQuotes.size()>0){
                    for(zqu__Quote__c quoteObj: lstQuotes){
                        quoteObj.Tcode__c=null;
                    }
                    //update the quotes to clear the tcode and campaign code
                    update lstQuotes;
                }
            }
        }
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        15/01/2016
    Function    Call the function that will check the quote type and in case of 
                amendment quote it will to the test mid term discount to the quote amendment's description 
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       15/06/2017  //simplified 
    ****************************************************************************************/ 
    private void adjustQuoteAmendmentDescription(zqu__QuoteAmendment__c[] newQuoteAmendments){
        Set<Id> setQuoteIds = new Set<Id>();
        Map<Id,string> mapQuoteSubscriptionType = new Map<Id, String>();
        
        //set of Amendments quote Ids
        for(zqu__QuoteAmendment__c quoteAmendmentObj : newQuoteAmendments){
            if(!setQuoteIds.contains(quoteAmendmentObj.zqu__Quote__c)){
                setQuoteIds.add(quoteAmendmentObj.zqu__Quote__c);
            }   
        }
        
        //get the quote subscription type because we don't want to change of the quote amendment in new quote or cancellation
        List<zqu__Quote__c> lstQuotes = [select Id, zqu__SubscriptionType__c from zqu__Quote__c where Id in :setQuoteIds];
        if(lstQuotes!=null){
            for(zqu__Quote__c quoteObj : lstQuotes){
                if(!mapQuoteSubscriptionType.containsKey(quoteObj.Id)){
                    mapQuoteSubscriptionType.put(quoteObj.Id, quoteObj.zqu__SubscriptionType__c);
                }
            }
        }
        
        //change the amendment description text
        for(zqu__QuoteAmendment__c quoteAmendmentObj : newQuoteAmendments){
            //get the quote subscription type
            String quoteSubscriptionType = mapQuoteSubscriptionType.get(quoteAmendmentObj.zqu__Quote__c);
            
            //check that the quote subscription is amendment as mid term discounts are added only for quote amednments
            //check that the type of amendment is newProduct
            //check that the product added is a dicsount , because only mid term discounts are available in amendment quotes
            if(String.isNotBlank(quoteSubscriptionType) && quoteSubscriptionType == Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE 
                && quoteAmendmentObj.zqu__Type__c == Constants.RATE_PLAN_NEW_PRODUCT_AMENDMENT_TYPE 
                && quoteAmendmentObj.zqu__Description__c.tolowerCase().contains(Constants.SUBSCRIPTION_PRODUCTCHARGE_DISCOUNT_VALUE)){
                
                //modify the amendment description to contain the mid term discount text to description
                quoteAmendmentObj.zqu__Description__c += ' '+Label.Amendment_Description_Mid_Term_Discount_Text;
            }
        } 
    }
}