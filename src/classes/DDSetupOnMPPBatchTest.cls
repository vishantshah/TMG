/**
* Author:       Unknown
* Date:         Unknown
* Description:  Test class for   
* ******************* Change Log *******************
* Modified by       Change Date 
* Wiktor Czykin     25/02/2016  //removed usage of TestDataUtility.loadPlaneUrl()
**/
@isTest(SeeAllData=false)
private class DDSetupOnMPPBatchTest {
    //Build Test data for Batch
    public static  void initTestData(string ddStage) {
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        
        Profile prof = [Select Id from Profile where Name ='TMG System' limit 1];
        User usr = [Select Id from User where ProfileId=:prof.id and IsActive=true limit 1];
        //system.runAs(usr)
        {
        Account acc = new Account(Title__c = 'MR',
                    FirstName = 'TMG First',
                    LastName = 'TMG Last',
                    IsUsingMPP__c = false,
                    PersonEmail = 'tmgtesting@test.com',
                    PersonMailingStreet= '8 Forest Drive East',
                    PersonMailingCity = 'London',
                    PersonMailingState = 'Walthamstow',
                    PersonMailingPostalCode = 'E11 1JY',
                    Guid__c='123456abcdefg', 
                    Subscriber_Number_static__c = 'TS10921');
        
        insert acc;
        
    
        Subscription__c subActive = new Subscription__c(Subscriber__c = acc.Id,
                            Subscription_Status__c = 'Active',
                            Is_MPP_DDCCA_Letter_Extracted__c = false,
                            Start_Date__c = Date.today().addDays(21).toStartOfWeek(),
                            Payment_Details_Received__c = true,
                            Weekly_Price__c = 6.50,
                            Payment_Type__c = 'Direct Debit',
                            isContinuous__c = true,
                            Delivery_Type__c = 'OTC',
                            Voucher_Pack_Duration__c = 5);
        insert subActive;
        
        Subscription__c subOffered = new Subscription__c(Subscriber__c = acc.Id,
                            Subscription_Status__c = 'Offered',
                            Is_MPP_DDCCA_Letter_Extracted__c = false,
                            Start_Date__c = Date.today().addMonths(15).toStartOfWeek(),
                            Weekly_Price__c = 6.50,
                            Payment_Type__c = 'Direct Debit',
                            Delivery_Type__c = 'OTC',
                            Previous_Subscription__c=subActive.id,
                            MppDDCalloutStage__c=ddStage,
                            MppDDCalloutAttemptCount__c=0,
                            Voucher_Pack_Duration__c = 14); 
        insert subOffered;



        Account acc2 = new Account(Title__c = 'MR',
                    FirstName = 'TMG First',
                    LastName = 'TMG Last',
                    PersonEmail = 'tmgtesting2@test.com',
                    PersonMailingStreet= '8 Forest Drive East',
                    PersonMailingCity = 'London',
                    PersonMailingState = 'Walthamstow',
                    PersonMailingPostalCode = 'E11 1JY',
                    Guid__c='123456abcdefgh', 
                    IsUsingMPP__c=true,
                    Subscriber_Number_static__c = 'TS109212');
        
        insert acc2;
        

        Subscription__c subActive2 = new Subscription__c(Subscriber__c = acc2.Id,
                            Subscription_Status__c = 'Active',
                            Is_MPP_DDCCA_Letter_Extracted__c = false,
                            Start_Date__c = Date.today().addDays(21).toStartOfWeek(),
                            Payment_Details_Received__c = true,
                            Weekly_Price__c = 6.50,
                            Payment_Type__c = 'Direct Debit',
                            isContinuous__c = true,
                            Delivery_Type__c = 'OTC',
                            Subscription_Duration_Picklist__c='52',
                            MPP_DD_Frequency__c='Monthly',
                            PaymentDate__c='15',
                            MPP_Scheduled_First_Payment_Date__c = System.today(),
                            Voucher_Pack_Duration__c = 5);
        insert subActive2; 
        
        Subscription__c subOffered2 = new Subscription__c(Subscriber__c = acc2.Id,
                            Subscription_Status__c = 'Offered',
                            Is_MPP_DDCCA_Letter_Extracted__c = false,
                            Start_Date__c = Date.today().addMonths(15).toStartOfWeek(),
                            Weekly_Price__c = 6.50,
                            Payment_Type__c = 'Direct Debit',
                            isContinuous__c = true,
                            Delivery_Type__c = 'OTC',
                            Previous_Subscription__c=subActive2.id,
                            MppDDCalloutAttemptCount__c=0,
                            Voucher_Pack_Duration__c = 14); 
                       
        insert subOffered2;
        

        if(PlaneURL__c.getInstance('MPP')==null)
        {
                PlaneURL__c customSetting = new PlaneURL__c();
                customSetting.Name='MPP';
                customSetting.URL__c='http://';
                customSetting.baseURL__c='http://';
                customSetting.login__c='1234';
                customSetting.password__c='test$pwd';
                customSetting.Digital_Annually_ID__c='1111';
                customSetting.Digital_Monthly_ID__c='2222';
                customSetting.Premium_Continuous_ID__c='3333';
                insert customSetting;
        }       
        }
    }

   
    public static testMethod void testUserManageBatch() {
	    Test.startTest();
	    initTestData(null);
	    ID batchprocessid = Database.executeBatch(new DDSetupOnMPPBatch((new MPPBulkUserManageScheduler()).query+' limit 2','UserManage'));
	    Test.stopTest();
    }
 
