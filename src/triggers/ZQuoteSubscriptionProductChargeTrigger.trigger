/**
* Author:       Sally ElGhoul (Accenture)
* Date:         21/09/2015
* Description:  Trigger on Zuora Subscription Product Charge Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger ZQuoteSubscriptionProductChargeTrigger on Zuora__SubscriptionProductCharge__c (after delete, after insert) {
	
	ZQuoteSubProductChargeTriggerHandler handler = ZQuoteSubProductChargeTriggerHandler.getInstance();
    
    //After update trigger
    if(Trigger.isAfter){
    	
    	//after insert
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,Trigger.newMap);
        } else if(Trigger.isDelete){ //after Delete
            handler.OnAfterDelete(  Trigger.old, Trigger.oldMap);
        } 
    }
}