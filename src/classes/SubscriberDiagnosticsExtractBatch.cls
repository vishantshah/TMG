/*
 * File Name   : SubscriberDiagnosticsExtractBatch
 * Description : Batch process that gets diagnostics for all customers resulting by the SOQL query received
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 15/04/2014 IVAN ALMEIDA	 Initial Version 
 */ 
global class SubscriberDiagnosticsExtractBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	global String query {get;set;}
	global String fileBody {get;set;}
	global Integer numberOfRecords {
		get {
			if (numberOfRecords == null) {
				numberOfRecords = 0;
			}
			return numberOfRecords;
		}
		set;
	}
	
	//Constructor
	global SubscriberDiagnosticsExtractBatch(String queryIn){
		query = queryIn;
	}

	//Start - get scope and set the header for the csv attachment
	global Database.QueryLocator start(Database.BatchableContext BC){
		fileBody = 'TS Number,ruleCode,ruleResultCode,ruleUserMessage,ruleData,ruleGroup,ruleName\n';
		return Database.getQueryLocator(query);
	}

	//Execute - Run diagnostics on the scope and build the rows for the csv attachment
	global void execute(Database.BatchableContext BC, List<sObject> scope){
		Account tempAccount = new Account();
		subscriberConsoleWebservice.subscriberIdentifier tempSubIdentifier;
		subscriberConsoleWebservice.subscriberOverviewResult tempSubscriberOverviewResult;
		String ruleCode, ruleResultCode, ruleUserMessage, ruleData, ruleGroup, ruleName;
		for(sObject obj : scope){
			numberOfRecords ++;
			tempAccount = (Account) obj;
			tempSubIdentifier = new subscriberConsoleWebservice.subscriberIdentifier('TSNUMBER', tempAccount.Subscriber_Number_static__c);
            tempSubscriberOverviewResult = subscriberConsoleWebservice.subscriberOverview(tempSubIdentifier);
            for (subscriberConsolesWebserviceHandlers.subscriberRuleLog rl : tempSubscriberOverviewResult.subscriberRuleLog) {
                ruleCode = String.isEmpty(rl.ruleCode) ? '' : rl.ruleCode.replace(',',';');
                ruleResultCode = String.isEmpty(rl.ruleResultCode) ? '' : rl.ruleResultCode.replace(',',';');
                ruleUserMessage = String.isEmpty(rl.ruleUserMessage) ? '' : rl.ruleUserMessage.replace(',', ';');
                ruleData = String.isEmpty(rl.ruleData) ? '' : rl.ruleData.replace(',', ';');
                ruleGroup = String.isEmpty(rl.ruleGroup) ? '' : rl.ruleGroup.replace(',', ';');
                ruleName = String.isEmpty(rl.ruleName) ? '' : rl.ruleName.replace(',', ';');
                fileBody += '"' + tempAccount.Subscriber_Number_static__c + '",'; 
				fileBody +=	'"' + ruleCode + '",';
				fileBody +=	'"' + ruleResultCode + '",';
				fileBody += '"' + ruleUserMessage + '",';
				fileBody += '"' + ruleData + '",';
				fileBody += '"' + ruleGroup + '",';
				fileBody += '"' + ruleName + '"';
				fileBody += '\n';
            }
		}
	}

	//Finish - create extract record and attachment if all went correctly
	global void finish(Database.BatchableContext BC){
		Subscriber_Diagnostics_Extract__c extract = new Subscriber_Diagnostics_Extract__c();
		extract.Date_extracted__c = Datetime.now();
		extract.Number_of_Records__c = numberOfRecords;
		extract.SOQL_Query__c = query;
		try {
			insert extract;
			if (numberOfRecords != 0) {
				Attachment attachment = new Attachment();
				attachment.Body = Blob.valueOf(fileBody);
				attachment.Name = Label.DiagnosticsExtractFileName;
				attachment.ParentId = extract.Id; 
				insert attachment;
			}
			else {
				extract.Description__c = Label.DiagnosticExtractNoRecordsProcessedError;
				extract.Status__c = Constants.DIAGNOSTICS_EXTRACT_STATUS_ERROR;
				update extract;
			}
		}
		catch (Exception ex) {
			extract.Description__c = ex.getMessage() + ' --- ' + ex.getStackTraceString();
			extract.Status__c = Constants.DIAGNOSTICS_EXTRACT_STATUS_ERROR;
			upsert extract;
		}
	}
}