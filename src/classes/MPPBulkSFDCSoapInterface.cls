public with sharing class MPPBulkSFDCSoapInterface 
{
    /*
    	Abstract interface flow for MPP soap webservice callouts:
    	@param T = MPPBusinessObjectsBulkUpdate.Object
    	@param U = MPPBusinessObjectsBulkUpdate.ArrayOfObject 
    */
    public interface IMPPDataProcess<T, U>
    {
    	T createRequest(SObject obj);
    	List<T> getCurrentJobData();
    	U getJobLoad();
    	MPPBusinessObjectsIPaydev.BulkUpdateResultData getResult();
    
    	void buildJobData();
    	void buildJobData(List<SObject> queue);
    	void invokeCall();
    } 
    
    /*
    	Generic MPP Soap Request class
    */  
    public virtual class SoapRequest
    {
		protected Map<Id, SObject> sObjectMap;
		protected Map<String, String> oldData;
		protected String query;
		private MPPBusinessObjectsIPaydev.BulkUpdateResultData testData;
		
		public SoapRequest()
		{
			sObjectMap = new Map<Id, SObject>();
			oldData = new Map<String, String>();
			testData = null;
		}
		
		public SoapRequest(String query)
		{
			sObjectMap = new Map<Id, SObject>();
			oldData = new Map<String, String>();
			testData = null;
			setQuery(query);
		}
		
		public MPPBusinessObjectsIPaydev.BulkUpdateResultData getTestData()
		{
			return this.testData;
		}
		
	    public Map<String, String> getOldData()
	    {
	    	return oldData;
	    }
	    
	    public void setOldData(Map<String, String> theData)
	    {
	    	oldData = theData;
	    }
	    
	    public Map<Id, SObject> getSObjectMap()
	    {
	    	return sObjectMap;
	    }
	    
	    public String getQuery()
	    {
	    	return query; 
	    }
	    
	    public void setQuery(String query)
	    {
	    	this.query = query;
	    }
	    
	    public void setTestData(MPPBusinessObjectsIPaydev.BulkUpdateResultData testData)
	    {
	    	this.testData = testData;
	    }
    }
    
    public class UserManageRequest extends SoapRequest implements IMPPDataProcess<MPPBusinessObjectsBulkUpdate.UserManageRequest,
													   							  MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest>
	{
		private List<MPPBusinessObjectsBulkUpdate.UserManageRequest> jobData;
		
		public UserManageRequest()
		{
			super();
			jobData = new List<MPPBusinessObjectsBulkUpdate.UserManageRequest>();
		}
		
		public UserManageRequest(String query)
		{
			super(query);
			jobData = new List<MPPBusinessObjectsBulkUpdate.UserManageRequest>();
		}

		public MPPBusinessObjectsBulkUpdate.UserManageRequest createRequest(SObject acc)
		{
			MPPBusinessObjectsBulkUpdate.UserManageRequest req = new MPPBusinessObjectsBulkUpdate.UserManageRequest();
	        req.FirstName = (String)acc.get('FirstName');
	        req.Surname = (String)acc.get('LastName');
	        req.NewUki = (String)acc.get('PersonEmail'); 
	        req.CustomAccountParameters = new MPPDataContract.ArrayOfAccountParameter();
	        MPPDataContract.AccountParameter tsParam = new MPPDataContract.AccountParameter();
	        tsParam.ParameterName = 'TSNumber';
	        tsParam.ParameterValue = (String)acc.get('Subscriber_Number_static__c');
	        req.CustomAccountParameters.AccountParameter = new List<MPPDataContract.AccountParameter>{tsParam};
			return req;
		}
		
		public List<MPPBusinessObjectsBulkUpdate.UserManageRequest> getCurrentJobData()
	    {
	    	return this.jobData;
	    }
		
		public void buildJobData()
	    {
	    	for(SObject a :Database.query(query)){
	    		sObjectMap.put(a.Id, a);
	    		jobData.add(createRequest(a));
	    	}
	    }
	    
	    public void buildJobData(List<SObject> queue)
	    {
	    	if((queue == null || queue.isEmpty())){
	    		return;
	    	}
	    	
	    	for(SObject a :queue){
	    		sObjectMap.put(a.Id, a);
	    		jobData.add(createRequest(a));
	    	}
	    }
	    
	    public MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest getJobLoad()
	    {
	        MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest queue = new MPPBusinessObjectsBulkUpdate.ArrayOfUserManageRequest();
	        queue.UserManageRequest = new List<MPPBusinessObjectsBulkUpdate.UserManageRequest>(getCurrentJobData());
	        return queue;
	    }
	    
	    public MPPBusinessObjectsIPaydev.BulkUpdateResultData getResult()
	    {
	    	if(!Test.isRunningTest()){
	    		PlaneURL__c mppSetting = PlaneURL__c.getInstance('MPP');
		    	MPPBulkInterface.SOAPEndpoint soapStub = new MPPBulkInterface.SOAPEndpoint();
		    	soapStub.endpoint_x = mppSetting.BaseURL__c + 'interface/mpp/BulkUpdate/v4/BulkUpdate.SOAP.svc/soap';
	            soapStub.timeout_x = 60000;
	            Integer affilateId = Integer.valueOf(mppSetting.Login__c);
	            String password = mppSetting.Password__c;
	            MPPBusinessObjectsIPaydev.BulkUpdateResultData result = soapStub.BulkUserManage(affilateId, password, getJobLoad(), false);
	            System.debug('### MPP RESULT: ' + result);
	            return result;
	    	}else{
	    		return this.testData;
	    	}
	    }
	    
	    private void setDetailsOnFailure(Account acc, String firstName, String lastName, String personEmail)
	    {
	    	if(firstName != null && firstName.length() > 0 && acc.FirstName != firstName){
	    		acc.FirstName = firstName;
	    	}
	    	if(lastName != null && lastName.length() > 0 && acc.LastName != lastName){
	    		acc.LastName = lastName;
	    	}
	    	if(personEmail != null && personEmail.length() > 0 && acc.PersonEmail != personEmail){
	    		acc.PersonEmail = personEmail;
	    	}
	    }
	    
	    public void restoreDetailsOnFailure(List<Account> accQueue, Map<Id, String> accMap, String stackTrace)
	    {
	    	if((accQueue == null || accQueue.isEmpty()) || (accMap == null || accMap.isEMpty())){
	    		System.debug('### Invalid params passed in MPPAccountUserManageRequest.restoreDetailsOnFailure ###:');
	    		return;
	    	}
	    	
	    	System.debug('### Webservice failed - restoring old user details ###: ' + stackTrace);
	    	List<Task> taskJob = new List<Task>();
	    	
	    	for(Account acc :accQueue){
	    		List<String> fieldMap = accMap.get(acc.Id).split(',');
	    		String firstName = fieldMap[0];
	    		String lastName = fieldMap[1];
	    		String personEmail = fieldMap[2];
	    		
				taskJob.add(TaskHelper.createTask(
					acc.LastModifiedById, acc.Id, 
					Constants.FAILED_USER_REQUEST_SUBJECT.replace('[SYSTEM]', 'MPP'),  
	    			Constants.FAILED_USER_REQUEST_DESCRIPTION.replace('[SYSTEM]', 'MPP') + '\n'
	    				+ (acc.FirstName != firstName ? 'Change first name to: ' + acc.FirstName + '\n' : '')
	    				+ (acc.LastName != lastName ? 'Change last name to: ' + acc.LastName + '\n': '') 
	    				+ (acc.PersonEmail != personEmail ? 'Change email to: ' + acc.PersonEmail + '\n': '')
	    				+ '\n\nExtra Details:\n' + stackTrace, 
	    			Constants.FAILED_USER_REQUEST_STATUS)
	    		);
	    		
	    		//Revert the old details back.
	    		setDetailsOnFailure(acc, firstName, lastName, personEmail);
	    	}
	    	
	    	//Update account queue with the old user details, make sure global flag is set to avoid loop back with webservice call.
			insert taskJob;
			//Set global flag here.
			Constants.MPP_CALLOUT_DISABLED = true;
			update accQueue;
	    } 
	    
	    public void invokeCall()
	    {
	    }
		
		/*
	        @param Map<Id, String> - Id = Account.Id => String = Old(FirstName),Old(LastName),Old(PersonEmail)
	    */ 
		public void invokeCall(Map<Id, String> objectMap)
		{
			if(objectMap == null || objectMap.isEmpty()){
				return;
			}
			
			this.buildJobData([SELECT Id, FirstName, LastName, Salutation, 
				Subscriber_Number__c, PersonEmail, PersonTitle, LastModifiedById, 
				Subscriber_Number_static__c FROM Account 
				WHERE Id IN :objectMap.keySet()]);
				
			System.debug('### JOB DATA: ' + this.getCurrentJobData());
			
			try{
				MPPBusinessObjectsIPaydev.BulkUpdateResultData result = this.getResult();
				//If there was an error from the callback response, then revert details back. 
	        	if(!MPPBulkSFDCSoapInterface.isValidCallBack(result)){
	        		SubscriberPortal.SAM_WS_UPDATE = true;
	        		restoreDetailsOnFailure((List<Account>)this.sObjectMap.values(), 
	        			objectMap, MPPBulkSFDCSoapInterface.buildResponseString(result));
	        		MPPBulkSFDCSoapInterface.sendErrorEmail('MPP Webservice Error', 'MPP Webservices', 
	        			'MPPBulkSFDCSoapInterface.UserManageRequest.invokeCall', 
	        			'MPP callback response showed failed, calling MPPBulkSFDCSoapInterface.UserManageRequest.restoreDetailsOnFailure', null, 
	        			'Reverting back old subscriber details, job log: ' + String.valueof(this.getCurrentJobData()));
	        	}else{
	        		System.debug('### User change request successfully received by MPP ###: ' + result);
	        	}
			}catch(System.Exception e){
				String stack = MPPBulkSFDCSoapInterface.getStackTraceMsg(e);
	            System.debug('### Error in MPPAccountUserManageRequest.invokeCall failed ###: ' + stack);
	            //Revert emails back if salesforce error occurs.
	            SubscriberPortal.SAM_WS_UPDATE = true;
	            restoreDetailsOnFailure((List<Account>)this.sObjectMap.values(), objectMap, stack);
	            MPPBulkSFDCSoapInterface.sendErrorEmail('MPP Webservice Error', 'MPP Webservices', 
	    			'MPPBulkSFDCSoapInterface.UserManageRequest.invokeCall', 
	    			'Salesforce webservice error found, calling MPPBulkSFDCSoapInterface.UserManageRequest.restoreDetailsOnFailure', e, 
	    			'Reverting back old subscriber details, job log: ' + String.valueof(this.getCurrentJobData()));
			}
		}												  	
	}
	
	public static String getStackTraceMsg(Exception e)
    {
    	return (e.getMessage() + ' - ' + e.getStackTraceString());
    }
    
    public static String buildResponseString(MPPBusinessObjectsIPaydev.BulkUpdateResultData response)
    {
    	return ('Job Id: ' + response.BulkUpdateJobId + ' - Error Message: ' + response.ErrorMessage + ' - Error Number: ' + response.ErrorNumber);
    }
    
    public static Boolean isValidCallBack(MPPBusinessObjectsIPaydev.BulkUpdateResultData response)
    {
    	Boolean result = true;
    	try{
    		result = (response.ErrorMessage.length() == 0 && Integer.valueOf(response.ErrorNumber) == 0);
    	}catch(System.Exception e){
    		result = false;
    	}
    	return result;
    }
    
    public static void sendErrorEmail(String subject, String displayName, String method, 
    								  String message, Exception thrownException, 
    								  String stackTrace)
    {
		String emailAddress = 'teamsalesforce@telegraph.co.uk';
		TMGUtil.EmailUtil eml = new TMGUtil.EmailUtil(new List<String> {emailAddress});
		
		String body = 'An error occured in method: ' + method + '\r\n\r\n';
		body += 'Returned error message: ' + message + '\r\n\r\n';
		body += 'Further exception details: ' + string.valueOf(thrownException) + '\r\n\r\n';
		body += 'Stack: ' + stackTrace;
		
		eml.plainTextBody(body)
			.subject(subject)
			.replyTo(emailAddress)
			.senderDisplayName(displayName)
			.build()
			.sendEmail();
	}
	
	@future(callout=true) 
    public static void invokeFutureUserManageRequest(Map<Id, String> accMap)
    {
    	try
    	{
    		MPPBulkSFDCSoapInterface.UserManageRequest request = new MPPBulkSFDCSoapInterface.UserManageRequest();
    		request.invokeCall(accMap);  
    	}
    	catch(Exception e)
    	{
    		//Database.rollback(sp);
    		system.debug('=====invokeFutureUserManageRequest===== Exception '+e.getStackTraceString());
    	
    	}
    }		
}