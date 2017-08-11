/**
* @author Unknown
* @date Unknown
* @description Test class for SubscriptionTriggerHandler
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         11/02/2015  //moved here test method from GiftSubscriptionTriggerHandlerTest as that class was no longer required. 
                                        Modifications to few test methods to load test data from csv.
Wiktor Czykin   1.2         05/06/2015  //modified renewalPostageTest_AllChange() and renewalPostageTest_NoStartDateChange(),renewalPostageTest_HistoricStartDate()
Wiktor Czykin   1.3         08/06/2015  //added tests for startDateValidation();
Wiktor Czykin   1.4         15/06/2015  //added testStartDateValidationNegativeScenarioWithExtractTime()
Wiktor Czykin   1.5         16/07/2015  //added testStartDateMoveOnAcquisition() and modified start date validation exception tests
Cristina Anghenie1.6		11/09/2015	//add new method when subs moves from Pending Cancellation to Cancelled
Cristina Anghenie1.7		18/09/2015	//test incentive description update before subs status moves to pending
Wiktor Czykin	1.8			06/11/2015	//modified the way custom settings are loadeed across almost all methods
Wiktor Czykin	1.9			05/12/2015	//modified testStartDateValidationPositiveScenarios()
Wiktor Czykin	2.0			13/01/2016	//moved here and refactored methods related to multiple active subs validation
Wiktor Czykin   2.1         25/02/2016  //removed references to old TestDataUtility methods
Pawel Chrzanowski	2.2		29/03/2016	//added testTCodeProductRelationship()
Michal Szewczyk     2.3     28/04/2016  //changed testTCodeProductRelationship()
Pawel Chrzanowski   2.4     29/04/2016  //added testSetDefaultPlan()
Gavin Palmer        2.5     31/05/2016 // added validateAgainstProductPriceTest()
Gavin Palmer        2.6     17/06/2016 // modified testTCodeProductRelationship(), renewalPostageTest_AllChange() and testFindNextStartDatePositiveChangedLeadTime()
Michal Szewczyk     2.7     17/06/2016  //added testProductRemoval()
Pawel Chrzanowski   2.8     25/07/2016  //added updateOutboundRenewalCasesTest()
Wiktor Czykin   2.9         27/09/2016  //added testSetDefaultPlanWithProductPlanAndThenChangeProduct()
Wiktor Czykin   3.0         29/09/2016  //added testValidateUpdateAgainstProductPrice()
Pawel Chrzanowski 3.1       29/11/2016  modified updateOutboundRenewalCasesTest()
Pawel Chrzanowski 3.2       07/12/2016  modified updateOutboundRenewalCasesTest()
Vishant Shah      3.3       12/01/2017  removed testStartDateMoveOnAcquisition
Pawel Chrzanowski 3.4       28/02/2017  removed testSetDefaultPlanWithProductPlanAndThenChangeProduct()
Wiktor Czykin     3.5       31/03/2017  modified testTCodeProductRelationship()
Vishant Shah.               09/06/2017  added autoclose test methods
**/
@isTest
private class SubscriptionTriggerHandlerTest {
    private static final integer FIRST_CLASS_LEAD_TIME = 9;
    
