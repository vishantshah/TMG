/**
Name: POCRemovalBatch
* @author Mateusz Michalczyk
* @date 12/03/2015
* @description 	Batch, schedulable class that will run through all POC attached to TCode and delete them.
##########Change Log##########
Modified by     Version     Change Date 
*/
public without sharing class POCRemovalBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
	
	private Integer batchSize {get;set;}
	private List<Id> tCodeManagementsIDs {get;set;}
	@TestVisible private static Boolean DONT_RUN_BATCH = false;

	/*************************************************************************************** 
	Developer - Mateusz Michalczyk
	Date Created -  12/03/2015
	Version - 1.0 
	Function - 	Constructor gets TCode from which all POC are to be deleted. Defaults batch size to 200.
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public POCRemovalBatch(List<Id> tCodeManagementsIDs, Integer batchSize) {
		this.batchSize = batchSize;
		this.tCodeManagementsIDs = tCodeManagementsIDs;
	}

	/*************************************************************************************** 
	Developer - Mateusz Michalczyk
	Date Created -  12/03/2015
	Version - 1.0 
	Function - 	Constructor gets TCode from which all POC are to be deleted. Defaults batch size to 200.
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		System.assert(tCodeManagementsIDs!=null || !tCodeManagementsIDs.isEmpty(), 'Expected List<Id> of TCodes but got null or empty');
		String sQuery = 'SELECT Id FROM POC__c WHERE TCodeManagement__C IN :tCodeManagementsIDs ';
		return Database.getQueryLocator(sQuery);
	}

	/*************************************************************************************** 
	Developer - Mateusz Michalczyk
	Date Created -  12/03/2015
	Version - 1.0 
	Function - 	Simple deletion of passed POC__c.
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
   	public void execute(Database.BatchableContext BC, List<POC__c> scope) {
		delete scope;
	}

	/*************************************************************************************** 
	Developer - Mateusz Michalczyk
	Date Created -  12/03/2015
	Version - 1.0 
	Function - 	Schedulable execute implementation
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public void execute(SchedulableContext ctx) {
		if(Test.isRunningTest() && DONT_RUN_BATCH){
			return;
    	}
    	Database.executeBatch(this, this.batchSize);
    }

    /*************************************************************************************** 
	Developer - Mateusz Michalczyk
	Date Created -  12/03/2015
	Version - 1.0 
	Function - 	Batchable finish implementation - nothing happens
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public void finish(Database.BatchableContext BC) {
		System.debug('POCRemoval Batchable Finish');
	}
	
}