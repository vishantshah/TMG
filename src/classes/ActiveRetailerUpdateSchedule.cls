global class ActiveRetailerUpdateSchedule implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		//get count of subscribers for each reatiler 
		//Run batch as a series of batches so that governor limits are not broken
    	String query = 'select Retailer__c, Retailer__r.Retailer_Active_Sub_Count__c from Subscription__c where Retailer__c != null and Delivery_Type__c =\'HND\' and (Subscription_Status__c = \'Active\' or Subscription_Status__c = \'In Renewal\' or (Subscription_Status__c = \'Pending Cancellation\' and Cancellation_Date__c>:dt)) Order By Retailer__c';
        try {
    		ActiveRetailerUpdateBatch batchable = new ActiveRetailerUpdateBatch(query);
            Id activeRetailersID = Database.executeBatch(batchable);
	    } catch(Exception ex){}

	}
}