/**
* @author Unknown
* @date Unknown
* @description Test class for MPPInterfaceHTTP
#############Change Log#############
Modified by     	Version     Change Date
Wiktor Czykin   	1.1         13/05/2015  //added test for new method userManagePartialAccountBased(), changed API version so that tests run in sandboxed mode
Wiktor Czykin		1.2			26/05/2015	//updated testBulkPaymentDetails(), testChangePaymentScheduleDate(), testEditPaymentScheduleDate(), added @testSetup init
Cristina Anghenie	1.3			11/9/2015	//update cancelPaymentSchedule test method
Cristina Anghenie	1.4			14/9/2015	//update test method because testResponse was moved to MPPWebserviceMocks
Mantas Grigaliunas	1.5			31/01/2017  //modified testRefundOrder
**/
@isTest
private class MPPInterfaceHTTPTest {
	
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 22/05/2015
    Version - 1.0
    Function - test init for all methods
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @testSetup static void init(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadPlaneURL();
    }

	public static testMethod void testCancelSubscription(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.CancelSubscriptionResult result;
    	try{
			result = mpp.CancelSubscription('', '');
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
		System.assertEquals(null, ex);
		System.assertEquals('Removed', result.status);
	}
	
	public static testMethod void testCancelSubscription_FAILURE(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		mpp.isFailureTest = true;
		Exception ex;
		MPPInterfaceHTTP.CancelSubscriptionResult result;
    	try{
			result = mpp.CancelSubscription('', '');
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
		System.assert(ex instanceof MPPInterfaceHTTP.MPPInterfaceHTTPException);
		MPPInterfaceHTTP.MPPInterfaceHTTPException ex2 = (MPPInterfaceHTTP.MPPInterfaceHTTPException)ex;
		System.assertEquals('Message',ex2.getErrorMessage());
	}
	
	public static testMethod void testRemoveSubscription(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.CancelSubscriptionResult result;
    	try{
			result = mpp.RemoveSubscription('', '');
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
		System.assertEquals(null, ex);
		System.assertEquals('Removed', result.status);
	}
	
	public static testMethod void testRemoveSubscriptionForClientUserId(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.CancelSubscriptionResult result;
    	try{
			result = mpp.RemoveSubscriptionForClientUserId('', '');
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
		System.assertEquals(null, ex);
		System.assertEquals('Removed', result.status);
	}
	
	public static testMethod void testRefundOrder(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.RefundOrderResult result;
		Decimal refundAmount = 90.0;
    	try{
			result = mpp.processRefundOrder('', '', refundAmount);
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
		System.assertEquals(null, ex);
		System.assertEquals(refundAmount, Decimal.valueOf(result.refundAmount));
	}
	
	public static testMethod void testUserManage(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.UserManageResult result;
		String guid = 'GUID_TEST';
    	try{
			result =mpp.UserManage('', null, null, null, null, null, null, null, null, null, null, null, null, 'GUID_TEST');
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
		System.assertEquals(null, ex);
		System.assertEquals(guid, result.guid);
	}
	

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			26/05/2015	//removed lines referencing removed lines
    ****************************************************************************************/
	public static testMethod void testBulkPaymentDetails(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadGeneral();
        tdu.loadPlaneURL();
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		List<MPPInterfaceHTTP.PaymentDetailResult> result;
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{});
            Test.setMock(HttpCalloutMock.class, mock); 
            CreditCardExpiryDateUpdateBatch batchCls = new CreditCardExpiryDateUpdateBatch();
            Database.executeBatch(batchCls);
        Test.stopTest();
    	try{
			result = mpp.getBulkPaymentDetailResult('TEST');
    	}catch(Exception e){
    		System.assert(false, 'exception thrown where should not be');
		}
		
		System.assertNotEquals(result, null);
		System.assertEquals(result.size(), 1);
	}
	
	public static testMethod void testReactivatePaymentSchedule(){
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadPlaneURL();
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		MPPInterfaceHTTP.ReactivatePaymentScheduleResult result;
		Exception ex;
		
        Test.startTest();
            //failure because error returned from MPP
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_AMOUNT => '468',
                MPPWebserviceMocks.PARAM_NOSCHEDULES => '12',
                MPPWebserviceMocks.PARAM_CURRENCY => 'GBP',
                MPPWebserviceMocks.PARAM_PAYMENTSCHID => '1061'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
	    	try{
				result = mpp.reactivatePaymentSchedule('TEST');
	    	}
	    	catch(Exception e){
	    		System.debug(e);
				ex = e;
			}
		Test.stopTest();
		System.assertNotEquals(result, null);
		System.assertEquals(null, ex);
		System.assertNotEquals(result, null);
		System.assertEquals(result.chargedStatusMissedPayments, 'false');
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			11/09/2015	//update method to check that the right sub was cancelled
    ****************************************************************************************/
	public static testMethod void testCancelPaymentSchedule(){
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadPlaneURL();
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.CancelPaymentScheduleResult result;
			
		Test.startTest();	
			MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_AMOUNT => '468',
                MPPWebserviceMocks.PARAM_NOSCHEDULES => '12',
                MPPWebserviceMocks.PARAM_CURRENCY => 'GBP',
                MPPWebserviceMocks.PARAM_PAYMENTSCHID => '1061'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
	    	try{
				result = mpp.cancelPaymentSchedule('1061');
	    	}
	    	catch(Exception e){
	    		System.debug(e);
				ex = e;
			}
		Test.stopTest();
		System.assertEquals(null, ex);
		System.assertNotEquals(result, null);
		System.assertEquals(result.noCancelledPayments,'12');
		System.assertEquals(result.paymentScheduleId,'1061');
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			26/05/2015	//removed lines referencing removed lines
    ****************************************************************************************/
	public static testMethod void testChangePaymentScheduleDate(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		MPPInterfaceHTTP.ChangePaymentScheduleDateResult result;

    	try{
			result = mpp.changePaymentScheduleDate('TEST', '21/08/2009', '2011-10-15T00:00:00', '0');
    	}catch(Exception e){
    		System.assert(false, 'exception thrown where should not be');
		}
		
		System.assertNotEquals(result, null);
		System.assertEquals('15', result.sfdcNextPaymentDate, JSON.serialize(result));
		
		result = new MPPInterfaceHTTP.ChangePaymentScheduleDateResult('2011-10-01T00:00:00');
		System.assertEquals(result.sfdcNextPaymentDate, '1');
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			26/05/2015	//removed lines referencing removed lines
    ****************************************************************************************/
	public static testMethod void testEditPaymentScheduleDate(){
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.EditPaymentScheduleResult result;

		PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));

		Test.startTest();
			MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{});
            Test.setMock(HttpCalloutMock.class, mock); 
	    	try{
				result = mpp.editPaymentSchedule('10989', '100', 'Monthly');
	    	}catch(Exception e){
	    		System.assert(false, 'exception thrown where should not be');
			}
		Test.stopTest();
		
		System.assertNotEquals(result, null);
	}
	
	public static testMethod void testAutoRenewSubscriber()
	{
		MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
		Exception ex;
		MPPInterfaceHTTP.AutoRenewResult result;

    	try{
			result = mpp.AutoRenewSubscriber('10989', '10000', 'true');
    	}
    	catch(Exception e){
    		System.debug(e);
			ex = e;
		}
	}


	/** Test method for Subscriptions BAU:PP-1615 */
	private static testMethod void testUserServices() {
		Test.startTest();
		try {
			MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
			MPPInterfaceHTTp.UserServicesResult userServicesRes = mpp.getUserServices(null, false);
			List<MppInterfaceHTTP.ServiceInformationResult> serviceInfoResultList =
				userServicesRes.serviceInformation.getServiceInformationResults();
			system.debug('LIST SIZE::' + serviceInfoResultList.size());
			if(serviceInfoResultList.size() == 1) {
				DateTime resultDate = ((MppInterfaceHTTP.ServiceInformationResult) serviceInfoResultList.get(0)).expiryDate;
				system.debug('EXPIRY DATE::' + resultDate);
			} 
		} catch (Exception e) {
			system.debug(e);
		}
		Test.stopTest();
	}
	
	/** Test method for subscriberOverview API */
	public static testMethod void testUserInfo() {
		Test.startTest();
		try {
			MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
			MPPInterfaceHTTp.UserInfoResult userInfoRes = mpp.callUserInfoByTSNumber('TS9899999');
			if(userInfoRes.AccountStatus != null) {
				System.assertEquals(userInfoRes.AccountStatus, 'Active');
			} 
		} catch (Exception e) {
			system.debug(e);
		}
		Test.stopTest();
	}

	/** Test method for subscriberOverview API */
	public static testMethod void testUserOrderHistory() {
		Test.startTest();
		try {
			MPPInterfaceHTTP mpp = new MPPInterfaceHTTP();
			MPPInterfaceHTTp.UserOrderHistoryResult UserOrderHistoryResult = mpp.callUserOrderHistoryByMppGuid('TS9899999');
			if(UserOrderHistoryResult.TotalNumberOfOrders != null) {
				System.assertEquals(UserOrderHistoryResult.TotalNumberOfOrders, '3');
			} 
		} catch (Exception e) {
			system.debug(e);
		}
		Test.stopTest();
	}
	
	/** Test method for Subscriptions BAU:PP-1631 */
	private static testMethod void testChangePaymentSchedulePaymentDate() {
		Test.startTest();
		String empty = '';
		try {
			MPPInterfaceHTTP callout = new MPPInterfaceHTTP();
			MPPInterfaceHTTP.ChangePaymentSchedulePaymentDateResult cpspdResult = 
				callout.changePaymentSchedulePaymentDate(empty, empty, empty, empty, empty, false);

			List<MPPInterfaceHTTP.ChangePaymentScheduleDateResult> paymentResults = 
				cpspdResult.getChangedPaymentSchedules().getChangePaymentSchedulePaymentDateItems();			
			system.debug('ChangePaymentScheduleDateResult Items::' + paymentResults.size());
		} catch (Exception e) {
			system.debug(e);
		}
		Test.stopTest();
	}

	//Test AddSubscription with a successful callout
	private static testMethod void testAddSubscription() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('MPPAddSubscriptionSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		MPPInterfaceHTTP.AddSubscriptionResult addSubscriptionResult = MPPInterfaceHTTP.AddSubscription('TSNumber', 10000, 20000);
		Test.stopTest();
		
		System.assertEquals(addSubscriptionResult.ErrorNumber, '0');
	}
	
	//Test AddSubscription with a wrong callout
	private static testMethod void testAddSubscriptionCalloutError() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('MPPAddSubscriptionSuccess');
		mock.setStatusCode(404);
		mock.setStatus('TEST - Not found');
		mock.setHeader('Content-Type', 'application/json');
		
		Boolean errorCaught = false;
		MPPInterfaceHTTP.AddSubscriptionResult addSubscriptionResult;
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		
		try {
			addSubscriptionResult = MPPInterfaceHTTP.AddSubscription('TSNumber', 10000, 20000);
			System.assert(false, 'An error must happen');
		}
		catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
			errorCaught = true;
		}

		Test.stopTest();
		
		System.assert(errorCaught);
	}
	
	//Test AddSubscription with a generic error
	private static testMethod void testAddSubscriptionGenericError() {
		MPPInterfaceHTTP.AddSubscriptionResult addSubscriptionResult;
		Boolean errorCaught = false;
		
		Test.startTest();
		
		try {
			addSubscriptionResult = MPPInterfaceHTTP.AddSubscription('TSNumber', 10000, 20000);
			System.assert(false, 'An error must happen');
		}
		catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
			errorCaught = true;
		}

		Test.stopTest();
		
		System.assert(errorCaught);
	}
	
	//Test ChangeSubscriptionWithoutCharge with a successful callout
	private static testMethod void testChangeSubscriptionWithoutCharge() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		MPPInterfaceHTTP.ChangeSubscriptionResult changeSubscriptionResult = MPPInterfaceHTTP.ChangeSubscriptionWithoutCharge('TSNumber', 10000, 20000);
		Test.stopTest();
		
		System.assertEquals(changeSubscriptionResult.ErrorNumber, '0');
	}
	
	//Test ChangeSubscriptionWithoutCharge with a wrong callout
	private static testMethod void testChangeSubscriptionWithoutChargeCalloutError() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithoutChargeSuccess');
		mock.setStatusCode(404);
		mock.setStatus('TEST - Not found');
		mock.setHeader('Content-Type', 'application/json');
		
		Boolean errorCaught = false;
		MPPInterfaceHTTP.ChangeSubscriptionResult changeSubscriptionResult;
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		
		try {
			changeSubscriptionResult = MPPInterfaceHTTP.ChangeSubscriptionWithoutCharge('TSNumber', 10000, 20000);
			System.assert(false, 'An error must happen');
		}
		catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
			errorCaught = true;
		}