   public static testMethod void testPaymentScheduleBatch() {
        Test.startTest();
        initTestData('DirectDebit');
        ID batchprocessid3 = Database.executeBatch(new DDSetupOnMPPBatch((new MPPBulkPaymentScheduleScheduler()).query+' limit 2','PaymentSchedule'));
        Test.stopTest();
   }
   
	public static testMethod void testGetPaymentScheduleBatch() {
    Test.startTest();
    initTestData('GetPayment-Failed');
    //System.assert(false, Database.query((new MPPBulkGetPaymentDetailsScheduler()).query+' limit 2') + '===' +  (new MPPBulkGetPaymentDetailsScheduler()).query+' limit 2');
    ID batchprocessid3 = Database.executeBatch(new DDSetupOnMPPBatch((new MPPBulkGetPaymentDetailsScheduler()).query+' limit 2','GetPayment'));
    Test.stopTest();
  }
   
      public static testMethod void testLapsedSubPaymentScheduleBatch() {
        Test.startTest();
        initTestData('GetPayment');
        String qry = 'Select Name,start_date__c, Previous_Subscription__c, total_price__c, TCode__r.Name, Order_Taken_By_Company__c, Order_Taken_By_User_Department__c, Order_Taken_Method__c, PaymentDate__c, Previous_Subscription__r.End_Date__c, Subscriber__r.Subscriber_Number__c, Subscriber__r.IsUsingMPP__c, Subscriber__r.Subscriber_Digital_Status__c, Previous_Subscription__r.MPP_Scheduled_First_Payment_Date__c, Previous_Subscription__r.Subscription_Duration_Picklist__c, Previous_Subscription__r.MPP_DD_Frequency__c, Previous_Subscription__r.MPP_CC_Frequency__c, Previous_Subscription__r.Payment_Type__c, Previous_Subscription__r.PaymentDate__c, MPP_Premium_Subscription_ID__c, MppDDCalloutAttemptCount__c,MppDDCalloutStage__c,MppDDLastCalloutDateTime__c,MPP_CC_First_Payment_Amount__c' 
									 + ' from Subscription__c limit 2'; 
        ID batchprocessid3 = Database.executeBatch(new DDSetupOnMPPBatch(qry,'LapsedSubPaymentSchedule'));
        Test.stopTest();
   }
   
   public static testMethod void testDDSchedulers()
   {
   	
	    Test.startTest();
	    //Schedulers test
	    String nextYear = String.valueof(date.Today().addYears(1).year());
	    String jobId = System.schedule('DDSetupOnMPPBatch'+Math.random(), '00 50 16 29 AUG ? '+nextYear, new MPPBulkUserManageScheduler());
	    jobId = System.schedule('DDSetupOnMPPBatch'+Math.random(), '00 50 16 29 AUG ? '+nextYear, new MPPBulkPaymentScheduleScheduler());
	    jobId = System.schedule('DDSetupOnMPPBatch'+Math.random(), '00 50 16 29 AUG ? '+nextYear, new MPPBulkGetPaymentDetailsScheduler());
    
    	Test.stopTest();  
             
   }

