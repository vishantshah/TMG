/************************************************************************************
Developer - Cristina Popescu
Date - 16/06/2015
Version - 1.0
Function - test soft and hard cancellation
#############Change Log#############
Modified by     	Version     Change Date
Cristina Anghenie	1.1			24/08/2015	//test soft cancellation multiple cancellation record for the same subscription
Wiktor Czykin       1.2         25/02/2016  //removed references to old TestDataUtility methods
Pawel Chrzanowski	1.3			26/04/2016	//updated to use Constants for cancellation status
*************************************************************************************/
@isTest
private class DigitalSubscriptionCancellationTest {
	/************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.1
    Function - test error messages for soft cancellation
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //changed how test data is created
    *************************************************************************************/
    static testMethod void testNegativeSoftCancellation() {
        TestDataUtility tdu = new TestDataUtility(1);
       
        List<PlaneURL__c> pURL = tdu.loadPlaneURL();
        tdu.createDigitalMPPTransactionHistory(Constants.ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE);
        //create cancellation record
        Cancellation__c cancellation = new Cancellation__c();
        //create account
        Account acc = tdu.lstDigitalSubscribers[0];
        acc.Subscriber_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        update acc;
        //create MPP transaction history
        MPP_Transaction_History__c transHistory = tdu.lstMPPTransactionHistory[0];
        transHistory.Order_ID__c = '9789765hgj';
        transHistory.DD_Transaction_Type__c = '';
        transHistory.Payment_Status__c = Constants.ORDER_SUCCESS_STATUS_VALUE;
        update transHistory;
        
        Test.startTest();
	        test.setCurrentPage(Page.DigitalSubscriptionCancellation);
	        ApexPages.currentPage().getParameters().put('accId',acc.Id);
	        ApexPages.currentPage().getParameters().put('type','soft');
	        DigitalSubscriptionCancellation stdCtrl = new DigitalSubscriptionCancellation(new ApexPages.StandardController(cancellation));
	        System.assertEquals(acc.Id,stdCtrl.accountId);
	        System.assertEquals('soft',stdCtrl.cancelationType);
	        stdCtrl.save();
	        System.assertEquals(Label.Reason_Cancellation,stdCtrl.cancelationMsg);
	        
	        cancellation.Cancellation_Reason__c = 'Price';
	        stdCtrl.save();
	        System.assertEquals(Label.Details_Reason_Cancellation,stdCtrl.cancelationMsg);
			
			cancellation.Reason_Details__c = 'Other';
			cancellation.Other_Reason__c = '';
			stdCtrl.save();
	        System.assertEquals(Label.Other_Reason_Details,stdCtrl.cancelationMsg);
	        
	        cancellation.Other_Reason__c = 'Other Reason';
	        stdCtrl.save();
	        System.assertEquals(Label.Wrong_Service_ID,stdCtrl.cancelationMsg);
			
	        acc.Subscriber_Digital_Status__c = Constants.SSTATUS_INACTIVE;
	        update acc;
	        stdCtrl.save();
	        System.assertEquals(Label.Cancel_Inactive_Account,stdCtrl.cancelationMsg);
        Test.stopTest(); 
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.1
    Function - test soft cancellation functionality works
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //changed how test data is created
	Pawel Chrzanowski 1.2 		26/04/2016	//updated to use Constants for cancellation status
    *************************************************************************************/
    static testMethod void testPositiveSoftCancellation() {
        TestDataUtility tdu = new TestDataUtility(1);
        List<PlaneURL__c> pURL = tdu.loadPlaneURL();
        tdu.createDigitalMPPTransactionHistory(Constants.ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE);
        //create cancellation record
        Cancellation__c cancellation = new Cancellation__c();
        //create account
        Account acc = tdu.lstDigitalSubscribers[0];
        acc.MPP_Service_Id__c = '123456';
        acc.Subscriber_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        update acc;
        //create MPP transaction history
        MPP_Transaction_History__c transHistory = tdu.lstMPPTransactionHistory[0];
        transHistory.Order_ID__c = '9789765hgj';
        transHistory.DD_Transaction_Type__c = '';
        transHistory.Payment_Status__c = Constants.ORDER_SUCCESS_STATUS_VALUE;
        update transHistory;
        
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pURL[0].baseURL__c, new Map<String,String>{MPPWebserviceMocks.PARAM_IS_RENEWAL => 'false'});
        	Test.setMock(HttpCalloutMock.class, mock);
        	
	        test.setCurrentPage(Page.DigitalSubscriptionCancellation);
	        ApexPages.currentPage().getParameters().put('accId',acc.Id);
	        ApexPages.currentPage().getParameters().put('type', Constants.SHORT_SOFT_CANCELLATION);
	        DigitalSubscriptionCancellation stdCtrl = new DigitalSubscriptionCancellation(new ApexPages.StandardController(cancellation));
	        System.assertEquals(acc.Id,stdCtrl.accountId);
	        System.assertEquals('soft',stdCtrl.cancelationType);
	        
	        cancellation.Cancellation_Reason__c = 'Price';
	        cancellation.Reason_Details__c = 'Other';
	        cancellation.Other_Reason__c = 'Other Reason';
	        stdCtrl.save();
	        System.assertEquals(Label.Subscriptions_Cancelled,stdCtrl.cancelationMsg);
        Test.stopTest(); 
        
        cancellation = [SELECT Id,Account__c, MPP_Transaction_History__c, Cancelled_Date__c, Cancellation_Type__c, Cancellation_Reason__c, Reason_Details__c, Other_Reason__c, Cancellation_Status__c FROM Cancellation__c WHERE Account__c =: acc.Id];
        System.assertEquals(transHistory.Id,cancellation.MPP_Transaction_History__c);
        System.assertEquals(Constants.SOFT_CANCELLATION,cancellation.Cancellation_Type__c);
        System.assertEquals(System.today(),cancellation.Cancelled_Date__c);
        System.assertEquals('Price',cancellation.Cancellation_Reason__c);
        System.assertEquals('Other',cancellation.Reason_Details__c);
        System.assertEquals('Other Reason',cancellation.Other_Reason__c);
        System.assertEquals(Constants.COMPLETE_CANCELLATION_STATUS,cancellation.Cancellation_Status__c);
        
        acc = [SELECT Id, MPP_Service_Id__c, Subscriber_Digital_Status__c, Cancelled_Date__c, Cancelled_By__c, Cancellation_Type__c FROM Account WHERE Id =: acc.Id];
        System.assertEquals(System.today(),acc.Cancelled_Date__c);
        System.assertEquals(UserInfo.getUserId(),acc.Cancelled_By__c);
        System.assertEquals(Constants.SOFT_CANCELLATION,acc.Cancellation_Type__c);
        System.assertEquals(true,stdCtrl.wasCancelled);
        
        for(ApexPages.Message message : ApexPages.getMessages()){
        	System.assertEquals(Label.Subscriptions_Cancelled,message.getSummary());
        }
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.1
    Function - test error messages for hard cancellation
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //changed how test data is created
    *************************************************************************************/
    static testMethod void testNegativeHardCancellation() {
        TestDataUtility tdu = new TestDataUtility();
        tdu.createDigitalSubscribers();
        //create cancellation record
        Cancellation__c cancellation = new Cancellation__c();
        //create account
        Account acc = tdu.lstDigitalSubscribers[0];
        Test.startTest();
	        test.setCurrentPage(Page.DigitalSubscriptionCancellation);
	        ApexPages.currentPage().getParameters().put('accId',acc.Id);
	        ApexPages.currentPage().getParameters().put('type','hard');
	        DigitalSubscriptionCancellation stdCtrl = new DigitalSubscriptionCancellation(new ApexPages.StandardController(cancellation));
	        acc.Subscriber_Digital_Status__c = Constants.SSTATUS_INACTIVE;
	        update acc;
	        
	        stdCtrl.save();
	        System.assertEquals(Label.Cancel_Inactive_Account,stdCtrl.cancelationMsg);
	        
	        acc.Subscriber_Digital_Status__c = Constants.SSTATUS_ACTIVE;
	        update acc;
	        cancellation.Cancellation_Reason__c = 'Price';
	        stdCtrl.save();
	        System.assertEquals(Label.Details_Reason_Cancellation,stdCtrl.cancelationMsg);
			
			cancellation.Reason_Details__c = 'Other';
			cancellation.Other_Reason__c = '';
			stdCtrl.save();
	        System.assertEquals(Label.Other_Reason_Details,stdCtrl.cancelationMsg);
	        
	        cancellation.Other_Reason__c = 'Other Reason';
	        stdCtrl.save();
	        System.assertEquals(Label.No_Transaction_History,stdCtrl.cancelationMsg);
	        

            tdu.createDigitalMPPTransactionHistory(Constants.ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE);
	        MPP_Transaction_History__c transHistory = tdu.lstMPPTransactionHistory[0];
	        transHistory.Payment_Status__c = Constants.ORDER_SUCCESS_STATUS_VALUE;
	        transHistory.DD_Transaction_Type__c = '';
	        transHistory.Order_ID__c = null;
	        update transHistory;
	        stdCtrl.save();
	        System.assertEquals(Label.Wrong_Service_ID,stdCtrl.cancelationMsg);
	        
	        acc.MPP_Service_Id__c = '1234';
	        update acc;
	        stdCtrl.save();
        Test.stopTest();
        System.assertEquals(Label.No_Order_ID,stdCtrl.cancelationMsg);
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 16/06/2015
    Version - 1.1
    Function - test hard cancellation functionality
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         25/02/2016  //changed how test data is created
    *************************************************************************************/
    static testMethod void testPositiveHardCancellation() {
        TestDataUtility tdu = new TestDataUtility();
        tdu.createDigitalMPPTransactionHistory(Constants.ORDER_PAYMENT_TYPE_DIRECT_DEBIT_VALUE);
        List<PlaneURL__c> pURL = tdu.loadPlaneURL();
        //create cancellation record
        Cancellation__c cancellation = new Cancellation__c();
        //create account
        Account acc = tdu.lstDigitalSubscribers[0];
        acc.Subscriber_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        acc.MPP_Service_Id__c = '1234';
        update acc;
        //create MPP transaction history
        MPP_Transaction_History__c transHistory = tdu.lstMPPTransactionHistory[0];
        transHistory.Order_ID__c = '9789765hgj';
        transHistory.DD_Transaction_Type__c = '';
        transHistory.Payment_Status__c = Constants.ORDER_PENDING_STATUS_VALUE;
        update transHistory;
        
        Test.startTest();
       		MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pURL[0].baseURL__c, new Map<String,String>{});
        	Test.setMock(HttpCalloutMock.class, mock);
        	
	        test.setCurrentPage(Page.DigitalSubscriptionCancellation);
	        ApexPages.currentPage().getParameters().put('accId',acc.Id);
	        ApexPages.currentPage().getParameters().put('type','hard');
	        DigitalSubscriptionCancellation stdCtrl = new DigitalSubscriptionCancellation(new ApexPages.StandardController(cancellation));
	        cancellation.Cancellation_Reason__c = 'Price';
	        cancellation.Reason_Details__c = 'Other';
	        cancellation.Other_Reason__c = 'Other Reason';
	        stdCtrl.save();
	        System.assertEquals(Label.Subscriptions_Cancelled_With_Refund + ' £90.00', stdCtrl.cancelationMsg);
	        stdCtrl.back();
		Test.stopTest();
		
		cancellation = [SELECT Id,Account__c, MPP_Transaction_History__c, Cancelled_Date__c, Cancellation_Type__c FROM Cancellation__c WHERE Account__c =: acc.Id];
        System.assertEquals(transHistory.Id,cancellation.MPP_Transaction_History__c);
        System.assertEquals(Constants.HARD_CANCELLATION,cancellation.Cancellation_Type__c);
        System.assertEquals(System.today(),cancellation.Cancelled_Date__c);
        System.assertEquals(true,stdCtrl.wasCancelled);
        
        acc = [SELECT Id, MPP_Service_Id__c, Subscriber_Digital_Status__c, Cancelled_Date__c, Cancelled_By__c, Cancellation_Type__c FROM Account WHERE Id =: acc.Id];
        System.assertEquals(System.today(),acc.Cancelled_Date__c);
        System.assertEquals(UserInfo.getUserId(),acc.Cancelled_By__c);
        System.assertEquals(Constants.HARD_CANCELLATION,acc.Cancellation_Type__c);
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 26/08/2015
    Version - 1.0
    Function - test renewal functionality
    #############Change Log#############
    Modified by     Version     Change Date
    *************************************************************************************/
    static testMethod void testReactivateSubscriptionPositives() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        List<PlaneURL__c> pURL = tdu.loadPlaneURL();
        //create cancellation and all dependent records
        tdu.createCancellation();
        tdu.lstDigitalSubscribers[0].MPP_Service_Id__c = '123456';
        tdu.lstDigitalSubscribers[0].Subscriber_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        tdu.lstDigitalSubscribers[0].Cancellation_Type__c = 'Soft Cancel';
        update tdu.lstDigitalSubscribers[0];
        
        tdu.lstMPPTransactionHistory[0].Order_ID__c = '9789765hgj';
        tdu.lstMPPTransactionHistory[0].DD_Transaction_Type__c = '';
        tdu.lstMPPTransactionHistory[0].Payment_Status__c = Constants.ORDER_SUCCESS_STATUS_VALUE;
        update tdu.lstMPPTransactionHistory[0];
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pURL[0].baseURL__c, new Map<String,String>{MPPWebserviceMocks.PARAM_IS_RENEWAL => 'true'});
        	Test.setMock(HttpCalloutMock.class, mock);
	        String result = DigitalSubscriptionCancellation.ReactivateSubscription(tdu.lstDigitalSubscribers[0].Id);
    	Test.stopTest();
    	
    	System.assertEquals(Constants.REACTIVATION_SUCCESSFULL,result);
        Cancellation__c cnx = [SELECT Id, Cancellation_Status__c FROM Cancellation__c WHERE Account__c =: tdu.lstDigitalSubscribers[0].Id];
		System.assertEquals(Constants.REVOKED_CANCELLATION_STATUS,cnx.Cancellation_Status__c);
		Account acc = [SELECT Id, Cancellation_Type__c, Cancelled_By__c, Cancelled_Date__c FROM Account WHERE Id=: tdu.lstDigitalSubscribers[0].Id];
		System.assertEquals(null,acc.Cancellation_Type__c);
		System.assertEquals(null,acc.Cancelled_By__c);
		System.assertEquals(null,acc.Cancelled_Date__c);
    }
    
