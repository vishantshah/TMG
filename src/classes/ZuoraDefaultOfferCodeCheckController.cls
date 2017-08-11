/**
* Author:       Sally ElGhoul (Accenture)
* Date:         26/10/2015
* Description:  this class is controller to the page ZuoraDefaultOfferCodeCheck
*
* ******************* Change Log *******************
* Modified by       Change Date  
* Sally ElGhoul     21/01/2016  the default offer code is added from the page layout and it should replace acquisition offer and take the user back to quote page   
* Sally ElGhoul     17/02/2016  query the quote Subscription_Rate_Plan_Term_Type__c field
* Vishant Shah      14/11/2016  remove duplicate offer codes and keep only one. SUB-5608
* Wiktor Czykin     24/05/2017  modifications   
**/
public class ZuoraDefaultOfferCodeCheckController{

    public Id quoteId{get; private set;}

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        29/10/2015
    Function    this is the controller - no it is the constructor 
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       31/05/2017  removed everything
    ****************************************************************************************/
    public ZuoraDefaultOfferCodeCheckController(){
        if(String.isBlank(ApexPages.currentPage().getParameters().get(Constants.ID_QUERY_STRING))){
            throw new TelegraphApplicationException(Label.Offer_Selection_Wrong_id_parameter_passed);
        }

        try{
            this.quoteId = (Id)ApexPages.currentPage().getParameters().get(Constants.ID_QUERY_STRING);
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.Offer_Selection_Wrong_id_parameter_passed);
        }

        if(zqu__Quote__c.SObjectType != this.quoteId.getSobjectType()){
            throw new TelegraphApplicationException(Label.Offer_Selection_Wrong_id_parameter_passed);
        }
    }
    
    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        29/10/2015
    Function    this is to check that the new subscriptionquote has default offer or acquisition code or no 
                and if no add the default offer code
    ******************* Change Log *******************
    Modified by         Change Date
    Sally ElGhoul       17/02/2016  query the quote Subscription_Rate_Plan_Term_Type__c field and remove the discount addition from this method as it will lead to two discounts added
    Vishant Shah        ??          remove duplicate offer codes and keep only one. SUB-5608
    Wiktor Czykin       31/05/2017  re-arranged a bit, made it use Offer__c object rather than callout
    ****************************************************************************************/
    public PageReference insertDefaultOfferCode(){
        //get the default offer code of the rate plan if exists and add it to the quote
        //select the quote to check its type, we add it only for new subscription
        List<zqu__Quote__c> lstQuotes= [select  Id, 
                                                Tcode__c, 
                                                Subscription_Rate_Plan_Term_Type__c, 
                                                zqu__SubscriptionType__c, 
                                                zqu__Customer_Acceptance_Date__c 
                                            from zqu__Quote__c 
                                            where Id = :this.quoteId];
        
        try{  
            if(lstQuotes.isEmpty()) return null;

            List<zqu.zChargeGroup> lstQuoteChargeGroups;
            if(!Test.isRunningTest()){
                lstQuoteChargeGroups = Zuora_Utility.getQuoteChargeGroups(this.quoteId);
            }else{
                lstQuoteChargeGroups = new List<zqu.zChargeGroup>();  
            }
            //get the rate plans for this quote
            List<zqu__QuoteRatePlan__c> lstQuoteRatePlans = [select Id,
                                                                    Name,
                                                                    zqu__ProductRatePlan__r.DefaultOfferCode__c 
                                                                from zqu__QuoteRatePlan__c 
                                                                where zqu__Quote__c = :this.quoteId];
            
            
            zqu__QuoteRatePlan__c defaultQuoteRatePlan;                                               
            for(zqu__QuoteRatePlan__c quoteRatePlanObj : lstQuoteRatePlans){
                if(!quoteRatePlanObj.Name.contains(Constants.DISCOUNT_RATE_PLAN_NAME) && !String.isEmpty(quoteRatePlanObj.zqu__ProductRatePlan__r.DefaultOfferCode__c)){
                    defaultQuoteRatePlan = quoteRatePlanObj;
                }
            }
            if(defaultQuoteRatePlan == null){
                throw new TelegraphApplicationException(Label.Offer_Selection_No_quote_rate_plan);
            } 
                
            Offer__c offer = GlobalQueries.getOffer(null, defaultQuoteRatePlan.zqu__ProductRatePlan__r.DefaultOfferCode__c);
            if(offer == null){ 
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, Label.Offer_Selection_No_default_offer_code_found_for_rate_plan));
            }else{
                //and pass the current quote charge groups that we got as first step of this method
                Zuora_Utility.addNewOfferCode(lstQuotes[0], lstQuotes[0].zqu__SubscriptionType__c, offer, lstQuoteChargeGroups, Constants.OFFER_CODE_DEFAULT_RATE_PLAN_DISCOUNT_TYPE);
                this.addOpenOfferTcodeToQuote(lstQuotes[0]);
                if(offer.Discount__c == null || offer.Discount__c <= 0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Default_Offer_Code_Addition_Confirmation_Message_Zero_Discount));
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Default_Offer_Code_Addition_Confirm_Message));
                }
            }
            this.removeAdditionalOfferCodes(this.quoteId);
        }catch(exception e){
            System.debug('Error Occured on page load of insertDefaultOfferCode: '+e.getMessage() + ':' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error +' : '+e.getMessage()));
        }
        return null;
    }
    
    /*************************************************************************************** 
    Developer   Unknown
    Date        Unknown
    Function    populate open offer tcode on quote in context
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       10/05/2017  //replaced TcodeUtility reference to GlobalQueries one
    ****************************************************************************************/
    private void addOpenOfferTcodeToQuote(zqu__Quote__c quoteObj){
        TCodeManagement__c openOfferTcodeObj = GlobalQueries.getOpenOfferTcode();
        if(openOfferTcodeObj != null){
            quoteObj.Tcode__c = openOfferTcodeObj.id;
            try{
                update quoteObj;
            }catch(DmlException e){
                ApexPages.addMessages(e);
            }
        }
    }
    
    /*************************************************************************************** 
    Developer   Vishant Shah
    Date        09/11/2016
    Function    To remove duplicate offer codes and keep only one. SUB-5608
                This has to be manually tested as we cannot do a duplicate at runtime in test class
    ******************* Change Log *******************
    Modified by         Version     Change Date    
    ****************************************************************************************/
    private void removeAdditionalOfferCodes(String quoteId){
        List<zqu.zChargeGroup> deleteGroups = new List<zqu.zChargeGroup>();
		for (zqu.zChargeGroup chg : Zuora_Utility.getQuoteChargeGroups(quoteId)){
            if (chg.ratePlanName == Constants.DISCOUNT_RATE_PLAN_NAME){
                deleteGroups.add(chg);
            }
        }
        // KEEP ONE OFFER CODE ON THE QUOTE AND REMOVE OTHERS.
        if (deleteGroups.size() > 1){
            deletegroups.remove(0);
            zqu.ZQuoteUtil.deleteChargeGroups(deleteGroups);
        }
    }
}