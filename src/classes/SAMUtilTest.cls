/**
* @author Unknown
* @date Unknown
* @description Test class for SAMUtil
#############Change Log#############
Modified by     	Version     Change Date
Pawel Chrzanowski   1.1         14/03/2016  //modified setupSAMData_Digital(), setupSAMData_Premium() to test email update only
Pawel Chrzanowski   1.2         01/04/2016  //removed setupSAMData_Digital() and setupSAMData_Premium(), added setupSAMDataTest()
Michal Szewczyk     1.3         20/04/2016  //added setEntitlemetMapping to init()
**/
@isTest(SeeAllData=false)
private class SAMUtilTest {
    private static Account a;
    private static void init(){
        TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        tdu.setEntitlemetMapping();
    }
    
    
    /*  Setup the Test Account (it doesnt matter if Premium or Digital for this test)
    */
    private static String setupAccountData(){
        a = new Account();
        a.Title__c = 'Mr.';
        a.Guid__c = 'GUIDTestMethodData' + Math.random();
        a.Wave_ID__c = '445T'; 
        a.PersonTitle = 'Mr';
        a.FirstName = 'Testio';
        a.LastName = 'Testev';
        a.PersonEmail= DateTime.now().getTime() + 'testio@test.com';
        a.PersonMailingStreet = 'Cannon Street';
        a.PersonMailingCity = 'Reading';
        a.PersonMailingPostalCode = 'RG1';
        a.PersonMailingCountry = 'GB';
        a.PersonHomePhone = '077777777777';
        a.Origin__c = 'Online';
        a.Email_Sent__c = false;
        a.TMG_Promo_Email__c = 1;
        a.TMG_Promo_Phone__c = 1;
        a.TMG_Promo_Post__c = 1;
        a.TMG_Promo_SMS__c = 1;
        a.TMG_Loyalty_Email__c = 1;
        a.TMG_Loyalty_Phone__c = 1;
        a.TMG_Loyalty_Mail__c = 1;
        a.TMG_Loyalty_SMS__c =1;
        insert a;
    
        if(Country_Codes__c.getInstance('GB') == null){
            Country_Codes__c cc = new Country_Codes__c( name='GB', Country_Name__c='United Kingdom');
            insert cc;
        }
        String TsNumber = [select Subscriber_Number_static__c from Account where id=:a.id].Subscriber_Number_static__c;
        return TsNumber;        
    }
    
	/*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 31/03/2016
    Version - 1.0
    Function - Test setupSAMData()
    #############Change Log#############
	Modified by    		Version     Change Date
    ****************************************************************************************/
	private static testMethod void setupSAMDataTest(){    	
    	init();
    	String tsNumber = setupAccountData();
    	Account acc = [SELECT Id, RecordTypeId, GUID__c, Salutation, FirstName, LastName, PersonEmail, PersonMailingStreet, PersonMailingCity,
               PersonMailingPostalCode, PersonMailingCountry, PersonMailingState,
               PersonHomePhone, Origin__c, Email_Sent__c,  TMG_Promo_Email__c,  TMG_Promo_Phone__c,
               TMG_Promo_Post__c, TMG_Promo_SMS__c, TMG_Loyalty_Email__c, TMG_Loyalty_SMS__c, 
               TMG_Partner_Promo_Email__c, Subscriber_Number_static__c, Subscriber_Digital_Status__c, Product__c From Account WHERE Subscriber_Number_Static__c=:tsNumber];
    	
		Id rt = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_DEFAULT, Subscription__c.class.getName());
		Date startDate = UtilitySelectOptionsSubscriptions.getFirstStartDate(5);
    	Subscription__c sub = new Subscription__c(Voucher_Pack_Duration__c=1, Cancellation_Date__c=null, Cancellation_Method__c=null, Cancellation_Reason__c=null, Start_Date__c=startDate, Payment_Type__c='Cheque', Delivery_Type__c='OTC', Weekly_Price__c=5, Subscription_Status__c=Constants.SSTATUS_ACTIVE, Subscription_Duration_Picklist__c='26', Subscriber__c=acc.Id, RecordTypeId=rt, Payment_Details_Received__c=true);
    	insert sub;

