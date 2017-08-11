@isTest
private class DefaultNewlettersQueueableTest {
	
	@TestSetup private static void setupData(){
		//Creating only 5 accounts as we hit AsyncException.
        TestDataUtility tdu = new TestDataUtility(5);
        tdu.CreateCoreApiEndPointSettings();
        tdu.createMyNewslettersEndPointSettings();
        tdu.loadCountryCodes();
        tdu.createIndividualSubscribers();
        tdu.createNewslettersEndPointSettings();
    }

	@isTest static void testAddNewsletterQueue() {
        
		List<Account> accounts = [SELECT Id, Name, Subscriber_Number__c, PersonMailingPostalCode, Guid__c FROM Account];

		Test.startTest();

		DefaultNewlettersQueueable defaultNewsletters = new DefaultNewlettersQueueable(accounts, null, null);
		System.enqueueJob(defaultNewsletters);
        
        Test.stopTest();
	}
	
	@isTest static void testAddNewsletterAccount() {
        
		List<Account> accounts = [SELECT Id, Name, Subscriber_Number__c, PersonMailingPostalCode, Guid__c FROM Account];

		Test.startTest();

		DefaultNewsletterUtility.addDefaultNewsletter(accounts[0].Id);
        
        Test.stopTest();
	}
}