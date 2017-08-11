/**
* @author Pawel Chrzanowski
* @date 18/07/2016
* @description Test class for OutboundCallingBalanceReviewCtrl
* #############Change Log#############
* Modified by           Version     Change Date
* Pawel Chrzanowski     1.1         01/08/2016  //added test coverage
* Mantas Grigaliunas    1.2         19/08/2016  //updated Parameters string and field name
**/
@isTest
private class OutboundCallingBalanceReviewCtrlTest {

    private final static String PARAMETER = '{'
    +   '  "callStageParameters": [ {'
    +   '  "stagename": "BR1",'
    +   '  "outcome": "OC_Stage_5_Outcome__c",'
    +   '  "calldatetime": "OC_Stage_5_Call_Date_Time__c",'
    +   '  "nosalereason": "",'
    +   '  "tcode": "",'
    +   '  "offset": 0'
    +   '}] }';
    
    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/07/2016
    Version - 1.0
    Function - method to test the Constructor with no OC Setting
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void noOCSettingTest(){
        TestDataUtility tdu = new TestDataUtility(1);

        OutboundCallingBalanceReviewCtrl controller;
        PageReference pr = Page.OutboundCallingBalanceReview;
        Test.setCurrentPage(pr);

        Test.startTest();

            //no Outbound Call Setting
            tdu.createOutboundCallSetting();
            tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME;
            update tdu.lstOutboundCallSetting[0];
            controller = new OutboundCallingBalanceReviewCtrl();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Respective Outbound Call Setting is incomplete or was not found.'));
            
            //No Outbound Call Setting Parameters
            tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME;
            update tdu.lstOutboundCallSetting[0];
            controller = new OutboundCallingBalanceReviewCtrl();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Respective Outbound Call Setting\'s Parameters error occurred.'));

            System.assert(!controller.hasCustomer);
            System.assert(!controller.hasPayments);
            System.assert(!controller.hasVoucherActivities);

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/07/2016
    Version - 1.0
    Function - method to test the Constructor with no OC Rule
    #############Change Log#############
    * Modified by         Version   Change Date
    * Mantas Grigaliunas    1.1     19/08/2016  //updated Parameters string
    *************************************************************************************/
    static testMethod void noOCRuleTest(){
        TestDataUtility tdu = new TestDataUtility(1);

        tdu.createOutboundCallSetting();
        tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME;
        tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME;
        tdu.lstOutboundCallSetting[0].Parameters__c = PARAMETER;
        update tdu.lstOutboundCallSetting[0];

        OutboundCallingBalanceReviewCtrl controller;
        PageReference pr = Page.OutboundCallingBalanceReview;
        Test.setCurrentPage(pr);

        Test.startTest();

            controller = new OutboundCallingBalanceReviewCtrl();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'Respective Outbound Call Rule was not found.'));

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 18/07/2016
    Version - 1.0
    Function - method to test getCustomer
    #############Change Log#############
    * Modified by         Version     Change Date
    * Mantas Grigaliunas    1.1     19/08/2016  //updated Parameters string and field name
    *************************************************************************************/
    static testMethod void getCustomerTest(){
        TestDataUtility tdu = new TestDataUtility(1);

        tdu.createOutboundCallSetting();
        tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME;
        tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME;
        tdu.lstOutboundCallSetting[0].Parameters__c = PARAMETER;
        update tdu.lstOutboundCallSetting[0];

        tdu.createOutboundCallRule();
        tdu.lstOutboundCallRule[0].Priority_Field__c = 'Priority';
        update tdu.lstOutboundCallRule[0];

        tdu.createSubscriptions();
        tdu.createVoucherAdjustments();

        tdu.createCase();
        tdu.lstCases[0].Status = Constants.UPGRADE_IN_PROGRESS;
        tdu.lstCases[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, tdu.lstOutboundCallSetting[0].Case_Record_Type__c, Case.class.getName());
        tdu.lstCases[0].OC_Call_Stage__c = 'BR1';
        tdu.lstCases[0].OC_Stage_5_Call_Date_Time__c = DateTime.now().addYears(-1);
        tdu.lstCases[0].AccountId = tdu.lstIndividualSubscribers[0].Id;
        tdu.lstCases[0].Print_Subscription__c = tdu.lstSubscriptions[0].Id;
        update tdu.lstCases[0];

        OutboundCallingBalanceReviewCtrl controller;
        PageReference pr = Page.OutboundCallingBalanceReview;
        Test.setCurrentPage(pr);

        Test.startTest();

        	controller = new OutboundCallingBalanceReviewCtrl();
        	controller.getCustomer();
            System.assert(controller.hasCustomer);
            System.assertEquals(tdu.lstCases[0].Id, controller.selectedCase.Id);

        Test.stopTest();
    }
    
    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 01/08/2016
    Version - 1.0
    Function - method to test enableSaveButton
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/    
    static testMethod void enableSaveButtonTest(){
        OutboundCallingBalanceReviewCtrl controller = new OutboundCallingBalanceReviewCtrl();
        System.assert(!controller.isSaveButtonEnabled);
        controller.enableSaveButton();
        System.assert(controller.isSaveButtonEnabled);
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 01/08/2016
    Version - 1.0
    Function - method to test saveSelectedCustomer
    #############Change Log#############
    * Modified by         Version     Change Date
    * Mantas Grigaliunas    1.1     19/08/2016  //updated Parameters string and field name
    *************************************************************************************/    
    static testMethod void saveSelectedCustomerTest(){
        TestDataUtility tdu = new TestDataUtility(1);

        tdu.createOutboundCallSetting();
        tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME;
        tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME;
        tdu.lstOutboundCallSetting[0].Parameters__c = PARAMETER;
        update tdu.lstOutboundCallSetting[0];

        tdu.createOutboundCallRule();
        tdu.lstOutboundCallRule[0].Priority_Field__c = 'Priority';
        update tdu.lstOutboundCallRule[0];

        tdu.createSubscriptions();

        tdu.createCase();
        tdu.lstCases[0].Status = Constants.UPGRADE_IN_PROGRESS;
        tdu.lstCases[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, tdu.lstOutboundCallSetting[0].Case_Record_Type__c, Case.class.getName());
        tdu.lstCases[0].OC_Call_Stage__c = 'BR1';
        tdu.lstCases[0].OC_Stage_5_Call_Date_Time__c = DateTime.now().addYears(-1);
        tdu.lstCases[0].AccountId = tdu.lstIndividualSubscribers[0].Id;
        tdu.lstCases[0].Print_Subscription__c = tdu.lstSubscriptions[0].Id;
        update tdu.lstCases[0];

        OutboundCallingBalanceReviewCtrl controller;
        PageReference pr = Page.OutboundCallingBalanceReview;
        Test.setCurrentPage(pr);

        Test.startTest();

            controller = new OutboundCallingBalanceReviewCtrl();
            controller.getCustomer();
            controller.selectedCase.OC_Outcome__c = Constants.CASE_OUTCOME_WITHDRAWN;
            controller.selectedCase.Print_Subscription__r.Revenue_Write_off_Amount__c = 10;
            controller.selectedCase.Print_Subscription__r.Revenue_Write_off_Reason__c = 'DD error';
            controller.saveSelectedCustomer();
            System.assert(!controller.isSaveButtonEnabled);

            Case updatedCase = [SELECT OC_Outcome__c FROM Case WHERE Id = :controller.selectedCase.Id];
            System.assertEquals(Constants.CASE_OUTCOME_WITHDRAWN, updatedCase.OC_Outcome__c);

            Subscription__c updatedSub = [SELECT Revenue_Write_off_Amount__c, Revenue_Write_off_Reason__c FROM Subscription__c WHERE Id = :controller.selectedCase.Print_Subscription__c];
            System.assertEquals(10, updatedSub.Revenue_Write_off_Amount__c);
            System.assertEquals('DD error', updatedSub.Revenue_Write_off_Reason__c);

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 01/08/2016
    Version - 1.0
    Function - method to test takeOneOffPayment
    #############Change Log#############
    * Modified by         Version     Change Date
    * Mantas Grigaliunas    1.1     19/08/2016  //updated Parameters string and field name
    *************************************************************************************/    
    static testMethod void takeOneOffPaymentTest(){
        TestDataUtility tdu = new TestDataUtility(1);

        tdu.createOutboundCallSetting();
        tdu.lstOutboundCallSetting[0].Visualforce_Page__c = Constants.OC_BALANCE_REVIEW_VF_PAGE_NAME;
        tdu.lstOutboundCallSetting[0].Case_Record_Type__c = Constants.OC_BALANCE_REVIEW_RECORD_TYPE_NAME;
        tdu.lstOutboundCallSetting[0].Parameters__c = PARAMETER;
        update tdu.lstOutboundCallSetting[0];

        tdu.createOutboundCallRule();
        tdu.lstOutboundCallRule[0].Priority_Field__c = 'Priority';
        update tdu.lstOutboundCallRule[0];

        tdu.createSubscriptions();

        tdu.createCase();
        tdu.lstCases[0].Status = Constants.UPGRADE_IN_PROGRESS;
        tdu.lstCases[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, tdu.lstOutboundCallSetting[0].Case_Record_Type__c, Case.class.getName());
        tdu.lstCases[0].OC_Call_Stage__c = 'BR1';
        tdu.lstCases[0].OC_Stage_5_Call_Date_Time__c = DateTime.now().addYears(-1);
        tdu.lstCases[0].AccountId = tdu.lstIndividualSubscribers[0].Id;
        tdu.lstCases[0].Print_Subscription__c = tdu.lstSubscriptions[0].Id;
        update tdu.lstCases[0];

        OutboundCallingBalanceReviewCtrl controller;
        PageReference pr = Page.OutboundCallingBalanceReview;
        Test.setCurrentPage(pr);

        Test.startTest();

            controller = new OutboundCallingBalanceReviewCtrl();
            controller.getCustomer();
            PageReference redirectedPage = controller.takeOneOffPayment();
            System.assertEquals(tdu.lstSubscriptions[0].Id, redirectedPage.getParameters().get('id'));
            System.assertEquals(Constants.OC_BALANCE_REVIEW_FLOW_NAME, redirectedPage.getParameters().get('flow'));

        Test.stopTest();
    }

}