/**
* Author:       Sally ElGhoul (Accenture)
* Date:         26/01/2016
* Description:  Trigger handler for Zuora quote offer codes Object
*
* ******************* Change Log *******************
* Modified by       Change Date  
* Wiktor Czykin     06/06/2017 //minor cleanup
**/
public class ZQuoteOfferCodeTriggerHandler {

    private static ZQuoteOfferCodeTriggerHandler instance;
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        26/01/2016
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZQuoteOfferCodeTriggerHandler getInstance() {
        if (instance == null) instance = new ZQuoteOfferCodeTriggerHandler();
        return instance; 
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        26/01/2016
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterInsert(Quote_Offer_Code__c[] newQuoteOfferCodes, Map<Id, Quote_Offer_Code__c> newQuoteOfferCodesMap){
        //loop on the quote offer codes and check the type and if acquisition or default offer code , fill the quote promo code with the offer code
        updateQuoteOfferCode(newQuoteOfferCodes,false);
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        26/01/2016
    Function    this function is called to handle on after delete
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void OnAfterDelete(Quote_Offer_Code__c[] oldQuoteOfferCodes, Map<Id, Quote_Offer_Code__c> oldQuoteOfferCodesMap){
        //loop on the quote offer codes and check the type and if acquisition or default offer code , fill the quote promo code with the offer code
        updateQuoteOfferCode(oldQuoteOfferCodes,true);
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        26/01/2016
    Function    this function is called to update the promo code either with value or to clear it
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void updateQuoteOfferCode(Quote_Offer_Code__c[] lstQuoteOffercodes, Boolean isClearPromoCode){
        
        //list of updated quotes
        List<zqu__Quote__c> lstUpdateQuotes = new List<zqu__Quote__c>();
        Set<Id> setUpdateQuotes = new Set<Id>();
        
        //map of quotes
        Map<Id,zqu__Quote__c> mapQuotes = getQuotes(lstQuoteOffercodes);
        
        //loop on quote offer code and check if it is acquisition or default offer code, we need to update the quote promo code
        for(Quote_Offer_Code__c quoteOfferCodeObj : lstQuoteOffercodes){
            if((quoteOfferCodeObj.Type__c == Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE || quoteOfferCodeObj.Type__c == Constants.OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE)   
                && mapQuotes.containsKey(quoteOfferCodeObj.Quote__c)){
                    zqu__Quote__c updateQuoteObj = mapQuotes.get(quoteOfferCodeObj.Quote__c);

                    if(!setUpdateQuotes.contains(updateQuoteObj.id)){
                        //if the quote offer code is deleted we need to clear the promo code field
                        if(isClearPromoCode){
                            updateQuoteObj.PromoCode__c = '';
                        }else{ //if the quote offer code is added, we need to update the promo field with the offer code value
                            updateQuoteObj.PromoCode__c = quoteOfferCodeObj.Offer_Code_Value__c;
                        }
                        
                        lstUpdateQuotes.add(updateQuoteObj);
                        setUpdateQuotes.add(updateQuoteObj.Id);
                    }
              }
        }
        
        //update the quotes
        if(lstUpdateQuotes.size()>0){
            update lstUpdateQuotes;
        }
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        26/01/2016
    Function    this function is called to get the map of quotes
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       06/06/2017  //simplified
    ****************************************************************************************/
     private Map<Id, zqu__Quote__c> getQuotes(Quote_Offer_Code__c[] lstQuoteOffercodes){
        Map<Id,zqu__Quote__c> mapQuotes = new Map<Id,zqu__Quote__c>();
        Set<Id> setQuoteId = new Set<Id>();
        for(Quote_Offer_Code__c qoc : lstQuoteOffercodes){
            if(qoc.Quote__c != null){    
                setQuoteId.add(qoc.Quote__c);
            }
        }
        if(!setQuoteId.isEmpty()){
            mapQuotes = new Map<Id, zqu__Quote__c>([select Id, PromoCode__c from zqu__Quote__c where Id = :setQuoteId]);
        }
        return mapQuotes;
    }
}