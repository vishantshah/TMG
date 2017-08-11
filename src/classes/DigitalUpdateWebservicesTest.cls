/**
* @author Unknown
* @date Unknown
* @description
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin	1.1			23/02/2016  //removed usage of old TestDataUtility methods
Wiktor Czykin	1.2			22/03/2016	//modified testClearDigitalEntitlementsSuccess()
**/
@isTest(SeeAllData=false)
private class DigitalUpdateWebservicesTest {
	
	private static Id digitalRecordTypeId=TMGUtil.recordTypeMap.get('Account.Digital Subscriber').Id;
	private static Id printRecordTypeId=TMGUtil.recordTypeMap.get('Account.Individual Subscriber').Id;
	private static void init(){
		TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
	}
	private static testMethod void testUpdateLastAccessedData_success(){
		init();
		DateTime firstAccessed = DateTime.now();
		Account a = new Account(Title__c='Mr.', lastname='testUpdateLastAccessedDatasuccess',Subscriber_Digital_Status__c='Active');
		insert a;
		
		a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		DigitalUpdateWebservices.UpdateLastAccessedData(a.Subscriber_Number_Static__c, 'website', firstAccessed);

		a = [SELECT Id, Website_First_Accessed__c, Website_Last_Accessed__c, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		system.assertEquals(firstAccessed, a.Website_First_Accessed__c);
		system.assertEquals(firstAccessed, a.Website_Last_Accessed__c);
				
	}
	
	private static testMethod void testUpdateLastAccessedData_success_secondupdate(){
		init();
		DateTime firstAccessed = DateTime.now().addDays(-1);
		Account a = new Account(Title__c='Mr.', lastname='testUpdateLastAccessedDatasuccesssecondupdate',Subscriber_Digital_Status__c='Active');
		insert a;
		
		a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		DigitalUpdateWebservices.UpdateLastAccessedData(a.Subscriber_Number_Static__c, 'website', firstAccessed);

		a = [SELECT Id, Website_First_Accessed__c, Website_Last_Accessed__c, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		system.assertEquals(firstAccessed, a.Website_First_Accessed__c);
		system.assertEquals(firstAccessed, a.Website_Last_Accessed__c);
		
		DateTime lastAccessed = DateTime.now();
		DigitalUpdateWebservices.UpdateLastAccessedData(a.Subscriber_Number_Static__c, 'website', lastAccessed);

		a = [SELECT Id, Website_First_Accessed__c, Website_Last_Accessed__c, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		system.assertEquals(firstAccessed, a.Website_First_Accessed__c);
		system.assertEquals(lastAccessed, a.Website_Last_Accessed__c);
		
				
	}
	
	private static testMethod void testUpdateLastAccessedData_failure(){
		init();
		DateTime firstAccessed = DateTime.now();
		Account a = new Account(Title__c='Mr.', lastname='testUpdateLastAccessedDatafailure');
		insert a;

		a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		SubscriptionsWebservices.GeneralSubscriptionsWebserviceResult ret =DigitalUpdateWebservices.UpdateLastAccessedData(a.Subscriber_Number_Static__c, 'frank', firstAccessed);

		system.assertNotEquals(null, ret);
		system.assertNotEquals(null, ret.wsError);
				
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.2
    Function - test for ClearDigitalEntitlements method
    #############Change Log#############
	Modified by     Version     Change Date
	Wiktor Czykin	1.1			23/02/2016	//removed usage of initSAMPlaneURL method from TestDataUtility
	Wiktor Czykin	1.2			22/03/2016	//added assertion, modified to fully use TestDataUtility
    ****************************************************************************************/
	private static testMethod void testClearDigitalEntitlementsSuccess(){
		init();
		TestDataUtility td = new TestDataUtility(3);
		td.loadPlaneURL();
		td.createTCodeManagement();
		td.createSubscriptions();
		td.createDigitalSubscribers();

		List<String> guids = new List<String>();
		Integer i = 1;
		for(Account acc : td.lstDigitalSubscribers){
			acc.Guid__c = 'digiguid'+i;
			acc.Subscriber_Digital_Status__c = Constants.SUBSCRIBER_ACTIVE_STATUS;
			guids.add(acc.Guid__c);
			i++;
		}
		update td.lstDigitalSubscribers;
		for(Account acc : td.lstIndividualSubscribers){
			acc.Guid__c = 'printguid'+i;
			guids.add(acc.Guid__c);
			i++;
		}
		update td.lstIndividualSubscribers;
		Test.startTest();
			DigitalUpdateWebservices.ClearDigitalEntitlements(guids);
		Test.stopTest();	

		List<Account> lstDigi = [select Id, Subscriber_Digital_Status__c from Account where Id in :td.lstDigitalSubscribers];
		System.assert(!lstDigi.isEmpty());
		for(Account acc : lstDigi){
			System.assertEquals(Constants.SUBSCRIBER_INACTIVE_STATUS, acc.Subscriber_Digital_Status__c);
		}
	}
	
	
	private static testMethod void testUpdateUsage(){
		init();
		DateTime lastAccessed = DateTime.now();
		Account a = new Account(Title__c='Mr.', lastname='testUpdateLastAccessedDatafailure');
		insert a;

		a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		
		
		DigitalUpdateWebservices.VendorId vId=new DigitalUpdateWebservices.VendorId();
		vId.id='test id';
		vId.idType = 'test idType';
		
		DigitalUpdateWebservices.DeviceInfo devInfo=new DigitalUpdateWebservices.DeviceInfo();
		devInfo.deviceid='dev001';
		devInfo.deviceName='apple';
		
		DigitalUpdateWebservices.SubscriptionDetails subdetail=new DigitalUpdateWebservices.SubscriptionDetails();
		
		DigitalUpdateWebservices.UpdateUsage(vId, subdetail, devInfo, lastAccessed);
	}
	
	
	private static testMethod void testUpdateUsageTracking(){
		init();
		DateTime lastAccessed = DateTime.now();
		Account a = new Account(Title__c='Mr.', lastname='testUpdateLastAccessedDatafailure');
		insert a;

		a = [SELECT Id, Subscriber_Number_Static__c FROM Account WHERE Id = :a.Id LIMIT 1];
		DigitalUpdateWebservices.VendorId vId=new DigitalUpdateWebservices.VendorId();
		vId.id='test id';
		vId.idType = 'test idType';
		
		DigitalUpdateWebservices.DeviceInfo devInfo=new DigitalUpdateWebservices.DeviceInfo();
		devInfo.deviceid='dev001';
		devInfo.deviceName='apple';
		
		DigitalUpdateWebservices.EntitlementDetails entitlement=new DigitalUpdateWebservices.EntitlementDetails();
		entitlement.entitlementIdentifier='Testentitle';
		entitlement.entitlementType='Testtype';
		
		DigitalUpdateWebservices.SubscriptionDetails subdetail=new DigitalUpdateWebservices.SubscriptionDetails();
		
		DigitalUpdateWebservices.UpdateUsageTracking(vId, entitlement, devInfo, lastAccessed);
		
	}
}