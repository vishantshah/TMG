/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         26/02/2015  //added callSamForUpdateAsync()
Wiktor Czykin	1.2 		31/03/2015	//removed batch interface from the class and removed no longer used methods
Michal Szewczyk	1.3			24/04/2016  //changed callSamForUpdateAsync()
Wiktor Czykin	1.4			21/11/2016  //changed callSamForUpdateAsync()
Wiktor Czykin 	1.5			27/11/2016  //changed callSamForUpdateAsync()
Wiktor Czykin	1.6			31/01/2017	//removed callSamForSingleUpdate(), 
Wiktor Czykin 	1.7			10/02/2017  //changed callSamForUpdateAsync()
**/
global class UpdateSamUserDetailsBatch{
	
	global final Set<Id> Ids;
	global static Boolean UPDATE_EMAIL = true;
		
	global UpdateSamUserDetailsBatch(Set<Id> AccountIds) {
		this.Ids = AccountIds;
	}

	private static string extractValue(List<SubscriberPortal.KeyValuePair> pairs, string key){
		for(SubscriberPortal.KeyValuePair kvp : pairs){
			if(kvp.key == key)
				return (kvp.value == null || kvp.value.length() == 0) ? null : kvp.value;
		}
		return null;
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/02/2015
    Version - 1.4
    Function -  Copy paste of execute method. Batch execution replaced with future call 
    			as batches were blowing up the trigger because of the number of scheduled apex jobs limit.
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1			28/04/2016	 //added SubscriberEntitlementsQueueable call and change entitlements for more then one value
    Wiktor Czykin	1.2			21/11/2016	 //removed registrants from queueable
    Wiktor Czykin	1.3			29/11/2016 	 //added reset of Force_Entitlement_Update__c
    Wiktor Czykin	1.4			31/01/2017   //modified signature to handle run for registrants
    Wiktor Czykin	1.5			10/02/2017	 //modified so that registrant status is re-set based on subscriptions 
    ****************************************************************************************/
	@future(callout=true)
	public static void callSamForUpdateAsync(Set<Id> Ids, Boolean updateEmail, Boolean bRunForRegistrants){
		String SAMServiceKey = PlaneURL__c.getInstance('SAM').Login__c;
		String SAM_URL = PlaneURL__c.getInstance('SAM').URL__c;
		Set<String> setGuidsToUpdateEntitlements = new Set<String>();
		List<Account> lstAccounts = new List<Account>();
		List<Account> lstAccountsToUpdate = new List<Account>();//to update because of flag reset
		Set<Id> setRegistrantIds = new Set<Id>();//to update because of status resync
		Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		if(!bRunForRegistrants){
			lstAccounts = [select Id, Guid__c, RecordTypeId, Force_Entitlement_Update__c from Account where Id in :Ids and RecordTypeId != :registrantRecordTypeId];
		}else{
			lstAccounts = [select Id, Guid__c, RecordTypeId, Force_Entitlement_Update__c from Account where Id in :Ids];
		}

		for(Account acc : lstAccounts){
			if(String.isNotBlank(acc.Guid__c)){
				setGuidsToUpdateEntitlements.add(acc.Guid__c);
			}
			if(acc.Force_Entitlement_Update__c){
				lstAccountsToUpdate.add(new Account(Id = acc.Id, Force_Entitlement_Update__c = false));
			}
			if(acc.RecordTypeId == registrantRecordTypeId){
				setRegistrantIds.add(acc.Id);
			}
		}

		List<SubscriberPortal.Subscriber> subscribers = SubscriberPortal.getSubscribers(Ids);
		List<SubscriptionsSAMWebservices.updateNotification> payload = new List<SubscriptionsSAMWebservices.updateNotification>();
		List<SubscriptionsSAMWebservices.updateNotification> payloadwithEntitlements = new List<SubscriptionsSAMWebservices.updateNotification>();
		for(SubscriberPortal.Subscriber s : subscribers){
			if(s.guid == null) continue;
				
			// Add them to the array to call out to SAM
			SubscriptionsSAMWebservices.updateNotification subUpdate = new SubscriptionsSAMWebservices.updateNotification();	
			if(s.entitlements.size() > 0){
				subUpdate.entitlements = String.join(s.entitlements, ',');
			}else{
				subUpdate.entitlements = null;
			}

			subUpdate.guid = s.guid;
			subUpdate.pid = s.pid;
			subUpdate.samServiceKey = SAMServiceKey;
			subUpdate.timeStamp = Datetime.now();
			
			SubscriptionsSAMWebservices.attributes_element attrs = new SubscriptionsSAMWebservices.attributes_element();

			String value = extractValue(s.attributes, 'FIRST_NAME');
			if(value!= null){
				attrs.firstName = new SubscriptionsSAMWebservices.firstNameAttribute();
				attrs.firstName.value = value;
			}
			
			value = extractValue(s.attributes, 'LAST_NAME');
			if(value != null){			
				attrs.lastName = new SubscriptionsSAMWebservices.lastNameAttribute();
				attrs.lastName.value = value;
			}
			
			value = extractValue(s.attributes, 'TITLE');
			if(value != null){
				attrs.title = new SubscriptionsSAMWebservices.titleAttribute();
				attrs.title.value = value;
			}
			
			if(updateEmail == true){
				value = extractValue(s.attributes, 'EMAIL_ADDRESS');
				if(value != null){
					attrs.email = new SubscriptionsSAMWebservices.emailAttribute();
					attrs.email.value = value;
				}
			}

			value = extractValue(s.attributes, 'ADDRESS_LINE1');
			if(value != null){
				attrs.addressLine1 = new SubscriptionsSAMWebservices.addressLine1Attribute();
				attrs.addressLine1.value = value.replace('\n','|');
			}
			
			value = extractValue(s.attributes, 'ADDRESS_LINE3');
			if(value != null){
				attrs.addressLine3 = new SubscriptionsSAMWebservices.addressLine3Attribute();
				attrs.addressLine3.value = value;
			}
			
			value = extractValue(s.attributes, 'COUNTY');
			if(value != null){
				attrs.county = new SubscriptionsSAMWebservices.countyAttribute();
				attrs.county.value = value;
			}
			
			value = extractValue(s.attributes, 'POSTCODE');
			if(value != null){
				attrs.postcode = new SubscriptionsSAMWebservices.postcodeAttribute();
				attrs.postcode.value = value;
			}
			
			value = extractValue(s.attributes, 'COUNTRY');
			if(value != null){
				attrs.country = new SubscriptionsSAMWebservices.countryAttribute();
				attrs.country.value = value;
			}
			
			value = extractValue(s.attributes, 'HOME_PHONE');
			if(value != null){
				attrs.phoneNo = new SubscriptionsSAMWebservices.phoneNoAttribute();
				attrs.phoneNo.value = value;
			}
			
			value = extractValue(s.attributes, 'MOBILE_PHONE');
			if(value != null){
				attrs.mobilePhoneNo = new SubscriptionsSAMWebservices.mobilePhoneNoAttribute();
				attrs.mobilePhoneNo.value = value;
			}
			
			attrs.contactByEmail = new SubscriptionsSAMWebservices.contactByEmailAttribute();
			attrs.contactByEmail.value = boolean.valueOf(extractValue(s.attributes, 'CONTACT_BY_EMAIL'));
			attrs.contactByPost = new SubscriptionsSAMWebservices.contactByPostAttribute();
			attrs.contactByPost.value = boolean.valueOf(extractValue(s.attributes, 'CONTACT_BY_POST'));
			attrs.contactByPhone = new SubscriptionsSAMWebservices.contactByPhoneAttribute();
			attrs.contactByPhone.value = boolean.valueOf(extractValue(s.attributes, 'CONTACT_BY_PHONE'));
			attrs.contactBySms = new SubscriptionsSAMWebservices.contactBySmsAttribute();
			attrs.contactBySms.value = boolean.valueOf(extractValue(s.attributes, 'CONTACT_BY_SMS'));
			attrs.marketingOptIn3rd = new SubscriptionsSAMWebservices.marketingOptIn3rdAttribute();
			attrs.marketingOptIn3rd.value = boolean.valueOf(extractValue(s.attributes, 'MARKETING_OPT_IN_3RD'));
			attrs.tmgSalesforceSubscriptionId = new SubscriptionsSAMWebservices.tmgSalesforceSubscriptionIdAttribute();
			attrs.tmgSalesforceSubscriptionId.value = extractValue(s.attributes, 'TMG_SALESFORCE_SUBSCRIPTION_ID');
			attrs.tmgSubscribersOffersOptIn = new SubscriptionsSAMWebservices.tmgSubscribersOffersOptInAttribute();
			attrs.tmgSubscribersOffersOptIn.value = extractValue(s.attributes, 'TMG_SUBSCRIBERS_OFFERS_OPT_IN');

			subUpdate.attributes = attrs;
			if(setGuidsToUpdateEntitlements.contains(s.guid)){
				payloadwithEntitlements.add(subUpdate.clone());
			}
			subUpdate.entitlements = 'SALESFORCE';
			payload.add(subUpdate);
		}
		
		System.debug('### PAY_LOAD_SIZE: ' + payload.size());
		// Nothing to send
		if(!payload.isEmpty()){
			// This flag means we sent the data to SAM
			SubscriberPortal.SUB_TRIGGER_FIRED = true;
			SubscriptionsSAMWebservices.SalesforceServiceImplPort svc = new SubscriptionsSAMWebservices.SalesforceServiceImplPort();
			svc.endpoint_x = SAM_URL;
			
			if(!Test.isRunningTest()){
				svc.bulkUpdate(payload, Datetime.now().getTime() + '', SAMServiceKey);
				Id logId = TMGUtil.logWebServiceRequest('Outbound', svc.endpoint_x, 'bulkUpdate', new Map<string, object>{'payload.size' => payload.size()});
				if(payload.size() == 1){
					TMGUtil.logWebServiceDetail(logId, string.valueOf(payload));
				}
			}
		}

		AccountTriggerHandler.getInstance().isExecuting = true;
		if(!lstAccountsToUpdate.isEmpty()){
			Database.update(lstAccountsToUpdate, false);
		}
		if(!setRegistrantIds.isEmpty()){
			Map<Id,String> mapErrors = ZQuoteSubscriptionTriggerHandler.getInstance().resyncAccountDigitalStatus(setRegistrantIds);
			if(!mapErrors.isEmpty()){
				TMGUtil.logWebServiceRequestSerialized(Constants.DIRECTION_INBOUND, Constants.LOG_TRIGGER_ENDPOINT, Constants.LOG_TRIGGER_ZUORA_SUBSCRIPTION_ERROR+'-digital status sync in sam force sync', mapErrors);
			}
		}
		AccountTriggerHandler.getInstance().isExecuting = false;

		if(!payload.isEmpty()){
			if(!Test.isRunningTest()){
				System.enqueueJob(new SubscriberEntitlementsQueueable(200, payloadwithEntitlements,0));
			}
		}
	}

	public static void callSamToUpdateEntitlement(Set<String> samGUIDs, String entitlement,Set<Id> Ids, Boolean updateEmail){
	    List<string> guidsUpdated=new List<string>();
		
		Set<String> GUIDsToUpdate = new Set<String>();
		if(Ids.size() >0)
		{
			List<SubscriberPortal.Subscriber> subscribers = SubscriberPortal.getSubscribers(Ids);
			System.debug('### SUBSCRIBERS_SIZE: ' + subscribers.size());
			for(SubscriberPortal.Subscriber s : subscribers){
				if(s.guid == null)
					continue;
				GUIDsToUpdate.add(s.guid);
				guidsUpdated.add(s.guid);
			}
		}
		
		if(samGUIDs != null && !samGUIDs.isEmpty()){
			GUIDsToUpdate.addAll(samGUIDs);
			guidsUpdated.addAll(samGUIDs);
		}
		
		// Nothing to send
		System.debug(GUIDsToUpdate);
		if(GUIDsToUpdate.size() == 0)
			return;
		
		if(!Test.isRunningTest()){
			SAMInterfaceHTTP.callBulkUpdate(GUIDsToUpdate, entitlement);
			Id logId = TMGUtil.logWebServiceRequest('Outbound', SAMInterfaceHTTP.brokerUrl, 'callSamToUpdateEntitlement', new Map<string, object>{'payload.size' => GUIDsToUpdate.size(),'guidsUpdated' => guidsUpdated});
			if(GUIDsToUpdate.size() == 1)
				TMGUtil.logWebServiceDetail(logId, string.valueOf(GUIDsToUpdate));
		}	
	}	

}