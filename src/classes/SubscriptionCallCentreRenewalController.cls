/**
* @author Wiktor Czykin(Tquila)
* @date 20/02/2015
* @description Controller for SubscriptionCallCentreRenewal
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         20/02/2015 //basic clean-up so that the class is even readable
Wiktor Czykin   1.2         29/04/2015 //removed Start_Date__c validation
Wiktor Czykin   1.3         14/07/2015 //updated updateIncentives()
Wiktor Czykin   1.4         29/07/2015 //modified searchAccount()
Wiktor Czykin   1.5         04/09/2015 //modified searchAccount() - label change
Cristina Anghenie1.6        04/09/2015 //modified searchAccount() - stop user using offline renewal if sub offer is not linked to a previous sub
Cristina Anghenie1.7        08/09/2015 //modified saveAndTakePayment() - sub startDate on cheque payment
Cristina Anghenie1.8        11/09/2015 //modified searchSub() - get current sub details
Wiktor Czykin    1.9        20/10/2015 //modified searchSub() - added field to soql
Cristina Anghenie2.0        26/10/2015 //modified saveAndTakePayment() - change start date for cheque only if date in the past
Wiktor Czykin   2.1         02/11/2015 //modified saveAndTakePayment() and saveAccount();
Wiktor Czykin    2.2           11/2015 //modified saveAndTakePayment() - order taken detail wrapper change and MppUtil call replaced old copy pasted method
Wiktor Czykin    2.3           12/2015 //Clean-up related to product hardcoding removal - move of some duplicated methods outside to common TMGUtil
Wiktor Czykin   2.4         19/01/2016 //modified saveAccount()
Pawel Chrzanowski2.5        15/03/2016 //Added Add/Change Email iFrame functionality
Sally ElGhoul    2.6        18/3/2016  //Remove the check for the selected product value as this functionality is used only for print (premi
Wiktor Czykin   2.7         13/04/2016 //defaulted marketing flags to false
Wiktor Czykin   2.8         25/05/2016 //modified saveAndTakePayment()
Wiktor Czykin   2.9         14/06/2016 //added product switch capability plus some cleanup
Wiktor Czykin   3.0         22/06/2016 //modified searchSub() with exception handling, change to globalAccountSearch()
Wiktor Czykin   3.1         07/07/2016 //fix for cheque payment
wiktor Czykin   3.2         23/08/2016 //modified searchSub()
Wiktor Czykin   3.3         06/09/2016 //changed delivery type initialization and added validation on save sub and saveAndTakePayment
Vishant Shah    3.4         07/10/2016 //removed query for cheque as we always want to create a new cheque record Jira - 4710
Wiktor Czykin   3.5         31/10/2016 //added extra flag to ProductSwitchController init
Pawel Chrzanowski 3.6       04/11/2016 //reworked incentives and modified saveAndTakePayment() to include incentives
Wiktor Czykin   3.7         18/01/2017 //modified saveAndTakePayment()
Pawel Chrzanowski   3.8     03/05/2017  //removed unused Marketing Preferences
**/
public with sharing class SubscriptionCallCentreRenewalController implements ProductSwitchSupport{

    //Marketing perms variables
    private static final String s2ndEmail = 'TMG_Promo_Email__c';
    private static final String s2ndPhone = 'TMG_Promo_Phone__c';
    private static final String s2ndPost = 'TMG_Promo_Post__c';
    private static final String s2ndSMS = 'TMG_Promo_SMS__c';
    private static final Integer DEF_YES = 1;
    private static final Integer DEF_NO = 0;
    private static final String NONE = 'None';

    @TestVisible private String selectedDeliveryBeforeEdit;
    @TestVisible private Subscription__c subBeforeEdit;
    @TestVisible private Account accBeforeEdit;
    @TestVisible private String orderMethodBeforeEdit;
    private Map<Id, String> incentiveMap = new Map<Id, String>();
    private String tCode;//this is passed as a parameter to the new subscriber page - need to look up 4 digit code
    private Id tCodeId;
    private Id productId;
    private String selectedProduct = Constants.PRODUCT_PREMIUM;// - required for MPP call, but not stored, so we default to Premium as this process relates to print renewals
    private Id subIdRefresh;
    @TestVisible private Set<String> setDeliveryOptions;

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

    public String displayedPaymentType{get;set;}
    public String preferedStartPaymentDate{get;set;}
    public Id subId {get; set;}
    public List<Account> foundAccounts{get;set;}
    public List<Subscription__c> foundSubscriptions{get;set;}
    public Account accountDetail;
    public Subscription__c subscriptionDetail;
    public Cheque__c cheque{get;set;}
    public Cheque__c chequeBeforeEdit {get;set;}
    public Boolean subEditEnabled = false;
    public Boolean accEditEnabled = false;
    public String paymentFrequency {get;set;}
    public String subscriptionType {get;set;}
    public String surname{ get; set;}
    public String postCode{ get; set;}
    public String tsNumber{ get; set;}
    public Boolean showPermissions{get;set;}
    public Id accountId {get; set;}
    public Boolean displaySearchButton { get; set; }
    public String selectedRetailer{get;set;}
    public String newSelectedRetailer{get;set;}
    public Account retailerAccount;

    //Incentive
    public String selectedIncentive {get;set;}
    public String selectedIncentiveBeforeEdit;
    private Map<String, String> mapIncentiveDescription = new Map<String, String>();
    public Boolean hasIncentives {get;set;}
    public List<SelectOption> activeIncentives {get;set;}
    public SubscriptionIncentiveAssociation__c relatedIncentive {get;set;}
    public String incentiveName {get;set;}
    public String selectedIncentiveReason {get;set;}
    public String selectedIncentiveReasonBeforeEdit;
    public final List<SelectOption> incentiveReasons {get; private set;}

    public String getIncentiveDescription(){
        return mapIncentiveDescription.get(this.selectedIncentive) != null ? mapIncentiveDescription.get(this.selectedIncentive) : '';
    }

    //Retailers
    public Boolean displayRetailers{get;set;}
    public String postcodeRetailSearch{get;set;}
    public Boolean displaySelectedRetailerMsg{get;set;}
    public List<ActiveRetailers> allActiveRetailers{get;set;}
    public Boolean displayRetailerResults{get;set;}
    public String retailerID{get;set;}
    public String paymentType {get;set;}
    public Integer chequePaymentLength{get;set;}

    //Cheque
    public Boolean createNewBatch{get;set;}
    public List<SelectOption> chequeBatchOptions{get;set;}
    public String chequeBatchSelected{get;set;}
    public String chequeBatchBeforeEdit{get;set;}
    public List<SelectOption> orderMethodValues{
        get{
            List<SelectOption> values = new List<SelectOption>{
                new SelectOption(Constants.DIRECTION_INBOUND, Constants.DIRECTION_INBOUND),
                new SelectOption(Constants.ORDER_METHOD_COUPON, Constants.ORDER_METHOD_COUPON)
            };
            return values;
        }
        private set;
    }

    public String selectedOrderMethod {get; set;}
    //add/change email iFrame
    public Boolean showEmailIFrame{get;set;}
    public ProductSwitchController productSwitcher{get;set;}
    //OTC/HND filter validation
    public Boolean bValidDeliveryType{get;set;}
    public List<SelectOption> lstDeliveryOptions{get;set;}

    public Boolean p2ndEmail {
        get {
            if (accountDetail.get(s2ndEmail) == null) {accountDetail.put(s2ndEmail, DEF_NO);}
            if (accountDetail.get(s2ndEmail) == 1) { return true;} else {return false;}
        }
        set {
            if (value) {accountDetail.put(s2ndEmail,1);} else {accountDetail.put(s2ndEmail,0);}
        }
    }

    public Boolean p2ndPhone {
        get {
            if (accountDetail.get(s2ndPhone) == null) {accountDetail.put(s2ndPhone, DEF_NO);}
            if (accountDetail.get(s2ndPhone) == 1) {return true;} else {return false;}
        }
        set {
            if (value) {accountDetail.put(s2ndPhone,1);} else {accountDetail.put(s2ndPhone,0);}
        }
    }
    public Boolean p2ndPost {
        get {
            if (accountDetail.get(s2ndPost)==null) {accountDetail.put(s2ndPost, DEF_NO);}
            if (accountDetail.get(s2ndPost) == 1) {return true;} else {return false;}
        }
        set {
            if (value) {accountDetail.put(s2ndPost,1);} else {accountDetail.put(s2ndPost,0);}
        }
    }
    public Boolean p2ndSMS {
        get {
            if (accountDetail.get(s2ndSMS)==null) {accountDetail.put(s2ndSMS, DEF_NO);}
            if (accountDetail.get(s2ndSMS) == 1) {return true;} else {return false;}
        }
        set {
            if (value) {accountDetail.put(s2ndSMS,1);} else {accountDetail.put(s2ndSMS,0);}
        }
    }

    public String lastUpdateDate {
        get {
            if (this.accountDetail.Permissions_Last_Change_Date__c != null) {
                return this.accountDetail.Permissions_Last_Change_Date__c.format();
            } else {return null;}
        }
    }

    public Boolean getSubEditEnabled(){
        return subEditEnabled;
    }

    public Boolean getAccEditEnabled(){
        return accEditEnabled;
    }

    public Decimal dInitialWeeklyPrice;
    public Id initialProductId;

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public SubscriptionCallCentreRenewalController(){
        this.showPermissions = false;
        this.incentiveReasons = new List<SelectOption>();
        this.incentiveReasons.add(new SelectOption('', NONE));
        for(Schema.PicklistEntry reason : SubscriptionIncentiveAssociation__c.Reason__c.getDescribe().getPickListValues()){
            this.incentiveReasons.add(new SelectOption(reason.getLabel(), reason.getLabel()));
        }
        this.selectedIncentiveReason = '';
        this.showEmailIFrame = false;
    }

    //Method to enable subscriber edit part of page
    public void editAccount(){
        try{
            this.accBeforeEdit = this.accountDetail.clone(true);
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return;
        }
        this.accEditEnabled = true;
    }

    public void cancelAccountEdit(){
        this.accEditEnabled = false;
        this.searchAccount();

        if(subBeforeEdit != null){
            this.subscriptionDetail = this.subBeforeEdit;
            this.cheque = this.chequeBeforeEdit;
            this.chequeBatchSelected = this.chequeBatchBeforeEdit;
            this.preferedStartPaymentDate = this.subscriptionDetail.PaymentDate__c;
            this.displayedPaymentType = this.subscriptionDetail.Payment_Type__c;
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - Method to save subscriber record
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/11/2015  //added unique email check
    Wiktor Czykin   1.2         19/01/2016  //added salutation override
    ****************************************************************************************/
    public void saveAccount(){
        try{
            if(this.checkMandatory()){
                if(!GlobalQueries.checkIsEmailUnique(this.accountDetail.Id, this.accountDetail.PersonEmail)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Email_duplicate_error));
                    return;
                }

                if(String.isNotBlank(this.accountDetail.Title__c)){
                    this.accountDetail.Salutation = this.accountDetail.Title__c;
                }
                update this.accountDetail;
                this.accBeforeEdit = this.accountDetail.clone(true);
                this.accEditEnabled = false;
            }
        }catch(System.DMLException dmlex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlex.getDmlMessage(0)));
            return;
        }catch(Exception ex) {
            System.debug('Exception: '+ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return;
        }
    }

    public void editSub(){
        try{
            this.subBeforeEdit = this.subscriptionDetail.clone(true);
            this.chequeBeforeEdit = this.cheque.clone(true);
            this.chequeBatchBeforeEdit = this.chequeBatchSelected;
            this.selectedIncentiveBeforeEdit = this.selectedIncentive;
            this.selectedIncentiveReasonBeforeEdit = this.selectedIncentiveReason;
            this.selectedDeliveryBeforeEdit = this.selectedDelivery;
            this.orderMethodBeforeEdit = this.selectedOrderMethod;
            this.subEditEnabled = true;
            this.displayRetailerResults = false;
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return;
        }
    }

    public void cancelSubEdit(){
        this.subEditEnabled = false;
        if(this.subBeforeEdit != null){
            this.subscriptionDetail = this.subBeforeEdit;
        }

        if(this.chequeBeforeEdit != null){
            this.cheque = this.chequeBeforeEdit;
        }

        if(this.chequeBatchBeforeEdit != null){
            this.chequeBatchSelected = this.chequeBatchBeforeEdit;
        }

        selectedIncentive = selectedIncentiveBeforeEdit;
        selectedIncentiveReason = selectedIncentiveReasonBeforeEdit;
        this.selectedDelivery = this.selectedDeliveryBeforeEdit;
        this.selectedOrderMethod = this.orderMethodBeforeEdit;
        this.displayedPaymentType = this.subscriptionDetail.Payment_Type__c;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.4
    Function - current subscription record save
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         23/02/2015 //added Start_Date__c validation - removed afterwards
    Cristina A      1.2         14/10/2015 //clean up code
    Wiktor Czykin   1.3         14/06/2016 //added labels and re-init of search on after save to update view with weekly price and product, added DmlException handling
    Wiktor Czykin   1.4         06/09/2016 //added delivery type validation
    Pawel Chrzanowski  1.5      02/11/2016 //put upsertSubscriptionIncentive() before searchAccount()
    ****************************************************************************************/
    public void saveSub(){
        try{
            if(this.subscriptionDetail.IsContinuous__c && this.subscriptionDetail.Payment_Type__c != Constants.SUB_PMETHOD_DD){
                this.subscriptionDetail.MPP_CC_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
            } else{
                this.subscriptionDetail.MPP_CC_Frequency__c = null;
            }

            if(this.displayedPaymentType.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE)){
                if((this.createNewBatch == null || this.createNewBatch == false) && !TMGUtil.isDataValid(this.chequeBatchSelected)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_No_cheque_batch_selected));
                    return ;
                }

                if(String.isBlank(this.cheque.Name_on_Cheque__c)){
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Cheque_name_blank));
                   return;
                }

                if(String.isBlank(this.cheque.Account_Number__c)){
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Cheque_account_number_blank));
                   return;
                }

                if(String.isBlank(this.cheque.Sort_Code__c)){
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Sort_code_empty));
                   return;
                }

                if(String.isBlank(this.cheque.Ref_Number_on_Cheque__c)){
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Cheque_reference_number_blank));
                   return;
                }
            }

            //Incentive reason is required if an incentive has been selected
            if(!String.isEmpty(this.selectedIncentive) && this.selectedIncentive != NONE && String.isEmpty(this.selectedIncentiveReason)){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Incentive_reason_required_if_incentive_is_selected));
                return;
            }

            if(String.isBlank(this.selectedOrderMethod)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Order_method_is_required));
                return;
            }else{
                this.subscriptionDetail.Order_Taken_Method__c = this.selectedOrderMethod;
            }

            this.validateDeliveryType();
            if(!this.bValidDeliveryType){
                return;
            }

            try{
                this.subscriptionDetail.PaymentDate__c = this.preferedStartPaymentDate;
                this.subscriptionDetail.Payment_Type__c = this.displayedPaymentType;

                if (this.displayedPaymentType == Constants.SUB_PMETHOD_DD){
                    this.subscriptionDetail.MPP_DD_Frequency__c = this.paymentFrequency;
                    this.subscriptionDetail.MPP_CC_Frequency__c = null;
                }else{
                    this.subscriptionDetail.MPP_CC_Frequency__c = this.paymentFrequency;
                    this.subscriptionDetail.MPP_DD_Frequency__c = null;
                }

                if (!this.subscriptionDetail.IsContinuous__c){
                    this.subscriptionDetail.MPP_DD_Frequency__c = null;
                    this.subscriptionDetail.MPP_CC_Frequency__c = null;
                }

                //Validation rule means that only 'HND' can have a retailer. Therefore, if we swap from HND to OTC, remove any associated retailer
                if(this.selectedDelivery == Constants.DELIVERYTYPE_HND && String.isBlank(this.newSelectedRetailer)){
                    this.subscriptionDetail.Retailer__c = this.newSelectedRetailer;
                } else if(this.selectedDelivery == Constants.DELIVERYTYPE_OTC){
                    //Retailer is only allowed for HND
                    this.subscriptionDetail.Retailer__c = null;
                    this.newSelectedRetailer = null;
                }
                this.subscriptionDetail.Delivery_Type__c = this.selectedDelivery;

                if(!this.validateContinuousFlagLogic(subscriptionDetail)){
                    return;
                }
                this.dInitialWeeklyPrice = this.subscriptionDetail.Weekly_Price__c;
                this.initialProductId = this.subscriptionDetail.Product__c;

                update this.subscriptionDetail;
                this.subIdRefresh = this.subscriptionDetail.Id;
                this.subBeforeEdit = this.subscriptionDetail.clone(true);
                this.upsertSubscriptionIncentive();
                this.searchAccount();
            }catch(DmlException ex){
                ApexPages.addMessages(ex);
                return;
            }catch(Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
                return;
            }
            this.subEditEnabled = false;
        }catch(DmlException ex){
            ApexPages.addMessages(ex);
            return;
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return;
        }
    }

    @TestVisible private Boolean checkMandatory(){
        if((this.accountDetail.RecordType.Name != Constants.RECTYPE_ACCOUNT_SCHOOL && String.isBlank(this.accountDetail.FirstName)) || String.isBlank(this.accountDetail.LastName) || String.isBlank(this.accountDetail.PersonMailingStreet) || String.isBlank(this.accountDetail.PersonMailingCity) || String.isBlank(this.accountDetail.PersonMailingPostalCode)){
            String message = '';
            if(accountDetail.RecordType.Name != Constants.RECTYPE_ACCOUNT_SCHOOL){
                message = 'First Name, ';
            }
            message += 'Last Name, Mailing Street, Mailing City, Postal Code are mandatory!';

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, message));
            return false;
        }
        return true;
    }

    public void toggleIsContinuous(){
        if(!String.isBlank(this.selectedOrderMethod)){
            this.subscriptionDetail.IsContinuous__c = (this.selectedOrderMethod.equalsIgnoreCase(Constants.ORDER_METHOD_COUPON)?false:this.subscriptionDetail.IsContinuous__c);
        }
    }

    public Boolean getAccountDetailsFound(){
        if(this.accountDetail.Id == null){
            return true;
        } else {
            return false;
        }
    }
    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - //Retailers search engine
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/06/2016 //added constant, moved here utilities as was only used in this method
    ****************************************************************************************/
    public PageReference retrieveAllRetailers(){
        try{
            UtilitiesForSubscriptions subUtils = new UtilitiesForSubscriptions();
            subUtils.fastRetrieveRetailers(postcodeRetailSearch, true);
            this.displayRetailers = subUtils.displayRetailers;
            this.allActiveRetailers = subUtils.allActiveRetailers;
            this.displayRetailerResults = true;
        }catch(Exception e){
            System.debug('TMGLOG::SubscriptionCallCentreRenewalController:retrieveAllRetailers:exception:' + e);
        }
        return null;
    }

    public void selectRetailerByID(){
        try{
            if(String.isBlank(this.retailerID)) return;

            //We clear the results from the search engine
            if(this.allActiveRetailers != null){
                this.allActiveRetailers.clear();
            }
            this.retailerAccount = UtilitiesForSubscriptions.getRetailerFromRETID(this.retailerID);
            this.newSelectedRetailer = this.retailerAccount.Id;
            this.selectedRetailer = this.retailerAccount.Id;
            this.displaySelectedRetailerMsg = true;
            this.displayRetailerResults = true;
        }catch(Exception errSaveRetailerUsingID){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_No_retailers_found));
        }
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - //Click the radio button in front of a Retailer after selecting HND
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/06/2016 //removed useless debugs
    ****************************************************************************************/
    public PageReference selectRetailer(){
        try{
            if (this.retailerAccount == null){
                this.retailerAccount = new Account();
            }
            this.retailerAccount = UtilitiesForSubscriptions.getRetailerAcc(selectedRetailer);
            this.newSelectedRetailer =  this.retailerAccount.Id;
            this.selectedRetailer = this.retailerAccount.Id;
            this.subscriptionDetail.Retailer__c = this.retailerAccount.Id;
        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_No_retailers_found));
        }
        return null;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.4
    Function - Global Search functionality for account
    Modified by         Version     Change Date
    Cristina Anghenie    1.1        01/10/2015  //clean up the code
    Wiktor Czykin        1.2        14/06/2016  //added labels, changed few ifs - minor clean-up
    Wiktor Czykin        1.3        22/06/2016  //added escepe quotes for tsnumber param
    Wiktor Czykin        1.4        07/07/2016  //nullification of the cheque fix
    ****************************************************************************************/
    public void globalAccountSearch(){
        this.subIdRefresh = null;
        //if either LastName or Postcode is not empty the other one is required
        if(String.isBlank(this.surname) && String.isBlank(this.postCode) && String.isBlank(this.tsNumber)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Missing_search_criteria_for_account));
            return;
        }
        // Check that both LastName and postcode are fillled in case of a lastname/postcode search
        if(String.isBlank(this.tsNumber) && (String.isBlank(this.surname) || String.isBlank(this.postCode))){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Subscriber_search_last_name_and_post_code_mandatory));
            return;
        }

        this.foundAccounts = new List<Account>();
        this.accountDetail = new Account();
        this.foundSubscriptions = new List<Subscription__c>();

        String query = 'select   Name, Salutation, Subscriber_Number_static__c, PersonEmail, Guid__c, '+
                                '(select Id from Subscriptions1__r where Previous_Subscription__c != null and Subscription_Status__c = \'' + Constants.SSTATUS_OFFERED + '\' ' +
                            ' order by CreatedDate desc limit 1)' +
                            ' from Account where ';

        if(String.isNotBlank(this.tsNumber)){
            query += ' Subscriber_Number_static__c = \'' +  String.escapeSingleQuotes(this.tsNumber) + '\'';
            this.foundAccounts = Database.query(query);
        } else if(String.isNotBlank(this.surname) && String.isNotBlank(this.postCode)) {
            this.surname = this.surname.trim();
            this.postCode = this.postCode.trim();
            String tempName = '%' + String.escapeSingleQuotes(this.surname) + '%';
            String tempPostCode = '%' + String.escapeSingleQuotes(this.postCode) + '%';
            query += ' LastName like \'' + tempName + '\' ' + ' and PersonMailingPostalCode like \'' + tempPostCode + '\' ';
            this.foundAccounts = Database.query(query);
        }

        this.displaySearchButton = false;
        if(this.foundAccounts.size() == 1 && !foundAccounts[0].Subscriptions1__r.isEmpty()){
            this.displaySearchButton = true;
            this.accountId = this.foundAccounts[0].Id;
            this.showPermissions = true;
            this.searchAccount();
            if(this.foundSubscriptions.size() == 1){
                this.subId = this.foundSubscriptions[0].Id;
                this.searchSub();
            }
        }else if(!this.foundAccounts.isEmpty()){
            //if there are any offered subs that have a previous sub linked to any of the accounts returned display the search button
            for(Account accs : this.foundAccounts){
                if (accs.Subscriptions1__r.size() > 0){
                    this.displaySearchButton = true;
                    break;
                }
            }
        }
        this.showPermissions = false;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.5
    Function - Search for account for the flow
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         29/07/2015 //added single quotes escaping
    Wiktor Czykin       1.2         04/09/2015 //replaced 1 error message
    Cristina Anghenie   1.3         04/09/2015 //update foundAccount query to get the subscription list
    Wiktor Czykin       1.4         14/06/2016 //clean-up, added check for re-init of the same subscription with subIdRefresh variable
    Wiktor Czykin       1.5         07/07/2016  //nullification of the cheque fix
    Pawel Chrzanowski   1.6         03/05/2017  //removed unused Marketing Preferences
    ****************************************************************************************/
    public void searchAccount() {
        this.foundAccounts = new List<Account>();
        this.accountDetail = new Account();
        this.subscriptionDetail = new Subscription__c();
        this.foundSubscriptions = new List<Subscription__c>();

        if(this.accountId == null) return;

        List<Account> lstAccount = [select Name, PersonTitle, Title__c, Salutation, RecordType.Name, Preferred_Phone_Contact__pc, Phone, PersonMobilePhone, PersonHomePhone,
                                        Subscriber_Number_static__c, LastName, FirstName, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode,
                                        PersonMailingCountry, Permissions_Last_Change_Date__c, TMG_Promo_SMS__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Promo_Email__c,
                                        PersonContactId, PersonEmail, Guid__c,
                                        (select Id from Subscriptions1__r where Previous_Subscription__c != null and Subscription_Status__c = :Constants.SSTATUS_OFFERED
                                     order by CreatedDate desc limit 1)
                                     from Account where Id = :this.accountId];
        if(lstAccount.isEmpty()) return;

        this.accountDetail = lstAccount[0];
        this.showPermissions = true;
        this.foundAccounts.add(this.accountDetail);
        this.foundSubscriptions = [select   Name,
                                            Subscriber__c,
                                            Weekly_Price__c,
                                            Subscription_Duration_Picklist__c,
                                            Delivery_Type__c,
                                            Payment_Type__c,
                                            Start_Date__c,
                                            End_Date__c,
                                            Duration__c,
                                            TCode__c,
                                            TCode__r.Name,
                                            Product__c
                                        from Subscription__c
                                        where Subscriber__c = :this.accountId
                                        and Subscription_Status__c = :Constants.SSTATUS_OFFERED
                                        and Previous_Subscription__c != null];
        if(this.foundSubscriptions.size() == 1){
            this.subId = this.foundSubscriptions[0].Id;
            this.searchSub();
        }else if(this.foundSubscriptions.size() > 1 && this.subIdRefresh != null){
            for(Subscription__c sub : this.foundSubscriptions){
                if(sub.Id == this.subIdRefresh){
                    this.subId = sub.Id;
                    this.searchSub();
                }
            }
        }

        this.chequePaymentLength = 365;
        if(this.cheque == null || this.subIdRefresh == null){
            this.cheque = new Cheque__c();
            this.chequeBatchSelected = null;
        }
        chequeBatchOptions = new List<SelectOption>{new SelectOption('', '')};
        for (Cheque_Batch__c batch : [select Name from Cheque_Batch__c where Batch_Closed_Date__c = null order by Name, CreatedDate desc limit 990]){
            chequeBatchOptions.add(new SelectOption(batch.Name, batch.Name));
        }

        this.accEditEnabled = false;
        this.subEditEnabled = false;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 2.0
    Function - search for selected subscription
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         23/02/2015 //added next available start date fetching and extra field in soql
    Wiktor Czykin   1.2         29/04/2015 //removed next available start date fetching
    Cristina A.     1.3         11/09/2015 //query current sub details
    Wiktor Czykin   1.4         20/10/2015 //added Renewal_Price_Override__c
    Wiktor Czykin   1.5         14/06/2016 //added initialiazation of product switch component
    Wiktor Czykin   1.6         22/06/2016 //added handling of ProductSwitchControllerException
    Wiktor Czykin   1.7         07/07/2016 //nullification of the cheque fix
    Wiktor Czykin   1.8         23/08/2016 //modified the read from Order_Taken_Method__c value
    Wiktor Czykin   1.9         06/09/2016 //added initialization of delivery types
    Vishant Shah    2.0         07/10/2016 //removed query for cheque as we always want to create a new cheque record Jira - 4710
    Wiktor Czykin   2.1         31/10/2016 //modified init of ProductSwitchController
    ****************************************************************************************/
    public void searchSub(){
        this.subscriptionDetail = [select   Id,
                                            Subscriber__c,
                                            Subscriber__r.Id,
                                            Weekly_Price__c,
                                            Previous_Price__c,
                                            Previous_Subscription_Expiry__c,
                                            Subscription_Status__c,
                                            FirstRenewal__c,
                                            PaymentDate__c,
                                            Previous_Subscription__c,
                                            Previous_Subscription__r.Name,
                                            Previous_Subscription__r.Start_Date__c,
                                            Previous_Subscription__r.End_Date__c,
                                            Previous_Subscription__r.Weekly_Price__c,
                                            Previous_Subscription__r.Product__c,
                                            Previous_Subscription__r.Renewal_Product_Override__c,
                                            Previous_Subscription__r.Renewal_Price_Override__c,
                                            Subscription_Duration_Picklist__c,
                                            MPP_DD_Frequency__c,
                                            Order_Taken_Method__c,
                                            Delivery_Type__c,
                                            Payment_Type__c,
                                            Start_Date__c,
                                            End_Date__c,
                                            Duration__c,
                                            Retailer__c,
                                            TCode__c,
                                            TCode__r.Name,
                                            IsContinuous__c,
                                            MPP_CC_Frequency__c,
                                            If_Is_Renewal_Binary__c,
                                            TCode_Product__c,
                                            Product__c
                                        from Subscription__c
                                        where Id = :this.subId];
        if(String.isNotBlank(this.subscriptionDetail.Order_Taken_Method__c) && (this.subscriptionDetail.Order_Taken_Method__c == Constants.ORDER_METHOD_COUPON || this.subscriptionDetail.Order_Taken_Method__c == Constants.DIRECTION_INBOUND)){
            this.selectedOrderMethod = this.subscriptionDetail.Order_Taken_Method__c;
        }else if(subscriptionDetail.Payment_Type__c.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE)){
            this.selectedOrderMethod = Constants.ORDER_METHOD_COUPON;
        }else{
            this.selectedOrderMethod = Constants.DIRECTION_INBOUND;
        }
        if(subscriptionDetail.Payment_Type__c.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE)){
            this.subscriptionDetail.IsContinuous__c = false;
        }

        this.preferedStartPaymentDate = this.subscriptionDetail.PaymentDate__c;
        this.displayedPaymentType = this.subscriptionDetail.Payment_Type__c;
        this.tcode = this.subscriptionDetail.TCode__r.Name;
        this.tCodeId = this.subscriptionDetail.TCode__c;
        this.initialProductId = this.subscriptionDetail.Product__c;
        this.dInitialWeeklyPrice = this.subscriptionDetail.Weekly_Price__c;

        if(this.subscriptionDetail.IsContinuous__c){
            this.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        }else if(this.subscriptionDetail.Subscription_Duration_Picklist__c == Constants.SUB_DURATION_52){
            this.subscriptionType = Constants.SUBSCRIPTIONTYPE_52WEEKS;
        }else{
            this.subscriptionType= Constants.SUBSCRIPTIONTYPE_26WEEKS;
        }

        if(this.subscriptionDetail.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            this.paymentFrequency = (this.subscriptionDetail.MPP_DD_Frequency__c != null)?this.subscriptionDetail.MPP_DD_Frequency__c:Constants.DD_COL_FREQ_QUARTERLY;
        }else{
            this.paymentFrequency = Constants.DD_COL_FREQ_MONTHLY;
        }

        this.newSelectedRetailer = this.subscriptionDetail.Retailer__c;
        this.displayRetailerResults = false;
        this.displaySelectedRetailerMsg = false;

        //Get the most recent incentive related to this subscription
        List<SubscriptionIncentiveAssociation__c> lstSia = [SELECT Reason__c, Incentive_Description__c, Incentive__r.Name, Subscriber__c
                                                            FROM SubscriptionIncentiveAssociation__c
                                                            WHERE Subscription__c = :subscriptionDetail.Id
                                                            ORDER BY CreatedDate DESC LIMIT 1];
        if(!lstSia.isEmpty()){
            relatedIncentive = lstSia[0];
        }else{
            relatedIncentive = null;
        }
        this.updateIncentives();

        if(this.cheque == null || this.subIdRefresh == null){
            this.cheque = new Cheque__c();
        }

        //Anytime the Details button is pressed, the sub data should revert to non-edit mode
        this.subEditEnabled = false;
        try{
            this.productSwitcher = new ProductSwitchController(this, this.initialProductId, this.tCodeId, true, true);
        }catch(ProductSwitchController.ProductSwitchControllerException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
        }

        this.selectedDelivery = this.subscriptionDetail.Delivery_Type__c;
        if(this.selectedDelivery == Constants.DELIVERYTYPE_OTC){
            this.newSelectedRetailer = null;
            this.selectedRetailer = null;
        }
        if(this.selectedDelivery == Constants.DELIVERYTYPE_HND && String.isBlank(this.newSelectedRetailer)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Retailer_required_for_home_delivery));
        }
        this.initDeliveryOptions();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/09/2016
    Version - 1.0
    Function - Init of delivery type options based on subscription related product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void initDeliveryOptions(){
        if(this.subscriptionDetail == null) throw new TelegraphApplicationException(Label.Wrong_method_call);
        String sParam;
        if(this.subscriptionDetail.Product__c != null){
            List<zqu__ZProduct__c> lstProductVoucherDelivery = [select Id, Voucher_Delivery_Type__c from zqu__ZProduct__c where Id = :this.subscriptionDetail.Product__c and Voucher_Delivery_Type__c != null];
            if(!lstProductVoucherDelivery.isEmpty()){
                sParam = lstProductVoucherDelivery[0].Voucher_Delivery_Type__c;
            }
        }
        this.lstDeliveryOptions = UtilitySelectOptionsSubscriptions.getDeliveryOptions(sParam);
        if(this.lstDeliveryOptions == null) throw new TelegraphApplicationException(Label.Offline_Acquisition_Renewal_Not_able_to_detect_delivery_types);
        this.setDeliveryOptions = new Set<String>();
        for(SelectOption so : this.lstDeliveryOptions){
            this.setDeliveryOptions.add(so.getValue());
        }
        this.validateDeliveryType();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 05/09/2016
    Version - 1.0
    Function - validation of delivery type vs product available delivery types
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @TestVisible private void validateDeliveryType(){
        if(this.subscriptionDetail != null && String.isNotBlank(this.selectedDelivery) && !this.setDeliveryOptions.isEmpty() && this.setDeliveryOptions.contains(this.selectedDelivery)){
            this.bValidDeliveryType = true;
            return;
        }
        this.bValidDeliveryType = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Not_supported_delivery_type_for_selected_product));
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.3
    Function - preparation of custom incentives list
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/07/2015 //added extra condition to Incentives soql to match lookup filter
    Sally ElGhoul   1.2         22/03/2016 //get the incentives from the tcode product incentive
    Wiktor Czykin   1.3         31/10/2016 //modified so that incentives are refreshed with product change
    ****************************************************************************************/
    public void updateIncentives(){
        this.activeIncentives = new List<SelectOption>{new SelectOption(NONE, NONE)};
        hasIncentives = true;

        //This if else statement can be removed later on after all data migration is done and complete but now to avoid any issues we agreed to leave the old logic for now
        if(subscriptionDetail.Product__c != null && subscriptionDetail.TCode__c != null){
            //get the incentive based on the subscription tcode and subscription product
            List<TCode_Product_Incentive__c> lstProductTcodeIncentives = GlobalQueries.getProductTcodeIncentives(subscriptionDetail.TCode__c, subscriptionDetail.Product__c);
            for(TCode_Product_Incentive__c incentiveProdObj : lstProductTcodeIncentives){
                if(incentiveProdObj.Is_Incentive_Valid_For_Renewal__c){
                     activeIncentives.add(new SelectOption(incentiveProdObj.Incentive__c, incentiveProdObj.Incentive_Name__c));
                     mapIncentiveDescription.put(incentiveProdObj.Incentive__c, incentiveProdObj.Incentive_Description__c);
                }
            }
        }else{
            for(Incentive__c inc: [SELECT Name, Incentive_Description__c FROM Incentive__c
                                   WHERE Is_Valid_For_Renewal__c = true AND Validity_Status__c = true]){
                activeIncentives.add(new SelectOption(inc.Id, inc.Name));
                mapIncentiveDescription.put(inc.Id, inc.Incentive_Description__c);
            }
        }

        incentiveName = activeIncentives[0].getLabel();
        selectedIncentive = activeIncentives[0].getValue();
        selectedIncentiveReason = '';

        //select relative incentive if it exists
        if(relatedIncentive != null){
            for(SelectOption s : activeIncentives){
                if(s.getLabel() == relatedIncentive.Incentive__r.Name){
                    incentiveName = relatedIncentive.Incentive__r.Name;
                    selectedIncentive = relatedIncentive.Incentive__c;
                    selectedIncentiveReason = relatedIncentive.Reason__c;
                    break;
                }
            }
        }
    }

    public Subscription__c getSubDetail(){
        return subscriptionDetail;
    }

    public PageReference fetchAccountDetails(){
        return null;
    }

    public Account getAccountDetail(){
        return this.accountDetail;
    }

    public void savePerms(){
        this.accountDetail.Permissions_Last_Change_Date__c = System.today();
        try{
            this.accountId = this.accountDetail.Id;
            update accountDetail;
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            return;
        }
        requery();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 04/11/2016
    Method to upsert Incentive
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         03/05/2017  //removed unused Marketing Preferences
    ****************************************************************************************/
    public void upsertSubscriptionIncentive(){
        if(relatedIncentive == null && selectedIncentive != NONE){
           //create new incentive
           SubscriptionIncentiveAssociation__c sia = new SubscriptionIncentiveAssociation__c();
           sia.Incentive__c = selectedIncentive;
           sia.Subscriber__c = accountDetail.Id;
           sia.Subscription__c = subscriptionDetail.Id;
           sia.Reason__c = selectedIncentiveReason;
           insert sia;
       }else if(relatedIncentive != null && selectedIncentive != NONE && selectedIncentive != relatedIncentive.Incentive__c){
           //update current incentive
           relatedIncentive.Incentive__c = selectedIncentive;
           relatedIncentive.Subscriber__c = accountDetail.Id;
           relatedIncentive.Subscription__c = subscriptionDetail.Id;
           relatedIncentive.Reason__c = selectedIncentiveReason;
           update relatedIncentive;
       }else if(relatedIncentive != null && selectedIncentive == NONE){
           //delete current incentive
           delete relatedIncentive;
       }
    }

    @TestVisible private Boolean validSelectedIncentive(){
        if(!String.isBlank(this.selectedIncentive) && String.isBlank(this.selectedIncentiveReason)){
            return false;
        } else {
            return true;
        }
    }

    @TestVisible private void requery() {
        this.accountDetail = [select Name, PersonTitle, Title__c, RecordType.Name, Salutation, Preferred_Phone_Contact__pc, Phone, PersonMobilePhone, PersonHomePhone,
                                        Subscriber_Number_static__c, LastName, FirstName, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode,
                                        PersonMailingCountry, Permissions_Last_Change_Date__c, TMG_Promo_SMS__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Promo_Email__c,
                                        PersonContactId, Guid__c, PersonEmail
                                    from Account
                                    where Id = :this.accountId];
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - setting marketing flags on account record
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         13/04/2016  //modified so that loyalty flags are set as well based on their values and not just set to true by default
    Pawel Chrzanowski   1.2         03/05/2017  //removed unused Marketing Preferences
    ****************************************************************************************/
    public void integerizeFlags(){
        accountDetail.TMG_Promo_Email__c = Integer.valueOf(accountDetail.TMG_Promo_Email__c);
        accountDetail.TMG_Promo_Phone__c = Integer.valueOf(accountDetail.TMG_Promo_Phone__c);
        accountDetail.TMG_Promo_Post__c = Integer.valueOf(accountDetail.TMG_Promo_Post__c);
        accountDetail.TMG_Promo_SMS__c = Integer.valueOf(accountDetail.TMG_Promo_SMS__c);
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 2.4
    Function - payment processing
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         23/02/2015 //added Start_Date__c validation
    Cristina Anghenie   1.2         13/08/2015 //send the correct subscription start date to MPP if the date is in the past
    Cristina Anghenie   1.3         03/09/2015 //set the subscriptionDetails status to PENDING if cheque record was succesfully upserted
    Wiktor Czykin       1.4         04/09/2015 //removed reference to ErrorMessages__c
    Cristina Anghenie   1.5         08/09/2015 //set subscription start date to the second monday from today when payment type is cheque
    Cristina Anghenie   1.6         26/10/2015 //dont change sub start date if payment type is cheque but start date is today or in the future
    Wiktor Czykin       1.7         02/11/2015 //added validation for person email uniqueness
    Wiktor Czykin       1.8            11/2015 //modified call to getOrderTakenFieldMap() to be a call to MppUtil static method and modified the wrapper it returns
    Sally ElGhoul       1.9         18/3/2016  //Remove the check for the selected product value as this functionality is used only for print (premium)
    Wiktor Czykin       2.0         25/05/2016 //Added entitlements queueable for CREATE_SAM scenario
    Wiktor Czykin       2.1         14/06/2016 //Added labels, DmlException handling
    Wiktor Czykin       2.2         05/06/2016 //Added delivery type validation
    Pawel Chrzanowski   2.3         18/11/2016 //Added incentives to parameters
    Wiktor Czykin       2.4         18/01/2017 //Fixed incentives parameters passed
    Pawel Chrzanowski   2.5         03/05/2017 //removed unused Marketing Preferences
    ****************************************************************************************/
    public PageReference saveAndTakePayment(){
        this.accEditEnabled = false;
        this.subEditEnabled = false;

        if(!GlobalQueries.checkIsEmailUnique(this.accountDetail.Id, this.accountDetail.PersonEmail)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Email_duplicate_error));
            return null;
        }
        this.validateDeliveryType();
        if(!bValidDeliveryType){
            return null;
        }

        Account subscriber = this.accountDetail;
        SAMUtil samUtil = null;
        //if there isn't a guid parameter in the url take guid from the account details info
        String Guid = String.isBlank(ApexPages.currentPage().getParameters().get('Guid')) ? subscriber.Guid__c : ApexPages.currentPage().getParameters().get('Guid');

        if (!Test.isRunningTest()){
            // Get the Guid if set on the Existing Account (= Already Linked with SAM)
            samUtil = new SAMUtil();
            if(String.isNotBlank(subscriber.PersonEmail)){
                try{
                    SAMUtil.SAMAccountResult samAccount = samUtil.getExistingSAMAccount(subscriber.PersonEmail);
                    System.debug('### SAM GUID: ' + samAccount.guid);
                    if(samAccount.entitlementStatus != null && samAccount.entitlementStatus.equals('ACTIVE')){
                        List<Account> accSAMList = [SELECT  Id,
                                                            PersonEmail,
                                                            Account.Guid__c
                                                        FROM Account
                                                        WHERE PersonEmail = :subscriber.PersonEmail
                                                        AND Account.Guid__c = NULL];
                        if(accSAMList.size() == 1){
                            Guid = samAccount.guid;
                        }else{
                            //start date must be in the future, and the status should not be active or pending
                            if (this.subscriptionDetail.Start_Date__c <= System.today()){
                                if(!(this.subscriptionDetail.Subscription_Status__c.equals(Constants.SSTATUS_ACTIVE) || this.subscriptionDetail.Subscription_Status__c.equals(Constants.SSTATUS_PENDING))){
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Active_subscription_in_SAM_error + samAccount.guid));
                                    return null;
                                }
                            }
                        }
                    }else{
                        Guid = samAccount.guid;
                    }
                }catch(System.CalloutException ce){
                    System.debug(LoggingLevel.ERROR,'Problem calling EventBroker->SAM getExistingSAMAccount with email: ' + subscriber.PersonEmail);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Offline_Renewal_Get_existing_SAM_account_issue, new List<String>{subscriber.PersonEmail})));
                    return null;
                }catch(System.NullPointerException e){
                    System.debug('### Cannot find active user in SAM: ' + e);
                }catch(WebserviceUtil.SamException e){
                    System.debug(LoggingLevel.ERROR, 'Problem (2) calling SAM getExistingSAMAccount with email: ' + subscriber.PersonEmail);
                    if(e.getError().errorMessage.contains('ACCOUNT_LOCKED')) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.SAM_Account_locked_error));
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Offline_Renewal_Get_existing_SAM_account_issue, new List<String>{subscriber.PersonEmail})));
                    }
                    return null;
                }
            }
        }
        subscriber.Guid__c = Guid;

        if(this.subscriptionDetail != null && this.subscriptionDetail.Id == null){
            this.subscriptionDetail= [select Id, TCode_Product__c, Subscriber__c, Subscriber__r.Id,
                                        Weekly_Price__c, Previous_Price__c, Previous_Subscription_Expiry__c,
                                        FirstRenewal__c, PaymentDate__c,
                                        Previous_Subscription__c, Subscription_Duration_Picklist__c,
                                        MPP_DD_Frequency__c, Delivery_Type__c,
                                        Payment_Type__c, Start_Date__c, End_Date__c, Duration__c,
                                        Retailer__c,
                                        TCode__r.Name,
                                        IsContinuous__c, MPP_CC_Frequency__c
                    from Subscription__c s
                    where Id = :subId];
        }

        //Get order taken fields for passing back to MPP.
        MppUtil.OrderTakenDetails mppFieldMap = MppUtil.getOrderTakenFieldMap(UserInfo.getUserId(), Constants.CONST_DSOSOrderTakenCompany, SelectedOrderMethod);
        this.subscriptionDetail.Order_Taken_Date__c = Date.today();
        this.subscriptionDetail.Order_Taken_By_Company__c = mppFieldMap.byCompany;
        this.subscriptionDetail.Order_Taken_By_User_Department__c = mppFieldMap.byUser;
        this.subscriptionDetail.Order_Taken_Method__c = mppFieldMap.orderMethod;

        String sRenewalOffer = Constants.TCODE_DEFAULT_RENEWAL_RECORD_NAME;
        General__c renewalTCodeNameSetting = General__c.getInstance(Constants.GENERAL_RENEWAL_TCODE_NAME);
        if(renewalTCodeNameSetting != null && String.isNotBlank(renewalTCodeNameSetting.Value__c)){
            sRenewalOffer = renewalTCodeNameSetting.Value__c;
        }
        List<TCodeManagement__c> lstTCode = [select Id from TCodeManagement__c where Type__c = :Constants.TCODE_TYPE_RENEWAL and Valid__c = true and Name = :sRenewalOffer limit 1];
        if(lstTCode.isEmpty()) throw new TelegraphApplicationException('Unable to identify renewal offer.');

        this.subscriptionDetail.TCode__c = lstTCode[0].Id;

        String paymentStartDate;//required for MPP call, but not in renewal
        String selectedOffer;//required for MPP call, but not for renewal
        String tsNumber = this.accountDetail.Subscriber_Number_static__c;
        Double weekly_price = this.subscriptionDetail.Weekly_Price__c;
        Date preferedStartDate = SubscriptionTriggerHandler.findNextStartDate(this.subscriptionDetail);
        Id subid = this.subscriptionDetail.id;

        if(this.subscriptionDetail.Payment_Type__c == Constants.SUB_PMETHOD_CC){
            this.paymentType = Constants.SUB_ACQUISITION_PAYMENT_CC;
        } else if(this.subscriptionDetail.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            this.paymentType = Constants.SUB_ACQUISITION_PAYMENT_DD;
            this.subscriptionDetail.MPP_DD_Frequency__c = this.paymentFrequency;
            this.subscriptionDetail.MPP_CC_Frequency__c = null;
        }else{
            this.paymentType = this.subscriptionDetail.Payment_Type__c;
        }

        this.preferedStartPaymentDate = this.subscriptionDetail.PaymentDate__c;
        this.displayedPaymentType = this.subscriptionDetail.Payment_Type__c;

        if (this.subscriptionDetail.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            this.subscriptionDetail.MPP_DD_Frequency__c = this.paymentFrequency;
            this.subscriptionDetail.MPP_CC_Frequency__c = null;
        }else{
            this.subscriptionDetail.MPP_CC_Frequency__c = this.paymentFrequency;
            this.subscriptionDetail.MPP_DD_Frequency__c = null;
        }

        if (!this.subscriptionDetail.IsContinuous__c){
            this.subscriptionDetail.MPP_DD_Frequency__c = null;
            this.subscriptionDetail.MPP_CC_Frequency__c = null;
        }

        if(this.subscriptionDetail.IsContinuous__c){
            this.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        } else if(this.subscriptionDetail.Subscription_Duration_Picklist__c == Constants.SUB_DURATION_52){
            this.subscriptionType = Constants.SUBSCRIPTIONTYPE_52WEEKS;
        }else{
            this.subscriptionType = Constants.SUBSCRIPTIONTYPE_26WEEKS;
        }
        this.tcode = this.subscriptionDetail.TCode__r.Name;

        //Set payment details (this also calls updateIncentives, so comment out that call below)
        this.checkPaymentState();
        if(ApexPages.hasMessages()){
            return null;
        }

        if(!this.validateContinuousFlagLogic(this.subscriptionDetail)){
            return null;
        }

        // Checking that LastName is only Letters
        Pattern MyPattern = Pattern.compile('^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$');

        Matcher MyMatcher = MyPattern.matcher(subscriber.LastName);
        if (!MyMatcher.matches()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Surname_validation));
            return null;
        }

        if(subscriber.FirstName != null){
            MyMatcher = MyPattern.matcher(subscriber.FirstName);
            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_First_name_validation));
                return null;
            }
        }
        //This process only deals with Individual (non-digital) subscription
        subscriber.RecordTypeID = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());

        String subscriberStatus = subscriber.Subscription_Status__c;
        subscriber.Origin__c = Constants.SUBSCRIBER_ORIGIN_FLOW_OFFLINE;
        subscriber.Wave_ID__c = this.tCode;

        // The Customer could have an active Account already
        if(subscriber.Subscriber_Digital_Status__c == null){
            subscriber.Subscriber_Digital_Status__c = Constants.SUBSCRIBER_INACTIVE_STATUS;
        }

        subscriber.TMG_Promo_Email__c = Integer.valueOf(accountDetail.TMG_Promo_Email__c);
        subscriber.TMG_Promo_Phone__c = Integer.valueOf(accountDetail.TMG_Promo_Phone__c);
        subscriber.TMG_Promo_Post__c = Integer.valueOf(accountDetail.TMG_Promo_Post__c);
        subscriber.TMG_Promo_SMS__c = Integer.valueOf(accountDetail.TMG_Promo_SMS__c);

        //This is a test to see if a subscriber exists with the Guid that's been created - not relevant to renewal
        if(TMGUtil.isDataValid(subscriber.Guid__c) && !TMGUtil.isDataValid(subscriber.Id) || TMGUtil.isDataValid(subscriber.Guid__c) && subscriberStatus == Constants.SSTATUS_INACTIVE){
            try{
                List<Account> accSAMList = Database.query('SELECT Id, Name, PersonEmail, Account.Guid__c FROM Account '
                        + ' WHERE Account.Guid__c = \'' + subscriber.Guid__c + '\''
                        + (TMGUtil.isDataValid(tsNumber) ? ' AND Subscriber_Number_static__c != \'' + tsNumber + '\'' : ''));

                if(accSAMList.size() > 0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is already a subscriber with the GUID: '
                        + subscriber.Guid__c + ' SFDC Link: <a href="/' + accSAMList[0].Id + '">' + accSAMList[0].Name + '</a>'));
                    return null;
                }
            }catch(Exception e){
                System.debug('### No Accounts found for SAM GUID:  ' + subscriber.Guid__c);
            }
        }

           // Continuous and 52 weeks are both weekly price * 52
        String selectedPrice = (this.subscriptionType == Constants.SUBSCRIPTIONTYPE_26WEEKS) ? (String.valueOf(weekly_Price * 26)): (String.valueOf(weekly_Price * 52));

        // Get Preferred Payment date should already be filled in if this is an offered subscription renewal
        // Interestingly it isn't actually a date at all, rather a 2 character text field holding the preferred payment day - 1 or 15
        this.preferedStartPaymentDate = this.subscriptionDetail.PaymentDate__c;
        this.displayedPaymentType = this.subscriptionDetail.Payment_Type__c;

        // Calculate the Payment start date
        Date tmpStartDate = preferedStartDate;
        if(this.subscriptionDetail.isContinuous__c){
            tmpStartDate = calculatePaymentStartDate(preferedStartDate, this.preferedStartPaymentDate);
        }
        paymentStartDate = tmpStartDate.format();
        this.subscriptionDetail.MPP_Scheduled_First_Payment_Date__c = tmpStartDate;

        // Check Price configuration
        if(selectedPrice == null || selectedPrice == 'null'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Price_error));
            return null;
        }

        // This identifies the message that should be displayed in the confirmation page
        String action;
        String paymentMethod = (this.paymentType == Constants.SUB_ACQUISITION_PAYMENT_CC)?Constants.MPP_PAYMENTMETHOD_CC:Constants.MPP_PAYMENTMETHOD_DD;

        // Prepare the values for MPP
        PageReference pr = new PageReference(Page.MppPaymentFrame.getUrl()
            +'?selectedProduct='    + selectedProduct
            +'&email='              + (subscriber.PersonEmail == null ? '':EncodingUtil.urlEncode(subscriber.PersonEmail,'UTF-8'))
            +'&title='              + (subscriber.Salutation == null ? '':EncodingUtil.urlEncode(subscriber.Salutation,'UTF-8'))
            +'&firstName='          + (subscriber.FirstName == null ? '':EncodingUtil.urlEncode(subscriber.FirstName,'UTF-8'))
            +'&lastName='           + (subscriber.LastName == null ? '':EncodingUtil.urlEncode(subscriber.LastName,'UTF-8'))
            +'&price='              + (selectedPrice == null ? '':EncodingUtil.urlEncode(selectedPrice,'UTF-8'))
            +'&subscriptionType='   + (this.subscriptionType == null ? '':EncodingUtil.urlEncode(this.subscriptionType,'UTF-8'))
            +'&PaymentMethod='      + (paymentMethod == null ? '':EncodingUtil.urlEncode(paymentMethod,'UTF-8'))
            +'&PaymentFrequency='   + (paymentFrequency == null ? '':EncodingUtil.urlEncode(paymentFrequency,'UTF-8'))
            +'&paymentStartDate='   + (paymentStartDate == null ? '':EncodingUtil.urlEncode(paymentStartDate,'UTF-8'))
            +'&TCode='              + (this.tCode == null ? '':EncodingUtil.urlEncode(this.tCode,'UTF-8'))
            +'&incentiveId='        + ''
            +'&incentiveDescription='+ ((String.isBlank(this.selectedIncentive) || this.selectedIncentive == Constants.OC_NONE)? '':EncodingUtil.urlEncode(this.getIncentiveDescription() ,'UTF-8'))
            +'&Guid='               + (Guid == null ? '':EncodingUtil.urlEncode(Guid,'UTF-8'))
            +'&isRenew=true');
        System.debug('TMGLOG::SubscriptionCallCentreRenewal:saveAndTakePayment:CURRENT GUID: ' + subscriber.Guid__c);
        System.debug('TMGLOG::SubscriptionCallCentreRenewal:saveAndTakePayment:Subscribe:'+JSON.serialize(subscriber));

        //This logic checks to see if a payment has already been made by a new subscriber - not relevant for renewal
        // No payment for Active Account
        if((TMGUtil.isDataValid(subscriberStatus) && subscriberStatus.equalsIgnoreCase('active'))){
            // We check if we received a GUID from SAM
            if(subscriber.Guid__c != null && subscriber.Guid__c!= ''){
                // UPDATE (AND LINK) SAM ACCOUNT
                samUtil.updateSamAccount(subscriber, subscriber.Subscriber_Number_static__c, Guid, selectedProduct.toLowerCase(), false);
                action = 'UPDATE_SAM';
            }else{
                // CREATE SAM ACCOUNT
                subscriber.Guid__c = samUtil.createSamAccount(subscriber, subscriber.Subscriber_Number_static__c, selectedProduct.toLowerCase(), false, true);
                action = 'CREATE_SAM';
            }
            pr = new PageReference(Page.MppPaymentConfirm.getUrl()+'?accId='+subscriber.Id +'&subId='+this.subscriptionDetail.Id+ '&paymentStatus=SuccessWithoutPayment&isRenew=true&action='+action);
            if (String.isNotBlank(tsNumber)){
                System.debug('### UPDATING SUBSCRIBER');
                try{
                    update subscriber;
                }catch(Exception ex){
                    System.debug('Exception saveAndTakePayment() : '+ex);
                    if(this.accBeforeEdit != null){
                        this.accountDetail = this.accBeforeEdit;
                    }
                    return null;
                }
                if(action == 'CREATE_SAM'){
                    SubscriptionsWebservicesHandlers.setEntitlements(subscriber.Id);
                }
            }
            return pr;
        }

        //Cheque Start - If Cheque was linked earlier then delete, to recalculate amount via triggers
        if(cheque!=null){
            if(this.displayedPaymentType.equalsIgnoreCase(Constants.SUB_PMETHOD_CHEQUE)){
                try{
                    TMGUtil.processChequePayment(subscriptionDetail.Id, chequeBatchSelected, createNewBatch, Integer.valueOf(subscriptionDetail.Subscription_Duration_Picklist__c), cheque, subscriptionDetail.Weekly_Price__c);
                }catch(Exception e){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Renewal_Cheque_creation_error + e.getMessage()));
                    return null;
                }
                //if cheque record was succesfully upserted set the subscriptionDetails status to PENDING
                this.subscriptionDetail.Subscription_Status__c = Constants.SSTATUS_PENDING;
            }else{
                try{
                    delete cheque;
                    cheque = new Cheque__c();
                }catch(Exception ex){
                    System.debug('Cheque Delete Exception: '+ex);
                }
            }
        }

        try{
            this.upsertSubscriptionIncentive();
            if(this.selectedOrderMethod.equalsIgnoreCase('coupon')){
                subscriptionDetail.TaskCreation__c='Cashposting';
            }
            update this.subscriptionDetail;
        }catch(DMLException e){
            ApexPages.addMessages(e);
            return null;
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return null;
        }

        Boolean bError = false;
        if (String.isNotBlank(tsNumber)){
            System.debug('### UPDATING SUBSCRIBER');
            try{
                update subscriber;
            }catch(DMLException ex){
                ApexPages.addMessages(ex);
                bError = true;
            }catch(Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
                bError = true;
             }
        }
        if(bError){
            if(this.accBeforeEdit!=null){
                this.accountDetail=this.accBeforeEdit;
            }
            return null;
        }

        pr.getParameters().put('accId', subscriber.id);
        pr.getParameters().put('TSNumber', tsNumber);

        // Staff Offer
        String staffName;
        if (selectedOffer == Constants.OFFER_STAFF){
            staffName = ApexPages.currentPage().getParameters().get('staffName');
        }

         //Send only if going through the payment page?
        if(pr.getUrl().contains(Page.MppPaymentFrame.getUrl())){
            pr.getParameters().put('orderTakenMethod', (TMGUtil.isDataValid(mppFieldMap.orderMethod) ? EncodingUtil.urlEncode(mppFieldMap.orderMethod, 'UTF-8') : ''));
            pr.getParameters().put('orderTakenByCompany', (TMGUtil.isDataValid(mppFieldMap.byCompany) ? EncodingUtil.urlEncode(mppFieldMap.byCompany, 'UTF-8') : ''));
            pr.getParameters().put('orderTakenbyUser', (TMGUtil.isDataValid(mppFieldMap.byUser) ? EncodingUtil.urlEncode(mppFieldMap.byUser, 'UTF-8') : ''));

            if(TMGUtil.isDataValid(subId)){
                pr.getParameters().put('subId', subId);
            }
        }

        //Cheque stuff
        if(PaymentType.toLowerCase().equals('cheque')){
            if(TMGUtil.isDataValid(subscriber.PersonEmail)){
                // We check if we received a GUID from SAM
                if(subscriber.Guid__c != null && subscriber.Guid__c!= ''){
                    action = 'UPDATE_SAM';
                }
                else{
                    action = 'CREATE_SAM';
                }
            }else{
                action = '';
            }

            if(!ApexPages.hasMessages()){
                pr = new PageReference(Page.MppPaymentConfirm.getUrl() + '?accId=' + subscriber.id+'&subId='+subscriptionDetail.id+ '&isRenew=true&PaymentStatus=Success&action='
                    + action + '&offeredMsg=<br/><br/>Subscription created successfully.&emailTrigger=true');
            }else{
                pr = null;
            }
        }

        SubscriberPortal.SUB_TRIGGER_FIRED = true;
        Constants.MPP_CALLOUT_DISABLED = true;
        try{
            update subscriber;
        }catch(Exception ex){
            System.debug('Exception saveAndTakePayment() : '+ex);
            if(this.accBeforeEdit != null){
                this.accountDetail = this.accBeforeEdit;
            }
            return null;
        }
        return pr;
    }

    //Translate Country code to Name, extracting from Custom Settings.
    public String getCountryName(){
        String country = '';
        try{
            country = Country_Codes__c.getInstance(this.accountDetail.PersonMailingCountry.toUpperCase()).Country_Name__c;
        }catch(System.NullPointerException e){
            System.debug('### No country code custom setting can be found');
        }
        return country;
    }

    //Read Counties with code from Custom Settings.
    public List<SelectOption> getCountries(){
        List<SelectOption> liOptions = new List<SelectOption>();
        if(this.accountDetail.RecordTypeId == RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName()) ){
            liOptions.add(new SelectOption(Constants.COUNTRY_CODE_GB, Constants.UNITED_KINGDOM_COUNTRY_NAME_VALUE));
        } else {
            for(Country_Codes__c country : [select Name, Country_Name__c from Country_Codes__c order by Display_Order__c, Country_Name__c asc]){
                liOptions.add(new SelectOption(country.Name, country.Country_Name__c));
            }
        }
        return liOptions;
    }

    /*
    *   Returns the Payment Start Date. User input: 1 or 15
    *   1: always next date mont 1st day
    *   15: if today before 15 then its this month's 15th
    *       else Next month's 15th
    */
    @TestVisible private Date calculatePaymentStartDate(Date preferedStartDate, String oneOrFifteen){
        Date paymentDate;
        if(oneOrFifteen == '1'){
            paymentDate = Date.newinstance(preferedStartDate.year(), preferedStartDate.month()+1, 1);
        }else{
            if(preferedStartDate.day() < 15){
                paymentDate = Date.newinstance(preferedStartDate.year(), preferedStartDate.month(), 15);
            }else{
                paymentDate = Date.newinstance(preferedStartDate.year(), preferedStartDate.month()+1, 15);
            }
        }
        if(paymentDate < preferedStartDate){
            paymentDate = paymentDate.addMonths(1);
        }
        return paymentDate;
    }

    /***************************************************************************************
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - preparation of custom incentives list
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/06/2016 //added labels
    ****************************************************************************************/
    public Boolean validateContinuousFlagLogic(Subscription__c sub){
        if(String.isBlank(sub.Subscription_Duration_Picklist__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Missing_duration_error));
            return false;
        }

        if(sub.Payment_Type__c == Constants.SUB_PMETHOD_DD){
            if(!sub.IsContinuous__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Select_is_continuous_for_DD_option));
                return false;
            }
            if(sub.Subscription_Duration_Picklist__c != Constants.SUB_DURATION_52){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Continuous_subscriptions_have_to_be_52_weeks));
                return false;
            }
        }
        if((sub.Payment_Type__c == Constants.SUB_PMETHOD_DD || sub.Payment_Type__c == Constants.SUB_PMETHOD_CC) && sub.IsContinuous__c && sub.Subscription_Duration_Picklist__c != Constants.SUB_DURATION_52){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Continuous_subscriptions_have_to_be_52_weeks));
            return false;
        }
        if(sub.Payment_Type__c != Constants.SUB_PMETHOD_DD && sub.Payment_Type__c != Constants.SUB_PMETHOD_CC && sub.IsContinuous__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_Continuous_flag_only_for_continuous_subscription));
            return false;
        }

        if( sub.IsContinuous__c && sub.Subscription_Duration_Picklist__c != Constants.SUB_DURATION_52){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Renewal_52_weeks_only_for_continuous));
            return false;
        }
        return true;
    }

    public void checkPaymentState(){
        this.preferedStartPaymentDate = null;
        if(this.subscriptionType != Constants.SUBSCRIPTIONTYPE_CONTINUOUS){
            this.paymentFrequency = null;
        }
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
        List<Account> lstAcc = [select PersonEmail from Account where Id = :this.accountDetail.Id];
        if(!lstAcc.isEmpty()){
            this.accountDetail.PersonEmail = lstAcc[0].PersonEmail;
            this.showEmailIFrame = false;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Offline_Acquisition_Account_refetch_error_update));
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 06/05/2016
    Version - 1.0
    Function - implementation of ProductSwitchSupport interface method - changes product Id in context and sets new pricing
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void changeProductId(Id productId){
        if(productId == null) throw new TelegraphApplicationException(Label.Offline_Renewal_Product_switch_error);
        this.subscriptionDetail.Product__c = productId;
        if(this.subscriptionDetail.Product__c != this.initialProductId){
            TCode_Product__c tproduct = GlobalQueries.getTCodeProduct(this.subscriptionDetail.TCode__c, this.subscriptionDetail.Product__c);
            this.subscriptionDetail.TCode_Product__c = tproduct.Id;
            this.subscriptionDetail.Weekly_Price__c = tproduct.Weekly_Price__c;
        }else{
            this.subscriptionDetail.Weekly_Price__c = this.dInitialWeeklyPrice;
        }
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
        if(this.dInitialWeeklyPrice != null && lstProducts != null && !lstProducts.isEmpty()){
            for(TCodeProductWrapper tpw : lstProducts){
                if(tpw.productId == this.initialProductId){
                    tpw.premiumPrice = this.dInitialWeeklyPrice;
                    break;
                }
            }
        }
    }
}