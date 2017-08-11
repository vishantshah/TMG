/* -----------------------------------------------------------------------------------------------------------------------
   Name:    TestDataUtility.cls
   Description: Utility class for creating test data
   Date         Author              Summary of Changes
   -----------  ------- -----------------   ------------------------------------------------------------------------------
   30/08/2016   Mantas Grigaliunas   Amended createOutboundCallSalesStageMappingSettings and defineOutboundCallStageMappingSettings methods
   09/09/2016	Mantas Grigaliunas   Added methods to create test EmailMessage records
   19/09/2016	Mantas Grigaliunas   Added createSocialRegistrationEndPointSettings() method
   29/09/2016	Mantas Grigaliunas   Added createNewslettersEndPointSettings() method
   07/10/2016   Mantas Grigaliunas   Added newNewsletterConfiguration() and createNewsletterConfigurations() methods
   11/10/2016   Wiktor Czykin        Modified Price Plan related methods
   17/10/2016   Michal Szewczyk      Amended checkVoucherAdjustmentDependencies()
   20/12/2016   Mantas Grigaliunas   Modified newVoucherAdjustment()
   09/01/2017   Vishant Shah         added LeadDays__c .. value synced from zuora so has to be in text format
   09/12/2016   Mantas Grigaliunas   Added updateThresholdValue()
   08/03/2017   Wiktor Czykin        Modified newTCodeProduct()
   20/03/2017   Wiktor Czykin        Email uniqueness imposed changes (removal of old OC with it)
   15/03/2017   Wiktor Czykin        Added Offer__c support
   30/03/2017   Vishant Shah         Added createMarketingPrefSettings()
   22/05/2017   Wiktor Czykin        Added zqu__ProductRatePlan__c set of methods and other related to zuora schema
   15/06/2017   Wiktor Czykin        Removed TCodeIncentive__c related methods as object is no longer used anywhere
   03/07/2017   Wiktor Czykin        Added Home_Delivery_Voucher__c and Home_Delivery_Settings__c
   06/07/2017   Wiktor Czykin        Modified newOffer()
   10/07/2017   Wiktor Czykin        Modified Home_Delivery_Voucher__c dependencies
------------------------------------------------------------------------------------------------------------------------ */
@isTest
public class TestDataUtility {
  public static Integer iAccountEmailDifferentiator = 0;

  public static final Date dateToday = Date.today();

  public static final String PAYMENTMETHOD_CC = 'CC';
  public static final String PAYMENTMETHOD_DD = 'DD';

  public static Map<String, Id> mapProfileNameToId;

  public Boolean bLoadCustomSettingsDependencies = true;
  public List<General__c> lstGeneral{get;set;}
  public List<User> lstUsers{get;set;}
  public List<Account> lstIndividualSubscribers{get;set;}
  public List<Account> lstDigitalSubscribers{get;set;}
  public List<Account> lstRetailers{get;set;}
  public List<Account> lstAccounts{get;set;}
  public List<Case> lstCases{get;set;}
  public List<CaseComment> lstCaseComments {get;set;}
  public List<Subscription__c> lstSubscriptions{get;set;}
  public List<Task> lstSubscriptionTasks{get;set;}
  public List<TCodeManagement__c> lstTCodeManagement{get;set;}
  public Map<Id, List<POC__c>> mapTCodeManagementToPOCs{get;set;}
  public List<Product2> lstProducts{get;set;}
  public List<Pricebook2> lstPriceBooks{get;set;}
  public List<PricebookEntry> lstPriceBookEntries{get;set;}
  public List<PricebookEntry> lstStandardPriceBookEntries{get;set;}
  public List<Voucher_Adjustment__c> lstVoucherAdjustment{get;set;}
  public List<Cheque_Batch__c> lstChequeBatches{get;set;}
  public List<Cheque__c> lstCheques{get;set;}
  public List<MPP_Transaction_History__c> lstMPPTransactionHistory{get;set;}
  public Map<Integer, List<Pricing_Options__c>> mapPricingOptions{get;set;}
  public List<Upgrade_Option__c> lstUpgradeOptions{get;set;}
  public List<Upgrade_History_Item__c> lstUpgradeHistoryItems {get;set;}
  public List<FulfillmentPlan__c> lstFulfillmentPlan{get;set;}
  public List<EmailMessage> lstEmailMessage {get;set;}
  public List<Newsletter_Configuration__c> lstNewsletterConfiguration {get;set;}
  public List<Zuora__Product__c> lstZuoraProducts {get;set;}

  public List<PlaneURL__c> lstPlaneURL{get;set;}
  public List<subscriberValidationRuleInfov2__c> lstSubscriberValidationRuleInfo{get;set;}
  public List<SubscriberConsoleSettings__c> lstSubscriberConsoleSettings{get;set;}
  public List<SAM_Entitlement__c> lstSAMEntitlements{get;set;}
  public List<SAMHTTPSettings__c> lstSAMHTTPSettings{get;set;}
  public List<Entitlements__c> lstEntitlementsSettings{get;set;}
  public List<Entitlements__c> lstEntitlementsmMapping{get;set;}
  public List<Incentive__c> lstIncentives{get;set;}
  public List<SubscriptionIncentiveAssociation__c> lstIncentivesAssociation{get;set;}
  public List<Country_Codes__c> lstCountryCodes{get;set;}
  public List<VAT__c> lstVAT{get;set;}
  public List<Cancellation__c> lstCancellations{get;set;}
  public List<TCodeIncentive__c> lstTCodeIncentives{get;set;}
  public List<zqu__ZProductFeature__c> lstZProductFeature{get;set;}
  public List<zqu__ZFeature__c> lstZFeature{get;set;}
  public List<TCode_Product__c> lstTCodeProducts{get;set;}
  public List<TCode_Product__c> lstTCodeProductOffers{get;set;}
  public List<Plan__c> lstPlans{get;set;}
  public List<Price_Plan__c> lstPricePlans{get;set;}
  public List<POC__c> lstPOCs{get;set;}

  public List<Account> lstRegistrants{get;set;}
  public List<zqu__Quote__c> lstZQuotes{get;set;}
  public List<Zuora__PaymentMethod__c> lstZuoraPaymentMethods{get;set;}
  public List<Zuora__CustomerAccount__c> lstBillingAccount{get;set;}
  public List<Zuora__Subscription__c> lstZuoraSubscriptions{get;set;}
  public List<Zuora__SubscriptionProductCharge__c> lstZuoraSubscriptionProductCharges{get;set;}
  public List<zqu__ProductRatePlan__c> lstProductRatePlans{get;set;}
  public List<zqu__ProductRatePlanCharge__c> lstProductRatePlanCharges{get;set;}
  public List<zqu__QuoteRatePlanCharge__c> lstQuoteRatePlanCharges{get;set;}
  public List<zqu__QuoteCharge__c> lstQuoteCharges{get;set;}
  public List<Zuora__Payment__c> lstZuoraPayments{get;set;}
  public List<zqu__QuoteAmendment__c> lstQuoteAmendments{get;set;}
  public List<zqu__QuoteRatePlan__c> lstQuoteRatePlans{get;set;}
  public List<zqu__ZProduct__c> lstZproducts{get;set;}
  public List<TCode_Product_Incentive__c> lstTCodeProductIncentives{get;set;}
  public List<Product_Price__c> lstProductPrice {get; set;}

  public List<Outbound_Call_Batch_Setting__c> lstOutboundCallBatchSetting{get;set;}
  public List<Outbound_Call_Setting__c> lstOutboundCallSetting{get;set;}
  public List<Outbound_Call_Rule__c> lstOutboundCallRule {get;set;}
  public List<Offer__c> lstOffers {get;set;}
  public List<Home_Delivery_Voucher__c> lstHomeDeliveryVouchers{get;set;}
  public List<Home_Delivery_Settings__c> lstHomeDeliverySettings{get;set;}

  public List<Subscription_Plan_Upload__c> subscriptionPlanUploads {get; set;}
  public Map<Id,List<Price_Plan_Offer__c>> mapPricePlanOffer {get; set;}
  public Map<Id,List<Price_Plan_Offer__c>> mapPricePlanDefaultOffer {get; set;}
  public static final Set<Decimal> TEST_PRODUCT_PRICES = new Set<Decimal>{
    8, 9, 20, 219.11, 250, 259.11, 299.11
  };

  public Integer iCounter{get;set;}
  public Integer iProductRatePlanFrequencyMultiplier;

  public TestDataUtility(){
    this.iCounter = 200;
  }

    public TestDataUtility(Integer i){
        this.iCounter = i;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 20/03/2017
    Version - 1.0
    Function - increase unique identifier by one every time called
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static void increaseUniquenessDifferentiator(){
      TestDataUtility.iAccountEmailDifferentiator ++;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 12/10/2014
    Version - 1.0
    Function - General function that retrieves profile Id for specified string
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public Id getProfileIdForName(String sProfileName){
        if(TestDataUtility.mapProfileNameToId == null){
            Map<String, Id> mapBuffer = new Map<String, Id>();
            for(Profile p : [select Id, Name from Profile]){
                mapBuffer.put(p.Name, p.Id);
            }
            if(mapBuffer.isEmpty()){
                throw new TelegraphApplicationException('Problems in identifying profiles.');
            }
            TestDataUtility.mapProfileNameToId = mapBuffer;
        }
        if(!String.isBlank(sProfileName) && TestDataUtility.mapProfileNameToId.containsKey(sProfileName) && TestDataUtility.mapProfileNameToId.get(sProfileName) != null){
            return TestDataUtility.mapProfileNameToId.get(sProfileName);
        }else{
            throw new TelegraphApplicationException('Trying to fetch profile that does not exist.');
        }
        return null;
    }

  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 10/02/2015
  Version - 1.0
  Function - loads custom settings for General__c from csv file
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public List<General__c> loadGeneral(){
    if(this.lstGeneral == null){
      this.lstGeneral = Test.loadData(General__c.sObjectType, 'GeneralTestData');
    }
    return this.lstGeneral;
  }
  
    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 28/11/2016
    Version - 1.0
    Function - sets Application Configurations custom setting
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public void setApplicationConfigurations(){
        insert new Configuration__c(Core_Api_App_Id__c='app_id', Core_Api_App_Id_Value__c='00000001', Core_Api_App_Key__c='app_key', Core_Api_App_Key_Value__c='00000000000000000000000000000001',
            Visualforce_Base_Url__c='https://c.cs86.visual.force.com/apex/');
    }
  
  /***************************************************************************************
  Developer - Michal Szeczyk
  Date - 04/04/2016
  Version - 1.1
  Function - set custom settings
  #############Change Log#############
  Modified by    Version   Change Date
    Wiktor Czykin  1.1       27/05/2016 //modified the setting name to constant
  ****************************************************************************************/
  public void setDefautProdCustomSetting(){
     if(lstZproducts == null) {
      createZProduct();
     }
    General__c applicationSettingObj = new General__c(Name=Constants.GENERAL_DEFAULT_PRODUCT_ID, Value__c=lstZproducts[0].Id);
    insert applicationSettingObj;
    General__c applicationSettingObj1 = new General__c(Name=Constants.DIGITAL_DEFAULT_PRODUCT_ID, Value__c=lstZproducts[0].Id);
    insert applicationSettingObj1;
    General__c applicationSettingObj2 = new General__c(Name=Constants.WEBPACK_DEFAULT_PRODUCT_ID, Value__c=lstZproducts[0].Id);
    insert applicationSettingObj2;
  }

  /***************************************************************************************
  Developer - Michal Szeczyk
  Date - 20/04/2016
  Version - 1.0
  Function - set custom settings for entitlement mapping
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void setEntitlemetMapping(){
    List<Entitlements_Mapping__c> allSettings = new List<Entitlements_Mapping__c>();
    if(lstZproducts == null) {
      createZProductFeatures();
    }
    Entitlements_Mapping__c entMapping = new Entitlements_Mapping__c(Name='ZProductFeature1',Old_Name__c=Constants.SPRODUCT_7DAY,Is_print__c = true);
    Entitlements_Mapping__c entMapping1 = new Entitlements_Mapping__c(Name='ZProductFeature2',Old_Name__c=Constants.DIGITAL_PRODUCT_ALLDEVICES,Is_print__c = true);
    allSettings.add(entMapping);
    allSettings.add(entMapping1);
    insert allSettings;
  }

    /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/05/2016
  Version - 1.0
  Function - create the custom setting that enables the product price validation
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static void enableProductPriceValidationSetting(){
    insert new General__c( Name = Constants.ENABLE_PRODUCT_PRICE_VALIDATION, Value_Boolean__c = true);
  }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 01/04/2015
    Version - 1.0
    Function - insert PlaneURL__c custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<PlaneURL__c> loadPlaneURL(){
        if(this.lstPlaneURL == null){
            this.lstPlaneURL = Test.loadData(PlaneURL__c.sObjectType, 'PlaneURLTestData');
        }
        return this.lstPlaneURL;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 14/05/2015
    Version - 1.0
    Function - insert subscriberValidationRuleInfov2__c custom settings based on test data file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<subscriberValidationRuleInfov2__c> loadSubscriberValidationRuleInfo(){
        if(this.lstSubscriberValidationRuleInfo == null){
            this.lstSubscriberValidationRuleInfo = Test.loadData(subscriberValidationRuleInfov2__c.sObjectType, 'SubscriberValidationRuleInfoV2TestData');
        }
        return this.lstSubscriberValidationRuleInfo;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 15/05/2015
    Version - 1.0
    Function - insert SubscriberConsoleSettings__c custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<SubscriberConsoleSettings__c> loadSubscriberConsoleSettings(String sUserName){
        if(String.isBlank(sUserName)) sUserName = UserInfo.getName();
            this.lstSubscriberConsoleSettings = new List<SubscriberConsoleSettings__c>{
                new SubscriberConsoleSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), Guid_Task_Recipient__c = sUserName)
            };
            insert lstSubscriberConsoleSettings;
        return lstSubscriberConsoleSettings;

    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 15/05/2015
    Version - 1.0
    Function - insert SAM_Entitlements__cs custom settings based on test data file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<SAM_Entitlement__c> loadSAMEntitlements(){
        if(this.lstSAMEntitlements == null){
            this.lstSAMEntitlements = Test.loadData(SAM_Entitlement__c.sObjectType, 'SAMEntitlementsTestData');
        }
        return this.lstSAMEntitlements;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 15/05/2015
    Version - 1.0
    Function - insert SAMHTTPSettings__c custom settings based on test data file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<SAMHTTPSettings__c> loadSAMHTTPSettings(){
        if(this.lstSAMHTTPSettings == null){
            this.lstSAMHTTPSettings = Test.loadData(SAMHTTPSettings__c.sObjectType, 'SAMHTTPSettingsTestData');
        }
        return this.lstSAMHTTPSettings;
    }

    /***************************************************************************************
    Developer - Cristina Popescu (Tquila)
    Date - 11/06/2015
    Version - 1.0
    Function - insert Entitlements__c custom settings based on testdata file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<Entitlements__c> loadEntitlementsSettings(){
        if(this.lstEntitlementsSettings == null){
            this.lstEntitlementsSettings = Test.loadData(Entitlements__c.sObjectType, 'EntitlementsSettingsTestData');
        }
        return this.lstEntitlementsSettings;
    }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 21/01/2016
    Version - 1.0
    Function - insert  Entitlements_Mapping__c custom settings based on testdata file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<Entitlements__c> loadEntitlementsMappingSettings(){
        if(this.lstEntitlementsmMapping == null){
            this.lstEntitlementsmMapping = Test.loadData(Entitlements_Mapping__c.sObjectType, 'EntitlementsMappingTestData');
        }
        return this.lstEntitlementsmMapping;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 07/08/2015
    Version - 1.0
    Function - loads custom settings for Country_Codes__c from csv file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<Country_Codes__c> loadCountryCodes(){
        if(this.lstCountryCodes == null){
            this.lstCountryCodes = Test.loadData(Country_Codes__c.sObjectType, 'CountryCodesTestData');
        }
        return this.lstCountryCodes;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 07/08/2015
    Version - 1.0
    Function - loads custom settings for Country_Codes__c from csv file
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public List<VAT__c> loadVAT(){
        if(this.lstVAT == null){
            this.lstVAT = Test.loadData(VAT__c.sObjectType, 'VATTestData');
        }
        return this.lstVAT;
    }

    /***************************************************************************************
    // ZProducts and ZFeatures

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 20/01/2016
  Function - Returns object instance for Zproduct
  #############Change Log#############
  Modified by   Change Date
  Wiktor Czykin 24/05/2016  //added print product flag
  Vishant Shah  09/01/2017  //added LeadDays__c .. value synced from zuora so has to be in text format
  Wiktor Czykin 25/05/2017  //added zqu__Allow_Feature_Changes__c to match what was in Sally's method I want to replace at some point 
  Wiktor Czykin 30/05/2017  //added max cover prices
  ****************************************************************************************/
  public static zqu__ZProduct__c newZProduct(Integer i, Boolean bPrintProduct){
    zqu__ZProduct__c product = new zqu__ZProduct__c(
      Name = 'ZProduct'+i,
      zqu__SKU__c ='SKU-' + i,
      zqu__ZuoraId__c = 'ZuoraId' + i,
      zqu__EffectiveStartDate__c = System.today(),
      zqu__EffectiveEndDate__c = System.today().addDays(60),
      zqu__Active__c = true,
      zqu__Allow_Feature_Changes__c = true,
      LeadDays__c = '9',
      RefundsAllowed__c = 'Yes',
      MaxCoverPriceAnnual__c = 100+'',
      MaxCoverPriceMonth__c = 10+'',
      MaxCoverPriceDay__c = 1+''
    );
    if(bPrintProduct == null || bPrintProduct){
      product.Print_Product__c = true;
    }
    return product;
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 20/01/2016
  Version - 1.0
  Function - Returns object instance for ZFeature
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static zqu__ZFeature__c newZFeature(Integer i){
    return new zqu__ZFeature__c(
      Name = 'ZFeature'+i,
      zqu__FeatureName__c ='FeatureName' + i,
      zqu__ZuoraId__c = 'ZuoraId' + i,
      zqu__Code__c = 'TESTCODE' + i,
      Entitlement__c = 'ZFeature'+i
    );
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 20/01/2016
  Version - 1.0
  Function - Returns object instance for ZFeature with custom name
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static zqu__ZFeature__c newZFeatureByName(String fname,Integer i){
    return new zqu__ZFeature__c(
      Name = fname,
      zqu__FeatureName__c ='fname' + i,
      zqu__ZuoraId__c = 'ZuoraId' + i,
      zqu__Code__c = 'TESTCODE' + i,
      Entitlement__c = fname
    );
  }

    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 20/01/2016
    Version - 1.0
    Function - Returns object instance for ZProductFeature
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static zqu__ZProductFeature__c newZProductFeature(Id featureId , Id productId,Integer i){
        return new zqu__ZProductFeature__c(
      Name = 'ZProductFeature'+i,
            zqu__ZFeature__c = featureId,
            zqu__ZProduct__c = productId,
            zqu__ZuoraId__c = 'ZuoraId' + i

        );
    }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 20/01/2016
  Version - 1.0
  Function - Creates ZFeature list
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createZFeatures(){
    if(this.lstZFeature == null){
      this.lstZFeature = new List<zqu__ZFeature__c>();

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstZFeature.add(TestDataUtility.newZFeature(i));
      }
      insert this.lstZFeature;
    }
  }
  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 20/01/2016
  Version - 1.0
  Function - Creates ZProduct list
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createZProduct(){
    if(this.lstZproducts == null){
      this.lstZproducts = new List<zqu__ZProduct__c>();

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstZproducts.add(TestDataUtility.newZProduct(i, null));
      }
      insert this.lstZproducts;
    }
  }
  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 20/01/2016
  Version - 1.0
  Function - Creates ZProductFeature list
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createZProductFeatures(){
    if(lstZproducts == null) {
      this.createZProduct();
    }
    if(lstZFeature == null) {
      this.createZFeatures();
    }
    if(this.lstZProductFeature == null){
      this.lstZProductFeature = new List<zqu__ZProductFeature__c>();

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstZProductFeature.add(TestDataUtility.newZProductFeature(lstZFeature[i].Id,lstZproducts[i].Id,i));
      }
      insert this.lstZProductFeature ;
    }
  }


    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 07/05/2015
    Version - 1.0
    Function - Create the custom setting for the reset Password EndPoint
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateCoreApiResetPasswordEndPointSetting(){
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CORE_API_RESET_PASSWORD_END_POINT_NAME,Value__c='Testing');
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 03/09/2015
    Version - 1.0
    Function - Create the custom setting for the CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateGracePeriodValueSetting(){
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME,Value__c='14');
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 12/10/2015
    Version - 1.0
    Function - Create the custom setting for the CallCoreApiForAccountCreation
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         19/02/2016 - added paramter to the method
    Michal Kwika    1.2         22/02/2016 - added functionality for SeeAllData Methods
    ****************************************************************************************/
    public void createFireAccountCreationCustomSetting(Boolean callCoreApi){
        Application_Settings__c applicationSettingObj = Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION);
        if(applicationSettingObj==null){
            applicationSettingObj=new Application_Settings__c(name=Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION,Value__c=String.valueOf(callCoreApi));
            insert applicationSettingObj;
        }
        else {
            applicationSettingObj.Value__c = String.valueOf(callCoreApi);
            update applicationSettingObj;
        }
    }

