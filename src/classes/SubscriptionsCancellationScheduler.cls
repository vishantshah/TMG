/**
 * The scheduler class for SubscriptionsCancellationBatch
 * @see SubscriptionsCancellationBatch
 */
global class SubscriptionsCancellationScheduler implements Schedulable {
    
    /** The query variable to pick the records from Susbcription__c satisfying the criteria of:
     * Subscription_Status__c = 'Pending Cancellation'
     */
    final String query = 'SELECT Id, Subscription_Status__c, Current_Week_Position__c, Cancellation_Date__c, Start_Date__c'
                         + ' FROM Subscription__c'
                         + ' WHERE Subscription_Status__c IN (\'Pending Cancellation\', \'Cancelled\')'
                         + ' AND Cancellation_Date__c <= TODAY'; 
    
    /**
     * The default execute() implementation to schedule the batch class.
     *
     * @param sc    the default SchedulableContext reference  
     */
    global void execute(SchedulableContext sc) {
        try {
            //create the batch and execute it
            SubscriptionsCancellationBatch batch = new SubscriptionsCancellationBatch(query);       
            Database.executeBatch(batch);
        } catch(Exception ex) { 
            // in case of any exception re-schedule the batch to run
            //ExceptionHandler.scheduleOnException('SubscriptionsCancellationScheduler:', new SubscriptionsCancellationScheduler());
        }
    }
}