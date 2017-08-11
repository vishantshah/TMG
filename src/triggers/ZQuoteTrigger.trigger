/**
* Author:       Sally ElGhoul (Tquila)
* Date:         8/07/2015
* Description:  Trigger on Zuora quote Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
* Michal Kwika      1.1
**/
trigger ZQuoteTrigger on zqu__Quote__c (before insert,after insert, before update) {
    
    ZQuoteTriggerHandler handler = ZQuoteTriggerHandler.getInstance();
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            handler.OnBeforeInsert(Trigger.new);
        }
         else if(Trigger.isUpdate){
            handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new);
        }
    }
}