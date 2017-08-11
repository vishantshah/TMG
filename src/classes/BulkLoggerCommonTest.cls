/**
* @author Wiktor Czykin
* @date 16/12/2015
* @description test class for BulkLoggerCommon
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class BulkLoggerCommonTest {
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 17/12/2015
    Version - 1.0
    Function - check all positive flows. So tiny no point splitting at the moment.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testPositiveFlows(){
		Test.startTest();
			WebService_Log__c log = TMGUtil.newLogWebServiceRequestSerialized(	Constants.DIRECTION_OUTBOUND, 
		                                                                        'http://telegraph.co.uk', 
		                                                                        Constants.LOG_CREATE_SESSION,
		                                                                        new Map<String, Object>{'parameter' => 'someString'},
		                                                                      	null,
		                                                                      	null,
		                                                                      	null
	                                                                   		);
			
			MppInterfaceHttp blc = new MppInterfaceHttp();
			String sBufferName = MppInterfaceHttp.class.getName();
			System.assertEquals(sBufferName, blc.sLoggerKey);
			blc.addLogToBuffer(log);
			List<WebService_Log__c> lstLog = [select Id from WebService_Log__c];
			System.assert(lstLog.isEmpty());
			System.assert(TMGUtil.mapCommonLogBuffer.containsKey(sBufferName));
			System.assertEquals(1, TMGUtil.mapCommonLogBuffer.get(sBufferName).size());
			blc.saveLogBuffer();
			lstLog = [select Id from WebService_Log__c];
			System.assert(!lstLog.isEmpty());
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 17/12/2015
    Version - 1.0
    Function - check all positive flows. So tiny no point splitting at the moment.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testNegativeFlow(){
		WebService_Log__c log = TMGUtil.newLogWebServiceRequestSerialized(	Constants.DIRECTION_OUTBOUND, 
	                                                                        'http://telegraph.co.uk', 
	                                                                        Constants.LOG_CREATE_SESSION,
	                                                                        new Map<String, Object>{'parameter' => 'someString'},
	                                                                      	null,
	                                                                      	null,
	                                                                      	null
                                                                   		);
		
		MppInterfaceHttp blc = new MppInterfaceHttp();
		String sBufferName = MppInterfaceHttp.class.getName();
		blc.addLogToBuffer(log);
		System.assertEquals(1, TMGUtil.mapCommonLogBuffer.get(sBufferName).size());
		BulkLoggerCommon.bTestFailure = true;
		blc.saveLogBuffer();
		List<WebService_Log__c> lstLog = [select Id from WebService_Log__c];
		System.assert(lstLog.isEmpty());
	}
}