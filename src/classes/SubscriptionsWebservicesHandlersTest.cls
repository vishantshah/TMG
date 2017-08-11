/**
* @author Unknown
* @date Unknown
* @description PP-2: Test classes for the SubscriptionsWebservicesHandlers class. Dependencies: SubscriptionsWebservicesHandlers
#############Change Log#############
Modified by     Version     Change Date
Lynette Lim         1.1     17/06/2015  //Updated setupIncentiveData method to create test incentive records to include valid-from and valid-to dates
                            26/06/2015  //Added test methods to check all possible scenarios of partial update of accounts/subscritption on payment schedule creation callback,
                                        //Restored assertions across some of the old methods.
Wiktor Czykin       1.2     02/09/2015  //modified testMethodCoverage(), temporarily removed getIncentives() test methods
Cristina Anghenie   1.3     26/10/2015  //modified testCreateTransaction_SuccessPremium();
Wiktor Czykin		1.4		08/12/2015	//added coverage to modified update and create subscription methods and their helper methods
Wiktor Czykin		1.5		15/12/2015	//modified few test methods with a common TestDataUtility method changeTCodeToLowStart();
Wiktor Czykin       1.6     23/02/2016  //modified testMethodCoverage()
Wiktor Czykin       1.7     25/02/2016  //added testRegistrantRecordTypeIsNotOverridenByDigitalOnDigitalSub() test method
Pawel Chrzanowski   1.8     02/03/2016  //disabled some methods to reflect changes in SubscriptionsWebservicesHandlers.cls
Michal Szewczyk     1.9     28/04/2016  //added TestDataUtility to some test methods to allow run SAM/MPP calls
Mantas Grigaliunas	2.0		09/06/2016	//removed testCreateAccount_Success_ipad method and some code that is not required anymore after ipad and android types are depricated on the system
Mantas Grigaliunas  2.1     17/01/2017  //put testCreateTransaction_Success_EU method in test context 
Wiktor Czykin       2.2     21/03/2017  //modifications to make unique email on account work
**/
@isTest(SeeAllData=false)
private class SubscriptionsWebservicesHandlersTest {
    
    private static SubscriptionsWebservices.Subscriber digitalSubscriberDetails;
    private static SubscriptionsWebservices.Subscriber premiumSubscriberDetails;
    private static SubscriptionsWebservices.Payment paymentDetails;
    private static SubscriptionsWebservices.Subscription digitalSubscriptionDetails;
    private static SubscriptionsWebservices.Subscription premiumSubscriptionDetails;
    private static SubscriptionsWebservices.MPPRecurringInfo recurringDetails;
    private static SubscriptionsWebservices.DirectDebitInfo ddDetails;
    private static zqu__ZProduct__c selectedProduct;
    private static List<SubscriptionsWebservices.CustomParameter> contexParams;
    private static decimal vatRateGB = 0.2;
    private static decimal vatRateEU = 0.1;
    static final Integer MAX_ACCOUNTS = 10;
    
