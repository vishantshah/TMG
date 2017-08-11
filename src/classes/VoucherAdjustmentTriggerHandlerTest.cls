/**
* @author Wiktor Czykin
* @date 21/09/2015
* @description Test for Voucher_Adjustment__c trigger handler
#############Change Log#############
Modified by     	Version     Change Date
Michal Szewczyk 	1.1			14/10/2016  - added test methods to test generateDateCalc()
Mantas Grigaliunas	1.2			09/12/2016	- added test method updateRefundTest()
Mantas Grigaliunas	1.3			12/12/2016	- added updateChequeAmountTest()
Mantas Grigaliunas  1.4 	    19/12/2016  - removed testUpdateDeferredAssetValueUpdate and modified testUpdateDeferredAssetValue()
Mantas Grigaliunas	1.5			09/02/2017	- added test methods preventMultipleSameDateVoucherCreationTestNoConflict(),
											  preventMultipleSameDateVoucherCreationTestWithConflicts() and supporting method createHolidayReturnVoucher()
Vishant Shah		1.6			20/04/2017	- added overlapTest()
Konrad Czykin		1.7			14/05/2017	- added overlapTestPreNotificationHoliday()
**/
@isTest
private class VoucherAdjustmentTriggerHandlerTest{

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 22/09/2015
    Version - 1.0  
    Function - Test not used trigger handler method
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testEmptyMethods(){
		Test.startTest();
			VoucherAdjustmentTriggerHandler vat = VoucherAdjustmentTriggerHandler.getInstance();
			vat.OnBeforeDelete(null, null);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 22/09/2015
    Version - 1.0 
    Function -  test of updateDeferredAssetValue method
    #############Change Log#############
	Modified by     	Version     Change Date
	Mantas Grigaliunas	1.1			20/12/2016	refactored code to cover after insert and after update scenarios
    ****************************************************************************************/
	private static testMethod void testUpdateDeferredAssetValue(){
		TestDataUtility td = new TestDataUtility(5);
		td.checkVoucherAdjustmentDependencies();
		List<Date> testDates = new List<Date>{
			Date.today().addDays(-1),
			Date.today().addDays(1),
			Date.today().addDays(-2),
			Date.today().addDays(2),
			Date.today().addDays(-3)
		};
		
		Test.startTest();

		List<Voucher_Adjustment__c> lstVouchers = new List<Voucher_Adjustment__c>();
		Date startDate = DateUtility.getDateOfNextNamedDay(Date.today(), 'Monday').addDays(49);
		Date endDate = startDate.addDays(3);
		for(Integer i = 0; i<td.iCounter; i++){
			Voucher_Adjustment__c va = TestDataUtility.newVoucherAdjustment(i, td.lstSubscriptions[i].Id, startDate, endDate);
			va.Deferred_Asset_Value__c = null;
			lstVouchers.add(va);
		}
		insert lstVouchers;

		//assert insert results
		List<Voucher_Adjustment__c> lstRefetched = [SELECT Id, Deferred_Asset_Value__c, Voucher_Value__c
													FROM Voucher_Adjustment__c WHERE Id IN :lstVouchers ];
		System.assert(!lstRefetched.isEmpty());
		for(Voucher_Adjustment__c va : lstRefetched){
			System.assertEquals(va.Voucher_Value__c, va.Deferred_Asset_Value__c);
		}

		//update dates to test deffered value after update
		for(Subscription__c sub : td.lstSubscriptions){
			sub.Start_Date__c = Date.today().addDays(-10);
		}
		update td.lstSubscriptions;
		System.assertEquals(lstRefetched.size(), testDates.size());
		for(Integer i = 0; i < testDates.size(); i++){
			lstRefetched[i].Start_Date__c = testDates[i].addDays(-7);
			lstRefetched[i].End_Date__c = testDates[i];
		}
		update lstRefetched;

		//assert update results
		List<Voucher_Adjustment__c> lstUpdated = [SELECT Id, End_Date__c, Deferred_Asset_Value__c, Voucher_Value__c
												  FROM Voucher_Adjustment__c WHERE Id IN :lstVouchers ];
		System.assert(!lstUpdated.isEmpty());
		for(Voucher_Adjustment__c va : lstUpdated){
			if(va.End_Date__c > Date.today()){
				System.assertEquals(va.Voucher_Value__c, va.Deferred_Asset_Value__c);
			} else {
				System.assertEquals(0.0, va.Deferred_Asset_Value__c);
			}
		}
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 22/09/2015
    Version - 1.0 
    Function - test of updateDeferredAssetValue method -> End Date in the past
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testUpdateDeferredAssetValueUpdateToZero(){
		TestDataUtility td = new TestDataUtility(2);
		td.checkSubscriptionDependencies();
		Test.startTest();
			List<Subscription__c> lstSubscriptions = new List<Subscription__c>();
			for(Integer i = 0; i < td.iCounter; i++){
				Subscription__c sub = TestDataUtility.newSubscripiton(i, td.lstIndividualSubscribers[i].Id, td.lstRetailers[i].Id,  Date.newInstance(2014, 5, 26));
				sub.Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
				lstSubscriptions.add(sub);
			}
			insert lstSubscriptions;

			lstSubscriptions = [select Id, Start_Date__c, End_Date__c from Subscription__c where Id in :lstSubscriptions];
			List<Voucher_Adjustment__c> lstVouchers = new List<Voucher_Adjustment__c>();
			for(Integer i = 0; i<td.iCounter; i++){
				Voucher_Adjustment__c va = TestDataUtility.newVoucherAdjustment(i, lstSubscriptions[i].Id, lstSubscriptions[i].Start_Date__c.addDays(5),lstSubscriptions[i].End_Date__c);
				va.Deferred_Asset_Value__c = null;
				va.Voucher_Activity_Action__c = 'someValue';
				lstVouchers.add(va);
			}
			insert lstVouchers;

			List<Voucher_Adjustment__c> lstRefetched =  [select Id, Deferred_Asset_Value__c, Voucher_Value__c from Voucher_Adjustment__c where Id in :lstVouchers];
			System.assert(!lstRefetched.isEmpty());
			for(Voucher_Adjustment__c va :lstRefetched){
				System.assertEquals(0, va.Deferred_Asset_Value__c);
			}
			update lstVouchers;

			lstRefetched =  [select Id, Deferred_Asset_Value__c, Voucher_Value__c from Voucher_Adjustment__c where Id in :lstVouchers];
			System.assert(!lstRefetched.isEmpty());
			for(Voucher_Adjustment__c va :lstRefetched){
				System.assertEquals(0, va.Deferred_Asset_Value__c);
			}
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 22/09/2015
    Version - 1.0 
    Function - Verify that related subscription is updated correctly with adjustment type, number of vouchers, vouchers resend date, vouchers adjustment start date
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testVoucherAdjustPositive(){
		TestDataUtility td = new TestDataUtility(5);
		td.checkVoucherAdjustmentDependencies();
		Test.startTest();
			List<Voucher_Adjustment__c> lstVouchers = new List<Voucher_Adjustment__c>();
			List<Subscription__c> lstSubscriptions = [select Id, Voucher_Pack_2_Start_Date__c, Voucher_Pack_2_End_Date__c from Subscription__c where Id in :td.lstSubscriptions];
			Map<Id, Voucher_Adjustment__c> mapSubscriptionIdToVoucher = new Map<Id, Voucher_Adjustment__c>();

			for(Integer i = 0; i<td.iCounter; i++){
				Voucher_Adjustment__c va = TestDataUtility.newVoucherAdjustment(i, td.lstSubscriptions[i].Id, lstSubscriptions[i].Voucher_Pack_2_Start_Date__c, lstSubscriptions[i].Voucher_Pack_2_End_Date__c);
				va.Deferred_Asset_Value__c = null;
				va.Voucher_Activity_Action__c = 'someValue';
				va.Adjustment_Type__c = Constants.VOUCHER_ADJUSTMENTTYPE_FULLPACK;
				lstVouchers.add(va);
			}
			insert lstVouchers;
		Test.stopTest();

		List<Voucher_Adjustment__c> lstRefetchedVouchers = [select 	Id,
																	Adjustment_Type__c,
																	Number_of_Vouchers__c,
																	Subscription__c,
																	Start_Date__c
																from Voucher_Adjustment__c
																where Id in :lstVouchers];
		System.assert(!lstRefetchedVouchers.isEmpty());
		for(Voucher_Adjustment__c va : lstRefetchedVouchers){
			mapSubscriptionIdToVoucher.put(va.Subscription__c, va);
		}
			

		List<Subscription__c> lstSubscriptionsToVerify = [select 	Id, 
																	Voucher_Adjustment_Reason__c,
																	Voucher_Resend_Number__c,
																	Voucher_Resend_Date__c,
																	Voucher_Adjustment_Start_Date__c
																	from Subscription__c 
																	where Id in :td.lstSubscriptions];
		System.assert(!lstSubscriptionsToVerify.isEmpty());
		for(Subscription__c sub : lstSubscriptionsToVerify){
			System.assertEquals(Date.today(), sub.Voucher_Resend_Date__c);
			System.assertEquals(mapSubscriptionIdToVoucher.get(sub.Id).Adjustment_Type__c+'.', sub.Voucher_Adjustment_Reason__c);
			System.assertEquals(mapSubscriptionIdToVoucher.get(sub.Id).Number_of_Vouchers__c, sub.Voucher_Resend_Number__c);
			System.assertEquals(mapSubscriptionIdToVoucher.get(sub.Id).Start_Date__c, sub.Voucher_Adjustment_Start_Date__c);
		}
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 22/09/2015
    Version - 1.0 
    Function - Verify that subscription does not get updated when error occurs with sub update
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testVoucherAdjustNegative(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
		td.checkVoucherAdjustmentDependencies();
		Test.startTest();
			List<Voucher_Adjustment__c> lstVouchers = new List<Voucher_Adjustment__c>();
			List<Subscription__c> lstSubscriptions = [select Id, Voucher_Pack_2_Start_Date__c, Voucher_Pack_2_End_Date__c from Subscription__c where Id in :td.lstSubscriptions];
			for(Integer i = 0; i<td.iCounter; i++){
				Voucher_Adjustment__c va = TestDataUtility.newVoucherAdjustment(i, td.lstSubscriptions[i].Id, lstSubscriptions[i].Voucher_Pack_2_Start_Date__c, lstSubscriptions[i].Voucher_Pack_2_End_Date__c);
				va.Deferred_Asset_Value__c = null;
				va.Voucher_Activity_Action__c = 'someValue';
				va.Adjustment_Type__c = Constants.VOUCHER_ADJUSTMENTTYPE_FULLPACK;
				lstVouchers.add(va);
			}

			VoucherAdjustmentTriggerHandler va = VoucherAdjustmentTriggerHandler.getInstance();
			va.bTriggerError = true;
			insert lstVouchers;
		Test.stopTest();

		List<Subscription__c> lstSubscriptionsToVerify = [select 	Id, 
																	Voucher_Adjustment_Reason__c,
																	Voucher_Resend_Number__c,
																	Voucher_Resend_Date__c,
																	Voucher_Adjustment_Start_Date__c
																	from Subscription__c 
																	where Id in :td.lstSubscriptions];
		System.assert(!lstSubscriptionsToVerify.isEmpty());
		for(Subscription__c sub : lstSubscriptionsToVerify){
			System.assertEquals(null,sub.Voucher_Resend_Date__c);
			System.assertEquals(null, sub.Voucher_Adjustment_Reason__c);
			System.assertEquals(0, sub.Voucher_Resend_Number__c);
			System.assertEquals(null, sub.Voucher_Adjustment_Start_Date__c);
		}
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin (Tquila)
    Date - 22/09/2015
    Version - 1.0 
    Function - Verify coverage of deferredCalculation execution caused by Voucher_Adjustment__c record changes
    #############Change Log#############
	Modified by     	Version     Change Date
    ****************************************************************************************/
	private static testMethod void testDeferredRevenueCalculationOnInsertDeleteUndelete(){
        Test.startTest();
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        DeferredCalculation.isTestScenario = true;
        	
        td.checkVoucherAdjustmentDependencies();
    	List<Subscription__c> lstRefetched = [select Id, Asset_Calc__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(0, lstRefetched[0].Asset_Calc__c);

    	DeferredCalculation.isTestScenario = false;
    	td.createVoucherAdjustments();

        List<Voucher_Adjustment__c> lstVouchers = [select 	Id, 
                                                            Deferred_Asset_Value__c, 
                                                            Voucher_Activity_Action__c, 
                                                            Date_Vouchers_Received__c, 
                                                            Adjustment_Type__c ,
                                                            Voucher_Value__c
                                                        from Voucher_Adjustment__c 
                                                        where Id in :td.lstVoucherAdjustment];
                                              
		System.assert(!lstVouchers.isEmpty());
        Decimal dToCompare = -lstVouchers[0].Deferred_Asset_Value__c;
        lstRefetched = [select Id, Asset_Calc__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(dToCompare, lstRefetched[0].Asset_Calc__c);

        delete lstVouchers;
        lstRefetched = [select Id, Asset_Calc__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(0, lstRefetched[0].Asset_Calc__c);

        undelete lstVouchers;
        lstRefetched = [select Id, Asset_Calc__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(dToCompare, lstRefetched[0].Asset_Calc__c);
        Test.stopTest();
	}


	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/10/2016
    Version - 1.0 
    Function - Verify coverage of generateDateCalc execution caused by Voucher_Adjustment__c record changes
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testVoucherValueCalculation(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkVoucherAdjustmentDependencies();
 		Date subStartDate = Date.newInstance(2016,10,1);
 		Date voucherStartDate = Date.newInstance(2016,10,10);
 		Date voucherEndDate = Date.newInstance(2016,10,19);

 		td.lstSubscriptions[0].Start_Date__c = subStartDate;
 		td.lstSubscriptions[0].Weekly_Price__c = 9;
 		update td.lstSubscriptions;

    	List<Subscription__c> lstRefetched = [select Id,Product__c,RecordTypeId,RecordType.Name,Start_Date__c,Weekly_Price__c,Low_Start_Weekly_Price__c,Low_Start_End_Date__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        
        System.assert(!lstRefetched.isEmpty());
        System.assertNotEquals(null,lstRefetched[0].Product__c);

        Test.startTest();

      		Voucher_Adjustment__c newVoucher = TestDataUtility.newVoucherAdjustment(1,lstRefetched[0].Id,voucherStartDate,voucherEndDate);
      		insert newVoucher;
	        List<Voucher_Adjustment__c> lstVouchers = [select 	Id, 
	                                                            Voucher_Validity_in_Weeks_Calc__c, 
	                                                            Voucher_Value_Calc__c, 
	                                                            Number_of_Vouchers_Calc__c, 
	                                                            Start_Date__c,
	                                                            End_Date__c
	                                                        from Voucher_Adjustment__c 
	                                                        where Id=:newVoucher.Id];
			System.assert(!lstVouchers.isEmpty());
			System.assertNotEquals(null,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Value_Calc__c);
			System.assertEquals(7,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertEquals(1.75,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertEquals(15.75,lstVouchers[0].Voucher_Value_Calc__c);

			Voucher_Adjustment__c newVoucherError = TestDataUtility.newVoucherAdjustment(1,lstRefetched[0].Id,null,voucherEndDate);
      		try{
      			insert newVoucherError;
  			} catch (Exception e) {
      			system.assert(e.getMessage().contains('generateDateCalc method error : One of method param is null or empty'));
  			}
        Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/10/2016
    Version - 1.0 
    Function - Verify coverage of generateDateCalc execution caused by Voucher_Adjustment__c record changes for Low Start Sub
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testVoucherValueCalculationFullLowStart(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkVoucherAdjustmentDependencies();
 		Date subStartDate = Date.newInstance(2016,10,1);
 		Date subLowEndDate = Date.newInstance(2016,11,10);
 		Date voucherStartDate = Date.newInstance(2016,10,14);
 		Date voucherEndDate = Date.newInstance(2016,10,21);

 		td.lstSubscriptions[0].Start_Date__c = subStartDate;
 		td.lstSubscriptions[0].Low_Start_End_Date__c = subLowEndDate;
 		td.lstSubscriptions[0].Weekly_Price__c = 9;
 		td.lstSubscriptions[0].Low_Start_Weekly_Price__c = 4;
 		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
 		update td.lstSubscriptions;

    	List<Subscription__c> lstRefetched = [select Id,Product__c,RecordTypeId,RecordType.Name,Start_Date__c,Weekly_Price__c,Low_Start_Weekly_Price__c,Low_Start_End_Date__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        
        System.assert(!lstRefetched.isEmpty());
        System.assertNotEquals(null,lstRefetched[0].Product__c);

        Test.startTest();

      		Voucher_Adjustment__c newVoucher = TestDataUtility.newVoucherAdjustment(1,lstRefetched[0].Id,voucherStartDate,voucherEndDate);
      		insert newVoucher;
	        List<Voucher_Adjustment__c> lstVouchers = [select 	Id, 
	                                                            Voucher_Validity_in_Weeks_Calc__c, 
	                                                            Voucher_Value_Calc__c, 
	                                                            Number_of_Vouchers_Calc__c, 
	                                                            Start_Date__c,
	                                                            End_Date__c
	                                                        from Voucher_Adjustment__c 
	                                                        where Id=:newVoucher.Id];
			System.assert(!lstVouchers.isEmpty());
			System.assertNotEquals(null,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Value_Calc__c);
			System.assertEquals(4,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertEquals(1,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertEquals(4,lstVouchers[0].Voucher_Value_Calc__c);
        Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/10/2016
    Version - 1.0 
    Function - Verify coverage of generateDateCalc execution caused by Voucher_Adjustment__c record changes for Low Start Sub
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testVoucherValueCalculationNoLowStart(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkVoucherAdjustmentDependencies();
 		Date subStartDate = Date.newInstance(2016,10,1);
 		Date subLowEndDate = Date.newInstance(2016,11,10);
 		Date voucherStartDate = Date.newInstance(2016,12,05);
 		Date voucherEndDate = Date.newInstance(2016,12,15);

 		td.lstSubscriptions[0].Start_Date__c = subStartDate;
 		td.lstSubscriptions[0].Low_Start_End_Date__c = subLowEndDate;
 		td.lstSubscriptions[0].Weekly_Price__c = 9;
 		td.lstSubscriptions[0].Low_Start_Weekly_Price__c = 4;
 		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
 		update td.lstSubscriptions;

    	List<Subscription__c> lstRefetched = [select Id,Product__c,RecordTypeId,RecordType.Name,Start_Date__c,Weekly_Price__c,Low_Start_Weekly_Price__c,Low_Start_End_Date__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        
        System.assert(!lstRefetched.isEmpty());
        System.assertNotEquals(null,lstRefetched[0].Product__c);
        Test.startTest();

      		Voucher_Adjustment__c newVoucher = TestDataUtility.newVoucherAdjustment(1,lstRefetched[0].Id,voucherStartDate,voucherEndDate);
      		insert newVoucher;
	        List<Voucher_Adjustment__c> lstVouchers = [select 	Id, 
	                                                            Voucher_Validity_in_Weeks_Calc__c, 
	                                                            Voucher_Value_Calc__c, 
	                                                            Number_of_Vouchers_Calc__c, 
	                                                            Start_Date__c,
	                                                            End_Date__c
	                                                        from Voucher_Adjustment__c 
	                                                        where Id=:newVoucher.Id];
			System.assert(!lstVouchers.isEmpty());
			System.assertNotEquals(null,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Value_Calc__c);
			System.assertEquals(8,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertEquals(2,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertEquals(18,lstVouchers[0].Voucher_Value_Calc__c);
        Test.stopTest();
	}
	/*************************************************************************************** 
    Developer - Michal Szewczyk
    Date - 14/10/2016
    Version - 1.0 
    Function - Verify coverage of generateDateCalc execution caused by Voucher_Adjustment__c record changes for Low Start Sub
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testVoucherValueCalculationPartLowStart(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        td.checkVoucherAdjustmentDependencies();
 		Date subStartDate = Date.newInstance(2016,10,1);
 		Date subLowEndDate = Date.newInstance(2016,11,10);
 		Date voucherStartDate = Date.newInstance(2016,11,05);
 		Date voucherEndDate = Date.newInstance(2016,11,15);

 		td.lstSubscriptions[0].Start_Date__c = subStartDate;
 		td.lstSubscriptions[0].Low_Start_End_Date__c = subLowEndDate;
 		td.lstSubscriptions[0].Weekly_Price__c = 9;
 		td.lstSubscriptions[0].Low_Start_Weekly_Price__c = 4;
 		td.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
 		update td.lstSubscriptions;

    	List<Subscription__c> lstRefetched = [select Id,Product__c,RecordTypeId,RecordType.Name,Start_Date__c,Weekly_Price__c,Low_Start_Weekly_Price__c,Low_Start_End_Date__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        
        System.assert(!lstRefetched.isEmpty());
        System.assertNotEquals(null,lstRefetched[0].Product__c);

        Test.startTest();

      		Voucher_Adjustment__c newVoucher = TestDataUtility.newVoucherAdjustment(1,lstRefetched[0].Id,voucherStartDate,voucherEndDate);
      		insert newVoucher;
	        List<Voucher_Adjustment__c> lstVouchers = [select 	Id, 
	                                                            Voucher_Validity_in_Weeks_Calc__c, 
	                                                            Voucher_Value_Calc__c, 
	                                                            Number_of_Vouchers_Calc__c, 
	                                                            Start_Date__c,
	                                                            End_Date__c
	                                                        from Voucher_Adjustment__c 
	                                                        where Id=:newVoucher.Id];
			System.assert(!lstVouchers.isEmpty());
			System.assertNotEquals(null,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertNotEquals(null,lstVouchers[0].Voucher_Value_Calc__c);
			System.assertEquals(6,lstVouchers[0].Number_of_Vouchers_Calc__c);
			System.assertEquals(1.5,lstVouchers[0].Voucher_Validity_in_Weeks_Calc__c);
			System.assertEquals(8.5,lstVouchers[0].Voucher_Value_Calc__c);
        Test.stopTest();
	}
	/*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 09/12/2016
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void updateRefundTest(){

    	//create test data
    	Integer RECORDS_SIZE = 2; //counting from 0
    	Integer WEEK = 7;
    	Test.startTest();
    	TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE + 1);
    	tdu.createVoucherAdjustments();
    	for(Voucher_Adjustment__c va : tdu.lstVoucherAdjustment){
    		va.End_Date__c = va.Start_Date__c.addMonths(1);
    		va.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
        	va.Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN;
    	}
    	update tdu.lstVoucherAdjustment;
    	insert DefaultSettings.APPLICATION_CONFIGURATIONS;
    	TestDataUtility.updateThresholdValue(500);

    	//update records with expected refund status and dates to populate refund amount
    	List<Voucher_Adjustment__c> vouchersToUpdate = new List<Voucher_Adjustment__c>();
    	for(Integer i = 0; i < RECORDS_SIZE; i++){
    		vouchersToUpdate.add(new Voucher_Adjustment__c(Id = tdu.lstVoucherAdjustment[i].Id,
    			Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL,
    			Start_Date__c = tdu.lstSubscriptions[i].Start_Date__c,
            	End_Date__c = tdu.lstSubscriptions[i].Start_Date__c.addDays(WEEK)));
    	}
    	//updated last record with same status but refund amount value above threshold
    	vouchersToUpdate.add(new Voucher_Adjustment__c(Id = tdu.lstVoucherAdjustment[RECORDS_SIZE].Id,
    			Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_WAITING_FOR_APPROVAL,
    			Start_Date__c = tdu.lstSubscriptions[RECORDS_SIZE].Start_Date__c,
            	End_Date__c = tdu.lstSubscriptions[RECORDS_SIZE].Start_Date__c.addDays(32))); //6 weeks
    	update vouchersToUpdate;

    	//update all records to fire a trigger again
    	List<Voucher_Adjustment__c> testVoucherActivities = [ SELECT Id, Refund_Status__c, End_Date__c FROM Voucher_Adjustment__c]; 
    	for(Voucher_Adjustment__c va : testVoucherActivities){
    		va.End_Date__c = va.End_Date__c.addDays(WEEK);
    	}
    	update testVoucherActivities;

    	//assert results
    	List<Voucher_Adjustment__c> updatedVoucherActivities = [ SELECT Id, Refund_Status__c, Refund_Amount__c FROM Voucher_Adjustment__c 
    		WHERE Refund_Status__c = :Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING];
    	System.assertEquals(RECORDS_SIZE, updatedVoucherActivities.size());
    	Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 12/12/2016
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void updateChequeAmountTest(){
    	Test.startTest();
    	//create test data
    	Integer RECORDS_SIZE = 2;
    	Integer WEEK = 7;
    	DeferredCalculation.isTestScenario = true; //to minimize the number of SOQL queries
    	TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);
    	tdu.createVoucherAdjustments();
    	for(Voucher_Adjustment__c va : tdu.lstVoucherAdjustment){
    		va.End_Date__c = va.Start_Date__c.addMonths(1);
    		va.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
        	va.Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN;
    	}
    	update tdu.lstVoucherAdjustment;
    	tdu.createCheques();

    	//update records with expected refund status and dates to populate refund amount
    	List<Voucher_Adjustment__c> vouchersToUpdate = new List<Voucher_Adjustment__c>();
    	List<Cheque__c> chequesToUpdate = new List<Cheque__c>();
    	for(Integer i = 0; i < RECORDS_SIZE; i++){
    		vouchersToUpdate.add(new Voucher_Adjustment__c(Id = tdu.lstVoucherAdjustment[i].Id,
    			Refund_Status__c = Constants.VOUCHERADJUSTMENT_REFUND_STATUS_PENDING,
    			Refund_Method__c = Constants.VOUCHERADJUSTMENT_REFUND_METHOD_MANUAL_CHEQUE,
    			Start_Date__c = tdu.lstSubscriptions[i].Start_Date__c,
            	End_Date__c = tdu.lstSubscriptions[i].Start_Date__c.addDays(WEEK)));
    		//link voucher activities to cheques
    		chequesToUpdate.add(new Cheque__c(Id = tdu.lstCheques[i].Id,
    			Voucher_Activity__c = tdu.lstVoucherAdjustment[i].Id));
    	}
    	update vouchersToUpdate;
    	update chequesToUpdate;

    	//update all records to fire a trigger again
    	List<Voucher_Adjustment__c> testVoucherActivities = [ SELECT Id, Refund_Status__c, End_Date__c FROM Voucher_Adjustment__c]; 
    	for(Voucher_Adjustment__c va : testVoucherActivities){
    		va.End_Date__c = va.End_Date__c.addDays(WEEK);
    	}
    	update testVoucherActivities;

    	//assert results
    	Map<Id, Voucher_Adjustment__c> updatedVoucherActivitiesMap = new Map<Id, Voucher_Adjustment__c>(
    		[ SELECT Id, Refund_Amount__c FROM Voucher_Adjustment__c ]);
    	for(Cheque__c cheque : [ SELECT Id, Cheque_Amount__c, Voucher_Activity__c FROM Cheque__c]){
    		System.assertEquals(updatedVoucherActivitiesMap.get(cheque.Voucher_Activity__c).Refund_Amount__c, cheque.Cheque_Amount__c);
    	}
    	Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 09/02/2017
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void preventMultipleSameDateVoucherCreationTestNoConflict(){

    	Integer RECORDS_SIZE = 2;

    	Test.startTest();

    	TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);
    	tdu.createVoucherAdjustments();
    	for(Voucher_Adjustment__c va : tdu.lstVoucherAdjustment){
    		va.End_Date__c = va.Start_Date__c.addMonths(1);
    		va.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
        	va.Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN;
    	}
    	update tdu.lstVoucherAdjustment;

    	List<Voucher_Adjustment__c> lstTestVoucher = [ SELECT Id, Start_Date__c, End_Date__c, Subscription__c FROM Voucher_Adjustment__c ];
    	System.assertEquals(2, lstTestVoucher.size());

    	List<Voucher_Adjustment__c> lstNewVouchers = new List<Voucher_Adjustment__c>();

    	System.assertNotEquals(lstTestVoucher[0].Subscription__c, lstTestVoucher[1].Subscription__c);

    	//define new vouchers
    	lstNewVouchers.add(createHolidayReturnVoucher(lstTestVoucher[0].Subscription__c, 
    		lstTestVoucher[0].Start_Date__c.addMonths(2), lstTestVoucher[0].Start_Date__c.addMonths(3)));
    	lstNewVouchers.add(createHolidayReturnVoucher(lstTestVoucher[1].Subscription__c, 
    		lstTestVoucher[1].Start_Date__c.addMonths(2), lstTestVoucher[1].Start_Date__c.addMonths(3)));

    	insert lstNewVouchers;

    	List<Voucher_Adjustment__c> lstResults = [ SELECT Id, Start_Date__c, End_Date__c FROM Voucher_Adjustment__c ];
    	System.assertEquals(4, lstResults.size());

    	Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 09/02/2017
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void preventMultipleSameDateVoucherCreationTestWithConflicts(){

    	Integer RECORDS_SIZE = 3;

    	Test.startTest();

    	TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);
    	tdu.createVoucherAdjustments();
    	for(Voucher_Adjustment__c va : tdu.lstVoucherAdjustment){
    		va.End_Date__c = va.Start_Date__c.addMonths(1);
    		va.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
        	va.Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN;
    	}
    	update tdu.lstVoucherAdjustment;

    	List<Voucher_Adjustment__c> lstTestVoucher = [ SELECT Id, Start_Date__c, End_Date__c, Subscription__c FROM Voucher_Adjustment__c ];
    	System.assertEquals(RECORDS_SIZE, lstTestVoucher.size());

    	List<Voucher_Adjustment__c> lstNewVouchers = new List<Voucher_Adjustment__c>();

    	//define new vouchers

    	//within period
    	lstNewVouchers.add(createHolidayReturnVoucher(lstTestVoucher[0].Subscription__c, 
    		lstTestVoucher[0].Start_Date__c.addDays(1), lstTestVoucher[0].End_Date__c.addDays(-1)));

    	//start date in period
    	lstNewVouchers.add(createHolidayReturnVoucher(lstTestVoucher[1].Subscription__c, 
    		lstTestVoucher[1].Start_Date__c.addDays(1), lstTestVoucher[1].End_Date__c.addDays(1)));

    	//same start date and end date in period
    	lstNewVouchers.add(createHolidayReturnVoucher(lstTestVoucher[2].Subscription__c, 
    		lstTestVoucher[2].Start_Date__c, lstTestVoucher[2].End_Date__c.addDays(-1))); 	

    	try{
    		insert lstNewVouchers;
    		System.assert(false, 'Insertion expected to fail'); 
    	} catch(DmlException e){
    		System.assert(true, 'None of new voucher were inserted');
    		System.assert(e.getMessage().contains(Label.Voucher_Activity_Already_Exist_With_Same_Dates), e.getMessage());
    	}
 
    	List<Voucher_Adjustment__c> lstResults = [ SELECT Id, Start_Date__c, End_Date__c FROM Voucher_Adjustment__c ];
    	System.assertEquals(RECORDS_SIZE, lstResults.size());

    	Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 09/02/2016
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static Voucher_Adjustment__c createHolidayReturnVoucher(Id subscriptionId, Date startDate, Date endDate){
    	Voucher_Adjustment__c voucher = TestDataUtility.newVoucherAdjustment(1, subscriptionId, startDate, endDate);
    	voucher.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
        voucher.Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN;
        return voucher;
    }

    /*************************************************************************************** 
    Developer - Vishant Shah
    Date - 20/04/2017
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void overlapTest(){

    	Integer RECORDS_SIZE = 1;

    	Test.startTest();

    	TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);

    	tdu.createVoucherAdjustments();
    	
    	Voucher_Adjustment__c va 	  = tdu.lstVoucherAdjustment[0];
		va.End_Date__c                = va.Start_Date__c.addMonths(1);
		va.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
    	va.Adjustment_Type__c 		  = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_HOLIDAYRETURN;
    	update va;

    	Voucher_Adjustment__c newVoucher 	  = createHolidayReturnVoucher(va.Subscription__c, va.Start_Date__c, va.End_Date__c);
    	newVoucher.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSSENT;
    	insert newVoucher;

    	Voucher_Adjustment__c insertedVA = [SELECT Id, Start_Date__c, End_Date__c, Overlaps_Other_Voucher_Activity__c, Voucher_Activity_Action__c 
    										  FROM Voucher_Adjustment__c 
    										 WHERE Voucher_Activity_Action__c = :Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSSENT LIMIT 1];
    	
    	System.assertNotEquals(null, insertedVA, 'Overlap VA didnot get inserted');
    	System.assertNotEquals(va.Voucher_Activity_Action__c, insertedVA.Voucher_Activity_Action__c, 'VA and insertedVA should have different actions');
    	System.assertEquals(va.Start_Date__c, insertedVA.Start_Date__c, 'Start Dates should match');
    	System.assertEquals(va.End_Date__c, insertedVA.End_Date__c, 'End Dates should match');
    	System.assertEquals(insertedVA.Overlaps_Other_Voucher_Activity__c, Label.Overlap_With_Other_Voucher_Activity, 'Overlap field should have the warning message');

    	Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Konrad Czykin
    Date - 23/05/2017
    Version - 1.0 
    #############Change Log#############
	Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void overlapTestPreNotificationHoliday(){

    	Integer RECORDS_SIZE = 1;

    	Test.startTest();

    	TestDataUtility tdu = new TestDataUtility(RECORDS_SIZE);

    	tdu.createVoucherAdjustments();
    	
    	Voucher_Adjustment__c va 	  = tdu.lstVoucherAdjustment[0];
		va.End_Date__c                = va.Start_Date__c.addMonths(1);
		va.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
    	va.Adjustment_Type__c 		  = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_PRENOTIFICATIONHOLIDAY;
    	update va;

    	Voucher_Adjustment__c newVoucher 	  = createHolidayReturnVoucher(va.Subscription__c, va.Start_Date__c, va.End_Date__c);
    	newVoucher.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED;
    	va.Adjustment_Type__c 		  = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_PRENOTIFICATIONHOLIDAY;
    	insert newVoucher;

    	Voucher_Adjustment__c insertedVA = [SELECT Id, Start_Date__c, End_Date__c, Overlaps_Other_Voucher_Activity__c, Voucher_Activity_Action__c 
    										  FROM Voucher_Adjustment__c 
    										 WHERE Voucher_Activity_Action__c = :Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSRECEIVED LIMIT 1];
    	
    	System.assertNotEquals(null, insertedVA, 'Overlap VA didnot get inserted');
    	System.assertEquals(va.Voucher_Activity_Action__c, insertedVA.Voucher_Activity_Action__c, 'VA and insertedVA should have the same actions');
    	System.assertEquals(va.Start_Date__c, insertedVA.Start_Date__c, 'Start Dates should match');
    	System.assertEquals(va.End_Date__c, insertedVA.End_Date__c, 'End Dates should match');
    	System.assertNotEquals(insertedVA.Overlaps_Other_Voucher_Activity__c, Label.Overlap_With_Other_Voucher_Activity, 'Overlap field should not have the warning message');

    	Test.stopTest();

    }

}