global with sharing class TSSearchController {
/* -----------------------------------------------------------------------------------------------------------------------
   Name:        TSSearchController.cls
   Description:   

   Date        	Version	Author						Summary of Changes 
   -----------	-------	-----------------	------------------------------------------------------------------------------
   Unknown			1.0			Unknown				Initial Release
   16/10/2013		1.1			Chris Yorkston		Moved test classes to TSSearchControllerTest.cls Increased API version to 28.0
   08/06/2015		1.2			Cristina Popescu	Update the controller to fix the search issue on subscriber and subscription displayed on the side bar produced by the summer15 release
------------------------------------------------------------------------------------------------------------------------ */	
	@TestVisible private static final String TSPREFIX = 'TS';
	@TestVisible private static final String SUBPREFIX = 'SUB-';

    /*************************************************************************************** 
    Developer - Cristina Popescu
    Date - 08/06/2014
    Version - 1.0
    Function - Method that search for a specified Subscriber and redirects to the page layout of the search result
    ****************************************************************************************/
	@RemoteAction
	global Static String doSubscriberSearch(String tsNumber) {
		String url;
		List<Account> subscriberResults = new List<Account>();
		//if the search button was pressed without anything beign added in the search field display error message
		if (String.IsBlank(tsNumber)) {
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.FATAL, Label.Empty_Subscriber_Id));
			throw new TelegraphApplicationException(Label.Empty_Subscriber_Id);
		}
		tsNumber = tsNumber.trim().toUpperCase();
		if(!tsNumber.contains(TSPREFIX)){
			tsNumber = TSPREFIX+tsNumber;
		}

		//check if there is a record with the specified Subscriber Number
		subscriberResults = [SELECT Id ,Name ,Subscriber_Number_Static__c 
							 FROM Account 
							 WHERE Subscriber_Number_Static__c =: tsNumber];
		//if no record returned display message
		
		if (subscriberResults.size() == 0 || subscriberResults.size() > 1) {
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.FATAL, Label.No_Subscriber_Id_Found));
			throw new TelegraphApplicationException(Label.No_Subscriber_Id_Found);
		//if record is returned redirect to the specified record page layout
		}else if(subscriberResults.size() == 1) {
			url = '/'+subscriberResults[0].Id;
		}
		return url;		
	}
	
	/*************************************************************************************** 
    Developer - Cristina Popescu
    Date - 08/06/2014
    Version - 1.0
    Function - Method that search for a specified Subscription and redirects to the page layout of the search result
    ****************************************************************************************/
	@RemoteAction
	global Static String doSubscriptionSearch(String subNumber) {    
		List<Subscription__c> subscriptionResults = new List<Subscription__c>();
		String url;
		//if the search button was pressed without anything beign added in the search field display error message
		if (String.IsBlank(subNumber)) {
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.FATAL, Label.Empty_Subscription_Id));
			throw new TelegraphApplicationException( Label.Empty_Subscription_Id);
		}
		//check if there is a record with the specified Subscription Name
		subNumber = subNumber.trim().toUpperCase();
		if(!subNumber.contains(SUBPREFIX)){
			subNumber = SUBPREFIX+subNumber;
		}

		subscriptionResults = [SELECT Id ,Name  
							   FROM Subscription__c 
							   WHERE Name =: subNumber];	
		//if no record returned display message
		if (subscriptionResults.size() == 0 || subscriptionResults.size() > 1) {
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.FATAL, Label.No_Subscription_Id_Found));
			throw new TelegraphApplicationException(Label.No_Subscription_Id_Found);
		//if record is returned redirect to the specified record page layout
		}else if (subscriptionResults.size() == 1) {
			url = '/'+subscriptionResults[0].Id;
		}
		return url;
	}
		
}