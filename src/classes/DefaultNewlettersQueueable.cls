/************************************************************************************
Class Name   : DefaultNewlettersQueueable
Author       : Vishant Shah
Created Date : 28/02/2017
Function     : Queueable class to add default newsletters for Individual Subscriber accounts.
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class DefaultNewlettersQueueable implements Queueable, Database.AllowsCallouts {
    
    List<Account> scope = new List<Account>();
    
    @TestVisible private Integer DEFAULT_QUEUE_SIZE = 5;
    @TestVisible private Integer scopePointer { get; set; }
    @TestVisible private Integer iQueueSize   { get; set; }
    
    /************************************************************************************
    Method Name  : DefaultNewlettersQueueable (Constructor)
    Author       : Vishant Shah
    Created Date : 28/02/2017
    Description  : accepts list of Accounts, queuesize and current pointer position. also pre-fetches list of default newsletters
    Change Log   :
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public DefaultNewlettersQueueable(List<Account> accounts, Integer iQueueSize, Integer pointer){
        
        if ( !accounts.isEmpty() ) {
            this.scopePointer  = pointer != null ? pointer : 0;
            this.iQueueSize    = iQueueSize != null ? iQueueSize : DEFAULT_QUEUE_SIZE;
            scope              = accounts;
        }
    }
    
    /************************************************************************************
    Method Name  : execute
    Author       : Vishant Shah
    Created Date : 28/02/2017
    Description  : Adds default newsletter for the account, and queues new job if needed.
    Change Log   :
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public void execute(QueueableContext context) {
        Integer stopIndex  = scopePointer + iQueueSize;

        if(stopIndex > scope.size()) {
            stopIndex = scope.size();
        }
        
        for(Integer index = scopePointer; index < stopIndex; index++){
            DefaultNewsletterUtility.addDefaultNewsletter(scope[index]);
            scopePointer++;
        }
        
        if(stopIndex < scope.size()){
            System.enqueueJob(new DefaultNewlettersQueueable(scope, iQueueSize, scopePointer));
        }
    }
}