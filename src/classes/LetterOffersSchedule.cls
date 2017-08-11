global class LetterOffersSchedule implements Schedulable {
//SMS-467
global void execute(SchedulableContext sc) {
    	String query = '';
    	String fileName = '';
    	Integer randomHash = 0;
  
		//get all subs which has the specific task and the sub status is Offered
		query = 'Select subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName, subscriber__r.LastName, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where subscriber__c In :taskIDs and Subscription_Status__c = \'Offered\'';
		fileName = UtilitiesForSubscriptions.generateUniqueFileName('Coupon','csv');
		
        LetterOffersBatch batchable = new LetterOffersBatch(query, fileName);
        try {
            Id couponbatchID = Database.executeBatch(batchable);
        } catch(Exception ex) {}
}       

}