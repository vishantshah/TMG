@isTest(SeeAllData=false)
private class LetterOfferBatchTest {


static testMethod void LetterOffersTest1() { 
	//set up data	
	setupBatchData();

	
        //String testedCSV;
        Test.startTest();
			//1st test
			String query='Select subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName, subscriber__r.LastName, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where subscriber__c In :taskIDs and Subscription_Status__c = \'Offered\'';
			String toAddress='steven.fouracre@telegraph.co.uk';
			String[] toAddresses = new String[]{toAddress};
			String replyToAddress='steven.fouracre@telegraph.co.uk';
			String fileName = 'test.csv';
			
			LetterOffersBatch batchable = new LetterOffersBatch(query, fileName);					
			Id LetterOffersBatchId = Database.executeBatch(batchable);
			System.assert(LetterOffersBatchId != null);
			//testedCSV = batchable.eachRowOfCSV; 
		Test.stopTest();
			//String header = 'TS Number, Title, First Name, Last Name, Address Line 1, Address Line 2, Address Line 3, Postal Code, Weekly Price, CC 52 Weeks, CC 26 Weeks, First Monthly Price, Ongoing Monthly Price, Quarterly Price    ';
			//System.assert(true,testedCSV.length() > header.length());
			
}  	

static testMethod void LetterOffersTest2() {
	//set up data	
	setupBatchData();

    Test.startTest();
		//2nd test
		LetterOffersSchedule c = new LetterOffersSchedule();
		SchedulableContext sc;
		c.execute(sc);	
	Test.stopTest();    
}

static testMethod void LetterOffersTestSchedule() {
	//set up data	
	setupBatchData();

    Test.startTest();
			//3rd test
			String nextYear = String.valueof(date.Today().addYears(1).year());
			String jobId = System.schedule('LetterOffersScheduleTest'+Math.random(), '00 50 16 29 AUG ? '+nextYear, new LetterOffersSchedule());
	        
	        CronTrigger ct = [Select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
	        
	        System.assertEquals('00 50 16 29 AUG ? '+nextYear,ct.CronExpression);

	        //verify that the job has not run
	        System.assertEquals(0, ct.TimesTriggered);
	        //Verify the next time the job will run
	        System.assertEquals(nextYear+'-08-29 16:50:00', String.valueOf(ct.NextFireTime));
	        System.assert(jobId != null);	
	Test.stopTest();    
}
      
static testMethod void LetterOffersTestStart() {
	//set up data	
	setupBatchData();

    Test.startTest();
			//4th test			
			String query='Select subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName, subscriber__r.LastName, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where subscriber__c In :taskIDs and Subscription_Status__c = \'Offered\'';
			String fileName = 'test.csv';
			LetterOffersBatch batchable2 = new LetterOffersBatch(query, fileName);					
			Database.BatchableContext bc;
			Database.QueryLocator LetterOffersBatchList;
			LetterOffersBatchList = batchable2.start(bc);
			System.assertNotEquals(null,batchable2.taskIDs.size());
	Test.stopTest();    
}
      
static testMethod void LetterOffersTestExecute() {
	//set up data	
	setupBatchData();

    Test.startTest();
    //5th test
			String query='Select subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName, subscriber__r.LastName, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where subscriber__c In :taskIDs and Subscription_Status__c = \'Offered\'';
			String fileName = 'test.csv';
			LetterOffersBatch batchable3 = new LetterOffersBatch(query, fileName);					
			List<sObject> scope =  Database.query('Select subscriber__r.id,subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName, subscriber__r.LastName, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where Subscription_Status__c = \'Offered\' limit 5');
			Database.BatchableContext bc;
			batchable3.execute(bc,scope);
			System.assertNotEquals(null,batchable3.eachRowOfCSV.length());
	Test.stopTest();    
}

static testMethod void LetterOffersTestFinish() {
	//set up data	
	setupBatchData();

    Test.startTest();
		//6th test 
		String query='Select subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.FirstName, subscriber__r.LastName, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where subscriber__c In :taskIDs and Subscription_Status__c = \'Offered\'';
		String fileName = 'test.csv';
		
		insertOfferEmailRecipients();
		LetterOffersBatch batchable3 = new LetterOffersBatch(query, fileName);					
		
		
		Database.BatchableContext bc;
		system.debug('test LetterOffersTestFinish');
		batchable3.finish(bc);
	Test.stopTest();    
}

static private void insertOfferEmailRecipients(){
	//SMS-474
	  list<SubManagementDefaults__c> defaultOffer = new list<SubManagementDefaults__c>();
	  
	  defaultOffer = [Select ID__c,DefaultValue__c From SubManagementDefaults__c Where ID__c='OfferEmailRecipients'];
	  
	  SubManagementDefaults__c newSubManagementDefaults;
	  if (defaultOffer.size() == 0){
	    newSubManagementDefaults = new SubManagementDefaults__c(ID__c='OfferEmailRecipients',DefaultValue__c='steven.fouracre@telegraph.co.uk');
	    insert newSubManagementDefaults;
	    }
	    else{
	        defaultOffer[0].DefaultValue__c = 'steven.fouracre@telegraph.co.uk';
	        update defaultOffer;
	    }
	}
	
	static private void insertSpecificValidPrice(Decimal thisPrice){ 
	//SMS-474
	  list<ValidPrice__c> DefaultValidPrices = [Select Source__c, Price__c,CC_26_Weeks__c, CC_52_Weeks__c, First_Monthly_Price__c, Ongoing_Monthly_Price__c, Quarterly_Price__c From ValidPrice__c where Price__c=:thisPrice];
	  if (DefaultValidPrices.size() > 0)
	    delete DefaultValidPrices;
	  
	  ValidPrice__c newValidPrice;
	  try{
	    //NB: If calc of DD values changes tests using this data may fail
	    newValidPrice = new ValidPrice__c(Source__c='TMG', Price__c=thisPrice,CC_26_Weeks__c=169, CC_52_Weeks__c=338, First_Monthly_Price__c=28.24, Ongoing_Monthly_Price__c=28.16, Quarterly_Price__c=84.50);
	    insert newValidPrice;
	  }
	  catch (Exception e1){}
	}
	
	static void setupBatchData(){
		insertSpecificValidPrice(6.50);
		insertSpecificValidPrice(4.35);
		insertSpecificValidPrice(4.20);
		insertOfferEmailRecipients();
		
		Set<ID> taskIDs =  new Set<ID>();
		for (Task eachtask: [Select AccountId From Task where Reason_For_Call__c=:Constants.SUBSCRIPTION_LETTER_OFFER])
			taskIDs.add(eachtask.AccountId);
		
		list<sobject> s;
		if (taskIDs.size() > 0)
			s = Database.query('Select subscriber__r.id,subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where subscriber__c In :taskIDs and Subscription_Status__c = \'Offered\' limit 300');
		else
			s = Database.query('Select subscriber__r.id,subscriber__r.Subscriber_Number_static__c, subscriber__r.Salutation, subscriber__r.PersonMailingStreet, subscriber__r.PersonMailingCity, subscriber__r.PersonMailingState, subscriber__r.PersonMailingPostalCode, Weekly_Price__c From Subscription__c where Subscription_Status__c = \'Offered\' limit 300');
		
		list<Subscription__c> subs= (list<Subscription__c>)s;
		if (subs.size() == 0)
			subs = new list<Subscription__c>();
		
		if (subs.size() == 0){
	        Account newaccountrecord1 = setupAccount('SW1W 0DT');
	        system.debug('setupSub Account1 6.50 ' + newaccountrecord1);
	        Subscription__c newsubsrecord1 = setupSub('Offered', newaccountrecord1,6.50);
	        system.debug('setupSub Account2 ' + newsubsrecord1);
	 
	        Account newaccountrecord2 = setupAccount('SD56 78U');
	        system.debug('setupSub Account3 4.35' + newaccountrecord2);
	        Subscription__c newsubsrecord2 = setupSub('Offered', newaccountrecord2,4.35);
			system.debug('setupSub Account4 ' + newaccountrecord2);
			
	        Account newaccountrecord3 = setupAccount('SP96 78T');
	        system.debug('setupSub Account4 4.20' + newaccountrecord3);
	        Subscription__c newsubsrecord3 = setupSub('Offered', newaccountrecord3,4.20);

			Task newtaskrecord1 = setupTask(newaccountrecord1.id);
			Task newtaskrecord2 = setupTask(newaccountrecord2.id);
			Task newtaskrecord3 = setupTask(newaccountrecord3.id);
			
			subs.add(newsubsrecord1);
			subs.add(newsubsrecord2);
			subs.add(newsubsrecord3);
		}
		
		list<Task> tkList = new list<Task>();
		for (Subscription__c eachsub: subs){
			Task tk = new Task(WhatId= eachsub.subscriber__r.id,Reason_For_Call__c=Constants.SUBSCRIPTION_LETTER_OFFER);
			tkList.add(tk);
		}
				insert tkList;
		
		system.debug(subs[0].subscriber__r.Subscriber_Number_static__c);
		
		list<Task> newtk = [Select AccountId From Task where Reason_For_Call__c=:Constants.SUBSCRIPTION_LETTER_OFFER];
		system.debug('list size ' + newtk.size());
	}

    static Account setupAccount(String postcode) {
    	Account newaccountrecord = new Account(Title__c = 'Mr.', FirstName='Monty', LastName='Python', PersonMailingStreet='Address line 1 \n Address Line 2 \n Address Line 3', PersonMailingCity='London', PersonMailingState='Westminster'
        										, PersonMailingPostalcode=postcode);
        insert newaccountrecord;
        
        return newaccountrecord;
    }
    
    static Subscription__c setupSub(String status, Account newaccountrecord, Decimal weeklyprice) {
    	//didnt use SubscriptionPaymentUtils because it requires to send a created subscription to the constructor which then creates a DD attached to the Sub  
    	//sms-473
    	Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
    	
    	Subscription__c newsubsrecord = new Subscription__c(
  	                            Payment_Details_Received__c = false,
                                Start_Date__c=stDate,
  	                            Subscriber__c = newaccountrecord.id,
  	                            subscription_status__c = status,
  	                            delivery_type__c = 'OTC',
  	                            weekly_price__c = weeklyprice,
  	                            payment_type__c = 'Direct Debit',
  	                            voucher_pack_duration__c = 50);
        
        insert newsubsrecord; 
        return newsubsrecord;	
    }
     
    static Task setupTask(Id newaccountrecord) {
    		Task tk = new Task(WhatId=newaccountrecord,Reason_For_Call__c=Constants.SUBSCRIPTION_LETTER_OFFER, Subject='acquisition details');
			insert tk;
			
			return tk;
    }
}