@isTest(SeeAllData=false)
private class TestAccountAddressManagementExtension {
	static testMethod void testAccountAddressManagementExtension() {
		
       account a = new account(name='Test Account');
        insert a;
        
		Country_Codes__c cc = new Country_Codes__c(name='Test', Country_Name__c = 'Test');
		insert cc;
		
        State_Codes__c stateCode=new State_Codes__c (name='AA',Country_Code__c ='US',Display_Order__c =999,State_Name__c ='Armed Forces America');
		insert stateCode;
        
        ApexPages.Standardcontroller c = new ApexPages.StandardController(a);

		Apexpages.currentPage().getHeaders().put('USER-AGENT', 'MSIE');
		
		Test.startTest();
		AccountAddressManagementExtension controller = new AccountAddressManagementExtension(c);
		
		controller.getCountries();
		controller.switchToEdit();
		controller.switchToEditAgain();
		controller.getCountryName();
		controller.getStateName();
		controller.SaveAddress();
        controller.getStates();
        boolean ValueCheck=controller.isPostalCodeRequired;
        ValueCheck=controller.isStateRequired;
        ValueCheck=controller.isRegistrantAccount;
        string strValue=controller.RegistrantRecordTypeId;
        controller.RefreshUI();
        PageReference pr = controller.RenderAddressType();
        Boolean ukSearch = controller.isUKSearch;
		Test.stopTest();

		
	}
    
    private static string getRegistrantRecordTypeId(){
        return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName()); 
    }
}