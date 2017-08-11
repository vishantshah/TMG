/**
* @author Gavin Palmer
* @date 26/05/2016
* @description trigger on TCode_Product__c
*#############Change Log#############
*Modified by     Version     Change Date
*Wiktor Czykin   1.1         29/09/2016  //added passing old set of records on before update
**/
trigger TCodeProductTrigger on TCode_Product__c (before insert, before update) {

    TCodeProductTriggerHandler handler = TCodeProductTriggerHandler.getInstance();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}