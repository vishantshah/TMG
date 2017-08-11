/**
* @author Wiktor Czykin
* @date 15/02/2017
* @description extension for the TCodeSetup page this page will allow
*               creation and modification of TCodes with their child
*               TCode Products and then the Product Incentives and
*               Pricing oprions - kinda rewrote most of the things Gavin Palmer
*               wrote in his old TCodeSetupExtension
*#############Change Log#############
*Modified by     Change Date
*Wiktor Czykin   17/05/2017     //modified saveAndNew()
*Wiktor Czykin   15/04/2017     //added incentives validation - related to auto incentives adding
*Wiktor Czykin   20/06/2017     //modified getTCode() and removeTCodeProduct()
**/
public with sharing class TCodeManagementController {

    public static final Integer OFFERS_LIMIT;
    public static final Integer ZOFFERS_LIMIT;
    public static final Id OFFER_RECORDTYPE_ID;
    public static final Id ZOFFER_RECORDTYPE_ID;
    @TestVisible private static Boolean ZOFFERS_LIMIT_ENABLED = false; 

    @TestVisible private Integer iCustomIndex = 0;
    @TestVisible private Map<Id, Offer> mapExistingOffersById;
    @TestVisible private Map<Integer, Offer> mapExistingOffersByIndex;
    @TestVisible private Map<Id, ProductItem> mapAvailableZProducts {get; set;}
    @TestVisible private List<TCode_Product__c> lstTCodeProductsToDelete{get;set;}
    @TestVisible private List<TCode_Product_Incentive__c> lstIncentivesToDelete {get;set;}
    @TestVisible private List<Pricing_Options__c> lstPricingOptionsToDelete{get;set;}

     // parameters passed in from the page
    transient public Id selectedProductId {get; set;}
    transient public Integer selectedRow {get; set;}
    transient public String sZOffer {get;set;}
    transient public Integer iSelectedIndex {get;set;}
    public Offer offerInContext{get;set;}
    public Integer iOfferRowToPopulate{get;set;}

    public TCodeManagement__c tCode{get;set;}
    public List<Offer> lstSelectedOffers{get{
        this.lstSelectedOffers = new List<Offer>();
        if(!this.mapExistingOffersByIndex.isEmpty()){
            for(Offer o : this.mapExistingOffersByIndex.values()){
                if(o.tp.RecordTypeId == OFFER_RECORDTYPE_ID){
                    this.lstSelectedOffers.add(o);
                }
            }
        }
        this.lstSelectedOffers.sort();
        return this.lstSelectedOffers;
        } set;}

    public List<Offer> lstSelectedZuoraOffers{get{
        this.lstSelectedZuoraOffers = new List<Offer>();
        if(!this.mapExistingOffersByIndex.isEmpty()){
            for(Offer o : this.mapExistingOffersByIndex.values()){
                if(o.tp.RecordTypeId == ZOFFER_RECORDTYPE_ID){
                    this.lstSelectedZuoraOffers.add(o);
                }
            }
        }
        this.lstSelectedZuoraOffers.sort();
        return this.lstSelectedZuoraOffers;
        } set;}

    public List<ProductItem> availableZProductsList{get{
        this.availableZProductsList = new List<ProductItem>();
        for(ProductItem pi : this.mapAvailableZProducts.values()){
            if(pi.isVisible()){
                this.availableZProductsList.add(pi);
            }
        }
        this.availableZProductsList.sort();
        return this.availableZProductsList;
        } private set;}

    public Boolean canSeeAvailableProducts{get;set;}
    public Boolean canViewPricingOptions{get;set;}
    public Boolean canViewIncentives{get;set;}

    public Id zOfferRecordTypeId {get;set;}

    static{
        ZOFFERS_LIMIT = Offer__c.Frequency__c.getDescribe().getPicklistValues().size();
        OFFERS_LIMIT = 1;
        OFFER_RECORDTYPE_ID = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER , TCode_Product__c.class.getName());
        ZOFFER_RECORDTYPE_ID = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_ZOFFER , TCode_Product__c.class.getName());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function -  constructor - initialize collections and preparation of available products and selected offers
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public TCodeManagementController(ApexPages.StandardController std){
        Id tCodeId = std.getId();
        this.lstSelectedOffers = new List<Offer>();
        this.lstSelectedZuoraOffers = new List<Offer>();
        this.mapExistingOffersById = new Map<Id, Offer>();
        this.mapExistingOffersByIndex = new Map<Integer, Offer>();
        this.mapAvailableZProducts = new Map<Id, ProductItem>();
        this.lstTCodeProductsToDelete = new List<TCode_Product__c>();
        this.lstIncentivesToDelete = new List<TCode_Product_Incentive__c>();
        this.lstPricingOptionsToDelete = new List<Pricing_Options__c>();
        this.zOfferRecordTypeId = ZOFFER_RECORDTYPE_ID;
        this.canSeeAvailableProducts = true;
        try{
            if(String.isEmpty(tCodeId)){
                this.tCode = new TCodeManagement__c();
                this.prepareAvailableZProducts(null);
            } else {
                this.tCode = this.getTCode(tCodeId); //get tcode with related tcodeproducts
                this.prepareAvailableZProducts(this.tCode.TCode_Products__r);
                if(!this.tCode.TCode_Products__r.isEmpty()){
                    this.canSeeAvailableProducts = false;
                }
                for(TCode_Product__c tcp : this.tCode.TCode_Products__r){
                    Offer o = new Offer(this.iCustomIndex, tcp, tcp.Product__r.Name);
                    this.mapExistingOffersById.put(tcp.Id, o);
                    this.mapExistingOffersByIndex.put(this.iCustomIndex, o);
                    this.iCustomIndex++;
                }
                this.populateExistingIncentives();
                this.populateExistingPricingOptions();
            }
            if(ApexPages.currentPage().getParameters().containsKey('clone') && ApexPages.currentPage().getParameters().get('clone') == '1'){
                this.clearIdAndRelationshipFields();
            }
        } catch (QueryException qException){
            throw new TelegraphApplicationException('Error fetching TCode related lists data.' + qException.getMessage());
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function -  populate map of available products
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void prepareAvailableZProducts(List<TCode_Product__c> lstOffers){
        Map<Id, ProductItem> mapProductsWrapper = new Map<Id, ProductItem>();
        for(zqu__ZProduct__c prod : [SELECT Id, Name, Print_Product__c FROM zqu__ZProduct__c]){
            mapProductsWrapper.put(prod.Id, new ProductItem(prod));
        }

        if(lstOffers != null && !lstOffers.isEmpty()){
            for(TCode_Product__c tp : lstOffers){
                ProductItem pi = mapProductsWrapper.get(tp.Product__c);
                if(pi != null){
                    if(tp.RecordTypeId == OFFER_RECORDTYPE_ID){
                        pi.addOffer();
                    }else if(tp.RecordTypeId == ZOFFER_RECORDTYPE_ID){
                        pi.addZOffer();
                    }
                }
            }
        }
        this.mapAvailableZProducts = mapProductsWrapper;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function -  get Tcode with related tcode products
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   20/06/2017  //added Offer Name field to soql
    ****************************************************************************************/
    private TCodeManagement__c getTCode(Id tCodeId){
        Set<String> setExtraFields = new Set<String>{'Product__r.Name', 'Offer__r.Name'};
        for(Schema.FieldSetMember fsm : Schema.SObjectType.Offer__c.fieldSets.ZTCodeSetup.getFields()){
            setExtraFields.add('Offer__r.'+fsm.getFieldPath());
        }
        String subQuery = 'select '+GlobalQueries.generateFieldsListForQuery('TCode_Product__c', setExtraFields, null)+' from TCode_Products__r';
        String query = GlobalQueries.getQueryFromFieldSet(SObjectType.TCodeManagement__c.FieldSets.TCodeSetup, null, subQuery, 'Id = \'' + tCodeId + '\'', 1);
        List<TCodeManagement__c> tCodes = (List<TCodeManagement__c>) Database.query(query);
        if(tCodes.isEmpty()) {
            throw new TelegraphApplicationException(Label.TCodeSetup_Error_Getting_TCode);
        }
        return tCodes[0];
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function -  get all the children pricing options for
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void populateExistingPricingOptions(){
        Set<Id> setIds = this.mapExistingOffersById.keySet();
        if(setIds.isEmpty()) return;

        String whereClause = 'TCode_Product__c in :setIds';
        Set<String> additionalFields = new Set<String>{'TCode_Product__c', 'TCode_Product__r.Product__c', 'Name'};
        String query = GlobalQueries.getQueryFromFieldSet(SObjectType.Pricing_Options__c.FieldSets.TCodeSetup, additionalFields, null, whereClause, null);

        for(Pricing_Options__c po : Database.query(query)){
            this.mapExistingOffersById.get(po.TCode_Product__c).addPricingOption(po);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - get all the children incentives to a list of tCode Products
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void populateExistingIncentives(){
        Set<Id> setIds = this.mapExistingOffersById.keySet();
        if(setIds.isEmpty()) return;

        String whereClause = 'TCode_Product__c IN :setIds';
        Set<String> additionalFields = new Set<String>{'TCode_Product__c', 'TCode_Product__r.Product__c', 'Name', 'Auto_Assign_for_Zuora_Subscription__c'};
        String query = GlobalQueries.getQueryFromFieldSet(SObjectType.TCode_Product_Incentive__c.FieldSets.TCodeSetup, additionalFields, null, whereClause, null);

        for(TCode_Product_Incentive__c tpi : Database.query(query)){
            this.mapExistingOffersById.get(tpi.TCode_Product__c).addIncentive(tpi);
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function -  clear ids on all records - used for clone action
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void clearIdAndRelationshipFields(){
        this.tCode.Id = null;
        for(Offer o : this.mapExistingOffersById.values()){
            o.clearIds();
        }
        this.mapExistingOffersById = new Map<Id, Offer>();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - add new offer instance (wrapper) and sorts resulting lists afterwards
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void addTCodeProduct(){
        ProductItem pi = this.mapAvailableZProducts.get(this.selectedProductId);
        if(pi == null) return;

        Offer o = new Offer(this.iCustomIndex, new TCode_Product__c(Product__c = selectedProductId), pi.product.Name);
        if(String.isNotBlank(this.sZOffer)){
            pi.addZOffer();
            o.tp.RecordTypeId = ZOFFER_RECORDTYPE_ID;
            this.lstSelectedZuoraOffers.add(o);
        }else{
            pi.addOffer();
            o.tp.RecordTypeId = OFFER_RECORDTYPE_ID;
            this.lstSelectedOffers.add(o);
        }

        this.mapExistingOffersByIndex.put(o.iCustomIndex, o);
        this.lstSelectedOffers.sort();
        this.lstSelectedZuoraOffers.sort();
        this.iCustomIndex++;
    }


    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - on/off flag for products list
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void toggleAvailableProducts(){
        this.canSeeAvailableProducts = !this.canSeeAvailableProducts;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - removes offer from all the respective collections, restores product for selection, adds item to list for delete (if persisted)
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   20/07/2017  //replaced error strings with labels
    ****************************************************************************************/
    public void removeTCodeProduct(){
        if(this.iSelectedIndex == null) return;
        if(!this.mapExistingOffersByIndex.containsKey(iSelectedIndex)) return;
        Offer removedOffer = this.mapExistingOffersByIndex.get(this.iSelectedIndex);

        if(removedOffer == null) throw new TelegraphApplicationException(Label.TCodeSetup_Unexpected_data_error);
        ProductItem pi = this.mapAvailableZProducts.get(removedOffer.tp.Product__c);
        if(pi == null)  throw new TelegraphApplicationException(Label.TCodeSetup_Unexpected_data_error);
        if(removedOffer.tp.RecordTypeId == OFFER_RECORDTYPE_ID){
            pi.removeOffer();
        }else if(removedOffer.tp.RecordTypeId == ZOFFER_RECORDTYPE_ID){
            pi.removeZOffer();
        }
        if(removedOffer.tp.Id != null){
            this.lstTCodeProductsToDelete.add(removedOffer.tp);
            this.mapExistingOffersById.remove(removedOffer.tp.Id);
        }
        this.mapExistingOffersByIndex.remove(removedOffer.iCustomIndex);

        if(this.offerInContext != null && this.offerInContext.iCustomIndex == removedOffer.iCustomIndex){
            this.offerInContext = null;
            closeSection();
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - set flags to close the related items section
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void closeSection(){
        this.canViewPricingOptions = false;
        this.canViewIncentives = false;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function -  views incentives for offer in context (sets respective flags)
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void viewIncentives(){
        if(this.iSelectedIndex == null) return;
        if(!this.mapExistingOffersByIndex.containsKey(this.iSelectedIndex)) return;
        this.offerInContext = this.mapExistingOffersByIndex.get(iSelectedIndex);

        // make the section visible
        this.canViewPricingOptions = false;
        this.canViewIncentives = true;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - views pricing options for offer in context (sets respective flags)
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void viewPricingOptions(){
        if(this.iSelectedIndex == null) return;
        if(!this.mapExistingOffersByIndex.containsKey(this.iSelectedIndex)) return;
        this.offerInContext = this.mapExistingOffersByIndex.get(iSelectedIndex);

        // make the section visible
        this.canViewPricingOptions = true;
        this.canViewIncentives = false;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - adds new instance of incentive to offer in context
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void addIncentive(){
        this.offerInContext.addIncentive(new TCode_Product_Incentive__c());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - adds new instance of pricing option to offer in context
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void addPricingOption(){
        this.offerInContext.addPricingOption(new Pricing_Options__c());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - removes incentive instance from the wrapper and adds to list to delete (if persisted)
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void removeIncentive(){
        if(this.offerInContext == null || this.offerInContext.lstIncentives == null || this.offerInContext.lstIncentives.isEmpty()) return;
        if(this.offerInContext.lstIncentives[selectedRow].Id != null){
            this.lstIncentivesToDelete.add(this.offerInContext.lstIncentives[selectedRow]);
        }
        this.offerInContext.lstIncentives.remove(selectedRow);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - removes pricing option instance from the wrapper and adds to list to delete (if persisted)
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void removePricingOption(){
        if(this.offerInContext == null || this.offerInContext.lstPricingOptions == null || this.offerInContext.lstPricingOptions.isEmpty()) return;

        if(this.offerInContext.lstPricingOptions[selectedRow].Id != null){
            this.lstPricingOptionsToDelete.add(this.offerInContext.lstPricingOptions[selectedRow]);
        }
        this.offerInContext.lstPricingOptions.remove(selectedRow);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/02/2017
    Function - copy of old method - return to saved item
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public PageReference save(){
        if(saveSucceeded()) {
           return new PageReference('/' + this.tCode.Id);
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 22/02/2017
    Function - copy of old method - return
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   17/05/2017  //added return url to make sure it works as standard page
    ****************************************************************************************/
    public PageReference saveAndNew(){
        if(this.saveSucceeded()){
            PageReference pr = Page.TCodeSetup;
            pr.setRedirect(true);
            pr.getParameters().put(Constants.GET_PARAM_RETURL, '/'+this.tCode.Id);
            return pr;
        }
        return null;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Function - saves all data
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   14/06/2017  //added prevalidation
    ****************************************************************************************/
    private Boolean saveSucceeded(){
        Savepoint tCodeSavepoint = Database.setSavepoint();
        Database.UpsertResult tCodeUpsertResult;
        List<TCode_Product__c> tCodeProductsToUpsert = new List<TCode_Product__c>();

        this.preValidateOffers();
        if(ApexPages.hasMessages()){
            return false;
        }

        try{
            tCodeUpsertResult = Database.upsert(this.tCode);
            if(!this.mapExistingOffersByIndex.isEmpty()){
                for(Offer o : this.mapExistingOffersByIndex.values()){
                    o.tp.TCodeManagement__c = this.tCode.Id;
                    tCodeProductsToUpsert.add(o.tp);
                }
            }

            if(!this.lstTCodeProductsToDelete.isEmpty()) delete this.lstTCodeProductsToDelete;
            if(!tCodeProductsToUpsert.isEmpty()) upsert tCodeProductsToUpsert;

            if(!this.lstIncentivesToDelete.isEmpty()) delete this.lstIncentivesToDelete;
            if(!this.lstPricingOptionsToDelete.isEmpty()) delete this.lstPricingOptionsToDelete;

            List<Pricing_Options__c> lstPricingOptionsToUpsert = new List<Pricing_Options__c>();
            List<TCode_Product_Incentive__c> lstIncentivesToUpsert = new List<TCode_Product_Incentive__c>();
            for(Offer o :this.mapExistingOffersByIndex.values()){
                o.populateIds();
                lstPricingOptionsToUpsert.addAll(o.lstPricingOptions);
                lstIncentivesToUpsert.addAll(o.lstIncentives);
            }

            if(!lstPricingOptionsToUpsert.isEmpty()){
                upsert lstPricingOptionsToUpsert;
            }

            if(!lstIncentivesToUpsert.isEmpty()){
                upsert lstIncentivesToUpsert;
            }
        } catch(DmlException exceptionToHandle){
            Database.rollback(tCodeSavepoint);
            if(tCodeUpsertResult != null && tCodeUpsertResult.isCreated()) tCode.Id = null;
            for(Integer i = 0; i < exceptionToHandle.getNumDml(); i++) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, exceptionToHandle.getDmlMessage(i)));
            }
            return false;
        }
        return true;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 14/06/2017
    Function - added custom validation method for save
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void preValidateOffers(){
        for(Offer o :this.mapExistingOffersByIndex.values()){
            if(!o.areValidIncentives()){
                List<String> lstParams = new List<String>{o.tp.Product__r.Name, (String.isNotBlank(o.offer.Name)?o.offer.Name:Label.Unknown)};
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, String.format(Label.TCodeSetup_Only_one_auto_incentive_validation, lstParams)));
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 14/03/2017
    Function - populate read only fields from selected offer
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void refreshOfferSelection(){
        if(this.iOfferRowToPopulate == null) return;

        Offer offerItem = this.mapExistingOffersByIndex.get(this.iOfferRowToPopulate);
        if(offerItem == null || offerItem.tp == null) return;

        if(offerItem.tp.Offer__c == null){
            offerItem.offer = new Offer__c();
        }else{
            Set<String>setFields = new Set<String>{'Name'};
            for(Schema.FieldSetMember fsm :  Schema.SObjectType.Offer__c.fieldSets.ZTCodeSetup.getFields()){
                setFields.add(fsm.getFieldPath());
            }
            Id recId = offerItem.tp.Offer__c;
            List<Offer__c> lstOffer = Database.query('select Id, ' + String.join(new List<String>(setFields), ',') + ' from Offer__c where Id = :recId');
            if(lstOffer.isEmpty()) return;
            offerItem.offer = lstOffer[0];
        }
    }

    /**
    * @author Wiktor Czykin
    * @date 15/02/2017
    * @description  Wrapper class to hold information about actual data row that is then stored
    *#############Change Log#############
    *Modified by     Change Date
    *Wiktor Czykin   14/06/2017 //added incentives validation method
    **/
    public class Offer implements Comparable{
        public Integer iCustomIndex{get;set;}
        public String sProductName{get;set;}
        public TCode_Product__c tp{get;set;}
        public List<TCode_Product_Incentive__c> lstIncentives{get;set;}
        public List<Pricing_Options__c> lstPricingOptions{get;set;}
        public Offer__c offer{get;set;}

        public Offer(Integer i, TCode_Product__c tp, String sName){
            this.lstIncentives = new List<TCode_Product_Incentive__c>();
            this.lstPricingOptions = new List<Pricing_Options__c>();
            this.tp = tp;
            this.iCustomIndex = i;
            this.sProductName = sName;
            this.offer = tp.getSObject('Offer__r') != null ? (Offer__c)tp.getSObject('Offer__r') : new Offer__c();
        }

        public void addIncentive(TCode_Product_Incentive__c tpi){
            this.lstIncentives.add(tpi);
        }

        public void addPricingOption(Pricing_Options__c po){
            this.lstPricingOptions.add(po);
        }

        public void clearIds(){
            this.tp.Id = null;
            this.tp.TCodeManagement__c = null;
            this.clearIncentiveIdsForClone();
            this.clearPricingOptionIdsForClone();
        }

        private void clearIncentiveIdsForClone(){
            for(TCode_Product_Incentive__c tpi : this.lstIncentives){
                tpi.Id = null;
                tpi.TCode_Product__c = null;
            }
        }

        private void clearPricingOptionIdsForClone(){
            for(Pricing_Options__c po : this.lstPricingOptions){
                po.Id = null;
                po.TCode_Product__c = null;
            }
        }

        public void populateIds(){
            if(this.tp.Id == null) return;

            if(!lstIncentives.isEmpty()){
                for(TCode_Product_Incentive__c tpi : this.lstIncentives){
                    if(tpi.TCode_Product__c == null){
                        tpi.TCode_Product__c = this.tp.Id;
                    }
                }
            }

            if(!lstPricingOptions.isEmpty()){
                for(Pricing_Options__c po : this.lstPricingOptions){
                    if(po.TCode_Product__c == null){
                        po.TCode_Product__c = this.tp.Id;
                    }
                }
            }
        }

        public Boolean areValidIncentives(){
            Integer iCount = 0;
            
            if(!this.lstIncentives.isEmpty()){
                for(TCode_Product_Incentive__c incentive : this.lstIncentives){
                    if(incentive.Auto_Assign_for_Zuora_Subscription__c){
                        iCount++;
                    }
                }
            }
            if(iCount > 1){
                return false;
            }
            return true;
        }

        public Integer compareTo(Object compareTo){
            Offer to = (Offer) compareTo;
            if(String.isBlank(this.sProductName) || String.isBlank(to.sProductName)) return 0;
            if(this.sProductName.equals(to.sProductName)) return 0;
            if(this.sProductName > to.sProductName) return 1;
            return -1;
        }
    }

    /**
    * @author Wiktor Czykin
    * @date 15/02/2017
    * @description inner class to reflect available products selection
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    public class ProductItem implements Comparable{
        public Integer iOfferCount{get;set;}
        public Integer iZOfferCount{get;set;}
        public zqu__ZProduct__c product{get;set;}
        public Boolean bShowAddOffer{get;set;}
        public Boolean bShowAddZOffer{get;set;}

        public ProductItem(zqu__ZProduct__c product){
            this.bShowAddOffer = true;
            this.bShowAddZOffer = true;
            this.iOfferCount = 0;
            this.iZOfferCount = 0;
            this.product = product;
            if(product.Print_Product__c){
                this.bShowAddZOffer = false;
            }
        }

        public void addOffer(){
            this.iOfferCount++;
            if(this.iOfferCount == OFFERS_LIMIT){
                this.bShowAddOffer = false;
            }
        }

        public void addZOffer(){
            this.iZOfferCount ++;
            if(this.iZOfferCount == ZOFFERS_LIMIT && ZOFFERS_LIMIT_ENABLED){
                this.bShowAddZOffer = false;
            }
        }

        public void removeOffer(){
            this.iOfferCount--;
            if(this.iOfferCount < OFFERS_LIMIT){
                this.bShowAddOffer = true;
            }
        }

        public void removeZOffer(){
            this.iZOfferCount--;
            if(this.iZOfferCount < ZOFFERS_LIMIT && ZOFFERS_LIMIT_ENABLED){
                this.bShowAddZOffer = true;
            }
        }

        public Boolean isVisible(){
            return this.bShowAddOffer || this.bShowAddZOffer;
        }

        public Integer compareTo(Object compareTo){
            ProductItem to = (ProductItem) compareTo;
            if(this.product == null || to.product == null) return 0;
            if(this.product.Name.equals(to.product.Name)) return 0;
            if(this.product.Name > to.product.Name) return 1;
            return -1;
        }
    }
}