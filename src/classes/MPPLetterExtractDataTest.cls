/**
* @author Unknown
* @date Unknown
* @description Test class for MPPLetterExtractData class
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   2.0         23-26/10/2015	//fully rewritten
Wiktor Czykin	2.1			09/02/2016	//modified testCreateCSVRowForAccountWithSubscriptionDD() and testCreateCSVRowForAccountWithSubscriptionCC()
**/
@isTest(SeeAllData=false)
private class MPPLetterExtractDataTest {

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - Test of BatchLogger wrapper class - all setter and getters
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testBatchLoggerWrapper(){
		Test.startTest();
			MPPLetterExtractData.BatchLogger bl = new MPPLetterExtractData.BatchLogger('test1', 'test2');
			System.assertEquals('test2', bl.csvHeader);
			System.assertEquals('', bl.csvData);
			System.assertEquals('', bl.log);
			System.assert(bl.logHeader.contains('test1'));

			String sLogText = 'logText';
			bl.addLog(sLogText);
			System.assert(bl.log.contains(sLogText));
			System.assert(bl.getLog().contains('test1') && bl.getLog().contains(sLogText));

			String sRowData = 'rowData';
			bl.addCSVData(sRowData);
			System.assert(bl.isCSVDataValid());
			System.assertEquals('test1', bl.getFileName());
			System.assert(bl.getCSVData().contains(bl.csvHeader) && bl.getCSVData().contains(bl.csvData));
			System.assertEquals(bl.csvHeader, bl.getCSVHeader());
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - Simple test of DigitalSubscriber wrapper class - all setter and getters
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testDigitalSubscriberWrapper(){
		Test.startTest();
			MPPLetterExtractData.DigitalSubscriber ds = new MPPLetterExtractData.DigitalSubscriber();
			System.assertEquals(null, ds.acc);
			System.assertEquals(null, ds.subStartDate);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - Simple test of SubscriberTransaction wrapper class 
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testSubscriberTransactionWrapper(){
		TestDataUtility td = new TestDataUtility(1);
		td.createIndividualSubscribers();
		Test.startTest();
			//test empty constructor
			MPPLetterExtractData.SubscriberTransaction st = new MPPLetterExtractData.SubscriberTransaction();
			System.assertEquals(null, st.acc);
			System.assertNotEquals(null, st.monthly);
			System.assertNotEquals(null, st.annual);
 			System.assert(st.monthly.isEmpty());
 			System.assert(st.annual.isEmpty());

 			//test constructor with Account
 			st = new MPPLetterExtractData.SubscriberTransaction(td.lstIndividualSubscribers[0]);
 			System.assertEquals(td.lstIndividualSubscribers[0].Id, st.acc.Id);
 			System.assertNotEquals(null, st.monthly);
			System.assertNotEquals(null, st.annual);
 			System.assert(st.monthly.isEmpty());
 			System.assert(st.annual.isEmpty());
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test retrieval of csv headers, and DDCC query generator
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testDDCCABatchQueryAndHeaders(){
		TestDataUtility td = new TestDataUtility(1);
		Id profileId = td.getProfileIdForName(Constants.PROFILE_SYSTEMADMINISTRATOR);
		User u = TestDataUtility.newUser(0, profileId);
		u.FirstName = null;
		u.lastName = Constants.USERNAME_POC_GUEST;
		insert u;

		Test.startTest();
			System.assert(String.isNotBlank(MPPLetterExtractData.CSV_DDCCA_HEADER));
			System.assert(String.isNotBlank(MPPLetterExtractData.CSV_DIGITAL_SUBSCRIBER_HEADER));

			PDD_Settings__c pdd = new PDD_Settings__c(Name = Constants.PDD_SETTING_CUSTOM_DDCCA_DATE, DD_Created_Date__c = Date.today().addDays(-2));
			insert pdd;
			String sQuery = MPPLetterExtractData.getMPP_DDCCA_BatchQuery();
			System.assert(String.isNotBlank(sQuery));
			System.assert(sQuery.contains(u.Id));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test retrieval of csv headers, and CCA query generator
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testCCABatchQuery(){
		TestDataUtility td = new TestDataUtility(1);
		Id profileId = td.getProfileIdForName(Constants.PROFILE_SYSTEMADMINISTRATOR);
		User u = TestDataUtility.newUser(0, profileId);
		u.FirstName = null;
		u.lastName = Constants.USERNAME_POC_GUEST;
		insert u;

		Test.startTest();
			PDD_Settings__c pdd = new PDD_Settings__c(Name = Constants.PDD_SETTING_CUSTOM_DDCCA_DATE, DD_Created_Date__c = Date.today().addDays(-2));
			insert pdd;
			String sQuery = MPPLetterExtractData.getMPP_CCA_BatchQuery();
			System.assert(String.isNotBlank(sQuery));
			System.assert(sQuery.contains(u.Id));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test DD query generator
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testDDBatchQuery(){
		TestDataUtility td = new TestDataUtility(1);
		Id profileId = td.getProfileIdForName(Constants.PROFILE_SYSTEMADMINISTRATOR);
		User u = TestDataUtility.newUser(0, profileId);
		u.FirstName = null;
		u.lastName = Constants.USERNAME_POC_GUEST;
		insert u;

		Test.startTest();
			PDD_Settings__c pdd = new PDD_Settings__c(Name = Constants.PDD_SETTING_CUSTOM_DDCCA_DATE, DD_Created_Date__c = Date.today().addDays(-2));
			insert pdd;
			String sQuery = MPPLetterExtractData.getMPP_DD_BatchQuery();
			System.assert(String.isNotBlank(sQuery));
			System.assert(sQuery.contains(u.Id));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test Digital account query generator
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testDigitalBatchQuery(){	
		Test.startTest();
			String sQuery = MPPLetterExtractData.getMPP_Digital_BatchQuery();
			System.assert(String.isNotBlank(sQuery));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test file name generating method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testCreateFileName(){
		Date dtOther = Date.today().addDays(-2);
		PDD_Settings__c pdd = new PDD_Settings__c(Name = Constants.PDD_SETTING_CUSTOM_PDD_DATE, DD_Created_Date__c = dtOther);
		insert pdd;
		Test.startTest();
			String sFileName = 'myfile';
			String sExtension = 'csv';
			String sFileName1 = MPPLetterExtractData.createFileName(sFileName, sExtension, 1);
			String sFileName2 = MPPLetterExtractData.createFileName(sFileName, sExtension, 0);
			System.assert(String.isNotBlank(sFileName1));
			System.assert(String.isNotBlank(sFileName2));
			System.assert(sFileName1.contains(dtOther.format().replaceAll('/', '-')));
			System.assert(sFileName2.contains(Date.today().format().replaceAll('/', '-')));
			System.assert(sFileName1.contains(sExtension));
			System.assert(sFileName2.contains(sExtension));
		Test.stopTest();	
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test method that returns only the name of the file without extension - based on passed in file string
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testRetrieveFileName(){
		Test.startTest();
			System.assertEquals(null, MPPLetterExtractData.retrieveFileName(null));
			System.assert(!MPPLetterExtractData.retrieveFileName('test.xml').contains('.xml'));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - simple "enhanced" is not empty method check
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testIsValid(){
		Test.startTest();
			System.assert(!MPPLetterExtractData.isValid(null));
			System.assert(MPPLetterExtractData.isValid('test'));
			System.assertEquals(' ', MPPLetterExtractData.getValidCSV_Value(null));
			System.assertEquals('test', MPPLetterExtractData.getValidCSV_Value('test'));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method pad()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testPad(){
		Test.startTest();
			String sText = 'test';
			System.assertEquals(sText+sText, MPPLetterExtractData.pad(sText, 2));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method leftPadding()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testLeftPadding(){
		Test.startTest();
			System.assertEquals(null, MPPLetterExtractData.leftPadding(null, null, 2));
			System.assertEquals('tstststme', MPPLetterExtractData.leftPadding('testme', 'ts', 3));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method prefixPadding()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testPrefixPadding(){
		Test.startTest();
			System.assertEquals(null, MPPLetterExtractData.prefixPadding(null, null, 2));
			System.assertEquals('tststest', MPPLetterExtractData.prefixPadding('test', 'ts', 2));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method - simple replace comma method
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testReplaceComma(){
		Test.startTest();
			System.assertEquals(null, MPPLetterExtractData.replaceCommaWithSpace(null));
			System.assertEquals('t t', MPPLetterExtractData.replaceCommaWithSpace('t,t'));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method - date conversion method test
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testDateMethods(){
		Test.startTest();
			System.assertEquals(null, MPPLetterExtractData.getDate(null));
			System.assertEquals(Date.today().day()+'/'+Date.today().month()+'/'+Date.today().year(), MPPLetterExtractData.getDate(Date.today().year()+'-'+Date.today().month()+'-'+Date.today().day()+'T00:00:00'));
			Date dt = Date.newInstance(2014, 04, 23);
			Datetime dtime= Datetime.newInstance(dt, Time.newInstance(10, 0, 0, 0));
			System.assertEquals(null, MPPLetterExtractData.getSFDCDate((Date)null));
			System.assertEquals('23/04/2014', MPPLetterExtractData.getSFDCDate(dt));
			System.assertEquals(null, MPPLetterExtractData.getSFDCDate((Datetime)null));
			System.assertEquals('23/04/2014', MPPLetterExtractData.getSFDCDate(dtime));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method -  method that returns title string depending which one is available based on sfdc fields
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testGetTitle(){
		Test.startTest();
			System.assertEquals('', MPPLetterExtractData.getTitle(null, null, null));
			String sWithCommas = 'test,test';
			String sWithoutCommas = 'test test';
			System.assertEquals(sWithoutCommas, MPPLetterExtractData.getTitle(sWithCommas, null, null));
			System.assertEquals(sWithoutCommas, MPPLetterExtractData.getTitle(null, sWithCommas, null));
			System.assertEquals(sWithoutCommas, MPPLetterExtractData.getTitle(null, null, sWithCommas));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method -  method that formats address into multiple comma separated values
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testGetMailingAddress(){
		Test.startTest();
			System.assertEquals(' ,  ,  , ', MPPLetterExtractData.getMailingAddress(''));
			System.assertEquals('onelineaddress,  ,  , ', MPPLetterExtractData.getMailingAddress('onelineaddress'));
			System.assertEquals('onelineaddress, twolineaddress,  , ', MPPLetterExtractData.getMailingAddress('onelineaddress\ntwolineaddress'));
			System.assertEquals('onelineaddress, twolineaddress, threelineaddress, ', MPPLetterExtractData.getMailingAddress('onelineaddress\ntwolineaddress\nthreelineaddress'));
			System.assertEquals('onelineaddress;twolineaddress, threelineaddress, fourlineaddress, ', MPPLetterExtractData.getMailingAddress('onelineaddress\ntwolineaddress\nthreelineaddress\nfourlineaddress'));
			System.assertEquals('onelineaddress;twolineaddress, threelineaddress;fourlineaddress, fivelineaddress, ', MPPLetterExtractData.getMailingAddress('onelineaddress\ntwolineaddress\nthreelineaddress\nfourlineaddress\nfivelineaddress'));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method -  method that builds request url for MPP
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public static testMethod void testParamsBuilder(){
		TestDataUtility td = new TestDataUtility(10);
		td.createSubscriptions();
		List<Subscription__c> lstSubscriptions = [select Id, Subscriber__r.Subscriber_Number_static__c from Subscription__c];
		System.assert(!lstSubscriptions.isEmpty());
		Test.startTest();
			String sResult = MPPLetterExtractData.buildParamMap(lstSubscriptions);
			System.assert(String.isNotBlank(sResult));
			System.assertEquals(10, sResult.countMatches('TSNumber'));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv helper method - method that defines frequency of digital sub
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testGetDigitalFrequency(){
		Test.startTest();
			System.assertEquals('MONTHLY', MPPLetterExtractData.getDigitalFrequency(10));
			System.assertEquals('ANNUAL', MPPLetterExtractData.getDigitalFrequency(60));
			System.assertEquals('UNKNOWN', MPPLetterExtractData.getDigitalFrequency(40));
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.0
    Function - test for csv row generating method related to digital sub
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testMethod void testCreateCSVRowForDigital(){
		TestDataUtility td = new TestDataUtility(1);
		td.createDigitalSubscribers();
		Test.startTest();
			MPPLetterExtractData.DigitalSubscriber digisub = new MPPLetterExtractData.DigitalSubscriber();
			digisub.acc = td.lstDigitalSubscribers[0];
			digisub.subStartDate = Datetime.now();
			String sDigitalAccountResult = MPPLetterExtractData.createCSV_Row(digisub);
			System.assert(String.isNotBlank(sDigitalAccountResult));
			System.assert(digisub.acc.Is_Digital_Letter_Extracted__c);
		Test.stopTest();
	}		

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.1
    Function - test for csv row generating method related to premium sub with CC payment option
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin 	1.1			09/02/2016	//modified soql to use common set of fields, removed setting of params that have no impact any more
    ****************************************************************************************/
	private static testMethod void testCreateCSVRowForAccountWithSubscriptionCC(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		td.lstSubscriptions[0].MPP_CC_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
		update td.lstSubscriptions[0];

		List<Subscription__c> lstSub =  Database.query('select ' + MPPLetterExtractData.getFieldsToQuery() + ' from Subscription__c where Id = \'' +td.lstSubscriptions[0].Id +'\'');
		System.assert(!lstSub.isEmpty());
		Subscription__c sub = lstSub[0];
		sub.MPP_CC_Next_Payment_Date__c  = Date.today();
		sub.MPP_CC_First_Payment_Amount__c = 9;
		MPPInterfaceHTTP.PaymentDetailResult pdr = new MPPInterfaceHTTP.PaymentDetailResult();
		pdr.payerRef = 'testRef';
		pdr.sortCode = '1234';
		pdr.accNumber = 'acc112';
		pdr.collectionDate = '01/01/2015';
		pdr.creditCardNumber = '24314';
		pdr.creditCardExpiryDate = '08/16';
		pdr.creditCardAuthCode = '123';
		
		Test.startTest();
			String sResult = MPPLetterExtractData.createCSV_Row(sub, pdr);
			System.assert(sResult.contains(Constants.DD_COL_FREQ_MONTHLY));
			System.assert(sub.Is_MPP_DDCCA_Letter_Extracted__c);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 23-26/10/2015
    Version - 1.1
    Function - test for csv row generating method related to premium sub with DD payment option
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin 	1.1			09/02/2016	//modified soql to use common set of fields, removed setting of params that have no impact any more	
    ****************************************************************************************/
	private static testMethod void testCreateCSVRowForAccountWithSubscriptionDD(){
		TestDataUtility td = new TestDataUtility(1);
		td.createSubscriptions();
		td.lstSubscriptions[0].MPP_DD_Frequency__c = Constants.DD_COL_FREQ_MONTHLY;
		update td.lstSubscriptions[0];

		List<Subscription__c> lstSub =  Database.query('select ' + MPPLetterExtractData.getFieldsToQuery() + ' from Subscription__c where Id = \'' +td.lstSubscriptions[0].Id +'\'');

		System.assert(!lstSub.isEmpty());
		Subscription__c sub = lstSub[0];
		sub.MPP_DD_Next_Payment_Date__c = Date.today();
		sub.MPP_DD_First_Payment_Amount__c = 9;
		MPPInterfaceHTTP.PaymentDetailResult pdr = new MPPInterfaceHTTP.PaymentDetailResult();
		pdr.payerRef = 'testRef';
		pdr.sortCode = '1234';
		pdr.accNumber = 'acc112';
		pdr.creditCardNumber = '24314';
		pdr.creditCardExpiryDate = '08/16';
		pdr.creditCardAuthCode = '123';
		
		Test.startTest();
			String sResult = MPPLetterExtractData.createCSV_Row(sub, pdr);
			System.assert(sResult.contains(Constants.DD_COL_FREQ_MONTHLY));
			System.assert(sub.Is_MPP_DDCCA_Letter_Extracted__c);
		Test.stopTest();
	}
}