/**
* @author Unknown
* @date <2013
* @description  not really sure what it does -> no time to do full analysis
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         14/05/2015  //modified methods that had no webservice mocks so that they do not fail ->
                                        they have to be moved to separate class with a some proper cleanup procedure
Michal Szewczzyk 1.2        28/04/2016  //modified init() to use TestDataUtility()
Wiktor Czykin    1.3        21/03/2017  //modified a bit just to pass tests after email uniqueness was enabled 
**/
@isTest(SeeAllData=false)
private class MPPBulkSFDCSoapInterfaceTest {
	static final Integer MAX_ACCOUNTS = 20;
	
	static List<Account> getAccountData(){
		List<Account> accList = new List<Account>();
	    for(Integer i = 0; i < MAX_ACCOUNTS; i++){
	    	Account acc = new Account();
            acc.Title__c = 'Mr.';
	    	acc.FirstName = 'Amir';
	    	acc.LastName = 'Hafeez';
	    	acc.IsUsingMPP__c = true;
	    	acc.Subscriber_Number_static__c = '0000' + i;
	    	acc.PersonEmail = 'amir.hafeez.test' + i + '@testmppxxxx.com';
	    	acc.LastModifiedById = UserInfo.getUserId();
	    	accList.add(acc);
	    }
	    return accList;
	}
	
	static void init(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createZProductFeatures();
	}
	
	/*
		This is a general test method for MPPBulkSFDCSoapInterface.SoapRequest class.
	*/
    static testMethod void testGenericMethods_Default() {
    	init();
    	List<Account> accList = getAccountData();
    	insert accList;
    	
    	Constants.MPP_CALLOUT_DISABLED = true;
    	
        Test.startTest();
        	MPPBusinessObjectsIPaydev.BulkUpdateResultData res1 = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
        	res1.BulkUpdateJobId = 12345;
	    	res1.ErrorNumber = 0;
	    	res1.ErrorMessage = '';
	    	
	    	MPPBusinessObjectsIPaydev.BulkUpdateResultData res2 = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
	    	res2.BulkUpdateJobId = 12345;
	    	res2.ErrorNumber = 1007;
	    	res2.ErrorMessage = 'MPP Error';
	    	
    		//Some basic tests not really asserting here.
    		WebserviceUtil.GenericWSException e = new WebserviceUtil.GenericWSException('25', 'TEST EXCEPTION');
    		String stack = MPPBulkSFDCSoapInterface.getStackTraceMsg(e);
    		MPPBulkSFDCSoapInterface.sendErrorEmail('TEST', 'TEST', 'TEST', 'TEST', e, 'TEST');
    		
        	MPPBulkSFDCSoapInterface.UserManageRequest prop1 = new MPPBulkSFDCSoapInterface.UserManageRequest();
        	prop1.buildJobData(accList);
        	//system.assertEquals(prop1.getCurrentJobData().size(), MAX_ACCOUNTS);
        	prop1.getJobLoad();
        	prop1.createRequest(accList[0]);
        	prop1.setTestData(res1);
        	
        	prop1.getQuery();
        	//system.assertEquals(prop1.getSObjectMap().size(), MAX_ACCOUNTS);
        	prop1.setOldData(new Map<String, String>{'AMIR-HAFEEZ' => 'AMIR-HAFEEZ'});
        	//system.assertEquals(prop1.getOldData().size(), 1);
        	prop1.setQuery('SELECT Id, FirstName, LastName, Salutation, Subscriber_Number__c, PersonEmail, PersonTitle, LastModifiedById, Subscriber_Number_static__c FROM Account WHERE PersonEmail LIKE \'%@testmppxxxx.com\'');
        	//system.assertEquals(prop1.getQuery(), 'SELECT Id, FirstName, LastName, Salutation, Subscriber_Number__c, PersonEmail, PersonTitle, LastModifiedById, Subscriber_Number_static__c FROM Account WHERE PersonEmail LIKE \'%@testmppxxxx.com\'');
        	prop1.invokeCall();
        	
        	Map<Id, String> accMap = new Map<Id, String>();
        	for(Account acc :accList){
        		accMap.put(acc.Id, acc.FirstName + ',' + acc.LastName + ',' + acc.PersonEmail);
        	}
        	prop1.invokeCall(accMap);	
        
            MPPBulkSFDCSoapInterface.UserManageRequest prop2 = new MPPBulkSFDCSoapInterface.UserManageRequest('SELECT Id, FirstName, LastName, Salutation, Subscriber_Number__c, PersonEmail, PersonTitle, LastModifiedById, Subscriber_Number_static__c FROM Account WHERE PersonEmail LIKE \'%@testmppxxxx.com\'');
        	prop2.buildJobData();
        	prop2.getResult();
        Test.stopTest();
    }
    
