/********************************************************************
 * testBillingAccountManager
 * Author: Unknown
#############Change Log#############
* Modified by           Version     Change Date
  Mantas Grigaliunas    1.1         20/06/2016  //added filterPaymentsByDateAndPaymentMethodTest() test method
  Mantas Grigaliunas    1.2         02/05/2017  //added getNotAllowedForRefundPaymentsMapTest()
********************************************************************/

@isTest (SeeAllData=true)
private class testBillingAccountManager {

    static final String SUBSCRIPTION_NUMBER   = '123456789';
    static final String INVOICE_ID            = 'I123';
    static final String PAYMENT_ID            = 'P123';

    static testMethod void BillingAccountManagerTest() {
        Test.startTest();
        ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller(new Zuora__CustomerAccount__c());
        BillingAccountManager bam = new BillingAccountManager(controller);
        bam.addCard();
        bam.editCards();
        bam.confirmError();
        bam.deleteCards();
        bam.makePayment();
        bam.setDefault();
        bam.selectIndex();
        bam.cancel();
        string strTestValue=bam.paymentMethodRefundId;
        strTestValue=bam.paymentRefundId;
        //Michal Kwika 06/10/2015 SUB-1180
        bam.transferToCreditBalance();
        bam.creditToInvoice();
        bam.makeRefund();
        //Michal Kwika 02/12/2015 improving code coverage
        bam.getBillingAccount();
        bam.getPaymentMethods();
        bam.invokeActionsToShowPayments();
        bam.RefreshUI();
        List <SelectOption> listPay = bam.lAllPaymentMethods;
        Test.stopTest();
    }


    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 20/06/2016
    Function - test method for filterPaymentsByDateAndPaymentMethod() and filterPaymentsByDate()
    #############Change Log#############
    Modified by         Change Date
    Mantas Grigaliunas  03/05/2017  added Zuora parameters 
    ****************************************************************************************/
    static testMethod void filterPaymentsByDateAndPaymentMethodTest(){

        Test.startTest();

        //add product
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();

        //define zuora test params
        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{tdu.lstZuoraSubscriptions[0].Name, INVOICE_ID, '8', '2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };
        Z_TestFactory.invoiceItemParameters    = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters = invoicePaymentParams;
        Z_TestFactory.testPaymentId            = PAYMENT_ID;   

        //call the constructor class
        BillingAccountManager bam = new BillingAccountManager(new ApexPages.Standardcontroller(new Zuora__CustomerAccount__c()));
        System.assertEquals(3, bam.zPayments.size(), 'Constructor');

        //define dates as strings
        String[] today = String.valueOf(Date.today()).split('-',0);

        //Test1. paymentFrom and paymentTo values are blank
        bam.paymentFrom = '';
        bam.paymentTo = '';
        bam.selectIndex();
        System.assertEquals(bam.zPayments.size(), bam.viewedPayments.size(), 'Test1');
        //Test2. paymentFrom/paymentTo set to invalid date
        bam.paymentFrom = '34/02/2014';
        bam.paymentTo = '1 July 2016';
        bam.selectIndex();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
                        Label.Manage_Billing_Account_Filter_Invalid_Date_Error_Message), 'Test2');
        //Test3. paymentFrom set to invalid date
        bam.paymentFrom = 'Test2Date';
        bam.paymentTo = '01/01/2016';
        bam.selectIndex();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
                        Label.Manage_Billing_Account_Filter_Invalid_Date_Error_Message), 'Test3');
        //Test4. paymentTo set to invalid date
        bam.paymentFrom = TMGUtil.convertDateToString(Date.today().addMonths(5));
        bam.paymentTo = '2000-01-20';
        bam.selectIndex();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
                        Label.Manage_Billing_Account_Filter_Invalid_Date_Error_Message), 'Test4');
        //Test5. paymentFrom is blank and paymentTo correct date
        bam.paymentFrom = '';
        bam.paymentTo = TMGUtil.convertDateToString(Date.today());
        bam.selectIndex();
        System.assertEquals(2, bam.viewedPayments.size(), 'Test5');
        //Test6. paymentTo is null and paymentFrom correct date
        bam.paymentFrom = TMGUtil.convertDateToString(Date.today());
        bam.paymentTo = null;
        bam.selectIndex();
        System.assertEquals(2, bam.viewedPayments.size(), 'Test6');
        //Test7. paymentTo and paymentFrom are set in correct dates
        bam.paymentFrom = TMGUtil.convertDateToString(Date.today().addMonths(-3));
        bam.paymentTo = TMGUtil.convertDateToString(Date.today().addMonths(2));
        bam.selectIndex();
        System.assertEquals(bam.zPayments.size(), bam.viewedPayments.size(), 'Test7');
        //Test8. paymentTo is before paymentFrom date
        bam.paymentFrom = TMGUtil.convertDateToString(Date.today().addMonths(1));
        bam.paymentTo = TMGUtil.convertDateToString(Date.today().addMonths(-1));
        bam.selectIndex();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),
                        Label.Manage_Billing_Account_Filter_Date_Error_Message), 'Test8');

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 03/05/2017
    Version - 1.0
    Function - test method for filterPaymentsByDateAndPaymentMethod() and filterPaymentsByDate()
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    @isTest(SeeAllData=true)
    static void getNotAllowedForRefundPaymentsMapTest(){

        Test.startTest();

        //add product
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptionProductCharges();
        tdu.createZProducts();

        //define zuora test params
        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{tdu.lstZuoraSubscriptions[0].Name, INVOICE_ID, '8', '2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

        Z_TestFactory.invoiceItemParameters    = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters = invoicePaymentParams;
        Z_TestFactory.testPaymentId            = PAYMENT_ID;  

        BillingAccountManager bam = new BillingAccountManager();
        System.assertEquals(1, bam.getNotAllowedForRefundPaymentsMap(new Set<String>{PAYMENT_ID}).size());

        Test.stopTest();
    }

}