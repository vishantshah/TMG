/**
* @author Wiktor Czykin
* @date 30/03/2015
* @description 
#############Change Log#############
Modified by     	Version     Change Date
Wiktor Czykin   	1.0         30/03/2015	//all test logic here moved from former SubscriptionACcountTriggerHandlerTest class
Cristina Popescu	1.1			08/06/2015  increase AccountTriggerHandler coverange to 90% from 68%
Cristina Anghenie	1.2			22/09/2015	//remove SubscriberPortal__c custom settings
Michal Kwika        1.3         11/02/2016  //added test method for Given Title
Michal Kwika        1.4         16/02/2016  //added modifications for Given Title
Wiktor Czykin		1.5			22/02/2016	//coverage improvement
Michal Szewczyk		1.6			28/04/2016	// add createZProductFeatures() to init
Mantas Grigaliunas	1.7			26/10/2016	//added test for preventMarkingMasterAsDuplicate()
Wiktor Czykin 		1.8			15/11/2016	//added forceEntitlementUpdateTest() and modified preventMarkingMasterAsDuplicateTest()
Wiktor Czykin		1.9			31/01/2017  //added forceEntitlementUpdateForRegistrantsTest()
Wiktor Czykin		2.0			10/02/2017  //added forceEntitlementUpdateForRegistrantsWithStatusResyncTest()
Pawel Chrzanowski   2.1         03/05/2017  //removed testMarketingFlag()
**/
@isTest
private class AccountTriggerHandlerTest {


	private static decimal vatRateGB = 0.2;
	private static decimal vatRateEU = 0.1;
	
	private static void init(){
		TestDataUtility tdu = new TestDataUtility();
		tdu.loadSAMHTTPSettings();
		tdu.loadGeneral();
		tdu.loadPlaneURL();
		tdu.loadCountryCodes();
		tdu.loadVAT();
		tdu.createZProductFeatures();
	}
	
	public static testMethod void testSendDigitalWelcomePackEmail(){
		init();
		
		TCodeManagement__c tCode = new TCodeManagement__c();
		tCode.Name = 'A001';
		tCode.Digital_Monthly_Price__c = 9.99;
		tCode.Digital_Yearly_Price__c = 99.99;
		tCode.Type__c = 'TEST';
		tCode.Description__c = 'TEST';
		tCode.Price__c = tCode.Digital_Monthly_Price__c;
		try{ 
			insert tCode;
		}catch(Exception ex){}
		
		Account acc = new Account(Salutation='Mr.', firstName='Laurent', lastNAme='Delcambre', personEmail='l.l@l.com', subscriber_number_static__c='TS001', 
				origin__c='Online', RecordTypeId = TMGUtil.recordTypeMap.get('Account.Digital Subscriber').Id, Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_ALLDEVICES,
				Wave_ID__c = tCode.Name, PersonMailingCountry = 'GB');
		try{ 
			insert acc;
		}catch(Exception ex){}
		
		MPP_Transaction_History__c tranHist = new MPP_Transaction_History__c();
		tranHist.Subscriber__c = acc.Id;
		tranHist.Payment_Status__c = 'Success';
		tranHist.Total_Price__c = tCode.Digital_Monthly_Price__c;
		try{ 
			insert tranHist;
		}catch(Exception ex){}
		
		Test.startTest();
			acc.Email_Sent__c = false;
			update acc;
		Test.stopTest();
		
		
		delete tranHist;
		tranHist = new MPP_Transaction_History__c();
		tranHist.Subscriber__c = acc.Id;
		tranHist.Payment_Type__c = 'Success';
		tranHist.Total_Price__c = tCode.Digital_Yearly_Price__c;
		try{ 
			insert tranHist;
		}catch(Exception ex){}
		
		acc.Email_Sent__c = false;
		update acc;
		
		delete tranHist;
		acc.Email_Sent__c = false;
		update acc;
	}
	
