/**
* @author Pawel Chrzanowski
* @date 08/09/2016
* @description  Test class for OutboundCallingActivator
#############Change Log#############
**/
@isTest
private class OutboundCallingActivatorTest {

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 08/09/2016
    Function - method to test the Constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    @isTest static void constructorTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallRule();

        ApexPages.StandardController sc;
        OutboundCallingActivator controller;

        PageReference pr = Page.OutboundCallingRuleActivator;
        Test.setCurrentPage(pr);

        sc = new ApexPages.StandardController(tdu.lstOutboundCallRule[0]);
        controller = new OutboundCallingActivator(sc);
        System.assertEquals(controller.ocId, tdu.lstOutboundCallRule[0].Id);
        System.assertEquals(null, controller.errorMessage);
        System.assert(controller.disableButton);
    }
    
    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 08/09/2016
    Function - method to test OC config item activation
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    @isTest static void activateTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallSetting();
        Id ocSettingId = tdu.lstOutboundCallSetting[0].Id;

        List<Outbound_Call_Rule__c> lstOCRules = new List<Outbound_Call_Rule__c>();
        lstOCRules.add(new Outbound_Call_Rule__c(Outbound_Call_Setting__c=ocSettingId, Name='t1', Call_Answered__c=1, Call_Busy__c=1, Call_No_Answer__c=1, Call_Record_Entry__c=1, Active__c=true));
        lstOCRules.add(new Outbound_Call_Rule__c(Outbound_Call_Setting__c=ocSettingId, Name='t2', Call_Answered__c=1, Call_Busy__c=1, Call_No_Answer__c=1, Call_Record_Entry__c=1, Active__c=true));
        lstOCRules.add(new Outbound_Call_Rule__c(Outbound_Call_Setting__c=ocSettingId, Name='t3', Call_Answered__c=1, Call_Busy__c=1, Call_No_Answer__c=1, Call_Record_Entry__c=1, Active__c=true));
        insert lstOCRules;

        ApexPages.StandardController sc;
        OutboundCallingActivator controller;

        PageReference pr = Page.OutboundCallingRuleActivator;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(lstOCRules[0]);
            controller = new OutboundCallingActivator(sc);
            OutboundCallingActivator.activate(lstOCRules[0].Id);

            lstOCRules = [SELECT Name, Active__c, Status__c FROM Outbound_Call_Rule__c];
            for(Outbound_Call_Rule__c ocr : lstOCRules){
                if(ocr.Name == 't1') {
                    System.assert(ocr.Active__c);
                    System.assertEquals(tdu.lstOutboundCallSetting[0].Id, ocr.Status__c);
                }
                if(ocr.Name == 't2') System.assert(!ocr.Active__c);
                if(ocr.Name == 't3') System.assert(!ocr.Active__c);
            }

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 08/09/2016
    Function - method to test OC config item activation - negative scenario
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    @isTest static void activateTest_negative(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createAccount();
        System.assertEquals(Label.OC_Invalid_Object, OutboundCallingActivator.activate(tdu.lstAccounts[0].Id));
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 08/09/2016
    Function - method to test showErrorMessage
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    @isTest static void showErrorMessageTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallRule();

        ApexPages.StandardController sc;
        OutboundCallingActivator controller;

        PageReference pr = Page.OutboundCallingRuleActivator;
        Test.setCurrentPage(pr);

        sc = new ApexPages.StandardController(tdu.lstOutboundCallRule[0]);
        controller = new OutboundCallingActivator(sc);
        controller.errorMessage = 'test message';
        controller.showErrorMessage();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'test message'));
    }
}