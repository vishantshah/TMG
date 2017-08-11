/**
* Author:       Michal Kwika (Accenture)
* Date:         22/01/2016
* Description:  Controller for Summary page
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      09/02/2016 - added new message for mid-term
* Michal Kwika      10/02/2016 - added new field (Campaign Description)
* Michal Kwika      12/02/2016 - fixes to Product Name
* Michal Kwika      15/02/2016 - added new zuora Discount changes
* Michal Kwika      18/02/2016 - code security improvement
* Wiktor Czykin     22/09/2016 - added handling of subscription id incoming as get param
* Pawel Chrzanowski 07/02/2017 - added Page Message
* Pawel Chrzanowski 08/03/2017 - removed Page Message
* Wiktor Czykin     15/07/2017 - added tcode name fetching when there is no sub in context yet
**/
public class Zuora_SubscriptionSummaryCtrl {

    public String zuoraAccountId                        {get; set;}
    public String quoteId                               {get; set;}
    public String previousSubId                         {get; set;}
    public String zuoraSubId                            {get; set;}
    public String zuoraDiscountRatePlanId               {get; set;}
    public String newProductName                        {get; set;}
    public String newPaymentMethod                      {get; set;}
    public String oldPaymentMethod                      {get; set;}
    public String newServiceActivationDate              {get; set;}
    public String oldServiceActivationDate              {get; set;}
    public String tsNumber                              {get; set;}
    public String accountName                           {get; set;}
    public String accountId                             {get; set;}
    public String newStatus                             {get; set;}
    public String oldStatus                             {get; set;}
    public String campaignInfo                          {get; set;}
    public String newQuoteRatePlanName                  {get; set;}
    public String subTermType                           {get; set;}
    public Date newStartDate                            {get; set;}

    public zqu__Quote__c sfQuote                        {get; set;}
    public Zuora.zObject zuoraSub                       {get; set;}
    public Zuora__Subscription__c sfMidSub              {get; set;}
    public Zuora__Subscription__c sfOldSub              {get; set;}
    public Boolean showFullPage                         {get; set;}
    public Boolean isAmendment                          {get; set;}
    public Boolean isMidTermAmendment                   {get; set;}
    public Boolean showBillingPreview                   {get; set;}

    /*ZUORA API*/
    private Zuora.zApi api = new Zuora.zApi();
    private String subscriptionId;

