/**
* @author Unknown
* @date Unknown
* @description Test class for SubscriptionsWebservices
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         16/07/2015  //modified testprocessPaymentScheduleSetupSuccess()
Cristina Anghenie1.2        11/08/2015  //clean up the test class and increase code coverage
Wiktor Czykin   1.3         14/12/2015  //added missing coverage for GetMPPCreateSession()
Pawel Chrzanowski 1.4       02/03/2016  //disabled testDigitalSubscriptionEnded()
Michal Szewczyk 1.5         04/04/2016  //removed GetMPPCreateSession() test methods
Wiktor Czykin   1.6         26/05/2016  //added loadSAMHTTPSettings to data creation methods
Michal Szewczyk 1.7         03/06/2016  //added testCreateSubscriber_Digital
Michal Szewczyk 1.8         19/10/2016  //modified testCreateTransactionAndUpsertSAMAccountv2()
Wiktor Czykin   1.9         21/03/2017  //removed references to removed methods
**/
@isTest(SeeAllData=false)
private class SubscriptionsWebservicesTest {
    
     /** A series of tests to prove that the webservice calls into the business logic correctly and returns the expected error codes **/
    private static final Map<String,String> subscriberTypes = new Map<String,String>{'digital' => 'Digital Subscriber', 'premium' => 'Individual Subscriber'};
    
    private static SubscriptionsWebservices.Subscriber subscriberDetails;
    private static SubscriptionsWebservices.Subscription subscriptionDetails;
    private static SubscriptionsWebservices.Payment paymentDetails;
    private static SubscriptionsWebservices.MPPRecurringInfo recurringDetails;
    private static List<SubscriptionsWebservices.CustomParameter> contexParams;
    
    private static decimal vatRateGB = 0.2;
    private static decimal vatRateEU = 0.1;
    private static TestDataUtility td = new TestDataUtility(1);

    private static void setupDigitalData(){
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.loadCountryCodes();
        td.loadVAT();
        
        subscriberDetails = new SubscriptionsWebservices.Subscriber( );
        subscriberDetails.guid = 'GUIDTestMethodData ' + Math.random();
        subscriberDetails.subscriberType = 'digital';
        subscriberDetails.digitalSubscriberStatus = 'Active';
        subscriberDetails.firstName = 'Testio';
        subscriberDetails.lastName = 'Testev';
        subscriberDetails.personalEmail = 'testio@test.com';
        subscriberDetails.street = 'Cannon Street';
        subscriberDetails.city = 'Reading';
        subscriberDetails.postalCode = 'GIR0aa';
        subscriberDetails.country = 'GB';
        subscriberDetails.homePhone = '01603554887';
        subscriberDetails.mobilePhone = '077777777777';
        subscriberDetails.marketingEmailPref = true;    
        subscriberDetails.TCode = '005T';

        paymentDetails = new SubscriptionsWebservices.Payment( );
        paymentDetails.paymentDate = System.now().date();
        paymentDetails.amountGross = 4.8;
        paymentDetails.currencyType = 'GBP';
        paymentDetails.paymentStatus = 'success';
        paymentDetails.paymentType = 'DirectDebit';
        paymentDetails.productName = 'tomatoes';
        paymentDetails.digitalSubscriptionID = 'my Digital Subscription';
        paymentDetails.OrderId = '123';
        paymentDetails.ServiceId = '12';
        
        recurringDetails = new SubscriptionsWebservices.MPPRecurringInfo();
        recurringDetails.paymentType = paymentDetails.paymentType;
        recurringDetails.firstPaymentAmount = 200.00;
        recurringDetails.nextPaymentDate = Date.today().addDays(120);
        recurringDetails.frequency = '15';
        recurringDetails.premiumSubscriptionID = '100101';
        
        paymentDetails.recurringDetails = recurringDetails;
        
        subscriptionDetails = new SubscriptionsWebservices.Subscription();
        subscriptionDetails.productType = 'digital';
        subscriptionDetails.startDate = date.today().addDays(21).toStartOfWeek();
        subscriptionDetails.subscriptionType = 'Continuous';
        subscriptionDetails.paymentDate=date.today().adddays(21);
    }

    private static void setupPremiumData(){
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.loadCountryCodes();
        td.loadVAT();
        td.createTCodeManagement();
        
        subscriberDetails = new SubscriptionsWebservices.Subscriber( );
        subscriberDetails.guid = 'GUIDTestMethodData' + Math.random();
        subscriberDetails.subscriberType = 'premium';
        subscriberDetails.firstName = 'Testio';
        subscriberDetails.lastName = 'TestevPrem';
        subscriberDetails.personalEmail = DateTime.now().getTime() + 'testiop@test.com';
        subscriberDetails.street = 'Cannon Street';
        subscriberDetails.city = 'Reading';
        subscriberDetails.postalCode = 'GIR0aa';
        subscriberDetails.country = 'GB';
        subscriberDetails.homePhone = '01603554887';
        subscriberDetails.mobilePhone = '077777777777';
        subscriberDetails.marketingEmailPref = true;
        subscriberDetails.TCode = td.lstTCodeManagement[0].Name;   

        subscriptionDetails = new SubscriptionsWebservices.Subscription();
        subscriptionDetails.productType = 'premium';
        subscriptionDetails.subscriptionType = 'Continuous';
        subscriptionDetails.startDate = date.today().adddays(21).toStartOfWeek();
        subscriptionDetails.paymentDate=date.today().adddays(21);

        paymentDetails = new SubscriptionsWebservices.Payment( );
        paymentDetails.paymentDate = System.now();
        paymentDetails.amountGross = 4.8;
        paymentDetails.currencyType = 'GBP';
        paymentDetails.paymentStatus = 'success';
        paymentDetails.paymentType = 'CreditDebitCard';
        paymentDetails.productName = 'Premium';
        paymentDetails.serviceId = '123';
        paymentDetails.orderId = '123';
        
        recurringDetails = new SubscriptionsWebservices.MPPRecurringInfo();
        recurringDetails.paymentType = paymentDetails.paymentType;
        recurringDetails.firstPaymentAmount = 200.00;
        recurringDetails.nextPaymentDate = Date.today().addDays(120);
        recurringDetails.frequency = '15';
        recurringDetails.premiumSubscriptionID = '123301';
        
        paymentDetails.recurringDetails = recurringDetails;
    }
    

