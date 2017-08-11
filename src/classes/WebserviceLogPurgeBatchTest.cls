@isTest(SeeAllData=false)
public class WebserviceLogPurgeBatchTest {
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
}