    	Test.startTest();
    		SAMUtil samUtil = new SAMUtil();
    		SubscriptionsSAMWebservices.commonRequest request = samUtil.setupSAMData(acc, tsNumber, 'digital');
        	System.assertEquals(acc.Salutation, request.title);
        	System.assertEquals(acc.LastName, request.lastname);
        	System.assertEquals(acc.FirstName, request.firstname);
        	System.assertEquals(acc.PersonEmail, request.email);
        	System.assertEquals(acc.PersonMailingStreet, request.street);
        	System.assertEquals(acc.PersonMailingCity, request.city);
        	System.assertEquals(acc.PersonMailingPostalCode, request.postcode);
        	System.assertEquals(acc.PersonMailingCountry, request.country);
        	System.assertEquals(acc.PersonMailingState, request.county);
        	System.assert(request.marketingEmailPref);
        	System.assert(request.marketingPhonePref);
        	System.assert(request.marketingPostPref);
        	System.assert(request.marketingSMSPref);
        	System.assert(!request.marketing3rdPref);
        	System.assert(request.subscribersOfferPref);        	
        	System.assertEquals(samUtil.SAMServiceKey, request.samServiceKey);
        	System.assertEquals(tsNumber, request.tsNumber);
        	System.assertEquals(SubscriberPortal.SEVENDAY_ENT_PREFIX + Constants.SSTATUS_ACTIVE.toUpperCase(), request.entitlements);
        Test.stopTest();
    }
    
    public static testMethod void testisExistingSamAccount(){
    	init();
    	SAMUtil samUtil = new SAMUtil();
    	
    	Exception ex;
    	try{
    		System.assertEquals(null, samUtil.isExistingSamAccount(''));
    	}
		catch(WebserviceUtil.NullParameterException e){
			ex = e;
		}
		System.assert(ex instanceof WebserviceUtil.NullParameterException);
		
		try{
    		System.assertEquals(null, samUtil.isExistingSamAccount(null));
    	}
		catch(WebserviceUtil.NullParameterException e){
			ex = e;
		}
		System.assert(ex instanceof WebserviceUtil.NullParameterException);
    	
        Test.startTest();
        
        String Guid = samUtil.isExistingSamAccount('test');
        Test.stopTest();
        System.assertEquals('GUID__TEST', Guid);
    }
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         04/09/2015  //removed TestDataUtility.insertErrorMessage() call
    ****************************************************************************************/
    public static testMethod void testGetExistingSAMAccount(){
        init();
        SAMUtil samUtil = new SAMUtil();
        
        Exception ex;
        try{
            System.assertEquals('INACTIVE', samUtil.getExistingSAMAccount('').entitlementStatus);
        }
        catch(WebserviceUtil.NullParameterException e){
            ex = e;
        }
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
        try{
            System.assertEquals('INACTIVE', samUtil.getExistingSAMAccount(null).entitlementStatus);
        }
        catch(WebserviceUtil.NullParameterException e){
            ex = e;
        }
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
        SAMUtil.SAMAccountResult result;
        Test.startTest();
            result = samUtil.getExistingSAMAccount('test');
        Test.stopTest();
        
        System.assertEquals('GUID__TEST', result.guid);
        System.assertEquals('INACTIVE', result.entitlementStatus);

        // test criteria added for ACCOUNT_LOCKED scenario in response.status
        String errMessage = '';
        try{
            samUtil.getExistingSAMAccount('ACCOUNT_LOCKED@TEST');
        }
        catch(WebserviceUtil.SamException e){
            errMessage = e.getError().errorMessage;
            System.debug('ACCOUNT_LOCKED ERROR THROWN - ' + errMessage);
            System.debug(Label.SAM_Account_locked_error);
        }
        System.assert(errMessage.contains('ACCOUNT_LOCKED'));
    }
    
    public static testMethod void testupdateSamAccount(){
        init();
        String TsNumber = setupAccountData();
        System.debug('TsNumber: '+TsNumber);
        
        SAMUtil samUtil = new SAMUtil();
        
        Exception ex;
        try{
            samUtil.updateSamAccount(a, '', a.Guid__c, 'digital', true);
        }
        catch(WebserviceUtil.NullParameterException e){
            ex = e;
        }
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
        try{
            samUtil.updateSamAccount(a, null, a.Guid__c, 'digital', true);
        }
        catch(WebserviceUtil.NullParameterException e){
            ex = e;
        }
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
        Test.startTest();
        
        ex = null;
        try{
            samUtil.updateSamAccount(a, TsNumber, a.Guid__c, 'digital', true);
        }
        catch(Exception e){
            ex = e;
        }
        Test.stopTest();
        System.assertEquals(null, ex);
    }
    
    public static testMethod void testcreateSamAccount(){
        init();
        String TsNumber = setupAccountData();
        System.debug('TsNumber: '+TsNumber);
        
        SAMUtil samUtil = new SAMUtil();
        
        Exception ex;
        try{
            samUtil.createSamAccount(a, '', 'digital', true, false);
        }
        catch(WebserviceUtil.NullParameterException e){
            ex = e;
        }
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
        try{
            samUtil.createSamAccount(a, null, 'digital', true, false);
        }
        catch(WebserviceUtil.NullParameterException e){
            ex = e;
        }
        System.assert(ex instanceof WebserviceUtil.NullParameterException);
        
        Test.startTest();
        
        ex = null;
        String Guid;
        try{
            Guid = samUtil.createSamAccount(a, TsNumber, 'digital', true, false);
        }
        catch(Exception e){
            ex = e;
        }
        Test.stopTest();
        System.assertEquals('GUID__TEST', Guid);
        System.assertEquals(null, ex);
    }
}