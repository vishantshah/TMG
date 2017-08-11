/**
* @author Wiktor Czykin
* @date 29/07/2015
* @description 	Test class for  MPPTransactionHistoryTriggerHandler - new class but all its contents come from an old one
				The only thing changed in the process is restoration of assertions.
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk 1.1         06/04/2016  // added setupProductData() method and change test methods to use it also changed setupIncentiveData()
Wiktor Czykin   1.2         26/05/2016  // modified digital setup method
Wiktor Czykin   1.3         08/03/2017  // modified setupIncentiveData() to add record type
**/
@isTest
private class MPPTransactionHistoryTriggerHandlerTest{

	private static SubscriptionsWebservices.Subscriber digitalSubscriberDetails;
    private static SubscriptionsWebservices.Subscriber premiumSubscriberDetails;
    private static SubscriptionsWebservices.Payment paymentDetails;
    private static SubscriptionsWebservices.MPPRecurringInfo recurringDetails;
    private static SubscriptionsWebservices.Subscription digitalSubscriptionDetails;
    private static SubscriptionsWebservices.Subscription premiumSubscriptionDetails;
    private static List<SubscriptionsWebservices.CustomParameter> contexParams;
    private static decimal vatRateGB = 0.2;
    private static decimal vatRateEU = 0.1;
    private static decimal websitecost = 0.5;
    private static decimal tabletcost = 0.2;
    private static TestDataUtility td = new TestDataUtility(1);

    private static void setupDigitalAccountData(){
        digitalSubscriberDetails = new SubscriptionsWebservices.Subscriber( );
        digitalSubscriberDetails.guid = 'GUIDTestMethodData' + Math.random();
        digitalSubscriberDetails.subscriberType = 'digital';
        digitalSubscriberDetails.digitalSubscriberStatus = 'Active';
        digitalSubscriberDetails.firstName = 'Testio';
        digitalSubscriberDetails.lastName = 'Testev';
        digitalSubscriberDetails.personalEmail = DateTime.now().getTime() + 'testio@test.com';
        digitalSubscriberDetails.street = 'Cannon Street';
        digitalSubscriberDetails.city = 'Reading';
        digitalSubscriberDetails.postalCode = 'GIR0aa';
        digitalSubscriberDetails.country = 'GB';
        digitalSubscriberDetails.homePhone = '01603554887';
        digitalSubscriberDetails.mobilePhone = '077777777777';
        digitalSubscriberDetails.marketingEmailPref = true;
        digitalSubscriberDetails.TCode = '445T';
        digitalSubscriberDetails.poc = '009R0091946476';


        digitalSubscriptionDetails = new SubscriptionsWebservices.Subscription();
        digitalSubscriptionDetails.productType = 'digital';
        digitalSubscriptionDetails.subscriptionType = 'monthly';
        digitalSubscriptionDetails.startDate = date.today();

        setupCustomSettings();
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
        premiumSubscriberDetails.postalCode = 'GIR0aa';
        premiumSubscriberDetails.country = 'GB';
        premiumSubscriberDetails.homePhone = '01603554887';
        premiumSubscriberDetails.mobilePhone = '077777777777';
        premiumSubscriberDetails.marketingEmailPref = true;
        premiumSubscriberDetails.TCode = '0A8A';
        premiumSubscriberDetails.poc = '009R0091946476';

        premiumSubscriptionDetails = new SubscriptionsWebservices.Subscription();
        premiumSubscriptionDetails.productType = 'premium';
        premiumSubscriptionDetails.subscriptionType = 'monthly';
        premiumSubscriptionDetails.startDate = date.today().adddays(21).toStartOfWeek();
        premiumSubscriptionDetails.paymentDate=date.today().adddays(21);

        setupCustomSettings();
    }

