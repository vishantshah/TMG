/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk 1.1         24/04/2016 // changed multiAccountUsageTest() and nullFirstAccessOnInsertTest()
Wiktor Czykin   1.2         20/03/2017 // modified slightly all methods. Modified 2 methods that were adding more than 1 account - prevent email dupe.
**/

@isTest
private class UsageTrackingTriggerHandlerTest {

    static testMethod void insertNewUsageTest() {
        TestDataUtility td = new TestDataUtility(1);
		td.checkAccountDependencies();
        Account acc = createAccount();
        insert acc;
        
        DateTime accessDate = DateTime.now();
        
        Usage_Tracking__c trackingInfo = createTracking('Tablet', acc.Id, accessDate, accessDate);
        insert trackingInfo;
        
		acc = [select id, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c from Account where id = :acc.Id];
		system.assertEquals(accessDate, acc.Tablet_First_Accessed__c);
		system.assertEquals(accessDate, acc.Tablet_Last_Accessed__c);
    }

    static testMethod void updateNewUsageTest() {
        TestDataUtility td = new TestDataUtility(1);
		td.checkAccountDependencies();
        Account acc = createAccount();
        insert acc;
        
        DateTime accessDate = DateTime.now();
        
        Usage_Tracking__c trackingInfo = createTracking('Mobile', acc.Id, accessDate, accessDate);
        insert trackingInfo;
        
        trackingInfo.Last_Accessed_Date__c = accessDate.addDays(1);
        update trackingInfo;
        
		acc = [select id, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c from Account where id = :acc.Id];
		system.assertEquals(accessDate, acc.Mobile_First_Accessed__c);
		system.assertEquals(accessDate.addDays(1), acc.Mobile_Last_Accessed__c);
    }

    static testMethod void multiUsageInsertTest() {
        TestDataUtility td = new TestDataUtility(1);
		td.checkAccountDependencies();
        Account acc = createAccount();
        insert acc;
        
        DateTime accessDate = DateTime.now();
        
        List<Usage_Tracking__c> trackingInfo = new List<Usage_Tracking__c>();
        trackingInfo.add(createTracking('Mobile', acc.Id, accessDate, accessDate));
        trackingInfo.add(createTracking('Mobile', acc.Id, accessDate, accessDate.addDays(1)));
        trackingInfo.add(createTracking('Tablet', acc.Id, accessDate, accessDate));
        trackingInfo.add(createTracking('Tablet', acc.Id, accessDate, accessDate.addDays(1)));
        insert trackingInfo;
        
		acc = [select id, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c from Account where id = :acc.Id];
		system.assertEquals(accessDate, acc.Tablet_First_Accessed__c);
		system.assertEquals(accessDate.addDays(1), acc.Tablet_Last_Accessed__c);
		system.assertEquals(accessDate, acc.Mobile_First_Accessed__c);
		system.assertEquals(accessDate.addDays(1), acc.Mobile_Last_Accessed__c);
    }
    /*************************************************************************************** 
    Date - unknown
    Version - 1.0
    Function - unknown
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         28/04/2016 //added SAM settings 
    ****************************************************************************************/
    static testMethod void multiAccountUsageTest() {
        TestDataUtility td = new TestDataUtility(1);
        td.checkAccountDependencies();
        List<Account> acc = new List<Account>();
        acc.add(createAccount());
        Account acc2 =createAccount();
        acc2.PersonEmail = 'someOtherEmail@telegraph.co.uk'; 
        acc.add(acc2);
        insert acc;

        DateTime accessDate = DateTime.now();
    	List<Usage_Tracking__c> trackingInfo = new List<Usage_Tracking__c>();
    	trackingInfo.add(createTracking('Mobile', acc[0].Id, accessDate, accessDate));
    	trackingInfo.add(createTracking('Tablet', acc[1].Id, accessDate, accessDate));
    	insert trackingInfo;
    	
		for(Account a : [select id, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c from Account where id in :acc]){
			if(a.Id == acc[0].Id){
				System.assertEquals(accessDate, a.Mobile_First_Accessed__c);
				System.assertEquals(accessDate, a.Mobile_Last_Accessed__c);
			}else{
				System.assertEquals(accessDate, a.Tablet_First_Accessed__c);
				System.assertEquals(accessDate, a.Tablet_Last_Accessed__c);
			}
		}
		
    }
    /*************************************************************************************** 
    Date - unknown
    Version - 1.1
    Function - unknown
    #############Change Log#############
    Modified by         Version     Change Date
    Michal Szewczyk     1.1         28/04/2016 //added SAM settings 
    ****************************************************************************************/
    static testMethod void nullFirstAccessOnInsertTest() {
        TestDataUtility td = new TestDataUtility(1);
        td.checkAccountDependencies();
        List<Account> acc = new List<Account>();
        acc.add(createAccount());
        Account acc2 = createAccount();
        acc2.PersonEmail = 'someOtherEmail@telegraph.co.uk'; 
        acc.add(acc2);
        insert acc;
        
        DateTime accessDate = DateTime.now();
    	list<Usage_Tracking__c> trackingInfo = new list<Usage_Tracking__c>();
    	trackingInfo.add(createTracking('Mobile', acc[0].Id, null, accessDate));
    	trackingInfo.add(createTracking('Tablet', acc[1].Id, null, accessDate));
    	insert trackingInfo;

        
		for(Usage_Tracking__c ti : [select First_Accessed_Date__c, Last_Accessed_Date__c from Usage_Tracking__c where id in :trackingInfo]){
			System.assertEquals(ti.Last_Accessed_Date__c, ti.First_Accessed_Date__c);
		}
    	
		for(Account a : [select id, Mobile_First_Accessed__c, Mobile_Last_Accessed__c, Tablet_First_Accessed__c, Tablet_Last_Accessed__c from Account where id in :acc]){
			if(a.Id == acc[0].Id){
				System.assertEquals(a.Mobile_Last_Accessed__c, a.Mobile_First_Accessed__c);
				System.assertEquals(accessDate, a.Mobile_Last_Accessed__c);
			}else{
				System.assertEquals(a.Tablet_Last_Accessed__c, a.Tablet_First_Accessed__c);
				System.assertEquals(accessDate, a.Tablet_Last_Accessed__c);
			}
			
		}
    }