    static List<Account> getMPPAccountData()
    {
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < MAX_ACCOUNTS; i++){
            Account acc = new Account();
            acc.Title__c='Mr.';
            acc.FirstName = 'Amir';
            acc.LastName = 'Hafeez';
            acc.IsUsingMPP__c = true;
            acc.Subscriber_Number_static__c = '0000' + i;
            acc.PersonEmail = 'amir.hafeez.test' + i + '@test.com';
            acc.PersonMailingPostalCode = 'E11 1JY';
            accList.add(acc);
        }
        return accList;
    }
    
    
    private static void setupDigitalAccountData(){
        digitalSubscriberDetails = new SubscriptionsWebservices.Subscriber( );
        digitalSubscriberDetails.guid = 'GUIDTestMethodData' + Math.random();
        digitalSubscriberDetails.subscriberType = 'digital';
        digitalSubscriberDetails.digitalSubscriberStatus = 'Active';
        digitalSubscriberDetails.firstName = 'Testio';
        digitalSubscriberDetails.lastName = 'Testev';
        digitalSubscriberDetails.personalEmail = DateTime.now().getTime() + 'testio@test.com';
        digitalSubscriberDetails.street = 'Cannon Street|Some district';
        digitalSubscriberDetails.city = 'Reading';
        digitalSubscriberDetails.postalCode = 'RG1 AHE';
        digitalSubscriberDetails.country = 'GB';
        digitalSubscriberDetails.homePhone = '01603554887';
        digitalSubscriberDetails.mobilePhone = '077777777777';
        digitalSubscriberDetails.marketingEmailPref = true;
        digitalSubscriberDetails.TCode = '445T';  
        digitalSubscriberDetails.poc = '009R0091946476';
        digitalSubscriberDetails.isPrint = false;

        digitalSubscriptionDetails = new SubscriptionsWebservices.Subscription();
        digitalSubscriptionDetails.productType = 'digital';
        digitalSubscriptionDetails.subscriptionType = 'monthly';
        digitalSubscriptionDetails.startDate = date.today();

        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.loadCountryCodes();
        tdu.loadVAT();
    }
    
    private static void setupPremiumAccountData(){
        premiumSubscriberDetails = new SubscriptionsWebservices.Subscriber( );
        premiumSubscriberDetails.guid = 'GUIDTestMethodData' + Math.random();
        premiumSubscriberDetails.subscriberType = 'premium';
        premiumSubscriberDetails.firstName = 'Testio';
        premiumSubscriberDetails.lastName = 'TestevPrem';
        premiumSubscriberDetails.personalEmail = DateTime.now().getTime() + 'testiop@test.com';
        premiumSubscriberDetails.street = 'Cannon Street';
        premiumSubscriberDetails.city = 'Reading';
        premiumSubscriberDetails.postalCode = 'RG1 AHE';
        premiumSubscriberDetails.country = 'GB';
        premiumSubscriberDetails.homePhone = '01603554887';
        premiumSubscriberDetails.mobilePhone = '077777777777';
        premiumSubscriberDetails.marketingEmailPref = true;
        premiumSubscriberDetails.TCode = '0A8A';    
        premiumSubscriberDetails.poc = '009R0091946476';
        premiumSubscriberDetails.isPrint = true;
        
        premiumSubscriptionDetails = new SubscriptionsWebservices.Subscription();
        premiumSubscriptionDetails.productType = 'premium';
        premiumSubscriptionDetails.subscriptionType = 'monthly';
        premiumSubscriptionDetails.startDate = date.today().adddays(21).toStartOfWeek();
        
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.loadCountryCodes();
        tdu.loadVAT();
    }
    
    private static void setupDDData(){
        ddDetails = new SubscriptionsWebservices.DirectDebitInfo();
        ddDetails.AccountName = 'TestAccount';
        ddDetails.AccountNumber = '1234';
        ddDetails.SortCode= '121212';
    }
    
    /** Returns the Salesforce Account from the WebService Subscriber
    */
    private static final Map<String,String> subscriberTypes = new Map<String,String>{'digital' => 'Digital Subscriber', 'premium' => 'Individual Subscriber'};
    private static Account getAccountFromWSSubscriber(){
        Account a = new Account();
        if(digitalSubscriberDetails.GUID != null)
            a.Guid__c = digitalSubscriberDetails.GUID;
        if(digitalSubscriberDetails.TCode != null)
            a.Wave_ID__c = digitalSubscriberDetails.TCode; 
        a.Subscriber_Digital_Status__c = digitalSubscriberDetails.digitalSubscriberStatus;
        a.RecordTypeID = UtilityLookupSubscriptionVariables.getRecordType(subscriberTypes.get(digitalSubscriberDetails.subscriberType.toLowerCase().trim()));
        a.Salutation = digitalSubscriberDetails.title;
        a.FirstName = digitalSubscriberDetails.firstName;
        a.LastName = digitalSubscriberDetails.lastName;
        a.PersonEmail= digitalSubscriberDetails.personalEmail;
        a.PersonMailingStreet = digitalSubscriberDetails.street;
        a.PersonMailingCity = digitalSubscriberDetails.city;
        a.PersonMailingPostalCode = subscriberPortal.FormatPostCode(digitalSubscriberDetails.postalCode);
        a.PersonMailingCountry = digitalSubscriberDetails.country;
        a.PersonHomePhone = digitalSubscriberDetails.homePhone;
        a.PersonMobilePhone = digitalSubscriberDetails.mobilePhone;
        a.Origin__c = 'Online';
        a.Email_Sent__c = false;
        a.TMG_Promo_Email__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingEmailPref);
        a.TMG_Promo_Phone__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingPhonePref);
        a.TMG_Promo_Post__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingPostPref);
        a.TMG_Promo_SMS__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingSMSPref);
        a.TMG_Loyalty_Email__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingEmailPref);
        a.TMG_Loyalty_Phone__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingPhonePref);
        a.TMG_Loyalty_Mail__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingPostPref);
        a.TMG_Loyalty_SMS__c = UtilitiesForSubscriptions.convertBooleanToInteger(digitalSubscriberDetails.marketingSMSPref);
        a.Title__c = 'Mr.';
        
        return a;
    }
    
    /** Insert the Test Account data prepared by setupDigitalAccountData()
    *   returns the TsNumber
    */
    private static String insertAccountData(){
        setupDigitalAccountData();
        Account acc = getAccountFromWSSubscriber();
        try{ 
            insert acc;
        }catch(Exception ex){}
        
        String TsNumber = [select Subscriber_Number_static__c from Account where personEmail=:digitalSubscriberDetails.personalEmail].Subscriber_Number_static__c;
        return TsNumber;
    }
    
    private static void setupDigitalPaymentData(){

        paymentDetails = new SubscriptionsWebservices.Payment( );
        paymentDetails.paymentDate = System.now();
        paymentDetails.amountGross = 4.8;
        paymentDetails.currencyType = 'GBP';
        paymentDetails.paymentStatus = 'success';
        paymentDetails.paymentType = 'CreditDebitCard';
        paymentDetails.productName = 'Digital';
        paymentDetails.digitalSubscriptionID = 'my Digital Subscription';
        paymentDetails.serviceId = '123';
        paymentDetails.orderId = '123';
        
        recurringDetails = new SubscriptionsWebservices.MPPRecurringInfo();
        recurringDetails.paymentType = paymentDetails.paymentType;
        recurringDetails.firstPaymentAmount = 200.00;
        recurringDetails.nextPaymentDate = Date.today().addDays(120);
        recurringDetails.frequency = '15';
        recurringDetails.premiumSubscriptionID = '100101';
        
        paymentDetails.recurringDetails = recurringDetails;
    }   
    
    private static void setupPremiumPaymentData(){

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
    
    private static void setupIncentiveData(TestDataUtility tdu){
        if(tdu == null){
            tdu = new TestDataUtility(1);
        }
        tdu.createZProductFeatures();
        selectedProduct = tdu.lstZproducts[0];
        tdu.createTCodeProducts();
        
        contexParams = new List<SubscriptionsWebservices.CustomParameter>();
        SubscriptionsWebservices.CustomParameter prodId = new SubscriptionsWebservices.CustomParameter();
        prodId.name = 'productId';
        prodId.value = '' + selectedProduct.id;
        contexParams.add(prodId);
        tdu.setDefautProdCustomSetting();

        try{
            delete ([Select Id from TCodeManagement__c where type__c='Open Offer' and Valid__c = true  ]);
        }
        catch(DmlException e){
        }
        Date myDate = date.newinstance(System.now().year(), System.now().month(), System.now().day());
        Incentive__c inc1 = new Incentive__c( Name='Incentive1', Incentive_Description__c='An exciting incentive', Valid_From__c=myDate-2, Valid_To__c=myDate+2);
        Incentive__c inc2 = new Incentive__c( Name='Incentive2', Incentive_Description__c='An even more exciting incentive', Valid_From__c=myDate-2, Valid_To__c=myDate+2);
        
        try{
            insert inc1;
        }catch(Exception ex){}
        try{
            insert inc2;
        }catch(Exception ex){}

        TCodeManagement__c tcm1 = new TCodeManagement__c( name='0A5A', Price__c=4.5, Digital_Monthly_Price__c=2.5, Digital_Yearly_Price__c=62.3, Description__c='Something about tcode 1', Type__c='POC' );
        TCodeManagement__c tcm2 = new TCodeManagement__c( name='0A8A', Price__c=4.5, Digital_Monthly_Price__c=3.5, Digital_Yearly_Price__c=42.3, Description__c='Something about tcode 2', Type__c='POC' );
        
        try{
            insert tcm1;
            insert TestDataUtility.newTCodeProduct(selectedProduct.Id,tcm1.Id);
        }catch(Exception ex){}
        try{
            insert tcm2;
            insert TestDataUtility.newTCodeProduct(selectedProduct.Id,tcm2.Id);
        }catch(Exception ex){}

       POC__c poc1 = new POC__c( TCodeManagement__c=tcm2.Id, POC_ID__c='12345678', PostalCode__c='nn4 0qs', LastName__c = 'frank',Product__c = selectedProduct.Id);
       POC__c poc2 = new POC__c( TCodeManagement__c=tcm1.Id, POC_ID__c='123456789', PostalCode__c='nn4 0qs', LastName__c = 'frank',Product__c = selectedProduct.Id);
          
        try{
            insert poc1;
            insert poc2;
        }catch(Exception ex){}

        TCodeIncentive__c tci1_1_d = new TCodeIncentive__c( TCode__c=tcm1.Id, Incentive__c=inc1.Id, Product__c='digital', Subscription_Type__c = 'Yearly' );
        TCodeIncentive__c tci1_2_d = new TCodeIncentive__c( TCode__C=tcm1.id, Incentive__c=inc2.Id, Product__c='digital', Subscription_Type__c = 'Yearly' );
        TCodeIncentive__c tci1_2_p = new TCodeIncentive__c( TCode__C=tcm1.id, Incentive__c=inc2.Id, Product__c='premium', Subscription_Type__c = '52 Weeks' );
        
        TCodeIncentive__c tci2_1_d = new TCodeIncentive__c( TCode__C=tcm2.id, Incentive__c=inc1.Id, Product__c='digital', Subscription_Type__c = 'Monthly' );
        
        try{
            insert tci1_1_d;    
        }catch(Exception ex){}
        try{
            insert tci1_2_d;
        }catch(Exception ex){}
        try{
            insert tci1_2_p;
        }catch(Exception ex){}
        try{
            insert tci2_1_d;
        }catch(Exception ex){}

		List<TCodeManagement__c> tcodes = new List<TCodeManagement__c>();
        tcodes = [SELECT Id FROM TCodeManagement__c WHERE Valid__c = true and Type__c = 'Open Offer'];
        if( tcodes != null && tcodes.size() == 0 ){
            TCodeManagement__c ooTCode = new TCodeManagement__c( name='BOO1', Price__c=4.5, Digital_Monthly_Price__c=3.5, Digital_Yearly_Price__c=42.3, Description__c='Something about tcode 2', Type__c='Open Offer', valid__c = true );
            try{ insert ooTcode;
                insert TestDataUtility.newTCodeProduct(selectedProduct.Id,ooTcode.Id);

             }catch(Exception ex){}
        }
    } 

    static testMethod void testCreateAccount_Success() {
        setupDigitalAccountData();
        setupDigitalPaymentData();
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);

        System.assertNotEquals(null, r);
        List<Account> accs = [Select Id, Guid__c From Account Where Subscriber_Number_static__c = :r];
        
        System.assertNotEquals(null,accs);
        System.assertEquals(1,accs.size());
        System.assertEquals(digitalSubscriberDetails.guid, accs[0].Guid__c);
    }   

    static testMethod void testCreateAccount_Success_webpack(){
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
   
        digitalSubscriberDetails.subscriberType = 'webpack';
  
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
       
        System.assertNotEquals(null, r);
        
        List<Account> accs = [Select Id, Digital_Product_Type__c, iPadAccess__c, websiteAccess__c, smartphoneAccess__c, loyaltyAccess__c From Account Where Subscriber_Number_static__c = :r];
        
        System.assertNotEquals(null,accs);
        System.assertEquals(1,accs.size());
        
        System.assertEquals(false, accs[0].iPadAccess__c);
        System.assertEquals(true, accs[0].websiteAccess__c);
        System.assertEquals(true, accs[0].smartphoneAccess__c);
        System.assertEquals(false, accs[0].loyaltyAccess__c);
        System.assertEquals(Constants.DIGITAL_PRODUCT_WEBPACK, accs[0].Digital_Product_Type__c);
    } 
    
    static testMethod void testCreateAccount_Success_alldevices() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
   
        digitalSubscriberDetails.subscriberType = 'digital';
  
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        List<Account> accs = [Select Id, Digital_Product_Type__c, iPadAccess__c, websiteAccess__c, smartphoneAccess__c, loyaltyAccess__c From Account Where Subscriber_Number_static__c = :r];
        
        System.assertNotEquals(null,accs);
        System.assertEquals(1,accs.size());
        
        System.assertEquals(true, accs[0].iPadAccess__c);
        System.assertEquals(true, accs[0].websiteAccess__c);
        System.assertEquals(true, accs[0].smartphoneAccess__c);
        System.assertEquals(true, accs[0].loyaltyAccess__c);
        System.assertEquals(Constants.DIGITAL_PRODUCT_ALLDEVICES, accs[0].Digital_Product_Type__c);
    } 
            
    static testMethod void testCreateAccount_DuplicateGuid() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;
        
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r); 
        try{
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.GuidInUseException);
    }
    
    static testMethod void testCreateAccount_NullParameter() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        
        System.assertNotEquals(null, r);
        try{
            SubscriptionsWebservicesHandlers.createSubscriber(null);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    } 
        
    static testMethod void testCreateAccount_NameTooLong() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        try{
            digitalSubscriberDetails.lastName = 'lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName lastName '; 
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    }
    
    static testMethod void testCreateAccount_InvalidSubscriberType() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        try{
            digitalSubscriberDetails.subscriberType = 'blah';
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    }
        
    static testMethod void testCreateAccount_NullSubscriberType() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        try{
            digitalSubscriberDetails.subscriberType = null;
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void testCreateAccount_InvalidDigitalSubscriberStatus() {
        
        setupDigitalAccountData();
        Exception ex;

        try{
            digitalSubscriberDetails.digitalSubscriberStatus = 'blah';
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    }

    static testMethod void testCreateAccount_InvalidEmailAddress() {
        
        setupDigitalAccountData();
        Exception ex;

        try{
            digitalSubscriberDetails.personalEmail = '';
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Test sendErrorEmail method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			07/12/2015	//added load of General__c costom settings to reach sendErrorEmail() code
    ***************************************************************************************/
    static testMethod void testSendEmail() {
        TestDataUtility td = new TestDataUtility();
        td.loadGeneral();
        setupDigitalAccountData();
        Exception ex;

        try{
            digitalSubscriberDetails.personalEmail = '';
            SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }
        
        SubscriptionsWebservicesHandlers.sendErrorEmail('Test method', 'no log id', 'an error message', ex);
        
    }
    
    static testMethod void testCreateTransaction_Success() {
        TestDataUtility tdu = new TestDataUtility(3);
        tdu.loadPlaneURL();
        setupDigitalAccountData();
        setupDigitalPaymentData();
        setupIncentiveData(tdu);
        
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{});
            Test.setMock(HttpCalloutMock.class, mock); 
            SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
            List<MPP_Transaction_History__c> txs = [Select Id From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r];
            System.assertNotEquals(0, txs.size());
            SubscriptionsWebservicesHandlers.updatePaymentSchedulesOnAccount(r,'OFFLINE',digitalSubscriptionDetails,paymentDetails);
        Test.stopTest();
    }    
	
	 /*************************************************************************************** 
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - Test method for SubscriptionsWebservicesHandler#testCreateTransaction_Success_EU()
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			26/08/2015	//test if MPP_Service_Id__c on account gets defaulted to custom setting value if serviceId from MPP is null
    Mantas Grigaliunas  1.2         17/01/2017  //put the method in test context to avoid SOQL queries limit reached exception
    ****************************************************************************************/
    static testMethod void testCreateTransaction_Success_EU() {
        // NOTE: whilst these situations shouldn't happen i.e. premium is UK only
        // it's still good to have them in place and tested
        setupPremiumAccountData();
        setupPremiumPaymentData();
        setupIncentiveData(null);

        Test.startTest();
        premiumSubscriberDetails.country = 'FR';
        premiumSubscriberDetails.TCode ='t1';
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();

        Id subId = SubscriptionsWebservicesHandlers.createSubscription(r, null, 'BOO1', premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        System.assertNotEquals(null, subId);

        SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        List<MPP_Transaction_History__c> txs = [Select Id, VAT_Rate__c From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r];
        System.assertNotEquals(0, txs.size());
        System.assertEquals(0, txs[0].VAT_Rate__c);
        //test if MPP_Service_Id__c gets defaulted to PlaneURL custom settings if null 
        TestDataUtility td = new TestDataUtility(1);
        td.loadPlaneURL();
        paymentDetails.serviceId = null;
        SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        Account acc = [SELECT Id, MPP_Service_Id__c FROM Account WHERE Subscriber_Number_static__c =: r];
        System.assertEquals(td.lstPlaneURL[0].Premium_Continuous_ID__c,acc.MPP_Service_Id__c);
        Test.stopTest();
    } 
    

    static testMethod void testCreateTransaction_Success_ROW() {
        
        // NOTE: whilst these situations shouldn't happen i.e. premium is UK only
        // it's still good to have them in place and tested

        setupPremiumAccountData();
        setupPremiumPaymentData();
        setupIncentiveData(null);

        premiumSubscriberDetails.country = 'US';
        premiumSubscriberDetails.TCode ='t1';
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        Id subId = SubscriptionsWebservicesHandlers.createSubscription(r, null, 'BOO1', premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        System.assertNotEquals(null, subId);
        

        SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        List<MPP_Transaction_History__c> txs = [Select Id, VAT_Rate__c From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r];
        System.assertNotEquals(0, txs.size());
        System.assertEquals(0, txs[0].VAT_Rate__c);
    } 
    
    /*************************************************************************************** 
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - Test method for SubscriptionsWebservicesHandler#testCreateTransaction_SuccessPremium()
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/        
    static testMethod void testCreateTransaction_SuccessPremium() {
        setupPremiumAccountData();
        setupPremiumPaymentData();
        setupIncentiveData(null);

        premiumSubscriberDetails.TCode ='t1';
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        Id subId = SubscriptionsWebservicesHandlers.createSubscription(r, null, 'BOO1', premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        System.assertNotEquals(null, subId);
        
        SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        List<MPP_Transaction_History__c> txs = [Select Id,DD_Account_Name__c,DD_Account_Number__c,DD_Sort_Code__c  From MPP_Transaction_History__c Where Subscriber__r.Subscriber_Number_static__c = :r];
        System.assertNotEquals(0, txs.size());
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 11.11.2015
    Version - 1.0
    Function - test that the DD account name saves in MPP_Transaction_History
                the first 255 characters in case is longer than that
    #############Change Log#############
    Modified by         Version     Change Date
    ****************************************************************************************/        
    static testMethod void testLongAccountName() {
        TestDataUtility tdu = new TestDataUtility();
        tdu.createSubscriptions();
        setupPremiumAccountData();
        setupPremiumPaymentData();
        setupIncentiveData(tdu);

        String tsNumber = [SELECT Subscriber_Number_Static__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_Static__c;
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        
        
        ddDetails = new SubscriptionsWebservices.DirectDebitInfo();
        ddDetails.AccountName = 'Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account Very long test account ';
        ddDetails.AccountNumber = '22222222';
        ddDetails.SortCode = '000000';
        ddDetails.auddisRef = 'ref1234';
        ddDetails.submittedPaymentDate = System.today();
        System.assert(ddDetails.AccountName.length()>255);
        
        SubscriptionsWebservicesHandlers.createTransaction(tsNumber, paymentDetails, ddDetails, false);
        List<MPP_Transaction_History__c> txs = [Select Id,DD_Account_Name__c,DD_Account_Number__c,DD_Sort_Code__c  
                                                From MPP_Transaction_History__c 
                                                Where Subscriber__r.Subscriber_Number_static__c = :tsNumber
                                                AND DD_Account_Number__c != null];
        System.assertEquals(ddDetails.AccountName.left(100),txs[0].DD_Account_Name__c);
        System.assertEquals('22222222',txs[0].DD_Account_Number__c);
        System.assertEquals('000000',txs[0].DD_Sort_Code__c);
    }

    static testMethod void testCreateTransaction_failure_nosub() {
        
        Exception ex;       
        setupPremiumAccountData();
        setupPremiumPaymentData();
        setupIncentiveData(null);

        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);

        try{
            SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, true);
        } catch(Exception e){
            ex = e;
        }
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NoActiveSubscriptionException);
    }     
            
    static testMethod void testCreateTransaction_InvalidTSNumber() {
        
        setupDigitalPaymentData();
        Exception ex;

        try{
            SubscriptionsWebservicesHandlers.createTransaction('', paymentDetails, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
    }   
        
    static testMethod void testCreateTransaction_NullTSNumber() {
        
        setupDigitalPaymentData();
        Exception ex;

        try{
            SubscriptionsWebservicesHandlers.createTransaction(null, paymentDetails, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    } 

    static testMethod void testCreateTransaction_DMLException() {
        
        setupDigitalPaymentData();
        Exception ex;

        setupDigitalAccountData();
        setupDigitalPaymentData();
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);

        paymentDetails.digitalSubscriptionID = 'long long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long longlong long long';
        try{
            SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    } 

    static testMethod void testCreateTransaction_NullPaymentDetails() {
        
        setupDigitalPaymentData();
        Exception ex;

        
        try{
            SubscriptionsWebservicesHandlers.createTransaction(' ', null, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
         
    static testMethod void testCreateTransaction_InvalidPaymentStatus() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
 
        try{
            paymentDetails.paymentStatus = 'random';
            SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
        System.assert(((WebserviceUtil.WSException)ex).getError().errorMessage.toLowerCase().contains('paymentstatus'));
    }
    
    static testMethod void testCreateTransaction_InvalidCurrencyType() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
 
        try{
            paymentDetails.currencyType = 'random';
            SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void testCreateTransaction_InvalidPaymentType() {
        
        setupDigitalAccountData();
        setupDigitalPaymentData();
        Exception ex;

        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
 
        try{
            paymentDetails.paymentType = 'random';
            SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);

        System.assert(((WebserviceUtil.WSException)ex).getError().errorMessage.toLowerCase().contains('paymenttype'));
    }

    static testMethod void testUpdateSubscriber_Success(){
        setupDigitalAccountData();
        setupDigitalPaymentData();
        
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r); 

       digitalSubscriberDetails.TSNumber = r;
        
        digitalSubscriberDetails.personalEmail = 'alternate@t.co.uk';           
        digitalSubscriberDetails.street = 'Street 1|Street2'; 
        SubscriptionsWebservicesHandlers.updateSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails);

        List<Account> accs = [Select Id, personEmail, personMailingStreet From Account Where Subscriber_Number_static__c = :r];
        System.assertNotEquals(0,accs.size());
        System.assertEquals(digitalSubscriberDetails.personalEmail, accs[0].personEmail); 
        
        System.assertEquals('Street 1\nStreet2', accs[0].personMailingStreet);
    }


    static testMethod void testUpdateSubscriber_Success_noguid(){
  
        setupDigitalAccountData();
        setupDigitalPaymentData();
        
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r); 
 

       digitalSubscriberDetails.TSNumber = r;
       
        digitalSubscriberDetails.personalEmail = 'alternate@t.co.uk';           
        digitalSubscriberDetails.GUID = null;
        //pp-2484 changes--added the extra parameters
        SubscriptionsWebservicesHandlers.updateSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails);


        List<Account> accs = [Select Id, personEmail, personMailingStreet From Account Where Subscriber_Number_static__c = :r];
        System.assertNotEquals(0,accs.size());
        System.assertEquals(digitalSubscriberDetails.personalEmail, accs[0].personEmail); 
    }
        
    static testMethod void testUpdateSubscriber_UnknownTSNumber(){
        
        setupDigitalAccountData();
        Exception ex;

        try{
            digitalSubscriberDetails.TSNumber = 'blah blah test';               
            SubscriptionsWebservicesHandlers.updateSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
    }   

    static testMethod void testUpdateSubscriber_InvalidEmail(){
        
        setupDigitalAccountData();
        Exception ex;

        try{                
            digitalSubscriberDetails.personalEmail = '';
            SubscriptionsWebservicesHandlers.updateSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }

    static testMethod void testUpdateSubscriber_NullDetails(){
        
        setupDigitalAccountData();
        Exception ex;

        try{                
            digitalSubscriberDetails.personalEmail = '';
            SubscriptionsWebservicesHandlers.updateSubscriber(null);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
            
    static testMethod void testUpdateSubscriber_InvalidDigitalSubscriberStatus(){
        
        setupDigitalAccountData();
        Exception ex;

        try{                
            digitalSubscriberDetails.digitalSubscriberStatus = 'blah';
            SubscriptionsWebservicesHandlers.updateSubscriber(digitalSubscriberDetails);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    }
    
    static testMethod void testCheckDigitalSubscriberStatus_Success() {

        setupDigitalAccountData();

        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r); 

        
        String s = SubscriptionsWebservicesHandlers.checkDigitalSubscriberStatus(r);
        System.assertEquals(digitalSubscriberDetails.digitalSubscriberStatus, s);
    }

    static testMethod void testCheckDigitalSubscriberStatus_UnknownTSNumber() {

        Exception ex;
    
        try{
            SubscriptionsWebservicesHandlers.checkDigitalSubscriberStatus('kkjhkhjkjh');
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
    }
    
    static testMethod void testCheckDigitalSubscriberStatus_NullTSNumber() {

        Exception ex;
    
        try{
            SubscriptionsWebservicesHandlers.checkDigitalSubscriberStatus(null);
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void testgetPOCStatus(){
        
        setupIncentiveData(null);
        
        SubscriptionsWebservices.POCDetails details = SubscriptionsWebservicesHandlers.getPOCStatus('12345678', 'nn40qs');
        System.assertNotEquals(null, details);
        System.assertEquals('valid', details.POCStatus.toLowerCase());

    }
    
    static testMethod void testgetPOCStatus_missing(){
        
        setupIncentiveData(null);
        
        SubscriptionsWebservices.POCDetails details = SubscriptionsWebservicesHandlers.getPOCStatus('12345678xx', 'nn40qs');
        System.assertNotEquals(null, details);
        System.assertEquals('doesntexist', details.POCStatus.toLowerCase());
    }    
    
    static testMethod void testupdateSubscriberStatus(){
        String TsNumber = insertAccountData();
        Exception ex;
        String digitalSubscriberStatus = 'Active';
        String mppServiceId = 'mppServiceId';
        try{                
            
            SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(TsNumber, mppServiceId);
        } catch(Exception e){
            ex = e; 
        }
        Account acc = [select Subscriber_Digital_Status__c, Email_Sent__c, MPP_Service_Id__c from Account where Subscriber_Number_static__c=:TsNumber];
        System.assertEquals(ex, null);
        System.assertEquals(acc.Subscriber_Digital_Status__c, digitalSubscriberStatus);
        System.assertEquals(acc.MPP_Service_Id__c, mppServiceId);
    }
    
    static testMethod void testupdateSubscriberStatus_InvalidStatus(){
        String TsNumber = insertAccountData();
        Exception ex;
        String mppServiceId = 'mppServiceId';

        try{                
            String digitalSubscriberStatus = 'xxx';
            SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(TsNumber, mppServiceId);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    }
    
    
    
    static testMethod void testupdateSubscriberStatus_NullTSNumber(){
        String TsNumber = insertAccountData();
        Exception ex;
        String mppServiceId = 'mppServiceId';

        try{                
            String digitalSubscriberStatus = 'Active';
            SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(null, mppServiceId);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void testupdateSubscriberStatus_UnknownTSNumber(){
        String TsNumber = insertAccountData();
        Exception ex;
        String mppServiceId = 'mppServiceId';

        try{                
            String digitalSubscriberStatus = 'Active';
            SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(TsNumber + 'xx', mppServiceId);
        } catch(Exception e){
            ex = e;
        }

        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
    }
    
    static testMethod void testupdateSubscriberStatus_NoEmailUpdate(){
        String TsNumber = insertAccountData();
        Exception ex;
        String digitalSubscriberStatus = 'Active';
        String mppServiceId = 'mppServiceId';
        try{                
            
            SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(TsNumber, mppServiceId);
        } catch(Exception e){
            ex = e; 
        }
        Account acc = [select Subscriber_Digital_Status__c, Email_Sent__c, MPP_Service_Id__c from Account where Subscriber_Number_static__c=:TsNumber];
        System.assertEquals(ex, null);
        System.assertEquals(acc.Subscriber_Digital_Status__c, digitalSubscriberStatus);
        System.assert(!acc.Email_Sent__c);
        System.assertEquals(acc.MPP_Service_Id__c, mppServiceId);
    }

    static testMethod void testvalidateStartDate_success(){
        Date proposed = date.today();
        
        Date valid = SubscriptionsWebservicesHandlers.validateStartDate(proposed);
        
        System.assert(valid > proposed);
    }
    

    static testMethod void testgetTCode_success_openofferflow(){
        setupIncentiveData(null);
        
        SubscriptionsWebservices.Tcode tCode = SubscriptionsWebservicesHandlers.getTCodeNewImpl('', 'openofferflow', '');
        
        //System.assertEquals('BOO1', tCode);
    }

    static testMethod void testgetTCode_success_promotionsflow(){
        setupIncentiveData(null);
        
        SubscriptionsWebservices.Tcode tCode = SubscriptionsWebservicesHandlers.getTCodeNewImpl('112211', 'promotionflow', '0A5A');
        
        //System.assertEquals('testcode', tCode);
    }
      
    
    static testMethod void testgetTcode_failure_invalidflow(){
        
        Exception ex;
        try{
            SubscriptionsWebservicesHandlers.getTCodeNewImpl('', 'badflow', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
    }
    
    static testMethod void testgetTcode_failure_notcode(){
        
        Exception ex;
        try{
            SubscriptionsWebservicesHandlers.getTCodeNewImpl('', 'promotionflow', null);
        } catch(Exception e){
            ex = e;
        }
        
        //System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void testgetTcode_failure_nopoc(){
        
        Exception ex;
        try{
            SubscriptionsWebservicesHandlers.getTCodeNewImpl(null, 'pocflow', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void testcreateSubscription_success_tcode(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();

        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        Id subId = SubscriptionsWebservicesHandlers.createSubscription(r, null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        System.assertNotEquals(null, subId);
    }
    
    static testMethod void testcreateSubscription_success_poc(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        
        premiumSubscriberDetails.TCode ='t1';
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        Id subId = SubscriptionsWebservicesHandlers.createSubscription(r, '12345678', null, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        System.assertNotEquals(null, subId);
    }
        
    static testMethod void testcreateSubscription_failure_nullproducttype(){
        Exception ex;
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
       
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        premiumSubscriptionDetails.productType = null;
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        
        try{
            SubscriptionsWebservicesHandlers.createSubscription(r, null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        } catch(Exception e){
            ex = e;
        }
        System.assertEquals(null, ex);
        
    }
    
    static testMethod void testcreateSubscription_failure_invalidproducttype(){
        Exception ex;
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        premiumSubscriptionDetails.productType = 'frank';
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        
        try{
            SubscriptionsWebservicesHandlers.createSubscription(r, null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        } catch(Exception e){
            ex = e;
        }
        System.assertEquals(null, ex);
        
    }
    
    static testMethod void testcreateSubscription_failure_nullsubscriptiontype(){
        Exception ex;
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        
        //pp-2484 changes -- commented the below line
        //String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails);
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType = null;
        
        try{
            SubscriptionsWebservicesHandlers.createSubscription(r, null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        } catch(Exception e){
            ex = e;
        }
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
    }
    
    static testMethod void testcreateSubscription_failure_invalidsubscriptiontype(){
        Exception ex;
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();

        //pp-2484 changes -- commented the below line
        //String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails);
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType = 'frank';
        
        try{
            SubscriptionsWebservicesHandlers.createSubscription(r, null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        } catch(Exception e){
            ex = e;
        }
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);
        
    }
            
    static testMethod void testcreateSubscription_failure_nullstartdate(){
        Exception ex;
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();

        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        premiumSubscriptionDetails.startDate = null;
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        
        try{
            SubscriptionsWebservicesHandlers.createSubscription(r, null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        } catch(Exception e){
            ex = e;
        }
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
    }

    static testMethod void testcreateSubscription_unknowntsnumber(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';

        Id subId = SubscriptionsWebservicesHandlers.createSubscription('somerubbish', null, premiumSubscriberDetails.TCode, premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);

        System.assertEquals(null, subId);
        
    }
        
    static testMethod void testupdateLastAccessedData_website(){
 
        Date lastAccessed = Date.valueOf('2011-05-01');
 
        Account a = new Account(Title__c='Mr.', lastname = 'testupdateLastAccessedDatasinglewebsite', PersonMailingPostalCode = 'E11 1JY',Subscriber_Digital_Status__c='active');
        try{ insert a; }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE id = :a.id LIMIT 1];
        
        SubscriptionsWebservicesHandlers.updateLastAccessedData(a.Subscriber_Number_static__c, 'website', lastAccessed);

        a = [SELECT Id, Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE id = :a.id LIMIT 1];
        System.assertEquals(lastAccessed, a.Website_First_Accessed__c);     
        System.assertEquals(lastAccessed, a.Website_Last_Accessed__c);      
        
    }   
       
    static testMethod void testupdateLastAccessedData_mobile(){
 
        Date lastAccessed = Date.valueOf('2011-05-01');
 
        Account a = new Account(Title__c='Mr.', lastname = 'testupdateLastAccessedDatasinglemobile', PersonMailingPostalCode = 'E11 1JY',Subscriber_Digital_Status__c='active');
        try{ insert a; }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE id = :a.id LIMIT 1];
        
        SubscriptionsWebservicesHandlers.updateLastAccessedData(a.Subscriber_Number_static__c, 'mobile', lastAccessed);

        a = [SELECT Id, Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE id = :a.id LIMIT 1];
        System.assertEquals(lastAccessed, a.Mobile_First_Accessed__c);      
        System.assertEquals(lastAccessed, a.Mobile_Last_Accessed__c);       
        
    }    
    
    static testMethod void testupdateLastAccessedData_single_tablet(){
 
        Date lastAccessed = Date.valueOf('2011-05-01');
 
        Account a = new Account(Title__c='Mr.', lastname = 'testupdateLastAccessedDatasingletablet', PersonMailingPostalCode = 'E11 1JY',Subscriber_Digital_Status__c='active');
        try{ insert a; }catch(Exception ex){}
        a = [SELECT Id, Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE id = :a.id LIMIT 1];

        SubscriptionsWebservicesHandlers.updateLastAccessedData(a.Subscriber_Number_static__c, 'tablet', lastAccessed);

        a = [SELECT Id, Subscriber_Number_Static__c, Website_First_Accessed__c, Website_Last_Accessed__c, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c FROM Account WHERE id = :a.id LIMIT 1];
        System.assertEquals(lastAccessed, a.Tablet_First_Accessed__c);      
        System.assertEquals(lastAccessed, a.Tablet_Last_Accessed__c);       
        
    }   
    
    static testMethod void testupdateLastAccessedData_nulltsnumber(){
        
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.updateLastAccessedData(null, 'mobile', datetime.now());
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.NullParameterException);     
        
    } 
     
    static testMethod void testupdateLastAccessedData_nulldevice(){
        
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.updateLastAccessedData('tsnujmber', null, datetime.now());
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.NullParameterException);     
        
    } 
    
    static testMethod void testupdateLastAccessedData_nulllastaccessed(){
        
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.updateLastAccessedData('tsnumber', 'mobile', null);
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.NullParameterException);     
        
    }        
    static testMethod void testupdateLastAccessedData_single_baddevice(){
 
        Exception ex;
        
        try{
            SubscriptionsWebservicesHandlers.updateLastAccessedData('tsnumber', 'frank', datetime.now());
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.InvalidFieldException);      
        
    }
    
    
    static testMethod void testpaymentFailure_unknownTSNumber(){
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.paymentFailure('frank', new SubscriptionsWebservices.Payment(), '', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);           
    }
    
    static testMethod void testpaymentFailure_nullpaymentDetails(){
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.paymentFailure('', null, '', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.NullParameterException);         
    }    
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0 
    Function - test payment failure for digital dd
    #############Change Log#############
    Modified by     	Version     Change Date
	Pawel Chrzanowski	1.1			03/03/2016	//disabled assertion for inactive Account
    ****************************************************************************************/
    static testMethod void testpaymentFailure_success_digitalddfail(){

        setupDigitalAccountData();
        
        string failureReason = 'just failed';
        string failureCode = '8';
        string orderId = '12345aa';
        
       //pp-2484 changes -- commented the below line
        //String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        SubscriptionsWebservices.Payment pay = new SubscriptionsWebservices.Payment();
        pay.paymentDate = date.today();
        pay.amountGross = 5;
        pay.currencyType = 'GBP'; 
        pay.paymentStatus = 'success'; 
        pay.paymentType = 'directdebit';
        pay.productName = 'digital'; 
        pay.digitalSubscriptionID = 'd1';
        pay.orderId = orderId;
        pay.serviceId = '1234';
        
        SubscriptionsWebservicesHandlers.createTransaction(r, pay, null, false);    
        
        List<MPP_Transaction_History__c> hist = [SELECT Id, Payment_status__c FROM MPP_Transaction_History__c WHERE Order_id__c = :orderId];
        System.assertNotEquals(null, hist);
        System.assertNotEquals(0, hist.size());
        System.assertEquals('Success', hist[0].Payment_status__c);
        
        pay = new SubscriptionsWebservices.Payment();
        pay.paymentDate = date.today();
        pay.amountGross = 5;
        pay.currencyType = 'GBP'; 
        pay.paymentStatus = 'failed'; 
        pay.paymentType = 'directdebit';
        pay.productName = 'digital'; 
        pay.digitalSubscriptionID = 'd1';
        pay.orderId = orderId;
        pay.serviceId = '1234';         
 
        SubscriptionsWebservicesHandlers.paymentFailure(r, pay , failureReason, failureCode);
        hist = [SELECT Id, Payment_status__c, Failure_Code__c, Failure_Reason__c FROM MPP_Transaction_History__c WHERE Order_id__c = :orderId];
        System.assertNotEquals(null, hist);
        System.assertNotEquals(0, hist.size());
        System.assertEquals('Failed', hist[0].Payment_status__c);
        System.assertEquals(failureReason, hist[0].Failure_Reason__c);
        System.assertEquals(failureCode, hist[0].Failure_Code__c);
        
        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :r];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());
        //System.assertEquals('Inactive', accs[0].Subscriber_Digital_Status__c);		
        
        List<Task> tsks = [SELECT Id, Subject FROM Task WHERE WhatId = :accs[0].Id];
        System.assertNotEquals(null, tsks);
        System.assertNotEquals(0, tsks.size());
        System.assertEquals('DD Payment Failure ' + date.today(), tsks[0].Subject);

    }  
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0 
    Function - test payment failure for digital cc
    #############Change Log#############
    Modified by     Version     Change Date
	Pawel Chrzanowski	1.1			03/03/2016	//disabled assertion for inactive Account
    ****************************************************************************************/
    static testMethod void testpaymentFailure_success_digitalccfail(){
        setupDigitalAccountData();
        
        string failureReason = 'Payment Failure';
        string failureCode = null;

        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        SubscriptionsWebservices.Payment pay = new SubscriptionsWebservices.Payment();
        pay.paymentDate = date.today();
        pay.amountGross = 5;
        pay.currencyType = 'GBP'; 
        pay.paymentStatus = 'failed'; 
        pay.paymentType = 'CreditDebitCard';
        pay.productName = 'digital'; 
        pay.digitalSubscriptionID = 'd1';
        pay.serviceId = '1234';
 
        SubscriptionsWebservicesHandlers.paymentFailure(r, pay, null, null);
        List<MPP_Transaction_History__c> hist = [SELECT Id, Payment_status__c, Failure_Code__c, Failure_Reason__c FROM MPP_Transaction_History__c WHERE subscriber__r.Subscriber_Number_Static__c = :r];
        System.assertNotEquals(null, hist);
        System.assertNotEquals(0, hist.size());
        System.assertEquals('Failed', hist[0].Payment_status__c);
        System.assertEquals('Cancelled', hist[0].Failure_Reason__c);
        System.assertEquals('Unknown', hist[0].Failure_Code__c);
        
        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :r];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());
        System.assertEquals('Inactive', accs[0].Subscriber_Digital_Status__c);
        
        List<Task> tsks = [SELECT Id, Subject FROM Task WHERE WhatId = :accs[0].Id];
        System.assertNotEquals(null, tsks);
        System.assertNotEquals(0, tsks.size());
        System.assertEquals('Card Payment Failure ' + date.today(), tsks[0].Subject);
    } 
    
    static testMethod void DDSetupFailure_nullTSNumber(){
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.DDSetupFailure(null, '', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.NullParameterException);    
    }
    
    static testMethod void DDSetupFailure_nullFailureReason(){
        Exception ex;
 
        try{
            SubscriptionsWebservicesHandlers.DDSetupFailure('', null, '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);       
        System.assert(ex instanceof WebserviceUtil.NullParameterException);    
    }
    
    static testMethod void DDSetupFailure_success_digital(){
        setupDigitalAccountData();
        setupIncentiveData(null); 
        
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r); 
        
        SubscriptionsWebservicesHandlers.DDSetupFailure(r, 'FAIL', '');
        
        List<Account> accs = [SELECT Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :r];
        System.assertNotEquals(null,accs);
        System.assertNotEquals(0, accs.size());
        System.assertEquals('Inactive', accs[0].Subscriber_Digital_Status__c);
        
        List<Task> tasks = [SELECT WhatId, Subject FROM Task WHERE WhatId = :accs[0].Id];
       	System.assertNotEquals(null, tasks);
        System.assertNotEquals(0, tasks.size());
        System.assert(tasks[0].subject.startsWith('DD Setup Failure'));
    }
    
        
    static testMethod void DDSetupFailure_success_premium(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        setupDDData();
        paymentDetails.recurringDetails.paymentType = 'directbedit';
        
        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, ddDetails,contexParams).TSNumber;

        System.assertNotEquals(null, TSNumber);
        
        SubscriptionsWebservicesHandlers.DDSetupFailure(TSNumber, 'FAIL', '');
        
        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null,accs);
        System.assertNotEquals(0, accs.size());

        List<Subscription__c> subs = [SELECT Id FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        
        List<Task> tasks = [SELECT WhatId, Subject FROM Task WHERE WhatId = :subs[0].Id];
        System.assertNotEquals(null, tasks);
        System.assertNotEquals(0, tasks.size());
        System.assert(tasks[0].subject.startsWith('DD Setup Failure'));
    }
            
    static testMethod void DDSetupFailure_failure_nulltsnumber(){

        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.DDSetupFailure(null, 'FAIL', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
            
    static testMethod void DDSetupFailure_failure_nullfailurereason(){

        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.DDSetupFailure('tsnumber', null, '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }   
            
    static testMethod void DDSetupFailure_failure_unknowntsnumber(){

        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.DDSetupFailure('tsnumber', 'FAIL', '');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
    }   
            
    static testMethod void DDSetupFailure_success_nosubs(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        setupDDData();
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, ddDetails,contexParams).TSNumber;
        System.assertNotEquals(null, TSNumber);

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null,accs);
        System.assertNotEquals(0, accs.size());

        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id AND Subscription_Status__c = 'Pending'];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());

        subs[0].Subscription_Status__c = 'Offered';
        update subs[0];
        
        SubscriptionsWebservicesHandlers.DDSetupFailure(TSNumber, 'FAIL', '');
        List<Task> tasks = [SELECT WhatId, Subject FROM Task WHERE WhatId = :subs[0].Id];
        System.assertNotEquals(null, tasks);
        System.assertEquals(0, tasks.size());
    }       
    

    static testMethod void getActiveSubscriptionDetails_failure_noactivesub(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        setupDDData();
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, ddDetails,contexParams).TSNumber;
        System.assertNotEquals(null, TSNumber);
        
        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        
        subs[0].Subscription_Status__c = 'Offered';
        update subs[0];
        
        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.getActiveSubscriptionDetails(TSNumber);
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NoActiveSubscriptionException);      
        
    }
    
    static testMethod void getActiveSubscriptionDetails_failure_nulltsnumber(){
        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.getActiveSubscriptionDetails(null);
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
    }
    
    static testMethod void getActiveSubscriptionDetails_failure_unknowntsnumber(){
        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.getActiveSubscriptionDetails('frank');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);
    }   
    
    static testMethod void getActiveSubscriptionDetails_success(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        setupDDData();
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, ddDetails,contexParams).TSNumber;
        System.assertNotEquals(null, TSNumber);
        
        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c, Weekly_Price__c, End_Date__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending', subs[0].Subscription_Status__c);
        
        SubscriptionsWebservices.ActiveSubscription subDetails = SubscriptionsWebservicesHandlers.getActiveSubscriptionDetails(TSNumber);
        
        System.assertNotEquals(null, subDetails);
        //System.assertEquals(subs[0].Weekly_Price__c, );       
        
    }
    
    static testMethod void digitalSubscriptionEnded_failure_nulltsnumber(){
        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.digitalSubscriptionEnded(null);
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.NullParameterException);     
     }
     
    static testMethod void digitalSubscriptionEnded_failure_unknowntsnumber(){
        Exception ex;
        try{        
            SubscriptionsWebservicesHandlers.digitalSubscriptionEnded('frank');
        } catch(Exception e){
            ex = e;
        }
        
        System.assertNotEquals(null, ex);
        System.assert(ex instanceof WebserviceUtil.UnknownTSNumberException);       
     }
     
         
    static testMethod void digitalSubscriptionEnded_success(){
        setupDigitalAccountData();
        setupIncentiveData(null);
        
         //pp-2484 changes -- commented the below line
        //String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails);
        String r = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r); 


        SubscriptionsWebservicesHandlers.digitalSubscriptionEnded(r);
        
        List<Account> accs = [SELECT Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :r];
        System.assertNotEquals(null, accs);
        System.assertEquals(1, accs.size());
        System.assertEquals('Inactive', accs[0].Subscriber_Digital_Status__c);

        
     }
     
     static testMethod void testcreateSubscriberIncentive_success(){
        setupPremiumAccountData();
        setupIncentiveData(null);
        
        //pp-2484 changes -- commented the below line
        //String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails);
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);        

        List<Incentive__c> incentives = [SELECT Id FROM Incentive__c WHERE name = 'Incentive1'];
        System.assertNotEquals(null, incentives);
        System.assertNotEquals(0, incentives.size());
                
        SubscriptionsWebservicesHandlers.createSubscriberIncentive(r, null, incentives[0].Id);
        
        List<SubscriptionIncentiveAssociation__c> sia = [SELECT Id FROM SubscriptionIncentiveAssociation__c WHERE incentive__c = :incentives[0].Id];
        System.assertNotEquals(null, sia);
        System.assertNotEquals(0, sia.size());
        
        
     }
     
     static testMethod void testcreateSubscriberIncentive_unknowntsnumber(){
        setupIncentiveData(null);
                
        List<Incentive__c> incentives = [SELECT Id FROM Incentive__c WHERE name = 'Incentive1'];
        System.assertNotEquals(null, incentives);
        System.assertNotEquals(0, incentives.size());
        
        SubscriptionsWebservicesHandlers.createSubscriberIncentive('some rubbish', null, incentives[0].Id);
        
        List<SubscriptionIncentiveAssociation__c> sia = [SELECT Id FROM SubscriptionIncentiveAssociation__c WHERE incentive__c = :incentives[0].Id];
        System.assertNotEquals(null, sia);
        System.assertEquals(0, sia.size());
        
     }
     
     static testmethod void testdeletePOC_success(){
        setupIncentiveData(null);

        List<POC__c> pocs = [SELECT Id FROM POC__c WHERE POC_Id__c = '12345678'];
        System.assertNotEquals(null, pocs);
        System.assertNotEquals(0, pocs.size());
        
        SubscriptionsWebservicesHandlers.deletePOC('12345678');
        
        pocs = [SELECT Id FROM POC__c WHERE POC_Id__c = '12345678'];
        System.assertNotEquals(null, pocs);
        System.assertEquals(0, pocs.size());
     }
     
     
     static testmethod void testdeletePOC_failure_invalidPOC(){
        setupIncentiveData(null);

        List<POC__c> pocs = [SELECT Id FROM POC__c WHERE POC_Id__c = '12345678'];
        System.assertNotEquals(null, pocs);
        System.assertNotEquals(0, pocs.size());

        pocs = [SELECT Id FROM POC__c WHERE POC_Id__c = 'qqq'];
        System.assertNotEquals(null, pocs);
        System.assertEquals(0, pocs.size());
        
        SubscriptionsWebservicesHandlers.deletePOC('qqq');
        
        pocs = [SELECT Id FROM POC__c WHERE POC_Id__c = '12345678'];
        System.assertNotEquals(null, pocs);
        System.assertNotEquals(0, pocs.size());
     }
     
    /*************************************************************************************** 
    Date - unknown
    Version - 1.2
    Function - test MPP Failed Results is Valid
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         28/04/2016 //added SAM settings and ZProduct with Features
    Wiktor Czykin       1.2         21/03/2017 //differentiated email in update call
    ****************************************************************************************/
    static testMethod void testMPPFailedResults_Valid() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createZProductFeatures();
        SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult event;
        List<Account> accList = getMPPAccountData();
        List<SubscriptionsWebservices.FailedUserManageResult> resultSet = new List<SubscriptionsWebservices.FailedUserManageResult>();
        Set<String> accTSNumbers = new Set<String>();
        
        //Insert test accounts.
        insert accList;
        //Do we now have 20 accounts?
        System.assertEquals(accList.size(), MAX_ACCOUNTS);
        //Some sanity checking if emails don't match.
        System.assertNotEquals(accList[0].PersonEmail, accList[1].PersonEmail);
        
        //Build the result set.
        Integer iVar = 0;
        for(Account acc :accList){
            SubscriptionsWebservices.FailedUserManageResult response = new SubscriptionsWebservices.FailedUserManageResult();
            response.message = 'MPP Failed';
            response.tsNumber = acc.Subscriber_Number_static__c;
            response.firstName = 'amirxxxx';
            response.lastName = 'hafeezxxxx';
            response.emailAddress = 'amir.hafeez.valideeee'+iVar+'@mpp.com';
            accTSNumbers.add(response.tsNumber);
            resultSet.add(response);
            iVar++;
        }
        
        //Check if the result set matches that of the accounts.
        System.assertEquals(resultSet.size(), MAX_ACCOUNTS);
        
        //Now callout processFailedUserManageRequests.
        Test.startTest();
            event = SubscriptionsWebservices.processFailedMPPUserManageRequests(resultSet);
        Test.stopTest();
        
        //All the accounts details should have been reverted back and at least one task should be created.
        accList = [SELECT Id, FirstName, LastName, PersonEmail, Subscriber_Number_static__c, LastModifiedById, IsUsingMPP__c,
            (SELECT Subject, Description FROM Tasks WHERE Subject =:Constants.FAILED_USER_REQUEST_SUBJECT.replace('[System]', 'MPP')) 
            FROM Account WHERE Subscriber_Number_static__c IN :accTSNumbers];
        
        //Check if we have a valid list of accounts.
        System.assertEquals(accList.size(), MAX_ACCOUNTS);
            
        for(Account acc :accList){
            System.assertEquals(acc.FirstName, 'amirxxxx');
            System.assertEquals(acc.LastName, 'hafeezxxxx');
            System.assert(acc.PersonEmail.contains('amir.hafeez.valideeee'));
        }
    }
    /*************************************************************************************** 
    Date - unknown
    Version - 1.0
    Function - test MPP Failed Results is Valid
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         28/04/2016 //added SAM settings and ZProduct with Features
    ****************************************************************************************/
    static testMethod void testMPPFailedResults_InValid() 
    {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createZProductFeatures();
        SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult event;
        List<Account> accList = getMPPAccountData();
        List<SubscriptionsWebservices.FailedUserManageResult> resultSet = new List<SubscriptionsWebservices.FailedUserManageResult>();
        Map<Id, List<String>> oldFieldMap = new Map<Id, List<String>>();
        //Insert test accounts.
        insert accList;
        
        //Build the invalid result set.
        for(Account acc :accList){
            //Store the old emails for checking.
            oldFieldMap.put(acc.Id, new List<String>{acc.FirstName, acc.LastName, acc.PersonEmail});
            SubscriptionsWebservices.FailedUserManageResult response = new SubscriptionsWebservices.FailedUserManageResult();
            response.tsNumber = '12300@xxx';
            resultSet.add(response);
        }
        
        //Check if the result set matches that of the accounts.
        System.assertEquals(resultSet.size(), MAX_ACCOUNTS);
        
        //Now callout CWebserviceInterfaceResponse.processFailedMPPEmailResults.
        Test.startTest();
            event = SubscriptionsWebservices.processFailedMPPUserManageRequests(resultSet);
        Test.stopTest();
        
        //None of the tsnumbers should match so no change to the emails should be made or tasks being created.
        accList = [SELECT Id, FirstName, LastName, PersonEmail, Subscriber_Number_static__c, LastModifiedById, IsUsingMPP__c,
            (SELECT Subject, Description FROM Tasks WHERE Subject =:Constants.FAILED_USER_REQUEST_SUBJECT.replace('[System]', 'MPP')) 
            FROM Account WHERE Id IN :accList];
        
        //Check if we have a valid list of accounts.    
        System.assertEquals(accList.size(), MAX_ACCOUNTS);
            
        for(Account acc :accList){
            System.assertEquals(acc.FirstName, oldFieldMap.get(acc.Id)[0]);
            System.assertEquals(acc.LastName, oldFieldMap.get(acc.Id)[1]);
            System.assertEquals(acc.PersonEmail, oldFieldMap.get(acc.Id)[2]);
            System.assertEquals(acc.Tasks.size(), 0);
        }
        
        event = SubscriptionsWebservices.processFailedMPPUserManageRequests(null);
        System.assert(event != null);
    }  
    /*************************************************************************************** 
    Date - unknown
    Version - 1.0
    Function - test MPP Failed Results is Valid
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         28/04/2016 //added SAM settings and ZProduct with Features
    ****************************************************************************************/
    static testMethod void testAssignMPPFields(){

        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createZProductFeatures();
        List<Account> accList = new List<Account>();
        List<Subscription__c> subList = new List<Subscription__c>();
        Map<String, SubscriptionsWebservices.MPPRecurringInfo> infoMap = new Map<String, SubscriptionsWebservices.MPPRecurringInfo>();
        
        for(Account acc :getMPPAccountData()){
            acc.RecordTypeId = Constants.IndivSubscriberRecordType();
            acc.IsUsingMPP__c=false;
            accList.add(acc);
        }
        insert accList;
        
        Integer i = 0;
        for(Account acc :accList){
            i++;
            Subscription__c subscription = new Subscription__c();
            subscription.Subscriber__c = acc.Id;
            subscription.Last_Status_Change__c = Date.today().addDays(-1);
            subscription.Subscription_Status__c = 'Pending';
            subscription.Is_MPP_DDCCA_Letter_Extracted__c = false;
            subscription.Start_Date__c = Date.today().addDays(21).toStartOfWeek();
            subscription.Payment_Details_Received__c = true;
            subscription.Weekly_Price__c = 6.50;
            subscription.Payment_Type__c = (Math.mod(i, 2) == 0 ? 'CreditDebitCard' : 'DirectDebit');
            subscription.Delivery_Type__c = 'OTC';
            subscription.Voucher_Pack_Duration__c = 14;
            subscription.Subscription_Duration_Picklist__c = '52';
            subscription.MPP_Premium_Subscription_ID__c = '001' + i;
            subscription.MPP_DD_Next_Payment_Date__c = null;
            if(subscription.Payment_Type__c.equalsIgnoreCase('DirectDebit'))
                subscription.IsContinuous__c=true;
            
            SubscriptionsWebservices.MPPRecurringInfo info = new SubscriptionsWebservices.MPPRecurringInfo();
            info.premiumSubscriptionID = subscription.MPP_Premium_Subscription_ID__c;
            info.firstPaymentAmount = 200.00;
            info.frequency = '15';
            info.nextPaymentDate = Date.newInstance(2015,8,15);
            info.paymentType = subscription.Payment_Type__c;
            infoMap.put(info.premiumSubscriptionID, info);
            subList.add(subscription);
        }
        insert subList;
        
        List<Subscription__c> subsToUpdate = new List<Subscription__c>();
        for(Subscription__c a :subList){
            a.Payment_Type__c = null;
            a.IsContinuous__c=true;            
            subsToUpdate.add(SubscriptionsWebservicesHandlers.setMPPSubscriptionFields(a, infoMap.get(a.MPP_Premium_Subscription_ID__c)));
            a.Payment_Type__c = infoMap.get(a.MPP_Premium_Subscription_ID__c).paymentType;
        }
        
        Test.startTest();
            update subsToUpdate;
        Test.stopTest();
        
        subsToUpdate = [SELECT Id, MPP_Premium_Subscription_ID__c, MPP_CC_First_Payment_Amount__c, MPP_CC_Frequency__c, MPP_CC_Next_Payment_Date__c,
            Payment_Type__c, MPP_DD_First_Payment_Amount__c, MPP_DD_Frequency__c, MPP_DD_Next_Payment_Date__c, MPP_Pay_Schedule_Start_Date__c, MPP_Pay_Schedule_End_Date__c FROM Subscription__c WHERE Id IN :subsToUpdate];
            
        System.assertEquals(subsToUpdate.size(), MAX_ACCOUNTS);
        
        for(Subscription__c a :subsToUpdate){
            if(a.Payment_Type__c == 'CreditDebitCard'){
                System.assertEquals(a.MPP_CC_First_Payment_Amount__c, 200.00);
                System.assertEquals(a.MPP_CC_Frequency__c, '15');
                System.assertEquals(a.MPP_CC_Next_Payment_Date__c, Date.newInstance(2015,8,15));
            }
            else if(a.Payment_Type__c == 'DirectDebit'){
                System.assertEquals(a.MPP_DD_First_Payment_Amount__c, 200.00);
                System.assertEquals(a.MPP_DD_Frequency__c, '15');
                System.assertEquals(a.MPP_DD_Next_Payment_Date__c, Date.newInstance(2015,8,15));
                System.assertEquals(a.MPP_Pay_Schedule_Start_Date__c, Date.newInstance(2015,8,15));
                System.assertEquals(a.MPP_Pay_Schedule_End_Date__c, Date.newInstance(2016,8,15));
            }
        }
    }
        
    private static testMethod void createAUUDISTransactionHistory_UnknownTSNumber(){
        Exception ex;
        
        try{
            SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord('', null, new SubscriptionsWebservices.DirectDebitInfo());
        } catch(Exception e){
            ex = e;
        }
        
        setupPremiumAccountData();
        setupIncentiveData(null);
        setupPremiumPaymentData();
        setupDDData();
        paymentDetails.recurringDetails.paymentType = 'directbedit';
        
        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, ddDetails,contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        List<Subscription__c> subs = [SELECT Id FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        try{
            SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(false, '',null,ddDetails);
        } catch(Exception e){
            ex = e;
        }
        
        try{
            SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(false, TSNumber,null,ddDetails);
        } catch(Exception e){
            ex = e;
        }
        try{
            SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber,ddDetails,paymentDetails);
        } catch(Exception e){
            ex = e;
        }
        try{
            SubscriptionsWebservicesHandlers.createAUDDISTransactionHistoryRecord(TSNumber,null,paymentDetails);
        } catch(Exception e){
            ex = e;
        }
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/09/2015  //removed getPriceByTCode() references, removed getTCodeDetailsByPromoName() reference
    Wiktor Czykin   1.2         23/02/2016  //removed insertTCodeManagement()
    ****************************************************************************************/
    private static testMethod void testMethodCoverage(){
    	TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();

        tdu.createTCodeManagement();
        tdu.lstTCodeManagement[0].Name = '445T';
        tdu.lstTCodeManagement[0].Type__c = Constants.TCODE_TYPE_OPENOFFER;
        update tdu.lstTCodeManagement;

        TCodeManagement__c tcodeRec = new TCodeManagement__c();
        tcodeRec.Price__c=5; //For Premium/Print
        tcodeRec.Digital_Monthly_Price__c=20;
        tcodeRec.Digital_Yearly_Price__c=210;
        tcodeRec.Web_Pack_Monthly_Price__c=25;
        tcodeRec.Web_Pack_Yearly_Price__c=250;
        tcodeRec.type__c = '000M';
        tcodeRec.Name = '000M';
        tcodeRec.Description__c='Test desc';
        insert tcodeRec;
        
        SubscriptionsWebservicesHandlers.calculateSavingOnCoverPrice(1.2, 5,26);
        
        //Create Account
        Account acc = new Account();
        acc.Title__c = 'Mr.';
        acc.FirstName = 'TestFirstName';
        acc.LastName = 'TestLastName';
        acc.PersonEmail = 'abc.xyz.tmg.test@test.com';
        acc.PersonMailingPostalCode = 'E11 1JY';
        insert acc;
        
        acc = [select Subscriber_Number__c from Account where id =:acc.id];

        //Create Subscription
        Subscription__c sub1 = new Subscription__c();
        sub1.Subscriber__c = acc.Id;
        sub1.Last_Status_Change__c = Date.today().addDays(-1);
        sub1.Subscription_Status__c = 'Lapsed';
        sub1.Is_MPP_DDCCA_Letter_Extracted__c = false;
        sub1.Start_Date__c = Date.today().addDays(21).toStartOfWeek();
        sub1.Payment_Details_Received__c = true;
        sub1.Weekly_Price__c = 6.50;
        sub1.Payment_Type__c = 'DirectDebit';
        sub1.Delivery_Type__c = 'OTC';
        sub1.Voucher_Pack_Duration__c = 14;
        sub1.MPP_Premium_Subscription_ID__c = '0011'; 
        sub1.MppDDCalloutStage__c='User Manage';
        sub1.MppDDCalloutAttemptCount__c=5;
        insert sub1;   
        
         //Create Subscription
        Subscription__c sub2 = new Subscription__c();
        sub2.Subscriber__c = acc.Id;
        sub2.Last_Status_Change__c = Date.today().addDays(-1);
        sub2.Subscription_Status__c = 'Pending';
        sub2.Is_MPP_DDCCA_Letter_Extracted__c = false;
        sub2.Start_Date__c = Date.today().addMonths(1).toStartOfWeek();
        sub2.Payment_Details_Received__c = true;
        sub2.Weekly_Price__c = 6.50;
        sub2.Previous_Subscription__c=sub1.id;
        sub2.Payment_Type__c = 'DirectDebit';
        sub2.Delivery_Type__c = 'OTC';
        sub2.Voucher_Pack_Duration__c = 14;
        insert sub2;       
        
        List<SubscriptionsWebservices.FailedMPPBulkResult> lstDDFailure = new List<SubscriptionsWebservices.FailedMPPBulkResult>();
        SubscriptionsWebservices.FailedMPPBulkResult recFailure = new SubscriptionsWebservices.FailedMPPBulkResult();
        recFailure.tsNumber=acc.Subscriber_Number__c;
        recFailure.subject='Failed';
        recFailure.message='Failure';
        recFailure.status='Fail';
        lstDDFailure.add(recFailure);
        
        SubscriptionsWebservicesHandlers.updateFailedDirectDebitRequests('MPP', lstDDFailure);
        
        sub2.MppDDCalloutStage__c='User Manage';
        update sub2;
        
        SubscriptionsWebservicesHandlers.updateFailedPaymentScheduleRequests(null, 'MPP', lstDDFailure);
        
        sub2.Subscription_Status__c = 'In Renewal';
        sub2.Iscontinuous__c=true;
        update sub2;
        
        //Create Subscription
        Subscription__c OfferedSub = new Subscription__c();
        Offeredsub.Subscriber__c = acc.Id;
        Offeredsub.Last_Status_Change__c = Date.today().addDays(-1);
        Offeredsub.Subscription_Status__c = 'Offered';
        Offeredsub.Is_MPP_DDCCA_Letter_Extracted__c = false;
        Offeredsub.Start_Date__c = Date.today().addYears(2).toStartOfWeek();
        Offeredsub.Payment_Details_Received__c = true;
        Offeredsub.Weekly_Price__c = 6.50;
        Offeredsub.Payment_Type__c = 'DirectDebit';
        Offeredsub.Delivery_Type__c = 'OTC';
        Offeredsub.Voucher_Pack_Duration__c = 14;
        Offeredsub.MPP_Premium_Subscription_ID__c = '0011'; 
        Offeredsub.MppDDCalloutStage__c='User Manage';
        Offeredsub.MppDDCalloutAttemptCount__c=5;
        Offeredsub.Previous_Subscription__c = sub2.id;
        Offeredsub.Subscription_Duration_Picklist__c='26';
        insert OfferedSub;  
                
               
        SubscriptionsWebservicesHandlers.getRenewalOffer(acc.Subscriber_Number__c);
        
        Offeredsub.Subscription_Status__c = 'Pending';
        update OfferedSub;
        SubscriptionsWebservicesHandlers.getActiveAndRenewedSubscriptionDetails(acc.Subscriber_Number__c,'E11 1JY');
        
        sub2.Subscription_Status__c = 'Lapsed';
        sub2.Current_Week_Position_Final__c=26;
        update sub2;
        SubscriptionsWebservicesHandlers.getLapsedSubscriptionDetails(acc.Subscriber_Number__c);
        
        SubscriptionsWebservices.Subscription webSub = new SubscriptionsWebservices.Subscription();
        websub.paymentDate=System.today().addMonths(1);
        websub.paymentType='creditdebitcard';
        websub.productType='premium';
        websub.subscriptionType='82';
        websub.startDate=Offeredsub.Start_Date__c;
        
        SubscriptionsWebservices.MPPRecurringInfo webRecur = new SubscriptionsWebservices.MPPRecurringInfo();
        webRecur.PaymentType='creditdebitcard';
        
        SubscriptionsWebservicesHandlers.updateSubscription(Offeredsub.id, webSub, webRecur,true);
        
        SubscriptionsWebservicesHandlers.getTCode('123456789','pocflow','445T');
        SubscriptionsWebservicesHandlers.getTCode('123456789','openofferflow','445T');
        
        List<Account> accList=[select Guid__c from Account limit 3];
        List<String> samGUIDs =  new List<String>();
        for(Account acc1 : accList){
            samGUIDs.add(acc1.Guid__c);
        }          
        if(!samGUIDs.isEmpty()){
            samGUIDs.clear();
        }
        SubscriptionsWebservicesHandlers.clearDigitalEntitlements(samGUIDs,'Test newEntitlement');
        SubscriptionsWebservicesHandlers.getPricingOptionsByServiceIDs('123456','987654','promo Name');
        SubscriptionsWebservicesHandlers.getPricingOptionByName('PO-0496');
    }
    
    private static testMethod void testupdateUsageTrackingData(){
        setupDigitalAccountData();
        setupIncentiveData(null); 
       
        String Tsnumber = SubscriptionsWebservicesHandlers.createSubscriber(digitalSubscriberDetails,paymentDetails,digitalSubscriptionDetails,recurringDetails);
        DigitalUpdateWebservices.DeviceInfo device = new DigitalUpdateWebservices.DeviceInfo();
        device.deviceid='1213';
        device.deviceName='Samsung Galaxy';
        device.deviceType='Mobile';
        device.deviceOS='Andriod';
        
        DigitalUpdateWebservices.AppInfo app1=new DigitalUpdateWebservices.AppInfo();
        app1.appName='app1';
        app1.appVersion='v1';
        
        List<DigitalUpdateWebservices.AppInfo> appList=new List<DigitalUpdateWebservices.AppInfo>();
        appList.add(app1);
        device.apps=appList;
        
        DigitalUpdateWebservices.EntitlementDetails entitlement=new DigitalUpdateWebservices.EntitlementDetails();
        entitlement.entitlementIdentifier='abc';
        entitlement.entitlementType='xyz';
        
        Datetime dateTimetemp = System.now();
        SubscriptionsWebservicesHandlers.updateUsageTrackingData(Tsnumber,device,entitlement,dateTimetemp);
    }    
    
   
	public static testMethod void getTCodeForPOCTest_Success(){
		TCodeManagement__c tcm = new TCodeManagement__c();
		tcm.Name = 'XX99';
		tcm.Type__c = 'Test';
		tcm.Description__c = 'Test';
		insert tcm;
		
		POC__c poc = new POC__c();
		poc.POC_Id__c = 'Test';
		poc.TCodeManagement__c = tcm.Id;
		poc.LastName__c = 'Smith';
		poc.PostalCode__c = 'SW1A 1AA';
		insert poc;
		Test.startTest();
		  SubscriptionsWebservices.Tcode result = SubscriptionsWebservicesHandlers.getTCodeForPOC(poc.POC_Id__c);
		  System.assertEquals('XX99', result.tCode);
        Test.stopTest();
	}
	
	public static testMethod void getTCodeForPOCTest_Fail1(){
		Test.startTest();
            SubscriptionsWebservices.Tcode result = SubscriptionsWebservicesHandlers.getTCodeForPOC(null);
            System.assertEquals(null, result);
        Test.stopTest();
		WebService_Log__c[] log = [select id, Parameters__c from WebService_Log__c];
		System.assertEquals(1, log.size());
	}
	
	public static testMethod void getTCodeForPOCTest_Fail2(){
		Test.startTest();
            SubscriptionsWebservices.Tcode result = SubscriptionsWebservicesHandlers.getTCodeForPOC('Banana');
            System.assertEquals(null, result);
        Test.stopTest();
		WebService_Log__c[] log = [select id, Parameters__c from WebService_Log__c];
		System.assertEquals(1, log.size());
	}

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 24/06/2015
    Version - 1.0
    Function - test added to increase coverage of updateSuccessPaymentScheduleSetup()
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void  testUpdateSuccessPaymentScheduleSetup(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkSubscriptionDependencies();
        WebService_Log__c wlInitial = new WebService_Log__c();
        insert wlInitial;
        Subscription__c subscription = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subscription.MppDDCalloutStage__c = 'someStage';
        subscription.IsContinuous__c = true;
        insert subscription;

        List<Account> lstAccount = [select Id, Subscriber_Number__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assertEquals(1, lstAccount.size());

        SubscriptionsWebservices.PaymentSchedules paymentSchedule = new SubscriptionsWebservices.PaymentSchedules();
        paymentSchedule.startDate = Datetime.now();
        paymentSchedule.paymentDate = Datetime.now();
        paymentSchedule.endDatePaymentSchedule = Datetime.now().addYears(1);
        paymentSchedule.totalAmount = 10.04;
        paymentSchedule.frequency = Constants.DD_COL_FREQ_MONTHLY;
        paymentSchedule.TSNumber = lstAccount[0].Subscriber_Number__c; 
        paymentSchedule.paymentScheduleId = '1234'; 
        
        SubscriptionsWebservices.PaymentOrders payOrders = new SubscriptionsWebservices.PaymentOrders();
        payOrders.orderId = null;
        payOrders.orderDate = Datetime.now();
        payOrders.amount = 3.00; 
        payOrders.status = null; 
        payOrders.paymentType = null; 
        
        paymentSchedule.paymntOrders = payOrders;
        
        List<SubscriptionsWebservices.PaymentSchedules> lstPaymentSchedules = new List<SubscriptionsWebservices.PaymentSchedules>();
        lstPaymentSchedules.add(paymentSchedule);
        
        Test.startTest();
            SubscriptionsWebservicesHandlers.updateSuccessPaymentScheduleSetup(wlInitial.Id, lstPaymentSchedules);
        Test.stopTest();

        List<Subscription__c> lstSubscription = [select Id, 
                                                        Subscription_Status__c, 
                                                        MPP_Pay_Schedule_Start_Date__c, 
                                                        MPP_Pay_Schedule_End_Date__c, 
                                                        MPP_Premium_Subscription_ID__c, 
                                                        MppDDCalloutStage__c
                                                    from Subscription__c where Id = :subscription.Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertEquals(paymentSchedule.startDate, lstSubscription[0].MPP_Pay_Schedule_Start_Date__c);
        System.assertEquals(TMGDateExtension.getPaymentCollectionDate(paymentSchedule.endDatePaymentSchedule.date()), lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(paymentSchedule.paymentScheduleId, lstSubscription[0].MPP_Premium_Subscription_ID__c);
        System.assertEquals(Constants.SSTATUS_PENDING, lstSubscription[0].Subscription_Status__c);
        System.assertEquals(Constants.MPP_DDCALLOUT_STAGE_4, lstSubscription[0].MppDDCalloutStage__c );
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 24/06/2015
    Version - 1.0
    Function - check that Account update succeeds even if Subscription update fails
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void  testUpdateSuccessPaymentScheduleSetupFailureOfSubscriptionUpdate(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkSubscriptionDependencies();
        WebService_Log__c wlInitial = new WebService_Log__c();
        insert wlInitial;
        Subscription__c subscription = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subscription.MppDDCalloutStage__c = 'someStage';
        subscription.Payment_Type__c = Constants.SUB_PMETHOD_CC;
        insert subscription;

        List<Subscription__c> lstSub = [select MPP_Pay_Schedule_Start_Date__c from Subscription__C where Id = :subscription.Id];
        System.assertEquals(null, lstSub[0].MPP_Pay_Schedule_Start_Date__c);

        List<Account> lstAccount = [select Id, IsUsingMPP__c, Subscriber_Number__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assertEquals(1, lstAccount.size());
        System.assert(!lstAccount[0].IsUsingMPP__c);
        SubscriptionsWebservices.PaymentSchedules paymentSchedule = new SubscriptionsWebservices.PaymentSchedules();
        paymentSchedule.startDate = Datetime.now();
        paymentSchedule.paymentDate = Datetime.now();
        paymentSchedule.endDatePaymentSchedule = Datetime.now().addYears(1);
        paymentSchedule.totalAmount = null;
        paymentSchedule.frequency = Constants.DD_COL_FREQ_QUARTERLY;
        paymentSchedule.TSNumber = lstAccount[0].Subscriber_Number__c; 
        paymentSchedule.paymentScheduleId = '1234'; 
        
        SubscriptionsWebservices.PaymentOrders payOrders = new SubscriptionsWebservices.PaymentOrders();
        payOrders.orderId = null;
        payOrders.orderDate = Datetime.now();
        payOrders.amount = 3.00; 
        payOrders.status = null; 
        payOrders.paymentType = null; 
        
        paymentSchedule.paymntOrders = payOrders;
        
        List<SubscriptionsWebservices.PaymentSchedules> lstPaymentSchedules = new List<SubscriptionsWebservices.PaymentSchedules>();
        lstPaymentSchedules.add(paymentSchedule);
        SubscriptionsWebservicesHandlers.TESTFAILSUBSCRIPTION_ALL = true;
        Test.startTest();
            SubscriptionsWebservicesHandlers.updateSuccessPaymentScheduleSetup(wlInitial.Id, lstPaymentSchedules);
        Test.stopTest();
        //check that account was updated
        lstAccount = [select Id, IsUsingMPP__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(lstAccount[0].IsUsingMPP__c);

        //check that subscription was not updated
        List<Subscription__c> lstSubscription = [select Id, 
                                                        Subscription_Status__c, 
                                                        MPP_Pay_Schedule_Start_Date__c, 
                                                        MPP_Pay_Schedule_End_Date__c, 
                                                        MPP_Premium_Subscription_ID__c, 
                                                        MppDDCalloutStage__c
                                                    from Subscription__c where Id = :subscription.Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertEquals(null, lstSubscription[0].MPP_Pay_Schedule_Start_Date__c);
        System.assertEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(null, lstSubscription[0].MPP_Premium_Subscription_ID__c);
        System.assertEquals(Constants.SSTATUS_OFFERED, lstSubscription[0].Subscription_Status__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 24/06/2015
    Version - 1.0
    Function - check that partial save works when one of the Accounts fails to update
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void  testUpdateSuccessPaymentScheduleSetupPartialFailureOfAccountUpdate(){
        TestDataUtility td = new TestDataUtility(2);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkSubscriptionDependencies();
        WebService_Log__c wlInitial = new WebService_Log__c();
        insert wlInitial;
        Subscription__c subscription = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subscription.MppDDCalloutStage__c = 'someStage';
        subscription.IsContinuous__c = true;
        Subscription__c subscription2 = TestDataUtility.newSubscripiton(1, td.lstIndividualSubscribers[1].Id, td.lstRetailers[1].Id, null);
        subscription2.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subscription2.MppDDCalloutStage__c = 'someStage';
        subscription2.IsContinuous__c = true;

        List<Subscription__c> lstSubscriptions = new List<Subscription__c>{subscription, subscription2};
        insert lstSubscriptions;

        Map<Id, Account> mapAccount = new Map<Id, Account>([select Id, IsUsingMPP__c, Subscriber_Number__c from Account where Id in :td.lstIndividualSubscribers]);
        System.assertEquals(td.iCounter, mapAccount.size());
       
        List<SubscriptionsWebservices.PaymentSchedules> lstPaymentSchedules = new List<SubscriptionsWebservices.PaymentSchedules>();


        SubscriptionsWebservices.PaymentOrders payOrders = new SubscriptionsWebservices.PaymentOrders();
        payOrders.orderId = null;
        payOrders.orderDate = Datetime.now();
        payOrders.amount = 3.00; 
        payOrders.status = null; 
        payOrders.paymentType = null; 

        for(Account acc : td.lstIndividualSubscribers){
            System.assert(!acc.IsUsingMPP__c);

            SubscriptionsWebservices.PaymentSchedules paymentSchedule = new SubscriptionsWebservices.PaymentSchedules();
            paymentSchedule.startDate = Datetime.now();
            paymentSchedule.paymentDate = Datetime.now();
            paymentSchedule.endDatePaymentSchedule = Datetime.now().addYears(1);
            paymentSchedule.totalAmount = null;
            paymentSchedule.frequency = Constants.DD_COL_FREQ_QUARTERLY;
            paymentSchedule.TSNumber = mapAccount.get(acc.Id).Subscriber_Number__c; 
            paymentSchedule.paymentScheduleId = '1234'; 
            paymentSchedule.paymntOrders = payOrders;
            lstPaymentSchedules.add(paymentSchedule);

        }
        Test.startTest();
            SubscriptionsWebservicesHandlers.TESTFAILACCOUNT_LAST = true;
            SubscriptionsWebservicesHandlers.updateSuccessPaymentScheduleSetup(wlInitial.Id, lstPaymentSchedules);
        Test.stopTest();
        //check that account was updated
        mapAccount = new Map<Id, Account>([select Id, IsUsingMPP__c from Account where Id in :td.lstIndividualSubscribers]);
        System.assertEquals(td.iCounter, mapAccount.size());
        System.assert(mapAccount.get(td.lstIndividualSubscribers[0].Id).IsUsingMPP__c, mapAccount.get(td.lstIndividualSubscribers[0].Id));
        System.assert(!mapAccount.get(td.lstIndividualSubscribers[1].Id).IsUsingMPP__c, mapAccount.get(td.lstIndividualSubscribers[1].Id));

        //check that subscription was not updated
        Map<Id, Subscription__c> mapSubscription = new Map<Id,Subscription__c>([select  Id, 
                                                                                        Subscription_Status__c, 
                                                                                        MPP_Pay_Schedule_Start_Date__c, 
                                                                                        MPP_Pay_Schedule_End_Date__c, 
                                                                                        MPP_Premium_Subscription_ID__c, 
                                                                                        MppDDCalloutStage__c
                                                                                    from Subscription__c 
                                                                                    where Id in :lstSubscriptions]);
        System.assert(!mapSubscription.isEmpty() && mapSubscription.size() == td.iCounter);
        System.assertEquals(null, mapSubscription.get(subscription2.Id).MPP_Pay_Schedule_Start_Date__c);
        System.assertEquals(null, mapSubscription.get(subscription2.Id).MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(null, mapSubscription.get(subscription2.Id).MPP_Premium_Subscription_ID__c);
        System.assertEquals(Constants.SSTATUS_OFFERED, mapSubscription.get(subscription2.Id).Subscription_Status__c);

        System.assertEquals(lstPaymentSchedules[0].paymentScheduleId, mapSubscription.get(subscription.Id).MPP_Premium_Subscription_ID__c,mapSubscription.get(subscription.Id));
        System.assertEquals(Constants.SSTATUS_PENDING, mapSubscription.get(subscription.Id).Subscription_Status__c);
        System.assertEquals(Constants.MPP_DDCALLOUT_STAGE_4, mapSubscription.get(subscription.Id).MppDDCalloutStage__c );
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 06/08/2015
    Version - 1.0
    Function -  Check that order taken fields on account are set only when payment details are passed in. 
                Added extra assertions for other parameters within setAccountFields()
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void testSetSubscriberFieldsOrderTakenChange(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.createZProduct();
        td.createTCodeProducts();
        td.createPricingOptions(Constants.PRICING_WEBPACK_TYPE);
        List<Pricing_Options__c> lstPricingOption = [select Name from Pricing_Options__c where Id =:td.mapPricingOptions.get(0)[0].Id];
        System.assert(!lstPricingOption.isEmpty());

        Account digitalAccount = TestDataUtility.newPersonAccount(1, RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName()));
        digitalAccount.Guid__c = 'this-is-an-old-guid-12345';
        digitalAccount.Promotion_Name__c = 'somePromotionName';
        digitalAccount.Promo_Code_Expiry_Date__c = Date.today().addDays(-2);
        digitalAccount.Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE;
        digitalAccount.Cancellation_Type__c = 'someValue';
        digitalAccount.Cancelled_By__c = UserInfo.getUserId();
        digitalAccount.Cancelled_Date__c = Date.today();
        insert digitalAccount;

        List<Account> lstAccountRefetched = [select Id, Subscriber_Number__c from Account where Id =:digitalAccount.Id];
        System.assert(!lstAccountRefetched.isEmpty());
        SubscriptionsWebservices.Subscriber subscriber = new SubscriptionsWebservices.Subscriber();
        subscriber.subscriberType = 'digital';
        subscriber.digitalSubscriberStatus = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        subscriber.title = 'Master';
        subscriber.firstName = 'Jabba';
        subscriber.lastName = 'the Hut';
        subscriber.personalEmail = 'testemail11@telegraph.co.uk';
        subscriber.street = 'Buckingham Road';
        subscriber.city = 'London';
        subscriber.mobilePhone = '11234567890';
        subscriber.homePhone = '3123213213';
        subscriber.TSNumber = lstAccountRefetched[0].Subscriber_Number__c;
        subscriber.GUID = 'this-is-a-guid-12345';
        subscriber.PricingOptionID = lstPricingOption[0].Name;
        subscriber.token = new DealWebservice.Token('xxx','xxx');
        SubscriptionsWebservices.Payment payment = new SubscriptionsWebservices.Payment();
        payment.paymentDate = Date.today();
        payment.digitalSubscriptionID = '12345';
        subscriber.productId = td.lstZproducts[0].Id;
        subscriber.isPrint = false;

        Test.startTest();   
            Account accountAfter = SubscriptionsWebservicesHandlers.setAccountFields(digitalAccount.clone(true,true), subscriber, payment, null, null);
        Test.stopTest();
        System.assertEquals(subscriber.GUID, accountAfter.Guid__c);
        System.assertEquals(null, accountAfter.Cancellation_Type__c);
        System.assertEquals(null, accountAfter.Cancelled_By__c);
        System.assertEquals(null, accountAfter.Cancelled_Date__c);
        System.assertEquals(subscriber.digitalSubscriberStatus, accountAfter.Subscriber_Digital_Status__c);
        System.assertEquals(digitalAccount.Promo_Code_Expiry_Date__c, accountAfter.previous_Promo_Code_Expiry_Date__c);
        System.assertEquals(digitalAccount.Promotion_Name__c, accountAfter.previous_Promotion_Name__c);
        System.assertEquals(null, accountAfter.Promo_Code_Expiry_Date__c);
        System.assertEquals(null, accountAfter.Promotion_Name__c);
        System.assertEquals(null, accountAfter.Promo_Code__c);
        System.assertEquals(td.mapPricingOptions.get(0)[0].Id, accountAfter.Pricing_Option__c);
        System.assertEquals(subscriber.firstName, accountAfter.FirstName);
        System.assertEquals(subscriber.lastName, accountAfter.LastName);
        System.assertEquals(subscriber.personalEmail, accountAfter.PersonEmail);
        System.assertEquals(Date.today(), accountAfter.Order_Taken_Date__c);
        System.assertEquals(Label.Webservices_TMG, accountAfter.Order_Taken_By_Company__c);
        System.assertEquals(Label.Webservices_Online_user_department, accountAfter.Order_Taken_By_User_Department__c);
        System.assertEquals(Label.Webservices_Order_taken_method_online, accountAfter.Order_Taken_Method__c);
        System.assertEquals(payment.digitalSubscriptionID, accountAfter.MPP_Digital_Payment_Id__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 06/08/2015
    Version - 1.0
    Function -  Check that order taken fields on account are set only when payment details are passed in - negative (fields not set) 
                Added extra assertions for other parameters within setAccountFields()
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void testSetSubscriberFieldsOrderTakenNoChange(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.createZProduct();
        td.createTCodeProducts();
        td.createPricingOptions(Constants.PRICING_WEBPACK_TYPE);
        List<Pricing_Options__c> lstPricingOption = [select Name from Pricing_Options__c where Id =:td.mapPricingOptions.get(0)[0].Id];
        System.assert(!lstPricingOption.isEmpty());

        Account digitalAccount = TestDataUtility.newPersonAccount(1, RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName()));
        digitalAccount.Guid__c = 'this-is-an-old-guid-12345';
        digitalAccount.Promotion_Name__c = 'somePromotionName';
        digitalAccount.Promo_Code_Expiry_Date__c = Date.today().addDays(-2);
        digitalAccount.Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_INACTIVE;
        digitalAccount.Cancellation_Type__c = 'someValue';
        digitalAccount.Cancelled_By__c = UserInfo.getUserId();
        digitalAccount.Cancelled_Date__c = Date.today();
        insert digitalAccount;

        List<Account> lstAccountRefetched = [select Id, Subscriber_Number__c from Account where Id =:digitalAccount.Id];
        System.assert(!lstAccountRefetched.isEmpty());
        SubscriptionsWebservices.Subscriber subscriber = new SubscriptionsWebservices.Subscriber();
        subscriber.subscriberType = 'digital';
        subscriber.digitalSubscriberStatus = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        subscriber.title = 'Master';
        subscriber.firstName = 'Jabba';
        subscriber.lastName = 'the Hut';
        subscriber.personalEmail = 'testemail11@telegraph.co.uk';
        subscriber.street = 'Buckingham Road';
        subscriber.city = 'London';
        subscriber.mobilePhone = '11234567890';
        subscriber.homePhone = '3123213213';
        subscriber.TSNumber = lstAccountRefetched[0].Subscriber_Number__c;
        subscriber.GUID = 'this-is-a-guid-12345';
        subscriber.PricingOptionID = lstPricingOption[0].Name;
        subscriber.token = new DealWebservice.Token('xxx','xxx');
        subscriber.productId = td.lstZproducts[0].Id;
        subscriber.isPrint = false;

        Test.startTest();   
            Account accountAfter = SubscriptionsWebservicesHandlers.setAccountFields(digitalAccount.clone(true,true), subscriber, null, null, null);
        Test.stopTest();
        System.assertEquals(subscriber.GUID, accountAfter.Guid__c);
        System.assertEquals(null, accountAfter.Cancellation_Type__c);
        System.assertEquals(null, accountAfter.Cancelled_By__c);
        System.assertEquals(null, accountAfter.Cancelled_Date__c);
        System.assertEquals(subscriber.digitalSubscriberStatus, accountAfter.Subscriber_Digital_Status__c);
        System.assertEquals(digitalAccount.Promo_Code_Expiry_Date__c, accountAfter.previous_Promo_Code_Expiry_Date__c);
        System.assertEquals(digitalAccount.Promotion_Name__c, accountAfter.previous_Promotion_Name__c);
        System.assertEquals(null, accountAfter.Promo_Code_Expiry_Date__c);
        System.assertEquals(null, accountAfter.Promotion_Name__c);
        System.assertEquals(null, accountAfter.Promo_Code__c);
        System.assertEquals(td.mapPricingOptions.get(0)[0].Id, accountAfter.Pricing_Option__c);
        System.assertEquals(subscriber.firstName, accountAfter.FirstName);
        System.assertEquals(subscriber.lastName, accountAfter.LastName);
        System.assertEquals(subscriber.personalEmail, accountAfter.PersonEmail);
        System.assertEquals(null, accountAfter.Order_Taken_Date__c);
        System.assertEquals(null, accountAfter.Order_Taken_By_Company__c);
        System.assertEquals(null, accountAfter.Order_Taken_By_User_Department__c);
        System.assertEquals(null, accountAfter.Order_Taken_Method__c);
        System.assertEquals(null, accountAfter.MPP_Digital_Payment_Id__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 06/08/2015
    Version - 1.0
    Function - test that record type is not changed for Registrant record type when first clarity calls sfdc with digital subscription type
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void testRegistrantRecordTypeIsNotOverridenByDigitalOnDigitalSub(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkAccountDependencies();
        td.CreateCoreApiEndPointSettings();
        td.createFireAccountCreationCustomSetting(true);
        td.createZProduct();
        td.createTCodeProducts();
        Account digitalAccount = TestDataUtility.newPersonAccount(1, RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()));
        digitalAccount.Guid__c = 'this-is-an-old-guid-12345';
        digitalAccount.Subscriber_Digital_Status__c = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        insert digitalAccount;

        List<Account> lstAccountRefetched = [select Id, Subscriber_Number__c from Account where Id =:digitalAccount.Id];
        System.assert(!lstAccountRefetched.isEmpty());
        SubscriptionsWebservices.Subscriber subscriber = new SubscriptionsWebservices.Subscriber();
        subscriber.subscriberType = Constants.PRODUCT_DIGITAL.toLowerCase();
        subscriber.digitalSubscriberStatus = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
        subscriber.personalEmail = 'testemail11@telegraph.co.uk';
        subscriber.TSNumber = lstAccountRefetched[0].Subscriber_Number__c;
        subscriber.GUID = 'this-is-a-guid-12345';
        subscriber.productId = td.lstZproducts[0].Id;
        subscriber.isPrint = false;

        Test.startTest();   
            Account accountAfter = SubscriptionsWebservicesHandlers.setAccountFields(digitalAccount.clone(true,true), subscriber, null, null, null);
        Test.stopTest();
        System.assertEquals(subscriber.GUID, accountAfter.Guid__c);
        System.assertEquals(subscriber.digitalSubscriberStatus, accountAfter.Subscriber_Digital_Status__c);
        System.assertEquals(digitalAccount.RecordTypeId, accountAfter.RecordTypeId);
    }

    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 26/08/2015
    Version - 1.1
    Function - Test method for SubscriptionsWebservicesHandler#testUpdateSubscriber_EmailSent_MPPServiceID()
    #############Change Log#############
    Modified by     	Version     Change Date
    ****************************************************************************************/
    static testMethod void testUpdateSubscriber_EmailSent_MPPServiceID(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.createIndividualSubscribers();
        td.lstIndividualSubscribers[0].isUsingMPP__c = true;
        update td.lstIndividualSubscribers[0];
        
        String TsNumber = [SELECT Id,Subscriber_Number_static__c FROM Account WHERE Id =: td.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
        String mppServiceId = null;
        Test.startTest();
            SubscriptionsWebservicesHandlers.updateSubscriber_EmailSent_MPPServiceID(TsNumber, mppServiceId);
        Test.stopTest();
        
        Account acc = [SELECT Id, MPP_Service_Id__c FROM Account WHERE Subscriber_Number_static__c =: TsNumber];
        System.assertEquals(td.lstPlaneURL[0].Premium_Continuous_ID__c,acc.MPP_Service_Id__c);
    }
    
    /*************************************************************************************** 
    Date - 24/09/2015
    Version - 1.1
    Function - Test payment cancellation from MPP
    #############Change Log#############
    Modified by     	Version     Change Date
    ****************************************************************************************/
    static testMethod void testPaymentFailureOnManualCancellationFromMPP(){
        setupPremiumAccountData();
        setupPremiumPaymentData();
        setupIncentiveData(null);
        
        premiumSubscriberDetails.TCode ='t1';
        String r = SubscriptionsWebservicesHandlers.createSubscriber(premiumSubscriberDetails,paymentDetails,premiumSubscriptionDetails,recurringDetails);
        System.assertNotEquals(null, r);
        
        paymentDetails.recurringDetails.paymentType = 'directdebit';
        premiumSubscriptionDetails.subscriptionType= 'continuous';
        premiumSubscriptionDetails.paymentDate = Date.today();
        Id subId = SubscriptionsWebservicesHandlers.createSubscription(r, null, 'BOO1', premiumSubscriptionDetails, paymentDetails.recurringDetails,selectedProduct);
        System.assertNotEquals(null, subId);
        Subscription__c sub = [SELECT Subscription_Status__c, Cancellation_Reason__c, Cancellation_Method__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = : r];
		System.assertEquals('Pending',sub.Subscription_Status__c);

        SubscriptionsWebservicesHandlers.createTransaction(r, paymentDetails, null, false);
        
        List<MPP_Transaction_History__c> hist = [SELECT Id, Payment_status__c FROM MPP_Transaction_History__c WHERE Order_id__c = :'123'];
        System.assertNotEquals(null, hist);
        System.assertNotEquals(0, hist.size());
        System.assertEquals('Success', hist[0].Payment_status__c);
        
        paymentDetails.paymentDate = date.today();
        paymentDetails.amountGross = 5;
        paymentDetails.currencyType = 'GBP'; 
        paymentDetails.paymentStatus = 'failed'; 
 		Profile p = [SELECT Id FROM Profile WHERE Name='TMG System']; 
        User u = new User(Alias = 'standt', Email='TMGSystemUser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='TMGSystemUser@testorg.com');

        System.runAs(u) {
	        Test.startTest();
	        	SubscriptionsWebservicesHandlers.paymentFailure(r, paymentDetails , '', '');
	        Test.stopTest();
        }
        hist = [SELECT Id, Payment_status__c, Failure_Code__c, Failure_Reason__c FROM MPP_Transaction_History__c WHERE Order_id__c = :'123'];
        System.assertNotEquals(null, hist);
        System.assertNotEquals(0, hist.size());
        System.assertEquals('Failed', hist[0].Payment_status__c);
        System.assertEquals('Cancelled', hist[0].Failure_Reason__c);
        System.assertEquals('Unknown', hist[0].Failure_Code__c);
        
        sub = [SELECT Cancellation_Reason__c, Cancellation_Method__c FROM Subscription__c WHERE Subscriber__r.Subscriber_Number_Static__c = : r];
        System.assertEquals('Payment Failure', sub.Cancellation_Method__c);
        System.assertEquals('Cancelled', sub.Cancellation_Reason__c);
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 04/12/2015
    Version - 1.1
    Function - test create subscription method with low start tcode, DD payment type, with 1 as payment date
    #############Change Log#############
    Modified by     Version     Change Date
   	Wiktor Czykin	1.1			15/12/2015	//added changeTCodeToLowStart()
    ***************************************************************************************/
    private static testMethod void  testCreateSubscriptionWithLowStartDDFirstOfTheMonth(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadVAT();	
        td.loadCountryCodes();
        td.checkSubscriptionDependencies();
        td.createTCodeManagement();
        td.createZProductFeatures();
        td.createTCodeProducts();
   		TestDataUtility.changeTCodeToLowStart(td.lstTCodeManagement[0]);
        update td.lstTCodeManagement;
        
        List<Account> lstAccount = [select Id, Name, Subscriber_Number_Static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        SubscriptionsWebservices.Subscription subscriptionDetails = new SubscriptionsWebservices.Subscription();
        
        Date dt = Date.today().addMonths(2).toStartOfMonth();
        subscriptionDetails.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
        subscriptionDetails.paymentDate = dt;
        subscriptionDetails.startDate = dt;
        subscriptionDetails.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        
        SubscriptionsWebservices.MPPRecurringInfo rec = new SubscriptionsWebservices.MPPRecurringInfo();
        rec.paymentType = Constants.SAM_DIRECTDEBIT;
        rec.frequency = Constants.DD_COL_FREQ_MONTHLY;
        
        MppUtil.PaymentSetupWrapper psw = new MppUtil.PaymentSetupWrapper();
        psw.dtSwitchPaymentDate = dt;
        psw.dSwitchAmount = 9;
        String sCustomPaymentSchedule = JSON.serialize(psw);
        
        Test.startTest();
        System.assertNotEquals(null, lstAccount[0].Subscriber_Number_Static__c);
        	Id idSubscription = SubscriptionsWebservicesHandlers.createSubscription(	lstAccount[0].Subscriber_Number_Static__c,
			        																	null, 
			        																	td.lstTCodeManagement[0].Name,
			        																	subscriptionDetails, 
			        																	rec,
                                                                                        td.lstZproducts[0]
			        																);
        	System.assertNotEquals(null, idSubscription);
        Test.stopTest();
        List<Subscription__c> lstSub = [select 	Id, 
										        isContinuous__c, 
										        MPP_Irregular_Payment_Schedule__c, 
										        RecordTypeId, 
										        Payment_Details_Received__c,
										        Subscription_Status__c,
										        Order_Taken_Date__c,
										        TCode__c,
										        Subscriber__c,
										        PaymentDate__c,
										        Low_Start_Period__c,
										        Low_Start_Weekly_Price__c,
										        MPP_DD_Frequency__c,
										        MPP_CC_Frequency__c
									        from Subscription__c 
									        where Subscriber__c = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstSub.isEmpty());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()), lstSub[0].RecordTypeId, 'not Low Start record type where should be');
        System.assertEquals(true, lstSub[0].isContinuous__c, 'subscription is not continuous where should be');
        System.assert(String.isNotBlank(lstSub[0].MPP_Irregular_Payment_Schedule__c),'irregular payment schedule not populated');
        System.assert(lstSub[0].Payment_Details_Received__c, 'payment details not received where should be');
        System.assertEquals(Constants.SSTATUS_PENDING, lstSub[0].Subscription_Status__c, 'suscription status should be pending');
        System.assertEquals(td.lstTCodeManagement[0].Id, lstSub[0].TCode__c, 'tcode not set correctly');
        System.assertEquals(td.lstIndividualSubscribers[0].Id, lstSub[0].Subscriber__c, 'related subscriber record does not match');
        System.assertEquals('1', lstSub[0].PaymentDate__c, 'payment date does not match');
        System.assertEquals(Integer.valueOf(td.lstTCodeManagement[0].Low_Start_Period__c),lstSub[0].Low_Start_Period__c);
        System.assertEquals(td.lstTCodeManagement[0].Low_Start_Weekly_Price__c, lstSub[0].Low_Start_Weekly_Price__c);
        System.assertEquals(Constants.DD_COL_FREQ_MONTHLY, lstSub[0].MPP_DD_Frequency__c);
		System.assertEquals(null, lstSub[0].MPP_CC_Frequency__c);
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 04/12/2015
    Version - 1.1
    Function - test create subscription method with low start tcode, CC payment type, with 15 as payment date
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/12/2015	//added changeTCodeToLowStart()
    ***************************************************************************************/
    private static testMethod void testCreateSubscriptionWithLowStartDDFifteenthOfTheMonth(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadVAT();	
        td.loadCountryCodes();
        td.checkSubscriptionDependencies();
        td.createTCodeManagement();
        td.createZProductFeatures();
        td.createTCodeProducts();
     	TestDataUtility.changeTCodeToLowStart(td.lstTCodeManagement[0]);
        update td.lstTCodeManagement;
        
        List<Account> lstAccount = [select Id, Name, Subscriber_Number_Static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        SubscriptionsWebservices.Subscription subscriptionDetails = new SubscriptionsWebservices.Subscription();
        
        Date dt = Date.today().addMonths(2);
        dt = Date.newInstance(dt.year(), dt.month(), 15);
        subscriptionDetails.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
        subscriptionDetails.paymentDate = dt;
        subscriptionDetails.startDate = dt;
        subscriptionDetails.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        
        SubscriptionsWebservices.MPPRecurringInfo rec = new SubscriptionsWebservices.MPPRecurringInfo();
        rec.paymentType = Constants.SAM_DIRECTDEBIT;
        rec.frequency = Constants.DD_COL_FREQ_MONTHLY;
        
        MppUtil.PaymentSetupWrapper psw = new MppUtil.PaymentSetupWrapper();
        psw.dtSwitchPaymentDate = dt;
        psw.dSwitchAmount = 9;
        String sCustomPaymentSchedule = JSON.serialize(psw);
        
        Test.startTest();
       		System.assertNotEquals(null, lstAccount[0].Subscriber_Number_Static__c);
        	Id idSubscription = SubscriptionsWebservicesHandlers.createSubscription(	lstAccount[0].Subscriber_Number_Static__c,
			        																	null, 
			        																	td.lstTCodeManagement[0].Name,
			        																	subscriptionDetails, 
			        																	rec,
                                                                                        td.lstZproducts[0]
			        																);
        	System.assertNotEquals(null, idSubscription);
        Test.stopTest();
        List<Subscription__c> lstSub = [select 	Id, 
										        isContinuous__c, 
										        MPP_Irregular_Payment_Schedule__c, 
										        RecordTypeId, 
										        Payment_Details_Received__c,
										        Subscription_Status__c,
										        Order_Taken_Date__c,
										        TCode__c,
										        Subscriber__c,
										        PaymentDate__c,
										        Low_Start_Period__c,
										        Low_Start_Weekly_Price__c,
										        MPP_DD_Frequency__c,
										        MPP_CC_Frequency__c
									        from Subscription__c 
									        where Subscriber__c = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstSub.isEmpty());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()), lstSub[0].RecordTypeId, 'not Low Start record type where should be');
        System.assertEquals(true, lstSub[0].isContinuous__c, 'subscription is not continuous where should be');
        System.assert(String.isNotBlank(lstSub[0].MPP_Irregular_Payment_Schedule__c),'irregular payment schedule not populated');
        System.assert(lstSub[0].Payment_Details_Received__c, 'payment details not received where should be');
        System.assertEquals(Constants.SSTATUS_PENDING, lstSub[0].Subscription_Status__c, 'suscription status should be pending');
        System.assertEquals(td.lstTCodeManagement[0].Id, lstSub[0].TCode__c, 'tcode not set correctly');
        System.assertEquals(td.lstIndividualSubscribers[0].Id, lstSub[0].Subscriber__c, 'related subscriber record does not match');
        System.assertEquals('15', lstSub[0].PaymentDate__c, 'payment date does not match');
        System.assertEquals(Integer.valueOf(td.lstTCodeManagement[0].Low_Start_Period__c),lstSub[0].Low_Start_Period__c);
        System.assertEquals(td.lstTCodeManagement[0].Low_Start_Weekly_Price__c, lstSub[0].Low_Start_Weekly_Price__c);
        System.assertEquals(Constants.DD_COL_FREQ_MONTHLY, lstSub[0].MPP_DD_Frequency__c);
		System.assertEquals(null, lstSub[0].MPP_CC_Frequency__c);
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 04/12/2015
    Version - 1.1
    Function - test update subscription method with low start tcode, CC payment type, with 1 as payment date
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/12/2015	//added changeTCodeToLowStart()
    ***************************************************************************************/
    private static testMethod void testUpdateSubscriptionWithLowStartCCFirstOfTheMonth(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadVAT();	
        td.loadCountryCodes();
        td.checkSubscriptionDependencies();
        td.createTCodeManagement();
        td.createTCodeProducts();
        TestDataUtility.changeTCodeToLowStart(td.lstTCodeManagement[0]);
        update td.lstTCodeManagement;
        
        Subscription__c subscription = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        subscription.TCode__c = td.lstTCodeManagement[0].Id;
        subscription.TCode_Product__c = td.lstTCodeProducts[0].Id;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
   		insert subscription;
   		
        SubscriptionsWebservices.Subscription subscriptionDetails = new SubscriptionsWebservices.Subscription();
        
        Date dt = Date.today().addMonths(2).toStartOfMonth();
        subscriptionDetails.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
        subscriptionDetails.paymentDate = dt;
        subscriptionDetails.startDate = dt;
        subscriptionDetails.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        
        SubscriptionsWebservices.MPPRecurringInfo rec = new SubscriptionsWebservices.MPPRecurringInfo();
        rec.paymentType = Constants.SAM_CREDITDEBITCARD;
        rec.frequency = Constants.DD_COL_FREQ_MONTHLY;
        
        MppUtil.PaymentSetupWrapper psw = new MppUtil.PaymentSetupWrapper();
        psw.dtSwitchPaymentDate = dt;
        psw.dSwitchAmount = 9;
        String sCustomPaymentSchedule = JSON.serialize(psw);
        
        Test.startTest();
        	Id idSubscription = SubscriptionsWebservicesHandlers.updateSubscription(	subscription.Id,
			        																	subscriptionDetails, 
			        																	rec,
			        																	true
			        																);
        	System.assertNotEquals(null, idSubscription);
        Test.stopTest();
        
        List<Subscription__c> lstSub = [select 	Id, 
										        isContinuous__c, 
										        MPP_Irregular_Payment_Schedule__c, 
										        RecordTypeId, 
										        Payment_Details_Received__c,
										        Subscription_Status__c,
										        Order_Taken_Date__c,
										        TCode__c,
										        Subscriber__c,
										        PaymentDate__c,
										        Low_Start_Period__c,
										        Low_Start_Weekly_Price__c,
										        MPP_DD_Frequency__c,
										        MPP_CC_Frequency__c
									        from Subscription__c 
									        where Subscriber__c = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstSub.isEmpty());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()), lstSub[0].RecordTypeId, 'not Low Start record type where should be');
        System.assertEquals(true, lstSub[0].isContinuous__c, 'subscription is not continuous where should be');
        System.assert(String.isNotBlank(lstSub[0].MPP_Irregular_Payment_Schedule__c),'irregular payment schedule not populated');
        System.assert(lstSub[0].Payment_Details_Received__c, 'payment details not received where should be');
        System.assertEquals(td.lstTCodeManagement[0].Id, lstSub[0].TCode__c, 'tcode not set correctly');
        System.assertEquals(td.lstIndividualSubscribers[0].Id, lstSub[0].Subscriber__c, 'related subscriber record does not match');
        System.assertEquals('1', lstSub[0].PaymentDate__c, 'payment date does not match');
        System.assertEquals(Integer.valueOf(td.lstTCodeManagement[0].Low_Start_Period__c),lstSub[0].Low_Start_Period__c);
        System.assertEquals(td.lstTCodeManagement[0].Low_Start_Weekly_Price__c, lstSub[0].Low_Start_Weekly_Price__c);
        System.assertEquals(Constants.DD_COL_FREQ_MONTHLY, lstSub[0].MPP_CC_Frequency__c);
		System.assertEquals(null, lstSub[0].MPP_DD_Frequency__c);
    }
    
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 04/12/2015
    Version - 1.1
    Function - test update subscription method with low start tcode, CC payment type, with 1 as payment date
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/12/2015	//added changeTCodeToLowStart()
    ***************************************************************************************/
    private static testMethod void testUpdateSubscriptionWithLowStartCCFifteenthOfTheMonth(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadVAT();	
        td.loadCountryCodes();
        td.checkSubscriptionDependencies();
        td.createTCodeManagement();
        td.createTCodeProducts();
        TestDataUtility.changeTCodeToLowStart(td.lstTCodeManagement[0]);
        update td.lstTCodeManagement;
        
        Subscription__c subscription = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        subscription.TCode__c = td.lstTCodeManagement[0].Id;
        subscription.TCode_Product__c = td.lstTCodeProducts[0].Id;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
   		insert subscription;
   		
        SubscriptionsWebservices.Subscription subscriptionDetails = new SubscriptionsWebservices.Subscription();
        
        Date dt = Date.today().addMonths(2);
        dt = Date.newInstance(dt.year(), dt.month(), 15);
        subscriptionDetails.productType = Constants.PRODUCT_PREMIUM.toLowerCase();
        subscriptionDetails.paymentDate = dt;
        subscriptionDetails.startDate = dt;
        subscriptionDetails.subscriptionType = Constants.SUBSCRIPTIONTYPE_CONTINUOUS;
        
        SubscriptionsWebservices.MPPRecurringInfo rec = new SubscriptionsWebservices.MPPRecurringInfo();
        rec.paymentType = Constants.SAM_CREDITDEBITCARD;
        rec.frequency = Constants.DD_COL_FREQ_MONTHLY;
        
        MppUtil.PaymentSetupWrapper psw = new MppUtil.PaymentSetupWrapper();
        psw.dtSwitchPaymentDate = dt;
        psw.dSwitchAmount = 9;
        String sCustomPaymentSchedule = JSON.serialize(psw);
        
        Test.startTest();
        	Id idSubscription = SubscriptionsWebservicesHandlers.updateSubscription(	subscription.Id,
			        																	subscriptionDetails, 
			        																	rec,
			        																	true
			        																);
        	System.assertNotEquals(null, idSubscription);
        Test.stopTest();
        
        List<Subscription__c> lstSub = [select 	Id, 
										        isContinuous__c, 
										        MPP_Irregular_Payment_Schedule__c, 
										        RecordTypeId, 
										        Payment_Details_Received__c,
										        Subscription_Status__c,
										        Order_Taken_Date__c,
										        TCode__c,
										        Subscriber__c,
										        PaymentDate__c,
										        Low_Start_Period__c,
										        Low_Start_Weekly_Price__c,
										        MPP_DD_Frequency__c,
										        MPP_CC_Frequency__c
									        from Subscription__c 
									        where Subscriber__c = :td.lstIndividualSubscribers[0].Id];
        System.assert(!lstSub.isEmpty());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName()), lstSub[0].RecordTypeId, 'not Low Start record type where should be');
        System.assertEquals(true, lstSub[0].isContinuous__c, 'subscription is not continuous where should be');
        System.assert(String.isNotBlank(lstSub[0].MPP_Irregular_Payment_Schedule__c),'irregular payment schedule not populated');
        System.assert(lstSub[0].Payment_Details_Received__c, 'payment details not received where should be');
        System.assertEquals(td.lstTCodeManagement[0].Id, lstSub[0].TCode__c, 'tcode not set correctly');
        System.assertEquals(td.lstIndividualSubscribers[0].Id, lstSub[0].Subscriber__c, 'related subscriber record does not match');
        System.assertEquals('15', lstSub[0].PaymentDate__c, 'payment date does not match');
        System.assertEquals(Integer.valueOf(td.lstTCodeManagement[0].Low_Start_Period__c),lstSub[0].Low_Start_Period__c);
        System.assertEquals(td.lstTCodeManagement[0].Low_Start_Weekly_Price__c, lstSub[0].Low_Start_Weekly_Price__c);
        System.assertEquals(Constants.DD_COL_FREQ_MONTHLY, lstSub[0].MPP_CC_Frequency__c);
		System.assertEquals(null, lstSub[0].MPP_DD_Frequency__c);
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 04/12/2015
    Version - 1.0
    Function - Test exception where no subscription is found for given id
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void  testUpdateFailureNoSubscription(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		Id subscriptionId = td.lstSubscriptions[0].Id;
		delete td.lstSubscriptions;
		Test.startTest();
			try{
				SubscriptionsWebservicesHandlers.updateSubscription(subscriptionId, null, null, null);
				System.assert(false, 'exception not thrown where should be');
			}catch(WebserviceUtil.GenericWSException e){
				System.assertEquals(WebserviceUtil.UNKNOWN_ERROR_CODE, e.getError().errorCode);
			}
		Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 03/12/2015
    Version - 1.1
    Function - Test positive direct call to setSubscriptionLowStartDetails()
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			15/12/2015	//added changeTCodeToLowStart()
    ***************************************************************************************/
    private static testMethod void  testSetLowStartSubscriptionDetails(){
    	TestDataUtility td = new TestDataUtility(1);
        td.checkSubscriptionDependencies();
        
        td.createTCodeManagement();
        TestDataUtility.changeTCodeToLowStart(td.lstTCodeManagement[0]);
        update td.lstTCodeManagement;
        
        Subscription__c subscription = TestDataUtility.newSubscripiton(0, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null);
        subscription.MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
		subscription.Subscription_Duration_Picklist__c = Constants.SUB_DURATION_52;
		insert subscription;
        
        Test.startTest();
    		//SubscriptionsWebservicesHandlers.setSubscriptionLowStartDetails(subscription, td.lstTCodeManagement[0]);
    	Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 03/12/2015
    Version - 1.0
    Function - Test exception where no parameters are passed to the low start fields generation method
    #############Change Log#############
    Modified by     Version     Change Date
    ***************************************************************************************/
    private static testMethod void  testSetLowStartSubscriptionDetailsMethodCallFailure(){
		Test.startTest();
			try{
				SubscriptionsWebservicesHandlers.setSubscriptionLowStartDetails(null, null,null);
				System.assert(false, 'exception not thrown where should be');
			}catch(WebserviceUtil.GenericWSException e){
				System.assertEquals(WebserviceUtil.UNKNOWN_ERROR_CODE, e.getError().errorCode);
			}
		Test.stopTest();
    }
}