/************************************************************************************
Class Name   : ChequeBatchTrigger
Author       : Mantas Grigaliunas
Created Date : 25/11/2016
Function     : Cheque_Batch trigger class
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
trigger ChequeBatchTrigger on Cheque_Batch__c (after update) {

	ChequeBatchTriggerHandler handler = ChequeBatchTriggerHandler.getInstance();

	if(Trigger.isAfter){
		if(Trigger.isUpdate){
          	handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}