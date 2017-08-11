/**
* @author Unknown
* @date Unknown
* @description Controller for the second page in the offlince acquisition flow
#############Change Log#############
Modified by     Change Date
Wiktor Czykin   10/07/2015  //modified upsertSub();
Wiktor Czykin   01/09/2015  //modified saveAndTakePayment()
Wiktor Czykin   14/09/2015  //modified saveAndTakePayment() - back button param
Wiktor Czykin   08-09/2015  //LOW START feature related changes
Wiktor Czykin   13/10/2015  //fixed Back button in Low Start version of code
Wiktor Czykin   29/10/2015  //modified upsertSub() and restoreParametersOnBack() and qualifyThisAgency()
Wiktor Czykin   11/11/2015  //modified: constructor, saveAndTakePayment(), getInterruptedSubscriptionAndIncentives()
Wiktor Czykin   17/11/2015  //modified: selectSubscription()
Wiktor Czykin   24/11/2015  //modified: Moved TSNumber initisalization to beginning of Constructor OapSubscriptionTMG()
Wiktor Czykin   11/2015     //removed not used variables, moved method used cross flows into MppUtil class, simplified wrapper for OrderTaken.
Wiktor Czykin   12/2015     //clean-up related to product hardcoding removal
Wiktor Czykin   15/01/2016  //modified saveAndTakePayment() - support for passing forced prices, added POC offer to LOW START conversion if POC related tcode is of Low Start type
                                        //added OtherTitle initialization if different than available picklist values in salutation picklist
Wiktor Czykin   02/02/2016  //fix to pre-selection of values
Pawel Chrzanowski   01/03/2016  //added displayDuplicateErrorMessage(), modified saveAndTakePayment() with duplicate email validation
Pawel Chrzanowski   03/03/2016  //modified getInterruptedSubscriptionAndIncentives()
Pawel Chrzanowski   15/03/2016  //Added Add/Change Email iFrame functionality
Michal Szewczyk     14/03/2016  //replaced checkboxes with multi picklist in initializePremiumPaymentMap()
Pawel Chrzanowski   06/04/2016  //added new email validation in saveAndTakePayment()
Michal Kwika        11/04/2016  //changing flow due to producthardcoding removal; added support for Product__c lookup; new change product functionality;
Wiktor Czykin       12/04/2016  //modified the default values for Loyalty flags to false and removed unused ones
Wiktor Czykin       04-05/2016  //change to initialization order, fixed weekly price for print, removed qualifyAgency method - replaced with initSubscriber, added implementation of product switch,
                                        //modified save to support product lookup population and passing to MPPUtil,
Wiktor Czykin       16/05/2016  //added default product in constructor
Wiktor Czykin       25/05/2016  //modified callSAMFuture()
Wiktor Czykin       06/05/2016  //added new getters to support product switch component lowstart/digital behaviour
Gavin Palmer        17/06/2016  //modified getPOCAccount()
Wiktor Czykin       19/07/2016  //modified getPOCAccount()
Wiktor Czykin       01/08/2016  //added supporty for product configurable delivery type
Wiktor Czykin       31/10/2016  //modified changeProductId() - added refresh of incentives
Wiktor Czykin       17/11/2016  //modified upsertSub()
Vishant Shah        04/01/2017  //moved generation of preferred start days and added generation in changeProductId
Wiktor Czykin       03/03/2017  //modified updateIncentives()
Pawel Chrzanowski   13/04/2017  //modified Marketing Preferences in saveAndTakePayment()
Pawel Chrzanowski   03/05/2017  //removed unused Marketing Preferences
Mantas G.           09/06/2017  //added parameter if the payment is from OC DDCX 
Wiktor Czykin       19/07/2017  //modified getCountries()
**/
public class OapSubscriptionTMG implements ProductSwitchSupport{

    //in theory we could go directly to Constants but private vars were here first, then decided to leave them in as easier to read
    private static final String CONTINUOUS_13 = Constants.SUBSCRIPTIONTYPE_13CONTINUOUS;
    private static final String CONTINUOUS_26 = Constants.SUBSCRIPTIONTYPE_26CONTINUOUS;
    private static final String CONTINUOUS_52 = Constants.SUBSCRIPTIONTYPE_52CONTINUOUS;
    private static final String ONEOFF_13 = Constants.SUBSCRIPTIONTYPE_13WEEKS;
    private static final String ONEOFF_26 = Constants.SUBSCRIPTIONTYPE_26WEEKS;
    private static final String ONEOFF_52 = Constants.SUBSCRIPTIONTYPE_52WEEKS;

    private static final String ONEOFF_DIGITAL_MONTHLY = Constants.SUBSCRIPTIONTYPE_MONTHLY;
    private static final String ONEOFF_DIGITAL_YEARLY = Constants.SUBSCRIPTIONTYPE_YEARLY;
    private static final String CC = Constants.SUB_ACQUISITION_PAYMENT_CC;
    private static final String DD = Constants.SUB_ACQUISITION_PAYMENT_DD;

    private static final Set<String> SET_CONTINUOUS = new Set<String>{CONTINUOUS_13, CONTINUOUS_26, CONTINUOUS_52};
    private static final List<String> LST_DEFAULTS = new List<String>{ONEOFF_52, CONTINUOUS_52, ONEOFF_26, CONTINUOUS_26, ONEOFF_13, CONTINUOUS_13, ONEOFF_DIGITAL_MONTHLY, ONEOFF_DIGITAL_YEARLY};
    private static final Map<String, String> MAP_TYPE_TO_TCODEINCENTIVE_FIELD = new Map<String, String>{
        CONTINUOUS_13 => 'Continuous 13 Week Applicable',
        CONTINUOUS_26 => 'Continuous 26 Week Applicable',
        CONTINUOUS_52 => 'Continuous 52 Week Applicable',
        ONEOFF_13 => 'One Off 13 Week Applicable',
        ONEOFF_26 => 'One Off 26 Week Applicable',
        ONEOFF_52 => 'One Off 52 Week Applicable',
        ONEOFF_DIGITAL_MONTHLY => 'Digital - Monthly',
        ONEOFF_DIGITAL_YEARLY => 'Digital - Yearly'
    };

    private static final Set<String> SET_CONVERTABLE_TO_LOWSTART = new Set<String>{Constants.OFFER_POC};

    public static final String PARAM_ORDER_METHOD = 'orderMethod';
    public static final String PARAM_SELECTED_PRODUCT = 'selectedProduct';
    public static final String PARAM_TCODE = 'tcode';
    public static final String PARAM_POCID = 'pocid';
    public static final String PARAM_SELECTED_OFFER = 'selectedOffer';
    public static final String PARAM_MGM_GIVERID = 'mgmGiverId';
    public static final String PARAM_TSNUMBER = 'tsnumber';
    public static final String PARAM_PRODUCTID = 'productId';
    public static final String PARAM_FORCED_PRICE = 'forcedPrice';
    public static final String PARAM_FORCED_LOWSTART_PRICE = 'forcedLowStartPrice';
    public static final String PARAM_RESTART = 'restart';
    public static final String PARAM_AGENCYID = 'agencyid';
    public static final String PARAM_AGENT_USERID = 'agentuserid';
    public static final String PARAM_SURNAME = 'surname';
    public static final String PARAM_POSTCODE = 'postcode';
    public static final String PARAM_READERSHIP_FREQUENCY = 'tmgreadfreq';
    public static final String PARAM_READERSHIP_FREQUENCY_SUNDAY = 'tmgsundayfreq';
    public static final String PARAM_OPPOSITION_TITLE = 'opptitle';
    public static final String PARAM_OPPOSITION_TITLE_SUNDAY = 'oppsundaytitle';
    public static final String PARAM_OPPOSITION_FREQUENCY = 'oppfreq';
    public static final String PARAM_OPPOSITION_FREQUENCY_SUNDAY = 'oppsundayfreq';
    public static final String PARAM_RETAILERID = 'retailerid';
    public static final String PARAM_HASBACK = 'hasBack';
    public static final String PARAM_SUBSCRIPTION_TYPE = 'subscriptionType';
    public static final String PARAM_PAYMENT_TYPE = 'PaymentType';
    public static final String PARAM_PAYMENT_FREQUENCY = 'PaymentFrequency';
    public static final String PARAM_INCENTIVEID = 'incentiveId';
    public static final String PARAM_PAYMENT_START_DATE = 'paymentStartDate';
    public static final String PARAM_SFDC_RETAILERID = 'sfdcRetailerId';
    public static final String PARAM_OTHER_TITLE = 'otherTitle';
    public static final String PARAM_STAFF_NAME = 'staffName';
    public static final String PARAM_GUID = 'guid';

    //retailer
    public String selectedRetailer{get;set;}
    public String newselectedRetailer{get;set;}
    //record holders
    public Account subscriber{get;set;}
    public Account retailerAccount;
    public Subscription__c subscription{get;set;}
    public Cheque__c cheque{get;set;}
    public TCodeManagement__c currentCampaign{get;set;}

    //Account
    public String otherTitle{get;set;}
    public Id newAccId{get;set;}
    public String selectedDelivery{get;
        set{
            this.selectedDelivery = value;
            if (selectedDelivery == Constants.DELIVERYTYPE_OTC){
                this.displayRetailers = false;
            }else{
                this.displayRetailers = true;
            }
        }
    }

    //Retailers
    public Boolean displayRetailers{get;set;}
    public String postcodeRetailSearch{get;set;}
    public String selectedRetailerName{get;set;}
    public List<ActiveRetailers> allActiveRetailers{get;set;}
    public Boolean displayRetailerResults{get;set;}
    public String retailerID{get;set;}//ret_ID__c
    public String retailerPostalCode{get;set;}

    //TMG readership  frequency
    public String tmgReadershipFreq{get;set;}
    public String tmgSundayReadershipFreq{get;set;}

    //Opposition newspaper readership
    public String oppositionTitle{get;set;}
    public String oppositionSundayTitle{get;set;}
    public String oppositionTitleFrequency{get;set;}
    public String oppositionSundayTitleFrequency{get;set;}

    //Prices
    public String weeklyPriceDisplayed{get;set;}
    public String weeklyPriceDisplayedLowStart{get;set;}

    // 13 week subscriptions are set to be £30 by default, this price has to be gotten from the TCODE
    public Double price_13week {
        get {
            if (this.currentTCodeProduct != null && this.currentTCodeProduct.X13_Week_Price__c != null)
                price_13week = this.currentTCodeProduct.X13_Week_Price__c;
            else
                price_13week = 30;
            return price_13week;
        }
        private set;
    }

    //Cheque
    public Boolean createNewBatch{get;set;}
    public List<SelectOption> chequeBatchOptions{get;set;}
    public String chequeBatchSelected{get;set;}
    public String newChequeBatchSelected;
    //CC
    public String customerFullName{get;set;}
    public String customerFullAddress{get;set;}
    public String emailToPassToCC{get;set;}
    public String totalPriceToPassToPaymentProvider{get;set;}
    public String agencyIdentifier{get;set;}
    public String agencyPrice{get;set;}
    public String orderMethod{get;set;}
    public String orderTakenCompany{get;set;}
    public String POC_id{get;set;}
    public String tsNumber{get;set;}
    public Double weeklyPrice{get;set;}
    public Double weeklyLowStartPrice{get;set;}
    public String duplicateSurname{get;set;}
    public String duplicatePostCode{get;set;}

    //Product Hardcoding changes - new informations needed
    public Id productId {get; set;}
    public Id initialProductId{get;set;}
    public String zProductName {get; set;}
    public TCode_Product__c currentTCodeProduct{get;set;}
    public UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
    //Start Dates
    public List<SelectOption> preferredStartDatesList{get;set;}
    public String preferedStartDate{get;set;}
    public String preferedStartPaymentDate{get;set;}
    public String agentUserId{get;set;}
    public String tCode{get;set;}

    //Marketing
    public Boolean TMG_Promo_Email{get;set;}
    public Boolean TMG_Promo_Phone{get;set;}
    public Boolean TMG_Promo_Post{get;set;}
    public Boolean TMG_Promo_Sms{get;set;}

    // Special Open Offer Incentives
    public List<SelectOption> incentiveSelection{get;set;}
    public String incentive{get;set;}

    //display on successful creation
    public String successMessagePart3{get;set;}
    //MGM
    public String mgmGiverId;
    public String mgmPrompt{get;set;}
    public String mgmValue{get;set;}
    public String outboundPromoSelected{get;set;}
    //created offer
    public String selectedOfferOptions{get;set;}
    public String defaultEmail;
    public Boolean displayOfferSection{get;set;}//controls if to display Create Offer section on load
    public String newTSNumber{get;set;}
    public String selectedProduct {get;set;}
    public String selectedOffer {get;set;}
    public String subscriptionType {get;set;}
    public String paymentType {get;set;}
    public String paymentFrequency {get;set;}
    public Decimal digitalMonthlyOpenOfferPrice {get;set;}
    public Decimal digitalYearlyOpenOfferPrice {get;set;}
    //Interupted Subscription Id, Name
    public Id subscriptionId {get;set;}
    public String subscriptionName {get;set;}
    // Showing all possible payment values for Outbound
    public List<PaymentValues> paymentValues {get;set;}
    // Subscription Constants
    public String saveBtnName {get; private set;}
    public List<SelectOption> paymentOptionsList{get;set;}
    public String selectedIncentive{get;set;}
    //Needed to know if we display the list
    public Boolean bRenderIncentives{get;set;}
    // Gets the list of incentive for the selected product, sub type, tCode
    public List<SelectOption> lstActiveIncentives{get;set;}
    public List<SelectOption> lstSubscriptionTypes{get;set;}
    public List<SelectOption> lstFrequencies {get;set;}
    public Map<String, String> mapParameters;
    public List<SelectOption> lstPersonTitleValues{get;set;}
    public Boolean bRenderForm{get;set;}
    public ProductSwitchController productSwitcher{get;set;}
    public List<SelectOption> lstDeliveryOptions{get;set;}

    //main map that holds subscription types and applicable payment methods based on TCodes - populated in initializePaymentMap()
    @TestVisible private Map<String,PaymentConfig> mapPaymentConfig;
    //To store the incentive description associated with its name
    @TestVisible private Map<String, String> mapIncentiveDescription = new Map<String, String>();
    @TestVisible private Boolean bIsBack;
    private Boolean bIsRestart = false;
    private String subId;
    private String selectedOfferOriginal;
    @TestVisible private Decimal dForcedPrice;
    @TestVisible private Decimal dforcedLowStartPrice;

