/**
* Author:       Michal Kwika (Accenture)
* Date:         11/11/2015
* Description:  this class is the controller test class of converting accounts
* ******************* Change Log *******************
* Modified By   Version     Change Date
* Michal Kwika  1.1         15/01/2016
* Wiktor Czykin 1.2         17/02/2016  //modified testConvertAccountFailure() and testConvertWhileOtherAccountExistsWithThatEmail() and method names
* Michal Kwika  1.3         19/02/2016  //changed to CreateFireAccountCreationCustomSetting() method
* Wiktor Czykin 1.4         14/03/2016  //removed no longer used references across methods
* Wiktor Czykin 1.5         20/03/2017  //removedtestConvertWhileOtherAccountExistsWithThatEmail() as no longer valid when emails are unique in sfdc
**/
@isTest
private class Account_ConvertToRegistrantCtrlTest {

    static testMethod void testConvertWithoutId() {
        Test.setCurrentPage(Page.Account_ConvertToRegistrant);
        testDataUtility testDataUtilityObj = new TestDataUtility(1);
        //error message that not criteria of search is entered
        Account_ConvertToRegistrantCtrl controllerObj = new Account_ConvertToRegistrantCtrl();
        system.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.No_Account));
    }

    static testMethod void testConvertWrongRT() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        //Create zquote record and this function will create a registrant as well
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        Test.setCurrentPage(Page.Account_ConvertToRegistrant);
        testDataUtilityObj.createZquotes();
        ApexPages.currentPage().getParameters().put('id', testDataUtilityObj.lstRegistrants[0].id);
        Account_ConvertToRegistrantCtrl controllerObj = new Account_ConvertToRegistrantCtrl();
        //system.assert(TestDataUtility.CheckMessageExist(ApexPages.getMessages(),Label.Convert_Account_Error_IsRegistrant));
    }

    static testMethod void testConvertValid() {
        Test.setCurrentPage(Page.Account_ConvertToRegistrant);
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.loadCountryCodes();

        testDataUtilityObj.createIndividualSubscribers();
        Account testAccount = testDataUtilityObj.lstIndividualSubscribers.get(0);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        Account_ConvertToRegistrantCtrl controllerObj = new Account_ConvertToRegistrantCtrl();

        //set new valid Account obj
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = '';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'me88ru';
        //set marketing to TRUE
        controllerObj.isAccountOptIn = true;
        controllerObj.SaveNewAccount();
        //insert custom settings and mockups
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        testDataUtilityObj.CreateCoreApiEndPointSettings();
        testDataUtilityObj.createFireAccountCreationCustomSetting(true);
        controllerObj.SaveNewAccount();

        //improve code coverage
        Boolean title = controllerObj.isTitleRequired;
        Boolean state = controllerObj.isStateRequired;
        Boolean isShown = controllerObj.showNewAccoountForm;
        Boolean isAccountOpt = controllerObj.isAccountOptIn;
        Boolean pcode = controllerObj.isPostalCodeRequired;

        //invoke method
        controllerObj.getCountries();
        controllerObj.getStates();
        controllerObj.redirectManageSubscription();
        controllerObj.RefreshUI();
    }

    /*************************************************************************************** 
    Developer - Michał Kwika
    Date - Unknown
    Version - 1.0
    Function - validate the checks of converting new account
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         17/02/2016  //updated based on account creation main method change
    ****************************************************************************************/
    static testmethod void testConvertAccountFailure() {
        Test.setCurrentPage(Page.Account_ConvertToRegistrant);
        testDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createIndividualSubscribers();
        Account testAccount = testDataUtilityObj.lstIndividualSubscribers.get(0);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        Account_ConvertToRegistrantCtrl controllerObj = new Account_ConvertToRegistrantCtrl();
        //clear basic fields
        controllerObj.newAccountObj.FirstName = '';
        controllerObj.newAccountObj.LastName = '';
        controllerObj.newAccountObj.PersonEmail = '';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.newAccountObj.Salutation = '';
        //empty salutation error message
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Salutation), ApexPages.getMessages());

        //empty First Name error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Empty_First_Name_Error),ApexPages.getMessages());

        //empty last name error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Last_Name_Error_Message));

        //Invalid last name format error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'Test2';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Last_Name_Format));

        //Invalid last name too short message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'T';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Account_LastName_Small));

        //Empty email error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Email));

        //Empty Mailing Street error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.newAccountObj.PersonMailingStreet = '';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Mailing_Street), ApexPages.getMessages());

        //Empty Mailing City error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = '';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Mailing_City));

        //Empty Mailing Country error message
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = '';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Mailing_Country));

        //Empty Mailing PostCode message for UK cods
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = '';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Postal_Code));

        //Empty State message for US cods
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.FirstName = 'TestFirst';
        controllerObj.newAccountObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = '90001';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'US';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.State_Error_Message));

        //Home Phone Validation added
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'ME88RU';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.newAccountObj.PersonHomePhone = '3278 ';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.New_Account_Wizard_Home_Phone_Format_Error_Message));

        //Mobile Phone Validation added
        controllerObj.newAccountObj.Salutation = 'Mr.';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'ME88RU';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.newAccountObj.PersonMobilePhone = '666 ';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.New_Account_Wizard_Mobile_Phone_Format_Error_Message));

        //improve code coverage
        Boolean title = controllerObj.isTitleRequired;
        Boolean state = controllerObj.isStateRequired;
        Boolean isShown = controllerObj.showNewAccoountForm;
        Boolean isAccountOpt = controllerObj.isAccountOptIn;
        Boolean pcode = controllerObj.isPostalCodeRequired;
    }

}