/**
* Author:       Michal Kwika(Tquila)
* Date:         30/07/2015
* Description:  this class is the constructor for the redirection for Account Payment Management flow
* ******************* Change Log *******************
* Modified by           Change Date
* Sally El Ghoul        21/10/2015 remove the Related_Quote_ID__c from subscription object
* Michal Kwika          20/01/2016
* Michal Kwika          17/02/2016 added workaround to Produciton payment page
* Mantas Grigaliunas    14/10/2016 modified addNewPaymentMethod() method  
* Wiktor Czykin         18/05/2017 added payment method cancellation option
* Mantas Grigaliunas    22/06/2017 added paypal payment method
**/
public with sharing class Account_BillingPM_SummaryExtCt {

    public String index  { get; set; }
    public String accId  { get; set; } // Id value of Account passed through URL parameter
    public String zId    { get; set; }
    public String billId { get; set; }

    public Zuora__CustomerAccount__c billingAccount           { get; private set; }
    public zqu.NotificationOptions notificationOptions        { get; set; }
    public Map<String, PaymentSelectorCombo> paymentMap       { get; set; }
    public Map<String, PaymentSelectorCombo> paypalPaymentMap { get; set; }

    public Boolean bShowPage                    { get; set; }
    public Boolean bIsProductDayPass            { get; set; }
    public Boolean hasAccountActiveSubscription { get; set; }
    public Boolean bIsRemovePaymentAvailable    { get; set; }

    private Zuora.zApi zapi;
    private Account sfdcAccount;
    @TestVisible private Zuora__Subscription__c subscription;
 
    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        30/07/2015
    Function    Main Constructor of page - getting Billing Account record
    ******************* Change Log *******************
    Modified by     Change Date
    Wiktor Czykin   17/05/2017  //modified the logic to also allow page entry for lapsed daypass subscribers
    ****************************************************************************************/
    public Account_BillingPM_SummaryExtCt(){
        this.zapi = new Zuora.zApi();
        if(!Test.isRunningTest()){
            zapi.zlogin();
        }

        this.bIsRemovePaymentAvailable = false;
        this.bIsProductDayPass         = false;
        this.bShowPage                 = false;

        //Following code is part of the BillingAccountManager controllerfrom Zuora unmanaged package
        //Instantiate and fill out information related to the pop-up notification
        notificationOptions = new zqu.NotificationOptions();
        notificationOptions.isPopup = true;
        notificationOptions.continueAction = 'continueToNextPage();';
        notificationOptions.backLabel = 'Remain';
        notificationOptions.successTitle = 'Success!';
        notificationOptions.failureTitle = 'Error!';

        this.accId = System.currentPageReference().getParameters().get('id');
        List<Account> lstAccount = [SELECT Id, Card_Details_Stored__c, Product__c, Product__r.Name FROM Account where Id = :this.accId];
        if(lstAccount.isEmpty() || lstAccount[0].Product__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_No_account_or_product_for_id));
            return;
        }
        this.sfdcAccount = lstAccount[0];
        this.accId = this.sfdcAccount.Id;
        this.queryBillingAccountAndMostRecentSubscription();

        if(this.billingAccount == null || this.subscription == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Subscription_No_billing_account_or_related_subscription));
            return;
        }

        this.zId = this.billingAccount.Zuora__Zuora_Id__c;
        this.hasAccountActiveSubscription = this.isAccountReadyToManagePaymentMethod();
        this.bIsProductDayPass = this.isProductDaypass();

        if(!this.hasAccountActiveSubscription && !this.bIsProductDayPass){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.BillingAccount_AccountDoesNotMeetCriteria));
            return;
        }
        this.bShowPage = true;

        //Get Payment Methods from Zuora and generates the selector objectects
        paymentMap = new Map<String, PaymentSelectorCombo>();
        paypalPaymentMap = new Map<String, PaymentSelectorCombo>();
        try {
            this.queryPaymentMethod();
            this.checkIsRemovePaymentAvailable();
        } catch (Exception e) { 
            this.paymentMap = new Map<String, PaymentSelectorCombo>();
            this.paypalPaymentMap = new Map<String, PaymentSelectorCombo>();
        }

        //If a display message exists from another page, display it upon page load.
        if (System.currentPageReference().getParameters().containsKey('displayMessage')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.currentPageReference().getParameters().get('displayMessage')));
        }
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        18/05/2017
    Function    Retrieves account related subscription and billing account
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private void queryBillingAccountAndMostRecentSubscription(){
        //check active subscription related to the account 
        List<Zuora__Subscription__c> lstSubscription = [SELECT  Id, 
                                                                Name, 
                                                                Zuora__CustomerAccount__c,
                                                                Zuora__Status__c
                                                            FROM Zuora__Subscription__c 
                                                            WHERE Zuora__Account__c = :this.sfdcAccount.Id 
                                                            ORDER BY CreatedDate desc LIMIT 1];
        if(lstSubscription.isEmpty()){
            return;
        }
        this.subscription = lstSubscription[0]; 

        List<Zuora__CustomerAccount__c> lstBillingAccount = [SELECT Id, 
                                                                    Name, 
                                                                    Zuora__AccountNumber__c, 
                                                                    Zuora__Account__c, 
                                                                    Zuora__Zuora_Id__c, 
                                                                    Zuora__CreditCardNumber__c, 
                                                                    Zuora__DefaultPaymentMethod__c 
                                                                FROM Zuora__CustomerAccount__c 
                                                                WHERE Id = :this.subscription.Zuora__CustomerAccount__c
                                                                ORDER BY CreatedDate DESC 
                                                                LIMIT 1];
        if(lstBillingAccount.isEmpty()){
            return;
        }
        this.billingAccount = lstBillingAccount[0];
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        30/07/2015
    Function    Method to check if Account has active digital subscription
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       17/05/2017  //modified to use prefetched subscription
    ****************************************************************************************/
    private Boolean isAccountReadyToManagePaymentMethod(){
        Set<String> sActiveSubStatuses = new Set<String>{Constants.SUBSCRIPTION_ACTIVE_STATUS, Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS};
        if (sActiveSubStatuses.contains(this.subscription.Zuora__Status__c)){
            return true;
        }
        return false;
    } 

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        18/05/2017
    Function    Method to check if Account related product (currrent product) has daypass related rate plan
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private Boolean isProductDaypass(){
        //check if the current product can be sold as daypass - if so, condition met
        Map<String, Offers_Frequency_Rate_Plan_Map__mdt> mapRatePlanMapping = GlobalQueries.retrieveFrequencySetting();
        Offers_Frequency_Rate_Plan_Map__mdt mapping = mapRatePlanMapping.get(Constants.OFFER_FREQUENCY_DAILY);
        if(mapping == null || String.isBlank(mapping.Target_Rate_Plan_Name__c)){
            return false;
        }

        List<zqu__ProductRatePlan__c> lstProductRatePlan = [SELECT Id 
                                                                FROM zqu__ProductRatePlan__c 
                                                                WHERE zqu__ZProduct__c = :this.sfdcAccount.Product__c 
                                                                AND Name = :mapping.Target_Rate_Plan_Name__c];
        if(lstProductRatePlan.isEmpty()){
            return false;
        }
        return true;
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        17/05/2017
    Function    checks if selected payment method is applicable for removal
    ******************* Change Log *******************
    Modified by         Change Date
    Mantas Grigaliunas  22/06/2017 added paypalPaymentMap 
    ****************************************************************************************/
    public void checkIsRemovePaymentAvailable(){
        this.bIsRemovePaymentAvailable = false;
        //check if selection was made and card details flag is ticked and account product is of daypass type 
        if(this.index == null || !this.sfdcAccount.Card_Details_Stored__c || !this.bIsProductDayPass){
            return;
        }
        //make sure selected most recent subscription product name actually matches product related to account
        //not quite sure this check makes much sense, so can be binned (replaced) if turns out problematic
        List<Zuora__SubscriptionProductCharge__c> lstChargesForProductName = [SELECT    Id 
                                                                                    FROM Zuora__SubscriptionProductCharge__c 
                                                                                    WHERE Zuora__Account__c = :this.accId 
                                                                                    AND Zuora__Subscription__c = :this.subscription.Id 
                                                                                    AND Zuora__Product__r.Name = :this.sfdcAccount.Product__r.Name
                                                                                    LIMIT 1];

        if(lstChargesForProductName.isEmpty()) return;

        String subInvoiceItemsQuery = 'SELECT Id, InvoiceId, ChargeAmount, TaxAmount, ServiceStartDate, ServiceEndDate ' 
                                    + 'FROM InvoiceItem WHERE SubscriptionNumber = \''+this.subscription.Name+'\'';
        List<Zuora.zObject> allInvoiceItemsList = ZuoraUtilities.queryToZuora(zApi, subInvoiceItemsQuery);

        Set<String> subInvoiceIdsSet = new Set<String>();
        for(Zuora.zObject invoiceItem : allInvoiceItemsList){
            subInvoiceIdsSet.add((String)invoiceItem.getValue('InvoiceId'));
        }

        String invoicePayemntsQuery = 'SELECT Id, PaymentId, InvoiceId FROM InvoicePayment';
        List<Zuora.zObject> invoicePaymentsList = ZuoraUtilities.queryMultipleZItems(zApi, subInvoiceIdsSet, invoicePayemntsQuery, 'InvoiceId', null);

        //get payment ids set and define a map of payment id to invoice
        Set<String> paymentIdsSet = new Set<String>();
        for(Zuora.zObject invoicePayment : invoicePaymentsList){
            String paymentId = (String)invoicePayment.getValue('PaymentId');
            paymentIdsSet.add(paymentId);
        }

        String paymentsQuery = 'SELECT Id, Amount, RefundAmount, Status, CreatedDate, GatewayState, PaymentMethodId, Type FROM Payment';
        List<Zuora.zObject> paymentsList = ZuoraUtilities.queryMultipleZItems(zApi, paymentIdsSet, paymentsQuery, 'Id',  null);
        Set<String> paymentMethodIds = new Set<String>();
        for(Zuora.zObject payment : paymentsList){
            paymentMethodIds.add((String)payment.getValue('PaymentMethodId'));
        }

        if(this.index != null && paymentMethodIds.contains(this.index) 
            && (paymentMap.containsKey(this.index) || paypalPaymentMap.containsKey(this.index))){
                this.bIsRemovePaymentAvailable = true;
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    Method to set Method as default on Billing Account in Zuora
    ******************* Change Log *******************
    Modified by         Change Date
    Michal Kwika        13/10/2015
    Michal Kwika        20/01/2016
    Wiktor Czykin       18/05/2017  //nothing much
    Mantas Grigaliunas  22/06/2017 added paypalPaymentMap 
    ****************************************************************************************/
    public void setAsDefault() {
        if (index == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.BillingAccount_Error_NoPMSelected));
            return;
        }
        //Get selected Payment Method
        Zuora__PaymentMethod__c pm = (paymentMap.get(index) != null ? paymentMap.get(index).paymentMethod : paypalPaymentMap.get(index).paymentMethod);
        //If Payment Method is already Default, return error message
        if (pm.Zuora__DefaultPaymentMethod__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.BillingAccount_Error_ThisPMisDefaultAlready));
            return;
        }
        
        try {
            //Invoke zuora utility set default payment method
            if(!Test.isRunningTest()){
                Zuora_Utility.setDefaultPaymentMethod(zapi, this.zId, pm.Zuora__External_Id__c , true);
            }
            //Re-query for data to get updated data
            this.queryPaymentMethod();
            CoreAPICalloutUtility.SendObjectEvent(Constants.CORE_API_CHANGE_DEFAULT_PAYMENT_METHOD_EVENT, Constants.ZUORA_ACCOUNT_OBJECT_NAME, this.accId);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    Method to add new payment method to
    ******************* Change Log *******************
    Modified by         Version     Change Date   
    Michal Kwika        1.1         18/02/2016 - added workaround for Prod (EMEA in host)
    Mantas Grigalunas   1.2         14/10/2016 - change the method to use custom setting
    ****************************************************************************************/
    public PageReference addNewPaymentMethod() {
        Configuration__c CONFIG = Configuration__c.getOrgDefaults();
        PageReference pr = new PageReference(CONFIG.Visualforce_Base_Url__c + Constants.PAGE_ACCOUNT_MANAGE_PAYMENT_METHOD);
        pr.getParameters().put('id',  this.billingAccount.Id);
        pr.getParameters().put('zId', this.zId);
        pr.getParameters().put('accountId', this.accId);      
        return pr;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    Just go back to Account detail page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference goBack() {
        PageReference pageref = new PageReference('/' + this.accId);
        pageref.setRedirect(true);
        return pageref;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    Based on unmnaged package - Queries Zuora for the current Billing Account
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       17/05/2017  //minor clean-up
    ****************************************************************************************/
    public Zuora__CustomerAccount__c queryAccount() {
        List<Zuora.zObject> accounts;
        //Create the sObject and fills it with data from the zObject after
        Zuora__CustomerAccount__c acc = new Zuora__CustomerAccount__c();
        String zoql = 'SELECT Name, AccountNumber, Id, DefaultPaymentMethodId FROM Account WHERE Id = \'' + this.zId + '\'';
        if (!Test.isRunningTest()) {
            //Query for payments from Zuora
            accounts = this.zapi.zquery(zoql);
            acc.put(Zuora__CustomerAccount__c.Name, accounts.get(0).getValue('Name'));
            acc.put(Zuora__CustomerAccount__c.Zuora__AccountNumber__c, accounts.get(0).getValue('AccountNumber'));
            acc.put(Zuora__CustomerAccount__c.Zuora__Zuora_Id__c, accounts.get(0).getValue('Id'));
            acc.put(Zuora__CustomerAccount__c.Zuora__DefaultPaymentMethod__c, accounts.get(0).getValue('DefaultPaymentMethodId'));
        } 
        return acc;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    Based on unmnaged package - Queries Zuora for all Payment Methods in the current
                Billing Account that are Credit Cards
    ******************* Change Log *******************
    Modified by         Change Date
    Michal Kwika        24/08/2015
    Wiktor Czykin       17/05/2017  //added filter for Closed payment methods and moved here logic for wrapper preparation
    Mantas Grigaliunas  22/06/2017 added Paypal payment method
    ****************************************************************************************/
    public void queryPaymentMethod() {
        List<Zuora.zObject> paymentMethods;
        //Login to Zuora
        if (!Test.isRunningTest()) {
            zapi.zlogin();
        }
        String zoql = 'SELECT AchAbaCode, AchAccountName, AchAccountNumberMask, AchAccountType, AchBankName, CreditCardHolderName, CreditCardMaskNumber, CreditCardType, CreditCardExpirationMonth, CreditCardExpirationYear, Id, CreditCardAddress1, CreditCardAddress2, CreditCardState, CreditCardCountry, CreditCardPostalCode, CreditCardCity, Type';
        //add bank transfer fields
        zoql += ', BankTransferAccountName, BankTransferAccountType,  BankTransferAccountNumberMask, BankTransferAccountName, BankPostalCode, BankStreetName, BankStreetNumber,  BankName';
        zoql += ', PaypalBaid, PaypalEmail, PaypalPreapprovalKey, PaypalType';
        zoql += ' from PaymentMethod where AccountId = \'' + zId + '\' and PaymentMethodStatus != \'Closed\'';
        paymentMethods = ZuoraUtilities.queryToZuora(zapi, zoql);

        //Gets the Default Payment Method Id if one exists.
        String def = '';
        Zuora__CustomerAccount__c zAccount = this.queryAccount();
        if (zAccount.Zuora__DefaultPaymentMethod__c != null) {
            def = zAccount.Zuora__DefaultPaymentMethod__c;
        }

        //Create the list of payment method sObjects
        for (Zuora.zObject payment : paymentMethods) {

            //Create the sObject and fills it with data from the zObject and then adds it to the list.
            String paymentType = (String)payment.getValue('Type');
            String externalId  = (String)payment.getValue('Id');

            Zuora__PaymentMethod__c pm = new Zuora__PaymentMethod__c();
            pm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, externalId);

            if (paymentType == Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE) {
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('CreditCardHolderName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('CreditCardMaskNumber'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardType__c, payment.getValue('CreditCardType'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardExpirationMonth__c, String.valueOf(payment.getValue('CreditCardExpirationMonth')));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardExpirationYear__c, String.valueOf(payment.getValue('CreditCardExpirationYear')));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardAddress1__c , payment.getValue('CreditCardAddress1'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardAddress2__c , payment.getValue('CreditCardAddress2'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardCity__c , payment.getValue('CreditCardCity'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardState__c , payment.getValue('CreditCardState'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardPostalCode__c , payment.getValue('CreditCardPostalCode'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardCountry__c , payment.getValue('CreditCardCountry'));
                pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL);
            } else if (paymentType == Constants.PAYMENT_METHOD_ACH_TYPE) {
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('AchAccountName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('AchAbaCode') + ' ' + payment.getValue('AchAccountNumberMask'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardType__c, payment.getValue('AchAccountType'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardCountry__c , payment.getValue('AchBankName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, payment.getValue('Type'));
            } else if (paymentType == constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE) {
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('BankTransferAccountName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('BankTransferAccountNumberMask'));
                pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL);
            } else if(paymentType == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
                pm.put(Zuora__PaymentMethod__c.Zuora__PaypalBaid__c, payment.getValue('PaypalBaid'));
                pm.put(Zuora__PaymentMethod__c.Zuora__PaypalEmail__c, payment.getValue('PaypalEmail'));
                pm.put(Zuora__PaymentMethod__c.Zuora__PaypalType__c, payment.getValue('PaypalType'));
                pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, Constants.PAYMENT_METHOD_PAYPAL_TYPE);
            }


            if (pm.Zuora__External_Id__c == def) {
                pm.put(Zuora__PaymentMethod__c.Zuora__DefaultPaymentMethod__c, true);
            } else {
                pm.put(Zuora__PaymentMethod__c.Zuora__DefaultPaymentMethod__c, false);
            }

            if(paymentType == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
                paypalPaymentMap.put(externalId, new PaymentSelectorCombo(pm));
            } else {
                paymentMap.put(externalId, new PaymentSelectorCombo(pm));
            }
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    Based on unmnaged package - confirm error, clear messages
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void confirmError(){
        ApexPages.getMessages().clear();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        16/05/2017
    Function    Action support method on payment method option change
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void changeSelection(){
        this.confirmError();
        this.checkIsRemovePaymentAvailable();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        18/05/2017
    Function    actions related to payment method closure - account update, core api callout
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Mantas Grigaliunas  22/06/2017 added paypalPaymentMap 
    ****************************************************************************************/
    public void removePaymentMethod(){
        try{
            update new Account(Id = accId, Card_Details_Stored__c = false);
        }catch(DmlException e){
            ApexPages.addMessages(e);
            return;
        }

        if(paymentMap.containsKey(index)) paymentMap.remove(this.index);
        if(paymentMap.containsKey(index)) paypalPaymentMap.remove(index);
        CoreAPICalloutUtility.sendObjectEvent(Constants.CARD_DETAILS_CHANGE_ACTION_NAME, Account.class.getName(), accId);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Manage_Subscription_Payment_method_removed));
    }

    public Integer getPaymentMapSize(){
        return paymentMap.size();
    }

    public Integer getPaypalPaymentMapSize(){
        return paypalPaymentMap.size();
    }

    /***************************************************************************************
    Developer   Michal Kwika (Tquila)
    Date        31/07/2015
    Function    From unmanaged package - Wrapper class to show data in better way
                Extended for Direct Debit
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Mantas Grigaliunas  22/06/2017  modified the wrapper after paypal method was added 
    ****************************************************************************************/
    public class PaymentSelectorCombo{
        public Zuora__PaymentMethod__c paymentMethod {get; set;}
        public String address {get; set;}
        public String expirationDate {get; set;}

        public PaymentSelectorCombo(Zuora__PaymentMethod__c pm) {
            paymentMethod = pm;
            if (pm.Zuora__Type__c == Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE)
                expirationDate = pm.Zuora__CreditCardExpirationMonth__c + '/' + pm.Zuora__CreditCardExpirationYear__c;
            else
                expirationDate = '';

            address = '';
            if (pm.Zuora__CreditCardAddress1__c != null) {
                address = pm.Zuora__CreditCardAddress1__c;
                if (pm.Zuora__CreditCardAddress2__c != null)
                    address = address + ', ' + pm.Zuora__CreditCardAddress2__c + ',\r\n';
                else
                    address = address + ',\r\n';
            }
            if (pm.Zuora__CreditCardCity__c != null)
                address = address + pm.Zuora__CreditCardCity__c + ', ';
            if (pm.Zuora__CreditCardState__c != null)
                address = address + pm.Zuora__CreditCardState__c + ', ';
            if (pm.Zuora__CreditCardCountry__c != null)
                address = address + pm.Zuora__CreditCardCountry__c;
            if (pm.Zuora__CreditCardPostalCode__c != null)
                address = address + ' ' + pm.Zuora__CreditCardPostalCode__c;
        }
    }
}