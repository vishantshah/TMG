trigger PricingOptionTrigger on Pricing_Options__c (before insert, before update) {

	PricingOptionTriggerHandler handler = PricingOptionTriggerHandler.getInstance();
	
	if(trigger.isBefore){
		if(trigger.isInsert){
			handler.OnBeforeInsert(trigger.new);
		}
		else if(trigger.isUpdate){
			handler.OnBeforeUpdate(trigger.new);
		}
	}

}