    /*************************************************************************************** 
    Developer - Unknown 
    Date - Unknown
    Version - 1.1
    Description - 
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         24/02/2016  //removed usage on old PlaneUrl adding
    ****************************************************************************************/
	public static testMethod void testDDSetupOnMPPBatchThreading() {
		TestDataUtility td = new TestDataUtility(1);
        td.loadPlaneURL();

        Test.startTest();
    		DDSetupOnMPPBatch obj1 = new DDSetupOnMPPBatch((new MPPBulkUserManageScheduler()).query + ' limit 2', 'UserManage');
    		DDSetupOnMPPBatch obj2 = new DDSetupOnMPPBatch((new MPPBulkUserManageScheduler()).query + ' limit 2', 'UserManage');
    		List<sobject> scope = Database.query(new MPPBulkUserManageScheduler().query + ' limit 2');
    		
    		obj1.start(null);
    		obj1.execute(null, scope);
    		obj2.start(null);
    		obj2.execute(null, scope);
    		obj2.finish(null);
    		obj1.finish(null);
    		
    		DDSetupOnMPPBatch obj5 = new DDSetupOnMPPBatch((new MPPBulkPaymentScheduleScheduler()).query + ' limit 2', 'PaymentSchedule');
    		DDSetupOnMPPBatch obj6 = new DDSetupOnMPPBatch((new MPPBulkPaymentScheduleScheduler()).query + ' limit 2', 'PaymentSchedule');
    		scope = Database.query(new MPPBulkPaymentScheduleScheduler().query + ' limit 2');
    		
    		obj5.start(null);
    		obj5.execute(null, scope);
    		obj6.start(null);
    		obj6.execute(null, scope);
    		obj6.finish(null);
    		obj5.finish(null);
    		
    		DDSetupOnMPPBatch obj7 = new DDSetupOnMPPBatch((new MPPBulkGetPaymentDetailsScheduler()).query + ' limit 2', 'GetPayment');
    		DDSetupOnMPPBatch obj8 = new DDSetupOnMPPBatch((new MPPBulkGetPaymentDetailsScheduler()).query + ' limit 2', 'GetPayment');
    		scope = Database.query(new MPPBulkGetPaymentDetailsScheduler().query + ' limit 2');
    		
    		obj7.start(null);
    		obj7.execute(null, scope);
    		obj8.start(null);
    		obj8.execute(null, scope);
    		obj8.finish(null);
    		obj7.finish(null);
    		
    		
    		String qry = 'Select Name,start_date__c, Previous_Subscription__c, total_price__c, TCode__r.Name, Order_Taken_By_Company__c,Order_Taken_By_User_Department__c, Order_Taken_Method__c, PaymentDate__c, Previous_Subscription__r.End_Date__c, Subscriber__r.Subscriber_Number__c, Subscriber__r.IsUsingMPP__c, Subscriber__r.Subscriber_Digital_Status__c, Previous_Subscription__r.MPP_Scheduled_First_Payment_Date__c, Previous_Subscription__r.Subscription_Duration_Picklist__c, Previous_Subscription__r.MPP_DD_Frequency__c, Previous_Subscription__r.MPP_CC_Frequency__c, Previous_Subscription__r.Payment_Type__c, Previous_Subscription__r.PaymentDate__c, MPP_Premium_Subscription_ID__c, MppDDCalloutAttemptCount__c,MppDDCalloutStage__c,MppDDLastCalloutDateTime__c,MPP_CC_First_Payment_Amount__c from Subscription__c limit 2'; 
    		DDSetupOnMPPBatch obj9 = new DDSetupOnMPPBatch(qry, 'LapsedSubPaymentSchedule');
    		DDSetupOnMPPBatch obj10 = new DDSetupOnMPPBatch(qry, 'LapsedSubPaymentSchedule');
    		scope = Database.query(qry);
    		
    		obj9.start(null);
    		obj9.execute(null, scope);
    		obj10.start(null);
    		obj10.execute(null, scope);
    		obj10.finish(null);
    		obj9.finish(null);
		Test.stopTest();		
	}
}