	public static testMethod void testSendWebWelcomePackEmail(){
		init();
		
		TCodeManagement__c tCode = new TCodeManagement__c();
		tCode.Name = 'A001';
		tCode.Web_Pack_Monthly_Price__c = 9.99;
		tCode.Web_Pack_Yearly_Price__c = 99.99;
		tCode.Type__c = 'TEST';
		tCode.Description__c = 'TEST';
		tCode.Price__c = tCode.Web_Pack_Monthly_Price__c;
		try{ 
			insert tCode;
		}catch(Exception ex){}
		
		Account acc = new Account(Salutation='Mr.', firstName='Laurent', lastNAme='Delcambre', personEmail='l.l@l.com', subscriber_number_static__c='TS001', 
				origin__c='Online', RecordTypeId = TMGUtil.recordTypeMap.get('Account.Digital Subscriber').Id, Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_WEBPACK,
				Wave_ID__c = tCode.Name, PersonMailingCountry = 'GB');
		try{ 
			insert acc;
		}catch(Exception ex){}
		
		MPP_Transaction_History__c tranHist = new MPP_Transaction_History__c();
		tranHist.Subscriber__c = acc.Id;
		tranHist.Payment_Status__c = 'Success';
		tranHist.Total_Price__c = tCode.Web_Pack_Monthly_Price__c;
		try{ 
			insert tranHist;
		}catch(Exception ex){}
		
		Test.startTest();
			acc.Email_Sent__c = false;
			update acc;
		Test.stopTest();
		
		delete tranHist;
		tranHist = new MPP_Transaction_History__c();
		tranHist.Subscriber__c = acc.Id;
		tranHist.Payment_Type__c = 'Success';
		tranHist.Total_Price__c = tCode.Web_Pack_Yearly_Price__c;
		try{ 
			insert tranHist;
		}catch(Exception ex){}
		
		acc.Email_Sent__c = false;
		update acc;
	}
	
	public static testMethod void testSendPrintWelcomePackEmail(){
		init();
		
		TCodeManagement__c tCode = new TCodeManagement__c();
		tCode.Name = 'A001';
		tCode.Type__c = 'TEST';
		tCode.Description__c = 'TEST';
		tCode.Price__c = 9.99;
		try{ 
			insert tCode;
		}catch(Exception ex){}
		
		Incentive__c incent = new Incentive__c();
		incent.Incentive_Description__c = 'I LIVE I SLAY';
		try{ 
			insert incent;
		}catch(Exception ex){}
		
		Account acc = new Account(Salutation='Mr.', firstName='Laurent', lastNAme='Delcambre', personEmail='l.l@l.com', subscriber_number_static__c='TS001', 
				origin__c='Online', RecordTypeId = TMGUtil.recordTypeMap.get('Account.Individual Subscriber').Id, Wave_ID__c = tCode.Name, PersonMailingCountry = 'GB');
		try{ 
			insert acc;
		}catch(Exception ex){}
		
		Subscription__c sub = new Subscription__c();
		sub.Subscriber__c = acc.Id;
		sub.Last_Status_Change__c = Date.today().addDays(-1);
		sub.Subscription_Status__c = 'Pending';
		sub.Is_MPP_DDCCA_Letter_Extracted__c = false;
		sub.Start_Date__c = Date.today().addDays(21).toStartOfWeek();
		sub.Payment_Details_Received__c = true;
		sub.Weekly_Price__c = 6.50;
		sub.Payment_Type__c = 'Credit Card';
		sub.Delivery_Type__c = 'OTC';
		sub.Voucher_Pack_Duration__c = 14;
		try{ 
			insert sub;
		}catch(Exception ex){}
		
		SubscriptionIncentiveAssociation__c link = new SubscriptionIncentiveAssociation__c();
		link.Subscriber__c = acc.Id;
		link.Incentive__c = incent.Id;
		link.Subscription__c = sub.Id;
		try{ 
			insert link;
		}catch(Exception ex){}
 
		Test.startTest();
			acc.Email_Sent__c = false;
			update acc;
		Test.stopTest();
		
	}

	private static String getAddressString(Account acc){
		return acc.PersonMailingCity+':'+acc.PersonMailingCountry+':'+acc.PersonMailingState+':'+acc.PersonMailingStreet+':'+acc.PersonMailingPostalCode;
	}
	