    private static void setupProductData(){
        td.createTCodeProducts();
        for(zqu__ZProduct__c prod : td.lstZproducts){
            prod.Print_Product__c = false;
        }
        update td.lstZproducts;

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

    private static void setupCustomSettings(){
        if(Country_Codes__c.getInstance('GB') == null){
            Country_Codes__c cc = new Country_Codes__c( name='GB', Country_Name__c='United Kingdom', EU__c = true);
            try{
            	insert cc;
			}catch(Exception ex){}
        }
        if(Country_Codes__c.getInstance('FR') == null){
            Country_Codes__c cc = new Country_Codes__c( name='FR', Country_Name__c='France', EU__c = true);
            try{
            	insert cc;
			}catch(Exception ex){}
        }
        if(Country_Codes__c.getInstance('US') == null){
            Country_Codes__c cc = new Country_Codes__c( name='US', Country_Name__c='United States', EU__c = false);
            try{
            	insert cc;
			}catch(Exception ex){}
        }
        if(VAT__c.getInstance('VAT') != null)
            delete VAT__c.getInstance('VAT');

        VAT__c vat = new VAT__c(name='VAT', EU_Standard_VAT_Rate__c=vatRateEU*100, Premium_Mobile_Cost__c=0.1, Premium_Tablet_Cost__c=tabletcost, Premium_Website_Cost__c=websiteCost, UK_Exempt_VAT_Rate__c=0, UK_Export_VAT_Rate__c=0, UK_Standard_VAT_Rate__c=vatRateGB*100);
        try{
        	insert vat;
		}catch(Exception ex){}
    }

    private static void setupPaymentData(){

        paymentDetails = new SubscriptionsWebservices.Payment( );
        paymentDetails.paymentDate = System.now();
        paymentDetails.amountGross = 4.8;
        paymentDetails.currencyType = 'GBP';
        paymentDetails.paymentStatus = 'success';
        paymentDetails.paymentType = 'CreditDebitCard';
        paymentDetails.productName = 'tomatoes';
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

    private static void setupPremiumDDPaymentData(){

        paymentDetails = new SubscriptionsWebservices.Payment( );
        paymentDetails.paymentDate = System.now();
        paymentDetails.amountGross = 4.8;
        paymentDetails.currencyType = 'GBP';
        paymentDetails.paymentStatus = 'success';
        paymentDetails.paymentType = 'DirectDebit';
        paymentDetails.productName = 'tomatoes';
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

    private static void setupIncentiveData(){

        zqu__ZProduct__c prod1 = new zqu__ZProduct__c(Name = 'ZProduct',zqu__SKU__c ='SKU-1323',zqu__ZuoraId__c = 'ZuoraId' ,zqu__EffectiveStartDate__c = System.today(),zqu__EffectiveEndDate__c = System.today().addDays(60),zqu__Active__c = true);
        try{
            insert prod1;
        }catch(Exception ex){}

        contexParams = new List<SubscriptionsWebservices.CustomParameter>();
        SubscriptionsWebservices.CustomParameter prodId = new SubscriptionsWebservices.CustomParameter();
        prodId.name = 'productId';
        prodId.value = '' + prod1.Id;
        contexParams.add(prodId);

        Incentive__c inc1 = new Incentive__c( Name='Incentive1', Incentive_Description__c='An exciting incentive' );
        Incentive__c inc2 = new Incentive__c( Name='Incentive2', Incentive_Description__c='An even more exciting incentive' );

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
		}catch(Exception ex){}
        try{
       		insert tcm2;
		}catch(Exception ex){}

        Id recordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        TCode_Product__c tcodeProd1 = new TCode_Product__c(RecordTypeId = recordTypeId, Product__c =prod1.Id,TCodeManagement__c = tcm1.Id,Low_Start_Price__c = 9.00,Digital_Yearly_Price__c = 62.3, Digital_Monthly_Price__c = 2.5,Weekly_Price__c = 4.5);
        TCode_Product__c tcodeProd2 = new TCode_Product__c(RecordTypeId = recordTypeId, Product__c =prod1.Id,TCodeManagement__c = tcm2.Id,Low_Start_Price__c = 9.00,Digital_Yearly_Price__c = 42.3, Digital_Monthly_Price__c = 3.5,Weekly_Price__c = 4.5);

        try{
            insert tcodeProd1;
        }catch(Exception ex){}
        try{
            insert tcodeProd2;
        }catch(Exception ex){}

        POC__c poc1 = new POC__c(TCodeManagement__c=tcm2.Id, POC_ID__c='12345678', PostalCode__c='nn4 0qs', LastName__c = 'frank',Product__c = prod1.Id);

        try{
        	insert poc1;
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

        List<SubManagementDefaults__c> def = [SELECT DefaultValue__c FROM SubManagementDefaults__c WHERE ID__c='OrderTakenWave'];
        if( def == null || def.size() ==0 ){
            SubManagementDefaults__c dOO = new SubManagementDefaults__c(ID__c='OrderTakenWave',DefaultValue__c='999T');
            try{
            	insert dOO;
			}catch(Exception ex){}
        }

        def = [SELECT DefaultValue__c FROM SubManagementDefaults__c WHERE ID__c='PromotionTCode'];
        if( def == null || def.size() ==0 ){
            SubManagementDefaults__c dOO = new SubManagementDefaults__c(ID__c='PromotionTCode',DefaultValue__c='998T');
            try{
            	insert dOO;
			}catch(Exception ex){}
        }

        def = [SELECT DefaultValue__c FROM SubManagementDefaults__c WHERE ID__c='iPadTCode'];
        if( def == null || def.size() ==0 ){
            SubManagementDefaults__c dOO = new SubManagementDefaults__c(ID__c='iPadTCode',DefaultValue__c='00AT');
            try{
            	insert dOO;
			}catch(Exception ex){}
        }


        def = [SELECT DefaultValue__c FROM SubManagementDefaults__c WHERE ID__c='AndroidTCode'];
        if( def == null || def.size() ==0 ){
            SubManagementDefaults__c dOO = new SubManagementDefaults__c(ID__c='AndroidTCode',DefaultValue__c='00PT');
            try{
            	insert dOO;
			}catch(Exception ex){}
        }

        List<TCodeManagement__c> tcodes = [SELECT Id FROM TCodeManagement__c WHERE Valid__c = true and Type__c = 'Open Offer'];
        if( tcodes != null && tcodes.size() == 0 ){
            TCodeManagement__c ooTCode = new TCodeManagement__c( name='BOO1', Price__c=4.5, Digital_Monthly_Price__c=3.5, Digital_Yearly_Price__c=42.3, Description__c='Something about tcode 2', Type__c='Open Offer' );
            try{
            	insert ooTCode;
			}catch(Exception ex){}
        }

    }

    private static testMethod void test_UpdateSubscriptionDetails_digital_success(){
        setupDigitalAccountData();
        setupPaymentData();
        setupProductData();
        paymentDetails.recurringDetails.paymentType = 'creditdebitcard';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(digitalSubscriberDetails, digitalSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());

        accs[0].Subscriber_Digital_Status__c = 'Inactive';
        update accs[0];

        Account acc = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Id = :accs[0].Id LIMIT 1];
        System.assertEquals('Inactive', acc.Subscriber_Digital_Status__c);

        MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Payment_Status__c = 'Success', Total_Price__c = 4.8);
        try{
        	insert txn;
		}catch(Exception ex){}

        acc = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Id = :accs[0].Id LIMIT 1];
        System.assertEquals('Active', acc.Subscriber_Digital_Status__c);

    }

