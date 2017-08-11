/**
* @author Unknown
* @date Unknown
* @description Test class for DeferredCalculation class
#############Change Log#############
Modified by         Version     Change Date
Wiktor Czykin       1.1         17-22/06/2015  	//rewritten
Mantas Grigaliunas  1.3         13/01/2017 	//added test method testDDNotCompletedPaymentsSumFieldUpdate
Mantas Grigaliunas  1.2         18/11/2016 //removed Voucher Activity Refund_Due field updated
**/
@isTest(SeeAllData=false)
private class DeferredCalculationTest {
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 19/06/2015
    Version - 1.0
    Function -  test constructor and check that subs adding works correctly
    #############Change Log#############
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1         17/01/2017 //modified assertion after additional param was introduced in class
    ****************************************************************************************/
    private static testMethod void testConstructorAndGettingSubscriptionData(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        DeferredCalculation.isTestScenario = true;
        td.createSubscriptions();

        Test.startTest();
            DeferredCalculation.DeferredAssetCalc calculator = new DeferredCalculation.DeferredAssetCalc();     
            System.assertNotEquals(null, calculator.mapSubscription);
            System.assertNotEquals(null, calculator.mapSubscriptionSums);

            Set<Id> setSubscriptionIds = new Set<Id>();
            for(Subscription__c s : td.lstSubscriptions){
                setSubscriptionIds.add(s.Id);
            }
            calculator.addSubsForProcessing(setSubscriptionIds);

            System.assertEquals(td.iCounter, calculator.mapSubscription.size());
            System.assertEquals(td.iCounter, calculator.mapSubscriptionSums.size());

            for(List<Decimal> lstDecimals : calculator.mapSubscriptionSums.values()){
                System.assertEquals(4, lstDecimals.size());
                System.assertEquals(0, lstDecimals[0]+lstDecimals[1]+lstDecimals[2]);
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 19/06/2015
    Version - 1.0
    Function -  check that retrieval of related data works
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSubscriptionRelatedDataRetrieval(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        DeferredCalculation.isTestScenario = true;
        td.createMPPTransactionHistory(TestDataUtility.PAYMENTMETHOD_CC);
        td.createVoucherAdjustments();
        td.createCheques();

        Set<Id> setSubscriptionIds = new Set<Id>();
        for(Subscription__c s : td.lstSubscriptions){
            setSubscriptionIds.add(s.Id);
        }
        Test.startTest();
            DeferredCalculation.DeferredVoucherCalc calculator = new DeferredCalculation.DeferredVoucherCalc();     
            
            calculator.addSubsForProcessing(setSubscriptionIds);
            calculator.GetSubData();
        Test.stopTest();
        System.assertEquals(1, calculator.vouchers.size());
        System.assertEquals(1, calculator.cheques.size());
        System.assertEquals(1, calculator.mppTransactions.size());
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 19/06/2015
    Version - 1.0
    Function -  check of Asset_Calc__c field calculation
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testSubscriptionCountingOfAssets(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        DeferredCalculation.isTestScenario = true;
        td.createMPPTransactionHistory(TestDataUtility.PAYMENTMETHOD_CC);
        td.createVoucherAdjustments();
        td.createCheques();

        Set<Id> setSubscriptionIds = new Set<Id>();
        for(Subscription__c s : td.lstSubscriptions){
            setSubscriptionIds.add(s.Id);
        }

        Voucher_Adjustment__c va1 = TestDataUtility.newVoucherAdjustment(1, td.lstSubscriptions[0].Id, td.lstVoucherAdjustment[0].Start_Date__c, td.lstVoucherAdjustment[0].End_Date__c);
        va1.Voucher_Activity_Action__c = Constants.VOUCHERADJUSTMENT_ACTIVITYACTION_VOUCHERSSENT;
        Voucher_Adjustment__c va2 = TestDataUtility.newVoucherAdjustment(1, td.lstSubscriptions[0].Id, td.lstVoucherAdjustment[0].Start_Date__c, td.lstVoucherAdjustment[0].End_Date__c);
        va2.Voucher_Activity_Action__c = 'some other';
        va2.Adjustment_Type__c = Constants.VOUCHERADJUSTMENT_ACTIVITYTYPE_GOODWILL;
        List<Voucher_Adjustment__c> lstToAdd = new List<Voucher_Adjustment__c>{va1, va2};
        insert lstToAdd;


        Test.startTest();
            DeferredCalculation.DeferredAssetCalc calculator = new DeferredCalculation.DeferredAssetCalc();     
            calculator.addSubsForProcessing(setSubscriptionIds);
            calculator.GetSubData();
            calculator.Calculate();
            calculator.UpdateValues();
        Test.stopTest();
        Set<Id> setVouchers = new Set<Id>{lstToAdd[0].Id, lstToAdd[1].Id, td.lstVoucherAdjustment[0].Id};
        Map<Id,Voucher_Adjustment__c> mapVouchers = new Map<Id, Voucher_Adjustment__c>([select  Id, 
                                                                                                Deferred_Asset_Value__c, 
                                                                                                Voucher_Activity_Action__c, 
                                                                                                Date_Vouchers_Received__c, 
                                                                                                Adjustment_Type__c ,
                                                                                                Voucher_Value__c
                                                                                            from Voucher_Adjustment__c 
                                                                                            where Id in :setVouchers]);
        System.assertEquals(3, mapVouchers.size());

        Decimal dToCompare = -mapVouchers.get(td.lstVoucherAdjustment[0].Id).Deferred_Asset_Value__c - mapVouchers.get(va2.Id).Voucher_Value__c + mapVouchers.get(va1.Id).Voucher_Value__c;

        List<Subscription__c> lstRefetched = [select Id, Asset_Calc__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(dToCompare, lstRefetched[0].Asset_Calc__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 22/06/2015
    Version - 1.0
    Function - check of Liab_Calc__c value population based on subscription related items
    #############Change Log#############
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1        18/11/2016 //removed Voucher Activity Refund_Due field updated
    ****************************************************************************************/
    private static testMethod void testSubscriptionCountingOfLiabilityAndPayment(){
        TestDataUtility td = new TestDataUtility(1);
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        DeferredCalculation.isTestScenario = true;
        td.createMPPTransactionHistory(TestDataUtility.PAYMENTMETHOD_CC);
        td.createVoucherAdjustments();
        td.createCheques();

        Decimal oldPaymentTotal = 101;
        Set<Id> setSubscriptionIds = new Set<Id>();
        for(Subscription__c s : td.lstSubscriptions){
            setSubscriptionIds.add(s.Id);
            s.Old_Payment_Method_Total__c = oldPaymentTotal;
        }
        update td.lstSubscriptions;
        //add refund cheque
        Cheque__c refundCheque = TestDataUtility.newCheque(1, td.lstChequeBatches[0].Id, td.lstIndividualSubscribers[0].Id, td.lstSubscriptions[0].Id);
        refundCheque.Type__c = Constants.CHEQUE_TYPE_REFUND;
        refundCheque.Cheque_Refund_Reason__c = 'test';
        refundCheque.Cheque_Amount__c = 50;
        insert refundCheque;

        //add refund MPP
        MPP_Transaction_History__c mpp = TestDataUtility.newMPPTransactionHistory(1, td.lstIndividualSubscribers[0].Id, td.lstSubscriptions[0].Id, TestDataUtility.PAYMENTMETHOD_CC);
        mpp.Payment_status__c = Constants.MPPTRANSACTION_PAYMENTSTATUS_REFUND;
        insert mpp;
		td.lstVoucherAdjustment[0].Refund_Due__c = true;
        update td.lstVoucherAdjustment;
		
        Test.startTest();
            DeferredCalculation.DeferredRevenueCalc calculator = new DeferredCalculation.DeferredRevenueCalc();     
            calculator.addSubsForProcessing(setSubscriptionIds);
            calculator.GetSubData();
            calculator.Calculate();
            calculator.UpdateValues();
        Test.stopTest();
        Map<Id,Voucher_Adjustment__c> mapVouchers = new Map<Id, Voucher_Adjustment__c>([select  Id, 
                                                                                                Deferred_Asset_Value__c, 
                                                                                                Voucher_Activity_Action__c, 
                                                                                                Date_Vouchers_Received__c, 
                                                                                                Adjustment_Type__c ,
                                                                                                Voucher_Value__c
                                                                                            from Voucher_Adjustment__c 
                                                                                            where Id in :td.lstVoucherAdjustment]);
        System.assertEquals(1, mapVouchers.size());
        Decimal dToCompare = -refundCheque.Cheque_Amount__c + td.lstCheques[0].Cheque_Amount__c - mpp.Total_Price__c + td.lstMPPTransactionHistory[0].Total_Price__c + oldPaymentTotal;
        List<Subscription__c> lstRefetched = [select Id, Liab_Calc__c, Sum_of_Payments__c from Subscription__c where Id = :td.lstSubscriptions[0].Id];
        System.assert(!lstRefetched.isEmpty());
        System.assertEquals(dToCompare + mapVouchers.get(td.lstVoucherAdjustment[0].Id).Voucher_Value__c, lstRefetched[0].Liab_Calc__c);
        System.assertEquals(dToCompare, lstRefetched[0].Sum_of_Payments__c);
    }

    /*************************************************************************************** 
    Developer - Mantas Grigaliunas
    Date - 13/01/2017
    Version - 1.0
    Function - test for DD_Not_Completed_Payments_Sum__c field update
    #############Change Log#############
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1         13/01/2017  //added assertion for DD_Not_Completed_Payments_Sum__c
    ****************************************************************************************/
    private static testMethod void testDDNotCompletedPaymentsSumFieldUpdate(){
        Test.startTest();
        TestDataUtility td = new TestDataUtility(1);
        td.createMPPTransactionHistory(TestDataUtility.PAYMENTMETHOD_DD);
        List<Subscription__c> lstRefetched = [SELECT Id, DD_Not_Completed_Payments_Sum__c FROM Subscription__c WHERE Id = :td.lstSubscriptions[0].Id];
        System.assertEquals(td.lstMPPTransactionHistory[0].Total_Price__c, lstRefetched[0].DD_Not_Completed_Payments_Sum__c);
        Test.stopTest();
    }
}