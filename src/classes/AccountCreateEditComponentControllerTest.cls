/**
* @author Wiktor Czykin 
* @date 24/07/2017
* @description  tests for AccountCreateEditComponentController
*#############Change Log#############
*Modified by     Version     Change Date
*/
@isTest
private class AccountCreateEditComponentControllerTest {
    
    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - constructor init assertions
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testInitNoAccount(){
        Test.startTest();
            AccountCreateEditComponentController ace = new AccountCreateEditComponentController();
            System.assertNotEquals(null, ace.getAccount());
            System.assertNotEquals(null, ace.acc);
            System.assertEquals(RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_PERSONACCOUNT_INDIVIDUAL_SUBSCRIBER, Account.class.getName()), ace.acc.RecordTypeId);
            System.assertNotEquals(null, ace.contact);
            System.assertEquals('', ace.contact.FirstName);
            System.assertEquals('', ace.contact.LastName);
            System.assertEquals('', ace.contact.Salutation);
            System.assert(!ace.tmgPromoEmail);
            System.assert(!ace.tmgPromoPhone);
            System.assert(!ace.tmgPromoPost);
            System.assert(!ace.tmgPromoSms);
            ace.acc = null;
            System.assertNotEquals(null, ace.getAccount());
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - constructor init assertions - account passed in
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testInitWithAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        Test.startTest();
            try{
                AccountCreateEditComponentController ace = new AccountCreateEditComponentController(null);
                System.assert(false, 'exception not thrown');
            }catch(TelegraphApplicationException e){
                System.assert(e.getMessage().contains('Null account'));
            }
            AccountCreateEditComponentController ace = new AccountCreateEditComponentController(td.lstIndividualSubscribers[0]);


        Test.stopTest();
        System.assertNotEquals(null, ace.acc);
        System.assertNotEquals(null, ace.acc.Id);

        System.assertEquals(td.lstIndividualSubscribers[0].RecordTypeId, ace.acc.RecordTypeId);
        System.assertNotEquals(null, ace.contact);
        System.assertEquals(td.lstIndividualSubscribers[0].FirstName, ace.contact.FirstName);
        System.assertEquals(td.lstIndividualSubscribers[0].LastName, ace.contact.LastName);
        System.assertEquals(td.lstIndividualSubscribers[0].Salutation, ace.contact.Salutation);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - test save positive
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testSaveAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkAccountDependencies();
        List<Country_Codes__c> lst = td.loadCountryCodes();

        AccountCreateEditComponentController ace = new AccountCreateEditComponentController();
        Test.startTest();
            ace.tmgPromoEmail = true;
            ace.tmgPromoPhone = true;
            ace.tmgPromoPost = true;
            ace.tmgPromoSms = true;
            ace.contact.FirstName = 'kot';
            ace.contact.LastName = 'jaroslawa';
            ace.contact.Salutation = 'mrs';
            ace.acc.Title__c = 'kitka';
            ace.acc.PersonMailingStreet = 'street1';
            ace.acc.PersonMailingState = 'state1';
            ace.acc.PersonMailingPostalCode = 'sw1w 0dt';
            ace.acc.PersonMailingCity = 'London';
            ace.acc.PersonHomePhone = '099999';
            ace.acc.PersonMobilePhone = '088888';
            ace.acc.PersonEmail = 'someemail@telegraph.co.uk';
            ace.setGuid('test_guid');
            System.assertEquals('test_guid', ace.acc.Guid__c);

            System.assertEquals(lst.size(), ace.getCountries().size());
            ace.saveAccount();
        Test.stopTest();
        List<Account> lstAccount = [SELECT  Id, 
                                            Salutation,
                                            FirstName,
                                            LastName,
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
                                        FROM Account];
        System.assertEquals(1, lstAccount.size());
        Account a = lstAccount[0];
        System.assert(String.isNotBlank(a.Guid__c));
        System.assertEquals(ace.acc.Title__c, a.Salutation);
        System.assertEquals(ace.acc.PersonMailingStreet, a.PersonMailingStreet);
        System.assertEquals(ace.acc.PersonMailingState, a.PersonMailingState);
        System.assertEquals(ace.acc.PersonMailingPostalCode.toUpperCase(), a.PersonMailingPostalCode);
        System.assertEquals(ace.acc.PersonMailingCity, a.PersonMailingCity);
        System.assertEquals(ace.acc.PersonHomePhone, a.PersonHomePhone);
        System.assertEquals(ace.acc.PersonEmail, a.PersonEmail);
        System.assertEquals(ace.contact.FirstName, a.FirstName);
        System.assertEquals(ace.contact.LastName, a.LastName);
        System.assertEquals(1, a.TMG_Promo_Email__c);
        System.assertEquals(1, a.TMG_Promo_Phone__c);
        System.assertEquals(1, a.TMG_Promo_Post__c);
        System.assertEquals(1, a.TMG_Promo_SMS__c);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 24/07/2017
    Function - test validation failures
    #############Change Log#############
    Modified by     Change Date  
    ****************************************************************************************/
    private static testMethod void testValidation(){
        AccountCreateEditComponentController ace = new AccountCreateEditComponentController();
        Test.startTest();
            ace.contact.FirstName = 'kot';
            ace.contact.LastName = 'jaroslawa';
            ace.contact.Salutation = '';
            ace.acc.PersonMailingStreet = 'street1';
            ace.acc.PersonMailingState = 'state1';
            ace.acc.PersonMailingPostalCode = 'sw1w 0dt';
            ace.acc.PersonMailingCity = 'London';
            ace.acc.PersonHomePhone = '099999';
            ace.acc.PersonMobilePhone = '088888';
            ace.acc.PersonEmail = 'someemail@telegraph.co.uk';

            ace.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Salutation));
            ace.contact.Salutation = 'Mrs';

            ace.contact.FirstName = '999';
            ace.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_First_name_validation));

            ace.contact.FirstName = 'abc';
            ace.contact.LastName = '9909';
            ace.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Last_name_validation));

            ace.contact.LastName = 'abcde';
            ace.acc.PersonMobilePhone = 'asdfasdf';
            ace.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Mobile_number_validation));

            ace.acc.PersonMobilePhone = '0865854325';
            ace.acc.PersonHomePhone = 'dsfasfd';
            ace.saveAccount();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_Mobile_number_validation));
        Test.stopTest();
    }
}