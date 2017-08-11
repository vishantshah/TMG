/**
* @author Michal Szewczyk
* @date 01/08/2016
* @description Test class for OutboundCallingCCExpiryCtrl
* #############Change Log#############
* Modified by           Version     Change Date
* Michal Szewczyk       1.1         2/8/2016    //changed outboundCallingBalanceReviewCtrl_GetCustomerTest method
* Mantas Grigaliunas    1.2         30/08/2016  //added constant string for outbound calling setting paramters
* Mantas Grigaliunas    1.2         30/08/2016 //renamed field OC_Stage_1_Call_Date_Time__c to OC_Stage_6_Call_Date_Time__c
**/
@isTest
private class OutboundCallingCCExpiryCtrlTest {

    private final static String PARAMETER = '{'
    +   '  "callStageParameters": [ {'
    +   '  "stagename": "CCEX1",'
    +   '  "outcome": "OC_Stage_6_Outcome__c",'
    +   '  "calldatetime": "OC_Stage_6_Call_Date_Time__c",'
    +   '  "nosalereason": "",'
    +   '  "tcode": "",'
    +   '  "offset": 0'
    +   '}] }';
    
    /************************************************************************************
    Developer - Michal Szewczyk
    Date - 01/08/2016
    Version - 1.0
    Function - method to test the Constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void outboundCallingBalanceReviewCtrl_NoOCSetting(){
        TestDataUtility tdu = new TestDataUtility(1);

        OutboundCallingCCExpiryCtrl controller;
        PageReference pr = Page.OutboundCallingCCExpiry;
        Test.setCurrentPage(pr);

        Test.startTest();

            //no Outbound Call Setting
            tdu.createOutboundCallSetting();
            tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_CREDIT_CARD_EXPIRY_VF_PAGE_NAME;
            update tdu.lstOutboundCallSetting[0];
            controller = new OutboundCallingCCExpiryCtrl();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_OCS_Incomplete));
            
            //No Outbound Call Setting Parameters
            tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME;
            update tdu.lstOutboundCallSetting[0];
            controller = new OutboundCallingCCExpiryCtrl();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_OCS_Parameters_Error));
            System.assert(!controller.hasCustomer);
        Test.stopTest();
    }

    /************************************************************************************
    Developer - Michal Szewczyk
    Date - 01/08/2016
    Version - 1.0
    Function - method to test the Constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void outboundCallingBalanceReviewCtrl_NoOCRule(){
        TestDataUtility tdu = new TestDataUtility(1);

        tdu.createOutboundCallSetting();
        tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_CREDIT_CARD_EXPIRY_VF_PAGE_NAME;
        tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME;
        tdu.lstOutboundCallSetting[0].Parameters__c = PARAMETER;
        update tdu.lstOutboundCallSetting[0];

        OutboundCallingCCExpiryCtrl controller;
        PageReference pr = Page.OutboundCallingCCExpiry;
        Test.setCurrentPage(pr);

        Test.startTest();

            controller = new OutboundCallingCCExpiryCtrl();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.OC_OCR_Not_Found));

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Michal Szewczyk
    Date - 01/08/2016
    Version - 1.0
    Function - method to test the Constructor
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         2/08/2016  // added tests for save
    *************************************************************************************/
    static testMethod void outboundCallingBalanceReviewCtrl_GetCustomerTest(){
        TestDataUtility tdu = new TestDataUtility(1);

        tdu.createOutboundCallSetting();
        tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_CREDIT_CARD_EXPIRY_VF_PAGE_NAME;
        tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_CREDIT_CARD_EXPIRY_RECORD_TYPE_NAME;
        tdu.lstOutboundCallSetting[0].Parameters__c = PARAMETER;
        update tdu.lstOutboundCallSetting[0];

        tdu.createOutboundCallRule();
        tdu.lstOutboundCallRule[0].Priority_Field__c = 'Priority';
        update tdu.lstOutboundCallRule[0];

        tdu.createSubscriptions();

        tdu.createCase();
        tdu.lstCases[0].Status = Constants.UPGRADE_IN_PROGRESS;
        tdu.lstCases[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, tdu.lstOutboundCallSetting[0].Case_Record_Type__c, Case.class.getName());
        tdu.lstCases[0].OC_Call_Stage__c = 'CCEX1';
        tdu.lstCases[0].OC_Stage_6_Call_Date_Time__c = DateTime.now().addYears(-1);
        tdu.lstCases[0].AccountId = tdu.lstIndividualSubscribers[0].Id;
        tdu.lstCases[0].Print_Subscription__c = tdu.lstSubscriptions[0].Id;
        update tdu.lstCases[0];

        OutboundCallingCCExpiryCtrl controller;
        PageReference pr = Page.OutboundCallingCCExpiry;
        Test.setCurrentPage(pr);

        Test.startTest();

        	controller = new OutboundCallingCCExpiryCtrl();
        	controller.getCustomer();
            controller.selectedCase.OC_Outcome__c = 'No response';
            controller.enableSaveButton();
            controller.saveSelectedCustomer();

        Test.stopTest();

        System.assertEquals(controller.selectedCase != null , true , 'Case was not found');
        System.assertEquals(controller.selectedCase.AccountId,tdu.lstCases[0].AccountId, 'Incorect subscriber related to the case');

        List<Case> queryCase = [SELECT OC_Outcome__c FROM Case WHERE Id =:controller.selectedCase.Id];
        System.assertEquals(queryCase[0].OC_Outcome__c, 'No response' , 'Case was not savd correctly');

    }
    
}