global class AccountUpdateBatch implements Database.Batchable<sObject> {
	
	global final String query;
	global final String toAddress;
	global final String replyToAddress;
		
	global AccountUpdateBatch(String q, String ta, String rta) {
		query = q;
		toAddress = ta;
		replyToAddress = rta;
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		SubscriberPortal.SAM_WS_UPDATE = true;
		for(sObject so: scope) {
			Account a = (Account)so;
			a.Subscriber_Number_static__c = '';
		}
		update scope;
	}
	
	global void finish(Database.BatchableContext bc) {
		if(String.isNotBlank(toAddress) && String.isNotBlank(replyToAddress)){
			List<String> toAddresses = new List<String> {toAddress};
			TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(toAddresses);
			emailUtil.plainTextBody('The batch apex is now complete.')
					.senderDisplayName('Telegraph Media Group SFDC')
					.replyTo(replyToAddress)
					.subject('Account Update Batch Apex Complete')
					.build()
					.sendEmail();  
		}
	}
}