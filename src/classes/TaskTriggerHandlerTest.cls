/**
* @author Unknown
* @date Unknown
* @description Task trigger handler
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         06/01/2016  //modified to use proper TestDataUtility methods
Vishant Shah    1.2         12/10/2016  //added assertion to testTaskCreation & testTaskUpdate for Product__c
                                        //Added methods testTaskCreationProductAssertion & testTaskUpdateProductAssertion
**/
@isTest
private class TaskTriggerHandlerTest {
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test scenario on insert
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			06/01/2016	//modified to use proper methods from TestDataUtility
    Vishant Shah    1.2         12/10/2016  //Added assertion to ckeck product is not populated
    ****************************************************************************************/
	private static testmethod void testTaskCreation () {
		TestDataUtility tdu = new TestDataUtility(1);
       	tdu.createDigitalSubscribers();
       	tdu.checkSubscriptionDependencies();
        Subscription__c testActiveSub = TestDataUtility.newSubscripiton(5, tdu.lstDigitalSubscribers[0].Id, tdu.lstRetailers[0].Id, null);
        testActiveSub.Product__c = tdu.lstZproducts[0].Id;
        insert testActiveSub;
        
        Account acc = [SELECT PersonContactId FROM Account WHERE Id = :tdu.lstDigitalSubscribers[0].Id];
        
        Task testTask = new Task();
        testTask.WhatId = testActiveSub.Id;
        testTask.Subject = 'Test';
        
		Test.startTest();
		insert testTask;
		Test.stopTest();
		
		testTask = [SELECT WhoId, Sub_Weekly_Price__c, Product__c FROM Task WHERE Id = :testTask.Id];
		System.assertEquals(testTask.Whoid, acc.PersonContactId);
		System.assertEquals(testTask.Sub_Weekly_Price__c, testActiveSub.Weekly_Price__c);
        System.assertequals(null, testTask.Product__c, 'Task Product should be null when Task is not a Complete Sale');
	}

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 12/10/2016
    Version - 1.1
    Function - test scenario on insert of a completed sale to make sure product is populated
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testmethod void testTaskCreationProductAssertion() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createDigitalSubscribers();
        tdu.checkSubscriptionDependencies();


        tdu.createZProduct();
        tdu.createZSubscriptions();
        tdu.lstZuoraSubscriptions[0].PromoCode__c = 'somethingElse';
        tdu.lstZuoraSubscriptions[0].Subscription_Product__c = 'somethingElse';
        update tdu.lstZuoraSubscriptions;

        Subscription__c testActiveSub = TestDataUtility.newSubscripiton(5, tdu.lstDigitalSubscribers[0].Id, tdu.lstRetailers[0].Id, null);
        testActiveSub.Product__c = tdu.lstZproducts[0].Id;
        insert testActiveSub;
        
        Account acc = [SELECT PersonContactId FROM Account WHERE Id = :tdu.lstDigitalSubscribers[0].Id];
        
        Task testTask = new Task();
        testTask.WhatId = testActiveSub.Id;
        testTask.Subject = 'Test';
        testTask.Status = Constants.TSTATUS_COMPLETED;
        testTask.Outcome__c = Constants.TOUTCOME_SALE;

        Test.startTest();
        insert testTask;
        Test.stopTest();
        
        testTask = [Select WhoId, Sub_Weekly_Price__c, Product__c from Task where Id = :testTask.Id];
        System.assertEquals(testTask.Whoid, acc.PersonContactId);
        System.assertEquals(testTask.Sub_Weekly_Price__c, testActiveSub.Weekly_Price__c);

        Subscription__c sub =  [SELECT Id, Product__c, Product__r.Name FROM Subscription__c WHERE Id = :testActiveSub.Id];
        System.assertEquals(sub.Product__r.Name, testTask.Product__c, 'Task Product should NOT be null when Task is a Complete Sale');

        testtask.WhatId = tdu.lstZuoraSubscriptions[0].Id;
        testTask.Status = Constants.TSTATUS_NOTSTARTED;
        testTask.Outcome__c = Constants.TSTATUS_NOTSTARTED;
        update testTask;

