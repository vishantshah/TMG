/**
* @author Unknown
* @date Unknown
* @description Cheque trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         30/07/2015  //moved flag to the handler
**/
trigger ChequeTrigger on Cheque__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    ChequeTriggerHandler instance = ChequeTriggerHandler.getInstance();
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            instance.onBeforeInsert(Trigger.New);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            instance.onAfterInsert(Trigger.New, Trigger.Old,Trigger.NewMap,Trigger.oldMap);
        }
        if(Trigger.isUpdate){
            instance.onAfterUpdate(Trigger.New, Trigger.Old,Trigger.NewMap,Trigger.oldMap);
        }
        if(Trigger.isDelete){
            instance.onAfterDelete(Trigger.New, Trigger.Old);
        }   
        if(Trigger.isUnDelete){
            instance.onAfterUnDelete(Trigger.New, Trigger.Old);
        }   
   }
}