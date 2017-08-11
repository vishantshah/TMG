global class LetterOffersBatch implements Database.Batchable<sObject>, Database.Stateful {
//SMS-467
	global final String query;
	global List<String> toAddresses;
	global final String replyToAddress;
	global final String fileName;
	
	//global List<String> couponLetterRecordList = new List<String>();
	global Set<ID> taskIDs;
	global Map<Double,ValidPrice__c> prices;
	global String eachRowOfCSV;
	global String buildRowsOfCSV;
	
	global LetterOffersBatch(String q, String newFile) { 
		query = q;
		
		eachRowOfCSV ='';
			prices = new Map<Double,ValidPrice__c>();
			for (ValidPrice__c vp: [Select Price__c, CC_52_Weeks__c, CC_26_Weeks__c, First_Monthly_Price__c, Ongoing_Monthly_Price__c, Quarterly_Price__c From ValidPrice__c]) 
				prices.put(vp.Price__c, vp);
			
			system.debug('vp prices ' + prices);
			toAddresses = new List<String>(); 
			list<SubManagementDefaults__c> offerEmailRecipients = [Select DefaultValue__c From SubManagementDefaults__c Where ID__c='OfferEmailRecipients'];
			if (offerEmailRecipients.size() == 1 && offerEmailRecipients[0].DefaultValue__c.Contains('@'))
				toAddresses = offerEmailRecipients[0].DefaultValue__c.split(',');
			else
				toAddresses.add(Constants.TEAMSALESFORCE_EMAIL);
				
		replyToAddress = Constants.TEAMSALESFORCE_EMAIL;		
		fileName = newFile;		
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {		
		taskIDs =  new Set<ID>();
		for (Task eachtask: [Select AccountId From Task where (Reason_For_Call__c=:Constants.SUBSCRIPTION_LETTER_OFFER or Reason_For_Call__c=:Constants.SUBSCRIPTION_EMAIL_AND_LETTER_OFFER) and Status='Not Started'])
			taskIDs.add(eachtask.AccountId);
			
		return Database.getQueryLocator(query);
	} 
	 
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		list<Subscription__c> subs = (list<Subscription__c>)scope;
		ValidPrice__c thisVP;
		system.debug('vp prices ' + prices);
		if (subs.size() > 0) {
			String CC52, CC26, firstmonth, ongoingmonth, quarter, stateAddress,mailingStreet,mailingCity;
			for(Subscription__c sub : subs) {
				thisVP = prices.get(sub.Weekly_Price__c);
				//if thisVp is null
				stateAddress = sub.subscriber__r.PersonMailingState;
				if (stateAddress == null)
					stateAddress = ' ';
				else
					stateAddress = stateAddress.replaceall(',',' ');
				
				//if statements because sandboxes can have bad data in them so without these the batch would fail but is unlikely to fail in live but could do
				if (sub.subscriber__r.PersonMailingStreet == null)
					mailingStreet = ' ';
				else
					mailingStreet = sub.subscriber__r.PersonMailingStreet.replaceall('[,\r\n]',' ');
						
				if (sub.subscriber__r.PersonMailingCity == null)
					mailingCity = ' ';
				else
					mailingCity = sub.subscriber__r.PersonMailingCity.replaceall('[,\r\n]',' ');
						
				if (thisVP == null){
					CC52 = ''; 
					CC26 = '';
					firstmonth = '';
					ongoingmonth = '';
					quarter = '';
				}
				else{
					CC52 = String.valueof(thisVP.CC_52_Weeks__c); 
					CC26 = String.valueof(thisVP.CC_26_Weeks__c);
					firstmonth = String.valueof(thisVP.First_Monthly_Price__c); 
					ongoingmonth = String.valueof(thisVP.Ongoing_Monthly_Price__c); 
					quarter = String.valueof(thisVP.Quarterly_Price__c);
				}
				system.debug('thisVP ' + sub.subscriber__r.Subscriber_Number_static__c + ',' + sub.subscriber__r.Salutation + ',' + sub.subscriber__r.FirstName + ',' + sub.subscriber__r.LastName + ',' + sub.subscriber__r.PersonMailingStreet + ',' + sub.subscriber__r.PersonMailingCity + ',' + stateAddress + ',' + sub.subscriber__r.PersonMailingPostalCode + ',' + sub.Weekly_Price__c  + ' ' +  sub + ' ' + stateAddress  + ' ' + CC52  + ' ' + thisVP +' ' + sub.Weekly_Price__c);
	
				eachRowOfCSV += sub.subscriber__r.Subscriber_Number_static__c + ',' + sub.subscriber__r.Salutation + ',' + sub.subscriber__r.FirstName + ',' + sub.subscriber__r.LastName + ',' + mailingStreet + ',' + mailingCity + ',' + stateAddress + ',' + sub.subscriber__r.PersonMailingPostalCode + ',' + sub.Weekly_Price__c  + ',' + CC52 + ',' + CC26 + ',' + firstmonth + ',' + ongoingmonth + ',' + quarter + '\n';
			}
		}
	}

	global void finish(Database.BatchableContext bc) {
		//use the new util class to send an email
		TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(toAddresses);
		
		if (eachRowOfCSV != null && eachRowOfCSV != ''){
			buildRowsOfCSV = 'TS Number, Title, First Name, Last Name, Address Line 1, Address Line 2, Address Line 3, Postal Code, Weekly Price, CC 52 Weeks, CC 26 Weeks, First Monthly Price, Ongoing Monthly Price, Quarterly Price'+'\n';
			buildRowsOfCSV += eachRowOfCSV;

			List<Messaging.Emailfileattachment> fileAttachments = UtilitiesForSubscriptions.createEmailAttachment(buildRowsOfCSV,fileName);
			
			emailUtil.plainTextBody('IMPORTANT - Before doing a mail merge and printing the letters you must make sure that this email has not been sent from the Sandbox. To confirm this ensure that you do NOT see the word Sandbox in the subject of the email. The Coupon Offers csv file is attached.')
					.senderDisplayName('Coupon Offers From Team Salesforce')
					.replyTo(replyToAddress)
					.subject('Please mail merge these Coupon Offers')
					.fileAttachments(fileAttachments)
					.build()
					.sendEmail();
		}
		
	}
		
}