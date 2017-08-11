@isTest
private class OutboundCaseRequeueControllerTest {
	private static final Integer RECORDS_SIZE = 2;
	
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 12/09/2016
    Version - 1.0
    Function - Test data setup 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@testSetup
	private static void testDataSetup(){

		final String DEFAULT_CASE_STATUS = 'Not Started';

		TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);

		/* CREATE OUTBOUND CALL SETTING AND RULES */
		tdu.iCounter = 1;
		tdu.createSalesOutboundCallSetting();
		tdu.createOutboundCallRule();
	}

	@isTest static void testConstructorOne() {

        PageReference pageRef = Page.OutboundCaseRequeue;
        Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('recTypeName', Constants.OC_SALES_RECORD_TYPE_NAME);
		ApexPages.currentPage().getParameters().put('retURL', 'google.com');
		Outbound_Call_Setting__c ocSetting = [SELECT Id, Name FROM Outbound_Call_Setting__c LIMIT 1];
		ApexPages.StandardController con = new ApexPages.StandardController(ocSetting);
		OutboundCaseRequeueController controller = new OutboundCaseRequeueController(con);

		Test.startTest();

			controller.setStatusSelections(new List<String>{'Busy'} );
			controller.setStageSelections(new List<String>{'T2'});
			controller.getCallStatus();
			controller.getCaseStage();
			controller.getStageSelections();
			controller.getStatusSelections();
			controller.recalculateQueue();

		Test.stopTest();
	}
	
}