    /***************************************************************************************
     Author:       Michal Kwika (Accenture)
     Date:         22/01/2016
     Function      Constructor
     ******************* Change Log *******************
     Modified by         Version     Change Date
     Michal Kwika        1.1         09/02/2016
     Wiktor Czykin       1.2         22/09/2016  //added setting of subscription id from GET
     Pawel Chrzanowski   1.3         07/02/2017  //added Page Message
     Pawel Chrzanowski   1.4         08/03/2017  //removed Page Message
     ****************************************************************************************/
    public Zuora_SubscriptionSummaryCtrl() {
        Map<String, String> mapParams = ApexPages.currentPage().getParameters();
        //check if there is a DD parameter set
        if (mapParams.containsKey('zuoraId')) {
            this.zuoraAccountId = mapParams.get('zuoraId');
        }
        if (mapParams.containsKey(Constants.QUOTE_ID_QUERY_STRING)) {
            this.quoteId = mapParams.get(Constants.QUOTE_ID_QUERY_STRING);
        }
        if(mapParams.containsKey(Constants.SUBSCRIPTION_ID_QUERY_STRING)){
            this.subscriptionId = mapParams.get(Constants.SUBSCRIPTION_ID_QUERY_STRING);
        }

        //set properties
        this.showFullPage = true;
        this.isAmendment = false;
        this.showBillingPreview = false;
        this.isMidTermAmendment = false;
        this.sfOldSub = new Zuora__Subscription__c();
        this.sfMidSub = new Zuora__Subscription__c();

        try {
            //Get subscription directly from Zuora
            setLatestSubscription();
            //set values on new sub page
            setValuesForNewSubOnPage();
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.New_Digital_Platform_Generic_Error_Message));
            this.showFullPage = false;
            System.debug('### Error Occured on Zuora_SubscriptionSummaryCtrl: ' + ex.getMessage());
            return;
        }

        if (this.sfQuote != null) {
            if (this.sfQuote.Previous_Subscription__c != null) {
                this.isAmendment = true;
                this.oldStatus = Constants.SUBSCRIPTION_CANCELLED_STATUS;
                this.previousSubId = sfQuote.Previous_Subscription__c;
                this.sfOldSub = getPreviousSubscription(this.previousSubId);
                this.oldServiceActivationDate = this.sfOldSub.Zuora__ServiceActivationDate__c.format();
                if (String.isNotBlank(this.sfOldSub.Related_Quote__r.zqu__PaymentMethod__c)) {
                    this.oldPaymentMethod = getCorrectLabelForPaymentMethod(this.sfOldSub.Related_Quote__r.zqu__PaymentMethod__c);
                }
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.New_Digital_Platform_Generic_Error_Message));
            this.showFullPage = false;
            return;
        }

        if (this.showFullPage) {
            if(isMidTermAmendment){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Subscription_Summary_Message_Success_MidTerm));
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Subscription_Summary_Message_Success));
				
            }
        }
    }

    /***************************************************************************************
     Author:       Michal Kwika (Accenture)
     Date:         26/01/2016
     Function      Method used to query Zuora Subs
     ******************* Change Log *******************
     Modified by         Change Date
     Wiktor Czykin       22/09/2016  //added setting of subscription id from GET
     Wiktor Czykin       15/06/2017  //added promo code and campaign code to soql
     ****************************************************************************************/
    public void setLatestSubscription() {
        List <Zuora.zObject> lstZuoraSubs;
        if (this.quoteId != null) {

            this.sfQuote = [SELECT Name,
                            zqu__ZuoraSubscriptionID__c,
                            zqu__SubscriptionType__c,
                            Default_Payment_Method_Type__c,
                            zqu__Account__r.Name,
                            Previous_Subscription__c,
                            zqu__PaymentMethod__c,
                            zqu__Service_Activation_Date__c,
                            zqu__Account__c,
                            PromoCode__c,
                            CampaignCode__c
                            FROM zqu__Quote__c WHERE Id = :quoteId];
            //set values for new sub preview
            this.zuoraSubId = this.sfQuote.zqu__ZuoraSubscriptionID__c;
            if(String.isBlank(this.zuoraSubId)) this.zuoraSubId = this.subscriptionId;

            //if Product Name is Blank - try check if this is Quote After Mid Term Discount
            if (String.isNotBlank(this.sfQuote.zqu__SubscriptionType__c)) {
                if (this.sfQuote.zqu__SubscriptionType__c.equalsIgnoreCase(Constants.QUOTE_SUBSCRIPTION_TYPE_AMEND_VALUE)) {
                    //that means we have subscription in system
                    this.isMidTermAmendment = true;
                    this.sfMidSub = [SELECT Id,
                                     Zuora__SubscriptionStartDate__c,
                                     Subscription_Product__c,
                                     Zuora__ServiceActivationDate__c,
                                     Zuora__Status__c
                                     FROM Zuora__Subscription__c WHERE Related_Quote__c = :quoteId LIMIT 1];
                    System.debug('### sfMidSub ' + sfMidSub);
                    return;
                }
            }

            //try to get informations from Zuora about the Sub
            String zoql = 'select id, status, serviceActivationDate, subscriptionStartDate, CampaignCode__c, PromoCode__c from Subscription where id=' + '\'' + this.zuoraSubId + '\'';
            System.debug('### zoql : ' + zoql);

            if ( !Test.isRunningTest() ) {
                //Query Zuora
                this.api.zlogin();
                lstZuoraSubs = api.zquery(zoql);
                System.debug('### setLatestSubscription SUB FROM ZUORA ' + lstZuoraSubs);
            } else {
                lstZuoraSubs = new List <Zuora.zObject>();
                Zuora.zobject subsObj = new zuora.zobject(Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
                if (this.zuoraAccountId == null) {
                    this.zuoraAccountId = '123456789012345';
                }
                subsObj.setValue('AccountId', this.zuoraAccountId);
                subsObj.setValue('Status', Constants.SUBSCRIPTION_ACTIVE_STATUS);
                subsObj.setValue('Id', '1223');
                subsObj.setValue('Name', 'testing');
                lstZuoraSubs.add(subsObj);
            }

        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Outbound_Missing_QuoteId_Query_String_ErrorMessage));
            this.showFullPage = false;
            return;
        }

        if (lstZuoraSubs != null && lstZuoraSubs.size() > 0) {
            this.zuoraSub = lstZuoraSubs.get(0);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Cancellation_Subscription_Revoke_Cannot_Load_Sub));
            this.showFullPage = false;
            return;
        }
    }
    /***************************************************************************************
     Author:       Michal Kwika (Accenture)
     Date:         26/01/2016
     Function      Method used to get Product Name from RatePlan
     ******************* Change Log *******************
     Modified by         Version     Change Date
     ****************************************************************************************/
    public List <zqu__QuoteRatePlan__c> getRatePlans(String quoteId) {
        if (String.isNotBlank(quoteId)) {
            List <zqu__QuoteRatePlan__c> lRatePlans = [SELECT Id, Name, zqu__ProductRatePlanZuoraId__c, zqu__QuoteProductName__c FROM zqu__QuoteRatePlan__c
                    WHERE zqu__Quote__c = :quoteId LIMIT 20];
            if (lRatePlans.size() > 0) {
                return lRatePlans;
            }

        }
        return null;
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         26/01/2016
    Function      Method used to get Subscription from Zuora to show summary
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Zuora__Subscription__c getPreviousSubscription(String previousSubId) {
        List<Zuora__Subscription__c> lSFSubs = [SELECT Id, Zuora__Status__c, Zuora__ServiceActivationDate__c, Subscription_Product__c, Related_Quote__r.zqu__PaymentMethod__c
                                                FROM Zuora__Subscription__c WHERE Id = :previousSubId LIMIT 1];

        if (lSFSubs.size() > 0) {
            return lSFSubs.get(0);
        }
        return null;
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         26/01/2016
    Function      Method used to set values for preview
    ******************* Change Log *******************
    Modified by         Change Date
    Michal Kwika        10/02/2016 - added campaign information
    Michal Kwika        15/02/2016 - added Account Id for Billing preview
    Michal Kwika        18/02/2016 - added code improvements
    Wiktor Czykin       15/07/2017 - added backup way of retrieving tcode name -> from quote if sub is not there.
                                        They are same as subscription tcode is copied over from the submitted quote. 
    ****************************************************************************************/
    public void setValuesForNewSubOnPage() {
        if (String.isNotBlank(this.sfQuote.zqu__PaymentMethod__c)) {
            this.newPaymentMethod = getCorrectLabelForPaymentMethod(this.sfQuote.zqu__PaymentMethod__c);
        } else  if (String.isNotBlank(this.sfQuote.Default_Payment_Method_Type__c)) {
            this.newPaymentMethod = getCorrectLabelForPaymentMethod(this.sfQuote.Default_Payment_Method_Type__c);
        }
        if (this.sfQuote.Name != null) {
            this.tsNumber = this.sfQuote.Name.replaceAll(Constants.QUOTE_OBJECT_NAME, '');
            this.tsNumber = this.tsNumber.deleteWhitespace();
        }
        if (this.sfQuote.zqu__Account__c != null) {
            this.accountName = this.sfQuote.zqu__Account__r.Name;
            this.accountId = this.sfQuote.zqu__Account__c;
        }
        if (this.sfQuote.zqu__Service_Activation_Date__c != null) {
            this.newServiceActivationDate = this.sfQuote.zqu__Service_Activation_Date__c.format();
        }

        String sTCodeName = '';
        if (this.zuoraSub != null) {
            this.newStatus = String.valueOf(this.zuoraSub.getValue(Constants.ZUORA_AMENDMENT_STATUS_FIELD_NAME));
            this.newStartDate = Date.valueOf(this.zuoraSub.getValue(Constants.ZUORA_AMENDMENT_SUBSCRIPTION_START_DATE_FIELD_NAME));
            sTCodeName = String.valueOf(this.zuoraSub.getValue(Constants.ZUORA_SUB_CAMPAIGN_CODE_FIELD_NAME));
        } else if (this.isMidTermAmendment) {
            this.newStatus = this.sfMidSub.Zuora__Status__c;
        }

        if(String.isBlank(sTCodeName) && this.sfQuote != null){
            sTCodeName = this.sfQuote.CampaignCode__c;
        }
        this.campaignInfo = GlobalQueries.getTCodeNameWithDescriptionBasedOnName(sTCodeName);

        //set names for new product and old product if this is amendment
        setValuesFromRatePlansAfterFiltering(getRatePlans(this.quoteId));
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         02/02/2016
    Function      Method used to set correct label value for payment method
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public String getCorrectLabelForPaymentMethod(String paymentMethodName) {
        String correctLabelForPaymentMethod = '';
        if (String.isNotBlank(paymentMethodName)) {
            if (paymentMethodName.equalsIgnoreCase(Constants.DIRECT_DEBIT_PAYMENT_METHOD)) {
                correctLabelForPaymentMethod = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL;
            } else if (paymentMethodName.equalsIgnoreCase(Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL)) {
                correctLabelForPaymentMethod = Constants.CREDIT_CARD_PAYMENT_METHOD;
            } else {
                correctLabelForPaymentMethod = paymentMethodName;
            }
        }

        System.debug('### correctLabelForPaymentMethod ' + correctLabelForPaymentMethod);
        return correctLabelForPaymentMethod;
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         03/02/2016
    Function      Method used to filter discount
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         12/02/2016 - added new discount
    ****************************************************************************************/
    public void setValuesFromRatePlansAfterFiltering(List <zqu__QuoteRatePlan__c> lRatePlans) {
        if (lRatePlans != null) {
            for (zqu__QuoteRatePlan__c ratePlan : lRatePlans) {
                if (ratePlan.Name != Constants.DISCOUNT_RATE_PLAN_NAME) {
                    this.newProductName = getCorrectProductName(ratePlan.zqu__QuoteProductName__c, ratePlan.Name);
                    this.newQuoteRatePlanName = ratePlan.zqu__QuoteProductName__c;
                    setCorrectSubsTermType(ratePlan.Name);
                }
            }
            //set correct discount Rateplan Id
            setZuoraDiscountRatePlanId(this.newQuoteRatePlanName);
            //show Billing Preview for monthly sub
            if (String.isNotBlank(this.newProductName)) {
                setShowBillingPreviewBasedOnProduct(this.newProductName);
            } else if (this.sfMidSub != null) {
                setShowBillingPreviewBasedOnProduct(this.sfMidSub.Subscription_Product__c);
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Subscription_Summary_Message_Error_Product_RatePlan));
            this.showFullPage = false;
            return;
        }
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         03/02/2016
    Function      Method used to set Billing Preview
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         15/02/2016 - added Service Activation Date dependency
    ****************************************************************************************/
    public void setShowBillingPreviewBasedOnProduct(String productName) {
        if (String.isNotBlank(productName)) {
            if (productName.contains(Constants.RATE_PLAN_MONTHLY)) {
                this.showBillingPreview = true;
            } else if (productName.contains(Constants.RATE_PLAN_ANNUAL) && (this.sfQuote.zqu__Service_Activation_Date__c > Date.today())) {
                this.showBillingPreview = true;
            }
        }
    }
    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         03/02/2016
    Function      Method used to  redirect user to Quote
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference goToQuotePage() {
        return new PageReference('/' + this.quoteId);
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         03/02/2016
    Function      Method used to  redirect user to SF Account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference goToAccountPage() {
        return new PageReference('/' + this.sfQuote.zqu__Account__c);
    }


    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         12/02/2016
    Function      Helper Method used to set correct product Name (without 'Open Offer' text)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public String getCorrectProductName(String quoteProductName, String ratePlanName) {
        String correctProductName = '';

        if (String.isNotBlank(ratePlanName)) {
            if (ratePlanName.contains(Constants.OPEN_OFFER_TCODE_TYPE)) {
                ratePlanName = ratePlanName.replaceAll(Constants.OPEN_OFFER_TCODE_TYPE, '');
                ratePlanName = ratePlanName.deleteWhitespace();
                ratePlanName = ratePlanName.replaceAll('-', ' ');
            }
        }

        correctProductName = quoteProductName + ratePlanName;
        return correctProductName;
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         15/02/2016
    Function      Helper Method used to set correct Subscription Type (Annual or Monthly)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void setCorrectSubsTermType(String ratePlanName) {

        if (String.isNotBlank(ratePlanName)) {
            if (ratePlanName.contains(Constants.RATE_PLAN_ANNUAL)) {
                this.subTermType = Constants.RATE_PLAN_ANNUAL;
            } else if (ratePlanName.contains(Constants.RATE_PLAN_MONTHLY)) {
                this.subTermType = Constants.RATE_PLAN_MONTHLY;
            }
        } else {
            this.subTermType = '';
        }
    }

    /***************************************************************************************
    Author:       Michal Kwika (Accenture)
    Date:         15/02/2016
    Function      Helper Method used to set correct Zuora Discount Id based on Product
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void setZuoraDiscountRatePlanId(String quoteProductName) {
        if (String.isNotBlank(quoteProductName)) {
            List <zqu__ProductRatePlan__c> lDiscountPlan = [SELECT zqu__ZuoraId__c  
                    FROM zqu__ProductRatePlan__c
                    WHERE Name = :Constants.EMPTY_DISCOUNT_RATE_PLAN_NAME
                                 AND zqu__ZProduct__r.Name = :quoteProductName];
            System.debug('### quoteProductName ' + quoteProductName + ' || list for DiscountProductRatePLan ' + lDiscountPlan);
            if (lDiscountPlan.size() > 0) {
                this.zuoraDiscountRatePlanId = lDiscountPlan.get(0).zqu__ZuoraId__c;
            }
        }
    }
}