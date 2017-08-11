/*
 * File Name   : Upgrade_OptionTriggerHandler
 * Description : Trigger handler for Upgrade_OptionTrigger
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 30/01/2014 IVAN ALMEIDA	 Initial Version 
 */ 
public with sharing class Upgrade_OptionTriggerHandler {

	//AFTER INSERT
	public void afterInsert(List<Upgrade_Option__c> upgradeOptions, Map<Id, Upgrade_Option__c> upgradeOptionsNewMap) {
		checkUniqueness(upgradeOptions, upgradeOptionsNewMap);
	}
	
	//AFTER UPDATE
	public void afterUpdate(List<Upgrade_Option__c> upgradeOptions, Map<Id, Upgrade_Option__c> upgradeOptionsNewMap) {
		checkUniqueness(upgradeOptions, upgradeOptionsNewMap);
	}
	
	//AFTER UNDELETE
	public void afterUndelete(List<Upgrade_Option__c> upgradeOptions, Map<Id, Upgrade_Option__c> upgradeOptionsNewMap) {
		checkUniqueness(upgradeOptions, upgradeOptionsNewMap);
	}
	
	//Check the uniqueness of the combination From - To options
	private void checkUniqueness(List<Upgrade_Option__c> upgradeOptions, Map<Id, Upgrade_Option__c> upgradeOptionsNewMap) {
		Map<String, Id> idsToOptionsId = new Map<String, Id>();
		Set<Id> fromIds = new Set<Id>();
		Set<Id> toIds = new Set<Id>();
		String tempKey = '';	
		
		//Loop the new values, put them in a Map to check uniqueness and in sets to query the object
		for (Upgrade_Option__c upgradeOption : upgradeOptions) {
			tempKey = String.valueOf(upgradeOption.Pricing_Option_From__c) + String.valueOf(upgradeOption.Pricing_Option_To__c);
			if (idsToOptionsId.containsKey(tempKey))
				upgradeOptionsNewMap.get(upgradeOption.Id).addError(Label.ServiceIdsUniqueFile);
			else {
				idsToOptionsId.put(tempKey, upgradeOption.Id);
				fromIds.add(upgradeOption.Pricing_Option_From__c);
				toIds.add(upgradeOption.Pricing_Option_To__c);
			}
		}
		
		//Query existing options
		List<Upgrade_Option__c> existingOptions = [Select Pricing_Option_From__c, Pricing_Option_To__c 
												   from Upgrade_Option__c 
												   where Pricing_Option_From__c in :fromIds
														 or Pricing_Option_To__c in :toIds];
									
		//Loop the query results and check that the new values don't correspond with already existing records
		tempKey = '';
		for (Upgrade_Option__c existingOption : existingOptions) {
			tempKey = String.valueOf(existingOption.Pricing_Option_From__c) + String.valueOf(existingOption.Pricing_Option_To__c);
			if (idsToOptionsId.containsKey(tempKey)) {
				if (idsToOptionsId.get(tempKey) != existingOption.Id) 
					upgradeOptionsNewMap.get(idsToOptionsId.get(tempKey)).addError(Label.UpgradeOptionsUnique);
			}
		}
	}
}