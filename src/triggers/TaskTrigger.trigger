/**
* @author Unknown
* @date Unknown
* @description Task trigger
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         06/01/2016  //added singleton pattern
**/
trigger TaskTrigger on Task (before insert, before update) {
	
	TaskTriggerHandler instance = TaskTriggerHandler.getInstance();
	
	if (Trigger.isBefore) {
		if (Trigger.isInsert) {
			instance.BeforeInsert(Trigger.new);
		}else if (Trigger.isUpdate) {
			instance.BeforeUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}