/**
* Author:       Sally ElGhoul (Accenture)
* Date:         27/08/2015
* Description:  Trigger on Zuora QuoteRatePlan Object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger ZQuoteRatePlanTrigger on zqu__QuoteRatePlan__c (before insert, after insert) {
	
	ZQuoteRatePlanTriggerHandler handler = ZQuoteRatePlanTriggerHandler.getInstance();
    
    //Handle the after insert
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.OnAfterInsert(Trigger.new,Trigger.newMap);
        }
    } else if(Trigger.isBefore){
    	if(Trigger.isInsert){
            handler.OnBeforeInsert(Trigger.new);
        }
    }
}