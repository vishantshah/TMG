trigger UsageTrackingTrigger on Usage_Tracking__c (before insert, before update, after insert, after update) {
	
	if(trigger.isBefore){	
		
		if(trigger.isInsert){
			UsageTrackingTriggerHandler.beforeInsertHandler(trigger.new);
		}
		
		if(trigger.isUpdate){
			UsageTrackingTriggerHandler.beforeUpdateHandler(trigger.new, trigger.oldMap);
		}
		
	}
	
	if(trigger.isAfter){	
		
		if(trigger.isInsert){
			UsageTrackingTriggerHandler.afterInsertHandler(trigger.new);
		}
		
		if(trigger.isUpdate){
			UsageTrackingTriggerHandler.afterUpdateHandler(trigger.new, trigger.oldMap);
		}
		
	}
}