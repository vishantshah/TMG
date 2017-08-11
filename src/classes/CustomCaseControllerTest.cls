/**
* Author:       Vishant Shah
* Date:         28/06/2017
* Description:  Test class for CustomCase
* ******************* Change Log *******************
* Modified by 	Change Date
**/

@isTest
private class CustomCaseControllerTest{

	private static final String READER_RELATIONS = 'Reader Relations';
	private static final String DIGITAL_SERVICES = 'Digital Services';

	@testSetup
	private static void setupTestData(){

		TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCustomValidationRules();
        tdu.createCase();
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test page load failure
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadFailure(){

		setPageReference(); 
		ApexPages.StandardController sc = new ApexPages.StandardController(getCase());
		CustomCaseController ccc        = new CustomCaseController(sc);
		Case thisCase = [SELECT Id, RecordType.Name FROM Case WHERE Id = :ccc.thisCase.Id];
		checkMessage('Picklist values not found in Custom Validation Rules for ' + thisCase.RecordType.Name);
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test redirection when not a OC recordtype
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadNewCase(){

		setPageReference();
		Case c = new Case();
		
		Id recortTypeId  = RecordtypeUtility.getRecordTypeId(Case.SObjectType, DIGITAL_SERVICES, 'Case');
		ApexPages.currentPage().getParameters().put('RecordType', recortTypeId);

		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		CustomCaseController ccc        = new CustomCaseController(sc);
		System.assertEquals(null, ccc.thisCase.Id, 'This should be a new case.' );
		System.assertEquals(recortTypeId, ccc.thisCase.RecordTypeId, 'New Case recordtype should be ' + DIGITAL_SERVICES );
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test failure when wrong picklist value selected.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadSuccessDMLException(){

		updateCase(READER_RELATIONS);
		setPageReference();
		Case thisCase = getCase();

		ApexPages.StandardController sc = new ApexPages.StandardController(thisCase);
		CustomCaseController ccc        = new CustomCaseController(sc);

		List<SelectOption> reasons = ccc.getReasonPicklist();
		ccc.selectedReason = reasons[1].getValue();
		ccc.caseReasonChanged();
		System.assertEquals('Puzzles & Games', ccc.selectedReason);

		List<SelectOption> detail1 = ccc.getDetail1Picklist();
		ccc.selectedDetail1 = detail1[2].getValue();
		ccc.caseDetail1Changed();
		System.assertEquals('Website', ccc.selectedDetail1);

		List<SelectOption> detail2 = ccc.getDetail2Picklist();
		ccc.selectedDetail2 = detail2[1].getValue();
		ccc.caseDetail2Changed();
		System.assertEquals('Issue', ccc.selectedDetail2);

		List<SelectOption> detail3 = ccc.getDetail3Picklist();
		ccc.selectedDetail3 = detail3[1].getValue();
		ccc.caseDetail3Changed();
		System.assertEquals('Performance', ccc.selectedDetail3);

		List<SelectOption> detail4 = ccc.getDetail4Picklist();
		ccc.selectedDetail4 = 'No loading1';
		ccc.caseDetail4Changed();  

		PageReference pr = ccc.saveCase();
		checkMessage('Allowed values for Case Detail 4 are : {No loading}');
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test to check exception.. deliberately deleted to cause exception to cover code
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadSuccessException(){

		updateCase(READER_RELATIONS);
		setPageReference();
		Case thisCase = getCase();

		ApexPages.StandardController sc = new ApexPages.StandardController(thisCase);
		CustomCaseController ccc        = new CustomCaseController(sc);

		List<SelectOption> reasons = ccc.getReasonPicklist();
		ccc.selectedReason = reasons[1].getValue();
		ccc.caseReasonChanged();
		System.assertEquals('Puzzles & Games', ccc.selectedReason);

		List<SelectOption> detail1 = ccc.getDetail1Picklist();
		ccc.selectedDetail1 = detail1[2].getValue();
		ccc.caseDetail1Changed();
		System.assertEquals('Website', ccc.selectedDetail1);

		List<SelectOption> detail2 = ccc.getDetail2Picklist();
		ccc.selectedDetail2 = detail2[1].getValue();
		ccc.caseDetail2Changed();
		System.assertEquals('Issue', ccc.selectedDetail2);

		List<SelectOption> detail3 = ccc.getDetail3Picklist();
		ccc.selectedDetail3 = detail3[1].getValue();
		ccc.caseDetail3Changed();
		System.assertEquals('Performance', ccc.selectedDetail3);

		List<SelectOption> detail4 = ccc.getDetail4Picklist();
		ccc.selectedDetail4 = 'No loading';
		ccc.caseDetail4Changed();  

		Case c = [SELECT Id FROM Case WHERE Id = :thisCase.Id];
		delete c;
		PageReference pr = ccc.saveCase();
		checkMessage('Record deleted');

	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test to check exception.. should save and go to detail page
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadSuccessSave(){

		updateCase(READER_RELATIONS);
		setPageReference();
		Case thisCase = getCase();

		ApexPages.StandardController sc = new ApexPages.StandardController(thisCase);
		CustomCaseController ccc        = new CustomCaseController(sc);

		List<SelectOption> reasons = ccc.getReasonPicklist();
		ccc.selectedReason = reasons[1].getValue();
		ccc.caseReasonChanged();
		System.assertEquals('Puzzles & Games', ccc.selectedReason);

		List<SelectOption> detail1 = ccc.getDetail1Picklist();
		ccc.selectedDetail1 = detail1[2].getValue();
		ccc.caseDetail1Changed();
		System.assertEquals('Website', ccc.selectedDetail1);

		List<SelectOption> detail2 = ccc.getDetail2Picklist();
		ccc.selectedDetail2 = detail2[1].getValue();
		ccc.caseDetail2Changed();
		System.assertEquals('Issue', ccc.selectedDetail2);

		List<SelectOption> detail3 = ccc.getDetail3Picklist();
		ccc.selectedDetail3 = detail3[1].getValue();
		ccc.caseDetail3Changed();
		System.assertEquals('Performance', ccc.selectedDetail3);

		List<SelectOption> detail4 = ccc.getDetail4Picklist();
		ccc.selectedDetail4 = detail4[1].getValue();
		ccc.caseDetail4Changed();
		System.assertEquals('No loading', ccc.selectedDetail4);

		ccc.comments = 'test comments';
		PageReference pr = ccc.saveCase();

		System.assertNotEquals(null, pr, 'save failed');
		System.assertEquals(pr.getUrl(), '/' + thiscase.Id);

		CaseComment cc = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :thisCase.Id];
		System.assertEquals('test comments', cc.CommentBody);
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test to check exception.. should save and go to case close page
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadSuccessSaveAndClose(){

		updateCase(READER_RELATIONS);
		setPageReference();
		Case thisCase = getCase();

		ApexPages.StandardController sc = new ApexPages.StandardController(thisCase);
		CustomCaseController ccc        = new CustomCaseController(sc);

		List<SelectOption> reasons = ccc.getReasonPicklist();
		ccc.selectedReason = reasons[1].getValue();
		ccc.caseReasonChanged();
		System.assertEquals('Puzzles & Games', ccc.selectedReason);

		List<SelectOption> detail1 = ccc.getDetail1Picklist();
		ccc.selectedDetail1 = detail1[2].getValue();
		ccc.caseDetail1Changed();
		System.assertEquals('Website', ccc.selectedDetail1);

		List<SelectOption> detail2 = ccc.getDetail2Picklist();
		ccc.selectedDetail2 = detail2[1].getValue();
		ccc.caseDetail2Changed();
		System.assertEquals('Issue', ccc.selectedDetail2);

		List<SelectOption> detail3 = ccc.getDetail3Picklist();
		ccc.selectedDetail3 = detail3[1].getValue();
		ccc.caseDetail3Changed();
		System.assertEquals('Performance', ccc.selectedDetail3);

		List<SelectOption> detail4 = ccc.getDetail4Picklist();
		ccc.selectedDetail4 = detail4[1].getValue();
		ccc.caseDetail4Changed();
		System.assertEquals('No loading', ccc.selectedDetail4);

		ccc.comments = 'test comments';
		PageReference pr = ccc.saveAndClose();

		System.assertNotEquals(null, pr, 'save failed');
		System.assertEquals(pr.getUrl(), '/' + thiscase.Id + '/s?retURL=' + thiscase.Id);

		CaseComment cc = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :thisCase.Id];
		System.assertEquals('test comments', cc.CommentBody);
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description test to check exception.. should save and go to recordtype selection page
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static testMethod void testPageLoadSuccessSaveAndNew(){

		updateCase(READER_RELATIONS);
		setPageReference();
		Case thisCase = getCase();

		ApexPages.StandardController sc = new ApexPages.StandardController(thisCase);
		CustomCaseController ccc        = new CustomCaseController(sc);

		List<SelectOption> reasons = ccc.getReasonPicklist();
		ccc.selectedReason = reasons[1].getValue();
		ccc.caseReasonChanged();
		System.assertEquals('Puzzles & Games', ccc.selectedReason);

		List<SelectOption> detail1 = ccc.getDetail1Picklist();
		ccc.selectedDetail1 = detail1[2].getValue();
		ccc.caseDetail1Changed();
		System.assertEquals('Website', ccc.selectedDetail1);

		List<SelectOption> detail2 = ccc.getDetail2Picklist();
		ccc.selectedDetail2 = detail2[1].getValue();
		ccc.caseDetail2Changed();
		System.assertEquals('Issue', ccc.selectedDetail2);

		List<SelectOption> detail3 = ccc.getDetail3Picklist();
		ccc.selectedDetail3 = detail3[1].getValue();
		ccc.caseDetail3Changed();
		System.assertEquals('Performance', ccc.selectedDetail3);

		List<SelectOption> detail4 = ccc.getDetail4Picklist();
		ccc.selectedDetail4 = detail4[1].getValue();
		ccc.caseDetail4Changed();
		System.assertEquals('No loading', ccc.selectedDetail4);

		ccc.comments = 'test comments';
		PageReference pr = ccc.saveAndNew();

		System.assertNotEquals(null, pr, 'save failed');
		System.assertEquals(true, pr.getUrl().contains('recordtypeselect'));

		CaseComment cc = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :thisCase.Id];
		System.assertEquals('test comments', cc.CommentBody);
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description helper to set page reference 
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static void setPageReference(){
		PageReference pageRef = Page.CustomCase;
        Test.setCurrentPage(pageRef);
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description helper to get case record.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static Case getCase(){

		List<String> caseFields = new List<String>(Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().keySet());
		String fields           = String.join(caseFields, ','); 
		String query            = ' SELECT ' + fields + ' FROM Case';

		List<Case> caseList = Database.query(query);

		if (caseList.size() == 1)
			return caseList[0];
		else 
			return null;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description helper to update case to set recordtype
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static void updateCase(String recType){
        Id recortTypeId  = RecordtypeUtility.getRecordTypeId(Case.SObjectType, recType, 'Case');
		List<Case> cases = [SELECT Id FROM Case];

		for (Case c : cases){
			c.RecordTypeId = recortTypeId;
		}

        update cases;
	}

	/***************************************************************************************
    Developer   Vishant Shah
    Date        28/06/2017
    Description heloer to test page message.
    ******************* Change Log *******************
    Modified by 	Change Date
    ****************************************************************************************/
	private static void checkMessage(String message){
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), message), 'FAIL : ' + message);
	}
}