/**
* @author Wiktor Czykin
* @date 13/03/2017
* @description trigger on Offer__c
*#############Change Log#############
*Modified by     Version     Change Date
**/
trigger OfferTrigger on Offer__c (before insert, before update, after insert, after update, after delete, after undelete) {

	OfferTriggerHandler handler = OfferTriggerHandler.getInstance();
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
    } else if (Trigger.isAfter){
    	if(Trigger.isInsert){
    		handler.onAfterInsert(Trigger.new);
    	}else if(Trigger.isUpdate){
    		handler.onAfterUpdate(Trigger.oldMap, Trigger.new);
    	}else if(Trigger.isDelete){
            handler.onAfterDelete(Trigger.old);
        }else if(Trigger.isUndelete){
            handler.onAfterUndelete(Trigger.new);
        }
    }
}
