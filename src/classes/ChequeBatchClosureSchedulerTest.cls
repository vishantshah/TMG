/************************************************************************************
Class Name   : ChequeBatchClosureSchedulerTest
Author       : Mantas Grigaliunas
Created Date : 14/12/2016
Function     : Unit Test class for ChequeBatchClosureScheduler
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
private class ChequeBatchClosureSchedulerTest {

   // CRON expression: midnight on March 15.
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    /************************************************************************************
    Method Name  : testSetup
    Author       : Mantas Grigaliunas
    Created Date : 14/12/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
   @testSetup static void testSetup(){
   		//create cheque batch
        insert new Cheque_Batch__c(
            RecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName()),
            Batch_Closed_Date__c = null);
   }

    /************************************************************************************
    Method Name  : executeTest
    Author       : Mantas Grigaliunas
    Created Date : 14/12/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
   @isTest static void executeTest() {

      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new ChequeBatchClosureScheduler());

      // Verify the scheduled job hasn't run yet.
      List<Cheque_Batch__c> testChequeBatch = new List<Cheque_Batch__c>(
      	[ SELECT Id FROM Cheque_Batch__c WHERE Batch_Closed_Date__c != NULL ]);
      System.assertEquals(0, testChequeBatch.size());

      // Because this is a test, job executes immediately after Test.stopTest().
      Test.stopTest();

      //check if Cheque Batch was closed 
      List<Cheque_Batch__c> updatedChequeBatch = new List<Cheque_Batch__c>(
      	[ SELECT Id FROM Cheque_Batch__c WHERE Batch_Closed_Date__c != NULL ]);
      System.assertEquals(1, updatedChequeBatch.size());
   }
}