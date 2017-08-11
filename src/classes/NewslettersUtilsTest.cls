@isTest
private class NewslettersUtilsTest {

	public static final String TEST_STRING = 'Test';
	
	/************************************************************************************
  	Method Name  : testGetResponse
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetResponse(){

		Test.startTest();
		HttpResponse testResponse = new HttpResponse();
		testResponse.setBody(TEST_STRING);
		NewslettersUtils.testResponse = testResponse;
		System.assertEquals(TEST_STRING, NewslettersUtils.getResponse(TEST_STRING, TEST_STRING, TEST_STRING).getBody());
		Test.stopTest();
	}

	/************************************************************************************
  	Method Name  : testGetSetting
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testGetSetting(){

		TestDataUtility tdu = new TestDataUtility();
		tdu.createNewslettersEndPointSettings();

		Test.startTest();
			System.assertEquals('Testing', NewslettersUtils.getSetting(Constants.NEWSLETTERS_GET_END_POINT));
		Test.stopTest();
	}
}