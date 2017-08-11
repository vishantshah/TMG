/**
 * This class contains unit tests for validating the behavior of 
 * Subscription_beforeUpd_SubStartDate trigger.
 * SMS-362
 */
@isTest(SeeAllData=false)
private class SubStartDateTriggerTest {

private static Date stDate;
    static testMethod void subStartDateTest() {
		//didnt use SubscriptionPaymentUtils because it requires to send a created subscription to the constructor which then creates a DD attached to the Sub  
		//sms-473
		stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
        
        //create test test data
        //To appease the Gods of governor limits test
        //this triggger with 300 records to see how much 
        //strain can this thing handle.        
        List<Account> accs = new List<Account>();
        for(Integer i = 0; i < 200; i++) {
        	Account acc = setupAccount('RG1 7JX');	
        	accs.add(acc);
        }
        insert accs;
        
        List<Subscription__c> subs = new List<Subscription__c>();
        for(Account acc : accs) {
        	Subscription__c sub = setupSub('Offered', acc);
        	subs.add(sub);
        }
        insert subs;
        
        Date stDate2 = stDate.addDays(7);
        
        //change the sub start date 
        subs = [Select Id, start_date__c from Subscription__c where Id in :subs];
        for(Subscription__c sub : subs) {
        	sub.subscription_status__c = 'Offered';
        	sub.start_date__c =  stDate2;
        }
        update subs;
    }
        
    //utility method
    static Account setupAccount(String postcode) {
    	Account newaccountrecord = new Account(name = 'Monty Python'+Math.random().format(), tdt__c = 'wibble');
               
        return newaccountrecord;
    }
    
    static Subscription__c setupSub(String status, Account newaccountrecord) {
    	Subscription__c newsubsrecord = new Subscription__c(
    							Payment_Details_Received__c = false,
                                Start_Date__c=stDate,
  	                            Subscriber__c = newaccountrecord.id,
  	                            subscription_status__c = status,
  	                            delivery_type__c = 'HNC',
  	                            weekly_price__c = 250,
  	                            payment_type__c = 'Direct Debit',
  	                            voucher_pack_duration__c = 50);
        
        
        return newsubsrecord;	
    }
}