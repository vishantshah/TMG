/*
 * File Name   : SubscriberDiagnosticsExtractBatchTest
 * Description : Test class for SubscriberDiagnosticsExtractBatch
 *
 * Modification Log
 * ======================================================== 
 * Ver Date       Author         Modification
 * --- ---------- -------------- --------------------------
 * 1.0 15/04/2014 IVAN ALMEIDA	 Initial Version 
 * 1.1 07/12/2015 CRISTINA ANG.	 Clean up code and remove reference to WebPackActionsTestData	
 */
@isTest
private class SubscriberDiagnosticsExtractBatchTest {

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Description - Test successful execution of the batch class
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         12/07/2015  //clean up code and remove reference to WebPackActionsTestData
    ****************************************************************************************/
	static testmethod void testBatchSuccess() {
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadSubscriberValidationRuleInfo();
		tdu.createIndividualSubscribers();
		
		Test.startTest();
			//Execute batch
			SubscriberDiagnosticsExtractBatch diagnosticsBatch = new SubscriberDiagnosticsExtractBatch('Select Subscriber_Number_static__c from Account');
			Database.executeBatch(diagnosticsBatch);
		Test.stopTest();
		
		List<Subscriber_Diagnostics_Extract__c> extracts = [Select ID, Status__c, (Select Id from Attachments) from Subscriber_Diagnostics_Extract__c];
		System.assertEquals(1, extracts.size());
		System.assertEquals(1, extracts[0].Attachments.size());
		System.assertEquals(Constants.DIAGNOSTICS_EXTRACT_STATUS_SUCCESS, extracts[0].Status__c);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Description - Test execution of the batch class without records to process, so the process logs the erroneous run.
    #############Change Log#############
    Modified by     	Version     Change Date
    ****************************************************************************************/
	static testmethod void testBatchNoRecords() {
		Test.startTest();
			//Execute batch
			SubscriberDiagnosticsExtractBatch diagnosticsBatch = new SubscriberDiagnosticsExtractBatch('Select Subscriber_Number_static__c from Account');
			Database.executeBatch(diagnosticsBatch);
		Test.stopTest();
		
		List<Subscriber_Diagnostics_Extract__c> extracts = [Select ID, Status__c, (Select Id from Attachments) from Subscriber_Diagnostics_Extract__c];
		System.assertEquals(1, extracts.size());
		System.assertEquals(0, extracts[0].Attachments.size());
		System.assertEquals(Constants.DIAGNOSTICS_EXTRACT_STATUS_ERROR, extracts[0].Status__c);
	}
}