/**
Name: RegistrantEntitlementsBatch
* @author Wiktor Czykin
* @date 26/02/2016
* @description 
* ##########Change Log##########
* Modified by     Version     Change Date 
*/
public without sharing class RegistrantEntitlementsBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {

	@TestVisible private static final String GENERAL_REGISTRANT_SYNC_DATE = 'Batch Registrant Sync From Date';
	@TestVisible private static final String GENERAL_REGISTRANT_SYNC_BATCH_SIZE = 'Batch Registrant Sync Batch Size';
	@TestVisible private static final String GENERAL_REGISTRANT_SYNC_FAILURE_USER = 'Batch Registrant Sync Failure Users';
	@TestVisible private static final String JOB_NAME = 'RegistrantEntitlementCleanup';
	@TestVisible private static final Integer DEFAULT_BATCH_SIZE = 1;
	@TestVisible private static final Integer ATTEMPTS = 3;
	@TestVisible private static final Integer ERROR_LIMIT = 400;
	@TestVisible private List<BatchRowResult> lstErrors = new List<BatchRowResult>();
	@TestVisible private Date dDateFrom;
	@TestVisible private Integer iBatchSize;
	@TestVisible private Set<Id> setIds;

	private static final Map<String, String> MAP_ENTITLEMENTS = new Map<String, String>{ 	'Tablet' => 'DIGITAL_SUBSCRIBER_ACTIVE',
																							'Website' => 'WEBPACK_SUBSCRIBER_ACTIVE',
																							'Customer Portal Offers' => 'CUSTOMER_PORTAL_OFFERS',
																							'Salesforce' => 'SALESFORCE'
	};

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created - 26/02/2015
	Version - 1.0
	Function -  constructor - init of custom settings and default values
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public RegistrantEntitlementsBatch(Boolean bUseCustomDate, Set<Id> setIds){
		this.dDateFrom = Date.today().addDays(-1);//default to yesterday
		this.iBatchSize = DEFAULT_BATCH_SIZE;
		this.setIds = setIds;
		
		if(bUseCustomDate){
			General__c settingDate = General__c.getInstance(GENERAL_REGISTRANT_SYNC_DATE);
			if(settingDate != null && String.isNotBlank(settingDate.Value__c)){
				try{
					this.dDateFrom = Date.parse(settingDate.Value__c);	
				}catch(Exception e){
					System.debug('TMGLOG:RegistrantEntitlementsBatch:constructor:failed to process data from settings - default used');
				}
			}
			
		}
		
		General__c settingSize = General__c.getInstance(GENERAL_REGISTRANT_SYNC_BATCH_SIZE);
		if(settingSize != null && String.isNotBlank(settingSize.Value__c) && settingSize.Value__c.isNumeric()){
			this.iBatchSize = Integer.valueOf(settingSize.Value__c);
		}
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created - 26/02/2015
	Version - 1.0
	Function - 	static method to run a schedule in one "go"
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public static void go(Boolean bUseCustomDate, String sCron, Set<Id> setIds){
		RegistrantEntitlementsBatch reb = new RegistrantEntitlementsBatch(bUseCustomDate, setIds);
		String sDefaultCron = '0 0,10,20,30,40,50 * * * ? *';
		if(String.isNotBlank(sCron)){
			sDefaultCron = sCron;
		}
		String sAddToName = Datetime.now().format('ss_mm_HH_dd_MM_yyyy');
		Id batchID = System.schedule(JOB_NAME+'_'+sAddToName, sDefaultCron, reb);
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created - 26/02/2015
	Version - 1.0
	Function - 	Implemented method from Batchable interface - queries required records and settings for processing
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public Database.querylocator start(Database.BatchableContext BC){
		Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		Date dFrom = this.dDateFrom;
		String sStatus = Constants.DIGITAL_SUBSCRIBER_STATUS_ACTIVE;
		Integer iAttempts = ATTEMPTS;
		String sFields = GlobalQueries.generateFieldsListForQuery(Account.class.getName(), null, null);
		String sQuery = 'select '+sFields+' from Account where RecordTypeId = :registrantRecordTypeId and Registrant_Entitlement_Sync_Completed__c = false and CreatedDate > :dFrom and Replatform_Digital_Status__c = :sStatus and (Registrant_Entitlement_Sync_Attempts__c = null or Registrant_Entitlement_Sync_Attempts__c < :iAttempts)';
		if(this.setIds != null && !this.setIds.isEmpty()){
			Set<Id> setTemp = this.setIds;
			sQuery += ' and Id in :setTemp';
		}
		return Database.getQueryLocator(sQuery);
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created - 26/02/2015
	Version - 1.0
	Function - Implemented execute method from Batchable interface 
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public void execute(Database.BatchableContext BC, List<Account> scope){
		Set<Id> setProductIds = new Set<Id>();
		for(Account acc : scope){
			if(acc.Product__c != null){
				setProductIds.add(acc.Product__c);
			}
		}
		Map<Id, zqu__ZProduct__c> mapProductToFeatures = new Map<Id, zqu__ZProduct__c>([select 	Id, 
																								Name, 
																								(select Id, 
																										zqu__ZFeature__r.Name, 
																										zqu__ZFeature__r.zqu__Code__c  
																									from zqu__ZProductFeatures__r) 
																							from zqu__ZProduct__c 
																							where Id in :setProductIds]);
		
		SAMUtil samUtil = new SAMUtil(); 
		Map<Id, BatchRowResult> mapAccountIdToErrors = new Map<Id, BatchRowResult>();
		for(Account acc : scope){
			if(acc.Registrant_Entitlement_Sync_Attempts__c == null){
				acc.Registrant_Entitlement_Sync_Attempts__c = 1;
			}else{
				acc.Registrant_Entitlement_Sync_Attempts__c++;
			}

			mapAccountIdToErrors.put(acc.Id, new BatchRowResult(acc));
			BatchRowResult brr = mapAccountIdToErrors.get(acc.Id);

			SAMUtil.SAMAccountResult accountResult;
			SAMInterfaceHTTP.bulkUpdateResponse blkResponseRemove;
			SAMInterfaceHTTP.bulkUpdateResponse blkResponseAdd;
			try{
				accountResult = SAMUtil.getExistingSAMAccount(acc.PersonEmail);
				
				if(accountResult!=null){
					if(String.isBlank(accountResult.guid)){
						//create the sam account
						String newGuid = samUtil.createSamAccount(acc, acc.Subscriber_Number__c, Constants.PRODUCT_DIGITAL.toLowerCase(), false, true);
						acc.Guid__c = newGuid;
						brr.sMessage = 'New guid attempt:'+newGuid;
						accountResult = SAMUtil.getExistingSAMAccount(acc.PersonEmail);
					}
					if(String.isBlank(acc.Guid__c)){
						acc.Guid__c = accountResult.guid;
					}
				}
			}catch(Exception e){
				brr.sError += 'Failed to find existing account or issue with retrieval of recreated one:'+e.getMessage();
				continue;
			}

			try{
				if(accountResult != null && String.isNotBlank(accountResult.guid)){
					if(accountResult.entitlements != null && !accountResult.entitlements.isEmpty()){
						brr.sEntitlementsRemoved = String.join(accountResult.entitlements, ', ');
						Set<String> setEntitlements = new Set<String>(accountResult.entitlements);
						blkResponseRemove = SAMInterfaceHTTP.updateSubscriptionEntitlement(	acc.PersonEmail, 
																							acc.Guid__c, 
																							new Set<String>(accountResult.entitlements), 
																							SAMInterfaceHTTP.EntitlementUpdateType.REMOVE
																						);
						if(blkResponseRemove.statusCode != null  && blkResponseRemove.statusCode == SAMInterfaceHTTP.ResponseStatusCodes.FAIL && blkResponseRemove.message != null){
							throw new TelegraphApplicationException(blkResponseRemove.message);
						}
					}
				}else{
					throw new TelegraphApplicationException('Still failed to find matching account in SAM.');
				}
			}catch(Exception e){
				brr.sError += 'Failed to delete entitlements for existing account or to create a new account in sam:'+e.getMessage();
				continue;
			}

			if(acc.Product__c != null){
				zqu__ZProduct__c product = mapProductToFeatures.get(acc.Product__c);
				if(product != null && product.getSObjects('zqu__ZProductFeatures__r') != null){
					List<zqu__ZProductFeature__c> lstProductFeatures = (List<zqu__ZProductFeature__c>)product.getSObjects('zqu__ZProductFeatures__r');
					Set<String> setEntitlements = new Set<String>();
					if(!lstProductFeatures.isEmpty()){
						for(zqu__ZProductFeature__c productFeature : lstProductFeatures){
							if(MAP_ENTITLEMENTS.containsKey(productFeature.zqu__ZFeature__r.Name)){
								setEntitlements.add(MAP_ENTITLEMENTS.get(productFeature.zqu__ZFeature__r.Name));
							}			
						}
					}
					if(!setEntitlements.isEmpty()){
						brr.sEntitlementsAdded = String.join(new List<String>(setEntitlements), ', ');
						try{
							blkResponseAdd = SAMInterfaceHTTP.updateSubscriptionEntitlement(acc.PersonEmail, acc.Guid__c, setEntitlements, SAMInterfaceHTTP.EntitlementUpdateType.ADD);
							if(blkResponseAdd.statusCode != null  && blkResponseAdd.statusCode == SAMInterfaceHTTP.ResponseStatusCodes.FAIL && blkResponseAdd.message != null){
								throw new TelegraphApplicationException(blkResponseAdd.message);
							}
							//[message=Username or password invalid, statusCode=FAIL] - response if no account
						}catch(Exception e){
							brr.sError += 'Failed to add new entitlements:'+e.getMessage();
							continue;
						}
					}else{
						brr.sError += 'Not able to identify entitlements based on account product.';
					}
				}else{
					brr.sError = 'Could not find product data for account in salesforce.';
				}
			}else{
				brr.sError += 'No product found in account product lookup.';
			}
			acc.Registrant_Entitlement_Sync_Completed__c = true;
		}
		try{
			AccountTriggerHandler.getInstance().bRunAPI = false;
			update scope;
			AccountTriggerHandler.getInstance().bRunAPI = true;
		}catch(DmlException e){
			for(Integer i = 0; i < e.getNumDml(); i++) {
                mapAccountIdToErrors.get(scope[e.getDmlIndex(i)].Id).sError += e.getDMLMessage(i);
            }
		}
		if(lstErrors.size() < ERROR_LIMIT){
			for(BatchRowResult brr : mapAccountIdToErrors.values()){
				if(String.isNotBlank(brr.sError) || String.isNotBlank(brr.sMessage)){
					this.lstErrors.add(brr);
				}
			}
		}
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created - 26/02/2015
	Version - 1.0
	Function - 	Implemented method from Schedulable interface 
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public void execute(SchedulableContext ctx) {
		Database.executeBatch(this, this.iBatchSize);
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date Created - 26/02/2015
	Version - 1.0
	Function - 	Implemented method from Batchable interface 
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	public void finish(Database.BatchableContext BC) {

		if(this.lstErrors.isEmpty()) return;
		
		General__c sendToIds = General__c.getInstance(GENERAL_REGISTRANT_SYNC_FAILURE_USER);
		if(sendToIds == null || String.isBlank(sendToIds.Value__c)) return;
		List<Id> lstTargetObjectId = new List<Id>();
		try{
			lstTargetObjectId  = sendToIds.Value__c.split(',');
		}catch(Exception e){
			throw new TelegraphApplicationException('Failed to retreive recipients.');
		}

		List<Messaging.SingleEmailMessage> lstMessages = new List<Messaging.SingleEmailMessage>();
		String sHtmlMessageContent = '';
		for(BatchRowResult row : this.lstErrors){
			sHtmlMessageContent  += '<tr><td>'+row.sTsNumber+'</td><td>'+row.accountId+'</td><td>'+row.sEmail+'</td><td>'+row.sEntitlementsRemoved+'</td><td>'+row.sEntitlementsAdded+'</td><td>'+row.sError+'</td><td>'+row.sMessage+'</td></tr>';
		}
		String sHtmlMessage = '<div><table width="100%"><tr><th>TSNumber</th><th>Account Id</th><th>Email</th><th>Entitlements Removed</th><th>Entitlements Added</th><th>Errors</th><th>Messages</th></tr>'; 
		sHtmlMessage += sHtmlMessageContent;
		sHtmlMessage += '</table></div>';
		if(this.lstErrors.size() >= ERROR_LIMIT){
			sHtmlMessage += '<div>Error limit reached:'+ERROR_LIMIT+'</div>';
		}
		sHtmlMessage += '';
		for(Id userId : lstTargetObjectId){
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setTargetObjectId(userId);
			mail.setSenderDisplayName('TMG Registrant Fix Batch');
			mail.setSubject('Errors within update.');
			mail.setHTMLBody(sHtmlMessage);
			mail.setSaveAsActivity(false);
			lstMessages.add(mail);
		}
		if(!lstMessages.isEmpty()){
			try{
				Messaging.sendEmail(lstMessages);
			}catch(Exception e){}
		}
	}

	/**
	* @author Wiktor Czykin
	* @date 26/02/2016
	* @description Nested class to store log for batch 
	* ##########Change Log##########
	* Modified by     Version     Change Date 
	*/
	public class BatchRowResult{
		public String sTsNumber;
		public String sEmail;
		public String sEntitlementsRemoved;
		public String sEntitlementsAdded;
		public Id accountId;
		public String sError;
		public String sMessage;

		/*************************************************************************************** 
		Developer - Wiktor Czykin
		Date Created - 26/02/2015
		Version - 1.0
		Function - constructor - initializes params based on account
		#############Change Log#############
		Modified by     Version     Change Date
		****************************************************************************************/
		public BatchRowResult(Account acc){
			this.sTsNumber = acc.Subscriber_Number__c;
			this.sEmail = acc.PersonEmail;
			this.accountId = acc.Id;
			this.sError = '';
			this.sEntitlementsRemoved = '';
			this.sEntitlementsAdded = '';
			this.sMessage = '';
		}
	}
}