    private static void setupProductData(){

            td.createTCodeProducts();
            td.createPOCs(1);
            td.lstPOCs[0].Product__c = td.lstZproducts[0].Id;
            update td.lstPOCs;
            td.createIncentives();
            
            td.createPricingOptions('Digital');
            List<Pricing_Options__c> prOpt = td.mapPricingOptions.get(0);
            prOpt[0].TCode_Product__c = td.lstTCodeProducts[0].Id;
            update prOpt;

            contexParams = new List<SubscriptionsWebservices.CustomParameter>();
            SubscriptionsWebservices.CustomParameter prodId = new SubscriptionsWebservices.CustomParameter();
            prodId.name = 'productId';
            prodId.value = '' + td.lstZproducts[0].Id;
            contexParams.add(prodId);

            td.setDefautProdCustomSetting();
    }

     /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCreateSubscriberAndTransaction_Success()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testCreateSubscriberAndTransaction_Success() {
        setupDigitalData();
        setupProductData();
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        Test.stopTest();
        
        System.assertEquals(null, r.wsError);
        System.assertEquals(true, String.isNotBlank(r.TSNumber));
        
        List<Account> accs = [Select Id From Account Where Subscriber_Number_static__c = :r.TSNumber];
        System.assertEquals(1, accs.size());
        
        List<MPP_Transaction_History__c> hist = [Select Id From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r.TSNumber];
        System.assertEquals(1, hist.size());
    }
    
     /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCreateSubscriberAndTransaction_DuplicateGuid()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    ****************************************************************************************/
    static testMethod void testCreateSubscriberAndTransaction_DuplicateGuid() {
        setupDigitalData();
        setupProductData();

        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        
            System.assertEquals(null, r.wsError);
            System.assertEquals(true, String.isNotBlank(r.TSNumber));

            r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, null, paymentDetails, null, null, null,contexParams);
            
