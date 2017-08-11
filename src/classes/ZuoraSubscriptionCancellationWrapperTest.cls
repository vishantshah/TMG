/************************************************************************************
Class Name   : ZuoraSubscriptionCancellationWrapperTest
Author       : Mantas Grigaliunas
Created Date : 29/03/2017
Function     : Test class for ZuoraSubscriptionCancellationWrapper
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
public class ZuoraSubscriptionCancellationWrapperTest {

	static final String SUBSCRIPTION_ID   = 'S123';
	static final String CANCEL_INVOICE_ID = 'C123';
    static final String INVOICE_ID        = 'I123';
    static final String PAYMENT_ID        = 'P123';


	/************************************************************************************
  	Method Name  : constructorTest
  	Author       : Mantas Grigaliunas
  	Created Date : 29/03/2017
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void constructorTest(){

		ZuoraSubscriptionCancellationWrapper testWrapper = new ZuoraSubscriptionCancellationWrapper(
			Constants.ZUORA_TEST_STRING, 0, 0, 0, Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, 
			Constants.ZUORA_TEST_STRING, 0, Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING, Constants.ZUORA_TEST_STRING);
		System.assert(testWrapper != null);
	}

	/************************************************************************************
  	Method Name  : getZuoraSubscriptionCancellationWrapperListTest
  	Author       : Mantas Grigaliunas
  	Created Date : 29/03/2017
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest(seeAllData=true)
	static void getZuoraSubscriptionCancellationWrapperListTest(){

		String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

		Test.startTest();
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters      = invoicePaymentParams;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testTaxationItemInvoiceItemId = CANCEL_INVOICE_ID;
        Z_TestFactory.testPaymentId                 = PAYMENT_ID;  

        ZuoraSubscriptionCancellationWrapper controller = new ZuoraSubscriptionCancellationWrapper();
        System.assertEquals(1, controller.getZuoraSubscriptionCancellationWrapperList(
        	ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, CANCEL_INVOICE_ID, Constants.ZUORA_TEST_STRING).size());
        Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : getZuoraSubscriptionCancellationWrapperListRefundDiscountTest
  	Author       : Mantas Grigaliunas
  	Created Date : 29/03/2017
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest(seeAllData=true)
	static void getZuoraSubscriptionCancellationWrapperListRefundDiscountTest(){

		String INVOICE_AMOUNT = '10';

		Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            INVOICE_ID => new List<String>{INVOICE_ID, INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            'InvoiceItem1'        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '4', '1'},
            'InvoiceItem2'        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            PAYMENT_ID       => new List<String>{'10', PAYMENT_ID, INVOICE_ID}
        };

		Test.startTest();
        Z_TestFactory.invoiceParameters        = invoiceParams;
        Z_TestFactory.invoiceItemParameters    = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters = invoicePaymentParams;
        Z_TestFactory.testAmendmentInvoiceId   = INVOICE_ID;
        Z_TestFactory.testAmendmentAmount      = Decimal.valueOf(INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount        = Decimal.valueOf(INVOICE_AMOUNT);
        Z_TestFactory.testPaymentId            = PAYMENT_ID;  

        ZuoraSubscriptionCancellationWrapper controller = new ZuoraSubscriptionCancellationWrapper();
        System.assertEquals(0, controller.getZuoraSubscriptionCancellationWrapperList(
        	ZuoraUtilities.zuoraApiAccess(), Constants.ZUORA_TEST_STRING, INVOICE_ID, Constants.ZUORA_TEST_STRING).size());
        Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : getZuoraSubscriptionCancellationWrapperListTest
  	Author       : Mantas Grigaliunas
  	Created Date : 29/03/2017
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest(seeAllData=true)
	static void getZuoraSubscriptionCancellationWrapperListMultiplePaymentsTest(){

		String CANCEL_INVOICE_AMOUNT = '-10';

        Map<String, List<String>> invoiceParams = new Map<String, List<String>>{
            CANCEL_INVOICE_ID => new List<String>{CANCEL_INVOICE_ID, CANCEL_INVOICE_AMOUNT}
        };

        Map<String, List<String>> invoiceItemParams = new Map<String, List<String>>{
            INVOICE_ID        => new List<String>{SUBSCRIPTION_ID, INVOICE_ID, '8', '2'},
            CANCEL_INVOICE_ID => new List<String>{SUBSCRIPTION_ID, CANCEL_INVOICE_ID, '-8', '-2'}
        };

        Map<String, List<String>> invoicePaymentParams = new Map<String, List<String>>{
            'Payment1'        => new List<String>{'5', Constants.ZUORA_TEST_STRING, INVOICE_ID},
            'Payment2' 		  => new List<String>{'5', Constants.ZUORA_TEST_STRING, INVOICE_ID}
        };

		Test.startTest();
        Z_TestFactory.invoiceParameters             = invoiceParams;
        Z_TestFactory.invoiceItemParameters         = invoiceItemParams;
        Z_TestFactory.invoicePaymentParameters  	= invoicePaymentParams;
        Z_TestFactory.testAmendmentInvoiceId        = CANCEL_INVOICE_ID;
        Z_TestFactory.testAmendmentAmount           = Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testPaymentAmount             = -Decimal.valueOf(CANCEL_INVOICE_AMOUNT);
        Z_TestFactory.testTaxationItemInvoiceItemId = CANCEL_INVOICE_ID;

        ZuoraSubscriptionCancellationWrapper controller = new ZuoraSubscriptionCancellationWrapper();
        System.assertEquals(2, controller.getZuoraSubscriptionCancellationWrapperList(
        	ZuoraUtilities.zuoraApiAccess(), SUBSCRIPTION_ID, CANCEL_INVOICE_ID, Constants.ZUORA_TEST_STRING).size());
        Test.stopTest();
	}
}