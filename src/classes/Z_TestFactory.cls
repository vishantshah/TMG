/************************************************************************************
Class Name   : Z_TestFactory
Author       : Mantas Grigaliunas
Created Date : 20/06/2016
Function     : Class to hold all Zuora Test records
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas Grigaliunas    02/05/2017   Added extra methods to be able to create data for different Zuora related test scenarios
*************************************************************************************/
@isTest
public class Z_TestFactory {

    //Account
    public static Integer testAccountBalance = 0;

    //Subscription
    public static Boolean createZuoraSubscriptionTestRecord = true;
    public static String  testSubscriptionStatus            = Constants.SUBSCRIPTION_ACTIVE_STATUS;
    public static Date    testSubscriptionStartDate         = Date.today().addMonths(-1);
    public static Date    testSubscriptionTermEndDate       = Date.today().addMonths(8);

    //Invoice
    public static Map<String, List<String>> invoiceParameters = new Map<String, List<String>>();

    //InvoiceItem
    public static Boolean createZuoraInvoiceItemTestRecord        = true;
    public static Map<String, List<String>> invoiceItemParameters = new Map<String, List<String>>();

    //Payment
    public static Decimal testPaymentAmount       = 12;
    public static String  testPaymentType         = Constants.ZUORA_REFUND_TYPE_ELECTRONIC;
    public static String  testPaymentGatewayState = Constants.ZUORA_PAYMENT_GATEWAY_STATE_SUBMITTED;
    public static String  testPaymentId           = Constants.ZUORA_TEST_STRING;
    public static Boolean testPaymentVoided       = true;

    //InvoicePayment
    public static Map<String, List<String>> invoicePaymentParameters = new Map<String, List<String>>();

    //PaymentMethod
    public static String testPaymentMethod                 = Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE;
    public static String testInvoicePaymentMethodInvoiceId = Constants.ZUORA_TEST_STRING;

    //Amendment
    public static Decimal testAmendmentAmount    = -6;
    public static Boolean testAmendmentSuccess   = true;
    public static String  testAmendmentInvoiceId = Constants.ZUORA_TEST_STRING;

    //TaxationItem
    public static String testTaxationItemInvoiceItemId = Constants.ZUORA_TEST_STRING;

