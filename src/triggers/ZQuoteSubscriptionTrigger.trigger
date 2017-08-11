/**
* Author:       Sally ElGhoul (Tquila)
* Date:         9/07/2015
* Description:  Trigger on Zuora Subscription Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger ZQuoteSubscriptionTrigger on Zuora__Subscription__c (before insert, after insert,before update,after update) {
	
	ZQuoteSubscriptionTriggerHandler handler = ZQuoteSubscriptionTriggerHandler.getInstance();
    
    //After update trigger
    if(Trigger.isAfter){
    	
    	//after insert
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,Trigger.newMap);
        } else if(Trigger.isUpdate){ //after update
            handler.OnAfterUpdate(  Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        } 
    }else if(Trigger.isBefore){
    	if(Trigger.isInsert){
    		handler.onBeforeInsert(Trigger.New);
    	}else if(Trigger.isUpdate){
    		handler.OnBeforeUpdate( Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    	}
    }
    
}