		Test.stopTest();
		
		System.assert(errorCaught);
	}
	
	//Test ChangeSubscriptionWithoutCharge with a generic error
	private static testMethod void testChangeSubscriptionWithoutChargeError() {
		MPPInterfaceHTTP.ChangeSubscriptionResult changeSubscriptionResult;
		Boolean errorCaught = false;
		
		Test.startTest();
		
		try {
			changeSubscriptionResult = MPPInterfaceHTTP.ChangeSubscriptionWithoutCharge('TSNumber', 10000, 20000);
			System.assert(false, 'An error must happen');
		}
		catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
			errorCaught = true;
		}

		Test.stopTest();
		
		System.assert(errorCaught);
	}
	
	//Test ChangeSubscriptionWithCharge with a successful callout
	private static testMethod void testChangeSubscriptionWithCharge() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithChargeSuccess');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		MPPInterfaceHTTP.ChangeSubscriptionResult changeSubscriptionResult = MPPInterfaceHTTP.ChangeSubscriptionWithCharge('TSNumber', 10000, 20000);
		Test.stopTest();
		
		System.assertEquals(changeSubscriptionResult.ErrorNumber, '0');
	}
	
	//Test ChangeSubscriptionWithCharge with a wrong callout
	private static testMethod void testChangeSubscriptionWithChargeCalloutError() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ChangeSubscriptionWithChargeSuccess');
		mock.setStatusCode(404);
		mock.setStatus('TEST - Not found');
		mock.setHeader('Content-Type', 'application/json');
		
		Boolean errorCaught = false;
		MPPInterfaceHTTP.ChangeSubscriptionResult changeSubscriptionResult;
		Test.setMock(HttpCalloutMock.class, mock);
		
		Test.startTest();
		
		try {
			changeSubscriptionResult = MPPInterfaceHTTP.ChangeSubscriptionWithCharge('TSNumber', 10000, 20000);
			System.assert(false, 'An error must happen');
		}
		catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
			errorCaught = true;
		}

		Test.stopTest();
		
		System.assert(errorCaught);
	}
	
	//Test ChangeSubscriptionWithCharge with a generic error
	private static testMethod void testChangeSubscriptionWithChargeError() {
		MPPInterfaceHTTP.ChangeSubscriptionResult changeSubscriptionResult;
		Boolean errorCaught = false;
		
		Test.startTest();
		
		try {
			changeSubscriptionResult = MPPInterfaceHTTP.ChangeSubscriptionWithCharge('TSNumber', 10000, 20000);
			System.assert(false, 'An error must happen');
		}
		catch (MPPInterfaceHTTP.MPPInterfaceHTTPException MPPex) {
			errorCaught = true;
		}

		Test.stopTest();
		
		System.assert(errorCaught);
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  16/05/2015
    Version - 1.0
    Function - Tests userManagePartialAccountBased()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testUserManagePartialAccountBased(){
		TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
		td.createIndividualSubscribers();

		Test.startTest();

			List<Account> lstAcc = [select Id, FirstName, LastName, Subscriber_Number_static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
			System.assert(lstAcc.size()==1);
			Test.setMock(HttpCalloutMock.class, MPPWebserviceMocks.getMPPUserManageSuccessMock());
			MPPInterfaceHTTP mih = new MPPInterfaceHTTP();
			try{
				mih.userManagePartialAccountBased(lstAcc[0], new Set<String>{'FirstName','Subscriber_Number_static__c'});
			}catch(Exception e){
				System.assert(false, 'transaction failed where it should succeed');
			}
		Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date -  16/05/2015
    Version - 1.0
    Function - Tests userManagePartialAccountBased() failure
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testUserManagePartialAccountBasedFailure(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
		td.createIndividualSubscribers();

		Test.startTest();
			List<Account> lstAcc = [select Id, FirstName, LastName, Subscriber_Number_static__c from Account where Id = :td.lstIndividualSubscribers[0].Id];
			System.assert(lstAcc.size()==1);
			Test.setMock(HttpCalloutMock.class, MPPWebserviceMocks.getMPPUserManageFailureWithMessageMock());
			MPPInterfaceHTTP mih = new MPPInterfaceHTTP();
			try{
				mih.userManagePartialAccountBased(lstAcc[0], new Set<String>{'FirstName','Subscriber_Number_static__c'});
				System.assert(false, 'logic did not fail where it should have');
			}catch(Exception e){
				System.assert(e.getMessage().contains('Error'), e.getMessage());
			}
		Test.stopTest();
    }
}