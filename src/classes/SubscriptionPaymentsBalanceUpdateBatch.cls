/************************************************************************************
Class Name   : SubscriptionPaymentsBalanceUpdateBatch
Author       : Mantas Grigaliunas
Created Date : 16/01/2016
Function     : Batch class to update subscriptions with 'DD Not Completed Payments Sum' from MPP Historical Transactions records
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*************************************************************************************/
public class SubscriptionPaymentsBalanceUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	public Map<String, String> mapFailedRecords = new Map<String, String>();
	
	public SubscriptionPaymentsBalanceUpdateBatch() {}
	
	/************************************************************************************
    Method Name  : start
    Developer    : Mantas Grigaliunas
    Created Date : 16/01/2016
    Function     : Class start method to query related records
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id, Subscription__c, Total_Price__c '
									  + 'FROM MPP_Transaction_History__c '
									  + 'WHERE DD_Payment_Completion_Date__c = TODAY '
                                      + 'AND Total_Price__c != NULL '
                                      + 'AND Subscription__c != NULL');
    }

	/************************************************************************************
    Method Name  : execute
    Developer    : Mantas Grigaliunas
    Created Date : 16/01/2016
    Function     : Class execute method to process the records and update the subscriptions with correct balance
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
   	public void execute(Database.BatchableContext BC, List<sObject> scope) {

       	try{

            List<MPP_Transaction_History__c> lstMppTransactions = (List<MPP_Transaction_History__c>)scope;
       		Map<Id, Decimal> ddPaymentsBalanceMap = new Map<Id, Decimal>();
       		List<Subscription__c> lstSubs = new List<Subscription__c>();

       		//declares map of subscription to sum of DD payments made 5 days ago
       		for(MPP_Transaction_History__c txn : lstMppTransactions){
       			Id subscriptionId = txn.Subscription__c;
       			Decimal amount = txn.Total_Price__c; 
       			if(ddPaymentsBalanceMap.get(subscriptionId) != null){
       				amount += ddPaymentsBalanceMap.get(subscriptionId);
       			}
       			ddPaymentsBalanceMap.put(subscriptionId, amount);
       		}

       		//retrieves all related subscriptions
       		if(ddPaymentsBalanceMap.size() > 0){
       			lstSubs = [ SELECT Id, DD_Not_Completed_Payments_Sum__c FROM Subscription__c WHERE Id IN : ddPaymentsBalanceMap.keySet()];
       			for(Subscription__c sub : lstSubs){
                    if(sub.DD_Not_Completed_Payments_Sum__c != null && sub.DD_Not_Completed_Payments_Sum__c > 0){
       				    sub.DD_Not_Completed_Payments_Sum__c -= ddPaymentsBalanceMap.get(sub.Id);
                    } 
                    if(sub.DD_Not_Completed_Payments_Sum__c < 0 || sub.DD_Not_Completed_Payments_Sum__c == null) {
                        sub.DD_Not_Completed_Payments_Sum__c = 0;
                    }
       			}	
       		}

       		//updates subscriptions with the new DD uncompleted payments balances
       		Database.SaveResult[] lstResults = Database.update(lstSubs, false);
            for(Integer i=0; i < lstResults.size(); i++){
                if(!lstResults[i].isSuccess()){
                    String errors = '';
                    for(Database.Error err : lstResults[i].getErrors()){
                       errors += err.getFields() + ', ' + err.getMessage() + '\n';
                    }
                    mapFailedRecords.put(lstSubs[i].Id, errors);
                }
            }
        } catch(Exception e){
            mapFailedRecords.put(e.getMessage(), e.getStackTraceString());
        }
	}
	
	/************************************************************************************
    Method Name  : finish
    Developer    : Mantas Grigaliunas
    Created Date : 16/01/2016
    Function     : Class finish method to send an email if any errors occured
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer         Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
	public void finish(Database.BatchableContext BC) {

        if(mapFailedRecords.size() > 0){

          	String htmlBody = 'The following error has occurred on SubscriptionPaymentsBalanceUpdateBatch run:<br/>';

          	String errorRows = '';
            for(Id res : mapFailedRecords.keySet()){
                errorRows += '<tr><td>' + res + '</td><td>' + mapFailedRecords.get(res) + '</td></tr>';
            }

            htmlBody += '<table><tr><td>Record ID</td><td>Errors</td></tr>' + errorRows + '</table>';

           	TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(new List<String>{Constants.MPP_LETTEREXTRACT_ADMINEMAIL_VALUE});
		    emailUtil.htmlBody(htmlBody)
				.subject('Error in SubscriptionPaymentsBalanceUpdateBatch')
				.build()
				.sendEmail();
        }   		
	}
}