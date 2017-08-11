@isTest(SeeAllData=false)
private class UpdateSamTriggerTest {

    // This unit test is kind of arb as there is little we can check programmatically, most of it relies on visually checking the debug log
    public static testMethod void testUpdateSamUserDetails(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();

        Account a1 = setupAccount('Smith', 'N3');
        Account a2 = setupAccount('Jones', 'N3');
        Account a3 = setupAccount('Black', 'N3');
            
                
        // Test 1. No guid so SubscriberPortal.SUB_TRIGGER_FIRED will not be set to true
        System.assertEquals(false, SubscriberPortal.SUB_TRIGGER_FIRED);
        
        update a1;
        
        System.assertEquals(false, SubscriberPortal.SUB_TRIGGER_FIRED);
        
        // Test 3. Mimic a SAM-initiated update. Trigger shouldn't fire.
        SubscriberPortal.SUB_TRIGGER_FIRED = false;
        SubscriberPortal.SAM_WS_UPDATE = true;
        
        a3.guid__c = 'DEF';
        
        update a3;
        
        System.assertEquals(false, SubscriberPortal.SUB_TRIGGER_FIRED);
    }
    /*
    // This unit test is kind of arb as there is little we can check programmatically, most of it relies on visually checking the debug log
    public static testMethod void testUpdateSamSubscriptionDetails(){
        Account a1 = setupAccount('Smith', 'N3');
        Account a2 = setupAccount('Jones', 'N3');
        Account a3 = setupAccount('Black', 'N3');
        
        Subscription__c s1 = setupSub(a1,'Active');
            
        
        // Test 1. No change to sub so should not fire trigger
        System.assert(SubscriberPortal.SUB_TRIGGER_FIRED == false);
        //s1.Subscription_Status__c = 'In Renewal';
        
        update s1;
        
        System.assert(SubscriberPortal.SUB_TRIGGER_FIRED == false);
        
        // Test 2. Sub status change should be push = > trigger should have fired
        s1.Subscription_Status__c = 'In Renewal';
        
        update s1;
    }

    /* Utility Methods */
    public static Account setupAccount(String lname, String postcode){
        Account acc = new Account(Title__c='Mr.', lastname=lname, personmailingPostalCode=postcode);
        insert acc;
        
        acc = [SELECT id, lastname, personmailingpostalcode, Subscriber_Number_static__c FROM Account WHERE id = :acc.id];
        
        return acc;
    }
/*
    
    public static Subscription__c setupSub(Account acc, String status){
        //sms-473
        Date stDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
        return setupSub(acc, status, stDate);
    }
    
    public static Subscription__c setupSub(Account acc, String status, Date startDate){
        RecordType rt = [SELECT id FROM recordType WHERE name = 'Default'];
        Integer price;
        
        if(status.toUpperCase() == 'OFFERED')
            price = null;
        else
            price = 5;
        
        Subscription__c sub = new Subscription__c(Cancellation_Date__c=null,Cancellation_Method__c=null, Cancellation_Reason__c=null, start_date__c = startDate , Payment_Type__c = 'Cheque', Delivery_Type__c = 'OTC', Weekly_Price__c=price, Subscription_Status__c=status, Subscription_Duration_Picklist__c='26', Subscriber__c=acc.id, RecordTypeId=rt.id,Payment_Details_Received__c=true);
        insert sub;
        
        return sub;
    }*/
}