        testTask =  [SELECT Id, Product__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(null, testTask.Product__c, 'Task product should be NULL when NOT a Complete Sale and Changed to Digital Sub');

        testTask.Status = Constants.TSTATUS_COMPLETED;
        testTask.Outcome__c = Constants.TOUTCOME_SALE;
        update testTask;

        testTask =  [SELECT Id, Product__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(tdu.lstZuoraSubscriptions[0].Subscription_Product__c, testTask.Product__c, 'Task should MATCH Digital Sub Product when Complete Sale');

        testTask.Detail__c = 'test';
        update testTask;
        testTask =  [SELECT Id, Product__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(tdu.lstZuoraSubscriptions[0].Subscription_Product__c, testTask.Product__c, 'Updating with no changes to a task should not change product__c');

        tdu.lstZuoraSubscriptions[0].Subscription_Product__c = null;
        update tdu.lstZuoraSubscriptions;
        update testTask;
        testTask =  [SELECT Id, Product__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(null, testTask.Product__c,'Task Product__c should be NULL when Digital Sub Product is Empty');

        
    }


	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test scenario on update
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			06/01/2016	//modified to use proper methods from TestDataUtility
    Vishant Shah    1.2         12/10/2016  //Added assertion to ckeck product is not populated
    ****************************************************************************************/
	private static testmethod void testTaskUpdate(){
		TestDataUtility tdu = new TestDataUtility(2);
       	tdu.checkSubscriptionDependencies();
       	tdu.createDigitalSubscribers();

		Double beforeWeeklyPrice = 219.11;
		Double afterWeeklyPrice = 50.11;
        
       	Subscription__c testActiveSub = TestDataUtility.newSubscripiton(5, tdu.lstDigitalSubscribers[0].Id, tdu.lstRetailers[0].Id, null);
        testActiveSub.Product__c = tdu.lstZproducts[0].Id;
        insert testActiveSub;
        
        Account acc = [SELECT PersonContactId FROM Account WHERE Id = :tdu.lstDigitalSubscribers[0].Id];
        Account acc2 = [SELECT PersonContactId FROM Account WHERE Id = :tdu.lstDigitalSubscribers[1].Id];
        
        Task testTask = new Task();
        testTask.WhatId = testActiveSub.Id;
        testTask.Subject = 'Test';
        insert testTask;
        
        testTask = [SELECT WhoId, Sub_Weekly_Price__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(testTask.WhoId, acc.PersonContactId);
		System.assertEquals(testTask.Sub_Weekly_Price__c, beforeWeeklyPrice);
		
		testActiveSub.Weekly_Price__c = afterWeeklyPrice;
		update testActiveSub;
		
		Test.startTest();
			testTask.WhoId = acc2.PersonContactId;
			update testTask;
		Test.stopTest();
		
		testTask = [SELECT WhoId, Sub_Weekly_Price__c, Product__c FROM Task WHERE Id = :testTask.Id];
		System.assertEquals(testTask.Whoid, acc2.PersonContactId);
		System.assertEquals(testTask.Sub_Weekly_Price__c, afterWeeklyPrice);
        System.assertEquals(null, testTask.Product__c, 'Task Product should be null when Task is not a Complete Sale');
	}

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 12/10/2016
    Version - 1.1
    Function - test scenario on update task, completed sale should populate product
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testmethod void testTaskUpdateProductAssertion(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.checkSubscriptionDependencies();
        tdu.createDigitalSubscribers();

        Double beforeWeeklyPrice = 219.11;
        Double afterWeeklyPrice = 50.11;
        
        Subscription__c testActiveSub = TestDataUtility.newSubscripiton(5, tdu.lstDigitalSubscribers[0].Id, tdu.lstRetailers[0].Id, null);
        testActiveSub.Product__c = tdu.lstZproducts[0].Id;
        insert testActiveSub;
        
        Account acc = [SELECT PersonContactId FROM Account WHERE Id = :tdu.lstDigitalSubscribers[0].Id];
        Account acc2 = [SELECT PersonContactId FROM Account WHERE Id = :tdu.lstDigitalSubscribers[1].Id];
        
        Task testTask = new Task();
        testTask.WhatId = testActiveSub.Id;
        testTask.Subject = 'Test';
        insert testTask;
        
        testTask = [SELECT WhoId, Sub_Weekly_Price__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(testTask.WhoId, acc.PersonContactId);
        System.assertEquals(testTask.Sub_Weekly_Price__c, beforeWeeklyPrice);
        
        testActiveSub.Weekly_Price__c = afterWeeklyPrice;
        update testActiveSub;
        
        Test.startTest();
            testTask.WhoId = acc2.PersonContactId;
            update testTask;
        Test.stopTest();
        
        testTask = [SELECT WhoId, Sub_Weekly_Price__c, Product__c FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(testTask.Whoid, acc2.PersonContactId);
        System.assertEquals(testTask.Sub_Weekly_Price__c, afterWeeklyPrice);
        
        testTask.Status = Constants.TSTATUS_COMPLETED;
        testTask.Outcome__c = Constants.TOUTCOME_SALE;
        
        Subscription__c sub =  [SELECT Id, Product__c, Product__r.Name FROM Subscription__c WHERE Id = :testActiveSub.Id];
        System.assertEquals(null, testTask.Product__c, 'Task Product should NOT be null when Task is a Complete Sale');

        update testTask;
    }
}