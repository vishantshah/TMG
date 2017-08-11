/**
* @author Cristina Anghenie
* @date Unknown
* @description Test class for CreditCardExpiryDateUpdateBatch
#############Change Log#############
Modified by         Version     Change Date
Pawel Chrzanowski   1.1         31/05/2016  //added coverage
**/
@isTest
private class CreditCardExpiryDateUpdateBatchTest {
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 26/10/2015
    Version - 1.0
    Function - method that checks if credit card expiry date get updated when changed for digital acc
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCCExpiryDateDigital() {
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createDigitalSubscribers();
        for(Account acc : tdu.lstDigitalSubscribers){
        	acc.Subscriber_Digital_Status__c = 'Active';
        	acc.Credit_Card_Expiry_Date__c = system.today().addDays(5);
        }
        update tdu.lstDigitalSubscribers;
        Account[] digitalAccs = [SELECT Id, Subscriber_Number_Static__c, Credit_Card_Expiry_Date__c FROM Account WHERE Id IN: tdu.lstDigitalSubscribers];
        insert TestDataUtility.newMPPTransactionHistory(1, tdu.lstDigitalSubscribers[0].Id, null, 'CreditDebitCard');
        insert TestDataUtility.newMPPTransactionHistory(1, tdu.lstDigitalSubscribers[1].Id, null, 'CreditDebitCard');
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISLIST => 'isList',
                MPPWebserviceMocks.PARAM_TS1 => digitalAccs[0].Subscriber_Number_Static__c,
                MPPWebserviceMocks.PARAM_TS2 => digitalAccs[1].Subscriber_Number_Static__c
            });
            Test.setMock(HttpCalloutMock.class, mock); 
	        CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
	        Database.executeBatch(batchCls);
	    Test.stopTest();
	    digitalAccs = [SELECT Id, Subscriber_Number_Static__c, Credit_Card_Expiry_Date__c FROM Account WHERE Id IN: tdu.lstDigitalSubscribers];
	    System.assertEquals(Date.newInstance(2019,09,30),digitalAccs[0].Credit_Card_Expiry_Date__c);
	    System.assertEquals(Date.newInstance(2018,09,30),digitalAccs[1].Credit_Card_Expiry_Date__c);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 26/10/2015
    Version - 1.0
    Function - method that checks if credit card expiry date get updated when changed for print acc
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCCExpiryDatePrint() {
        TestDataUtility tdu = new TestDataUtility(5);
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createMPPTransactionHistory('CreditDebitCard');
        for (Integer i = 1; i<=5; i++){
        	tdu.lstIndividualSubscribers[i-1].Credit_Card_Expiry_Date__c = system.today().addDays(i*15);
        }
        update tdu.lstIndividualSubscribers;
        //update only the first 2 records
        for(Subscription__c sub : tdu.lstSubscriptions){
            Integer i = 0;
            sub.Payment_Type__c = 'Credit Card';
            sub.isContinuous__c = true;
            i++;
            if(i>1) break;
        }
        
        update tdu.lstSubscriptions;
        
        Account[] printAccs = [SELECT Id, Subscriber_Number_Static__c, Credit_Card_Expiry_Date__c FROM Account WHERE Id IN: tdu.lstIndividualSubscribers];
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISLIST => 'isList',
                MPPWebserviceMocks.PARAM_TS1 => printAccs[0].Subscriber_Number_Static__c,
                MPPWebserviceMocks.PARAM_TS2 => printAccs[1].Subscriber_Number_Static__c
            });
            Test.setMock(HttpCalloutMock.class, mock); 
            CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
            Database.executeBatch(batchCls);
        Test.stopTest();
        printAccs = [SELECT Id, Subscriber_Number_Static__c, Credit_Card_Expiry_Date__c FROM Account WHERE Id IN: tdu.lstIndividualSubscribers];
        System.assertEquals(Date.newInstance(2019,09,30),printAccs[0].Credit_Card_Expiry_Date__c);
        System.assertEquals(Date.newInstance(2018,09,30),printAccs[1].Credit_Card_Expiry_Date__c);
        System.assertEquals(System.today().addDays(45),printAccs[2].Credit_Card_Expiry_Date__c);
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 31/05/2016
    Function - method that checks batch for Registrants
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCCExpiryDateRegistrant(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createRegistrants();
        tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
        tdu.lstZuoraPaymentMethods[0].Zuora__CreditCardExpirationMonth__c = '12';
        tdu.lstZuoraPaymentMethods[0].Zuora__CreditCardExpirationYear__c = '2018';
        update tdu.lstZuoraPaymentMethods[0];

        tdu.lstRegistrants[0].Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        update tdu.lstRegistrants[0];

        Test.startTest();
            CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
            Database.executeBatch(batchCls);
        Test.stopTest();

        Integer noOfDays = date.daysInMonth(2018, 12);
        Account acc = [select Credit_Card_Expiry_Date__c from Account limit 1];
        System.assertEquals(Date.newInstance(2018,12,noOfDays), acc.Credit_Card_Expiry_Date__c);
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 31/05/2016
    Function - method that checks batch for Registrants - negative scenarios
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCCExpiryDateRegistrant_Negative(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createRegistrants();
        tdu.lstRegistrants[0].Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        update tdu.lstRegistrants[0];

        //no Billing Account
        CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
        Database.executeBatch(batchCls);
        Account acc = [select Credit_Card_Expiry_Date__c from Account limit 1];
        System.assertEquals(null, acc.Credit_Card_Expiry_Date__c);

        //incomplete Payment Method
        tdu.createBillingAccountToRegistrant(tdu.lstRegistrants[0].Id, Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
        Database.executeBatch(batchCls);
        acc = [select Credit_Card_Expiry_Date__c from Account limit 1];
        System.assertEquals(null, acc.Credit_Card_Expiry_Date__c);
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 31/05/2016
    Function - method that checks batch - negative scenarios
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCCExpiryDateDigital_Negative(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.createAccount();

        tdu.lstAccounts[0].Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        update tdu.lstAccounts[0];

        Test.startTest();
            CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
            Database.executeBatch(batchCls);
        Test.stopTest();

        Account acc = [select Credit_Card_Expiry_Date__c from Account limit 1];
        System.assertEquals(null, acc.Credit_Card_Expiry_Date__c);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 17/11/2015
    Version - 1.0
    Function - test batch without custom settings 
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void testCreditCardExpiryDateSchedulerWithoutCS(){
        Test.startTest();
            try{
                CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
            }catch (TelegraphApplicationException ex){
                System.assert(ex.getMessage().contains(Label.NoOfDay_CC_Expiry_Date));
            }
        Test.stopTest();
    }
}