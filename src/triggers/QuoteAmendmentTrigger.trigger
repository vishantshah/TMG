/**
* Author:       Sally ElGhoul (Tquila)
* Date:         16/05/2015
* Description:  this trigger on zqu__QuoteAmendment__c object
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
trigger QuoteAmendmentTrigger on zqu__QuoteAmendment__c ( before delete,before update) {
	
	//get an instance from the quotechargetriggerHandler clas
    QuoteAmendmentTriggerHandler handler = QuoteAmendmentTriggerHandler.getInstance();
    
    //check if is before and is delete action call the before method from the handler class
    if(Trigger.isBefore){
    	
    	if(trigger.isDelete){
    		handler.onBeforeDelete(Trigger.new,Trigger.oldMap);
    	}else if(trigger.isUpdate){
    		handler.OnBeforeUpdate(Trigger.new);
    	}
    }
}