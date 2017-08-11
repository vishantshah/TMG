/**
* Author:       Sally ElGhoul (Accenture)
* Date:         21/09/2015
* Description:  Test class for the class ZQuoteSubProductChargeTriggerHandler
*
* ******************* Change Log *******************
* Modified by       Change Date    
* Michal Szewczyk    23/02/2015 Added new test method testSubSummaryCalculation();
* Gavin Palmer      27/06/2016 added testSubSummaryCalculationWithFutureEffectiveStartDate() and modified testSubSummaryCalculation() 
* Michal Szewczyk   22/08/2016 changed testSubSummaryCalculationWithFutureEffectiveStartDate()
* Pawel Chrzanowski 22/02/2017 added updateRestrictedOfferUsageRecordsTest()
**/
@isTest
private class ZQuoteSubProductChargeTriggerHandlerTest {

    /***************************************************************************************
    Developer - Sally ElGhoul (Accenture)
    Date - 21/09/2015
    Version - 1.0
    Function -  test functionality of the trigger
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         27/06/2016 - moved all the test data setup into a single method: createSubscriptionProductCharges()
    ****************************************************************************************/
    static testMethod void testMyUnitTest() {
        TestDataUtility testDataUtilityObj=new TestDataUtility(1);
        
        testDataUtilityObj.createSubscriptionProductCharges();
       	
       	//get the subscription record and compare the subscription product value to the subscription charge we created
       	list<Zuora__Subscription__c> lstSubscription=[select id,Subscription_Product__c from Zuora__Subscription__c where id =:testDataUtilityObj.lstZuoraSubscriptions[0].id];
       	system.assertEquals(lstSubscription[0].Subscription_Product__c,'TestProduct Annual');
       	
       	//delete the subscription product charge record and make sure the subscription product value is empty
       	delete testDataUtilityObj.lstZuoraSubscriptionProductCharges;
       	lstSubscription=[select id,Subscription_Product__c from Zuora__Subscription__c where id =:testDataUtilityObj.lstZuoraSubscriptions[0].id];
       	system.assertEquals(lstSubscription[0].Subscription_Product__c,null);
    }
    
    /***************************************************************************************
    Developer - Michal Szewczyk
    Date - 23/02/2016
    Version - 1.0
    Function -  Check that Ongoing/Initial prices for sub are correct
    #############Change Log#############
    Modified by     Version     Change Date
    Gavin Palmer    1.1         27/06/2016 - moved all the test data setup into a single method: createSubscriptionProductCharges()
    ****************************************************************************************/
    static testMethod void testSubSummaryCalculation() {

        TestDataUtility testDataUtilityObj=new TestDataUtility(1);
        
        testDataUtilityObj.createSubscriptionProductCharges();

        //get the subscription record and compare the subscription product value to the subscription charge we created
        list<Zuora__Subscription__c> lstSubscription=[select id,Subscription_Product__c,On_Going_Subscription_Price__c,Initial_Subscription_Price__c from Zuora__Subscription__c where id =:testDataUtilityObj.lstZuoraSubscriptions[0].id];
        system.assertEquals(150,lstSubscription[0].On_Going_Subscription_Price__c);
        system.assertEquals(150,lstSubscription[0].Initial_Subscription_Price__c);
    } 
    
    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 27/06/2016
    Version - 1.0
    Function -  Check that Ongoing/Initial prices for sub are correct when we have a future effective start date
                test runs calculateSubSummaryFields() on after insert
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         22/08/2016     // removed hidden fields logic for on going/initial price
    ****************************************************************************************/
    static testMethod void testSubSummaryCalculationWithFutureEffectiveStartDate() {
        
        TestDataUtility testDataUtilityObj = new TestDataUtility(1);
        testDataUtilityObj.createZuoraSubscription();
        
        Zuora__SubscriptionProductCharge__c subscriptionProductChargeObj 
            = TestDataUtility.newSubscriptionProductCharge(testDataUtilityObj.lstZuoraSubscriptions[0].Id, null);
            
        subscriptionProductChargeObj.Zuora__EffectiveStartDate__c = Date.today().addDays(1);

        Test.startTest();
            insert subscriptionProductChargeObj;
        Test.stopTest();

        List<Zuora__Subscription__c> lstSubscription = [
            SELECT On_Going_Subscription_Price__c, 
                Initial_Subscription_Price__c 
            FROM Zuora__Subscription__c 
            WHERE Id = :testDataUtilityObj.lstZuoraSubscriptions[0].Id
        ];

        System.assertEquals(150, lstSubscription[0].On_Going_Subscription_Price__c,
            'The On Going subscription price should not be');
        System.assertEquals(150, lstSubscription[0].Initial_Subscription_Price__c,
            'The initial subscription price should  be set');
    }   