    /*************************************************************************************** 
    Developer - Matt Hime
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void endDateOnInsertTest() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createDigitalSubscribers();
        
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = tdu.lstDigitalSubscribers[0].Id;
        subscription.Start_Date__c = Date.today();
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = 'Active';
        subscription.MPP_Pay_Schedule_End_Date__c = Date.today().addYears(1);
        
        insert subscription;
        
        Account subscriber = [select MPP_CurrentPayScheduleEndDate__c from account where id = :tdu.lstDigitalSubscribers[0].Id];
        System.assertEquals(subscription.MPP_Pay_Schedule_End_Date__c, subscriber.MPP_CurrentPayScheduleEndDate__c);
    }

    /*************************************************************************************** 
    Developer - Matt Hime
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void endDateOnUpdateTest() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createDigitalSubscribers();
        Account subscriber = tdu.lstDigitalSubscribers[0];
        subscriber.MPP_CurrentPayScheduleEndDate__c = date.today().addYears(-1);
        update subscriber;
        
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = date.today();
        subscription.Subscription_Status__c = 'Offered';
        subscription.MPP_Pay_Schedule_End_Date__c = date.today().addYears(1);
        
        insert subscription;
        
        //Should be no change
        subscriber = [select MPP_CurrentPayScheduleEndDate__c from account where id = :subscriber.Id];
        System.assertEquals(Date.today().addYears(-1), subscriber.MPP_CurrentPayScheduleEndDate__c);
        
        
        subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        update subscription;
        
        //Should have changed
        subscriber = [select MPP_CurrentPayScheduleEndDate__c from Account where id = :subscriber.Id];
        System.assertEquals(subscription.MPP_Pay_Schedule_End_Date__c, subscriber.MPP_CurrentPayScheduleEndDate__c);
    }
    
    /*************************************************************************************** 
    Developer - Matt Hime
    Date - Unknown
    Version - 1.1
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void renewalPostageTest_NoChanges() {
        TestDataUtility td = new TestDataUtility(1);
        td.createDigitalSubscribers();
        Account subscriber = td.lstDigitalSubscribers[0];
        
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = date.today().addDays(30);
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert subscription;
        
        Test.startTest();
        subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
        update subscription;
        Test.stopTest();
        
        subscription = [select Is_Fast_Track__c, Next_Voucher_Extraction_Override__c, Start_Date__c from Subscription__c where Id = :subscription.Id];
        System.assertEquals(false, subscription.Is_Fast_Track__c);
        System.assertEquals(date.today().addDays(30), subscription.Start_Date__c);
    }
    
    /*************************************************************************************** 
    Developer - Matt Hime
    Date - Unknown
    Version - 1.2
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         05/06/2015  //modified assertion for  Next_Voucher_Extraction_Override__c check
    Wiktor Czykin   1.2         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void renewalPostageTest_NoStartDateChange() {
        TestDataUtility td = new TestDataUtility(1);
        td.createDigitalSubscribers();
        Account subscriber = td.lstDigitalSubscribers[0];
        //create the original subscription
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = date.today().addYears(-1).addDays(3);
        insert subscription;
        
        Id prevSubId = subscription.Id;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Previous_Subscription__c = prevSubId;
        subscription.Start_Date__c = date.today().addDays(20);
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert subscription;
        
        subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
        update subscription;
        
        subscription = [select Is_Fast_Track__c, Next_Voucher_Extraction_Override__c, Start_Date__c from Subscription__c where Id = :subscription.Id];
        System.assertEquals(true, subscription.Is_Fast_Track__c);
        System.assertEquals(date.today().addDays(20), subscription.Start_Date__c);
        System.assertEquals(null, subscription.Next_Voucher_Extraction_Override__c);   
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - Unknown
    Version - 1.1
    Function - test that Is_Fast_Track__c is set back to false if does not apply
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void renewalPostageTestNegativeTestToCheckFeatureOffFlag() {
        TestDataUtility td = new TestDataUtility();
        td.createDigitalSubscribers();
        
        General__c firstClassFeature = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_FEATURE);
        System.assert(firstClassFeature!=null);
        firstClassFeature.Value_Boolean__c = false;
        update firstClassFeature;

        Account subscriber = td.lstDigitalSubscribers[0];
        //create the original subscription
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = Date.today().addYears(-1).addDays(3);
        insert subscription;
        
        Id prevSubId = subscription.Id;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Previous_Subscription__c = prevSubId;
        subscription.Start_Date__c = date.today().addDays(20);
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert subscription;
        
        Test.startTest();
            subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
            update subscription;
        Test.stopTest();
        
        subscription = [select Is_Fast_Track__c from Subscription__c where Id = :subscription.Id];
        System.assertNotEquals(true, subscription.Is_Fast_Track__c);
    }
    /*************************************************************************************** 
    Developer - Matt Hime (Tquila)
    Date - Unknown
    Version - 1.2
    Function - test that Is_Fast_Track__c is set back to false if does not apply
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/02/2015  //made sure test actually tests what it should. Previous subscription had to be added to meet the criteria.
    Wiktor Czykin   1.2         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void nonRenewalNotFastTrackedTest() {
        TestDataUtility td = new TestDataUtility();
        td.createDigitalSubscribers();
        
        Account subscriber = td.lstDigitalSubscribers[0];
        
        Subscription__c origSubscription = new Subscription__c();
        origSubscription.Subscriber__c = subscriber.Id;
        origSubscription.Start_Date__c = Date.today().addYears(-1).addDays(3);
        insert origSubscription;

        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = date.today().addDays(50);
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        subscription.Is_Fast_Track__c = true;
        subscription.Previous_Subscription__c = origSubscription.Id;
        insert subscription;
        
        Test.startTest();
            subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
            update subscription;
        Test.stopTest();

        subscription = [select Is_Fast_Track__c from Subscription__c where Id = :subscription.Id];
        System.assertEquals(false, subscription.Is_Fast_Track__c);
    
    }
    
    /*************************************************************************************** 
    Developer - Matt Hime (Tquila)
    Date - Unknown
    Version - 1.3
    Function - test that Is_Fast_Track__c is set and Start_Date__c is modified
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/02/2015  //made sure it goes into the '!=Monday' if by changing the lead time to 8 days
    Wiktor Czykin   1.2         05/06/2015  //modified assertion checking Next_Voucher_Extraction_Override__c
    Wiktor Czykin   1.2         25/02/2016  //removed reference to insertAccountDigital();
    Gavin Palmer    1.3         17/06/2016  // Added logic to stop tests failing on sundays
    ****************************************************************************************/
    static testMethod void renewalPostageTest_AllChange() {
        TestDataUtility td = new TestDataUtility();
        td.createDigitalSubscribers();
        
        General__c firstClassLeadTime = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        System.assert(firstClassLeadTime!=null);
        firstClassLeadTime.Value__c = '8';
        update firstClassLeadTime;
        
        Account subscriber = td.lstDigitalSubscribers[0];
        //create the original subscription
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = date.today().addYears(-1).addDays(3);
        insert subscription;
        
        Id prevSubId = subscription.Id;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Previous_Subscription__c = prevSubId;
        subscription.Start_Date__c = Date.today().addDays(4);
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert subscription;
        
        Test.startTest();
        subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
        update subscription;
        Test.stopTest();
        
        subscription = [select Is_Fast_Track__c, Next_Voucher_Extraction_Override__c, Start_Date__c from Subscription__c where Id = :subscription.Id];
        System.assertEquals(true, subscription.Is_Fast_Track__c);
        
        Date newValidDate = DateUtility.getDateOfNextNamedDay(date.today(), 'Sunday');//as lead time was changed to 8 it is now Sunday not Saturday
        System.assertEquals(null, subscription.Next_Voucher_Extraction_Override__c);

		Date newStartDate = newValidDate.addDays(Integer.valueOf(firstClassLeadTime.Value__c)); //Add lead time and wind to the next Monday if necessary
		if(DateUtility.DayOfWeek(newStartDate) != 'Monday'){
			newStartDate = DateUtility.getDateOfNextNamedDay(newStartDate, 'Monday');
		}
        if(DateUtility.DayOfWeek(Date.today()) == 'Sunday'){
            newStartDate = newStartDate.addDays(7);
        }
        System.assertEquals(newStartDate, subscription.Start_Date__c);
    }
    
