@isTest
private class SubscriptionIncentiveTriggerHandlerTest {

    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 18/09/2015
    Version - 1.0
    Function - test that changing status to pending will update incentive description field on sub
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private static testMethod void testUpdateIncentiveDescriptionOnSubscription(){
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.loadPlaneURL();
        tdu.createSubscriptions();
		List<Incentive__c> incentives = new List<Incentive__c>();
        for(Integer i=1;i<=5;i++){
        	Incentive__c inc = TestDataUtility.newIncentive();
        	inc.Incentive_Description__c = 'Incentive no ' + i;
        	incentives.add(inc);
        }
        insert incentives;
        List<SubscriptionIncentiveAssociation__c> sias = new List<SubscriptionIncentiveAssociation__c>();
        Test.startTest();
	        for(Integer i=1;i<=incentives.size();i++){
	        	SubscriptionIncentiveAssociation__c sia = TestDataUtility.newSubscriptionIncentiveAssociation(incentives[incentives.size()-1].Id,tdu.lstIndividualSubscribers[0].Id, tdu.lstSubscriptions[0].Id);
	        	sia.CreatedDate = System.Today().addDays(-i);
	        	sias.add(sia);
	        }
	        insert sias;
        Test.stopTest();
        
    	Subscription__c sub = [SELECT Incentive_Description__c, Subscription_Status__c FROM Subscription__c WHERE Id =: tdu.lstSubscriptions[0].Id];
        System.assertEquals('Incentive no 5',sub.Incentive_Description__c);
        
        sub = [SELECT Incentive_Description__c, Subscription_Status__c FROM Subscription__c WHERE Id =: tdu.lstSubscriptions[1].Id];
        System.assertEquals('Active',sub.Subscription_Status__c);
        System.assertEquals(null,sub.Incentive_Description__c);
    }
}