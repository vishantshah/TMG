/**
* @author Gavin Palmer
* @date 26/05/2016
* @description trigger on Price_Plan__c
*#############Change Log#############
*Modified by     Version     Change Date
*Wiktor Czykin   1.1         29/09/2016  //added passing of oldMap on before update
**/
trigger PricePlanTrigger on Price_Plan__c (before insert, before update) {

    PricePlanTriggerHandler handler = PricePlanTriggerHandler.getInstance();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}
