/**
* @author Cristina Anghenie
* @date 07/10/2015
* @description 
#############Change Log#############
Modified by     Version     Change Date
Pawel Chrzanowski   1.1     03/05/2017  removed unused Marketing Preferences
**/
@isTest
private class SubscriberEmailManagementControllerTest {
	
	/************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.0
    Function - method that checks if you can change no email address with an empty string
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void changeNoEmailAddressWithEmptyString() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[0].PersonEmail = null;
        update tdu.lstIndividualSubscribers[0];
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        System.assertEquals(true,strCtrl.displayPopUp);
        strCtrl.acc.PersonEmail = null;
        Test.startTest();
	        PageReference pagRef = strCtrl.saveNewEmail();
	        System.assertEquals(null,pagRef);
	        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please enter an email address.'));
	        
	        strCtrl.acc.PersonEmail = '';
	        pagRef = strCtrl.saveNewEmail();
	    Test.StopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please enter an email address.'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.1
    Function - method that checks if you can change the email address with the same email 
    		   address when the sam guid matches salesforce guid
    #############Change Log#############
    Modified by     	Version     Change Date
    Wiktor Czykin       1.1         17/02/2016  //changed hardcoded email string to var reference
    *************************************************************************************/
    static testMethod void changeEmailAddressWithTheSameEmailAddress() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        
        tdu.lstIndividualSubscribers[0].Guid__c = 'GUID__TEST';
        update tdu.lstIndividualSubscribers[0];
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = tdu.lstIndividualSubscribers[0].PersonEmail;
        Test.startTest();
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'No changes required. The email address entered is the existing email on the account.'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.1
    Function - test changing the email address when new email address is linked with a locked sam account
    #############Change Log#############
    Modified by     	Version     Change Date
    Wiktor Czykin       1.1         17/02/2016  //changed hardcoded email string to var reference
    *************************************************************************************/
    static testMethod void changeEmailAddressLockedSAMAccount() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'ACCOUNT_LOCKED@TEST';
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => tdu.lstIndividualSubscribers[0].PersonEmail
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'SAM account for the new email is locked.'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.0
    Function - test changing the email address when corresponding guid for the new email 
    		   already exists in SFDC
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void changeEmailAddressNewGuidAlreadyInSFDC() {
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[1].Guid__c = 'GUID__TEST';
        tdu.lstIndividualSubscribers[0].PersonEmail = null;
        update new Account[]{ tdu.lstIndividualSubscribers[0],tdu.lstIndividualSubscribers[1]};
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'personemail12@telegraph.co.uk';
        Test.startTest();
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'SAM account for the new email is already linked to a subscriber'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.0
    Function - test changing the email address when there is no data in SAM
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void changeEmailAddressWithAnExistingEmailAddress() {
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'personemail1@telegraph.co.uk';
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISFAILURE => 'isfailure',
                MPPWebserviceMocks.PARAM_FAILUREREASON => ''
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.0
    Function - test changing the email address when new email address is already linked with an MPP account
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void changeEmailAddressWithAnEmailAddressThatIsInMPP() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'personemail+123@telegraph.co.uk';
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => 'personemail+123@telegraph.co.uk'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'This email address is already being used in MPP'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.1
    Function - test changing the email address when new email address already exists in SAM and Salesforce
    #############Change Log#############
    Modified by     	Version     Change Date
    Wiktor Czykin       1.1         17/02/2016  //changed hardcoded email string to var reference
    *************************************************************************************/
    static testMethod void changeEmailAddressWithAnExistingEmailAddressThatIsInSfdcAndSAM() {
        TestDataUtility tdu = new TestDataUtility(2);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[1].Guid__c = 'GUID__TEST';
        update tdu.lstIndividualSubscribers[0];
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = tdu.lstIndividualSubscribers[1].PersonEmail;
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => tdu.lstIndividualSubscribers[1].PersonEmail
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'This email address is already being used in SAM and Salesforce'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.0
    Function - test changing the email address when new email is linked to a SAM account
    			that requires decommission
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void changeEmailAddressNeedsDecommission() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'personemail1@telegraph.co.uk';
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISFAILURE => 'isfailure',
                MPPWebserviceMocks.PARAM_FAILUREREASON => 'Account cannot be found.'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please decommission either the current SAM account or the target one before retrying this change'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 07/10/2015
    Version - 1.0
    Function - test changing the email address when new email is linked with 2 MPP accounts
    #############Change Log#############
    Modified by     	Version     Change Date
    *************************************************************************************/
    static testMethod void changeEmailAddressNoUniqueMPPAccount() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'personemail1@telegraph.co.uk';
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISFAILURE => 'isfailure',
                MPPWebserviceMocks.PARAM_FAILUREREASON => 'Account does not match all ClientUserIds supplied in Account Detail Parameters'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Account cannot be uniquely identified for update in MPP'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 08/10/2015
    Version - 1.1
    Function - test changing the email address succesfully
    #############Change Log#############
    Modified by     	Version     Change Date
    Wiktor Czykin       1.1         17/02/2016  //changed hardcoded email string to var reference
    *************************************************************************************/
    static testMethod void changeEmailAddressSuccessfully() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        tdu.lstIndividualSubscribers[0].Guid__c = 'different-guid';
        update tdu.lstIndividualSubscribers[0];
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = tdu.lstIndividualSubscribers[0].PersonEmail;
        Test.startTest();
        	MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => tdu.lstIndividualSubscribers[0].PersonEmail
            });
            Test.setMock(HttpCalloutMock.class, mock); 
        	PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertNotEquals(null, pagRef, ApexPages.getMessages());
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 11/11/2015
    Version - 1.0
    Function - method that checks if you can change existing email address that is already 
                in SAM and MPP with an empty string
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressWithEmptyString() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = null;
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_ISFAILURE => 'isfailure',
                MPPWebserviceMocks.PARAM_FAILUREREASON => 'Account cannot be found.'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
            PageReference pagRef = strCtrl.saveNewEmail();
        Test.stopTest();
        System.assertEquals(null,pagRef);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),'Please decommission SAM account if you need to delete email  - please note that customer would no longer be able to log in using this email address.'));
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 11/11/2015
    Version - 1.0
    Function - method that checks if you can change existing email address that doesn't exists in SAM 
                but exists in MPP with an empty string
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressNoSamWithEmptyString() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        String tsNumber = [SELECT Subscriber_Number_static__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id].Subscriber_Number_static__c;
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = null;
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => 'noemail+'+tsNumber+'@telegraph.co.uk'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
            strCtrl.existingSamAccountGuid = null;
            strCtrl.samResult = null;
            strCtrl.updateMPP = true;
            strCtrl.updateAccountEmail(tdu.lstIndividualSubscribers[0], Constants.PRODUCT_PREMIUM, null, 'oldEmail@test.com');
        Test.stopTest();
        Account acc = [SELECT PersonEmail, Guid__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        System.assertEquals(null,acc.Guid__c);
        System.assertEquals(null,acc.PersonEmail);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 11/11/2015
    Version - 1.0
    Function - method that create succesfully SAM Account
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressAndCreateSAM() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        Account acc = [SELECT Subscriber_Number__c, Salutation, FirstName, LastName, Guid__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        strCtrl.acc.PersonEmail = 'personemail1@telegraph.co.uk';
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => 'personemail1@telegraph.co.uk'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
            strCtrl.existingSamAccountGuid = null;
            strCtrl.samResult = null;
            strCtrl.updateMPP = true;
            strCtrl.updateAccountEmail(acc, Constants.PRODUCT_PREMIUM, 'personemail1@telegraph.co.uk', 'personemail0@telegraph.co.uk');
        Test.stopTest();
        acc = [SELECT PersonEmail, Guid__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        System.assertEquals('personemail1@telegraph.co.uk',acc.PersonEmail);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 11/11/2015
    Version - 1.0
    Function - method that update succesfully SAM Account for print with subs
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie	1.1			02/12/2015	//update method to test changing email when the account has subs
    Pawel Chrzanowski   1.2         03/05/2017  //removed unused Marketing Preferences
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressAndUpdateSAMForPrintWithSubs() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createSubscriptions();
        Account acc = [SELECT Id, Salutation, PersonEmail, FirstName, LastName, PersonMailingStreet, PersonMailingCity, recordTypeId, 
							 PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Number__c, Guid__c, RecordType.Name,  
							 TMG_Promo_Email__c, TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c,
							 (SELECT Id FROM MPP_Transaction_Histories__r), Number_of_Subscriptions__c  
					   FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => 'personemail1@telegraph.co.uk'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
            strCtrl.existingSamAccountGuid = null;
            strCtrl.samResult = new SAMUtil.SAMAccountResult();
            strCtrl.samResult.guid = 'GUID__TEST';
            strCtrl.samResult.entitlements = new List<String>{'7DAY_SUBSCRIBER_INACTIVE'};
            strCtrl.samResult.entitlementStatus = 'INACTIVE';
            strCtrl.updateMPP = true;
            strCtrl.updateAccountEmail(acc, Constants.PRODUCT_PREMIUM, 'personemail1@telegraph.co.uk', acc.PersonEmail);
        Test.stopTest();
        acc = [SELECT PersonEmail, Guid__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        System.assertEquals('GUID__TEST',acc.Guid__c);
        System.assertEquals('personemail1@telegraph.co.uk',[SELECT PersonEmail FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id].PersonEmail);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 02/12/2015
    Version - 1.1
    Function - method that doesnt update guid because SAM Account is not upserted for print when no subs
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         17/02/2016  //changed hardcoded email string to var reference
    Pawel Chrzanowski   1.2         03/05/2017  //removed unused Marketing Preferences
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressAndUpdateSAMForPrintWithoutSubs() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createIndividualSubscribers();
        Account acc = [SELECT Id, Salutation, PersonEmail, FirstName, LastName, PersonMailingStreet, PersonMailingCity, recordTypeId, 
							 PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Number__c, Guid__c, RecordType.Name,  
							 TMG_Promo_Email__c, TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c,
							 (SELECT Id FROM MPP_Transaction_Histories__r), Number_of_Subscriptions__c  
					   FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstIndividualSubscribers[0]));
        System.assertEquals(tdu.lstIndividualSubscribers[0].PersonEmail, acc.PersonEmail);
         
        Test.startTest();
            strCtrl.updateAccountEmail(acc, Constants.PRODUCT_PREMIUM, 'personemail1@telegraph.co.uk', acc.PersonEmail);
             System.assert(ApexPages.getMessages().isEmpty(), ApexPages.getMessages());
        Test.stopTest();
        acc = [SELECT PersonEmail, Guid__c FROM Account WHERE Id =: tdu.lstIndividualSubscribers[0].Id];
        System.assertEquals(null,acc.Guid__c);
        System.assertEquals('personemail1@telegraph.co.uk',[SELECT PersonEmail FROM Account WHERE Id =: acc.Id].PersonEmail);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 02/12/2015
    Version - 1.1
    Function - method that update guid on account for digital wiht mpp transaction history
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         17/02/2016  //changed hardcoded email string to var reference
    Pawel Chrzanowski   1.2         03/05/2017  //removed unused Marketing Preferences
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressAndUpdateSAMForDigitalWithMPP() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createDigitalMPPTransactionHistory('CC');
        Account acc = [SELECT Id, Salutation, PersonEmail, FirstName, LastName, PersonMailingStreet, PersonMailingCity, recordTypeId, 
							 PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Number__c, Guid__c, RecordType.Name,  
							 TMG_Promo_Email__c, TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c,
							 (SELECT Id FROM MPP_Transaction_Histories__r), Number_of_Subscriptions__c  
					   FROM Account WHERE Id =: tdu.lstDigitalSubscribers[0].Id];
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstDigitalSubscribers[0]));
        System.assertEquals(tdu.lstDigitalSubscribers[0].PersonEmail, acc.PersonEmail);
        System.assertEquals(1,acc.MPP_Transaction_Histories__r.size());
        Test.startTest();
            MPPWebserviceMocks.MPPHttpResponseGenerator mock = new MPPWebserviceMocks.MPPHttpResponseGenerator(tdu.lstPlaneURL[0].baseURL__c, new Map<String,String>{
                MPPWebserviceMocks.PARAM_EMAIL => 'personemail1@telegraph.co.uk'
            });
            Test.setMock(HttpCalloutMock.class, mock); 
            strCtrl.existingSamAccountGuid = null;
            strCtrl.samResult = new SAMUtil.SAMAccountResult();
            strCtrl.samResult.guid = 'GUID__TEST';
            strCtrl.samResult.entitlements = new List<String>{'7DAY_SUBSCRIBER_INACTIVE'};
            strCtrl.samResult.entitlementStatus = 'INACTIVE';
            strCtrl.updateMPP = true;
            strCtrl.updateAccountEmail(acc, Constants.PRODUCT_PREMIUM, 'personemail1@telegraph.co.uk', acc.PersonEmail);
        Test.stopTest();
        acc = [SELECT PersonEmail, Guid__c FROM Account WHERE Id =: tdu.lstDigitalSubscribers[0].Id];
        System.assertEquals('GUID__TEST',acc.Guid__c);
        System.assertEquals('personemail1@telegraph.co.uk',[SELECT PersonEmail FROM Account WHERE Id =: acc.Id].PersonEmail);
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 02/12/2015
    Version - 1.0
    Function - method that doesnt update guid on account for digital without mpp transaction history
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         03/05/2017  //removed unused Marketing Preferences
    *************************************************************************************/
    static testMethod void changeExistingEmailAddressAndUpdateSAMForDigitalWithoutMPP() {
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createDigitalSubscribers();
        Account acc = [SELECT Id, Salutation, PersonEmail, FirstName, LastName, PersonMailingStreet, PersonMailingCity, recordTypeId, 
							 PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Number__c, Guid__c, RecordType.Name,  
							 TMG_Promo_Email__c, TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c,
							 (SELECT Id FROM MPP_Transaction_Histories__r), Number_of_Subscriptions__c  
					   FROM Account WHERE Id =: tdu.lstDigitalSubscribers[0].Id];
        SubscriberEmailManagementController strCtrl = new SubscriberEmailManagementController(new ApexPages.StandardController(tdu.lstDigitalSubscribers[0]));
        System.assertEquals(tdu.lstDigitalSubscribers[0].PersonEmail, acc.PersonEmail);
        System.assertEquals(0,acc.MPP_Transaction_Histories__r.size());
        Test.startTest();
            strCtrl.updateAccountEmail(acc, Constants.PRODUCT_PREMIUM, 'personemail1@telegraph.co.uk',  acc.PersonEmail);
            System.assert(ApexPages.getMessages().isEmpty(), ApexPages.getMessages());
        Test.stopTest();
        acc = [SELECT PersonEmail, Guid__c FROM Account WHERE Id =: tdu.lstDigitalSubscribers[0].Id];
        System.assertEquals(null,acc.Guid__c);
        System.assertEquals('personemail1@telegraph.co.uk',[SELECT PersonEmail FROM Account WHERE Id =: acc.Id].PersonEmail);
    }
}