	/*************************************************************************************** 
    Developer: Pawel Chrzanowski
    Date: 22/02/2017
    Test for updateRestrictedOfferUsageRecords()
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @isTest static void updateRestrictedOfferUsageRecordsTest(){
        TestDataUtility tdu = new TestDataUtility(3);
        tdu.createZSubscriptions();
        tdu.createZProducts();
        
        tdu.lstZuoraSubscriptions[0].Zuora__External_Id__c = 'aaaaaaaaaaaa';
        tdu.lstZuoraSubscriptions[1].Zuora__External_Id__c = 'bbbbbbbbbbbb';
        tdu.lstZuoraSubscriptions[1].Zuora__External_Id__c = 'cccccccccccc';
        update tdu.lstZuoraSubscriptions;
    
        List<Zuora__Product__c> lstZuoraProducts = new List<Zuora__Product__c>();
        lstZuoraProducts.add(new Zuora__Product__c(Name = 'zuora product 1', Zuora__External_Id__c = tdu.lstZproducts[0].zqu__ZuoraId__c));
        lstZuoraProducts.add(new Zuora__Product__c(Name = 'zuora product 2', Zuora__External_Id__c = tdu.lstZproducts[1].zqu__ZuoraId__c));
        lstZuoraProducts.add(new Zuora__Product__c(Name = 'zuora product 3', Zuora__External_Id__c = tdu.lstZproducts[2].zqu__ZuoraId__c));
        insert lstZuoraProducts;

        List<Restricted_Offer_Usage__c> lstROU = new List<Restricted_Offer_Usage__c>();
        lstROU.add(new Restricted_Offer_Usage__c(Account__c = tdu.lstRegistrants[0].Id, Zuora_Product_Id__c = tdu.lstZproducts[0].zqu__ZuoraId__c, Zuora_Subscription_Id__c = tdu.lstZuoraSubscriptions[0].Zuora__External_Id__c));
        lstROU.add(new Restricted_Offer_Usage__c(Account__c = tdu.lstRegistrants[1].Id, Zuora_Product_Id__c = tdu.lstZproducts[1].zqu__ZuoraId__c, Zuora_Subscription_Id__c = tdu.lstZuoraSubscriptions[1].Zuora__External_Id__c));
        lstROU.add(new Restricted_Offer_Usage__c(Account__c = tdu.lstRegistrants[2].Id, Zuora_Product_Id__c = tdu.lstZproducts[2].zqu__ZuoraId__c, Zuora_Subscription_Id__c = tdu.lstZuoraSubscriptions[2].Zuora__External_Id__c));
        insert lstROU;
        
        List<Zuora__SubscriptionProductCharge__c> lstSPC = new List<Zuora__SubscriptionProductCharge__c>();
        lstSPC.add(new Zuora__SubscriptionProductCharge__c(Zuora__Account__c = tdu.lstRegistrants[0].Id, Zuora__Product__c = lstZuoraProducts[0].Id, Zuora__Subscription__c = tdu.lstZuoraSubscriptions[0].Id));
        lstSPC.add(new Zuora__SubscriptionProductCharge__c(Zuora__Account__c = tdu.lstRegistrants[1].Id, Zuora__Product__c = lstZuoraProducts[1].Id, Zuora__Subscription__c = tdu.lstZuoraSubscriptions[1].Id));
        lstSPC.add(new Zuora__SubscriptionProductCharge__c(Zuora__Account__c = tdu.lstRegistrants[2].Id, Zuora__Product__c = lstZuoraProducts[2].Id, Zuora__Subscription__c = tdu.lstZuoraSubscriptions[2].Id));
        insert lstSPC;

        lstROU = [SELECT Product__c, Zuora_Product_Id__c, Subscription__c, Zuora_Subscription_Id__c FROM Restricted_Offer_Usage__c];
        System.assertEquals(3, lstROU.size());
        for(Restricted_Offer_Usage__c rou : lstROU){
            if(rou.Product__c == tdu.lstZproducts[0].Id) System.assertEquals(tdu.lstZproducts[0].zqu__ZuoraId__c, rou.Zuora_Product_Id__c);
            if(rou.Product__c == tdu.lstZproducts[1].Id) System.assertEquals(tdu.lstZproducts[1].zqu__ZuoraId__c, rou.Zuora_Product_Id__c);
            if(rou.Product__c == tdu.lstZproducts[2].Id) System.assertEquals(tdu.lstZproducts[2].zqu__ZuoraId__c, rou.Zuora_Product_Id__c);
            if(rou.Subscription__c == tdu.lstZuoraSubscriptions[0].Id) System.assertEquals(tdu.lstZuoraSubscriptions[0].Zuora__External_Id__c, rou.Zuora_Subscription_Id__c);
            if(rou.Subscription__c == tdu.lstZuoraSubscriptions[1].Id) System.assertEquals(tdu.lstZuoraSubscriptions[1].Zuora__External_Id__c, rou.Zuora_Subscription_Id__c);
            if(rou.Subscription__c == tdu.lstZuoraSubscriptions[2].Id) System.assertEquals(tdu.lstZuoraSubscriptions[2].Zuora__External_Id__c, rou.Zuora_Subscription_Id__c);
        }
    }
}