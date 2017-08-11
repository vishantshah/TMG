/**
* @author Pawel Chrzanowski
* @date 09/09/2016
* @description Outbound Call Rule trigger
#############Change Log#############
Modified by     Version     Change Date
**/
trigger OutboundCallRuleTrigger on Outbound_Call_Rule__c (before delete) {

    System.debug('OutboundCallRuleTrigger starts');
    
    OutboundCallRuleTriggerHandler handler = OutboundCallRuleTriggerHandler.getInstance();
    
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            handler.onBeforeDelete(Trigger.old, Trigger.oldMap);
        }
    }
}