    private static testMethod void test_UpdateSubscriptionDetails_digital_failure(){
        setupDigitalAccountData();
        setupPaymentData();
        setupProductData();
        paymentDetails.recurringDetails.paymentType = 'creditdebitcard';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(digitalSubscriberDetails, digitalSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
       	System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());
        System.assertEquals('Active', accs[0].Subscriber_Digital_Status__c);

        MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Payment_Status__c = 'Failed', Total_Price__c = 4.8);
        try{
        	insert txn;
		}catch(Exception ex){}

        Account acc = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Id = :accs[0].Id LIMIT 1];
        System.assertEquals('Inactive', acc.Subscriber_Digital_Status__c);
    }

    private static testMethod void test_UpdateSubscriptionDetails_premium_success_offered(){
        setupPremiumAccountData();
        setupIncentiveData();
        setupPaymentData();
        paymentDetails.recurringDetails.paymentType = 'directdebit';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscription_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());
        System.assertEquals('Pending', accs[0].Subscription_Status__c);

        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c, Cancellation_Date__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending', subs[0].Subscription_Status__c);

        // Force the sub back to offered
        subs[0].Subscription_Status__c = 'Offered';
        update subs[0];

        // Check it moved ok
        subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Offered', subs[0].Subscription_Status__c);

        Test.startTest();
            // Now to test the trigger - insert a successful payment
            MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Subscription__c = subs[0].Id, Payment_Status__c = 'Success', Total_Price__c = 4.8);
            try{
            	insert txn;
			}catch(Exception ex){}
        Test.stopTest();

        // Check it's moved to Pending
        subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending', subs[0].Subscription_Status__c);
    }

    private static testMethod void test_UpdateSubscriptionDetails_premium_success_pendingcancelationtoactive(){
        setupPremiumAccountData();
        setupIncentiveData();
        setupPaymentData();
        paymentDetails.recurringDetails.paymentType = 'directdebit';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;
        System.debug('#### Mou TSNumber' + TSNumber);
        List<Account> accs = [SELECT Id, Subscription_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.debug('#### Mou accs' + accs);
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());
        System.assertEquals('Pending', accs[0].Subscription_Status__c);

        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c, Cancellation_Date__c, Cancellation_Reason__c, Cancellation_Method__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending', subs[0].Subscription_Status__c);

        // Force the sub back to pending cancellation
        subs[0].Subscription_Status__c = 'Pending Cancellation';
        subs[0].Cancellation_Date__c = Date.today().addDays(21);
        subs[0].Cancellation_Reason__c = 'Failed payment';
        subs[0].Cancellation_Method__c = 'Failed payment';
        update subs[0];

        // Check it moved ok
        subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending Cancellation', subs[0].Subscription_Status__c);

        Test.startTest();
            // Now to test the trigger - insert a successful payment
            MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Subscription__c = subs[0].Id, Payment_Status__c = 'Success', Total_Price__c = 4.8);
            try{
            	insert txn;
			}catch(Exception ex){}
        Test.stopTest();

        // Check it's moved to Pending
        subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Active', subs[0].Subscription_Status__c);
    }

    private static testMethod void test_UpdateSubscriptionDetails_premium_success_pendingcancellationtoactive(){
        setupPremiumAccountData();
        setupIncentiveData();
        setupPaymentData();
        paymentDetails.recurringDetails.paymentType = 'directdebit';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(premiumSubscriberDetails, premiumSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscription_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());
        System.assertEquals('Pending', accs[0].Subscription_Status__c);

        List<Subscription__c> subs = [SELECT Id, Subscription_Status__c, Cancellation_Date__c, Cancellation_Reason__c, Cancellation_Method__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending', subs[0].Subscription_Status__c);

        // Force the sub back to pending cancellation
        subs[0].Subscription_Status__c = 'Pending Cancellation';
        subs[0].Cancellation_Date__c = Date.today().addDays(21);
        subs[0].Cancellation_Reason__c = 'Failed payment';
        subs[0].Cancellation_Method__c = 'Failed payment';
        update subs[0];

        // Check it moved ok
        subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Pending Cancellation', subs[0].Subscription_Status__c);

        // Now to test the trigger - insert a successful payment
        MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Subscription__c = subs[0].Id, Payment_Status__c = 'Success', Total_Price__c = 4.8);
        try{
        	insert txn;
		}catch(Exception ex){}

        // Check it's moved to Pending
        subs = [SELECT Id, Subscription_Status__c FROM Subscription__c WHERE Subscriber__c = :accs[0].Id];
        System.assertNotEquals(null, subs);
        System.assertNotEquals(0, subs.size());
        System.assertEquals('Active', subs[0].Subscription_Status__c);
    }

    private static testMethod void test_CalculateVAT_digitalGB_success(){
        decimal price = 10;
        setupDigitalAccountData();
        setupPaymentData();
        setupProductData();
        paymentDetails.recurringDetails.paymentType = 'creditdebitcard';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(digitalSubscriberDetails, digitalSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());

        MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Payment_Status__c = 'Success', Total_Price__c = price);
        try{
        	insert txn;
		}catch(Exception ex){}

        txn = [SELECT Id, Net_Amount__c, VAT_Amount__c, Total_Price__c FROM MPP_Transaction_History__c WHERE Id = :txn.Id LIMIT 1];

        System.assertEquals(price, txn.Total_Price__c);
        System.assertEquals(TMGUtil.decimalRound(price/(1+vatRateGB), 2), txn.Net_Amount__c);
        System.assertEquals(TMGUtil.decimalRound(price-(price/(1+vatRateGB)), 2), txn.VAT_Amount__c);

    }

    private static testMethod void test_CalculateVAT_digitalEU_success(){
        decimal price = 10;
        setupDigitalAccountData();
        digitalSubscriberDetails.country = 'FR';
        setupPaymentData();
        setupProductData();
        paymentDetails.recurringDetails.paymentType = 'creditdebitcard';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(digitalSubscriberDetails, digitalSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());

        MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Payment_Status__c = 'Success', Total_Price__c = price);
        try{
        	insert txn;
		}catch(Exception ex){}

        txn = [SELECT Id, Net_Amount__c, VAT_Amount__c, Total_Price__c FROM MPP_Transaction_History__c WHERE Id = :txn.Id LIMIT 1];

        System.assertEquals(price, txn.Total_Price__c);
        System.assertEquals(TMGUtil.decimalRound(price/(1+vatRateEU), 2), txn.Net_Amount__c);
        System.assertEquals(TMGUtil.decimalRound(price-(price/(1+vatRateEU)), 2), txn.VAT_Amount__c);

    }

    private static testMethod void test_CalculateVAT_digitalROW_success(){
        decimal price = 10;
        setupDigitalAccountData();
        digitalSubscriberDetails.country = 'US';
        setupPaymentData();
        setupProductData();
        paymentDetails.recurringDetails.paymentType = 'creditdebitcard';

        String TSNumber = SubscriptionsWebservices.CreateSubscriber(digitalSubscriberDetails, digitalSubscriptionDetails, paymentDetails.recurringDetails, null, null, null, contexParams).TSNumber;

        List<Account> accs = [SELECT Id, Subscriber_Digital_Status__c FROM Account WHERE Subscriber_Number_Static__c = :TSNumber];
        System.assertNotEquals(null, accs);
        System.assertNotEquals(0, accs.size());

        MPP_Transaction_History__c txn = new MPP_Transaction_History__c(Subscriber__c = accs[0].Id, Payment_Status__c = 'Success', Total_Price__c = price);
        try{
        	insert txn;
		}catch(Exception ex){}

        txn = [SELECT Id, Net_Amount__c, VAT_Amount__c, Total_Price__c FROM MPP_Transaction_History__c WHERE Id = :txn.Id LIMIT 1];

        System.assertEquals(price, txn.Total_Price__c);
        System.assertEquals(price, txn.Net_Amount__c);
        System.assertEquals(0, txn.VAT_Amount__c);
    }

}
