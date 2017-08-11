/**
* @author Unknown
* @date Unknown
* @description Scheduled for AccountUpdateBatch
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         14/10/2015  //moved test method to AccountUpdateBatchTest
**/
global class AccountUpdateScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		
		String query = 'Select Id, SRN__c, Subscriber_Number__c, Subscriber_Number_Static__c from Account where SRN__c != null and Subscriber_Number_Static__c = null';
		String toAddress = 'anup.jadhav@telegraph.co.uk';
		String replyToAddress = 'anup.jadhav@telegraph.co.uk';
		
		
		AccountUpdateBatch batchable = new AccountUpdateBatch(query, toAddress, replyToAddress);
		try {
			Id accountUpdateBatchId = Database.executeBatch(batchable);
		} catch(Exception ex) {
			
			List<String> toAddresses = new List<String> {'anup.jadhav@telegraph.co.uk'};
			//use the new util class to send an email
			TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(toAddresses);
			emailUtil.plainTextBody('The scheduled job has been fubar\'ed.')
					 .senderDisplayName('Anup Jadhav')
					 .subject('Error Error: Don\'t Panic')
					 .replyTo(replyToAddress).build().sendEmail();
		
		}
	}
}