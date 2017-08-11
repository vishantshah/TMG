/**
Name: SubscriberEntitlementsQueueable
* @author Michal Szewczyk
* @date 21/04/2016
* @description Queueable class for processing entitlements update every time that account/sub is updated
* ##########Change Log##########
* Modified by     Version     Change Date 
* Wiktor Czykin	  1.1		  27/01/2017 //modified callSamUpdateByQueueable()
*/
public class SubscriberEntitlementsQueueable implements Queueable {
	
	@TestVisible private List<SubscriptionsSAMWebservices.updateNotification> scope = new List<SubscriptionsSAMWebservices.updateNotification>();
	@TestVisible private Integer scopePointer{get;set;}
	public static final Integer ERROR_LIMIT = 200;
	public static final Integer DEFAULT_QUEUE_SIZE = 100;
	public static final Integer FEATURE_CALL_SIZE = 20;
	public static final String WL_REASON_GENERAL_ERROR = 'callSamUpdateByQueueable';
	public static final String WL_REASON_REGISTRANT_RESYNC = 'registrantEntitlementsResync';
	@TestVisible private Integer iQueueSize{get;set;}

    /*************************************************************************************** 
	Developer - Michal Szewczyk
	Date Created -  21/04/2016
	Version - 1.0 
	Function - 	Default constructor. Accepts queue size (number records to be process by iteration) and list of all rec to process
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
  	public SubscriberEntitlementsQueueable(Integer iQueueSize, List<SubscriptionsSAMWebservices.updateNotification> scope,Integer pointer){
	    if(scope != null){
	    	this.scope = scope;
	    }
	    this.scopePointer = pointer != null?pointer:0;
	    this.iQueueSize = iQueueSize!=null?iQueueSize:DEFAULT_QUEUE_SIZE;
  	}
    
    /*************************************************************************************** 
	Developer - Michal Szewczyk
	Date Created -  21/04/2016
	Version - 1.0 
	Function - 	execute method that process all scope
	############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public void execute(QueueableContext context) {
		Integer stopIndex = scopePointer + iQueueSize;
		List<SubscriptionsSAMWebservices.updateNotification> serializedRecords = new List<SubscriptionsSAMWebservices.updateNotification>();
		if(stopIndex > scope.size()) stopIndex = scope.size();

		for(Integer startIndex = scopePointer;startIndex < stopIndex;startIndex++){
			SubscriptionsSAMWebservices.updateNotification loopRow = scope[startIndex];		
			serializedRecords.add(loopRow);
			if(serializedRecords.size() == FEATURE_CALL_SIZE) {
				callSamUpdateByQueueable(JSON.serialize(serializedRecords));
				serializedRecords.clear();
			}
			
			scopePointer++;
		}

		if(serializedRecords.size() > 0) {
			callSamUpdateByQueueable(JSON.serialize(serializedRecords));
			serializedRecords.clear();
		}
		
		if(stopIndex < scope.size()){
			System.enqueueJob(new SubscriberEntitlementsQueueable(iQueueSize,scope,scopePointer));
		}
	}

	/**
	* @author Michal Szewczyk
	* @date 21/04/2016
	* @description Nested class to store log for batch 
	* ##########Change Log##########
	* Modified by     Version     Change Date 
	*/
	public class BulkEntRowResult{
		public String sTsNumber;
		public String sEmail;
		public String sEntitlementsRemoved;
		public String sEntitlementsAdded;
		public String guid;
		public String sError;
		public String sMessage;

		/*************************************************************************************** 
		Developer - Michal Szewczyk
		Date Created - 21/04/2016
		Version - 1.0
		Function - constructor - initializes params based on updateNotification obj
		#############Change Log#############
		Modified by     Version     Change Date
		****************************************************************************************/
		public BulkEntRowResult(SubscriptionsSAMWebservices.updateNotification rec){
			//this.sTsNumber = acc.Subscriber_Number__c;
			
			SubscriptionsSAMWebservices.attributes_element attr = rec.attributes;
			SubscriptionsSAMWebservices.emailAttribute emailAttr = attr.email;
			this.sEmail = emailAttr.value;
			this.guid = rec.guid;
			this.sError = '';
			this.sEntitlementsRemoved = '';
			this.sEntitlementsAdded = '';
			this.sMessage = '';
		}
	}
	/*************************************************************************************** 
	Developer - Michal Szewczyk
	Date Created - 27/04/2016
	Version - 1.1
	Function - feature call to update entitlements
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1			27/01/2017	modified so that we log entitlements changes for registrants
	****************************************************************************************/
	@future(callout=true)
    public static void callSamUpdateByQueueable(String serializedRecords){ 
		SAMUtil samUtil = new SAMUtil();
		Map<String,BulkEntRowResult> mapSubGuidToErrors = new Map<String,BulkEntRowResult>();
        List<SubscriptionsSAMWebservices.updateNotification> rows = (List<SubscriptionsSAMWebservices.updateNotification>) JSON.deserialize(serializedRecords, List<SubscriptionsSAMWebservices.updateNotification>.class);
    	List<WebService_Log__c> logs = new List<WebService_Log__c>(); 
   		Map<String, Account> mapAccounts = new Map<String, Account>();
    	Id registrantTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());

