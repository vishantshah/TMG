/**
Name: SubscriptionStatusQueueableTest
* @author Michal Szewczyk
* @date 26/04/2016
* @description 	Tests for SubscriberEntitlementsQueueable
##########Change Log##########
Modified by     Change Date 
Wiktor Czykin	31/01/2017 //added testQueueableRunForRegistrant() method
*/
@isTest
private class SubscriberEntitlementsQueueableTest {
	
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 26/04/2016
    Version - 1.0
    Function - test Queueable logic
    #############Change Log#############
	Modified by     Version     Change Date
    ******************************************************************************************/
 	private static testMethod void testQueueableRunForPrint(){
		TestDataUtility td = new TestDataUtility(10);
		td.createSubscriptions();
		Set<Id> accIds = new Set<Id>();
		Integer i = 0;

		for(Account tmp: td.lstIndividualSubscribers) {
			accIds.add(tmp.Id);
			tmp.Guid__c ='guida'+i;
			i++;
		}

		AccountTriggerHandler.getInstance().isExecuting = true;
		update td.lstIndividualSubscribers;
		AccountTriggerHandler.getInstance().isExecuting = false;

		Test.startTest();
			//without any parameters
			List<SubscriberPortal.Subscriber> subscribers = SubscriberPortal.getSubscribers(accIds);
			List<SubscriptionsSAMWebservices.updateNotification> payload = new List<SubscriptionsSAMWebservices.updateNotification>();
			SubscriptionStatusQueueable ssq = new SubscriptionStatusQueueable(null, null);
			System.assertEquals(10, accIds.size());
			System.assertEquals(10, subscribers.size());
			for(SubscriberPortal.Subscriber s : subscribers){
			
				SubscriptionsSAMWebservices.updateNotification subUpdate = new SubscriptionsSAMWebservices.updateNotification();	
				if(s.entitlements.size() > 0){
					subUpdate.entitlements = String.join(s.entitlements, ',');
				}else{
					subUpdate.entitlements = null;
				}
				subUpdate.entitlements = '7DAY_SUBSCRIBER_ACTIVE';
				subUpdate.guid = s.guid;
				subUpdate.pid = s.pid;
				subUpdate.samServiceKey = 'SAMServiceKey';
				subUpdate.timeStamp = DateTime.now();

				SubscriptionsSAMWebservices.attributes_element attrs = new SubscriptionsSAMWebservices.attributes_element();
				String value = extractValue(s.attributes, 'EMAIL_ADDRESS');
				if(value != null){
					attrs.email = new SubscriptionsSAMWebservices.emailAttribute();
					attrs.email.value = value;
				}
				subUpdate.attributes = attrs;
				payload.add(subUpdate);
			}
			System.assertEquals(10, payload.size());
			System.enqueueJob(new SubscriberEntitlementsQueueable(10,payload,0));
		Test.stopTest();
		List<SubscriptionsSAMWebservices.updateNotification> serializedRecords = new List<SubscriptionsSAMWebservices.updateNotification>();
		for(SubscriptionsSAMWebservices.updateNotification tmp : payload) {
			serializedRecords.add(tmp);
		}
		SubscriberEntitlementsQueueable.callSamUpdateByQueueable(JSON.serialize(serializedRecords));
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 27/01/2017
    Version - 1.0
    Function - test Queueable logic for Registrants
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testQueueableRunForRegistrant(){
		TestDataUtility td = new TestDataUtility(4);
		td.checkAccountDependencies();
		td.createZSubscriptions();
		Set<Id> accIds = new Set<Id>();
		Integer i = 0;
		for(Account tmp: td.lstRegistrants) {
			accIds.add(tmp.Id);
			tmp.Guid__c ='guida'+i;
			i++;
		}
		AccountTriggerHandler.getInstance().isExecuting = true;
		update td.lstRegistrants;
		AccountTriggerHandler.getInstance().isExecuting = false;

		Test.startTest();
			List<SubscriberPortal.Subscriber> subscribers = SubscriberPortal.getSubscribers(accIds);
			List<SubscriptionsSAMWebservices.updateNotification> payload = new List<SubscriptionsSAMWebservices.updateNotification>();
			System.assertEquals(td.iCounter, accIds.size());
			System.assertEquals(td.iCounter, subscribers.size());
			for(SubscriberPortal.Subscriber s : subscribers){
			
				SubscriptionsSAMWebservices.updateNotification subUpdate = new SubscriptionsSAMWebservices.updateNotification();	
				if(s.entitlements.size() > 0){
					subUpdate.entitlements = String.join(s.entitlements, ',');
				}else{
					subUpdate.entitlements = null;
				}
				subUpdate.entitlements = '7DAY_SUBSCRIBER_ACTIVE';
				subUpdate.guid = s.guid;
				subUpdate.pid = s.pid;
				subUpdate.samServiceKey = 'SAMServiceKey';
				subUpdate.timeStamp = Datetime.now();

				SubscriptionsSAMWebservices.attributes_element attrs = new SubscriptionsSAMWebservices.attributes_element();
				String value = extractValue(s.attributes, 'EMAIL_ADDRESS');
				if(value != null){
					attrs.email = new SubscriptionsSAMWebservices.emailAttribute();
					attrs.email.value = value;
				}
				subUpdate.attributes = attrs;
				System.assert(String.isNotBlank(subUpdate.guid));
				payload.add(subUpdate);
			}
			System.assertEquals(td.iCounter, payload.size());
			SubscriberEntitlementsQueueable seq = new SubscriberEntitlementsQueueable(td.iCounter, payload, 0);
			seq.execute(null);
		Test.stopTest();
		List<WebService_Log__c> listWSL = [select Id, Event_Name__c, Method_Name__c from WebService_Log__c where Event_Name__c = :SubscriberEntitlementsQueueable.WL_REASON_REGISTRANT_RESYNC];
		System.assert(!listWSL.isEmpty());
		System.assertEquals(4, listWSL.size());
	}

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 26/04/2016
    Version - 1.0
    Function - helper method used in test
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static string extractValue(List<SubscriberPortal.KeyValuePair> pairs, string key){
		for(SubscriberPortal.KeyValuePair kvp : pairs){
			if(kvp.key == key)
				return (kvp.value == null || kvp.value.length() == 0) ? null : kvp.value;
		}
		return null;
	}

}