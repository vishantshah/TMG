/**
* @author Unknown
* @date Unknown
* @description Scheduled for AccountUpdateBatch
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         14/10/2015  //moved here schedulerTest, increased api version. Not updating the logic as this class in no longer used regularly.
**/
@isTest(SeeAllData=false)
private class AccountUpdateBatchTest{

	static testMethod void AccountUpdatesTest1() {
		setupBatchData();
        Test.startTest();
			String query='Select Id, SRN__c, Subscriber_Number__c, Subscriber_Number_Static__c from Account where FirstName=\'Monty\' and LastName=\'PythonTest\'';
			String toAddress='steven.fouracre@telegraph.co.uk';
			String[] toAddresses = new String[]{toAddress};
			String replyToAddress='steven.fouracre@telegraph.co.uk';
			
			AccountUpdateBatch batchable = new AccountUpdateBatch(query, toAddress,replyToAddress);					
			Id AccountUpdateBatchId = Database.executeBatch(batchable);
			System.assert(AccountUpdateBatchId != null);
		Test.stopTest();
	}  	
	
	static testMethod void AccountUpdatesTest2() {
		setupBatchData();
	    Test.startTest();
			AccountUpdateScheduler c = new AccountUpdateScheduler();
			SchedulableContext sc;
			c.execute(sc);	
		Test.stopTest();    
	}
	
	static testMethod void AccountUpdateTestSchedule() {
		setupBatchData();
	    Test.startTest();
			String nextYear = String.valueof(Date.today().addYears(1).year());
			String jobId = System.schedule('AccountUpdatesScheduleTest'+Math.random(), '00 50 16 29 AUG ? '+nextYear, new AccountUpdateScheduler());
	        
	        CronTrigger ct = [Select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
	        
	        System.assertEquals('00 50 16 29 AUG ? '+nextYear,ct.CronExpression);

	        //verify that the job has not run
	        System.assertEquals(0, ct.TimesTriggered);
	        //Verify the next time the job will run
	        System.assertEquals(nextYear+'-08-29 16:50:00', String.valueOf(ct.NextFireTime));
	        System.assert(jobId != null);	
		Test.stopTest();    
	}
	      
	static testMethod void AccountUpdatesTestStart() {
		//set up data	
		setupBatchData();
	
	    Test.startTest();
				String query='Select Id, SRN__c, Subscriber_Number__c, Subscriber_Number_Static__c from Account where FirstName=\'Monty\' and LastName=\'PythonTest\'';
				String toAddress='steven.fouracre@telegraph.co.uk';
				String replyToAddress='steven.fouracre@telegraph.co.uk';
				AccountUpdateBatch batchable2 = new AccountUpdateBatch(query, toAddress,replyToAddress);					
				Database.BatchableContext bc;
				Database.QueryLocator AccountUpdateBatchList;
				AccountUpdateBatchList = batchable2.start(bc);
		Test.stopTest();    
	}
	      
	static testMethod void AccountUpdateTestExecute() {
		//set up data	
		setupBatchData();
	
	    Test.startTest();
			String query='Select Id, SRN__c, Subscriber_Number__c, Subscriber_Number_Static__c from Account where FirstName=\'Monty\' and LastName=\'PythonTest\'';
			String toAddress='steven.fouracre@telegraph.co.uk';
			String replyToAddress='steven.fouracre@telegraph.co.uk';
			AccountUpdateBatch batchable3 = new AccountUpdateBatch(query, toAddress,replyToAddress);					
			List<sObject> scope =  Database.query(query);
			Database.BatchableContext bc;
			batchable3.execute(bc,scope);
		Test.stopTest();    
			
	}
	
	static testMethod void AccountUpdateTestFinish() {
		//set up data	
		setupBatchData();
	    Test.startTest();
			String query='Select Id, SRN__c, Subscriber_Number__c, Subscriber_Number_Static__c from Account where FirstName=\'Monty\' and LastName=\'PythonTest\'';
			String toAddress='steven.fouracre@telegraph.co.uk';
			String replyToAddress='steven.fouracre@telegraph.co.uk';
			AccountUpdateBatch batchable3 = new AccountUpdateBatch(query, toAddress,replyToAddress);					
			Database.BatchableContext bc;
			batchable3.finish(bc);
		Test.stopTest();    
	}

	static testmethod void schedulerTest(){ 
		Test.startTest();
		String nextYear = String.valueof(date.Today().addYears(1).year());
		//Schedule the test job  
		String jobId = System.schedule('accountUpdateScheduler', 
		'00 50 16 29 AUG ? ' + nextYear, new AccountUpdateScheduler());
		CronTrigger ct = [Select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
		
		//verify that the expression are the same
		System.assertEquals('00 50 16 29 AUG ? ' + nextYear,ct.CronExpression);
		//verify that the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		//Verify the next time the job will run
		System.assertEquals(nextYear + '-08-29 16:50:00', String.valueOf(ct.NextFireTime));
		System.assert(jobId != null);
	 	Test.stopTest();
	} 

	static void setupBatchData(){
		String query='Select Id, SRN__c, Subscriber_Number__c, Subscriber_Number_Static__c from Account where FirstName=\'Monty\' and LastName=\'PythonTest\'';
		list<sobject> acc = new list<sobject>();
		acc = Database.query(query);
		
		list<Account> accs = new list<Account>();
		if (acc.size() == 0){
	        Account newaccountrecord1 = setupAccount('SW1W 0DT','5788768787X');
	        Account newaccountrecord2 = setupAccount('SD56 78U','5788768787Y');
	        Account newaccountrecord3 = setupAccount('SP96 78T','5788768787Z');
		}		
	}

    static Account setupAccount(String postcode,String subnumber) {
    	Account newaccountrecord = new Account(Subscriber_Number_static__c=subnumber,Title__c = 'Mr.', FirstName='Monty', LastName='PythonTest', PersonMailingStreet='Address line 1 \n Address Line 2 \n Address Line 3', PersonMailingCity='London', PersonMailingState='Westminster'
        										, PersonMailingPostalcode=postcode);
        insert newaccountrecord;
		system.debug('setupAccount ' + newaccountrecord);
        
        return newaccountrecord;
    }
}