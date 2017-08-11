@isTest(SeeAllData=false)
private class ClearDigitalEntitlementsBatchTest {
	private static void init(){
		TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
	}
	private static testMethod void ClearDigitalEntitlementsBatch_single(){
		init();
		Account a = new Account( name = 't1', Subscriber_Digital_Status__c = 'Active', guid__c = '1');
		insert a;
		
		List<Account> accs = [SELECT Subscriber_Digital_Status__c FROM Account WHERE Id = :a.id];
		system.assertNotEquals(null, accs);
		system.assertNotEquals(0, accs.size());
		system.assertEquals('Active', accs[0].Subscriber_Digital_Status__c);
		
		Test.startTest();
		List<string> guids = new List<string>{'1'};
		
		ClearDigitalEntitlementsBatch batch = new ClearDigitalEntitlementsBatch(guids);
		database.executeBatch(batch);
		
		Test.stopTest();	
		
		accs = [SELECT Subscriber_Digital_Status__c FROM Account WHERE Id = :a.id];
		system.assertNotEquals(null, accs);
		system.assertNotEquals(0, accs.size());
		system.assertEquals('Inactive', accs[0].Subscriber_Digital_Status__c);
	}

	private static testMethod void ClearDigitalEntitlementsBatch_multiplerecords(){
		init();
		List<Account> newAccs = new List<Account>();
		List<string> guids = new List<string>();
		for(integer i = 1; i < 10; i++){
			Account a = new Account( name = 't' + i, Subscriber_Digital_Status__c = 'Active', guid__c = '' + i);
			guids.add('' + i);
			newAccs.add(a);
		}
		insert newAccs;
		
		List<Account> accs = [SELECT Subscriber_Digital_Status__c FROM Account WHERE Id = :newAccs];
		system.assertNotEquals(null, accs);
		system.assertNotEquals(0, accs.size());
		
		for(Account a : accs){
			system.assertEquals('Active', a.Subscriber_Digital_Status__c);
		}
		
		Test.startTest();
		
		ClearDigitalEntitlementsBatch batch = new ClearDigitalEntitlementsBatch(guids);
		database.executeBatch(batch);
		
		Test.stopTest();	
		
		accs = [SELECT Subscriber_Digital_Status__c FROM Account WHERE Id = :newAccs];
		system.assertNotEquals(null, accs);
		system.assertNotEquals(0, accs.size());
		
		for(Account a : accs){
			system.assertEquals('Inactive', a.Subscriber_Digital_Status__c);
		}
	}

}