	public static testMethod void testAddressChangetoNullByTMGSystem(){
		init();
		List<Account> accounts = setupAccounts(10);
		Profile p = [SELECT Id FROM Profile WHERE Name='TMG System']; 
		System.runAs(getUser(p))
		{
			Map<ID,String> oldAddress=new Map<ID,String>();
			Integer length=accounts.size();
			System.debug('After INIT');    
		
			Set<ID> ids=new Set<ID>();
			for(Integer i=0;i<length;i++)
			{
				oldAddress.put(accounts[i].Id,getAddressString(accounts[i]));
				if(math.mod(i, 6)==0)
					accounts[i].PersonMailingCity='';
				else if(math.mod(i, 5)==0)
					accounts[i].PersonMailingCountry='';
				else if(math.mod(i, 4)==0)
					accounts[i].PersonMailingState='';
				else if(math.mod(i, 3)==0)
					accounts[i].PersonMailingStreet='';
				else if(math.mod(i, 2)==0)
					accounts[i].PersonMailingPostalCode='';
				ids.add(accounts[i].Id);    
			}
			Test.startTest();
			update accounts;
			Test.stopTest();
			
			accounts=[Select Id,PersonMailingCity,PersonMailingCountry,PersonMailingState,PersonMailingStreet,PersonMailingPostalCode from Account where Id IN  :ids];
			//for(Account acc:accounts)
					////system.assertEquals(oldAddress.get(acc.Id), getAddressString(acc));         
		}   
	}
	
	private static User getUser(Profile p){
	  User u=[SELECT Id from User where ProfileId=:p.Id and isActive=true LIMIT 1];
	  return u;
	}
	

	public static List<Account> setupAccounts(Integer numberOfAccounts){
		
		List<Account> accountsToInsert= new List<Account>();
		for(Integer i=0;i<numberOfAccounts;i++)
		{
			String lname='testacc';
			String postcode='N'+i;
			String state='randomstate'+i;
			String city='randomcity'+i;
			String country='UK';
			String street='street '+i;
			Account acc = new Account(Title__c='Mr.',lastname=lname, personmailingPostalCode=postcode, guid__c='GUID'+i+lname,PersonMailingState=state,PersonMailingStreet=street,PersonMailingCountry=country,PersonMailingCity=city);
			accountsToInsert.add(acc);
		}
		try{ 
			insert accountsToInsert;
		}catch(Exception ex){}
		
		return accountsToInsert;
	}

		
	public static testMethod void testFormatPostcode_GBaddress(){
		Account a1 = new Account(Title__c='Mr.', Lastname ='lastname', PersonMailingPostalCode = 's n 1 4 2 w s', PersonMailingCountry = 'GB');
		
		Test.startTest();
		try{ 
			insert a1;
		}catch(Exception ex){}
		Test.stopTest();
		
		Account a = [SELECT PersonMailingPostalCode FROM Account WHERE Id = :a1.id LIMIT 1];
	}

	public static testMethod void testFormatPostcode_ESaddress(){
		Account a1 = new Account(Title__c='Mr.', Lastname ='lastname', PersonMailingPostalCode = 's n 1 4 2 w s', PersonMailingCountry = 'ES');
		
		Test.startTest();
		try{ 
			insert a1;
		}catch(Exception ex){}
		Test.stopTest();
		
		Account a = [SELECT PersonMailingPostalCode FROM Account WHERE Id = :a1.id LIMIT 1];
	}

	/* Utility Methods */
	public static Account setupAccount(String lname, String postcode){
		Account acc = new Account(Title__c='Mr.',lastname=lname, personmailingPostalCode=postcode, guid__c='GUID'+lname);
		try{ 
			insert acc;
		}catch(Exception ex){}
		
		acc = [SELECT id, lastname, personmailingpostalcode, subscriber_number__c, guid__c FROM Account WHERE id = :acc.id];
		return acc;
	}
	
	public static Subscription__c setupSub(Account acc, String status){
		return setupSub(acc, status, Date.Today().toStartOfWeek().addDays(21));
	}
	
