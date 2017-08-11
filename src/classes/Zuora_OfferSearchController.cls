/**
* Author:       Sally ElGhoul (Accenture)
* Date:         11/01/2016
* Description:  this class is the controller for Zuora_OfferSearch page to list the offers and campaigns for product and rate plan
*
* ******************* Change Log *******************
* Modified by       Change Date
* Sally ElGhoul 3/2/2016 add picklists for further filtering for promotional offers
* Sally ElGhoul 19/02/2016 filter tcode incentives based on offer product and subscription type
* Gavin Palmer  05/05/2016 Removed method getProductPrice() so that price can be set from the callout
* Wiktor Czykin 05/10/2016 Added weekly price column value support
* Wiktor Czykin 17/05/2017 Modified most of the things to support Offer object rather than core api response
**/
public class Zuora_OfferSearchController {

    @TestVisible private static final String SORT_ASCENDING = 'ASC';
    @TestVisible private static final String SORT_DESCENDING = 'DESC';
    @TestVisible private static final String SORT_BY_TCODE_NAME = 'tcodeName';
    @TestVisible private static final String SORT_BY_TCODE_DESCRIPTION = 'tcodeDesc';
    @TestVisible private static final String SORT_BY_OFFER_FRIENDLY_NAME = 'offerName';
    @TestVisible private static final String SORT_BY_PRODUCT_NAME = 'productName';
    @TestVisible private static final String SORT_BY_PRODUCT_FREQUENCY = 'productFrequency';
    @TestVisible private static final String SORT_BY_WEEKLY_PRICE = 'weeklyPrice';
    @TestVisible private static final String SORT_BY_BASE_PRICE = 'basePrice';
    @TestVisible private static final String SEARCH_CAMPAIGN_OPTION = 'campaign';
    @TestVisible private static final String SEARCH_POC_ID_OPTION = 'poc';
    @TestVisible private static final String SEARCH_POC_LAST_NAME_POSTAL_CODE_OPTION = 'pocLastNamePostalCode';

    public static String sortColumn;
    public static String sortOrder;

    public List<AvailableOffersWrapper> lstAvailableOpenOffers {get;set;} //List of all open Offers
    public List<AvailableOffersWrapper> lstAvailablePromotionalOffers {get;set;} //List of all available promotional Offers
    public List<AvailableOffersWrapper> lstFilteredPromotionalOffers {get;set;} //List of filtered promotional offers based on promotional offer search
    public List<AvailableOffersWrapper> lstVisiblePromotionalOffers {get;set;} //list of visible promotional offers after filtering results from dropdowns
    transient public List<InvoiceWrapper> lstInvoices {get;set;}
    public List<SelectOption> lstPromotionalOfferCampaignNames {get;set;}
    public List<SelectOption> lstPromotionalOfferProducts {get;set;}
    public List<SelectOption> lstPromotionalOfferFrequencies {get;set;}

    public String strSelectedRatePlan {get;set;}
    public String strSelectedOfferCode {get;set;}
    public String strSelectedFilterProductName {get;set;}
    public String strSelectedFilterCampaignName {get;set;}
    public String strSelectedFilterFrequency {get;set;}

    transient public Decimal productPrice {get;set;}
    transient public Decimal totalInvoiceValue {get;set;}

    public CoreApiResources.OfferCodeDetails selectedOfferCodeDetailsObj {get;set;}
    public Boolean displayFilteredOffers {get;set;}

    ///search filters
    public String strSelectedSearchCriteria {get;set;}
    public String strSearchText {get;set;}
    public String strPOCSearchLastName {get;set;}
    public String strPOCSearchPostalCode {get;set;}

    public List<SelectOption> getlstSearchOptions(){
        return new List<SelectOption>{
            new SelectOption(campaignSearchOptionValue,Label.Offer_Search_Campaign_Search_Label),
            new SelectOption(pocIDSearchOptionValue,Label.Offer_Search_POC_ID_Search_Label),
            new SelectOption(pocLastNamePostalCodeOptionValue,Label.Offer_Search_POC_Last_Name_Postal_Code_Search_Label)
        };
    }

    //get the campaign search value text
    public String campaignSearchOptionValue{
        get{return SEARCH_CAMPAIGN_OPTION;}
        set;
    }