    public void CreateCountryCodeCustomSetting(){
        if(Country_Codes__c.getInstance('GB')==null){
            Country_Codes__c gbCountryCode=new Country_Codes__c(name='GB',Country_Name__c='United Kingdom',EU__c=true);
            insert gbCountryCode;
        }
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 17/12/2015
    Version - 1.0
    Function - Create the custom setting for the Outbound Product Mapping
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createProductMappingCustomSetting(string productName,string SFProductID){
        if(Outbound_Product_Mapping__c.getInstance(productName)==null){
            Outbound_Product_Mapping__c outboundProductMappingObj=new Outbound_Product_Mapping__c(name=productName,SF_Product_ID__c=SFProductID);
            insert outboundProductMappingObj;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/04/2017
    Version - 1.0
    Function - Create offers callout trigger flag
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public Application_Settings__c createFireOfferApiSync(){
      Application_Settings__c aSetting = Application_Settings__c.getInstance(Constants.FIRE_CORE_API_OFFERS_CALLOUT);
      if(aSetting == null){
        aSetting = new Application_Settings__c(Name = Constants.FIRE_CORE_API_OFFERS_CALLOUT, Value__c = ''+true);
        insert aSetting;
      }
      return aSetting;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 09/12/2015
    Version - 1.0
    Function - Create the custom setting for the DefaultOfferCodeIds
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateDefaultOfferCodeIdsCustomSetting(){
        if(Application_Settings__c.getInstance(Constants.DEFAULT_OFFER_CODE_TMG_IDS)==null){
            Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.DEFAULT_OFFER_CODE_TMG_IDS,Value__c='Code1,Code2');
            insert applicationSettingObj;
        }
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 15/09/2015
    Version - 1.0
    Function - Create the custom setting for the CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME
                With correct
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateGracePeriodValueSetting(Integer days){
        String numberOfDays = String.valueOf(days);
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CANCELLATION_GRACE_PERIOD_CUSTOM_SETTING_NAME,Value__c=numberOfDays);
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 26/05/2015
    Version - 1.0
    Function - Create the custom setting for the getOfferCode EndPoint
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateCoreApiOfferCodeEndPointSetting(){
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CORE_API_GET_OFFER_DETAILS,Value__c='Testing');
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 13/11/2015
    Version - 1.0
    Function - Create the custom setting for the Get All Offer Code EndPoint
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateCoreApiAllOfferCodesEndPointSetting(){
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CORE_API_GET_ALL_OFFERS,Value__c='Testing');
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 26/01/2016
    Version - 1.0
    Function - Create the custom setting for the Tcode Offer code fields
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateTcodeOffersFieldsSetting(){
        Application_Settings__c applicationSettingObjUK=new Application_Settings__c(name=Constants.TCODE_OFFER_FIELDS_UK_PRODUCTS,Value__c='Tablet_UK_Annual_Offer_Code__c,Tablet_UK_Monthly_Offer_Code__c,Website_UK_Annual_Offer_Code__c,Website_UK_Monthly_Offer_Code__c');
        Application_Settings__c applicationSettingObjInt=new Application_Settings__c(name=Constants.TCODE_OFFER_FIELDS_INTERNATIONAL_PRODUCTS,Value__c='Tablet_International_Annual_Offer_Code__c,Tablet_International_Monthly_Offer_Code__c,Website_International_Annual_Offer_Code__c,Website_International_Monthly_Offer_Code__c');
        insert new List<Application_Settings__c>{applicationSettingObjUK, applicationSettingObjInt};
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        05/08/2015
    Function    this function creates Custom setting for the email searching in SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void CreateCoreApiSamUserSearchByEmailSetting(){
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CORE_API_SAM_USER_SEARCH_BY_EMAIL,Value__c='Testing');
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.1
    Function - Creates Person accounts list - Registrants
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/02/2016  //modified so that it does not retry to insert data
    ****************************************************************************************/
    public void CreateCoreApiEventEndPointSetting(){
        Application_Settings__c applicationSettingObj = Application_Settings__c.getInstance(Constants.CORE_API_EVENT_END_POINT_NAME);
        if(applicationSettingObj != null) return;
        insert new Application_Settings__c(Name = Constants.CORE_API_EVENT_END_POINT_NAME, Value__c = 'Testing');
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 19/05/2016
    Version - 1.0
    Function - Create Custom Settings for Core API EndPoints
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void CreateCoreApiEndPointSettings(){
        Application_Settings__c appSetting;
        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_EVENT_END_POINT_NAME);
        if(appSetting == null) insert new Application_Settings__c(Name = Constants.CORE_API_EVENT_END_POINT_NAME, Value__c = 'Testing');

        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_UPGRADE_END_POINT_NAME);
        if(appSetting == null) insert new Application_Settings__c(Name = Constants.CORE_API_UPGRADE_END_POINT_NAME, Value__c = 'Testing');

        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_PUT_OFFER_END_POINT_NAME);
        if(appSetting == null) insert new Application_Settings__c(Name = Constants.CORE_API_PUT_OFFER_END_POINT_NAME, Value__c = 'Testing');

        appSetting = Application_Settings__c.getInstance(Constants.CORE_API_GET_OFFERS_BY_PRODUCT_AND_FREQUENCY);
        if(appSetting == null) insert new Application_Settings__c(Name = Constants.CORE_API_GET_OFFERS_BY_PRODUCT_AND_FREQUENCY, Value__c = 'Testing');
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 19/09/2016
    Version - 1.0
    Function - Create Custom Settings for Social Connection EndPoints
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createSocialRegistrationEndPointSettings(){
        Application_Settings__c appSetting;
        appSetting = Application_Settings__c.getInstance(Constants.SOCIAL_REGISTRATION_GET_END_POINT);
        if(appSetting == null) 
            insert new Application_Settings__c(Name = Constants.SOCIAL_REGISTRATION_GET_END_POINT, Value__c = 'Testing');

        appSetting = Application_Settings__c.getInstance(Constants.SOCIAL_REGISTRATION_DELETE_END_POINT);
        if(appSetting == null) 
            insert new Application_Settings__c(Name = Constants.SOCIAL_REGISTRATION_DELETE_END_POINT, Value__c = 'Testing');
    }

    /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 28/09/2016
  Version - 1.0
  Function - Create Custom Settings for Newsletters EndPoints
  #############Change Log#############
  Modified by     Version     Change Date
  ****************************************************************************************/
  public void createNewslettersEndPointSettings(){
    Application_Settings__c appSetting;
    appSetting = Application_Settings__c.getInstance(Constants.NEWSLETTERS_GET_END_POINT);
    if(appSetting == null) 
      insert new Application_Settings__c(Name = Constants.NEWSLETTERS_GET_END_POINT, Value__c = 'Testing');

    appSetting = Application_Settings__c.getInstance(Constants.NEWSLETTERS_POST_END_POINT);
    if(appSetting == null) 
      insert new Application_Settings__c(Name = Constants.NEWSLETTERS_POST_END_POINT, Value__c = 'Testing');

    appSetting = Application_Settings__c.getInstance(Constants.NEWSLETTERS_POST_END_POINT);
    if(appSetting == null) 
      insert new Application_Settings__c(Name = Constants.NEWSLETTERS_POST_END_POINT, Value__c = 'Testing');
  }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 24/06/2016
  Version - 1.0
  Function - Since Zuora requires SeeAll data to be set to true for the test data creation this method is used to
         remove all Application_Settings custom setting records to avoid conflict with existing data while creating test data
  ######## #####Change Log#############
  Modified by   Version   Change Date
  ****************************************************************************************/
  public void deleteApplicationSettings(){
    delete Application_Settings__c.getAll().values();
  }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 30/06/2016
  Version - 1.0
  Function - Since Zuora requires SeeAll data to be set to true for the test data creation this method is used to
         remove all General custom setting records to avoid conflict with existing data while creating test data
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void deleteGeneralSettings(){
    delete General__c.getAll().values();
  }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 30/06/2016
  Version - 1.0
  Function - Since Zuora requires SeeAll data to be set to true for the test data creation this method is used to
         remove all PlaneURL custom setting records to avoid conflict with existing data while creating test data
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void deletePlaneURLSettings(){
    delete PlaneURL__c.getAll().values();
  }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 30/06/2016
  Version - 1.0
  Function - Since Zuora requires SeeAll data to be set to true for the test data creation this method is used to
         remove all Sam HTTP Settings custom setting records to avoid conflict with existing data while creating test data
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void deleteSAMHTTPSettings(){
    delete SAMHTTPSettings__c.getAll().values();
  }

    //USERS
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 12/10/2014
    Version - 1.0
    Function - Returns object instance user (as parameter you can specify profile Id)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static User newUser(Integer i, Id profileId){
        return new User(
            FirstName='Test'+i + System.now().format(),
            Country='United Kingdom',
            Alias = 's'+i,
            Email='tmgUser'+i + System.now().format().replaceAll('[/: ]', '') + '@tmgtestorg.com',
            Emailencodingkey='UTF-8',
            Lastname='Test'+i + System.now().format(),
            Languagelocalekey='en_US',
            LocalesIdKey='en_US',
            ProfileId = profileId,
            TimezonesIdKey='Europe/London',
            Username='tmguserx#_' + i + System.now().format().replaceAll('[/: ]', '') + '_#@telegraph.co.uk'
        );
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 08/08/2016
    Version - 1.0
    Function - Method to create OCCaseAutoclose__c hierarchical custom setting instance
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void createOCCaseAutocloseCustomSettingInstance(){
      insert new OCCaseAutoclose__c();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 12/10/2014
    Version - 1.0
    Function - Initializes users list
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createUsers(String sProfileName){
        if(this.lstUsers == null){
            this.lstUsers = new List<User>();
            Id idSelectedProfile = null;
            if(sProfileName != null){
                idSelectedProfile = this.getProfileIdForName(sProfileName);
            }else{
                idSelectedProfile = this.getProfileIdForName(Constants.PROFILE_SYSTEMADMINISTRATOR);
            }
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstUsers.add(TestDataUtility.newUser(i, idSelectedProfile));
            }
            insert this.lstUsers;
        }
    }

    //ACCOUNTS
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 16/02/2015
    Version - 1.2
    Function - Returns object instance for person Account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/2016     //moved here values from Replatforming project, lowercased the email
    Wiktor Czykin   1.2         20/03/2017  //added use of additional account uniqueness factor
    ****************************************************************************************/
    public static Account newPersonAccount(Integer i, Id recordTypeId){
        return new Account(
            Salutation='Mr.',
            PersonEmail='testemai_'+iAccountEmailDifferentiator+'_'+i+'@test.com',
            FirstName = 'person'+i,
            LastName = 'surnametestxxxtmg',
            RecordTypeId = recordTypeId,
            Price_Plan__c='B',
            Phone = '1234567'+i,
            PersonMailingPostalCode = 'EH1 1JG',
            PersonMailingCity='TestCity',
            PersonMailingCountry='GB',
            PersonMailingStreet='test Street1',
            TMG_Loyalty_Email__c = 0
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 16/02/2015
    Version - 1.0
    Function - Returns object instance for company Account
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         15/02/2016 - added Salutation
    ****************************************************************************************/
    public static Account newAccount(Integer i, Id recordTypeId){
        return new Account(
            Title__c='Mr.',
            Name = 'company x '+i,
            Price_Plan__c='B',
            RecordTypeId = recordTypeId,
            URN__c = '1111'+i
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 06/11/2015
    Version - 1.0
    Function - loads required settings for successful account insert
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkAccountDependencies(){
        if(bLoadCustomSettingsDependencies){
            this.loadSAMHTTPSettings();
            this.loadGeneral();
            this.loadPlaneURL();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 16/02/2015
    Version - 1.1
    Function - Creates Person accounts list - individual subscribers
    #############Change Log#############
    Modified by       Change Date
    Wiktor Czykin     20/03/2017  //added value increase for additional account  uniqueness factor
    ****************************************************************************************/
    public void createIndividualSubscribers(){
        if(this.lstIndividualSubscribers == null){
            this.checkAccountDependencies();
            this.lstIndividualSubscribers = new List<Account>();
            Id idSelectedRecordType = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB , Account.class.getName());

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstIndividualSubscribers.add(TestDataUtility.newPersonAccount(i, idSelectedRecordType));
            }
            insert this.lstIndividualSubscribers;
            TestDataUtility.increaseUniquenessDifferentiator();
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 26/08/2015
    Version - 1.1
    Function - Creates Person accounts list - digital subscribers
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   20/03/2017 //added additional uniqueness identifier increase method 
    ****************************************************************************************/
    public void createDigitalSubscribers(){
        if(this.lstDigitalSubscribers == null){
            this.checkAccountDependencies();
            this.lstDigitalSubscribers = new List<Account>();
            Id idSelectedRecordType = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB , Account.class.getName());

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstDigitalSubscribers.add(TestDataUtility.newPersonAccount(i, idSelectedRecordType));
            }
            insert this.lstDigitalSubscribers;
            TestDataUtility.increaseUniquenessDifferentiator();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - Creates business accounts list - individual subscribers
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createRetailers(){
        if(this.lstRetailers == null){
            this.lstRetailers = new List<Account>();
            Id idSelectedRecordType = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_ACCOUNT_RETAILER , Account.class.getName());
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstRetailers.add(TestDataUtility.newAccount(i, idSelectedRecordType));
            }
            insert this.lstRetailers;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2016
    Version - 1.2
    Function - loads required settings for successful registrant account insert
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         19/02/2016 - changes to createFireAccountCreationCustomSetting()
    Wiktor Czykin   1.2         22/02/2016 - added call to CreateCoreApiEventEndPointSetting()
    ****************************************************************************************/
    public void checkRegistrantAccountDependencies(){
        if(bLoadCustomSettingsDependencies){
            this.CreateCoreApiEndPointSettings();
            this.createFireAccountCreationCustomSetting(false);
            this.CreateCountryCodeCustomSetting();
        }
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.2
    Function - Creates Person accounts list - Registrants
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         15/02/2016  //simplified
    Wiktor Czykin   1.2         20/03/2017  //added additional uniqueness identifier increase method 
    ****************************************************************************************/
    public void createRegistrants(){
        if(this.lstRegistrants == null){
            this.lstRegistrants = new List<Account>();
            this.checkRegistrantAccountDependencies();
            Id idRegistrantRecordType = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME , Account.class.getName());
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstRegistrants.add(TestDataUtility.newPersonAccount(i, idRegistrantRecordType));
            }
            insert this.lstRegistrants;
            TestDataUtility.increaseUniquenessDifferentiator();
        }
    }
    //END OF ACCOUNT

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2016
    Version - 1.0
    Function -returns new instance of Zuora__CustomerAccount__c
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Zuora__CustomerAccount__c newZuoraCustomerAccount(Integer i, Id accountId){
        return new Zuora__CustomerAccount__c(   Name = 'CustAcc'+i,
                                                Zuora__Account__c = accountId,
                                                Zuora__Status__c = Constants.ZUORA_ACCOUNT_STATUS_FIELD_ACTIVE_VALUE
                                            );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2016
    Version - 1.0
    Function - loads dependencies for Zuora__CustomerAccount__c
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkZuoraCustomerAccountDependencies(){
        if(this.lstRegistrants == null){
            this.createRegistrants();
        }
    }


    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2016
    Version - 1.0
    Function - insert Zuora__CustomerAccount__c list
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createZuoraCustomerAccount(){
        if(this.lstBillingAccount == null){
            this.lstBillingAccount = new List<Zuora__CustomerAccount__c>();
            this.checkZuoraCustomerAccountDependencies();
            for(Integer i = 0; i < this.iCounter; i++){
                this.lstBillingAccount.add(TestDataUtility.newZuoraCustomerAccount(i, this.lstRegistrants[i].Id));
            }
            insert this.lstBillingAccount;
        }

    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.0
    Function - Creates billing account for registrant
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createBillingAccountToRegistrant(id RegistrantID,string PaymentMethodType){

        lstZuoraPaymentMethods=new list<Zuora__PaymentMethod__c>();
        lstBillingAccount=new list<Zuora__CustomerAccount__c>();

        //Create billing Account
        Zuora__CustomerAccount__c billingAccountObj=new Zuora__CustomerAccount__c(name='TestBilling',Zuora__Account__c=RegistrantID,Zuora__Status__c='Active');
        lstBillingAccount.add(billingAccountObj);
        insert lstBillingAccount;

        createZuoraPaymentRecord(null, lstBillingAccount[0].Id);
        
        String zuoraPaymentMethodId = String.valueOf(Math.random()); 
        lstZuoraPayments[0].ZuoraPaymentMethodId__c = zuoraPaymentMethodId; 
        update lstZuoraPayments; 

        //create payment method credit card
        if(PaymentMethodType==constants.PAYMENT_METHOD_CREDIT_CARD_TYPE){
            Zuora__PaymentMethod__c creditPaymentObj=new Zuora__PaymentMethod__c(Zuora__DefaultPaymentMethod__c=true,Zuora__PaymentMethodStatus__c='Active',Zuora__BillingAccount__c=billingAccountObj.id,name='CreditPayment',Zuora__Type__c=constants.PAYMENT_METHOD_CREDIT_CARD_TYPE,Zuora__CreditCardMaskNumber__c='XXXX111', Zuora__External_Id__c = zuoraPaymentMethodId);
            lstZuoraPaymentMethods.add(creditPaymentObj);
            insert creditPaymentObj;
        }else if(PaymentMethodType==constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE){
            Zuora__PaymentMethod__c directDebitPaymentObj=new Zuora__PaymentMethod__c(Zuora__DefaultPaymentMethod__c=true,Zuora__PaymentMethodStatus__c='Active',Zuora__BillingAccount__c=billingAccountObj.id,name='DirectDebitPayment',Zuora__Type__c=constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE,Zuora__BankTransferAccountNumber__c='XXXX111', Zuora__External_Id__c = zuoraPaymentMethodId);
            lstZuoraPaymentMethods.add(directDebitPaymentObj);
            insert directDebitPaymentObj;
        }

    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.0
    Function - Creates billing account for registrant
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createBillingAccountToRegistrant(id RegistrantID){
        lstBillingAccount=new list<Zuora__CustomerAccount__c>();

        //Create billing Account
        Zuora__CustomerAccount__c billingAccountObj=new Zuora__CustomerAccount__c(name='TestBilling',Zuora__Account__c=RegistrantID,Zuora__Status__c='Active');
        lstBillingAccount.add(billingAccountObj);
        insert lstBillingAccount;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.0
    Function - Creates zuora subscription for registrant
    #############Change Log#############
    Modified by          Change Date
    Mantas Grigaliunas   02/05/2017 Added more fields to query
    ****************************************************************************************/
    public void createZuoraSubscriptionToRegistrant(Id registrantId){
        lstZuoraSubscriptions = new List<Zuora__Subscription__c>();
        Zuora__Subscription__c subscriptionObj = new Zuora__Subscription__c(Name = 'TestSubscription', Zuora__Version__c=1, Zuora__Status__c='Active',
          Zuora__Account__c = registrantId, Zuora__CustomerAccount__c = lstBillingAccount[0].Id, Zuora__InvoiceOwner__c = lstBillingAccount[0].Id,
          Zuora__SubscriptionStartDate__c = Date.today(), Zuora__SubscriptionEndDate__c = Date.today().addYears(1), 
          Zuora__TermStartDate__c = Date.today(), Zuora__NextChargeDate__c = Date.today().addMonths(1));
        lstZuoraSubscriptions.add(subscriptionObj);
        insert lstZuoraSubscriptions;
    }

  /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 08/08/2018
    Version - 1.0
    Function - returns new instance of zuora subscription
    #############Change Log#############
    Modified by  Version   Change Date
    ****************************************************************************************/
    public static Zuora__Subscription__c newZSubscription(Integer i, Id accountId, Id billingAccountId){
        return new Zuora__Subscription__c(
                                        Name = 'TestSubscription'+i,
                                        Zuora__Version__c = 1,
                                        Zuora__Status__c = Constants.SUBSCRIPTION_ACTIVE_STATUS,
                                        Zuora__Account__c = accountId,
                                        Zuora__CustomerAccount__c = billingAccountId,
                                        Zuora__InvoiceOwner__c = billingAccountId);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 08/08/2018
    Version - 1.0
    Function - check dependencies for zuora subscription
    #############Change Log#############
    Modified by  Version   Change Date
    ****************************************************************************************/
    public void checkZSubscriptionDependencies(){
        if(this.lstBillingAccount == null){
            this.createZuoraCustomerAccount();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 08/08/2018
    Version - 1.0
    Function - Creates zuora subscription for registrant - pattern following method
    #############Change Log#############
    Modified by  Version   Change Date
    ****************************************************************************************/
    public void createZSubscriptions(){
        if(this.lstZuoraSubscriptions == null){
            this.checkZSubscriptionDependencies();
            this.lstZuoraSubscriptions = new List<Zuora__Subscription__c>();
            for(Integer i = 0; i < this.iCounter; i++){
                this.lstZuoraSubscriptions.add(TestDataUtility.newZSubscription(i, this.lstRegistrants[i].Id, this.lstBillingAccount[i].Id));
            }
            insert this.lstZuoraSubscriptions;
        }
    }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/06/2016
  Version - 1.0
  Function - create and insert new zuora subscriptions
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createZuoraSubscription(){

    if(this.lstZuoraSubscriptions == null){
      this.lstZuoraSubscriptions = new List<Zuora__Subscription__c>();
      this.checkZuoraSubscriptionDependancies();

      for(Integer i = 0; i < this.iCounter; i++){
        this.lstZuoraSubscriptions.add(
          TestDataUtility.newZuoraSubscription(i, this.lstRegistrants[i].Id, this.lstBillingAccount[i].Id)
        );
      }
      insert this.lstZuoraSubscriptions;
    }
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/06/2016
  Version - 1.0
  Function - check dependancies for the Zuora subscription creation
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkZuoraSubscriptionDependancies(){
    if(this.lstRegistrants == null){
      this.createRegistrants();
    }

    if(this.lstBillingAccount == null){
      this.createZuoraCustomerAccount();
    }
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/06/2016
  Version - 1.0
  Function - create a new Zuora Subscription
  #############Change Log#############
  Modified by         Change Date
  Mantas Grigaliunas  02/05/2017  Added more fields
  ****************************************************************************************/
  public static Zuora__Subscription__c newZuoraSubscription(Integer i, Id registrantId, Id billingAccountId){
    return new Zuora__Subscription__c(
      Name                                = 'TestSubscription' + String.valueOf(i),
      Zuora__Version__c                   = 1,
      Zuora__Status__c                    = Constants.SUBSCRIPTION_ACTIVE_STATUS,
      Zuora__Account__c                   = registrantId,
      Zuora__CustomerAccount__c           = billingAccountId,
      Zuora__InvoiceOwner__c              = billingAccountId,
      Zuora__SubscriptionStartDate__c     = Date.today(), 
      Zuora__SubscriptionEndDate__c       = Date.today().addYears(1),
      Zuora__TermStartDate__c             = Date.today(), 
      Zuora__NextChargeDate__c            = Date.today().addMonths(1),
      Subscription_Rate_Plan_Term_Type__c = Constants.RATE_PLAN_MONTHLY
    );
  }
  /***************************************************************************************
  Developer - Sally ElGhoul (Accenture)
  Date - 21/09/2015
  Version - 1.3
  Function - Creates zuora subscription product charge for a subscription
  #############Change Log#############
  Modified by  Version   Change Date
  Michal Szewczyk   1.1    26/01/2016  Added Zuora__Price__c
  Gavin Palmer    1.2     01/06/2016  Added effectiveStartDate and Effective end date
  Gavin Palmer    1.3     27/06/2016  moved the new sub product charge into seperate static method
  ****************************************************************************************/
  public void createSubscriptionProductCharges(id SubscriotionId){
    lstZuoraSubscriptionProductCharges=new list<Zuora__SubscriptionProductCharge__c>();
    Zuora__SubscriptionProductCharge__c subscriptionProductChargeObj = TestDataUtility.newSubscriptionProductCharge(SubscriotionId, null);
    lstZuoraSubscriptionProductCharges.add(subscriptionProductChargeObj);
    insert lstZuoraSubscriptionProductCharges;
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/06/2016
  Version - 1.0
  Function - create and insert new zuora subscription product charges
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createSubscriptionProductCharges(){
    if(this.lstZuoraSubscriptionProductCharges == null){
      this.lstZuoraSubscriptionProductCharges = new List<Zuora__SubscriptionProductCharge__c>();
      this.checkSubscriptionProductChargeDependancies();

      for(Integer i = 0; i < this.iCounter; i++){
        this.lstZuoraSubscriptionProductCharges.add(
          TestDataUtility.newSubscriptionProductCharge(this.lstZuoraSubscriptions[i].Id, this.lstZuoraProducts[i].Id)
        );
      }
      insert this.lstZuoraSubscriptionProductCharges;
    }
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/06/2016
  Version - 1.0
  Function - check dependancies for the subscription product charge creation
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkSubscriptionProductChargeDependancies(){
    if(this.lstZuoraSubscriptions == null){
      this.createZuoraSubscription();
    }

    if(this.lstZuoraProducts == null){
      this.createZuoraProducts();
    }
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/06/2016
  Version - 1.0
  Function - create a new Zuora Subscription product charge
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Zuora__SubscriptionProductCharge__c newSubscriptionProductCharge(Id subscriptionId, Id zuoraProductId){
    return new Zuora__SubscriptionProductCharge__c(
      Name = 'TestProduct Annual',
      Zuora__Model__c = Constants.SUBSCRIPTION_PRODUCTCHARGE_FLAT_FEE_PRICING_VALUE,
      Zuora__Subscription__c = subscriptionId,
      Zuora__Price__c = 150,
      Zuora__EffectiveStartDate__c = Date.today().addDays(-1),
      Zuora__EffectiveEndDate__c = Date.today().addDays(1),
      Zuora__Product__c = zuoraProductId
    );
  }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 14/10/2015
    Version - 1.0
    Function - Creates zuora payment record for a billing account
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createZuoraPaymentRecord(string sfAccountId,string BillingAccountId){
        lstZuoraPayments=new list<Zuora__Payment__c>();
        Zuora__Payment__c zuoraPaymentObj=new Zuora__Payment__c(ZuoraPaymentMethodId__c='ZuoraId1234',Name='testP2222',Zuora__Type__c='Electronic',Zuora__Status__c='Processed',Zuora__Account__c=sfAccountId,Zuora__BillingAccount__c=BillingAccountId,Zuora__AccountingCode__c='Credit Card',Zuora__PaymentMethod__c='Credit Card AmericanExpress ***********4343',Zuora__EffectiveDate__c=DateTime.now(),Zuora__SubmittedOn__c=DateTime.now(),Zuora__Amount__c=8);
        lstZuoraPayments.add(zuoraPaymentObj);
        insert lstZuoraPayments;
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 14/10/2015
    Version - 1.0
    Function - Creates zuora payment Method record for a billing account
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createZuoraPaymentMethod(string BillingAccountId){
        lstZuoraPaymentMethods=new list<Zuora__PaymentMethod__c>();
        Zuora__PaymentMethod__c zuoraPaymentMethodObj=new Zuora__PaymentMethod__c(Zuora__External_Id__c='ZuoraId1234',Name='TestPaymentMethodName1',Zuora__BillingAccount__c=BillingAccountId);
        lstZuoraPaymentMethods.add(zuoraPaymentMethodObj);
        insert lstZuoraPaymentMethods;
    }

    //Zquotes
    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.0
    Function - Zquote record instance creation -
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szwczyk   1.1        27/01/2016  Added zqu__ValidUntil__c
    ****************************************************************************************/
    public static zqu__Quote__c newZquote(Id accountId){
        return new zqu__Quote__c(   zqu__Account__c = accountId,
                                    zqu__InitialTerm__c=12,
                                    zqu__Subscription_Term_Type__c='Termed',
                                    zqu__RenewalSetting__c='RENEW_WITH_SPECIFIC_TERM',
                                    zqu__RenewalTerm__c=12,
                                    zqu__ValidUntil__c = Date.today()
                                );
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.0
    Function - dependencies for zqu__Quote__c object creation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkZquoteDependencies(){
        if(this.lstRegistrants == null){
            this.createRegistrants();
        }
    }

    /***************************************************************************************
    Developer - Sally ElGhoul (Tquila)
    Date - 27/04/2015
    Version - 1.0
    Function - dependencies zqu__Quote__c object creation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createZquotes(){
        if(this.lstZQuotes == null){
            this.checkZquoteDependencies();
            this.lstZQuotes = new List<zqu__Quote__c>();

            for(Integer registrantIndex = 0; registrantIndex<this.iCounter; registrantIndex++){
                for(integer i=0;i<this.iCounter;i++){
                    this.lstZQuotes.add(TestDataUtility.newZquote(this.lstRegistrants[registrantIndex].Id));
                }
            }
            insert this.lstZQuotes;
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date
    Function    This function is called to add the start discount
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ELGhoul       1.1         16/2/2016  //Modify the quote rate plan name for product
    Pawel Chrzanowski   1.2         24/03/2016  //Modified method to make all the Ids unique
    Wiktor Czykin       1.3      04/08/2016 //added max prices
    ****************************************************************************************/
    public void createZProducts(){
        if(lstZproducts==null){
            lstZproducts=new list<zqu__ZProduct__c>();
        }

        list<zqu__ProductRatePlan__c> lstRatePlans=new list<zqu__ProductRatePlan__c>();
        list<zqu__ProductRatePlanCharge__c> lstRatePlanCharges=new list<zqu__ProductRatePlanCharge__c>();

        for(integer i=0;i<this.iCounter;i++){
            zqu__ZProduct__c zProdObj=new zqu__ZProduct__c();
            zProdObj.Name='UnitTesting Product'+i;
            zProdObj.zqu__Active__c=true;
            zprodObj.zqu__Allow_Feature_Changes__c=true;
            zprodObj.zqu__EffectiveStartDate__c=Date.Today();
            zprodObj.zqu__EffectiveEndDate__c=Date.today().addYears(1);
            zprodObj.zqu__SKU__c='testSKU';
            zprodObj.zqu__ZuoraId__c='11111111' + i;
            zprodObj.MaxCoverPriceAnnual__c = 150+'';
            zprodObj.MaxCoverPriceMonth__c = 15+'';
            lstZproducts.add(zprodObj);
        }
        if(lstZproducts!=null && lstZproducts.size()>0){
            insert lstZproducts;

            Integer i = 0;
            for(zqu__ZProduct__c prodObj : lstZproducts){

                zqu__ProductRatePlan__c ratePlanObj=new zqu__ProductRatePlan__c();
                ratePlanObj.name='Monthly Open Offer Plan';
                ratePlanObj.zqu__ZProduct__c=prodObj.id;
                ratePlanObj.zqu__EffectiveStartDate__c=Date.Today();
                ratePlanObj.zqu__EffectiveEndDate__c=Date.today().addYears(1);
                ratePlanObj.zqu__ZuoraId__c='2222222' + i;
                ratePlanObj.DefaultOfferCode__c='UnitTest-001';

                zqu__ProductRatePlan__c discountRatePlanObj=new zqu__ProductRatePlan__c();
                discountRatePlanObj.name=constants.DISCOUNT_RATE_PLAN_NAME;
                discountRatePlanObj.zqu__ZProduct__c=prodObj.id;
                discountRatePlanObj.zqu__EffectiveStartDate__c=Date.Today();
                discountRatePlanObj.zqu__EffectiveEndDate__c=Date.today().addYears(1);
                discountRatePlanObj.zqu__ZuoraId__c='3333333' + i;

                lstRatePlans.add(ratePlanObj);
                lstRatePlans.add(discountRatePlanObj);
                i++;
            }

            if(lstRatePlans!=null && lstRatePlans.size()>0){
                insert lstRatePlans;

                for(zqu__ProductRatePlan__c rateplanObj : lstRatePlans){

                    zqu__ProductRatePlanCharge__c chargeObj=new zqu__ProductRatePlanCharge__c();
                    chargeObj.name=rateplanObj.name;
                    chargeObj.zqu__Apply_Discount_To_Recurring_Charges__c=true;
                    chargeObj.zqu__Apply_Discount_To_One_Time_Charges__c=false;
                    chargeObj.zqu__Apply_Discount_To_Usage_Charges__c=false;
                    chargeObj.zqu__DefaultQuantity__c=1;
                    chargeObj.zqu__Discount_Level__c='Subscription';
                    if(chargeObj.name!=constants.DISCOUNT_RATE_PLAN_NAME){
                        chargeObj.zqu__Model__c='Flat Fee';
                    }else{
                        chargeObj.zqu__Model__c='Discount-Fixed Amount';
                    }
                    chargeObj.zqu__ProductRatePlan__c=rateplanObj.id;
                    chargeObj.zqu__RecurringPeriod__c='Month';
                    chargeObj.zqu__Type__c='Recurring';
                    chargeObj.zqu__ZuoraId__c=rateplanObj.zqu__ZuoraId__c+'2';
                    lstRatePlanCharges.add(chargeObj);
                }

                if(lstRatePlanCharges!=null && lstRatePlanCharges.size()>0){
                    insert lstRatePlanCharges;
                }
            }
        }
    }

    //SUBSCRIPTIONS
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.3
    Function - Subscription record instance creation - created based on fields setup for subs in TestCreateTestEnvironments class
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         24/06/2015  //added first start date setting when null is passed in
    Wiktor Czykin   1.2         26/06/2015  //replaced Payment_Type__c string with constant
    Wiktor Czykin   1.3         14/10/2015  //fixed the Delivery_Type__c to be HND
    Gavin Palmer  1.4    27/05/2016  // Added renewal price override and low start weekly price
    Gavin Palmer  1.5    31/05/2016  // added parent z product
    Gavin Palmer  1.6    03/06/2016  // added fields Astra_Migration_Balance__c and Revenue_Write_off_Amount__c
    ****************************************************************************************/
  public static Subscription__c newSubscripiton(Integer i, Id subscriberId, Id retailerId, Date firstStartDate, Id zProductId){

    if(firstStartDate == null){
      firstStartDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
    }
    return new Subscription__c(
                    Subscriber__c = subscriberId,
                    Retailer__c = retailerId,
                    Weekly_Price__c = 219.11,
                    Subscription_Status__c = Constants.SSTATUS_ACTIVE,
                    Subscription_Duration_Picklist__c = '52',
                    Start_Date__c = firstStartDate,
                    Pricing_Error__c = false,
                    Delivery_Type__c = Constants.DELIVERYTYPE_HND,
                    Payment_Details_Received__c=true,
                    Payment_Type__c=Constants.SUB_PMETHOD_DD,
                    Voucher_Pack_Duration__c=13,
                    Asset_Calc__c=0,
                    Liab_Calc__c = 0,
                    Renewal_Price_Override__c = 8,
                    Low_Start_Weekly_Price__c = 9,
                    Product__c = zProductId,
                    Astra_Migration_Balance__c = 11,
                    Revenue_Write_off_Amount__c = 0,
                                        PaymentDate__c = '1'
    );
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 31/05/2016
  Version - 1.0
  Function - added another method that calls the above method with a null final parameter
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Subscription__c newSubscripiton(Integer i, Id subscriberId, Id retailerId, Date firstStartDate){
    return TestDataUtility.newSubscripiton(i, subscriberId, retailerId, firstStartDate, null);
  }

  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 17/02/2015
  Version - 1.1
  Function - dependencies for Subscription__c object creation
  #############Change Log#############
  Modified by     Version     Change Date
  Gavin Palmer 1.1     31/05/2016 // added a z product dependency
  ****************************************************************************************/
  public void checkSubscriptionDependencies(){
    if(this.lstRetailers == null){
        this.createRetailers();
    }
    if(this.lstIndividualSubscribers == null){
        this.createIndividualSubscribers();
    }
    if(this.lstZproducts == null) {
      this.createZProductFeatures();
    }
  }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - Creates subscriptions
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer 1.1     31/05/2016 // added a z product dependancy
    ****************************************************************************************/
    public void createSubscriptions(){
        if(this.lstSubscriptions == null){
            this.checkSubscriptionDependencies();
            this.lstSubscriptions = new List<Subscription__c>();

            Date firstDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
            for(Integer i = 0; i<this.iCounter; i++){
        this.lstSubscriptions.add(TestDataUtility.newSubscripiton(i, this.lstIndividualSubscribers[i].Id, this.lstRetailers[i].Id, firstDate, lstZproducts[i].Id));
            }
            insert this.lstSubscriptions;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - Creates subscriptions with target end date (based on end date formula counted from duration and start date)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createSubscriptionsBasedOnEndDate(Date dEndDate){
        if(this.lstSubscriptions == null){
            this.checkSubscriptionDependencies();
            this.lstSubscriptions = new List<Subscription__c>();
            Integer iDurationOverride = 26;
            Date firstDate = dEndDate.addDays(-(iDurationOverride*7)+1);
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstSubscriptions.add(TestDataUtility.newSubscripiton(i, this.lstIndividualSubscribers[i].Id, this.lstRetailers[i].Id, firstDate));
                this.lstSubscriptions[i].Subscription_Duration_Number_Override__c = iDurationOverride;
            }
            insert this.lstSubscriptions;
        }
    }

  //TCODEMANAGEMENT
  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 25/02/2015
  Version - 1.1
  Function - return new TCodeManagement__c instance
  #############Change Log#############
  Modified by    Version   Change Date
  Wiktor Czykin  1.1     24/05/2016 //added Payment_Type__c
  ****************************************************************************************/
  public static TCodeManagement__c newTCodeManagement(String sName){
    return new TCodeManagement__c(
                      Name = sName,
                      Digital_Monthly_Price__c = 9.99,
                      Digital_Yearly_Price__c = 99.99,
                      Type__c = Constants.TCODE_TYPE_PROMOTIONAL,
                      Description__c = 'test'+sName,
                      Price__c = 9.99,
                      Valid__c = true,
                      Payment_Type__c = Constants.ALLOW_ONE_OFF_52_WEEK
    );
  }

  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 01/05/2015
  Version - 1.0
  Function - inserts tcodes
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createTCodeManagement(){
    if(this.lstTCodeManagement == null){
      this.lstTCodeManagement = new List<TCodeManagement__c>();
      for(Integer i = 0; i<this.iCounter; i++){
        this.lstTCodeManagement.add(TestDataUtility.newTCodeManagement('t'+i));
      }
      insert this.lstTCodeManagement;
    }
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 15/12/2015
  Version - 1.1
  Function - modify tCode instance with Low Start fields
  #############Change Log#############
  Modified by    Version   Change Date
  Wiktor Czykin  1.1       26/05/2016 //set payment type
  ****************************************************************************************/
  public static TCodeManagement__c changeTCodeToLowStart(TCodeManagement__c tCode){
    tCode.Type__c = Constants.TCODE_TYPE_LOWSTART;
    tCode.Low_Start_Period__c = 13+'';
    tCode.Allow26Week__c = false;
    tCode.Allow52Week__c = false;
    tCode.Low_Start_Weekly_Price__c = 9;
        tCode.Payment_Type__c = Constants.ALLOW_52_WEEK_DD;
    return tCode;
  }

    //POC
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 01/05/2015
    Version - 1.0
    Function - return new POC__c instance
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static POC__c newPOC(Integer i, Id tcodeId){
        return new POC__c(
                            POC_ID__c='sad'+i,
                            PostalCode__C = 'E3 3EW',
                            LastName__c='lastName',
                            TCodeManagement__c = tcodeId
        );
    }

  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 01/05/2015
  Version - 1.0
  Function - dependencies for POC__c records creation
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkPOCDependencies(){
    if(this.lstTCodeManagement == null){
      this.createTCodeManagement();
    }
  }
  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 29/03/2016
  Version - 1.0
  Function - dependencies for TCode Product records creation
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkTCodeProducts(Boolean bDigital){
    if(this.lstTCodeManagement == null){
      this.createTCodeManagement();
    }
    if(this.lstZproducts == null){
      this.createZProductFeatures();
    }
    if(bDigital){
        if(this.lstOffers == null){
            this.createOffers();
        }
    }
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 29/03/2016
  Version - 1.0
  Function - create multiple pocs for tcodemanagement record
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createTCodeProducts(){
    if(this.lstTCodeProducts == null){
      this.checkTCodeProducts(false);
      this.lstTCodeProducts = new List<TCode_Product__c>();

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstTCodeProducts.add(TestDataUtility.newTCodeProduct(lstZproducts[i].Id,lstTCodeManagement[i].Id));
      }
      insert this.lstTCodeProducts;
    }
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 30/05/2017
  Version - 1.0
  Function - create tcode product offers
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createTCodeProductOffers(){
    if(this.lstTCodeProductOffers == null){
      this.checkTCodeProducts(true);
      this.lstTCodeProductOffers = new List<TCode_Product__c>();
      for(Integer i = 0; i<this.iCounter; i++){
        this.lstTCodeProductOffers.add(TestDataUtility.newTCodeProduct(this.lstZproducts[i].Id, this.lstTCodeManagement[i].Id, this.lstOffers[i].Id));
      }
      insert this.lstTCodeProductOffers;
    }
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 19/05/2015
  Version - 1.0
  Function - new instance creation for TCode_Product_Incentive__c
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static TCode_Product_Incentive__c newTCodeProductIncentive(Integer i, Id incentiveId, Id tCodeProductId, String sSubscriptionType){
    return new TCode_Product_Incentive__c(  Incentive__c = incentiveId,
                        TCode_Product__c = tCodeProductId,
                        Subscription_Type__c = sSubscriptionType
    );
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 19/05/2015
  Version - 1.0
  Function - check dependencies for TCode_Product_Incentive__c records creation
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkTCodeProductIncentivesDependencies(){
    if(this.lstTCodeProducts == null){
      this.createTCodeProducts();
    }
    if(this.lstIncentives == null){
      this.createIncentives();
    }
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 19/05/2015
  Version - 1.0
  Function - create TCode_Product_Incentive__c records list
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createTCodeProductIncentives(){
    if(this.lstTCodeProductIncentives == null){
      this.lstTCodeProductIncentives = new List<TCode_Product_Incentive__c>();
      this.checkTCodeProductIncentivesDependencies();
      List<Schema.PicklistEntry> lstEntries = TCode_Product_Incentive__c.Subscription_Type__c.getDescribe().getPicklistValues();
      List<String> lstValues = new List<String>();
      for(Schema.PicklistEntry entry : lstEntries){
        lstValues.add(entry.getValue());
      }
      String sAll = String.join(lstValues, ';');
      for(Integer i = 0; i < this.iCounter; i++){
        this.lstTCodeProductIncentives.add(TestDataUtility.newTCodeProductIncentive(i, this.lstIncentives[i].Id, this.lstTCodeProducts[i].Id, sAll));
      }
      insert this.lstTCodeProductIncentives;
    }
  }

  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 01/05/2015
  Version - 1.0
  Function - create multiple pocs for tcodemanagement record
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createPOCs(Integer iCountPerTCode){
    if(this.mapTCodeManagementToPOCs == null){
      this.checkPOCDependencies();
      this.mapTCodeManagementToPOCs = new Map<Id, List<POC__c>>();
      lstPOCs = new List<POC__c>();
      for(Integer i=0; i<this.iCounter ;i++){
        List<POC__c> lstPOCsForTCode = new List<POC__c>();
        for(Integer j=0; j<iCountPerTCode; j++){
          lstPOCsForTCode.add(TestDataUtility.newPOC(i+j,this.lstTCodeManagement[i].Id));
        }
        this.mapTCodeManagementToPOCs.put(this.lstTCodeManagement[i].Id, lstPOCsForTCode);
        lstPOCs.addAll(lstPOCsForTCode);
      }
      insert lstPOCs;
    }
  }
  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 29/03/2016
  Version - 1.1
  Function - returns new instance of TCode Product object - for print offer
  #############Change Log#############
  Modified by    Change Date
  Wiktor Czykin  08/03/2017 //added default record type 
  ****************************************************************************************/
  public static TCode_Product__c newTCodeProduct(Id productId,Id tcodeId){
    Id recTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
    TCode_Product__c tcodeProd = new TCode_Product__c(
            Product__c =productId,
            TCodeManagement__c = tcodeId,
            Low_Start_Price__c = 9.00,
            Digital_Yearly_Price__c = 2000.00,
            Digital_Monthly_Price__c = 200.00,
            Weekly_Price__c = 20.00,
            RecordTypeId = recTypeId
    );
    return tcodeProd;
  }

  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 30/05/2016
  Version - 1.0
  Function - returns new instance of TCode Product object - for digital zoffer
  #############Change Log#############
  Modified by    Change Date
  ****************************************************************************************/
  public static TCode_Product__c newTCodeProduct(Id productId,Id tcodeId, Id offerId){
    Id recTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_ZOFFER, TCode_Product__c.class.getName());
    TCode_Product__c tcodeProd = new TCode_Product__c(
            Product__c =productId,
            TCodeManagement__c = tcodeId,
            Offer__c = offerId,
            RecordTypeId = recTypeId
    );
    return tcodeProd;
  }

  //PLAN
  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 04/04/2016
  Version - 1.1
  Function - return new instance of Plan object
  #############Change Log#############
  Modified by  Version   Change Date
  Michal Szewczyk  1.1   05/07/2016  - added product population
  ****************************************************************************************/
  public static Plan__c newPlan(Integer i,Id productId){
    Plan__c plan = new Plan__c(
        Name = 'plan' + i,
        Description__c = 'description' + i,
        Days_Before__c = 5,
        Is_Valid__c = true,
        Product__c = productId
    );
    return plan;
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 04/04/2016
  Version - 1.1
  Function - create Plans
  #############Change Log#############
  Modified by  Version   Change Date
  Michal Szewczyk  1.1   05/07/2016  - added product population
  ****************************************************************************************/
  public void createPlans(){
    this.checkPlanDependencies();

    if(this.lstPlans == null){
      this.lstPlans = new List<Plan__c>();

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstPlans.add(TestDataUtility.newPlan(i,this.lstZproducts[i].Id));
      }
      insert this.lstPlans;
    }
  }

  //PRICE PLAN
  /***************************************************************************************
  Developer - Wiktor Czykin
  Date - 11/10/2016
  Version - 1.0
  Function - method version that allows record type Id selection
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Price_Plan__c newPricePlan(Id planId, Id productId, Id recordTypeId){
        if(recordTypeId == null){
            recordTypeId = RecordTypeUtility.getRecordTypeId(Price_Plan__c.SObjectType, Constants.PRICE_PLAN_RECORDTYPE_DIGITAL, Price_Plan__c.class.getName());
        }
    Price_Plan__c pricePlan = new Price_Plan__c(
        Plan__c = planId,
        High_Price__c = 9.99,
        Low_Price__c = 3.00,
        Renewal_Price__c = 8.00,
        Product_To__c = productId,
                RecordTypeId = recordTypeId
    );
    return pricePlan;
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 04/04/2016
  Version - 1.0
  Function - return new instance of Price Plan object
  #############Change Log#############
  Modified by  Version   Change Date
  Gavin Palmer   1.1   31/05/2016   added parent zProduct
  Lynette Lim      1.2     25/07/2016   Removed Rank__c field from Price Plan logic tests
    Wiktor Czykin    1.3     11/10/2016   Moved contents to the overloaded method
  ****************************************************************************************/
  public static Price_Plan__c newPricePlan(Id planId, Id productId){
    return newPricePlan(planId, productId, null);
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 04/04/2016
  Version - 1.0
  Function - check Price Plan dependencies
  #############Change Log#############
  Modified by  Version   Change Date
  Gavin Palmer 1.1     31/05/2016 added check for parent zProduct
  Michal Szewczyk  1.2   05/07/2016 swapped ifs
  ****************************************************************************************/
  public void checkPricePlanDependencies(){
    if(this.lstZproducts == null) {
      this.createZProduct();
    }
    if(this.lstPlans == null){
      this.createPlans();
    }
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 04/07/2016
  Version - 1.0
  Function - check Price Plan dependencies
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkPlanDependencies(){

    if(this.lstZproducts == null) {
      this.createZProduct();
    }
  }
  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 04/04/2016
  Version - 1.2
  Function - create Price Plans
  #############Change Log#############
  Modified by  Version   Change Date
  Gavin Palmer 1.1     31/05/2016 added parent zProduct
    Wiktor Czykin
  ****************************************************************************************/
  public void createPricePlans(){
    if(this.lstPricePlans == null){
      this.checkPricePlanDependencies();
      this.lstPricePlans = new List<Price_Plan__c>();
            Id recType = RecordTypeUtility.getRecordTypeId(Price_Plan__c.SObjectType, Constants.PRICE_PLAN_RECORDTYPE_DIGITAL, Price_Plan__c.class.getName());

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstPricePlans.add(TestDataUtility.newPricePlan(this.lstPlans[i].Id, this.lstZproducts[i].Id, recType));
      }
      insert this.lstPricePlans;
    }
  }

    //TASKS
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - returns new instance of Task object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Task newTask(Integer i, Id subscriptionId, String sSubject, Date dCreatedDate){
        Task t = new Task(
                        Scheduled_Callback__c = Date.today().addDays(-2),
                        Status = Constants.TSTATUS_INPROGRESS,
                        Outbound_Calling_Viewed_Date__c = (Date.today().addDays(1)),
                        WhatId = subscriptionId,
                        Description = 'test description'+i,
                        Outcome__c = 'an outcome',
                        No_Sale_Reason__c = 'wrong person'+i,
                        M_S__c = 'valuex'+i,
                        Manual_Voucher__c = 'mv',
                        Reduce_Price__c = '100',
                        CreatedDate = dCreatedDate
        );
        if(String.isNotBlank(sSubject)){
            t.Subject = sSubject;
        }else{
            t.Subject = 'Task subject '+i;
        }
        return t;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 02/03/2015
    Version - 1.0
    Function - dependencies for Task records creation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkSubscriptionTaskDependencies(){
        if(this.lstSubscriptions == null){
            this.createSubscriptions();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 17/02/2015
    Version - 1.0
    Function - Creates subscriptions
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createSubscriptionTasks(String sSubject, Date dCreatedDate){
        if(this.lstSubscriptionTasks == null){
            this.checkSubscriptionTaskDependencies();
            this.lstSubscriptionTasks = new List<Task>();

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstSubscriptionTasks.add(TestDataUtility.newTask(i, this.lstSubscriptions[i].Id, sSubject, dCreatedDate));
            }
            insert this.lstSubscriptionTasks;
        }
    }

    //PRODUCTS
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - returns instance of Product2 object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Product2 newProduct(Integer i){
        return new Product2(Name = 'Newspaper'+i,
                            Family = 'Media',
                            CanUseQuantitySchedule = true,
                            CanUseRevenueSchedule = true
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - inserts Product2 records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createProducts(){
        if(this.lstProducts == null){
            this.lstProducts = new List<Product2>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstProducts.add(TestDataUtility.newProduct(i));
            }
            insert this.lstProducts;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - returns instance of Pricebook2 object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Pricebook2 newPriceBook(Integer i){
        return new Pricebook2(  Name = 'TMG Test Pricebook2 '+i,
                                IsActive = true
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - inserts Pricebook2 records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createPriceBooks(){
        if(this.lstPriceBooks == null){
            this.lstPriceBooks = new List<Pricebook2>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstPriceBooks.add(TestDataUtility.newPriceBook(i));
            }
            insert this.lstPriceBooks;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - returns instance of PricebookEntry object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static PricebookEntry newPriceBookEntry(Integer i, Id priceBookId, Id productId){
        return new PricebookEntry(  PriceBook2Id = priceBookId,
                                    Product2Id = productId,
                                    UnitPrice = 10+i,
                                    IsActive = true
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - pricebookentry dependencies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkPriceBookEntryDependencies(){
        if(this.lstPriceBooks == null){
            this.createPriceBooks();
        }
        if(this.lstProducts == null){
            this.createProducts();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 27/05/2015
    Version - 1.0
    Function - inserts PricebookEntry records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createPriceBookEntries(){
        if(this.lstPriceBookEntries == null && this.lstStandardPriceBookEntries == null){
            this.lstPriceBookEntries = new List<PricebookEntry>();
            this.lstStandardPriceBookEntries = new List<PricebookEntry>();
            this.checkPriceBookEntryDependencies();

            Id standardPricebookId = Test.getStandardPricebookId();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstStandardPriceBookEntries.add(TestDataUtility.newPriceBookEntry(i, standardPricebookId, this.lstProducts[i].Id));
            }
            insert this.lstStandardPriceBookEntries;

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstPriceBookEntries.add(TestDataUtility.newPriceBookEntry(i, this.lstPriceBooks[i].Id, this.lstProducts[i].Id));
            }
            insert this.lstPriceBookEntries;
        }
    }


    //VOUCHER ADJUSTMENT
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - returns instance of Voucher_Adjustment__c object
    #############Change Log#############
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1         20/12/2016 Removed Deferred Asset Value declaratio as it is calculated in trigger
    ****************************************************************************************/
    public static Voucher_Adjustment__c newVoucherAdjustment(Integer i, Id subscriptionId, Date dStartDate, Date dEndDate){
        return new Voucher_Adjustment__c(   Subscription__c = subscriptionId,
                                            Start_Date__c = dStartDate,
                                            End_Date__c = dEndDate,
                                            Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_VOUCHERRETURN,
                                            Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED,
                                            Date_Vouchers_Received__c = Date.today(),
                                            Comments__c = 'Comment'+i
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - Voucher_Adjustment__c dependencies
    #############Change Log#############
    Modified by     Version     Change Date
  Michal Szewczyk 1.1         17/10/2016 - added PRINT_VOUCHER feature generation
    ****************************************************************************************/
    public void checkVoucherAdjustmentDependencies(){
        if(this.lstSubscriptions == null){
            this.createSubscriptions();
        }
    
    if(this.lstZFeature != null) {
            for(zqu__ZFeature__c tmp:lstZFeature){
              tmp.zqu__FeatureName__c = '4DAY_PRINT_VOUCHER';
              tmp.Active_Days__c ='MON-TUE-WED-THU';
              tmp.zqu__Code__c = '4DAY_PRINT_VOUCHER';
            }

            update this.lstZFeature;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - inserts Voucher_Adjustment__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createVoucherAdjustments(){
        if(this.lstVoucherAdjustment == null){
            this.checkVoucherAdjustmentDependencies();
            Map<Id, Subscription__c> mapSubscriptionsRefetched = new Map<Id, Subscription__c>([select Id, Start_Date__c, End_Date__c from Subscription__c where Id in :this.lstSubscriptions]);

            this.lstVoucherAdjustment = new List<Voucher_Adjustment__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstVoucherAdjustment.add(TestDataUtility.newVoucherAdjustment( i,
                                                                                    this.lstSubscriptions[i].Id,
                                                                                    mapSubscriptionsRefetched.get(this.lstSubscriptions[i].Id).Start_Date__c,
                                                                                    mapSubscriptionsRefetched.get(this.lstSubscriptions[i].Id).End_Date__c
                                                                                    ));
            }
            insert this.lstVoucherAdjustment;
        }
    }

    //CHEQUE
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - returns instance of Cheque_Batch__c object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Cheque_Batch__c newChequeBatch(Integer i){
        Date dTestDate = Date.today().addDays(10);
        return new Cheque_Batch__c( Payment_Slip_Ref_Number__c = '1'+i,
                                    Synthesys_Batch_ID__c = '1'+i
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - inserts Cheque_Batch__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createChequeBatches(){
        if(this.lstChequeBatches == null){

            this.lstChequeBatches = new List<Cheque_Batch__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstChequeBatches.add(TestDataUtility.newChequeBatch(i));
            }
            insert this.lstChequeBatches;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - returns instance of Cheque__c object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Cheque__c newCheque(Integer i, Id chequeBatchId, Id subscriberId, Id subscriptionId){
        return new Cheque__c(   Cheque_Batch__c = chequeBatchId,
                                Cheque_Amount__c = 100,
                                Sort_Code__c = '123456',
                                Account_Number__c = '12345678',
                                Subscriber__c = subscriberId,
                                Subscription__c = subscriptionId,
                                Name_on_Cheque__c ='name'+i,
                                Type__c = Constants.CHEQUE_TYPE_SUBPAYMENT,
                                Cheque_Banking_Status__c = Constants.CHEQUE_BANKINGSTATUS_BANKED
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - Cheque__c dependencies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkChequeDependencies(){
        if(this.lstChequeBatches == null){
            this.createChequeBatches();
        }
        if(this.lstSubscriptions == null){
            this.createSubscriptions();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - inserts Cheque__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createCheques(){
        if(this.lstCheques == null){
            this.checkChequeDependencies();
            this.lstCheques = new List<Cheque__c>();

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstCheques.add(TestDataUtility.newCheque(i, this.lstChequeBatches[i].Id, this.lstIndividualSubscribers[i].Id, this.lstSubscriptions[i].Id));
            }
            insert this.lstCheques;
        }
    }

    //MPP TRANSACTION HISTORY
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.1
    Function - returns instance of MPP_Transaction_History__c object
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         05/08/2015  //added Sale_Type__c
    ****************************************************************************************/
    public static MPP_Transaction_History__c newMPPTransactionHistory(Integer i, Id subscriberId, Id subscriptionId, String sPaymentType){
        MPP_Transaction_History__c mppth = new MPP_Transaction_History__c(
            Product_name__c = 'product'+i,
            Subscriber__c = subscriberId,
            Subscription__c = subscriptionId,
            Payment_Type__c = sPaymentType,
            Payment_Date__c = Datetime.now(),
            Payment_status__c = Constants.MPPTRANSACTION_PAYMENTSTATUS_SUCCESS,
            Total_Price__c = 100,
            Sale_Type__c = Constants.ORDER_TYPE_SALE
        );
        if(sPaymentType == Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE){
            mppth.Card_Type__c = Constants.MPPTRANSACTION_CARDTYPE_VISA;
        }else{
            mppth.DD_Account_Name__c = 'ddaccountname'+i;
            mppth.DD_Account_Number__c = '12345678';
            mppth.DD_Sort_Code__c = '12345678';
            mppth.DD_Transaction_Type__c = Constants.MPPTRANSACTION_DDTRANSACTIONTYPE_PAYMENT;
        }
        return mppth;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - MPP_Transaction_History__c dependencies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkMPPTransactionHistoryDependencies(){
        if(this.lstSubscriptions == null){
            this.createSubscriptions();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 18/06/2015
    Version - 1.0
    Function - inserts MPP_Transaction_History__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createMPPTransactionHistory(String sPaymentType){
        if(this.lstMPPTransactionHistory == null){
            this.checkMPPTransactionHistoryDependencies();
            this.lstMPPTransactionHistory = new List<MPP_Transaction_History__c>();

            String sPaymentMethod = Constants.ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE;
            if(sPaymentType == PAYMENTMETHOD_CC){
                sPaymentMethod = Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE;
            }

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstMPPTransactionHistory.add(TestDataUtility.newMPPTransactionHistory(i, this.lstIndividualSubscribers[i].Id, this.lstSubscriptions[i].Id, sPaymentMethod));
            }
            insert this.lstMPPTransactionHistory;
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 26/08/2015
    Version - 1.0
    Function - inserts MPP_Transaction_History__c records for digital
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createDigitalMPPTransactionHistory(String sPaymentType){
        if(this.lstMPPTransactionHistory == null){
            if (this.lstDigitalSubscribers == null){
                createDigitalSubscribers();
            }
            this.lstMPPTransactionHistory = new List<MPP_Transaction_History__c>();

            String sPaymentMethod = Constants.ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE;
            if(sPaymentType == PAYMENTMETHOD_CC){
                sPaymentMethod = Constants.ORDER_PAYMENT_TYPE_CREDIT_CARD_VALUE;
            }

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstMPPTransactionHistory.add(TestDataUtility.newMPPTransactionHistory(i, this.lstDigitalSubscribers[i].Id, null, sPaymentMethod));
            }
            insert this.lstMPPTransactionHistory;
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 23/07/2015
    Version - 1.0
    Function - inserts Incentive__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Incentive__c newIncentive(){
        Incentive__c incentive = new Incentive__c(
            Name = 'New incentive',
            Incentive_Description__c = 'Test',
            IncentiveValue__c = 5,
            Valid_From__c = System.today().addDays(-10),
            Valid_To__c = System.today().addDays(30));

        return incentive;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 28/07/2015
    Version - 1.0
    Function - inserts Incentive__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createIncentives(){
        if(this.lstIncentives == null){

            this.lstIncentives = new List<Incentive__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstIncentives.add(TestDataUtility.newIncentive());
            }
            insert this.lstIncentives;
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 24/07/2015
    Version - 1.0
    Function - inserts SubscriptionIncentiveAssociation__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static SubscriptionIncentiveAssociation__c newSubscriptionIncentiveAssociation(Id incentiveId, Id subscriberId, Id subscriptionId){
        SubscriptionIncentiveAssociation__c subIncentive = new SubscriptionIncentiveAssociation__c(
            Incentive__c = incentiveId,
            Subscriber__c = subscriberId,
            Subscription__c = subscriptionId);

        return subIncentive;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 28/07/2015
    Version - 1.0
    Function - SubscriptionIncentiveAssociation__c dependencies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkSubscriptionIncentiveAssociationDependencies(){
        if(this.lstSubscriptions == null){
            this.createSubscriptions();
        }
        if(this.lstIncentives == null){
            this.createIncentives();
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Tquila)
    Date - 28/07/2015
    Version - 1.0
    Function - inserts SubscriptionIncentiveAssociation__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createSubscriptionIncentiveAssociation(){
        if(this.lstIncentivesAssociation == null){
            this.checkSubscriptionIncentiveAssociationDependencies();
            this.lstIncentivesAssociation = new List<SubscriptionIncentiveAssociation__c>();

            for(Integer i = 0; i<this.iCounter; i++){
                this.lstIncentivesAssociation.add(TestDataUtility.newSubscriptionIncentiveAssociation(this.lstIncentives[i].Id, this.lstSubscriptions[i].Subscriber__c, this.lstSubscriptions[i].Id));
            }
            insert this.lstIncentivesAssociation;
        }
    }

    //FULFILLMENT PLAN
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 04/08/2015
    Version - 1.0
    Function - returns FulfillmentPlan__c instance
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static FulfillmentPlan__c newFulfillmentPlan(String sEntitlement, String sProductType){
        return new FulfillmentPlan__c(
            Entitlements__c = sEntitlement,
            ProductType__c = sProductType
        );

    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 04/08/2015
    Version - 1.1
    Function - checks dependencies for fulfillment plan creation
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         05/08/2015  //modified to prevent double load issue
    ****************************************************************************************/
    public void fulfillmentPlanDependencies(){
        if(this.lstEntitlementsSettings == null){
            if(!Entitlements__c.getAll().isEmpty()){
                this.lstEntitlementsSettings = Entitlements__c.getAll().values();
            }else{
                this.loadEntitlementsSettings();
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 04/08/2015
    Version - 1.0
    Function - creates fulfillment plan records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createFulfillmentPlan(){
        if(this.lstFulfillmentPlan == null){
            this.fulfillmentPlanDependencies();
            this.lstFulfillmentPlan = new List<FulfillmentPlan__c>();
            for(Entitlements__c ent : this.lstEntitlementsSettings){
                this.lstFulfillmentPlan.add(TestDataUtility.newFulfillmentPlan(ent.Active_Entitlement_Value__c, ent.Pricing_Option_Product_Type__c));
            }
            insert this.lstFulfillmentPlan;
        }

    }

  //PRICING OPTION
  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 03/08/2015
  Version - 1.0
  Function - returns Pricing_Options__c instance
  #############Change Log#############
  Modified by  Version   Change Date
  Michal Szewczyk 1.1     06/04/2016   // added tCodeProdId as a param
  ****************************************************************************************/
  public static Pricing_Options__c newPricingOption(Integer i, Id tCodeId, Id tCodeProdId, String sProductType){
    Pricing_Options__c po = new Pricing_Options__c(
                          ServiceId__c = 1+i,
                          ServicePriceId__c = 1000+i,
                          Subscription_Type__c = Constants.DD_COL_FREQ_MONTHLY,
                          Flow_Type__c = Constants.PRICING_FLOW_TYPE_OPENOFFER,
                          Product_Type__c = sProductType,
                          TCodeManagement__c = tCodeId,
                          TCode_Product__c = tCodeProdId
    );
    if(String.isBlank(sProductType)){
      po.Product_Type__c = Constants.PRICING_WEBPACK_TYPE;
    }
    po.Product_Type__c = po.Product_Type__c.toLowerCase();
    return po;
  }
  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 03/08/2015
  Version - 1.0
  Function - Pricing_Options__c dependencies
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkPricingOptionDependencies(){
    if(this.lstTCodeManagement == null){
      this.createTCodeManagement();
    }
    if(this.lstFulfillmentPlan == null){
      this.createFulfillmentPlan();
    }
  }

  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 03/08/2015
  Version - 1.0
  Function - creates a list of pricing options and adds it to a map -> supports add of records multiple times
  #############Change Log#############
  Modified by  Version   Change Date
  Michal Szewczyk 1.1     06/04/2016  // added Tcode Product population for lookup
  ****************************************************************************************/
  public void createPricingOptions(String sProduct){
    if(this.mapPricingOptions == null){
      this.checkPricingOptionDependencies();
      this.mapPricingOptions = new Map<Integer, List<Pricing_Options__c>>();
    }
    this.createTCodeProducts();
    List<Pricing_Options__c> lstBuffer = new List<Pricing_Options__c>();
    for(Integer i = 0; i<this.iCounter; i++){
      lstBuffer.add(TestDataUtility.newPricingOption(i,this.lstTCodeManagement[i].Id, lstTCodeProducts[i].Id, sProduct));
    }
    insert lstBuffer;
    this.mapPricingOptions.put(this.mapPricingOptions.size(), lstBuffer);
  }

    //UPGRADE_OPTIONS
    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 04/08/2015
    Version - 1.0
    Function - return Upgrade_Option__c instance
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Upgrade_Option__c newUpgradeOptions(Integer i, Id pricingOptionFrom, Id pricingOptionTo){
        return new Upgrade_Option__c(
            Pricing_Option_From__c = pricingOptionFrom,
            Pricing_Option_To__c = pricingOptionTo,
            Upgrade_Confirmation_Text__c = 'confirmation text '+i,
            Upgrade_Description__c = 'description text '+i,
            Upgrade_Sub_Text__c = 'sub text '+i
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 04/08/2015
    Version - 1.0
    Function - Upgrade_Option__c dependencies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void upgradeOptionsDependencies(){
        if(this.mapPricingOptions == null){
            this.createPricingOptions(Constants.PRICING_WEBPACK_TYPE);
            this.createPricingOptions(Constants.PRICING_DIGITAL_TYPE);
        }else if(this.mapPricingOptions.size() == 1){
            this.createPricingOptions(Constants.PRICING_DIGITAL_TYPE);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin (Tquila)
    Date - 04/08/2015
    Version - 1.0
    Function - creates a list of upgrade options
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createUpgradeOptions(){
        if(this.lstUpgradeOptions == null){
            this.upgradeOptionsDependencies();
            this.lstUpgradeOptions = new List<Upgrade_Option__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstUpgradeOptions.add(TestDataUtility.newUpgradeOptions(i, this.mapPricingOptions.get(0)[i].Id, this.mapPricingOptions.get(1)[i].Id));
            }
            insert this.lstUpgradeOptions;
        }
    }

    //Upgrade_History_Item__c
    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 03/12/2015
    Version - 1.0
    Function - return Upgrade_History_Item__c record
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Upgrade_History_Item__c newUpgradeHistoryItem(Id accountId, Id pricingFromId, Id pricingToId, String status) {
        return new Upgrade_History_Item__c(
            Account__c = accountId,
            Pricing_Option_From__c = pricingFromId,
            Pricing_Option_To__c = pricingToId,
            Status__c = status
        );
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 03/12/2015
    Version - 1.0
    Function - check Upgrade_History_Item__c dependecies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void upgradeHistoryItemDependencies(){
        if(this.lstAccounts == null){
            this.createAccount();
        }
        if(this.mapPricingOptions == null){
            this.createPricingOptions(Constants.PRICING_WEBPACK_TYPE);
            this.createPricingOptions(Constants.PRICING_DIGITAL_TYPE);
        }else if(this.mapPricingOptions.size() == 1){
            this.createPricingOptions(Constants.PRICING_DIGITAL_TYPE);
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 03/12/2015
    Version - 1.0
    Function - insert Upgrade_History_Item__c record
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createUpgradeHistoryItems(){
        if(this.lstUpgradeHistoryItems == null){
            this.upgradeHistoryItemDependencies();
            this.lstUpgradeHistoryItems = new List<Upgrade_History_Item__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstUpgradeHistoryItems.add(TestDataUtility.newUpgradeHistoryItem(this.lstAccounts[i].Id, this.mapPricingOptions.get(0)[i].Id, this.mapPricingOptions.get(1)[i].Id,Constants.UPGRADE_IN_PROGRESS));
            }
            insert this.lstUpgradeHistoryItems;
        }
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 08/12/2015
    Version - 1.0
    Function - return Account record
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Kwika    1.1         16/02/2015
    ****************************************************************************************/
    public static Account newAccount(String lastname, String email) {
        return new Account(
            Title__c='Mr.',
            LastName = lastname,
            PersonEmail = email
        );
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 08/12/2015
    Version - 1.1
    Function - insert Account record
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   20/03/2017  //added increase of account uniqueness factor
    ****************************************************************************************/
    public void createAccount() {
        if(this.lstAccounts == null){
            this.lstAccounts = new List<Account>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstAccounts.add(TestDataUtility.newAccount('LastName','test_'+TestDataUtility.iAccountEmailDifferentiator+'_'+i+'@telegraph.co.uk'));
            }
            insert this.lstAccounts;
            TestDataUtility.increaseUniquenessDifferentiator();
      }
    }

    //CANCELLATION
    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 26/08/2015
    Version - 1.0
    Function - inserts Cancellations__c records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Cancellation__c newCancellations(Id accountId, Id mppTransactionId, String cancellationType){
        Cancellation__c cnx = new Cancellation__c(
            Account__c = accountId,
            Cancellation_Type__c = cancellationType,
            Cancelled_By__c = UserInfo.getUserId(),
            Cancelled_Date__c = Date.today(),
            MPP_Transaction_History__c = mppTransactionId,
            Cancellation_Reason__c = 'Price',
            Reason_Details__c = 'Other',
            Other_Reason__c = 'Other Reason',
            Cancellation_Status__c = Constants.COMPLETE_CANCELLATION_STATUS);

        return cnx;
    }

    /***************************************************************************************
    Developer - Cristina Anghenie (Accenture)
    Date - 26/08/2015
    Version - 1.0
    Function - inserts Cancellations__c dependecies
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkCancellationDependencies(){
        if(this.lstDigitalSubscribers == null){
            this.createDigitalSubscribers();
        }
        if(this.lstMPPTransactionHistory == null){
            this.createDigitalMPPTransactionHistory('CC');
        }
    }

  /***************************************************************************************
  Developer - Cristina Anghenie (Accenture)
  Date - 26/08/2015
  Version - 1.0
  Function - create Cancellations__c records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createCancellation(){
    if(this.lstCancellations == null){
      this.checkCancellationDependencies();
      this.lstCancellations = new List<Cancellation__c>();

      for(Integer i = 0; i<this.iCounter; i++){
        this.lstCancellations.add(TestDataUtility.newCancellations(this.lstDigitalSubscribers[i].Id, this.lstMPPTransactionHistory[i].Id, 'Soft Cancel'));
      }
      insert this.lstCancellations;
    }
  }

  /***************************************************************************************
  Developer - Cristina Anghenie (Accenture)
  Date - 09/09/2015
  Version - 1.0
  Function - inserts SubManagementDefaults__c records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static SubManagementDefaults__c newSubManagement(String defaultValue, String idName){
    SubManagementDefaults__c submgm = new SubManagementDefaults__c(
      Name = String.ValueOf(Math.round(Math.random() * 7)),
      DefaultValue__c = defaultValue,
      Id__c = idName);

    return submgm;
  }

  //CASES
  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 20/01/2016
  Version - 1.0
  Function - return Case record
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Case newCase(Integer i) {
    return new Case(
      Status = Constants.CASE_STATUS_NEW,
      Subject = 'Subject ' + i
    );
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 20/01/2016
  Version - 1.0
  Function - insert Case record
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createCase() {
    if(this.lstCases == null){
      this.lstCases = new List<Case>();
      for(Integer i = 0; i<this.iCounter; i++){
        this.lstCases.add(TestDataUtility.newCase(i));
      }
      insert this.lstCases;
    }
  }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 18/07/2016
    Version - 1.1
    Function - return Outbound Calling related Case record
    #############Change Log#############
    Modified by   Version     Change Date
    Wiktor Czykin 1.1         14/12/2016
    ****************************************************************************************/
    public static Case newOCCase(Id recTypeId, String callStage, DateTime scheduledCallback) {
        return new Case(
            Status = Constants.CASE_STATUS_NEW,
            Subject = 'OC Subject ',
            RecordTypeId = recTypeId,
            OC_Outcome__c = 'Test outcome',
            OC_Call_Stage__c = callStage,
            OC_Scheduled_Callback__c = scheduledCallback,
            OC_Batch_Updated_Date__c = Date.today().addDays(-1)
        );
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 08/08/2016
    Version - 1.1
    Function - return Outbound Calling related Case record with default oc stage values
    #############Change Log#############
    Modified by  Version     Change Date
    Wiktor Czykin 1.1         14/12/2016
    ****************************************************************************************/
    public static Case newOCCase(Id recTypeId, String callStage, String subscriptionId, String subscriberId) {
        return new Case(
            Status = Constants.OC_DEFAULT_OUTCOME,
            Subject = 'OC Test',
            RecordTypeId = recTypeId,
            OC_Call_Stage__c = callStage,
            OC_Batch_Updated_Date__c = Date.today().addDays(-1),
            OC_Stage_1_Outcome__c = Constants.OC_DEFAULT_OUTCOME,
            OC_Stage_1_Call_Date_Time__c = Datetime.now(),
            OC_Stage_2_Outcome__c = Constants.OC_DEFAULT_OUTCOME,
            OC_Stage_2_Call_Date_Time__c = Datetime.now(),
            OC_Stage_3_Outcome__c = Constants.OC_DEFAULT_OUTCOME,
            OC_Stage_3_Call_Date_Time__c = Datetime.now(),
            OC_Stage_4_Outcome__c = Constants.OC_DEFAULT_OUTCOME,
            OC_Stage_4_Call_Date_Time__c = Datetime.now(),
            Print_Subscription__c = subscriptionId,
            AccountId = subscriberId
        );
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas  
    Date - 08/08/2016
    Version - 1.0
    Function - insert Outbound Call Case records
    #############Change Log#############
    * Modified by         Version   Change Date
    * Mantas Grigaliunas    1.1     19/08/2016  //renamed constant OC_CALL_STAGE_T2_28DAYS to OC_CALL_STAGE_T2
    ****************************************************************************************/
    public void createOCCases(String recTypeName) {

        if(this.lstCases == null){
            this.lstCases = new List<Case>();
            String recTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, recTypeName, Case.class.getName());
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstCases.add(TestDataUtility.newOCCase(
                    recTypeId, 
                    Constants.OC_CALL_STAGE_T2, 
                    lstSubscriptions[i].Id,
                    lstIndividualSubscribers[i].Id)
                );
            }
            insert this.lstCases;
        }
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas  
    Date - 12/08/2016
    Version - 1.0
    Function - insert case related comments
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public void createCaseComments(Integer numberOfCommentsPerCase) {

        if(this.lstCases != null){
            if(this.lstCaseComments == null){
                this.lstCaseComments = new List<CaseComment>();
            }
            for(Case c : lstCases){

                for(Integer i = 0; i<numberOfCommentsPerCase; i++){
                    this.lstCaseComments.add(TestDataUtility.newCaseComment(c.Id));
                }
            }
            insert this.lstCaseComments;
        }
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas  
    Date - 12/08/2016
    Version - 1.0
    Function - returns CaseComment record related to case
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public static CaseComment newCaseComment(String parentId) {
         return new CaseComment(ParentId = parentId, CommentBody = 'Test comment');
    }

  //OTHER
  /***************************************************************************************
  Developer - Wiktor Czykin (Tquila)
  Date - 17/02/2015
  Version - 1.0
  Function - checks if message of particular content exists in lst of apex page messages
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Boolean checkIfMessageExists(List<ApexPages.Message> lstMsg, String sToCheck){
    Boolean bResult = false;
    for(ApexPages.Message msg : lstMsg){
      if(msg.getSummary().contains(sToCheck)){
        bResult = true;
        break;
      }
    }
    return bResult;
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 26/05/2016
  Version - 1.0
  Function - checks if error message exists on a set of results
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Boolean checkIfErrorExists(List<Database.Error> errors, String errorToCheck){
    Boolean hasCorrectErrorMessage = false;
    for(Database.Error error : errors){
      if(error.getMessage() == errorToCheck){
        hasCorrectErrorMessage = true;
        break;
      }
    }
    return hasCorrectErrorMessage;
  }

  /***************************************************************************************
  Developer - Pawel Chrzanowski
  Date - 29/04/2016
  Version - 1.0
  Function - create Default Subscription Plan custom setting
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createDefaultSubscriptionPlanSettings(Id planId){
    General__c defaultPlan = new General__c(Name=Constants.DEFAULT_SUBSCRIPTION_PLAN, Value__c=planId);
    insert defaultPlan;
  }

  /***************************************************************************************
  Developer - Michal Kwika (Accenture)
  Date - 05/08/2015
  Version - 1.0
  Function - creating Hosting Payment Page Settings based on payment method
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createHostedPaymentPageSettings(String paymentMethodType){
    zqu__HostedPageLiteSetting__c zuoraHostedPageSetting = new zqu__HostedPageLiteSetting__c();

        zuoraHostedPageSetting.Name = 'TestPaymentMethodType';
        zuoraHostedPageSetting.zqu__PageId__c = 'zuoraID1234567890';
        zuoraHostedPageSetting.zqu__PaymentMethodType__c = paymentMethodType;
        zuoraHostedPageSetting.zqu__ComponentName__c = 'PaymentPage';

        insert zuoraHostedPageSetting;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 30/10/2015
    Version - 1.0
    Function - creating Test Quote Creation Failure custom setting
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createTestQuoteCreationFailureCS(Boolean isSet){
        String isTrueValueOfTestQuoteCreation = String.valueOf(isSet);
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.TEST_QUOTE_CREATION_FAILURE_CUSTOM_SETTING,Value__c=isTrueValueOfTestQuoteCreation);
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 25/11/2015
    Version - 1.0
    Function - creating SAM Known User blocker setting
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createSAMknownUserConversionCS(Boolean isSet){
        String isEnabled = String.valueOf(isSet);
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.FIRE_CORE_API_CALL_FOR_SAM_KNOWN_USER_CONVERSION,Value__c=isEnabled);
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 25/01/2016
    Version - 1.0
    Function - creating Gateway Response custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
     public void createGatewayResponseWithShortDescription(String source, String code, String description){

        GeatewayReasonCodes__c gtwayResponseSettingObj=new GeatewayReasonCodes__c(Name = source+'-'+code, Reason_Code__c = code, Source__c = source, Short_Description__c = description);
        insert gtwayResponseSettingObj;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        27/01/2016
    Function    this function creates Custom setting for the profile searching in SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/

    public void createCoreApiSamUserGetProfileSetting(){
        Application_Settings__c applicationSettingObj=new Application_Settings__c(name=Constants.CORE_API_SAM_USER_GET_PROFILE_BY_ID,Value__c='Testing');
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 03/02/2016
    Version - 1.0
    Function - creating Core API Double Encoding Custom Setting
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createCoreAPIdoubleEncodingCS(Boolean isSet){
        String isDoubleEnc = String.valueOf(isSet);
        Application_Settings__c applicationSettingObj=new Application_Settings__c(Name=Constants.CORE_API_SAM_DOUBLE_ENCODING,Value__c=isDoubleEnc);
        insert applicationSettingObj;
    }

    /***************************************************************************************
    Developer - Michal Kwika (Accenture)
    Date - 03/02/2016
    Version - 1.0
    Function - creating Refund record (using zuoraAccountId - creating in loop not suported)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Zuora__Refund__c newRefundRecordForPaymentIssueDD(String gatewayResponseWithCode, String reasonOfRefund, String zuoraAccountId){
        Zuora__Refund__c ref = new Zuora__Refund__c();
        //set values
        ref.Zuora__Type__c = Constants.ZUORA_REFUND_TYPE_EXTERNAL;
        ref.Zuora__RefundMethodType__c = Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE;
        ref.Zuora__ReasonCodeName__c = reasonOfRefund;
        ref.Zuora__BillingAccount__c = zuoraAccountId;
        ref.Zuora__GatewayResponseCode__c = gatewayResponseWithCode;
        ref.Zuora__Amount__c = 100;

        return ref;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/03/2016
    Version - 1.0
    Function - text EmailTemplate creation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static EmailTemplate newTextEmailTemplate(Id folderId, String sName){
        String sNameToUse = sName;
        if(String.isBlank(sName)) sNameToUse = 'somename';

        return new EmailTemplate (  Name = sNameToUse,
                                    DeveloperName = sNameToUse,
                                    FolderId = folderId,
                                    TemplateType= 'Text',
                                    IsActive = true);
    }

  /**
  * Author:       Gavin Palmer (Accenture)
  * Date:         27/04/2016
  * Description:  retuns an instance of a plan record
  *
  * ******************* Change Log *******************
  * Modified by       Change Date     Description
  **/
  public static Price_Plan_Offer__c newPricePlanOffer(Integer i, Id pricePlanId, Boolean isDefaultOffer){
    return new Price_Plan_Offer__c(
      Offer_Code__c = 'code' + String.valueOf(i),
      Offer_Friendly_Name__c = 'friendlyName' + String.valueOf(i),
      Price_Plan__c = pricePlanId,
      Default_Offer__c = isDefaultOffer
    );
  }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         27/2016
    * Description:  Creates and inserts a number of default price plan offers
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    public void createPricePlanDefaultOffers(Integer pricePlanOfferPerICount){
        if(this.mapPricePlanDefaultOffer == null){

            this.checkPricePlanOfferDependencies();
            this.mapPricePlanDefaultOffer = new Map<Id,List<Price_Plan_Offer__c>>();
            List<Price_Plan_Offer__c> pricePlanOffersToInsert = new List<Price_Plan_Offer__c>();

      for(Integer i = 0; i < this.iCounter; i++){
        List<Price_Plan_Offer__c> pricePlanOffersForMap = new List<Price_Plan_Offer__c>();
        for(Integer j = 0; j < pricePlanOfferPerICount; j++){
          pricePlanOffersForMap.add(TestDataUtility.newPricePlanOffer(i, this.lstPricePlans[i].Id, true));
        }
        this.mapPricePlanDefaultOffer.put(this.lstPricePlans[i].Id, pricePlanOffersForMap);
        pricePlanOffersToInsert.addAll(pricePlanOffersForMap);
      }
      insert pricePlanOffersToInsert;
    }
  }

    /**
  * Author:       Gavin Palmer (Accenture)
  * Date:         28/04/2016
  * Description:  Check there is a parent price plan if not create them
  *
  * ******************* Change Log *******************
  * Modified by       Change Date     Description
  **/
  public void checkPricePlanOfferDependencies(){
    if(this.lstPricePlans == null){
      this.createPricePlans();
    }
  }

  /**
  * Author:       Gavin Palmer (Accenture)
  * Date:         27/2016
  * Description:  Creates and inserts a number of non default price plan offers
  *
  * ******************* Change Log *******************
  * Modified by       Change Date     Description
  **/
  public void createPricePlanOffers(Integer pricePlanOfferPerICount){
    if(this.mapPricePlanOffer == null){

            this.checkPricePlanOfferDependencies();
            this.mapPricePlanOffer = new Map<Id,List<Price_Plan_Offer__c>>();
            List<Price_Plan_Offer__c> pricePlanOffersToInsert = new List<Price_Plan_Offer__c>();

      for(Integer i = 0; i < this.iCounter; i++){
        List<Price_Plan_Offer__c> pricePlanOffersForMap = new List<Price_Plan_Offer__c>();
        for(Integer j = 0; j < pricePlanOfferPerICount; j++){
          pricePlanOffersForMap.add(TestDataUtility.newPricePlanOffer(i, this.lstPricePlans[i].Id, false));
        }
        this.mapPricePlanOffer.put(this.lstPricePlans[i].Id, pricePlanOffersForMap);
        pricePlanOffersToInsert.addAll(pricePlanOffersForMap);
      }
      insert pricePlanOffersToInsert;
    }
  }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         27/04//2016
    * Description:  return a subscription plan upload with a given status
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    public static Subscription_Plan_Upload__c newSubscriptionPlanUpload(String status) {
        return new Subscription_Plan_Upload__c( Status__c = status );
    }

    /**
    * Author:       Gavin Palmer (Accenture)
    * Date:         27/04/2016
    * Description:  insert some subscription plan upload records
    *
    * ******************* Change Log *******************
    * Modified by       Change Date     Description
    **/
    public void createSubscriptionPlanUpload(String status) {
        if(this.subscriptionPlanUploads == null){
            this.subscriptionPlanUploads = new List<Subscription_Plan_Upload__c>();
        }
        for(Integer i = 0; i < this.iCounter; i++){
            this.subscriptionPlanUploads.add(TestDataUtility.newSubscriptionPlanUpload(status));
        }
        upsert this.subscriptionPlanUploads;
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/05/2016
  Version - 1.0
  Function - create product price records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Product_Price__c newProductPrice(Id productId, String type, Decimal price){
    return new Product_Price__c(
      Price__c = price,
      Pricing_Type__c = type,
      Valid__c = true,
      Product__c = productId
    );
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/05/2016
  Version - 1.0
  Function - create product price records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void checkProductPriceDependencies(){
    if(this.lstZproducts == null){
      createZProduct();
    }
  }

  /***************************************************************************************
  Developer - Gavin Palmer
  Date - 27/05/2016
  Version - 1.0
  Function - create and insert product price records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createProductPrice(){
    if(this.lstProductPrice == null){
      this.checkProductPriceDependencies();
      this.lstProductPrice = new List<Product_Price__c>();

      for(Integer i = 0; i < this.iCounter; i++){
        for(Decimal price : TEST_PRODUCT_PRICES){

          // add in renewal and aquisition types for each product using various prices used throughout testdata util
          this.lstProductPrice.add(TestDataUtility.newProductPrice(
            this.lstZproducts[i].id,
            Constants.PRODUCT_PRICE_AQUISITION,
            price
          ));
          this.lstProductPrice.add(TestDataUtility.newProductPrice(
            this.lstZproducts[i].id,
            Constants.PRODUCT_PRICE_RENEWAL,
            price
          ));
        }
      }
      insert this.lstProductPrice;
    }
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 08/07/2016
  Version - 1.0
  Function - create Outbound Call Setting Batch
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Outbound_Call_Batch_Setting__c newOutboundCallBatchSetting(String className,Id outboundCallSetting){
    return new Outbound_Call_Batch_Setting__c(
      Batch_Class_Name__c = className,
      Outbound_Call_Setting__c = outboundCallSetting,
      Cron_String__c = '0 0 0 3 9 ? 2022',
      Active__c = true
    );
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 08/07/2016
  Version - 1.0
  Function - create Outbound Call Setting
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static Outbound_Call_Setting__c newOutboundCallSetting(String queueName){
    return new Outbound_Call_Setting__c(
      Default_Queue_Name__c = queueName,
      Visualforce_Page__c = 'Test',
      Active__c = true
    );
  }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 18/07/2016
  Version - 1.0
  Function - create Outbound Call Setting
  #############Change Log#############
  Modified by  Version     Change Date
  ****************************************************************************************/
  public static Outbound_Call_Setting__c newOutboundCallSetting(String caseRecTypeName, String vfPageName, String parameters){

      return new Outbound_Call_Setting__c(
          Case_Record_Type__c = caseRecTypeName,
          Visualforce_Page__c = vfPageName,
          Parameters__c = parameters,
          Active__c = true,
          Available_In_Tab__c = 'Outbound_Calling_New',
          Case_Field_Map__c = '{"Subject":"Reason","OC_Call_Stage__c":"Type_Of_Issue__c","OC_Outcome__c":"Digital_Details__c","OC_No_Sale_Reason__c":"Digital_Details_2__c"}'
      );
  }

  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 08/07/2016
  Version - 1.0
  Function - create list of Outbound Call Setting records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createOutboundCallSetting(){
    
    if(this.lstOutboundCallSetting == null){
      this.lstOutboundCallSetting = new List<Outbound_Call_Setting__c>();
      for(Integer i = 0; i<this.iCounter; i++){
        this.lstOutboundCallSetting.add(TestDataUtility.newOutboundCallSetting(' QueueName' + i));
      }
      insert this.lstOutboundCallSetting;
    }
  }


  /***************************************************************************************
  Developer - Michal Szewczyk
  Date - 08/07/2016
  Version - 1.0
  Function - create list of Outbound Call Setting Batch records
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createOutboundCallBatchSetting(String className){

    if(this.lstOutboundCallSetting == null){
      createOutboundCallSetting();
    }

    if(this.lstOutboundCallBatchSetting == null){
      this.lstOutboundCallBatchSetting = new List<Outbound_Call_Batch_Setting__c>();
      for(Integer i = 0; i<this.iCounter; i++){
        this.lstOutboundCallBatchSetting.add(TestDataUtility.newOutboundCallBatchSetting(className,this.lstOutboundCallSetting[i].Id));
      }
      insert this.lstOutboundCallBatchSetting;
    }
  }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/07/2016
    Version - 1.0
    Function - create Outbound Call Setting Rule
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Outbound_Call_Rule__c newOutboundCallRule(Id outboundCallSettingId){
        return new Outbound_Call_Rule__c(
            Outbound_Call_Setting__c = outboundCallSettingId, 
            Name = 'test rule', 
            Call_Answered__c = 60, 
            Call_Busy__c = 30, 
            Call_No_Answer__c = 40,
            Call_Record_Entry__c = 50,
            Active__c = true
        );
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/07/2016
    Version - 1.0
    Function - create list of Outbound Call Rule records
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public void createOutboundCallRule(){
        if(this.lstOutboundCallSetting == null){
            createOutboundCallSetting();
        }

        if(this.lstOutboundCallRule == null){
            this.lstOutboundCallRule = new List<Outbound_Call_Rule__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstOutboundCallRule.add(TestDataUtility.newOutboundCallRule(this.lstOutboundCallSetting[i].Id));
            }
            insert this.lstOutboundCallRule;
        }
    }
  
    /************************************************************************************
    Method Name  : createOutboundCallSalesStageMappingSettings
    Author       : Mantas Grigaliunas
    Created Date : 18/07/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas  19/08/2016  //added No Sale Reason field to the parameters
    *************************************************************************************/ 
    public static void createOutboundCallStageMappingSettings(String recTypeName, String vfPageName, Integer paramsNumber){
        /**
        * @recTypeName - Record type label
        **/
        //set default JSON parameters for outbound call sales setting record
        List<OutboundCallingBean.CallStageMapping> defaultParams = new List<OutboundCallingBean.CallStageMapping>();
        List<String> stagePicklistValuesList = new List<String>(OutboundCallingUtils.getCallStagePicklistValues());
        for(Integer i = 1; i <= paramsNumber; i++){
          defaultParams.add(
                new OutboundCallingBean.CallStageMapping(
                    stagePicklistValuesList.get(i-1), 
                    'OC_Stage_' + i + '_Outcome__c', 
                    'OC_Stage_' + i + '_Call_Date_Time__c', 
                    'OC_Stage_' + i + '_No_Sale_Reason__c',
                    60, 
                    't' + (i-1)
                )
            );
        }

        OutboundCallingBean ocb = new OutboundCallingBean();
        ocb.callStageParameters = defaultParams;
        //create sales outbound call setting record
        insert TestDataUtility.newOutboundCallSetting(recTypeName, vfPageName, System.JSON.serialize(ocb));
    }

  /************************************************************************************
    Method Name  : defineOutboundCallStageMappingSettings
    Author       : Mantas Grigaliunas
    Created Date : 08/08/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer           Date        Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas  19/08/2016  //modified tcode parameter to get the correct record, starting with 0 not 1
    * Mantas Grigaliunas  19/08/2016  //added No Sale Reason field to the parameters
    *************************************************************************************/ 
    public static String defineOutboundCallStageMappingSettings(Integer paramsNumber){
        /**
        * @recTypeName - Record type label
        **/
        //set default JSON parameters for outbound call sales setting record
        List<OutboundCallingBean.CallStageMapping> defaultParams = new List<OutboundCallingBean.CallStageMapping>();
        List<String> stagePicklistValuesList = new List<String>(OutboundCallingUtils.getCallStagePicklistValues());
        for(Integer i = 1; i <= paramsNumber; i++){
          defaultParams.add(
                new OutboundCallingBean.CallStageMapping(
                    stagePicklistValuesList.get(i-1), 
                    'OC_Stage_' + i + '_Outcome__c', 
                    'OC_Stage_' + i + '_Call_Date_Time__c',
                    'OC_Stage_' + i + '_No_Sale_Reason__c', 
                    60, 
                    't' + (i-1)
                )
            );
        }

        OutboundCallingBean ocb = new OutboundCallingBean();
        ocb.callStageParameters = defaultParams;
        return System.JSON.serialize(ocb);
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 08/08/2016
    Function - creates Outbound Call Setting and for Sales Renewal
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public void createSalesOutboundCallSetting(){

        if(this.lstOutboundCallSetting == null){
            this.lstOutboundCallSetting = new List<Outbound_Call_Setting__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstOutboundCallSetting.add(TestDataUtility.newOutboundCallSetting(
                        Constants.OC_SALES_RECORD_TYPE_NAME, 
                        Constants.OC_SALES_VF_PAGE_NAME,
                        defineOutboundCallStageMappingSettings(4)
                    )
                );
            }
            insert this.lstOutboundCallSetting;
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 15/05/2017
    Function - creates Outbound Call Setting based on recordTypeName and VF page name and parameters.
    #############Change Log#############
    Modified by  Version     Change Date
    ****************************************************************************************/
    public void createOCSetting(String recordTypeName, String vfPageName, String parameters){

        if(this.lstOutboundCallSetting == null){
            this.lstOutboundCallSetting = new List<Outbound_Call_Setting__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstOutboundCallSetting.add(TestDataUtility.newOutboundCallSetting(recordTypeName, vfPageName, parameters ) );
            }
            insert this.lstOutboundCallSetting;
        }
    }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 09/09/2016
  Version - 1.0
  Function - create and insert email messages related to the case
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public void createEmailMessage(Id caseId){
    if(this.lstEmailMessage == null){
      this.lstEmailMessage = new List<EmailMessage>();
    }

    for(Integer i = 0; i < this.iCounter; i++){
      this.lstEmailMessage.add(TestDataUtility.newEmailMessage(caseId, i, 'testFrom@email.com'));
    }

    insert this.lstEmailMessage;
  }

  /***************************************************************************************
  Developer - Mantas Grigaliunas
  Date - 09/09/2016
  Version - 1.0
  Function - create email message record
  #############Change Log#############
  Modified by  Version   Change Date
  ****************************************************************************************/
  public static EmailMessage newEmailMessage(Id caseId, Integer i, String fromAddress){
    return new EmailMessage(
      FromAddress = fromAddress,
      FromName = 'Test From',
      Incoming = (Math.mod(i, 2) == 0 ? true : false),
      ToAddress = 'testTo@email.com',
      ParentId = caseId,
      Subject = 'Test'
    );
  }

      /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 07/10/2016
    Version - 1.0
    Function - define Newsletter Configuration test record
    #############Change Log#############
    Modified by  Version   Change Date
    ****************************************************************************************/
    public static Newsletter_Configuration__c newNewsletterConfiguration(String recTypeId, String name){
        return new Newsletter_Configuration__c(
            Name = name,
            Active__c =  true,
            RecordTypeId = recTypeId
        );
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 07/10/2016
    Version - 1.0
    Function - insert Newsletter Configuration test data
    #############Change Log#############
    Modified by  Version   Change Date
    ****************************************************************************************/
    public void createNewsletterConfigurations(String recordTypeName){
        this.lstNewsletterConfiguration = new List<Newsletter_Configuration__c>();
        String recordTypeId = RecordTypeUtility.getRecordTypeId(
            Newsletter_Configuration__c.sObjectType, recordTypeName, Newsletter_Configuration__c.class.getName());

        for(Integer i = 0; i < this.iCounter; i++){
            this.lstNewsletterConfiguration.add(TestDataUtility.newNewsletterConfiguration(recordTypeId, recordTypeName+i));
        }
        insert this.lstNewsletterConfiguration;
    }

    /************************************************************************************
    Method Name  : updateThresholdValue
    Author       : Mantas Grigaliunas
    Created Date : 09/12/2016
    Function     : Updateds threshold custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static void updateThresholdValue(Decimal value){
        Configuration__c c = Configuration__c.getOrgDefaults();
        c.Voucher_Refund_Threshold_Amount__c = value;
        update c;
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 02/12/2016
    Version - 1.0
    Function - Create Custom Settings for My Newsletters EndPoints
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createMyNewslettersEndPointSettings(){
        Application_Settings__c appSetting;

        appSetting = Application_Settings__c.getInstance(Constants.MY_NEWSLETTER_ENDPOINT);
        if(appSetting == null){
            insert new Application_Settings__c(Name = Constants.MY_NEWSLETTER_ENDPOINT, Value__c = 'Testing');
        }
        appSetting = Application_Settings__c.getInstance(Constants.IDENTITY_TOKEN_ENDPOINT);
        if(appSetting == null){
            insert new Application_Settings__c(Name = Constants.IDENTITY_TOKEN_ENDPOINT, Value__c = 'Testing');
        }
    }

    public MidTermUpgradeProduct__c createMidTermUpgradeProduct(Id zProductId, Id upgradeProductId){
        return new MidTermUpgradeProduct__c(ZProduct__c=zProductId, UpgradeProduct__c = upgradeProductId);
    }
  
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/03/2017
    Function - Offer instance creation method
    #############Change Log#############
    Modified by           Change Date
    Wiktor Czykin         06/07/2017  //added 2 new fields
    ****************************************************************************************/
    public static Offer__c newOffer(Integer i, Id productId){
        return new Offer__c(
            Name = 'offer-name-a'+i,
            Base_Price__c = 1,
            Frequency__c = Constants.OFFER_FREQUENCY_MONTHLY,
            Friendly_Name__c = 'someFriendlyName'+i,
            Description__c = 'someValue'+i,
            Name__c = '12'+i,
            ZProduct__c = productId,
            Initial_Term__c = 12,
            Initial_Term_Type__c = Constants.OFFER_FREQUENCY_MONTH,
            Renewal_Term__c = 12,
            Renewal_Term_Type__c = Constants.OFFER_FREQUENCY_MONTH,
            Item_Description__c = 'someString'+i,
            Initial_Price__c = 1
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/03/2017
    Version - 1.0
    Function - Offer dependencies check
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkOfferDependencies(){
        if(this.lstZproducts == null){
            this.createZProduct();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/03/2017
    Version - 1.0
    Function - Offer creation method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createOffers(){
        if(this.lstOffers == null){
            this.checkOfferDependencies();
            this.lstOffers = new List<Offer__c>();
            for(Integer i = 0; i < iCounter; i++){
                this.lstOffers.add(TestDataUtility.newOffer(i, this.lstZproducts[i].Id));  
            }
            insert this.lstOffers;
        }
    }

    /***************************************************************************************
    Developer - Vishant Shah
    Date - 30/03/2017
    Version - 1.0
    Function - create Custom Settings for Marketing Preferences
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createMarketingPrefSettings(){
        Application_Settings__c appSetting = Application_Settings__c.getInstance(Constants.PROFILES_FOR_MARKETING_PREFERENCES);
        if(appSetting == null) {
            User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = : UserInfo.getUserId() ];
            insert new Application_Settings__c(Name = Constants.PROFILES_FOR_MARKETING_PREFERENCES, Value__c = currentUser.Profile.Name);
        }
    }

    //PRODUCT RATE PLAN
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/03/2017
    Version - 1.0
    Function - Product Rate Plan instance creation method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static zqu__ProductRatePlan__c newProductRatePlan(Integer i, Id productId, String sName, String sDefaultOfferName){
        Date today = Date.today();
        zqu__ProductRatePlan__c prp = new zqu__ProductRatePlan__c(  zqu__Description__c = 'some description' +i,
                                                                    zqu__EffectiveStartDate__c = today,
                                                                    zqu__EffectiveEndDate__c = today.addYears(1),
                                                                    zqu__ZProduct__c= productId,
                                                                    Name = 'someName '+i,
                                                                    zqu__ZuoraId__c = 'zid'+i,
                                                                    DefaultOfferCode__c = sDefaultOfferName
                                                                  );
        if(String.isNotBlank(sName)){
            prp.Name = sName;
        }
        return prp;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/03/2017
    Version - 1.0
    Function - Product Rate Plan dependency check
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void checkProductRatePlanDependencies(){
        if(this.lstZproducts == null){
            this.createZProduct();
        }
        if(this.lstOffers == null){
            this.createOffers();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 23/03/2017
    Version - 1.0
    Function - Product Rate Plan list creation method 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void createProductRatePlans(){
        if(this.lstProductRatePlans == null){
            this.lstProductRatePlans = new List<zqu__ProductRatePlan__c>();
            this.checkProductRatePlanDependencies();
            Map<String, Offers_Frequency_Rate_Plan_Map__mdt> mapRatePlanSettings = GlobalQueries.retrieveFrequencySetting();
            this.iProductRatePlanFrequencyMultiplier = mapRatePlanSettings.size();
            if(mapRatePlanSettings != null && !mapRatePlanSettings.isEmpty()){
                Integer y = 1000;
                for(Integer i = 0; i<this.iCounter; i++){
                    for(Offers_Frequency_Rate_Plan_Map__mdt rpm : mapRatePlanSettings.values()){
                        if(String.isNotBlank(rpm.Target_Rate_Plan_Name__c)){
                            this.lstProductRatePlans.add(TestDataUtility.newProductRatePlan(i+y, this.lstZproducts[i].Id, rpm.Target_Rate_Plan_Name__c, this.lstOffers[i].Name));
                            y++;
                        }
                    }
                }
                insert this.lstProductRatePlans;
            }
        } 
    }
    
    //ZUORA PRODUCT
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - returns new instance of Zuora_Product__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public static Zuora__Product__c newZuoraProduct(Integer i){
        return new Zuora__Product__c(   Name = Constants.ZUORA_TEST_STRING, 
                                        Zuora__External_Id__c = '11111111' + i);
    }

    /***************************************************************************************
    Developer - Mantas Grigaliunas
    Date - 03/05/2017
    Function - insert zuora product records. NOTE - NOT zqu_ZProduct__c.
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   25/05/2017  //modified to use "new" method
    ****************************************************************************************/
    public void createZuoraProducts(){
        if(this.lstZuoraProducts == null){
            this.lstZuoraProducts = new List<Zuora__Product__c>();
            for(Integer i = 0; i < this.iCounter; i++){
                this.lstZuoraProducts.add(TestDataUtility.newZuoraProduct(i));
            }
            insert this.lstZuoraProducts;
        }
    }

   /***************************************************************************************
      Method Name  : createRetentionOutboundCallSetting
      Author       : Konrad Czykin
      Created Date : 08/05/2017
      Function     : creates Outbound Call Setting and for Sales Renewal
    ****************************************************************************************/
    public void createRetentionOutboundCallSetting(){

        if(this.lstOutboundCallSetting == null){
            this.lstOutboundCallSetting = new List<Outbound_Call_Setting__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstOutboundCallSetting.add(TestDataUtility.newRetentionOutboundCallSetting(
                        Constants.OC_RETENTION_RECORD_TYPE_NAME, 
                        Constants.OC_RETENTION_VF_PAGE_NAME,
                        defineRetentionOutboundCallStageMappingSettings(1)
                    )
                );
            }
            insert this.lstOutboundCallSetting;
        }
    }

  /************************************************************************************
    Method Name  : defineOutboundCallStageMappingSettings
    Author       : Konrad Czykin
    Created Date : 08/05/2017
    Function     : creates Outbound Call Setting parameters
  *************************************************************************************/ 
    public static String defineRetentionOutboundCallStageMappingSettings(Integer paramsNumber){
        /**
        * @recTypeName - Record type label
        **/
        //set default JSON parameters for outbound call sales setting record
        List<OutboundCallingBean.CallStageMapping> defaultParams = new List<OutboundCallingBean.CallStageMapping>();
        List<String> stagePicklistValuesList = new List<String>(OutboundCallingUtils.getCallStagePicklistValues());
        for(Integer i = 1; i <= paramsNumber; i++){
          defaultParams.add(
                new OutboundCallingBean.CallStageMapping(
                    'Retention',    
                    'Retention_Outcome__c', 
                    'Retention_Call_Date_Time__c',
                    '', 
                    0, 
                    ''
                )
            );
        }

        OutboundCallingBean ocb = new OutboundCallingBean();
        ocb.callStageParameters = defaultParams;
        return System.JSON.serialize(ocb);
    }

  /***************************************************************************************
    Method Name  : newRetentionOutboundCallSetting
    Author       : Konrad Czykin
    Created Date : 08/05/2017
    Function     : create Outbound Call Setting
  ****************************************************************************************/
  public static Outbound_Call_Setting__c newRetentionOutboundCallSetting(String caseRecTypeName, String vfPageName, String parameters){

      return new Outbound_Call_Setting__c(

          Case_Record_Type__c = caseRecTypeName,
          Visualforce_Page__c = vfPageName,
          Parameters__c = parameters,
          Order__c = 2,
          Name = 'Outbound Calling Retention',
          Menu_Name__c = 'Retention Calling',
          Active__c = true
      );
  }

    /***************************************************************************************
      Method Name  : createRetCases
      Author       : Konrad Czykin
      Created Date : 08/05/2017
      Function     : insert Outbound Call Case records
    ****************************************************************************************/
    public void createRetCases(String recTypeName) {

        if(this.lstCases == null){
            this.lstCases = new List<Case>();
            String recTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, recTypeName, Case.class.getName());
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstCases.add(TestDataUtility.newOCRetCase(
                    recTypeId, 
                    Constants.OC_RETENTION_STAGE, 
                    lstSubscriptions[i].Id,
                    lstIndividualSubscribers[i].Id)
                );
            }
            system.debug(this.lstCases);
            insert this.lstCases;
        }
    }

   /***************************************************************************************
      Method Name  : newOCRetCase
      Author       : Konrad Czykin
      Created Date : 08/05/2017
      Function     : return Outbound Calling related Case record with default oc stage values
    ****************************************************************************************/
    public static Case newOCRetCase(Id recTypeId, String callStage, String subscriptionId, String subscriberId) {
        return new Case(
            Status = Constants.OC_DEFAULT_OUTCOME,
            Subject = 'OC Test',
            RecordTypeId = recTypeId,
            OC_Call_Stage__c = callStage,
            OC_Batch_Updated_Date__c = Date.today().addDays(-1),
            Retention_Outcome__c = Constants.OC_DEFAULT_OUTCOME,
            Retention_Call_Date_Time__c = Datetime.now(),
            Print_Subscription__c = subscriptionId,
            AccountId = subscriberId
        );
    }

    /***************************************************************************************
      Method Name  : ewRetentionOutboundCallRule
      Author       : Konrad Czykin
      Created Date : 08/05/2017
      Function     : create Outbound Call Setting Rule
    ****************************************************************************************/
    public static Outbound_Call_Rule__c newRetentionOutboundCallRule(Id outboundCallSettingId){
        return new Outbound_Call_Rule__c(
            Outbound_Call_Setting__c = outboundCallSettingId, 
            Name = 'test rule', 
            Priority_Field__c = 'Retention_Priority__c',
            Call_Answered__c = 60, 
            Call_Busy__c = 30, 
            Call_No_Answer__c = 40,
            Call_Record_Entry__c = 50,
            Active__c = true
        );
    }

    /***************************************************************************************
      Method Name  : createRetentionOutboundCallRule
      Author       : Konrad Czykin
      Created Date : 08/05/2017
      Function     : create list of Outbound Call Rule records
    ****************************************************************************************/
    public void createRetentionOutboundCallRule(){
        if(this.lstOutboundCallSetting == null){
            createRetentionOutboundCallSetting();
        }

        if(this.lstOutboundCallRule == null){
            this.lstOutboundCallRule = new List<Outbound_Call_Rule__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstOutboundCallRule.add(TestDataUtility.newRetentionOutboundCallRule(this.lstOutboundCallSetting[i].Id));
            }
            insert this.lstOutboundCallRule;
        }
    }
    
    public List<Custom_Validation__c> createCustomValidationRules(){
      List<Custom_Validation__c> customvalidations = Test.loadData(Custom_Validation__c.sObjectType, 'CustomValidationRule');
      return customvalidations;
    }
    

    //QUOTE AMENDMENT
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - returns new instance of zqu__QuoteAmendment__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public static zqu__QuoteAmendment__c newQuoteAmendment(Integer i, Id quoteId){
        return new zqu__QuoteAmendment__c(
                                            zqu__Quote__c = quoteId,
                                            zqu__Type__c = Constants.RATE_PLAN_NEW_PRODUCT_AMENDMENT_TYPE,
                                            zqu__Description__c = 'test '+i,
                                            zqu__TotalAmount__c = 1 
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - check dependencies for creation of zqu__QuoteAmendment__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void checkQuoteAmendmentDependencies(){
        if(this.lstZQuotes == null){
            this.createZquotes();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - method that creates and populates list with zqu__QuoteAmendment__c records
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void createQuoteAmendments(){
        if(this.lstQuoteAmendments == null){
            this.checkQuoteAmendmentDependencies();
            this.lstQuoteAmendments = new List<zqu__QuoteAmendment__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstQuoteAmendments.add(TestDataUtility.newQuoteAmendment(i, this.lstZQuotes[i].Id));
            }
            insert this.lstQuoteAmendments;
        }
    }

    //QUOTE RATE PLAN
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - returns new instance of zqu__QuoteRatePlan__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public static zqu__QuoteRatePlan__c newQuoteRatePlan(Integer i, Id qouteId, Id quoteAmendmentId, Id productRatePlanId, String sProductName){
        return new zqu__QuoteRatePlan__c(
                zqu__Quote__c = qouteId,
                zqu__QuoteAmendment__c = quoteAmendmentId,
                zqu__AmendmentType__c = Constants.RATE_PLAN_NEW_PRODUCT_AMENDMENT_TYPE,
                zqu__ProductRatePlan__c = productRatePlanId,
                zqu__QuoteProductName__c = sProductName
            );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - check dependencies for creation of zqu__QuoteRatePlan__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void checkQuoteRatePlanDependencies(){
        if(this.lstQuoteAmendments == null){
            this.createQuoteAmendments();
        }
        if(this.lstProductRatePlans == null){
            this.createProductRatePlans();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - method that creates and populates list with zqu__QuoteRatePlan__c records
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void createQuoteRatePlans(){
        if(this.lstQuoteRatePlans == null){
            this.lstQuoteRatePlans = new List<zqu__QuoteRatePlan__c>();
            this.checkQuoteRatePlanDependencies();
            for(Integer i = 0; i < this.iCounter; i++){
                this.lstQuoteRatePlans.add(TestDataUtility.newQuoteRatePlan(i, this.lstZQuotes[i].Id, this.lstQuoteAmendments[i].Id, this.lstProductRatePlans[i*iProductRatePlanFrequencyMultiplier].Id, this.lstZProducts[i].Name));
            }
            insert this.lstQuoteRatePlans;
        }
    }

    //PRODUCT RATE PLAN CHARGE
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - returns new instance of zqu__ProductRatePlanCharge__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public static zqu__ProductRatePlanCharge__c newProductRatePlanCharge(Integer i, Id productRatePlanId, String sName, String sRecurringPeriod){
        zqu__ProductRatePlanCharge__c prpc =  new zqu__ProductRatePlanCharge__c(
                                                                                Name = 'prpc'+i,
                                                                                zqu__ProductRatePlan__c = productRatePlanId,
                                                                                zqu__DefaultQuantity__c = 1,
                                                                                zqu__Apply_Discount_To_Recurring_Charges__c = true,
                                                                                zqu__Apply_Discount_To_One_Time_Charges__c = false,
                                                                                zqu__Apply_Discount_To_Usage_Charges__c = false,
                                                                                zqu__Discount_Level__c='Subscription',
                                                                                zqu__Model__c = Constants.OFFER_SEARCH_FLAT_FEE_RATE_PLAN_CHARGE,
                                                                                zqu__Type__c = Constants.OFFER_SEARCH_RECURRING_RATE_PLAN_CHARGE,
                                                                                zqu__ZuoraId__c = 'ratePlanChargeZId'+i,
                                                                                zqu__RecurringPeriod__c = Constants.OFFER_FREQUENCY_MONTH
        );
        if(String.isNotBlank(sName)){
            prpc.Name = sName;
        }

        if(String.isNotBlank(sRecurringPeriod)){
            prpc.zqu__RecurringPeriod__c = sRecurringPeriod;
        }
        return prpc;        
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - check dependencies for creation of zqu__ProductRatePlanCharge__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void checkProductRatePlanChargeDependencies(){
        if(this.lstProductRatePlans == null){
            this.createProductRatePlans();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - method that creates and populates list with zqu__ProductRatePlanCharge__c records
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void createProductRatePlanCharges(){
        if(this.lstProductRatePlanCharges == null){
            this.lstProductRatePlanCharges = new List<zqu__ProductRatePlanCharge__c>();
            this.checkProductRatePlanChargeDependencies();

            Map<String, Offers_Frequency_Rate_Plan_Map__mdt> mapSettings = GlobalQueries.mapRatePlanOffersFrequencyMap;
            Boolean bMapFrequency = false;
            if(mapSettings != null && !mapSettings.isEmpty()){
                bMapFrequency = true;
            }
            Offers_Frequency_Rate_Plan_Map__mdt setting;
            Integer iMax = this.iCounter*this.iProductRatePlanFrequencyMultiplier;
            for(Integer i = 0; i < iMax; i++){
                if(bMapFrequency){
                    setting = mapSettings.get(this.lstProductRatePlans[i].Name);
                }
                this.lstProductRatePlanCharges.add(TestDataUtility.newProductRatePlanCharge(i, 
                                                                                            this.lstProductRatePlans[i].Id, 
                                                                                            this.lstProductRatePlans[i].Name, 
                                                                                            (setting!=null?setting.API_Frequency__c:null) 
                                                                                            )
                                                    );      
            }
            insert this.lstProductRatePlanCharges;
        }
    }

    //QUOTE RATE PLAN CHARGE
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - returns new instance of zqu__QuoteRatePlanCharge__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public static zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge(Integer i, Id qouteRatePlanId, zqu__ProductRatePlanCharge__c prpc){
        zqu__QuoteRatePlanCharge__c qrpc = new zqu__QuoteRatePlanCharge__c( zqu__QuoteRatePlan__c = qouteRatePlanId,
                                                                            Name = prpc.Name,
                                                                            zqu__ProductRatePlanCharge__c = prpc.Id,
                                                                            zqu__ChargeType__c = prpc.zqu__Type__c,
                                                                            zqu__EffectivePrice__c = 10,
                                                                            zqu__Quantity__c = 1,
                                                                            zqu__QuoteRatePlanChargeZuoraId__c = prpc.zqu__ZuoraId__c,
                                                                            zqu__Period__c = prpc.zqu__RecurringPeriod__c,
                                                                            zqu__Model__c = prpc.zqu__Model__c
        );
        return qrpc;
    }  

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - check dependencies for creation of zqu__QuoteRatePlanCharge__c 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void checkQouteRatePlanChargeDependencies(){
        if(this.lstProductRatePlanCharges  == null){
            this.createProductRatePlanCharges();
        }
        if(this.lstQuoteRatePlans == null){
            this.createQuoteRatePlans();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2017
    Function - method that creates and populates list with zqu__QuoteRatePlanCharge__c records
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void createQuoteRatePlanCharges(){
        if(this.lstQuoteRatePlanCharges == null){
            this.lstQuoteRatePlanCharges = new List<zqu__QuoteRatePlanCharge__c>();
            this.checkQouteRatePlanChargeDependencies();
            for(Integer i= 0; i<this.iCounter; i++){
                this.lstQuoteRatePlanCharges.add(TestDataUtility.newQuoteRatePlanCharge(i, this.lstQuoteRatePlans[i].Id, this.lstProductRatePlanCharges[i*iProductRatePlanFrequencyMultiplier]));
            }
            insert this.lstQuoteRatePlanCharges;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 31/05/2017
    Function - returns new instance of zqu__QuoteCharge__c - minimalistic as not really used
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public static zqu__QuoteCharge__c newQuoteCharge(Integer i, Id quoteId, Id productRatePlanChargeId){
        return new zqu__QuoteCharge__c( zqu__ProductRatePlanCharge__c = productRatePlanChargeId,
                                        zqu__Quote__c = quoteId

        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 31/05/2017
    Function - checks dependencies for zqu__QuoteCharge__c reocrds creation
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void checkQuoteChargeDependencies(){
        if(this.lstZQuotes == null){
            this.createZquotes();
        }
        if(this.lstProductRatePlanCharges == null){
            this.createProductRatePlanCharges();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 31/05/2017
    Function - creates zqu__QuoteCharge__c records in a list
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void createQuoteCharges(){
        if(this.lstQuoteCharges == null){
            this.lstQuoteCharges = new List<zqu__QuoteCharge__c>();
            this.checkQuoteChargeDependencies();
            for(Integer i = 0; i < this.iCounter; i++){
                this.lstQuoteCharges.add(TestDataUtility.newQuoteCharge(i, this.lstZQuotes[0].Id, this.lstProductRatePlanCharges[i*iProductRatePlanFrequencyMultiplier].Id));
            }
            insert this.lstQuoteCharges;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - create home delivery voucher record instance
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    public static Home_Delivery_Voucher__c newHomeDeliveryVoucher(Integer i, Id recordTypeId, Account acc){
      Id rtId = recordTypeId;
      if(rtId == null){
        rtId = RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName());
      }

      return new Home_Delivery_Voucher__c(
          RecordTypeId = rtId,
          First_Name__c = 'firstName'+i,
          Last_Name__c = 'lastName'+i,
          Mailing_Address__c = 'mystreet'+i,
          Mailing_Town__c = 'London',
          Mailing_County__c = 'tmgshire',
          Mailing_Postal_Code__c ='sw1w 0dt',
          Email__c = acc.PersonEmail,
          Account__c = acc.Id,
          Subscriber_Number__c = 'someId'+i,
          Phone__c = '213123123123'+i,
          Retailer_Id__c = '2131231'+i,
          Retailer_Name__c = 'retailer xyz'+i,
          Retailer_Phone__c = '2313213123',
          Retailer_Address__c = 'someStreet'+i,
          Retailer_Town__c = 'London'
      );  
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - check required items to create home delivery voucher records
    #############Change Log#############
    Modified by     Change Date  
    Wiktor Czykin   10/07/2017  //changed registrant to individual subscriber
    ****************************************************************************************/
    public void checkHomeDeliveryVouchersDependencies(){
        if(this.lstIndividualSubscribers == null){
          this.createIndividualSubscribers();
        }
        if(this.lstRetailers == null){
          this.createRetailers();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - create home delivery voucher record
    #############Change Log#############
    Modified by     Change Date  
    Wiktor Czykin   10/07/2017  //changed account reference to individual subscriber
    ****************************************************************************************/
    public void createHomeDeliveryVouchers(Id recordTypeId){
        if(this.lstHomeDeliveryVouchers == null){
            this.checkHomeDeliveryVouchersDependencies();
            this.lstHomeDeliveryVouchers = new List<Home_Delivery_Voucher__c>();
            for(Integer i = 0; i<this.iCounter; i++){
                this.lstHomeDeliveryVouchers.add(TestDataUtility.newHomeDeliveryVoucher(i, recordTypeId, this.lstIndividualSubscribers[i]));
            }
            insert this.lstHomeDeliveryVouchers;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - create home delivery settings records (only 2 based on record types)
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    public Map<String, Home_Delivery_Settings__c> createHomeDeliverySettings(){
        if(this.lstHomeDeliverySettings == null){
            if(this.lstZProductFeature == null){
              this.createZProductFeatures();
            }
            this.lstHomeDeliverySettings = new List<Home_Delivery_Settings__c>{
                new Home_Delivery_Settings__c(  Name = Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME,
                                                Offer_Name__c = 'on' + Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME,
                                                Offer_Description__c = 'od' + Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME,
                                                Supported_Product_Ids__c = this.lstZProducts[0].Id
                ),
                new Home_Delivery_Settings__c(  Name = Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME,
                                                Offer_Name__c = 'on' + Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME,
                                                Offer_Description__c = 'od' + Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME,
                                                Supported_Product_Ids__c = this.lstZProducts[0].Id
                )
            };
            insert this.lstHomeDeliverySettings;
        }
        Map<String, Home_Delivery_Settings__c> mapSettings = new Map<String, Home_Delivery_Settings__c>();
        for(Home_Delivery_Settings__c hds : this.lstHomeDeliverySettings){
            mapSettings.put(hds.Name, hds);
        }

        return mapSettings;
    }
}