/**
* Author:       Sally ElGhoul (Tquila)
* Date:         18/05/2015
* Description:  this class is the constructor for the offer code selection page
*
* ******************* Change Log *******************
* Modified by       Change Date
* Wiktor Czykin     04/08/2016 //minor clean-up, added new discount calculation based on max prices on product
* Wiktor Czykin     17/03/2017 //mostly rewritten to use new Offer object
**/
public class Zuora_OfferCodeStepController {
    private Id quoteId;
    private zqu__Quote__c quoteObj;

    public Boolean bShowPage{get; private set;}
    public Id selectedId{get;set;}
    public List<TCode_Product__c> lstTCodeOffers{get;set;}
    
    public Decimal dComparisonPrice{get;set;}
    public String sPeriod{get;set;}
    public String sPeriodConverted{get;set;}
    public String sResponse{get;set;}
    public Boolean bIsAscending{get;set;}
    public String sOrderByParam{get;set;}
    public Map<Id, String> mapTCodeProductIdToAutoIncentive{get;set;}

    private String sOrderByParamOld{get;set;}
    private String sOrderByQueryPart;

    private static final String DEFAULT_ORDER = ' TCodeManagement__r.CreatedDate desc, TCodeManagement__r.Name asc';
    @TestVisible private static final String RESPONSE_ERROR = 'error';
    @TestVisible private static final String RESPONSE_MESSAGE = 'message';

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        18/05/2015
    Function    Constructor
    ******************* Change Log *******************
    Change Date     Modified by        
    04/08/2016      Wiktor Czykin   //added init of bIsDiscount
    12/05/2017      Wiktor Czykin   //simplified, removed useless stuff     
    ****************************************************************************************/
    public Zuora_OfferCodeStepController(ApexPages.StandardController standardController) {
        this.quoteId = standardController.getId();
        if(this.quoteId == null) throw new TelegraphApplicationException(Label.Offer_Selection_Missing_quote_id);
        
        List<zqu__Quote__c> lstQuote = [SELECT  Id, 
                                                zqu__SubscriptionType__c, 
                                                Subscription_Rate_Plan_Term_Type__c,
                                                Tcode__c,
                                                Tcode__r.Name,
                                                Tcode__r.Description__c
                                            FROM zqu__Quote__c 
                                            WHERE Id = :this.quoteId];
        if(lstQuote.isEmpty()) throw new TelegraphApplicationException(Label.Offer_Selection_No_quote_found);

        this.quoteObj = lstQuote[0];
        this.lstTCodeOffers = new List<TCode_Product__c>();
        this.bShowPage = true;
        this.sOrderByQueryPart = DEFAULT_ORDER;

        this.bIsAscending = true;
        this.mapTCodeProductIdToAutoIncentive = new Map<Id, String>();
        this.initOffersData();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        02/06/2017
    Function    sorting order change method
    ******************* Change Log *******************
    Change Date     Modified by
    ****************************************************************************************/
    public void changeSortOrder(){
        if(String.isBlank(this.sOrderByParam)){
            this.sOrderByQueryPart = DEFAULT_ORDER;
        }else{
             if(this.sOrderByParamOld == null || this.sOrderByParam != this.sOrderByParamOld){
                this.bIsAscending = true;
                this.sOrderByParamOld = this.sOrderByParam;
            }else{
                this.bIsAscending = !this.bIsAscending;
            }
            this.sOrderByQueryPart = sOrderByParamOld + ' ' + (this.bIsAscending?' asc':' desc');
        }
        this.initOffersData();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        12/05/2017
    Function    Retrieval of offers information
    ******************* Change Log *******************
    Change Date     Modified by
    ****************************************************************************************/
    public void initOffersData(){
        //get the product rate plan on thw quote exclude the discount rate plan
        String discountRatePlanName = '%'+Constants.DISCOUNT_RATE_PLAN_NAME.tolowerCase()+'%';
        List<zqu__QuoteRatePlan__c> lstQuoteRatePlans=[select   Id,
                                                                zqu__QuoteProductName__c,
                                                                zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceAnnual__c,
                                                                zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceMonth__c,
                                                                zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceDay__c
                                                            from zqu__QuoteRatePlan__c
                                                            where zqu__Quote__c =: quoteObj.Id
                                                            and (not zqu__ProductRatePlan__r.Name like :discountRatePlanName)];
        if(lstQuoteRatePlans.isEmpty()){
            this.bShowPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Campaign_Product_Required_Error_Message));
            return;
        }
        zqu__QuoteRatePlan__c qrp = lstQuoteRatePlans[0];

        List<zqu__QuoteRatePlanCharge__c> lstQouteRatePlanCharge = [select Id, zqu__Period__c from zqu__QuoteRatePlanCharge__c where zqu__QuoteRatePlan__c = :qrp.Id];
        if(lstQouteRatePlanCharge.isEmpty() || String.isBlank(lstQouteRatePlanCharge[0].zqu__Period__c)){
            this.bShowPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offer_Selection_No_rate_plan_charge_for_quote));
            return;
        }  

        List<zqu__ZProduct__c> lstProduct = [select Id from zqu__ZProduct__c where Name = :qrp.zqu__QuoteProductName__c];
        if(lstProduct.isEmpty()){
            this.bShowPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offer_Selection_Unable_to_find_product_based_on_rate_plan));
            return;
        }
        this.sPeriod = lstQouteRatePlanCharge[0].zqu__Period__c;
        this.sPeriodConverted = Zuora_Utility.getFrequencyForOffer(lstQouteRatePlanCharge[0].zqu__Period__c);
        try{
            if(this.sPeriodConverted == Constants.OFFER_FREQUENCY_ANNUALLY && qrp.zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceAnnual__c != null){
                this.dComparisonPrice = Decimal.valueOf(qrp.zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceAnnual__c);
            }
            if(this.sPeriodConverted == Constants.OFFER_FREQUENCY_MONTHLY && qrp.zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceMonth__c != null){
                this.dComparisonPrice = Decimal.valueOf(qrp.zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceMonth__c);
            }
            if(this.sPeriodConverted == Constants.OFFER_FREQUENCY_DAILY && qrp.zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceDay__c != null){
                this.dComparisonPrice = Decimal.valueOf(qrp.zqu__ProductRatePlan__r.zqu__ZProduct__r.MaxCoverPriceDay__c);
            }
            this.dComparisonPrice = this.dComparisonPrice.setScale(2);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Offer_Selection_Maximum_comparison_price_parse_failure));
        }

        String sExtraConditions = ' and Product__c=\''+lstProduct[0].Id+'\' and Offer__r.Frequency__c = \''+this.sPeriodConverted+'\' order by '+this.sOrderByQueryPart +' nulls last';
        try{
            this.lstTCodeOffers = GlobalQueries.getZuoraTcodeProductsBasedOnTCodeOfferType(Constants.TCODE_TYPE_PROMOTIONAL, sExtraConditions);
            for(TCode_Product__c tp : this.lstTCodeOffers){
                this.mapTCodeProductIdToAutoIncentive.put(tp.Id, '');
                if(!tp.TCode_Product_Incentives__r.isEmpty()){
                    TCode_Product_Incentive__c toShow;
                    Integer i = 0;
                    for(TCode_Product_Incentive__c tpi : tp.TCode_Product_Incentives__r){
                        if(tpi.Auto_Assign_for_Zuora_Subscription__c){
                            i++;
                            toShow = tpi;
                        }
                    }
                    if(toShow != null && i == 1){
                        this.mapTCodeProductIdToAutoIncentive.put(tp.Id, toShow.Incentive__r.Name);
                    }
                }
            }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.General_Database_query_error + e.getMessage()));
        }

        if(lstTCodeOffers.isEmpty()){
            this.bShowPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offer_Selection_No_promotion_campaign_for_product));
            return;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        18/05/2015
    Function    add Offer Code
    ******************* Change Log *******************
    Modified by         Change Date
    Sally ElGhoul       17/02/2016 - Throw the error of invalid offer code only when the offer code doesn't exist in core API, but if it exists with zero discount just insert the quote offer code record
    Wiktor Czykin       17/05/2017 - Refactored - in logic and in response type 
    ****************************************************************************************/
    public void addOfferCode(){
        Map<String, String> mapResponse = new Map<String, String>{RESPONSE_ERROR => 'false', RESPONSE_MESSAGE => ''};
        if(selectedId == null) {
            mapResponse.put(RESPONSE_ERROR, 'true');
            mapResponse.put(RESPONSE_MESSAGE, Label.Required_Campaign);
            this.sResponse = JSON.serialize(mapResponse);
            return;
        }
        /*  get All the charge groups on the quote
            ??this call was removed from the zuora utility class and added here by Zuora engineer to solve the exception we were getting
            ??this call do callout in case of amendments ONLY
        */
        Savepoint sp = Database.setSavepoint();
        try{
            List<zqu.zChargeGroup> lstQuoteChargeGroups = Test.isRunningTest()?new List<zqu.zChargeGroup>():zqu.zQuoteUtil.getChargeGroups(quoteObj.Id);
            
            Map<Id,TCode_Product__c> mapTp = new Map<Id, TCode_Product__c>(lstTCodeOffers);
            TCode_Product__c tp = mapTp.get(this.selectedId);
            if(tp == null){
                mapResponse.put(RESPONSE_ERROR, 'true');
                mapResponse.put(RESPONSE_MESSAGE, Label.Required_Campaign);
                this.sResponse = JSON.serialize(mapResponse);
                return;
            }
            // Call Zuora Utility to add the discount from the offer code details and pass the current quote charge groups that we got as first step of this method , check the offer code type
            if(!Test.isRunningTest()){
                Zuora_Utility.addNewOfferCode(quoteObj, quoteObj.zqu__SubscriptionType__c, tp.Offer__r, lstQuoteChargeGroups, Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE);
            }
            quoteObj.Tcode__c = tp.TCodeManagement__c;
            update quoteObj;
            mapResponse.put(RESPONSE_ERROR, 'false');
            mapResponse.put(RESPONSE_MESSAGE, Label.Campaign_Addition_Confirmation_Message);
        }catch(Exception offerCodeException){
            Database.rollback(sp);
            mapResponse.put(RESPONSE_ERROR, 'true');
            mapResponse.put(RESPONSE_MESSAGE, Label.General_Contact_administrator_error);
        }
        this.sResponse = JSON.serialize(mapResponse);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        18/05/2015
    Function    Cancel redirec
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       12/05/2017  //changed the cancel url
    ****************************************************************************************/
    public PageReference cancel(){
        if(this.quoteObj == null) return new PageReference('/');
        return new PageReference('/'+quoteObj.Id);
    }
}