    /************************************************************************************
    Developer - Cristina Popescu
    Date - 26/08/2015
    Function - test renewal functionality
    #############Change Log#############
    Modified by     Version     Change Date
	Pawel Chrzanowski 1.1 		26/04/2016	//updated to use Constants for cancellation status
    *************************************************************************************/
    static testMethod void testReactivateSubscriptionNegatives() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        List<PlaneURL__c> pURL = tdu.loadPlaneURL();
        //create cancellation and all dependent records
        tdu.createCancellation();
        tdu.lstDigitalSubscribers[0].MPP_Service_Id__c = '123456';
        tdu.lstDigitalSubscribers[0].Subscriber_Digital_Status__c = Constants.SSTATUS_ACTIVE;
        tdu.lstDigitalSubscribers[0].Cancellation_Type__c = 'Hard Cancel';
        update tdu.lstDigitalSubscribers[0];
        
        tdu.lstMPPTransactionHistory[0].Order_ID__c = '9789765hgj';
        tdu.lstMPPTransactionHistory[0].DD_Transaction_Type__c = '';
        tdu.lstMPPTransactionHistory[0].Payment_Status__c = Constants.ORDER_SUCCESS_STATUS_VALUE;
        update tdu.lstMPPTransactionHistory[0];
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pURL[0].baseURL__c, new Map<String,String>{MPPWebserviceMocks.PARAM_IS_RENEWAL => 'true'});
        	Test.setMock(HttpCalloutMock.class, mock);
	        String result = DigitalSubscriptionCancellation.ReactivateSubscription(tdu.lstDigitalSubscribers[0].Id);
	        System.assertEquals(Label.Cancellation_ReactivationOnSoft,result);
	        
	        tdu.lstDigitalSubscribers[0].Cancellation_Type__c = 'Soft Cancel';
        	update tdu.lstDigitalSubscribers[0];
        	
        	tdu.lstCancellations[0].Cancellation_Status__c ='Revoked';
        	update tdu.lstCancellations[0];
        	result = DigitalSubscriptionCancellation.ReactivateSubscription(tdu.lstDigitalSubscribers[0].Id);
        	System.assertEquals(Label.Cancellation_NoCancellationToRevoke,result);
        	
        	tdu.lstCancellations[0].Cancellation_Status__c = Constants.COMPLETE_CANCELLATION_STATUS;
        	update tdu.lstCancellations[0];
        	tdu.lstDigitalSubscribers[0].MPP_Service_Id__c = null;
        	update tdu.lstDigitalSubscribers[0];
        	result = DigitalSubscriptionCancellation.ReactivateSubscription(tdu.lstDigitalSubscribers[0].Id);
    	Test.stopTest();
    	
    	System.assertEquals(Label.Wrong_Service_ID,result);
    }
}