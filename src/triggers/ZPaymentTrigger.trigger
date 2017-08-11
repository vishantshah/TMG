/**
* Author:       Sally ElGhoul (Accenture)
* Date:         13/10/2015
* Description:  Trigger on Zuora Payment Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger ZPaymentTrigger on Zuora__Payment__c (before insert,after insert) {
	
	ZPaymentTriggerHandler handler = ZPaymentTriggerHandler.getInstance();
	
	if(Trigger.isBefore){
        if(Trigger.isInsert){
            handler.OnBeforeInsert(Trigger.new);
        }
	}else if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,Trigger.newMap);
        }
	}
}