    /*************************************************************************************** 
    Developer - Matt Hime
    Date - Unknown
    Version - 1.2
    Function - 
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         05/06/2015  //modified assertion for  Next_Voucher_Extraction_Override__c check
    Wiktor Czykin   1.2         25/02/2016  //removed reference to insertAccountDigital();
    ****************************************************************************************/
    static testMethod void renewalPostageTest_HistoricStartDate() {
        TestDataUtility td = new TestDataUtility(1);
        td.createDigitalSubscribers();
        
        Account subscriber = td.lstDigitalSubscribers[0];
        //create the original subscription
        Subscription__c subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Start_Date__c = date.today().addYears(-1).addDays(3);
        insert subscription;
        
        Id prevSubId = subscription.Id;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        subscription = new Subscription__c();
        subscription.Subscriber__c = subscriber.Id;
        subscription.Previous_Subscription__c = prevSubId;
        subscription.Start_Date__c = date.today().addDays(-30);
        subscription.Weekly_Price__c = 250;
        subscription.Payment_Type__c = 'Test';
        subscription.Delivery_Type__c = 'Test';
        subscription.Voucher_Pack_Duration__c = 1;
        subscription.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert subscription;
        
        Test.startTest();
        subscription.Subscription_Status__c = Constants.SSTATUS_PENDING;
        update subscription;
        Test.stopTest();
        
        subscription = [select Is_Fast_Track__c, Next_Voucher_Extraction_Override__c, Start_Date__c from Subscription__c where Id = :subscription.Id];
        System.assertEquals(true, subscription.Is_Fast_Track__c);
        
        Date nextSaturday = DateUtility.getDateOfNextNamedDay(date.today(), 'Saturday');
        System.assertEquals(null, subscription.Next_Voucher_Extraction_Override__c);

		Date newStartDate = nextSaturday.addDays(FIRST_CLASS_LEAD_TIME); //Add lead time and wind to the next Monday if necessary
		if(DateUtility.DayOfWeek(newStartDate) != 'Monday'){
			newStartDate = DateUtility.getDateOfNextNamedDay(newStartDate, 'Monday');
		}
        System.assertEquals(newStartDate, subscription.Start_Date__c);
    }
        
    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - test for findNextStartDate() method - positive scenario
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
    ****************************************************************************************/
    static testMethod void testFindNextStartDatePositive(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProductFeatures();
        td.checkAccountDependencies();
        
        General__c firstClassLeadTime = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        System.assert(firstClassLeadTime!=null);

        td.createSubscriptions();
        td.lstSubscriptions[0].Start_Date__c = Date.today().addYears(-1).addDays(3);
        update td.lstSubscriptions;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        Subscription__c newSub = TestDataUtility.newSubscripiton(2,  td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id,Date.today().addDays(4));
        newSub.Previous_Subscription__c = td.lstSubscriptions[0].Id;
        newSub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert newSub;
        List<Subscription__c> lstRefetched = [select Id, Name, Start_Date__c, if_Is_Renewal_Binary__c from Subscription__c where Id = :newSub.Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(1, lstRefetched.size());
        Test.startTest();
            Date dt = SubscriptionTriggerHandler.findNextStartDate(lstRefetched[0]);
        Test.stopTest();
        
        Date newValidDate = DateUtility.getDateOfNextNamedDay(Date.today(), 'Saturday');
        Date newStartDate = newValidDate.addDays(Integer.valueOf(firstClassLeadTime.Value__c));
        if(DateUtility.DayOfWeek(newStartDate) != 'Monday'){
            newStartDate = DateUtility.getDateOfNextNamedDay(newStartDate, 'Monday');
        }
        System.assertEquals(newStartDate, dt);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - test for findNextStartDate() method - negative scenario - no custom setting 
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
    ****************************************************************************************/
    static testMethod void testFindNextStartDateNegativeNoSettings(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProductFeatures();
        td.createSubscriptions();
        td.lstSubscriptions[0].Start_Date__c = Date.today().addYears(-1).addDays(3);
        update td.lstSubscriptions;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        Subscription__c newSub = TestDataUtility.newSubscripiton(2,  td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id,Date.today().addDays(4));
        newSub.Previous_Subscription__c = td.lstSubscriptions[0].Id;
        newSub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert newSub;
        List<Subscription__c> lstRefetched = [select Id, Name, Start_Date__c, if_Is_Renewal_Binary__c from Subscription__c where Id = :newSub.Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(1, lstRefetched.size());
       	delete td.lstGeneral;
        Test.startTest();
            Date dt = SubscriptionTriggerHandler.findNextStartDate(lstRefetched[0]);
        Test.stopTest();
        
        System.assertEquals(null, dt);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 25/02/2015
    Version - 1.0
    Function - test for findNextStartDate() method - negative scenario - one custom setting missing
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
    ****************************************************************************************/
    static testMethod void testFindNextStartDateNegativeSingleMissingSetting(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProductFeatures();
        td.checkAccountDependencies();
        General__c firstClassLeadTime = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        System.assert(firstClassLeadTime!=null);
        delete firstClassLeadTime;

        td.createSubscriptions();
        td.lstSubscriptions[0].Start_Date__c = Date.today().addYears(-1).addDays(3);
        update td.lstSubscriptions;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        Subscription__c newSub = TestDataUtility.newSubscripiton(2,  td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id,Date.today().addDays(4));
        newSub.Previous_Subscription__c = td.lstSubscriptions[0].Id;
        newSub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert newSub;
        List<Subscription__c> lstRefetched = [select Id, Name, Start_Date__c, if_Is_Renewal_Binary__c from Subscription__c where Id = :newSub.Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(1, lstRefetched.size());
        Test.startTest();
            Date dt = SubscriptionTriggerHandler.findNextStartDate(lstRefetched[0]);
        Test.stopTest();
        
        System.assertEquals(null, dt);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - Unknown
    Version - 1.0
    Function - test for findNextStartDate() method - positive scenario - changed custom setting 
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
    Gavin Palmer    1.3         17/06/2016  // Added logic to stop tests failing on sundays
    ****************************************************************************************/
    static testMethod void testFindNextStartDatePositiveChangedLeadTime() {
        TestDataUtility td = new TestDataUtility();
        td.createZProductFeatures();
        td.checkAccountDependencies();
        
        General__c firstClassLeadTime = General__c.getInstance(Constants.SUBSCRIPTION_RENEWAL_FIRST_CLASS_LEAD_TIME);
        System.assert(firstClassLeadTime!=null);
        firstClassLeadTime.Value__c = '8';
        update firstClassLeadTime;

        td.createSubscriptions();
        td.lstSubscriptions[0].Start_Date__c = Date.today().addYears(-1).addDays(3);
        update td.lstSubscriptions;
        
        //Create the renewal (defined as a subscription with a reference to the previous subscription)
        Subscription__c newSub = TestDataUtility.newSubscripiton(2,  td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id,Date.today().addDays(4));
        newSub.Previous_Subscription__c = td.lstSubscriptions[0].Id;
        newSub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        insert newSub;
        List<Subscription__c> lstRefetched = [select Id, Name, Start_Date__c, if_Is_Renewal_Binary__c from Subscription__c where Id = :newSub.Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(1, lstRefetched.size());
        
        Test.startTest();
            Date dt = SubscriptionTriggerHandler.findNextStartDate(lstRefetched[0]);
        Test.stopTest();

        Date newValidDate = DateUtility.getDateOfNextNamedDay(date.today(), 'Sunday');//as lead time was changed to 8 it is now Sunday not Saturday
        Date newStartDate = newValidDate.addDays(Integer.valueOf(firstClassLeadTime.Value__c)); //Add lead time and wind to the next Monday if necessary
        if(DateUtility.DayOfWeek(newStartDate) != 'Monday'){
            newStartDate = DateUtility.getDateOfNextNamedDay(newStartDate, 'Monday');
        }
        
        if(DateUtility.DayOfWeek(Date.today()) == 'Sunday'){
            newStartDate = newStartDate.addDays(7);
        }
        System.assertEquals(newStartDate, dt);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 08/06/2015
    Version - 1.1
    Function - test positive scenario where renewal subscription falls out of fast track and gets back to it
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			05/12/2015	//changed "back to fast track" scenario date subsctraction as was causing issues on Saturdays because of the getFirstStartDate() method
    ****************************************************************************************/
    private static testMethod void testStartDateValidationPositiveScenarios() {
        TestDataUtility tdu = new TestDataUtility(4);
        tdu.checkAccountDependencies();
        General__c exclusion = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
        System.assert(exclusion != null);
        delete exclusion;
        tdu.checkSubscriptionDependencies();

        Date firstDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);//+21
        List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
        for(Integer i = 0; i< 2; i++){
            Subscription__c sub = TestDataUtility.newSubscripiton(i, tdu.lstIndividualSubscribers[i].Id, tdu.lstRetailers[i].Id, firstDate.addYears(-1).addDays(-7));
            sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
            lstSubscriptions.add(sub);
        }
        insert lstSubscriptions;

        Subscription__c sub1 = TestDataUtility.newSubscripiton(2, tdu.lstIndividualSubscribers[0].Id, tdu.lstRetailers[0].Id, firstDate);
        Subscription__c sub2 = TestDataUtility.newSubscripiton(3, tdu.lstIndividualSubscribers[1].Id, tdu.lstRetailers[1].Id, firstDate);
        sub1.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        sub1.Previous_Subscription__c = lstSubscriptions[0].Id;
        sub2.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        sub2.Previous_Subscription__c = lstSubscriptions[1].Id;
        List<Subscription__c> lstSubscriptions2 = new List<Subscription__c>{sub1, sub2};
        insert lstSubscriptions2; 

        for(Subscription__c sub : lstSubscriptions2){
            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
        }
        update lstSubscriptions2;
        Test.startTest();
            //check that it is fast track and update to become outside fast track
            List<Subscription__c> lstRefetched = [select Id, Start_Date__c, Is_Fast_Track__c from Subscription__c where Id in:lstSubscriptions2];
            for(Subscription__c sub : lstRefetched){
                System.assert(sub.Is_Fast_Track__c);
                sub.Start_Date__c = sub.Start_Date__c.addDays(28);
            }
            update lstRefetched;

            //check that it is no longer fast track and update the Start Date to fall under the fast track again
            lstRefetched = [select Id, Start_Date__c, Is_Fast_Track__c from Subscription__c where Id in:lstSubscriptions2];
            for(Subscription__c sub : lstRefetched){
                System.assert(!sub.Is_Fast_Track__c);
                sub.Start_Date__c = sub.Start_Date__c.addDays(-28);
            }
            update lstRefetched;

            //check that the fast track is ticked again
            lstRefetched = [select Id, Start_Date__c, Is_Fast_Track__c, Next_Voucher_Extraction__c from Subscription__c where Id in:lstSubscriptions2];
            for(Subscription__c sub : lstRefetched){
                System.assert(sub.Is_Fast_Track__c, 'Date failed to become fast tracked:'+sub.Start_Date__c+', Next Voucher Extraction: '+sub.Next_Voucher_Extraction__c);
            }

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 10/06/2015
    Version - 1.0
    Function - test invalid Start_Date__C update scenario with exclusion profiles enabled //probably would be useful to add System.runAs here
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testStartDateValidationPositiveScenarioWithExclusion(){
        TestDataUtility td = new TestDataUtility(4);
        td.checkAccountDependencies();
        General__c exclusion = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
        System.assert(exclusion != null);
        td.checkSubscriptionDependencies();

        Date firstDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);//+21
        List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
        for(Integer i = 0; i< td.iCounter; i++){
            Subscription__c sub = TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id, firstDate.addYears(-1).addDays(-7));
            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
            lstSubscriptions.add(sub);
        }
        insert lstSubscriptions;

        Test.startTest();
            for(Subscription__c sub : lstSubscriptions){
                sub.Start_Date__c = firstDate;
            }
            try{
                update lstSubscriptions;
            }catch(Exception e){
                System.assert(false, 'exception thrown where should not be');
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 08/06/2015
    Version - 1.1
    Function - test negative scenario - trying to pull Start_Date__c before Next_Voucher_Extraction__c
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         16/07/2015  //modified data preparation because of new field update in trigger on insert with or update to Pending status
    ****************************************************************************************/
    private static testMethod void testStartDateValidationNegativeScenarios() {
        TestDataUtility td = new TestDataUtility(4);
        td.checkSubscriptionDependencies();

        Date firstDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);//+21
        List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
        for(Integer i = 0; i< td.iCounter; i++){
            Subscription__c sub = TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id, Date.today());
            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
            lstSubscriptions.add(sub);
        }
        insert lstSubscriptions;

        for(Subscription__c sub : lstSubscriptions){
            sub.Start_Date__c = Date.today().addDays(-40);
        }
        update lstSubscriptions;

        General__c exclusion = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
        System.assert(exclusion != null);
        delete exclusion;

        Test.startTest();
            for(Subscription__c sub : lstSubscriptions){
                sub.Start_Date__c = firstDate;
            }
            try{
                update lstSubscriptions;
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.X23_days_renewal_cannot_change_start_date_after_extraction));
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 10/06/2015
    Version - 1.1
    Function - test negative scenario when exclusion setting exists but not for the current profile
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         16/07/2015  //modified data preparation because of new field update in trigger on insert with or update to Pending status
    ****************************************************************************************/
    private static testMethod void testStartDateValidationNegativeScenarioWithExclusion() {
        TestDataUtility td = new TestDataUtility(4);
        td.checkSubscriptionDependencies();

        List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
        for(Integer i = 0; i< td.iCounter; i++){
            Subscription__c sub = TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id, Date.today());
            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
            lstSubscriptions.add(sub);
        }
        insert lstSubscriptions;

        for(Subscription__c sub : lstSubscriptions){
            sub.Start_Date__c = Date.today().addDays(-40);
        }
        update lstSubscriptions;

        General__c exclusion = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
        System.assert(exclusion != null);
        exclusion.Value__c = 'someprofilename';
        update exclusion;

        Test.startTest();
            for(Subscription__c sub : lstSubscriptions){
                sub.Start_Date__c = Date.today();
            }
            try{
                update lstSubscriptions;
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.X23_days_renewal_cannot_change_start_date_after_extraction));
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 15/06/2015
    Version - 1.1
    Function - test start date validation failure when update to start date past extraction time
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         16/07/2015  //modified data preparation because of new field update in trigger on insert with or update to Pending status
    ****************************************************************************************/
    private static testMethod void testStartDateValidationNegativeScenarioWithExtractTime(){
        TestDataUtility tdu = new TestDataUtility(4);
        tdu.checkSubscriptionDependencies();

        //insert with pending -> it will automatically push the Start Date forward
        List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
        for(Integer i = 0; i< tdu.iCounter; i++){
            Subscription__c sub = TestDataUtility.newSubscripiton(i, tdu.lstIndividualSubscribers[i].Id, tdu.lstRetailers[i].Id, Date.today());
            sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
            lstSubscriptions.add(sub);
        }
        insert lstSubscriptions;

        //move the start date 9 days to the future only to check the time condition (as Next_Voucher_Extraction__c formula is then set to Start_Date__c - 9) -> as u are system admin, validation for moving will not kick in
        for(Subscription__c sub : lstSubscriptions){
            sub.Start_Date__c = Date.today().addDays(9);
        }
        update lstSubscriptions;

        //remove the validation exclusion for system admin and run the update again which should now fail - as expected :)
        General__c exclusion = General__c.getInstance(Constants.GENERAL_SUBSCRIPTION_STARTDATEVALIDATION);
        System.assert(exclusion != null);
        delete exclusion;

        Time tBase = Datetime.now().addMinutes(-10).time();
        insert new General__c(Name = Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME, Value__c = tBase.hour()+Constants.SUBSCRIPTION_RENEWAL_EXTRACT_TIME_SPLIT+tBase.minute());
        
        Test.startTest();
            for(Subscription__c sub : lstSubscriptions){
                sub.Start_Date__c = Date.today();
            }
            try{
                update lstSubscriptions;
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.X23_days_renewal_cannot_change_start_date_after_extraction));
            }
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 15/06/2016
    Version - 1.0
    Function - test that check validation for Product removal 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testProductRemoval(){
        TestDataUtility td = new TestDataUtility(1);
        td.checkSubscriptionDependencies();
        td.createZProduct();
        List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
        for(Integer i = 0; i< td.iCounter; i++){
            Subscription__c sub = TestDataUtility.newSubscripiton(  i,
                                                                    td.lstIndividualSubscribers[i].Id, 
                                                                    td.lstRetailers[i].Id, 
                                                                    Date.today().addDays(-30));
            sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
            sub.Payment_Details_Received__c = true;
            sub.Product__c = td.lstZproducts[0].Id;
            lstSubscriptions.add(sub);
        }
        insert lstSubscriptions;

        Test.startTest();
            for(Subscription__c sub : lstSubscriptions){
                sub.Subscription_Status__c = Constants.SSTATUS_PENDING;
                sub.Product__c = null;
            }
            
            try{
                update lstSubscriptions;
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Subscriptions_Product_Missing));
            }
        Test.stopTest();
    }
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 11/09/2015
    Version - 1.0
    Function - test that changing status to cancelled will cancel MPP Payment schedule
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
    ****************************************************************************************/
    private static testMethod void testSubscriptionChangeToCancelled(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProductFeatures();
        td.createSubscriptions();
        td.lstSubscriptions[0].Subscription_Status__c = 'Pending';
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '1061';
        td.lstSubscriptions[0].Cancellation_Date__c = System.today().addDays(30);
    	td.lstSubscriptions[0].Cancellation_Reason__c = 'Test';
    	td.lstSubscriptions[0].Cancellation_Method__c = 'Email';
        update td.lstSubscriptions[0];
        
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(td.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_AMOUNT => '468',
                MPPWebserviceMocks.PARAM_NOSCHEDULES => '12',
                MPPWebserviceMocks.PARAM_CURRENCY => 'GBP',
                MPPWebserviceMocks.PARAM_PAYMENTSCHID => '1061'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
        	td.lstSubscriptions[0].Subscription_Status__c = 'Pending Cancellation';
        	try{
        		update td.lstSubscriptions[0];
        	}catch(Exception e){
        		System.assertEquals(null,e);
        	}
        Test.stopTest();
    }

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  Test multiple active subscriptions validation.
                Insert new subscription for a period already covered
        		by an active subscription. Verify that save is not allowed.
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         13/01/2016  //moved here from SubscriptionTriggerHandlerTest, refactored to use TestDataUtility
	****************************************************************************************/
	private static testmethod void testPreventMultipleActiveSubsTwoActive(){
        TestDataUtility td = new TestDataUtility(5);
		td.createSubscriptions();

        Test.startTest();
        	List<Subscription__c> lstOverlapping = new List<Subscription__c>();
        	for(Integer i = 0; i < td.iCounter; i++){
				lstOverlapping.add(TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id, null));
        	}

	        try {
	        	insert lstOverlapping; 
	        	System.assert(false, 'Exception not thrown where should be.');
	        }catch(DmlException e){
	        	System.assertEquals(td.iCounter, e.getNumDml());
	        	for(Integer i = 0; i < td.iCounter; i++){
	        		System.assert(e.getDMLMessage(i).contains('Subscription cannot be saved with this start date. The subscriber already has an Active subscription covering all or part of this time period'));			
	        		System.assertEquals(Subscription__c.Start_Date__c, e.getDmlFields(i)[0], 'Exception on wrong field.');
	        	}
			}  
			for(Subscription__c sub : lstOverlapping){
        		sub.Start_Date__c=Date.today().addDays(400).toStartOfWeek();
        	}    
	        try{
	        	insert lstOverlapping;         	
	        }catch (DmlException e) {
			  	System.assert(false, 'Exception thrown where should not be.');       	   
			}        	                             
		Test.stopTest();                                                     
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 	Insert new subscription for a period already covered 
				by a pending cancellation subscription. Verify that save is 
			 	not allowed and that the cancellation date is used not the end date.
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         13/01/2016  //moved here from SubscriptionTriggerHandlerTest, refactored to use TestDataUtility
    Gavin Palmer    1.2         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
	****************************************************************************************/
	private static testmethod void testPreventMultipleActiveSubsOnePendingCancellationOneActive(){
		TestDataUtility td = new TestDataUtility();       
        td.createZProductFeatures();
        td.createSubscriptions();

        for(Subscription__c sub : td.lstSubscriptions){
        	sub.Subscription_Status__c = Constants.SSTATUS_PENDING_CANX;
        	sub.Cancellation_Date__c = Date.today().addDays(60).toStartOfWeek();
        	sub.Cancellation_Method__c='Phone';
        	sub.Cancellation_Reason__c='Distribution Problems';
        }
        update td.lstSubscriptions;

        List<Subscription__c> lstOverlapping = new List<Subscription__c>();
        for(Integer i = 0; i < td.iCounter; i++){
			lstOverlapping.add(TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id, null));    	
        }

        //start test by inserting a new subscription who's start date overlaps the existing Pending Cancellation subscription
        Test.startTest();
	        try{
	        	insert lstOverlapping; 
	        	System.assert(false, 'Exception not thrown where should be.');
	        }catch (DmlException e){
	        	System.assertEquals(td.iCounter, e.getNumDml());
	        	for(Integer i = 0; i < td.iCounter; i++){
	        		System.assert(e.getDMLMessage(i).contains('Subscription cannot be saved with this start date. The subscriber already has an Active subscription covering all or part of this time period'));			
	        		System.assertEquals(Subscription__c.Start_Date__c, e.getDmlFields(i)[0], 'Exception on wrong field.');
	        	}
			}              
			
			for(Subscription__c sub : lstOverlapping){
        		sub.Start_Date__c=Date.today().addDays(400).toStartOfWeek();
        	}    
	        try{
	        	insert lstOverlapping;         	
	        }catch (DmlException e) {
			  	System.assert(false, 'Exception thrown where should not be.');       	   
			}               	                                
		Test.stopTest();                                                     
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - 	Update an Offered subscription to become Active, for a 
		        period already covered by an existing active subscription. 
		        Verify that the save is not allowed.
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         13/01/2016  //moved here from SubscriptionTriggerHandlerTest, refactored to use TestDataUtility
	****************************************************************************************/
	private static testMethod void testPreventMultipleActiveSubsOfferedToActiveUpdate(){
        TestDataUtility td = new TestDataUtility(5);
        td.checkSubscriptionDependencies();

        List<Subscription__c> lstOffered = new List<Subscription__c>();
        for(Integer i = 0; i < td.iCounter; i++){
			Subscription__c sub = TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id, null);
			sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
			lstOffered.add(sub);
        }
        insert lstOffered;

        td.createSubscriptions();
        Test.startTest();
        	for(Subscription__c sub : lstOffered){
        		sub.Subscription_Status__c = Constants.SSTATUS_ACTIVE;
        	}

	        try{
	        	update lstOffered; 
	        	System.assert(false, 'Exception not thrown where should be.');
	        }catch (DmlException e) {
				System.assertEquals(td.iCounter, e.getNumDml());
	        	for(Integer i = 0; i < td.iCounter; i++){
	        		System.assert(e.getDMLMessage(i).contains('Subscription cannot be saved with this start date. The subscriber already has an Active subscription covering all or part of this time period'));			
	        		System.assertEquals(Subscription__c.Start_Date__c, e.getDmlFields(i)[0], 'Exception on wrong field.');
	        	}      	   
			}       
			
			for(Subscription__c sub : lstOffered){
				sub.Subscription_Status__c = Constants.SSTATUS_OFFERED;
        		sub.Start_Date__c=Date.today().addDays(400).toStartOfWeek();
        	}
        	update lstOffered;
			
			for(Subscription__c sub : lstOffered){
        		sub.Subscription_Status__c = Constants.SSTATUS_ACTIVE;
        	}
	        try {
	        	update lstOffered;         	
	        }catch (DmlException e) {
			  	System.assert(false, 'Exception thrown where should not be.');       	   
			}        	                                
		Test.stopTest();                                                     
    }
	
    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 29/03/2016
    Function -  test TCode_Product__c lookup relationship
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         28/04/2016 //added loadPlaneURL()
    Gavin Palmer    1.2         17/06/2016 //removed blanking out of product field so validation does not fire
    Wiktor Czykin   1.3         31/03/2017 //modified so that it works with temporary validation
    ****************************************************************************************/
    private static testMethod void testTCodeProductRelationship(){
        TestDataUtility td = new TestDataUtility(8);
        td.createSubscriptions();
        td.createTCodeProducts();
        List<PlaneURL__c> lstPlaneUrl = td.loadPlaneURL();
        Map<Id, Subscription__c> mapSubscriptions = new Map<Id, Subscription__c>();
        List<MidTermUpgradeProduct__c> upgradeProducts = new List<MidTermUpgradeProduct__c>();

        Map<String, String> mapNames = new Map<String, String>{ '2 Day Print' => '2 Day Complete',
                                                                '5 Day Print' => '5 Day Complete',
                                                                '6 Day Print' => '6 Day Complete',
                                                                '7 Day Print' => '7 Day Complete'
        };
        List<String> lstNames = new List<String>(mapNames.keySet());
        for(Integer i = 0; i<lstNames.size(); i++){
            td.lstZproducts[i].Name = lstNames[i];
        }
        Integer i = 4;
        for(String sName : mapNames.values()){
            td.lstZproducts[i].Name = sName;
            i++;
        }
        update td.lstZproducts;

        upgradeProducts.add(td.createMidTermUpgradeProduct(td.lstSubscriptions[0].Product__c, td.lstZproducts[4].Id));
        upgradeProducts.add(td.createMidTermUpgradeProduct(td.lstSubscriptions[1].Product__c, td.lstZproducts[5].Id));
        upgradeProducts.add(td.createMidTermUpgradeProduct(td.lstSubscriptions[2].Product__c, td.lstZproducts[6].Id));
        upgradeProducts.add(td.createMidTermUpgradeProduct(td.lstSubscriptions[3].Product__c, td.lstZproducts[7].Id));
        insert upgradeProducts;

        td.lstSubscriptions[0].TCode__c = td.lstTCodeManagement[0].Id;
        td.lstSubscriptions[0].Product__c = td.lstZproducts[0].Id;

        td.lstSubscriptions[1].TCode__c = td.lstTCodeManagement[1].Id;
        td.lstSubscriptions[1].Product__c = td.lstZproducts[1].Id;

        td.lstSubscriptions[2].TCode__c = td.lstTCodeManagement[2].Id;
        td.lstSubscriptions[2].Product__c = td.lstZproducts[2].Id;

        td.lstSubscriptions[3].TCode__c = null;

        td.lstSubscriptions[4].TCode__c = td.lstTCodeManagement[0].Id;
        td.lstSubscriptions[4].Product__c = td.lstZproducts[4].Id;

        td.lstSubscriptions[5].TCode__c = td.lstTCodeManagement[3].Id;

        update td.lstSubscriptions;
        List<Subscription__c> lstSubscriptions = [select TCode_Product__c from Subscription__c where TCode_Product__c != null];
        for(Subscription__c sub : lstSubscriptions){
            mapSubscriptions.put(sub.TCode_Product__c, sub);
        }

        System.assertEquals(td.lstTCodeProducts[0].Id, mapSubscriptions.get(td.lstTCodeProducts[0].Id).TCode_Product__c);
        System.assertEquals(td.lstTCodeProducts[1].Id, mapSubscriptions.get(td.lstTCodeProducts[1].Id).TCode_Product__c);
        System.assertEquals(td.lstTCodeProducts[2].Id, mapSubscriptions.get(td.lstTCodeProducts[2].Id).TCode_Product__c);
        System.assertEquals(null, mapSubscriptions.get(td.lstTCodeProducts[3].Id));
        System.assertEquals(null, mapSubscriptions.get(td.lstTCodeProducts[4].Id));
        System.assertEquals(null, mapSubscriptions.get(td.lstTCodeProducts[5].Id));
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 29/04/2016
    Function -  test SetDefaultPlan populating Plan__c
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         01/06/2016 // added createZProductFeatures() to stop null pointer thrown in SubscriberPortal
    ****************************************************************************************/
    private static testMethod void testSetDefaultPlan(){
        TestDataUtility td = new TestDataUtility(1);
        td.createPlans();
        td.createZProductFeatures();
        td.createDefaultSubscriptionPlanSettings(td.lstPlans[0].Id);
        td.createSubscriptions();

        Subscription__c sub = [select Plan__c from Subscription__c];
        System.assertEquals(td.lstPlans[0].Id, sub.Plan__c);
    }

    /***************************************************************************************
    Developer - Gavin Palmer    
    Date - 31/05/2016   
    Function -  test product price validation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testValidateAgainstProductPrice(){
        TestDataUtility testUtility = new TestDataUtility(1);
        testUtility.createProductPrice();
        testUtility.createZProductFeatures();
        

        TestDataUtility.enableProductPriceValidationSetting();

        testUtility.createSubscriptions();

        testUtility.lstSubscriptions[0].Weekly_Price__c = 500;

        Test.startTest();
        Database.SaveResult results = Database.update(testUtility.lstSubscriptions[0], false);
        Test.stopTest();

        System.assert(!results.isSuccess(), 'Validation rule has not fired');
        System.assert(TestDataUtility.checkIfErrorExists(results.getErrors(), Label.Subscription_Weekly_Price_Validation),'Correct validation has not fired');
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/06/2016
    Function - test product price validation - update scenario
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testValidateUpdateAgainstProductPrice(){
        TestDataUtility testUtility = new TestDataUtility(1);
        testUtility.createProductPrice();
        testUtility.createZProductFeatures();

        TestDataUtility.enableProductPriceValidationSetting();
        testUtility.createSubscriptions();

        List<Product_Price__c> lstProductPricesToDelete = [select Id from Product_Price__c where Price__c = :testUtility.lstSubscriptions[0].Weekly_Price__c];
        delete lstProductPricesToDelete;

        Test.startTest();
            Database.SaveResult results = Database.update(testUtility.lstSubscriptions[0], false);
            System.assert(results.isSuccess(), 'Validation rule has fired');

            testUtility.lstSubscriptions[0].Renewal_Price_Override__c = 400;
            testUtility.lstSubscriptions[0].Weekly_Price__c = 400;
            results = Database.update(testUtility.lstSubscriptions[0], false);
            System.assert(!results.isSuccess(), 'Validation rule has not fired');
            System.assert(TestDataUtility.checkIfErrorExists(results.getErrors(), Label.Subscription_Renewal_Price_Validation),'Correct validation has not fired');
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/07/2016   
    Function -  test updateOutboundRenewalCases
    #############Change Log#############
    Modified by       Version     Change Date
	Pawel Chrzanowski 1.1         29/11/2016  Changed status from 'Closed' to 'Completed'
	Pawel Chrzanowski 1.2         07/12/2016  Modified to reflect new Case validation
    ****************************************************************************************/
    private static testMethod void updateOutboundRenewalCasesTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();

        Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_SALES_RECORD_TYPE_NAME, Case.class.getName());
        insert new Case(Status=Constants.CASE_STATUS_NEW, Subject='s1', RecordTypeId=rtId, Print_Subscription__c=tdu.lstSubscriptions[0].Id);

        Test.startTest();
            insert new OCCaseAutoclose__c(SetupOwnerId=UserInfo.getOrganizationId(), Auto_Close_Cases__c=true);

            tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_WITHDRAWN;
            update tdu.lstSubscriptions[0];

            List<Case> lstCases = [select OC_Outcome__c, Status from Case];
            System.assertEquals(lstCases[0].OC_Outcome__c, Constants.CASE_OUTCOME_AUTO_COMPLETED);
            System.assertEquals(lstCases[0].Status, Constants.CASE_STATUS_COMPLETED);
        Test.stopTest();
        
    }

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 18/01/2016
    Function -  test updatesWhenProductChanged
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    private static testMethod void testUpdatesWhenProductChanged(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createTCodeProducts(); 
        
        List<zqu__zProduct__c> products = [SELECT Id, Name FROM zqu__zProduct__c];
        zqu__zProduct__c p1 = products[0];
        zqu__zProduct__c p2 = products[1];

        p1.LeadDays__c = '9';
        p1.Name = '2 Day Complete';
        update p1;
        
        p2.LeadDays__c = '2';
        p2.Name = '7 Day Complete';
        update p2;
        
        List<TCode_Product__c> tcodeProd = [SELECT Id, Product__c, TCodeManagement__c FROM TCode_Product__c];
        tcodeProd[1].TCodeManagement__c = tcodeProd[0].TCodeManagement__c;
        update tcodeProd;
        
        tdu.iCounter = 1;
        tdu.createSubscriptions();

        tdu.lstSubscriptions[0].TCode__c = tcodeProd[0].TCodeManagement__c;
        tdu.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_OFFERED;
        tdu.lstSubscriptions[0].Start_Date__c = Date.today().addDays(-14);
        update tdu.lstSubscriptions[0];

        Test.startTest();
            Subscription__c sub = [SELECT Id, Start_Date__c, Product__c FROM Subscription__c];
            System.assertNotEquals(sub.Product__c, p2.Id, 'Sub product should be p1.Id');
            Id product          = sub.Product__c;
            Date startDate      = sub.Start_Date__c;
            sub.Product__c      = p2.Id; 
            update sub;

            Subscription__c subP1 = [SELECT Id, Start_Date__c FROM Subscription__c];
        
            Date saturdayAdjustedRenewalDate = DateUtility.getDateOfNextNamedDay(Date.today(), 'Saturday');
            Date newStartDate                = saturdayAdjustedRenewalDate.addDays(Integer.valueOf(p2.LeadDays__c));
            
            System.assertEquals(newStartDate, subP1.Start_Date__c, 'New Start date should be less as its a 2 day product');

            sub.Product__c = p1.Id;
            update sub;
            sub = [SELECT Id, Start_Date__c, Product__c FROM Subscription__c];
        
            System.assertEquals(newStartDate.addDays(7),  sub.Start_Date__c, 'New Start date should match');
        Test.stopTest();        
    }

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 15/05/2017  
    Function -  test testDDWinbackAutoClose
    #############Change Log#############
    Modified by       Version     Change Date 
    ****************************************************************************************/
    private static testMethod void testDDWinbackAutoClose(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();

        Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DD_WINBACK_RECORD_TYPE_NAME, Case.class.getName());
        insert new Case(Status=Constants.CASE_STATUS_NEW, Subject='s1', RecordTypeId=rtId, Print_Subscription__c=tdu.lstSubscriptions[0].Id);

        Test.startTest();
            insert new OCCaseAutoclose__c(SetupOwnerId=UserInfo.getOrganizationId(), Auto_Close_Cases__c=true);

            tdu.lstSubscriptions[0].Cancellation_Reason__c = Constants.OC_NO_SALE_REASON_ILLNESS;
            update tdu.lstSubscriptions[0];

            List<Case> lstCases = [select DD_Winback_Outcome__c, Status from Case];
            System.assertEquals(Constants.CASE_OUTCOME_AUTO_COMPLETED, lstCases[0].DD_Winback_Outcome__c);
            System.assertEquals(Constants.CASE_STATUS_COMPLETED, lstCases[0].Status);
        Test.stopTest();
        
    }

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 15/05/2017  
    Function -  test testDDCancellationAutoClose
    #############Change Log#############
    Modified by       Version     Change Date 
    ****************************************************************************************/
    private static testMethod void testDDCancellationAutoClose(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();

        Id rtId = RecordTypeUtility.getRecordTypeId(Case.SObjectType, Constants.OC_DDCX_CASE_RECORD_TYPE_NAME, Case.class.getName());
        insert new Case(Status=Constants.CASE_STATUS_NEW, Subject='s1', RecordTypeId=rtId, Print_Subscription__c=tdu.lstSubscriptions[0].Id);

        Test.startTest();
            insert new OCCaseAutoclose__c(SetupOwnerId=UserInfo.getOrganizationId(), Auto_Close_Cases__c=true);

            tdu.lstSubscriptions[0].Cancellation_Reason__c = Constants.OC_NO_SALE_REASON_ILLNESS;
            update tdu.lstSubscriptions[0];

            List<Case> lstCases = [select DD_Cancellation_Outcome__c, Status from Case];
            System.assertEquals(Constants.CASE_OUTCOME_AUTO_COMPLETED, lstCases[0].DD_Cancellation_Outcome__c);
            System.assertEquals(Constants.CASE_STATUS_COMPLETED, lstCases[0].Status);
        Test.stopTest();
        
    }
}
