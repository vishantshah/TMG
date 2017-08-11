/**
* @author Wiktor Czykin
* @date 27/02/2017
* @description Bean class to store data about Zuora Offers that we pass to CoreAPI
#############Change Log#############
Modified by         Change Date
Wiktor Czykin       06/07/2017  //added 2 new attributes and modified constructor
**/
global class OfferBean {

    @TestVisible private static final Integer DEFAULT_INITIAL_TERM = 12;
    @TestVisible private static final Integer DEFAULT_RENEWAL_TERM = 12;
    @TestVisible private static final String DEFAULT_DISCOUNT_MODEL = 'DiscountFixedAmount';
    public static final String ENCODE_TYPE_POUND = 'pound';

    public String id;
    public String productId;
    public String ratePlanId;
    public String name;
    public String description;
    public Decimal basePrice;
    public String frequency;
    public List<Discount> discounts;
    public Boolean containsFreeTrial;
    public Boolean isRestricted;
    public String friendlyName;
    public Decimal weeklyAdvertisedPrice;
    public String subDescription;
    public Boolean autoRenew;
    public Integer initialTerm;
    public String initialTermPeriodType;
    public Integer renewalTerm;
    public String renewalTermPeriodType;
    public String itemDescription;//PayPal description
    public Decimal initialPrice;//PayPal initial price

    public OfferBean(){}

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 01/03/2017
    Function - Constructor - init wrapper based on required parameters
    #############Change Log#############
    Modified by         Change Date
    Wiktor Czykin       06/07/2017  //added itemDescription and initialPrice
    ****************************************************************************************/
    public OfferBean(Offer__c o, zqu__ZProduct__c product, zqu__ProductRatePlan__c ratePlan){
        if(o == null || product == null || ratePlan == null) throw new TelegraphApplicationException('Required elements are missing.');
        this.id = o.Name;
        this.productId = product.zqu__ZuoraId__c;
        this.ratePlanId = ratePlan.zqu__ZuoraId__c;
        this.name = o.Name__c;
        this.description = o.Description__c;
        this.basePrice = o.Base_Price__c;
        this.frequency = o.Frequency__c;
        this.discounts = new List<Discount>();
        this.containsFreeTrial = o.Free_Trial__c;
        this.isRestricted = o.Is_Restricted__c;
        this.friendlyName = o.Friendly_Name__c;
        this.weeklyAdvertisedPrice = o.Weekly_Advertised_Price__c;
        this.subDescription = o.Sub_Description__c;
        this.autoRenew = o.Auto_Renew__c;
        this.itemDescription = o.Item_Description__c;
        this.initialPrice = o.Initial_Price__c;

        this.initialTerm = DEFAULT_INITIAL_TERM;
        if(o.Initial_Term__c != null){
            this.initialTerm = (Integer) o.Initial_Term__c;
        }

        this.initialTermPeriodType = Constants.OFFER_FREQUENCY_MONTH;
        if(String.isNotBlank(o.Initial_Term_Type__c)){
            this.initialTermPeriodType = o.Initial_Term_Type__c;
        }

        this.renewalTerm = DEFAULT_RENEWAL_TERM;
        if(o.Renewal_Term__c != null){
            this.renewalTerm = (Integer) o.Renewal_Term__c;
       }

        this.renewalTermPeriodType = Constants.OFFER_FREQUENCY_MONTH;
        if(String.isNotBlank(o.Renewal_Term_Type__c)){
            this.renewalTermPeriodType = o.Renewal_Term_Type__c;
        }

        if(o.Discount__c != null && o.Discount_Duration__c != null){
            Discount d = new Discount(o.Frequency__c, o.Discount__c, (Integer) o.Discount_Duration__c);
            this.discounts.add(d);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/04/2017
    Version - 1.0
    Function - method to encode beans variables content - iniitally only pound character
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void encodeVariables(List<OfferBean> lstBeans, String sType){
        if(String.isBlank(sType) || sType == ENCODE_TYPE_POUND){
            String regExp = '[£]';
            String replacement = '&#163;';
            for(OfferBean o : lstBeans){
                if(String.isNotBlank(o.Name)){
                    o.Name = o.Name.replaceAll(regExp, replacement);
                }
                if(String.isNotBlank(o.friendlyName)){
                    o.friendlyName = o.friendlyName.replaceAll(regExp, replacement);
                }
                if(String.isNotBlank(o.description)){
                    o.description = o.description.replaceAll(regExp, replacement);
                }
                if(String.isNotBlank(o.subDescription)){
                    o.subDescription = o.subDescription.replaceAll(regExp, replacement);
                }
            }
        }
    }

    /**
    * @author Wiktor Czykin
    * @date 27/02/2017
    * @description Inner class to hold discount info about the zuora offer
    #############Change Log#############
    Modified by     Version     Change Date
    **/
    public class Discount{
        public String model;
        public String billingPeriod;
        public Decimal discountAmount;
        public Integer numberOfPeriods;

        public Discount(){}

        /***************************************************************************************
        Developer - Wiktor Czykin
        Date - 01/03/2017
        Version - 1.0
        Function - Constructor - init wrapper
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public Discount(String sBillingPeriod, Decimal dDiscountAmount, Integer iNumberOfPeriods){
            this.model = DEFAULT_DISCOUNT_MODEL;
            this.billingPeriod = sBillingPeriod;
            this.discountAmount = dDiscountAmount;
            this.numberOfPeriods = iNumberOfPeriods;
        }
    }
}