    /************************************************************************************
    Method Name  : generateZuoraTestData
    Author       : Mantas Grigaliunas
    Created Date : 03/05/2017
    Function     : Creates zuora test data based on query passed
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zObject> generateZuoraTestData(String query){

        String QFROM = 'from ';
        String objectName;
        objectName = query.toLowerCase().substringBetween(QFROM, ' ');
        if(objectName == null) objectName = query.toLowerCase().substringAfter(QFROM);

        if (objectName.equalsIgnoreCase('Account'))        { return createZuoraAccounts();        }
        if (objectName.equalsIgnoreCase('Subscription'))   { return createZuoraSubscriptions();   }
        if (objectName.equalsIgnoreCase('InvoiceItem'))    { return createZuoraInvoiceItems();    }
        if (objectName.equalsIgnoreCase('InvoicePayment')) { return createZuoraInvoicePayments(); }
        if (objectName.equalsIgnoreCase('Invoice'))        { return createZuoraInvoices();        }
        if (objectName.equalsIgnoreCase('Payment'))        { return createZuoraPayments();        }
        if (objectName.equalsIgnoreCase('TaxationItem'))   { return createZuoraTaxationItems();   }
        if (objectName.equalsIgnoreCase('PaymentMethod'))  { return createZuoraPaymentMethods();  }
        return null;
    }   

    /************************************************************************************
    Method Name  : makeAccount
    Author       : Mantas Grigaliunas
    Created Date : 20/06/2016
    Function     : Creates test account
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static Account makeAccount() {
		Account testAcc = new Account();
		testAcc.Name = 'my test account';
		insert testAcc;
		return testAcc;
	}

    /************************************************************************************
    Method Name  : createZuoraAccounts
    Author       : Mantas Grigaliunas
    Created Date : 20/06/2016
    Function     : Creates a list of zuora test accounts
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static List<Zuora.zObject> createZuoraAccounts(){

		List<Zuora.zObject> zAccounts = new List<Zuora.zObject>();
        Zuora.zObject testAccount = new Zuora.zObject('Account');
        testAccount.setValue('AccountNumber', Constants.ZUORA_TEST_STRING);
        testAccount.setValue('Name', Constants.ZUORA_TEST_STRING);
        testAccount.setValue('Id', Constants.ZUORA_TEST_STRING);
        testAccount.setValue('DefaultPaymentMethodId', Constants.ZUORA_TEST_STRING);
        testAccount.setValue('TotalInvoiceBalance', 0);
        testAccount.setValue('Balance', testAccountBalance);
        testAccount.setValue('CreditBalance', 0);
        zAccounts.add(testAccount);

        return zAccounts;
  	}

    /************************************************************************************
    Method Name  : createZuoraSubscriptions
    Author       : Mantas Grigaliunas
    Created Date : 30/06/2016
    Function     : Creates a list of zuora test payments
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zObject> createZuoraSubscriptions(){

        List<Zuora.zObject> zSubscriptions = new List<Zuora.zObject>();
        if(createZuoraSubscriptionTestRecord){
            Zuora.zObject testSubscription =  new Zuora.zObject('Subscription');
            testSubscription.setValue('Id', Constants.ZUORA_TEST_STRING);
            testSubscription.setValue('Name', Constants.ZUORA_TEST_STRING);
            testSubscription.setValue('AccountId', Constants.ZUORA_TEST_STRING);
            testSubscription.setValue('SubscriptionStartDate', testSubscriptionStartDate);
            testSubscription.setValue('TermEndDate', testSubscriptionTermEndDate);
            testSubscription.setValue('Status', testSubscriptionStatus);
            zSubscriptions.add(testSubscription);
        }
        return zSubscriptions;
    }

    /************************************************************************************
    Method Name  : createZuoraPayments
    Author       : Mantas Grigaliunas
    Created Date : 20/06/2016
    Function     : Creates a list of zuora test payments
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static List<Zuora.zObject> createZuoraPayments(List<DateTime> paymentDatesList){

		List<Zuora.zObject> zPayments = new List<Zuora.zObject>();

		for(DateTime dt : paymentDatesList){

            Zuora.zObject testPayment = new Zuora.zObject('Payment');
            testPayment.setValue('Amount', testPaymentAmount);
            testPayment.setValue('RefundAmount', 0.00);
            testPayment.setValue('PaymentNumber','PaymentNumber');
            testPayment.setValue('CreatedDate', dt);
            testPayment.setValue('EffectiveDate', dt);
            testPayment.setValue('PaymentMethodId', Constants.ZUORA_TEST_STRING);
            testPayment.setValue('Id', testPaymentId);
            testPayment.setValue('Type', testPaymentType);
            testPayment.setValue('GatewayState', testPaymentGatewayState);
            zPayments.add(testPayment);
        }
        return zPayments;
	}

    public static List<Zuora.zObject> createZuoraPayments(){
        return createZuoraPayments(new List<DateTime>{DateTime.now()});
    }

    /************************************************************************************
    Method Name  : createZuoraPaymentMethods
    Author       : Mantas Grigaliunas
    Created Date : 20/06/2016
    Function     : Creates a list of zuora test payment methods
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static List<Zuora.zObject> createZuoraPaymentMethods(){

		List<Zuora.zObject> zPaymentMethods = new List<Zuora.zObject>();

		Zuora.zObject testPm = new Zuora.zObject('PaymentMethod');

        testPm.setValue('CreditCardHolderName','Name');
        testPm.setValue('CreditCardMaskNumber','Number');
        testPm.setValue('CreditCardType','Type');
        testPm.setValue('CreditCardExpirationMonth','01');
        testPm.setValue('CreditCardExpirationYear','2014');
        testPm.setValue('Id', Constants.ZUORA_TEST_STRING);
        testPm.setValue('CreditCardAddress1','Address');
        testPm.setValue('CreditCardAddress2','Address');
        testPm.setValue('CreditCardCity','City');
        testPm.setValue('CreditCardState','State');
        testPm.setValue('CreditCardCountry','Country');
        testPm.setValue('CreditCardPostalCode','PCode');
        testPm.setValue('Type', testPaymentMethod);
        zPaymentMethods.add(testPm);

        return zPaymentMethods;
	}

    /************************************************************************************
    Method Name  : createZuoraInvoices
    Author       : Mantas Grigaliunas
    Created Date : 20/06/2016
    Function     : Creates a list of zuora test invoices
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public static List<Zuora.zObject> createZuoraInvoices(){

        if(invoiceParameters.isEmpty()){
            invoiceParameters.put(Constants.ZUORA_TEST_STRING, new List<String>{Constants.ZUORA_TEST_STRING, '-6'});
        }
		
		List<Zuora.zObject> zInvoices = new List<Zuora.zObject>();

        for(String invId : invoiceParameters.keySet()){
            List<String> params = invoiceParameters.get(invId);
            Zuora.zObject testInvoice = new Zuora.zObject('Invoice');
            testInvoice.setValue('Id', invId);
            testInvoice.setValue('InvoiceNumber', params.get(0));
            testInvoice.setValue('Balance', 0);
            testInvoice.setValue('PaymentAmount', 0.00);
            testInvoice.setValue('Amount', Decimal.valueOf(params.get(1)));
            testInvoice.setValue('RefundAmount',0.00);
            testInvoice.setValue('Status','Posted');
            testInvoice.setValue('TargetDate', Date.today().addMonths(1));
            zInvoices.add(testInvoice);
        }
        return zInvoices;
	}

    /************************************************************************************
    Method Name  : createZuoraInvoiceItems
    Author       : Mantas Grigaliunas
    Created Date : 30/06/2016
    Function     : Creates a list of zuora test invoice items
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zObject> createZuoraInvoiceItems(){

        if(invoiceItemParameters.isEmpty()){
            invoiceItemParameters.put(Constants.ZUORA_TEST_STRING, 
                new List<String>{Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, '-8', '-2'});
        }

        List<Zuora.zObject> zInvoiceItems = new List<Zuora.zObject>();
        if(createZuoraInvoiceItemTestRecord){
            for(String invItemId : invoiceItemParameters.keySet()){
                List<String> params = invoiceItemParameters.get(invItemId);
                Zuora.zObject invoiceItem = new Zuora.zObject('InvoiceItem');
                invoiceItem.setValue('Id', invItemId);
                invoiceItem.setValue('SubscriptionId', params.get(0));
                invoiceItem.setValue('SubscriptionNumber', params.get(0));
                invoiceItem.setValue('InvoiceId', params.get(1));
                invoiceItem.setValue('ChargeName', 'Partner Membership - Annual');
                invoiceItem.setValue('ServiceStartDate', Date.today());
                invoiceItem.setValue('ServiceEndDate', Date.today().addMonths(1));
                invoiceItem.setValue('ChargeAmount', Decimal.valueOf(params.get(2)));
                invoiceItem.setValue('TaxAmount', Decimal.valueOf(params.get(3)));
                zInvoiceItems.add(invoiceItem);
            }
        }
        return zInvoiceItems;
    }

    /************************************************************************************
    Method Name  : createZuoraInvoicePayments
    Author       : Mantas Grigaliunas
    Created Date : 28/04/2017
    Function     : Creates a list of zuora test invoice payment
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zObject> createZuoraInvoicePayments(){

        if(invoicePaymentParameters.isEmpty()){
            invoicePaymentParameters.put(Constants.ZUORA_TEST_STRING, new List<String>{'12', Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING});
        }

        List<Zuora.zObject> zInvoicePayments = new List<Zuora.zObject>();
        for(String invPaymentId : invoicePaymentParameters.keySet()){
            List<String> params = invoicePaymentParameters.get(invPaymentId);
            Zuora.zObject invoicePayment = new Zuora.zObject('InvoicePayment');
            invoicePayment.setValue('Id', invPaymentId);
            invoicePayment.setValue('Amount', Decimal.valueOf(params.get(0)));
            invoicePayment.setValue('PaymentId', params.get(1));
            invoicePayment.setValue('InvoiceId', params.get(2));
            zInvoicePayments.add(invoicePayment);
        }
        return zInvoicePayments;
    }

    /************************************************************************************
    Method Name  : createZuoraTaxationItems
    Author       : Mantas Grigaliunas
    Created Date : 28/04/2017
    Function     : Creates a list of zuora test invoice payment
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zObject> createZuoraTaxationItems(){

        List<Zuora.zObject> zTaxationItems = new List<Zuora.zObject>();
        Zuora.zObject taxationItem = new Zuora.zObject('TaxationItem');
        taxationItem.setValue('Id', Constants.ZUORA_TEST_STRING);
        taxationItem.setValue('InvoiceItemId', testTaxationItemInvoiceItemId);
        zTaxationItems.add(taxationItem);
        return zTaxationItems;
    }

    /************************************************************************************
    Method Name  : createZuoraTestSaveResultError
    Author       : Mantas Grigaliunas
    Created Date : 12/10/2016
    Function     : Creates a list of zuora test save results with errors
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zApi.SaveResult> createZuoraTestSaveResultError(){
        //create zuora test save results
        List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();
        Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
        res.Success = false;
        Zuora.zObject error = new Zuora.zObject(Constants.ZUORA_ERROR_OBJECT_NAME);
        error.setValue(Constants.ZUORA_ERROR_CODE_ATTRIBUTE_NAME, Constants.ZUORA_TEST_STRING);
        error.setValue(Constants.ZUORA_ERROR_MESSAGE_ATTRIBUTE_NAME, Constants.ZUORA_TEST_STRING);
        res.errors = new Zuora.zObject[]{error};
        results.add(res);
        return results;
    }

    /************************************************************************************
    Method Name  : createZuoraTestSaveResultSuccess
    Author       : Mantas Grigaliunas
    Created Date : 12/10/2016
    Function     : Creates a list of zuora test success save results
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static List<Zuora.zApi.SaveResult> createZuoraTestSaveResultSuccess(){
        //create zuora test save results
        List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();
        Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
        res.Success = true;
        results.add(res);
        return results;
    }

    /************************************************************************************
    Method Name  : createZuoraTestAmendment
    Author       : Mantas Grigaliunas
    Created Date : 02/05/2017
    Function     : Create test zuora amendment result
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public static  Zuora.zApi.AmendResult createZuoraTestAmendment(){

        Zuora.zApi.AmendResult amendResult;

        List<Zuora.zObject> lstinvoiceDatasValues = new List<Zuora.zObject>();
            
        Zuora.ZObject invoiceDatasValue = new Zuora.zObject('InvoiceData');   
        List<Zuora.zObject> lstInvoices = new List<Zuora.zObject>();
        
        Zuora.zObject invoiceItem = new Zuora.zObject('InvoiceItem');    
        invoiceItem.setValue('ChargeAmount',9.5);
        invoiceItem.setValue('TaxAmount',0.5);
        invoiceItem.setValue('ServiceStartDate',Date.today());
        lstInvoices.add(invoiceItem);
        invoiceDatasValue.setValue('InvoiceItem',lstInvoices);
        
        Zuora.zobject invoiceObj = new Zuora.zobject('Invoice');
        invoiceObj.setValue('Amount', testAmendmentAmount);
        invoiceDatasValue.setValue('Invoice',invoiceObj);
        
        lstinvoiceDatasValues.add(invoiceDatasValue);

        amendResult = new Zuora.zApi.AmendResult();
        amendResult.InvoiceDatas = new List<Zuora.zObject>();
        amendResult.InvoiceDatas.add(invoiceDatasValue);   
        amendResult.Success = testAmendmentSuccess;
        amendResult.InvoiceId = testAmendmentInvoiceId;
        amendResult.SubscriptionId = Constants.ZUORA_TEST_STRING;

        return amendResult;
    }
}