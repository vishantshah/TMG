/**
* Author:       Sally ElGhoul (Accenture)
* Date:         14/10/2015
* Description:  Trigger on Zuora Payment Method Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger ZPaymentMethodTrigger on Zuora__PaymentMethod__c (after insert) {
	
	ZPaymentMethodTriggerHandler handler = ZPaymentMethodTriggerHandler.getInstance();
	
	if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,Trigger.newMap);
        }
	}
	
}