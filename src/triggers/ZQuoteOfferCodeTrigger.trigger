/**
* Author:       Sally ElGhoul (Accenture)
* Date:         13/10/2015
* Description:  Trigger on Zuora Payment Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger ZQuoteOfferCodeTrigger on Quote_Offer_Code__c (after delete, after insert) {
	
	ZQuoteOfferCodeTriggerHandler handler = ZQuoteOfferCodeTriggerHandler.getInstance();
	
	if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,Trigger.newMap);
        }else if(Trigger.isDelete){
            handler.OnAfterDelete(Trigger.old,Trigger.oldMap);
        } 
	}
}