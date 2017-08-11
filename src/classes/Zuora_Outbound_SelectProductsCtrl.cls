/**
* Author:       Sally ElGhoul (Accenture)
* Date:         25/11/2015
* Description:  this class is the controller for page Zuora_Outbound_SelectProducts
*
* ******************* Change Log *******************
* Modified by       Change Date    
* Sally ElGhoul 04/02/2016 Getting the subsequent discount duration from Custom setting 
* Sally ElGhoul 16/02/2016 Stop throwing an exception when subsequent price or start price = product price and handle the discount duration to be 54000 for renewals 
* Wiktor Czykin 12/06/2017 Removed stuff that didnt work and now wouldnt even compile because of the offer changes. Waiting for scope definition before can be rewritten. 
**/
public class Zuora_Outbound_SelectProductsCtrl {
    private final zqu__Quote__c quoteObj;   

    public zqu.NotificationOptions notificationOptions {get;set;}
    public Decimal quoteProductPrice {get;set;}
    public static TCodeManagement__c tcodeObj {get;set;}
    public String offerCodeValue {get;set;}
    public CoreApiResources.OfferCodeDetails offerCodeDetailsResult {get;set;}
    public static decimal subsequentPrice {get;set;}
    
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/11/2015
    Function    Constructor
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public Zuora_Outbound_SelectProductsCtrl(ApexPages.StandardController stdController) {
        if(stdController.getId() == null) throw new TelegraphApplicationException(Label.Offer_Selection_Missing_quote_id);
        this.quoteObj = (zqu__Quote__c)stdController.getRecord();
        notificationOptions = new zqu.NotificationOptions();
        notificationOptions.isPopup = true;
        notificationOptions.continueAction = 'goToQuotePage();';
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        25/11/2015
    Function    This function is called to add the outbound product
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/ 
    public PageReference addOutboundProduct(){
        try{
            //call zuora ustility to add the outbound product for the outbound quote
            Zuora_Utility.AddOutboundProduct(quoteObj.id,quoteObj.Outbound_Selected_Product__c.tolowerCase(),quoteObj.Outbound_Payment_Frequency__c.tolowerCase());
            //get the outbound product details
            zqu__QuoteRatePlan__c quoteProductRatePlan=ZuoraQuote_Utility.getQuoteProductRatePlan(quoteObj.id);
        
            if(quoteProductRatePlan!=null && quoteProductRatePlan.zqu__Quote_Rate_Plan_Charges__r!=null && quoteProductRatePlan.zqu__Quote_Rate_Plan_Charges__r.size()>0){
                
                //Get the effective price
                quoteProductPrice=quoteProductRatePlan.zqu__Quote_Rate_Plan_Charges__r[0].zqu__EffectivePrice__c;       
                
                //initialize the subsequent price to be the full product price
                subsequentPrice=quoteProductPrice;
                
                //if product is added successfully to the quote, add discounts
                //add the offer based on the start price and subsequent price if both available 
                throw new TelegraphApplicationException('Planned failure.');
            }else{ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Outbound_Selected_Product_Error_Message));return null;}
            //redirect user to quote page
            return goToQuotePage();
               
        }catch(TMGUtil.GenericException genericExceptionObj){ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,genericExceptionObj.getmessage()); ApexPages.addMessage(myMsg);
        }catch(exception ex){system.debug('Error occured to addOutboundProduct: '+ex+'at Line : '+ex.getLineNumber());ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,Label.New_Digital_Platform_Generic_Error_Message); ApexPages.addMessage(myMsg);}
        
        return null;
    }
    

    /* Apex methods to expose as javascript through actionFunctions */
    public pageReference goToQuotePage(){
        PageReference pageRef = new PageReference('/'+quoteObj.id);
        pageRef.setredirect(true);
        return pageRef;
    }
}