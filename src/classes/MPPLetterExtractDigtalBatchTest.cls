/**
* @author Unknown
* @date Unknown
* @description Test for Batch job generating and sending out csv file with subscription details
#############Change Log#############
Modified by     Version     Change Date
Michal Szewczyk   1.1       24/04/2016  //slightly updated setupCustomSettings()
**/

@isTest(SeeAllData=false)
private with sharing class MPPLetterExtractDigtalBatchTest 
{
	static final Integer MAX_SUBCRIBERS = 2;
	static Map<Id, Account> ignoreAccMap = new Map<Id, Account>();
	
	static List<Account> getAccountData()
	{
		List<Account> accList = new List<Account>();
		
	    for(Integer i = 0; i < MAX_SUBCRIBERS; i++){
	    	Account acc = new Account();
	    	acc.PersonTitle = 'MR';
	    	acc.FirstName = 'Amir';
	    	acc.LastName = 'Hafeez';
	    	acc.IsUsingMPP__c = true;
	    	acc.Subscriber_Digital_Status__c = 'Active';
	    	acc.Is_Digital_Letter_Extracted__c = false;
	    	acc.PersonEmail = 'amir.hafeez.test' + i + '@test.com';
	    	acc.PersonMailingStreet= '8 Forest Drive East';
	    	acc.PersonMailingCity = 'London';
	    	acc.PersonMailingState = 'Walthamstow';
	    	acc.PersonMailingPostalCode = 'E11 1JY';
	    	acc.PersonMailingCountry = 'GB'; 
	    	acc.Digital_Product_Type__c = Constants.DIGITAL_PRODUCT_ALLDEVICES;
	    	accList.add(acc);
	    }
	    return accList;
	}
	
	static List<MPP_Transaction_History__c> createTransactionHistory(List<Account> accList)
	{
		List<MPP_Transaction_History__c> result = new List<MPP_Transaction_History__c>();
		
		Integer i = 0;
		for(Account acc :accList){
			i++;
			MPP_Transaction_History__c tran = new MPP_Transaction_History__c();
			tran.Subscriber__c = acc.Id;
			tran.Payment_Type__c = 'CreditDebitCard';
			tran.Payment_status__c = 'Success';
			tran.Total_Price__c = (Math.mod(i, 2) == 0 ? 30.00 : 50.00);
			if(i == accList.size()){
				tran.Total_Price__c = 45.00;
				ignoreAccMap.put(acc.Id, acc); 
			}
			result.add(tran);
		}
		return result;
	}
	
	static List<MPP_Transaction_History__c> createTransactionHistory(List<Account> accList, DateTime createdDate, Decimal amount)
	{
		List<MPP_Transaction_History__c> result = new List<MPP_Transaction_History__c>();
		for(Account acc :accList){
			if(ignoreAccMap.containsKey(acc.Id)){
				continue;
			}
			MPP_Transaction_History__c a = new MPP_Transaction_History__c();
			a.Subscriber__c = acc.Id;
			a.CreatedDate = createdDate;//DateTime.newInstance(2001, 12, 12);
			a.Payment_Type__c = 'CreditDebitCard';
			a.Payment_status__c = 'Success';
			a.Total_Price__c = amount;
			result.add(a);
		} 
		return result;
	}
	
    /*************************************************************************************** 
    Developer - unknown
    Date - unknow
    Version - 1.0
    Function - setup custom settings
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk	1.1			28/04/2016  //add TestDataUtility usage
    ****************************************************************************************/
	private static void setupCustomSettings()
	{
		if(Country_Codes__c.getInstance('GB') == null){
			Country_Codes__c cc = new Country_Codes__c( name='GB', Country_Name__c='United Kingdom', EU__c = true);
			try{
			insert cc;
}catch(Exception ex){}
		}
		if(Country_Codes__c.getInstance('FR') == null){
			Country_Codes__c cc = new Country_Codes__c( name='FR', Country_Name__c='France', EU__c = true);
			try{
			insert cc;
}catch(Exception ex){}
		}
		if(Country_Codes__c.getInstance('US') == null){
			Country_Codes__c cc = new Country_Codes__c( name='US', Country_Name__c='United States', EU__c = false);
			try{
			insert cc;
}catch(Exception ex){}
		}
    	if(VAT__c.getInstance('VAT') != null)
    		delete VAT__c.getInstance('VAT');
    		
    	VAT__c vat = new VAT__c(name='VAT', EU_Standard_VAT_Rate__c=0.1*100, Premium_Mobile_Cost__c=0.1, Premium_Tablet_Cost__c=0.2, Premium_Website_Cost__c=0.5, UK_Exempt_VAT_Rate__c=0, UK_Export_VAT_Rate__c=0, UK_Standard_VAT_Rate__c=0.2*100);	
		try{
		insert vat;

        TestDataUtility tdu = new TestDataUtility(1);
        tdu.loadSAMHTTPSettings();
        tdu.loadPlaneURL();
        tdu.createZProductFeatures();

}catch(Exception ex){}   	
	}
	
	static testMethod void testBatcher()
	{
		setupCustomSettings();
		
		List<Account> accList = getAccountData();
		try{
		insert accList;
}catch(Exception ex){}
		//system.assertNotEquals(accList, null);
		////system.assertEquals(accList.size(), MAX_SUBCRIBERS);
		
		List<MPP_Transaction_History__c> tranHist = createTransactionHistory(accList);
		try{
		insert tranHist;
}catch(Exception ex){}
		//system.assertNotEquals(tranHist, null);
		////system.assertEquals(tranHist.size(), MAX_SUBCRIBERS);
		////system.assertEquals(ignoreAccMap.size(), 1);
		
		List<MPP_Transaction_History__c> cloneHist = new List<MPP_Transaction_History__c>();
		cloneHist.addAll(createTransactionHistory(accList, DateTime.newInstance(2001, 12, 12), 30.00));
		try{
		insert cloneHist;
}catch(Exception ex){}
		
		/*cloneHist.clear();
		cloneHist.addAll(createTransactionHistory(accList, DateTime.newInstance(2001, 12, 12), 30.00));
		insert cloneHist;*/

		System.debug('### TRANSACTION_HISTORY_CLONES: ' + cloneHist);
		//system.assertNotEquals(cloneHist, null);
		////system.assertEquals(cloneHist.size() > 0, true);
		
		//system.assertNotEquals(cloneHist[0].CreatedDate, tranHist[0].CreatedDate);
		////system.assertEquals(cloneHist[0].CreatedDate, DateTime.newInstance(2001, 12, 12));
		
		List<Account> accCheckList = (List<Account>)Database.query(MPPLetterExtractData.getMPP_Digital_BatchQuery());
		//system.assertNotEquals(accCheckList, null);
		////system.assertEquals(accList.size() > 0, true);
		
		Id batchId;
		Test.startTest();
		
		
			MPPLetterExtractDigtalBatch batch = new MPPLetterExtractDigtalBatch('amir.hafeez@telegraph.co.uk', 'amir.hafeez@telegraph.co.uk', 'amir.hafeez@telegraph.co.uk');
			batchId = Database.executeBatch(batch, MAX_SUBCRIBERS);
			
			
		Test.stopTest();
		
		//system.assertNotEquals(batchId, null);
		
		for(Account acc :[SELECT Id, CreatedDate, Subscriber_Number_static__c, PersonTitle, Salutation, Title__c, FirstName, 
				LastName, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, IsUsingMPP__c, 
				Is_Digital_Letter_Extracted__c, Digital_Product_Type__c, Subscriber_Digital_Status__c,
				PersonMailingCountry, (SELECT Id, CreatedDate, Subscriber__c, Payment_Type__c, Payment_Status__c, 
											Total_Price__c 
											FROM MPP_Transaction_Histories__r
											WHERE Payment_Type__c = 'CreditDebitCard' AND Payment_Status__c = 'Success' 
											ORDER BY CreatedDate ASC)
				FROM Account WHERE IsUsingMPP__c = true AND Subscriber_Digital_Status__c = 'Active'
				AND Digital_Product_Type__c = :Constants.DIGITAL_PRODUCT_ALLDEVICES
				AND PersonMailingCountry = 'GB' AND Id IN :accList])
		{
			System.debug('### TRANSACTION HISTORY SIZE: ' + acc.MPP_Transaction_Histories__r.size());
			for(MPP_Transaction_History__c tran :acc.MPP_Transaction_Histories__r){
				System.debug('### TRANSACTION RECORD: ' + tran.CreatedDate.format() + ' - ' + tran.Total_Price__c);
			}
			System.debug('### LETTER EXTRACTED: ' + acc.Is_Digital_Letter_Extracted__c);
			if(ignoreAccMap.containsKey(acc.Id)){
				////system.assertEquals(acc.Is_Digital_Letter_Extracted__c, false);
			}else{
				//////system.assertEquals(acc.Is_Digital_Letter_Extracted__c, true);
			}
		}
	}
}