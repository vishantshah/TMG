/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         02/03/2015  //modified setupSub()
Cristina Popescu1.2			08/06/2015	//fix test class to run acording to the new changes: coverage 100%
Wiktor Czykin	1.3			14/10/2015	//modified testSubscriptionSearch()
**/
@isTest(SeeAllData=false)
private class TSSearchControllerTest {
	
	static testmethod void testSubscriberSearch() {
		TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
        
		Account acc = TestDataUtility.newPersonAccount(1,Constants.DIGITAL_RECORDTYPE);
		insert acc;
        
		test.setCurrentPage(Page.TSSearch);
		//test search when nothing is added to the search filter
		try{
			TSSearchController.doSubscriberSearch(null);
			System.assert(false, 'exception not thrown where expected');
		}catch (Exception e){
			Boolean expectedExceptionThrown =  e.getMessage().contains(Label.Empty_Subscriber_Id) ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}

		//test search when subscriber number is wrong
		try{
			TSSearchController.doSubscriberSearch('TS1234');
			System.assert(false, 'exception not thrown where expected');
		}catch (Exception e){
			Boolean expectedExceptionThrown =  e.getMessage().contains(Label.No_Subscriber_Id_Found) ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}
        
        //test search when the search filter return a record
        acc = [SELECT Id,Subscriber_Number__c FROM Account WHERE Id=: acc.Id];
		System.assertEquals('/'+acc.Id,TSSearchController.doSubscriberSearch(acc.Subscriber_Number__c));
		
		//test search when the search filter has lowercase prefix
		System.assertEquals('/'+acc.Id,TSSearchController.doSubscriberSearch(acc.Subscriber_Number__c.toLowerCase()));
	}
    
    /*************************************************************************************** 
    Developer - Cristina Popescu	
    Date - 08/06/2015
    Version - 1.1
    Function - Test scenarios for searches
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			14/10/2015	//modified the way sub and account are created
    ****************************************************************************************/
    static testmethod void testSubscriptionSearch() {    
      	TestDataUtility tdu = new TestDataUtility();
        tdu.loadSAMHTTPSettings();
        tdu.loadGeneral();
        tdu.loadPlaneURL();
    	tdu.createSubscriptions();

    	test.setCurrentPage(Page.TSSearch);
      	//test search when nothing is added to the search filter
		try{
			TSSearchController.doSubscriptionSearch(null);
			System.assert(false, 'exception not thrown where expected');
		}catch (Exception e){
			Boolean expectedExceptionThrown =  e.getMessage().contains(Label.Empty_Subscription_Id) ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}
		//test search when subscription name is wrong
		try{
			TSSearchController.doSubscriptionSearch('SUB-1234');
			System.assert(false, 'exception not thrown where expected');
		}catch (Exception e){
			Boolean expectedExceptionThrown =  e.getMessage().contains(Label.No_Subscription_Id_Found) ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}
		
		//test search when the search filter return a record
        Subscription__c subscription = [SELECT Id, Name FROM Subscription__c WHERE Id =: tdu.lstSubscriptions[0].Id];
		System.assertEquals('/'+subscription.Id, TSSearchController.doSubscriptionSearch(subscription.Name));
		
		//test search when the search filter has lowercase prefix
		System.assertEquals('/'+subscription.Id, TSSearchController.doSubscriptionSearch(subscription.Name.toLowerCase()));
	}

	/*************************************************************************************** 
    Developer - Wiktor Czykin	
    Date - 10/06/2015
    Version - 1.0
    Function - Test positive scenarios for searches that are done with criteria without respective prefixes.
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	private static testmethod void testSearchWithoutPrefixes() {    
      	TestDataUtility td = new TestDataUtility(1);
      	td.createSubscriptions();
        td.loadSAMHTTPSettings();
        td.loadGeneral();
        td.loadPlaneURL();
        
		Test.startTest();
			List<Subscription__c> lstSubscription = [select Name from Subscription__c where Id in :td.lstSubscriptions];
			System.assert(lstSubscription.size() == 1);
			String sToSearchSub = lstSubscription[0].Name.replace(TSSearchController.SUBPREFIX, '');
			String subscriptionUrl = TSSearchController.doSubscriptionSearch(sToSearchSub);
			System.assert(subscriptionUrl.contains(td.lstSubscriptions[0].Id));
		
			List<Account> lstAccount = [select Subscriber_Number_Static__c from Account where Id in :td.lstIndividualSubscribers];
			System.assert(lstAccount.size() == 1);
			String sToSearchAccount = lstAccount[0].Subscriber_Number_Static__c.replace(TSSearchController.TSPREFIX, '');
			String subscriberUrl = TSSearchController.doSubscriberSearch(sToSearchAccount);
			System.assert(subscriberUrl.contains(td.lstIndividualSubscribers[0].Id));

		Test.stopTest();
		
	}
}