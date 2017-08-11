/**
* @author Pawel Chrzanowski
* @date 11/07/2016
* @description Test class for OutboundCallManageJobExtension
#############Change Log#############
Modified by         Version     Change Date
**/
@isTest
private class OutboundCallManageJobExtensionTest{

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 11/07/2016
    Version - 1.0
    Function - method to test the Constructor
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void outboundCallManageJobExtensionTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallBatchSetting(BalanceReviewBatch.class.getName());

        ApexPages.StandardController sc;
        OutboundCallManageJobExtension controller;

        PageReference pr = Page.OutboundCallManageJob;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(tdu.lstOutboundCallBatchSetting[0]);
            controller = new OutboundCallManageJobExtension(sc);
            System.assertEquals(controller.ocbs.Id, tdu.lstOutboundCallBatchSetting[0].Id);
            System.assertEquals(controller.ct, null);
            System.assert(controller.hasBatchClassName);
            System.assert(controller.isActive);
            System.assert(!controller.hasJobId);
            System.assert(!controller.hasJob);

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 11/07/2016
    Version - 1.0
    Function - method to check checkJobStatus
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void checkJobStatusTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallBatchSetting(BalanceReviewBatch.class.getName());

        ApexPages.StandardController sc;
        OutboundCallManageJobExtension controller;

        PageReference pr = Page.OutboundCallManageJob;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(tdu.lstOutboundCallBatchSetting[0]);
            controller = new OutboundCallManageJobExtension(sc);

            //success
            String jobId = System.schedule('test batch', tdu.lstOutboundCallBatchSetting[0].Cron_String__c, new BalanceReviewBatch());
            controller.ocbs.Job_Id__c = jobId;
            controller.checkJobStatus();

            System.assertEquals(controller.ct.CronExpression, tdu.lstOutboundCallBatchSetting[0].Cron_String__c);
            System.assertEquals(controller.ct.TimesTriggered, 0);
            System.assertEquals(String.valueOf(controller.ct.NextFireTime), '2022-09-03 00:00:00');

            //invalid Job Id
            controller.ocbs.Job_Id__c = '111111';
            controller.checkJobStatus();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Call_Batch_Setting_Job_Not_Found));

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 11/07/2016
    Version - 1.0
    Function - method to check checkJobStatus - positive scenario
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void scheduleJobTest_positive(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallBatchSetting(BalanceReviewBatch.class.getName());

        ApexPages.StandardController sc;
        OutboundCallManageJobExtension controller;

        PageReference pr = Page.OutboundCallManageJob;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(tdu.lstOutboundCallBatchSetting[0]);
            controller = new OutboundCallManageJobExtension(sc);

            //Batch Setting not found
            String schedulableResult = OutboundCallManageJobExtension.scheduleJob('111111111111111');
            System.assert(schedulableResult.contains(Label.Outbound_Call_Batch_Setting_Not_Found));

            //schedule success
            schedulableResult = OutboundCallManageJobExtension.scheduleJob(tdu.lstOutboundCallBatchSetting[0].Id);
            System.assertEquals('success', schedulableResult);

            Outbound_Call_Batch_Setting__c ocbs = [select Job_Id__c from Outbound_Call_Batch_Setting__c where Id = :tdu.lstOutboundCallBatchSetting[0].Id];
            CronTrigger ct = [select CronExpression, TimesTriggered, NextFireTime, CronJobDetail.Name, CronJobDetail.JobType from CronTrigger where Id = :ocbs.Job_Id__c];

            System.assertEquals(ct.CronExpression, tdu.lstOutboundCallBatchSetting[0].Cron_String__c);
            System.assertEquals(ct.TimesTriggered, 0);
            System.assertEquals(String.valueOf(ct.NextFireTime), '2022-09-03 00:00:00');

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 11/07/2016
    Version - 1.0
    Function - method to check checkJobStatus - negative scenario
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void scheduleJobTest_negative(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallBatchSetting(BalanceReviewBatch.class.getName());

        ApexPages.StandardController sc;
        OutboundCallManageJobExtension controller;

        PageReference pr = Page.OutboundCallManageJob;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(tdu.lstOutboundCallBatchSetting[0]);
            controller = new OutboundCallManageJobExtension(sc);

            //two active Batch Settings error
            insert new Outbound_Call_Batch_Setting__c(
                Batch_Class_Name__c = BalanceReviewBatch.class.getName(), 
                Outbound_Call_Setting__c = tdu.lstOutboundCallSetting[0].Id, 
                Cron_String__c = '0 0 0 3 9 ? 2022', 
                Active__c = true
            );
            String schedulableResult = OutboundCallManageJobExtension.scheduleJob(tdu.lstOutboundCallBatchSetting[0].Id);
            System.assert(schedulableResult.contains(Label.Outbound_Call_Batch_Setting_Error));

        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 11/07/2016
    Version - 1.0
    Function - method to check unscheduleJob
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void unscheduleJobTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallBatchSetting(BalanceReviewBatch.class.getName());

        ApexPages.StandardController sc;
        OutboundCallManageJobExtension controller;

        PageReference pr = Page.OutboundCallManageJob;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(tdu.lstOutboundCallBatchSetting[0]);
            controller = new OutboundCallManageJobExtension(sc);

            //ocbs not found error
            String schedulableResult = OutboundCallManageJobExtension.unscheduleJob('111111111111111');
            System.assert(schedulableResult.contains(Label.Outbound_Call_Batch_Setting_Not_Found));

            //job Id not found error
            schedulableResult = OutboundCallManageJobExtension.unscheduleJob(tdu.lstOutboundCallBatchSetting[0].Id);
            System.assert(schedulableResult.contains(Label.Outbound_Call_Batch_Setting_Job_Id_Not_Found));
            
            //success
            String jobId = System.schedule('test batch', tdu.lstOutboundCallBatchSetting[0].Cron_String__c, new BalanceReviewBatch());
            controller.ocbs.Job_Id__c = jobId;
            update controller.ocbs;
            schedulableResult = OutboundCallManageJobExtension.unscheduleJob(tdu.lstOutboundCallBatchSetting[0].Id);
            System.assertEquals('success', schedulableResult);
        
        Test.stopTest();
    }

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 11/07/2016
    Version - 1.0
    Function - method to check showErrorMessage
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void showErrorMessageTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createOutboundCallBatchSetting(BalanceReviewBatch.class.getName());

        ApexPages.StandardController sc;
        OutboundCallManageJobExtension controller;

        PageReference pr = Page.OutboundCallManageJob;
        Test.setCurrentPage(pr);

        Test.startTest();

            sc = new ApexPages.StandardController(tdu.lstOutboundCallBatchSetting[0]);
            controller = new OutboundCallManageJobExtension(sc);
            controller.errorMessage = 'test error';
            controller.showErrorMessage();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'test error'));

        Test.stopTest();
    }

}