/**
* Author:       Sally ElGhoul (Accenture)
* Date:         16/10/2015
* Description:  this class is a utility for managing Salesforce custom offer code object
*
* ******************* Change Log *******************
* Modified by       Change Date  
* Wiktor Czykin     16/05/2017  //modified to work with new Offer__c object   
**/
public class OfferCode_Utility {
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        16/10/2015
    Function    add Offer Code in Salesforce after calling CoreApi
    ******************* Change Log *******************
    Modified by     Change Date
    Wiktor Czykin   16/05/2017  //modified to use Offer__c object
    ****************************************************************************************/
    public static Quote_Offer_Code__c addNewOfferCode(Id quoteId, Offer__c offerCodeDetailObj, Id quoteRatePlanChargeId, String offerType){
        Quote_Offer_Code__c offerCodeObj = new Quote_Offer_Code__c();
       
        offerCodeObj.Name__c = offerCodeDetailObj.Name__c;
        offerCodeObj.Description__c = offerCodeDetailObj.Description__c;
        offerCodeObj.Quote__c = quoteId;
        if(quoteRatePlanChargeId != null){
            offerCodeObj.Quote_Rate_Plan_Charge__c = quoteRatePlanChargeId;
        }
        
        if(offerCodeDetailObj.Discount__c != null){
            offerCodeObj.Blling_Period__c = GlobalQueries.replaceOfferFrequencyForApi(offerCodeDetailObj.Frequency__c);
            offerCodeObj.Discount_Amount__c = offerCodeDetailObj.Discount__c;
            offerCodeObj.Number_of_Periods__c = offerCodeDetailObj.Discount_Duration__c;
        }
        offerCodeObj.Type__c=offerType;
        offerCodeObj.Offer_Code_Value__c = offerCodeDetailObj.Name;
        offerCodeObj.Creation_Date__c = DateTime.now();
        return offerCodeObj;
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        16/10/2015
    Function    Get All Offer Codes of the quote
    ******************* Change Log *******************
    Modified by     Change Date
    Wiktor Czykin   16/05/2017  //simplified
    ****************************************************************************************/
    public static List<Quote_Offer_Code__c> getAllQuoteOfferCodes(String quoteId){
        return Database.query(GlobalQueries.queryBuilderSelectAll('Quote_Offer_Code__c', null, 'Quote__c=\''+quoteId+'\'', null, '5000'));
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        26/10/2015
    Function    Get All Active Offer Codes of the quote
    ******************* Change Log *******************
    Modified by     Change Date
    Wiktor Czykin   16/05/2017  //simplified
    ****************************************************************************************/
    public static List<Quote_Offer_Code__c> getAllOfferCodes(String whereCondition){
        return Database.query(GlobalQueries.queryBuilderSelectAll('Quote_Offer_Code__c', null, whereCondition, null, '5000'));
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        21/10/2015
    Function    Clone offer codes from the previous quote to the new one
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void cloneOfferCodes(Set<Id> setPreviousQuoteIds, Map<Id, Id> mapPreviousQuoteCurrentQuoteIds){
        //List of the new offer codes we want to insert for the new quote
        List<Quote_Offer_Code__c> lstNewOfferCodes = new List<Quote_Offer_Code__c>();
        
        //get the offer quotes of the previous quotes
        if(setPreviousQuoteIds!=null && setPreviousQuoteIds.size()>0){
            
            //get the active offer codes of the previous quotes
            String quoteOfferCodes = GlobalQueries.queryBuilderSelectAll('Quote_Offer_Code__c', null, '', null, '5000');
            quoteOfferCodes = quoteOfferCodes.replace('Quote_Offer_Code__c','Quote_Offer_Codes__r');
            String quoteQuery = 'select id,('+quoteOfferCodes+') from zqu__Quote__c where id in:setPreviousQuoteIds';
            System.debug('check quoteQuery: '+quoteQuery);
            List<zqu__Quote__c> lstPreviousQuotes = Database.query(quoteQuery);
                                                        
            if(lstPreviousQuotes!=null && lstPreviousQuotes.size()>0){
                //loop on the previous quots
                for(zqu__Quote__c prevQuoteObj : lstPreviousQuotes){
                    if(mapPreviousQuoteCurrentQuoteIds.containskey(prevQuoteObj.id)){
                        Id newQuoteId=mapPreviousQuoteCurrentQuoteIds.get(prevQuoteObj.Id);
                        if(prevQuoteObj.Quote_Offer_Codes__r!=null && prevQuoteObj.Quote_Offer_Codes__r.size()>0){
                            //clone the offer codes
                            List<Quote_Offer_Code__c> lstClonedOfferCodes=prevQuoteObj.Quote_Offer_Codes__r.deepClone(false,false,false);
                            
                            //link the cloned offer codes to the quote and mark them as cloned
                            for(Quote_Offer_Code__c offerCodeObj : lstClonedOfferCodes){
                                offerCodeObj.Quote__c=newQuoteId;
                                offerCodeObj.isOfferCodeCloned__c=true; //to diffrentiate between offer codes cloned from previous quote and the offers newly added to the new quote
                            }
                            //insert the cloned offer codes
                            if(lstClonedOfferCodes!=null && lstClonedOfferCodes.size()>0){
                                lstNewOfferCodes.addall(lstClonedOfferCodes);
                            }
                        }
                    }
                }
                if(lstNewOfferCodes!=null && lstNewOfferCodes.size()>0){
                    insert lstNewOfferCodes;
                }
            }
        }
    }
}