/**
* Author:       Gavin Palmer (Accenture)
* Date:         21/04/2016
* Description:  Test class for the PricePlanRulesCloneController
*
* ******************* Change Log *******************
* Michal Szewczy	15/11/2016		Changed saveChildRecordsTest()
* Modified by       Change Date     Description
**/
@isTest
private class PricePlanRulesCloneControllerTest{

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Set up the test data for the unit tests
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@testSetup
	static void testDataSetup(){
		TestDataUtility testUtility = new TestDataUtility(1);
		// create price plan records here
		testUtility.createPricePlans();
		testUtility.createPricePlanOffers(1);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Setup the test page that will be called at the beginning of each unit test
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	private static Plan__c setupTestPage(){
		// query for price plan record
		Plan__c plan = [
			SELECT Id, Name, Days_Before__c, Is_Valid__c
			FROM Plan__c 
			LIMIT 1
		];

		Test.setCurrentPage(Page.PricePlanRulesSetup);

		return plan;
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Test the pages constructor
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	static void constructorTest(){
		Plan__c plan = setupTestPage();

		Test.startTest();
			PricePlanRulesCloneController controller = new PricePlanRulesCloneController(new ApexPages.StandardController(plan));
		Test.stopTest();

		System.assertEquals('plan0', controller.planClone.Name);
		System.assertEquals(5, controller.planClone.Days_Before__c);
		System.assertEquals(true, controller.planClone.Is_Valid__c);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Test the functionality to return to the original detail page
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	static void returnToOriginalPlanPageTest(){
		Plan__c plan = setupTestPage();

		Test.startTest();
			PricePlanRulesCloneController controller = new PricePlanRulesCloneController(new ApexPages.StandardController(plan));
			String endURL = controller.returnToOriginalPlanPage().getURL();
		Test.stopTest();

		// check that the page has successfully redirected to the record detail page
		PageReference expectedPageRefrence = new PageReference('/' + plan.Id);
		System.assertEquals(expectedPageRefrence.getURL(), endURL);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Test the save functionality
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	* Michal Szewczy	15/11/2016		Added price plan offers to clone test
	**/
	@isTest
	static void saveChildRecordsTest(){
		Plan__c plan = setupTestPage();

		Test.startTest();
			PricePlanRulesCloneController controller = new PricePlanRulesCloneController(new ApexPages.StandardController(plan));
			// add a letter to the name so that we dont vail on the unique name validation rule
			controller.planClone.Name += 'a';
			String endURL = controller.saveChildRecords().getURL();
		Test.stopTest();

		// query for the cloned plan
		Plan__c clonedPlan = [
			SELECT Id, 
			(
				SELECT Id
				FROM Price_Plans__r
			)
			FROM Plan__c 
			WHERE Id !=:plan.Id
			LIMIT 1
		];
		List<Id> pricePlanIds = new List<Id>();
		for(Price_Plan__c tmp :clonedPlan.Price_Plans__r ) {
			pricePlanIds.add(tmp.Id);
		}

		Price_Plan__c clonedPricePlan = [SELECT Id,(SELECT Id FROM Price_Plan_Offers__r) FROM Price_Plan__c WHERE Id=:pricePlanIds[0] LIMIT 1];

		// check that the record and its children have saved correctly
		System.assertNotEquals(null, clonedPlan);
		System.assertEquals(1, clonedPlan.Price_Plans__r.size());
		System.assertEquals(1,clonedPricePlan.Price_Plan_Offers__r.size());

		// check that the page has successfully redirected to the second visualforce page
		PageReference expectedPageRefrence = Page.PricePlanRulesSetup;
		expectedPageRefrence.getParameters().put('id', clonedPlan.Id);
		System.assertEquals(expectedPageRefrence.getURL(), endURL);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Test the save functionality
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	static void partialSaveTest(){
		Plan__c plan = setupTestPage();

		Test.startTest();
			PricePlanRulesCloneController controller = new PricePlanRulesCloneController(new ApexPages.StandardController(plan));
			// add a letter to the name so that we dont vail on the unique name validation rule
			controller.planClone.Name += 'a';
			String endURL = controller.saveClonedRecord().getURL();
		Test.stopTest();

		// query for the cloned plan
		Plan__c clonedPlan = [
			SELECT Id, 
			(
				SELECT Id
				FROM Price_Plans__r
			)
			FROM Plan__c 
			WHERE Id !=:plan.Id
			LIMIT 1
		];

		// check that the record and the children have not saved
		System.assertNotEquals(null, clonedPlan);
		System.assertEquals(0, clonedPlan.Price_Plans__r.size());

		// check that the page has successfully redirected to the record detail page
		PageReference expectedPageRefrence = new PageReference('/' + clonedPlan.Id);
		System.assertEquals(expectedPageRefrence.getURL(), endURL);
	}

	/**
	* Author:       Gavin Palmer (Accenture)
	* Date:         21/04/2016
	* Description:  Test the failing save functionality
	*
	* ******************* Change Log *******************
	* Modified by       Change Date     Description
	**/
	@isTest
	static void saveFailedOnValidationTest(){
		Plan__c plan = setupTestPage();

		Test.startTest();
			PricePlanRulesCloneController controller = new PricePlanRulesCloneController(new ApexPages.StandardController(plan));
			// clear the required field
			controller.planClone.Name = '';
			PageReference endPage = controller.saveClonedRecord();
		Test.stopTest();

		// query for the cloned plan
		List<Plan__c> clonedPlan = [
			SELECT Id, 
			(
				SELECT Id
				FROM Price_Plans__r
			)
			FROM Plan__c 
			WHERE Id !=:plan.Id
			LIMIT 1
		];

		// check that the record and has not saved
		System.assertEquals(0, clonedPlan.size());

		// check that the page has remained on the same page
		System.assertEquals(null, endPage);

		// check that the page messages have been put on the page
		System.assertEquals(true, ApexPages.hasMessages());
		System.assertEquals(1, ApexPages.getMessages().size());
	}
}