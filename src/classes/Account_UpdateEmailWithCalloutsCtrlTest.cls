/**
* Author:       Michal Kwika
* Date:         05/08/2015
* Description:  API calls to check email in SAM
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika		01/09/2015
* Wiktor Czykin		20/03/2017 //modified so that it works after unique email is enabled for accounts
**/
@isTest
public class Account_UpdateEmailWithCalloutsCtrlTest {
	static testmethod void testValidSearch() {

		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200,0);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		// Call method to test.
		// This causes a fake response to be sent from the class that implements HttpCalloutMock.
		TestDataUtility testDataUtilityObj = new TestDataUtility(3);
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.CreateCoreApiSamUserSearchByEmailSetting();
		//Create a registrant
        testDataUtilityObj.createRegistrants();
        Test.setCurrentPage(Page.Account_UpdateEmailWithCallouts);

		Test.startTest();
		ApexPages.StandardController stdctrl = new ApexPages.StandardController(testDataUtilityObj.lstRegistrants[0]);
		Account_UpdateEmailWithCalloutsCtrl updateEmailCtrl = new Account_UpdateEmailWithCalloutsCtrl(stdctrl);
		//try to enter blank value and save
		updateEmailCtrl.acc.PersonEmail= '';
		updateEmailCtrl.save();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Email));
		
		//set new user Email
		updateEmailCtrl.acc.PersonEmail= testDataUtilityObj.lstRegistrants[1].PersonEmail;
		//try to save (there is account with this email adddress in SF)
		updateEmailCtrl.save();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Email_Invalid_Other_Account_Exist));

		//set new user Email (there is no email in SAM)
		updateEmailCtrl.acc.PersonEmail= 'test@test.com';
		//try to save 
		updateEmailCtrl.save();

		//set fake value and try to update
		updateEmailCtrl.emailSAMCounter = 0;
		Account_UpdateEmailWithCalloutsCtrl.updateAccountEmail(testDataUtilityObj.lstRegistrants[0].Id, 'test@test.com');

		Test.stopTest();

	}

	//when email exists in SAM
	static testmethod void testValidSearchEmailExistsSAM() {
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200,2);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		// Call method to test.
		// This causes a fake response to be sent
		// from the class that implements HttpCalloutMock.
		TestDataUtility testDataUtilityObj = new TestDataUtility(3);
		//Create the custom setting
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.CreateCoreApiSamUserSearchByEmailSetting();
		//Create a registrant
        testDataUtilityObj.createRegistrants();
        Test.setCurrentPage(Page.Account_UpdateEmailWithCallouts);

		Test.startTest();
		ApexPages.StandardController stdctrl = new ApexPages.StandardController(testDataUtilityObj.lstRegistrants[0]);
		Account_UpdateEmailWithCalloutsCtrl updateEmailCtrl = new Account_UpdateEmailWithCalloutsCtrl(stdctrl);

		//set new user Email (there is an email in SAM)
		updateEmailCtrl.acc.PersonEmail= 'test@test.com';
		//try to save 
		updateEmailCtrl.save();
		Test.stopTest();
	}

	//invalid format of email
	static testmethod void testInvalidFormatOfEmail() {

		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200,0);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		// Call method to test.
		// This causes a fake response to be sent
		// from the class that implements HttpCalloutMock.
		TestDataUtility testDataUtilityObj = new TestDataUtility(3);
		//Create the custom setting
		testDataUtilityObj.CreateCoreApiEventEndPointSetting();
        testDataUtilityObj.CreateCoreApiSamUserSearchByEmailSetting();
		//Create a registrant
        testDataUtilityObj.createRegistrants();
        Test.setCurrentPage(Page.Account_UpdateEmailWithCallouts);

		Test.startTest();
		ApexPages.StandardController stdctrl = new ApexPages.StandardController(testDataUtilityObj.lstRegistrants[0]);
		Account_UpdateEmailWithCalloutsCtrl updateEmailCtrl = new Account_UpdateEmailWithCalloutsCtrl(stdctrl);
		//try to enter blank value and save
		updateEmailCtrl.acc.PersonEmail= '';
		updateEmailCtrl.save();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Error_Empty_Email));
		
		//set new user Email
		updateEmailCtrl.acc.PersonEmail= 'testEmai0////%@test.com';
		//try to save (there is account with this email adddress in SF)
		updateEmailCtrl.save();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Email_Invalid_Format_Error));

		//set new user Email (there is no email in SAM)
		updateEmailCtrl.acc.PersonEmail= 'test@test.com';
		//try to save 
		updateEmailCtrl.save();

		//set fake value and try to update
		updateEmailCtrl.emailSAMCounter = 0;
		Account_UpdateEmailWithCalloutsCtrl.updateAccountEmail(testDataUtilityObj.lstRegistrants[0].Id, 'test@test.com');
		Test.stopTest();
	}
}