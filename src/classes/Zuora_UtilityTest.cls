/**
* Author:       Sally ElGhoul (Accenture)
* Date:         12/10/2015
* Description:  this class is a zuora Utility test class
*
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika		28/01/2016
**/
@isTest(SeeAllData = true)
//this flag is needed in order to see Zuora WSDL and avoid failure for this method for example
//Zuora.zObject acc = new Zuora.zObject(constants.ZUORA_ACCOUNT_OBJECT_NAME);
private class Zuora_UtilityTest {

	static testMethod void testgetZuoraPaymentRecords() {
		try {
			Zuora_Utility.getZuoraPaymentRecords(new Zuora.zApi(), new list<string> {});
		} catch (exception ex) {}

		Zuora_Utility.getZuoraPaymentRecords(new Zuora.zApi(), new list<string> {'id1', 'id2'});
	}

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

		string sfAccountId = testDataUtilityObj.lstRegistrants[0].id;

		//test Creating zbilling account
		Zuora_Utility.CreateZuoraBillingAccount(new Zuora.zApi(), sfAccountId);

		//test dele record in zuora
		Zuora_Utility.DeleteZuoraRecords(new Zuora.zApi(), 'Account', new list<string> {'Test123'});

		//check zuora result in case of error
		Zuora.zApi.SaveResult res = new Zuora.zApi.SaveResult();
		res.Success = false;
		Zuora.zObject error = new Zuora.zObject('Error');
		error.setValue('Code', '1223');
		error.setValue('Message', 'Error');
		res.errors = new list<Zuora.zObject> {error};
		List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult> {res};
		try {
			Zuora_Utility.CheckZuoraResults(results, 'Testing Method');
		} catch (exception ex) {}

		//check zuora result in case of error
		Zuora.zApi.DeleteResult delRes = new Zuora.zApi.DeleteResult();
		delRes.Success = false;
		Zuora.zObject delError = new Zuora.zObject('Error');
		delError.setValue('Code', '1223');
		delError.setValue('Message', 'Error');
		delRes.errors = new list<Zuora.zObject> {delError};
		List<Zuora.zApi.DeleteResult> delResults = new List<Zuora.zApi.DeleteResult> {delRes};
		try {
			Zuora_Utility.CheckZuoraResults(delResults, 'Testing Method');
		} catch (exception ex) {}

		//Call the set payment method function
		Zuora_utility.setDefaultPaymentMethod(new Zuora.zApi(), 'AccountId', 'PaymentId', false);
	}

	//another test methods
	static testMethod void testAllZuoraActions() {
		// Set mock callout class
		MockHttpCoreApiResponseGenerator ResponseGenerator = new MockHttpCoreApiResponseGenerator(200);
		Test.setMock(HttpCalloutMock.class, ResponseGenerator);

		TestDataUtility testDataUtilityObj = new TestDataUtility(1);
		//Create a registrant
		testDataUtilityObj.createZquotes();

		String sfAccountId = testDataUtilityObj.lstRegistrants[0].id;
		String quoteId = testDataUtilityObj.lstZQuotes[0].Id;

		Zuora_Utility.getQuoteChargeGroups(quoteId);
		String testId1 = '01rg00000000000';
		String testId2 = '01rg00000000001';

		List<zqu.zChargeGroup> lChargeGroups = new List<zqu.zChargeGroup>();
		List<zqu.zChargeGroup> lChargeGroups2 = new List<zqu.zChargeGroup>();
		//delete ddiscount rateplan
		Zuora_Utility.deleteDiscountRatePlans(quoteId, lChargeGroups, new Set <Id> {testId1, testId2});

		Zuora_Utility.deleteQuoteRatePlan(quoteId, new Set <Id> {testId1, testId2}, lChargeGroups);
		//delete Quote Rate Plan
		Zuora_Utility.deleteDiscountRatePlansByOfferType(quoteId, lChargeGroups2, new List<String> {testId1, testId2});
		//rollback
		Zuora_Utility.rollbackZuoraAccountContactCreation(new Zuora.zApi(), 'zuoraSampleId', 'zuoraContactSAmpleId');
		//get original zuora subAmenmds
		Zuora_Utility.getZuoraSubscriptionAmendments(new Zuora.zApi(), '');
		//all zuora Sub
		Zuora_Utility.getAllZuoraSubscriptionVersions(new Zuora.zApi(), 'originalSubId');
		//get latest version
		Zuora_Utility.getLatestSubscriptionVersion(new Zuora.zApi(), 'originalSubId');
		//uopdate sub
		Zuora_Utility.UpdateCancelledSubscription(new Zuora.zApi(), Constants.SUBSCRIPTION_CANCELLATION_REASON_PRICE, 'Price Increase', '00:00:00 01/01/2016', '00:00:00 01/01/2016', 'zuoraSubId');
		//get Zuora Billing Accounts
		Zuora_Utility.getZuoraBillingAccounts(new Zuora.zApi(), testDataUtilityObj.lstRegistrants[0].id);
		//update electronic payment
		Zuora_Utility.updateQuoteElectornicPayment(testDataUtilityObj.lstZQuotes[0].Id, 'paymentMethodIdp');
		//send quote to zbilling
		Zuora_Utility.sendQuoteToZBilling(testDataUtilityObj.lstZQuotes[0].Id, testDataUtilityObj.lstRegistrants[0].id, 'zuoraAccountId', 'PaymentMethodID');
		//get Quote Products
		Zuora_Utility.getQuoteProducts(testDataUtilityObj.lstZQuotes[0].Id, lChargeGroups);
		// gate ratePlanIds
		Set <Id> ratePlanIds = Zuora_Utility.getProductDiscountRatePlanIds(new Set<Id> {testId1, testId2});
		//insert them
		//CoreApiResources.OfferCodeDetails offdetails = new CoreApiResources.OfferCodeDetails(name='name', description='bla', longdescription='blablabla',containsFreeTrial=true, tmgId='id12345');
		/*CoreApiResources.OfferCodeDetails offdetails = new CoreApiResources.OfferCodeDetails();
		Zuora_Utility.insertDiscountRatePlans(testDataUtilityObj.lstZQuotes[0].Id, new Set<Id> {testId1, testId2}, offdetails);
		//update details
		Zuora_Utility.UpdateQuoteRatePlanChargeRecord(testDataUtilityObj.lstZQuotes[0].Id, offdetails, 'offerCodeTextValue', 'Tablet');
		//delete records
		List<String> lZuoraIds = new List <String> {'id1555555555555555', 'id2222222222222222'};
		Zuora_Utility.deleteZuoraRecords(lZuoraIds, 'Account', new Zuora.zApi());
		try {
			Zuora_Utility.AddNewOfferCode(testDataUtilityObj.lstZQuotes[0], 'New subscription', offdetails, lChargeGroups2, 'offerCodeTextValueVustom', Constants.OFFER_CODE_ACQUISITION_DISCOUNT_TYPE);
		} catch (Exception ex) {}*/
	}

}