/**
Name:    GlobalQueries
* @author Wiktor Czykin
* @date    02/09/2015
* @description Class that helps in SOQL querying
#############Change Log#############
Modified by        Change Date
Wiktor Czykin      02/11/2015 //added checkIsEmailUnique();
Wiktor Czykin      02/12/2015 //added getVATRateForCountry();
Michal Kwika       10/02/2016 //added getTCodeNameWithDescriptionBasedOnName()
Michal Szewczyk    14/03/2016 //added Payment_Type__c to getTCodeBasedOnName() and remove old checkboxes
Michal Kwika       15/03/2016 //added getTcodeProducts()
Michal Szewczyk    04/04/2016 //changes in getPricingOptions()
Wiktor Czykin      20/04/2016 //simplified  getTcodeProducts(), added getTCodeProduct()
Wiktor Czykin      10/05/2016 //modified getTcodeProducts()
Wiktor Czykin      26/05/2016 //modified getProductTcodeIncentives();
Lynette Lim        07/07/2016 //Pricing Options retrieval to work with Digital and Webpack Products for online POC
Wiktor Czykin      30/08/2016 //modified getTcodeProducts()
Wiktor Czykin      18/10/2016 //modified getTcodeProducts()
Wiktor Czykin      25/10/2016 //added overloaded version of getProductTcodeIncentives()
Wiktor Czykin      28/10/2016 //modified getTcodeProducts()
Vishant Shah       04/01/2017 //added LeadDays__c
Wiktor Czykin      03/03/2017 //modified getProductTCodeIncentive(), getTCodeProducts(), getTCodeProduct()
Wiktor Czykin      17/05/2017 //added Offers_Frequency_Rate_Plan_Map__mdt support methods, moved few method here from outside
*/
public with sharing class GlobalQueries {

    public static Map<String, Map<String, Schema.DescribeFieldResult>> mapObjectNameToFieldsDescribe = new Map<String, Map<String, Schema.DescribeFieldResult>>();
    public static Map<String, Map<String, Schema.SObjectField>> mapObjectNameToFieldsData = new Map<String, Map<String, Schema.SObjectField>>();
    public static Map<String, Map<String, Schema.FieldSet>> mapObjectNameToFieldSetsData = new Map<String, Map<String, Schema.FieldSet>>();
    public static Map<String, Offers_Frequency_Rate_Plan_Map__mdt> mapOffersFrequencyRatePlanMap;
    public static Map<String, Offers_Frequency_Rate_Plan_Map__mdt> mapRatePlanOffersFrequencyMap;

    private static final Id TCODEPRODUCT_OFFER_TYPE_ID = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
    private static final Id TCODEPRODUCT_ZOFFER_TYPE_ID = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_ZOFFER, TCode_Product__c.class.getName());

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/09/2015
    Version - 1.0
    Function - Function that returns all fields for a passed object as comma-separated string
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String generateFieldsListForQuery(String sObjectName, Set<String> setExtraFields, Set<String> setExcludeFields){
        if(sObjectName == null || sObjectName == ''){
            return null;
        }
        if(setExcludeFields == null){
            setExcludeFields = new Set<String>();
        }

        String sQueryFields = '';
        Set <String> setFields = GlobalQueries.getFieldsForObject(sObjectName);
        if(setFields!= null && !setFields.isEmpty()){
                for(String sField : setFields){
                    if(!setExcludeFields.contains(sField.toLowerCase())){
                    sQueryFields += sField+',';
                }
            }
            if(setExtraFields != null && !setExtraFields.isEmpty()){
                for(String sField : setExtraFields){
                    if(!setFields.contains(sField.toLowerCase())){
                        sQueryFields += sField+',';
                    }
                }
            }
            sQueryFields = sQueryFields.substring(0, sQueryFields.length()-1);
            return sQueryFields;
        }
        return null;
    }

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        27/08/2015
    Function    this function is called to build the query string for an object to simulate select * and add where clause, orber by and limit
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       11/05/2017  //moved here from SoqlUtility    
    ****************************************************************************************/
    public static string queryBuilderSelectAll(String objectName, Set<String> setRelatedObjectFields, String whereClause, String orderClause, String limitValue){
        String query = 'SELECT';
        query += ' ' + generateFieldsListForQuery(objectName, setRelatedObjectFields, null);
        // Add FROM statement
        query += ' FROM ' + objectName;
        // Add on a WHERE clause
        if(!String.isEmpty(whereClause)){
            query += ' WHERE '+whereClause; 
        }
        //add order by
        if(!String.isEmpty(orderClause)){
            query += ' ORDER BY '+orderClause;
        }
        //add limit
        if(!String.isEmpty(LimitValue)){
            query += ' Limit '+limitValue;
        }
        return query;
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 27/05/2016
    Version - 1.0
    Function -  get the query string based on a field set
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getQueryFromFieldSet(FieldSet fieldSet, Set<String> additionalFields, String subQuery, String whereClause, Integer limitNumber){

        if(fieldSet == null) return null;

        String query = 'SELECT ';

        for(Schema.FieldSetMember field : fieldSet.getFields()) {
            query += field.getFieldPath() + ', ';
        }

        if(additionalFields != null){
            for(String field : additionalFields){
                query += field + ', ';
            }
        }

        // how to make the sObject into a child sObject?
        if(String.isNotBlank(subQuery)){
            query += '(' + subQuery + ')';
        } else {
            query = query.left(query.lastIndexOf(','));
        }

        query += ' FROM ' + fieldSet.getSobjectType().getDescribe().getName();

        if(String.isNotBlank(whereClause)){
            query += ' WHERE ' + whereClause;
        }

        if(limitNumber != null || limitNumber > 0){
            query += ' LIMIT ' + String.valueOf(limitNumber);
        }

        return query;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/09/2015
    Version - 1.0
    Function - Function that retrieves object's fields Name-> DescribeFieldsResults map
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Map<String,Schema.DescribeFieldResult> getFieldsNameToMetaDescriptionMappingForObject(String sObjectName){
        if(sObjectName!=null && sObjectName!=''){
            if(!GlobalQueries.mapObjectNameToFieldsData.containsKey(sObjectName) ||  GlobalQueries.mapObjectNameToFieldsData.get(sObjectName) == null){
                Map<String, Schema.SObjectType> globalObjectList = Schema.getGlobalDescribe();
                GlobalQueries.mapObjectNameToFieldsData.put(sObjectName, globalObjectList.get(sObjectName).getDescribe().fields.getMap());
            }
            if(!GlobalQueries.mapObjectNameToFieldsDescribe.containsKey(sObjectName) || GlobalQueries.mapObjectNameToFieldsDescribe.get(sObjectName) == null){
                Map<String, Schema.DescribeFieldResult> mapFieldsNameToDescribeResult = new Map <String, Schema.DescribeFieldResult>();
                for (Schema.SObjectField field : GlobalQueries.mapObjectNameToFieldsData.get(sObjectName).values()){
                    Schema.DescribeFieldResult description = field.getDescribe();
                    mapFieldsNameToDescribeResult.put(description.getName(), description);
                }
                GlobalQueries.mapObjectNameToFieldsDescribe.put(sObjectName, mapFieldsNameToDescribeResult);
            }

            return GlobalQueries.mapObjectNameToFieldsDescribe.get(sObjectName);
        }else{
            return null;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/09/2015
    Version - 1.0
    Function - Function that retrieves object's fields Name -> SOBjectField tokens map
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Set<String> getFieldsForObject(String sObjectName){
        if(!GlobalQueries.mapObjectNameToFieldsData.containsKey(sObjectName)){
            Map<String, Schema.SObjectType> mapAll = Schema.getGlobalDescribe();
            if(!mapAll.containsKey(sObjectName)){
                return null;
            }
            GlobalQueries.mapObjectNameToFieldsData.put(sObjectName, mapAll.get(sObjectName).getDescribe().fields.getMap());
        }
        return GlobalQueries.mapObjectNameToFieldsData.get(sObjectName).keySet();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 08/09/2015
    Version - 1.1
    Function - retrieves pricing option record based on flow type, subscription type, product type and Tcode
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/08/2015  //simplified
    Wiktor Czykin    1.2            08/09/2015    //moved here from SubscriptionsWebservicesHandlers as used from multiple places within app
    Michal Szewczyk 1.3         04/04/2016  // change SOQL to use new data model
    Lynette Lim     1.4         06/05/2016  //Pricing Options retrieval to work with Digital and Webpack Products for online POC
    ****************************************************************************************/
    public static Pricing_Options__c getPricingOptions(String  productId, String  sFlowType, String sSubscriptionType, String sTCode){
        if (String.isNotBlank(sTCode) && String.isNotBlank(productId) && String.isNotBlank(sFlowType) && String.isNotBlank(sSubscriptionType)){

            sSubscriptionType = (sSubscriptionType == Constants.SUBSCRIPTIONTYPE_CONTINUOUS ? Constants.SUBSCRIPTIONTYPE_52CONTINUOUS : sSubscriptionType);
            List<Pricing_Options__c> lstPricingOptions;
            if (productId=='digital' || productId=='webpack') {
                lstPricingOptions = [select    Id,
                                                                    Name,
                                                                    ServiceId__c,
                                                                    ServicePriceId__c,
                                                                    Dynamic_Price__c,
                                                                    Flow_Type__c,
                                                                    Subscription_Type__c,
                                                                    Multi_User_Discount_Voucher__c,
                                                                    Payment_Required__c,
                                                                    Package_Name__c,
                                                                    Product_Type__c,
                                                                    imageURL__c,
                                                                    TCodemanagement__r.Name,
                                                                    Show_Cancel_Button__c,
                                                                    Display_Expiry_Date__c,
                                                                    tandcURL__c
                                                                from Pricing_Options__c
                                                                where Product_Type__c =: productId
                                                                and Subscription_Type__c  =: sSubscriptionType
                                                                and Flow_Type__c =: sFlowType
                                                                and TCode_Product__r.TCodeManagement__r.Name =: sTCode
                                                                limit 1];
            } else {
                lstPricingOptions = [select    Id,
                                                                    Name,
                                                                    ServiceId__c,
                                                                    ServicePriceId__c,
                                                                    Dynamic_Price__c,
                                                                    Flow_Type__c,
                                                                    Subscription_Type__c,
                                                                    Multi_User_Discount_Voucher__c,
                                                                    Payment_Required__c,
                                                                    Package_Name__c,
                                                                    Product_Type__c,
                                                                    imageURL__c,
                                                                    TCodemanagement__r.Name,
                                                                    Show_Cancel_Button__c,
                                                                    Display_Expiry_Date__c,
                                                                    tandcURL__c
                                                                from Pricing_Options__c
                                                                where TCode_Product__r.Product__c =: productId
                                                                and Subscription_Type__c  =: sSubscriptionType
                                                                and Flow_Type__c =: sFlowType
                                                                and TCode_Product__r.TCodeManagement__r.Name =: sTCode
                                                                limit 1];
            }
            if(!lstPricingOptions.isEmpty()) return lstPricingOptions[0];
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 14/09/2015
    Version - 1.0
    Function - retrieve custom settings set Pricing Option based on digital subscription type
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Pricing_Options__c getDigitalPricingOptionBasedOnSetting(String sSubscriptionType){
        if(String.isBlank(sSubscriptionType)) return null;

        General__c pricingOptionConfig;
        Pricing_Options__c po;
        if(sSubscriptionType == Constants.SUBSCRIPTIONTYPE_YEARLY){
            pricingOptionConfig = General__c.getInstance(Constants.GENERAL_DIGITAL_YEARLY_PRICINGOPTION);
        }else if(sSubscriptionType == Constants.SUBSCRIPTIONTYPE_MONTHLY){
            pricingOptionConfig = General__c.getInstance(Constants.GENERAL_DIGITAL_MONTHLY_PRICINGOPTION);
        }
        if(pricingOptionConfig != null && String.isNotBlank(pricingOptionConfig.Value__c)){
            try{
                List<Pricing_Options__c> lstOption = [select     Id,
                                                                ServiceId__c,
                                                                ServicePriceId__c
                                                              from Pricing_Options__c
                                                              where Id = :pricingOptionConfig.Value__c
                                                              limit 1];
                if(lstOption.isEmpty()) throw new TelegraphApplicationException(pricingOptionConfig.Value__c+' could not be found in Pricing Options');
                po = lstOption[0];
            }catch(Exception e){
                System.debug('Pricing Option couldn not be fetched:'+e.getMessage());
            }
        }
        return po;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/09/2015
    Version - 1.0
    Function - retrieve active TCode based on TCode name
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         // added Payment_Type__c and remove old checkboxes
    ****************************************************************************************/
    public static List<TCodeManagement__c> getTCodeBasedOnName(String sTCodeName){
        if(String.isEmpty(sTCodeName)) return new List<TCodemanagement__c>();
        return [select  Id,
                        Name,
                        Special_Data__c,
                        Special_Data_Text__c,
                        AllowCCA__c,
                        X13_week_price__c,
                        AllowContinuous__c,
                        AllowDD__c,
                        Digital_Monthly_Price__c,
                        Digital_Yearly_Price__c,
                        Price__c,
                        OptionalIncentive__c,
                        Is_13_Continuous__c,
                        Is_26_Continuous__c,
                        Is_52_Continuous__c,
                        Low_Start_Weekly_Price__c,
                        Low_Start_Period__c,
                        Type__c,
                        Exclude_Digital_Type_For_Flow__c,
                        Payment_Type__c
                    from TCodeManagement__c
                    where Name = :sTCodeName
                    and Valid__c=true];
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 02/11/2015
    Version - 1.0
    Function - Simple soql based uniqueness check. Might no longer be usefull after implementation of email uniqueness on object level.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Boolean checkIsEmailUnique(Id currentRecordId, String sEmail){
        if(currentRecordId == null) throw new TelegraphApplicationException('Check email uniqueness method call error. Missing parameters.');
        if(String.isBlank(sEmail)) return true;

        List<Account> lstDuplicate = [select Id, Name from Account where PersonEmail = :sEmail and Id != :currentRecordId];
        if(lstDuplicate.isEmpty()) return true;
        return false;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/11/2015
    Version - 1.0
    Function - Common method to fetch country respective vat rate
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Decimal getVATRateForCountry(VAT__c vatSettings, Country_Codes__c countryCodeSettings){
        Decimal vat = null;
        if(vatSettings == null || countryCodeSettings == null || vatSettings.UK_Standard_VAT_Rate__c == null || vatSettings.EU_Standard_VAT_Rate__c == null) return vat;

        if(countryCodeSettings.Name == Constants.COUNTRY_CODE_GB){
            vat = vatSettings.UK_Standard_VAT_Rate__c;
        }else if(countryCodeSettings.EU__c){
            vat = vatSettings.EU_Standard_VAT_Rate__c;
        }else{
            vat = 0;
        }
        return vat;
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - 10/02/2016
    Version - 1.0
    Function - retrieve TCode Name with Description (as a String)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getTCodeNameWithDescriptionBasedOnName(String sTCodeName){
        String tcodeNameWithDescription = '';
        if(String.isEmpty(sTCodeName)){
            return tcodeNameWithDescription;
        }
        List<TCodemanagement__c> lTCodes = [SELECT Description__c FROM TCodemanagement__c WHERE Name =:sTCodeName LIMIT 1];

        if(lTCodes.size()>0){
            tcodeNameWithDescription = sTCodeName + ' (' +lTCodes.get(0).Description__c +')';
        }
        return tcodeNameWithDescription;
    }
    
    /***************************************************************************************
    Developer - Sally ElGhoul
    Date - 22/03/2016
    Version - 1.1
    Function - Get the incentive for a certain product and a certain tcode using the product tcode incentives
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         26/05/2016     //fix for null pointer
    ****************************************************************************************/
    public static List<TCode_Product_Incentive__c> getProductTcodeIncentives(Id tcodeProductId){
        if(tcodeProductId != null){
            List<TCode_Product__c> lstTcodeProduct = [select id, (select Incentive__c,Incentive_Name__c,
                                                                         Incentive_Description__c,Is_Incentive_Valid_For_Renewal__c
                                                                         from TCode_Product_Incentives__r
                                                                         where Incentive_Validity_Status__c=true)
                                                        from TCode_Product__c
                                                        where id=:tcodeProductId];

            if(!lstTcodeProduct.isEmpty() && !lstTcodeProduct[0].TCode_Product_Incentives__r.isEmpty()){
                return lstTcodeProduct[0].TCode_Product_Incentives__r;
            }
        }
        return new List<TCode_Product_Incentive__c>();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/10/2016
    Version - 1.1
    Function - Get the incentive for a certain product and a certain tcode using the individual ids
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/03/2017  //added filter for Offer record type
    ****************************************************************************************/
    public static List<TCode_Product_Incentive__c> getProductTcodeIncentives(Id tcodeId, Id productId){
        if(tcodeId != null && productId != null){
            List<TCode_Product__c> lstTcodeProduct = [select Id, (select    Incentive__c,
                                                                            Incentive_Name__c,
                                                                            Incentive_Description__c,
                                                                            Is_Incentive_Valid_For_Renewal__c
                                                                        from TCode_Product_Incentives__r
                                                                        where Incentive_Validity_Status__c=true)
                                                        from TCode_Product__c
                                                        where TCodeManagement__c = :tcodeId 
                                                        and Product__c = :productId
                                                        and RecordTypeId = :TCODEPRODUCT_OFFER_TYPE_ID
                                                        ];
            if(!lstTcodeProduct.isEmpty() && !lstTcodeProduct[0].TCode_Product_Incentives__r.isEmpty()){
                return lstTcodeProduct[0].TCode_Product_Incentives__r;
            }
        }
        return new List<TCode_Product_Incentive__c>();
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - 04/04/2016
    Version - 1.0
    Function - retrieve TCode Name only based on tcodeId
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getTCodeNameBasedOnId(Id sTCodeId){
        if(String.isBlank(sTCodeId)){
            return null;
        }
        List<TCodemanagement__c> lTCodes = [SELECT Name FROM TCodemanagement__c WHERE Id =:sTCodeId LIMIT 1];

        if(lTCodes.size()>0){
            return lTCodes[0].Name;
        }
        return '';
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - 15/03/2016
    Version - 1.6
    Function -  get all TcodeProducts based on tCodeId and flag PrintProduct
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         20/04/2016  //simplified
    Wiktor Czykin   1.2         10/05/2016  //added extra fields to SOQL
    Wiktor Czykin   1.3         30/08/2016  //added Voucher_Delivery_Type__c
    Wiktor Czykin   1.4         18/10/2016  //added Rank to soql
    Wiktor Czykin   1.5         28/10/2016  //added status fields for incentives
    Wiktor Czykin   1.6         02/03/2017  //added filter for Offer record type
    ****************************************************************************************/
    public static List<TCode_Product__c> getTcodeProducts(Id tCodeId, Boolean isPrintProduct){
        if(tCodeId == null || tCodeId.getSobjectType() != TCodeManagement__c.SObjectType || isPrintProduct == null) return null;

        return [select  Id,
                        Weekly_Price__c,
                        X13_Week_Price__c,
                        Low_Start_Price__c,
                        Product__c,
                        Product__r.Name,
                        Product__r.Print_Product__c,
                        Product__r.Voucher_Delivery_Type__c,
                        Digital_Yearly_Price__c,
                        Digital_Monthly_Price__c,
                        Product__r.Rank__c,
                        (select Id, Incentive_Validity_Status__c, Is_Incentive_Valid_For_Renewal__c, Incentive__r.Name from TCode_Product_Incentives__r)
                    from TCode_Product__c
                    where TCodeManagement__c = :tCodeId
                    and Product__r.Print_Product__c = :isPrintProduct
                    and RecordTypeId = :TCODEPRODUCT_OFFER_TYPE_ID
                    ];
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/04/2016
    Version - 1.0
    Function -  get all Zuora Offers TcodeProducts based on TCode type
    #############Change Log#############
    ****************************************************************************************/
    public static List<TCode_Product__c> getZuoraTcodeProductsBasedOnTCodeOfferType(String sOfferType, String sSoqlSuffix){
        if(String.isBlank(sOfferType)) return null;
        String sQuery = 'select   Id, Weekly_Price__c, X13_Week_Price__c, Low_Start_Price__c,'+
                                    'Product__c, Product__r.Name, '+
                                    'Offer__c, Offer__r.Name__c, Offer__r.Description__c, Offer__r.Name, Offer__r.Base_Price__c, Offer__r.Frequency__c, Offer__r.Weekly_Advertised_Price__c, Offer__r.Friendly_Name__c, Offer__r.Discount__c, Offer__r.Discount_Duration__c, '+
                                    'TCodeManagement__c, TCodeManagement__r.Name, TCodeManagement__r.Description__c,'+
                                    '(select Id, Incentive_Validity_Status__c, Incentive__r.Name, Auto_Assign_for_Zuora_Subscription__c from TCode_Product_Incentives__r) '+
                                ' from TCode_Product__c'+
                                ' where RecordTypeId = :TCODEPRODUCT_ZOFFER_TYPE_ID'+
                                ' and TCodeManagement__r.Valid__c = true'+
                                ' and TCodeManagement__r.Type__c = :sOfferType';
        if(String.isNotBlank(sSoqlSuffix)){
            sQuery += sSoqlSuffix;
        }
        return Database.query(sQuery);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 28/04/2016
    Version - 1.0
    Function -  get all Zuora Offers TcodeProducts based on TCode type
    #############Change Log#############
    ****************************************************************************************/
    public static Offer__c getOffer(Id offerId, String offerName){
        if(offerId == null && String.isBlank(offerName)){
            return null;
        }
        String sFields = generateFieldsListForQuery(Offer__c.class.getName(), null, new Set<String>{'Offer_Name_Uniqueness__c'});
        String sQuery = 'select '+sFields+' from Offer__c where ';
        List<Offer__c> lstOffers = new List<Offer__c>();
        if(offerId != null){
            lstOffers = Database.query(sQuery + ' Id = :offerId');
        }else if(String.isNotBlank(offerName)){
            lstOffers = Database.query(sQuery + ' Name = :offerName');
        }
        if(!lstOffers.isEmpty()){
            return lstOffers[0];
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/03/2016
    Version - 1.3
    Function -  get all TcodeProduct based on tCode id and product id
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         30/08/2016  //added Voucher_Delivery_Type__c
    Vishant Shah    1.2         04/01/2017  //added LeadDays__c
    Wiktor Czykin   1.3         02/03/2017  //added filter for Offer record type
    ****************************************************************************************/
    public static TCode_Product__c getTCodeProduct(Id tCodeId, Id productId){
        if(tCodeId == null || productId == null) return null;
        String sQueryFields =  generateFieldsListForQuery(    TCode_Product__c.class.getName(),
                                                                                new Set<String>{'Product__r.Print_Product__c',
                                                                                                'Product__r.Name',
                                                                                                'Product__r.Voucher_Delivery_Type__c',
                                                                                                'Product__r.LeadDays__c'},
                                                                                null);
        Id offerId = TCODEPRODUCT_OFFER_TYPE_ID;
        List<TCode_Product__c> lstTCodeProduct = Database.query('select '+sQueryFields+' from TCode_Product__c where Product__c =: productId and TCodeManagement__c =:tCodeId and RecordTypeId = :offerId');
        if(lstTCodeProduct.isEmpty()) return null;
        return lstTCodeProduct[0];
    }

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Accenture)
    Date        18/01/2016
    Function    This function is called to get the Open Offer Tcode Record
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.1         19/02/2016 get the tcode incentive product and subscription type fields
    Sally ElGhoul       1.2         19/02/2016 remove tcode object name hardcoding
    Wiktor Czykin       1.3         11/05/2017 moved here from Zuora_TcodeUtility
    ****************************************************************************************/
    public static TCodeManagement__c getOpenOfferTcode(){
        String tcodeSoql=GlobalQueries.queryBuilderSelectAll(TCodeManagement__c.class.getName(), null, 'Valid__c=true and Type__c=\''+Constants.TCODE_TYPE_OPENOFFER+'\'', null, '1');
        List<TCodeManagement__c> lstAvailableTcodes = Database.query(tcodeSoql);
        if(lstAvailableTcodes!=null && lstAvailableTcodes.size()>0){
            return lstAvailableTcodes[0];
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 28/02/2017
    Version - 1.0
    Function - Prepare mapping of frequency to product respective rate plan name for that frequency
    #############Change Log#############
    Modified by      Change Date
    Wiktor Czykin    16/05/2017 //moved here from OffersHandler
    ****************************************************************************************/
    public static Map<String, Offers_Frequency_Rate_Plan_Map__mdt> retrieveFrequencySetting(){
        if(mapOffersFrequencyRatePlanMap != null) return mapOffersFrequencyRatePlanMap;

        mapRatePlanOffersFrequencyMap = new Map<String, Offers_Frequency_Rate_Plan_Map__mdt>();
        mapOffersFrequencyRatePlanMap = new Map<String, Offers_Frequency_Rate_Plan_Map__mdt>();
        for(Offers_Frequency_Rate_Plan_Map__mdt offerFrequency : [select MasterLabel, Target_Rate_Plan_Name__c, API_Frequency__c from Offers_Frequency_Rate_Plan_Map__mdt where Active__c = true]){
            mapOffersFrequencyRatePlanMap.put(offerFrequency.MasterLabel, offerFrequency);
            mapRatePlanOffersFrequencyMap.put(offerFrequency.Target_Rate_Plan_Name__c, offerFrequency);
        }
        return mapOffersFrequencyRatePlanMap;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 16/05/2017
    Version - 1.0
    Function - retrieve offer frequency in its "for API" version
    #############Change Log#############
    Modified by      Change Date
    ****************************************************************************************/
    public static String replaceOfferFrequencyForApi(String sFrequency){
        if(String.isBlank(sFrequency)) return sFrequency;
        retrieveFrequencySetting();

        Offers_Frequency_Rate_Plan_Map__mdt mappingObject = mapOffersFrequencyRatePlanMap.get(sFrequency);
        if(mappingObject != null && String.isNotBlank(mappingObject.API_Frequency__c)){
            return mappingObject.API_Frequency__c;
        }
        return sFrequency;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 18/07/2017
    Version - 1.0
    Function - Returns picklist-ready list of Countries based on custom settings - moved here as to be used from multiple sources
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<SelectOption> getCountries(Boolean bWithNoneOption){
        List<SelectOption> liOptions = new List<SelectOption>();
        if(bWithNoneOption){
            liOptions.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
        }
        for(Country_Codes__c country:[SELECT Name, Country_Name__c FROM Country_Codes__c ORDER BY Display_Order__c, Country_Name__c ASC]){
            liOptions.add(new SelectOption(country.Name, country.Country_Name__c));
        }
        return liOptions;
    }
}