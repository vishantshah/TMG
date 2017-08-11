/** This batch will purge the webservice logs that are more than a certain number of weeks old
	The number of weeks must be specified in the constructor
*/
global class ClearDigitalEntitlementsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{

	global final string query;
	global final List<string> guids;
		
	global ClearDigitalEntitlementsBatch(List<string> guidsToClear) {
		guids = guidsToClear;
		query = 'Select Id, Subscriber_Digital_Status__c From Account Where Guid__c IN :guids';
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext bc, List<Account> scope) {
		
		for(Account a : scope){
			a.Subscriber_Digital_Status__c = 'Inactive';
			
		}
		update scope;
	}
	
	
	global void finish(Database.BatchableContext bc) {

	}

}