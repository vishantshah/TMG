/**
* Author:       Sally ElGhoul (Tquila)
* Date:         28/04/2015
* Description:  Testing class for "CoreAPICalloutUtility"
*
* ******************* Change Log *******************
* Modified by       @version    Change Date
* Michal Kwika      1.1         27/01/2016
* Michal Kwika      1.2         03/02/2016 - added double encoding CS dependency
* Wiktor Czykin     1.3         22/02/2016 - modified testSendNewRecordCreatedEventToSAM(), added testSendBulkEvents()
* Gavin Palmer      1.4         22/06/2016 - modified testGetNumEmailsInSAM() and testGetProfileFromSAM()
**/
@isTest
private class CoreAPICalloutUtilityTest {
    @testSetup
    static void initialize() {
        TestDataUtility testDataUtilityObj = new TestDataUtility(2);
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiResetPasswordEndPointSetting();
        testDataUtilityObj.CreateCoreApiEndPointSettings();
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiOfferCodeEndPointSetting();
        //Create the custom setting
        testDataUtilityObj.CreateCoreApiAllOfferCodesEndPointSetting();
        //Create custom setting -search by email
        testDataUtilityObj.CreateCoreApiSamUserSearchByEmailSetting();
        //create custom setting for SAM profile
        testDataUtilityObj.createCoreApiSamUserGetProfileSetting();
        //Create a registrants
        testDataUtilityObj.createRegistrants();
        //add new custom setting setup
        testDataUtilityObj.createCoreAPIdoubleEncodingCS(true);
    }

    /***************************************************************************************
    Developer Unknown
    Date Unknown
    Function Test coreApi callout for single record event
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         22/02/2016 //added assertion for logging
    ****************************************************************************************/
    static testMethod void testSendNewRecordCreatedEventToSAM() {
        List <Account> lstRegistrants = [SELECT Id, PersonEmail FROM Account LIMIT 1];
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        
        Test.startTest();
            CoreAPICalloutUtility.SendObjectEvent(Constants.NEW_RECORD_CREATED_ACTION_NAME, Account.class.getName(), lstRegistrants[0].id);
        Test.stopTest();
        List<WebService_Log__c> lstlog = [select Id, Response_Content__c, Response_Time__c, Parameters__c from WebService_Log__c];
        System.assert(!lstlog.isEmpty());
        System.assertEquals(1, lstlog.size());
        System.assertNotEquals(null, lstLog[0].Response_Time__c, lstLog[0].Response_Time__c);
        System.assertNotEquals(null, lstLog[0].Response_Content__c);

    }

    static testMethod void testResetPasswordSuccess() {
        List <Account> lstRegistrants = [SELECT Id, PersonEmail FROM Account LIMIT 1];

        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(204, 'ResetPassword');
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);
        //Try to call the callout
        Test.startTest();
        CoreAPICalloutUtility.ResetPassword(lstRegistrants[0].PersonEmail);
        Test.stopTest();
    }

    static testMethod void testResetPasswordFailure() {
        List <Account> lstRegistrants = [SELECT Id, PersonEmail FROM Account LIMIT 1];
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(404, 'ResetPassword');
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.startTest();
        //Try to call the callout
        CoreAPICalloutUtility.ResetPassword(lstRegistrants[0].PersonEmail);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        26/05/2015
    Function    Testing get offer Details
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         27/01/2016
    ****************************************************************************************/
    static testMethod void testGetOfferCode() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200, 'GetOfferCode');
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.startTest();
        //Try to call the callout
        CoreAPICalloutUtility.GetOfferCode('TestValue');
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        13/11/2015
    Function    Test Get All Offer Codes
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         27/01/2016
    ****************************************************************************************/
    static testMethod void testGetAllOfferCodes() {

        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200, 'GetAllOfferCodes');
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.startTest();
        //Try to call the callout
        CoreAPICalloutUtility.GetAllOfferCodes();
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        05/08/2015
    Function    Testing part of checking Email in SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Gavin Palmer        1.1         22/06/2016 // modified callout to non static method
    ****************************************************************************************/
    static testMethod void testGetNumEmailsInSAM() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200, 3);
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.startTest();
        //Try to call
        CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
        calloutUtility.getNumOfEmailsInSAM('test@test.com');
        Boolean title = CoreAPICalloutUtility.checkIfSalutation('Lord');
        title = CoreAPICalloutUtility.checkIfSalutation('Dr');
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        27/01/2016
    Function    Testing part of getting Profile from SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Gavin Palmer        1.1         22/06/2016 // modified callout to non static method
    ****************************************************************************************/
    static testMethod void testGetProfileFromSAM() {
        // Set mock callout class
        MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200, 'getProfileFromSAM');
        Test.setMock(HttpCalloutMock.class, ResponseGenerator);

        Test.startTest();
        CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
        calloutUtility.getProfileFromSAM('baaa12343545365-423424-3-21314');
        Test.stopTest();
    }

    /***************************************************************************************
    Developer Wiktor Czykin
    Date 22/02/2016
    Function Test for bulk event handling future method
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSendBulkEvents(){
        TestDataUtility td = new TestDataUtility(10);
        TestDataUtility.iAccountEmailDifferentiator = 100;
        td.createIndividualSubscribers();
        
        Set<Id> setAccountId = new Set<Id>();
        for(Account acc : td.lstIndividualSubscribers){
            setAccountId.add(acc.Id);
        }
        Test.startTest();
            MockHttpCoreApiResponseGenerator responseGenerator = new MockHttpCoreApiResponseGenerator(200);
            Test.setMock(HttpCalloutMock.class, responseGenerator);
            CoreAPICalloutUtility.sendBulkEvents(Constants.NEW_RECORD_CREATED_ACTION_NAME, Account.class.getName(), setAccountId);
        Test.stopTest();
        List<WebService_Log__c> lstlog = [select Id, Response_Content__c, Response_Time__c, Parameters__c from WebService_Log__c];
        System.assert(!lstlog.isEmpty());
        System.assertEquals(1, lstlog.size());
        System.assertNotEquals(null, lstLog[0].Response_Time__c, lstLog[0].Response_Time__c);
        System.assertNotEquals(null, lstLog[0].Response_Content__c);
    }
}