    //get the poc ID search value text
    public String pocIDSearchOptionValue{
        get{return SEARCH_POC_ID_OPTION;}
        set;
    }

    //get the POC Last name and postal code search value text
    public String pocLastNamePostalCodeOptionValue{
        get{return SEARCH_POC_LAST_NAME_POSTAL_CODE_OPTION;}
        set;
    }

    //get the sorting by Tcode Name text
    public String sortByTcodeNameValue{
        get{return SORT_BY_TCODE_NAME;}
        set;
    }

    //get the sorting by Tcode description text
    public String sortByTcodeDescriptionValue{
        get{return SORT_BY_TCODE_DESCRIPTION;}
        set;
    }

    //get the sorting by Offer Name text
    public String sortByOfferFriendlyNameValue{
        get{return SORT_BY_OFFER_FRIENDLY_NAME;}
        set;
    }

    //get the sorting by Product Name text
    public String sortProductNameValue{
        get{return SORT_BY_PRODUCT_NAME;}
        set;
    }

    //get the sorting by Product Frequency text
    public String sortProductFrequencyValue{
        get{return SORT_BY_PRODUCT_FREQUENCY;}
        set;
    }

    public String sortProductWeeklyPrice{
        get{return SORT_BY_WEEKLY_PRICE;}
        set;
    }

    public String sortBasePrice{
        get{return SORT_BY_BASE_PRICE;}
        set;
    }

    public String ascendingOrderValue{
        get{return SORT_ASCENDING;}
        set;
    }

    public String descendingOrderValue{
        get{return SORT_DESCENDING;}
        set;
    }

    private String sPreviousSortExpression;

    //get and set the sorting expression for lists
    public String sortExpression{
        get;
        set{
            this.sortExpression = value;
            if(this.sortExpression == this.sPreviousSortExpression){
                this.sortDirection = (this.sortDirection == SORT_ASCENDING? SORT_DESCENDING : SORT_ASCENDING);
            }else{
                this.sortDirection = SORT_ASCENDING;
            }
            this.sPreviousSortExpression = this.sortExpression;
        }
   }

    //get and set the sorting direction
    public String sortDirection{
        get{
            if(String.isBlank(this.sortDirection)){
                this.sortDirection = SORT_ASCENDING;
            }
            return this.sortDirection;
        }
        set;
    }

    //get the promotional offers section label
    public String getPromotionalOffersSectionLabel(){
        if(displayFilteredOffers){
            return Label.Offer_Search_Promotional_Offers_Search_Result_Section_Label;
        }else{
            return Label.Offer_Search_Promotional_Offers_Section_Label;
        }
    }

