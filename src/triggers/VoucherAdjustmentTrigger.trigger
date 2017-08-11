/**
* @author Wiktor Czykin
* @date 18/09/2015
* @description Voucher Adjustment (Activity) trigger
#############Change Log#############
Modified by     Version     Change Date
**/
trigger VoucherAdjustmentTrigger on Voucher_Adjustment__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){

    VoucherAdjustmentTriggerHandler handler = VoucherAdjustmentTriggerHandler.getInstance();

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            handler.OnBeforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.OnBeforeUpdate( Trigger.old, 
                                    Trigger.new, 
                                    Trigger.newMap);
        } else if(Trigger.isDelete){
            handler.OnBeforeDelete( Trigger.old, 
                                    Trigger.oldMap);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,
                                  Trigger.newMap);
        } else if(Trigger.isUpdate){
            handler.OnAfterUpdate(  Trigger.old, 
                                    Trigger.new, 
                                    Trigger.oldMap, 
                                    Trigger.newMap);
        } else if(Trigger.isDelete){
            handler.OnAfterDelete(  Trigger.old,
                                    Trigger.oldMap);
        } else if(Trigger.isUndelete){
            handler.OnUndelete(Trigger.new);    
        }
    }
}