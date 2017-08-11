/************************************************************************************
Class Name   : CaseEmailsControllerExtensionTest
Author       : Mantas Grigaliunas
Created Date : 09/09/2016
Function     : CaseEmailsControllerExtensionTest class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer    Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Mantas Grigaliunas    03/11/2016  //modified getEmailMessagesWithAutoResponseFilterEnabledTest()
* Vishant Shah          07/12/2016  //modified getEmailMessagesWithAutoResponseFilterEnabledTest() 
* Wiktor Czykin         11/07/2017  //added getForwardUrlTest();
*************************************************************************************/
@isTest
private class CaseEmailsControllerExtensionTest {

    private static final Integer EMAIL_MSG_SIZE = 10;
        
    /************************************************************************************
    Method Name  : testSetup
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @testSetup static void testSetup(){

        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadGeneral();
        tdu.createCase();

        TestDataUtility tduMsg = new TestDataUtility(EMAIL_MSG_SIZE);
        tduMsg.createEmailMessage(tdu.lstCases[0].Id);
    }
    
    /************************************************************************************
    Method Name  : CaseEmailsControllerExtensionConstructorTest
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void caseEmailsControllerExtensionConstructorTest() {

        List<Case> testCase = [SELECT Id FROM Case];
        System.assertEquals(1, testCase.size());

        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(
            new ApexPages.StandardController(testCase[0]));

        System.assertEquals(testCase[0].Id, ctrlExt.thisCase.Id);
        System.assertEquals(ctrlExt.INITIAL_RECORDS_NUMBER, ctrlExt.currentRecordsNumber);
        System.assertEquals(ctrlExt.INITIAL_RECORDS_NUMBER, ctrlExt.emailMsgWrapperList.size());
        Test.stopTest();
    }
    
    /************************************************************************************
    Method Name  : GetEmailMessagesWithAutoResponseFilterEnabledTest
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer             Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Mantas Grigaliunas    03/11/2016  //changed the order of SOQL queries execution after random test failure was reported
    * Vishant Shah          07/12/2016  //fixed issue with assertions as the deployment was failing. Jira-5534 
    *************************************************************************************/
    @isTest static void getEmailMessagesWithAutoResponseFilterEnabledTest() {
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Set<Id> displayedMessages = new Set<Id>();
        
        Test.startTest();
            
            List<String> fromAddress = General__c.getInstance(Constants.CASE_AUTORESPONSE_EMAIL_ADDRESS_SETTING).Value__c.split(';');
            
            EmailMessage autoResponseEmail = TestDataUtility.newEmailMessage(testCase.Id, 1, fromAddress[0]);
            autoResponseEmail.MessageDate = DateTime.now().addDays(1);
            insert autoResponseEmail;
            
            CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(new ApexPages.StandardController(testCase));
            ctrlExt.autoResponse = true;
            ctrlExt.getEmailMessages();
            
            for(CaseEmailsControllerExtension.EmailMsgWrapper msg : ctrlExt.emailMsgWrapperList)
                displayedMessages.add(msg.eMsg.Id);
            
            System.assertEquals(ctrlExt.INITIAL_RECORDS_NUMBER, ctrlExt.emailMsgWrapperList.size());
            System.assertEquals(autoResponseEmail.Id, ctrlExt.emailMsgWrapperList[0].eMsg.Id, 'First displayed message should always be a autoresponse.');
        
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : DeletMessageTest
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void deletMessageTest() {
        
        EmailMessage msg = [SELECT Id FROM EmailMessage LIMIT 1];

        Test.startTest();
        CaseEmailsControllerExtension.deleteMessage(msg.Id);
        List<EmailMessage> deletedMessage = [SELECT Id FROM EmailMessage WHERE Id = :msg.Id];
        System.assertEquals(0, deletedMessage.size());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : GetSendEmailUrl
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void getSendEmailUrlTest() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(new ApexPages.StandardController(testCase));
        System.assert(!String.isEmpty(ctrlExt.getSendEmailUrl()));
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : GetReplylUrl
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void getReplylUrlTest() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(new ApexPages.StandardController(testCase));
        System.assert(!String.isEmpty(ctrlExt.getReplyUrl()));
        Test.stopTest();
    }

    /************************************************************************************
    Author       : Wiktor Czykin
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void getForwardUrlTest(){
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(new ApexPages.StandardController(testCase));
        System.assert(!String.isEmpty(ctrlExt.getForwardUrl()));
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : GetShowAllUrl
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void getShowAllUrlTest() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(
            new ApexPages.StandardController(testCase));
        System.assert(!String.isEmpty(ctrlExt.getShowAllUrl()));
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : ShowMoreTest
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void showMoreTest() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(
            new ApexPages.StandardController(testCase));
        Integer currentRecordsNumber = ctrlExt.currentRecordsNumber;
        ctrlExt.showMore();
        System.assertEquals(currentRecordsNumber + ctrlExt.INITIAL_RECORDS_NUMBER, ctrlExt.emailMsgWrapperList.size());
        Test.stopTest();
    }

    /************************************************************************************
    Method Name  : GetGeneralCustomSettingNoSettingsFoundTest
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void getGeneralCustomSettingNoSettingsFoundTest() {

        delete General__c.getAll().values();
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        CaseEmailsControllerExtension ctrlExt = new CaseEmailsControllerExtension(
            new ApexPages.StandardController(testCase));
        System.assert(checkApexMessages(Constants.CASE_AUTORESPONSE_EMAIL_ADDRESS_SETTING), ApexPages.getMessages());
        Test.stopTest();

    }

    /************************************************************************************
    Method Name  : checkApexMessages
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @TestVisible
    private static Boolean checkApexMessages(String paramName) {
        String message = String.format(Label.Case_Emails_Missing_Custom_Setting, new List<String>{paramName});
        for(Apexpages.Message msg : ApexPages.getMessages()){
            if (msg.getDetail().contains(message)) {
                return true;
            }
    }
        return false;
    }
}