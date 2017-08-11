/**
* @author Unknown
* @date Unknown
* @description Test class for subscriptionInRenewalCreation and subscriptionInRenewalButton classes
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         30/07/2015  //introduced new init() method, restored assertions, replaced lock flag with SubscriptionTriggerHandler one, added testRaiseError()
Cristina Anghenie 1.2       14/09/2015  //test MppDDCalloutStage__c id set to manualRenewal only when renewal button is clicked on the subscription page
Wiktor Czykin   1.3         30/09/2015  //removed Discount__c references
Pawel Chrzanowski   1.4     07/04/2016  //updated for new data model
Michal Szewczyk 1.5         11/05/2016  //removed Subscription_Product__c from code
Gavin Palmer    1.6         02/06/2016  // modified TestSubscriptionInRenewalTrigger3()
**/
@isTest(SeeAllData=false)
private class TestSubscriptionInRenewal {        
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 30/07/2015
    Version - 1.0
    Function - test init for all methods
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @testSetup static void init(){
        TCodeManagement__c renewalTCode = TestDataUtility.newTCodeManagement('RNWL');
        renewalTCode.Type__c = 'Renewal';
        renewalTCode.Valid__c = true;
        insert renewalTCode;
    }
     
    /*************************************************************************************** 
    Developer - unknown
    Date - unknown
    Version - 1.1
    Function -  Assert that a new subscription is NOT created when current subscription status becomes
                'In Renewal' BUT the weekly price is not within a priceband. Also, tests to ensure null fields
                do not throw an exception.      
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         19/08/2015  //update test class to check if certain fields got populated
    Lynette Lim     1.2         06/04/2016  //update test class to reflect new data model changes with Unbundling
    Gavin Palmer    1.3         02/06/2016  // modified the subscription status so that additional renewal subs arent created
    ****************************************************************************************/    
    static testMethod void TestSubscriptionInRenewalTrigger3 () {
        TestDataUtility td = new TestDataUtility(5);
        td.loadEntitlementsSettings();
        td.loadEntitlementsMappingSettings();
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.createRetailers();
        td.createZProductFeatures();
        td.createTCodeManagement();
        td.createSubscriptions();

        Integer countBefore = [SELECT count() FROM Subscription__c];
        Test.startTest();
            SubscriptionTriggerHandler.getInstance().bDeferredCalculationSkip = false;
            td.lstSubscriptions[0].Subscription_Status__c = 'hi';      
            td.lstSubscriptions[0].Product__c = td.lstZproducts[0].Id;
            update td.lstSubscriptions[0];
            
            Integer countAfter = [select count() from Subscription__c];
            System.assertEquals(countAfter, countBefore);
            
            Subscription__c Sub = [select Pricing_Error__c from subscription__c where Id = :td.lstSubscriptions[0].Id];
            System.assertEquals(false, Sub.Pricing_Error__c);
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - test new renewal button for cancelled or withdrawn subscriptions 
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         19/08/2015  //update test class to check if certain fields got populated
    Pawel Chrzanowski   1.2         07/04/2016  //updated for new data model
    ****************************************************************************************/    
    static testMethod void TestSubscriptionInRenewalButton1 () {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createRetailers();
        tdu.createZProductFeatures();
        tdu.createTCodeManagement();
        tdu.createSubscriptions();

        tdu.lstSubscriptions[0].Start_Date__c = Date.newInstance(2015,8,25);
        tdu.lstSubscriptions[0].Subscription_Status__c = 'Cancelled';
        tdu.lstSubscriptions[0].Cancellation_Date__c = Date.newInstance(2015,9,1);
        tdu.lstSubscriptions[0].Cancellation_Reason__c = 'Failed payment';
        tdu.lstSubscriptions[0].Cancellation_Method__c = 'Failed payment';
        tdu.lstSubscriptions[0].PaymentDate__c = '15';
        tdu.lstSubscriptions[0].MPP_DD_Frequency__c = 'Monthly';
        tdu.lstSubscriptions[0].isContinuous__c = true;
        tdu.lstSubscriptions[0].Product__c = tdu.lstZproducts[0].Id;
        update tdu.lstSubscriptions[0];
        
        Integer countBefore = [SELECT count() FROM Subscription__c WHERE Subscriber__c =: tdu.lstIndividualSubscribers[0].Id];
        
        Test.startTest();   
            String returnID = subscriptionInRenewalButton.subInRenewal(tdu.lstSubscriptions[0].Id);
        Test.stopTest();
        
        Id returnIDvalue = [select Id from subscription__c where previous_subscription__c =:tdu.lstSubscriptions[0].Id].Id;     
        Integer countAfter = [SELECT count() FROM Subscription__c WHERE Subscriber__c =: tdu.lstIndividualSubscribers[0].Id];
        System.assertEquals(returnIDvalue, returnID);
        System.assertEquals(countAfter, countBefore+1);
        
        Subscription__c renewedSub = [SELECT Subscription_Start_Calc__c, Price_Plan__c, New_Sub_Duration__c, Subscription_Status__c, Subscriber__c,
                                           Subscriber__r.RecordTypeId, Start_Date__c, End_Date__c, Previous_Subscription__c, Retailer__c, 
                                           Delivery_Type__c, Subscription_Duration_Picklist__c, Subscription_Duration_Number__c, 
                                           Weekly_Price__c, Previous_Price__c, Discount__c, payment_type__c, isContinuous__c, MPP_CC_Frequency__c, 
                                           RecordTypeId, PaymentDate__c, MPP_DD_Frequency__c, Order_Taken_Method__c, MppDDCalloutStage__c 
                                      FROM subscription__c WHERE previous_subscription__c =: tdu.lstSubscriptions[0].Id];
        System.assertEquals(tdu.lstSubscriptions[0].MPP_CC_Frequency__c,renewedSub.MPP_CC_Frequency__c);
        System.assertEquals(tdu.lstSubscriptions[0].MPP_DD_Frequency__c,renewedSub.MPP_DD_Frequency__c);
        System.assertEquals(tdu.lstSubscriptions[0].PaymentDate__c,renewedSub.PaymentDate__c);
        System.assertEquals('Auto Renewal',renewedSub.Order_Taken_Method__c );
        System.assertEquals('ManualRenewal',renewedSub.MppDDCalloutStage__c );
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 30/07/2015
    Version - 1.0
    Function - Check error handling method 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testmethod void testRaiseError() {
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.createSubscriptions();
        String sError = 'serror';
        Test.startTest();
            Test.setCurrentPage(Page.SiteLogin);
            subscriptionInRenewalCreation.raiseError(td.lstSubscriptions[0], sError, 'trigger');
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),sError));
        System.assert(td.lstSubscriptions[0].Pricing_Error__c);
    }
}