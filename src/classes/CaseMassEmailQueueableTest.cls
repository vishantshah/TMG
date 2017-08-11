/**
Name: SubscriptionStatusQueueableTest
* @author Pawel Chrzanowski
* @date 25/08/2016
* @description 	Tests for SubscriptionStatusQueueable
##########Change Log##########
Modified by     Version     Change Date
*/
@isTest
private class CaseMassEmailQueueableTest {

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - tests for constructor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void constructorTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCase();

        CaseMassEmailQueueable cmeq = new CaseMassEmailQueueable(tdu.lstCases, '001', CaseMassAmendmentController.EMAIL_BODY_CUSTOM, 'subject', 'body', '002', null, null, null);
        System.assertEquals(tdu.lstCases.size(), cmeq.selectedCases.size());
        System.assertEquals('001', cmeq.selectedOrgEmailId);
        System.assertEquals(CaseMassAmendmentController.EMAIL_BODY_CUSTOM, cmeq.selectedEmailBodyType);
        System.assertEquals('subject', cmeq.emailCustomSubject);
        System.assertEquals('body', cmeq.emailCustomBody);
        System.assertEquals('002', cmeq.selectedTemplate);
        System.assertEquals('', cmeq.emailErrorReport);
        System.assertEquals(0, cmeq.successCount);
        System.assertEquals(0, cmeq.failCount);
        System.assert(cmeq.otherCases.isEmpty());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - tests for constructor's batch size limit
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void constructorTest_limit(){
        Integer buffer = 11;
        TestDataUtility tdu = new TestDataUtility(CaseMassEmailQueueable.BATCH_SIZE + buffer);
        tdu.createCase();

        CaseMassEmailQueueable cmeq = new CaseMassEmailQueueable(tdu.lstCases, '001', CaseMassAmendmentController.EMAIL_BODY_CUSTOM, 'subject', 'body', '002', null, null, null);
        System.assertEquals(CaseMassEmailQueueable.BATCH_SIZE, cmeq.selectedCases.size());
        System.assertEquals(buffer, cmeq.otherCases.size());
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - tests for queueable execution
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void executeTest(){
        Contact c = new Contact(FirstName='test', LastName='test', Email='test@test.coom');
        insert c;

        Case testCase = new Case(ContactId=c.Id, Status=Constants.CASE_STATUS_NEW, Subject='subject');
        insert testCase;

        String emailId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        String folderId = [SELECT Id FROM Folder WHERE Name = :CaseMassAmendmentController.EMAIL_TEMPLATE_FOLDER LIMIT 1].Id;
        String templateId = [SELECT Id FROM EmailTemplate WHERE IsActive = true AND FolderId = :folderId LIMIT 1].Id;

        //template email
        CaseMassEmailQueueable cmeq = new CaseMassEmailQueueable(new List<Case>{testCase}, emailId, CaseMassAmendmentController.EMAIL_BODY_TEMPLATE, null, null, templateId, 'report', null, null);

        //custom body email
        CaseMassEmailQueueable cmeq2 = new CaseMassEmailQueueable(new List<Case>{testCase}, emailId, CaseMassAmendmentController.EMAIL_BODY_CUSTOM, 'subject', 'body', null, 'report', null, null);
        
        Test.startTest();
            System.enqueueJob(cmeq);
            System.enqueueJob(cmeq2);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Version - 1.0
    Function - tests for queueable execution and chaining
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void executeTest_chain(){
        Contact c = new Contact(FirstName='test', LastName='test', Email='test@test.coom');
        insert c;

        Integer buffer = 11;
        List<Case> lstCases = new List<Case>();
        for(Integer i=0; i<CaseMassEmailQueueable.BATCH_SIZE+buffer; i++){
            lstCases.add(new Case(ContactId=c.Id, Status=Constants.CASE_STATUS_NEW, Subject='subject '+i));
        }
        insert lstCases;

        String emailId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        CaseMassEmailQueueable cmeq = new CaseMassEmailQueueable(lstCases, emailId, CaseMassAmendmentController.EMAIL_BODY_CUSTOM, 'subject', 'body', null, 'report', null, null);

        Test.startTest();
            System.enqueueJob(cmeq);
        Test.stopTest();
    }

}