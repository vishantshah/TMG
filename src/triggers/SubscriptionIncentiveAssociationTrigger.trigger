/**
* @author Cristina Anghenie
* @date 25/09/2015
* @description Subscription Incentive Association trigger
#############Change Log#############
Modified by     Version     Change Date
**/
trigger SubscriptionIncentiveAssociationTrigger on SubscriptionIncentiveAssociation__c (after insert) {
	SubscriptionIncentiveTriggerHandler handler = new SubscriptionIncentiveTriggerHandler();
	
	if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
    }
}