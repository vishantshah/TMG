/**
* @author Wiktor Czykin
* @date 23/06/2017
* @description test class for DeliverNewspaperHandler
*#############Change Log#############
*Modified by     Change Date
*Wiktor Czykin   10/07/2017 //modified record type for account created automatically in the process
**/
@isTest
private class DeliverNewspaperHandlerTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - helper method to genenerate bean to serialize
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static DeliverNewspaperBean.DeliverNewspaperBeanData generateDeliverNewspaperBean(TestDataUtility td){
        List<Account> lstAccount = [SELECT Subscriber_Number__c FROM Account WHERE Id = :td.lstIndividualSubscribers[0].Id];

        DeliverNewspaperBean.DeliverNewspaperBeanData bean = new DeliverNewspaperBean.DeliverNewspaperBeanData();
        bean.firstName = 'fc';
        bean.lastName = 'ln';
        bean.addressLineOne = 'line1';
        bean.addressLineTwo = 'line2';
        bean.addressLineThree = 'line3';
        bean.town = 'London';
        bean.county = 'TMGShire';
        bean.postcode = 'sw1w 0dt';
        bean.email = td.lstIndividualSubscribers[0].PersonEmail;
        bean.subscriberId = lstAccount[0].Subscriber_Number__c;
        bean.phone = '1231232';
        bean.optInEmail = DeliverNewspaperHandler.OPTIN_YES;
        bean.optInPhone = DeliverNewspaperHandler.OPTIN_YES;
        bean.optInPost = DeliverNewspaperHandler.OPTIN_YES;
        bean.optInText = DeliverNewspaperHandler.OPTIN_YES;
        bean.deliveryDays = new List<List<String>>{new List<String>{'SAT','SUN'}};
        bean.retailerId = td.lstRetailers[0].URN__c;
        bean.retailerName = 'someName';
        bean.retailerPhoneNumber = '12312312';
        bean.retailerAddressLineOne = 'line1';
        bean.retailerAddressLineTwo = 'line2';
        bean.retailerTown = 'London';
        bean.retailerPostcode = 'sw1w 0dt';
        bean.retailerType ='shop';
        return bean;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test processing of request when mapping to existing account is done via subscriber number
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryMappingViaSubscriberNumber(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();

        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        List<Home_Delivery_Voucher__c> lstVoucher = Database.query('SELECT '+GlobalQueries.generateFieldsListForQuery(Home_Delivery_Voucher__c.class.getName(), null, null)+ ' FROM Home_Delivery_Voucher__c');
        System.assertEquals(1, lstVoucher.size());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()), lstVoucher[0].RecordTypeId);
        System.assertEquals(dnb.firstName, lstVoucher[0].First_Name__c);
        System.assertEquals(dnb.lastName, lstVoucher[0].Last_Name__c);
        System.assertEquals(dnb.addressLineOne+'\n'+dnb.addressLineTwo+'\n'+dnb.addressLineThree, lstVoucher[0].Mailing_Address__c );
        System.assertEquals(dnb.town, lstVoucher[0].Mailing_Town__c);
        System.assertEquals(dnb.county, lstVoucher[0].Mailing_County__c);
        System.assertEquals(dnb.postcode, lstVoucher[0].Mailing_Postal_Code__c);
        System.assertEquals(dnb.email, lstVoucher[0].Email__c);
        System.assertEquals(dnb.subscriberId, lstVoucher[0].Subscriber_Number__c);
        System.assertEquals(dnb.phone, lstVoucher[0].Phone__c);
        System.assertEquals(dnb.optInEmail==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Email__c);
        System.assertEquals(dnb.optInPhone==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Phone__c);
        System.assertEquals(dnb.optInPost==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Post__c);
        System.assertEquals(dnb.optInText==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_SMS__c);
        System.assertEquals(td.lstRetailers[0].Id, lstVoucher[0].Retailer__c);
        System.assertEquals(dnb.retailerId, lstVoucher[0].Retailer_Id__c);
        System.assertEquals(dnb.retailerName, lstVoucher[0].Retailer_Name__c);
        System.assertEquals(dnb.retailerPhoneNumber, lstVoucher[0].Retailer_Phone__c);
        System.assertEquals(dnb.retailerAddressLineOne+'\n'+dnb.retailerAddressLineTwo, lstVoucher[0].Retailer_Address__c);
        System.assertEquals(dnb.retailerTown, lstVoucher[0].Retailer_Town__c);
        System.assertEquals(dnb.retailerPostcode, lstVoucher[0].Retailer_Post_Code__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test processing of request when mapping to existing account is done via email address
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryMappingViaEmail(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();

        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        dnb.subscriberId = '';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        List<Home_Delivery_Voucher__c> lstVoucher = Database.query('SELECT '+GlobalQueries.generateFieldsListForQuery(Home_Delivery_Voucher__c.class.getName(), null, null)+ ' FROM Home_Delivery_Voucher__c');
        System.assertEquals(1, lstVoucher.size());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()), lstVoucher[0].RecordTypeId);
        System.assertEquals(dnb.firstName, lstVoucher[0].First_Name__c);
        System.assertEquals(dnb.lastName, lstVoucher[0].Last_Name__c);
        System.assertEquals(dnb.addressLineOne+'\n'+dnb.addressLineTwo+'\n'+dnb.addressLineThree, lstVoucher[0].Mailing_Address__c );
        System.assertEquals(dnb.town, lstVoucher[0].Mailing_Town__c);
        System.assertEquals(dnb.county, lstVoucher[0].Mailing_County__c);
        System.assertEquals(dnb.postcode, lstVoucher[0].Mailing_Postal_Code__c);
        System.assertEquals(dnb.email, lstVoucher[0].Email__c);
        System.assertEquals(dnb.subscriberId, '');
        System.assertEquals(dnb.phone, lstVoucher[0].Phone__c);
        System.assertEquals(dnb.optInEmail==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Email__c);
        System.assertEquals(dnb.optInPhone==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Phone__c);
        System.assertEquals(dnb.optInPost==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Post__c);
        System.assertEquals(dnb.optInText==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_SMS__c);
        System.assertEquals(dnb.retailerId, lstVoucher[0].Retailer_Id__c);
        System.assertEquals(dnb.retailerId, lstVoucher[0].Retailer_Id__c);
        System.assertEquals(dnb.retailerName, lstVoucher[0].Retailer_Name__c);
        System.assertEquals(dnb.retailerPhoneNumber, lstVoucher[0].Retailer_Phone__c);
        System.assertEquals(dnb.retailerAddressLineOne+'\n'+dnb.retailerAddressLineTwo, lstVoucher[0].Retailer_Address__c);
        System.assertEquals(dnb.retailerTown, lstVoucher[0].Retailer_Town__c);
        System.assertEquals(dnb.retailerPostcode, lstVoucher[0].Retailer_Post_Code__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test processing of request when mapping to existing account is done via email address (where dupes exists - simulation only)
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryMappingViaEmailDupeSimulation(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();
        DeliverNewspaperHandler.bDupeScenario = true;
        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        dnb.subscriberId = '';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        List<Home_Delivery_Voucher__c> lstVoucher = Database.query('SELECT '+GlobalQueries.generateFieldsListForQuery(Home_Delivery_Voucher__c.class.getName(), null, null)+ ' FROM Home_Delivery_Voucher__c');
        System.assertEquals(1, lstVoucher.size());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()), lstVoucher[0].RecordTypeId);
        System.assertEquals(dnb.firstName, lstVoucher[0].First_Name__c);
        System.assertEquals(dnb.lastName, lstVoucher[0].Last_Name__c);
        System.assertEquals(dnb.addressLineOne+'\n'+dnb.addressLineTwo+'\n'+dnb.addressLineThree, lstVoucher[0].Mailing_Address__c );
        System.assertEquals(dnb.town, lstVoucher[0].Mailing_Town__c);
        System.assertEquals(dnb.county, lstVoucher[0].Mailing_County__c);
        System.assertEquals(dnb.postcode, lstVoucher[0].Mailing_Postal_Code__c);
        System.assertEquals(dnb.email, lstVoucher[0].Email__c);
        System.assertEquals(dnb.subscriberId, '');
        System.assertEquals(dnb.phone, lstVoucher[0].Phone__c);
        System.assertEquals(dnb.optInEmail==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Email__c);
        System.assertEquals(dnb.optInPhone==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Phone__c);
        System.assertEquals(dnb.optInPost==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Post__c);
        System.assertEquals(dnb.optInText==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_SMS__c);
        System.assertEquals(dnb.retailerId, lstVoucher[0].Retailer_Id__c);
        System.assertEquals(dnb.retailerId, lstVoucher[0].Retailer_Id__c);
        System.assertEquals(dnb.retailerName, lstVoucher[0].Retailer_Name__c);
        System.assertEquals(dnb.retailerPhoneNumber, lstVoucher[0].Retailer_Phone__c);
        System.assertEquals(dnb.retailerAddressLineOne+'\n'+dnb.retailerAddressLineTwo, lstVoucher[0].Retailer_Address__c);
        System.assertEquals(dnb.retailerTown, lstVoucher[0].Retailer_Town__c);
        System.assertEquals(dnb.retailerPostcode, lstVoucher[0].Retailer_Post_Code__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test logic when no account is found (neither by subscriber number, nor by email)
    #############Change Log#############
    Modified by     Change Date  
    Wiktor Czykin   10/07/2017  //modified account data source references and default account record type for the functionality
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryWithoutMapping(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();

        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        dnb.subscriberId = '';
        dnb.email = 'asdfads@telegraph.co.uk';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        List<Home_Delivery_Voucher__c> lstVoucher = Database.query('SELECT '+GlobalQueries.generateFieldsListForQuery(Home_Delivery_Voucher__c.class.getName(), null, null)+ ' FROM Home_Delivery_Voucher__c');
        System.assertEquals(1, lstVoucher.size());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()), lstVoucher[0].RecordTypeId);
        System.assertNotEquals(null, lstVoucher[0].Account__c);
        System.assertNotEquals(td.lstIndividualSubscribers[0].Id, lstVoucher[0].Account__c);
        System.assertEquals(dnb.firstName, lstVoucher[0].First_Name__c);
        System.assertEquals(dnb.lastName, lstVoucher[0].Last_Name__c);
        System.assertEquals(dnb.addressLineOne+'\n'+dnb.addressLineTwo+'\n'+dnb.addressLineThree, lstVoucher[0].Mailing_Address__c );
        System.assertEquals(dnb.town, lstVoucher[0].Mailing_Town__c);
        System.assertEquals(dnb.county, lstVoucher[0].Mailing_County__c);
        System.assertEquals(dnb.postcode, lstVoucher[0].Mailing_Postal_Code__c);
        System.assertEquals(dnb.email, lstVoucher[0].Email__c);
        System.assertEquals(dnb.subscriberId, '');
        System.assertEquals(dnb.phone, lstVoucher[0].Phone__c);
        System.assertEquals(dnb.optInEmail==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Email__c);
        System.assertEquals(dnb.optInPhone==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Phone__c);
        System.assertEquals(dnb.optInPost==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_Post__c);
        System.assertEquals(dnb.optInText==DeliverNewspaperHandler.OPTIN_YES, lstVoucher[0].Marketing_Preference_SMS__c);
        System.assertEquals(dnb.retailerId, lstVoucher[0].Retailer_Id__c);
        System.assertEquals(dnb.retailerName, lstVoucher[0].Retailer_Name__c);
        System.assertEquals(dnb.retailerPhoneNumber, lstVoucher[0].Retailer_Phone__c);
        System.assertEquals(dnb.retailerAddressLineOne+'\n'+dnb.retailerAddressLineTwo, lstVoucher[0].Retailer_Address__c);
        System.assertEquals(dnb.retailerTown, lstVoucher[0].Retailer_Town__c);
        System.assertEquals(dnb.retailerPostcode, lstVoucher[0].Retailer_Post_Code__c);

        List<Account> lstAccount = [SELECT  Id, 
                                            RecordTypeId, 
                                            FirstName, 
                                            LastName, 
                                            PersonMailingCity, 
                                            PersonMailingState, 
                                            PersonMailingPostalCode, 
                                            PersonMailingStreet,
                                            PersonEmail,
                                            PersonHomePhone,
                                            TMG_Promo_Email__c,
                                            TMG_Promo_Phone__c,
                                            TMG_Promo_Post__c,
                                            TMG_Promo_SMS__c,
                                            Guid__c
                                        FROM Account WHERE Id = :lstVoucher[0].Account__c];

        System.assert(!lstAccount.isEmpty());
        Account acc = lstAccount[0];
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME, Account.class.getName()), acc.RecordTypeId);
        System.assertEquals(dnb.firstName, acc.FirstName);
        System.assertEquals(dnb.lastName, acc.LastName);
        System.assertEquals(dnb.town, acc.PersonMailingCity);
        System.assertEquals(dnb.county, acc.PersonMailingState);
        System.assertEquals(dnb.postcode.toUpperCase(), acc.PersonMailingPostalCode);
        System.assertEquals(dnb.addressLineOne+'\n'+dnb.addressLineTwo+'\n'+dnb.addressLineThree, acc.PersonMailingStreet);
        System.assertEquals(dnb.email, acc.PersonEmail);
        System.assertEquals(dnb.phone, acc.PersonHomePhone);
        System.assertEquals(1, acc.TMG_Promo_Email__c);
        System.assertEquals(1, acc.TMG_Promo_Phone__c);
        System.assertEquals(1, acc.TMG_Promo_Post__c);
        System.assertEquals(1, acc.TMG_Promo_SMS__c);
        System.assertEquals('GUID__TEST', acc.Guid__c, 'guid not assigned');
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 03/07/2017
    Function - test logic when no account is found (neither by subscriber number, nor by email)
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   10/07/2017  //modified assertion 
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryWithoutMappingFailureDml(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();

        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        dnb.firstName = '';
        dnb.lastName ='kk890';
        dnb.subscriberId = '';
        dnb.email = 'asdfads@telegraph.co.uk';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();
        DeliverNewspaperBean.DeliverNewspaperErrorResponseBean error = (DeliverNewspaperBean.DeliverNewspaperErrorResponseBean) JSON.deserialize(res.responseBody.toString(), DeliverNewspaperBean.DeliverNewspaperErrorResponseBean.class);
        System.assertEquals(400, res.statusCode);
        System.assert(error.error.contains(String.format(Label.DMN_Main_error_message, new List<String>{dnb.firstName, dnb.lastName})));
        List<Webservice_Log__c> lst = [SELECT Id FROM Webservice_Log__c WHERE Event_Name__c = :DeliverNewspaperHandler.ACTION_NAME];
        System.assertEquals(1, lst.size());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 12/07/2017
    Function - test exception when account with the sam guid exists in sfdc under different email 
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryWithoutMappingSAMError(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();

        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        dnb.subscriberId = '';
        dnb.email = 'asdfads@telegraph.co.uk';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;

        Account acc2 = TestDataUtility.newPersonAccount(2, RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB , Account.class.getName()));
        acc2.Guid__c = 'GUID__TEST';
        insert acc2;

        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();
        List<Webservice_Log__c> lst = [SELECT Id, Response_Content__c FROM Webservice_Log__c WHERE Event_Name__c = :DeliverNewspaperHandler.ACTION_NAME];
        System.assertEquals(1, lst.size());
        System.assert(lst[0].Response_Content__c.contains(Label.DMN_duplicate_accounts_by_guid));
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 12/07/2017
    Function - test new sam account creation when none exists for new account created via Deliver My Newspaper endpoint
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testProcessDeliveryWithoutMappingSAMCreated(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkHomeDeliveryVouchersDependencies();
        td.createHomeDeliverySettings();

        DeliverNewspaperBean.DeliverNewspaperBeanData dnb = generateDeliverNewspaperBean(td);
        dnb.subscriberId = '';
        dnb.email = 'asdfads@telegraph.co.uk';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();  
        RestContext.request = req;
        RestContext.response = res;
        SAMUtil.bTestSamCreation = true;
        Test.startTest();
            req.requestBody = Blob.valueOf(JSON.serialize(dnb));
            DeliverNewspaperHandler.processDelivery();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        List<Home_Delivery_Voucher__c> lstVoucher = Database.query('SELECT '+GlobalQueries.generateFieldsListForQuery(Home_Delivery_Voucher__c.class.getName(), null, null)+ ' FROM Home_Delivery_Voucher__c');
        System.assertEquals(1, lstVoucher.size());
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()), lstVoucher[0].RecordTypeId);
        System.assertNotEquals(null, lstVoucher[0].Account__c);
        System.assertNotEquals(td.lstIndividualSubscribers[0].Id, lstVoucher[0].Account__c);
        List<Account> lstAccount = [SELECT  Id, 
                                            RecordTypeId, 
                                            Guid__c
                                        FROM Account WHERE Id = :lstVoucher[0].Account__c];

        System.assert(!lstAccount.isEmpty());
        Account acc = lstAccount[0];
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME, Account.class.getName()), acc.RecordTypeId);
        System.assertEquals('GUID__TEST', acc.Guid__c, 'guid not assigned');
    }
}