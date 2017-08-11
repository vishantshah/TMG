/**
* @author Wiktor Czykin
* @date Q1/2016
* @description Offer Selection Controller
* #############Change Log#############
* Modified by       Version     Date
* Michal Kwika      1.1         12/03/2016
* Wiktor Czykin     1.2         04/2016    //clean-up, made sure all offers actually work as they should, fixes for POCs behaviour
* Wiktor Czykin     1.3         11/05/2016 //made digital offer selection work - added differentiation for print product, added digital pricing, added filtering for digi offers
* Wiktor Czykin     1.4         16/05/2016 //modified searchMGM()
* Wiktor Czykin     1.5.        25/05/2016 //added getTCodesDetails()
* Gavin Palmer      1.6         15/06/2016 //added functionality to filter tCodes by product
* Pawel Chrzanowski 1.7         23/06/2016 //added email to account search
* Wiktor Czykin     1.8         09/09/2016 //added missing fields to product soqls
* Wiktor Czykin     1.9         18/10/2016 //modified getTCodesDetails() methods
* Wiktor Czykin     2.0         13/01/2016 //modified getIsFindAccountShowed() and constructor to prevent random null pointer
* Wiktor Czykin     2.1         03/03/2017 //modified TCode_Product__c queries to filter record type
**/
public with sharing class OfferSelectionController {

    private static String CONST_NONE = 'none';
    private static String CONST_BLOCK = 'block';
    @TestVisible private static final List<String> LIST_SUPPORTED_OFFERS = new List<String>{ Constants.OFFER_OPENOFFER,
                                                                                Constants.OFFER_ADHOCPRICE,
                                                                                Constants.OFFER_LOWSTART,
                                                                                Constants.OFFER_PROMOTION,
                                                                                Constants.OFFER_POC,
                                                                                Constants.OFFER_DIRECTMAIL,
                                                                                Constants.OFFER_MGM,
                                                                                Constants.OFFER_STAFF
    };
    @TestVisible private static final Set<String> SET_PREMIUM_ONLY_OFFERS = new Set<String>{    Constants.OFFER_ADHOCPRICE,
                                                                                                Constants.OFFER_LOWSTART,
                                                                                                Constants.OFFER_MGM,
                                                                                                Constants.OFFER_STAFF
    };
    @TestVisible private static final Map<String, String> MAP_OFFER_LABELS = new Map<String, String>{Constants.OFFER_OPENOFFER => Label.Offline_Acquisition_Offer_type_open_offer,
                                                                                        Constants.OFFER_ADHOCPRICE => Label.Offline_Acquisition_Offer_type_discount_price,
                                                                                        Constants.OFFER_LOWSTART => Label.Offline_Acquisition_Offer_type_low_start,
                                                                                        Constants.OFFER_PROMOTION => Label.Offline_Acquisition_Offer_type_promotion,
                                                                                        Constants.OFFER_POC => Label.Offline_Acquisition_Offer_type_direct_mail_POC_search,
                                                                                        Constants.OFFER_DIRECTMAIL => Label.Offline_Acquisition_Offer_type_direct_mail_customer_search,
                                                                                        Constants.OFFER_MGM => Label.Offline_Acquisition_Offer_type_member_get_member,
                                                                                        Constants.OFFER_STAFF => Label.Offline_Acquisition_Offer_type_staff_offer

    };
    @TestVisible private static final Set<String> SET_HIDE_ORDER_DETAILS = new Set<String>{  Constants.OFFER_POC,
                                                                                Constants.OFFER_DIRECTMAIL,
                                                                                Constants.OFFER_LOWSTART
    };
    @TestVisible private static final Set<String> SET_PROMOTION_OFFERS = new Set<String>{    Constants.OFFER_PROMOTION,
                                                                                Constants.OFFER_LOWSTART
    };
    @TestVisible private static final Set<String> SET_DO_NOT_LOAD_PRODUCTS_ON_INIT = new Set<String>{Constants.OFFER_PROMOTION,
                                                                                        Constants.OFFER_LOWSTART,
                                                                                        Constants.OFFER_POC,
                                                                                        Constants.OFFER_DIRECTMAIL,
                                                                                        Constants.OFFER_MGM,
                                                                                        Constants.OFFER_STAFF};
    public static final String YES = 'Yes';
    public static final String NO = 'No';

    @TestVisible private String sAdHocTCode{
        get{
            if(String.isBlank(this.sAdHocTCode)){
                General__c setting = General__c.getInstance(Constants.GENERAL_ADHOCPRICE_TCODE);
                if(setting != null && String.isNotBlank(setting.Value__c)){
                    this.sAdHocTCode = setting.Value__c;
                }else{
                    this.sAdHocTCode = Constants.TCODE_ADHOCPRICE_DEFAULT;
                }
            }
            return this.sAdHocTCode;
        }
        set;
    }

    public String inputTsNumber {get;set;}
    public String inputPOC {get;set;}
    public String inputEmail {get;set;}
    public String selectedFilter {get;set;}
    public Boolean filterSelected {get;set;}
    public Boolean selectSelected {get;set;}
    public Boolean renderCreateExistingAccountBtn{get; private set;}
    // MGM
    public MgmGiverInfoPrice mgmGiverInfo{get;set;}
    //POC
    public List<POC__c> returnedPOCsList{get;set;}
    public OfferSelectionData selectionData{get;set;}
    public List<SelectOption> lstOfferTypes{get;set;}
    public List<AccountWithProductTypeWrapper> lstFoundAccounts{get;set;}
    public Boolean bProductsSearched{get;set;}

    public OfferSelector offerSelector{get;
        set{
            if(value == null || value.offerSelection == null || String.isBlank(value.offerSelection.sSelectedProductType)){
                throw new TelegraphApplicationException('Component not initialized correctly. Missing data instance and/or product type selection.');
            }else if(this.lstOfferTypes == null){
                this.selectionData = value.offerSelection;
                this.lstOfferTypes = new List<SelectOption>();
                this.offerSelector = value;
                for(String sOffer : LIST_SUPPORTED_OFFERS){
                    if(value.offerSelection.sSelectedProductType != Constants.PRODUCT_PREMIUM && SET_PREMIUM_ONLY_OFFERS.contains(sOffer)) continue;
                    this.lstOfferTypes.add(new SelectOption(sOffer, MAP_OFFER_LABELS.get(sOffer)));
                }
            }
        }
    }

    public List<String> lstFilterOffers{get;
        set{
            if(this.lstOfferTypes != null){
                Set<String> setToExclude = new Set<String>();
                if(value != null){
                    setToExclude = new Set<String>(value);
                    for(Integer i = 0; i<this.lstOfferTypes.size(); i++){
                        if(setToExclude.contains(this.lstOfferTypes[i].getValue())){
                            this.lstOfferTypes.remove(i);
                            i--;
                        }
                    }
                }
            }
        }
    }

    public Boolean bIsLowStart{
        get{
            return this.selectionData != null && String.isNotBlank(this.selectionData.sSelectedOffer) && this.selectionData.sSelectedOffer == Constants.OFFER_LOWSTART;
        }
        set;
    }
    public List<TCodeWrapper> lstPromotionIncentives {get;set;}
    public List<TCodeProductWrapper> lstAvailableProducts {get;set;}
    private Map<Id, TCodeWrapper> promoMap {get; set;}

    public List<SelectOption> lstOrderMethodValues{
        get{
            if(this.lstOrderMethodValues != null) return lstOrderMethodValues;

            this.lstOrderMethodValues = new List<SelectOption>{
                new SelectOption(Constants.SUB_ORDER_METHOD_INBOUND, Constants.SUB_ORDER_METHOD_INBOUND),
                new SelectOption(Constants.ORDER_METHOD_COUPON, Constants.ORDER_METHOD_COUPON)
            };
            return this.lstOrderMethodValues;
        }
        set;
    }

    public List<SelectOption> lstFilterOptions{
        get{
            if(this.lstFilterOptions != null) return lstFilterOptions;
            this.lstFilterOptions = new List<SelectOption>{
                new SelectOption(YES, 'On'),
                new SelectOption(NO, 'Off')
            };
            return this.lstFilterOptions;
        }
        set;
    }
    private String sTCodeProductQuery = 'select Id,'+
                                                'Product__c, ' +
                                                'Product__r.Name, ' +
                                                'TCodeManagement__c,'+
                                                'TCodeManagement__r.Name,'+
                                                'TCodeManagement__r.CreatedDate,'+
                                                'TCodeManagement__r.Valid__c,'+
                                                'TCodeManagement__r.Description__c,'+
                                                'TCodeManagement__r.Allow13Week__c, '+
                                                'TCodeManagement__r.Allow26Week__c, '+
                                                'TCodeManagement__r.Allow52Week__c, '+
                                                'TCodeManagement__r.Allow_13_Week_DD__c,'+
                                                'TCodeManagement__r.Allow_13_Week_CCA__c,'+
                                                'TCodeManagement__r.Allow_26_Week_DD__c,'+
                                                'TCodeManagement__r.Allow_26_Week_CCA__c,'+
                                                'TCodeManagement__r.Allow_52_Week_DD__c,'+
                                                'TCodeManagement__r.Allow_52_Week_CCA__c,'+
                                                'TCodeManagement__r.Low_Start_Period__c,'+
                                                'TCodeManagement__r.Payment_Type__c'+
                                            ' from TCode_Product__c where TCodeManagement__r.Valid__c = true {0} {1} order by TCodeManagement__r.Name desc limit 10000';

    public List<SelectOption> productNames {get; set;}
    transient public String selectedProductId {get; set;}

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - Q1/2016
    Version - 1.5
    Function - remote method to fetch the tcode related products
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         12/05/2016  //added extra fields to SOQL
    Gavin Palmer    1.2         15/06/2016  //moved query to be dynamic and added parameter
    Wiktor Czykin   1.3         09/09/2016  //added missing field to SOQL
    Wiktor Czykin   1.4         18/10/2016  //added Rank__c to SOQL and sorting of the list
    Wiktor Czykin   1.5         03/03/2017  //added record type filter in SOQL
    ****************************************************************************************/
    @RemoteAction
    public static List<TCodeProductWrapper> getTCodeDetails(Id tCodeId, String productId){
        if(tCodeId == null || tCodeId.getSobjectType() != TCodeManagement__c.SObjectType) return null;

        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        List<TCodeProductWrapper> lstProducts = new List<TCodeProductWrapper>();
        String productQuery =
            'select Weekly_Price__c, X13_Week_Price__c, Low_Start_Price__c, ' +
                'Digital_Monthly_Price__c, Digital_Yearly_Price__c, ' +
                'Product__c, Product__r.Name, Product__r.Print_Product__c, Product__r.Voucher_Delivery_Type__c, Product__r.Rank__c, ' +
                '(select Id, Incentive__r.Name from TCode_Product_Incentives__r)' +
            'from TCode_Product__c where TCodeManagement__c = :tCodeId and RecordTypeId = : offerRecordTypeId ';
        productQuery += String.isBlank(productId) ? '':' AND Product__c = :productId';

        for(TCode_Product__c tcp : Database.query(productQuery)){
            lstProducts.add(new TCodeProductWrapper(tcp));
        }
        if(lstProducts.isEmpty()) return null;
        lstProducts.sort();
        return lstProducts;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/05/2016
    Version - 1.4
    Function - remote method to fetch the tcode related products - support for list of tcode ids
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         15/06/2016  // moved query to be dynamic and added parameter
    Wiktor Czykin   1.2         09/09/2016  //added missing field to SOQL
    Wiktor Czykin   1.3         18/10/2016  //added Rank__c to SOQL and sorting of the list
    Wiktor Czykin   1.4         03/03/2017  //added record type filter in SOQL
    ****************************************************************************************/
    @RemoteAction
    public static Map<Id, List<TCodeProductWrapper>> getTCodesDetails(List<Id> lstTCodeIds, String productId){
        if(lstTCodeIds == null || lstTCodeIds.isEmpty()) return null;

        Map<Id, List<TCodeProductWrapper>> mapProducts = new Map<Id, List<TCodeProductWrapper>>();
        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());

        String productQuery =
            'select TCodeManagement__c, Weekly_Price__c, X13_Week_Price__c, Low_Start_Price__c, ' +
                'Digital_Monthly_Price__c, Digital_Yearly_Price__c, ' +
                'Product__c, Product__r.Name, Product__r.Print_Product__c, Product__r.Voucher_Delivery_Type__c, Product__r.Rank__c,' +
                '(select Id, Incentive__r.Name from TCode_Product_Incentives__r)' +
            'from TCode_Product__c where TCodeManagement__c in :lstTCodeIds and RecordTypeId = :offerRecordTypeId';
        productQuery += String.isBlank(productId) ? '':' AND Product__c = :productId';

        for(TCode_Product__c tcp :  Database.query(productQuery)){
            if(!mapProducts.containsKey(tcp.TCodeManagement__c)){
                mapProducts.put(tcp.TCodeManagement__c, new List<TCodeProductWrapper>{new TCodeProductWrapper(tcp)});
            }else{
                mapProducts.get(tcp.TCodeManagement__c).add(new TCodeProductWrapper(tcp));
            }
        }
        if(mapProducts.isEmpty()) return null;
        for(List<TCodeProductWrapper> lst : mapProducts.values()){
            lst.sort();
        }
        return mapProducts;
    }


    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - Q1/2016
    Version - 1.0
    Function - builds options list Premium/Digital
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<SelectOption> getProductTypeOptions(){
        return new List<SelectOption>{
            new SelectOption(Constants.PRODUCT_PREMIUM, Constants.PRODUCT_PREMIUM),
            new SelectOption(Constants.PRODUCT_DIGITAL, Constants.PRODUCT_DIGITAL)
        };
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - 15/03/2016
    Version - 1.2
    Function - constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         04/2016 //added some more initializations
    Wiktor Czykin   1.2         13/01/2017 //more init to prevent null pointers
    ****************************************************************************************/
    public OfferSelectionController(){
        this.selectedFilter = YES;
        this.bProductsSearched = false;
        this.lstAvailableProducts = new List<TCodeProductWrapper>();
        this.lstPromotionIncentives = new List<TCodeWrapper>();
        this.returnedPOCsList = new List<POC__c>();
        this.renderCreateExistingAccountBtn = true;
        this.selectSelected = false;
        this.filterSelected = false;
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - 15/03/2016
    Version - 1.1
    Function - method used to get all Products based on tCode and Print Product flag
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         04/2016 //added searched flag, sorting, error handling for null product search
    ****************************************************************************************/
    public List<TCodeProductWrapper> getAvailableProducts(Id tCodeId, Boolean isPrintProduct){
        this.lstAvailableProducts = new List<TCodeProductWrapper>();
        List<TCode_Product__c> lProducts = GlobalQueries.getTcodeProducts(tCodeId, isPrintProduct);
        if(lProducts == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_No_products_for_tcode));
            return this.lstAvailableProducts;
        }

        if(lProducts!=null){
            for(TCode_Product__c tcp : lProducts){
                lstAvailableProducts.add(new TCodeProductWrapper(tcp));
            }
        }
        this.bProductsSearched = true;
        this.lstAvailableProducts.sort();
        if(this.lstAvailableProducts.size() == 1){
            this.selectionData.productId = lstAvailableProducts[0].productId;
            lstAvailableProducts[0].selected = true;
            this.selectTcodeInfo();
        }
        return this.lstAvailableProducts;
    }



    public Boolean getShowOrderDetails(){
        if(this.selectionData != null && this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM && String.isNotBlank(this.selectionData.sSelectedOffer) && !SET_HIDE_ORDER_DETAILS.contains(this.selectionData.sSelectedOffer)){
            return true;
        }
        return false;
    }

    public Boolean getShowPromotions(){
        if(this.selectionData != null && String.isNotBlank(this.selectionData.sSelectedOffer) && SET_PROMOTION_OFFERS.contains(this.selectionData.sSelectedOffer)){
            return true;
        }
        return false;
    }

    public String getOfferLabel(){
        if(this.selectionData != null && String.isNotBlank(this.selectionData.sSelectedOffer) && MAP_OFFER_LABELS.containsKey(this.selectionData.sSelectedOffer)){
            return MAP_OFFER_LABELS.get(this.selectionData.sSelectedOffer);
        }
        return '';
    }

    public Boolean getIsPremium(){
        if(this.selectionData != null && this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM){
            return true;
        }
        return false;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.4
    Function - executes when offer is selcteed. Sets single tcode or retrieves a list depending on the offer.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/08/2015 //simplified, added vars, added low start
    Wiktor Czykin   1.2         09/09/2015 //added dupAccount blanking out so that found accounts are not maintained when offer is changed as could lead to wrong TCode being sold
    Michal Kwika    1.3         14/03/2016 //added initialisation of products
    Wiktor Czykin   1.4         04/2016    //added nullification of parameters which shouldn't be maintained when offer is changed, modified when products should be fetched
    ****************************************************************************************/
    public void initTcodes(){
        this.lstFoundAccounts = null;
        this.selectSelected = false;
        this.filterSelected = false;
        this.lstAvailableProducts = new List<TCodeProductWrapper>();
        this.bProductsSearched = false;
        this.mgmGiverInfo = null;
        this.selectionData.sStaffName = null;
        this.selectionData.productId = null;
        this.returnedPOCsList = new List<POC__C>();
        this.selectionData.pocSfdcId = null;
        this.selectionData.sTsNumber = null;
        this.selectionData.sTCodeId  = null;
        this.selectionData.sSurname = null;
        this.selectionData.sPostCode = null;
        this.selectionData.sPocId = null;
        if(this.selectionData.sSelectedOffer == Constants.OFFER_PROMOTION || this.selectionData.sSelectedOffer == Constants.OFFER_LOWSTART){
            this.selectFilter();
        }else if(this.selectionData.sSelectedOffer == Constants.OFFER_OPENOFFER){
            this.setOpenOfferTcode();
        }else if(this.selectionData.sSelectedOffer == Constants.OFFER_ADHOCPRICE){
            this.setAdHocTcode();
        }else if(this.selectionData.sSelectedOffer == Constants.OFFER_STAFF){
            this.setStaffTcode();
        }else if(this.selectionData.sSelectedOffer == Constants.OFFER_MGM){
            this.setMGMTcode();
        }

        if(!SET_DO_NOT_LOAD_PRODUCTS_ON_INIT.contains(this.selectionData.sSelectedOffer)){
            this.getAvailableProducts(this.selectionData.sTcodeId, (this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM));
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function - Builds a list of TCodes depending on
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         08-09/2015 //replaced the individual method calls with where conditions passed to single search method. Added low start. Added nullification of vars to avoid selection issues.
    Wiktor Czykin   1.2         12/05/2016 //added condition to filter out print products for digital only
    Gavin Palmer    1.3         15/06/2016 // moved the conditional logic into separate method so it can be called in different cases
    ****************************************************************************************/
    public void selectFilter(){
        this.filterselected = true;//if method is called means list of tcodes is refreshed. Then flag is switched as selection has to be made again
        this.lstFoundAccounts = null;
        this.selectedProductId = null;
        System.debug('selectionData.sSelectedOffer:'+this.selectionData.sSelectedOffer);
        System.debug('selectionData.sSelectedProductType:'+this.selectionData.sSelectedProductType);

        callInitPromotionIncentivesMap(true);
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 15/06/2016
    Version - 1.0
    Function - just calls the initPromotionIncentivesMap with a parameter of false
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void selectWithProductFilter(){
        this.filterselected = true;
        this.selectionData.productId = null;
        this.selectionData.sTCodeId  = null;
        callInitPromotionIncentivesMap(false);
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 15/06/2016
    Version - 1.0
    Function - Builds a list of TCodes depending on selected product type and where the method is called from
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void callInitPromotionIncentivesMap(Boolean isFromSelectFilter){
        if(this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM && this.selectionData.sSelectedOffer == Constants.OFFER_LOWSTART){
            this.initPromotionIncentivesMap(' and TCodeManagement__r.Type__c =\''+Constants.TCODE_TYPE_LOWSTART+'\'', isFromSelectFilter);
        }else if((this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM || this.selectionData.sSelectedProductType == Constants.PRODUCT_DIGITAL) && this.selectedFilter == NO){
            this.initPromotionIncentivesMap(' and TCodeManagement__r.Type__c =\''+Constants.TCODE_TYPE_PROMOTIONAL+'\'', isFromSelectFilter);
        }else if(this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM && this.selectionData.sSelectedOffer == Constants.OFFER_PROMOTION &&  this.selectedFilter == YES){
            this.initPromotionIncentivesMap(' and TCodeManagement__r.Type__c =\''+Constants.TCODE_TYPE_PROMOTIONAL+'\' and TCodeManagement__r.Reporting_Type__c!=\''+Constants.TCODE_REPORTTYPE_DIGITALONLY+'\'', isFromSelectFilter);
        }else if(this.selectionData.sSelectedProductType == Constants.PRODUCT_DIGITAL && this.selectionData.sSelectedOffer == Constants.OFFER_PROMOTION && this.selectedFilter == YES){
            this.initPromotionIncentivesMap(' and TCodeManagement__r.Type__c =\''+Constants.TCODE_TYPE_PROMOTIONAL+'\' and Product__r.Print_Product__c = false and TCodeManagement__r.Reporting_Type__c=\''+Constants.TCODE_REPORTTYPE_DIGITALONLY+'\'', isFromSelectFilter);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 13/08/2015
    Version - 1.3
    Function - Common method to fetch TCodes. Replaced individual methods that were only different in where condition.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         Q1/2016 //modified to fit with new data model.
    Gavin Palmer    1.2         15/06/2016 // added construction of select list to filter by products
    Wiktor Czykin   1.3         02/03/2017 // added record type filter for tcode products
    ****************************************************************************************/
    @TestVisible private void initPromotionIncentivesMap(String sExtraWhereTCode, Boolean isFromSelectFilter){
        if(String.isBlank(sExtraWhereTCode)) throw new TelegraphApplicationException('No filters specified for tcode search.');
        Map<Id, TCodeWrapper> mapTCodeIdToWrapper = new Map<Id, TCodeWrapper>();
        this.promoMap = new Map<Id, TCodeWrapper>();

        Id offerRecordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        String productWhereClause = String.isBlank(selectedProductId) ? '':' AND Product__c = :selectedProductId';
        String sFinalTCodeProductQuery = String.format(sTCodeProductQuery, new List<String>{sExtraWhereTCode + ' and RecordTypeId =: offerRecordTypeId ' , productWhereClause});

        Set<Id> productIds = new Set<Id>();
        if(isFromSelectFilter){
            productNames = new List<SelectOption>();
            productNames.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
        }

        for(TCode_Product__c tcodeProduct : Database.query(sFinalTCodeProductQuery)){
            if(!mapTCodeIdToWrapper.containsKey(tcodeProduct.TCodeManagement__c)){
                mapTCodeIdToWrapper.put(tcodeProduct.TCodeManagement__c,  new TCodeWrapper((TCodeManagement__c) tcodeProduct.getSObject('TCodeManagement__r')));
            }
            if(isFromSelectFilter && !productIds.contains(tcodeProduct.Product__c)){
                productNames.add(new SelectOption(tcodeProduct.Product__c, tcodeProduct.Product__r.Name));
                productIds.add(tcodeProduct.Product__c);
            }
        }

        this.lstPromotionIncentives = mapTCodeIdToWrapper.values();
        this.lstPromotionIncentives.sort();
        for(TCodeWrapper a : lstPromotionIncentives){
            this.promoMap.put(a.tCodeId, a);
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - Get the OpenOffer Tcode from TCodeManagement__c
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         08/2015     //added label and constant
    Michal Kwika    1.2         16/03/2016  //added tcode Id
    ****************************************************************************************/
    public void setOpenOfferTcode(){
        List<TCodeManagement__c> liTcodes = [select Name from TCodeManagement__c where Type__c = :Constants.TCODE_TYPE_OPENOFFER and Valid__c=true];
        if(liTcodes.size() == 1){
            this.selectionData.sTCode = liTcodes[0].Name;
            this.selectionData.sTcodeId = liTcodes[0].Id;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Multiple_open_offer_records_error));
        }
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - Michal Kwika
    Version - 1.0
    Function - Get the AdHoc Tcode from TCodeManagement__c
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void setAdHocTcode(){
        List<TCodeManagement__c> liTcodes = [SELECT Name FROM TCodeManagement__c WHERE Name =:this.sAdHocTCode and Valid__c=true];
        if(liTcodes.size() == 1){
            this.selectionData.sTCode = liTcodes[0].Name;
            this.selectionData.sTcodeId = liTcodes[0].Id;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Multiple_open_offer_records_error));
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Get the Staff Offer Tcode from TCodeManagement__c
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/08/2015 //added label and constant
    Michal Kwika    1.2         16/03/2016  //added tcode Id
    ****************************************************************************************/
    public void setStaffTcode(){
        List<TCodeManagement__c> liTcodes = [select Name from TCodeManagement__c where Type__c=:Constants.TCODE_TYPE_STAFFOFFER and Valid__c=true];
        if(liTcodes.size() == 1){
            this.selectionData.sTCode = liTcodes[0].name;
            this.selectionData.sTcodeId = liTcodes[0].Id;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Staff_offer_tcode_configuration_error));
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Get the MGM Tcode from TCodeManagement__c
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/08/2015 //added label and constant
    Michal Kwika    1.2         16/03/2016  //added tcode Id
    ****************************************************************************************/
    public void setMGMTcode(){
        List<TCodeManagement__c> liTcodes = [select Name from TCodeManagement__c Where Type__c=:Constants.TCODE_TYPE_MGM and Valid__c=true];
        if(liTcodes.size() == 1){
            this.selectionData.sTCode = liTcodes[0].Name;
            this.selectionData.sTcodeId = liTcodes[0].Id;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_MGM_tcode_configuration_error));
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function - looks for accounts meeting the criteria, redirects if none found
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         28/08/2015  //added labels, fixed postcode/lastname validation
    Wiktor Czykin   1.2         08/2015     //added constants
    Wiktor Czykin   1.3         15/10/2015  //modified validation condition type
    Pawel Chrzanowski   1.4     23/06/2016  //added email
    ****************************************************************************************/
    public Pagereference checkDuplicates(){
        // If either LastName or Postcode is not empty the other one is required
        if(String.isBlank(this.selectionData.sSurname) && String.isBlank(this.selectionData.sPostCode) && String.isBlank(inputTsNumber) && String.isBlank(inputEmail)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Subscriber_search_criteria_not_specified));
            return null;
        }

        // Check that both LastName and postcode are filled in case of a lastname/postcode search
        if(String.isBlank(inputEmail) && String.isBlank(inputTsNumber) && (String.isBlank(this.selectionData.sSurname) || String.isBlank(this.selectionData.sPostCode))){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Subscriber_search_last_name_and_post_code_mandatory));
            return null;
        }

        if(this.selectionData.sSelectedOffer == Constants.OFFER_ADHOCPRICE){
            if(!TMGUtil.isDataValid(this.selectionData.sDiscountPrice)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Subscriber_search_discount_price_validation));
                return null;
            }

            Pattern numericPattern = Pattern.compile('\\d+(\\.\\d{1,2})?');
            Matcher matcher = numericPattern.matcher(this.selectionData.sDiscountPrice);
            if(!matcher.matches()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Subscriber_search_discount_price_characters_validation));
                return null;
            }
        }

        //Added duplicateSurname!='' condition to check the Lastname pattern if LastName is not null
        if(String.isBlank(inputEmail) && String.isBlank(inputTsNumber) && String.isNotBlank(this.selectionData.sSurname)){
            // We know it's a lastname/postcode search
            // Checking that LastName is only Letters
            Pattern MyPattern = Pattern.compile('^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$');
            Matcher MyMatcher = MyPattern.matcher(this.selectionData.sSurname);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Subscriber_search_last_name_characters_validation));
                return null;
            }
        }
        System.debug('### CheckDuplicates: Chosen TCODe: ' + this.selectionData.sTcode);

        TCodeWrapper productSwitchPromo = null;
        if(this.selectionData.sSelectedOffer == Constants.OFFER_PROMOTION){
            try{
                //Put search for myTCode for mapped promotions.
                productSwitchPromo = this.promoMap.get(this.selectionData.sTcodeId);
                this.checkProductSwitchingButton();
            }catch(System.Exception e){}
        }

        if (findDuplicateAccounts(this.selectionData.sPostCode, this.selectionData.sSurname, inputTsNumber, inputEmail)){
            //duplicates found stay on same screen and display duplictes
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Offline_Acquisition_Existing_accounts_found));
            return null;
        }else{
          //move to 2nd screen
          if(TMGUtil.isDataValid(productSwitchPromo) && TMGUtil.isDataValid(productSwitchPromo.Description) && productSwitchPromo.Description.toLowerCase().contains('product switching')){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Product_switching_subscriber_not_found));
                return null;
          }else{
              return this.offerSelector.processOfferSelection();
          }
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 09/09/2015
    Version - 1.0
    Function - re-checks of selected tcode description whether it has 'product switching' within to show the 'Create New Customer' button without the need of searching for existing account again
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private void checkProductSwitchingButton(){
        this.renderCreateExistingAccountBtn = true;
        if(this.promoMap != null && this.selectionData.sTcodeId != null && this.promoMap.containsKey(this.selectionData.sTcodeId) && this.promoMap.get(this.selectionData.sTcodeId).Description != null && this.promoMap.get(this.selectionData.sTcodeId).Description.toLowerCase().contains('product switching')){
            this.renderCreateExistingAccountBtn = false;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function -  Find Existing customer information linked to POC
                Used for both Direct Mail POC Search AND    Direct Mail Customer Search
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         28/08/2015  //added trimming of keyword searched, added labels, constants
    MIchal Kwika    1.2         19/03/2016  //some changes due to new data model
    ************************************************************************************/
    public void findCustomerPOC(){
        this.returnedPOCsList = new List<POC__c>();
        if (String.isBlank(this.inputPOC)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Missing_POC_string_for_POC_search));
        }else{
            this.returnedPOCsList  = [select    Id,
                                                Title__c, FirstName__c, LastName__c, Street_Address_Line_2__c, State__c, Street__c, City__c, PostalCode__c,
                                                POC_ID__c,
                                                ExpiryDate__c,
                                                Subscriber_Number__c,
                                                TCodeManagement__c,
                                                TCodeManagement__r.Name
                                            from POC__c
                                            where POC_ID__c = :this.inputPOC.trim() order by createddate desc limit 2];

            if(this.returnedPOCsList.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_No_POC_record_found));
            }else{
                if(this.returnedPOCsList.size() == 2){
                    this.returnedPOCsList.remove(1);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Offline_Acquisition_More_than_1_poc_for_unique_poc_id_warning));
                }
                this.selectionData.sOrderMethod = Constants.SUB_ORDER_METHOD_INBOUND;
                this.setPOCSelectionFields(this.returnedPOCsList[0]);
            }
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function -  Find Existing customer information linked to POC
                Used for both Direct Mail POC Search AND Direct Mail Customer Search
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         08/2015     //added constants, labels, added escape qoutes and trimming
    Wiktor Czykin   1.2         15/10/2015  //removed one condition that could never be reached
    Michal Kwika    1.3         29/03/2015 // changed due to data model changes and code transformation
    **************************************************************************************/
    public void findCustomerDirectMail(){
        this.returnedPOCsList = new List<POC__c>();
        //Added search validation
        if(String.isBlank(this.selectionData.sSurname) && String.isBlank(this.selectionData.sPostCode)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Direct_mail_customer_search_empty_criteria));
        }else if (String.isNotBlank(this.selectionData.sSurname) && String.isBlank(this.selectionData.sPostCode)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Direct_mail_customer_search_empty_post_code));
        }else{
            String duplicatePostCode = UtilitiesForSubscriptions.formatPostCode(this.selectionData.sPostCode);
            String querystring = 'select Id, Title__c, FirstName__c, LastName__c, Street__c, City__c, Street_Address_Line_2__c, state__c, PostalCode__c, POC_ID__c, ExpiryDate__c, Subscriber_Number__c, TCodeManagement__c, TCodeManagement__r.Name from POC__c where ';
            if (String.isNotBlank(this.selectionData.sSurname) && String.isNotBlank(this.selectionData.sPostCode)){
                querystring += 'LastName__c =\''+ String.escapeSingleQuotes(this.selectionData.sSurname.trim()) +'\' and ';
                querystring += 'PostalCode__c =\''+ String.escapeSingleQuotes(this.selectionData.sPostCode.trim())  +'\'';
            } else if(this.selectionData.sPostCode != '') {
                querystring += 'PostalCode__c=\''+ String.escapeSingleQuotes(this.selectionData.sPostCode.trim()) +'\'';
            }
            this.returnedPOCsList = Database.query(querystring);
            if(this.returnedPOCsList.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Direct_mail_customer_search_empty_result));
            }else if(this.returnedPOCsList.size() == 1){
                this.setPOCSelectionFields(this.returnedPOCsList[0]);
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/05/2016
    Version - 1.0
    Function - Called on poc row click
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    public void selectPOC(){
        if(this.selectionData.pocSfdcId != null && !this.returnedPOCsList.isEmpty()){
            for(POC__c p : this.returnedPOCsList){
                if(p.Id == this.selectionData.pocSfdcId){
                    this.setPOCSelectionFields(p);
                    break;
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/05/2016
    Version - 1.0
    Function - setting of context variables based on selected poc data
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private void setPOCSelectionFields(POC__c poc){
        this.selectionData.pocSfdcId = poc.Id;
        this.selectionData.sPocId = poc.POC_ID__c;
        this.selectionData.sSurname = poc.LastName__c;
        this.selectionData.sPostCode = poc.PostalCode__c;
        this.selectionData.sTsNumber = poc.Subscriber_Number__c;
        this.selectionData.sTCodeId  = poc.TCodeManagement__c;
        this.getAvailableProducts(this.selectionData.sTCodeId, (this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM));
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - After clicking find acc method
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    public PageReference displayDupAccount(){
        List<Account> lstAccount = [select RecordTypeId, IsPersonAccount, Subscriber_Number_static__c, Subscription_Status__c, Guid__c from Account where Id = :this.selectionData.selectedAccountId];
        if(lstAccount.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Account_details_not_found_on_submit));
            return null;
        }
        Account selectedAccount = lstAccount[0];
        this.selectionData.sTsNumber = selectedAccount.Subscriber_Number_static__c;
        this.selectionData.sGuid = SelectedAccount.Guid__c;

        // DIGITAL: we can edit Active Account
        this.selectionData.bIsActive = (selectedAccount.Subscription_Status__c == Constants.SSTATUS_ACTIVE);
        return this.offerSelector.processOfferSelection();
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - returns duplicate existing accounts by searching on surname and postcode entered
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin       1.1     30/07/2015  //escaped single qoutes for last name search
    Pawel Chrzanowski   1.2     23/06/2016  //added email
    **************************************************************************************/
    public Boolean findDuplicateAccounts(String postCode, String lastName, String tsNumber, String email){
        Boolean dupAccountsFound;
        this.selectionData.sTsNumber = '';
        try{
            dupAccountsFound = false;
            String formatedPostCode = UtilitiesForSubscriptions.formatPostCode(postCode);

            this.lstFoundAccounts = new List<AccountWithProductTypeWrapper>();
            String sSoql = 'SELECT Id, Name, RecordTypeId, Guid__c, IsPersonAccount,  Salutation, FirstName, LastName, PersonEmail, PersonMailingCity, '
                 + 'PersonMailingPostalCode, PersonMailingState, PersonMailingStreet, Subscriber_Number_static__c, Subscription_Status__c, Digital_Low_Start_Used__c, '
                 + 'Mobile_Free_Trial_Used__c, Deceased__pc FROM Account WHERE (LastName= \''+String.escapeSingleQuotes(lastName.trim())+'\' AND PersonMailingPostalCode=\''+formatedPostCode+'\') '
                 + (TMGUtil.isDataValid(tsNumber) ? 'OR Subscriber_Number_static__c=:tsNumber ': '')
                 + (TMGUtil.isDataValid(email) ? 'OR PersonEmail=:email ': '')
                 + 'ORDER BY CreatedDate DESC';

            for(Account acc: Database.query(sSoql)){
                this.lstFoundAccounts.add(new AccountWithProductTypeWrapper(acc));
            }
            dupAccountsFound = !lstFoundAccounts.isEmpty();
        } catch (Exception e){
            dupAccountsFound = false;
        }
        return dupAccountsFound;
    }


    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Executed on tcode selection from the list. Sets combination of flags so that account search section shows up.
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/08/2015 //changed the way how parameter is passed is passed in (assignTo from VF instead of from the page context)
    Michal Kwika    1.2         28/03/2016 //improvements due to data model changes
    *************************************************************************************/
    public void selectTcodeInfo(){
        this.selectSelected=true;
        this.filterSelected=false;
    }

    /***************************************************************************************
    Developer - Michal Kwika
    Date - 15/03/2016
    Version - 1.0
    Function - Executed on tcode Product selection from the list.
                Sets combination of flags so that account search section shows up.
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
    public void selectProductInfo(){
        if(this.selectionData.sSelectedOffer == Constants.OFFER_PROMOTION){
            this.checkProductSwitchingButton();
        }
        this.selectTcodeInfo();
        this.selectionData.sTCode = this.promoMap.get(this.selectionData.sTcodeId).tCode;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - Prepare the URL to the next page oapsubscription
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         27/04/2016  //made sure the product of the giver is copied over to the new subscriber
    Wiktor Czykin   1.2         16/05/2016  //made sure product Id is selected in context
    ***************************************************************************************/
    public void searchMGM(){
        String mgmCode = this.selectionData.sMgmGiverCode.trim();
        List<Account> mgmGiver = [select    Id,
                                            Subscriber_Number_static__c,
                                            Salutation,
                                            FirstName,
                                            LastName,
                                            PersonEmail,
                                            PersonMailingCity,
                                            PersonMailingPostalCode
                                        from Account
                                        where MGMcode__c = :mgmCode
                                        and MGMcode__c != null
                                        limit 1];
        if(!mgmGiver.isEmpty()){
            Set<String> setSubscriptionStatus = new Set<String>{Constants.SSTATUS_ACTIVE, Constants.SSTATUS_PENDING};
            List<Subscription__c> liSub = [select Weekly_Price__c, Product__c from Subscription__c where subscriber__c=:mgmGiver[0].Id and Subscription_Status__c IN :setSubscriptionStatus order by CreatedDate desc limit 1];
            if(liSub.size() == 1){
                this.selectionData.mgmGiverId = mgmGiver[0].Id;
                this.selectionData.dForcedPrice = liSub[0].Weekly_Price__c;
                this.mgmGiverInfo = new MgmGiverInfoPrice(mgmGiver[0], liSub[0].Weekly_Price__c);
                this.getAvailableProducts(this.selectionData.sTcodeId, (this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM));
                this.bProductsSearched = false; //we don't want to show product selection, we just default the product to givers product
                Boolean bMatchfound = false;
                for(TCodeProductWrapper tpw : this.lstAvailableProducts){
                    if(tpw.productId == liSub[0].Product__c){
                        bMatchfound = true;
                        this.mgmGiverInfo.productName = tpw.sProductName;
                        this.selectionData.productId = tpw.productId;
                        this.selectTcodeInfo();
                    }
                }
                if(!bMatchfound){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_MGM_matching_product_not_available));
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_No_active_subscription_found_for_MGM_giver+' '+mgmGiver[0].Subscriber_Number_static__c));
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_No_MGM_giver_found+' '+mgmCode));
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - simple staff name validation for staff offer
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/08/2015 //added label
    Michal Kwika    1.2         30/03/2016 //data model changes
    *************************************************************************************/
    public void enterStaffName(){
        if(String.isBlank(this.selectionData.sStaffName)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Staff_name_mandatory));
        }
        this.getAvailableProducts(this.selectionData.sTcodeId, (this.selectionData.sSelectedProductType == Constants.PRODUCT_PREMIUM));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 25/04/2016
    Version - 1.1
    Function - defines when find account section should appear on the page
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/01/2017 //added conditions so that null pointer is not thrown
    *************************************************************************************/
    public Boolean getIsFindAccountShowed(){
        if(this.selectionData == null || String.isBlank(this.selectionData.sSelectedOffer)) return false;
        return ((this.selectionData.sSelectedOffer == Constants.OFFER_OPENOFFER || this.selectionData.sSelectedOffer == Constants.OFFER_ADHOCPRICE || this.selectionData.sSelectedOffer == Constants.OFFER_PROMOTION || this.selectionData.sSelectedOffer == Constants.OFFER_LOWSTART) && this.selectSelected && !this.filterSelected)
                || (this.selectionData.sSelectedOffer == Constants.OFFER_STAFF && this.selectSelected && String.isNotBlank(this.selectionData.sStaffName))
                || (this.selectionData.sSelectedOffer == Constants.OFFER_MGM && this.mgmGiverInfo != null && this.selectSelected);
    }

    /**
    * @author Unknown
    * @date Unknown
    * @description Wrapper for Account search results
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/08/2015  //changed record type fetching method
    **/
    public class AccountWithProductTypeWrapper{
        public Account subscriber {get;set;}
        public String productType {get;set;}
        public AccountWithProductTypeWrapper(Account acc){
            this.subscriber = acc;
            if(subscriber.recordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName())){
                this.productType = Constants.PRODUCT_PREMIUM;
            }else if(subscriber.recordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName())){
                this.productType = Constants.PRODUCT_DIGITAL;
            }
        }
    }

    /**
    * @author Cristina Popescu
    * @date 19.06.2015
    * @description Wrapper to enable sorting
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         30/06/2015  //simplified the wrapper
    Wiktor Czykin   1.2         13/08/2015  //added continuous grouping vars
    Wiktor Czykin   1.3         29/09/2015  //added low start period
    Wiktor Czykin   1.4         21/01/2016  //modified to use new data model - product hardcoding removal
    Michal Kwika    1.5         28/03/2016  //modified to use new multipicklist Payment Type instead of flags
    **/
    public class TCodeWrapper implements Comparable {

        private final String DD = 'DD';
        private final String CCA = 'CCA';
        private final String NA = 'N/A';

        public Id tCodeId{get;set;}
        public String tCode                 {get;set;}
        public DateTime tCodeCreatedDate    {get;set;}
        public String description           {get;set;}
        public Boolean allow13weeks         {get;set;}
        public Boolean allow26weeks         {get;set;}
        public Boolean allow52weeks         {get;set;}
        public String allow13Continuous     {get;set;}
        public String allow26Continuous     {get;set;}
        public String allow52Continuous     {get;set;}
        public String lowStartPeriod       {get;set;}

        public Boolean selected             {get;set;}

        // Constructor
        public TCodeWrapper(TCodeManagement__c tcm){
            this.tCodeId = tcm.Id;
            this.tCode = tcm.Name;
            this.tCodeCreatedDate = tcm.CreatedDate;
            this.description = tcm.Description__c;
            this.lowStartPeriod = tcm.Low_Start_Period__c;

            //set values based on new picklist
            this.allow13weeks = TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_ONE_OFF_13_WEEK);
            this.allow26weeks = TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_ONE_OFF_26_WEEK);
            this.allow52weeks = TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_ONE_OFF_52_WEEK);

            List<String> lstContinuous = new List<String>();
            if(TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_13_WEEK_CCA)){
                lstContinuous.add(CCA);
            }
            if(TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_13_WEEK_DD)){
                lstContinuous.add(DD);
            }
            this.allow13Continuous = String.join(lstContinuous, ', ');
            if(String.isBlank(this.allow13Continuous)) this.allow13Continuous = NA;
            lstContinuous = new List<String>();

            if(TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_26_WEEK_CCA)){
                lstContinuous.add(CCA);
            }
            if(TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_26_WEEK_DD)){
                lstContinuous.add(DD);
            }
            this.allow26Continuous = String.join(lstContinuous, ', ');
            if(String.isBlank(this.allow26Continuous)) this.allow26Continuous = NA;
            lstContinuous = new List<String>();

            if(TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_52_WEEK_CCA)){
                lstContinuous.add(CCA);
            }
            if(TMGUtil.multiPickListSelectionCheck(tcm.Payment_Type__c,Constants.ALLOW_52_WEEK_DD)){
                lstContinuous.add(DD);
            }
            this.allow52Continuous = String.join(lstContinuous, ', ');
            if(String.isBlank(this.allow52Continuous)) this.allow52Continuous = NA;
            this.selected = false;
        }

        /***************************************************************************************
        Developer - Cristina Popescu
        Date - 19.06.2015
        Version - 1.1
        Function -  Method to sort the wrapper by TCodeManagement__c Created date and by Name
        #############Change Log#############
        Modified by     Version     Change Date
        Wiktor Czykin   1.1         30/06/2015  //changed to match the simplified wrapper
        ****************************************************************************************/
        // Compare opportunities based on the opportunity amount.
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            TCodeWrapper compareToOppy = (TCodeWrapper)compareTo;
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (this.tCodeCreatedDate > compareToOppy.tCodeCreatedDate){
                // Set return value to a negative value.
                returnValue = -1;
            } else if (this.tCodeCreatedDate < compareToOppy.tCodeCreatedDate) {
                // Set return value to a positive value.
                returnValue = 1;
            }else if (this.tCode > compareToOppy.tCode) {
                // Set return value to a negative value.
                returnValue = -1;
            } else if (this.tCode < compareToOppy.tCode) {
                // Set return value to a positive value.
                returnValue = 1;
            }
            return returnValue;
        }
    }

    /**
    * @author Unknown
    * @date Unknown
    * @description Wrapper to  hold MGM information
    #############Change Log#############
    Modified by     Version     Change Date
    **/
    public class MgmGiverInfoPrice{
        public Account giver{get;set;}
        public Decimal price{get;set;}
        public String productName{get;set;}

        public MgmGiverInfoPrice(Account giver, Decimal price){
            this.giver = giver;
            this.price = price;
        }
    }
}
