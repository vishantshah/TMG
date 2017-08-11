/**
* @author Wiktor Czykin
* @date 30/03/2015
* @description
*#############Change Log#############
*Modified by        Version     Change Date
**/
@isTest
private class OfferTriggerHandlerTest {

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/03/2017
    Version - 1.0
    Function - test name uniqueness field population on insert
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testNameCopyOnCreate(){
        TestDataUtility td = new TestDataUtility(3);
        Test.startTest();
            td.createOffers();
        Test.stopTest();
        List<Offer__c> lstOffers = [SELECT Id, Name, Offer_Name_Uniqueness__c FROM Offer__c];
        System.assert(!lstOffers.isEmpty());
        for(Offer__c o : lstOffers){
            System.assertEquals(o.Name, o.Offer_Name_Uniqueness__c);
        }
        List<Webservice_Log__c> lstLogs = [SELECT Id FROM Webservice_Log__c];
        System.assert(lstLogs.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/03/2017
    Version - 1.0
    Function - test name uniqueness field update on update
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testNameCopyOnUpdate(){
        TestDataUtility td = new TestDataUtility(3);
        td.createOffers();
        Test.startTest();
            for(Offer__c o : td.lstOffers){
                o.Name +='test2';
            }
            update td.lstOffers;
        Test.stopTest();
        List<Offer__c> lstOffers = [SELECT Id, Name, Offer_Name_Uniqueness__c FROM Offer__c];
        System.assert(!lstOffers.isEmpty());
        for(Offer__c o : lstOffers){
            System.assertEquals(o.Name, o.Offer_Name_Uniqueness__c);
        }
        List<Webservice_Log__c> lstLogs = [SELECT Id FROM Webservice_Log__c];
        System.assert(lstLogs.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 04/04/2017
    Version - 1.0
    Function - test that notification callout is made on insert
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCoreApiInsertCallout(){
        TestDataUtility td = new TestDataUtility(1);
        td.createFireOfferApiSync();
        td.createCoreApiEndPointSettings();
        MockHttpCoreApiResponseGenerator responseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, responseGenerator);
        Test.startTest();
            td.createOffers();
        Test.stopTest();
        List<Webservice_Log__c> lstLogs = [SELECT Id FROM Webservice_Log__c];
        System.assert(!lstLogs.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 04/04/2017
    Version - 1.0
    Function - test that notification callout is made on update
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCoreApiUpdateCallout(){
        TestDataUtility td = new TestDataUtility(1);
        td.createCoreApiEndPointSettings();
        td.createOffers();
        td.createFireOfferApiSync();
        OfferTriggerHandler.getInstance().bRunCoreApiCallouts = true;
        MockHttpCoreApiResponseGenerator responseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, responseGenerator);
        Test.startTest();
            update td.lstOffers;
        Test.stopTest();
        List<Webservice_Log__c> lstLogs = [SELECT Id FROM Webservice_Log__c];
        System.assert(!lstLogs.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 11/04/2017
    Version - 1.0
    Function - test that notification callout is made on delete
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCoreApiDeleteCallout(){
        TestDataUtility td = new TestDataUtility(1);
        td.createCoreApiEndPointSettings();
        td.createOffers();
        td.createFireOfferApiSync();
        OfferTriggerHandler.getInstance().bRunCoreApiCallouts = true;
        MockHttpCoreApiResponseGenerator responseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, responseGenerator);
        Test.startTest();
            delete td.lstOffers;
        Test.stopTest();
        List<Webservice_Log__c> lstLogs = [SELECT Id FROM Webservice_Log__c];
        System.assert(!lstLogs.isEmpty());
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 11/04/2017
    Version - 1.0
    Function - test that notification callout is made on undelete
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testCoreApiUndeleteCallout(){
        TestDataUtility td = new TestDataUtility(1);
        td.createCoreApiEndPointSettings();
        td.createOffers();
        td.createFireOfferApiSync();
        OfferTriggerHandler.getInstance().bRunCoreApiCallouts = true;
        MockHttpCoreApiResponseGenerator responseGenerator = new MockHttpCoreApiResponseGenerator(200);
        Test.setMock(HttpCalloutMock.class, responseGenerator);
        Test.startTest();
            delete td.lstOffers;
            undelete td.lstOffers;
        Test.stopTest();
        List<Webservice_Log__c> lstLogs = [SELECT Id FROM Webservice_Log__c];
        System.assert(!lstLogs.isEmpty());
        System.assertEquals(td.iCounter*2, lstLogs.size());
    }
}
