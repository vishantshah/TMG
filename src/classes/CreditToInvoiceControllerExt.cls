/**
* Author:       Michal Kwika (Accenture)
* Date:         09/10/2015
* Description:  Controller for transferring some credit to positive invoice (CreditToInvoice)
*
* ******************* Change Log *******************
* Modified by       Version       Change Date
**/
public with sharing class CreditToInvoiceControllerExt {

    public Zuora__CustomerAccount__c sfAccount;
    public zqu.NotificationOptions notificationOptions {get; set;}
    public String billId {get; set;}
    public String accId {get; set;}
    public String zId {get; set;}
    public Zuora__CustomerAccount__c zAccount {get; set;}
    public List<Zuora.zObject> positiveInvoices;
    public List<Zuora__ZInvoice__c> lstViewsPositiveInvoices {get; set;}
    public String invoiceToTransferId {get; set; }
    public Decimal amountInvoiceTransfer {get; set;}
    public Decimal selectedInvoiceBalance {get; set;}
    public Boolean ShowPrompt {get; set;}
    /*Instance of ZUora API*/
    public Zuora.zApi zapi = new Zuora.zApi();

    /**
     * Main Controller
     */
    public CreditToInvoiceControllerExt(ApexPages.StandardController stdController) {
        //Create Notification object and sets values to set up the pop-up
        notificationOptions = new zqu.NotificationOptions();
        notificationOptions.isPopup = true;
        notificationOptions.continueAction = 'continueToNextPage();';
        notificationOptions.backLabel = 'Remain';
        notificationOptions.successTitle = 'SUCCESS!';
        notificationOptions.failureTitle = 'AN ERROR OCCURRED!';

        //set amountInvoiceTransfer
        amountInvoiceTransfer = 0;

        //Get the Zuora Customer Id
        this.billId = System.currentPageReference().getParameters().get('Id');

        //Get Accounts from SalesForce
        if (!Test.isRunningTest())
            this.sfAccount = ([SELECT Name, Zuora__Balance__c, Zuora__AccountNumber__c, Zuora__Credit_Balance__c, Zuora__Account__c, Zuora__Zuora_Id__c, Zuora__CreditCardNumber__c, Zuora__DefaultPaymentMethod__c from Zuora__CustomerAccount__c where Id = :billId ]).get(0);
        else {
            this.sfAccount = new Zuora__CustomerAccount__c();
            Account tempAcc = Z_TestFactory.makeAccount();
            sfAccount.Zuora__Zuora_Id__c = 'zId';
            sfAccount.Zuora__Account__c = tempAcc.Id;
            this.billId = 'billId';
        }
        //Retrieve important values from the SF account
        this.zId = sfAccount.Zuora__Zuora_Id__c;
        this.accId = sfAccount.Zuora__Account__c;
        this.zAccount = queryAccount();

        try {
            positiveInvoices = queryPositiveInvoices();
            convertPositiveInvoices();

        } catch (Exception e) {
            //Throw exception is Zuora error occurs
            throw new zqu.ZQException(e.getMessage());
        }

    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    Get positive invoices on Zuora Account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public list<Zuora.zObject> queryPositiveInvoices() {
        //login to Zuora if not test is runing
        if (!Test.isRunningTest()) {
            zapi.zlogin();
        }

        //Create ZOQL query
        String zoql = 'SELECT InvoiceNumber, Balance, PaymentAmount, Amount, RefundAmount, Status, Id from Invoice where Amount>0 and AccountId = \'' + zId + '\' limit 100';
        if (!Test.isRunningTest()) {
            //Query for Invoices from Zuora
            return zapi.zquery(zoql);
        } else {
            List<Zuora.zObject> tempInvoiceList = new List<Zuora.zObject>();
            Zuora.zObject tempInvoice = new Zuora.zObject('Invoice');
            tempInvoice.setValue('InvoiceNumber', 'INV00001430');
            tempInvoice.setValue('Balance', 25.00);
            tempInvoice.setValue('PaymentAmount', 0.00);
            tempInvoice.setValue('Amount', 25.00);
            tempInvoice.setValue('RefundAmount', 0.00);
            tempInvoice.setValue('Status', 'Posted');
            tempInvoice.setValue('Id', 'pId');
            tempInvoiceList.add(tempInvoice);
            return tempInvoiceList;
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    Convert invoices from zuora object to salesforce object
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void convertPositiveInvoices() {
        //convert the positive invoices from zuora to be in the format of salesforce objects
        lstViewsPositiveInvoices = new list<Zuora__ZInvoice__c>();
        for (Zuora.zObject payment : positiveInvoices) {
            Zuora__ZInvoice__c addInvoice = new Zuora__ZInvoice__c();
            addInvoice.put(Zuora__ZInvoice__c.Name, payment.getValue('InvoiceNumber'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__Balance2__c, payment.getValue('Balance'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__PaymentAmount__c, payment.getValue('PaymentAmount'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__TotalAmount__c, payment.getValue('Amount'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__RefundedAmount__c, payment.getValue('RefundAmount'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__Status__c, payment.getValue('Status'));
            addInvoice.put(Zuora__ZInvoice__c.Zuora__Zuora_Id__c, payment.getValue('Id'));
            lstViewsPositiveInvoices.add(addInvoice);
        }
    }


    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    Confirms error message and clears all messages on page.
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void confirmError() {
        ApexPages.getMessages().clear();
    }


    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    Refresh pageLayout
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference RefreshUI() {

        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    back to refund tool
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference cancel() {
        return new PageReference('/apex/Manage_Billing_Account?id=' + billId);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        12/10/2015
    Function    back to refund tool
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Boolean validateAmount() {

        System.debug('### validateAmount: Amount to Transfer: ' + amountInvoiceTransfer);
        System.debug('### validateAmount: zAcc CreditBalance: ' + zAccount.Zuora__Credit_Balance__c);

        if (amountInvoiceTransfer <= 0 ) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.CreditToInvoice_AmountGreaterThanZero);
            ApexPages.addMessage(myMsg);
            return false;
        }

        if (amountInvoiceTransfer > zAccount.Zuora__Credit_Balance__c) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.CreditToInvoice_AmountTooBig);
            ApexPages.addMessage(myMsg);
            return false;
        }

        if (amountInvoiceTransfer > selectedInvoiceBalance) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.CreditToInvoice_CannotTransferMoreThanInvoiceHas);
            ApexPages.addMessage(myMsg);
            return false;
        }

        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        09/10/2015
    Function    Get Zuora account details
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/

    public Zuora__CustomerAccount__c queryAccount() {
        List<Zuora.zObject> accounts;
        if (!Test.isRunningTest()) {
            //Login to Zuora
            zapi.zlogin();
        }

        //Create ZOQL query
        String zoql = 'SELECT Name, AccountNumber, Id, DefaultPaymentMethodId, Balance, TotalInvoiceBalance, CreditBalance from Account where Id = \'' + zId + '\'';
        if (!Test.isRunningTest()) {
            //Query for payments from Zuora
            accounts = zapi.zquery(zoql);
        } else {
            //Create test data for testing if needed
            accounts = new List<Zuora.zObject>();
            Zuora.zObject testAccount = new Zuora.zObject('Account');
            testAccount.setValue('Name', 'Name');
            testAccount.setValue('AccountNumber', 'AccountNumber');
            testAccount.setValue('Id', 'Id');
            testAccount.setValue('DefaultPaymentMethodId', 'pmId');
            accounts = new List<Zuora.zObject>();
            accounts.add(testAccount);
        }

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
    Developer   Michal Kwika (Accenture)
    Date        12/10/2015
    Function    Pay for the invoice from your credit balance
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference transferFundsFromCreditBalance() {
        System.debug('### TransferMethod: ID of invoice: ' + this.invoiceToTransferId);
        System.debug('### Amount to transfer ' + this.amountInvoiceTransfer);
        if (validateAmount()) {
            List<Zuora.zApi.SaveResult> saveResultsList = new List<Zuora.zApi.SaveResult>();
            String errrorMessage = '';
            ShowPrompt = false;
            
            //Try to create new Credit Balance Adjustment
            Zuora.zObject cba = new Zuora.zObject('CreditBalanceAdjustment');
            cba.setValue('AccountingCode', '');
            cba.setValue('Amount', this.amountInvoiceTransfer);
            cba.setValue('ReasonCode', '');
            cba.setValue('ReferenceId', '');
            cba.setValue('SourceTransactionId', this.invoiceToTransferId);
            cba.setValue('Type', 'Decrease');

            List<Zuora.zObject> cbaToCreateList = new List<Zuora.zObject> {cba};
            if (!Test.isRunningTest()) {
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
                    System.debug('########## INFO: Funds from Credit Balance to Invoice applied.');
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Refund_Tool_TransferAmountToCreditBalance + ' £' +  this.amountInvoiceTransfer));
                    positiveInvoices = queryPositiveInvoices();
                    convertPositiveInvoices();
                    zAccount = queryAccount();
                    ShowPrompt  = true;
                    return null;
                }
            }
        }
        return null;
    }
}