    static testMethod void firstAccessedDateCannotGoForwardInTimeTest() {
        TestDataUtility td = new TestDataUtility(1);
		td.checkAccountDependencies();
        Account acc = createAccount();
        insert acc;
        
        DateTime accessDate = DateTime.now();
        
        Usage_Tracking__c trackingInfo = createTracking('Mobile', acc.Id, accessDate, accessDate);
        insert trackingInfo;
        
        trackingInfo.First_Accessed_Date__c = accessDate.addDays(1);
        update trackingInfo;
        
		trackingInfo = [select First_Accessed_Date__c from Usage_Tracking__c where id = :trackingInfo.Id];
		System.assertEquals(accessDate, trackingInfo.First_Accessed_Date__c);
    }

    static testMethod void lastAccessedDateCannotGoBackInTimeTest() {
        TestDataUtility td = new TestDataUtility(1);
        td.checkAccountDependencies();
        Account acc = createAccount();
        insert acc;
        
        datetime accessDate = datetime.now();
        
        Usage_Tracking__c trackingInfo = createTracking('Mobile', acc.Id, accessDate, accessDate);
        insert trackingInfo;
        
        trackingInfo.Last_Accessed_Date__c = accessDate.addDays(-1);
        update trackingInfo;
        
		trackingInfo = [select Last_Accessed_Date__c from Usage_Tracking__c where id = :trackingInfo.Id];
		system.assertEquals(accessDate, trackingInfo.Last_Accessed_Date__c);
    }

    private static Account createAccount(){
        Account acc = new Account();
        acc.Title__c = 'Mr.';
        acc.FirstName = 'Amir';
        acc.LastName = 'Hafeez';
        acc.PersonEmail = String.valueOf(Math.random()) + '@test.com';
        acc.PersonMailingPostalCode = 'E11 1JY';
    	return acc;
    }
    
    private static Usage_Tracking__c createTracking(string deviceType, Id accountId, datetime firstAccessed, datetime lastAccessed){
        Usage_Tracking__c trackingInfo=new Usage_Tracking__c();
        trackingInfo.App_Name__c = 'Jeremy';
        trackingInfo.App_Version__c = '1';
        trackingInfo.Device_Unique_ID__c = string.valueOf(math.Random());  //Must be random otherwise we get duplicate errors for TalendUpsertKey__c
        trackingInfo.Device_Operating_System__c = 'Android';
        trackingInfo.Device_Name__c = 'Timothy';
        trackingInfo.Device_Type__c = deviceType;
        trackingInfo.First_Accessed_Date__c = firstAccessed;
        trackingInfo.Last_Accessed_Date__c = lastAccessed;
        trackingInfo.Account__c = accountId;
        return trackingInfo;
    }
}