            System.assertNotEquals(null, r.wsError);
            System.assertEquals('2',r.wsError.errorCode);
            System.assert(r.wsError.errorMessage.contains('GUID already associated with an Account.'));
        Test.stopTest();
    }
    
     /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testUpdateSubscriberAndCreateTransactionDigital()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testUpdateSubscriberAndCreateTransactionDigital() {
        setupDigitalData();
        setupProductData();
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
    
            subscriberDetails.TSNumber = r.TSNumber;    
            subscriberDetails.personalEmail = 'alt@t.co.uk';    
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r2 = SubscriptionsWebservices.UpdateSubscriberAndCreateTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        Test.stopTest();
        System.assertEquals(null, r.wsError);
        
        List<Account> accs = [Select Id, PersonEmail From Account Where Subscriber_Number_static__c = :r.TSNumber];     
        System.assertEquals(1, accs.size());
        System.assertEquals(accs[0].PersonEmail, subscriberDetails.personalEmail);
        
        List<MPP_Transaction_History__c> hist = [Select Id From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r.TSNumber];
        System.assertEquals(2, hist.size());
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testUpdateSubscriberAndCreateTransactionPremium()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testUpdateSubscriberAndCreateTransactionPremium() {
        setupPremiumData();
        setupProductData();
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
    
            subscriberDetails.TSNumber = r.TSNumber;    
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r2 = SubscriptionsWebservices.UpdateSubscriberAndCreateTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        Test.stopTest();
        System.assertEquals(null, r.wsError);
        
        List<Account> accs = [Select Id, PersonEmail From Account Where Subscriber_Number_static__c = :r.TSNumber];     
        System.assertEquals(1, accs.size());
        
        List<MPP_Transaction_History__c> hist = [Select Id From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r.TSNumber];
        System.assertEquals(1, hist.size());
    }
    
     /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCreateSubscriber()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testCreateSubscriber(){
        setupPremiumData();
        setupProductData();
        td.lstZproducts[0].Print_Product__c = true;
        update td.lstZproducts;
        subscriptionDetails.paymentDate = Date.newInstance(2015, 8, 21);
        subscriberDetails.TCode = 't0';
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, td.lstIncentives[0].Id, null,contexParams);
        Test.stopTest();
        System.assertEquals(null, r.wsError);
        List<Account> accs = [SELECT Id,MPP_CurrentPayScheduleEndDate__c, PersonEmail,Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_static__c = :r.TSNumber];     
        System.assertEquals(Date.newInstance(2015, 9, 01).addMonths(12),accs[0].MPP_CurrentPayScheduleEndDate__c);
        System.assertEquals(1, accs.size());
        List<Subscription__c> subs = [SELECT Id FROM Subscription__c WHERE Subscriber__c =: accs[0].Id];
        System.assertEquals(1, subs.size());
        
        List<SubscriptionIncentiveAssociation__c> sias = [SELECT Id FROM SubscriptionIncentiveAssociation__c WHERE Subscriber__c =: accs[0].Id AND Subscription__c =: subs[0].Id AND Incentive__c =: td.lstIncentives[0].Id]; 
        System.assertEquals(1, sias.size());
    }
   /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCreateSubscriber for Digital()
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/
    static testMethod void testCreateSubscriber_Digital(){
        
        setupDigitalData();
        setupProductData();
        td.lstZproducts[0].Print_Product__c = false;
        update td.lstZproducts;
        subscriptionDetails.paymentDate = Date.newInstance(2015, 8, 21);
        
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, null, null,null);
        Test.stopTest();
        System.assertEquals(null, r.wsError);
        List<Account> accs = [SELECT Id,MPP_CurrentPayScheduleEndDate__c, PersonEmail,Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_static__c = :r.TSNumber];     
        System.assertEquals(1, accs.size());
        System.assertEquals('Active', accs[0].Subscriber_Digital_Status__c);
        List<Subscription__c> subs = [SELECT Id FROM Subscription__c WHERE Subscriber__c =: accs[0].Id];
        System.assertEquals(0, subs.size());
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCreateSubscriber_NoSubscription()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testCreateSubscriber_NoSubscription(){
        setupPremiumData();
        setupProductData();
        subscriptionDetails.paymentDate = Date.newInstance(2015, 8, 21);
        
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, null, paymentDetails.recurringDetails, null, null, null,contexParams);
        Test.stopTest();
        System.assertEquals(null, r.wsError);
        List<Account> accs = [SELECT Id,MPP_CurrentPayScheduleEndDate__c, PersonEmail FROM Account WHERE Subscriber_Number_static__c = :r.TSNumber];     
        System.assertEquals(1, accs.size());
        
        List<Subscription__c> subs = [SELECT Id FROM Subscription__c WHERE Subscriber__c =: accs[0].Id];
        System.assertEquals(0, subs.size());
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testAllNegativeScenario()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testAllNegativeScenario(){
        setupPremiumData();
        setupProductData();
        Test.startTest();
            //subscriber doesnt exist
            SubscriptionsWebservices.CreateSubscriberResult r1 = SubscriptionsWebservices.CreateSubscriber(null, null, paymentDetails.recurringDetails, null, null, null,contexParams);
            System.assertNotEquals(null, r1.wsError);
            System.assertEquals('5',r1.wsError.errorCode);
            System.assert(r1.wsError.errorMessage.contains('Paramater: subscriberDetails cannot be null.'));
            //Invalid TSNumber
            subscriberDetails.TSNumber = 'INVALID TSNUMBER';
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r2 = SubscriptionsWebservices.UpdateSubscriberAndCreateTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
            System.assertNotEquals(null, r2.wsError);
            System.assertEquals('3',r2.wsError.errorCode);
            System.assert(r2.wsError.errorMessage.contains('Unknown TSNumber'));
            //Invalid PostCode
            subscriberDetails.TSNumber = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams).TSNumber;
            subscriberDetails.postalCode = 'INVALID POSTCODE FORMAT';
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r3 = SubscriptionsWebservices.UpdateSubscriberAndCreateTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
            System.assertEquals('4',r3.wsError.errorCode);
            System.assert(r3.wsError.errorMessage.toLowerCase().contains('personmailingpostalcode'));
            //Invalid payment type
            paymentDetails.paymentType = 'INVALID PAYMENT TYPE';
            //SubscriptionsWebservices.CreateSubscriberAndTransactionResult r3 = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,null);
            r2 = SubscriptionsWebservices.CreateTransaction(subscriberDetails.TSNumber, paymentDetails, null);
            System.assertNotEquals('', r2.wsError.errorCode);
            System.assert(r2.wsError.errorMessage.toLowerCase().contains('paymenttype'));
        Test.stopTest();    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testUpdateDigitalSubscriber_InvalidField()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testUpdateDigitalSubscriber_InvalidField() {
        setupDigitalData();
        setupProductData();

        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        
        subscriberDetails.TSNumber = r.TSNumber;
        subscriberDetails.digitalSubscriberStatus = 'INVALID DIGITAL STATUS';
        Test.startTest();        
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r1 = SubscriptionsWebservices.UpdateSubscriber(subscriberDetails, null,null);
            System.assertNotEquals(null, r1.wsError);
            System.assert(r1.wsError.errorMessage.toLowerCase().contains('digitalsubscriberstatus'));
            //invalid ts number
            SubscriptionsWebservices.CheckDigitalSubscriberStatusResult cr = SubscriptionsWebservices.CheckDigitalSubscriberStatus('kjahskjhf');
        Test.stopTest();   
        System.assertNotEquals(null, cr.wsError);
        System.assert(cr.wsError.errorMessage.toLowerCase().contains('unknown tsnumber'));
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCheckDigitalSubscriberStatus_Success()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    Wiktor Czykin       1.3         26/05/2016  //changed products to non-print
    ****************************************************************************************/
    static testMethod void testCheckDigitalSubscriberStatus_Success() {
        setupDigitalData();
        setupProductData();

        List<zqu__ZProduct__c> lstProducts = [select Id from zqu__ZProduct__c];
        for(zqu__ZProduct__c zp : lstProducts){
            zp.Print_Product__c = false;
        }
        update lstProducts;

        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
            SubscriptionsWebservices.CheckDigitalSubscriberStatusResult cr = SubscriptionsWebservices.CheckDigitalSubscriberStatus(r.TSNumber);
        Test.stopTest();
        System.assertNotEquals(null,cr);
        System.assertEquals(null, cr.wsError);
        System.assertEquals(subscriberDetails.digitalSubscriberStatus, cr.digitalSubscriberStatus);
    }   
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testCreateTransactionAndUpsertSAMAccountv2()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    Michal Szewczyk     1.3         18/10/2016  //added PaymentReason
    ****************************************************************************************/
    static testMethod void testCreateTransactionAndUpsertSAMAccountv2(){
        setupPremiumData();
        setupProductData();
        Test.startTest();     
            List<SubscriptionsWebservices.CustomParameter> cpArray = new List<SubscriptionsWebservices.CustomParameter>();
            SubscriptionsWebservices.CreateSubscriberResult r1 = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, null, null,contexParams);
            SubscriptionsWebservices.CustomParameter cp1 = new SubscriptionsWebservices.CustomParameter();
            cp1.name = 'test';
            cp1.value = 'test';
            cpArray.add(cp1);
            SubscriptionsWebservices.CustomParameter cp3 = new SubscriptionsWebservices.CustomParameter();
            cp3.name = 'PaymentReason';
            cp3.value = 'Other';
            cpArray.add(cp3);
            paymentDetails.productName= 'oneoffpayment';
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r2 = SubscriptionsWebservices.CreateTransactionAndUpsertSAMAccountv2(r1.TSNumber, null, null, td.lstIncentives[0].Id, paymentDetails, null, cpArray);
            System.assertNotEquals(null,r2);
            
            Subscription__c sub = [SELECT Id FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_static__c =: r1.TSNumber];
            SubscriptionsWebservices.CustomParameter cp2 = new SubscriptionsWebservices.CustomParameter();
            cp2.name = 'SubscriptionId';
            cp2.value = sub.Id;
            cpArray.add(cp2);
            paymentDetails.paymentType = 'DirectDebit';
            r2 = SubscriptionsWebservices.CreateTransactionAndUpsertSAMAccountv2(r1.TSNumber, null, null, td.lstIncentives[0].Id, paymentDetails, null, cpArray);
        Test.stopTest();      
        System.assertNotEquals(null,r2);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testGetTCodeAndIncentivesPositive()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testGetTCodeAndIncentivesPositive(){
        setupDigitalData();
        setupProductData();
        Test.startTest();     
            SubscriptionsWebservices.GetTCodeAndIncentivesResult r = SubscriptionsWebservices.GetTCodeAndIncentives('digital', null, '', null, '12345678','');
            System.assertNotEquals(null,r);
            
            td.lstTCodeManagement[0].Type__c = 'Open Offer';
            update td.lstTCodeManagement;

            r = SubscriptionsWebservices.GetTCodeAndIncentives(td.lstZproducts[0].Id, 'openofferflow', td.lstTCodeManagement[0].Name, 'Monthly', '12345678','');
            System.assertEquals(null,r.wsError);
        Test.stopTest();    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testGetTCodeAndIncentivesNegative()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testGetTCodeAndIncentivesNegative(){
        setupDigitalData();
        setupProductData();
        Test.startTest();     
            SubscriptionsWebservices.GetTCodeAndIncentivesResult r = SubscriptionsWebservices.GetTCodeAndIncentives(null, 'openofferflow', td.lstTCodeManagement[0].Name, 'Monthly', '12345678','');
            System.assertNotEquals(null,r.wsError);
            System.assert(r.wsError.errorMessage.contains('productId cannot be null')); 
            
            r = SubscriptionsWebservices.GetTCodeAndIncentives('digital', 'openofferflow', null, 'Monthly', '12345678','');
            System.assertNotEquals(null,r.wsError);
            
            td.lstTCodeManagement[0].Type__c = 'Open Offer';
            update td.lstTCodeManagement;
            td.createPricingOptions('Digital');
            r = SubscriptionsWebservices.GetTCodeAndIncentives(td.lstZproducts[0].Id, 'openofferflow', td.lstTCodeManagement[0].Name, 'Monthly', '12345678','');
            System.assertEquals(null,r.wsError);
        Test.stopTest();    
    }
    
     /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDDSetupFailure()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testGetTCodeAndIncentivesByPromoName(){
        setupDigitalData();
        setupProductData();
        Test.startTest();     
            SubscriptionsWebservices.GetTCodeAndIncentivesResult r = SubscriptionsWebservices.GetTcodeIncentivesByPromoName('12345','2314','test promo');
            System.assertNotEquals(null,r);
            
            r = SubscriptionsWebservices.GetTcodeIncentivesByPromoName('2','1001',null);
            System.assertEquals('NOPRICINGOPTION',r.wsError.errorCode);
            
            Pricing_Options__c po = [SELECT Package_Name__c,ServiceId__c, ServicePriceId__c FROM Pricing_Options__c WHERE TCodeManagement__c =: td.lstTCodeManagement[0].Id];
            System.assertEquals(null,po.Package_Name__c);
            System.assertEquals(1,po.ServiceId__c);
            System.assertEquals(1000,po.ServicePriceId__c);
            po.Package_Name__c = 'Test';
            update po; 
            r = SubscriptionsWebservices.GetTcodeIncentivesByPromoName('1','1000','Test');
            System.assertEquals(null,r.wsError);
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDDSetupFailure()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         10/08/2015  //update method to increase code coverage
    ****************************************************************************************/
    static testMethod void testGetRenewalOffer(){
        td = new TestDataUtility(1);
        td.createSubscriptions();
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        
        Account acc = [SELECT Id, Subscriber_Number_static__c FROM Account WHERE Id=: td.lstIndividualSubscribers[0].Id];
            
        Subscription__c subs = [SELECT Id FROM Subscription__c WHERE Subscriber__c =: td.lstIndividualSubscribers[0].Id];
        subs.Subscription_Status__c = 'Lapsed';
        update subs;
        
        Subscription__c subOffered = TestDataUtility.newSubscripiton(1, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, Date.newInstance(2015, 8, 15));
        subOffered.Subscription_Status__c = 'Offered';
        subOffered.Previous_Subscription__c = subs.Id;
        subOffered.isContinuous__c = true;
        subOffered.Payment_Type__c = 'Direct Debit';
        insert subOffered;
        
        Test.startTest();
            SubscriptionsWebservices.RenewalOffer r = SubscriptionsWebservices.GetRenewalOffer(acc.Subscriber_Number_static__c, 'EC1A 9HP');
        Test.stopTest();
        System.assertEquals(null, r.wsError);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDDSetupFailure()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testValidatePOC(){
        setupDigitalData();
        setupProductData();
        String poc = td.mapTCodeManagementToPOCs.get(td.lstTCodeManagement[0].Id)[0].Id;

        Test.startTest();
            SubscriptionsWebservices.ValidatePOCResult r = SubscriptionsWebservices.ValidatePOC(null, 'invalid postcode');
            System.assertNotEquals(null, r);
            System.assertEquals(null, r.wsError);
            
            r = SubscriptionsWebservices.ValidatePOC(poc, 'E3 3EW');
            System.assertEquals(null, r.wsError);
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDDSetupFailure()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Wiktor Czykin       1.2         30/11/2015  //modified test method because of change to checkClientCustomParams() method signature
    Michal Szewczyk     1.3         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testcheckClientCustomParams(){
        setupDigitalData();
        setupProductData();
        
        List<SubscriptionsWebservices.CustomParameter> cpArray= new List<SubscriptionsWebservices.CustomParameter>();
        SubscriptionsWebservices.CustomParameter cp = new SubscriptionsWebservices.CustomParameter();
        cp.name='';
        cp.value=null;
        cpArray.add(cp);
        
        Test.startTest();  
            Map<String,String> mapParams = SubscriptionsWebservices.remapClientCustomParams(cpArray);
            SubscriptionsWebservices.Subscriber sub = SubscriptionsWebservices.checkClientCustomParams(subscriberDetails, mapParams);
            System.assertNotEquals(null, sub);
            
            SubscriptionsWebservices.CustomParameter cp1 = new SubscriptionsWebservices.CustomParameter();
            cp1.name='pricingoptionname';
            cp1.value=td.mapTCodeManagementToPOCs.get(td.lstTCodeManagement[0].Id)[0].Name;
            cpArray.add(cp1);
            mapParams = SubscriptionsWebservices.remapClientCustomParams(cpArray);
            sub = SubscriptionsWebservices.checkClientCustomParams(subscriberDetails, mapParams);
        Test.stopTest(); 
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDDSetupFailure()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    Wiktor Czykin       1.3         26/05/2016  //changed products to non-print
    ****************************************************************************************/
    static testMethod void testUpdateLastAccessedDataPositive(){
        setupDigitalData();
        setupProductData();
        List<zqu__ZProduct__c> lstProducts = [select Id from zqu__ZProduct__c];
        for(zqu__ZProduct__c zp : lstProducts){
            zp.Print_Product__c = false;
        }
        update lstProducts;
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
            //device = website
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = SubscriptionsWebservices.UpdateLastAccessedData(r.TSNumber, 'website', Date.newInstance(2015, 8, 30));
            System.assertNotEquals(null, ret);
            System.assertEquals(null, ret.wsError); 
            List<Account> accs = [SELECT Id, Website_Last_Accessed__c FROM Account WHERE Subscriber_Number_Static__c = :r.TSNumber];
            System.assertEquals(Date.newInstance(2015, 8, 30), accs[0].Website_Last_Accessed__c);
            
            //device = tablet
            ret = SubscriptionsWebservices.UpdateLastAccessedData(r.TSNumber, 'tablet', Date.newInstance(2015, 8, 30));
            System.assertNotEquals(null, ret);
            System.assertEquals(null, ret.wsError); 
            accs = [SELECT Id, Tablet_First_Accessed__c FROM Account WHERE Subscriber_Number_Static__c = :r.TSNumber];
            System.assertEquals(Date.newInstance(2015, 8, 30), accs[0].Tablet_First_Accessed__c);

            //device = mobile
            ret = SubscriptionsWebservices.UpdateLastAccessedData(r.TSNumber, 'mobile', Date.newInstance(2015, 8, 30));
        Test.stopTest();
        System.assertNotEquals(null, ret);
        System.assertEquals(null, ret.wsError); 
        accs = [SELECT Id, Mobile_First_Accessed__c FROM Account WHERE Subscriber_Number_Static__c = :r.TSNumber];
        System.assertEquals(Date.newInstance(2015, 8, 30), accs[0].Mobile_First_Accessed__c);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testUpdateLastAccessedDataNegative()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testUpdateLastAccessedDataNegative(){
        setupDigitalData();
        setupProductData();
        
        DateTime dt = Date.newInstance(2015, 8, 30);
        Test.startTest();
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = SubscriptionsWebservices.UpdateLastAccessedData(null, null, dt);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));  
            
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
            ret = SubscriptionsWebservices.UpdateLastAccessedData(r.TSNumber, null, dt);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('device cannot be null')); 
            
            ret = SubscriptionsWebservices.UpdateLastAccessedData(r.TSNumber, 'tablet', null);
        Test.stopTest();        
        System.assertEquals('5', ret.wsError.errorCode);  
        System.assert(ret.wsError.errorMessage.contains('lastAccessed cannot be null'));
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDDSetupFailure()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testDDSetupFailure(){
        setupPremiumData();
        setupProductData();
        
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
            
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = SubscriptionsWebservices.DDSetupFailure(null, null, null);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));
            
            ret = SubscriptionsWebservices.DDSetupFailure(r.TSNumber, null, null);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('FailureReason cannot be null'));
            
            ret = SubscriptionsWebservices.DDSetupFailure(r.TSNumber, 'Just failed', '1');
            System.assertEquals(null,ret.wsError);
            
            subscriberDetails.TSNumber = null;
            ret = SubscriptionsWebservices.DDSetupFailureOverLoad(subscriberDetails, 'Just failed', '1',paymentDetails);
            System.assertNotEquals(null, ret.wsError);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));
            
            Subscriberdetails.TSNumber = r.TSNumber;
            ret = SubscriptionsWebservices.DDSetupFailureOverLoad(subscriberDetails, 'Just failed', '1',paymentDetails);
        Test.stopTest();
        System.assertEquals(null,ret.wsError);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testFailedPayment()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testFailedPayment(){
        setupPremiumData();
        setupProductData();
        
        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        
        Test.startTest();
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = SubscriptionsWebservices.FailedPayment(null, paymentDetails, '1', 'no reason');
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));
            
            ret = SubscriptionsWebservices.FailedPayment(r.TSNumber, null, '1', 'no reason');
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('PaymentDetails cannot be null'));
            
            ret = SubscriptionsWebservices.FailedPayment(r.TSNumber, paymentDetails, '1', 'no reason');
            System.assertNotEquals(null, ret.wsError);
        Test.stopTest();
        MPP_Transaction_History__c mth = [SELECT Id FROM MPP_Transaction_History__c 
                                          WHERE Subscriber__r.Subscriber_Number_static__c = :r.TSNumber
                                          AND Failure_Code__c != 'no reason'];    
                                                    
        System.assertNotEquals(null,mth);    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testFailedPaymentOverLoad()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testFailedPaymentOverLoad(){
        setupPremiumData();
        setupProductData();

        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        
        Test.startTest();
            Subscriberdetails.TSNumber = null;
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = SubscriptionsWebservices.FailedPaymentOverLoad(subscriberDetails, paymentDetails, '1', 'no reason');
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));
            
            Subscriberdetails.TSNumber = r.TSNumber;
            ret = SubscriptionsWebservices.FailedPaymentOverLoad(subscriberDetails, null, '1', 'no reason');
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('PaymentDetails cannot be null'));
            
            ret = SubscriptionsWebservices.FailedPaymentOverLoad(subscriberDetails, paymentDetails, '1', 'no reason');
            System.assertNotEquals(null, ret.wsError);
        Test.stopTest();
        MPP_Transaction_History__c mth = [SELECT Id FROM MPP_Transaction_History__c 
                                          WHERE Subscriber__r.Subscriber_Number_static__c = :r.TSNumber
                                          AND Failure_Code__c != 'no reason'];    
        System.assertNotEquals(null,mth);    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testDigitalSubscriptionEnded()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Pawel Chrzanowski	1.2         03/03/2016	//disabled to reflect changes to the class
    Michal Szewczyk     1.3         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testDigitalSubscriptionEnded(){
        setupDigitalData();
        setupProductData();
        
        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        
        Test.startTest();
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret = SubscriptionsWebservices.DigitalSubscriptionEnded(null);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));
            
            ret = SubscriptionsWebservices.DigitalSubscriptionEnded(r.TSNumber);
        Test.stopTest();
        System.assertEquals(null, ret.wsError);
        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c, MPP_Digital_Payment_Id__c FROM Account WHERE Subscriber_Number_Static__c = :r.TSNumber];   
        System.assertEquals('Inactive',accs[0].Subscriber_Digital_Status__c);    
        System.assertEquals(null,accs[0].MPP_Digital_Payment_Id__c);    
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 11/08/2015
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testGetActiveSubscriptionDetails()
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testGetActiveSubscriptionDetails(){
        setupPremiumData();
        setupProductData();
    
        subscriptionDetails.paymentDate = Date.newInstance(2015, 8, 21);
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, td.lstIncentives[0].Id, null,contexParams);   
            SubscriptionsWebservices.GetActiveSubscriptionDetailsResult ret = SubscriptionsWebservices.GetActiveSubscriptionDetails(null);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null'));        
            ret = SubscriptionsWebservices.GetActiveSubscriptionDetails(r.TSNumber);
        Test.stopTest();
        System.assertEquals(null, ret.wsError);
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 11/08/2015
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testGetActiveAndRenewedSubscriptionDetails()
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testGetActiveAndRenewedSubscriptionDetails(){
        setupPremiumData();
        setupProductData();
    
        subscriptionDetails.paymentDate = Date.newInstance(2015, 8, 21);
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, td.lstIncentives[0].Id, null,contexParams);
        
            SubscriptionsWebservices.ActiveAndRenewedSubscriptionResult ret = SubscriptionsWebservices.GetActiveAndRenewedSubscriptionDetails(null,null);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('TSNumber cannot be null.'));
            
            ret = SubscriptionsWebservices.GetActiveAndRenewedSubscriptionDetails(r.TSNumber,null);
            System.assertNotEquals(null, ret);
            System.assertEquals('5', ret.wsError.errorCode);  
            System.assert(ret.wsError.errorMessage.contains('Postcode cannot be null'));
            
            ret = SubscriptionsWebservices.GetActiveAndRenewedSubscriptionDetails(r.TSNumber,'E3 3EW');
        Test.stopTest();
        System.assertEquals(null, ret.wsError);
    }
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testprocessFailedMPPUserManageRequests()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testprocessFailedMPPUserManageRequests(){
        setupPremiumData();
        setupProductData();
        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        String TsNumber = r.TSNumber;
        
        SubscriptionsWebservices.FailedUserManageResult task = new SubscriptionsWebservices.FailedUserManageResult();
        task.tsNumber = TsNumber;
        task.subject = 'Test Subject';
        task.message = 'Test Message';
        task.status = 'Test Status';
        task.firstName = 'TestFirst';
        task.lastName = 'TestLast';
        task.emailAddress = 'test@telegraph.co.uk';
        List<SubscriptionsWebservices.FailedUserManageResult> tasks = new List<SubscriptionsWebservices.FailedUserManageResult>();
        tasks.add(task);
        
        Test.startTest();    
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult res = SubscriptionsWebservices.processFailedMPPUserManageRequests(null);
            System.assertNotEquals(null, res);
            System.assertEquals('5', res.wsError.errorCode);  
            System.assert(res.wsError.errorMessage.contains('FailedUserManageResult[] cannot be null'));
            
            res = SubscriptionsWebservices.processFailedMPPUserManageRequests(tasks); 
        Test.stopTest();
        System.assert(res != null);  
        System.assertEquals(null, res.wsError);  
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testprocessFailedMPPDirectDebitRequests()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testprocessFailedMPPDirectDebitRequests(){
        setupPremiumData();
        setupProductData();
        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        String TsNumber = r.TSNumber;
        
        SubscriptionsWebservices.FailedMPPBulkResult task = new SubscriptionsWebservices.FailedMPPBulkResult();
        task.tsNumber = TsNumber;
        task.subject = 'Test Subject';
        task.message = 'Test Message';
        task.status = 'Test Status';
        List<SubscriptionsWebservices.FailedMPPBulkResult> tasks = new List<SubscriptionsWebservices.FailedMPPBulkResult>();
        tasks.add(task);
        Test.startTest();   
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult res = SubscriptionsWebservices.processFailedMPPDirectDebitRequests(null);
            System.assertNotEquals(null, res);
            System.assertEquals('5', res.wsError.errorCode);  
            System.assert(res.wsError.errorMessage.contains('FailedMPPBulkResult[] cannot be null'));
            
            res = SubscriptionsWebservices.processFailedMPPDirectDebitRequests(tasks); 
        Test.stopTest();
        System.assert(res != null);  
        System.assertEquals(null, res.wsError);    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#testprocessFailedMPPPaymentScheduleRequests()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Michal Szewczyk     1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testprocessFailedMPPPaymentScheduleRequests(){
        setupPremiumData();
        setupProductData();
        SubscriptionsWebservices.CreateSubscriberAndTransactionResult r = SubscriptionsWebservices.CreateSubscriberAndTransaction(subscriberDetails, subscriptionDetails, paymentDetails, null, null, null,contexParams);
        String TsNumber = r.TSNumber;
        SubscriptionsWebservices.FailedMPPBulkResult task = new SubscriptionsWebservices.FailedMPPBulkResult();

        task.tsNumber = TsNumber;
        task.subject = 'Test Subject';
        task.message = 'Test Message';
        task.status = 'Test Status';
        List<SubscriptionsWebservices.FailedMPPBulkResult> tasks = new List<SubscriptionsWebservices.FailedMPPBulkResult>();
        tasks.add(task);
        Test.startTest();  
            SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult res = SubscriptionsWebservices.processFailedMPPPaymentScheduleRequests(null); 
            System.assertNotEquals(null, res);
            
            res = SubscriptionsWebservices.processFailedMPPPaymentScheduleRequests(tasks); 
        Test.stopTest();
        System.assert(res != null);  
        System.assertEquals(null, res.wsError);    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test method for SubscriptionsWebservices#processPaymentScheduleSetupSuccess()
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         16/07/2015  //removed cancellation fields from subscription initialization as was throwing exception
    Michal Szewczyk 1.2         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    private static testMethod void testprocessPaymentScheduleSetupSuccess() {
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        Test.startTest();
        
        Account account = new Account(
                                    PersonTitle = 'MR',
                                    FirstName = 'TMG First',
                                    LastName = 'TMG Last',
                                    IsUsingMPP__c = false,
                                    PersonEmail = 'tmgtesting@test.com',
                                    PersonMailingStreet= '8 Forest Drive East',
                                    PersonMailingCity = 'London',
                                    PersonMailingState = 'Walthamstow',
                                    PersonMailingPostalCode = 'E11 1JY',
                                    Guid__c='123456abcdefg', 
                                    Subscriber_Number_static__c = 'TS12345');
        insert account;
        
        Subscription__c sub = new Subscription__c(
                                    Subscriber__c = account.Id,
                                    Subscription_Status__c = 'Offered',
                                    MppDDCalloutStage__c = 'PaymentSchedule',
                                    Is_MPP_DDCCA_Letter_Extracted__c = false,
                                    Start_Date__c = Date.today().addDays(-1),
                                    Current_Week_Position_Final__c = 0,
                                    Payment_Details_Received__c = true,
                                    Weekly_Price__c = 6.50,
                                    Payment_Type__c = 'Direct Debit',
                                    isContinuous__c = true,
                                    Delivery_Type__c = 'OTC',
                                    Voucher_Pack_Duration__c = 5);
        insert sub;     
        
        System.assert(account.MPP_CurrentPayScheduleEndDate__c == null);
        System.assert(sub.MPP_Pay_Schedule_Start_Date__c == null);
        
        SubscriptionsWebservices.PaymentSchedules pymntSchdls = new SubscriptionsWebservices.PaymentSchedules();
        pymntSchdls.TSNumber = 'TS12345';
        pymntSchdls.endDatePaymentSchedule = Datetime.now();
        pymntSchdls.endDateRnwlPaymentSchedule = Datetime.now().addDays(10);
        pymntSchdls.paymentDate = Datetime.now().addDays(-10);
        pymntSchdls.startDate = Datetime.now();
        pymntSchdls.totalAmount=264.00;
        List<SubscriptionsWebservices.PaymentSchedules> recordList = new List<SubscriptionsWebservices.PaymentSchedules>();
        recordList.add(pymntSchdls);
        
        SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult r = SubscriptionsWebservices.processPaymentScheduleSetupSuccess(null);
        System.assertNotEquals(null, r.wsError);
        
        SubscriptionsWebservices.processPaymentScheduleSetupSuccess(recordList);
        
        Account subscriber = [select Id, MPP_CurrentPayScheduleEndDate__c, 
                                         MPP_Renewal_Pay_Schedule_Start_Date__c, MPP_Renewal_Pay_Schedule_End_Date__c
                                  from Account 
                                  where Subscriber_Number_static__c = 'TS12345' limit 1];
        
        Subscription__c subs = [select Id, MPP_Pay_Schedule_Start_Date__c, MPP_Pay_Schedule_End_Date__c
                                  from Subscription__c 
                                  where Subscriber__r.Subscriber_Number_static__c = 'TS12345' limit 1];
        
        System.assert(subs.MPP_Pay_Schedule_Start_Date__c != null);
        
        Test.stopTest();    
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - Test method for SubscriptionsWebservices#testGetLapsedSubscriptionDetails()
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/08/2015  //update method to increase code coverage
    Wiktor Czykin       1.2         13/10/2015  //made cancellation date dynamic based on start date
    ****************************************************************************************/
    static testMethod void testGetLapsedSubscriptionDetails(){
        setupPremiumData();
        setupProductData();
    
        subscriptionDetails.paymentDate = Date.newInstance(2015, 8, 21);
        Test.startTest();
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, td.lstIncentives[0].Id, null,contexParams);
            SubscriptionsWebservices.GetLapsedSubscriptionDetailsResult res = SubscriptionsWebservices.GetLapsedSubscriptionDetails(null);
            System.assertNotEquals(null, res.wsError);  
            System.assert(res.wsError.errorMessage.contains('TSNumber cannot be null'));
            
            Subscription__c subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_static__c =: r.TSNumber  limit 1];
            subs.Subscription_Status__c = 'Pending Cancellation';
            subs.Cancellation_Method__c = 'Phone';
            subs.Cancellation_Reason__c = 'Test';
            subs.Cancellation_Date__c = subscriptionDetails.startDate.addDays(20);
            update subs;
            res = SubscriptionsWebservices.GetLapsedSubscriptionDetails(r.TSNumber);
            System.assertNotEquals(null, res.wsError);  
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 10/08/2015
    Version - 1.1
    Function - testnullGuid
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         01/04/2016  //adjust method to use new data model
    ****************************************************************************************/
    static testMethod void testnullGuid(){
        setupPremiumData();
        setupProductData();
        Test.startTest();     
            subscriberDetails.guid = null;
            SubscriptionsWebservices.CreateSubscriberResult r = SubscriptionsWebservices.CreateSubscriber(subscriberDetails, subscriptionDetails, paymentDetails.recurringDetails, null, null, null,null);
        Test.stopTest();      
        System.assertNotEquals(null, r);
        System.assertEquals('2', r.wsError.errorCode);  
        System.assert(r.wsError.errorMessage.contains('Please select a GUID for this Account'));
    }
}