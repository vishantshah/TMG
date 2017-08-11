/**
* Author:       Sally ElGhoul (Tquila)
* Date:         22/06/2015
* Description:  this class for testing NewAccountWizardController
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      15/07/2015
* Michal Kwika      26/08/2015
* Michal Kwika      23/09/2015
* Michal Kwika      17/11/2015
* Michal Kwika      12/01/2016
* Michal Szewczyk   04/02/2016
* Michal Szewczyk   21/06/2016 // added PopulateLastNameAccount()
* Pawel Chrzanowski 24/06/2016
* Wiktor Czykin     21/03/2017 //made work after unique email implementation
**/
@isTest
private class NewAccountWizardControllerTest {

    //test the invalid search criteria checks
    static testMethod void testInvalidSearchCriteria() {

        Test.setCurrentPage(Page.NewAccountWizard);

        //error message that not criteria of search is entered
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        controllerObj.FindAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Account_Search_Criteria));

        //error message that the surname value conyains numbers
        controllerObj.strSearchSurname = 'test';
        controllerObj.strSearchPostCode = 'TestPostCode';
        controllerObj.strSearchEmail = 'test';
        controllerObj.FindAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Email_Invalid_Format_Error));

        //error message that the surname value conyains numbers
        controllerObj.strSearchSurname = 'test2';
        controllerObj.strSearchPostCode = 'TestPostCode';
        controllerObj.strSearchEmail = 'test@hotmail.com';
        controllerObj.FindAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Surname_Only_Letters));
    }

    //test the search with valid search criteria
    static testMethod void testValidSearch() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.createRegistrants();

        testDataUtilityObj.lstRegistrants[0].Subscriber_Number_static__c = 'tsNumber111';
        update testDataUtilityObj.lstRegistrants[0];

        NewAccountWizardController controllerObj = new NewAccountWizardController();
        controllerObj.strSearchTsNumber = 'tsNumber111';
        controllerObj.FindAccount();
        //Michal Kwika SUB-679 26/08/2015
        controllerObj.sortCharacter = 'All';
        controllerObj.getSortedAccountsByChar();

    }
    //Michal Kwika - 14/7/2015 - DSS-305
    //test searching one more time - with Whitespaces before Surname
    static testmethod void testValidSearchWithWhitespacesAndPopulation() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.createRegistrants();

        testDataUtilityObj.lstRegistrants[0].PersonMailingPostalCode = 'CR4 1AA';
        testDataUtilityObj.lstRegistrants[0].LastName = 'TestSurnameWithSpaces';

        //Michal Kwika 24/07/2015 SUB-99
        //add also PersonMail value
        testDataUtilityObj.lstRegistrants[0].PersonEmail = 'test@test.com';
        update testDataUtilityObj.lstRegistrants[0];

        NewAccountWizardController controllerObj = new NewAccountWizardController();
        controllerObj.strSearchPostCode = '    CR4 1AA';
        controllerObj.strSearchSurname = '          TestSurnameWithSpaces     ';
        controllerObj.FindAccount();
        //Michal Kwika SUB-679 26/08/2015
        controllerObj.sortCharacter = 'T';
        controllerObj.getSortedAccountsByChar();
    }

    //Michal Kwika - 14/7/2015 - DSS-305
    //test searching with Whitespaces before Surname - invalid
    //and check if txtPostCode is populated into a form (with postcode searching)
    //---Michal Kwika - 24/7/2015 - SUB-99
    static testmethod void testInvalidSearchWithWhitespacesAndPopulation() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.createRegistrants();

        testDataUtilityObj.lstRegistrants[0].PersonMailingPostalCode = 'CR4 1AA';
        testDataUtilityObj.lstRegistrants[0].LastName = 'TestSurnameWithSpaces';
        testDataUtilityObj.lstRegistrants[0].FirstName = 'TestSurnameWithSpaces';
        update testDataUtilityObj.lstRegistrants[0];

        NewAccountWizardController controllerObj = new NewAccountWizardController();
        controllerObj.strSearchPostCode = '    CR4 2BB';
        controllerObj.strSearchSurname = 'InvalidTestSurnameWithSpaces     ';
        controllerObj.strSearchEmail = '   testingNew@test.com   ';
        Test.startTest();
        controllerObj.FindAccount();
        Test.stopTest();
        System.assertEquals(controllerObj.newAccountObj.PersonMailingPostalCode, 'CR4 2BB');
        System.assertEquals(controllerObj.newAccountObj.PersonEmail, 'testingNew@test.com');
        //Michal Kwika SUB-679 26/08/2015
        controllerObj.sortCharacter = 'T';
        controllerObj.sortListAccBasedOnFirstName(testDataUtilityObj.lstRegistrants);
    }

    //validate the checks of creating new account
    //added email validation
    static testmethod void addNewAccountFailure() {
        Test.setCurrentPage(Page.NewAccountWizard);
        TestDataUtility td = new TestDataUtility(1);
        td.CreateCoreApiEndPointSettings();
        td.CreateCoreApiEventEndPointSetting();

        NewAccountWizardController controllerObj = new NewAccountWizardController();

        //empty salutation error message
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Salutation));

        //empty First Name error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Empty_First_Name_Error));

        //empty last name error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Last_Name_Error_Message));

        //Invalid last name format error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'Test2';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Last_Name_Format));

        //Empty email error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Email));

        //Empty Mailing Street error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Mailing_Street), ApexPages.getMessages());

        //Empty Mailing City error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Mailing_City));

        //Empty Mailing Country error message
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = '';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Mailing_Country));

        //Empty Mailing PostCode message for UK cods
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = '';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Postal_Code));

        //Empty State message for US cods
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = '90001';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'US';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.State_Error_Message));

        //Account with given email address already exists
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        td.createRegistrants();
        //then fill the form on page
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = td.lstRegistrants[0].PersonEmail;
        controllerObj.newAccountObj.PersonMailingPostalCode = 'e110lt';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Email_Invalid_Other_Account_Exist));
        
    }
    //new method to validate only phone
    static testMethod void addNewAccountWithoutProperPhone() {
        Test.setCurrentPage(Page.NewAccountWizard);
        TestDataUtility td = new TestDataUtility();
        td.CreateCoreApiEndPointSettings();
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        //Home Phone Validation added
        controllerObj.newAccountObj.title__c = 'Mr';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'ME88RU';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.newAccountObj.PersonHomePhone = '3278 ';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.New_Account_Wizard_Home_Phone_Format_Error_Message), ApexPages.getMessages());

        //Mobile Phone Validation added
        controllerObj.newAccountObj.title__c = 'Mr';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'ME88RU';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.newAccountObj.PersonMobilePhone = '666 ';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.New_Account_Wizard_Mobile_Phone_Format_Error_Message));
    }

    /***************************************************************************************
    * @author Michal Szeczyk
    * @date 21/06/2016
    * @description Validate surname population
    #############Change Log#############
    Modified by         Version     Change Date
    ***************************************************************************************/
    static testmethod void populateLastNameAccount() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        controllerObj.strSearchSurname = 'TestLast';

        controllerObj.FindAccount();
        controllerObj.ShowNewAccountSection();

        System.assertEquals(controllerObj.newContactObj.LastName,controllerObj.strSearchSurname);
    }

    //validate adding new account successfully
    static testmethod void addNewAccountSuccessfully() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();

        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'cr42aa';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingState = 'state';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.SaveNewAccount();
    }

    //Michal Kwika 24/07/2015 SUB-99
    //added eaccount successfully with GivenTitle and marked option
    static testmethod void addNewAccountSuccessfullyWithGivenTitle() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();

        controllerObj.newAccountObj.title__c = 'Sir';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'cr42ab';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingState = 'state';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.isAccountOptIn = true;
        //controllerObj.newAccountObj.isNewAccountOptIn__c = true;
        controllerObj.SaveNewAccount();

        String rtid = controllerObj.RegistrantRecordTypeId;
        controllerObj.setNotificationsOnSite();
        testDataUtilityObj.createRegistrants();
        controllerObj.samAccount = testDataUtilityObj.lstRegistrants.get(0);
        controllerObj.assignSAMaccountToNewAccount();
    }

    //call other controller methods to increase the code coverage
    static testMethod void testControllerOtherMethods() {
        Test.setCurrentPage(Page.NewAccountWizard);
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        string regRecordTypeId = controllerObj.RegistrantRecordTypeId;
        string digitalRecordTypeId = controllerObj.DigitalSubscriberRecordTypeId;
        string individualRecordTypeId = controllerObj.IndividualSubscriberRecordTypeId;
        controllerObj.ShowNewAccountSection();
        controllerObj.getCountries();
        controllerObj.redirectDigitalProduct();
        controllerObj.redirectPrintProduct();
        controllerObj.redirectProductSelectionScreen();
        controllerObj.strSelectedAccountId = 'test';
        controllerObj.redirectManageSubscription();
        controllerObj.getStates();
        boolean Val = controllerObj.isPostalCodeRequired;
        boolean Val1 = controllerObj.isTitleRequired;
        boolean Val2 = controllerObj.isStateRequired;
        controllerObj.RefreshUI();
        controllerObj.goToAccountConversion();
    }

    //Michal Kwika SUB-679 26/08
    //test 2 letters on lastname validation
    static testmethod void testValidationRuleOnForm() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        //test validation rule on last name
        controllerObj.newContactObj.Salutation = 'Mr.';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'T';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = 'ttt111';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'London';
        controllerObj.newAccountObj.PersonMailingState = 'state';
        controllerObj.newAccountObj.PersonMailingCountry = 'GB';
        controllerObj.SaveNewAccount();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Account_LastName_Small));

        //test valdiation rule on first name
        //Michal Kwika 24/09/2015 - off now
        controllerObj.newContactObj.FirstName = 'F';
        controllerObj.newContactObj.LastName = 'Tester';
        controllerObj.SaveNewAccount();
        System.assert(!TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Account_FirstName_Small));
    }

    //Michal Kwika - 24/09/2015 - SUB-930
    //test searching  with new functionality
    static testmethod void testValidSearchWithNoRecords() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.createRegistrants();

        testDataUtilityObj.lstRegistrants[0].PersonMailingPostalCode = 'CR4 1AA';
        testDataUtilityObj.lstRegistrants[0].LastName = 'TestSurnameWithSpaces';
        testDataUtilityObj.lstRegistrants[0].PersonEmail = 'test@test.com';
        update testDataUtilityObj.lstRegistrants[0];

        NewAccountWizardController controllerObj = new NewAccountWizardController();
        controllerObj.strSearchPostCode = '    ME88RU';
        controllerObj.FindAccount();
        //find one more time
        controllerObj.strSearchPostCode = '';
        controllerObj.strSearchSurname = 'Random';
        controllerObj.FindAccount();
        //more coverage
        controllerObj.sortCharacter = null;
        controllerObj.getSortedAccountsByChar();
        AccountUtility.getNonRegistrantAccounts(testDataUtilityObj.lstRegistrants);
    }

    //Michal Kwika - 24/09/2015 - SUB-930
    //add account from USA
    static testmethod void addNewAccountFromUSA() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.setCurrentPage(Page.NewAccountWizard);
        NewAccountWizardController controllerObj = new NewAccountWizardController();
        testDataUtility testDataUtilityObj = new testDataUtility(1);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiEventEndPointSetting();

        controllerObj.newAccountObj.title__c = 'Mr';
        controllerObj.newContactObj.FirstName = 'TestFirst';
        controllerObj.newContactObj.LastName = 'TestLast';
        controllerObj.newAccountObj.PersonEmail = 'test@test.com';
        controllerObj.newAccountObj.PersonMailingPostalCode = '45674';
        controllerObj.newAccountObj.PersonMailingStreet = 'Street1';
        controllerObj.newAccountObj.PersonMailingCity = 'RandomCity';
        controllerObj.newAccountObj.PersonMailingState = 'Alabama';
        controllerObj.newAccountObj.PersonMailingCountry = 'US';
        controllerObj.isAccountOptIn = true;
        controllerObj.SaveNewAccount();
    }

    static testMethod void liteAccountTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createRegistrants();

        Test.setCurrentPage(Page.NewAccountWizard);
        ApexPages.currentPage().getParameters().put('id', tdu.lstRegistrants[0].Id);

        NewAccountWizardController ctrl = new NewAccountWizardController();
        System.assert(!ctrl.showSearchPanel);
    }

    @testsetup
    static void neededDataForTestClass() {
        TestDataUtility testDataUtilityObjCS = new TestDataUtility(1);
        testDataUtilityObjCS.createSAMknownUserConversionCS(true);
    }
}
