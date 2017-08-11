/**
* @author Unknown
* @date Unknown
* @description 
#############Change Log#############
Modified by     Version     Change Date
Wiktor Czykin   1.1         02/03/2015  //modified setupSub()
Wiktor Czykin	1.2			08/01/2016	//modified to fully utilize TestDataUtility
Michal Szewczyk 1.3         20/04/2016  //modified testGetSubscribers()
**/
@isTest(SeeAllData=false)
private class SubscriberPortalRestTest {

    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - testSubChangeNotificationXml
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         22/09/2015  //remove SubscriberPortal__c custom settings
    ****************************************************************************************/
    private static testMethod void testSubChangeNotificationXml(){
        TestDataUtility tdu = new TestDataUtility(1);
      	tdu.createSubscriptions();
      	List<Account> lstAccount = [select Id, subscriber_number_static__c from Account where Id = :tdu.lstIndividualSubscribers[0].Id];
      	System.assert(lstAccount.size() == 1);
      	Test.startTest();
        	SubscriberPortal.Subscriber spSub = SubscriberPortal.getSubscriber(lstAccount[0].subscriber_number_static__c, tdu.lstIndividualSubscribers[0].PersonMailingPostalCode);
        Test.stopTest();
    } 
    
    /*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - testGetSubscribers
    #############Change Log#############
    Modified by     	Version     Change Date
    Cristina Anghenie   1.1         22/09/2015  //remove SubscriberPortal__c custom settings
    Michal Szewczyk     1.2         20/04/2016  //added setEntitlemetMapping()
    ****************************************************************************************/
    private static testMethod void testGetSubscribers(){
    	TestDataUtility tdu = new TestDataUtility(2);
		tdu.checkSubscriptionDependencies();
        tdu.setEntitlemetMapping();

        tdu.lstIndividualSubscribers[0].Guid__c = 'guid1';
        tdu.lstIndividualSubscribers[0].Guid__c = 'guid2';
        update tdu.lstIndividualSubscribers;
        
        Subscription__c sub1ForAcc1 = TestDataUtility.newSubscripiton(1, tdu.lstIndividualSubscribers[0].Id, tdu.lstRetailers[0].Id, null);
        insert sub1ForAcc1;
        Test.startTest();
        	List<SubscriberPortal.Subscriber> subs = SubscriberPortalRest.getSubscribers(new Set<Id>{tdu.lstIndividualSubscribers[0].Id, tdu.lstIndividualSubscribers[1].Id});
        Test.stopTest();
        
        System.assertEquals(1, subs.size());
        System.assert(subs[0].entitlements.size() == 1);
    }
    
}