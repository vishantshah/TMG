/**
* @author Unknown
* @date Unknown
* @description Utility class for HTTP callouts to MPP
#############Change Log#############
Modified by     Version 	Change Date
Wiktor Czykin   	1.1     13/05/2015  //added userManagePartialAccountBased(), few new attributes, 
Wiktor Czykin		1.2		21/05/2015	//refactored user order history fetching method
Wiktor Czykin		1.3		22/05/2015	//trying to split endpoints from requests so that at some point those could be extracted to settings
										//moved hardcoded responses to MPPWebserviceMock class
Wiktor Czykin		1.4		29/05/2015	//modified callUserOrderHistoryByMppGuid(), added getBulkPaymentDetailResultBasedOnTSNumbers()
Cristina Anghenie	1.5		04/08/2015	//add new method for MPP single update 		
Cristina Anghenie	1.6		11/09/2015	//remove test result from cancelPaymentSchedule from class and move it to MPPWebserviceMocks
Wiktor Czykin		1.7		06/10/2015	//modified PaymentDetailResult wrapper
Wiktor Czykin		1.8		08/10/2015	//modified getUserOrderHistoryFromMPP() and getUserOrderHistoryResult()
Cristina Ang		1.9		11/12/2015	//modified UserManageSingleUpdate() and invokeSingleFutureUserManageRequest()
Wiktor Czykin		2.0		17/12/2015	//added extention for BulkLoggerCommon and its usage in constructor and UserManageSingleUpdate()
Pawel Chrzanowski	2.1		07/03/2016	//modified invokeSingleFutureUserManageRequest() to fix no-email-change error in MPP
Pawel Chrzanowski	2.2		29/03/2016	//modified RefundOrder() to use lookup to ZProduct on subscriber
Pawel Chrzanowski	2.3		14/04/2016	//added AutoRenewSubscriber() with optional call logging, RefundOrder() with optional Transaction History creation and call logging
Michal Szewczyk		2.4		02/08/2016	//changed initialise() from private to public
Mantas Grigaliunas	2.5		11/11/2016	//modified createRefundTransactionHistory() and RefundOrder()
Mantas Grigaliunas	2.6		25/11/2016	//added aditional variables to createRefundTransactionHistory() and RefundOrder()
Mantas Grigaliunas	2.7		01/12/2016	//refactored web service logging in RefundOrder method
Mantas Grigaliunas	2.8		30/01/2017	//modified and renamed RefundOrder to processRefundOrder, added RefundOrder wrapper
**/
global class MPPInterfaceHTTP extends BulkLoggerCommon{
	
	public static Boolean bRunTest = false;
	public static final String STRING_BASEURL = '[BASE_URL]';
	//endpoints with no request params
	public static final String userOrderHistoryEndpoint = STRING_BASEURL+'interface/mpp/eDeveloper/v7_15/eDeveloper.GETXML.svc/UserOrderHistory';
	public static final String userManageEndpoint = STRING_BASEURL+'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/UserManage';
	public static final String bulkPaymentDetailsEndpoint = STRING_BASEURL+'web/affiliates/affiliate_435/GetPaymentDetails.ashx';
	public static final String changePaymentScheduleDateEndpointOnly = STRING_BASEURL+'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/ChangePaymentSchedulePaymentDate';
	public static final String editPaymentScheduleEnpoint = STRING_BASEURL+'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/EditPaymentSchedule';
	public static final String autoRenewalEndpoint = STRING_BASEURL+'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/SetAutoRenew';
	public static final String cancelPaymentScheduleEndpointOnly = STRING_BASEURL+'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/CancelPaymentSchedule';
	public static final String userInfoEndpointOnly = STRING_BASEURL+'interface/mpp/eDeveloper/v7/eDeveloper.GETXML.svc/UserInfo';
	//requests
	private static final String getGuidEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/GetGuid?affiliateid=435&password=[PASSWORD]&paramnumber=1&paramname1=TSNUmber&paramvalue1=[TS_NUMBER]';
	@TestVisible private static final String cancelSubscriptionEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/CancelSubscription?affiliateid=435&password=[PASSWORD]&serviceGroupTag=&serviceId=[SERVICE_ID]&guid=[GUID]&uki=&clientUserId=';
	private static final String removeSubscriptionEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/RemoveSubscription?affiliateid=435&password=[PASSWORD]&serviceGroupTag=&serviceId=[SERVICE_ID]&guid=[GUID]&uki=&clientUserId=';
	private static final String removeSubscriptionForClientUserIdEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/RemoveSubscription?affiliateid=435&password=[PASSWORD]&serviceGroupTag=&serviceId=[SERVICE_ID]&uki=&clientUserId=[CLIENTUSERID]';
	@TestVisible private static final String refundOrderEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/RefundOrder?affiliateid=435&password=[PASSWORD]&orderId=[ORDER_ID]&grossAmount=[REFUND_AMOUNT]&clientOrderId=';
	private static final String userManageEndpointRequest = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/UserManage?affiliateid=435&password=[PASSWORD]&newUki=[EMAIL]&creditCardType=Undefined&title=[TITLE]&firstName=[FIRST_NAME]&surname=[SURNAME]&gender=NotKnown&billingHouseName=[HOUSE_NAME]&billingHouseFlatNumber=[HOUSE_NUMBER]&billingStreet=[STREET]&billingDistrict=[DISTRICT]&billingTownCity=[CITY]&billingCounty=[COUNTY]&billingPostcode=[POSTCODE]&billingCountry=[COUNTRY]&AccountTypeId=0&AccountDetailsParamName1=TSNumber&AccountDetailsParamValue1=[TS_NUMBER]';
	private static final String userManageSingleEmailUpdateEndpointRequest = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/UserManage?affiliateid=435&password=[PASSWORD]&AccounttypeId=0&uki=[OLDEMAIL]&newUki=[EMAIL]&title=[TITLE]&firstName=[FIRST_NAME]&surname=[SURNAME]&gender=NotKnown&creditCardType=Undefined&AccountDetailsParamName1=TSNumber&AccountDetailsParamValue1=[TS_NUMBER]';
	private static final String userManageSingleUpdateEndpointRequest = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/UserManage?affiliateid=435&password=[PASSWORD]&AccounttypeId=0&uki=[EMAIL]&title=[TITLE]&firstName=[FIRST_NAME]&surname=[SURNAME]&gender=NotKnown&creditCardType=Undefined&AccountDetailsParamName1=TSNumber&AccountDetailsParamValue1=[TS_NUMBER]';
	private static final String userInfoEndpoint = '[BASE_URL]interface/mpp/eDeveloper/v7/eDeveloper.GETXML.svc/UserInfo?clientid=435&apiPassword=[PASSWORD]&clientUserId=[TSNUMBER]';
	private static final String userInfoEndpointEmail = '[BASE_URL]interface/mpp/eDeveloper/v7/eDeveloper.GETXML.svc/UserInfo?clientid=435&apiPassword=[PASSWORD]&emailAddress=[EMAIL]';
	private static final String	userOrderHistorySOAPEndpointRequest = '[BASE_URL]interface/mpp/eDeveloper/v7/eDeveloper.GETXML.svc/UserOrderHistory?clientId=435&clientUserId=[USERID]&apiPassword=[PASSWORD]&emailAddress=[EMAIL]&fromDate=[DTFROM]&toDate=[DTTO]&sortAscending=[ASC]&numOrdersInPage=100&pageNum=1';
	@TestVisible private static final String userOrderHistoryEndpointRequest = '[BASE_URL]interface/mpp/eDeveloper/v7_15/eDeveloper.GETXML.svc/UserOrderHistory?clientId=435&apiPassword=[PASSWORD]&guid=[GUID]&fromDateUTC=2012-01-01&toDateUTC=[TODAY]&numOrdersInPage=100&pageNum=1';
	private static final String bulkPaymentDetailsEndpointRequest = '[BASE_URL]web/affiliates/affiliate_435/GetPaymentDetails.ashx?affiliateid=435&password=[PASSWORD]&';
	private static final String reactivatePaymentScheduleEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/ReactivatePaymentSchedule?affiliateid=435&password=[PASSWORD]&paymentScheduleId=[PAYMENT_SCHEDULE_ID]&processMissedPayments=false';
	private static final String cancelPaymentScheduleEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/CancelPaymentSchedule?affiliateid=435&password=[PASSWORD]&paymentScheduleId=[PAYMENT_SCHEDULE_ID]';
	private static final String changePaymentScheduleDateEndpoint = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/ChangePaymentSchedulePaymentDate?affiliateid=435&password=[PASSWORD]&paymentScheduleId=[PAYMENT_SCHEDULE_ID]&DateOfMonth=[DATE_OF_MONTH]&DateOffset=[DATE_OFFSET]&EarliestPaymentDate=[START_DATE]';
	private static final String editPaymentScheduleEnpointRequest = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/EditPaymentSchedule?affiliateid=435&password=[PASSWORD]&paymentScheduleId=[PAYMENT_SCHEDULE_ID]&clientReference=&totalAmount=[TOTAL_PRICE]&frequency=[FREQUENCY]';
	private static final String autoRenewalEndpointRequest = '[BASE_URL]interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/SetAutoRenew?affiliateid=435&password=[PASSWORD]&serviceId=[SERVICE_ID]&guid=[GUID]&autoRenewEnabled=[AUTO_RENEW]&uki=&pin=&clientUserId=';
	@TestVisible private static final String addSubscriptionEndpoint = 'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/AddSubscription';
	@TestVisible private static final String changeSubscriptionWithoutChargeEndpoint = 'interface/mpp/iPayDeveloper/v5/iPayDeveloper.GETXML.svc/ChangeSubscriptionWithoutCharge';
	@TestVisible private static final String changeSubscriptionWithChargeEndpoint = 'interface/mpp/eDeveloper/v7_10/eDeveloper.GETXML.svc/ChangeSubscriptionWithCharge';
	/* Added for Subscriptions BAU:Subscriptions BAU:PP-1631 */
	private static final String changePaymentSchedulePaymentDateEndpoint = '[BASE_URL]interface/mpp/eDeveloper/v7_5/eDeveloper.GETXML.svc/ChangePaymentSchedulePaymentDate?clientId=435&apiPassword=[PASSWORD]&paymentScheduleId=[PAYMENT_SCHEDULE_ID]&dateOfMonth=[DATE_OF_MONTH]&dateOffset=[DATE_OFFSET]&earliestPaymentDate=[EARLIEST_PAYMENT_DATE]&cascadeChange=[CASCADE_CHANGE]';
	private static final String userServicesEndpoint = '[BASE_URL]interface/mpp/eDeveloper/v7_5/eDeveloper.GETXML.svc/UserServices?clientId=435&apiPassword=[PASSWORD]&clientUserId=[TSNUMBER]';
	private static final String userServicesEndpointForGuid = '[BASE_URL]interface/mpp/eDeveloper/v7_5/eDeveloper.GETXML.svc/UserServices?clientId=435&apiPassword=[PASSWORD]&guid=[GUID]';	
	public static Boolean logCancelation {
		get {
			if (logCancelation == null)
				logCancelation = true;
			return logCancelation;
		}
		set;
	}
	public String MPP_GUID {get;set;}
	public String BASE_MPP_URL {get;set;}
	private String MPP_PASSWORD;
	private String MPP_AFFILIATEID;
	public Boolean RENDER_MPP_FRAMES {get; private set;}
	 
	public Boolean isFailureTest = false;
	private String currentAccountTsNumber {get;set;}
	private String testXML;
	
	//map based on which request parameters are generated -> currently only used for custom UserManage
    public static final Map<String, String> MAP_ACCOUNT_FIELDS_TO_MPP_FIELDS = new Map<String, String>{
    	'Salutation' => 'title',
    	'FirstName' => 'firstName',
    	'LastName' => 'surname',
    	'PersonTitle' => 'title',
    	'PersonEmail' => 'uki'
    };
    //map based on which custom request parameters are generated -> currently only used for custom UserManage
    public static final Map<String, String> MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS = new Map<String, String>{
    	'Subscriber_Number_static__c'=>'TSNumber',
    	'Guid__c' => 'SAM_GUID'
    };

    public static final String MPP_CUSTOMPARAM_NAME = 'AccountDetailsParamName';
    public static final String MPP_CUSTOMPARAM_VALUE = 'AccountDetailsParamValue';
    
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			16/12/2015	//added execution of parent class constructor
    ****************************************************************************************/
	public MPPInterfaceHTTP(){
		super(MPPInterfaceHTTP.class.getName());
	}
	
	/*
	*	Extension Controller for Account Management
	*/
	public MPPInterfaceHTTP(ApexPages.StandardController stdController ){
		if(stdController.getRecord().getSObjectType() == Account.sObjectType){
			Account acc = (Account)stdController.getRecord();
			currentAccountTsNumber = acc.Subscriber_Number_static__c;
		}else if(stdController.getRecord().getSObjectType() == Subscription__c.sObjectType){
			Subscription__c sub = (Subscription__c)stdController.getRecord();
			currentAccountTsNumber = sub.Subscriber__r.Subscriber_Number_static__c;
		}
	}
	
	/*
	*	Calls the REST Method to get a MPP Session GUID
	*	It will be then inserted in the URL for the Account Management iFrames
	*/
	public void initMPPGuid(){
		Boolean disableFrames = PlaneURL__c.getInstance('MPP').Disable_Frames__c;
		this.RENDER_MPP_FRAMES = (disableFrames != true);
		
		if(this.RENDER_MPP_FRAMES){
			this.initialise(currentAccountTsNumber);
		}	
	}
	
	public void setTestXML(String xmlData)
	{
		this.testXML = xmlData;
	}
	
	public String getTestXML()
	{
		return this.testXML;
	}

	// START : Subscriptions BAU:PP-1862, Subscriptions BAU:PP-1615, Subscriptions BAU:PP-1631
	/**
	 * A helper method to log webservice request/response after a callout has been made from the caller and not directly
	 * in this class.
	 *
	 * Since multipe callouts can be method from a single caller method this would result in a callout exception 
	 * as each API in MPPInterfaceHTTP logs webservice which is a DML operation. This would result in an operation as:
	 * callout/dml/callout which is not supported by salesforce and would result in a callout exception.
	 *
	 * To avoid this exception, any caller should make sure that the callouts have been made and then this method should
	 * be called to log the request response accordingly.
	 *
	 * @param direction			inbound/outbound
	 * @param endpoint			the endpoint URL
	 * @param methodName		the MPPInterfaceHTTP method name invoked
	 * @param parameters		the request parameters to be logged
	 * @param response			the response to be logged
	 */
	public void logWebserviceRequestResponse(String direction, String endpoint, String methodName, 
		Map<String, Object> parameters, Object response) {
			
		// Logging call
		ID logId = TMGUtil.logWebServiceRequest(direction, endpoint, methodName, parameters);        
		// Logging the Response
		TMGUtil.logWebServiceResponse(logId, response);	
	}

	/**
	 * This method invokes and retrieves the user services response from MPP by passing the tsNumber
	 *
	 * @param TSNumber					the tsNumber for which the user services response is to be retrieved
	 * @param isLogWebServiceEnabled	a boolean param to identify if the webservice logging DML operation is to be
	 *									carried out or not
	 *
	 * @see #logWebserviceRequestResponse()
	 */
	public UserServicesResult getUserServices(String TSNumber, Boolean isLogWebServiceEnabled) {
		string errorMessage, errorNumber;
		initialise(TSNumber); 
		Dom.Document response;
		
        if (!Test.isRunningTest()){
        	try {
				response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.userServicesEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL)
																				.replace('[PASSWORD]', this.MPP_PASSWORD)
																  				   .replace('[TSNUMBER]', TSNumber));
        	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(), ex.getErrorMessage());
        	}
        } else{ // Dummy Response for Test
        	response = new Dom.Document();
        	response.load(MPPInterfaceHTTPHelper.getUserServicesTestXML()); 
        }	
	    UserServicesResult result = MPPInterfaceHTTPHelper.parseUserServicesResponse(response);											  
		
		if(isLogWebServiceEnabled) {
			// Logging call
			ID logId = TMGUtil.logWebServiceRequest('Outbound', userServicesEndpoint, 'getUserServices', new Map<String,Object>{'TSNUMBER' => TSNumber});        
			// Logging the Response
			TMGUtil.logWebServiceResponse(logId, result);	
		}
		
		return result;
	}

	public UserServicesResult getUserServicesByMppGuid(String guid) {
		initialiseIgnoreGuid();
		string errorMessage, errorNumber;
		Dom.Document response;
		
        if (!Test.isRunningTest()){
        	try {
				response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.userServicesEndpointForGuid.replace('[BASE_URL]',this.BASE_MPP_URL)
																				.replace('[PASSWORD]', this.MPP_PASSWORD)
																  				   .replace('[GUID]', guid));
          	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
          } else{ // Dummy Response for Test
        	response = new Dom.Document();
        	response.load(MPPInterfaceHTTPHelper.getUserServicesTestXML()); 
        }	
	    UserServicesResult result = MPPInterfaceHTTPHelper.parseUserServicesResponse(response);											  
		
		return result;
	}	
	
	/** 
     * Added for Subscriptions BAU:PP-1631
	 * This method invokes and retrieves the changePaymentSchedulePaymentDate MPP service.
	 *
	 * @param premSubId					the premium subscription id
	 * @param startDate					the earliest payment start date
	 * @param dateOfMonth				the date of month for payment
	 * @param dateOffset				the date offset
	 * @param cascadeChange				boolean value to determine if cascade effect is required
	 * @param isLogWebServiceEnabled	a boolean param to identify if the webservice logging DML operation is to be
	 *									carried out or not
	 * 
	 * @see #logWebserviceRequestResponse
	 * @see MPPRestAjaxService#changePaymentDay()
	 */
    public ChangePaymentSchedulePaymentDateResult changePaymentSchedulePaymentDate(
    	String premSubId, String startDate, 
    	String dateOfMonth, String dateOffset, String cascadeChange, Boolean isLogWebServiceEnabled) {

		ChangePaymentSchedulePaymentDateResult result = new ChangePaymentSchedulePaymentDateResult();    	
    	String errorMessage, errorNumber;
    	
    	initialiseIgnoreGuid();
    	Dom.Document response;
    	
    	if (!Test.isRunningTest()){
    		try {
    			response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.changePaymentSchedulePaymentDateEndpoint
	    			.replace('[BASE_URL]', this.BASE_MPP_URL)
	    			.replace('[PASSWORD]', this.MPP_PASSWORD)
	    			.replace('[PAYMENT_SCHEDULE_ID]', premSubId)
	    			.replace('[DATE_OF_MONTH]', dateOfMonth)
	    			.replace('[DATE_OFFSET]', dateOffset)
	    			.replace('[EARLIEST_PAYMENT_DATE]', startDate)
	    			.replace('[CASCADE_CHANGE]', cascadeChange));
	    	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
    	}else{
    		//Dummy Response for test.
    		response = new Dom.Document();
    		response.load(MPPInterfaceHTTPHelper.getChangePaymentScheduleDateTestXML());
    	}
    	
    	for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage'){
				errorMessage = node.getText();
			}	
			if(node.getName() == 'ErrorNumber'){
				errorNumber = node.getText();
			}
			
			if((errorNumber != null && errorNumber != '') && (errorMessage != null && errorMessage != '')) {
				break;
			}
			
    		if(node.getName() == 'ChangedPaymentSchedules') {
    			ChangedPaymentSchedules cps = new ChangedPaymentSchedules();
    			
    			for(DOM.Xmlnode schedulePaymentDateItemNode : node.getChildElements()) {
    				if(schedulePaymentDateItemNode.getName() == 'ChangePaymentSchedulePaymentDateItem') {
    					ChangePaymentScheduleDateResult cpsdresult = new ChangePaymentScheduleDateResult();
    					
    					for(DOM.Xmlnode changeSchedulePaymentDateItemNode : schedulePaymentDateItemNode.getChildElements()) {
					    	
							if(changeSchedulePaymentDateItemNode.getName() == 'NextPaymentDate'){
								cpsdresult.nextPaymentDate =
							       Date.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(changeSchedulePaymentDateItemNode.getText()));
							}
							if(changeSchedulePaymentDateItemNode.getName() == 'ExpiryDate'){
								cpsdresult.expiryDate = 
								     Date.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(changeSchedulePaymentDateItemNode.getText()));
							}
							if(changeSchedulePaymentDateItemNode.getName() == 'PaymentScheduleId'){
								cpsdresult.paymentScheduleId = changeSchedulePaymentDateItemNode.getText();
							}
				
							if(changeSchedulePaymentDateItemNode.getName() == 'DatedPayment'){
								for(DOM.Xmlnode datedPaymentNode : changeSchedulePaymentDateItemNode.getChildElements()) {
									if(datedPaymentNode.getName() == 'DatedPaymentv7_5') {
										DatedPayment datedPayment = new DatedPayment();
										// parse and populate the DatedPayments node
										for(DOM.Xmlnode dpNode : datedPaymentNode.getChildElements()) {
											if(dpNode.getName() == 'Amount'){
												datedPayment.amount = dpNode.getText();
											}	
											if(dpNode.getName() == 'Currency'){
												datedPayment.pCurrency = dpNode.getText();
											}
											if(dpNode.getName() == 'OrderDate'){
												datedPayment.orderDate = dpNode.getText();
											}
										}
										cpsdresult.datedPaymentList.add(datedPayment);
									}
								}
							}		
    					}
    					cps.pymtScheduleDateResultList.add(cpsdresult);
    				}
    			}
    			result.changedPymtSchedules = cps;
    		}
		}
				
		if((errorNumber != null && errorNumber != '') && (errorMessage != null && errorMessage != '')) {
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        if(isLogWebServiceEnabled) {
	        // Logging call
	        ID logId = 
	        	TMGUtil.logWebServiceRequest(
	        			'Outbound', 
	        			MPPInterfaceHTTP.changePaymentScheduleDateEndpoint, 'changePaymentSchedulePaymentDate', 
	        			new Map<String, Object>{
							'PAYMENT_SCHEDULE_ID' => premSubId, 
							'EARLIEST_PAYMENT_DATE' => startDate,
							'DATE_OF_MONTH' => dateOfMonth,
							'DATE_OFFSET' => dateOffset,
							'CASCADE_CHANGE' => cascadeChange});
	        
	        // Logging the Response
			TMGUtil.logWebServiceResponse(logId, result);	
        }
    	return result;
    }
	// END : Subscriptions BAU:PP-1862, Subscriptions BAU:PP-1615, Subscriptions BAU:PP-1631

	
	public CancelSubscriptionResult CancelSubscription(string TSNumber, string serviceId){

		string errorMessage, errorNumber;
		
		initialise(TSNumber); 
		
		Dom.Document response;
        if (!Test.isRunningTest()){
        	try {
				response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.cancelSubscriptionEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL)
																				   .replace('[GUID]', this.MPP_GUID)
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																  				   .replace('[SERVICE_ID]', ServiceId));
        	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
        }
		// Dummy Response for Test
        else{
        	response = new Dom.Document();
        	response.load('<CancelSubscriptionResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'
				  +'<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+(isFailureTest?'Message':'')+'</ErrorMessage>'
				  +'<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
				  +'<ServiceGroupTag xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Digital Products</ServiceGroupTag>'
				  +'<ServiceGroupTitle xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Digital Products</ServiceGroupTitle>'
				  +'<ServiceId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">11206</ServiceId>'
				  +'<Status xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Removed</Status>'
				  +'<DeferredRevenue xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">20</DeferredRevenue>'
				  +'</CancelSubscriptionResult>');
        }	
														  
		CancelSubscriptionResult result = new CancelSubscriptionResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			
			if(node.getName() == 'ErrorMessage')
				errorMessage = node.getText();
				
			if(node.getName() == 'ErrorNumber')
				errorNumber = node.getText();
				
			if(node.getName() == 'ServiceGroupTag')
				result.serviceGroupTag = node.getText();
				
			if(node.getName() == 'ServiceGroupTitle')
				result.serviceGroupTitle = node.getText();
				
			if(node.getName() == 'ServiceId')
				result.serviceId = node.getText();
				
			if(node.getName() == 'Status')
				result.status = node.getText();
				
			if(node.getName() == 'DeferredRevenue')
				result.deferredRevenue = node.getText();
			
			if(node.getName() == 'DeferredRevenueCurrency')
				result.deferredRevenueCurrency = node.getText();
		}
		
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
		}
		
		if (logCancelation) {
			// Logging call
	        ID logId = TMGUtil.logWebServiceRequest('Outbound', cancelSubscriptionEndpoint, 'CancelSubscription', new Map<String,Object>{'GUID' => this.MPP_GUID});
	        
			// Logging the Response
			TMGUtil.logWebServiceResponse(logId, result);
		}	
		
		return result;

	}
	
	public CancelSubscriptionResult RemoveSubscription(string TSNumber, string serviceId){
		
		string errorMessage, errorNumber;

		initialise(TSNumber);
		
        Dom.Document response;
        if (!Test.isRunningTest()){
        	try {
			response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.removeSubscriptionEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL)
																				   .replace('[GUID]', this.MPP_GUID)
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																  				   .replace('[SERVICE_ID]', serviceId));
        	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
        }
        // Dummy Response for Test
        else{
        	response = new Dom.Document();
        	response.load('<CancelSubscriptionResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'
				  +'<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>'
				  +'<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
				  +'<DeferredRevenue xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">90.0</DeferredRevenue>'
				  +'<DeferredRevenueCurrency xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">9.99</DeferredRevenueCurrency>'
				  +'<ServiceGroupTag xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Digital Products</ServiceGroupTag>'
				  +'<ServiceGroupTitle xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Digital Products</ServiceGroupTitle>'
				  +'<ServiceId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">11206</ServiceId>'
				  +'<Status xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Removed</Status>'
				  +'</CancelSubscriptionResult>');
        }	
																  
		CancelSubscriptionResult result = new CancelSubscriptionResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			
			if(node.getName() == 'ErrorMessage')
				errorMessage = node.getText();
				
			if(node.getName() == 'ErrorNumber')
				errorNumber = node.getText();
				
			if(node.getName() == 'DeferredRevenue')
				result.deferredRevenue = node.getText();
				
			if(node.getName() == 'DeferredRevenueCurrency')
				result.deferredRevenueCurrency = node.getText();
				
			if(node.getName() == 'ServiceGroupTag')
				result.serviceGroupTag = node.getText();
				
			if(node.getName() == 'ServiceGroupTitle')
				result.serviceGroupTitle = node.getText();
				
			if(node.getName() == 'ServiceId')
				result.serviceId = node.getText();
				
			if(node.getName() == 'Status')
				result.status = node.getText();
				
		}

		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
		}
		return result;
	}
	
	public CancelSubscriptionResult RemoveSubscriptionForClientUserId(string TSNumber, string serviceId){
		
		string errorMessage, errorNumber;

		initialise(TSNumber);
		
        Dom.Document response;
        if (!Test.isRunningTest()){
        	try {
			response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.removeSubscriptionForClientUserIdEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL)
																				   .replace('[CLIENTUSERID]', TSNumber)
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																  				   .replace('[SERVICE_ID]', serviceId));
        	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
        }
        // Dummy Response for Test
        else{
        	response = new Dom.Document();
        	response.load('<CancelSubscriptionResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'
				  +'<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>'
				  +'<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
				  +'<DeferredRevenue xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">90.0</DeferredRevenue>'
				  +'<DeferredRevenueCurrency xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">9.99</DeferredRevenueCurrency>'
				  +'<ServiceGroupTag xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Digital Products</ServiceGroupTag>'
				  +'<ServiceGroupTitle xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Digital Products</ServiceGroupTitle>'
				  +'<ServiceId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">11206</ServiceId>'
				  +'<Status xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">Removed</Status>'
				  +'</CancelSubscriptionResult>');
        }	
																  
		CancelSubscriptionResult result = new CancelSubscriptionResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			
			if(node.getName() == 'ErrorMessage')
				errorMessage = node.getText();
				
			if(node.getName() == 'ErrorNumber')
				errorNumber = node.getText();
				
			if(node.getName() == 'DeferredRevenue')
				result.deferredRevenue = node.getText();
				
			if(node.getName() == 'DeferredRevenueCurrency')
				result.deferredRevenueCurrency = node.getText();
				
			if(node.getName() == 'ServiceGroupTag')
				result.serviceGroupTag = node.getText();
				
			if(node.getName() == 'ServiceGroupTitle')
				result.serviceGroupTitle = node.getText();
				
			if(node.getName() == 'ServiceId')
				result.serviceId = node.getText();
				
			if(node.getName() == 'Status')
				result.status = node.getText();
				
		}

		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
		}
		
		// Logging call
        //ID logId = TMGUtil.logWebServiceRequest('Outbound', removeSubscriptionEndpoint, 'RemoveSubscription', new Map<String,Object>{'GUID' => this.MPP_GUID});
		// Logging the Response
		//TMGUtil.logWebServiceResponse(logId, result);		
		return result;
				
	}
	
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Function - MPP Subscription renewal with option to log call
    #############Change Log#############
    Modified by     	Version     Change Date
    Pawel Chrzanowski	1.1			14/04/2016	//Modified to make call logging optional
    ****************************************************************************************/
	public AutoRenewResult AutoRenewSubscriber(String tsNumber, String serviceId, String autoRenew, Boolean isLogCall){
		String errorMessage, errorNumber;
		AutoRenewResult result = new AutoRenewResult();
		Dom.Document response;
		initialise(tsNumber);
		
		String endpoint = MPPInterfaceHTTP.autoRenewalEndpointRequest.replace('[BASE_URL]',this.BASE_MPP_URL)
														   .replace('[PASSWORD]', this.MPP_PASSWORD)
										  				   .replace('[SERVICE_ID]', serviceId)
										  				   .replace('[GUID]', this.MPP_GUID)
										  				   .replace('[AUTO_RENEW]', autoRenew);
		try {
			response = TMGAPIUtils.callOutGet(endpoint);
		}
    	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}
		
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage'){
				errorMessage = node.getText();
			}
			if(node.getName() == 'ErrorNumber'){
				errorNumber = node.getText();
			}
			if(node.getName() == 'AutoRenewEnabled'){
				result.autoRenewEnabled = Boolean.valueOf(node.getText());
			}
			if(node.getName() == 'ServiceId'){
				result.serviceId = node.getText();
			}
		}
		System.debug('### ERROR: ' + errorMessage + '  -  ' + errorNumber);
		
		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
		}
		
		if(isLogCall){
			// Logging call
	        ID logId = TMGUtil.logWebServiceRequest('Outbound', endpoint, 'AutoRenewSubscriber', new Map<String,Object>{'GUID' => this.MPP_GUID, 'SERVICE_ID' => serviceId, 'AUTO_RENEW' => autoRenew});
	        
			// Logging the Response
			TMGUtil.logWebServiceResponse(logId, result);
		}
															  				   
		return result;
	}

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 14/04/2016
    Function - MPP Subscription renewal with call logging
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public AutoRenewResult AutoRenewSubscriber(String tsNumber, String serviceId, String autoRenew){
		return AutoRenewSubscriber(tsNumber, serviceId, autoRenew, true);
	}
	
	//Callout to AddSubscription
	public static AddSubscriptionResult AddSubscription(String TSNumber, Integer serviceId, Integer servicePriceId) {
		//Get settings
		PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
		//Build parameter map
		Map<String, String> parameters = new Map<String,String>();
		parameters.put('affiliateid', customSetting.login__c);
		parameters.put('password', customSetting.password__c);
		parameters.put('clientUserId', TSNumber);
		parameters.put('ServiceId', String.valueOf(serviceId));
		parameters.put('servicePriceId', String.valueOf(servicePriceId));
		parameters.put('multipleserviceid', 'true');
		parameters.put('use3dSecure', 'false');
		//Base endpoint
		String url = customSetting.baseURL__c + addSubscriptionEndpoint;
		AddSubscriptionResult result = new AddSubscriptionResult();
		Boolean continueProcess = true;
		Dom.Document response = new Dom.Document();
		
		//Do callout
		try { 
			response = TMGAPIUtils.callOutGet(url, parameters);
		}
		catch (TMGAPIUtils.UnsuccessfullResponseException URex) {
			result.ErrorNumber = URex.getErrorCode();
			result.ErrorMessage = URex.getErrorMessage();
			continueProcess = false;
		}
		catch (Exception ex) {
			result.ErrorNumber = ex.getMessage();
			result.ErrorMessage = ex.getMessage();
			continueProcess = false;
		}
		
		//Parse response
		if (continueProcess) {
			for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
				if(node.getName() == 'ErrorMessage'){
					result.ErrorMessage = node.getText();
				}
				if(node.getName() == 'ErrorNumber'){
					result.ErrorNumber = node.getText();
				}
				if(node.getName() == 'ClientRoleTitle'){
					result.ClientRoleTitle = node.getText();
				}
				if(node.getName() == 'FixedEndDate'){
					result.FixedEndDate = DateTime.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(node.getText()));
				}
				if(node.getName() == 'RenewalDate'){
					result.RenewalDate = DateTime.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(node.getText()));
				}
				if(node.getName() == 'RoleId'){
					result.RoleId = node.getText();
				}
				if(node.getName() == 'RoleTitle'){
					result.RoleTitle = node.getText();
				}
				if(node.getName() == 'ServiceGroupTag'){
					result.ServiceGroupTag = node.getText();
				}
				if(node.getName() == 'ServiceGroupTitle'){
					result.ServiceGroupTitle = node.getText();
				}
				if(node.getName() == 'ServiceId'){
					result.ServiceId = node.getText();
				}
				if(node.getName() == 'SubscriptionStatus'){
					result.SubscriptionStatus = node.getText();
				}
				if(node.getName() == 'ThreeDSecureEnrolled'){
					result.ThreeDSecureEnrolled = node.getText();
				}
				if(node.getName() == 'ThreeDSecureHtml'){
					result.ThreeDSecureHtml = node.getText();
				}
				if(node.getName() == 'ThreeDSecureMD'){
					result.ThreeDSecureMD = node.getText();
				}
				if(node.getName() == 'ThreeDSecureStatus'){
					result.ThreeDSecureStatus = node.getText();
				}
				if(node.getName() == 'ThreeDSecureAcsUrl'){
					result.ThreeDSecureAcsUrl = node.getText();
				}
				if(node.getName() == 'ThreeDSecurePaReq'){
					result.ThreeDSecurePaReq = node.getText();
				}
			}			
		}
		
		//Handle errors
		if(result.ErrorMessage != null && result.ErrorMessage !=''){
			throw new MPPInterfaceHTTPException(result.ErrorNumber, result.ErrorMessage);
		}
		return result;
	}
	
	//Callout to ChangeSubscriptionWithoutCharge
	public static ChangeSubscriptionResult ChangeSubscriptionWithoutCharge(String TSNumber, Integer currentServicePriceId, Integer newServicePriceId) {
		//Get settings
		PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
		//Build parameter map
		Map<String, String> parameters = new Map<String,String>();
		parameters.put('affiliateid', customSetting.login__c);
		parameters.put('password', customSetting.password__c);
		parameters.put('clientUserId', TSNumber);
		parameters.put('currentServicePriceId', String.valueOf(currentServicePriceId));
		parameters.put('newServicePriceId', String.valueOf(newServicePriceId));
		//Base endpoint
		String url = customSetting.baseURL__c + changeSubscriptionWithoutChargeEndpoint;
		ChangeSubscriptionResult result = new ChangeSubscriptionResult();
		Boolean continueProcess = true;
		Dom.Document response = new Dom.Document();
		
		//Do callout
		try { 
			response = TMGAPIUtils.callOutGet(url, parameters);
		}
		catch (Exception ex) {
			result.ErrorNumber = ex.getMessage();
			result.ErrorMessage = ex.getStackTraceString();
			continueProcess = false;
		}
		
		//Parse response
		if (continueProcess) {
			for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
				if(node.getName() == 'ErrorMessage'){
					result.ErrorMessage = node.getText();
				}
				if(node.getName() == 'ErrorNumber'){
					result.ErrorNumber = node.getText();
				}
				if(node.getName() == 'ClientRoleTitle'){
					result.ClientRoleTitle = node.getText();
				}
				if(node.getName() == 'FixedEndDate'){
					result.FixedEndDate = DateTime.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(node.getText()));
				}
				if(node.getName() == 'RenewalDate'){
					result.RenewalDate = DateTime.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(node.getText()));
				}
				if(node.getName() == 'RoleId'){
					result.RoleId = node.getText();
				}
				if(node.getName() == 'RoleTitle'){
					result.RoleTitle = node.getText();
				}
				if(node.getName() == 'ServiceGroupTag'){
					result.ServiceGroupTag = node.getText();
				}
				if(node.getName() == 'ServiceGroupTitle'){
					result.ServiceGroupTitle = node.getText();
				}
				if(node.getName() == 'ServiceId'){
					result.ServiceId = node.getText();
				}
				if(node.getName() == 'SubscriptionStatus'){
					result.SubscriptionStatus = node.getText();
				}
			}			
		}
		
		//Handle errors
		if(result.ErrorMessage != null && result.ErrorMessage !=''){
			throw new MPPInterfaceHTTPException(result.ErrorNumber, result.ErrorMessage);
		}
		return result;
	}
	
	//Callout to ChangeSubscriptionWithCharge
	public static ChangeSubscriptionResult ChangeSubscriptionWithCharge(String TSNumber, Integer currentServiceId, Integer newServiceId) {
		//Get settings
		PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
		//Build parameter map
		Map<String, String> parameters = new Map<String,String>();
		parameters.put('clientId', customSetting.login__c);
		parameters.put('apiPassword', customSetting.password__c);
		parameters.put('clientUserId', TSNumber);
		parameters.put('currentServiceId', String.valueOf(currentServiceId));
		parameters.put('newServiceId', String.valueOf(newServiceId));
		//Base endpoint
		String url = customSetting.baseURL__c + changeSubscriptionWithChargeEndpoint;
		ChangeSubscriptionResult result = new ChangeSubscriptionResult();
		Boolean continueProcess = true;
		Dom.Document response = new Dom.Document();
		
		//Do callout
		try { 
			response = TMGAPIUtils.callOutGet(url, parameters);
		}catch (Exception ex) {
			result.ErrorNumber = ex.getMessage();
			result.ErrorMessage = ex.getStackTraceString();
			continueProcess = false;
		}
		
		//Parse response
		if (continueProcess) {
			for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
				if(node.getName() == 'ErrorMessage'){
					result.ErrorMessage = node.getText();
				}
				if(node.getName() == 'ErrorNumber'){
					result.ErrorNumber = node.getText();
				}
				if(node.getName() == 'ClientRoleTitle'){
					result.ClientRoleTitle = node.getText();
				}
				if(node.getName() == 'FixedEndDateUTC'){
					result.FixedEndDate = DateTime.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(node.getText()));
				}
				if(node.getName() == 'RenewalDateUTC'){
					result.RenewalDate = DateTime.valueOf(MPPInterfaceHTTPHelper.getDateTimeString(node.getText()));
				}
				if(node.getName() == 'RoleId'){
					result.RoleId = node.getText();
				}
				if(node.getName() == 'RoleTitle'){
					result.RoleTitle = node.getText();
				}
				if(node.getName() == 'ServiceGroupTag'){
					result.ServiceGroupTag = node.getText();
				}
				if(node.getName() == 'ServiceGroupTitle'){
					result.ServiceGroupTitle = node.getText();
				}
				if(node.getName() == 'ServiceId'){
					result.ServiceId = node.getText();
				}
				if(node.getName() == 'SubscriptionStatus'){
					result.SubscriptionStatus = node.getText();
				}
			}			
		}
		
		//Handle errors
		if(result.ErrorMessage != null && result.ErrorMessage !=''){
			throw new MPPInterfaceHTTPException(result.ErrorNumber, result.ErrorMessage);
		}
		return result;
	}
	
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Function - MPP refund with option to log call and create Transaction History record
    #############Change Log#############
    Modified by     	Version     Change Date
    Pawel Chrzanowski	1.1 		29/03/2016	//modified to use lookup to ZProduct on subscriber
    Pawel Chrzanowski	1.2			14/04/2016	//Modified to make call logging and creating Transaction History record optional
    Mantas Grigaliunas	1.3			11/11/2016	//added SubscriptionId variable declaration
    Mantas Grigaliunas	1.4			25/22/2016	//added paymentType variable declaration
    Mantas Grigaliunas	1.5			01/12/2016	//refactored and moved code to add web service log only on failure
    Mantas Grigaliunas	1.6			30/01/2017	//bulkified and renamed RefundOrder to processRefundOrder
    ****************************************************************************************/
	public List<RefundOrderResult> processRefundOrder(String tsNumber, String subscriptionId, List<RefundOrder> refundOrders, 
													  Boolean isTransactionHistory, Boolean isLogCall){
		
		initialise(tsNumber);

		List<RefundOrderResult> refundResults = new List<RefundOrderResult>();
		Map<String, RefundOrder> refundOrderMap = new Map<String, RefundOrder>();

		for(RefundOrder refund : refundOrders){
		
	        Dom.Document response;
	       	RefundOrderResult result = new RefundOrderResult();

	        if (!Test.isRunningTest()){
	        	try {
					response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.refundOrderEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL)
																					   .replace('[PASSWORD]', this.MPP_PASSWORD)
																	  				   .replace('[ORDER_ID]', refund.saleOrderId)
																	  				   .replace('[REFUND_AMOUNT]', string.valueOf(refund.refundAmount)));
	        	}
	        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
	        		result.errorNumber = ex.getErrorCode();
	        		result.errorMessage = ex.getErrorMessage();
	        	}
			}
	        // Dummy Response for Test
	        else{
	        	response = new Dom.Document();
	        	response.load('<CancelSubscriptionResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'
					  +'<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>'
					  +'<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
					  +'<RefundAmount xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+refund.refundAmount+'</RefundAmount>'
					  +'<RefundOrderId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">' + String.valueOf(Crypto.getRandomInteger()) + '</RefundOrderId>' + 
					  +'</CancelSubscriptionResult>');
	        }

	        if(response != null){

		        for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
				
					if(node.getName() == 'RefundAmount')
						result.refundAmount = node.getText();
						
					if(node.getName() == 'RefundOrderId'){
						result.refundOrderId = node.getText();
						refundOrderMap.put(result.refundOrderId, refund);
					}

					if(node.getName() == 'ErrorMessage')
						result.errorMessage = node.getText();
			
					if(node.getName() == 'ErrorNumber')
						result.errorNumber = node.getText();
				}
			}
														  
			refundResults.add(result);
		}

		List<WebService_Log__c> errorLogs = new List<WebService_Log__c>();
		List<MPP_Transaction_History__c> successfulTransactions = new List<MPP_Transaction_History__c>();

		for(RefundOrderResult result : refundResults){
			if(result.errorMessage != null && result.errorMessage !='' && isLogCall){
				//logging call on failure
                errorLogs.add(TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, 
                	refundOrderEndpoint, 'RefundOrder', result, tsNumber, subscriptionId, null));
			} else {
				//create Transaction History record
				if(isTransactionHistory && TMGUtil.isDataValid(result.refundOrderId) && TMGUtil.isDataValid(result.refundAmount) && Decimal.valueOf(result.refundAmount) > 0.0){
					Account subscriber = SubscriptionsWebservicesHandlers.getAccountByTSNumber(tsNumber);
					
					if(TMGUTil.isDataValid(subscriber)){
						successfulTransactions.add(createRefundTransactionHistory(subscriber, subscriptionId, 
							result.refundOrderId, refundOrderMap.get(result.refundOrderId)));
					}
				}
			}
		}

		//insert log records
		if(errorLogs.size() > 0) 
			insert errorLogs;
		if(successfulTransactions.size() > 0) 
			insert successfulTransactions;

		return refundResults;
	}

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 14/04/2016
    Function - MPP refund with Transaction History creation without call logging
    #############Change Log#############
    Modified by     	Version     Change Date
    Mantas Grigaliunas	1.1			30/01/2017	//changed to comply with changes in main method
    ****************************************************************************************/
	public RefundOrderResult processRefundOrder(String tsNumber, String orderId, Decimal refundAmount){
		return processRefundOrder(tsNumber, orderId, refundAmount, true, false);
	}

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 15/11/2016
    Function - MPP refund with Transaction History creation without subscription
    #############Change Log#############
    Modified by     	Version     Change Date
    Mantas Grigaliunas	1.1			30/01/2017	//changed to comply with changes in main method
    ****************************************************************************************/
	public RefundOrderResult processRefundOrder(String tsNumber, String orderId, Decimal refundAmount, Boolean isTransactionHistory, Boolean isLogCall){

		List<RefundOrderResult> results = 
			processRefundOrder(tsNumber, null, new List<RefundOrder>{new RefundOrder(orderId, refundAmount, null)}, isTransactionHistory, isLogCall);
		RefundOrderResult result = results[0];

		if(!String.isEmpty(result.errorNumber) && !String.isEmpty(result.errorMessage)){
			throw new MPPInterfaceHTTPException(result.errorNumber, result.errorMessage);
		}
		return result;
	}
	
    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 15/04/2016
    Function - create MPP Refund Transaction History record for Print Subscription payments
    #############Change Log#############
    Modified by     	Version     Change Date
    Mantas Grigaliunas	1.0			11/11/2016	Added subscription assignmnet, removed productName as not used, similar logic is in workflow,
    											Replaced string with constants
    Mantas Grigaliunas 	1.1			25/11/2016	Added paymentType and modified payment status to be 'Refund' instead of 'success'
    Mantas Grigaliunas	1.2			30/01/2017	Added Sale Order Id field and changed to use wrapper
    ****************************************************************************************/
	public static MPP_Transaction_History__c createRefundTransactionHistory(Account subscriber, String subscriptionId, 
																			String refundOrderId, RefundOrder refund){
		return new MPP_Transaction_History__c(
			Subscriber__c = subscriber.Id,
			Subscription__c = subscriptionId,
			Sale_Type__c = Constants.MPPTRANSACTION_PAYMENT_TYPE_REFUND,
			Payment_status__c = Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND,
			Payment_Type__c = refund.paymentType,
			Total_Price__c = refund.refundAmount,
			Expected_Amount__c = refund.refundAmount,
			Payment_Date__c = DateTime.now(),
			Order_id__c = refundOrderId,
			Sale_Order_ID__c = refund.saleOrderId
		);
	}

	/*************************************************************************************** 
    Developer - Mantas Grigaliunas	
    Date - 11/11/2016
    Function - create MPP Refund Transaction History record for Zuora payments
    #############Change Log#############
    Modified by    		Version     Change Date
    Mantas Grigaliunas	1.1			30/01/2017	//changed to comply with changes in main method
    ****************************************************************************************/
	public static void createRefundTransactionHistory(Account subscriber, String refundAmount, String refundOrderId){
		createRefundTransactionHistory(subscriber, null, refundOrderId, 
										new RefundOrder(null, Decimal.valueOf(refundAmount), null));
	}

	public UserManageResult UserManage(string TSNumber, string emailAddress, string salutation, string firstName, string surname, string houseName, string houseNumber, string street, string district, string city, string county, string postCode, string country, string guid){
		
		String errorMessage, errorNumber;

		initialise(TSNumber);
		
		Dom.Document response;
        if (!Test.isRunningTest()){
        	try {
        		String userManageCompleteEndpoint = MPPInterfaceHTTP.userManageEndpointRequest.replace('[BASE_URL]',this.BASE_MPP_URL)
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																				   .replace('[EMAIL]', (emailAddress==null ? '' : emailAddress))
																				   .replace('[TITLE]', (salutation==null ? '' : salutation))
																				   .replace('[FIRST_NAME]', (firstName==null ? '' : firstName))
																				   .replace('[SURNAME]', (surname==null ? '' : surname))
																				   .replace('[HOUSE_NAME]', (houseName==null ? '' : houseName))
																				   .replace('[HOUSE_NUMBER]', (houseNumber==null ? '' : houseNumber))
																				   .replace('[STREET]', (street==null ? '' : street))
																				   .replace('[DISTRICT]', (district==null ? '' : district))
																				   .replace('[CITY]', (city==null ? '' : city))
																				   .replace('[COUNTY]', (county==null ? '' : county))
																				   .replace('[POSTCODE]', (postCode==null ? '' : postCode))
																				   .replace('[COUNTRY]', (country==null ? '' : country))
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																  				   .replace('[SAM_GUID]', (guid==null ? '' : guid))
																				   .replace('[TS_NUMBER]', TSNumber);
				
				if(!String.isEmpty(guid)) {
		          userManageCompleteEndpoint += '&AccountDetailsParamName2=SAM_GUID&AccountDetailsParamValue2=' + guid;
		        }
		        response = TMGAPIUtils.callOutGet(userManageCompleteEndpoint);
			}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
		} else { // Dummy Response for Test
        	response = new Dom.Document();
        	response.load('<CancelSubscriptionResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'
				  +'<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>'
				  +'<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
				  +'<Guid xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">'+guid+'</Guid>'+'</CancelSubscriptionResult>');
        }
        														  
		UserManageResult result = new UserManageResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			
			if(node.getName() == 'ErrorMessage')
				errorMessage = node.getText();
				
			if(node.getName() == 'ErrorNumber')
				errorNumber = node.getText();

			if(node.getName() == 'Guid')
				result.guid = node.getText();
		}
		
		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
		// Logging call
        ID logId = TMGUtil.logWebServiceRequest('Outbound', userManageEndpointRequest, 'UserManage', new Map<String,Object>{'PASSWORD' => this.MPP_PASSWORD,'EMAIL' => (emailAddress==null ? '' : emailAddress),'TITLE' => (salutation==null ? '' : salutation),'FIRST_NAME' => (firstName==null ? '' : firstName),'SURNAME' => (surname==null ? '' : surname),'HOUSE_NAME' => (houseName==null ? '' : houseName),'HOUSE_NUMBER' => (houseNumber==null ? '' : houseNumber),'STREET' => (street==null ? '' : street),'DISTRICT' => (district==null ? '' : district),'CITY' => (city==null ? '' : city),'COUNTY' => (county==null ? '' : county),'POSTCODE' => (postCode==null ? '' : postCode),'COUNTRY' => (country==null ? '' : country),'PASSWORD' => this.MPP_PASSWORD, 'GUID' => (guid==null ? '' : guid),'TS_NUMBER' => TSNumber});
        
        // Logging the Response
		TMGUtil.logWebServiceResponse(logId, result);	
        return result;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 07/08/2015
    Version - 1.3
    Function -  MPP Webservice call to update salutation, firstName and lastName on MPP 
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			12/10/2015	//add guid parameter to method
    Cristina Anghenie	1.2			11/12/2015	//encode newEmail, oldEmail, first and last name before calling MPP
    Wiktor Czykin		1.3			17/12/2015	//modified error logging
    ****************************************************************************************/
    public UserManageResult UserManageSingleUpdate(String TSNumber, String emailAddress, String oldEmailAddress, String salutation, string firstName, String surname, String guid){
		String errorMessage, errorNumber;
		String userManageCompleteEndpoint;
		initialise(TSNumber);
		Dom.Document response;
        if (!Test.isRunningTest()){
        	try {
        		//default new email address to noemail+TSNUMBER@telegraph.co.uk if new email is null
        		if(String.isBlank(emailAddress)){
	    			emailAddress = Constants.DEFAULT_EMAIL_ADDRESS.substringBefore('@') + '+' + TSNumber +'@'+ Constants.DEFAULT_EMAIL_ADDRESS.substringAfter('@');
        		}
        		//default old email address to noemail+TSNUMBER@telegraph.co.uk if old email is null
	    		if(String.isBlank(oldEmailAddress)){
		    		oldEmailAddress = Constants.DEFAULT_EMAIL_ADDRESS.substringBefore('@') + '+' + TSNumber +'@'+ Constants.DEFAULT_EMAIL_ADDRESS.substringAfter('@');
        		}
        		
        		if (emailAddress != oldEmailAddress){
    				userManageCompleteEndpoint = MPPInterfaceHTTP.userManageSingleEmailUpdateEndpointRequest.replace('[BASE_URL]',this.BASE_MPP_URL)
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																				   .replace('[EMAIL]', (emailAddress==null ? '' : EncodingUtil.urlEncode(emailAddress, 'UTF-8')))
																				   .replace('[OLDEMAIL]', (oldEmailAddress==null ? '' : EncodingUtil.urlEncode(oldEmailAddress, 'UTF-8')))
																				   .replace('[TITLE]', (salutation==null ? '' : salutation))
																				   .replace('[FIRST_NAME]', (firstName==null ? '' : EncodingUtil.urlEncode(firstName, 'UTF-8')))
																				   .replace('[SURNAME]', (surname==null ? '' : EncodingUtil.urlEncode(surname, 'UTF-8')))
																				   .replace('[TS_NUMBER]', TSNumber);
    			} else userManageCompleteEndpoint = MPPInterfaceHTTP.userManageSingleUpdateEndpointRequest.replace('[BASE_URL]',this.BASE_MPP_URL)
																				   .replace('[PASSWORD]', this.MPP_PASSWORD)
																				   .replace('[EMAIL]', (emailAddress==null ? '' : EncodingUtil.urlEncode(emailAddress, 'UTF-8')))
																				   .replace('[TITLE]', (salutation==null ? '' : salutation))
																				   .replace('[FIRST_NAME]', (firstName==null ? '' : EncodingUtil.urlEncode(firstName, 'UTF-8')))
																				   .replace('[SURNAME]', (surname==null ? '' : EncodingUtil.urlEncode(surname, 'UTF-8')))
																				   .replace('[TS_NUMBER]', TSNumber);
        		
 				if(!String.isEmpty(guid)) {
		          userManageCompleteEndpoint += '&AccountDetailsParamName2=SAM_GUID&AccountDetailsParamValue2=' + guid;
		        }
		        System.debug('### MPPInterfaceHTTP.UserManageSingleUpdate -> userManageCompleteEndpoint: ' + userManageCompleteEndpoint);
		        response = TMGAPIUtils.callOutGet(userManageCompleteEndpoint);
			}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
		} else { // Dummy Response for Test
        	response = new Dom.Document();
        	String sResponse = '<CancelSubscriptionResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
        	if(bRunTest){
	        	sResponse += '<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">error reported</ErrorMessage>';
        	}else{
	        	sResponse += '<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
        	}
        	sResponse += '<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
				  		+'<Guid xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">9eb5f34a6d774e0bac843cffa1d6d17a</Guid>'+'</CancelSubscriptionResult>';
        	response.load(sResponse);
        }
        														  
		UserManageResult result = new UserManageResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage')
				errorMessage = node.getText();
				
			if(node.getName() == 'ErrorNumber')
				errorNumber = node.getText();

			if(node.getName() == 'Guid')
				result.guid = node.getText();
		}
		
		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        Map<String,Object> mapToLog = new Map<String,Object>{	'PASSWORD' => this.MPP_PASSWORD,
																'EMAIL' => emailAddress,
																'OLDEMAIL' => oldEmailAddress,
																'TITLE' => salutation,
																'FIRST_NAME' => firstName,
																'SURNAME' => surname,
																'TS_NUMBER' => TSNumber};
		
		// Logging call
		WebService_Log__c wl = TMGUtil.newLogWebServiceRequestSerialized(	Constants.DIRECTION_OUTBOUND, 
																			(emailAddress != oldEmailAddress ? userManageSingleEmailUpdateEndpointRequest : userManageSingleUpdateEndpointRequest), 
																			Constants.LOG_USERMANAGE,
																			mapToLog,
																			null,
																			null,
																			null); 
		TMGUtil.populateResponseOnWebServiceRequestSerialized(wl, result);										
		if(this.bUseBulkLogging){
			this.addLogToBuffer(wl);
		}else{
			TMGUtil.logWebServiceRequestSerialized(wl);
		}
        return result;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 31/07/2015
    Version - 1.0
    Function -  Call the MPP Webservice to update salutation, firstName and lastName on MPP 
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			12/10/2015	//update UserManageSingleUpdate method 
    Cristina Anghenie	1.2			11/12/2015	//remove encoding for email, first name and last name because was moved to the UserManageSingleUpdate method
    Pawel Chrzanowski	1.3			07/03/2016	//fix no-email-update error in MPP after email change
    ****************************************************************************************/
    @future(callout=true) 
    public static void invokeSingleFutureUserManageRequest(Map<Id, String> accMap){
    	try{
    		Account acc = [SELECT Id, FirstName, LastName, Salutation, Subscriber_Number__c, PersonEmail, PersonTitle, LastModifiedById, Subscriber_Number_static__c, Guid__c 
						   FROM Account 
						   WHERE Id IN :accMap.keySet()];
    		MPPInterfaceHTTP request = new MPPInterfaceHTTP();

    		//supply both emails for MPP
    		request.UserManageSingleUpdate(acc.Subscriber_Number_static__c, acc.PersonEmail, accMap.values()[0], acc.Salutation, acc.FirstName, acc.LastName, acc.Guid__c);
    	}
    	catch(Exception e){
    		system.debug('=====invokeFutureUserManageRequest===== Exception '+e.getStackTraceString());
    	}
    }		

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 13/05/2015
    Version - 1.1
    Function -  Call the MPP Webservice to update subscriber 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public UserManageResult userManagePartialAccountBased(Account acc, Set<String> setFieldsToPush){
		this.initialiseIgnoreGuid(); 
		String sErrorMessage;
		String sErrorNumber;
		Dom.Document response;
		if(acc == null || setFieldsToPush == null || setFieldsToPush.isEmpty() || (acc.get('Subscriber_Number_static__c') == null && acc.get('PersonEmail') == null)) throw new MPPInterfaceHTTPException('Parameters required to process the request are missing.');

		Map<String, String> mapParameters = new Map<String, String>();
		try{
			String sUserManageEndpoint = MPPInterfaceHTTP.userManageEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL);
			mapParameters.put('affiliateid', this.MPP_AFFILIATEID);
			mapParameters.put('password', this.MPP_PASSWORD);
			mapParameters.put('AccountTypeId', '0');
			mapParameters.put('gender', 'NotKnown');
			mapParameters.put('creditCardType', 'Undefined');
			Integer iExtraParamsCount = 1;
			for(String sField : setFieldsToPush){
				if(MAP_ACCOUNT_FIELDS_TO_MPP_FIELDS.containsKey(sField)){
					mapParameters.put(MAP_ACCOUNT_FIELDS_TO_MPP_FIELDS.get(sField), (String)acc.get(sField));
				}else if(MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS.containsKey(sField)){
					mapParameters.put(MPP_CUSTOMPARAM_NAME+iExtraParamsCount, MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS.get(sField));
					mapParameters.put(MPP_CUSTOMPARAM_VALUE+iExtraParamsCount, (String)acc.get(sField));
					iExtraParamsCount++;
				}
			}
			response = TMGAPIUtils.callOutGet(sUserManageEndpoint, mapParameters);
		}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}

    	UserManageResult result = new UserManageResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage') sErrorMessage = node.getText();
			else if(node.getName() == 'ErrorNumber') sErrorNumber = node.getText();
			else if(node.getName() == 'Guid') result.guid = node.getText();
		}

		if(String.isNotBlank(sErrorMessage)){
			throw new MPPInterfaceHTTPException(sErrorNumber, sErrorMessage);
        }
        
        ID logId = TMGUtil.logWebServiceRequest('Outbound', MPPInterfaceHTTP.userManageEndpoint, 'UserManage', mapParameters);
		TMGUtil.logWebServiceResponse(logId, result);	
        return result;
	}
    
	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 21/05/2015
    Version - 1.1
    Function - builds request parameters based on set of tsnumbers passed id
    #############Change Log#############
    Modified by     Version     Change Date
    Lynette Lim     1.2         30/10/2015	//update the construction of sUrlParams to include '&' after every set of TSNumber
    ****************************************************************************************/
	public List<MPPInterfaceHTTP.PaymentDetailResult> getBulkPaymentDetailResultBasedOnTSNumbers(Set<String> setTSNumbers){
      	if(setTSNumbers == null || setTSNumbers.isEmpty() ||!MPPInterfaceHTTP.MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS.containsKey('Subscriber_Number_static__c')){
  			throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(Label.MPP_Communication_Missing_parameters_for_payment_details_callout);
  		}
  		String sUrlParams = '';
  		Integer i = 1;
  		for(String sTSNumber : setTSNumbers){
  			if(String.isBlank(sTSNumber)) continue;

  			if(i > 1) { sUrlParams+='&'; }

  			String sNumber = (i+'').length()==1?'0'+i:i+'';
  			sUrlParams += 	MPPInterfaceHTTP.MPP_CUSTOMPARAM_NAME+sNumber+'='+
  							MPPInterfaceHTTP.MAP_ACCOUNT_FIELDS_TO_MPP_PARAMS.get('Subscriber_Number_static__c')+'&'+
  							MPPInterfaceHTTP.MPP_CUSTOMPARAM_VALUE+sNumber+'='+sTSNumber;
  			i++;
  		}
  		if(String.isBlank(sUrlParams)) throw new MPPInterfaceHTTP.MPPInterfaceHTTPException(Label.MPP_Communication_Missing_parameters_for_payment_details_callout);
  		List<MPPInterfaceHTTP.PaymentDetailResult> lstPaymentDetails = this.getBulkPaymentDetailResult(sUrlParams);
  		if(lstPaymentDetails == null || lstPaymentDetails.isEmpty()){
      		throw new TelegraphApplicationException(Label.MPP_Communication_Unable_to_retrieve_payment_details);
  		}
  		return lstPaymentDetails;
  	}


    public List<PaymentDetailResult> getBulkPaymentDetailResult(String paramMap){
    	List<PaymentDetailResult> paymentResults = new List<PaymentDetailResult>();
    	String errorMessage, errorNumber;
    	
    	this.initialiseIgnoreGuid();
    	Dom.Document response;
    	
		try {
			response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.bulkPaymentDetailsEndpointRequest
				.replace('[BASE_URL]', this.BASE_MPP_URL)
				.replace('[PASSWORD]', this.MPP_PASSWORD) + paramMap);
		}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}		
		
        List<Dom.XmlNode> paymentNodes;
        for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage'){
				errorMessage = node.getText();
			}
			if(node.getName() == 'ErrorNumber'){
				errorNumber = node.getText();
			}
			if(node.getName() == 'PaymentDetails'){
				paymentNodes = node.getChildElements();
			}
		}
		
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        for(DOM.XmlNode a :paymentNodes){
        	PaymentDetailResult pDetail = new PaymentDetailResult();
        	for(DOM.XmlNode b :a.getChildren()){
        		if(b.getName() == 'TSNumber'){
        			pDetail.tsNumber = b.getText();
        		}
        		if(b.getName() == 'AccountNumber'){
        			pDetail.accNumber = b.getText();
        		}
        		if(b.getName() == 'SortCode'){
        			pDetail.sortCode = b.getText();
        		}
        		if(b.getName() == 'PayerReference'){
        			pDetail.payerRef = b.getText();
        		}
        		if(b.getName() == 'DigitalSubscriptionId'){
        			pDetail.digiSubId = b.getText();
        		}
        		if(b.getName() == 'PremiumSubscriptionId'){
        			pDetail.premSubId = b.getText();
        		}
        		if(b.getName() == 'FirstCollectionDate'){
        			pDetail.firstCollectionDate = b.getText();
        		}
        		if(b.getName() == 'CollectionFreqency'){
        			pDetail.collectionFreq = b.getText();
        		}
        		if(b.getName() == 'CollectionDate'){
        			pDetail.collectionDate = b.getText();
        		}
        		if(b.getName() == 'FirstCollectionAmount'){
        			pDetail.firstCollectionAmount = b.getText();
        		}
        		if(b.getName() == 'OnGoingCollectionAmount'){
        			pDetail.ongoingCollectionAmount = b.getText();
        		}
        		if(b.getName() == 'CreditCardNumberLast4Digits'){
        			pDetail.creditCardNumber = b.getText();
        		}
        		if(b.getName() == 'CreditCardExpiryDate'){
        			pDetail.creditCardExpiryDate = b.getText();
        		}
        		if(b.getName() == 'CreditCardAuthCode'){
        			pDetail.creditCardAuthCode = b.getText();
        		}
        	}
        	paymentResults.add(pDetail);
        }
        
    	return paymentResults;
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 16/09/2015
    Version - 1.0
    Function -  Call the MPP Webservice to cancel all payment schedules when subs are cancelled
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @future(callout=true) 
    public static void invokeSinglePaymentScheduleCancellation(String mppSubsIds){
    	MPPInterfaceHTTP request = new MPPInterfaceHTTP();
    	try{
    		request.cancelPaymentSchedule(mppSubsIds);
    	}catch(Exception e){
    		system.debug('=====invokeSinglePaymentScheduleCancellation===== Exception '+e.getStackTraceString());
    	}
    }	
    
    public static String getValidTestReactivatePaymentXML()
    {
    	String xml = '<ReactivatePaymentScheduleResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
 		xml += '		 <ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
	    xml += '	     <ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
	    xml += '		 <ClientReference xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>';
	    xml += '	     <CurrencyOfMissedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">ZZZ</CurrencyOfMissedPayments>';
	    xml += '		 <CurrencyOfReactivatedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">GBP</CurrencyOfReactivatedPayments>';
	    xml += '		 <GrossAmountOfMissedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</GrossAmountOfMissedPayments>';
	    xml += '		 <GrossAmountOfReactivatedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">362.9300</GrossAmountOfReactivatedPayments>';
	    xml += '		 <NumberOfMissedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</NumberOfMissedPayments>';
	    xml += '	     <NumberOfReactivatedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">12</NumberOfReactivatedPayments>';
	    xml += '		 <OrderId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</OrderId>';
	    xml += '		 <PaymentScheduleId xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">1047</PaymentScheduleId>';
	    xml += '		 <SuccessfullyChargedForMissedPayments xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">false</SuccessfullyChargedForMissedPayments>';
		xml +=       '</ReactivatePaymentScheduleResult>';
		return xml;
    }
    
    public static String getInvalidTestReactivatePaymentXML()
    {
    	String xml = '<ReactivatePaymentScheduleResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
 		xml += '		 <ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">MPP ERROR</ErrorMessage>';
	    xml += '	     <ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>';
		xml += '      </ReactivatePaymentScheduleResult>';
		return xml;
    }
    
    public ReactivatePaymentScheduleResult reactivatePaymentSchedule(String premSubId)
    {
    	ReactivatePaymentScheduleResult result = new ReactivatePaymentScheduleResult();
    	String errorMessage, errorNumber;
    	
    	initialiseIgnoreGuid();
    	Dom.Document response;
    	
    	if (!Test.isRunningTest()){
    		try {
	    		response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.reactivatePaymentScheduleEndpoint
	    			.replace('[BASE_URL]', this.BASE_MPP_URL)
	    			.replace('[PASSWORD]', this.MPP_PASSWORD)
	    			.replace('[PAYMENT_SCHEDULE_ID]', premSubId));	
	    	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}	
    	}else{
    		//Dummy Response for test.
    		response = new Dom.Document();
    		response.load((this.testXML == null ? MPPInterfaceHTTP.getValidTestReactivatePaymentXML() : this.testXML));
    	}
    	
    	for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage'){
				errorMessage = node.getText();
			}	
			if(node.getName() == 'ErrorNumber'){
				errorNumber = node.getText();
			}
			if(node.getName() == 'ClientReference'){
				result.clientRef = node.getText();
			}
			if(node.getName() == 'CurrencyOfMissedPayments'){
				result.currencyMissedPayments = node.getText();
			}
			if(node.getName() == 'CurrencyOfReactivatedPayments'){
				result.currencyReactivatedPayments = node.getText();
			}
			if(node.getName() == 'GrossAmountOfMissedPayments'){
				result.grossAmountMissedPayments = node.getText();
			}
			if(node.getName() == 'GrossAmountOfReactivatedPayments'){
				result.grossAmountReactivatedPayments = node.getText();
			}
			if(node.getName() == 'NumberOfMissedPayments'){
				result.noOfMissedPayments = node.getText();
			}
			if(node.getName() == 'NumberOfReactivatedPayments'){
				result.noOfReactivatedPayments = node.getText();
			}
			if(node.getName() == 'OrderId'){
				result.orderId = node.getText();
			}
			if(node.getName() == 'PaymentScheduleId'){
				result.paymentScheduleId = node.getText();
			}
			if(node.getName() == 'SuccessfullyChargedForMissedPayments'){
				result.chargedStatusMissedPayments = node.getText();
			}
		}
		
		System.debug('### REACTIVATE PAYMENT RESULT: ' + result);
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        // Logging call
        ID logId = TMGUtil.logWebServiceRequest('Outbound', MPPInterfaceHTTP.reactivatePaymentScheduleEndpoint, 'reactivatePaymentSchedule', new Map<String, Object>{'PAYMENT_SCHEDULE_ID' => premSubId});
        // Logging the Response
		TMGUtil.logWebServiceResponse(logId, result);	
    	return result;
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			11/09/2015	//clean up the method and move test result into MPPWebserviceMock class
    ****************************************************************************************/
    public CancelPaymentScheduleResult cancelPaymentSchedule(String premSubId){
    	CancelPaymentScheduleResult result = new CancelPaymentScheduleResult();
    	String errorMessage, errorNumber;
    	
    	initialiseIgnoreGuid();
    	Dom.Document response;
    	
		try {
    		response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.cancelPaymentScheduleEndpoint
    			.replace('[BASE_URL]', this.BASE_MPP_URL)
    			.replace('[PASSWORD]', this.MPP_PASSWORD)
    			.replace('[PAYMENT_SCHEDULE_ID]', premSubId));		
    	}
    	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}
    	
    	for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage'){
				errorMessage = node.getText();
			}	
			if(node.getName() == 'ErrorNumber'){
				errorNumber = node.getText();
			}
			if(node.getName() == 'ClientReference'){
				result.clientRef = node.getText();
			}
			if(node.getName() == 'CurrencyOfCancelledPayments'){
				result.currencyCancelledPayments = node.getText();
			}
			if(node.getName() == 'GrossAmountOfCancelledPayments'){
				result.grossAmountCancelledPayments = node.getText();
			}
			if(node.getName() == 'NumberOfCancelledPayments'){
				result.noCancelledPayments = node.getText();
			}
			if(node.getName() == 'PaymentScheduleId'){
				result.paymentScheduleId = node.getText();
			}
		}
		
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        // Logging call
        ID logId = TMGUtil.logWebServiceRequest('Outbound', MPPInterfaceHTTP.cancelPaymentScheduleEndpoint, 'cancelPaymentSchedule', new Map<String, Object>{'PAYMENT_SCHEDULE_ID' => premSubId});
        // Logging the Response
		TMGUtil.logWebServiceResponse(logId, result);	
    	return result;
    }
      
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - currently only called from MPPRestAJAXService ...
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public ChangePaymentScheduleDateResult	changePaymentScheduleDate(String premSubId, String startDate, String dateOfMonth, String dateOffset){
    	ChangePaymentScheduleDateResult result = new ChangePaymentScheduleDateResult();
    	String errorMessage, errorNumber;
    	
    	this.initialiseIgnoreGuid();
    	Dom.Document response;
    	System.debug('###: DATE_OFFSET: ' + dateOffset);
    	
    	if (!Test.isRunningTest()){
    		try {
	    		response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.changePaymentScheduleDateEndpoint
	    			.replace('[BASE_URL]', this.BASE_MPP_URL)
	    			.replace('[PASSWORD]', this.MPP_PASSWORD)
	    			.replace('[PAYMENT_SCHEDULE_ID]', premSubId)
	    			.replace('[DATE_OF_MONTH]', dateOfMonth)
	    			.replace('[DATE_OFFSET]', dateOffset)
	    			.replace('[START_DATE]', startDate));
    		}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}		
    	}else{
    		//Dummy Response for test.
    		response = new Dom.Document();
    		response.load(MPPWebserviceMocks.getTestPaymentScheduleDateChangeXML(new Map<String, String>()));
    	}
    	
    	for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			if(node.getName() == 'ErrorMessage'){
				errorMessage = node.getText();
			}	
			if(node.getName() == 'ErrorNumber'){
				errorNumber = node.getText();
			}
			if(node.getName() == 'NextPaymentDate'){
				result.setSFDCNextPaymentDate(node.getText());
			}
		}
		
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        // Logging call
        //ID logId = TMGUtil.logWebServiceRequest('Outbound', MPPInterfaceHTTP.changePaymentScheduleDateEndpoint, 'changePaymentScheduleDate', new Map<String, Object>{'PAYMENT_SCHEDULE_ID' => premSubId, 'DATE_OF_MONTH' => dateOfMonth});
        // Logging the Response
		//TMGUtil.logWebServiceResponse(logId, result);	
    	return result;
    }
        
    public EditPaymentScheduleResult editPaymentSchedule(String premSubId, String totalAmount, String frequency){
    	EditPaymentScheduleResult result = new EditPaymentScheduleResult();
    	String errorMessage, errorNumber;
    	
    	this.initialiseIgnoreGuid();
    	Dom.Document response;
    	
    	String rsAmount = (TMGUtil.isDataValid(totalAmount) ? totalAmount : '0');
    	String rsFrequency = (TMGUtil.isDataValid(frequency) ? frequency : 'NotSet');
    	
    	System.debug('### TOTAL_AMOUNT: ' + rsAmount);
    	System.debug('### FREQUENCY: ' + rsFrequency);
    	
		try {
    		response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.editPaymentScheduleEnpointRequest
				    			.replace('[BASE_URL]', this.BASE_MPP_URL)
				    			.replace('[PASSWORD]', this.MPP_PASSWORD)
				    			.replace('[PAYMENT_SCHEDULE_ID]', premSubId)
				    			.replace('[TOTAL_PRICE]', rsAmount)
				    			.replace('[FREQUENCY]', rsFrequency));
		}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}
    	
    	List<Dom.XmlNode> paymentDateNodes = new List<Dom.XmlNode>();		
    	for(DOM.Xmlnode pNode : response.getRootElement().getChildElements()){
			if(pNode.getName() == 'ErrorMessage'){
				errorMessage = pNode.getText();
			}	
			if(pNode.getName() == 'ErrorNumber'){
				errorNumber = pNode.getText();
			}
			if(pNode.getName() == 'AmountOwedToCustomer'){
				result.amountOwedToCustomer = pNode.getText();
			}			
			if(pNode.getName() == 'Payments'){
				paymentDateNodes.addAll(pNode.getChildElements());
			}
		}

		for(DOM.Xmlnode pNode : paymentDateNodes){
			DatedPayment payment = new DatedPayment();
			for(DOM.XmlNode sNode :pNode.getChildren()){
				if(sNode.getName() == 'Amount'){
					payment.amount = sNode.getText();
				}	
				if(sNode.getName() == 'Currency'){
					payment.pCurrency = sNode.getText();
				}
				if(sNode.getName() == 'OrderDate'){
					payment.orderDate = sNode.getText();
				}
			}
			result.paymentDateList.add(payment);
		}
		
		System.debug('### EDIT_PAYMENT_RESULT: ' + errorMessage + ' --- ' + result);
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        // Logging call
        //ID logId = TMGUtil.logWebServiceRequest('Outbound', MPPInterfaceHTTP.editPaymentScheduleEnpointRequest, 'editPaymentSchedule',
        //	 new Map<String, Object>{'PAYMENT_SCHEDULE_ID' => premSubId, 'TOTAL_AMOUNT' => totalAmount, 'FREQUENCY' => frequency});
        	 
        // Logging the Response
		//TMGUtil.logWebServiceResponse(logId, result);	
    	return result;		
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Sets up initial variables based on custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/05/2015  //added extra var setting - MPP_AFFILIATEID
    Michal Szewczyk 1.2         13/05/2015  //changed method to public to use it in other places
    ****************************************************************************************/
    public void initialise(string TSNumber){
        PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
        this.BASE_MPP_URL = customSetting.baseURL__c;
        this.MPP_PASSWORD = customSetting.Password__c;  
        this.MPP_AFFILIATEID = customSetting.Login__c;	

        setGuid(TSNumber);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Sets up initial variables based on custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/05/2015  //added extra var setting - MPP_AFFILIATEID
    ****************************************************************************************/
    public void initialiseIgnoreGuid(){
    	PlaneURL__c customSetting = PlaneURL__c.getInstance('MPP');
        this.BASE_MPP_URL = customSetting.baseURL__c;
        this.MPP_PASSWORD = customSetting.Password__c;  
        this.MPP_AFFILIATEID = customSetting.Login__c;	
    }

	private void setGuid(string TSNumber){
		
		string errorMessage, errorNumber;
		
		if(this.MPP_GUID != null)
			return;
		
		Dom.Document response;
        if (!Test.isRunningTest()){
        	system.debug('BASE_URL --->>'+BASE_MPP_URL);
        	system.debug('PASSWORD --->>'+MPP_PASSWORD);
        	system.debug('TS_NUMBER --->>'+TSNumber);
        	try {
				response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.getGuidEndpoint.replace('[BASE_URL]', this.BASE_MPP_URL)
																		.replace('[PASSWORD]', this.MPP_PASSWORD)
																  		.replace('[TS_NUMBER]', TSNumber));
        	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
        }
        // Dummy Response for Test
        else{
        	response = new Dom.Document();
        	response.load('<GetGuidResult xmlns="http://schemas.datacontract.org/2004/07/MppGlobal.iShop.BusinessObjects.iPayDeveloper" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'
  				+'<ErrorMessage xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4"/>'
  				+'<ErrorNumber xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">0</ErrorNumber>'
  				+'<Guid xmlns="MppGlobal.iShop.BusinessObjects.iPayDeveloper.DataContract.v4">a36b6b84f1514594bcd660c79d0afae4</Guid>'
  				+'</GetGuidResult>');
        }
		  
		GetGuidResult result = new GetGuidResult();
		for(DOM.Xmlnode node : response.getRootElement().getChildElements()){
			
			if(node.getName() == 'ErrorMessage')
				errorMessage = node.getText();
				
			if(node.getName() == 'ErrorNumber')
				errorNumber = node.getText();
				
			if(node.getName() == 'Guid')
				result.guid = node.getText();
				
		}
		
		if(errorMessage != null && errorMessage != ''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
		}
		
		this.MPP_GUID = result.guid;
		
	}
	
	//
	// userInfo call added by DM 11/10 as part of the subscriberConsoleWebservice
	//
	public UserInfoResult callUserInfoByTSNumber(string TSNumber){

		initialiseIgnoreGuid(); 
		string errorMessage, errorNumber;
		Dom.Document response;
        if (!Test.isRunningTest()){
        	try {
				response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.userInfoEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL)
									 										   .replace('[PASSWORD]', this.MPP_PASSWORD)
																			   .replace('[TSNUMBER]', TSNumber));
          	}
        	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}
          } else{ // Dummy Response for Test
        	response = new Dom.Document();
        	response.load(MPPInterfaceHTTPHelper.getUserInfoTestXML()); 
        }
        														  
		UserInfoResult result = MPPInterfaceHTTPHelper.parseUserInfoResponse(response);	
		
		if (result == Null)  
			system.debug('**** Error: UserInfoResult is NULL ***');	
		
		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        return result;
    }
    
	/**********************************************************************************
    Developer - DM
    Date - 11/10
    Version - 1.0
    Function -   userInfo call added as part of the subscriberConsoleWebservice
    #############Change Log#############
    Modified by     	Version     Change Date
	Cristina Anghenie	1.1			12/10/2015	//remove dummy response and add test response in MPPWebserviceMock
    ***********************************************************************************/  
	public UserInfoResult callUserInfoByEmail(string Email){

		initialiseIgnoreGuid(); 
		string errorMessage, errorNumber;
		Dom.Document response;
        	
    	String encodedEmail = EncodingUtil.urlEncode(Email, 'UTF-8'); 
    	try {
			response = TMGAPIUtils.callOutGet(MPPInterfaceHTTP.userInfoEndpointEmail.replace('[BASE_URL]',this.BASE_MPP_URL)
								 										   .replace('[PASSWORD]', this.MPP_PASSWORD)
																		   .replace('[EMAIL]', encodedEmail));
     	}
    	catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}
		UserInfoResult result = MPPInterfaceHTTPHelper.parseUserInfoResponse(response);	
		if (result == Null)  
			system.debug('**** Error: UserInfoResult is NULL ***');	
		
		if(errorMessage != null && errorMessage !=''){
			throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        }
        
        return result;
    }    
	
	/**********************************************************************************
    Developer - DM
    Date - 15/10
    Version - 1.1
    Function -   UserOrderHistory call added as part of the subscriberConsoleWebservice
    #############Change Log#############
    Modified by     Version     Change Date
	Wiktor Czykin	1.1			21/05/2015	//moved logic to getUserOrderHistoryFromMPP() so that it could be made more general
    										//used to be callUserOrderHistoryByMppGuid
    Wiktor Czykin 	1.2			29/05/2015	//set descending order -> will impact the diagnostic console order of order history related rows (most recent on top)
    										//done so that most recent orders don't stop showing up in console in few years time, also to simplyfy WebPackUpgradeBatch logic
    ***********************************************************************************/
 	public UserOrderHistoryResult callUserOrderHistoryByMppGuid(String sMppGuid){
 		return this.getUserOrderHistoryFromMPP(	sMppGuid, 
 												null, 
 												Datetime.newInstanceGmt(Date.newInstance(2012, 01, 01), Time.newInstance(0, 0, 0, 0)),
 												Datetime.now().addMonths(3),
 												null,
 												true
 												);
 	}

	/**********************************************************************************
    Developer - Wiktor Czykin
    Date - 21/05/2015
    Version - 1.1
    Function - refactored version of callUserOrderHistoryByMppGuid()
    #############Change Log#############
    Modified by     Version     Change Date
   	Wiktor Czykin	1.1			08/01/2015	//made all requests descending and then reversed in sfdc if it should be ascending. Ascending does not work in MPP - returning random orders.
    ***********************************************************************************/
    public UserOrderHistoryResult getUserOrderHistoryFromMPP(String sMppGuid, String sTSNumber, Datetime dtFrom, Datetime dtTo, Integer iNumberOfOrders, Boolean bDescending){
        this.initialiseIgnoreGuid(); 
        String sErrorMessage;
        String sErrorNumber;
        Dom.Document response;
        String sDateFormat = 'yyyy-MM-dd';
        Integer iOrders = 100;
        if(iNumberOfOrders != null && iNumberOfOrders > 0){
        	iOrders = iNumberOfOrders;
		}

        if (!Test.isRunningTest() || bRunTest){
        	if((String.isBlank(sMppGuid) && String.isBlank(sTSNumber)) || dtFrom == null || dtTo == null) throw new MPPInterfaceHTTPException('Missing required parameters to process the request.');

        	String sUserManageEndpoint = MPPInterfaceHTTP.userOrderHistoryEndpoint.replace('[BASE_URL]',this.BASE_MPP_URL);

        	Map<String, String> mapParameters = new Map<String, String>();
	        mapParameters.put('clientId', this.MPP_AFFILIATEID);
			mapParameters.put('apiPassword', this.MPP_PASSWORD);
			if(String.isNotBlank(sMppGuid)){
				mapParameters.put('guid', sMppGuid);
			}else if(String.isNotBlank(sTSNumber)){
				mapParameters.put('clientUserId', sTSNumber);
			}	
			mapParameters.put('fromDateUTC', dtFrom.format(sDateFormat));
			mapParameters.put('toDateUTC', dtTo.format(sDateFormat));
			mapParameters.put('numOrdersInPage', iOrders+'');
			mapParameters.put('pageNum', '1');
			mapParameters.put('sortAscending', 'false');

	        System.debug('TMGLOG::MPPInterfaceHTTP:getUserOrderHistoryFromMPP():JSON PARAMETERS: '+JSON.serialize(mapParameters));
	        
        	try {
            	response = TMGAPIUtils.callOutGet(sUserManageEndpoint, mapParameters);
          	}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
        		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
        	}

        } else{ // Dummy Response for Test
            response = new Dom.Document();
            response.load(MPPInterfaceHTTPHelper.getUserOrderHistoryTestXML()); 
        }
                                                                 
        UserOrderHistoryResult result = MPPInterfaceHTTPHelper.parseUserOrderHistoryResponse(response, (bDescending == null || !bDescending)); 
        
        if(String.isNotBlank(sErrorMessage)){
            throw new MPPInterfaceHTTPException(sErrorNumber, sErrorMessage);
        } 
        return result;
    }   
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 14/08/2015
    Version - 1.2
    Function -  MPP Webservice call to get the related MPP orders for the most recent subscription 
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie	1.1			29/09/2015	//add TS number to getUserOrderHistoryResult method to fix payment details if there is no email address
    Wiktor Czykin		1.2			08/10/2015	//made all requests descending and then reversed in sfdc if it should be ascending. Ascending does not work in MPP - returning random orders.
    ****************************************************************************************/
    public UserOrderHistoryResult getUserOrderHistoryResult(String emailAddress, String TSNumber, String dtFrom, String dtTo, Boolean bAscending){
		String errorMessage, errorNumber;
		initialiseIgnoreGuid();
		Dom.Document response;
    	try {
			String userOrderCompleteEndpoint = MPPInterfaceHTTP.userOrderHistorySOAPEndpointRequest.replace('[BASE_URL]',this.BASE_MPP_URL)
																		   .replace('[PASSWORD]', this.MPP_PASSWORD)
																		   .replace('[USERID]',(TSNumber==null ? '' : TSNumber))
																		   .replace('[EMAIL]', (emailAddress==null ? '' : EncodingUtil.urlEncode(emailAddress, 'UTF-8')))
																		   .replace('[DTFROM]', (dtFrom==null ? '' : dtFrom))
																		   .replace('[DTTO]', (dtTo==null ? '' : dtTo))
																		   .replace('[ASC]', false+'');
		
	        response = TMGAPIUtils.callOutGet(userOrderCompleteEndpoint);
		}catch (TMGAPIUtils.UnsuccessfullResponseException ex) {
    		throw new MPPInterfaceHTTPException(ex.getErrorCode(),ex.getErrorMessage());
    	}
        														  
		UserOrderHistoryResult result = MPPInterfaceHTTPHelper.parseUserOrderHistoryResponse(response, bAscending); 
        
        if(String.isNotBlank(errorMessage)){
            throw new MPPInterfaceHTTPException(errorNumber, errorMessage);
        } 
        return result;
    }

	private class GetGuidResult{
		public string guid;
	}
	
	public class DatedPayment // Subscriptions BAU:PP-1631 : changed visibility to public
	{
		public String amount;
		public String pCurrency;
		public String orderDate;
	}
	
	global class EditPaymentScheduleResult
	{
		public String amountOwedToCustomer;
		public List<DatedPayment> paymentDateList = new List<DatedPayment>();
	}
	
	global class ChangePaymentScheduleDateResult
	{
		public String mppNextPaymentDate {get; private set;}
		public String sfdcNextPaymentDate {get; private set;}
		
		/** START : Subscriptions BAU:PP-1631 */
		public String paymentScheduleId;
		public Date expiryDate;
		public Date nextPaymentDate;
		private List<DatedPayment> datedPaymentList = new List<DatedPayment>();

		public List<DatedPayment> getDatedPaymentsList() {
			return datedPaymentList;
		}

		/** END : Subscriptions BAU:PP-1631 */
		
		public ChangePaymentScheduleDateResult(){}
		public ChangePaymentScheduleDateResult(String theDate)
		{
			setSFDCNextPaymentDate(theDate);
		}
		
		public void setSFDCNextPaymentDate(String theDate)
		{
			mppNextPaymentDate = theDate.substring(0, theDate.indexOf('T')).trim();
			//Get rid of any trailing zeros i.e if 01 then we want 1.
			sfdcNextPaymentDate = Integer.valueOf(mppNextPaymentDate.split('-')[2].trim()).format();
		}
	}
	
	global class CancelPaymentScheduleResult
	{
		public String clientRef;
		public String currencyCancelledPayments;
		public String grossAmountCancelledPayments;
		public String noCancelledPayments;
		public String paymentScheduleId;
	} 
	
	global class ReactivatePaymentScheduleResult
	{
		public String clientRef;
		public String currencyMissedPayments;
		public String currencyReactivatedPayments;
		public String grossAmountMissedPayments;
		public String grossAmountReactivatedPayments;
		public String noOfMissedPayments;
		public String noOfReactivatedPayments;
		public String orderId;
		public String paymentScheduleId;
		public String chargedStatusMissedPayments;
	}
	
	/**
	* @author Unknown
	* @date Unknown
	* @description Wrapper to store payment details from MPP response
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         06/09/2015  //added low start parameters to support payment details on acquisition summary page
	**/
	global class PaymentDetailResult{
		public String tsNumber {get; set;}
		public String digiSubId {get; set;}
		public String premSubId {get; set;}
		public String payerRef {get; set;}
		public String sortCode {get; set;}
		public String accNumber {get; set;}
		public String firstCollectionDate {get; set;}
		public String collectionFreq {get; set;}
		public String collectionDate {get; set;}
		public String firstCollectionAmount {get; set;}
		public String ongoingCollectionAmount {get; set;}
		public String creditCardNumber {get; set;}
		public String creditCardExpiryDate {get; set;}
		public String creditCardAuthCode {get; set;}
		public String lowStartFirstCollectionAmount{get;set;}
		public String lowStartFirstCollectionDate{get;set;}
		public String lowStartOngoingCollectionAmount{get;set;}
	}
	
	global class AutoRenewResult{
		public Boolean autoRenewEnabled;
		public String serviceId; 
	}
	
	public class CancelSubscriptionResult{
		public string deferredRevenue;
		public string deferredRevenueCurrency;
		public string serviceGroupTag;
		public string serviceGroupTitle;
		public string serviceId;
		public string status;
	}
	
	public class UserManageResult{
		public string guid;
	}
	
	public class RefundOrderResult{
		public String refundAmount;
		public String refundOrderId; 
		public String errorNumber;
		public String errorMessage;
	}

	public class RefundOrder{
		public String saleOrderId;
		public Decimal refundAmount;
		public String paymentType;

		public RefundOrder(String saleOrderId, Decimal refundAmount, String paymentType){
			this.saleOrderId = saleOrderId;
			this.refundAmount = refundAmount;
			this.paymentType = paymentType;
		}
	}
	
	/**
	* @author Unknown
	* @date Unknown
	* @description Custom exception for MPP callouts
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         18/05/2015  //made sure getMessage() returns what it should
	**/
	public class MPPInterfaceHTTPException extends Exception{
		private string errorCode;
		private string errorMessage;
		
		public MPPInterfaceHTTPException(string errorCode, string errorMessage){
			this(errorMessage);
			this.errorCode = errorCode;
			this.errorMessage = errorMessage;
		}
		
		public string getErrorCode(){
			return errorCode;
		}
		
		public string getErrorMessage(){
			return errorMessage;
		}
	}


	// START : classes for Subscriptions BAU:PP-1862, Subscriptions BAU:PP-1615, Subscriptions BAU:PP-1631
	public class SubscriptionResult {
		public Decimal actualPrice;
	    public Boolean autoRenew;
	    public String currencyUsed;
	    public Decimal lastBillingAmount;
	    public String lastBillingCurrency;
	    public DateTime lastBillingDate;
	    public TaxResult lastBillingTaxResult;
	    public DateTime lastPaymentDate;
	    public DateTime nextPaymentDate;
	    public Integer servicePriceId;
	    public SubscriptionPriceItems subscriptionPriceItems;

	}
	
	public class AddSubscriptionResult {
		public String ErrorMessage {get;set;}
		public String ErrorNumber {get;set;}
		public String ClientRoleTitle {get;set;}
	    public DateTime FixedEndDate {get;set;}
	    public DateTime RenewalDate {get;set;}
	    public String RoleId {get;set;}
	    public String RoleTitle {get;set;}
	    public String ServiceGroupTag {get;set;}
	    public String ServiceGroupTitle {get;set;}
	    public String ServiceId {get;set;}
	    public String SubscriptionStatus {get;set;}
	    public String ThreeDSecureEnrolled {get;set;}
	    public String ThreeDSecureHtml {get;set;}
	    public String ThreeDSecureMD {get;set;}
	    public String ThreeDSecureStatus {get;set;}
	    public String ThreeDSecureAcsUrl {get;set;}
	    public String ThreeDSecurePaReq {get;set;}
	}
	
	public class ChangeSubscriptionResult {
		public String ErrorMessage {get;set;}
		public String ErrorNumber {get;set;}
		public String ClientRoleTitle {get;set;}
	    public DateTime FixedEndDate {get;set;}
	    public DateTime RenewalDate {get;set;}
	    public String RoleId {get;set;}
	    public String RoleTitle {get;set;}
	    public String ServiceGroupTag {get;set;}
	    public String ServiceGroupTitle {get;set;}
	    public String ServiceId {get;set;}
	    public String SubscriptionStatus {get;set;}
	}
	
	public class SubscriptionPriceItems {
	    private ArrayOfSubscriptionPriceItem items;
	    public ArrayOfSubscriptionPriceItem getItems() {
	        return items;
	    }
	    public void setItems(ArrayOfSubscriptionPriceItem value) {
	        this.items = value;
	    }
	}

	public class ArrayOfSubscriptionPriceItem {
	    private List<SubscriptionPriceItem> subscriptionPriceItems;
	    public List<SubscriptionPriceItem> getSubscriptionPriceItems() {
	        if (subscriptionPriceItems == null) {
	            subscriptionPriceItems = new List<SubscriptionPriceItem>();
	        }
	        return this.subscriptionPriceItems;
	    }
	}
	
	public class SubscriptionPriceItem {
	    public String description;
	    public Decimal price;
	    public Integer supplierId;
	    public String thirdPartyRef;
	}
	
	
	public class TaxResult {
		public Decimal grossAmount;
	    public Decimal netAmount;
    	public ArrayOfTaxRegionAmount taxRegions;
    	public Decimal totalTaxAmount;
	    public Decimal totalTaxPercentage;
	}
	
	
	public class TaxRegionAmount {
		public String regionName;
		public String regionType;
	   	public String displayName;
	    public Decimal taxAmountForRegion;
	    public String taxCategory;
	    public Decimal taxRateForRegion;
	
	}
	
	
	public class ArrayOfTaxRegionAmount {
		private List<TaxRegionAmount> taxRegionAmounts;

	    public List<TaxRegionAmount> getTaxRegionAmounts() {
	        if (taxRegionAmounts == null) {
	            taxRegionAmounts = new List<TaxRegionAmount>();
	        }
	        return this.taxRegionAmounts;
	    }

	}
		
	public class PaymentScheduleResult {
	    public String frequency;
	    public Integer paymentDate;
	    public Integer paymentDateOffset;
	    public ArrayOfScheduledOrdersResult scheduleOrders;
	    public DateTime startDate;
	    public Decimal totalAmount;
	}
	
	
	public class ScheduledOrdersResult {
		public String currencyUsed;
	    public DateTime orderDate;
	    public Integer orderID;
	    public OrderStatus orderStatus;
	    public PaymentTypes paymentMethod;
	    public TaxResult priceInformation;
	}
	
	global class UserInfoResult {
		webservice AccountDetailParameters[] AccountDetailParameters {get;set;}
		webservice String AccountStatus {get;set;}
		webservice String EmailAddress {get;set;}
		webservice String FirstName {get;set;}
	    webservice String Surname {get;set;}
	    webservice String MPPGuid {get;set;}	    
	}
	
	global class AccountDetailParameters {
		webservice String ParameterName {get;set;}
	    webservice String ParameterValue {get;set;}
	}
	
	global class UserOrderHistoryResult {
		webservice OrderHistoryItem[] OrderHistoryItems {get;set;}
		webservice String TotalNumberOfOrders {get;set;}
	}	

	global class OrderHistoryItem {
		webservice String OrderDate {get;set;}
    	webservice String RawOrderDescription {get;set;} //Description as returned from MPP
		webservice String OrderDescription {get;set;} //Currently defaulted
		webservice String OrderId {get;set;}
		webservice String GrossAmount {get;set;}
		webservice String NetAmount {get;set;}
		webservice String OrderCurrency {get;set;}
		webservice list<OrderParameter> OrderParameters {get;set;}
		webservice String PaymentType {get;set;}
	}

	global class OrderParameter {
	    webservice String Name {get;set;}
	    webservice String Value {get;set;}
	}
	
	public class ServiceInformationResult {
		public string  ApplicationMessage;
		public string  ApplicationMessage2;
		public string	ApplicationOfferName;
		public DateTime ExpiryDate;
		public DateTime FirstNonDiscountedBillingPoint;
		public DateTime LastDiscountedBillingPoint;
		public string	OfferName;
		public string	OfferTypeId;
		public string	VoucherCode;
		public string	ServiceGroup;
		public string	ServiceStatus;
		public string	ServiceTitle;
		public Integer	ServiceID;
		public Decimal VoucherDiscountPrice;
		
		public  SubscriptionResult SubscriptionInformation;

		
		public PaymentTypes PaymentMethod;
		public PaymentScheduleResult PaymentScheduleInformation;
	}
	
	public enum PaymentTypes {
		CREDITDEBITCARD,
	    SERVICECREDIT,
	    REVERSEBILLSMS,
	    NOTAVAILABLE,
	    VOUCHERCODE,
	    DIRECTDEBIT,
	    PAYPAL
	}

	public enum OrderStatus {
	    CREATED,
	    NEWORDER,
	    CONFIRMED,
	    DISPATCHED,
	    CANCELLED,
	    NOTIFIED,
	    REMINDER,
	    COMPLETED,
	    REFUNDED,
	    WAITING,
	    DOWNLOADED,
	    SUSPECTEDDUPLICATE,
	    MAXREFUNDED,
	    PARTIALREFUNDED,
	    NEEDTOORDER,
	    PRODUCTSORDERED,
	    AUTHORISED
	}

	
	public class ArrayOfScheduledOrdersResult {

	    private List<ScheduledOrdersResult> scheduledOrdersResults;
	
	    public List<ScheduledOrdersResult> getScheduledOrdersResults() {
	        if (scheduledOrdersResults == null) {
	            scheduledOrdersResults = new List<ScheduledOrdersResult>();
	        }
	        return this.scheduledOrdersResults;
	    }

	}
	
	public class UserServicesResult {
		public ArrayOfServiceInformationResult serviceInformation;
	}
	
	
	public class ArrayOfServiceInformationResult {
		public List<ServiceInformationResult> serviceInformationResults;

    	public List<ServiceInformationResult> getServiceInformationResults() {
        	if (serviceInformationResults == null) {
            	serviceInformationResults = new List<ServiceInformationResult>();
        	}
        	return this.serviceInformationResults;
    	} 
	}
	
	// added as container for Subscriptions BAU:PP-1631 restructured response
	public class ChangePaymentSchedulePaymentDateResult {
		private ChangedPaymentSchedules changedPymtSchedules;
		
		public ChangedPaymentSchedules getChangedPaymentSchedules() {
			return changedPymtSchedules;
		}
	}
	public class ChangedPaymentSchedules {
		private List<ChangePaymentScheduleDateResult> pymtScheduleDateResultList = new List<ChangePaymentScheduleDateResult>();
		
		public List<ChangePaymentScheduleDateResult> getChangePaymentSchedulePaymentDateItems() {
			return pymtScheduleDateResultList;
		}
	}
	
}