    ///////////////////////////////////Public Methods ///////////////////////////////////////////////
    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    Constructor
    ******************* Change Log *********************************************************
    Modified by         Change Date
    Sally ElGhoul       3/2/2016    adding lstVisiblePromotionalOffers
    Wiktor Czykin       17/05/2017  removed core api offers retrieval
    ****************************************************************************************/
    public Zuora_OfferSearchController(){
        if(String.isBlank(sortOrder)){
            sortOrder = SORT_ASCENDING;
        }

        //initialize variables
        lstAvailableOpenOffers = new List<AvailableOffersWrapper>();
        lstAvailablePromotionalOffers = new List<AvailableOffersWrapper>();
        lstFilteredPromotionalOffers = new List<AvailableOffersWrapper>();
        lstVisiblePromotionalOffers = new List<AvailableOffersWrapper>();
        strSelectedSearchCriteria = campaignSearchOptionValue;
        displayFilteredOffers = false;
        productPrice=totalInvoiceValue = 0;
        selectedOfferCodeDetailsObj = new CoreApiResources.OfferCodeDetails();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    This function is called to show the offer details
    ******************* Change Log *********************************************************
    Modified by         Change Date
    Gavin Palmer        05/05/2016 - remove call to deprecated method
    Wiktor Czykin       17/05/2017 - changed the way selected offer details are retrieved 
    ****************************************************************************************/
    public void getOfferDetails(){
        try{
            if(!String.isEmpty(strSelectedOfferCode)){
                Offer__c offer = GlobalQueries.getOffer(strSelectedOfferCode, null);
                if(offer == null){
                    throw new TelegraphApplicationException(Label.Offer_Search_No_offer_found);
                }
                this.strSelectedRatePlan = offer.Frequency__c;
                selectedOfferCodeDetailsObj = new CoreApiResources.OfferCodeDetails();
                selectedOfferCodeDetailsObj.name = offer.Name__c;
                selectedOfferCodeDetailsObj.description = offer.Description__c;
                selectedOfferCodeDetailsObj.containsFreeTrial = offer.Free_Trial__c;
                selectedOfferCodeDetailsObj.isRestricted = offer.Is_Restricted__c;
                selectedOfferCodeDetailsObj.tmgId = offer.Name;
                selectedOfferCodeDetailsObj.friendlyName = offer.Friendly_Name__c;
                selectedOfferCodeDetailsObj.basePrice = offer.Base_Price__c;
                selectedOfferCodeDetailsObj.discounts = new List<CoreApiResources.DiscountDetails>();

                CoreApiResources.DiscountDetails discount = new CoreApiResources.DiscountDetails();
                discount.billingPeriod = offer.Frequency__c;
                discount.numberOfPeriods = (Integer) offer.Discount_Duration__c;
                discount.discountAmount = offer.Discount__c;
                selectedOfferCodeDetailsObj.discounts.add(discount);
               
                if(selectedOfferCodeDetailsObj != null && selectedOfferCodeDetailsObj.discounts != null){
                    getBillingPreview();
                }
            }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.New_Digital_Platform_Generic_Error_Message+' '+e.getMessage()));
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    This function is called to show the offer details
    ******************* Change Log *********************************************************
    Modified by     Change Date
    Sally ElGhoul   3/2/2016 setting lstVisiblePromotionalOffers
    ****************************************************************************************/
    public PageReference loadAllAvailableOffers(){
        try{
            this.lstAvailableOpenOffers = this.getOpenOffers();
            this.lstAvailablePromotionalOffers = this.getPromotionalOffers();
            //by default all available promotional offers will be visible
            this.lstVisiblePromotionalOffers=lstAvailablePromotionalOffers;
            //fill picklist values based on offers
            this.fillPicklistFilterValues();

            //initially sort lists by tcodeName
            sortExpression=sortByTcodeNameValue;
            sortData();
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.New_Digital_Platform_Generic_Error_Message+ex));
        }
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    Sort the data
    ******************* Change Log *********************************************************
    Modified by         Change Date
    Sally ElGhoul       03/02/2016 sort only the lstVisiblePromotionalOffers list as it is the only promotional list that will be visible
    Wiktor Czykin       17/05/2017 removed try catch as shouldnt be any need for it
    ****************************************************************************************/
    public void sortData(){
        sortColumn = this.sortExpression;
        sortOrder = this.sortDirection;
        lstAvailableOpenOffers.sort();
        lstVisiblePromotionalOffers.sort();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    searching for offers
    ******************* Change Log *********************************************************
    Modified by         Change Date
    ****************************************************************************************/
    public PageReference searchOffers(){
        try{
            if(isValidSearchCriteria()){
                //set the flag to show the search result section and hide the list of all promotional offers
                displayFilteredOffers = true;

                //apply the appropriate filtering based on the selected radio button
                if(strSelectedSearchCriteria == campaignSearchOptionValue){
                    //search by tcode name or tcode description
                    lstFilteredPromotionalOffers = filterOfferByCampaign();
                }else if(strSelectedSearchCriteria == pocIDSearchOptionValue){
                    //search by POC ID
                    lstFilteredPromotionalOffers = filterOffersByPOCID();
                }else if(strSelectedSearchCriteria == pocLastNamePostalCodeOptionValue){
                    //Search By POC Last Name and postal Code
                    lstFilteredPromotionalOffers = filterOffersByPOCLastNamePostalCode();
                }

                //set the visible promotional offers list to be the filtered list
                lstVisiblePromotionalOffers=lstFilteredPromotionalOffers;
                fillPicklistFilterValues();
                sortData();
            }
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.New_Digital_Platform_Generic_Error_Message+'; '+ex.getMessage()));
        }

        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        03/02/2016
    Function    Filters the offers using the picklist values
    ******************* Change Log *********************************************************
    Modified by         Change Date
    Wiktor Czykin       17/05/2017  //changed condition levels 
    ****************************************************************************************/
    public void filterOffers(){
        lstVisiblePromotionalOffers = new List<AvailableOffersWrapper>();
        List<AvailableOffersWrapper> lstPromOffers = new List<AvailableOffersWrapper>();
        if(displayFilteredOffers){
            lstPromOffers=lstFilteredPromotionalOffers;
        }else{
            lstPromOffers=lstAvailablePromotionalOffers;
        }

        for(AvailableOffersWrapper wrapperObj : lstPromOffers){
            if(!String.isEmpty(strSelectedFilterProductName) && wrapperObj.offerProductName!=strSelectedFilterProductName){
                continue;
            }
            if(!String.isEmpty(strSelectedFilterCampaignName) && wrapperObj.tcodeObj.Description__c!=strSelectedFilterCampaignName){
                continue;
            }
            if(!String.isEmpty(strSelectedFilterFrequency) && wrapperObj.offerProductFrequencey!=strSelectedFilterFrequency){
                continue;
            }
            lstVisiblePromotionalOffers.add(wrapperObj);
        }
        sortData();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    Clear search text boxes with radio button change
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference refreshSearchPanel(){
        strSearchText=strPOCSearchLastName=strPOCSearchPostalCode='';
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    Show all promotional offers and clear the filterd offers list
    ******************* Change Log *********************************************************
    Modified by         Change Date
    Sally ElGhoul       3/2/2016   Setting the visible list to all available promotional offers
    ****************************************************************************************/
    public void showAllOffers(){
        displayFilteredOffers=false;
        strSelectedFilterFrequency=strSelectedFilterProductName=strSelectedFilterCampaignName=strSearchText=strPOCSearchLastName=strPOCSearchPostalCode='';
        strSelectedSearchCriteria=campaignSearchOptionValue;
        lstFilteredPromotionalOffers=new List<AvailableOffersWrapper>();
        lstVisiblePromotionalOffers=lstAvailablePromotionalOffers;
        fillPicklistFilterValues();
        sortData();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    Get all Open Offers
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    Wiktor Czykin       05/10/2016  //added weekly price assignment
    Wiktor Czykin       17/05/2017  //modified how offers are retrieved
    ****************************************************************************************/
    private List<AvailableOffersWrapper> getOpenOffers(){
        List<AvailableOffersWrapper> lstOpenOffersAvailableOffers=new List<AvailableOffersWrapper>();
        List<TCode_Product__c> lstOffers = GlobalQueries.getZuoraTcodeProductsBasedOnTCodeOfferType(Constants.TCODE_TYPE_OPENOFFER, null);

        if(lstOffers!=null && !lstOffers.isEmpty()){
            for(TCode_Product__c tcp : lstOffers){
                lstOpenOffersAvailableOffers.add(new AvailableOffersWrapper(tcp));
            }
        }
        return lstOpenOffersAvailableOffers;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        11/01/2015
    Function    Get all Promotional offers
    ******************* Change Log *********************************************************
    Modified by        Change Date
    Wiktor Czykin      05/10/2016  //added weekly price assignment
    Wiktor Czykin      17/05/2017  //modified how offers are retrieved
    ****************************************************************************************/
    private List<AvailableOffersWrapper> getPromotionalOffers(){
        List<AvailableOffersWrapper> lstPromotionalAvailableOffers=new List<AvailableOffersWrapper>();
        List<TCode_Product__c> lstOffers = GlobalQueries.getZuoraTcodeProductsBasedOnTCodeOfferType(Constants.TCODE_TYPE_PROMOTIONAL, null);
        if(lstOffers != null && !lstOffers.isEmpty()){
            for(TCode_Product__c tcp : lstOffers){
                lstPromotionalAvailableOffers.add(new AvailableOffersWrapper(tcp));
            }
        }
        return lstPromotionalAvailableOffers;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        12/01/2015
    Function    This function is to fill the billing preview details
    ******************* Change Log *********************************************************
    Modified by         Change Date
    Gavin Palmer        10/05/2016 - removed dependency on the product price to the base price from the offer
    Wiktor Czykin       17/05/2017 - changed frequency constant
    ****************************************************************************************/
    private void getBillingPreview(){
        lstInvoices = new List<InvoiceWrapper>();
        totalInvoiceValue = 0;
        productPrice = selectedOfferCodeDetailsObj.basePrice;

        //check that the product price is not zero
        if(productPrice != 0){

            //specify number of bills based on the frequency
            //it is 12 invoices for monthly and 1 for annual
            Integer numberOfInvoices = 1;
            if(strSelectedRatePlan == Constants.OFFER_FREQUENCY_MONTHLY){
                numberOfInvoices = 12;
            }

            //initialize the invoices to be all based on the product price
            for(Integer i = 0; i<numberOfInvoices; i++){
                InvoiceWrapper invoiceObj=new InvoiceWrapper();
                invoiceObj.invoiceNo = i+1;
                invoiceObj.invoiceAmount = productPrice;
                lstInvoices.add(invoiceObj);
            }

            //do the calculation for discounts by looping on the discounts
            if(selectedOfferCodeDetailsObj != null && selectedOfferCodeDetailsObj.discounts != null){
                //get the offer code detailed discount
                for(CoreApiResources.DiscountDetails discountObj : selectedOfferCodeDetailsObj.discounts){
                    //subtract the disocunt amount from the invoices
                    for(Integer i=0; i < discountObj.numberOfPeriods; i++){
                        if(i < lstInvoices.size()){
                            //check that the invoice amount is >= the discount amount
                            //otherwise the subtraction will cause negative values
                            if(lstInvoices[i].invoiceAmount >= discountObj.discountAmount){
                                lstInvoices[i].invoiceAmount = lstInvoices[i].invoiceAmount-discountObj.discountAmount;
                            }else{
                                lstInvoices[i].invoiceAmount = 0;
                            }
                        }
                    }
                }
            }

            //loop on the final verision of invoices after
            //subtracting the discount amounts to calculate the total invoice amount
            for(InvoiceWrapper invoiceObj : lstInvoices){
                totalInvoiceValue += invoiceObj.invoiceAmount;
            }
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        20/01/2015
    Function    This function is called to filter promotional offers by campaign
    ******************* Change Log *********************************************************
    Modified by         Change Date
    ****************************************************************************************/
    private List<AvailableOffersWrapper> filterOfferByCampaign(){
        List<AvailableOffersWrapper> lstFilterOffers=new List<AvailableOffersWrapper>();
        strSearchText=strSearchText.trim();

        //filter the promotional offers by the tcode name or tcode description
        //the search is not exact in this case it will return record if the search text is included in tcode name or description
        for(AvailableOffersWrapper offerWrapperObj : lstAvailablePromotionalOffers){
            if(offerWrapperObj.tcodeObj.name.tolowerCase().contains(strSearchText.tolowerCase()) ||
               offerWrapperObj.tcodeObj.Description__c.tolowerCase().contains(strSearchText.tolowerCase())){
                   lstFilterOffers.add(offerWrapperObj);
               }
        }

        return lstFilterOffers;

    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        20/01/2015
    Function    This function is called to filter promotional offers by POC ID
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private List<AvailableOffersWrapper> filterOffersByPOCID(){
        List<AvailableOffersWrapper> lstFilterOffers=new List<AvailableOffersWrapper>();
        Map<Id, POC__C> mapTcodeIdPoc = new Map<Id, POC__C>();
        strSearchText=strSearchText.trim();

        //get poc and build the map of Pocs where the key is the tcode id and the poc is the value
        List<POC__c> lstPocs=[select id, TCodeManagement__c,POC_ID__c,name from POC__c where POC_ID__c=:strSearchText limit 5000];
        if(lstPocs.size() > 0){
            for(POC__c pocObj : lstPocs){
                if(pocObj.TCodeManagement__c!=null && !mapTcodeIdPoc.containsKey(pocObj.TCodeManagement__c)){
                    mapTcodeIdPoc.put(pocObj.TCodeManagement__c,pocObj);
                }
            }
        }

        //filter offers
        for(AvailableOffersWrapper offerWrapperObj : lstAvailablePromotionalOffers){
            if(mapTcodeIdPoc.containskey(offerWrapperObj.tcodeObj.id)){
               AvailableOffersWrapper pocOfferWrapperObj=    offerWrapperObj;
               pocOfferWrapperObj.pocObj=mapTcodeIdPoc.get(offerWrapperObj.tcodeObj.id);
               lstFilterOffers.add(pocOfferWrapperObj);
            }
        }
        return lstFilterOffers;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        20/01/2015
    Function    This function is called to filter promotional offers by POC Last Name and Postal Code
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private List<AvailableOffersWrapper> filterOffersByPOCLastNamePostalCode(){
        List<AvailableOffersWrapper> lstFilterOffers=new List<AvailableOffersWrapper>();
        Map<Id,POC__C> mapTcodeIdPoc = new Map<id,POC__C>();
        //trim the searching text
        strPOCSearchLastName=strPOCSearchLastName.trim();
        strPOCSearchPostalCode=strPOCSearchPostalCode.trim();

        //get poc and build the map of Pocs where the key is the tcode id and the poc is the value
        //we will get the list of poc using the last name search
        //then we will loop on the return result to filter based on postal code because the postal codes are saved in different format like e140tr e14 0tr or e 12 0tr
        //so in the loop to filter postal codes i will remove all white spaces and compare
        List<POC__c> lstPocs=[select id,PostalCode__c,TCodeManagement__c,POC_ID__c, Name from POC__c where LastName__c=:strPOCSearchLastName limit 5000];
        if(lstPocs.size()>0){
            for(POC__c pocObj : lstPocs){
                if(!String.isEmpty(pocObj.PostalCode__c)){
                    if(pocObj.PostalCode__c.tolowerCase().deleteWhitespace()==strPOCSearchPostalCode.tolowerCase().deleteWhitespace() &&
                        pocObj.TCodeManagement__c!=null && !mapTcodeIdPoc.containsKey(pocObj.TCodeManagement__c)){
                        mapTcodeIdPoc.put(pocObj.TCodeManagement__c,pocObj);
                    }
                }
            }
        }

        //filter offers
        for(AvailableOffersWrapper offerWrapperObj : lstAvailablePromotionalOffers){
            if(mapTcodeIdPoc.containskey(offerWrapperObj.tcodeObj.id)){
               AvailableOffersWrapper pocOfferWrapperObj = offerWrapperObj;
               pocOfferWrapperObj.pocObj=mapTcodeIdPoc.get(offerWrapperObj.tcodeObj.id);
               lstFilterOffers.add(pocOfferWrapperObj);
            }
        }
        return lstFilterOffers;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        20/01/2015
    Function    This function is to check
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private Boolean isValidSearchCriteria(){
        if((strSelectedSearchCriteria == campaignSearchOptionValue || strSelectedSearchCriteria == pocIDSearchOptionValue) && String.isEmpty(strSearchText)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offer_Search_Text_Search_Missing_Error_Message));
            return false;
        }else if(strSelectedSearchCriteria==pocLastNamePostalCodeOptionValue && (String.isEmpty(strPOCSearchLastName)|| String.isEmpty(strPOCSearchPostalCode))){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offer_Search_Last_Name_Postal_Code_Search_Error_Message));
            return false;
        }
        return true;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        03/02/2016
    Function    This function is to fill the three picklist values based on the distinct values available in the table of promotional offers (all or filtered)
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void fillPicklistFilterValues(){
        lstPromotionalOfferProducts = new List<SelectOption>();
        lstPromotionalOfferCampaignNames = new List<SelectOption>();
        lstPromotionalOfferFrequencies = new List<SelectOption>();

        Set<String> setCampaignNames = new Set<String>();
        Set<String> setProductNames = new Set<String>();
        Set<String> setFrequencies = new Set<String>();
        List<AvailableOffersWrapper> lstPromOffers;

        //fill the list of product picklist from filtered promotional offers list if a search is applied
        //otherwise get the product picklist values from all promotional offers list
        if(displayFilteredOffers){
            lstPromOffers = lstFilteredPromotionalOffers;
        }else{
            lstPromOffers = lstAvailablePromotionalOffers;
        }

        if(lstPromOffers.size() > 0){
            System.debug('lstPromOffers: '+lstPromOffers);
            //add distinct product names
            for(AvailableOffersWrapper wrapperObj : lstPromOffers){
                //fill the product Name
                if(!setProductNames.contains(wrapperObj.offerProductName) && !String.isEmpty(wrapperObj.offerProductName)){
                    setProductNames.add(wrapperObj.offerProductName);
                }
                //fill the campaign names
                if(!setCampaignNames.contains(wrapperObj.tcodeObj.Description__c) && !String.isEmpty(wrapperObj.tcodeObj.Description__c)){
                    setCampaignNames.add(wrapperObj.tcodeObj.Description__c);
                }
                //fill the frequency values
                if(!setFrequencies.contains(wrapperObj.offerProductFrequencey) && !String.isEmpty(wrapperObj.offerProductFrequencey)){
                    setFrequencies.add(wrapperObj.offerProductFrequencey);
                }
            }

            //fill the campaign names selection option list
            lstPromotionalOfferCampaignNames=getSelectOptionList(setCampaignNames);
            //fill the product names selection option list
            lstPromotionalOfferProducts=getSelectOptionList(setProductNames);
            //fill the freqyency values selection option list
            lstPromotionalOfferFrequencies=getSelectOptionList(setFrequencies);
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        03/02/2016
    Function    This function is to form the select option list from a String set
    ******************* Change Log *********************************************************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private List<SelectOption> getSelectOptionList(Set<String> setSelectOptionValues){
        List<SelectOption> lstFinalReturnSelectOptions = new List<SelectOption>();
        List<SelectOption> lstRetuturnSelectOptions = new List<SelectOption>();

        if(setSelectOptionValues!=null){
            for(String strValue : setSelectOptionValues){
                lstRetuturnSelectOptions.add(new SelectOption(strValue,strValue));
            }
            //if the campaign options list contains more than one value add the NONE option
            if(lstRetuturnSelectOptions.size()>1){
                lstFinalReturnSelectOptions.add(new SelectOption('',Constants.NONE_PICKLIST_VALUE));
                lstFinalReturnSelectOptions.addAll(lstRetuturnSelectOptions);
            }else{
                lstFinalReturnSelectOptions=lstRetuturnSelectOptions;
            }
        }
        return lstFinalReturnSelectOptions;
    }

    /**
    * Author:       Sally ElGhoul (Accenture)
    * Date:         11/01/2016
    * Description: wrapper class to show the available offers details
    * ******************* Change Log *******************
    * Modified by       Change Date
    * Wiktor Czykin     05/09/2016 //added sorting for new weekly price
    * Wiktor Czykin     17/05/2017 //made use of constructor
    **/
    public class AvailableOffersWrapper implements Comparable{
        public POC__c pocObj {get;set;}
        public TCodeManagement__c tcodeObj {get;set;}
        public String strOfferFriendlyName {get;set;}
        public String strOfferTmgId {get;set;}
        public String offerProductName {get;set;}
        public String offerProductFrequencey {get;set;}
        public Decimal weeklyPrice {get;set;}
        public Decimal basePrice {get;set;}
        public String sIncentives{get;set;}
        public Id offerId{get;set;}

        public AvailableOffersWrapper(){}

        public AvailableOffersWrapper(TCode_Product__c tcp){
            this.offerId = tcp.Offer__c;
            this.strOfferTmgId = tcp.Offer__r.Name;
            this.tcodeObj = tcp.TCodeManagement__r;
            this.strOfferFriendlyName = tcp.Offer__r.Friendly_Name__c;
            this.offerProductName = tcp.Product__r.Name;
            this.offerProductFrequencey = tcp.Offer__r.Frequency__c;
            this.weeklyPrice = tcp.Offer__r.Weekly_Advertised_Price__c;
            this.basePrice = tcp.Offer__r.Base_Price__c;
            this.sIncentives = '';

            if(!tcp.TCode_Product_Incentives__r.isEmpty()){
                for(TCode_Product_Incentive__c tpi : tcp.TCode_Product_Incentives__r){
                    this.sIncentives += tpi.Incentive__r.Name+', ';
                }
            }
            
            if(String.isNotBlank(sIncentives)){
               this.sIncentives=  this.sIncentives.substring(0, sIncentives.length()-2);
            }
        }
   
        // Implement the compareTo() method
        public Integer compareTo(Object compareTo) {
            AvailableOffersWrapper compareToOffer = (AvailableOffersWrapper)compareTo;
            Integer sortDirectionControl=1;
            //if sort descending,set the sort direction integer to -1 to reverse the sorting
            if(sortOrder == SORT_DESCENDING){
                sortDirectionControl = -1;
            }
            //sort by product name
            if(sortColumn == SORT_BY_PRODUCT_NAME){
                if (offerProductName > compareToOffer.offerProductName) {
                    return (1*sortDirectionControl);
                }else if (offerProductName < compareToOffer.offerProductName) {
                    return (-1*sortDirectionControl);
                }else if (offerProductName == compareToOffer.offerProductName){
                    return 0;
                    //if both equal , i sort using the second word of the product name to sort tablet uk and tablet international for example
                     String[] productNameArr=offerProductName.split(' ');
                     String[] productNameCompareToArr=compareToOffer.offerProductName.split(' ');

                     if (productNameArr[1] > productNameCompareToArr[1]) {
                            return (1*sortDirectionControl);
                     }else if (productNameArr[1] < productNameCompareToArr[1]) {
                            return (-1*sortDirectionControl);
                     }else if (productNameArr[1] == productNameCompareToArr[1]){
                         return 0;
                     }
                }
            }else if(sortColumn == SORT_BY_TCODE_NAME){ //sort by tcode name
                if (tcodeObj.name > compareToOffer.tcodeObj.name) {
                    return (1*sortDirectionControl);
                }else if (tcodeObj.name < compareToOffer.tcodeObj.name) {
                    return (-1*sortDirectionControl);
                }else if (tcodeObj.name == compareToOffer.tcodeObj.name){
                    return 0;
                   }
            }else if (sortColumn == SORT_BY_TCODE_DESCRIPTION){ //sort by tcode description
                if (tcodeObj.Description__c > compareToOffer.tcodeObj.Description__c) {
                    return (1*sortDirectionControl);
                }else if (tcodeObj.Description__c < compareToOffer.tcodeObj.Description__c) {
                    return (-1*sortDirectionControl);
                }else if (tcodeObj.Description__c == compareToOffer.tcodeObj.Description__c){
                    return 0;
                }
            }else if(sortColumn == SORT_BY_OFFER_FRIENDLY_NAME){ //sort by the offer friendly name
                if (strOfferFriendlyName > compareToOffer.strOfferFriendlyName) {
                    return (1*sortDirectionControl);
                }else if (strOfferFriendlyName < compareToOffer.strOfferFriendlyName) {
                    return (-1*sortDirectionControl);
                }else if (strOfferFriendlyName == compareToOffer.strOfferFriendlyName){
                    return 0;
                }
            }else if(sortColumn == SORT_BY_PRODUCT_FREQUENCY){ //sort by the product frequency
                if (offerProductFrequencey > compareToOffer.offerProductFrequencey) {
                    return (1*sortDirectionControl);
                }else if (offerProductFrequencey < compareToOffer.offerProductFrequencey) {
                    return (-1*sortDirectionControl);
                }else if (offerProductFrequencey == compareToOffer.offerProductFrequencey){
                    return 0;
                }
            }else if(sortColumn == SORT_BY_WEEKLY_PRICE){
               if(weeklyPrice != null){
                   if(compareToOffer.weeklyPrice == null) return 1*sortDirectionControl;
                   if(weeklyPrice > compareToOffer.weeklyPrice){
                       return (1*sortDirectionControl);
                   }else if(weeklyPrice == compareToOffer.weeklyPrice){
                       return 0;
                   }
               }
               return -1*sortDirectionControl;
            }else if(sortColumn == SORT_BY_BASE_PRICE){
                if(basePrice != null){
                   if(compareToOffer.basePrice == null) return 1*sortDirectionControl;
                   if(basePrice > compareToOffer.basePrice){
                       return (1*sortDirectionControl);
                   }else if(basePrice == compareToOffer.basePrice){
                       return 0;
                   }
               }
               return -1*sortDirectionControl;
           }
           return -1*sortDirectionControl;
        }
    }

    //Wrapper class for invoice information
    public class InvoiceWrapper{
        public Integer invoiceNo{get;set;}
        public Decimal invoiceAmount{get;set;}
    }
}
