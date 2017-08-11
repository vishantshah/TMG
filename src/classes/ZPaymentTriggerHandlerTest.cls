/* Author:       Sally ElGhoul (Accenture)
* Date:         12/10/2015
* Description:  this class is a ZPaymentTriggerHandler test class
*
* ******************* Change Log *******************
* Modified by       Change Date     
**/
@isTest(SeeAllData=true)
public class ZPaymentTriggerHandlerTest {
	
	static testMethod void testCreateZuoraBillingAccount() {
		// Set mock callout class
	    MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
	    Test.setMock(HttpCalloutMock.class, ResponseGenerator);
	
	    // Call method to test.
	    // This causes a fake response to be sent
	    // from the class that implements HttpCalloutMock.
	    TestDataUtility testDataUtilityObj = new TestDataUtility(1);
	    
	    //Create a registrant
	    testDataUtilityObj.createRegistrants();
		string sfAccountId=testDataUtilityObj.lstRegistrants[0].id;
		
		//create billing account
		testDataUtilityObj.createBillingAccountToRegistrant(sfAccountId);
		string billingAccountId=testDataUtilityObj.lstBillingAccount[0].id;
		
		//Create Payment Record
		testDataUtilityObj.createZuoraPaymentRecord(sfAccountId,billingAccountId);
		
		//Create Payment Method Record	
		testDataUtilityObj.createZuoraPaymentMethod(billingAccountId);
	}
}