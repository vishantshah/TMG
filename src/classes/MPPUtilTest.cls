/**
* @author Unknown
* @date Unknown
* @description Test class for MPPUtil
#############Change Log#############
Modified by         Version     Change Date
Cristina Anghenie   1.1         18/08/2015
Wiktor Czykin       1.2         08/09/2015  //modified testSubscriberOneOffAmountPrint()
Wiktor Czykin		1.3			11/11/2015	//added testBackButtonV2()
Wiktor Czykin       1.4         26/05/2016  //modified testPremiumPayment();
Vishant Shah		1.5			04/11/2016  //added assert for one time payment reason
Wiktor Czykin		1.6			16/01/2017  //added testExceptionOnWrongPrice()
**/
@isTest
private with sharing class MPPUtilTest {

	/***************************************************************************************
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function -
	#############Change Log#############
	Modified by     	Version     Change Date
	Cristina Anghenie	1.1			18/08/2015	//increase code coverage
	****************************************************************************************/
	static testMethod void testSubscriberOneOffAmountDigital(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadPlaneURL();
		tdu.loadSAMHTTPSettings();
		tdu.loadGeneral();
		tdu.createPOCs(1);
		tdu.lstTCodeManagement[0].Type__c = 'Open Offer';
		update tdu.lstTCodeManagement[0];
		tdu.createIncentives();
		Account digitalSubscriber = TestDataUtility.newPersonAccount(1,Constants.DigitalSubscriberRecordType());
		insert digitalSubscriber;

		Test.startTest();
			Test.setCurrentPage(Page.SubscriberOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', digitalSubscriber.Id);
			ApexPages.currentPage().getParameters().put('incentiveMsg',tdu.lstIncentives[0].Name);
			ApexPages.currentPage().getParameters().put('isOneOffPayment','true');
			ApexPages.currentPage().getParameters().put('oneOffPaymentReason','Other');
			MppUtil paymentProcess = new MppUtil();

			ApexPages.StandardController con = new ApexPages.StandardController(digitalSubscriber);
			ApexPages.currentPage().getParameters().put('Id', digitalSubscriber.Id);

			paymentProcess = new MppUtil(con);
			System.assertEquals('Digital',paymentProcess.oneOffProductType);
			paymentProcess.oneOffAmount = null;
			System.assertEquals(null, paymentProcess.submitOneOffPaymentAmount());
			paymentProcess.oneOffAmount = 'ABC';
			System.assertEquals(null, paymentProcess.submitOneOffPaymentAmount());
			paymentProcess.oneOffAmount = '0.00';
			System.assertEquals(null, paymentProcess.submitOneOffPaymentAmount());
			paymentProcess.oneOffAmount = '10.00';
			System.assertEquals('/apex/oneoffpaymentprocessor?oneOffAmount=10.00&oneOffPaymentReason=null&productType=Digital&recordId=' + digitalSubscriber.Id, paymentProcess.submitOneOffPaymentAmount().getUrl());
			ApexPages.CurrentPage().getParameters().put('productType','Digital');
			ApexPages.CurrentPage().getParameters().put('oneOffAmount','10.00');
			ApexPages.CurrentPage().getParameters().put('recordId',digitalSubscriber.Id);
			Test.setMock(WebServiceMock.class, new MPPWebserviceMocks.MppPaymentInterfaceMock());
			try{
				paymentProcess.checkOneOffPayment();
			}catch(Exception ex) {}

		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Cristina Anghenie
	Date - 18/08/2015
	Version - 1.1
	Function - test MPPutil functionality for Premium account
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         08/09/2015  //update after change to goToPremiumContinuousPayment() and goToDigitalContinuousPayment() methods signature
	Vishant Shah	1.5			04/11/2016  //added assert for one time payment reason.
	****************************************************************************************/
	static testMethod void testSubscriberOneOffAmountPrint(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadPlaneURL();
		tdu.loadSAMHTTPSettings();
		tdu.loadGeneral();
		tdu.createPOCs(1);
		tdu.lstTCodeManagement[0].Type__c = 'Open Offer';
		update tdu.lstTCodeManagement[0];
		tdu.createIncentives();
		tdu.createSubscriptions();

		Test.startTest();
			ApexPages.StandardController con = new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]);
			Test.setCurrentPage(Page.SubscriberOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', tdu.lstIndividualSubscribers[0].Id);
			MppUtil paymentProcess = new MppUtil(con);
			System.assertEquals('Premium',paymentProcess.oneOffProductType);

			tdu.lstSubscriptions[0].Payment_Type__c = 'Direct Debit';
			tdu.lstSubscriptions[0].PaymentDate__c = '15';
			update tdu.lstSubscriptions[0];

			con = new ApexPages.StandardController(tdu.lstSubscriptions[0]);
			Test.setCurrentPage(Page.SubscriptionOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', tdu.lstSubscriptions[0].Id);

			paymentProcess = new MppUtil(con);
			paymentProcess.oneOffAmount = '10.00';

			paymentProcess.oneOffPaymentReason = Constants.NONE_PICKLIST_VALUE;
			ApexPages.CurrentPage().getParameters().put('currentPageName', 'SubscriptionOneOffPaymentAmount');

			paymentProcess.submitOneOffPaymentAmount();
			System.debug('ApexPages.getMessages() - ' + ApexPages.getMessages());
			Boolean hasPaymentReasonError = ApexPages.getMessages()[0].getDetail().contains(Label.One_Time_Payment_Reason_Not_Selected);
			System.assertEquals(true, hasPaymentReasonError, 'One Off payment reason should be entered');

			ApexPages.CurrentPage().getParameters().put('oneOffPaymentReason', 'Other');

			paymentProcess = new MppUtil(con);
			paymentProcess.oneOffAmount = '10.00';
			System.assertEquals('/apex/oneoffpaymentprocessor?oneOffAmount=10.00&oneOffPaymentReason=null&productType=Premium&recordId=' + tdu.lstSubscriptions[0].Id, paymentProcess.submitOneOffPaymentAmount().getUrl());
			ApexPages.CurrentPage().getParameters().put('productType','Premium');
			ApexPages.CurrentPage().getParameters().put('oneOffAmount','10.00');
			ApexPages.CurrentPage().getParameters().put('recordId',tdu.lstSubscriptions[0].id);
			paymentProcess.PaymentMethod = 'DirectDebit';
			Test.setMock(WebServiceMock.class, new MPPWebserviceMocks.MppPaymentInterfaceMock());
			try{
				paymentProcess.checkOneOffPayment();
			}catch(Exception ex) {}

			ApexPages.CurrentPage().getParameters().put('accId',tdu.lstIndividualSubscribers[0].id);
			ApexPages.CurrentPage().getParameters().put('PaymentStatus','Success');
			MppUtil util1 = new MppUtil();

			ApexPages.CurrentPage().getParameters().put('productType','Premium');
			ApexPages.CurrentPage().getParameters().put('subscriptionType','Continuous');
			ApexPages.CurrentPage().getParameters().put('recordId',tdu.lstSubscriptions[0].id);
			ApexPages.CurrentPage().getParameters().put('price','4.5');
			ApexPages.CurrentPage().getParameters().put('IncentiveId',tdu.lstSubscriptions[0].id);

			try{
				paymentProcess.checkOneOffPayment();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}

			try{
				ApexPages.CurrentPage().getParameters().put('oneOffAmount','4.5');
				paymentProcess.checkOneOffPayment();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}

			try{
				ApexPages.CurrentPage().getParameters().put('orderTakenMethod','Inbound');
				ApexPages.CurrentPage().getParameters().put('orderTakenByCompany','Chatham');
				ApexPages.CurrentPage().getParameters().put('orderTakenByUser','Salesforce');
				paymentProcess.PaymentPage();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}

			try{
				paymentProcess.goToOneOffPayment();
			}catch(Exception ex){}

			try{
				paymentProcess.goToPremiumContinuousPayment(null);
			}catch(Exception ex){}

			try{
				paymentProcess.goToDigitalContinuousPayment(null, null);
			}catch(Exception ex){}

			MPP_Transaction_History__c mth = TestDataUtility.newMPPTransactionHistory(1,tdu.lstIndividualSubscribers[0].Id,tdu.lstSubscriptions[0].Id, 'DirectDebit');
			mth.Product_name__c = 'Print';
			mth.Payment_Type__c='DirectDebit';
			insert mth;
			paymentProcess.failedDDPremiumOneOffPayment();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'No Failed DD payment for this Subscription'));

			paymentProcess.getlinkToAccount();
		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Cristina Anghenie
	Date - 19/10/2015
	Version - 1.1
	Function - test MPPutil back button functionality for Premium account
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	static testMethod void testBackButton(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadSAMHTTPSettings();
		tdu.loadGeneral();
		tdu.loadPlaneURL();
		tdu.createPOCs(1);
		tdu.lstTCodeManagement[0].Type__c = 'Open Offer';
		update tdu.lstTCodeManagement[0];
		tdu.createIncentives();
		tdu.createSubscriptions();

		Test.startTest();
			ApexPages.StandardController con = new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]);
			Test.setCurrentPage(Page.SubscriberOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', tdu.lstIndividualSubscribers[0].Id);
			MppUtil paymentProcess = new MppUtil(con);
			System.assertEquals('Premium',paymentProcess.oneOffProductType);

			tdu.lstSubscriptions[0].Payment_Type__c = 'Direct Debit';
			tdu.lstSubscriptions[0].PaymentDate__c = '15';
			update tdu.lstSubscriptions[0];

			con = new ApexPages.StandardController(tdu.lstSubscriptions[0]);
			Test.setCurrentPage(Page.SubscriptionOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', tdu.lstSubscriptions[0].Id);

			paymentProcess = new MppUtil(con);
			paymentProcess.oneOffPaymentReason = 'Other';
			paymentProcess.oneOffAmount = '10.00';
			System.assertEquals('/apex/oneoffpaymentprocessor?oneOffAmount=10.00&oneOffPaymentReason=Other&productType=Premium&recordId=' + tdu.lstSubscriptions[0].Id, paymentProcess.submitOneOffPaymentAmount().getUrl());
			ApexPages.CurrentPage().getParameters().put('productType','Premium');
			ApexPages.CurrentPage().getParameters().put('oneOffAmount','10.00');
			ApexPages.CurrentPage().getParameters().put('recordId',tdu.lstSubscriptions[0].id);
			ApexPages.CurrentPage().getParameters().put('accId',tdu.lstIndividualSubscribers[0].id);
			ApexPages.CurrentPage().getParameters().put('PaymentStatus','Success');
			ApexPages.CurrentPage().getParameters().put('productType','Premium');
			ApexPages.CurrentPage().getParameters().put('subscriptionType','Continuous');
			ApexPages.CurrentPage().getParameters().put('recordId',tdu.lstSubscriptions[0].id);
			ApexPages.CurrentPage().getParameters().put('price','4.5');
			ApexPages.CurrentPage().getParameters().put('IncentiveId',tdu.lstSubscriptions[0].id);
			ApexPages.CurrentPage().getParameters().put('orderTakenMethod','Inbound');
			ApexPages.CurrentPage().getParameters().put('orderTakenByCompany','Chatham');
			ApexPages.CurrentPage().getParameters().put('orderTakenByUser','Salesforce');
			ApexPages.CurrentPage().getParameters().put('agencyId','TMG');
			paymentProcess.back();
			System.assertEquals('TMG',ApexPages.CurrentPage().getParameters().get('agencyId'));
			System.assertEquals(tdu.lstIndividualSubscribers[0].id,ApexPages.CurrentPage().getParameters().get('accId'));

		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 11/11/2015
	Version - 1.0
	Function - test MPPutil back button functionality for Premium account
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	static testMethod void testBackButtonV2(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();

		Test.startTest();
			MppUtil mpp = new MppUtil();
			PageReference pr = Page.MppPaymentFrame;
			Map<String, String> mapParams = new Map<String, String>{
				'accId' => td.lstIndividualSubscribers[0].Id,
				'selectedProduct' => Constants.PRODUCT_PREMIUM,
				'restart' => 'true',
				'hasBack' => 'true',
				'email' => 'test',
				'firstName' => 'test',
				'price' => '12'
			};
			pr.getParameters().putAll(mapParams);
			Test.setCurrentPage(pr);
			mpp.getRequestValues();
			PageReference prResult = mpp.back();
		Test.stopTest();
		System.assertEquals('true', prResult.getParameters().get('restart'));
		System.assertEquals('true', prResult.getParameters().get('hasBack'));
		System.assertEquals('test', prResult.getParameters().get('email'));
		System.assertEquals('test', prResult.getParameters().get('firstName'));
		System.assertEquals(Constants.PRODUCT_PREMIUM, prResult.getParameters().get('selectedProduct'));
		System.assertEquals(td.lstIndividualSubscribers[0].Id, prResult.getParameters().get('accId'));
	}

	/***************************************************************************************
	Developer - Cristina Anghenie
	Date - 19/10/2015
	Version - 1.1
	Function - test low startn functionality for Premium account
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         26/05/2016 //added different Payment Type for Low Start
	****************************************************************************************/
	static testMethod void testPremiumPayment(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadSAMHTTPSettings();
		tdu.loadGeneral();
		tdu.loadPlaneURL();
		tdu.createPricingOptions('Premium');
		tdu.mapPricingOptions.get(0)[0].Flow_Type__c = Constants.PRICINGOPTION_FLOWTYPE_SFDC;
		tdu.mapPricingOptions.get(0)[0].TCodeManagement__c = tdu.lstTCodeManagement[0].Id;
		update tdu.mapPricingOptions.get(0)[0];

		tdu.lstTCodeManagement[0].Type__c = 'Open Offer';
		update tdu.lstTCodeManagement[0];
		tdu.createIncentives();
		tdu.createSubscriptions();

		Test.startTest();
			ApexPages.StandardController con = new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]);
			Test.setCurrentPage(Page.SubscriberOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', tdu.lstIndividualSubscribers[0].Id);
			MppUtil paymentProcess = new MppUtil(con);
			System.assertEquals('Premium',paymentProcess.oneOffProductType);

			tdu.lstSubscriptions[0].Payment_Type__c = 'Direct Debit';
			tdu.lstSubscriptions[0].PaymentDate__c = '15';
			update tdu.lstSubscriptions[0];

			con = new ApexPages.StandardController(tdu.lstSubscriptions[0]);
			Test.setCurrentPage(Page.SubscriptionOneOffPaymentAmount);
			ApexPages.currentPage().getParameters().put('Id', tdu.lstSubscriptions[0].Id);

			paymentProcess = new MppUtil(con);
			paymentProcess.oneOffAmount = '10.00';
			System.assertEquals('/apex/oneoffpaymentprocessor?oneOffAmount=10.00&oneOffPaymentReason=null&productType=Premium&recordId=' + tdu.lstSubscriptions[0].Id, paymentProcess.submitOneOffPaymentAmount().getUrl());
			ApexPages.CurrentPage().getParameters().put('productType','Premium');
			ApexPages.CurrentPage().getParameters().put('oneOffAmount','10.00');
			ApexPages.CurrentPage().getParameters().put('tCode',tdu.lstTCodeManagement[0].Name);
			ApexPages.CurrentPage().getParameters().put('recordId',tdu.lstSubscriptions[0].id);
			paymentProcess.PaymentMethod = 'DirectDebit';
			Test.setMock(WebServiceMock.class, new MPPWebserviceMocks.MppPaymentInterfaceMock());
			try{
				paymentProcess.checkOneOffPayment();
			}catch(Exception ex) {}

			ApexPages.CurrentPage().getParameters().put('accId',tdu.lstIndividualSubscribers[0].id);
			ApexPages.CurrentPage().getParameters().put('PaymentStatus','Success');
			MppUtil util1 = new MppUtil();

			ApexPages.CurrentPage().getParameters().put('productType','Premium');
			ApexPages.CurrentPage().getParameters().put('selectedProduct','Premium');
			ApexPages.CurrentPage().getParameters().put('subscriptionType','Continuous');
			ApexPages.CurrentPage().getParameters().put('recordId',tdu.lstSubscriptions[0].id);
			ApexPages.CurrentPage().getParameters().put('price','4.5');
			ApexPages.CurrentPage().getParameters().put('IncentiveId',tdu.lstSubscriptions[0].id);

			try{
				paymentProcess.checkOneOffPayment();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}

			try{
				ApexPages.CurrentPage().getParameters().put('oneOffAmount','4.5');
				paymentProcess.checkOneOffPayment();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}

			try{
				ApexPages.CurrentPage().getParameters().put('orderTakenMethod','Inbound');
				ApexPages.CurrentPage().getParameters().put('orderTakenByCompany','Chatham');
				ApexPages.CurrentPage().getParameters().put('orderTakenByUser','Salesforce');
				paymentProcess.PaymentPage();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}

			tdu.mapPricingOptions.get(0)[0].Subscription_Type__c = '52continuous';
			update tdu.mapPricingOptions.get(0)[0];
			try{
				paymentProcess.PaymentPage();
				System.assertNotEquals(null,ApexPages.getMessages());
				System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Payment_Page_Missing_tcode));
			}catch(Exception ex){}
			tdu.lstTCodeManagement[0].Payment_Type__c = Constants.ALLOW_52_WEEK_DD;
			tdu.lstTCodeManagement[0].Type__c = 'Low Start';
			tdu.lstTCodeManagement[0].Low_Start_Period__c = '13';
			tdu.lstTCodeManagement[0].AllowContinuous__c = true;
			tdu.lstTCodeManagement[0].Low_Start_Weekly_Price__c = 6.65;
			update tdu.lstTCodeManagement[0];
			try{
				paymentProcess.PaymentPage();
				System.assertNotEquals(null,ApexPages.getMessages());
				System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Low_Start_Missing_duration));
			}catch(Exception ex){}
			ApexPages.CurrentPage().getParameters().put('duration','52');
			try{
				paymentProcess.PaymentPage();
				System.assertNotEquals(null,ApexPages.getMessages());
				System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Low_Start_Division_method_error));
			}catch(Exception ex){}

			ApexPages.CurrentPage().getParameters().put('paymentStartDate','26/10/2015');
			ApexPages.CurrentPage().getParameters().put('paymentFrequency','Monthly');
			try{
				paymentProcess.PaymentPage();
				System.assertNotEquals(null,ApexPages.getMessages());
			}catch(Exception ex){}
		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Cristina Anghenie
	Date - 19/10/2015
	Version - 1.1
	Function - test not oneOfPayment functionality for Premium account
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	static testMethod void testContinuousPayments(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.loadSAMHTTPSettings();
		tdu.loadGeneral();
		tdu.loadPlaneURL();
		tdu.createPricingOptions('Premium');

		tdu.mapPricingOptions.get(0)[0].TCodeManagement__c = tdu.lstTCodeManagement[0].Id;
		update tdu.mapPricingOptions.get(0)[0];

		tdu.lstTCodeManagement[0].Type__c = 'Open Offer';
		update tdu.lstTCodeManagement[0];
		tdu.createIncentives();
		tdu.createSubscriptions();

		tdu.lstSubscriptions[0].RecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_LOWSTART, Subscription__c.class.getName());
		tdu.lstSubscriptions[0].MPP_Irregular_Payment_Schedule__c = 'test';
		update tdu.lstSubscriptions[0];

		Test.startTest();
			ApexPages.currentPage().getParameters().put('accId', tdu.lstIndividualSubscribers[0].Id);
			ApexPages.currentPage().getParameters().put('incentiveMSg', tdu.lstIndividualSubscribers[0].Id);
			ApexPages.currentPage().getParameters().put('isOneOffPayment', 'false');
			ApexPages.CurrentPage().getParameters().put('PaymentStatus','Success');
			ApexPages.CurrentPage().getParameters().put('paymentFrequency','Monthly');
			MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{});
			Test.setMock(HttpCalloutMock.class, mock);
			MppUtil paymentProcess = new MppUtil();
			System.assertEquals(0,ApexPages.getMessages().size());
		test.stopTest();
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/02/2016
	Version - 1.0
	Function - test payment schedule preparation for standard print sub - positive
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testNonLowStartContinuousPaymentScheduleCreationPositive(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();

		Test.startTest();
			MPPUtil.PaymentSetupWrapper psw = MppUtil.generatePaymentSchedule(	td.lstSubscriptions[0].Weekly_Price__c,
																				Integer.valueOf(td.lstSubscriptions[0].Subscription_Duration_Picklist__c),
																				Datetime.newInstance(td.lstSubscriptions[0].Start_Date__c, Datetime.now().time()).format('dd/MM/yyyy'),
																				Constants.DD_COL_FREQ_MONTHLY
																				);
			System.assertNotEquals(null, psw);
			System.assertEquals(12, psw.lstPaymentSetup.size());
			for(MppPaymentInterface.PaymentSetup ps : psw.lstPaymentSetup){
				System.assert(String.isNotBlank(ps.OrderDate));
				System.assert(ps.GrossAmount != null);
			}
		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/02/2016
	Version - 1.0
	Function - test payment schedule preparation for standard print sub - failure with null params
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testNonLowStartContinuousPaymentScheduleCreationWrongParams(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadPlaneURL();
		Test.startTest();
			try{
				MPPUtil.PaymentSetupWrapper psw = MppUtil.generatePaymentSchedule( null, null, null, null );
				System.assert(false, 'exception not thrown where should be');
			}catch(Exception e){
				System.assert(e.getMessage().contains(Label.MPP_Util_Wrong_parameters_for_payment_schedule_creation),  e.getMessage());
			}
		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 09/02/2016
	Version - 1.0
	Function - test payment schedule preparation for standard print sub  - failure with invalid length
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testNonLowStartContinuousPaymentScheduleCreationLengthDivisionError(){
		TestDataUtility td = new TestDataUtility(1);
		td.loadPlaneURL();
		Test.startTest();
			try{
				MPPUtil.PaymentSetupWrapper psw = MppUtil.generatePaymentSchedule(9, 12, '12/12/2121', Constants.DD_COL_FREQ_MONTHLY);
				System.assert(false, 'exception not thrown where should be');
			}catch(Exception e){
				System.assert(e.getMessage().contains(Label.MPP_Util_Subscription_lenght_division_error), e.getMessage());
			}
		Test.stopTest();
	}

	/***************************************************************************************
	Developer - Wiktor Czykin
	Date - 16/01/2017
	Version - 1.0
	Function - test nicer exception is thrown when wrong or missing price parameter is passed
	#############Change Log#############
	Modified by     Version     Change Date
	****************************************************************************************/
	private static testMethod void testExceptionOnWrongPrice(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		Test.startTest();
			PageReference pr = Page.MppPaymentFrame;
			Map<String, String> mapParams = new Map<String, String>{
				'accId' => td.lstIndividualSubscribers[0].Id,
				'selectedProduct' => Constants.PRODUCT_PREMIUM,
				'email' => 'test',
				'firstName' => 'test'
			};
			pr.getParameters().putAll(mapParams);
			MppUtil paymentProcess = new MppUtil();
			Test.setCurrentPage(pr);
			try{
				paymentProcess.getRequestValues();
				System.assert(false, 'exception not thrown where should be');
			}catch(Exception e){
				System.assert(e.getMessage().contains(Label.MPP_Error_Price_parameter_error), e.getMessage()+':'+e.getLineNumber());
			}
		Test.stopTest();
	}
}
