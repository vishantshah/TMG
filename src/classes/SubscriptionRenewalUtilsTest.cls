/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         02/03/2015  //modified setupSub()
Wiktor Czykin	1.2   		09/03/2015	//modified test methods so that they do not blow up after payment objects triggers de-activation
**/
@isTest(SeeAllData=false)
private class SubscriptionRenewalUtilsTest {

    static testMethod void testGetSubscriptionType() {
        // 1. Negative - null parm
	        String sType = SubscriptionRenewalUtils.getSubscriptionType(null);
	        System.assertEquals(sType, null);
        
        // 2. Positive - CC Sub
	        Account subscriber = setupAccount('test','n8');
	        Subscription__C sub = setupSub(subscriber, Constants.SSTATUS_ACTIVE);
	        sType = SubscriptionRenewalUtils.getSubscriptionType(sub);
	        System.assert(sType.contains('Week'));
        
        
       
    }
    
    static testMethod void testGetShowStartDate() {
    	// 1. Negative test - null sub	
	        Boolean show = SubscriptionRenewalUtils.getShowStartDate(null);
	        System.assertEquals(show, null);
        
        // 2. Positive - not DD
 	        Account subscriber = setupAccount('test','n8');
	        Subscription__C sub = setupSub(subscriber, Constants.SSTATUS_ACTIVE);
	        show = SubscriptionRenewalUtils.getShowStartDate(sub);
	        System.assert(show);
			
		// 4. Positive - DD (pending)
			sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
			update sub;
			sub = [SELECT Voucher_Pack_Duration__c , Cancellation_Date__c, Cancellation_Method__c, Cancellation_Reason__c, start_date__c , Payment_Type__c , Delivery_Type__c , Weekly_Price__c, Subscription_Status__c, Subscription_Duration_Picklist__c, Subscriber__c, Payment_Details_Received__c FROM Subscription__c WHERE id = :sub.id];
			show = SubscriptionRenewalUtils.getShowStartDate(sub);
			System.assert(show);
    }
    
    static testMethod void testGetShowEndDate(){
    	// 1. Negative test - null sub	
	        Boolean show = SubscriptionRenewalUtils.getShowEndDate(null);
	        System.assertEquals(show, null);
        
        // 2. Positive - not DD
 	        Account subscriber = setupAccount('test','n8');
	        Subscription__C sub = setupSub(subscriber, Constants.SSTATUS_ACTIVE);
	        show = SubscriptionRenewalUtils.getShowEndDate(sub);
	        System.assert(show);
 	    	
    }
    
    static testMethod void testGetAllowRenewal(){
    	// 1. Negative test - null sub	
	        Boolean allow = SubscriptionRenewalUtils.getAllowRenewal(null, true);
	        System.assertEquals(allow, null);
	        
        // 2. Positive - not DD
 	        Account subscriber = setupAccount('test','n8');
	        Subscription__C sub = setupSub(subscriber, Constants.SSTATUS_IN_RENEWAL);
	        allow = SubscriptionRenewalUtils.getAllowRenewal(sub, true);
	        System.assert(allow);	
	       	 	                
    }
    
	/* 
	 * Utility Methods 
	*/
	
	public static Account setupAccount(String lname, String postcode){
		Account acc = new Account(Title__c='Mr.',lastname=lname, personmailingPostalCode=postcode);
		insert acc;
		
		acc = [SELECT id, lastname, personmailingpostalcode, subscriber_number_static__c FROM Account WHERE id = :acc.id];
		
		return acc;
	}
	
	public static Subscription__c setupSub(Account acc, String status){
		//sms-473
		Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
		return setupSub(acc, status, stDate);
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - generate data for tests 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         02/03/2015  //modified record type fetching as was throwing exceptions on deployment
    ****************************************************************************************/
	public static Subscription__c setupSub(Account acc, String status, Date startDate){
		Id rt = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName());
        System.assertNotEquals(null, rt);
		Integer price;
		
		if(status.toUpperCase() == 'OFFERED')
			price = null;
		else
			price = 5;
		
		Subscription__c sub = new Subscription__c(Voucher_Pack_Duration__c = 13, Cancellation_Date__c=null,Cancellation_Method__c=null, Cancellation_Reason__c=null, start_date__c = startDate , Payment_Type__c = Constants.SUB_PMETHOD_CC, Delivery_Type__c = 'OTC', Weekly_Price__c=price, Subscription_Status__c=status, Subscription_Duration_Picklist__c='52', Subscriber__c=acc.id, RecordTypeId=rt,Payment_Details_Received__c=true);
		insert sub;
		
		return sub;
	}	    
}