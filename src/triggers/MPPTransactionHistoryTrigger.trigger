/**
* @author Unknown
* @date Unknown
* @description MPP_Transaction_History__c trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         29/07/2015  //reorganised
**/
trigger MPPTransactionHistoryTrigger on MPP_Transaction_History__c (after delete, after insert, after undelete, after update, before delete, before insert, before update){
    
    MPPTransactionHistoryTriggerHandler handler = MPPTransactionHistoryTriggerHandler.getInstance(); 
   
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            handler.OnBeforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.OnBeforeUpdate( Trigger.old, Trigger.new, Trigger.newMap);
        } else if(Trigger.isDelete){
            handler.OnBeforeDelete( Trigger.old, Trigger.oldMap);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.OnAfterUpdate(  Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        } else if(Trigger.isDelete){
            handler.OnAfterDelete(  Trigger.old, Trigger.oldMap);
        } else if(Trigger.isUndelete){
            handler.OnUndelete(Trigger.new);    
        }
    }
}