    //override vars are used to pre-load the values on page load only
    private String sPaymentTypeOverride{get;set;}
    private Id selectedIncentiveOverride{get;set;}
    private String sSelectedFrequencyOverride{get;set;}

    public Boolean bIsContinuous{
        get{
            if(String.isNotBlank(this.subscriptionType) && SET_CONTINUOUS.contains(this.subscriptionType)){
                return true;
            }
            return false;
        }
        set;
    }

    public Boolean bShowPricesType{
        get{
            if(this.paymentValues != null && this.paymentValues.size()>1){
                return true;
            }
            return false;
        }
        set;
    }

    //add/change email iFrame
    public Boolean showEmailIFrame{get;set;}
    public Boolean bIsPremium {get{
        return this.selectedProduct == Constants.PRODUCT_PREMIUM;

    }set;}
    public Boolean bIsLowStart {
        get{
            return this.selectedOffer == Constants.OFFER_LOWSTART;
        }
        set;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.8
    Function - Constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12-14/08/2015   //logic moved here from unnecessary action method, changes related to low-start-> clean-up, initialization and order of execution changes
    Wiktor Czykin   1.2         13/10/2015      //moved Cristinas logic for back button to separate method restoreParametersOnBack()
    Wiktor Czykin   1.3         11/11/2015      //added restart param fetching
    Wiktor Czykin   1.4         18/01/2016      //added initializeTitle() call
    Wiktor Czykin   1.5         02/02/2016      //modified how the existing offered subscription is initialized
    Michal Kwika    1.6         15/02/2016      //added productId as part of changes to OAP page
    Pawel Chrzanowski1.7        15/03/2016      //added Add/Change Email iFrame variable
    Wiktor Czykin   1.8         13/04/2016      //changed marketing flags default values
    Wiktor Czykin   1.9         16/05/2016      //added default product
    Wiktor Czykin   2.0         30/08/2016      //added initDeliveryOptions() call
    Mantas Grigaliunas  2.1     01/12/2016      //changed this.TMG_Loyalty_Email from false to true
    Vishant Shah    2.2         04/01/2017      //moved generation of preferred start days
    Pawel Chrzanowski   2.3     03/05/2017      //removed unused Marketing Preferences
    ****************************************************************************************/
    public OapSubscriptionTMG(){
        this.mapParameters = Apexpages.currentPage().getParameters();
        this.orderMethod = mapParameters.get(PARAM_ORDER_METHOD);
        this.selectedProduct = mapParameters.get(PARAM_SELECTED_PRODUCT);
        this.tCode = mapParameters.get(PARAM_TCODE);
        this.poc_id = (mapParameters.get(PARAM_POCID)!=null) ? mapParameters.get(PARAM_POCID) : null;
        this.selectedOffer = mapParameters.get(PARAM_SELECTED_OFFER);
        this.selectedOfferOriginal = this.selectedOffer;
        this.mgmGiverId = mapParameters.get(PARAM_MGM_GIVERID);
        this.tsNumber = mapParameters.get(PARAM_TSNUMBER);
        this.productId = mapParameters.get(PARAM_PRODUCTID);
        this.bRenderForm = true;
        this.saveBtnName = Label.Offline_Acquisition_Save_and_take_payment_button;

         // Price forced in URL by SYnthesis for Outbound
        String sForcedPrice = ApexPages.currentPage().getParameters().get(PARAM_FORCED_PRICE);
        String sForcedLowStartPrice = ApexPages.currentPage().getParameters().get(PARAM_FORCED_LOWSTART_PRICE);
        try{
            if(String.isNotBlank(sForcedPrice)){
                this.dForcedPrice = Decimal.valueof(sForcedPrice);
            }
            if(String.isNotBlank(sForcedLowStartPrice)){
                this.dforcedLowStartPrice = Decimal.valueOf(sForcedLowStartPrice);
            }
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.Offline_Acquisition_Forced_prices_conversion_error);
        }

        if(mapParameters.containsKey(PARAM_RESTART) && mapParameters.get(PARAM_RESTART) == 'true'){
            this.bIsRestart = true;
        }
        // If Tcode is passed in URL, and POC-ID is null, then use Tcode automatically
        if(this.poc_id != null){ // If POC-ID is not NULL, then use Tcode from the POC object
            this.tCode = this.getPOCAccount(this.poc_id);
        }

        if(String.isBlank(this.tCode)){
            // If POC-ID and Tcode are both NULL, then display error. Note - at time of writing, one of these two values should ALWAYS be passed in from either Synthesis or the Offline flow
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_No_tcode_detected));
            this.bRenderForm = false;
            return;
        }

        List<TCodeManagement__c> lstTCodeManagement = GlobalQueries.getTCodeBasedOnName(this.tCode);
        if(!lstTCodeManagement.isEmpty()){
            this.currentCampaign = lstTCodeManagement[0];
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_TCode_not_available));
            this.bRenderForm = false;
            return;
        }

        this.paymentOptionsList = new List<SelectOption>();

         // Digital Sub Init value
        if(this.selectedProduct == null){
            this.selectedProduct = Constants.PRODUCT_PREMIUM;
        }

        //check if product was selected - if not inform as a warning message
        if(!TMGUtil.isDataValid(this.productId)){
            General__c defaultProduct = General__c.getInstance(Constants.GENERAL_DEFAULT_PRODUCT_ID);
            if(defaultProduct != null && String.isNotBlank(defaultProduct.Value__c)){
                try{
                    this.productId = defaultProduct.Value__c;
                    //commented out messages for initial release - to be seamless for agents, to be uncommented for June release
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Offline_Acquisition_Default_product_used));
                }catch(Exception e){
                    System.debug('TMGLOG::OapSubscriptionTMG:unable to convert setting value to valid id.');
                }
            }
            if(this.productId == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Product_Not_Selected_Or_Passed_Message));
                this.bRenderForm = false;
                return;
            }
        }

        this.showEmailIFrame = false;
        this.initialProductId = this.productId;
        this.displayRetailerResults = false;
        this.displayOfferSection = true;

        //default marketing prefs
        this.TMG_Promo_Post = false;
        this.TMG_Promo_Phone = false;

        this.selectedOfferOptions = 'None';

        if(this.subscriber == null){//as might have been initialized already by POC check above
            this.subscriber = new Account(RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName()));
        }
        this.subscription = new Subscription__c();
        this.cheque = new Cheque__c();

        //Move this cheque options list to somewhere more logical later on
        this.chequeBatchOptions = new List<SelectOption>{new SelectOption('', '')};
        for (Cheque_Batch__c eachChequeBatch : [select Name from Cheque_Batch__c where Batch_Closed_Date__c = null order by Name]){
            this.chequeBatchOptions.add(new SelectOption(eachChequeBatch.Name, eachChequeBatch.Name));
        }

        this.agencyIdentifier = mapParameters.get(PARAM_AGENCYID);
        this.agentUserId = mapParameters.get(PARAM_AGENT_USERID);
        this.duplicateSurname = mapParameters.get(PARAM_SURNAME);
        this.duplicatePostCode = mapParameters.get(PARAM_POSTCODE);
        this.tmgReadershipFreq = mapParameters.get(PARAM_READERSHIP_FREQUENCY);
        this.tmgSundayReadershipFreq = mapParameters.get(PARAM_READERSHIP_FREQUENCY_SUNDAY);
        this.oppositionTitle = mapParameters.get(PARAM_OPPOSITION_TITLE);
        this.oppositionSundayTitle = mapParameters.get(PARAM_OPPOSITION_TITLE_SUNDAY);
        this.oppositionTitleFrequency = mapParameters.get(PARAM_OPPOSITION_FREQUENCY);
        this.oppositionSundayTitleFrequency = mapParameters.get(PARAM_OPPOSITION_FREQUENCY_SUNDAY);
        this.retailerID = mapParameters.get(PARAM_RETAILERID);

        try {
            if (String.isNotBlank(this.retailerID)){
                //confirms retailer is valid and sets the Name so it can be displayed
                this.selectRetailerByID();
            }
        }catch (Exception e){
            this.agencyIdentifier = '';
            this.agencyPrice = '';
        }

        if (String.isBlank(this.agentUserId)){
            this.agentUserId = UserInfo.getUserId();
        }
        //same variable are required in both classes, could centralise variables in another class but because the aim is for re-use of the code for future projects it would be better to contain vars in each class
        subUtils.agencyIdentifier = this.agencyIdentifier;
        this.orderTakenCompany = this.agencyIdentifier;

        this.initSubscriber();
        if (this.selectedProduct == Constants.PRODUCT_PREMIUM){
            // Try to get any Offerd Sub linked to this Account
            this.subscriptionId = this.getInterruptedSubscriptionAndIncentives(this.subscriber.Id);
        }

        //if offered sub was found for current account, load incentives separately as default values were set in
        //getInterruptedSubscriptionAndIncentives() call and setDefaultSubscriptionType() cannot be called as would override those defaults (except for back button request)
        this.bIsBack = this.restoreParametersOnBack(mapParameters);
        this.initializeTitle();


        this.productSwitcher = new ProductSwitchController(this, this.productId, this.currentCampaign.Id, this.selectedProduct == Constants.PRODUCT_PREMIUM);
        if(!this.productSwitcher.bProductTCodeMatch){
            this.bRenderForm = false;
        }

        if(!this.bRenderForm) return;

        this.initializeProductAndPricing();

        //create Preferred Start Dates options
        this.preferredStartDatesList =  UtilitySelectOptionsSubscriptions.getStartDates(12, Integer.valueOf(this.currentTCodeProduct.Product__r.LeadDays__c));
        this.preferedStartDate = preferredStartDatesList.get(1).getValue();

        this.initDeliveryOptions();
        this.setDefaultValues();
    }

    @TestVisible private void setDefaultValues(){
        if(this.subscriptionId != null){
            if(this.bIsBack){
                this.setDefaultSubscriptionType();
            }else{
                this.selectSubscription();
            }
        }else{
            this.setDefaultSubscriptionType();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 18/10/2015
    Version - 1.0
    Function - Title initialization method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void initializeTitle(){
    	this.lstPersonTitleValues =  UtilitySelectOptionsSubscriptions.getPersonTitleValues();
    	if(String.isBlank(this.otherTitle) && String.isNotBlank(this.subscriber.Salutation)){
    		Boolean bMatchFound = false;
    		for(SelectOption opt : this.lstPersonTitleValues){
    			if(opt.getLabel() == this.subscriber.Salutation){
    				bMatchFound = true;
    				break;
    			}
    		}
    		if(!bMatchFound){
    			List<SelectOption> lstCopy = this.lstPersonTitleValues;
    			this.lstPersonTitleValues = new List<SelectOption>{new SelectOption(this.subscriber.Salutation, this.subscriber.Salutation)};
    			this.lstPersonTitleValues.addAll(lstCopy);
    		}
    	}
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 30/08/2016
    Version - 1.0
    Function - populates list of delivery type options - assumes validation is in place that you cannot store sub with HND without retailer
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void initDeliveryOptions(){
        String sParam = null;
        if(this.currentTCodeProduct != null){
            sParam = this.currentTCodeProduct.Product__r.Voucher_Delivery_Type__c;
        }
        this.lstDeliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(sParam);
        if(this.lstDeliveryOptions == null) throw new TelegraphApplicationException(Label.Offline_Acquisition_Renewal_Not_able_to_detect_delivery_types);
        Set<String> setAvailable = new Set<String>();

        for(SelectOption so : this.lstDeliveryOptions){
            setAvailable.add(so.getValue());
        }
        //set default in this order
		if(setAvailable.contains(Constants.DELIVERYTYPE_OTC)){
			this.selectedDelivery = Constants.DELIVERYTYPE_OTC;
		}else if(setAvailable.contains(Constants.DELIVERYTYPE_HND)){
			this.selectedDelivery = Constants.DELIVERYTYPE_HND;
		}
        //if retailer is populated and HND is available set HND - else if no HND option for product, then warning
        if(this.newselectedRetailer != null){
            if(setAvailable.contains(Constants.DELIVERYTYPE_HND)){
            	this.selectedDelivery = Constants.DELIVERYTYPE_HND;
            }else{
                this.displayRetailerResults = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Offline_Acquisition_Not_matching_delivery_type));
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/04/2016
    Version - 1.1
    Function - Tires to restore original value of parameters when Back button is clicked from payment page
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/05/2016  //changed how payment date is set as was failing when it was '01'
    ****************************************************************************************/
    @TestVisible private Boolean restoreParametersOnBack(Map<String, String> mapParameters){
        if(String.isNotBlank(mapParameters.get(PARAM_HASBACK)) && mapParameters.get(PARAM_HASBACK) == 'true'){
            this.subscriptionType = (String.isNotBlank(mapParameters.get(PARAM_SUBSCRIPTION_TYPE))) ? mapParameters.get(PARAM_SUBSCRIPTION_TYPE) : subscriptionType;
            this.sPaymentTypeOverride = (String.isNotBlank(mapParameters.get(PARAM_PAYMENT_TYPE))) ? (mapParameters.get(PARAM_PAYMENT_TYPE)) : paymentType;
            this.sSelectedFrequencyOverride = (String.isNotBlank(mapParameters.get(PARAM_PAYMENT_FREQUENCY))) ? mapParameters.get(PARAM_PAYMENT_FREQUENCY) : paymentFrequency;
            this.selectedIncentiveOverride = (String.isNotBlank(mapParameters.get(PARAM_INCENTIVEID))) ? (mapParameters.get(PARAM_INCENTIVEID)) : selectedIncentive;
            String ppsd = mapParameters.get(PARAM_PAYMENT_START_DATE);
            if(String.isNotBlank(ppsd) && ppsd.left(2).isNumeric()){
                this.preferedStartPaymentDate = (Integer.valueOf(ppsd.left(2)))+'';
            }
            if (String.isNotBlank(mapParameters.get(PARAM_SFDC_RETAILERID))){
                this.selectedRetailer = Id.valueOf(mapParameters.get(PARAM_SFDC_RETAILERID));
                this.selectRetailer();
                this.displayRetailerResults = true;
            }
            this.otherTitle = (String.isNotBlank(mapParameters.get(PARAM_OTHER_TITLE))) ?  mapParameters.get(PARAM_OTHER_TITLE) : otherTitle;
            return true;
        }
        return false;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 13/10/2015
    Version - 1.1
    Function - Moved here from the constructor - if hasBack param is in place, then other Back button related buttons are fetched to preload the page correctly
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         29/10/2015  //changed substring to left()
    Pawel Chrzanowski   2.3     03/05/2017  //removed unused Marketing Preferences
    ****************************************************************************************/
    private void initSubscriber(){
         // POC selected
        if(selectedOffer == Constants.OFFER_POC && selectedProduct == Constants.PRODUCT_PREMIUM && (selectedOffer == Constants.OFFER_POC || selectedOffer == Constants.OFFER_DIRECTMAIL || agencyIdentifier != Constants.AGENT_TMG || orderMethod == Constants.DIRECTION_OUTBOUND)){
            // Force the country to GB - it's premium and POC may not hold the country
            this.subscriber.PersonMailingCountry = Constants.COUNTRY_CODE_GB;
        }else{//if not a POC -> get a subscriber based on TSNumber
            if(String.isNotBlank(this.tsNumber)){
                this.subscriber = [select   Email_Sent__c,
                                            Phone,
                                            Subscriber_Digital_Status__c,
                                            IsPersonAccount,
                                            Guid__c,
                                            Subscriber_Number_static__c,
                                            Salutation,
                                            Website_Last_Accessed__c,
                                            Mobile_Last_Accessed__c,
                                            Tablet_Last_Accessed__c,
                                            Subscription_Status__c,
                                            FirstName, LastName, PersonMailingCountry, PersonMobilePhone, PersonEmail, PersonHomePhone,
                                            PersonMailingState, PersonMailingPostalCode, PersonMailingStreet,
                                            PersonMailingCity, TMG_Promo_Email__c,
                                            TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c, Digital_Product_Type__c,
                                            RecordTypeId, DateOfBirth__c
                                        from Account
                                        where Subscriber_Number_static__c = :this.tsNumber
                                        limit 1];

                TMG_Promo_Email = (subscriber.TMG_Promo_Email__c == 1 ? true : false);
                TMG_Promo_Phone = (subscriber.TMG_Promo_Phone__c == 1 ? true : false);
                TMG_Promo_Post = (subscriber.TMG_Promo_Post__c == 1 ? true : false);
                TMG_Promo_Sms = (subscriber.TMG_Promo_SMS__c == 1 ? true : false);
            }else{
                this.subscriber.LastName = duplicateSurname;
                this.subscriber.PersonMailingPostalCode = duplicatePostCode;
            }

            if(this.selectedProduct == Constants.PRODUCT_PREMIUM){
                this.subscriber.PersonMailingCountry = Constants.COUNTRY_CODE_GB;
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function -  Ensures that the parameters sent via outside agency, inbound or outbound tmg are valid and retrieves the customer details
                Click the radio button in front of a Retailer after selecting HND
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         08/2015     //removed updateIncentives call as was a duplicate of constructor call and qualifyThisAgency is never called anywhere else than constructor
                                            //added low start feature support, moved getInterruptedSubscriptionAndIncentives() out to constructor as its execution had to be postponed
    Wiktor Czykin	1.2			29/10/2015	//replaced few strings with constants
    Wiktor Czykin 	1.3			15/01/2016	//added forced low start price handling and offer to low start switch
    Wiktor Czykin   1.4         12/05/2016  //added setting of digital prices variables
    ****************************************************************************************/
    public void initializeProductAndPricing(){
        this.mapPaymentConfig = new Map<String, PaymentConfig>();
        this.lstSubscriptionTypes = new List<SelectOption>();

        //get tcode product
        this.currentTCodeProduct = GlobalQueries.getTCodeProduct(this.currentCampaign.Id, this.productId);
        if(this.currentTCodeProduct == null) throw new TelegraphApplicationException('Failed to identify tcode product configuration.');
        this.zProductName = this.currentTCodeProduct.Product__r.Name;

        Boolean bForcedPriceApplicable = this.productId == this.initialProductId;

        if (this.orderMethod == Constants.ORDER_METHOD_COUPON){
            this.displayOfferSection = false;
        }

        // MGM price comes from forcedPrice parameter
        if(this.orderMethod == Constants.DIRECTION_INBOUND && this.selectedOffer != Constants.OFFER_MGM){
            // We get the prices from the TcodeMangement object
            this.weeklyPrice = this.currentTCodeProduct.Weekly_Price__c;
            //forced price needs to be set for all offers now
            if(bForcedPriceApplicable && this.dForcedPrice != null){
               this.weeklyPrice = this.dForcedPrice;
            }
        }else{
            // For outbound acquisition, parameters come from Synthesys
            setReadershipValues();
            this.weeklyPrice = this.currentTCodeProduct.Weekly_Price__c;

            // For outbound and 3rd party, price can be forced by parameter: agencyPrice
            if(bForcedPriceApplicable){
                if(this.dForcedPrice != null){
                    this.weeklyPrice = this.dForcedPrice;
                }
                if(this.dforcedLowStartPrice != null){
            	   this.weeklyLowStartPrice = this.dforcedLowStartPrice;
                }
            }
        }

		//change selected offer if related tcode is low start
        if(this.currentCampaign.Type__c == Constants.TCODE_TYPE_LOWSTART && String.isNotBlank(this.selectedOffer) && SET_CONVERTABLE_TO_LOWSTART.contains(this.selectedOffer)){
        	this.selectedOffer = Constants.OFFER_LOWSTART;
        }

        if(this.selectedOffer == Constants.OFFER_LOWSTART){
            if(this.currentTCodeProduct.Low_Start_Price__c != null){
                if(this.weeklyLowStartPrice == null){
                	this.weeklyLowStartPrice = this.currentTCodeProduct.Low_Start_Price__c;
            	}
            }else{
                throw new TelegraphApplicationException(Label.Offline_Acquisition_Low_Start_TCode_configuration_error);
            }
        }

        if(TMGUtil.isDataValid(this.weeklyPrice)){
            this.paymentValues = new List<PaymentValues>();
            if(this.selectedOffer == Constants.OFFER_LOWSTART){
                if(String.isBlank(this.currentCampaign.Low_Start_Period__c) || !this.currentCampaign.Low_Start_Period__c.isNumeric()) throw new TelegraphApplicationException(Label.Offline_Acquisition_Invalid_low_start_period_error);

                this.paymentValues.add(new PaymentValues(this.weeklyLowStartPrice, Label.Offline_Acquisition_Low_Start, Integer.valueOf(this.currentCampaign.Low_Start_Period__c)));
                this.paymentValues.add(new PaymentValues(this.weeklyPrice, Label.Offline_Acquisition_Standard_pricing, null));
            }else{
                this.paymentValues.add(new PaymentValues(this.weeklyPrice, null, null));
            }
            this.weeklyPriceDisplayed = UtilitiesForSubscriptions.convertToTwoDecimalPlaces(weeklyPrice);
        }

        if(TMGUtil.isDataValid(this.weeklyLowStartPrice)){
          	this.weeklyPriceDisplayedLowStart = UtilitiesForSubscriptions.convertToTwoDecimalPlaces(this.weeklyLowStartPrice);
        }

        //MGM code
        if (this.selectedOffer == Constants.OFFER_MGM && String.isBlank(this.mgmGiverId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_No_MGM_giver_id));
            return;
        }

        if (this.selectedProduct == Constants.PRODUCT_DIGITAL){
            if(this.currentTCodeProduct.Digital_Monthly_Price__c == null || this.currentTCodeProduct.Digital_Yearly_Price__c == null) throw new TelegraphApplicationException('Missing digital prices configuration on TCode Product.');
            //only prepare digital prices if we are selling digital sub
            this.digitalMonthlyOpenOfferPrice = this.currentTCodeProduct.Digital_Monthly_Price__c.setScale(2);
            this.digitalYearlyOpenOfferPrice =  this.currentTCodeProduct.Digital_Yearly_Price__c.setScale(2);

            this.initializeDigitalPaymentMap();
        }else{
            this.initializePremiumPaymentMap();
        }

        if(!this.bRenderForm){
            this.bRenderForm = true;
            this.setDefaultValues();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/08/2015
    Version - 1.1
    Function - Method that initializes payment map for Digital 'product' :)
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/05/2016  //changed variable with the price
    ****************************************************************************************/
    @TestVisible private void initializeDigitalPaymentMap(){
        if(this.currentCampaign == null || !TMGUtil.isDataValid(this.digitalMonthlyOpenOfferPrice) || !TMGUtil.isDataValid(this.digitalYearlyOpenOfferPrice)) throw new TelegraphApplicationException(Label.Offline_Acquisition_TCode_not_available);
        TCodeManagement__c t = this.currentCampaign;
        if (String.isBlank(t.Exclude_Digital_Type_For_Flow__c)){
        	PaymentConfig pcMonthly = new PaymentConfig(ONEOFF_DIGITAL_MONTHLY, 4);
	        pcMonthly.dPrice = this.digitalMonthlyOpenOfferPrice;
	        pcMonthly.lstPaymentOptions.add(this.getCCOption());
	        pcMonthly.lstPaymentOptions.add(this.getDDOption());

	        PaymentConfig pcYearly = new PaymentConfig(ONEOFF_DIGITAL_YEARLY, 52);
	        pcYearly.dPrice = this.digitalYearlyOpenOfferPrice;
	        pcYearly.lstPaymentOptions.add(this.getCCOption());
	        this.mapPaymentConfig.put(ONEOFF_DIGITAL_MONTHLY, pcMonthly);
	        this.mapPaymentConfig.put(ONEOFF_DIGITAL_YEARLY, pcYearly);
	        this.lstSubscriptionTypes.add(new SelectOption(pcMonthly.sConfigName, String.format(Label.Offline_Acquisition_Digital_monthly_subscription_type, new List<String>{pcMonthly.dPrice+''})));
	        this.lstSubscriptionTypes.add(new SelectOption(pcYearly.sConfigName, String.format(Label.Offline_Acquisition_Digital_yearly_subscription_type, new List<String>{pcYearly.dPrice+''})));
        }else if (t.Exclude_Digital_Type_For_Flow__c == ONEOFF_DIGITAL_MONTHLY){
        	PaymentConfig pcMonthly = new PaymentConfig(ONEOFF_DIGITAL_MONTHLY, 4);
            pcMonthly.dPrice = this.digitalMonthlyOpenOfferPrice;
            pcMonthly.lstPaymentOptions.add(this.getCCOption());
            pcMonthly.lstPaymentOptions.add(this.getDDOption());
            this.mapPaymentConfig.put(ONEOFF_DIGITAL_MONTHLY, pcMonthly);
            this.lstSubscriptionTypes.add(new SelectOption(pcMonthly.sConfigName, String.format(Label.Offline_Acquisition_Digital_monthly_subscription_type, new List<String>{pcMonthly.dPrice+''})));
        }else if (t.Exclude_Digital_Type_For_Flow__c == ONEOFF_DIGITAL_YEARLY){
            PaymentConfig pcYearly = new PaymentConfig(ONEOFF_DIGITAL_YEARLY, 52);
            pcYearly.dPrice = this.digitalYearlyOpenOfferPrice;
            pcYearly.lstPaymentOptions.add(this.getCCOption());
            this.mapPaymentConfig.put(ONEOFF_DIGITAL_YEARLY, pcYearly);
            this.lstSubscriptionTypes.add(new SelectOption(pcYearly.sConfigName, String.format(Label.Offline_Acquisition_Digital_yearly_subscription_type, new List<String>{pcYearly.dPrice+''})));
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/08/2015
    Version - 1.1
    Function - replaced old getSubscriptionListTypes() - defines available subscription types and payment options based on selected TCode
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         // replaced payment type checkboxes with multi picklist
    ****************************************************************************************/
    @TestVisible private void initializePremiumPaymentMap(){
        if(this.currentCampaign == null || !TMGUtil.isDataValid(this.weeklyPrice)) throw new TelegraphApplicationException(Label.Offline_Acquisition_TCode_not_available);
        TCodeManagement__c t = this.currentCampaign;
        PaymentConfig pc;
        //continuous
        if(t.Is_13_Continuous__c && this.show13WeekCheckbox()){
            pc = new PaymentConfig(CONTINUOUS_13, 13);
            if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_13_WEEK_DD)){
                pc.lstPaymentOptions.add(this.getDDOption());
                pc.sDefaultPaymentOption = DD;
            }
            if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_13_WEEK_CCA)){
                pc.lstPaymentOptions.add(this.getCCOption());
            }
            this.mapPaymentConfig.put(CONTINUOUS_13, pc);
        }
        if(t.Is_26_Continuous__c){
            pc = new PaymentConfig(CONTINUOUS_26, 26);
             if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_26_WEEK_DD)){
                pc.lstPaymentOptions.add(this.getDDOption());
                pc.sDefaultPaymentOption = DD;
            }
            if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_26_WEEK_CCA)){
                pc.lstPaymentOptions.add(this.getCCOption());
            }
            this.mapPaymentConfig.put(CONTINUOUS_26, pc);
        }
        if(t.Is_52_Continuous__c){
            pc = new PaymentConfig(CONTINUOUS_52, 52);
            if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_52_WEEK_DD)){
                pc.sDefaultPaymentOption = DD;
                pc.lstPaymentOptions.add(this.getDDOption());
            }
            if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_52_WEEK_CCA)){
                pc.lstPaymentOptions.add(this.getCCOption());
            }
            this.mapPaymentConfig.put(CONTINUOUS_52, pc);
        }
        //one offs
        if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_ONE_OFF_13_WEEK) && this.show13WeekCheckbox()){
            pc = new PaymentConfig(ONEOFF_13, 13);
            pc.dPrice = Decimal.valueOf(this.price_13week).setScale(2);
            pc.dWeeklyPrice =  pc.dPrice / Double.valueOf(pc.iDuration);
            this.mapPaymentConfig.put(ONEOFF_13, pc);
        }
        if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_ONE_OFF_26_WEEK)){
            pc = new PaymentConfig(ONEOFF_26, 26);
            pc.dPrice = Decimal.valueOf(this.weeklyPrice * 26).setScale(2);
            pc.dWeeklyPrice = this.weeklyPrice;
            this.mapPaymentConfig.put(ONEOFF_26, pc);
        }
        if(TMGUtil.multiPickListSelectionCheck(t.Payment_Type__c,Constants.ALLOW_ONE_OFF_52_WEEK)){
            pc = new PaymentConfig(ONEOFF_52, 52);
            pc.dPrice = Decimal.valueOf(this.weeklyPrice * 52).setScale(2);
            pc.dWeeklyPrice = this.weeklyPrice;
            this.mapPaymentConfig.put(ONEOFF_52, pc);
        }

        //loop through to set some common lines
        for(PaymentConfig pConfig : this.mapPaymentConfig.values()){
            if(SET_CONTINUOUS.contains(pConfig.sConfigName)){
                pConfig.dWeeklyPrice = this.weeklyPrice;
                if(t.Type__c == Constants.TCODE_TYPE_LOWSTART){
                    pConfig.dWeeklyLowStartPrice = this.weeklyLowStartPrice;
                    if(String.isNotBlank(t.Low_Start_Period__c) && t.Low_Start_Period__c.isNumeric()){
                        pConfig.iLowStartDuration = Integer.valueOf(t.Low_Start_Period__c);
                    }
                }
            }else{
                pConfig.lstPaymentOptions.add(this.getCCOption());
                if(this.orderMethod == Constants.ORDER_METHOD_COUPON){
                    pConfig.lstPaymentOptions.add(this.getChequeOption());
                }
            }
            this.lstSubscriptionTypes.add(pConfig.getSubscriptionTypeOption());
        }
        this.lstSubscriptionTypes.sort();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/08/2015
    Version - 1.1
    Function - Loops through the established list of default subscription types and selects one that is available for current tcode
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void setDefaultSubscriptionType(){
        if(this.mapPaymentConfig == null) return;
        if(String.isBlank(this.subscriptionType)){
            for(String sOption : LST_DEFAULTS){
                if(this.mapPaymentConfig.containsKey(sOption)){
                    this.subscriptionType = sOption;
                    break;
                }
            }
        }
        this.selectSubscription();
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function -  This methods initializes the list of Incetives
                It's also called in the constructor for the first load
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         12/04/2016 //changed due to new Tcode Product Incentive object
    Wiktor Czykin   1.2         03/03/2017 //added record type filter
    ****************************************************************************************/
    public void updateIncentives(){
        this.lstActiveIncentives = new List<SelectOption>();
        // For Campaigns with this field checked the user can select no Incentive, we then pass ''
        if(this.currentCampaign.OptionalIncentive__c){
            lstActiveIncentives.add(new SelectOption('', 'No Incentive'));
        }
        String tCodeId = this.currentCampaign.Id;

        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        List<TCode_Product_Incentive__c> lstProductIncentives = [SELECT Incentive__r.Name,
                                                        Incentive__c,
                                                        Incentive__r.Incentive_Description__c,
                                                        Incentive__r.Valid_From__c,
                                                        Incentive__r.Valid_To__c,
                                                        TCode_Product__r.Product__c,
                                                        Subscription_Type__c,
                                                        TCode_Product__r.TCodeManagement__r.Name,
                                                        TCode_Product__r.TCodeManagement__r.Valid__c
                                                    FROM TCode_Product_Incentive__c
                                                    WHERE  TCode_Product__r.TCodeManagement__c= :tCodeId
                                                    AND    TCode_Product__r.Product__c = :this.productId
                                                    AND    TCode_Product__r.RecordTypeId = :offerRecordTypeId
                                                    AND    (Incentive__r.Valid_From__c = NULL OR (Incentive__r.Valid_From__c != NULL AND Incentive__r.Valid_From__c <= TODAY))
                                                    AND    (Incentive__r.Valid_To__c = NULL OR (Incentive__r.Valid_To__c != NULL AND Incentive__r.Valid_To__c >= TODAY))];

		if(MAP_TYPE_TO_TCODEINCENTIVE_FIELD.containsKey(this.subscriptionType)){
            String sFieldToCheck = MAP_TYPE_TO_TCODEINCENTIVE_FIELD.get(this.subscriptionType);
            for(TCode_Product_Incentive__c tci : lstProductIncentives){
                if(tci.Subscription_Type__c.contains(sFieldToCheck)){
                    this.lstActiveIncentives.add(new SelectOption(tci.Incentive__c, tci.Incentive__r.Name));
                    this.mapIncentiveDescription.put(tci.Incentive__c, tci.Incentive__r.Incentive_Description__c);
                }
            }
        }

        // We select the first one be default
        if(lstActiveIncentives.size() != 0){
            if(this.selectedIncentiveOverride != null && this.mapIncentiveDescription.containsKey(this.selectedIncentiveOverride)){
                this.selectedIncentive = this.selectedIncentiveOverride;
                this.selectedIncentiveOverride = null;
            }else{
                this.selectedIncentive = lstActiveIncentives[0].getValue();
            }
            this.bRenderIncentives = true;
        }else{
            this.selectedIncentive ='';
            this.bRenderIncentives = false;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - generates and returns offer options
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         04/2016 //added constants
    ****************************************************************************************/
    public List<SelectOption> getOfferOptions() {
        if (orderMethod == Constants.DIRECTION_OUTBOUND || orderMethod == Constants.DIRECTION_INBOUND){
            return UtilitySelectOptionsSubscriptions.getOfferOptions();
        }else{
            return null;
        }
    }

    public List<SelectOption> getPromoOutbound() {
        if(orderMethod == 'Outbound'){
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('Yes','Yes'));
            options.add(new SelectOption('No','No'));

            outboundPromoSelected = 'No'; //default
            return options;
        }else{
            return null;
        }
    }

    // Retailers search engine
    public PageReference retrieveAllRetailers(){
        try{
            this.subutils.fastRetrieveRetailers(this.postcodeRetailSearch, true);
            this.displayRetailers = this.subUtils.displayRetailers ;
            this.allActiveRetailers = this.subUtils.allActiveRetailers;
            this.displayRetailerResults = true;
        }catch(Exception e){
            System.debug('RetrieveRetailers ' + e);
        }
        return null;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - fetch retailer based on RET_ID__c value
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/08/2015  //simplified
    Wiktor Czykin   1.2         22/09/2015  //changed fetching method
    ****************************************************************************************/
    public PageReference selectRetailerByID(){
        if(!TMGUTil.isDataValid(this.retailerID)){
            return null;
        }
        // We clear the results first
        if(allActiveRetailers != null){
            allActiveRetailers.clear();
        }

        this.retailerAccount = UtilitiesForSubscriptions.returnSelectedRetailerWithoutError(this.retailerID);
        if(this.retailerAccount != null){
            this.selectedRetailerName = retailerAccount.Name;
            this.newselectedRetailer = retailerAccount.Id;
            this.selectedRetailer = retailerAccount.Id;
            this.retailerPostalCode = retailerAccount.BillingPostalCode;
            this.displayRetailerResults = true;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_No_retailers_found_error));
        }
        System.debug('TMGLOG::OapSubscriptionTMG:selectRetailerByID:retailer:' + selectedRetailer);
        return null;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  fetch retailer based on Id value
                Click the radio button in front of a Retailer after selecting HND
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/08/2015  //simplified
    ****************************************************************************************/
    public PageReference selectRetailer(){
        System.debug('TMGLOG::OapSubscriptionTMG:selectRetailer:selectedRetailer:' + this.retailerID + ' ' + this.selectedRetailer);
        this.retailerAccount = UtilitiesForSubscriptions.getRetailerAcc(this.selectedRetailer);
        if(this.retailerAccount != null){
            this.selectedRetailerName = retailerAccount.Name;
            this.newselectedRetailer = retailerAccount.Id;
            this.selectedRetailer = retailerAccount.Id;
            this.retailerPostalCode = retailerAccount.BillingPostalCode;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_No_retailers_found_error));
        }
        return null;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.4
    Function -  Getting the POC informations
                Return Tcode and sets the subscriber variable when valid POC is found for specified criteria.
                Also copies over non-null data from POC record onto the account.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/08/2015  //added labels
    Wiktor Czykin   1.2         04/2016     //removed not used fields from SOQL, changed naming
    Gavin Palmer    1.3         17/06/2016  //added Email__c field to SOQL
    Wiktor Czykin   1.4         19/07/2016  //made sure TSNumber is populated if account retrieved via POC record already exists in sfdc
    ****************************************************************************************/
    public String getPOCAccount(String myPOCid){
        if(String.isBlank(myPOCid)){
            throw new POCException(Label.Offline_Acquisition_POC_code_not_in_URL);
        }
        List<POC__c> lstPocs = [select    Title__c,
                                            FirstName__c,
                                            LastName__c,
                                            Email__c,
                                            City__c,
                                            PostalCode__c,
                                            State__c, Street__c,
                                            POC_ID__c, ExpiryDate__c,
                                            Subscriber_Number__c,
                                            HomeTelephone__c, MobileTelephone__c,
                                            Special_Data__c,TCodeManagement__r.Name
                                        from POC__c
                                        where POC_ID__c = :myPOCid limit 1];
        if (lstPocs.isEmpty()){
            List<Account> accFromOffline = [select Id from Account where POC__c = :myPOCid limit 1];
            if (accFromOffline.isEmpty()){
                //No account has this POC either so user may have entered in an incorrect POC. This will only be applicable in DSOS not in OAP
                throw new POCException(Label.Offline_Acquisition_POC_not_found);
            }else{
                throw new POCException(Label.Offline_Acquisition_POC_code_already_used);
            }
        }else{
            String mytCode = lstPocs[0].TCodeManagement__r.Name;
            if(mytCode == null){
                throw new POCException(Label.Offline_Acquisition_POC_record_with_no_tcode);
            }
            this.poc_id = lstPocs[0].POC_ID__c;
            this.tsNumber = lstPocs[0].Subscriber_Number__c;
            this.subscriber = UtilitiesForSubscriptions.copyPOCToAccount(lstPocs[0]);
            if(String.isNotBlank(this.subscriber.Subscriber_Number_static__c) && this.tsNumber == null){
                this.tsNumber = this.subscriber.Subscriber_Number_static__c;
            }
            return mytCode;
        }
    }

    /*
    *   Set up readership values coming from the URL parameters build by SYnthesys
    */
    public void setReadershipValues(){
        if(String.isNotBlank(this.tmgReadershipFreq)){
            Integer tmgReadershipFreqInteger = 0;
            try{
                tmgReadershipFreqInteger = Integer.valueOf(this.tmgReadershipFreq);
            }catch (Exception err){}
            subscriber.Telegraph_Readership_Frequency__c = tmgReadershipFreqInteger;
        }

        if(String.isNotBlank(this.tmgSundayReadershipFreq)){
            Double tmgSundayReadershipFreqInteger=0;
            try{
                tmgSundayReadershipFreqInteger = Double.valueOf(tmgSundayReadershipFreq);
            }catch (Exception err){}
            subscriber.Telegraph_Sunday_Readership_Frequency__c = tmgSundayReadershipFreqInteger;
        }

        //opposition newspapers
        if(String.isNotBlank(oppositionTitle)){
            subscriber.OppositionTitle__c = oppositionTitle;
        }
        if(String.isNotBlank(oppositionSundayTitle)){
            subscriber.OppositionSundayTitle__c = oppositionSundayTitle;
        }
        if(String.isNotBlank(oppositionTitleFrequency)){
            Integer oppositionTitleFreqInteger=0;
            try{
                oppositionTitleFreqInteger = Integer.valueOf(oppositionTitleFrequency);
            }catch (Exception err){}
            subscriber.Opposition_Title_Frequency__c = oppositionTitleFreqInteger;
        }
        if(String.isNotBlank(oppositionSundayTitleFrequency)){
            Double oppositionSundayTitleFreqInteger=0;
            try{
                oppositionSundayTitleFreqInteger = Double.valueOf(oppositionSundayTitleFrequency);
            }catch (Exception errSundayTitle){}
            subscriber.Opposition_Sunday_Title_Frequency__c = oppositionSundayTitleFreqInteger;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/08/2015
    Version - 1.0
    Function -  just a simple method to generate CC option to avoid copy pasting
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private SelectOption getCCOption(){
        return new SelectOption(CC, Label.Offline_Acquisition_CC_payment_method);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/08/2015
    Version - 1.0
    Function -  just a simple method to generate DD option to avoid copy pasting
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private SelectOption getDDOption(){
        return new SelectOption(DD, Label.Offline_Acquisition_DD_payment_method);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 17/08/2015
    Version - 1.0
    Function -  just a simple method to generate cheque option to be consistent
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private SelectOption getChequeOption(){
        return new SelectOption(Constants.SUB_PMETHOD_CHEQUE, Constants.SUB_PMETHOD_CHEQUE);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - if any non-none subscription offer radio is selected, submission button changes label from default
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         19/08/2015  //added labels
    ****************************************************************************************/
    public void checkSelectedOffer(){
        if(this.selectedOfferOptions != 'None'){
            this.saveBtnName = Label.Offline_Acquisition_Create_subscription_button;
        }else{
            this.saveBtnName = Label.Offline_Acquisition_Save_and_take_payment_button;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/08/2015
    Version - 1.2
    Function -  Replaced checkPaymentState().
                Populates payment type and frequency, if applicable, on subscription type selection change.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			17/11/2015	//changed error message from ERROR to WARNING
    Wiktor Czykin 	1.2			02/02/2016	//added check to not set the payment type to default if it is already set
    ****************************************************************************************/
    public void selectSubscription(){
        if(!this.mapPaymentConfig.containsKey(this.subscriptionType)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Offline_Acquisition_Subsription_type_not_selected));
            return;
        }
        PaymentConfig pc = this.mapPaymentConfig.get(this.subscriptionType);
        this.paymentOptionsList = pc.lstPaymentOptions;
        if(String.isNotBlank(this.sPaymentTypeOverride)){
            for(SelectOption so : this.paymentOptionsList){
                if(this.sPaymentTypeOverride == so.getValue()){
                    this.paymentType = sPaymentTypeOverride;
                    break;
                }
            }
            sPaymentTypeOverride = null;
        }else if(String.isBlank(this.paymentType)){
             this.paymentType = pc.sDefaultPaymentOption;
        }
        if(this.bIsContinuous){
            pc.populateFrequency(this.paymentType == CC);
            this.lstFrequencies = pc.lstFrequency;
            this.paymentFrequency = pc.sDefaultFrequency;
            if(String.isNotBlank(this.sSelectedFrequencyOverride)){
            	this.paymentFrequency = this.sSelectedFrequencyOverride;
            	this.sSelectedFrequencyOverride = null;
            }
        }else{
            this.lstFrequencies = null;
            this.preferedStartPaymentDate = null;
        }
        this.updateIncentives();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/08/2015
    Version - 1.0
    Function -  Replaced checkPaymentType().
                Populates frequency select options depending on the payment method selected.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void populateFrequencies(){
        if(!this.mapPaymentConfig.containsKey(this.subscriptionType)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Subsription_type_not_selected));
            return;
        }
        PaymentConfig pc = this.mapPaymentConfig.get(this.subscriptionType);
        if(this.bIsContinuous){
            pc.populateFrequency(this.paymentType == CC);
            this.lstFrequencies = pc.lstFrequency;
            this.paymentFrequency = pc.sDefaultFrequency;
        }
    }


    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 2.3
    Function -  Validating inputs
                Checking SAM
                Saving Account (and Subscription for Premium)
                Redirecting to MPP payment page
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         01/09/2015  //added price option setting on digital subscriber based on custom settings
    Wiktor Czykin   1.2         14/09/2015  //added extra param to be picked up by MPPUtil controller when payment page accessed from this(acquisition flow)
    Wiktor Czykin   1.3         08-09/2015  //added labels for errors, modified record type fetching, modified upsertSub call, removed ErrorMessages__c reference, modified logic on how price is used
    Wiktor Czykin   1.4         09/09/2015  //moved getIsPageValid() behaviour in here and binned the method
    Cristina Ang.   1.5     	16/09/2015  //add extra param to the URL
    Wiktor Czykin   1.6			20/10/2015  //add extra param to the URL - selectedOffer
    Wiktor Czykin   1.7			11/11/2015  //added support for low start restart flow
    Cristina Ang.   1.8         12/11/2015  //add try and catch when upserting subscriber so that the validation messages are friendly display on the VF page
    Wiktor Czykin   1.9			11/2015		//modified order taken wrapper usage and call to getOrderTakenFieldMap()
    Wiktor Czykin 	2.0			15/01/2016	//added passing of override prices to MppUtil (needed for low start pricing override)
    Pawel Chrzanowski	2.1		06/04/2016	//added validation for Add/Change Email iFrame email
    Wiktor Czykin   2.2         09/05/2016  //added productId passing to MPPUtil
    Wiktor Czykin   2.3         12/05/2016  //added setting of productId on Account for digital subscription, made sure payment start date is not calculated for one-off
	Pawel Chrzanowski   2.4     13/04/2017  //modified Marketing Preferences
    Mantas G.       2.5         09/06/2017  //added parameter if the payment is from OC DDCX 
    ****************************************************************************************/
    public PageReference saveAndTakePayment(){
        SavePoint sp;
        try{
            // Check if there is no Page message
            if(ApexPages.hasMessages() && !Test.isRunningTest()){
                return null;
            }
            // Update Salutation
            this.setSalutation();

            //check email duplicates
			if(String.isNotBlank(this.subscriber.PersonEmail)){
				if(this.subscriber.Id == null){
					List<Account> lstDuplicate = [select Id from Account where PersonEmail = :this.subscriber.PersonEmail];
					if(!lstDuplicate.isEmpty()){
						this.displayDuplicateErrorMessage(lstDuplicate);
						return null;
					}
				}else{
					List<Account> lstDuplicate = [select Id from Account where PersonEmail = :this.subscriber.PersonEmail and Id != :this.subscriber.Id];
					if(!lstDuplicate.isEmpty()){
						this.displayDuplicateErrorMessage(lstDuplicate);
						return null;
					}
				}
			}

	        //throw error on Digital Product and Account without email
	        if(this.selectedProduct == Constants.PRODUCT_DIGITAL && (this.subscriber.PersonEmail == null || this.subscriber.PersonEmail == '')) {
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_No_Email_error));
	            return null;
	        }

            // Checking that LastName is only Letters
            Pattern MyPattern = Pattern.compile('^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$');

            Matcher MyMatcher = MyPattern.matcher(subscriber.FirstName);
            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_First_name_validation));
                return null;
            }

            MyMatcher = MyPattern.matcher(subscriber.LastName);
            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Last_name_validation));
                return null;
            }

            MyPattern = Pattern.compile('[0-9\\s?]+');

            if(TMGUtil.isDataValid(subscriber.PersonMobilePhone)){
                MyMatcher = MyPattern.matcher(subscriber.PersonMobilePhone);
                if(!subscriber.PersonMobilePhone.startsWith('0') || !MyMatcher.matches()){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Mobile_number_validation));
                    return null;
                }
            }

            if(TMGUtil.isDataValid(subscriber.PersonHomePhone)){
                MyMatcher = MyPattern.matcher(subscriber.PersonHomePhone);
                if(!subscriber.PersonHomePhone.startsWith('0') || !MyMatcher.matches()){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Phone_number_validation));
                    return null;
                }
            }

            if(this.selectedProduct == Constants.PRODUCT_PREMIUM && !TMGUtil.isDataValid(this.preferedStartDate)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Voucher_start_date_validation));
                return null;
            }

            if(!TMGUtil.isDataValid(this.subscriptionType)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Subscription_duration_validation));
                return null;
            }

            if(this.bIsContinuous && this.paymentType == CC && this.paymentFrequency != Constants.DD_COL_FREQ_MONTHLY){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Only_monthly_frequency_for_continuous_credit_card_payments));
                return null;
            }

            if ((selectedOfferOptions == Constants.OFFEROPTION_EMAIL || selectedOfferOptions == Constants.OFFEROPTION_BOTH) && String.isBlank(subscriber.PersonEmail)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Email_address_validation_for_offer_options));
                return null;
            }

            if(String.isNotBlank(this.subscriptionType) && !TMGUtil.isDataValid(this.paymentType)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Payment_type_validation));
                return null;
            }
            //fix
            if(this.selectedProduct == Constants.PRODUCT_PREMIUM && this.paymentType == DD && !TMGUtil.isDataValid(this.paymentFrequency)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Payment_frequency_validation_for_DD_payment));
                return null;
            }

            if(this.selectedDelivery == Constants.DELIVERYTYPE_OTC){
                this.newselectedRetailer = null;
                this.selectedRetailer = null;
            }

            if(this.selectedDelivery == Constants.DELIVERYTYPE_HND && String.isBlank(this.newselectedRetailer)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Retailer_required_for_home_delivery_subscription));
                return null;
            }

            if(this.selectedOfferOptions != 'None'  && TMGUtil.isDataValid(subscriber.PersonEmail)){
                for(Account acc : getOfferedDupes()){
                    if(!acc.Subscriptions1__r.isEmpty()){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Offline_Acquisition_Subscriber_offered_subscription_exists_for_given_email, new List<String>{acc.Id, acc.Name})));
                        return null;
                    }
                }
            }

            // Get the Guid if set on the Existing Account (= Already Linked with SAM)
            SAMUtil samUtil = new SAMUtil();
            String sGuid = String.isBlank(ApexPages.currentPage().getParameters().get('Guid')) ? subscriber.Guid__c : ApexPages.currentPage().getParameters().get('Guid');


            if(String.isNotBlank(this.subscriber.PersonEmail)){
                try{
                    SAMUtil.SAMAccountResult samAccount = samUtil.getExistingSAMAccount(this.subscriber.PersonEmail);
                    System.debug('### SAM GUID: ' + samAccount.guid);
                    if(samAccount.entitlementStatus != null && samAccount.entitlementStatus.equals('ACTIVE')){
                        List<Account> accSAMList = [SELECT  Id,
                                                            PersonEmail,
                                                            Account.Guid__c
                                                        FROM Account
                                                        WHERE PersonEmail = :subscriber.PersonEmail
                                                        AND Account.Guid__c = null];

                        if(accSAMList.size() == 1){
                            sGuid = samAccount.guid;
                        }else{
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Active_sam_subscription_error + samAccount.guid));
                            return null;
                        }
                    }else{
                        sGuid = samAccount.guid;
                    }
                }catch(System.CalloutException ce){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Offline_Acquisition_SAM_check_existing_account_issue, new List<String>{this.subscriber.PersonEmail})));
                    return null;
                }catch(System.NullPointerException e){
                    System.debug('### Cannot find active user in SAM: ' + e);
                }catch(WebserviceUtil.SamException e){
                    if(e.getError().errorMessage.contains('ACCOUNT_LOCKED')) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.SAM_Account_locked_error));
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Offline_Acquisition_SAM_check_existing_account_issue, new List<String>{this.subscriber.PersonEmail})));
                    }
                    return null;
                }
            }

            Decimal dSelectedPrice;
            Integer iDuration;
            PaymentConfig pc;
            if(this.subscriptionType != null && this.mapPaymentConfig.containsKey(this.subscriptionType)){
                pc = this.mapPaymentConfig.get(this.subscriptionType);
                if(SET_CONTINUOUS.contains(this.subscriptionType)){
                    dSelectedPrice = pc.dWeeklyPrice * pc.iDuration;
                    if(pc.dWeeklyLowStartPrice != null){
                        dSelectedPrice = pc.dWeeklyLowStartPrice * pc.iDuration;
                    }
                }else{
                    dSelectedPrice = pc.dPrice;
                }
                iDuration = pc.iDuration;
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_No_payment_config));
                return null;
            }

            // SAM GUID
            this.subscriber.Guid__c = sGuid;
            String subscriberStatus = '';
            if(this.selectedProduct == Constants.PRODUCT_DIGITAL){
                this.subscriber.RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName());
                subscriberStatus = subscriber.Subscriber_Digital_Status__c;
                this.subscriber.Product__c  = this.productId;
            }else{
                this.subscriber.RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());
                subscriberStatus = subscriber.Subscription_Status__c;
            }

            // Subscription bought offline
            this.subscriber.Origin__c = Constants.SUBSCRIBER_ORIGIN_FLOW_OFFLINE;
            // MPP email needs to be sent
            this.subscriber.Email_Sent__c = false;
            // The Tcode associated
            this.subscriber.Wave_ID__c = this.currentCampaign.Name;

            // The Customer could have an active Account already
            if(this.subscriber.Subscriber_Digital_Status__c == null){
                this.subscriber.Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE;
            }

            // Marketing Preferences
            this.subscriber.TMG_Promo_Email__c = UtilitiesForSubscriptions.convertBooleanToInteger(TMG_Promo_Email);
            this.subscriber.TMG_Promo_Phone__c = UtilitiesForSubscriptions.convertBooleanToInteger(TMG_Promo_Phone);
            this.subscriber.TMG_Promo_Post__c = UtilitiesForSubscriptions.convertBooleanToInteger(TMG_Promo_Post);
            this.subscriber.TMG_Promo_Sms__c = UtilitiesForSubscriptions.convertBooleanToInteger(TMG_Promo_Sms);

            // MGM
            if (this.selectedOffer == Constants.OFFER_MGM){
                this.subscriber.MGMgiver__c = this.mgmGiverId;
            }

            if(TMGUtil.isDataValid(this.subscriber.Guid__c) && !TMGUtil.isDataValid(this.subscriber.Id) || TMGUtil.isDataValid(this.subscriber.Guid__c) && subscriberStatus == 'Inactive'){
                try{
                    List<Account> accSAMList = Database.query('SELECT Id, Name, PersonEmail, Guid__c FROM Account '
                        + ' WHERE Guid__c = \'' + subscriber.Guid__c + '\''
                        + (TMGUtil.isDataValid(this.tsNumber) ? ' AND Subscriber_Number_static__c != \'' + this.tsNumber + '\'' : ''));

                    if(accSAMList.size() > 0){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Offline_Acquisition_Subscriber_exists_in_sfdc_with_given_guid, new List<String>{this.subscriber.Guid__c, accSAMList[0].Id, accSAMList[0].Name})));
                        return null;
                    }
                }catch(System.Exception e){
                    System.debug('### No Accounts found for SAM GUID:  ' + subscriber.Guid__c);
                }
            }

            //We get the selected price:
            String sPaymentStartDate;
            if(this.selectedProduct == Constants.PRODUCT_PREMIUM && this.bIsContinuous){
                sPaymentStartDate = calculatePaymentStartDate(this.preferedStartDate, this.preferedStartPaymentDate);
            }
            //Find and set the respective pricing option - both premium and digital -> if not there, the processing will continue, but digital customer will not be able to upgrade his sub with upgrade page
            Pricing_Options__c po = GlobalQueries.getPricingOptions(this.selectedProduct, Constants.PRICINGOPTION_FLOWTYPE_SFDC, this.subscriptionType, this.currentCampaign.Name);
            if(po == null && this.selectedProduct == Constants.PRODUCT_DIGITAL){
               po = GlobalQueries.getDigitalPricingOptionBasedOnSetting(this.subscriptionType);
            }
            if(po != null){
                this.subscriber.Pricing_Option__c = po.Id;
            }
            // Check Price configuration
            if(dSelectedPrice == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Price_configuration_failure));
                return null;
            }

            // This identifies the message that should be displayed in the confirmation page
            String mppPaymentMethod = (paymentType == CC)?Constants.MPP_PAYMENTMETHOD_CC:Constants.MPP_PAYMENTMETHOD_DD;

            //Set Subscriber entitlement flags here.
            this.setSubscriberEntitlementFlags();

            // Prepare the values for MPP
            PageReference pr = new PageReference(Page.MppPaymentFrame.getUrl()
                +'?selectedProduct='    + this.selectedProduct
                +'&email='              + (subscriber.PersonEmail == null ? '':EncodingUtil.urlEncode(subscriber.PersonEmail,'UTF-8'))
                +'&title='              + (subscriber.Salutation == null ? '':EncodingUtil.urlEncode(subscriber.Salutation,'UTF-8'))
                +'&othertitle='         + (otherTitle == null ? '':EncodingUtil.urlEncode(otherTitle,'UTF-8'))
                +'&firstName='          + (subscriber.FirstName == null ? '':EncodingUtil.urlEncode(subscriber.FirstName,'UTF-8'))
                +'&lastName='           + (subscriber.LastName == null ? '':EncodingUtil.urlEncode(subscriber.LastName,'UTF-8'))
                +'&price='              + (dSelectedPrice == null ? '':EncodingUtil.urlEncode(dSelectedPrice+'','UTF-8'))
                +'&subscriptionType='   + (this.subscriptionType == null ? '':EncodingUtil.urlEncode(this.subscriptionType,'UTF-8'))
                +'&paymentMethod='      + (mppPaymentMethod == null ? '':EncodingUtil.urlEncode(mppPaymentMethod,'UTF-8'))
                +'&paymentFrequency='   + (this.paymentFrequency == null ? '':EncodingUtil.urlEncode(this.paymentFrequency,'UTF-8'))
                +'&paymentStartDate='   + (sPaymentStartDate == null ? '':EncodingUtil.urlEncode(sPaymentStartDate,'UTF-8'))
                +'&tCode='              + (this.currentCampaign == null ? '':EncodingUtil.urlEncode(this.currentCampaign.Name,'UTF-8'))
                +'&incentiveId='        + (String.isBlank(this.selectedIncentive)? '':EncodingUtil.urlEncode(this.selectedIncentive,'UTF-8'))
                +'&incentiveDescription='+ (String.isBlank(this.selectedIncentive)? '':EncodingUtil.urlEncode(this.getIncentiveDescription() ,'UTF-8'))
                +'&guid='               + (sGuid == null ? '':EncodingUtil.urlEncode(sGuid,'UTF-8'))
                +'&retailerId='        	+ (retailerAccount == null ? '':EncodingUtil.urlEncode(retailerAccount.Id,'UTF-8')));
            pr.getParameters().put('bbtn', '1');
            pr.getParameters().put('requestorigin','internal');
            pr.getParameters().put('duration', iDuration+'');
            pr.getParameters().put('selectedOffer', (String.isNotBlank(this.selectedOfferOriginal)?EncodingUtil.urlEncode(this.selectedOfferOriginal,'UTF-8'):''));
            pr.getParameters().put('forcedPrice', (this.weeklyPrice==null?'':EncodingUtil.urlEncode(this.weeklyPrice+'', 'UTF-8')));
            pr.getParameters().put('forcedLowStartPrice', (this.weeklyLowStartPrice==null?'':EncodingUtil.urlEncode(this.weeklyLowStartPrice+'', 'UTF-8')));
            if(this.bIsRestart){
	            pr.getParameters().put('restart', 'true');
            }
            pr.getParameters().put('productId', this.productId);
            if(mapParameters.get('isOCDDCX') != null)
                pr.getParameters().put('isOCDDCX', mapParameters.get('isOCDDCX'));
            // Setting the Transaction
            sp = Database.setSavepoint();

            if (String.isNotBlank(this.tsNumber)){
                update subscriber;
            }else{
                insert subscriber;
                List<Account> lstAccount = [select Subscriber_Number__c from Account where Id = :subscriber.Id];
                if(lstAccount.isEmpty()) throw new TelegraphApplicationException(Label.Offline_Acquisition_Account_refetch_error);
                this.tsNumber = lstAccount[0].Subscriber_Number__c;
            }
            this.newTSNumber = this.tsNumber;
            this.newAccId = this.subscriber.Id;

            pr.getParameters().put('accId', this.subscriber.Id);
            pr.getParameters().put('TSNumber', this.tsNumber);
            //Get order taken fields for passing back to MPP.
            MppUtil.OrderTakenDetails mppFieldMap = MppUtil.getOrderTakenFieldMap(this.agentUserId, this.orderTakenCompany, this.orderMethod);
            subscriber.Order_Taken_Date__c = Date.today();
            subscriber.Order_Taken_By_Company__c = mppFieldMap.byCompany;
            subscriber.Order_Taken_By_User_Department__c = mppFieldMap.byUser;
            subscriber.Order_Taken_Method__c = mppFieldMap.orderMethod;

            //PREMIUM
            if(this.selectedProduct == Constants.PRODUCT_PREMIUM){
                // Staff Offer
                String sStaffName;
                if (selectedOffer == Constants.OFFER_STAFF && ApexPages.currentPage().getParameters().containsKey(PARAM_STAFF_NAME)){
                    sStaffName = ApexPages.currentPage().getParameters().get(PARAM_STAFF_NAME);
                    if(String.isNotBlank(sStaffName)){
                        subscriber.New_ACQ_Promo_code__c = sStaffName;
                    }

                    try{
                        update subscriber;
                    }catch(Exception ex){
                        ApexPages.addMessages(ex);
                    }
                }

                //SUBS
                if(selectedDelivery == Constants.DELIVERYTYPE_HND && retailerAccount != null){
                    this.newselectedRetailer =  retailerAccount.id;
                }


                try{
                    Subscription__c upsertedSubscription = this.upsertSub( 	this.subscriptionId,
										                                    this.subscriber,
										                                    pc,
										                                    this.preferedStartDate,
										                                    this.preferedStartPaymentDate,
										                                    this.paymentType,
										                                    this.selectedDelivery,
										                                    this.newselectedRetailer,
										                                    this.orderTakenCompany,
										                                    this.currentCampaign,
										                                    this.agentUserId,
										                                    'Agency',
										                                    this.orderMethod,
										                                    sStaffName,
										                                    mppFieldMap,
										                                    sPaymentStartDate,
										                                    this.paymentFrequency,
										                                    this.bIsContinuous
										                                    );
                  	this.subId = upsertedSubscription.Id;
	                 //Cheque stuff d subId, String chequeBatchSelected, Boolean createNewBatch, Integer duration, Cheque__c cheque, Decimal weeklyPrice){
			        if(this.paymentType == Constants.SUB_PMETHOD_CHEQUE && String.isNotBlank(this.subId)){
			            try{
			            	TMGUtil.processChequePayment(  	this.subId,
			                                        		chequeBatchSelected,
			                                        		createNewBatch,
			                                        		Integer.valueOf(upsertedSubscription.Subscription_Duration_Picklist__c),
			                                        		this.cheque,
			                                        		(Double)upsertedSubscription.Weekly_Price__c);
			            }catch(Exception e){
			                throw new ChequeException('The new TS Number is ' + this.newTSNumber + '. But an error occurred creating the Cheque. '+e.getMessage());
			            }

			            if(String.isNotBlank(this.selectedIncentive)){
			                SubscriptionsWebservicesHandlers.createSubscriberIncentive(this.newTSNumber, this.subId, (Id)this.selectedIncentive);
			            }
			        }
                } catch(Exception e){
                    if(sp != null)Database.rollback(sp);
                    this.resetTSNumber();
                    ApexPages.addMessages(e);
                    return null;
                }

                // No Payement when Offer is selected
                // It just creates an OffsuccessMessagePart3ered Sub and insert a Task
                if (this.selectedOfferOptions != 'None'){
                    this.sendOfferCommunication(this.paymentValues, pc);
                    if(this.orderMethod != Constants.ORDER_METHOD_COUPON){
                        if(this.selectedDelivery == Constants.DELIVERYTYPE_HND){
                            successMessagePart3 = Label.Offline_Acquisition_Offer_message_HND;
                        }else{
                            successMessagePart3 = Label.Offline_Acquisition_Offer_message_OTC;
                        }
                    }
                    if(!ApexPages.hasMessages()){
                        pr = new PageReference(Page.MppPaymentConfirm.getUrl() + '?accId=' + subscriber.id + '&PaymentStatus=Success&offeredMsg=Offered subscription created.<br/><br/>' + successMessagePart3);
                    }else{
                        pr = null;
                    }
                }
            }

             //Send only if going through the payment page?
            if(pr.getUrl().contains(Page.MppPaymentFrame.getUrl())){
                pr.getParameters().put('orderTakenMethod', (TMGUtil.isDataValid(mppFieldMap.orderMethod) ? EncodingUtil.urlEncode(mppFieldMap.orderMethod, 'UTF-8') : ''));
                pr.getParameters().put('orderTakenByCompany', (TMGUtil.isDataValid(mppFieldMap.byCompany) ? EncodingUtil.urlEncode(mppFieldMap.byCompany, 'UTF-8') : ''));
                pr.getParameters().put('orderTakenbyUser', (TMGUtil.isDataValid(mppFieldMap.byUser) ? EncodingUtil.urlEncode(mppFieldMap.byUser, 'UTF-8') : ''));

                if(TMGUtil.isDataValid(subId)){
                    pr.getParameters().put('subId', this.subId);
                }
            }

            //Cheque stuff
            String action;
            if(this.paymentType.toLowerCase().equals(Constants.SUB_PMETHOD_CHEQUE.toLowerCase())){
                if(TMGUtil.isDataValid(this.subscriber.PersonEmail)){
                    // We check if we received a GUID from SAM
                    if(String.isNotBlank(this.subscriber.Guid__c)){
                        action = 'UPDATE_SAM';
                    }else{
                        action = 'CREATE_SAM';
                    }
                }else{
                    action = '';
                }

                callSAMFuture(this.subscriber.Id, action, sGuid, this.selectedProduct.toLowerCase());
                if(!ApexPages.hasMessages()){
                    pr = new PageReference(Page.MppPaymentConfirm.getUrl() + '?accId=' + subscriber.id + '&PaymentStatus=Success&action='
                        + action + '&offeredMsg=<br/><br/>Subscription created successfully.&emailTrigger=true');
                }else{
                    pr = null;
                }
            }
            pr.getParameters().put('requestorigin','internal');
            if(TMGUtil.isDataValid(subId)){
                pr.getParameters().put('subId', subId);
            }
            SubscriberPortal.SUB_TRIGGER_FIRED = true;
            Constants.MPP_CALLOUT_DISABLED = true;
            update this.subscriber;
            return pr;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred during payment. Please contact the system administrator.<br/><br/>Details: <br/>' + e.getMessage()));
            if(sp != null) Database.rollback(sp);
            this.resetTSNumber();
            return null;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  sets titles based on custom title field, if populated
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void setSalutation(){
        if (String.isNotBlank(otherTitle)){
            subscriber.Salutation = otherTitle;
            subscriber.Title__c = otherTitle;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function -  sets product flags on Account depending on the product selection on the page
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void setSubscriberEntitlementFlags(){
        if(this.selectedProduct.toLowerCase().equals(Constants.PRODUCT_DIGITAL.toLowerCase())){
            this.subscriber.iPadAccess__c = true;
            this.subscriber.smartphoneAccess__c = true;
            this.subscriber.websiteAccess__c = true;
            this.subscriber.loyaltyAccess__c = (subscriber.PersonMailingCountry == Constants.COUNTRY_CODE_GB);
            this.subscriber.Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_ALLDEVICES;
        }else{
            this.subscriber.iPadAccess__c = true;
            this.subscriber.smartphoneAccess__c = true;
            this.subscriber.websiteAccess__c = true;
            this.subscriber.loyaltyAccess__c = (subscriber.PersonMailingCountry == Constants.COUNTRY_CODE_GB);
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  checks if account exists, else blanks out the vars
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         19/08/2015  //changed to non-exception driven
    ****************************************************************************************/
    private void resetTSNumber(){
        List<Account> lstAcc = [select Id, Subscriber_Number_static__c from Account where Subscriber_Number_static__c = :this.tsNumber];
        if(lstAcc.isEmpty()){
            this.tsNumber = null;
            this.newTSNumber = null;
            this.newAccId = null;
            this.subscriber.Id = null;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Checks if there exists another account with the same email, that already has an offered subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         19/08/2015  //simplified
    ****************************************************************************************/
    public List<Account> getOfferedDupes(){
        Set<String> setStatus = new Set<String>{Constants.SSTATUS_OFFERED};
        return [select  Id,
                        (select Id
                            from Subscriptions1__r
                            where Subscription_Status__c IN :setStatus
                        )
                    from Account
                    where PersonEmail = :this.subscriber.PersonEmail.toLowerCase()
                    and Subscriber_Number_Static__c != :this.tsNumber];
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Executed when selectedOfferOptions is different than None
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/09/2015  //added low start template version, fixed 2 issues where tsnumber was not populated and where tasks didnt get account assigned
    ****************************************************************************************/
    public void sendOfferCommunication(List<PaymentValues> lstPaymentValues, PaymentConfig config){
        if(lstPaymentValues == null || lstPaymentValues.isEmpty()) return;

        List<SubManagementDefaults__c> lstDefaults = [select DefaultValue__c from SubManagementDefaults__c where ID__c='CoverPrice'];
        Double coverPrice;
        if(lstDefaults.isEmpty() || String.isBlank(lstDefaults[0].DefaultValue__c)) throw new TelegraphApplicationException(Label.Offline_Acquisition_Offer_communication_cover_price_error);
        try{
            coverPrice = Decimal.valueOf(lstDefaults[0].DefaultValue__c);
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.Offline_Acquisition_Offer_communication_cover_price_error);
        }

        PaymentValues pvStandard = lstPaymentValues[0];
        String dtToday = UtilitySelectOptionsSubscriptions.getDateAsString(Date.today());
        String sCustName = this.subscriber.Salutation + ' ' + this.subscriber.FirstName  + ' ' + this.subscriber.LastName;
        String sStateEntry;
        TMGUtil.EmailUtil emailUtil;

        if(String.isNotBlank(subscriber.PersonMailingState)){
            sStateEntry = '<span>' + subscriber.PersonMailingState + '</span><br />';
        }else{
            sStateEntry = '';
        }

        String emailBody = String.format(Label.Offline_Acquisition_Offer_communication_email_header, new List<String>{  sCustName,
                                                                                                                        subscriber.PersonMailingStreet,
                                                                                                                        subscriber.PersonMailingCity,
                                                                                                                        sStateEntry,
                                                                                                                        subscriber.PersonMailingPostalCode,
                                                                                                                        newTSNumber,
                                                                                                                        dtToday
        });

        try{
            if(this.selectedOffer == Constants.OFFER_LOWSTART){
                PaymentValues pvLowStart = lstPaymentValues[0];
                pvStandard = lstPaymentValues[1];
                Decimal total = config.iLowStartDuration * config.dWeeklyLowStartPrice + ((config.iDuration - config.iLowStartDuration) * config.dWeeklyPrice);
                emailBody += String.format(Label.Offline_Acquisition_Offer_communication_email_content_low_start, new List<String>{ '£'+UtilitiesForSubscriptions.convertToTwoDecimalPlaces(pvLowStart.dWeeklyPrice),
                                                                                                                                    config.iLowStartDuration+'',
                                                                                                                                    '£'+UtilitiesForSubscriptions.convertToTwoDecimalPlaces(pvStandard.dWeeklyPrice),
                                                                                                                                    pvLowStart.firstMontlyPayment,
                                                                                                                                    pvStandard.firstMontlyPayment,
                                                                                                                                    pvLowStart.numberOfPayments+'',
                                                                                                                                    pvLowStart.quaterlyPayment,
                                                                                                                                    pvStandard.quaterlyPayment,
                                                                                                                                    config.iDuration+'',
                                                                                                                                    '£'+UtilitiesForSubscriptions.convertToTwoDecimalPlaces(total)
                });
                emailBody += String.format(Label.Offline_Acquisition_Offer_communication_email_last_paragraph_low_start, new List<String>{newTSNumber});
            }else{
                Double priceDifference = coverPrice - pvStandard.dWeeklyPrice;
                String sCoverPrice  = UtilitiesForSubscriptions.convertToTwoDecimalPlaces(coverPrice);
                String sPriceDifference = UtilitiesForSubscriptions.convertToTwoDecimalPlaces(priceDifference);
                String yearCostStr = pvStandard.creditCard52WkPayment;
                String halfyearCostStr =  pvStandard.creditCard26WkPayment;

                String ddPayment;
                //create text for the DD payments to enter into the email and letter
                if (pvStandard.firstMontlyPayment != pvStandard.subsequentMonthlyPayment){
                    ddPayment = '<label>Quarterly payments of  ' + pvStandard.quaterlyPayment + '</label><br /><label>First monthly payment of '+ pvStandard.firstMontlyPayment + ', followed by ' + pvStandard.subsequentMonthlyPayment + '</label><br />';
                }else{
                    ddPayment = '<label>Quarterly payments of  ' + pvStandard.quaterlyPayment + '</label><br /><label>Monthly payments of ' + pvStandard.firstMontlyPayment + '</label><br />';
                }
                emailBody += String.format(Label.Offline_Acquisition_Offer_communication_email_first_paragraph_non_low_start, new List<String> {    WeeklyPriceDisplayed,
                                                                                                                                                    sPriceDifference,
                                                                                                                                                    sCoverPrice,
                                                                                                                                                    yearCostStr,
                                                                                                                                                    halfyearCostStr
                });
                emailBody += String.format(Label.Offline_Acquisition_Offer_communication_email_second_paragraph_non_low_start, new List<String>{newTSNumber, ddPayment});
                emailBody += Label.Offline_Acquisition_Offer_communication_email_final_paragraph_non_low_start;
            }
        }catch(Exception e){
            throw new TelegraphApplicationException(Label.Offline_Acquisition_Offer_communication_email_content_error);
        }

        System.debug('emailBody ' + emailBody + ' ' + selectedOfferOptions  + ' ' + defaultEmail);
        List<String> toAddresses;
        if (selectedOfferOptions == Constants.OFFEROPTION_EMAIL || selectedOfferOptions == Constants.OFFEROPTION_BOTH){
            //send email to the customer
            List<Document> mandate =  [select Id from Document where Name = 'DD Mandate' limit 1];
            defaultEmail = [Select DefaultValue__c From SubManagementDefaults__c Where ID__c='DefaultAgencyEmail'].DefaultValue__c;
            ID mandateID;
            if (mandate.size()>0)
                mandateID = mandate[0].id;

            toAddresses = new List<String> {subscriber.PersonEmail};
            emailUtil = new TMGUtil.EmailUtil(toAddresses);
            emailUtil.htmlBody(emailBody)
                    .senderDisplayName(Label.Offline_Acquisition_Offer_communication_email_sender_name)
                    .replyTo(defaultEmail)
                    .subject(Label.Offline_Acquisition_Offer_communication_email_subject)
                    .documentAttach(mandateID)
                    .build()
                    .sendEmail();
        }
        if (selectedOfferOptions == Constants.OFFEROPTION_COUPON){
            //send email to the agents specified in SubManagementDefaults__c with attachment of the letter to print and create a task for a call to action
            this.createTask(this.newAccId, Label.Offline_Acquisition_Offer_communication_related_task_subject, Constants.SUBSCRIPTION_LETTER_OFFER);
        }else if (selectedOfferOptions == Constants.OFFEROPTION_EMAIL){
            this.createTask(this.newAccId, Label.Offline_Acquisition_Offer_communication_related_task_subject, Constants.SUBSCRIPTION_EMAIL_OFFER);
        }else if (selectedOfferOptions == Constants.OFFEROPTION_BOTH){
           	this.createTask(this.newAccId, Label.Offline_Acquisition_Offer_communication_related_task_subject,Constants.SUBSCRIPTION_EMAIL_AND_LETTER_OFFER);
        }
    }

	/***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/12/2015
    Version - 1.0
    Function - Moved here from UtilitySubscriptionTransactions class as it was the only used method in that big class. Class removed afterwards.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private void createTask(Id recordId, String sSubject, String sReason){
		try{
			insert new Task(	WhatId = recordId,
								Reason_For_Call__c = sReason,
								Subject = sSubject);
		}catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Task_creation_error));
		}
	}

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.6
    Function -  Create Subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/07/2015  //changed weekly price source for Cheque creation as was using wrong value
    Wiktor Czykin   1.2         21/08/2015  //modified the method signature and method contents to match new parameters
    Wiktor Czykin   1.3         16/09/2015  //added populating of frequency for continuous payments -> so that if callback is Irregular we can still now
    Cristina Ang    1.4         01/10/2015  //create subscription incentive when payment method is cheque
    Wiktor Czykin	1.5			29/10/2015	//added nullification of opposite frequency - change related to Low Start restart
    Wiktor Czykin   1.6         11/05/2016  //added reset of frequency and payment start date, so it is nullified unless save operation processes them.
                                            This is to support back button followed by change from continuous to one-off
    Wiktor Czykin   1.7         17/11/2016  //added reset to default sub from low start
    ****************************************************************************************/
    public Subscription__c upsertSub(  	Id subscriptionId,
			                            Account acc,
			                            PaymentConfig paymentSelection,
			                            String sPreferedStartDate,
			                            String sPreferedStartPaymentDate,
			                            String sPayType,
			                            String sSelectedDelivery,
			                            String sSelectedRetailer,
			                            String sOrderTakenCompany,
			                            TCodeManagement__c tCode,
			                            Id agentUserId,
			                            String sCurrentPage,
			                            String sOrderTakenMethod,
			                            String sStaffName,
			                            MppUtil.OrderTakenDetails mppFieldMap,
			                            String sPaymentStartDate,
			                            String sFrequency,
			                            Boolean bContinuous
			                            ){

        if(paymentSelection == null) throw new SubscriptionUpsertException(Label.Offline_Acquisition_Upsert_subscription_parameters_error);

        Subscription__c subToBeCreated;
        if(subscriptionId != null){
            subToBeCreated = new Subscription__c(Id = subscriptionId);
        }else{
            subToBeCreated = new Subscription__c();
            subToBeCreated.Subscriber__c = acc.id;
        }
        subToBeCreated.MPP_CC_Frequency__c = null;
        subToBeCreated.MPP_DD_Frequency__c = null;
        if(sPayType == CC){
            if(bContinuous){
                subToBeCreated.MPP_CC_Frequency__c = sFrequency;
            }
            sPayType = Constants.SUB_PMETHOD_CC;
        }else if(sPayType == Constants.SUB_PMETHOD_CHEQUE){
        }else {
            sPayType = Constants.SUB_PMETHOD_DD ;
            subToBeCreated.MPP_DD_Frequency__c = sFrequency;
        }

        // Staff Offer
        if(String.isNotBlank(sStaffName)){
            subToBeCreated.StaffOfferRecipient__c = sStaffName;
        }
        subToBeCreated.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subToBeCreated.Start_Date__c = Date.parse(sPreferedStartDate);
        subToBeCreated.PaymentDate__c = sPreferedStartPaymentDate;//1 or 15

        //added lookup on subscription to Zproduct
        if(this.productId != null){
            subToBeCreated.Product__c = this.productId;
        }
        subToBeCreated.Weekly_Price__c = paymentSelection.dWeeklyPrice;

        //if low start price exists means low start sub - setting proper fields and record type
        if(paymentSelection.dWeeklyLowStartPrice != null){
            subToBeCreated.Low_Start_Weekly_Price__c = paymentSelection.dWeeklyLowStartPrice;
            subToBeCreated.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
            subToBeCreated.Low_Start_Period__c = paymentSelection.iLowStartDuration;
            //Low_Start_End_Date__c is updated by Subscription__c trigger based on Low_Start_Period__c and Start_Date__c
        }else{
            subToBeCreated.RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName());
            subToBeCreated.Low_Start_Period__c = null;
            subToBeCreated.Low_Start_Weekly_Price__c = null;
            subToBeCreated.Low_Start_End_Date__c = null;
        }

        subToBeCreated.Subscription_Duration_Picklist__c = paymentSelection.iDuration+'';
        subToBeCreated.Payment_Type__c = sPayType;
        subToBeCreated.TCode__c = tCode.Id;
        subToBeCreated.Delivery_Type__c = sSelectedDelivery;
        subToBeCreated.Retailer__c = sSelectedRetailer;
        subToBeCreated.IsContinuous__c = SET_CONTINUOUS.contains(paymentSelection.sConfigName);
        subToBeCreated.Payment_Start_Date__c = null;
        if(TMGUtil.isDataValid(sPaymentStartDate)){
            subToBeCreated.Payment_Start_Date__c = Date.parse(sPaymentStartDate);
        }

        if(subToBeCreated.Id == null){
            subToBeCreated.WebsiteLastAccessed__c = acc.Website_Last_Accessed__c;
            subToBeCreated.Mobile_Last_Accessed__c = acc.Mobile_Last_Accessed__c;
            subToBeCreated.Tablet_Last_Accessed__c = acc.Tablet_Last_Accessed__c;
        }

        //Enter OrderTakenCompany as ID in SubManagementDefaults Default will be the area eg: UK, South Africa etc
        List<SubManagementDefaults__c> lstOrderTakenDepartmentList = [select DefaultValue__c From SubManagementDefaults__c where ID__c=:sOrderTakenCompany];
        if (!lstOrderTakenDepartmentList.isEmpty()){
            subToBeCreated.Order_Taken_By_Company__c = lstOrderTakenDepartmentList[0].DefaultValue__c;
        }else{
            subToBeCreated.Order_Taken_By_Company__c = sOrderTakenCompany;
        }
        subToBeCreated.Order_Taken_Date__c = Date.today();
        subToBeCreated.Order_Taken_Method__c = sOrderTakenMethod;

        if(sCurrentPage == 'Agency'){
            if (agentUserId != null){
                try{
                	subToBeCreated.Order_Taken_By_User_Department__c = [select Name From User where id=:AgentUserId].Name;
                }catch(System.Exception e){
                    subToBeCreated.Order_Taken_By_User_Department__c = agentUserId;
                }
            }else{
                subToBeCreated.Order_Taken_By_User_Department__c = 'Not Provided';
            }
        }else{
            subToBeCreated.Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
            subToBeCreated.Order_Taken_Method__c = Constants.CONST_DSOS; //if this changes then SubscriptionChangeToPending needs to be changed or use another default value for this
            subToBeCreated.Order_Taken_By_User_Department__c = sCurrentPage;
        }

        mppFieldMap.orderMethod = subToBeCreated.Order_Taken_Method__c;
        mppFieldMap.byCompany =  subToBeCreated.Order_Taken_By_Company__c;
        mppFieldMap.byUser = subToBeCreated.Order_Taken_By_User_Department__c;

        subscriber.Order_Taken_Date__c = Date.today();
        subscriber.Order_Taken_By_Company__c = subToBeCreated.Order_Taken_By_Company__c;
        subscriber.Order_Taken_By_User_Department__c = subToBeCreated.Order_Taken_By_User_Department__c;
        subscriber.Order_Taken_Method__c = subToBeCreated.Order_Taken_Method__c;
        subToBeCreated.TaskCreation__c='Call';

        upsert subToBeCreated;
      	return subToBeCreated;
    }

    public PageReference updateAndLinkSAMAccount(){
        return saveAndTakePayment();
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Function - Returns Picklist-ready list of Countries based on custom settings
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   18/07/2017  //moved the actual implementation to GlobalQueries
    ****************************************************************************************/
    public List<SelectOption> getCountries(){
        return GlobalQueries.getCountries(false);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 06/05/2016
    Version - 1.2
    Function - implementation of ProductSwitchSupport interface method - changes product Id in context and re-initializes pricing
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         01/09/2016  //added delivery options init - as available options are now dependent on the related product
    Wiktor Czykin   1.2         31/10/2016  //added call to refresh incentives list
    Vishant Shah    2.5         04/01/2017  //added generation in changeProductId
    ****************************************************************************************/
    public void changeProductId(Id productId){
        if(productId == null) throw new TelegraphApplicationException('Product switch functionality returned null value.');
        this.productId = productId;
        this.initializeProductAndPricing();
        this.preferredStartDatesList =  UtilitySelectOptionsSubscriptions.getStartDates(12, Integer.valueOf(this.currentTCodeProduct.Product__r.LeadDays__c));
        this.preferedStartDate = preferredStartDatesList.get(1).getValue();
        this.initDeliveryOptions();
        this.updateIncentives();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 06/05/2016
    Version - 1.0
    Function - implementation of ProductSwitchSupport interface method - makes sure forced price updates initially selected product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void prepareProductListBeforeView(List<TCodeProductWrapper> lstProducts){
        if((this.dForcedPrice != null || this.dforcedLowStartPrice != null) && lstProducts != null && !lstProducts.isEmpty()){
            for(TCodeProductWrapper tpw : lstProducts){
                if(tpw.productId == this.initialProductId){
                    if(this.dForcedPrice != null){
                        tpw.premiumPrice = this.dForcedPrice;
                    }
                    if(this.dforcedLowStartPrice != null){
                        tpw.lowStartPrice = this.dforcedLowStartPrice;
                    }
                    break;
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - Try to get the Offered Subscription Oject in case of an interupted Transaction and prepopulate the screen
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         20/08/2015  //made sure that fields are properly prepopulated in new execution flow (eg. added extra buffer vars)
    Wiktor Czykin	1.2			11/11/2015	//fixed wrong variable being set, added restart flow support
    Pawel Chrzanowski   1.3     03/03/2016  //added subscription name
    ****************************************************************************************/
    public Id getInterruptedSubscriptionAndIncentives(String subscriberId){
        List<Subscription__c> lstSub = [select  Id,
                                                isContinuous__c,
                                                Name,
                                                Subscription_Duration_Picklist__c,
                                                Start_Date__c,
                                                Weekly_Price__c,
                                                Payment_Type__c,
                                                Delivery_Type__c,
                                                Retailer__c,
                                                Order_Taken_By_Company__c
                                            from Subscription__c
                                            where Subscriber__c = :subscriberId
                                            and Subscription_Status__c =:Constants.SSTATUS_OFFERED
                                            order by LastModifiedDate desc
                                            limit 1];
        Subscription__c sub;
        if(lstSub.size() == 0){
            return null;
        }else{
            sub = lstSub[0];
        }

        String sKey = sub.Subscription_Duration_Picklist__c;
        if(sub.isContinuous__c){
            sKey += Constants.KEY_CONTINUOUS;
        }else{
            sKey += Constants.KEY_ONEOFF;
        }
        this.subscriptionType = sKey;
        this.preferedStartDate = sub.Start_Date__c.format();
        if(sub.Payment_Type__c == Constants.SUB_PMETHOD_CC){
            this.paymentType = CC;
        }else if(sub.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            this.paymentType = DD;
        }else if(sub.Payment_Type__c == Constants.SUB_PMETHOD_CHEQUE){
            this.paymentType = Constants.SUB_PMETHOD_CHEQUE;
        }
        this.selectedDelivery = sub.Delivery_Type__c;
        this.newselectedRetailer = sub.Retailer__c;
        this.orderTakenCompany = sub.Order_Taken_By_Company__c;

        List<SubscriptionIncentiveAssociation__c> lstSelectedIncentive = [SELECT Incentive__c FROM SubscriptionIncentiveAssociation__c WHERE Subscriber__c=:subscriberId AND Subscription__c=:sub.id];
        if(!lstSelectedIncentive.isEmpty()){
            this.selectedIncentiveOverride = lstSelectedIncentive[0].Incentive__c;
        }

        if(this.bIsRestart && this.preferredStartDatesList != null && sub.Start_Date__c != null){
        	Boolean bCurrentDateFound = false;
        	for(SelectOption so : this.preferredStartDatesList){
        		if(so.getValue() == this.preferedStartDate){
        			bCurrentDateFound = true;
        			break;
        		}
        	}
        	if(!bCurrentDateFound){
	        	List<SelectOption> lstOptions = new List<SelectOption>{new SelectOption(this.preferedStartDate, UtilitySelectOptionsSubscriptions.GetDateAsString(sub.Start_Date__c))};
	        	lstOptions.addAll(this.preferredStartDatesList);
	        	this.preferredStartDatesList = lstOptions;
        	}
        }
        this.subscriptionName = sub.Name;
        return sub.id;
    }

    /*
    *   Returns the Payment Start Date. User input: 1 or 15
    *   1: always next date mont 1st day
    *   15: if today before 15 then its this month's 15th
    *       else Next month's 15th
    */
    public String calculatePaymentStartDate(String preferedStartDate, String oneOrFifteen){
        System.debug('#### preferedStartDate: ' + preferedStartDate);
        System.debug('#### oneOrFifteen: ' + oneOrFifteen);

        Date paymentDate;
        Date dateStartDate = Date.parse(preferedStartDate);
        if(oneOrFifteen == '1'){
            paymentDate = Date.newinstance(dateStartDate.year(), dateStartDate.month()+1, 1);
        }else{
            if(dateStartDate.day() < 15){
                paymentDate = Date.newinstance(dateStartDate.year(), dateStartDate.month(), 15);
            }
            else{
                paymentDate = Date.newinstance(dateStartDate.year(), dateStartDate.month()+1, 15);
            }
        }
        System.debug('paymentDate.format(): '+paymentDate.format());
        return paymentDate.format();
    }

    //Gets the desciption of the selected incentive
    public String getIncentiveDescription(){
        return mapIncentiveDescription.get(this.selectedIncentive)!=null?mapIncentiveDescription.get(this.selectedIncentive):'';
    }

    @TestVisible
    private Boolean show13WeekCheckbox(){
        Boolean show = false;
        try{
            General__c setting = General__c.getInstance('Allow 13 week Inbound Sub Acq');
            if(setting != null){
                show = Boolean.valueOf(setting.Value__c);
            }else{
                show = false;
            }
        }catch(Exception ex){
            show = false;
        }
        return show;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - callout to setup/update sam account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/05/2016  //added entitlements setting for Create scenario
    Vishant Shah    1.2         20/03/2017  //added default newsletter during cheque payment
    ****************************************************************************************/
    @future(callout=true)
    private static void callSAMFuture(String id, String action, String guid, String product){
        SAMUtil samUtil = new SAMUtil();

        Account subscriber = [SELECT Email_Sent__c, RecordTypeId, Subscriber_Digital_Status__c, Guid__c, IsPersonAccount, Subscriber_Number_static__c, Salutation, Website_Last_Accessed__c, Mobile_Last_Accessed__c, Tablet_Last_Accessed__c,
            FirstName, LastName,PersonMailingCountry , PersonMobilePhone, PersonEmail, PersonHomePhone, PersonMailingState, PersonMailingPostalCode, PersonMailingStreet,
            PersonMailingCity, TMG_Promo_Email__c, TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c, Digital_Product_Type__c, DateOfBirth__c FROM Account WHERE Id = :id];

        if(action == 'UPDATE_SAM'){
            /* UPDATE (AND LINK) SAM ACCOUNT*/
            samUtil.updateSamAccount(subscriber, subscriber.Subscriber_Number_static__c, guid, product, false);
        }else if(action == 'CREATE_SAM'){
            subscriber.Guid__c = samUtil.createSamAccount(subscriber, subscriber.Subscriber_Number_static__c, product, false, true);
        }

        DefaultNewsletterUtility.addDefaultNewsletter(subscriber.Id);
        
        SubscriberPortal.SUB_TRIGGER_FIRED = true;
        update subscriber;

        if(action == 'CREATE_SAM'){
            SubscriptionsWebservicesHandlers.setEntitlements(id);
        }
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 01/03/2016
    Version - 1.0
    Function - display page error message and link to duplicate Account(s)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void displayDuplicateErrorMessage(List<Account> lstAccounts){
        String sError = Label.Offline_Acquisition_Email_duplicate_error + '<br/>' + Label.General_Duplicate_emails_found;
        for(Account acc : lstAccounts){
			sError += '<a href="/'+ acc.Id + '">' + acc.Id + '</a>, ';
        }
        sError = sError.substring(0, sError.length()-2);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sError));
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 15/03/2016
    Version - 1.0
    Function - display add/change email iFrame
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void displayChangeEmailIFrame(){
        this.showEmailIFrame = true;
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 15/03/2016
    Version - 1.0
    Function - hide add/change email iFrame
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void hideChangeEmailIFrame(){
        this.showEmailIFrame = false;
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 15/03/2016
    Version - 1.0
    Function - refetch subscriber email and close add/change email iFrame
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void refetchSubscriberEmail(){
        List<Account> lstAcc = [select PersonEmail from Account where Id = :this.subscriber.Id];
        if(!lstAcc.isEmpty()){
            this.subscriber.PersonEmail = lstAcc[0].PersonEmail;
            this.showEmailIFrame = false;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Account_refetch_error_update));
        }
    }

    /**
    * @author Unknown
    * @date Unknown
    * @description Wrapper class for pricing information at the top of the OapSubscriptionTMG page
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         17/08/2015  //moved external logic into this class contructor as was no point to have extra method
    **/
    public class PaymentValues{
        public Decimal dWeeklyPrice{get;set;}
        public String sType{get;set;}
        public String weeklyPrice {get;set;}
        public String firstMontlyPayment {get;set;}
        public String subsequentMonthlyPayment {get;set;}
        public String quaterlyPayment {get;set;}
        public String creditCard13WkPayment {get;set;}
        public String creditCard26WkPayment {get;set;}
        public String creditCard52WkPayment {get;set;}
        public Integer numberOfPayments{get;set;}

        public PaymentValues(Decimal weeklyPrice, String sType, Integer iWeeksLength){
            if(weeklyPrice == null || weeklyPrice < 0) throw new TelegraphApplicationException('wrong weekly price passed in');
            this.sType = sType;
            this.dWeeklyPrice = weeklyPrice;

            // Monthly Payment
            this.numberOfPayments = 12;
            Integer weeksLength = 52;

            if(iWeeksLength != null){
                weeksLength = iWeeksLength;
                if(Math.mod(weeksLength, Constants.WEEKS_IN_QUARTER) == 0){
                    this.numberOfPayments = weeksLength / Constants.WEEKS_IN_QUARTER * 3;
                }
            }

            Decimal totalAmount = weeklyPrice * weeksLength;
            Decimal subsequentMonthlyPayment = (totalAmount / this.numberOfPayments).setScale(2, System.RoundingMode.DOWN);
            Decimal firstMontlyPayment = subsequentMonthlyPayment + totalAmount - (subsequentMonthlyPayment * this.numberOfPayments);

            // Quarterly Payments
            Decimal quaterlyPayment = (weeklyPrice * Constants.WEEKS_IN_QUARTER).setScale(2, System.RoundingMode.DOWN);

            this.weeklyPrice                = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(weeklyPrice);
            this.firstMontlyPayment         = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(firstMontlyPayment);
            this.subsequentMonthlyPayment   = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(subsequentMonthlyPayment);
            this.quaterlyPayment            = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(quaterlyPayment);
            this.creditCard13WkPayment      = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(weeklyPrice * 13);
            this.creditCard26WkPayment      = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(weeklyPrice * 26);
            this.creditCard52WkPayment      = '£' + UtilitiesForSubscriptions.convertToTwoDecimalPlaces(weeklyPrice * 52);

            if(String.isNotBlank(this.sType) && sType == Label.Offline_Acquisition_Low_Start){
                this.creditCard26WkPayment = Label.Not_Applicable;
                this.creditCard52WkPayment = Label.Not_Applicable;
            }
        }
    }

    /**
    * @author Wiktor Czykin
    * @date 17-18/08/2015
    * @description Wrapper class for subscription types and respective payment types and frequency
    #############Change Log#############
    Modified by     Version     Change Date
    **/
    public class PaymentConfig{
        public String sConfigName{get;set;}
        public Decimal dWeeklyPrice{get;set;}
        public Decimal dWeeklyLowStartPrice{get;set;}
        public Decimal dPrice{get;set;}
        public List<SelectOption> lstFrequency{get;set;}
        public String sDefaultFrequency{get;set;}
        public String sDefaultPaymentOption{get;set;}
        public List<SelectOption> lstPaymentOptions{get;set;}
        public Integer iDuration{get;set;}//in weeks
        public Integer iLowStartDuration{get;set;}

        /***************************************************************************************
        Developer - Wiktor Czykin
        Date - 18/08/2015
        Version - 1.1
        Function - constructor
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public PaymentConfig(String sConfigName, Integer iDuration){
            this.lstPaymentOptions = new List<SelectOption>();
            this.iDuration = iDuration;
            this.sConfigName = sConfigName;
            this.sDefaultPaymentOption = CC;
        }

        /***************************************************************************************
        Developer - Wiktor Czykin
        Date - 18/08/2015
        Version - 1.1
        Function - populates the frequency options list
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public void populateFrequency(Boolean bIsCCA){
            this.lstFrequency = new List<SelectOption>();
            this.lstFrequency.add(new SelectOption(Constants.DD_COL_FREQ_MONTHLY, Constants.DD_COL_FREQ_MONTHLY));
            if(!bIsCCA){
                this.lstFrequency.add(new SelectOption(Constants.DD_COL_FREQ_QUARTERLY, Constants.DD_COL_FREQ_QUARTERLY));
                this.sDefaultFrequency = Constants.DD_COL_FREQ_QUARTERLY;
            }else{
                this.sDefaultFrequency = Constants.DD_COL_FREQ_MONTHLY;
            }
        }

        /***************************************************************************************
        Developer - Wiktor Czykin
        Date - 18/08/2015
        Version - 1.1
        Function -  Returns select option based on PaymentConfig setup, using proper labels
        #############Change Log#############
        Modified by     Version     Change Date
        ****************************************************************************************/
        public SelectOption getSubscriptionTypeOption(){
            String sLabel ='';
            List<String> lstParams = new List<String>{this.iDuration+''};

            if(this.dPrice != null){
                sLabel = Label.Offline_Acquisition_One_off_subscription_type_description;
                lstParams.add(this.dPrice.setScale(2)+'');
            }else if(dWeeklyLowStartPrice != null){
                sLabel = Label.Offline_Acquisition_Continuous_subscription_type_low_start_description;
                lstParams.add(this.dWeeklyLowStartPrice.setScale(2)+'');
                lstParams.add(this.dWeeklyPrice.setScale(2)+'');
            }else if(this.dWeeklyPrice != null){
                sLabel = Label.Offline_Acquisition_Continuous_subscription_type_description;
                lstParams.add(this.dWeeklyPrice.setScale(2)+'');
            }
            if(String.isBlank(sLabel) || lstParams.isEmpty()) throw new TelegraphApplicationException('Error in subscription type option preparation.');
            return new SelectOption(this.sConfigName, String.format(sLabel, lstParams));
        }
    }

    public class POCException extends Exception{}
    public class SubscriptionUpsertException extends Exception{}
    public class EmailMissingException extends Exception{}
    public class ChequeException extends Exception{}
}