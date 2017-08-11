/**
* @author Unknown
* @date Unknown
* @description 	//This batch is interesting because I found that you cannot pass in queries to batch classes that are AggregatedResults, so you cannot use things like Group By
*				//The reason is because AggregatedResults cannot be used with Database.QueryLocator which is required in batch classes.
*				//A Solution is to set the query that is sent to the batch class without Group By and to pass all records to the batch which will then be batched in groups of 200 and traverse through each record. The likelihood is that an extra soql/s will be required
*				//in the batch class to get the correct records to update but this shouldn't break limits
*				//Another solution is to set the query that is sent to the batch class without Group By, then have a separate soql within the batch class which is exactly the same as the soql sent to the batch class but this time with the Group By
*				//By using both results of the soqls in-conjunction with each other you can mimic using AggregatedResults with batch classes
*				//The only thing that needs to be remembered is that the new soql using Group By within the batch class must adhere to governor limits. If this causes an issue there are tricks you can use, such
*				//as using Limit 50000 and storing the CreatedDate of the last record and then requiring for the next 50000 records after the last CreatedDate
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         13/10/2015  //cleaned up, added flag to increase test coverage, added custom setting for email
**/
global class ActiveRetailerUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {

	@TestVisible private static Boolean TEST_FAIL = false;

	global final String query;
	global final String emailAddress;
	global String errors;
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         14/10/2015  //
    ****************************************************************************************/
	global ActiveRetailerUpdateBatch(String q) {
		query = q;
		General__c emailAddressRecord = General__c.getInstance(Constants.SUBSCRIPTION_STATUS_BATCH_ERROR_USERID);
		if(emailAddressRecord != null && String.isNotBlank(emailAddressRecord.Value__c)){
			this.emailAddress = emailAddressRecord.Value__c;
		}
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {		
		//only in testing makes sure the count from is the same from the alternative when added to the existing count in Account
		Date dt = date.Today();
		system.debug('query ' +query);
		
		return Database.getQueryLocator(query);
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - implementation of batch execute method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/10/2015  //added failure if
    ****************************************************************************************/
	global void execute(Database.BatchableContext bc, List<Sobject> scope) {
		
		Set<Id> rets = new Set<Id>();
		ID retacc;
		for (Sobject acc: scope){
			retacc = (ID)acc.get('Retailer__c');
			rets.add(retacc);
		}
		
		//this query group retailer with a count of active Subscriptions. Full descr why group by is used here is found at the header
		Date dt = Date.today();
		String query = 'select Retailer__c, Count(id) subCount from Subscription__c where Delivery_Type__c =\'HND\' and (Subscription_Status__c = \'Active\' or Subscription_Status__c = \'In Renewal\' or (Subscription_Status__c = \'Pending Cancellation\' and Cancellation_Date__c>:dt)) and Retailer__r.id in :rets group by Retailer__c';
		List<SObject> s = Database.query(query);		
		
		Map<Id, Integer> retrieveRetailers = new Map<Id, Integer>();
		for(Sobject eachsub: s){			
			retrieveRetailers.put((Id)eachsub.get('Retailer__c'), (Integer)eachsub.get('subCount'));
		}

		//get current value of Retailer_Active_Sub_Count__c for the retailers
		Map<Id, Account> retailers = new Map<Id, Account>([select Retailer_Active_Sub_Count__c from Account where id in : rets]);
		Account thisacc;
		Integer thisRetActive;
		Id thisRetID;
		for (SObject sub: scope){
			thisRetID = (Id)sub.get('Retailer__c');
			thisRetActive = retrieveRetailers.get(thisRetID);    //get the new count of active Subscriptions  for this retailer
			thisacc = retailers.get(thisRetID);					 //get this retailer to be updated outside the for loop
			thisacc.Retailer_Active_Sub_Count__c = thisRetActive; //update retailer with new count
			retailers.put(thisRetID,thisacc);
		}			
		
		//update all retailers
		List<Account> updateAccs = retailers.values();

		if(Test.isRunningTest() && TEST_FAIL){
			for(Account acc : updateAccs){
				acc.Name = null;
			}
		}

       	Database.SaveResult[] saveResults = Database.update(updateAccs, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults[i].isSuccess()) 
				errors += saveResults[i].getErrors()[0];
        }
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - implementation of batch finish method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         13/10/2015  //added checks if email address is set
    ****************************************************************************************/
	global void finish(Database.BatchableContext bc) {
		if (String.isNotBlank(this.errors) && String.isNotBlank(this.emailAddress)){
			TMGUtil.EmailUtil emailUtil = new TMGUtil.EmailUtil(new List<String>{this.emailAddress});
			emailUtil.plainTextBody(errors)
					.senderDisplayName('Active Retailer Update From Team Salesforce')
					.replyTo(this.emailAddress)
					.subject('Active Retailer Update Batch Process')
					.build()
					.sendEmail();
		}
	}	
}