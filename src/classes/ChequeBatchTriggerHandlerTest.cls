/************************************************************************************
Class Name   : ChequeBatchTriggerHandlerUnitTest
Author       : Mantas Grigaliunas
Created Date : 24/11/2016
Function     : ChequeBatchTriggerHandler class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date        Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
@isTest
private class ChequeBatchTriggerHandlerTest {

    final static Integer RECORDS_SIZE = 3;
    /************************************************************************************
    Method Name  : testSetup
    Author       : Mantas Grigaliunas
    Created Date : 24/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @testSetup static void testSetup(){
        //create cheque batch
        Cheque_Batch__c testChequeBatch = new Cheque_Batch__c(
        RecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName()),
            Batch_Closed_Date__c = null);
        insert testChequeBatch;

        //create voucher activities
        TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);
        tdu.createVoucherAdjustments();

        //create cheques
        List<Cheque__c> testCheques = new List<Cheque__c>();
        for(Voucher_Adjustment__c voucher : tdu.lstVoucherAdjustment){
            testCheques.add(new Cheque__c(
                Voucher_Activity__c = voucher.Id,
                Cheque_Banking_Status__c = Constants.CHEQUE_BANKINGSTATUS_ISSUED,
                Cheque_Batch__c = testChequeBatch.Id,
                Cheque_Amount__c = 10.90));
        }
        insert testCheques;
    }
    
    /************************************************************************************
    Method Name  : updateVoucherActiviesWithStatusProcessedTest
    Author       : Mantas Grigaliunas
    Created Date : 24/11/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    @isTest static void updateVoucherActiviesWithStatusProcessedTest() {
        
        Test.startTest();
        //insert Cheque Closing date to fire a trigger
        Cheque_Batch__c chequeBatch = [ SELECT Id, Batch_Closed_Date__c FROM Cheque_Batch__c WHERE Batch_Closed_Date__c = NULL LIMIT 1 ];
        chequeBatch.Batch_Closed_Date__c = Date.today();
        update chequeBatch;

        //assert results
        List<Voucher_Adjustment__c> updatedVouchers = new List<Voucher_Adjustment__c>(
            [ SELECT Id, Refund_Status__c FROM Voucher_Adjustment__c  
                WHERE Refund_Status__c = :Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED ]);
        System.assertEquals(RECORDS_SIZE, updatedVouchers.size());
        
        Test.stopTest();
    }
}