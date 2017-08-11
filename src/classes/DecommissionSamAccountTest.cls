/* ------------------------------------------------------------------------------
   Name:        DecommissionSamAccountTest.cls
   Description: Test DecommissionSamAccountController functionality  

   Date         Version Author              Summary of Changes 
   -----------  ------- -----------------   -------------------------------------
   02/09/2015   1.1     Cristina Anghenie 	Search for account with wrong data in SAM
   31/10/2016   1.2     Michal Szewczyk     Changed email assertion in testDecomissionAccounts(),testDecomissionAccountsMppFailure()        
--------------------------------------------------------------------------------- */
@isTest
private class DecommissionSamAccountTest {
	
	/*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - test search account info and display sam related info for the specified email
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void searchForAccountTest() {
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[0].Guid__c = 'GUID__TEST';
        update tdu.lstIndividualSubscribers[0];
        DecommissionSamAccountController ctrl = new DecommissionSamAccountController();
        ctrl.email = 'test@test.com';
        Test.startTest();
        	SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(tdu.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
        	ctrl.searchSAMandSFDC();
        Test.stopTest();
        System.assertNotEquals(null,ctrl.result);
        System.assertEquals('GUID__TEST',ctrl.result.guid);
        System.assertEquals(1,ctrl.existingAccs.size());
        System.assertNotEquals(null,ctrl.samDetailsResponse);
        System.assertEquals('Mr',ctrl.samDetailsResponse.salutation);
        System.assertEquals('fnTestUser',ctrl.samDetailsResponse.firstName);
        System.assertEquals('snTestUser',ctrl.samDetailsResponse.lastName);
		System.assertEquals('testuser28102010_153247826@firstclarity.co.uk',ctrl.samDetailsResponse.emailAddress);
		System.assertNotEquals(null,ctrl.samDetailsResponse.guid);
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.1
    Function - test decommission account fuctionality
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin	1.1			17/12/2015	//added assertions for positive mpp update flow
    Michal Szewczyk 1.2         31/10/2016  //changed email assertion
    ****************************************************************************************/
    static testMethod void testDecomissionAccounts(){
    	TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[0].Guid__c = 'GUID__TEST';
        tdu.lstIndividualSubscribers[0].PersonEmail = 'test@test.com';
        update tdu.lstIndividualSubscribers[0];
        DecommissionSamAccountController ctrl = new DecommissionSamAccountController();
        ctrl.result = new SamUtil.SAMAccountResult();
        ctrl.samDetailsResponse = new SAMInterfaceHTTP.SamUserDetails();
        ctrl.email = 'test@test.com';
        ctrl.existingAccs = new List<Account>{tdu.lstIndividualSubscribers[0]};
        Test.startTest();
        	SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(tdu.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
        	ctrl.result.entitlements = new List<String>{'7DAY_SUBSCRIBER_INACTIVE'};
        	ctrl.result.guid = 'GUID__TEST';
        	ctrl.samDetailsResponse.guid = 'GUID__TEST';
        	ctrl.samDetailsResponse.salutation = 'Mr';
        	ctrl.samDetailsResponse.emailAddress = 'testuser28102010_153247826@firstclarity.co.uk';
        	ctrl.decommissionAccounts();
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),Label.Decommission_Success));
        Account acc = [SELECT Id, Guid__c,PersonEmail FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        System.assertEquals(null,acc.Guid__c);
        System.assertEquals(ctrl.samDetailsResponse.emailAddress + Constants.DECOM_EMAIL,acc.PersonEmail);
        System.assert(ctrl.lstMPPResults != null);
		System.assertEquals(1, ctrl.lstMPPResults.size());
		System.assert(!ctrl.bMPPFailure);
    }
    
    /*************************************************************************************** 
    Developer - Wiktor Czykin
    Date - 17/12/2015
    Version - 1.0
    Function - test decommission account fuctionality - mpp failure
    #############Change Log#############
    Modified by     Version     Change Date
    Michal Szewczyk 1.1         31/10/2016  //changed email assertion
    ****************************************************************************************/
    static testMethod void testDecomissionAccountsMppFailure(){
    	TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[0].Guid__c = 'GUID__TEST';
        tdu.lstIndividualSubscribers[0].PersonEmail = 'test@test.com';
        update tdu.lstIndividualSubscribers[0];
        DecommissionSamAccountController ctrl = new DecommissionSamAccountController();
        ctrl.result = new SamUtil.SAMAccountResult();
        ctrl.samDetailsResponse = new SAMInterfaceHTTP.SamUserDetails();
        ctrl.email = 'test@test.com';
        ctrl.existingAccs = new List<Account>{tdu.lstIndividualSubscribers[0]};
        Test.startTest();
        	SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(tdu.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
        	ctrl.result.entitlements = new List<String>{'7DAY_SUBSCRIBER_INACTIVE'};
        	ctrl.result.guid = 'GUID__TEST';
        	ctrl.samDetailsResponse.guid = 'GUID__TEST';
        	ctrl.samDetailsResponse.salutation = 'Mr';
        	ctrl.samDetailsResponse.emailAddress = 'testuser28102010_153247826@firstclarity.co.uk';
        	MPPInterfaceHTTP.bRunTest = true;
        	ctrl.decommissionAccounts();
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Decommission_page_Warning_on_MPP_issues));
        List<Account> lstAcc = [SELECT Id, Guid__c,PersonEmail FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        System.assert(!lstAcc.isEmpty());
        System.assertEquals(null, lstAcc[0].Guid__c);
        System.assertEquals(ctrl.samDetailsResponse.emailAddress + Constants.DECOM_EMAIL, lstAcc[0].PersonEmail);
    }
    
    /*************************************************************************************** 
    Developer - Cristina Anghenie
    Date - 03/09/2015
    Version - 1.0
    Function - test all negative scenarios
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void testNegativeScenarios(){
    	TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        DecommissionSamAccountController ctrl = new DecommissionSamAccountController();
        ctrl.email = '';
        Test.startTest();
        	ctrl.searchSAMandSFDC();
        	System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Decommission_NoEmail));
        	ctrl.email = 'test@test.com';
        	SAMWebserviceMocks.SAMHttpResponseGenerator mock = new SAMWebserviceMocks.SAMHttpResponseGenerator(tdu.lstSAMHTTPSettings);
        	Test.setMock(HttpCalloutMock.class, mock);
        	ctrl.searchSAMandSFDC();
        	System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Decommission_NoSFDCrecords));
        	try{
        		ctrl.displaySamInfo('','');
        	}catch(Exception ex){
        		System.assertNotEquals(null,ex);
        	}
        Test.stopTest();
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 04/12/2015
    Version - 1.0
    Function - test decommission account when sam account is locked
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void decommissionLockedSAMAccount() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();

        DecommissionSamAccountController ctrl = new DecommissionSamAccountController();
        ctrl.email = 'ACCOUNT_LOCKED@TEST';
        Test.startTest();
        	ctrl.searchSAMandSFDC();
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'SAM account is locked.'));
    }
}