    	for (SubscriptionsSAMWebservices.updateNotification loopRow : rows) {
    		if(String.isBlank(loopRow.guid)) continue;
			mapSubGuidToErrors.put(loopRow.guid, new BulkEntRowResult(loopRow));
    	}

    	for(Account acc : [select Id, Guid__c, RecordTypeId, Subscriber_Number__c from Account where Guid__c != null and Guid__c in :mapSubGuidToErrors.keySet()]){
    		mapAccounts.put(acc.Guid__c, acc);	
    	}

    	for (SubscriptionsSAMWebservices.updateNotification loopRow :rows) {
    		if(String.isBlank(loopRow.guid)) continue;
			BulkEntRowResult brr = mapSubGuidToErrors.get(loopRow.guid);
			System.assert(String.isNotBlank(loopRow.guid), JSON.serialize(loopRow));
			SAMUtil.SAMAccountResult accountResult;
			SAMInterfaceHTTP.bulkUpdateResponse blkResponseRemove;
			SAMInterfaceHTTP.bulkUpdateResponse blkResponseAdd;
			try{
				accountResult = SAMUtil.getExistingSAMAccount(brr.sEmail);
			}catch(Exception e){
				brr.sError += 'Failed to find existing account or issue with retrieval of recreated one:'+e.getMessage();
				continue; 
			}

			Set<String> setEntitlementsBefore = new Set<String>();
			Set<String> setEntitlementsAfter = new Set<String>();
			try{
				if(accountResult != null && String.isNotBlank(accountResult.guid)){
					if(accountResult.entitlements != null && !accountResult.entitlements.isEmpty()){
						brr.sEntitlementsRemoved = String.join(accountResult.entitlements, ', ');
						setEntitlementsBefore = new Set<String>(accountResult.entitlements);
					}
				}else{
					throw new TelegraphApplicationException('Still failed to find matching account in SAM.');
				}

				if(String.isNotBlank(loopRow.entitlements)){
					brr.sEntitlementsAdded = loopRow.entitlements;
					for(String str : loopRow.entitlements.split(',') ){
						setEntitlementsAfter.add(str);
					}
				}
			}catch(Exception e){
				brr.sError += 'Failed to retrieve entitlements for processing: '+e.getMessage();
				continue;
			}

			if(setEntitlementsBefore != setEntitlementsAfter){
				if(!setEntitlementsBefore.isEmpty()){
					try{
						blkResponseRemove = SAMInterfaceHTTP.updateSubscriptionEntitlement(	brr.sEmail, 
																							brr.guid, 
																							setEntitlementsBefore, 
																							SAMInterfaceHTTP.EntitlementUpdateType.REMOVE
																						);
						if(blkResponseRemove.statusCode != null  && blkResponseRemove.statusCode == SAMInterfaceHTTP.ResponseStatusCodes.FAIL && blkResponseRemove.message != null){
							throw new TelegraphApplicationException(blkResponseRemove.message);
						}
					}catch(Exception e){
						brr.sError += 'Failed to delete entitlements for existing account or to create a new account in sam:'+e.getMessage();
						if(!Test.isRunningTest()) continue;
					}
				}

				if(!setEntitlementsAfter.isEmpty()){
					try{
						blkResponseAdd = SAMInterfaceHTTP.updateSubscriptionEntitlement(brr.sEmail, brr.guid, setEntitlementsAfter, SAMInterfaceHTTP.EntitlementUpdateType.ADD);
						if(blkResponseAdd.statusCode != null  && blkResponseAdd.statusCode == SAMInterfaceHTTP.ResponseStatusCodes.FAIL && blkResponseAdd.message != null){
							throw new TelegraphApplicationException(blkResponseAdd.message);
						}
						//[message=Username or password invalid, statusCode=FAIL] - response if no account
					}catch(Exception e){
						brr.sError += 'Failed to add new entitlements:'+e.getMessage();
						if(!Test.isRunningTest()) continue;
					}
				}
			}
			
			Account acc = mapAccounts.get(loopRow.guid);
			if(String.isNotEmpty(brr.sError)) {
				WebService_Log__c wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, null, WL_REASON_GENERAL_ERROR, brr, null, (acc != null)?acc.Id:null, null);
				if(acc!=null){
					wl.TS_Number__c = acc.Subscriber_Number__c;
				}
				logs.add(wl);
			} 
			if(setEntitlementsBefore != setEntitlementsAfter && acc != null && acc.RecordTypeId == registrantTypeId){
				WebService_Log__c wl = TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, null, WL_REASON_REGISTRANT_RESYNC, brr, null, acc.Id, null);
				wl.TS_Number__c = acc.Subscriber_Number__c;
				logs.add(wl);
			}
		}
		if(logs.size() > 0) {
			insert logs;
		}
    }
}