    static testMethod void testUserChangeRequest_Valid() {
        init();
        List<Account> accList = getAccountData();
        Map<Id, List<String>> oldDetailMap = new Map<Id, List<String>>();
        insert accList;
        
        for(Account acc :accList){
        	oldDetailMap.put(acc.Id, new List<String>{acc.FirstName, acc.LastName, acc.PersonEmail});
        	//Change details.
        	acc.FirstName = 'amirxxx';
        	acc.LastName = 'hafeezxxx';
            acc.PersonEmail = 'MPP' + acc.PersonEmail;
        }
        
        //Are the old user details stored?
        //system.assertEquals(oldDetailMap.size(), MAX_ACCOUNTS);
        Test.startTest();
        	update accList;
        Test.stopTest();
        
        //This callout should fail (although the data is fine it will fail due to running in test context), 
        //so we expect it to revert back to the old user details. All details should have been reverted 
        //back and at least one task should of been created
    }
    
    static testMethod void testUserChangeRequest_InValid() {
   		init();
        List<Account> accList = getAccountData();
        Map<Id, List<String>> newDetailMap = new Map<Id, List<String>>();
        
        for(Account acc :accList){
        	//Flaging this to false should make these accounts
        	//not go through the MPP webservice callout.
        	acc.IsUsingMPP__c = false;
        }
        insert accList;
        
        for(Account acc :accList){
        	acc.FirstName = 'amirxxxx';
        	acc.LastName = 'hafeezxxx';
        	acc.PersonEmail = 'MPP' + acc.PersonEmail;
        	newDetailMap.put(acc.Id, new List<String>{acc.FirstName, acc.LastName, acc.PersonEmail});
        }

        //These accounts should not go through the trigger.
        Test.startTest();
        	update accList;
        Test.stopTest();
    }
    
    static testMethod void testUserChangeRequest_Success() 
    {
    	init();
        List<Account> accList = getAccountData();
        Map<Id, String> accMap = new Map<Id, String>();
        insert accList;
        
        for(Account acc :accList){
        	accMap.put(acc.Id, acc.FirstName + ',' + acc.LastName + ',' + acc.PersonEmail);
        	acc.FirstName = 'amirxxxx';
        	acc.LastName = 'hafeezxxx';
            acc.PersonEmail = 'MPP' + acc.PersonEmail;
        }
        
        Constants.MPP_CALLOUT_DISABLED = true;
        update accList;
        
        MPPBusinessObjectsIPaydev.BulkUpdateResultData success = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
    	success.ErrorNumber = 0;
    	success.ErrorMessage = '';
    	MPPBulkSFDCSoapInterface.UserManageRequest request = new MPPBulkSFDCSoapInterface.UserManageRequest();
    	
        Test.startTest();
        	for(Account acc :accList){
        		request.createRequest(acc);
        	}
        	
        	//Error checking on methods.
        	request.restoreDetailsOnFailure(null, null, null);
        	request.restoreDetailsOnFailure(new List<Account>(), new Map<Id, String>(), 'Test');
        	request.invokeCall(null);
        	request.invokeCall(new Map<Id, String>());
        	
        	//Test success.
        	request.setTestData(success);
        	request.invokeCall(accMap);
        Test.stopTest();
    }
    
    static testMethod void testUserChangeRequest_Failure(){
    	init();
        List<Account> accList = getAccountData();
        Map<Id, String> accMap = new Map<Id, String>();
        insert accList;
        Integer i = 110;
        for(Account acc :accList){
        	accMap.put(acc.Id, acc.FirstName + ',' + acc.LastName + ',' + acc.PersonEmail);
        	acc.FirstName = 'amirxxxx';
        	acc.LastName = 'hafeezxxx';
        	acc.PersonEmail = 'amir.hafeez.valid'+i+'@mpp.com';
            i++;
        }
        
        Constants.MPP_CALLOUT_DISABLED = true;
        update accList;
        
    	MPPBusinessObjectsIPaydev.BulkUpdateResultData failure = new MPPBusinessObjectsIPaydev.BulkUpdateResultData();
    	failure.ErrorNumber = 1007;
    	failure.ErrorMessage = 'MPP Error';
    	MPPBulkSFDCSoapInterface.UserManageRequest request = new MPPBulkSFDCSoapInterface.UserManageRequest();
        
        Test.startTest();
            for(Account acc :accList){
        		request.createRequest(acc);
        	}
        	
        	//Test failure.
        	request.setTestData(failure);
        	request.invokeCall(accMap);
        Test.stopTest();
    }
    
    private static final Integer MPP_AFFILIATE_ID = 435;
    private static final String MPP_PASSWORD = 'PASS';
    private static final Boolean FAIL_ON_FIRST_ERROR = true;
    
