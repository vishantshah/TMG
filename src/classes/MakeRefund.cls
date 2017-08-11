/**
* Author:       Unknown
* Date:         Unknown
* Description:  Controller for Refund Tool
*
* ******************* Change Log *******************
* Modified by        	Change Date
* Michal Kwika     		03/11/2015
* Wiktor Czykin			12/02/2016 //modified queryExternalPaymentMethod() and other minor changes (constructor execution order, constants)  
* Michal Szewczyk		16/02/2016 //added InvoiceAdjustment generation for externalRefund() and creditCardRefund()
* Michal Szewczyk		07/03/2016 //replace InvoiceAdjustment  with Credit Balance in externalRefund() and creditCardRefund()
* Gavin Palmer 			20/06/2016 // modified submit()
* Pawel Chrzanowski 	24/01/2017 //added comments support
* Mantas Grigaliunas    28/06/2017 //added Paypal related code
**/
public with sharing class MakeRefund {
	
	public String refundType {get;set;}
	public String methodType {get;set;}
	public Zuora__PaymentMethod__c zPaymentMethod {get;set;}
	public Zuora__Payment__c zPayment {get;set;}
	public List<Zuora__PaymentInvoice__c> zInvoicePayment {get;set;}
	public List<PaymentSelectorCombo> paymentSelect {get;set;}
	public String pmId {get;set;}
	public String pId {get;set;}
	public String billId {get;set;}
	public String zId {get;set;}
	public String accId {get;set;}
	public Zuora__CustomerAccount__c sfAccount;
	public Decimal Amount {get;set;}
	public String comment {get;set;}
	public zqu.NotificationOptions notificationOptions {get;set;}
	public Decimal refundAvailable {get;set;}
	public List<Zuora__PaymentMethod__c> zExternalPaymentMethod {get;set;}
	public Boolean mustBeExternal {get;set;}
	public String refundDate {get;set;}
	public String originalPaymentMethod {get;set;}
	public List<Zuora__ZInvoice__c> zInvoice;
	public Map<String, String> zInvoiceMap;
	public Map<String, String> InvoicePaymentMap;
	public Map<String, String> PaymentInvoicIdMap;
	public Boolean isDirectDebitType {get; set;}
	public String refundReason {get; set;}
	public Zuora.zApi zapi = new Zuora.zApi();

	@TestVisible private static Map<String, Zuora.zObject> mapTestObjects = new Map<String,Zuora.zObject>();
	@TestVisible private static final String REQUEST_QUERY_PAYMENT_METHOD = 'queryPaymentMethod';

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -   Constructor
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1         12/02/2016  //minor changes
	****************************************************************************************/
	public MakeRefund(ApexPages.StandardController controller){
		//Create Notification object and sets values to set up the pop-up
		notificationOptions = new zqu.NotificationOptions();
		notificationOptions.isPopup = true;
		notificationOptions.continueAction = 'continueToNextPage();';
		notificationOptions.backLabel = 'Remain';
		notificationOptions.successTitle = Constants.ZUORA_NOTIFICATION_SUCCESS;
		notificationOptions.failureTitle = Constants.ZUORA_NOTIFICATION_ERROR;
		
		//Gets today's date
		String[] todays = String.valueOf(Date.today()).split('-',0);
		this.refundDate = todays[2] + '/' + todays[1] + '/' + todays[0];
		
		//Gets data from the URL
		this.pId = System.currentPageReference().getParameters().get('pId');
		this.billId = System.currentPageReference().getParameters().get('Id');
		
		//Gets the curret billing account from salesforce 
		if(!Test.isRunningTest()){
			this.sfAccount = ([SELECT Zuora__Account__c, Zuora__Zuora_Id__c from Zuora__CustomerAccount__c where Id = :billId ]).get(0);
		}else{
			//Creates test data during testing
			this.sfAccount = new Zuora__CustomerAccount__c();
			Account tempAcc = Z_TestFactory.makeAccount();
			sfAccount.Zuora__Zuora_Id__c = 'zId';
			sfAccount.Zuora__Account__c = tempAcc.Id;
			this.billId = 'billId';
		}
		//Gets important data from the SF Billing Account
		this.zId = sfAccount.Zuora__Zuora_Id__c;
		this.accId = sfAccount.Zuora__Account__c;
				
		//Query Zuora for various important infomation, inclduing all external payment methods,
		//The current payment and the invoicepayments associated with it, as well as the ID
		//of the Payment Method use and the Payment Method itself.
		this.zInvoice = queryInvoice();
		mapInvoice();
		this.zPayment = queryPayment();
		this.zInvoicePayment = queryInvoicePayment();
		generatePaymentSelect();
		this.pmId = zPayment.Zuora__PaymentMethod__c;
		this.zPaymentMethod = queryPaymentMethod();
		this.originalPaymentMethod = getRefundMethod();
		this.mustBeExternal = false;
		this.isDirectDebitType = false;
		this.refundReason ='';
		
		this.zExternalPaymentMethod = queryExternalPaymentMethod();
		//If the original payment method was external, the refund must be external
		for (Zuora__PaymentMethod__c xpm : zExternalPaymentMethod){
			if (xpm.Zuora__External_Id__c == pmId){
				this.mustBeExternal = true;
				if(xpm.Zuora__Name__c.contains(Constants.DIRECT_DEBIT_PAYMENT_METHOD)){
					this.isDirectDebitType = true;
				}
			}
		}

		System.debug('@@@ isDirectDebitType? ' + isDirectDebitType +':@@@ mustBeExternal?:'+mustBeExternal);
		//Sets default values
		this.refundType = 'external';
		this.methodType = '';
		
		//Sally El Ghoul - 28/9/2015 - Default the amount value with the amount passed in the query string
		//As agreed this page will only show one record in the list of transactions associated with the original payment
		if(ApexPages.currentPage().getParameters().containsKey('amount') && !String.isEmpty(ApexPages.currentPage().getParameters().get('amount'))){
			this.Amount = Decimal.valueOf(ApexPages.currentPage().getParameters().get('amount'));
		}else{
			this.Amount = 0;
		}
	}

	
	/**
		Converts the date from the date picker format to the code format
	*/
	public Date convertDate(String d){
		String[] splitDate = d.split('/',0);
		//Michal Kwika BUGFIX - changed due to error on converting date
		return Date.valueOf(splitDate[2] + '-' + splitDate[1] + '-' + splitDate[0]);
	}

	/*************************************************************************************** 
	Developer - Mantas Grigaliunas
	Date - 28/06/2017
	Function -  Return refund method string based on payment method type
	#############Change Log#############
	Modified by     Change Date
	****************************************************************************************/
	public String getRefundMethod(){
		System.debug('zPaymentMethod.Zuora__Type__c: ' + zPaymentMethod.Zuora__Type__c);
		if(zPaymentMethod.Zuora__Type__c == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
			return Constants.PAYMENT_METHOD_PAYPAL_TYPE + ' (' + zPaymentMethod.Zuora__PaypalEmail__c + ')';
		} else {
			return zPaymentMethod.Zuora__CreditCardHolderName__c + ', ' + zPaymentMethod.Zuora__CreditCardType__c + ' (' + zPaymentMethod.Zuora__CreditCardMaskNumber__c + ')';
		}
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Function -   Query Zuora for the used Payment Method
	#############Change Log#############
	Modified by     	Change Date
	Wiktor Czykin	    12/02/2016 //changed variable names, changed else for test, added constants
	Mantas Grigaliunas  28/06/2017 //added Paypal related code
	****************************************************************************************/
	public Zuora__PaymentMethod__c queryPaymentMethod(){
		List<Zuora.zObject> paymentMethods;
		Zuora.zObject payment;
		//Login to Zuora
		if (!Test.isRunningTest()){
			zapi.zlogin();
		}
			
		//Create ZOQL query
		String zoql = 'SELECT Type, AchAbaCode, AchAccountName, AchAccountNumberMask, AchAccountType, AchBankName, CreditCardHolderName, CreditCardMaskNumber, '
					+ 'CreditCardType, CreditCardExpirationMonth, CreditCardExpirationYear, Id, BankTransferAccountNumberMask, BankTransferAccountName, '
					+ 'PaypalBaid, PaypalEmail, PaypalPreapprovalKey, PaypalType '
					+ 'from PaymentMethod where Id = \'' + pmId + '\'';
		
		if (!Test.isRunningTest()){
			//Query for payments from Zuora
			paymentMethods = zapi.zquery(zoql);
			payment = paymentMethods.get(0);
		} else {
			//Generated data for testing
			if(mapTestObjects.containsKey(REQUEST_QUERY_PAYMENT_METHOD)){
				payment = mapTestObjects.get(REQUEST_QUERY_PAYMENT_METHOD);
			}else{
				Zuora.zObject tempPm = new Zuora.zObject('PaymentMethod');
				tempPm.setValue('CreditCardHolderName','Name');
				tempPm.setValue('CreditCardMaskNumber','Number');
				tempPm.setValue('CreditCardType','CreditCard');
				tempPm.setValue('CreditCardExpirationMonth','01');
				tempPm.setValue('CreditCardExpirationYear','2014');
				tempPm.setValue('Id','notDefault');
				tempPm.setValue('Type', Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
				payment = tempPm;
				mapTestObjects.put(REQUEST_QUERY_PAYMENT_METHOD, tempPm);
			}
		}
		
		Zuora__PaymentMethod__c zpm = new Zuora__PaymentMethod__c();
		if (payment.getValue('Type') == Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE || payment.getValue('Type') == Constants.PAYMENT_METHOD_DEBIT_CARD_TYPE){
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('CreditCardHolderName'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('CreditCardMaskNumber'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardType__c, payment.getValue('CreditCardType'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, payment.getValue('Id'));
		} else if (payment.getValue('Type') == Constants.PAYMENT_METHOD_ACH_TYPE){
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('AchAccountName'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('AchAbaCode') + ' ' + payment.getValue('AchAccountNumberMask'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardType__c, payment.getValue('AchBankName') + ' - ' + payment.getValue('AchAccountType'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, payment.getValue('Id'));
		} else if (payment.getValue('Type') == Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE) {
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardHolderName__c, payment.getValue('BankTransferAccountName'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, payment.getValue('BankTransferAccountNumberMask'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, payment.getValue('Id'));
			zpm.put(Zuora__PaymentMethod__c.Zuora__Type__c, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL);
			zpm.put(Zuora__PaymentMethod__c.Zuora__CreditCardType__c, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL);
		} else if(payment.getValue('Type') == Constants.PAYMENT_METHOD_PAYPAL_TYPE){
			zpm.put(Zuora__PaymentMethod__c.Zuora__PaypalBaid__c, payment.getValue('PaypalBaid'));
            zpm.put(Zuora__PaymentMethod__c.Zuora__PaypalEmail__c, payment.getValue('PaypalEmail'));
            zpm.put(Zuora__PaymentMethod__c.Zuora__PaypalType__c, payment.getValue('PaypalType'));
            zpm.put(Zuora__PaymentMethod__c.Zuora__Type__c, payment.getValue('Type'));
            zpm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, payment.getValue('Id'));
		}

		return zpm;
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -   Queries Zuora for all External Payment Methods on the current tenant.
	#############Change Log#############
	Modified by     Version     Change Date
	Michal Kwika    1.1         12/02/2016  //changed zoql to limit payment methods to current account instead of all accounts
	****************************************************************************************/
	public List<Zuora__PaymentMethod__c> queryExternalPaymentMethod(){
		List<Zuora.zObject> paymentMethods;
		//Login to Zuora
		if (!Test.isRunningTest()){
			zapi.zlogin();
		}
			
		//Create ZOQL query
		String zoql = 'SELECT Name, Id, AccountId from PaymentMethod where Name !=null and AccountId =\''+this.zId+'\'';
		if (!Test.isRunningTest()){
			//Query for payments from Zuora
			paymentMethods = zapi.zquery(zoql);
		} else {
			//Generate data for testing when needed
			Zuora.zObject tempPm = new Zuora.zObject('PaymentMethod');
			tempPm.setValue('Name','Name');
			tempPm.setValue('Id','pmId');
			paymentMethods = new List<Zuora.zObject>();
			paymentMethods.add(tempPm);
		}
		
		//Creates a list of payment method sObjects
		List<Zuora__PaymentMethod__c> ret = new List<Zuora__PaymentMethod__c>();					
	
		for (Integer i=0; i<paymentMethods.size(); i++){
			Zuora.zObject payment = paymentMethods.get(i);
			//Create the sObject and fills it with data from the zObject and adds it to the list
			Zuora__PaymentMethod__c zpm = new Zuora__PaymentMethod__c();
			zpm.put(Zuora__PaymentMethod__c.Zuora__Name__c, payment.getValue('Name') );
			zpm.put(Zuora__PaymentMethod__c.Zuora__External_Id__c, payment.getValue('Id'));
			ret.add(zpm);
		}
		return ret;
	}
	
	/**
		Query Zuora for the payment that is being refunded
	*/
	public Zuora__Payment__c queryPayment(){
		List<Zuora.zObject> payments;
		Zuora.zObject payment;
		if (!Test.isRunningTest()){
			zapi.zlogin();
		}
				
		//Create ZOQL query
		String zoql = 'SELECT Amount, AccountId, RefundAmount, PaymentNumber, CreatedDate, EffectiveDate, PaymentMethodId, Id from Payment where id = \'' + pId + '\'';
		
		if (!Test.isRunningTest()){
			//Query for payments from Zuora
			payments = zapi.zquery(zoql);
			payment = payments.get(0);
		} else {
			//Generates temporary data for testing purposes
			Zuora.zObject tempPayment = new Zuora.zObject('Payment');
			tempPayment.setValue('Amount',100.00);
			tempPayment.setValue('RefundAmount', 0.00);
			tempPayment.setValue('PaymentNumber','PaymentNumber');
			tempPayment.setValue('CreatedDate',DateTime.now());
			tempPayment.setValue('EffectiveDate',DateTime.now());
			tempPayment.setValue('PaymentMethodId','pmId');
			tempPayment.setValue('Id', 'pId');
			payment = tempPayment;
		}
		
		//Creats an sObject and fills in the data fro the zObject for use on the page
		Zuora__Payment__c add = new Zuora__Payment__c();
		add.put(Zuora__Payment__c.Zuora__Amount__c, payment.getValue('Amount'));
		add.put(Zuora__Payment__c.Zuora__AppliedCreditBalanceAmount__c, payment.getValue('RefundAmount'));
		add.put(Zuora__Payment__c.Zuora__PaymentNumber__c, payment.getValue('PaymentNumber'));
		add.put(Zuora__Payment__c.Zuora__CreatedDate__c, payment.getValue('CreatedDate'));
		add.put(Zuora__Payment__c.Zuora__EffectiveDate__c, payment.getValue('EffectiveDate'));
		add.put(Zuora__Payment__c.Zuora__PaymentMethod__c, payment.getValue('PaymentMethodId'));
		add.put(Zuora__Payment__c.Zuora__External_Id__c, payment.getValue('Id'));
		
		this.refundAvailable = add.Zuora__Amount__c - add.Zuora__AppliedCreditBalanceAmount__c;
		
		return add;
	}
	
	/**
		Gets all InvoicePayments associated with the current payment
	*/
	public List<Zuora__PaymentInvoice__c> queryInvoicePayment(){
		InvoicePaymentMap = new Map<String,String>();
		PaymentInvoicIdMap = new Map<String,String>();
		List<Zuora.zObject> payments;
		if (!Test.isRunningTest()){
			zapi.zlogin();
		}
				
		//Create ZOQL query
		String zoql = 'SELECT Amount, RefundAmount, Id, InvoiceId,PaymentId from InvoicePayment where PaymentId = \'' + pId + '\'';
		
		if (!Test.isRunningTest()){
			//Query for Invoice Payments from Zuora
			payments = zapi.zquery(zoql);
		} else {
			//Generate test data for testing
			payments = new List<Zuora.zObject>();
			Zuora.zObject tempPayment = new Zuora.zObject('InvoicePayment');
			tempPayment.setValue('Amount',100.00);
			tempPayment.setValue('RefundAmount', 100.00);
			tempPayment.setValue('Id', 'pId');
			payments.add(tempPayment);
		}
		
		//Sets max refund available to 0 initally
		this.refundAvailable = 0;
		//Creates the list of Invoice Payemnts
		List<Zuora__PaymentInvoice__c> ret = new List<Zuora__PaymentInvoice__c>();
		
		//Go through the list from Zuora and convert from zObjects to sObjects and adds it to the list
		//of Invoice Payments as well as increase to max refund available by each amount available per
		//Invoice Payment
		for (Zuora.zObject payment : payments){
			Zuora__PaymentInvoice__c add = new Zuora__PaymentInvoice__c();
			add.put(Zuora__PaymentInvoice__c.Zuora__ApplyAmount__c, payment.getValue('Amount'));
			add.put(Zuora__PaymentInvoice__c.Zuora__RefundAmount__c, payment.getValue('RefundAmount'));
			add.put(Zuora__PaymentInvoice__c.Zuora__External_Id__c, payment.getValue('Id'));
			ret.add(add);
			this.refundAvailable = refundAvailable + (add.Zuora__ApplyAmount__c - add.Zuora__RefundAmount__c);
			InvoicePaymentMap.put(String.valueOf(payment.getValue('Id')), zInvoiceMap.get(String.valueOf(payment.getValue('InvoiceId'))));
			PaymentInvoicIdMap.put(String.valueOf(payment.getValue('PaymentId')), String.valueOf(payment.getValue('InvoiceId')));
		}
		
		return ret;
	}
	
	public List<Zuora__ZInvoice__c> queryInvoice(){
		List<Zuora.zObject> invoices;
		
		//Create ZOQL query
		String zoql = 'SELECT Id, InvoiceNumber from Invoice where AccountId = \'' + zId + '\'' ;
		
		if (!Test.isRunningTest()){
			zapi.zlogin();
			invoices = zapi.zquery(zoql);
		} else {
			//Creates data for testing when needed
			Zuora.zObject tempInv = new Zuora.zObject('Invoice');
			tempInv.setValue('InvoiceNumber','Invoice Number');
			tempInv.setValue('Id','Id');
			invoices = new List<Zuora.zObject>();
			invoices.add(tempInv);
		}
		
		//Creates list of invoice sObjects
		List<Zuora__ZInvoice__c> ret = new List<Zuora__ZInvoice__c>();
		
		for (Integer i=0; i<invoices.size(); i++){
			Zuora.zObject inv = invoices.get(i);
			//Create the sObject and fills it with data from the zObject and places it into the list
			Zuora__ZInvoice__c add = new Zuora__ZInvoice__c();
			add.put(Zuora__Zinvoice__c.Name, inv.getValue('InvoiceNumber'));
			add.put(Zuora__ZInvoice__c.Zuora__External_Id__c, inv.getValue('Id'));
			ret.add(add);
		}
		
		return ret;
	}
	
	public void mapInvoice(){
		zInvoiceMap = new Map<String, String>();
		for (Zuora__ZInvoice__c invoice : zInvoice){
			System.Debug(invoice.Zuora__External_Id__c + ' | ' + invoice.Name);
			zInvoiceMap.put(invoice.Zuora__External_Id__c, invoice.Name);
		}
	}
	

	/**
		Generates a PaymentSelectorCombo list, which holds various data including PaymentInvoices,
		selection boolean, and some calculated values
	*/
	public void generatePaymentSelect(){
		this.paymentSelect = new List<PaymentSelectorCombo>();
		for (Integer i=0; i<zInvoicePayment.size(); i++){
			this.paymentSelect.add(new PaymentSelectorCombo(zInvoicePayment.get(i), InvoicePaymentMap));
		}
		//Sally ElGhoul - 28/9/2015 - Update the refund amount for the payment from the query string
		setRefundAmount(this.paymentSelect);
	}
	
	//Sally El Ghoul - 28/9/2015 - Update the refund amount from the payment using the query string
	public void setRefundAmount(List<PaymentSelectorCombo> lstPaymentSelectorCombos){
		for(PaymentSelectorCombo selectorComboObj : this.paymentSelect){
			if(ApexPages.currentPage().getParameters().containsKey('amount') && !String.isEmpty(ApexPages.currentPage().getParameters().get('amount'))){
				Decimal refundAmountValue = Decimal.valueOf(ApexPages.currentPage().getParameters().get('amount'));
				if(refundAmountValue>0){
					selectorComboObj.amountRefunded=refundAmountValue;
					selectorComboObj.isSelected = true;
				}
			}
		}
	}
	

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Function -   Creates the options for the radio buttons to choose refund type
	#############Change Log#############
	Modified by         Change Date
	Mantas Grigaliunas 	03/07/2017  Added Constants, paypal related functionality
	****************************************************************************************/
	public List<SelectOption> getRefundTypeOptions() {
		final String REFUND = ' Refund';
		List<SelectOption> options = new List<SelectOption>(); 
		options.add(new SelectOption('external','External Refund')); 
		if (Test.isRunningTest())
			mustBeExternal = false;
		if (!mustBeExternal){
			if(originalPaymentMethod.contains(Constants.PAYMENT_METHOD_PAYPAL_TYPE)){
				options.add(new SelectOption(Constants.PAYMENT_METHOD_PAYPAL_TYPE, + Constants.PAYMENT_METHOD_PAYPAL_TYPE + REFUND));
			} else {
				options.add(new SelectOption(Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE_LABEL + REFUND));
			}
		}
		if (isDirectDebitType){
			options.add(new SelectOption(Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE, Constants.PAYMENT_METHOD_DIRECT_DEBIT_TYPE_LABEL + REFUND));	 
		}
		return options; 
	}
	
	/**
		Creates the options for the external payment methods list.
	*/
   //Michal Kwika 25/11/2015 SUB-1625
   //removing external options except Check
	public List<SelectOption> getMethodTypeOptions(){
		List<SelectOption> options = new List<SelectOption>(); 
		options.add(new SelectOption('', '-- Select one --'));
		//options.add(new SelectOption('ACH','ACH'));
		//options.add(new SelectOption('Cash','Cash'));
		options.add(new SelectOption('Check',Constants.SUB_PMETHOD_CHEQUE));
		//options.add(new SelectOption('CreditCard','CreditCard'));
		//options.add(new SelectOption('DebitCard','Debit Card'));
		//options.add(new SelectOption('PayPal','PayPal'));
		//options.add(new SelectOption('WireTransfer','Wire Transfer'));
		//options.add(new SelectOption('CreditCardReferenceTransaction','Credit Card Ref Trans'));
		//options.add(new SelectOption('Other','Other'));
		return options;
	}
	
	/**
		Returns to previous page upon cancel
	*/
	public PageReference cancel(){
		return new PageReference('/apex/Manage_Billing_Account?id=' + billId);
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Function -   Submits the refund to be processed
	#############Change Log#############
	Modified by         Change Date
	Gavin Palmer 		20/06/2016  moved error messages into labels
	Pawel Chrzanowski   24/01/2017  added comment check
	Pawel Chrzanowski 	24/01/2017  added comment check
	Mantas Grigaliunas 	03/07/2017  Amendment on refundType assignment
	****************************************************************************************/
	public PageReference submit(){
		//If total refund is greater than that available, show error
		if(Amount > refundAvailable){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Refunds_Refund_too_much));
			return null;
		}
		if(Amount <= 0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Refunds_0));
			if (!Test.isRunningTest())
				return null;
		}
		//check refund reason
		if(refundReason==null || String.isEmpty(refundReason)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Refunds_Reason_Required));
			return null;
		}
		//check comment
		if(String.isNotBlank(comment) && comment.length() > 255){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Comment_Too_Long));
			return null;
		}
		//Go to correct function depending on type of refund
		if(String.isBlank(refundType)){
			//Show error if none selected
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Manage_Refunds_No_Refund_Type));
			return null;
		} else if(refundType=='external') {
			return externalRefund();
		} else {
			return creditCardRefund();
		}
	}

	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.0
	Function -   Process an external refund
	#############Change Log#############
	Modified by     Version     Change Date
	Michal Szewczyk	1.1         22/02/2016  Changes around Invoice Adjustment
	Michal Szewczyk	1.2         07/03/2016  Replace Invoice Adjustment with Credit Balance 
	Pawel Chrzanowski 1.3       24/01/2017  Added comment support
	****************************************************************************************/
	public PageReference externalRefund(){
		//Creates the zObject and fills it with correct values
		Zuora.zObject refund;
		List<Zuora.zObject> invoicesItems;
		List<Zuora.zObject> objs = new List<Zuora.zObject>();
		List<Zuora.zObject> objsCreditBalance = new List<Zuora.zObject>();
		//Login to Zuora

		for (PaymentSelectorCombo refundA : paymentSelect){
			refund = new Zuora.zObject('Refund');
			refund.setValue('AccountId', zId);
			refund.setValue('Amount', refundA.amountRefunded);
			refund.setValue('PaymentId', pId);
			refund.setValue('SourceType', 'Payment');
			refund.setValue('MethodType', methodType);
			refund.setValue('Type', 'External');
			if(String.isNotBlank(comment)){
				refund.setValue('Comment', comment);
			}
			//add refund reason
			refund.setValue('RefundReason__c', refundReason);
			//refund.setValue('RefundDate', Zuora.zUtil.getZuoraDate(ConvertDate(refundDate)));
			//code js
			refund.setValue('RefundDate', String.valueOf(ConvertDate(refundDate)).split(' ')[0]);
			//end code js
			objs.add(refund);
			if (!Test.isRunningTest()){

				String invoiceId = PaymentInvoicIdMap.get(pId);
				String invoiceRefundedId = Zuora_BillingPreviewUtility.createSubsDiscretionaryDiscount(zapi,invoiceId,refundA.amountRefunded);
				
				//Create credit balance
				if(invoiceRefundedId != null && invoiceRefundedId !='') {
						Zuora.zObject creditBalanceItem = new Zuora.zObject('CreditBalanceAdjustment');
			    		creditBalanceItem.setValue('Amount',refundA.amountRefunded);
			    		creditBalanceItem.setValue('Type','Increase');
						creditBalanceItem.setValue('SourceTransactionId',invoiceRefundedId );
		    		objsCreditBalance.add(creditBalanceItem);
				}
			}
		}
		System.debug('TMGLOG:MakeRefund:externalRefund objsCreditBalance: ' + objsCreditBalance);
		if (objs.isEmpty()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to perform rufunds unassociated with an invoice.  Credit Balance refund not currently supported.');
			ApexPages.addMessage(myMsg);
			return null;
		}
		
		try{
			List<Zuora.zApi.SaveResult> results; 
			List<Zuora.zApi.SaveResult> resultsCreditBalance;
			if (!Test.isRunningTest()){
			//Login to Zuora and update Account with new Default Payment Method
				results = zapi.zcreate(objs);
				System.debug('TMGLOG:MakeRefund:externalRefund results: ' + results);
				resultsCreditBalance = zapi.zcreate(objsCreditBalance);
				System.debug('TMGLOG:MakeRefund:externalRefund resultsCreditBalance: ' + resultsCreditBalance);
			} else {
				//Generate test results when testing
				Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
				res.Success = false;
				Zuora.zObject error = new Zuora.zObject('Error');
				res.errors = new Zuora.zObject[]{error};
				results = new List<Zuora.zApi.SaveResult>{};
				results.add(res);
			}
			//Goes through results and shows error for any that fail.
			for (Zuora.zApi.SaveResult result : results){
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
		} catch (Exception e){
			//Throws error if exception occurs
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
			ApexPages.addMessage(myMsg);
			System.debug('Error! ' + e.getMessage());
			return null;
		}
		return new PageReference('/apex/Manage_Billing_Account?id=' + billId);
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.0
	Function -   Process an electronic refund
	#############Change Log#############
	Modified by     Version     Change Date
	Michal Szewczyk	1.1         22/02/2016  Changes around Invoice Adjustment
	Michal Szewczyk	1.2         07/03/2016  Replace  Invoice Adjustment with Credit Balance 
	Pawel Chrzanowski 1.3       24/01/2017  Added comment support
	****************************************************************************************/
	public PageReference creditCardRefund(){
		//Creates the zObject and fills it with correct values
		Zuora.zObject refund;
		List<Zuora.zObject> invoicesItems;
		List<Zuora.zObject> objs = new List<Zuora.zObject>();
		List<Zuora.zObject> objsCreditBalance = new List<Zuora.zObject>();

		for (PaymentSelectorCombo refundA : paymentSelect){
			refund = new Zuora.zObject('Refund');
			refund.setValue('AccountId', zId);
			refund.setValue('Amount', refundA.amountRefunded);
			refund.setValue('PaymentId', pId);
			refund.setValue('SourceType', 'Payment');
			refund.setValue('Type', 'Electronic');
			if(String.isNotBlank(comment)){
				refund.setValue('Comment', comment);
			}
			//add refund reason
			refund.setValue('RefundReason__c', refundReason);
			objs.add(refund);
			if (!Test.isRunningTest()){
				String invoiceId = PaymentInvoicIdMap.get(pId);
				String invoiceRefundedId = Zuora_BillingPreviewUtility.createSubsDiscretionaryDiscount(zapi,invoiceId,refundA.amountRefunded);
				
				//Create credit balance
				if(invoiceRefundedId != null && invoiceRefundedId !='') {
						Zuora.zObject creditBalanceItem = new Zuora.zObject('CreditBalanceAdjustment');
			    		creditBalanceItem.setValue('Amount',refundA.amountRefunded);
			    		creditBalanceItem.setValue('Type','Increase');
						creditBalanceItem.setValue('SourceTransactionId',invoiceRefundedId );
		    		objsCreditBalance.add(creditBalanceItem);
				} else {
					// Error messages handled in ZuoraBillingPreviewUtility
					if(ApexPages.hasMessages()) return null;

					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Invoice_Id_Error));
					return null;
				}
			}
		}
		System.debug('TMGLOG:MakeRefund:creditCardRefund objsCreditBalance: ' + objsCreditBalance);
		if (objs.isEmpty()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to perform rufunds unassociated with an invoice.  Credit Balance refund not currently supported.');
			ApexPages.addMessage(myMsg);
			return null;
		}
		
		try{
			List<Zuora.zApi.SaveResult> results;
			List<Zuora.zApi.SaveResult> resultsCreditBalance;
			if (!Test.isRunningTest()){
			//Login to Zuora and update Account with new Default Payment Method
				results = zapi.zcreate(objs);
				System.debug('TMGLOG:MakeRefund:creditCardRefund results: ' + results);
				resultsCreditBalance = zapi.zcreate(objsCreditBalance);
				System.debug('TMGLOG:MakeRefund:creditCardRefund resultsCreditBalance: ' + resultsCreditBalance);
			} else {
				//Generate data for testing purposes when needed
				Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
				res.Success = false;
				Zuora.zObject error = new Zuora.zObject('Error');
				res.errors = new Zuora.zObject[]{error};
				results = new List<Zuora.zApi.SaveResult>{};
				results.add(res);
				
			}
			//Goes through results and shows error for any that fail.
			for (Zuora.zApi.SaveResult result : results){
				if (!result.Success){
					Zuora.zObject[] errors = result.errors;
					String errorText;
					for (Zuora.zObject error : errors) {
						errorText = errorText + (String)error.getValue('Code') + ': ' + (String)error.getValue('Message') + ':F '+ (String)error.getValue('Field')+'\n';
						System.debug('### ErrosText: ' + errorText);
					}
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Failure to update| \n' + errorText);
					ApexPages.addMessage(myMsg);
					if (!Test.isRunningTest())
						return null;
				}
				else {
					System.debug('@@@ Success Id: ' + result.Id + ' Success? ' + result.Success);
					if(isRefundCorrect(objs)){
						ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Refund_Tool_RefundDone);
						ApexPages.addMessage(myMsg);
						notificationOptions.continueAction = 'backToRefundTool();';
						return null;
					}

					else {
						System.debug('@@@ Refund was not correct!');
						ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Refund_Tool_RefundNotDone);
						ApexPages.addMessage(myMsg);
						notificationOptions.continueAction = 'backToRefundTool();';
						return null;
					}
					

				}
			}
		} catch (Exception e){
			//Throws error if exception occurs
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
			ApexPages.addMessage(myMsg);
			System.debug('Error! ' + e.getMessage());
			return null;
		}
		return new PageReference('/apex/Manage_Billing_Account?id=' + billId);
	}
	
	/**
		Update refund total when checkboxes and selected/deselected
	*/
	public void updateRefundTotal(){
		//Sets total amount to 0
		Amount = 0.00;
		
		//Goes through all paymentinvoices
		for (PaymentSelectorCombo ps : paymentSelect){
			//if current one is selected
			if (ps.isSelected){
				//and its personal amount refunded is 0
				if (ps.amountRefunded==0){
					//set amount refunded to max available amount
					ps.amountRefunded = ps.availableRefund;
				}
				//Add amount refunded to total amount refunded
				Amount += ps.amountRefunded;
			} else if (!ps.isSelected && ps.amountRefunded!=0){
				//If is it deselected and its amount refunded is not 0, set its
				//refunded amount to zero.
				ps.amountRefunded=0.00;
			}
		}
	}
	
	/**
		Updates values when amount refunded on individual payment invoices is changes
	*/
	public void updateValues(){
		//sets total amount to 0
		Amount = 0.00;
		
		//Goes through each payment invoice
		for (PaymentSelectorCombo ps : paymentSelect){
			//If payment invoice is selected
			if (ps.isSelected){
				//and its refund amount is set to 0
				if (ps.amountRefunded==0){
					//set it to deselected and go to next payment invoice
					ps.isSelected = false;
					continue;
				}
				//add the refunded amount to the total
				Amount += ps.amountRefunded;
			} else if (!ps.isSelected && ps.amountRefunded != 0){
				//if refunded amount is not 0 and it is not selected, change it to selected,
				//and add the refunded amount to the total
				ps.isSelected = true;
				Amount += ps.amountRefunded;
			}
		}
	}
	
	/**
		Update date to today when electronic refund is chosen
	*/
	public void updateDate(){
		if (refundType=='electronic'){
			String[] todays = String.valueOf(Date.today()).split('-',0);
			this.refundDate = todays[2] + '/' + todays[1] + '/' + todays[0];
		}
	}
	
	/**
		Confirms error message and clears all messages on page.
	*/
	public void confirmError(){
		ApexPages.getMessages().clear();
	}
	
	/**
		Object that holds various data, including an payment invoice, a boolean representing selection, and
		the amount to be refunded (as well as validation for setting the value), and a calculation of the
		max amount available for refund.
	*/
	public class PaymentSelectorCombo {
		
		public Zuora__PaymentInvoice__c PaymentInvoice {get;set;}
		public Boolean isSelected {get;set;}
		public Decimal amountRefunded 
									{get;
										set{
											if (value > availableRefund){
												ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Total Refund higher than maximum refund allowed!  Value set to maximum allowable refund.');
												ApexPages.addMessage(myMsg);
												amountRefunded = availableRefund;
											} else
												amountRefunded = value;
										}}
		public Decimal availableRefund {get;set;}
		public String InvoiceName {get;set;}
		
		public PaymentSelectorCombo (Zuora__PaymentInvoice__c pi, Map<String,String> zInvoiceMap) {
			PaymentInvoice = pi;
			isSelected = false;
			amountRefunded = 0.00;
			availableRefund = pi.Zuora__ApplyAmount__c - pi.Zuora__RefundAmount__c;
			System.Debug(pi.Zuora__External_Id__c + ' | ' + zInvoiceMap.get(pi.Zuora__External_Id__c));
			InvoiceName = zInvoiceMap.get(pi.Zuora__External_Id__c);
			if (Test.isRunningTest())
				isSelected = true;
		}
		
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/11/2015
	Function    go back to refund tool
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public PageReference backToRefundTool(){
		return new PageReference('/apex/Manage_Billing_Account?id=' + billId);
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/11/2015
	Function    check Refund status
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	private Boolean isRefundCorrect(List<Zuora.zObject> madeZuoraRefunds){
		Boolean isSuccess = false;
		List<Zuora.zObject> lRefundsFromZuora = new List<Zuora.zObject>();
		 //login to Zuora if not test is runing 
		if (!Test.isRunningTest()){
			zapi.zlogin();
		}
		//check only last 24hours
		Datetime dt = System.now()-1;
		String s = dt.format('yyyy-MM-dd\'T\'HH:mm:ss');

		//Create ZOQL query
		String zoql = 'SELECT Amount, Type, Status, Id from Refund where AccountId = \'' + zId + '\' and CreatedDate >= \'' + s + '\' and Status = \'' + Constants.DIAGNOSTICS_EXTRACT_STATUS_ERROR + '\' limit 50';
		if (!Test.isRunningTest()){
			//Query for Invoices from Zuora
			lRefundsFromZuora = zapi.zquery(zoql);
		}else {
			Zuora.zObject tempInvoice = new Zuora.zObject('Refund');
			tempInvoice.setValue('Status','Error');
			tempInvoice.setValue('Id', 'pId');
			tempInvoice.setValue('Amount', 10.00);
			lRefundsFromZuora.add(tempInvoice);
  
		}
		System.debug('@@@ Refunds from Zuora: ' + lRefundsFromZuora);
		System.debug('@@@ 1st refund tried to create amount: ' + (Decimal)madeZuoraRefunds.get(0).getValue('Amount'));
		if(lRefundsFromZuora.isEmpty()){
			System.debug('@@@ There is no failed refund related to Account');
			isSuccess = true;
		}
		else {
			for (Zuora.zObject failedRefund: lRefundsFromZuora){
				for(Zuora.zObject madeRefund: madeZuoraRefunds){
					if((Decimal)failedRefund.getValue('Amount') == (Decimal)madeRefund.getValue('Amount')){
						return false;
					}
				}
			}
			
		}

		return isSuccess;


	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        25/11/2015
	Function    get Selectlist from Refund Reason
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	public List<SelectOption> getRefundReasonOptions(){
		
		//the list of select option to return 
		list<selectOption> lstResult=new list<selectOption>();
		//get the field 
		Schema.DescribeFieldResult refundReasonField = Zuora__Refund__c.RefundReason__c.getDescribe(); 
		//get the picklist values of the  field
		List<Schema.PicklistEntry> refundReasonValues = refundReasonField.getPicklistValues();
		
		lstResult.add(new SelectOption('','-- Select Reason --'));
		//loop on the picklist values and fill the list of selectoption
		for(Schema.PicklistEntry entryObj : refundReasonValues){
			lstResult.add(new selectOption(entryObj.getValue(),entryObj.getLabel()));
		}
		
		//return the available payment methods
		return lstResult;
	}
}