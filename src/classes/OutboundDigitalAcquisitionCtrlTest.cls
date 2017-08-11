/**
* Author:       Michal Kwika (Accenture)
* Date:         05/01/2015
* Description:  this class is the test class for controller OutboundDigitalAcquisitionCtrl
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika		26/01/2016
* Wiktor Czykin		17/02/2016	//minor changes and clean-up across all test methods to decouple test logic from strings from test data records
* Michal Kwika		19/02/2016  //changed to CreateFireAccountCreationCustomSetting() method
* Wiktor Czykin		15/03/2016	//added testAcccountHasADuplicate()
* Wiktor Czykin		21/03/2017  //removed testAcccountHasADuplicate()
**/
@isTest
private class OutboundDigitalAcquisitionCtrlTest {
	
	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function   	with only necessary parameters
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void testOutboundAcquisitionWithNecessaryParametersValid() {
		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, Street__c, Street_Address_Line_2__c, 
										TCodeManagement__c, title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  	from POC__c 
		                  	LIMIT 1];
		
		System.assert(!lstPocs.isEmpty());
		
		Id registrantId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST + ' where RecordTypeId =:registrantId');
		System.assert(!lTempAccs.isEmpty());
		
		//update POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), true, true);
		//add parameters to the page

		Test.startTest();
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER);
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET);
			ApexPages.currentPage().getParameters().put('StartPrice', '7.50');
			OutboundDigitalAcquisitionCtrl ctrl = new OutboundDigitalAcquisitionCtrl();

			//move to save Account - account exists
			System.assert(ctrl.isUpdateOption);
			ctrl.isAccountOptIn = true;
			ctrl.updateOrConvertAccount();

			//save with valid data
			ctrl.newAccountObj.PersonEmail = 'randomtest@tmg.com';
			ctrl.newAccountObj.PersonMobilePhone = '012345679765';
			ctrl.newAccountObj.PersonHomePhone = '09988774734';
			//and simulate the form
			ctrl.newContactObj.Salutation = 'Mrs';
			ctrl.newContactObj.FirstName = 'Jake';
			MockHttpCoreApiResponseGenerator ResponseGenerator2 = new MockHttpCoreApiResponseGenerator(200);
			Test.setMock(HttpCalloutMock.class, ResponseGenerator2);
			ctrl.updateOrConvertAccount();

			//increase code coverage
			ctrl.RefreshUI();
			ctrl.getCountries();
			ctrl.closeTab();
			ctrl.getStates();

			Boolean title = ctrl.isTitleRequired;
			Boolean state = ctrl.isStateRequired;
			Boolean isShown = ctrl.isPostalCodeRequired;
		Test.stopTest();
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function   	with full parameters
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void testOutboundAcquisitionWithAllParametersValid() {
		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, 	
										Street__c, Street_Address_Line_2__c, TCodeManagement__c, Title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  		from POC__c LIMIT 1];

		System.assert(!lstPocs.isEmpty());

		Id registrantId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST + ' where RecordTypeId =:registrantId');		
		
		//update POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), false, true);
		//add parameters to the page
		Test.startTest();
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER);
			ApexPages.currentPage().getParameters().put('OrderMethod', 'Outbound');
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE);
			ApexPages.currentPage().getParameters().put('StartPrice', '8');
			ApexPages.currentPage().getParameters().put('StartPeriods', '3');
			ApexPages.currentPage().getParameters().put('SubseqPrice', '10');
			ApexPages.currentPage().getParameters().put('EMADD', 'test123456789@tmg.co.uk');
			OutboundDigitalAcquisitionCtrl ctrl =  new OutboundDigitalAcquisitionCtrl();

			System.assert(ctrl.isNewAccountOption);
			//and simulate the form
			ctrl.newContactObj.Salutation = 'Prof';
			ctrl.newContactObj.FirstName = 'Jake';
			ctrl.isAccountOptIn = true;
			MockHttpCoreApiResponseGenerator ResponseGenerator2 = new MockHttpCoreApiResponseGenerator(200);
			Test.setMock(HttpCalloutMock.class, ResponseGenerator2);
			ctrl.saveNewAccount();
		Test.stopTest();
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function   	new account creation check as an outcome
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void testOutboundAcquisitionNewAccount() {
		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, 
										State__c, Street__c, Street_Address_Line_2__c, TCodeManagement__c, Title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  			from POC__c LIMIT 1];

		System.assert(!lstPocs.isEmpty());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST);
		//update POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), false, false);
		pocObj.Email__c = 'brandnewrandom@email.com';
		pocObj.HomeTelephone__c = null;
		pocObj.WorkTelehone__c = '000034234';
		pocObj.Title__c = 'Lord';
		update pocObj;

		Test.startTest();
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER);
			ApexPages.currentPage().getParameters().put('OrderMethod', 'Outbound');
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE);
			ApexPages.currentPage().getParameters().put('StartPrice', '8');
			ApexPages.currentPage().getParameters().put('StartPeriods', '3');
			ApexPages.currentPage().getParameters().put('SubseqPrice', '10');

			OutboundDigitalAcquisitionCtrl ctrl =  new OutboundDigitalAcquisitionCtrl();

			//and simulate the form
			ctrl.newContactObj.Salutation = 'Prof';
			ctrl.newContactObj.FirstName = 'Jake';
			System.assert(ctrl.isNewAccountOption);
			MockHttpCoreApiResponseGenerator ResponseGenerator2 = new MockHttpCoreApiResponseGenerator(200);
			Test.setMock(HttpCalloutMock.class, ResponseGenerator2);
			ctrl.saveNewAccount();
		Test.stopTest();
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function    test with conversion
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void testOutboundAcquisitionOldWorldAccountConversion() {
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, Street__c,
										Street_Address_Line_2__c, TCodeManagement__c, Title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  			from POC__c LIMIT 1];

		System.assert(!lstPocs.isEmpty());

		Id individualSubscriberId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST + ' where RecordTypeId =:individualSubscriberId');		

		lTempAccs.get(0).PersonHomePhone = '08888888888';
		lTempAccs.get(0).PersonMobilePhone = '08888888889';
		lTempAccs.get(0).PersonMailingStreet = 'random street';
		lTempAccs.get(0).PersonMailingCountry = 'GB';
		lTempAccs.get(0).PersonMailingCity = 'Manchester';
		lTempAccs.get(0).Salutation = 'Mr';
		lTempAccs.get(0).PersonEmail = 'someOtherEmail@telegraph.co.uk';
		update lTempAccs.get(0);
		//update POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), false, true);

		Test.startTest();
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER);
			ApexPages.currentPage().getParameters().put('OrderMethod', 'Outbound');
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET);
			ApexPages.currentPage().getParameters().put('StartPrice', '8');
			ApexPages.currentPage().getParameters().put('StartPeriods', '3');
			ApexPages.currentPage().getParameters().put('SubseqPrice', '10');

			OutboundDigitalAcquisitionCtrl ctrl =  new OutboundDigitalAcquisitionCtrl();

			System.assert(ctrl.isConvertOption);

			//and simulate the form
			ctrl.newContactObj.Salutation = 'Prof';
			ctrl.newContactObj.FirstName = 'Jake';
			ctrl.isAccountOptIn = true;

			MockHttpCoreApiResponseGenerator ResponseGenerator2 = new MockHttpCoreApiResponseGenerator(200);
			Test.setMock(HttpCalloutMock.class, ResponseGenerator2);
			ctrl.updateOrConvertAccount();
		Test.stopTest();
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function    method to check wrong parameters
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void testOutboundWrongParameters() {

		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, Street__c, 
									Street_Address_Line_2__c, TCodeManagement__c, Title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  	from POC__c ];
		System.assert(!lstPocs.isEmpty());

		Id registrantId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST + ' where RecordTypeId =:registrantId');
		//updarte POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), true, true);

		Test.startTest();
			//showErrors from page
			OutboundDigitalAcquisitionCtrl ctrl =  new OutboundDigitalAcquisitionCtrl();
			//LABEL IS NOT WORKING !
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 'POC cannot be found in the URL parameters.'));
			//no product
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_Parameter_SelectedProduct));
			//no payfreq
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE);
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_Parameter_PayFreq));
			//put wrong string there
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE);
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongFrequency));
			//put monthly without startperiods
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_MONTHLY_FREQUENCY_LETTER);
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongStartM));

			//monthly without price
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_WEBSITE);
			ApexPages.currentPage().getParameters().put('StartPeriods', '3');
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongStartPeriodComboPrice));

			ApexPages.currentPage().getParameters().put('StartPrice', '8');
			ApexPages.currentPage().getParameters().put('StartPeriods', '3');
			ApexPages.currentPage().getParameters().put('SubseqPrice', '10');
		Test.stopTest();

	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function    another wrong parameters and combinations
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void testOutboundWrongValues() {
		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, Street__c, Street_Address_Line_2__c, 
										TCodeManagement__c, Title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  		from POC__c LIMIT 1];
		System.assert(!lstPocs.isEmpty());

		Id registrantId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST + ' where RecordTypeId =:registrantId');
		//updarte POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), true, false);
		pocObj.Subscription_Acquired__c = true;
		update pocObj;

		Test.startTest();
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER);
			ApexPages.currentPage().getParameters().put('OrderMethod', 'Outbound');
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET);
			OutboundDigitalAcquisitionCtrl ctrl = new  OutboundDigitalAcquisitionCtrl();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Offer_Code_Used));

			//wrong product string
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER);
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_WrongProduct));

			//wrong product string
			ApexPages.currentPage().getParameters().put('StartPeriods', 'totallyWrongString');
			ctrl.areSynthesisParametersCorrect();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Page_MissingURL_Type_PriceNumeric));
		Test.stopTest();
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function    another case when poc record does not exists
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void pocObjectIsNotThere() {
		Test.setCurrentPage(Page.OutboundDigitalAcquisition);

		ApexPages.currentPage().getParameters().put('pocid', 'randomPOCdesonNotExistInSF');
		ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER);
		ApexPages.currentPage().getParameters().put('OrderMethod', 'Outbound');
		ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET);
		OutboundDigitalAcquisitionCtrl ctrl = new  OutboundDigitalAcquisitionCtrl();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Offline_Acquisition_POC_not_found));
	}

	/***************************************************************************************
	Developer   Michal Kwika (Accenture)
	Date        05/01/2015
	Function    subscriber has already active subscription
	******************* Change Log *******************
	Modified by         Version     Change Date
	****************************************************************************************/
	static testMethod void acccountHasActiveSub() {

		Test.setCurrentPage(Page.OutboundDigitalAcquisition);
		List<POC__c> lstPocs = [select 	Name, FirstName__c, LastName__c, City__c, Country__c, Email__c, PostalCode__c, Subscriber_Number__c, State__c, Street__c, Street_Address_Line_2__c, TCodeManagement__c, 
									Title__c, MobileTelephone__c, HomeTelephone__c, Subscription_Acquired__c, POC_ID__c
		                  	from POC__c LIMIT 1];
		System.assert(!lstPocs.isEmpty());
		Account retailer = TestDataUtility.newAccount(30, RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_ACCOUNT_RETAILER , Account.class.getName()));
		insert retailer;

		Id registrantId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());
		List <Account> lTempAccs = Database.query(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_FOR_TEST + ' where RecordTypeId =:registrantId');
		Subscription__c sub = TestDataUtility.newSubscripiton(20, lTempAccs[0].Id, retailer.Id, null);
		insert sub;

		//update POC
		POC__c pocObj = preparePOCobjectForOutbound(lstPocs[0], lTempAccs.get(0), true, true);

		Test.startTest();
			ApexPages.currentPage().getParameters().put('pocid', pocObj.POC_ID__c);
			ApexPages.currentPage().getParameters().put('PayFreq', Constants.OUTBOUND_ANNUAL_FREQUENCY_LETTER);
			ApexPages.currentPage().getParameters().put('selectedProduct', Constants.OUTBOUND_PRODUCT_URL_PARAM_VALUE_TABLET);
			ApexPages.currentPage().getParameters().put('StartPrice', '7.50');
			OutboundDigitalAcquisitionCtrl ctrl = new OutboundDigitalAcquisitionCtrl();
			System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Outbound_Digital_Acquisition_Account_Has_Active_Sub));
		Test.stopTest();
	}


	//method to prepare POC record for this tests
	static POC__c preparePOCobjectForOutbound(POC__c pocObj, Account personAcc, Boolean isTSnumber, Boolean withUpdate) {
		pocObj.FirstName__c = 'firstName';
		pocObj.City__c = 'London';
		pocObj.Country__c = Constants.UNITED_KINGDOM_COUNTRY_NAME_VALUE;
		pocObj.Email__c = personAcc.PersonEmail;
		pocObj.State__c = 'Arizona';
		pocObj.Street__c = 'SampleStreet7';
		pocObj.title__c = 'Mr';
		pocObj.MobileTelephone__c = '0123456789';
		pocObj.HomeTelephone__c = '0987654321';

		if (isTSnumber) {
			pocObj.Subscriber_Number__c = personAcc.Subscriber_Number__c;
		}

		if (withUpdate) {
			update pocObj;
		}

		return pocObj;
	}

	@testsetup
	static void init() {
		TestDataUtility testDataUtilityObjCS = new TestDataUtility(4);
		//create custom settings
		testDataUtilityObjCS.CreateCoreApiEndPointSettings();
		testDataUtilityObjCS.createFireAccountCreationCustomSetting(true);
		testDataUtilityObjCS.loadCountryCodes();
		//create objects
		testDataUtilityObjCS.createPOCs(4);
		testDataUtilityObjCS.createRegistrants();
		testDataUtilityObjCS.createIndividualSubscribers();

		//zuora sub for one of them
		testDataUtilityObjCS.createZquotes();	
       	testDataUtilityObjCS.createBillingAccountToRegistrant(testDataUtilityObjCS.lstRegistrants[3].id,Constants.PAYMENT_METHOD_CREDIT_CARD_TYPE);
       	testDataUtilityObjCS.createZuoraSubscriptionToRegistrant(testDataUtilityObjCS.lstRegistrants[3].id);
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);
	}
}