	/*************************************************************************************** 
	Developer - Unknown
	Date - Unknown
	Version - 1.1
	Function - generate data for tests 
	#############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin   1.1         02/03/2015  //modified record type fetching as was throwing exceptions on deployment
	****************************************************************************************/
	public static Subscription__c setupSub(Account acc, String status, Date startDate){
		Id rt = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName());
		System.assertNotEquals(null, rt);
		Integer price;
		
		if(status.toUpperCase() == 'OFFERED')
			price = null;
		else
			price = 5;
		
		Subscription__c sub = new Subscription__c(Cancellation_Date__c=null,Cancellation_Method__c=null, Cancellation_Reason__c=null, start_date__c = startDate , Payment_Type__c = 'Cheque', Delivery_Type__c = 'OTC', Weekly_Price__c=price, Subscription_Status__c=status, Subscription_Duration_Picklist__c='26', Subscriber__c=acc.id, RecordTypeId=rt,Payment_Details_Received__c=true);
		try{ 
			insert sub;
		}catch(Exception ex){}
		
		return sub;
	}
	
	/*************************************************************************************** 
	Developer - Cristina Anghenie
	Date - 04/08/2015
	Version - 1.0
	Function - test MPP single update
	#############Change Log#############
	Modified by     	Version     Change Date
	Michal Kwika        1.1         11/02/2016 - removed not used methods
	****************************************************************************************/
	public static testMethod void testMPPSingleUpdate(){
		TestDataUtility tdu = new TestDataUtility(1);

		tdu.createIndividualSubscribers();
		
		Test.startTest();
			Test.setMock(HttpCalloutMock.class, MPPWebserviceMocks.getMPPUserManageSuccessMock());
			tdu.lstIndividualSubscribers[0].Salutation = 'Miss';
			tdu.lstIndividualSubscribers[0].Lastname = 'UpdatedLastName';
			tdu.lstIndividualSubscribers[0].PersonEmail = 'newemail@mail.com';
			update tdu.lstIndividualSubscribers[0];
			MPPInterfaceHTTP mppHTTP = new MPPInterfaceHTTP();
			MPPInterfaceHTTP.UserManageResult results = mppHTTP.UserManageSingleUpdate(tdu.lstIndividualSubscribers[0].Subscriber_Number_static__c, 
							   tdu.lstIndividualSubscribers[0].PersonEmail,
							   'personemail1@telegraph.co.uk', 
							   tdu.lstIndividualSubscribers[0].Salutation, 
							   tdu.lstIndividualSubscribers[0].FirstName, 
							   tdu.lstIndividualSubscribers[0].LastName,
							   tdu.lstIndividualSubscribers[0].Guid__c);
			System.assert(results.guid!=null);
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer - Michal Kwika
	Date - 11/02/2016
	Version - 1.0
	Function - test Salutation and Given Title override 
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void testSalutationWithGivenTitle(){
		TestDataUtility tdu = new TestDataUtility(1);
		tdu.createIndividualSubscribers();
		Account a1 = tdu.lstIndividualSubscribers[0];

		Test.startTest();
		a1.Title__c = 'King';
		update a1;

		Test.stopTest();

		List <Account> lTempAccs = [SELECT Title__c, Salutation FROM Account WHERE Id = :a1.id LIMIT 1];
		System.assertNotEquals(0, lTempAccs.size());
		System.assertEquals('King',lTempAccs.get(0).Salutation);
		System.assertEquals(null, lTempAccs.get(0).Title__c);
	}
	
	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 22/02/2016
	Version - 1.0
	Function - test Registrant insert and its callout to CoreAPI
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void testRegistrantInsertUpdate(){
		TestDataUtility tdu = new TestDataUtility(3);
		tdu.checkRegistrantAccountDependencies();
		tdu.createFireAccountCreationCustomSetting(true);
		Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
		List<Account> lstRegistrants = new List<Account>();
		for(Integer i = 0; i<tdu.iCounter; i++){
		   lstRegistrants.add(TestDataUtility.newPersonAccount(i, registrantRecordTypeId));
		}
		MockHttpCoreApiResponseGenerator rpesponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, rpesponseGenerator);
		Test.startTest();
			insert lstRegistrants;
		Test.stopTest();
		String sEventToLog = String.format(Constants.LOG_COREAPI_OBJECT_EVENT, new List<String>{Account.class.getName(), Constants.UPDATED_RECORD_ACTION_NAME});
		String sEventToLog2 = String.format(Constants.LOG_COREAPI_OBJECT_EVENT, new List<String>{Account.class.getName(), Constants.NEW_RECORD_CREATED_ACTION_NAME});

		List<WebService_Log__c> lstlog = [select Id, Response_Content__c, Response_Time__c, Parameters__c from WebService_Log__c where Event_Name__c in :new Set<String>{sEventToLog, sEventToLog2}];
		System.assert(!lstlog.isEmpty());
		System.assertEquals(2, lstlog.size());
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 22/02/2016
	Version - 1.0
	Function - simple test of createUserMap method
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void testCreateUserMap(){
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();
		Test.startTest();
			AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
			System.assert(String.isNotBlank(ath.createUserMap(td.lstIndividualSubscribers[0])));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 22/02/2016
	Version - 1.0
	Function - simple test of getValidValue method
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void testGetValidValue(){
		Test.startTest();
			AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
			System.assert(String.isNotBlank(ath.getValidValue('String sValue')));
			System.assert(String.isBlank(ath.getValidValue('')));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 22/02/2016
	Version - 1.0
	Function - simple test of mppDetailsChanged method
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void testMppDetailsChanged(){
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();
		Test.startTest();
			AccountTriggerHandler ath = AccountTriggerHandler.getInstance();
			Account a = td.lstIndividualSubscribers[0];
			Account b = a.clone(false, false);
			b.Salutation = 'sthDifferent';
			System.assert(ath.mppDetailsChanged(a, b));
			b.Salutation = a.Salutation;
			System.assert(!ath.mppDetailsChanged(a, b));
			b.FirstName = 'sthDifferent';
			System.assert(ath.mppDetailsChanged(a, b));
			b.FirstName = a.FirstName;
			System.assert(!ath.mppDetailsChanged(a, b));
			b.LastName = 'sthDifferent';
			System.assert(ath.mppDetailsChanged(a, b));
			b.LastName = a.LastName;
			System.assert(!ath.mppDetailsChanged(a, b));
			b.PersonEmail = 'sthdiffernet@telegraph.co.uk';
			System.assert(ath.mppDetailsChanged(a, b));
			b.PersonEmail = a.PersonEmail;
			System.assert(!ath.mppDetailsChanged(a, b));
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer - Mantas Grigaliunas
	Date - 22/02/2016
	Version - 1.1
	Function - test for preventMarkingMasterAsDuplicate function
	#############Change Log#############
	Modified by         Version     Change Date
	Wiktor Czykin		1.1			02/12/2016	//added related settings creation
	****************************************************************************************/
	public static testMethod void preventMarkingMasterAsDuplicateTest(){
		TestDataUtility td = new TestDataUtility(4);
		td.checkAccountDependencies();
		td.createAccount();
		Account masterAccount = td.lstAccounts[0];
		List<Account> duplicateAccounts = new List<Account>();
		List<String> duplicateAccountNames = new List<String>();
		for(Integer i = 2; i < td.lstAccounts.size(); i++){
			td.lstAccounts[i].Duplicate_Of__c = masterAccount.Id;
			duplicateAccounts.add(td.lstAccounts[i]);
			duplicateAccountNames.add(td.lstAccounts[i].LastName);
		}
		update duplicateAccounts;

		Test.startTest();
		masterAccount.Duplicate_Of__c = td.lstAccounts[1].Id;

		Database.SaveResult result = Database.update(masterAccount, false);
		System.assert(!result.isSuccess(), result);
		System.assert(TestDataUtility.checkIfErrorExists(result.getErrors(), 
			String.format(Label.Account_Duplicate_Master_Error, 
				new List<String>{String.join(duplicateAccountNames, ', ')})),
		result.getErrors());
		Test.stopTest();
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 29/11/2016
	Version - 1.0
	Function - test for reset of Force_Entitlement_Update__c field  
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void forceEntitlementUpdateTest(){
		TestDataUtility td = new TestDataUtility(4);
		td.createIndividualSubscribers();

		Test.startTest();
			for(Account acc : td.lstIndividualSubscribers){
				acc.Force_Entitlement_Update__c = true;
			}
			update td.lstIndividualSubscribers;

			List<Account> lstAcc = [select Id, Force_Entitlement_Update__c from Account where Id in :td.lstIndividualSubscribers];
			System.assert(!lstAcc.isEmpty());
			for(Account acc : lstAcc){
				System.assert(acc.Force_Entitlement_Update__c);
			}
		Test.stopTest();
		lstAcc = [select Id, Force_Entitlement_Update__c from Account where Id in :td.lstIndividualSubscribers];
		System.assert(!lstAcc.isEmpty());
		for(Account acc : lstAcc){
			System.assert(!acc.Force_Entitlement_Update__c);
		}
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 31/01/2017
	Version - 1.0
	Function - test for reset of Force_Entitlement_Update__c field for Registrants
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void forceEntitlementUpdateForRegistrantsTest(){
		TestDataUtility td = new TestDataUtility(3);
		td.checkAccountDependencies();
		td.createZSubscriptions();
		Set<Id> accIds = new Set<Id>();
		Integer i = 0;
		for(Account tmp: td.lstRegistrants) {
			accIds.add(tmp.Id);
			tmp.Guid__c ='guida'+i;
			i++;
		}
		AccountTriggerHandler.getInstance().isExecuting = true;
		update td.lstRegistrants;
		AccountTriggerHandler.getInstance().isExecuting = false;

		Test.startTest();
			for(Account acc : td.lstRegistrants){
				acc.Force_Entitlement_Update__c = true;
			}
			update td.lstRegistrants;

			List<Account> lstAcc = [select Id, Force_Entitlement_Update__c from Account where Id in :td.lstRegistrants];
			System.assert(!lstAcc.isEmpty());
			for(Account acc : lstAcc){
				System.assert(acc.Force_Entitlement_Update__c);
			}
		Test.stopTest();
		lstAcc = [select Id, Force_Entitlement_Update__c from Account where Id in :td.lstRegistrants];
		System.assert(!lstAcc.isEmpty());
		for(Account acc : lstAcc){
			System.assert(!acc.Force_Entitlement_Update__c);
		}
	}

	/*************************************************************************************** 
	Developer - Wiktor Czykin
	Date - 10/02/2017
	Version - 1.0
	Function - test for reset of Force_Entitlement_Update__c field for Registrants with pre-sync of account digital status based on zuora subs
	#############Change Log#############
	Modified by         Version     Change Date
	****************************************************************************************/
	public static testMethod void forceEntitlementUpdateForRegistrantsWithStatusResyncTest(){
		TestDataUtility td = new TestDataUtility(3);
		td.checkAccountDependencies();
		td.createZSubscriptions();

		Set<Id> accIds = new Set<Id>();
		Integer i = 0;
		for(Account tmp: td.lstRegistrants) {
			accIds.add(tmp.Id);
			tmp.Guid__c ='guida'+i;
			tmp.Replatform_Digital_Status__c = Constants.SUBSCRIBER_INACTIVE_STATUS;
			i++;
		}


		AccountTriggerHandler.getInstance().isExecuting = true;
		update td.lstRegistrants;
		AccountTriggerHandler.getInstance().isExecuting = false;

		Test.startTest();
			for(Account acc : td.lstRegistrants){
				acc.Force_Entitlement_Update__c = true;
			}
			update td.lstRegistrants;

			List<Account> lstAcc = [select Id, Force_Entitlement_Update__c from Account where Id in :td.lstRegistrants];
			System.assert(!lstAcc.isEmpty());
			for(Account acc : lstAcc){
				System.assert(acc.Force_Entitlement_Update__c);
			}
		Test.stopTest();
		lstAcc = [select Id, Force_Entitlement_Update__c, Replatform_Digital_Status__c from Account where Id in :td.lstRegistrants];
		System.assert(!lstAcc.isEmpty());
		for(Account acc : lstAcc){
			System.assert(!acc.Force_Entitlement_Update__c);
			System.assertEquals(Constants.SUBSCRIBER_ACTIVE_STATUS, acc.Replatform_Digital_Status__c);
		}
	}
}