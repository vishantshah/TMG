@isTest
private class NewslettersViewControllerTest {
	
	/************************************************************************************
  	Method Name  : testNewslettersCreateNewControllerConstructor
  	Author       : Mantas Grigaliunas
  	Created Date : 29/09/2016
  	Change Log:
  	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
  	* Developer    Date         Description
  	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  	*************************************************************************************/
	@isTest static void testNewslettersViewControllerConstructor(){

		Test.setCurrentPage(new PageReference(
			NewslettersUtils.generateTestUrl('newslettersview', NewslettersUtils.createTestNewsletter(), false)));

		Test.startTest();
		NewslettersViewController ctrl = new NewslettersViewController();
		Test.stopTest();
		System.assertEquals('Test', ctrl.nw.id);
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
	@isTest static void testEditRecord(){

		PageReference testPage = new PageReference(
			NewslettersUtils.generateTestUrl('newslettersview', NewslettersUtils.createTestNewsletter(), false));
		Test.setCurrentPage(testPage);

		Test.startTest();
		NewslettersViewController ctrl = new NewslettersViewController();
		System.assertEquals(testPage.getUrl(), ctrl.editRecord().getParameters().get(NewslettersUtils.RET_URL));
		Test.stopTest();
	}
	
}