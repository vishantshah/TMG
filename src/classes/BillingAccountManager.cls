/**
* Author:       Unknown
* Date:         Unknown
* Description:  Controller for Refund Tool
*
* ******************* Change Log *******************
* Modified by               Change Date
* Sally ElGhoul         07/09/2015
* Sally ElGhoul         25/09/2015
* Michal Kwika          05/10/2015
* Michal Kwika          03/11/2015
* Wiktor Czykin         11/02/2016 //removed queryExternalPaymentMethod() and whole external methods code as not used anywhere
* Mantas Grigaliunas    20/02/2016 //refactored selectIndex() method to handle the null pointer exceptions if invalid dates are given
*                                    moved zuora test data generation code to Z_TestFactory class
* Mantas Grigaliunas    02/05/2017 //added getNotAllowedForRefundPaymentsSet() method
* Mantas Grigaliunas    28/06/2017 //added Paypal related code
**/
public with sharing class BillingAccountManager {
    
    public String zId {get;set;}
    public String billId {get;set;}
    public String accId {get;set;}
    public Zuora__CustomerAccount__c sfAccount{get;set;}
    public Zuora__CustomerAccount__c zAccount {get;set;}
    public List<Zuora__PaymentMethod__c> zPaymentMethods;
    public List<Zuora.zObject> payments;
    public List<PaymentSelectorCombo> paymentSelect {get;set;}
    public String paymentFrom {get;set;}
    public String paymentTo {get;set;}
    public Integer index {get;set;}
    public zqu.NotificationOptions notificationOptions {get;set;}
    public String paymentMethodRefundId {get;set;}
    public String paymentRefundId {get;set;}
    public List<Zuora__Payment__c> zPayments;
    public boolean ShowPrompt{get; private set;}
    
    //Sally ElGhoul - Change the type of the list to be the wrapper class to include the refund amount
    public List<ZuoraPaymentRefundWrapper> viewedPayments {get;set;}
    
    //Sally ElGhoul - 7 September 2015
    public List<Zuora.zObject> negativeInvoices;
    public list<Zuora__ZInvoice__c> lstViewsNegativeInvoices{get;set;}

    //Michal Kwika - 05/10/2015
    public String invoiceToTransferId {get; set; }
    public Decimal amountInvoiceTransfer {get; set;}
    public String actualPaymentMethodZuoraId {get; set;}
    public String chosenPaymentMethod {get; set;}
    
    /*Zuora API Instance for calling into Zuora directly */
    Zuora.zApi zapi = new Zuora.zApi();

    private Map<String, String> paymentMethodIdToPaymentTypeMap = new Map<String, String>();
    
    /**
    *  Constructor
    */
    public BillingAccountManager(ApexPages.StandardController controller) {
        //Instantiate and fill out information related to the pop-up notification
        notificationOptions = new zqu.NotificationOptions();
        notificationOptions.isPopup = true;
        notificationOptions.continueAction = 'continueToNextPage();';
        notificationOptions.backLabel = 'Remain';
        notificationOptions.successTitle = 'SUCCESS!';
        notificationOptions.failureTitle = 'AN ERROR OCCURRED!';
        
        //Sets inital index to -1 (View all)
        index = -1;
        //Sets the from and to dates for the payment view.
        //Sally El Ghoul - 8 September , we agreed to default the from filter to be 3 months in the past and default the payment to to be one month in the future
        String[] oneMonth = String.valueOf(Date.today().addMonths(-3)).split('-',0); //2015-06-18
        this.paymentFrom = oneMonth[2] + '/' + oneMonth[1] + '/' + oneMonth[0];      //dd/mm/yyyy
        String[] todays = String.valueOf(Date.today().addMonths(1)).split('-',0);
        this.paymentTo = todays[2] + '/' + todays[1] + '/' + todays[0];
        //Get Important Ids from url
        this.billId = System.currentPageReference().getParameters().get('id');
        
        //Get Accounts from SalesForce
        if (!Test.isRunningTest())
            this.sfAccount = ([SELECT Name,Zuora__Balance__c, Zuora__AccountNumber__c, Zuora__Credit_Balance__c, Zuora__Account__c, Zuora__Zuora_Id__c, Zuora__CreditCardNumber__c, Zuora__DefaultPaymentMethod__c from Zuora__CustomerAccount__c where Id = :billId ]).get(0);
        else{
            this.sfAccount = new Zuora__CustomerAccount__c();
            Account tempAcc = Z_TestFactory.makeAccount();
            sfAccount.Zuora__Zuora_Id__c = 'zId';
            sfAccount.Zuora__Account__c = tempAcc.Id;
            this.billId = 'billId';
        }
        //Retrieve important values from the SF account
        this.zId = sfAccount.Zuora__Zuora_Id__c;
        this.accId = sfAccount.Zuora__Account__c;
        //Query for the current billing account
        this.zAccount = queryAccount();
        this.zPaymentMethods = new List<Zuora__PaymentMethod__c>();
        try{
            //Get Payment Methods from Zuora and generates the selector Objects
            this.zPaymentMethods = queryPaymentMethod();
            generatePaymentSelect();     
        }catch(Exception e){
            //create empty payment list and selector list if error occurs
            this.paymentSelect = new List<PaymentSelectorCombo>();
        }
        //Grab past payments from Zuora Database and converts them to SF versions
        try{
            payments = queryPayment();
            convertPayments();
            selectIndex();
        }catch(Exception e) {
            //Throw exception is Zuora error occurs
            throw new zqu.ZQException(e.getMessage());
        }

        //Sally ElGhoul - 7 September 2015, get the negative invoices record from Zuora
        try{
            negativeInvoices = queryNegativeInvoices();
            convertNegativeInvoices();
        }catch(Exception e) {
            //Throw exception is Zuora error occurs
            throw new zqu.ZQException(e.getMessage());
        }
        
        //If a display message exists from another page, display it upon page load.
        if (System.currentPageReference().getParameters().containsKey('displayMessage')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.currentPageReference().getParameters().get('displayMessage')));
        }
    }

    public BillingAccountManager(){}
    
    /**
        Queries Zuora for the current Billing Account
    */
    public Zuora__CustomerAccount__c queryAccount(){
        List<Zuora.zObject> accounts;
        if (!Test.isRunningTest()){
            //Login to Zuora
            zapi.zlogin();
        }

        //Create ZOQL query
        String zoql = 'SELECT Name, AccountNumber, Id, DefaultPaymentMethodId, Balance, TotalInvoiceBalance, CreditBalance from Account where Id = \'' + zId + '\'';
        accounts = ZuoraUtilities.queryToZuora(zapi, zoql);    
        
        //Create the sObject and fills it with data from the zObject
        Zuora__CustomerAccount__c acc = new Zuora__CustomerAccount__c();
        acc.put(Zuora__CustomerAccount__c.Name, accounts.get(0).getValue('Name'));
        acc.put(Zuora__CustomerAccount__c.Zuora__AccountNumber__c, accounts.get(0).getValue('AccountNumber'));
        acc.put(Zuora__CustomerAccount__c.Zuora__Zuora_Id__c, accounts.get(0).getValue('Id'));
        acc.put(Zuora__CustomerAccount__c.Zuora__DefaultPaymentMethod__c, accounts.get(0).getValue('DefaultPaymentMethodId'));
        acc.put(Zuora__CustomerAccount__c.Zuora__Balance__c, accounts.get(0).getValue('Balance'));
        acc.put(Zuora__CustomerAccount__c.Zuora__Credit_Balance__c, accounts.get(0).getValue('CreditBalance'));

        return acc;
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function -   Queries Zuora for all Payment Methods in the current Billing Account that are Credit Cards
    #############Change Log#############
    Modified by         Change Date
    Michal Kwika        03/11/2015 //SUB-1590
    Wiktor Czykin       11/02/2016 //Added else condition to cover unknown/remaining payment methods which allowed removal of queryExternalPaymentMethod()        
    Mantas Grigaliunas  28/06/2017 //added Paypal related code  
    ****************************************************************************************/
    public List<Zuora__PaymentMethod__c> queryPaymentMethod(){
        List<Zuora.zObject> paymentMethods;
        //Login to Zuora
        if (!Test.isRunningTest()){
            zapi.zlogin();
        }
            
        //Create ZOQL query
        String zoql = 'SELECT AchAbaCode, AchAccountName, AchAccountNumberMask, AchAccountType, AchBankName, CreditCardHolderName, CreditCardMaskNumber, ' 
                    + 'CreditCardType, CreditCardExpirationMonth, CreditCardExpirationYear, Id, CreditCardAddress1, CreditCardAddress2, CreditCardState, '
                    + 'CreditCardCountry, CreditCardPostalCode, CreditCardCity, Type, BankTransferAccountNumberMask, BankTransferAccountName, '
                    + 'PaypalBaid, PaypalEmail, PaypalPreapprovalKey, PaypalType '
                    + 'FROM PaymentMethod where AccountId = \'' + zId + '\'';
        paymentMethods = ZuoraUtilities.queryToZuora(zapi, zoql);

        //Gets the Default Payment Method Id if one exists.
        String def;
        if (zAccount.Zuora__DefaultPaymentMethod__c != null){
            def = zAccount.Zuora__DefaultPaymentMethod__c;
        } else {
            def = '';
        }
        
        //Create the list of payment method sObjects
        List<Zuora__PaymentMethod__c> ret = new List<Zuora__PaymentMethod__c>();                    
    
        for (Integer i=0; i<paymentMethods.size(); i++){
            Zuora.zObject payment = paymentMethods.get(i);
            paymentMethodIdToPaymentTypeMap.put((String)payment.getValue('Id'), (String)payment.getValue('Type'));
            String paymentType = (String) payment.getValue('Type');
            //Create the sObject and fills it with data from the zObject and then adds it to the list.
            Zuora__PaymentMethod__c pm = new Zuora__PaymentMethod__c();
            pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, paymentType);
            pm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, payment.getValue('Id'));

            if (paymentType == Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE || paymentType == Constants.PAYMENT_METHOD_DEBIT_CARD_TYPE){
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
            } else if (paymentType == Constants.PAYMENT_METHOD_ACH_TYPE){
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('AchAccountName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('AchAbaCode') + ' ' + payment.getValue('AchAccountNumberMask'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardType__c, payment.getValue('AchAccountType'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardCountry__c , payment.getValue('AchBankName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, payment.getValue('Type'));
            } else if (paymentType == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE){ 
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('BankTransferAccountName'));
                pm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('BankTransferAccountNumberMask'));
                pm.put(Zuora__PaymentMethod__c.Zuora__Type__c, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL);
            } else if (paymentType == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
                pm.put(Zuora__PaymentMethod__c.Zuora__PaypalBaid__c, payment.getValue('PaypalBaid'));
                pm.put(Zuora__PaymentMethod__c.Zuora__PaypalEmail__c, payment.getValue('PaypalEmail'));
                pm.put(Zuora__PaymentMethod__c.Zuora__PaypalType__c, payment.getValue('PaypalType'));
            }

            if (pm.Zuora__External_Id__c == def){
                pm.put(Zuora__PaymentMethod__c.Zuora__DefaultPaymentMethod__c, true);
            } else {
                pm.put(Zuora__PaymentMethod__c.Zuora__DefaultPaymentMethod__c, false);
            }

            ret.add(pm);
        }
        return ret;
    }
        
    /**
        Queries Zuora for all payments associated with the current Billing Account
    */
    public List<Zuora.zObject> queryPayment(){
        if (!Test.isRunningTest()){
            zapi.zlogin();
        }
                
        //Create ZOQL query
        String zoql = 'SELECT Amount, RefundAmount, PaymentNumber, CreatedDate, EffectiveDate, PaymentMethodId, Id, GatewayState from Payment where AccountId = \'' + zId + '\' and Status=\'Processed\'';
        
        if (!Test.isRunningTest()){
            //Query for payments from Zuora
            return zapi.zquery(zoql);
        } else {
            //Generate temporary data for testing when needed
            return Z_TestFactory.createZuoraPayments(
                new List<DateTime>{
                    DateTime.now().addMonths(-2),
                    DateTime.now(),
                    DateTime.now().addDays(20)       
                }
            );            
        }
    }
    
    //Sally ElGhoul 
    public PageReference RefreshUI(){

        return null;
    }
    
    //Sally El Ghoul - 7September 2015
    public list<Zuora.zObject> queryNegativeInvoices(){
        //login to Zuora if not test is runing 
        if (!Test.isRunningTest()){
            zapi.zlogin();
        }
        
        //Create ZOQL query
        String zoql = 'SELECT InvoiceNumber, Balance, PaymentAmount, Amount, RefundAmount, Status, Id from Invoice where Amount<0 and AccountId = \'' + zId + '\' limit 100';
        return ZuoraUtilities.queryToZuora(zapi, zoql);
    }
    
    /**
        Genreate the PaymentSelectorObject needed for the page that allows the user to pick
        different options from the UI in terms of payment methods.
    */
    public void generatePaymentSelect(){
        this.paymentSelect = new List<PaymentSelectorCombo>();

        for(Integer i=0; i<this.zPaymentMethods.size(); i++){
            //Adds in each payment method from the billing account
            this.paymentSelect.add(new PaymentSelectorCombo(zPaymentMethods.get(i), i));
            if(this.zPaymentMethods.get(i).Zuora__DefaultPaymentMethod__c){
                this.index = i;
                this.actualPaymentMethodZuoraId = this.zPaymentMethods.get(i).Zuora__External_Id__c;
                this.chosenPaymentMethod = this.actualPaymentMethodZuoraId;
            }
        }
        
        //Adds in two more "payment methods"
        //One for non-electronic payment methods and one for all payment methods (both electronic and non)
        Zuora__PaymentMethod__c tempPm = new Zuora__PaymentMethod__c();
        tempPm.Zuora__CreditCardHolderName__c = ' View Payments for';
        tempPm.Zuora__CreditCardCountry__c = 'Other Non-Electronic Payment Methods';
        this.paymentSelect.add(new PaymentSelectorCombo(tempPm,-2));
        tempPm.Zuora__CreditCardCountry__c = 'All Payment Methods';
        this.paymentSelect.add(new PaymentSelectorCombo(tempPm,-1));
    }
    
    /**
        Getter for the Billing Account
    */
    public Zuora__CustomerAccount__c getBillingAccount(){
        return sfAccount;
    }
    
    /**
        Getter for Payment Methods w/ attached data for radiobutton and index values
    */
    public List<PaymentSelectorCombo> getPaymentMethods(){
        return paymentSelect;
    }
    
    /**
        Navigate to Add Card Page
    */
    public PageReference addCard(){
        PageReference pr = new PageReference('/apex/New_Credit_Card?field_passthrough2=' + System.currentPageReference().getParameters().get('id') + '&field_accountId=' + zId + '&field_passthrough1=' + billId);
        return pr;
    }
        
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Converts Payments from zObject to sObject and adds them to the current list of 
                view payments if they fall between the to and from dates.
    #############Change Log#############
    Modified by     Version     Change Date
    Sally ElGhoul   1.1         25/09/2015  //Converted the zuora payment object to ZuoraPaymentRefundWrapper
    Wiktor Czykin   1.1         30/03/2015  //just some minor clean-up
    ****************************************************************************************/
    public void convertPayments(){
        this.zPayments = new List<Zuora__Payment__c>();
        //Sally El Ghoul - 25/9/2015 , Change the list type to be the wrapper class
        this.viewedPayments = new List<ZuoraPaymentRefundWrapper>();
        
        //Getting the invoice number from SF because We got an exception when we queries the invoice number from Zuora object and the knowledge center mentions it is just available for create
        Set<String> setExternalPaymentsIds = new Set<String>();
        Map<String, Zuora__Payment__c> mapExternalIdPayment=new Map<String, Zuora__Payment__c>();
        Map<String, Boolean> isPaymentAllowedForRefundMap = new Map<String, Boolean>();

        //get the payment external IDs to query salesforce
        for(Zuora.zObject payment : this.payments){
            setExternalPaymentsIds.add(String.valueof(payment.getValue('Id')));
        }

        isPaymentAllowedForRefundMap = getNotAllowedForRefundPaymentsMap(setExternalPaymentsIds);
        
        //query salesforce using the external Ids
        for(Zuora__Payment__c zuoraPaymentObj : [select Zuora__InvoiceNumber__c, Zuora__EXT_ID__c from Zuora__Payment__c where Zuora__EXT_ID__c in :setExternalPaymentsIds]){
            mapExternalIdPayment.put(zuoraPaymentObj.Zuora__EXT_ID__c, zuoraPaymentObj);
        }
        
        //Iterate through the list of Payments
        for (Integer i=0; i < this.payments.size(); i++){
            //Get the current zObject payment iteration
            Zuora.zObject payment = payments.get(i);
            String paymentId = (String)payment.getValue('Id');
            //Create the sObject and fills it with data from the zObject
            Zuora__Payment__c zp = new Zuora__Payment__c();
            zp.put(Zuora__Payment__c.Zuora__Amount__c, payment.getValue('Amount'));
            zp.put(Zuora__Payment__c.Zuora__PaymentNumber__c, payment.getValue('PaymentNumber'));
            zp.put(Zuora__Payment__c.Zuora__CreatedDate__c, payment.getValue('CreatedDate'));
            zp.put(Zuora__Payment__c.Zuora__EffectiveDate__c, payment.getValue('EffectiveDate'));
            zp.put(Zuora__Payment__c.Zuora__PaymentMethod__c, payment.getValue('PaymentMethodId'));
            zp.put(Zuora__Payment__c.Zuora__External_Id__c, paymentId);
            zp.put(Zuora__Payment__c.Zuora__AppliedCreditBalanceAmount__c, payment.getValue('RefundAmount'));
            zp.put(Zuora__Payment__c.Zuora__GatewayStatus__c, payment.getValue('GatewayState'));
            zp.put(Zuora__Payment__c.ZuoraPaymentMethodId__c, paymentMethodIdToPaymentTypeMap.get((String)payment.getValue('PaymentMethodId')));
            if(mapExternalIdPayment.containsKey(String.valueOf(paymentId))){
                zp.put(Zuora__Payment__c.Zuora__InvoiceNumber__c, mapExternalIdPayment.get(String.valueOf(payment.getValue('Id'))).Zuora__InvoiceNumber__c);
            }else{
                zp.put(Zuora__Payment__c.Zuora__InvoiceNumber__c, '');
            }
            //Iterate through the Payment Methods to find associated Payment Method
            if(isPaymentAllowedForRefundMap.get(paymentId) != null && isPaymentAllowedForRefundMap.get(paymentId)){
                this.zPayments.add(zp);
            }
        }
    }
    
    //Sally ElGhoul - 7 September 2015
    public void convertNegativeInvoices(){
        //convert the negative invoices from zuora to be in the format of salesforce objects
        lstViewsNegativeInvoices=new list<Zuora__ZInvoice__c>();
        for(Zuora.zObject payment : negativeInvoices){
            Zuora__ZInvoice__c addInvoice=new Zuora__ZInvoice__c();
            addInvoice.put(Zuora__ZInvoice__c.Name,payment.getValue('InvoiceNumber'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__Balance2__c,payment.getValue('Balance'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__PaymentAmount__c,payment.getValue('PaymentAmount'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__TotalAmount__c,payment.getValue('Amount'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__RefundedAmount__c,payment.getValue('RefundAmount'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__Status__c,payment.getValue('Status'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__Zuora_Id__c, payment.getValue('Id'));
            lstViewsNegativeInvoices.add(addInvoice);
        }
    }
    
    /**
        Converts date from the format created from the date chooser to the one used in code.
    */
    public Date convertDate(String d){
         String[] splitDate = d.split('/',0);
        //return Date.valueOf(splitDate[2] + '-' + splitDate[0] + '-' + splitDate[1]);
        //newInstance(year, month, date)
        return Date.newInstance(integer.valueof(splitDate[2]), integer.valueof(splitDate[1]), integer.valueof(splitDate[0]));
    }
    
    /**
        Navigate to the Edit Credit Card page
    */
    public PageReference editCards(){
        if (Test.isRunningTest()){
            index=0;
        }
        //If no card is chosen, return error message
        if (index < 0){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No editable Payment Method selected!  Please choose a Payment method that can be edited.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        //Get Payment method chosen
        Zuora__PaymentMethod__c pm = paymentSelect.get(index).PaymentMethod;
        
        if (pm.Zuora__Type__c == 'ACH'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'ACH cannot be editted.  Please choose a different Payment Method!');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        PageReference pr = new PageReference('/apex/Edit_Card?id=' + accId + '&zID=' + zId + '&billId=' + billId + '&pmId=' + pm.Zuora__External_Id__c);
        return pr;
    }
    
    /**
        Deletes the selected Payment Method
    */
    public PageReference deleteCards(){
        if (Test.isRunningTest()){
            //sets value for testing
            index=0;
        }
        //If no card is chosen, return error message
        if (index < 0){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No applicable Payment Method selected!  Please choose a Payment method that can be deleted.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        //Get Payment method chosen
        Zuora__PaymentMethod__c pm = paymentSelect.get(index).PaymentMethod;
        //If Payment Method chosen is default, return error message
        if(pm.Zuora__DefaultPaymentMethod__c == true){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot delete default payment method!');
            ApexPages.addMessage(myMsg);
            return null;
        }
        //Get Zuora Id of the Payment Method being deleted and holds it in an Array
        string obj = String.valueOf(pm.Zuora__External_Id__c);
        string[] toDelete = new string[]{obj};
        List<Zuora.zApi.DeleteResult> results;
        try {
            //Logs into Zuora and deletes the Payment method in Zuora
            if (!Test.isRunningTest()){
                zapi.zlogin();
                results = zapi.zdelete('PaymentMethod', toDelete);
            } else {
                //Create data for testing if needed
                Zuora.zApi.DeleteResult res = new Zuora.zApi.DeleteResult();
                res.Success = false;
                Zuora.zObject error = new Zuora.zObject('Error');
                res.errors = new Zuora.zObject[]{error};
                results = new List<Zuora.zApi.DeleteResult>{};
                results.add(res);
            }
            //Checks results for failues and displays error if they occurs
            for (Zuora.zApi.DeleteResult result : results){
                if (!result.Success){
                    Zuora.zObject[] errors = result.errors;
                    String errorText;
                    for (Zuora.zObject error : errors) {
                        errorText = errorText + (String)error.getValue('Code') + ': ' + (String)error.getValue('Message') + '\n';
                    }
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Failure to update| \n' + errorText);
                    ApexPages.addMessage(myMsg);
                    return null;
                }
            }
            
            //Delete Payment Method from the list in Code and regenerate list of Payment Methods
            paymentSelect.remove(index);
            
            this.zPaymentMethods = queryPaymentMethod();
            generatePaymentSelect();
            index=-1;
        } catch(Exception e){
            //Throws error message is something fails
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        return null;
    }
        
    /**
        Set Default Payment Method
    */
    public PageReference setDefault(){
        if (Test.isRunningTest()){
            //Set value during testing
            index=0;
        }
        //If no card is chosen, error messege is thrown.
        if (index < 0){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No applicable Payment Method selected!  Please choose a Payment method that can be set as the Default Payment Method!');
            ApexPages.addMessage(myMsg);
            return null;
        }
        //Get selected Payment Method
        Zuora__PaymentMethod__c pm = paymentSelect.get(index).PaymentMethod;
        //If Payment Method is already Default, return error message
        if(pm.Zuora__DefaultPaymentMethod__c == true){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Card is already default!');
            ApexPages.addMessage(myMsg);
            return null;
        }
        //Instatiate and current Default Payment Method
        Zuora__PaymentMethod__c current;
        for (Integer i=0; i<paymentSelect.size(); i++){
            if (paymentSelect.get(i).PaymentMethod.Zuora__DefaultPaymentMethod__c == true){
                current = paymentSelect.get(i).PaymentMethod;
            }
        }
        try {
            //Instatiate Account that needs to be changed and fill in Zuora Account Id and new Default Payment Method Id
            Zuora.zObject acc = new Zuora.zObject('Account');
            acc.setValue('Id', zId);
            acc.setValue('DefaultPaymentMethodId', pm.Zuora__External_Id__c);
            List<Zuora.zObject> listAcc = new List<Zuora.zObject>();
            listAcc.add(acc);
            List<Zuora.zApi.SaveResult> results;
            if (!Test.isRunningTest()){
            //Login to Zuora and update Account with new Default Payment Method
                zapi.zlogin();
                results = zapi.zupdate(listAcc);
            } else {
                //Create data during testing when needed
                Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
                res.Success = false;
                Zuora.zObject error = new Zuora.zObject('Error');
                res.errors = new Zuora.zObject[]{error};
                results = new List<Zuora.zApi.SaveResult>{};
                results.add(res);
            }
            //Goes through the results for failures and displays error when they occur
            for (Zuora.zApi.SaveResult result : results){
                if (!result.Success){
                    Zuora.zObject[] errors = result.errors;
                    String errorText;
                    for (Zuora.zObject error : errors) {
                        errorText = errorText + (String)error.getValue('Code') + ': ' + (String)error.getValue('Message') + '\n';
                    }
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Failure to update| \n' + errorText);
                    ApexPages.addMessage(myMsg);
                    if (!Test.isRunningTest())
                        return null;
                }
            }
            
            //Set the current and new Default payment methods to their new statuses
            if (current != null){
                current.Zuora__DefaultPaymentMethod__c = false;
            }
            pm.Zuora__DefaultPaymentMethod__c = true;
            
            //Re-query for data to get updated data
            zAccount = queryAccount();
            zPaymentMethods = queryPaymentMethod();
            generatePaymentSelect();
            
        } catch(Exception e){
            //Throws error if exception occurs
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        return null;
    }
    
    /**
        Navigates to the Payments page to make a payment
    */
    public PageReference makePayment(){
        if (Test.isRunningTest()){
            //Sets test data
            index=0;
        }
        //If no card is chosen, navigate to page without a chosen card
        if (index < 0){
            return new PageReference('/apex/Make_Payment?field_passthrough2=' + System.currentPageReference().getParameters().get('id') + '&field_accountId=' + zId + '&field_passthrough1=' + billId);
        }
        //Gets chosen payment method if applicable
        Zuora__PaymentMethod__c pm = paymentSelect.get(index).PaymentMethod;
        
        //Prevents choosing for expired card
        if (pm.Zuora__Type__c == 'CreditCard'){
            Date expiration = Date.valueOf(pm.Zuora__CreditCardExpirationYear__c + '-' + pm.Zuora__CreditCardExpirationMonth__c + '-1');
            expiration.addMonths(1);
        
            if (expiration < Date.today()){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot use expired card!');
                ApexPages.addMessage(myMsg);
                return null;
            }
        }
        //If card is chosen, navigate to page with the selection as chosen payment method
        return new PageReference('/apex/Make_Payment?field_passthrough2=' + System.currentPageReference().getParameters().get('id') + '&field_accountId=' + zId + '&field_passthrough1=' + billId + '&pmId=' + pm.Zuora__External_Id__c);
    }
        
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Updates the index to that of the chosen Payment Method
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         11/02/2016  //merged -1 and -2 behaviour as external payment methods fetching
                                                method didn't work and its options were not even returned to UI.
    Mantas Grigaliunas  1.2         20/06/2016  //moved filtering ralated code to a separate method 
    ****************************************************************************************/
    public void selectIndex(){

        //clears current viewed payments list and any current messeges
        this.viewedPayments.clear();
        ApexPages.getMessages().clear();

        if (this.index > -1){
            //If index is greater than -1 view all payments between chosen dates for the chosen card
            System.debug('@@@ chosen pmethod ' + this.chosenPaymentMethod);
            //String pmId = paymentSelect.get(index).PaymentMethod.Zuora__External_Id__c;
            filterPaymentsByDateAndPaymentMethod(this.chosenPaymentMethod);
                
        } else if (this.index == -1 || this.index == -2){
            //If index is -1, view all payments between chosen dates for all payment methods
            filterPaymentsByDate();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Unexpected error'));
        }
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 20/06/2016
    Version - 1.0
    Function -  filters payment records by selected from/to dates and payment method id
                if payment method id is not specified filterPaymentsByDate() method should be used 

    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/

    private void filterPaymentsByDateAndPaymentMethod(String paymentId){
        
        //if no dates specified in the filter show all payments
        if(String.isBlank(this.paymentFrom) && String.isBlank(this.paymentTo)){
            for (Integer i=0; i<zPayments.size(); i++){
                this.viewedPayments.add(new ZuoraPaymentRefundWrapper(zPayments.get(i)));
            }

        } else {

            //define regex matchers for valid date format dd/mm/yyyy
            Pattern datePattern = Pattern.compile(Constants.REG_DATE_FORMAT_DD_FSLASH_MM_FSLASH_YYYY);
            Matcher paymentFromMatcher;
            Matcher paymentToMatcher;

            //assign regexe matcher if date is not blank
            if(String.isNotBlank(this.paymentFrom)) paymentFromMatcher = datePattern.matcher(this.paymentFrom);
            if(String.isNotBlank(this.paymentTo))   paymentToMatcher = datePattern.matcher(this.paymentTo);

            Boolean isFromValidDate = true;
            Boolean isToValidDate = true;

            //check if valid date values are specified for paymentFrom and paymentTo dates
            if(paymentFromMatcher != null) isFromValidDate = paymentFromMatcher.matches();
            if(paymentToMatcher != null)   isToValidDate = paymentToMatcher.matches();

            //throw an error if any of the dates are invalid
            if(!isFromValidDate || !isToValidDate){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                Label.Manage_Billing_Account_Filter_Invalid_Date_Error_Message));

            } else {

                //declear date variables
                Date pFrom = null;
                Date pTo = null;

                //assigne date values
                if (String.isNotBlank(this.paymentFrom)) pFrom = convertDate(this.paymentFrom);
                if (String.isNotBlank(this.paymentTo))   pTo = convertDate(this.paymentTo);

                //if both date values specified make sure the  payment to date value > payment from date
                if((pFrom != null && pTo != null) && pFrom > pTo){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                        Label.Manage_Billing_Account_Filter_Date_Error_Message));

                } else {

                    //paymentTo date including
                    pTo = (pTo != null ? pTo.addDays(1) : null);

                    //filter payments with effective date in the range of the given dates
                    for (Integer i=0; i<zPayments.size(); i++){

                        Zuora__Payment__c tempPay = zPayments.get(i);
                        Date zEffectiveDate = Date.valueOf(tempPay.Zuora__EffectiveDate__c);

                        if  ((pTo == null && zEffectiveDate >= pFrom) ||
                             (zEffectiveDate < pTo && pFrom == null) ||
                             (zEffectiveDate < pTo && zEffectiveDate >= pFrom)){

                            if(String.isEmpty(paymentId)) 
                                this.viewedPayments.add(new ZuoraPaymentRefundWrapper(tempPay));
                            else if(tempPay.Zuora__PaymentMethod__c == paymentId) 
                                this.viewedPayments.add(new ZuoraPaymentRefundWrapper(tempPay));
                        }
                    }
                }
            }
        }
    }

    private void filterPaymentsByDate(){
        filterPaymentsByDateAndPaymentMethod(null);
    }
    
    /**
        When error is confirmed, messages on page clear.
    */
    public void confirmError(){
        ApexPages.getMessages().clear();
    }
    
    /**
        Navigates to the refund page
    */
    public PageReference makeRefund(){
        
        //Sally ElGhoul - 25/9/2015
        //passing the value through the apex:param didn't work and I didn't want to refactor the tool too much because it was developed by ZUORA
        //so that's why I loop on the payment records and get the refund value from it
        string RefundAmountValue='';
        for(ZuoraPaymentRefundWrapper wrapper : viewedPayments){
            if(wrapper.paymentObj.Zuora__External_Id__c==paymentRefundId){
                RefundAmountValue=string.valueof(wrapper.refundAmount);
            }
        }
        return new PageReference('/apex/Make_Refund?id=' + billId + '&pId=' + paymentRefundId+'&amount='+RefundAmountValue);
    }
    
   
    /**
        Returns to the billing account
    */
    public PageReference cancel(){
        //sally ElGhoul - 4/9/2015 , we want the user when press return to account to go back to salesforce account instead of the billing account
        //return new PageReference('/' + billId);
        return new PageReference('/'+sfAccount.Zuora__Account__c);
    }
        
    /**
        Class holding Payment Method, its index, and formatted versions of expiration date
        and address for viewing on page.
    */
    public class PaymentSelectorCombo{
        
        public Zuora__PaymentMethod__c PaymentMethod {get;set;}
        public Integer selectionIndex {get;set;}
        public String address {get;set;}
        public String expirationDate {get;set;}
        
        /**
            Constructor
        */
        public PaymentSelectorCombo(Zuora__PaymentMethod__c pm, Integer s){
            PaymentMethod = pm;
            selectionIndex = s;
            if (s>-1 && pm.Zuora__Type__c =='CreditCard')
                expirationDate = pm.Zuora__CreditCardExpirationMonth__c + '/' + pm.Zuora__CreditCardExpirationYear__c;
            else
                expirationDate = '';
            
            address = '';
            if (pm.Zuora__CreditCardAddress1__c != null){
                address = pm.Zuora__CreditCardAddress1__c;
                if (pm.Zuora__CreditCardAddress2__c != null)
                    address = address + ', ' + pm.Zuora__CreditCardAddress2__c + ',\r\n';
                else
                    address = address + ',\r\n';        
            }
            if (pm.Zuora__CreditCardCity__c != null)
                address = address + pm.Zuora__CreditCardCity__c + ', ';
            if(pm.Zuora__CreditCardState__c != null)
                address = address + pm.Zuora__CreditCardState__c + ', ';
            if (pm.Zuora__CreditCardCountry__c != null)
                address = address + pm.Zuora__CreditCardCountry__c;
            if (pm.Zuora__CreditCardPostalCode__c != null)
                address = address + ' ' + pm.Zuora__CreditCardPostalCode__c;
        }
    }
    
    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        25/09/2015
    Function    this is wrapper class for the viewed payment list to include the refund amount
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public class ZuoraPaymentRefundWrapper{
        public Zuora__Payment__c paymentObj {get;set;}
        public Boolean isRefundAllowed {get;set;}
        public decimal availableRefund {get;set;}
        public decimal refundAmount         {
                                                get;
                                                set{
                                                    if (value > availableRefund){
                                                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Total Refund higher than maximum refund allowed!  Value set to maximum allowable refund.');
                                                        ApexPages.addMessage(myMsg);
                                                        refundAmount = availableRefund;
                                                    } else
                                                        refundAmount = value;
                                                }
                                            }
        
        public ZuoraPaymentRefundWrapper(Zuora__Payment__c paymentObjValue){
            paymentObj=paymentObjValue;
            refundAmount=0;
            availableRefund = paymentObjValue.Zuora__Amount__c - paymentObjValue.Zuora__AppliedCreditBalanceAmount__c;
            if(paymentObjValue.ZuoraPaymentMethodId__c.equals(Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE) 
                && !paymentObjValue.Zuora__GatewayStatus__c.equals(Constants.ZUORA_PAYMENT_GATEWAY_STATE_SETTLED)){
                isRefundAllowed = false;
            } else isRefundAllowed = true;
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        05/10/2015
    Function    this is method to hangle button action to transfer amount to credit balance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference transferToCreditBalance(){
        List<Zuora.zApi.SaveResult> saveResultsList = new List<Zuora.zApi.SaveResult>();
        String errrorMessage = '';
        PageReference pr = new PageReference('/apex/Manage_Billing_Account?id=' + billId);
        ShowPrompt = false;      
        System.debug('### Negative Invoice Id: ' + this.invoiceToTransferId);
        System.debug('### Amount to transfer ' + this.amountInvoiceTransfer);
        //Try to create new Credit Balance Adjustment
        Zuora.zObject cba = new Zuora.zObject('CreditBalanceAdjustment');
        cba.setValue('AccountingCode', '');
        cba.setValue('Amount', this.amountInvoiceTransfer);
        cba.setValue('ReasonCode', '');
        cba.setValue('ReferenceId', '');
        cba.setValue('SourceTransactionId', this.invoiceToTransferId);
        cba.setValue('Type', 'Increase');

        List<Zuora.zObject> cbaToCreateList = new List<Zuora.zObject>{cba};
        if (!Test.isRunningTest()){
            //Login to Zuora
            zapi.zlogin();
            saveResultsList = ZuoraUtilities.createZuoraObjects(zApi, cbaToCreateList);
        }

        for (Zuora.zApi.SaveResult saveResult2 : saveResultsList) {
            if (! ZuoraUtilities.analyzeSaveResult(saveResult2).isEmpty()) {
                System.debug('########## ERROR: ' + ZuoraUtilities.analyzeSaveResult(saveResult2));
                errrorMessage += ZuoraUtilities.analyzeSaveResult(saveResult2) + ' .\n';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errrorMessage);
                ApexPages.addMessage(myMsg);

                return null;
            } else {
                System.debug('########## INFO: Refund Invoice to Credit Balance Adjustment created.');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Refund_Tool_TransferAmountToCreditBalance + this.amountInvoiceTransfer));    
                 negativeInvoices=queryNegativeInvoices();
                 convertNegativeInvoices();
                 zAccount = queryAccount();    
                 ShowPrompt  = true; 
                 return null;
            }
        }

        
        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    go to the transfer credit to invoice page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference creditToInvoice(){
        return new PageReference('/apex/creditToInvoice?id=' + billId);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        03/11/2015
    Function    generate combolist for Payment Methods
    ******************* Change Log *******************
    Modified by             Change Date
    Mantas Grigaliunas    28/06/2017 //added Paypal related code
    ****************************************************************************************/
    public List <SelectOption> lAllPaymentMethods{
        get{
            lAllPaymentMethods = new List <SelectOption>();
            for(PaymentSelectorCombo psc : this.paymentSelect){
                System.debug('@@@$$$ PSC: ' + psc);
                String showName='';
                if(psc.selectionIndex >= 0 && psc.PaymentMethod.Zuora__External_Id__c != null){
                   if(psc.PaymentMethod.Zuora__Type__c == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL){
                        showName = psc.PaymentMethod.Zuora__Type__c + ' | ' + psc.PaymentMethod.Zuora__CreditCardMaskNumber__c;
                   } else if(psc.PaymentMethod.Zuora__Type__c == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
                        showName = psc.PaymentMethod.Zuora__Type__c + ' | ' + psc.PaymentMethod.Zuora__PaypalEmail__c;
                   } else {
                       showName = psc.PaymentMethod.Zuora__Type__c + ' | ' + psc.PaymentMethod.Zuora__CreditCardType__c +' | ' + psc.PaymentMethod.Zuora__CreditCardMaskNumber__c;
                   } 
                   lAllPaymentMethods.add(new SelectOption(psc.PaymentMethod.Zuora__External_Id__c, showName));    
                }
            }
            return lAllPaymentMethods;
        }

        set;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        03/11/2015
    Function    onchange Payment Method 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void invokeActionsToShowPayments(){
        this.chosenPaymentMethod = this.actualPaymentMethodZuoraId;
        this.convertPayments();
        this.selectIndex();
    }

    /***************************************************************************************
    Developer   Mantas Grigaliunas
    Date        02/05/2017
    Function    check if payment is allowed for refund based on Subscription product RefundsNotAllowed flag
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Map<String, Boolean> getNotAllowedForRefundPaymentsMap(Set<String> paymentIds){
         
        Map<String, Boolean> paymentIdToRefundAllowanceMap = new Map<String, Boolean>();
        Map<String, String> invoiceIdToPaymentIdMap = new Map<String, String>();

        //get all invoice payments
        String invoicePayemntsQuery             = 'SELECT Id, PaymentId, InvoiceId FROM InvoicePayment';
        List<Zuora.zObject> invoicePaymentsList = ZuoraUtilities.queryMultipleZItems(zApi, paymentIds, invoicePayemntsQuery, 'PaymentId', null);

        //get payment ids and define a map of to invoiceId paymentId 
        for(Zuora.zObject invoicePayment : invoicePaymentsList){
            invoiceIdToPaymentIdMap.put((String)invoicePayment.getValue('InvoiceId'), (String)invoicePayment.getValue('PaymentId'));
        }

        //get all invoice items related to the same subscription
        String invoiceItemsQuery = 'SELECT Id, InvoiceId, SubscriptionNumber FROM InvoiceItem';
        List<Zuora.zObject> invoiceItemsList = ZuoraUtilities.queryMultipleZItems(zapi, invoiceIdToPaymentIdMap.keySet(), invoiceItemsQuery, 'InvoiceId', null);

        Map<String, List<String>> subscriptionNumberToInvoiceIdMap = new Map<String, List<String>>();
        Map<String, String> invoiceIdToSubscriptionNumberMap = new Map<String, String>();
        for(Zuora.zObject invoiceItem : invoiceItemsList){
            String subscriptionNumber = (String)invoiceItem.getValue('SubscriptionNumber');
            String invoiceId = (String)invoiceItem.getValue('InvoiceId');
            if(subscriptionNumberToInvoiceIdMap.get(subscriptionNumber) == null){
                subscriptionNumberToInvoiceIdMap.put(subscriptionNumber, new List<String>{invoiceId});
            } else {
                subscriptionNumberToInvoiceIdMap.get(subscriptionNumber).add(invoiceId);
            }
            invoiceIdToSubscriptionNumberMap.put((String)invoiceItem.getValue('Id'), subscriptionNumber);
        }

        List<Zuora__SubscriptionProductCharge__c> productChargeList = [ SELECT Id, Zuora__Product__r.Zuora__External_Id__c, Zuora__Subscription__r.Name FROM Zuora__SubscriptionProductCharge__c 
                                                                        WHERE Zuora__Subscription__r.Name IN :subscriptionNumberToInvoiceIdMap.keySet() ];

        if(productChargeList.isEmpty()){
            for(String invoiceId : invoiceIdToPaymentIdMap.keySet()){
                paymentIdToRefundAllowanceMap.put(invoiceIdToPaymentIdMap.get(invoiceId), true);
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,Label.Zuora_Subscription_Canceller_Charge_Product_Not_Found));
            return paymentIdToRefundAllowanceMap;
        }    

        Set<String> zProducIdSet = new Set<String>();
        Map<String, String> zuoraIdToSubscriptionName = new Map<String, String>();
        for(Zuora__SubscriptionProductCharge__c productCharge : productChargeList){

            String zuoraId = productCharge.Zuora__Product__r.Zuora__External_Id__c;
            String subscriptionName = productCharge.Zuora__Subscription__r.Name;
            if(!String.isBlank(zuoraId)){
                zProducIdSet.add(zuoraId);
                zuoraIdToSubscriptionName.put(zuoraId, subscriptionName);
            } else {
                for(String invoiceId : subscriptionNumberToInvoiceIdMap.get(subscriptionName)){
                    paymentIdToRefundAllowanceMap.put(invoiceIdToPaymentIdMap.get(invoiceId), true);
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, String.format(Label.Zuora_Subscription_Canceller_ZProduct_Not_Found, new List<String>{zuoraId})));
               } 
               return paymentIdToRefundAllowanceMap;
            }
        }

        List<zqu__ZProduct__c> zProductList = [SELECT Id, Name, RefundsAllowed__c, zqu__ZuoraId__c FROM zqu__ZProduct__c WHERE zqu__ZuoraId__c IN :zProducIdSet ];
        if(zProductList.isEmpty()){
            for(String invoiceId : invoiceIdToPaymentIdMap.keySet())
                paymentIdToRefundAllowanceMap.put(invoiceIdToPaymentIdMap.get(invoiceId), true);
            for(String zProductId : zProducIdSet)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, String.format(Label.Zuora_Subscription_Canceller_ZProduct_Not_Found, new List<String>{zProductId})));
            return paymentIdToRefundAllowanceMap;
        } 

        for(zqu__ZProduct__c zProduct : zProductList){
            List<String> invoiceIdList = subscriptionNumberToInvoiceIdMap.get(zuoraIdToSubscriptionName.get(zProduct.zqu__ZuoraId__c));
            for(String invoiceId : invoiceIdList)
                paymentIdToRefundAllowanceMap.put(invoiceIdToPaymentIdMap.get(invoiceId), zProduct.RefundsAllowed__c == 'Yes');
        }

        return paymentIdToRefundAllowanceMap;
    }
}