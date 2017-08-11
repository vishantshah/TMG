/************************************************************************************
Class Name   : ChequeBatchTriggerHandler
Author       : Mantas Grigaliunas
Created Date : 25/11/2016
Function     : ChequeBatchTrigger handler class
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class ChequeBatchTriggerHandler {

    private static ChequeBatchTriggerHandler instance;
    public Boolean isExecuting = false;

    public static ChequeBatchTriggerHandler getInstance() {
        if (instance == null) instance = new ChequeBatchTriggerHandler();
        return instance; 
    }

    /************************************************************************************
    Method Name  : OnAfterUpdate
    Developer    : Mantas Grigaliunas
    Created Date : 25/11/2016
    Function     : Method to hold all custom methods called after record update
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void OnAfterUpdate(List<Cheque_Batch__c> updatedChequeBatches, Map<ID, Cheque_Batch__c> oldChequeBatchMap){
        if (!this.isExecuting) {
            this.isExecuting = true;
            updateVoucherActiviesWithStatusProcessed(updatedChequeBatches, oldChequeBatchMap);
            this.isExecuting = false;        
        }   
    }

    /************************************************************************************
    Method Name  : updateVoucherActiviesWithStatusProcessed
    Developer    : Mantas Grigaliunas
    Created Date : 25/11/2016
    Function     : Method to update all related Voucher Activities Refund Status to processed
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void updateVoucherActiviesWithStatusProcessed(List<Cheque_Batch__c> updatedChequeBatches, Map<ID, Cheque_Batch__c> oldChequeBatchMap){

        Id chequeBatchRecordTypeId = RecordTypeUtility.getRecordTypeId(Cheque_Batch__c.sObjectType, 
                Constants.VOUCHER_REFUND_CHEQUE_BATCH_RECORD_TYPE_NAME, Cheque_Batch__c.class.getName());
        Set<Id> vaBatcheSet = new Set<Id>();
        //check if cheque batch close date changed
        for(Cheque_Batch__c cb : updatedChequeBatches){
            if(cb.RecordTypeId == chequeBatchRecordTypeId
                && oldChequeBatchMap.get(cb.Id).Batch_Closed_Date__c == null
                && cb.Batch_Closed_Date__c != null){
                vaBatcheSet.add(cb.Id);
            }
        }

        if(vaBatcheSet.size() > 0){
            List<Voucher_Adjustment__c> voucherActivitiesToUpdate = new List<Voucher_Adjustment__c>();
            for(Cheque__c cheque : [SELECT Id, Voucher_Activity__c, Voucher_Activity__r.Refund_Status__c FROM Cheque__c 
                                        WHERE Voucher_Activity__c != NULL 
                                        AND Cheque_Banking_Status__c = :Constants.CHEQUE_BANKINGSTATUS_ISSUED 
                                        AND Cheque_Batch__c IN :vaBatcheSet]){


                voucherActivitiesToUpdate.add(new Voucher_Adjustment__c(
                    Id = cheque.Voucher_Activity__c,
                    Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PROCESSED )
                );
            }

            if(voucherActivitiesToUpdate.size() > 0){
                update voucherActivitiesToUpdate;
            }
        }
    }
}