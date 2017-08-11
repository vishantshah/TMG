/**
 * Ref:PP-1896
 *
 * A batch class to update the "Current_Week_Position_Final__c" field on Subscriptions which have status 'Pending Cancellation'
 * The batch picks up all such records from Subscriptions__c and updates those records satisfying the above condition.
 *
 * The batch is scheduled through the SubscriptionsCancellationScheduler scheduler class
 *
 * @see SubscriptionsCancellationScheduler
 */
global class SubscriptionsCancellationBatch implements Database.Batchable<sObject> {

    /** The query variable */
    global final String query;

    /** The place holder for any custom params being passed along with */
    global final Map<String, Object> customParams;

    
    /** 
     * Default constructor accepting the query to be executed to pick the scope objects
     * to be updated.
     *
     * @param query     the query to be executed
     */
    global SubscriptionsCancellationBatch(String query) {
        this.query = query; 
    }


    /** 
     * Overloaded constructor for any future modifications.
     * Accepts the query and any custom parameters required for any further modifications to the class.
     *
     * @param query     the query to be executed
     */
    global SubscriptionsCancellationBatch(String query, Map<String, Object> customParams) {
        this.query = query; 
        this.customParams = customParams;
    }


    /**
     * The default start() implementation
     *
     * @param BC    the Database.BatchableContext reference
     * @return the query locator for the query string as passed in the constructor
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }


    /** 
     * The default execute() implementation. This method updates the Current_Week_Position_Final__c field of the
     * records satisfying the criteria. 
     *
     * @param BC    the Database.BatchableContext reference
     * @param scope the list of scope objects as returned by the query
     */
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Subscription__c> updateList = new List<Subscription__c>();
        Date cancellationDate;
        Date startDate;
        Subscription__c sub;
        
        for(sObject s : scope) {
            sub = (Subscription__c) s;
            if(sub.Subscription_Status__c == 'Pending Cancellation') {
                cancellationDate = sub.Cancellation_Date__c;
                startDate = sub.Start_Date__c;
                sub.Current_Week_Position_Final__c = Math.ceil(cancellationDate.daysBetween(startDate) / 7);
                updateList.add(sub);
            }
            
            if(sub.Subscription_Status__c == 'Cancelled') {
                sub.Current_Week_Position_Final__c = sub.Current_Week_Position__c < 0 ? 0 : sub.Current_Week_Position__c;
                updateList.add(sub);
            } 
        }

        // only for testing fail conditions
        if(Test.isRunningTest()) {
            if(customParams != null && customParams.containsKey('TEST_EXCEPTION')) {
                throw new WebserviceUtil.NullParameterException('TESTING EXCEPTION', '');
            }
        }

        update updateList;
    }

   
    /** 
     * The default finish() implementation 
     */
    global void finish(Database.BatchableContext BC) {
    
    }
}