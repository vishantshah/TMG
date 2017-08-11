@isTest
public class NewslettersControllerTest {

	public static final String testNewslettersBody = '['
		+ '{'
		+ '"id": "Test_Newsletter_1",'
    	+ '"category": "Category A",'
      	+ '"name": "Name A",'
	    + '"frequency": "Frequency A",'
	    + '"imageUrl": "http://www.telegraph.co.uk/content/dam/newsletters/Fashion/Fashion_5.jpg",'
	    + '"sampleUrl": "http://www.telegraph.co.uk/content/dam/newsletters/Fashion/Fashion_5.jpg",'
	    + '"publicFacingUrl": "http://www.telegraph.co.uk/content/dam/newsletters/Fashion/Fashion_5.jpg",'
	    + '"description": "Description A",'
	    + '"hideSample": false,'
	    + '"retired": false,'
	    + '"defaultAccess": true'
	    + '},'
	    + '{'
		+ '"id": "Test_Newsletter_2",'
    	+ '"category": "Category B",'
      	+ '"name": "Name B",'
	    + '"frequency": "Frequency B",'
	    + '"imageUrl": "http://www.telegraph.co.uk/content/dam/newsletters/Fashion/Fashion_5.jpg",'
	    + '"sampleUrl": "http://www.telegraph.co.uk/content/dam/newsletters/Fashion/Fashion_5.jpg",'
	    + '"publicFacingUrl": "http://www.telegraph.co.uk/content/dam/newsletters/Fashion/Fashion_5.jpg",'
	    + '"description": "Description B",'
	    + '"hideSample": false,'
	    + '"retired": true,'
	    + '"defaultAccess": true'
	    + '}'
    +']';
    public static final String ERROR_BODY = 'Error';
    public static final String CREATE_NEW_PAGE = 'newsletterscreatenew';
    public static final String DESC_ORDER = 'desc';
    public static final String ASC_ORDER = 'asc';

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
		TestDataUtility tdu = new TestDataUtility();
		tdu.createNewslettersEndPointSettings();
	}

	/************************************************************************************
  	Method Name  : testGetNewslettersSuccess
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetNewslettersSuccess() {

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		Test.stopTest();
		// Verify that the map contains the values from response
        System.assertEquals(2, ctrl.lstNewsletters.size());
	}

	/************************************************************************************
  	Method Name  : testGetNewslettersNotFound
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetNewslettersNotFound() {

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.NOT_FOUND);
		getNewslettersResponse.setBody('[]');

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		Test.stopTest();
		// Verify that the map contains the values from response
        System.assertEquals(0, ctrl.lstNewsletters.size());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
        				Label.Newsletter_Not_Found), ApexPages.getMessages());
	}

	/************************************************************************************
  	Method Name  : testGetNewslettersServerError
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetNewslettersServerError() {

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(500);
		getNewslettersResponse.setBody(ERROR_BODY);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		Test.stopTest();
		// Verify that the map contains the values from response
        System.assertEquals(0, ctrl.lstNewsletters.size());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
        				getNewslettersResponse.getBody()), ApexPages.getMessages());
	}

	/************************************************************************************
  	Method Name  : testGetNewslettersCustomSettingMissing
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetNewslettersCustomSettingMissing() {

		delete Application_Settings__c.getAll().values(); 

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.getNewsletters();
		Test.stopTest();
		// Verify that the map contains the values from response
        System.assertEquals(0, ctrl.lstNewsletters.size());
        System.debug(ApexPages.getMessages());
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), 
				String.format(Label.Newsletter_Custom_Setting_Missing , new List<String>{Constants.NEWSLETTERS_GET_END_POINT})), 
        		ApexPages.getMessages());
	}

	/************************************************************************************
  	Method Name  : testCreateNew
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testCreateNew() {

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		Test.setCurrentPage(ctrl.createNew());
		Test.stopTest();
		System.assertEquals('/apex/' + CREATE_NEW_PAGE + '?retUrl='
							+ NewslettersUtils.encode(NewslettersController.RETURN_URL), 
								ApexPages.currentPage().getUrl());
	}

	/************************************************************************************
  	Method Name  : testEditRecord
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testEditRecord() {

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		NewslettersController.NewsletterWrapper testNw = ctrl.lstNewsletters.get(0);
		NewslettersController.selectedNewsletterId = testNw.id;
		Test.setCurrentPage(ctrl.editRecord());
		Test.stopTest();
		System.assertEquals(NewslettersUtils.generateTestUrl(CREATE_NEW_PAGE, testNw, true),
				ApexPages.currentPage().getUrl());
	}

	/************************************************************************************
  	Method Name  : testViewRecord
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testViewRecord() {

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		NewslettersController.NewsletterWrapper testNw = ctrl.lstNewsletters.get(0);
		NewslettersController.selectedNewsletterId = testNw.id;
		Test.setCurrentPage(ctrl.viewRecord());
		Test.stopTest();
		System.assertEquals(NewslettersUtils.generateTestUrl('newslettersview', testNw, false),
				ApexPages.currentPage().getUrl());
	}

	/************************************************************************************
  	Method Name  : testSortByCategory
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSortByCategory() {

		String CATEGORY_A = 'Category A';
		String CATEGORY_B = 'Category B';

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		System.assertEquals(CATEGORY_A, ctrl.lstNewsletters.get(0).category);

		NewslettersController.sortField = Label.Newsletter_Category;
		NewslettersController.sortOrder = ASC_ORDER;
		ctrl.sort();
		System.assertEquals(CATEGORY_A, ctrl.lstNewsletters.get(0).category);
		NewslettersController.sortOrder = DESC_ORDER;
		ctrl.sort();
		System.assertEquals(CATEGORY_B, ctrl.lstNewsletters.get(0).category);
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSortByCategory
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSortByName() {

		String NAME_A = 'Name A';
		String NAME_B = 'Name B';

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		System.assertEquals(NAME_A, ctrl.lstNewsletters.get(0).name);

		NewslettersController.sortField = Label.Newsletter_Name;
		NewslettersController.sortOrder = ASC_ORDER;
		ctrl.sort();
		System.assertEquals(NAME_A, ctrl.lstNewsletters.get(0).name);
		NewslettersController.sortOrder = DESC_ORDER;
		ctrl.sort();
		System.assertEquals(NAME_B, ctrl.lstNewsletters.get(0).name);
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSortByFrequency
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSortByFrequency() {

		String FREQUENCY_A = 'Frequency A';
		String FREQUENCY_B = 'Frequency B';

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		System.assertEquals(FREQUENCY_A, ctrl.lstNewsletters.get(0).frequency);

		NewslettersController.sortField = Label.Newsletter_Frequency;
		NewslettersController.sortOrder = ASC_ORDER;
		ctrl.sort();
		System.assertEquals(FREQUENCY_A, ctrl.lstNewsletters.get(0).frequency);
		NewslettersController.sortOrder = DESC_ORDER;
		ctrl.sort();
		System.assertEquals(FREQUENCY_B, ctrl.lstNewsletters.get(0).frequency);
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSortByDescription
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSortByDescription() {

		String DESCRIPTION_A = 'Description A';
		String DESCRIPTION_B = 'Description B';

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		System.assertEquals(DESCRIPTION_A, ctrl.lstNewsletters.get(0).description);

		NewslettersController.sortField = Label.Newsletter_Description;
		NewslettersController.sortOrder = ASC_ORDER;
		ctrl.sort();
		System.assertEquals(DESCRIPTION_A, ctrl.lstNewsletters.get(0).description);
		NewslettersController.sortOrder = DESC_ORDER;
		ctrl.sort();
		System.assertEquals(DESCRIPTION_B, ctrl.lstNewsletters.get(0).description);
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testSortByRetired
  	Author       : Mantas Grigaliunas
  	Created Date : 28/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testSortByRetired() {

		HttpResponse getNewslettersResponse = new HttpResponse();
		getNewslettersResponse.setHeader('Test', 'Header');
		getNewslettersResponse.setStatusCode(NewslettersController.OK);
		getNewslettersResponse.setBody(testNewslettersBody);

		Test.startTest();
		NewslettersController ctrl = new NewslettersController();
		ctrl.testResponse = getNewslettersResponse; 
		ctrl.getNewsletters();
		System.assertEquals(2, ctrl.lstNewsletters.size());
		System.assertEquals(false, ctrl.lstNewsletters.get(0).retired);

		NewslettersController.sortField = Label.Newsletter_Retired;
		NewslettersController.sortOrder = ASC_ORDER;
		ctrl.sort();
		System.assertEquals(false, ctrl.lstNewsletters.get(0).retired);
		NewslettersController.sortOrder = DESC_ORDER;
		ctrl.sort();
		System.assertEquals(true, ctrl.lstNewsletters.get(0).retired);
		Test.stopTest();
	}
}