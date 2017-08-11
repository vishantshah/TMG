/**
* @author Cristina Anghenie
* @date 25/09/2015
* @description Subscription Incentive Association trigger handler
#############Change Log#############
Modified by     Version     Change Date
**/
public with sharing class SubscriptionIncentiveTriggerHandler {
	
	public void OnAfterInsert(List<SubscriptionIncentiveAssociation__c> newSubIncentives){
		updateSubscriptionIncentiveDescription(newSubIncentives);
	}
	
	/*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 25/09/2015
    Version - 1.1
    Function - Populate Incentive_Description__c when a new incentive is added to a subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public void updateSubscriptionIncentiveDescription(List<SubscriptionIncentiveAssociation__c> newSubIncentives){
		map<Id,SubscriptionIncentiveAssociation__c> subIncentivesDesc = new map<Id,SubscriptionIncentiveAssociation__c>();
		List<Subscription__c> subsToUpdate = new List<Subscription__c>();
		//create a map with all the subs that ne
		for(SubscriptionIncentiveAssociation__c sia : [SELECT Incentive__r.Incentive_Description__c, Subscription__r.Incentive_Description__c, Subscription__c 
													   FROM SubscriptionIncentiveAssociation__c 
													   WHERE Id IN: newSubIncentives
													   ORDER BY Subscription__c, CreatedDate desc]){
			if(sia.Subscription__c!=null && !subIncentivesDesc.keyset().contains(sia.Subscription__c)){
	    		subIncentivesDesc.put(sia.Subscription__c, sia);
	    	}
		}
		if(!subIncentivesDesc.isEmpty()){
			//populate the incentive description field if subs status moves to pending
	    	for (Id subId : subIncentivesDesc.keyset()){
	        	subsToUpdate.add(new Subscription__c( Id = subId, Incentive_Description__c = subIncentivesDesc.get(subId).Incentive__r.Incentive_Description__c));
	        }
		}
		//update subs but skip DeferredCalculation
		if(!subsToUpdate.isEmpty()){	
			SubscriptionTriggerHandler.getInstance().bDeferredCalculationSkip = true; 
			update subsToUpdate;
			SubscriptionTriggerHandler.getInstance().bDeferredCalculationSkip = false; 
		}
		 
	}
}