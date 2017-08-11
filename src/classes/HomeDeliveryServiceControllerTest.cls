/**
* @author Wiktor Czykin 
* @date 24/07/2017
* @description  tests for HomeDeliveryServiceController
*#############Change Log#############
*Modified by     Change Date
*/
@isTest
public with sharing class HomeDeliveryServiceControllerTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - just basic assertion of init
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testInit(){
        Test.startTest();
            HomeDeliveryServiceController hds = new HomeDeliveryServiceController(new ApexPages.StandardController(new Account()));
        Test.stopTest();
        System.assertNotEquals(null, hds.accEditController);
        System.assertNotEquals(null, hds.homeDeliveryItem);
        System.assertEquals(RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()), hds.homeDeliveryItem.RecordTypeId);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - test successful creation of Account and related Home Delivery Service record 
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testSaveAndNew(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkAccountDependencies();
        td.loadCountryCodes();
        td.createZProductFeatures();
        td.lstZFeature[0].Active_Days__c = 'SAT-SUN';
        update td.lstZFeature;
        Map<String, Home_Delivery_Settings__c> mapSettings = td.createHomeDeliverySettings();
        
        td.createRetailers();

        Test.startTest();
            HomeDeliveryServiceController hds = new HomeDeliveryServiceController(new ApexPages.StandardController(new Account()));
            HomeDeliveryServiceController.bForceSamCreation = true;

            Account acc = hds.accEditController.getAccount();
            hds.accEditController.tmgPromoEmail = true;
            hds.accEditController.tmgPromoPhone = true;
            hds.accEditController.tmgPromoPost = true;
            hds.accEditController.tmgPromoSms = true;
            hds.accEditController.contact.FirstName = 'kot';
            hds.accEditController.contact.LastName = 'jaroslawa';
            hds.accEditController.contact.Salutation = 'mrs';
            acc.Title__c = 'kitka';
            acc.PersonMailingStreet = 'street1';
            acc.PersonMailingState = 'state1';
            acc.PersonMailingPostalCode = 'sw1w 0dt';
            acc.PersonMailingCity = 'London';
            acc.PersonHomePhone = '099999';
            acc.PersonMobilePhone = '088888';
            acc.PersonEmail = 'someemail@telegraph.co.uk';
            hds.homeDeliveryItem.Retailer__c = td.lstRetailers[0].Id;
            hds.homeDeliveryItem.Delivery_Days__c = 'Sat;Sun';
            PageReference pr = hds.saveDetailsAndNew(); 
        Test.stopTest();
        System.assertNotEquals(null, pr, ApexPages.getMessages());

        List<Account> lstAccount = [SELECT  Id, 
                                            Salutation,
                                            FirstName,
                                            LastName,
                                            Subscriber_Number__c,
                                            PersonMailingStreet,
                                            PersonMailingState,
                                            PersonMailingPostalCode,
                                            PersonMailingCity,
                                            TMG_Promo_Email__c,
                                            TMG_Promo_Phone__c,
                                            TMG_Promo_Post__c,
                                            TMG_Promo_SMS__c,
                                            PersonHomePhone,
                                            PersonEmail,
                                            Guid__c
                                        FROM Account 
                                        WHERE RecordTypeId = :RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_PERSONACCOUNT_INDIVIDUAL_SUBSCRIBER, Account.class.getName())];
        System.assertEquals(1, lstAccount.size());
        Account a = lstAccount[0];
        System.assert(String.isNotBlank(a.Guid__c));
        System.assertEquals(acc.Title__c, a.Salutation);
        System.assertEquals(acc.PersonMailingStreet, a.PersonMailingStreet);
        System.assertEquals(acc.PersonMailingState, a.PersonMailingState);
        System.assertEquals(acc.PersonMailingPostalCode.toUpperCase(), a.PersonMailingPostalCode);
        System.assertEquals(acc.PersonMailingCity, a.PersonMailingCity);
        System.assertEquals(acc.PersonHomePhone, a.PersonHomePhone);
        System.assertEquals(acc.PersonEmail, a.PersonEmail);
        System.assertEquals(hds.accEditController.contact.FirstName, a.FirstName);
        System.assertEquals(hds.accEditController.contact.LastName, a.LastName);
        List<Home_Delivery_Voucher__c> lstHdv = [SELECT Id, 
                                                        Account__c, 
                                                        Delivery_Days__c, 
                                                        Description__c,
                                                        Email__c,
                                                        First_Name__c,
                                                        Last_Name__c,
                                                        Mailing_Address__c,
                                                        Mailing_County__c,
                                                        Mailing_Postal_Code__c,
                                                        Mailing_Town__c,
                                                        Marketing_Preference_Email__c,
                                                        Marketing_Preference_Phone__c,
                                                        Marketing_Preference_Post__c,
                                                        Marketing_Preference_SMS__c,
                                                        Offer_Name__c,
                                                        Phone__c,
                                                        Product__c,
                                                        Retailer__c,
                                                        Subscriber_Number__c
                                                    FROM Home_Delivery_Voucher__c
                                                    WHERE Id = :hds.homeDeliveryItem.Id];
        System.assertEquals(1, lstHdv.size());
        Home_Delivery_Voucher__c h = lstHdv[0];
        System.assertEquals(a.FirstName, h.First_Name__c);
        System.assertEquals(a.LastName, h.Last_Name__c);
        System.assert(String.isNotBlank(h.Delivery_Days__c));
        System.assertEquals(mapSettings.get(Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME).Offer_Name__c, h.Offer_Name__c);
        System.assertEquals(mapSettings.get(Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME).Offer_Description__c, h.Description__c);
        System.assertEquals(a.PersonEmail, h.Email__c);
        System.assertEquals(a.PersonMailingStreet, h.Mailing_Address__c);
        System.assertEquals(a.PersonMailingState, h.Mailing_County__c);
        System.assertEquals(a.PersonMailingPostalCode, h.Mailing_Postal_Code__c);
        System.assertEquals(a.PersonMailingCity, h.Mailing_Town__c);
        System.assertEquals(a.PersonHomePhone, h.Phone__c);
        System.assertEquals(td.lstZProducts[0].Id, h.Product__c);
        System.assertEquals(a.TMG_Promo_Email__c, h.Marketing_Preference_Email__c?1:0);
        System.assertEquals(a.TMG_Promo_Phone__c, h.Marketing_Preference_Phone__c?1:0);
        System.assertEquals(a.TMG_Promo_Post__c, h.Marketing_Preference_Post__c?1:0);
        System.assertEquals(a.TMG_Promo_SMS__c, h.Marketing_Preference_SMS__c?1:0);
        System.assertEquals(td.lstRetailers[0].Id, h.Retailer__c);
        System.assertEquals(a.Subscriber_Number__c, h.Subscriber_Number__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - test failure of insert of Home_Delivery_Voucher__c
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testSaveFailure(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadCountryCodes();
        td.createZProductFeatures();
        td.lstZFeature[0].Active_Days__c = 'SAT-SUN';
        update td.lstZFeature;
        td.createRetailers();
        Test.startTest();
            HomeDeliveryServiceController hds = new HomeDeliveryServiceController(new ApexPages.StandardController(new Account()));
            Account acc = hds.accEditController.getAccount();
            hds.accEditController.contact.FirstName = 'kot';
            hds.accEditController.contact.LastName = 'jaroslawa';
            hds.accEditController.contact.Salutation = 'mrs';
            acc.PersonMailingStreet = 'street1';
            acc.PersonMailingState = 'state1';
            acc.PersonMailingPostalCode = 'sw1w 0dt';
            acc.PersonMailingCity = 'London';
            acc.PersonHomePhone = '099999';
            hds.homeDeliveryItem.Retailer__c = td.lstRetailers[0].Id;
            hds.homeDeliveryItem.Delivery_Days__c = 'SatSun';
            PageReference pr = hds.saveDetails();
        Test.stopTest();
        System.assertEquals(null, pr);
        List<Account> lstAccount = [SELECT  Id FROM Account 
                                        WHERE RecordTypeId = :RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_PERSONACCOUNT_INDIVIDUAL_SUBSCRIBER, Account.class.getName())];
        System.assert(lstAccount.isEmpty());
    }
}