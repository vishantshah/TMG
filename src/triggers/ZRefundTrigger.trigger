/**
* Author:       Michal Kwika (Accenture)
* Date:         28/09/2015
* Description:  Trigger on Zuora refund Object
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika		09/02/2016 - removed not used methods
**/
trigger ZRefundTrigger on Zuora__Refund__c (after insert, after update, before insert, before update) {

	ZRefundTriggerHandler handler = ZRefundTriggerHandler.getInstance();

	if (Trigger.isBefore) {
		if (Trigger.isInsert) {
			handler.OnBeforeInsert(Trigger.new);
		} else if (Trigger.isUpdate) {
			handler.OnBeforeUpdate( Trigger.old,
			                        Trigger.new,
			                        Trigger.newMap);
		}
	} else if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			handler.OnAfterInsert(Trigger.new);
		} else if (Trigger.isUpdate) {
			handler.OnAfterUpdate(  Trigger.old,
			                        Trigger.new,
			                        Trigger.oldMap,
			                        Trigger.newMap);
		}
	}
}