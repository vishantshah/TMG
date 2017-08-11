/** This batch will purge the webservice logs that are more than a certain number of weeks old
	The number of weeks must be specified in the constructor
*/
global class WebserviceLogPurgeBatch implements Database.Batchable<sObject> {

	global final String query;
	global final String toAddress;
	global final String replyToAddress;
	global final Date oldestDate;
		
	global WebserviceLogPurgeBatch(String ta, String rta, Integer weeksToDelete) {
		toAddress = ta;
		replyToAddress = rta;
		oldestDate = Date.today().addDays(-7 * weeksToDelete);
		query = 'Select Id From WebService_Log__c Where Request_Time__c < :oldestDate';
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext bc) {
		/*List<String> toAddresses = new List<String> {toAddress};
		TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(toAddresses);
		emailUtil.plainTextBody('The batch apex is now complete.')
				.senderDisplayName('Simon Goodyear')
				.replyTo(replyToAddress)
				.subject('Webservice Log Purge Batch Apex Complete')
				.build()
				.sendEmail();*/ 
	}
	
	/*
	08/10/2013 CY - Moved test class to WebserviceLogPurgeBatchTest.cls
	
	//unit test
	static testMethod void WebserviceLogPurgeBatchTest() {

		// insert something to delete
		Webservice_Log__c log = new Webservice_Log__c( Request_Time__c = Date.valueOf('2001-01-01'), Response_time__c = Date.valueOf('1999-05-07') );
		insert log;
		//System.assertEquals( [Select Count() From Webservice_Log__c Where Request_Time__c = :Date.valueOf('2001-01-01') and Response_Time__c = :Date.valueOf('1999-05-07') ], 1 );

		// Run the batch between testStart/Stop to wait for the async batch to compelete
		Test.startTest();
		String toAddress = 'simon.goodyear@telegraph.co.uk';
		String replyToAddress = 'simon.goodyear@telegraph.co.uk';
		WebserviceLogPurgeBatch batchable = new WebserviceLogPurgeBatch(toAddress, replyToAddress, 1);		
		Id accountUpdateBatchId = Database.executeBatch(batchable);
		//System.assert(accountUpdateBatchId != null);
		Test.stopTest();
	
		// Make sure the record has gone
		//System.assertEquals( [Select Count() From Webservice_Log__c Where Request_Time__c = :Date.valueOf('2001-01-01') and Response_Time__c = :Date.valueOf('1999-05-07')], 0 );
	
	 }
	 */
	
}