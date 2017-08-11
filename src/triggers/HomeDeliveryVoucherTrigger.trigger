/**
* @author Wiktor Czykin
* @date 27/06/2017
* @description trigger for Home_Delivery_Voucher__c object
*#############Change Log#############
*Modified by     Change Date
**/
trigger HomeDeliveryVoucherTrigger on Home_Delivery_Voucher__c (before insert, before update){

    HomeDeliveryVoucherTriggerHandler handler = HomeDeliveryVoucherTriggerHandler.getInstance();
    
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}