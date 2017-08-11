/**
* Author:       Michal Kwika (Accenture)
* Date:         22/01/2016
* Description:  Trigger on Case Object
*
* ******************* Change Log *******************
* Modified by       	Change Date
* Mantas Grigaliunas	19/07/2016	//OnBeforeUpdate trigger handler method added
* Konrad Czykin         13/06/2017  //OnAfterUpdate trigger handler added
**/
trigger CaseTrigger on Case (after insert, before insert, before update, after update) {

	CaseTriggerHandler handler = CaseTriggerHandler.getInstance();

	if (Trigger.isBefore) {
		if (Trigger.isInsert) {
			handler.OnBeforeInsert(Trigger.new);
		}
		if(Trigger.isUpdate){
			handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
		}
	} else if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			handler.OnAfterInsert(Trigger.new);
		}
		if(Trigger.isUpdate){
			handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}