    /*************************************************************************************** 
    Developer - MIrfan@Appirio Plane 1.0 
    Date - 09/03/12known
    Version - 1.1
    Function - attempt to test  MPPBulkInterface class here -> should be moved to a separate test class
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/05/2015  //split 3 requests into separate methods, added mocks so that they are not skipped
    ****************************************************************************************/
 	private static testMethod void testCancelPaymentScheduleRequests(){    
   		MPPBulkInterface.SOAPEndpoint mpbi = new MPPBulkInterface.SOAPEndpoint(); 
   		MPPBusinessObjectsBulkUpdate.ArrayOfCancelPaymentScheduleRequest cancelPaymentScheduleRequests= new MPPBusinessObjectsBulkUpdate.ArrayOfCancelPaymentScheduleRequest();
        Test.setMock(WebServiceMock.class, new MPPWebserviceMocks.MPPBulkCancelPaymentScheduleMock());
   		mpbi.BulkCancelPaymentSchedule(MPP_AFFILIATE_ID, MPP_PASSWORD, cancelPaymentScheduleRequests, FAIL_ON_FIRST_ERROR);
 	}
 	
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 14/05/2015
    Version - 1.0
    Function - split from testCancelPaymentScheduleRequests() -> should be moved to a separate test class
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testChangePaymentSchedulePaymentDate(){
        MPPBulkInterface.SOAPEndpoint mpbi = new MPPBulkInterface.SOAPEndpoint();     
        MPPBusinessObjectsBulkUpdate.ArrayOfChangePaymentSchedulePaymentDateRequest changePaymentSchedulePaymentDateRequests = new MPPBusinessObjectsBulkUpdate.ArrayOfChangePaymentSchedulePaymentDateRequest();
        Test.setMock(WebServiceMock.class, new MPPWebserviceMocks.MPPBulkChangePaymentSchedulePaymentDateMock());
        mpbi.BulkChangePaymentSchedulePaymentDate(MPP_AFFILIATE_ID, MPP_PASSWORD, changePaymentSchedulePaymentDateRequests, FAIL_ON_FIRST_ERROR);

    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 14/05/2015
    Version - 1.0
    Function - split from testCancelPaymentScheduleRequests() -> should be moved to a separate test class
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testBulkUserManageRequest(){
        MPPBulkInterface.SOAPEndpoint mpbi = new MPPBulkInterface.SOAPEndpoint();     
        MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest userManageRequests = new MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest();
        Test.setMock(WebServiceMock.class, new MPPWebserviceMocks.MPPBulkUserUpdateMock());
        mpbi.BulkUserManage(MPP_AFFILIATE_ID, MPP_PASSWORD, userManageRequests, FAIL_ON_FIRST_ERROR);
    }

    /************************************************************************************** 
    Developer - MIrfa@Appirio Plane 1.2
    Date - 25/06/12
    Version - 1.1
    Function -
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/05/2015  //commented out code because of which the whole method was skipped. 
                                            To work properly it has to be split into multiple methods and response mocks have to be added.
                                            Skipping cleanup for time being as not relevant.
    ****************************************************************************************/
 	static testMethod void testMPPWcfServicesPublicBulkupdate(){
 		MPPWcfServicesPublicBulkupdate.SOAPEndpoint mpbi = new MPPWcfServicesPublicBulkupdate.SOAPEndpoint();
 		Integer affiliateId=435;
   		String password='String password';
   		MPPBusinessobjectsBulkupdate2.ArrayOfCancelPaymentScheduleRequest cancelPaymentScheduleRequests= new MPPBusinessobjectsBulkupdate2.ArrayOfCancelPaymentScheduleRequest();
   		MPPBusinessobjectsBulkupdate2.ArrayOfChangePaymentSchedulePaymentDateRequest changePaymentSchedulePaymentDateRequests = new MPPBusinessobjectsBulkupdate2.ArrayOfChangePaymentSchedulePaymentDateRequest();
   		MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest userManageRequests = new MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest();
   		MPPGlobalCoreDataContract.ArrayOfAddDynamicPaymentScheduleRequest arrPay = new MPPGlobalCoreDataContract.ArrayOfAddDynamicPaymentScheduleRequest();
   		MPPGlobalCoreDataContract.ArrayOfUserManageDirectDebitRequest arrDDReq =  new MPPGlobalCoreDataContract.ArrayOfUserManageDirectDebitRequest();
   		Boolean failOnFirstError=true;
   		
   		MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebitResponse_element aa = new MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebitResponse_element();
   		MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDate_element bb = new MPPWcfServicesPublicBulkupdate.BulkChangePaymentSchedulePaymentDate_element();
   		MPPWcfServicesPublicBulkupdate.SOAPEndpoint cc = new MPPWcfServicesPublicBulkupdate.SOAPEndpoint();
   		MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentSchedule_element dd = new MPPWcfServicesPublicBulkupdate.BulkAddDynamicPaymentSchedule_element();
   		MPPWcfServicesPublicBulkupdate.BulkUserManage_element ee= new MPPWcfServicesPublicBulkupdate.BulkUserManage_element();
   		MPPWcfServicesPublicBulkupdate.BulkCancelPaymentScheduleResponse_element ff= new MPPWcfServicesPublicBulkupdate.BulkCancelPaymentScheduleResponse_element();
   		MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebit_element gg= new MPPWcfServicesPublicBulkupdate.BulkUserManageDirectDebit_element();
   		MPPWcfServicesPublicBulkupdate.BulkUserManageResponse_element hh= new MPPWcfServicesPublicBulkupdate.BulkUserManageResponse_element();
   		MPPWcfServicesPublicBulkupdate.BulkCancelPaymentSchedule_element ii= new MPPWcfServicesPublicBulkupdate.BulkCancelPaymentSchedule_element();
 			
 	}
}