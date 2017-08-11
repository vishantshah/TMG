/**
* @author Unknown
* @date Unknown
* @description Test class for SearchRetailerController
#############Change Log#############
Modified by     Version     Change Date
**/
@isTest
private class SearchRetailerControllerTest {
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.0
    Function - test getDeliveryOptions() method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			12/01/2016 //re-enabled assertions
    ****************************************************************************************/
	private static testMethod void testGetDeliveryOptions(){
		SearchRetailerController searchRetailer = new SearchRetailerController();
		System.assertEquals(null, searchRetailer.displaySelectColumn);
		System.assertEquals(null, searchRetailer.defaultDelivery);
		System.assertEquals(null, searchRetailer.displaySelectDeliveryType);

		List<SelectOption> delivery = searchRetailer.getDeliveryOptions() ;
		System.assertEquals(1,delivery.size());
		System.assertEquals(Constants.DELIVERYTYPE_OTC,delivery[0].getLabel());
		searchRetailer.agencyIdentifier = Constants.AGENT_TMG;
		delivery = searchRetailer.getDeliveryOptions();
		System.assertEquals(2,delivery.size());
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test getDeliveryOptions() method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			12/01/2016 //re-enabled assertions, made to use TestDataUtility
    ****************************************************************************************/
	private static testMethod void testSaveRetailer(){	 
	    TestDataUtility td = new TestDataUtility(1);
	    td.createRetailers();
	    for(Account acc : td.lstRetailers){
	    	acc.BillingPostalCode = 'SW23 4RF';
	    }
		update td.lstRetailers;	    
	    
	    Test.startTest();
			SearchRetailerController searchRetailer = new SearchRetailerController();
			searchRetailer.selectedRetailer = td.lstRetailers[0].Id;
			searchRetailer.saveRetailer();
		Test.stopTest();
		System.assertEquals(td.lstRetailers[0].Name, searchRetailer.selectedRetailerName);	
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test setDelivery() method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			13/01/2016 //added constants
    ****************************************************************************************/
	private static testMethod void testSetDelivery(){	
		Test.startTest();
			SearchRetailerController searchRetailer = new SearchRetailerController();
			searchRetailer.SelectedDelivery = Constants.DELIVERYTYPE_OTC;
			searchRetailer.setDelivery();
			System.assertEquals(false, searchRetailer.displayRetailers);
			System.assertEquals(false, searchRetailer.displayRetailerResults);
		
			searchRetailer.SelectedDelivery = Constants.DELIVERYTYPE_HND;
			searchRetailer.setDelivery();
			System.assertEquals(true, searchRetailer.displayRetailers);
			System.assertEquals(true, searchRetailer.displayRetailerResults);
		Test.stopTest();
	}
	
	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test retailers retrieval - retailers with active subs
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			13/01/2016 //changed to use TestDataUtility
    ****************************************************************************************/
	private static testMethod void testRetrieveRetailersWithActiveSubs(){
		TestDataUtility tdu = new TestDataUtility(5);
		tdu.createSubscriptions();
	  	
	  	for(Account retailer : tdu.lstRetailers){
			retailer.BillingPostalCode = 'SW23 4RF';
			retailer.Retailer_Active_Sub_Count__c =  tdu.iCounter;	  		
	  	}
	  	update tdu.lstRetailers;

		Test.startTest();
		    SearchRetailerController searchRetailer = new SearchRetailerController();
		    searchRetailer.postcodeRetailSearch ='SW23 4RF'; 
			searchRetailer.retrieveAllRetailers() ;
			System.assertEquals(tdu.iCounter, searchRetailer.allActiveRetailers.size());
			System.assertEquals(true, searchRetailer.displayRetailers);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function -  test retailers retrieval - all retailers search - no active sub condition
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			13/01/2016 //changed to use TestDataUtility
    ****************************************************************************************/
	private static testMethod void testRetrieveRetailersWithoutActiveSubs(){
		TestDataUtility tdu = new TestDataUtility(5);
		tdu.createRetailers();

	  	for(Account retailer : tdu.lstRetailers){
			retailer.BillingPostalCode = 'SW23 4RF';	  		
	  	}
	  	update tdu.lstRetailers;

		Test.startTest();
			SearchRetailerController searchRetailer = new SearchRetailerController();
		    searchRetailer.postcodeRetailSearch ='SW23 4RF'; 
			searchRetailer.retrieveFullListRetailers();
			System.assertEquals(tdu.iCounter, searchRetailer.allActiveRetailers.size());
			System.assertEquals(true, searchRetailer.displayRetailers);
		Test.stopTest();
	}

	/*************************************************************************************** 
    Developer - Unknown
    Date - Unknown
    Version - 1.1
    Function - test retailers with active sub search - retailers without active subs - retailres
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			13/01/2016 //changed to use TestDataUtility
    ****************************************************************************************/
	private static testMethod void testRetrieveRetailersWithActiveSubsNegative(){
		TestDataUtility tdu = new TestDataUtility(5);
		tdu.createRetailers();

	  	for(Account retailer : tdu.lstRetailers){
			retailer.BillingPostalCode = 'SW23 4RF';	  		
	  	}
	  	update tdu.lstRetailers;

		Test.startTest();
			SearchRetailerController searchRetailer = new SearchRetailerController();
		    searchRetailer.postcodeRetailSearch ='SW23 4RF'; 
			searchRetailer.retrieveAllRetailers();
			System.assertEquals(0, searchRetailer.allActiveRetailers.size());
			System.assertEquals(false, searchRetailer.displayRetailers);
		Test.stopTest();
	}
}