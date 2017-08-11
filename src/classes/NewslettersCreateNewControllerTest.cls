@isTest
private class NewslettersCreateNewControllerTest {

	public static final String TEST_STRING = 'Test';
	public static final String ERROR_BODY = 'Error';
	public static final Integer RECORDS_NUMBER = 2;

	/************************************************************************************
  	Method Name  : testSetup
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@testSetup static void testSetup(){
		TestDataUtility tdu = new TestDataUtility(RECORDS_NUMBER);
		tdu.createNewsletterConfigurations(Constants.NEWSLETTER_CATEGORY_RECORD_TYPE_NAME);
		tdu.createNewsletterConfigurations(Constants.NEWSLETTER_FREQUENCY_RECORD_TYPE_NAME);
	}

	/************************************************************************************
  	Method Name  : testNewslettersCreateNewControllerConstructor
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testNewslettersCreateNewControllerConstructor(){

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		Test.stopTest();
		System.assertEquals(null, ctrl.nw.id);
	}

	/************************************************************************************
  	Method Name  : testGetYesNoOptions
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetYesNoOptions() {

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		System.assertEquals(2, ctrl.getYesNoOptions().size());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testGetCategoryOptions
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetCategoryOptions() {

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		System.assertEquals(RECORDS_NUMBER, ctrl.getCategoryOptions().size());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testGetFrequencyOptions
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetFrequencyOptions() {

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		System.assertEquals(RECORDS_NUMBER, ctrl.getFrequencyOptions().size());
		Test.stopTest();
	}
	
	/************************************************************************************
  	Method Name  : testNewslettersCreateNewControllerConstructorEditMode
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testNewslettersCreateNewControllerConstructorEditMode() {

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		Test.stopTest();

		System.assertEquals(TEST_STRING, ctrl.nw.id);
	}

	/************************************************************************************
  	Method Name  : testSaveRecordSuccess
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSaveRecordSuccess() {

		HttpResponse saveResponse = new HttpResponse();
		saveResponse.setHeader(TEST_STRING, 'Header');
		saveResponse.setStatusCode(NewslettersCreateNewController.OK);
		saveResponse.setBody(TEST_STRING);

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		ctrl.nw = NewslettersUtils.createTestNewsletter();
		ctrl.testResponse = saveResponse;
		System.assertEquals(NewslettersUtils.generateTestUrl('newslettersview', ctrl.nw, false), ctrl.saveRecord().getUrl());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSaveRecordAlreadyExists
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSaveRecordAlreadyExists() {
		HttpResponse saveResponse = new HttpResponse();
		saveResponse.setHeader(TEST_STRING, 'Header');
		saveResponse.setStatusCode(NewslettersCreateNewController.BAD_REQUEST);
		saveResponse.setBody(NewslettersCreateNewController.ALREADY_EXISTS);

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		ctrl.nw = NewslettersUtils.createTestNewsletter();
		ctrl.testResponse = saveResponse;
		ctrl.saveRecord();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
				String.format(Label.Newsletter_Already_Exists_Error, new List<String>{Label.Newsletter_Id, ctrl.nw.id})), 
        		ApexPages.getMessages());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSaveRecordWrongId
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSaveRecordWrongId() {
		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		ctrl.nw = NewslettersUtils.createTestNewsletter();
		ctrl.nw.Id = 'Test % Id';
		ctrl.saveRecord();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
        	String.format(Label.Newsletters_Id_Validation_Error, new List<String>{Label.Newsletter_Id})), 
        	ApexPages.getMessages()
        );
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSaveRecordServerError
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSaveRecordServerError() {
		HttpResponse saveResponse = new HttpResponse();
		saveResponse.setHeader(TEST_STRING, 'Header');
		saveResponse.setStatusCode(500);
		saveResponse.setBody(ERROR_BODY);

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		ctrl.nw = NewslettersUtils.createTestNewsletter();
		ctrl.testResponse = saveResponse;
		ctrl.saveRecord();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), ERROR_BODY), ApexPages.getMessages());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testUpdateRecordSuccess
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testUpdateRecordSuccess() {

		HttpResponse updateResponse = new HttpResponse();
		updateResponse.setHeader(TEST_STRING, 'Header');
		updateResponse.setStatusCode(NewslettersCreateNewController.OK);
		updateResponse.setBody(TEST_STRING);

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		ctrl.testResponse = updateResponse;
		System.assertEquals(NewslettersUtils.generateTestUrl('newslettersview', ctrl.nw, false), ctrl.updateRecord().getUrl());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testUpdateRecordServerError
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testUpdateRecordServerError() {

		HttpResponse updateResponse = new HttpResponse();
		updateResponse.setHeader(TEST_STRING, 'Header');
		updateResponse.setStatusCode(500);
		updateResponse.setBody(ERROR_BODY);

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		ctrl.testResponse = updateResponse;
		ctrl.updateRecord();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), ERROR_BODY), ApexPages.getMessages());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testCancel
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testCancel() {

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		System.assertEquals(NewslettersController.RETURN_URL, ctrl.cancel().getUrl());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : setRequestBody
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void setRequestBody() {

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettercreatenew', NewslettersUtils.createTestNewsletter(), true)));

		Test.startTest();
		NewslettersCreateNewController ctrl = new NewslettersCreateNewController();
		System.assertEquals(testJSON, ctrl.setRequestBody());
		System.assertEquals(NewslettersController.RETURN_URL, ctrl.cancel().getUrl());
		Test.stopTest();
	}

	public static String testJSON =
		+ '{'
		+ '"sampleUrl":"' + TEST_STRING +'",'
    	+ '"retired":false,'
    	+ '"publicFacingUrl":"' + TEST_STRING +'",'
      	+ '"name":"' + TEST_STRING +'",'
	    + '"imageUrl":"' + TEST_STRING +'",'
	    + '"id":"' + TEST_STRING +'",'
	    + '"hideSample":false,'
	    + '"frequency":"' + TEST_STRING +'",'
	    + '"description":"' + TEST_STRING +'",'
	    + '"defaultAccess":true,'
	    + '"category":"' + TEST_STRING +'"'
	    + '}';
}