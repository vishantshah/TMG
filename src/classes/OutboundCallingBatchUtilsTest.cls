/**
* @author Michal Szewczyk
* @date 08/07/2016
* @description Set of unit tests for the OutboundCallingBatchUtils class 
*#############Change Log#############
*Modified by     Version     Change Date
**/
@isTest
private class OutboundCallingBatchUtilsTest {

	/***************************************************************************************
	Developer - Michal Szewczyk
	Date - 08/07/2016
	Version - 1.0
	Function - test utils method that populate case based on json string
	#############Change Log#############
	Modified by	 Version	 Change Date
	****************************************************************************************/
	@isTest
	private static void testPopulateCaseValues() {

		String jsonCaseInput = '{"attributes":{"type":"Case"},"Status":"New","Priority":"Normal","Reason":"Bad Debt","Origin":"Internal Records","Type":"Outbound Calling"}';
		Case newCase = OutboundCallingBatchUtils.populateCaseValues(jsonCaseInput);

		System.assertEquals('New',newCase.Status);
		System.assertEquals('Normal',newCase.Priority);
		System.assertEquals('Bad Debt',newCase.Reason);
	}

	/***************************************************************************************
	Developer - Michal Szewczyk
	Date - 08/07/2016
	Version - 1.0
	Function - test utils method that get id of queue based on queue name
	#############Change Log#############
	Modified by	 Version	 Change Date
	****************************************************************************************/
	@isTest
	private static void testGetQueueId() {

		try {
			OutboundCallingBatchUtils.getQueueId('testQueue');
		} catch (Exception e) {
			System.assertEquals('The queue does not exist : testQueue', e.getMessage());
		}


	}

	/***************************************************************************************
	Developer - Michal Szewczyk
	Date - 08/07/2016
	Version - 1.0
	Function - test utils method that fetch confing record - error path
	#############Change Log#############
	Modified by	 Version	 Change Date
	****************************************************************************************/
	@isTest
	private static void testFetchConfigRecord() {

		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createOutboundCallBatchSetting('Test');

		 OutboundCallingBatchUtils.fetchConfigRecord('Test');

	}

	/***************************************************************************************
	Developer - Michal Szewczyk
	Date - 08/07/2016
	Version - 1.0
	Function - test utils method that fetch confing record - error path
	#############Change Log#############
	Modified by	 Version	 Change Date
	****************************************************************************************/
	@isTest
	private static void testFetchConfigRecordError() {
		
		try{
			OutboundCallingBatchUtils.fetchConfigRecord('Test');
		} catch (Exception e){
			System.assertEquals('Active Outbound Calling Batch config record was not found', e.getMessage());
		}
	}
}