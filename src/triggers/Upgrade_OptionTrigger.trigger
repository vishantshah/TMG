/*
 * File Name   : Upgrade_OptionTrigger
 * Description : Trigger for Upgrade_Option__c
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 */ 
trigger Upgrade_OptionTrigger on Upgrade_Option__c (after insert, after undelete, after update) {

	//Instantiate handler
	Upgrade_OptionTriggerHandler handler =  new Upgrade_OptionTriggerHandler();
	
	//Call after events
	if (Trigger.isAfter) {
		if (Trigger.isUnDelete)
			handler.afterUndelete(Trigger.new, Trigger.newMap);
		if (Trigger.isInsert)
			handler.afterInsert(Trigger.new, Trigger.newMap);
		if (Trigger.isUpdate)
			handler.afterUpdate(Trigger.new, Trigger.newMap);
	}
}