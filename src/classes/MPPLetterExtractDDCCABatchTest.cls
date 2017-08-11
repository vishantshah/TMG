/**
* @author Unknown
* @date Unknown
* @description Test class for MPPLetterExtractDDCCABatch class
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin	1.1			18/11/2015	//rewritten
Wiktor Czykin	1.2			09/02/2016	//modified testBatchPositiveFlow()
**/
@isTest
private class MPPLetterExtractDDCCABatchTest {
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 18/11/2015
    Version - 1.1
    Function - Positive flow test
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			09/02/2016	//added matching TSNumber to the xml response
    ****************************************************************************************/
	private static testMethod void testBatchPositiveFlow(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		for(Account acc : td.lstIndividualSubscribers){
			acc.IsUsingMPP__c = true;
		}
		update td.lstIndividualSubscribers;
		
		for(Subscription__c sub : td.lstSubscriptions){
			sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			sub.Is_MPP_DDCCA_Letter_Extracted__c = false;
			sub.isContinuous__c = true;
	   		sub.MPP_CC_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
	   		sub.Payment_Type__c = Constants.SUB_PMETHOD_CC;
			sub.MPP_Premium_Subscription_ID__c = '174764';//this has to match whatever is set in MPPWebserviceMocks response
		}
		update td.lstSubscriptions;
		List<Account> lstAccount = [select Id, Subscriber_Number__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
		System.assert(!lstAccount.isEmpty() && lstAccount[0].Subscriber_Number__c != null);

		
		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(	td.lstPlaneURL[0].baseURL__c, 
																												new Map<String,String>{MPPWebserviceMocks.PARAM_TS1 => lstAccount[0].Subscriber_Number__c
																													});
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
			MPPLetterExtractDDCCABatch batch = new MPPLetterExtractDDCCABatch(	Constants.SUB_ACQUISITION_PAYMENT_CC, 
																				'CC_CSV', 
																				MPPLetterExtractDDCCABatch.FILTERTYPE_RECORDTYPE,
										 										MPPLetterExtractData.getMPP_CCA_BatchQuery(), 
										 										'amir.hafeez@telegraph.co.uk', 
										 										'amir.hafeez@telegraph.co.uk', 
										 										'amir.hafeez@telegraph.co.uk');
			Id batchId = Database.executeBatch(batch, td.iCounter);
		Test.stopTest();
		
		System.assertNotEquals(batchId, null);
		List<Subscription__c> subList = [SELECT Id, Is_MPP_DDCCA_Letter_Extracted__c FROM Subscription__c WHERE Id IN :td.lstSubscriptions];
		for(Subscription__c s :subList){
			System.assertEquals(true, s.Is_MPP_DDCCA_Letter_Extracted__c);
		}
	}
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 18/11/2015
    Version - 1.0
    Function - Negative flow test - mpp error returned
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testBatchNegativeFlowMPPError(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		for(Account acc : td.lstIndividualSubscribers){
			acc.IsUsingMPP__c = true;
		}
		update td.lstIndividualSubscribers;
		
		for(Subscription__c sub : td.lstSubscriptions){
			sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			sub.Is_MPP_DDCCA_Letter_Extracted__c = false;
			sub.isContinuous__c = true;
	   		sub.MPP_CC_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
	   		sub.Payment_Type__c = Constants.SUB_PMETHOD_CC;
			sub.MPP_Premium_Subscription_ID__c = '174764';//this has to match whatever is set in MPPWebserviceMocks response
		}
		update td.lstSubscriptions;
		
		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(td.lstPlaneURL[0].baseURL__c, new Map<String,String>{MPPWebserviceMocks.PARAM_ISFAILURE=>''});
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
			MPPLetterExtractDDCCABatch batch = new MPPLetterExtractDDCCABatch(	Constants.SUB_ACQUISITION_PAYMENT_CC, 
																				'CC_CSV', 
																				MPPLetterExtractDDCCABatch.FILTERTYPE_RECORDTYPE,
										 										MPPLetterExtractData.getMPP_CCA_BatchQuery(), 
										 										'amir.hafeez@telegraph.co.uk', 
										 										'amir.hafeez@telegraph.co.uk', 
										 										'amir.hafeez@telegraph.co.uk');
			Id batchId = Database.executeBatch(batch, td.iCounter);
			
			batch.updateQueue(null);//unrelated line just to add coverage for one if
		Test.stopTest();
		
		System.assertNotEquals(batchId, null);
		List<Subscription__c> subList = [SELECT Id, Is_MPP_DDCCA_Letter_Extracted__c FROM Subscription__c WHERE Id IN :td.lstSubscriptions];
		for(Subscription__c s :subList){
			System.assertEquals(false, s.Is_MPP_DDCCA_Letter_Extracted__c);
		}
	}
}