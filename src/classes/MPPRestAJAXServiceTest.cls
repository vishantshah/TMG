/**
* @author Wiktor Czykin
* @date 14/05/2015
* @description Test class for SubscriberConsoleController -> methods mostly moved here from old SubscriberConsoleTest method
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         11/06/2015  //added methods to separately cover getFrequency() method. Updated test methods to cater for removed getPaymentDetailsCallout api callout
Wiktor Czykin   1.2         09-10/07/2015  //modified test methods to add different reference to mpp offset value, test fixes
Cristina Anghenie1.3		14/09/2015	//update test method because testResponse was moved to MPPWebserviceMocks

**/
@isTest(SeeAllData=false)
private class MPPRestAJAXServiceTest{

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 22/05/2015
    Version - 1.0
    Function - test init for all methods
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @testSetup static void init(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadPlaneURL();
		tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Positive scenario for payment reactivation - here place for refactoring as currently it is using hardcoded mock
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/05/2015  //removed unnecessary tests, brought back assertion
    ****************************************************************************************/
    private static testMethod void testReactivatePaymentResultValid(){
        Test.startTest();
            String result = MPPRestAJAXService.getReactivatePaymentResult(null);
        Test.stopTest();
        System.assert(result.toLowerCase().contains('successfully'));
    }

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Negative scenario for payment reactivation - here place for refactoring as currently it is using hardcoded mock
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/05/2015  //removed unnecessary tests, added extra one for standard exception hit, brought back assertion
    Cristina Anghenie1.2		14/09/2015	//update test method because testResponse was moved to MPPWebserviceMocks
    ****************************************************************************************/
    static testMethod void testReactivatePaymentResultInvalid(){
        Test.startTest();
            //failure because error returned from MPP
            MPPRestAJAXService.setTestXML(MPPWebserviceMocks.getCancelPaymentScheduleXML(new Map<String,String>{MPPWebserviceMocks.PARAM_ISFAILURE => 'isfailure'}));
            String result = MPPRestAJAXService.getReactivatePaymentResult('1047');
            System.assert(result.toLowerCase().contains('error'));

            //standard exception because invalid xml
            MPPRestAJAXService.setTestXML('non xml');
            String result2 = MPPRestAJAXService.getReactivatePaymentResult('1047');
            System.assert(result2.toLowerCase().contains('error'));
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Positive scenario for payment cancellation - here place for refactoring as currently it is using hardcoded mock
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/05/2015  //removed unnecessary tests, brought back assertion
    Cristina Anghenie1.2		14/09/2015	//update test method because testResponse was moved to MPPWebserviceMocks
    ****************************************************************************************/
    static testMethod void testCancelPaymentResultValid(){
        TestDataUtility tdu = new TestDataUtility();
		tdu.loadPlaneURL();
		Test.startTest();	
			MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_AMOUNT => '468',
                MPPWebserviceMocks.PARAM_NOSCHEDULES => '12',
                MPPWebserviceMocks.PARAM_CURRENCY => 'GBP',
                MPPWebserviceMocks.PARAM_PAYMENTSCHID => '12345555'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String result = MPPRestAJAXService.getCancelPaymentResult('12345555');
        Test.stopTest();
        System.assert(result.toLowerCase().contains('successfully'));
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - Negative scenario for payment cancellation - here place for refactoring as currently it is using hardcoded mock
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         22/05/2015  //removed unnecessary tests, added extra one for standard exception hit, brought back assertion
    Cristina Anghenie1.2		14/09/2015	//update test method because testResponse was moved to MPPWebserviceMocks
    ****************************************************************************************/
    static testMethod void testCancelPaymentResultInvalid(){
        TestDataUtility tdu = new TestDataUtility();
		tdu.loadPlaneURL();
        Test.startTest();
            //failure because error returned from MPP
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISFAILURE => 'isfailure'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String result = MPPRestAJAXService.getCancelPaymentResult('1047');
            System.assert(result.toLowerCase().contains('error'));

            MPPRestAJAXService.setTestXML('invalid xml');
            String result2 = MPPRestAJAXService.getCancelPaymentResult('1047');
            System.assert(result.toLowerCase().contains('error'));
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 22/05/2015
    Version - 1.0
    Function - Positive and negative scenarios for subscription fetching
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testRetrieveSubscriptionByMPPSubID(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        update td.lstSubscriptions;
        Test.startTest();
            //record found
            Subscription__c s = MPPRestAJAXService.retrieveSubscriptionByMPPSubID('123');
            System.assert(s != null);

            //no param
            try{
                MPPRestAJAXService.retrieveSubscriptionByMPPSubID(null);
                System.assert(false, 'exception not thrown where should be');
            }catch(TelegraphApplicationException e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_Missing_schedule_id_error));
            }

            //record not found
            try{
                MPPRestAJAXService.retrieveSubscriptionByMPPSubID('nonExistingVal');
                System.assert(false, 'exception not thrown where should be');
            }catch(TelegraphApplicationException e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_Could_not_retrieve_subscription_based_on_schedule_id));
            }
        Test.stopTest();
    }
   
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.2
    Function - Positive scenario where payment date is updated - simulating montly frequency
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/06/2015  //added frequency to record as no longer fetched from MPP(mock)
    Wiktor Czykin   1.2         09/07/2015  //changed method signature
    Cristina Anghenie1.3		10/09/2015	//check if MPP_DD_First_Payment_Amount__c gets overwritten when ChangePaymentDay or UpdatePaymentStartDate buttons are clicked
    ****************************************************************************************/
    private static testMethod void testChangePaymentDatePositiveMonthly(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
        td.lstSubscriptions[0].MPP_DD_First_Payment_Amount__c = 125.00;
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '15',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-05-13T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String sResult = MPPRestAJAXService.getChangePaymentDateResult(     '123', 
                                                                                td.lstSubscriptions[0].Start_Date__c.format(), 
                                                                                td.lstSubscriptions[0].PaymentDate__c 
                                                                                );
        Test.stopTest();
        Date toCheck = Date.newInstance(2016, 6, 15);
        List<Account> lstAccount = [select Id, MPP_CurrentPayScheduleEndDate__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        System.assertNotEquals(null, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);
        System.assertEquals(toCheck, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);

        List<Subscription__c> lstSubscription = [select Id, MPP_Pay_Schedule_End_Date__c, PaymentDate__c, MPP_DD_First_Payment_Amount__c from Subscription__c where Id =: td.lstSubscriptions[0].Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertNotEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(toCheck, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals('15', lstSubscription[0].PaymentDate__c);
        System.assertEquals(125.00, lstSubscription[0].MPP_DD_First_Payment_Amount__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.2
    Function - Positive scenario where payment date is updated - simulating quarterly frequency
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/06/2015  //added frequency to record as no longer fetched from MPP(mock)
    Wiktor Czykin   1.2         09/07/2015  //changed method signature
    Cristina Anghenie1.3		10/09/2015	//check if MPP_DD_First_Payment_Amount__c gets overwritten when ChangePaymentDay or UpdatePaymentStartDate buttons are clicked
    ****************************************************************************************/
    private static testMethod void testChangePaymentDatePositiveQuarterly(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_QUARTERLY;
        td.lstSubscriptions[0].MPP_DD_First_Payment_Amount__c = 125.00;
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '15',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-05-13T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String sResult = MPPRestAJAXService.getChangePaymentDateResult(     '123', 
                                                                                td.lstSubscriptions[0].Start_Date__c.format(), 
                                                                                td.lstSubscriptions[0].PaymentDate__c);
        Test.stopTest();
        Date toCheck = Date.newInstance(2016, 8, 15);
        List<Account> lstAccount = [select Id, MPP_CurrentPayScheduleEndDate__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        System.assertNotEquals(null, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);
        System.assertEquals(toCheck, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);

        List<Subscription__c> lstSubscription = [select Id, MPP_Pay_Schedule_End_Date__c, PaymentDate__c, MPP_DD_First_Payment_Amount__c from Subscription__c where Id =: td.lstSubscriptions[0].Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertNotEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(toCheck, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals('15', lstSubscription[0].PaymentDate__c);
        System.assertEquals(125.00, lstSubscription[0].MPP_DD_First_Payment_Amount__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.2
    Function - Positive scenario where payment date is updated - simulating annual frequency
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/06/2015  //added frequency to record as no longer fetched from MPP(mock)
    Wiktor Czykin   1.2         09/07/2015  //changed method signature
    Cristina Anghenie1.3		10/09/2015	//check if MPP_DD_First_Payment_Amount__c gets overwritten when ChangePaymentDay or UpdatePaymentStartDate buttons are clicked
    ****************************************************************************************/
    private static testMethod void testChangePaymentDatePositiveAnnual(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_ANNUAL;
        td.lstSubscriptions[0].MPP_DD_First_Payment_Amount__c = 125.00;
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '15',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-05-13T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String sResult = MPPRestAJAXService.getChangePaymentDateResult(     '123', 
                                                                                td.lstSubscriptions[0].Start_Date__c.format(), 
                                                                                td.lstSubscriptions[0].PaymentDate__c);
        Test.stopTest();
        Date toCheck = Date.newInstance(2017, 5, 15);
        List<Account> lstAccount = [select Id, MPP_CurrentPayScheduleEndDate__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        System.assertNotEquals(null, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);
        System.assertEquals(toCheck, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);

        List<Subscription__c> lstSubscription = [select Id, MPP_Pay_Schedule_End_Date__c, PaymentDate__c, MPP_DD_First_Payment_Amount__c from Subscription__c where Id =: td.lstSubscriptions[0].Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertNotEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(toCheck, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals('15', lstSubscription[0].PaymentDate__c);
        System.assertEquals(125.00, lstSubscription[0].MPP_DD_First_Payment_Amount__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - test retrievePaymentScheduleEndDateBasedOnOrders() - tested outside flow for negative scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testRetrievePaymentScheduleEndDateBasedOnOrdersNegative(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        update td.lstSubscriptions;

        Subscription__c s = MPPRestAJAXService.retrieveSubscriptionByMPPSubID('123');
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));

        MPPInterfaceHTTP callout = new MPPInterfaceHTTP();
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-05-13T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            
            //no frequency passed
            try{
                MPPRestAJAXService.retrievePaymentScheduleEndDateBasedOnOrders(callout, null, s);
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_Missing_frequency_in_payment_details), e.getMessage());
            }

            //no orders tocontinue processing
            mock.mapParams.put(MPPWebserviceMocks.PARAM_TOTALORDERS, '0');
            try{
                MPPRestAJAXService.retrievePaymentScheduleEndDateBasedOnOrders(callout, Constants.DD_COL_FREQ_MONTHLY, s);
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_No_orders_in_MPP), e.getMessage());
            }

            //date parsing issue
            mock.mapParams.remove(MPPWebserviceMocks.PARAM_TOTALORDERS);
            mock.mapParams.put(MPPWebserviceMocks.PARAM_LASTORDER_DATE, 'xxxxx');
            try{
                MPPRestAJAXService.retrievePaymentScheduleEndDateBasedOnOrders(callout, Constants.DD_COL_FREQ_MONTHLY, s);
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_Date_conversion_error_in_order_fetching), e.getMessage());
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.1
    Function - Negative scenario where subscription status is not applicable for processing
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         09/07/2015  //changed method signature
    ****************************************************************************************/
    private static testMethod void testChangePaymentInvalidStatusError(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_WITHDRAWN;
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            String sResult = MPPRestAJAXService.getChangePaymentDateResult(     '123', 
                                                                                td.lstSubscriptions[0].Start_Date__c.format(), 
                                                                                td.lstSubscriptions[0].PaymentDate__c);
            System.assertEquals(Label.MPP_Communication_Frequency_and_payment_data_validation, sResult);
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.3
    Function - Negative scenario where Payment Schedule End Date retrieved is not accurate
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         11/06/2015  //added frequency to record as no longer fetched from MPP(mock)
    Wiktor Czykin   1.2         09/07/2015  //changed method signature and added force fail as code is now autofixing the day
    ****************************************************************************************/
   	private static testMethod void testChangePaymentDateNegativeWrongDate(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;

        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '15',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-05-09T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            MPPRestAJAXService.bTestFail = true;
            String sResult = MPPRestAJAXService.getChangePaymentDateResult(     '123', 
                                                                                td.lstSubscriptions[0].Start_Date__c.format(), 
                                                                                td.lstSubscriptions[0].PaymentDate__c);
        Test.stopTest();
        System.assert(sResult.contains(Label.MPP_Communication_Unable_to_update_account_as_wrong_pay_schedule_end_date), sResult);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - Negative scenario - payment details method entry blow up
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testRetrievePaymentDetailsNegative(){
        Test.startTest();
            try{
                MPPRestAJAXService.retrievePaymentDetails(null, null);
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_Missing_parameters_for_payment_details_callout));
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - Negative scenario - payment details method entry blow up
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testRetrievePaymentDetailsPositive(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();

        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{});
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 

            MPPInterfaceHTTP callout = new MPPInterfaceHTTP();
            List<Account> lstSub = [select Id, Subscriber_Number_static__c from Account where Id in :td.lstIndividualSubscribers];
            System.assert(lstSub.size()==1);
            try{
               MPPInterfaceHTTP.PaymentDetailResult pd = MPPRestAJAXService.retrievePaymentDetails(callout, lstSub[0].Subscriber_Number_static__c);
                System.assertNotEquals(null, pd);
            }catch(Exception e){
                System.assert(false, 'exception thrown where should not be');
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - Positive scenario for payment schedule edit
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPaymentScheduleUpdateFrequencyPositive(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].Payment_Type__c = 'Credit Card';
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_FREQUENCY => Constants.DD_COL_FREQ_QUARTERLY,
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '1',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-04-29T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String sResult = MPPRestAJAXService.getEditPaymentScheduleResult(   '123', 
                                                                                '1000', 
                                                                                Constants.DD_COL_FREQ_QUARTERLY
                                                                                );
        Test.stopTest();
        Date toCheck = Date.newInstance(2016, 8, 1);
        List<Account> lstAccount = [select Id, MPP_CurrentPayScheduleEndDate__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        System.assertNotEquals(null, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);
        System.assertEquals(toCheck, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);

        List<Subscription__c> lstSubscription = [select Id, MPP_Pay_Schedule_End_Date__c, PaymentDate__c from Subscription__c where Id =: td.lstSubscriptions[0].Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertNotEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(toCheck, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals('1', lstSubscription[0].PaymentDate__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 11/06/2015
    Version - 1.0
    Function - Positive scenario for payment schedule edit when frequency is not passed and it is to be taken from subscription
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPaymentScheduleUpdateFrequencyNotSet(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].Payment_Type__c = 'Credit Card';
        td.lstSubscriptions[0].MPP_CC_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;

        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '1',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-04-29T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String sResult = MPPRestAJAXService.getEditPaymentScheduleResult(   '123', 
                                                                                '1000', 
                                                                                Constants.DD_COL_FREQ_NOTSET
                                                                                );
        Test.stopTest();
        Date toCheck = Date.newInstance(2016, 6, 1);
        List<Account> lstAccount = [select Id, MPP_CurrentPayScheduleEndDate__c from Account where Id =: td.lstIndividualSubscribers[0].Id];
        System.assert(!lstAccount.isEmpty());
        System.assertNotEquals(null, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);
        System.assertEquals(toCheck, lstAccount[0].MPP_CurrentPayScheduleEndDate__c);

        List<Subscription__c> lstSubscription = [select Id, MPP_Pay_Schedule_End_Date__c, PaymentDate__c from Subscription__c where Id =: td.lstSubscriptions[0].Id];
        System.assert(!lstSubscription.isEmpty());
        System.assertNotEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals(toCheck, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
        System.assertEquals('1', lstSubscription[0].PaymentDate__c);
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.0
    Function - Negative scenario for payment schedule edit - status criteria not met
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPaymentScheduleUpdateFrequencyNegativeEntryCriteriaNotMet(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].Subscription_Status__c = Constants.SSTATUS_WITHDRAWN;
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            String sResult = MPPRestAJAXService.getEditPaymentScheduleResult(   '123', 
                                                                                '1000', 
                                                                                Constants.DD_COL_FREQ_QUARTERLY
                                                                                );
            System.assert(sResult.contains(Label.MPP_Communication_Frequency_and_payment_data_validation));
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 26/05/2015
    Version - 1.1
    Function - Negative scenario for payment schedule edit - wrong date returned based on orders
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         10/07/2015  //set failing flag to true -> to prevent day autofix
    ****************************************************************************************/
    private static testMethod void testPaymentScheduleUpdateFrequencyNegativeWrongDate(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].Payment_Type__c = 'Credit Card';
        update td.lstSubscriptions;
        PlaneURL__c pu = PlaneURL__c.getInstance('MPP');
        System.assert(pu != null && String.isNotBlank(pu.baseURL__c));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(pu.baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_FREQUENCY => Constants.DD_COL_FREQ_QUARTERLY,
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '1',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-04-09T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            MPPRestAJAXService.bTestFail = true;
            String sResult = MPPRestAJAXService.getEditPaymentScheduleResult(   '123', 
                                                                                '1000', 
                                                                                Constants.DD_COL_FREQ_QUARTERLY
                                                                                );
            System.assert(sResult.contains(Label.MPP_Communication_Unable_to_update_account_as_wrong_pay_schedule_end_date));
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 11/06/2015
    Version - 1.0
    Function - Positive check that getFrequency() returns what it should based on input parameters (CC check)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetFrequencyPositiveCredtiCard(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        td.lstSubscriptions[0].MPP_CC_Frequency__c = Constants.DD_COL_FREQ_QUARTERLY;
        Test.startTest();
            System.assertEquals(Constants.DD_COL_FREQ_QUARTERLY, MPPRestAJAXService.getFrequency(td.lstSubscriptions[0]));
        Test.stopTest();

    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 11/06/2015
    Version - 1.0
    Function - Positive check that getFrequency() returns what it should based on input parameters (DD check)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testGetFrequencyPositiveDebit(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_DD;
        td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_QUARTERLY;
        Test.startTest();
            String sFrequency = '';
            try{
                sFrequency = MPPRestAJAXService.getFrequency(td.lstSubscriptions[0]);
                System.assertEquals(Constants.DD_COL_FREQ_QUARTERLY, sFrequency);
            }catch(Exception e){
                System.assert(false, 'exception thrown where should not be');
            }
        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 11/06/2015
    Version - 1.0
    Function - Negative check that getFrequency() throws exception when frequency cannot be identified
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
     private static testMethod void testGetFrequencyNegative(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].Payment_Type__c = Constants.SUB_PMETHOD_CC;
        td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_QUARTERLY;
        Test.startTest();
            try{
                System.assertEquals(Constants.DD_COL_FREQ_QUARTERLY, MPPRestAJAXService.getFrequency(td.lstSubscriptions[0]));
                System.assert(false, 'exception not thrown where should be');
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.MPP_Communication_Unable_to_retrieve_frequency));
            }
        Test.stopTest();
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 10/09/2015
    Version - 1.0
    Function - check amount field and frequency are updated when ChangeFrequency or updatePaymentSchedule buttons are clicked
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testEditPaymentScheduleMethod(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        td.lstSubscriptions[0].MPP_Premium_Subscription_ID__c = '123';
        td.lstSubscriptions[0].PaymentDate__c = '1';
        td.lstSubscriptions[0].Payment_Type__c = 'Direct Debit';
        update td.lstSubscriptions;
        td.loadPlaneURL();
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(td.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_FREQUENCY => Constants.DD_COL_FREQ_QUARTERLY,
                MPPWebserviceMocks.PARAM_COLLECTION_DATE => '1',
                MPPWebserviceMocks.PARAM_LASTORDER_DATE => '2016-04-29T00:00:00'
            });
            MPPInterfaceHTTP.bRunTest = true;
            Test.setMock(HttpCalloutMock.class, mock); 
            String sResult = MPPRestAJAXService.getEditPaymentScheduleResult(   '123', 
                                                                                '1000', 
                                                                                Constants.DD_COL_FREQ_QUARTERLY
                                                                                );
        Test.stopTest();
    	List<Subscription__c> lstSubscription = [select Id, MPP_Pay_Schedule_End_Date__c, PaymentDate__c,MPP_DD_Frequency__c,MPP_DD_First_Payment_Amount__c from Subscription__c where Id =: td.lstSubscriptions[0].Id];
    	System.assertNotEquals(null, lstSubscription[0].MPP_Pay_Schedule_End_Date__c);
    	System.assertEquals('1', lstSubscription[0].PaymentDate__c);
    	System.assertEquals(Constants.DD_COL_FREQ_QUARTERLY,lstSubscription[0].MPP_DD_Frequency__c);
    	System.assertEquals(125.00,lstSubscription[0].MPP_DD_First_Payment_Amount__c);
    }
}