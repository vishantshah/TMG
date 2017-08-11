/************************************************************************************
Class Name   : CaseCommentsControllerTest
Author       : Mantas Grigaliunas
Created Date : 15/08/2016
Function     : CaseCommentsController class unit tests
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer          Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Michal Szewczyk    05/10/2016 - changes to fix test after changes of CaseCommentsController logic
* Pawel Chrzanowski  21/10/2016   Added testSaveNewCommentEmpty()
* Mantas Grigaliunas 06/02/2016	  Amended testGetCaseCommentsOrderByParentId
*************************************************************************************/
@isTest
private class CaseCommentsControllerTest {

	private static final Integer CASE_SIZE = 1;
	private static final Integer CASE_COMMENT_SIZE = 30;
	private static final Integer DISPLAYED_COMMENTS = 3;
	private static final Integer QUERY_LIMIT = 10;
	private static List<CaseComment> testCaseComments;
	private static List<Case> testCase;

	/************************************************************************************
	Method Name  : testSetup
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@testSetup static void testSetup(){

		TestDataUtility tdu = new TestDataUtility(CASE_SIZE);
		tdu.createCase();
		tdu.createCaseComments(CASE_COMMENT_SIZE);
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsAscOrder
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCaseCommentsAscOrder() {

		CaseCommentsController ctrl = defineController();

		Test.startTest();
		System.assertEquals(DISPLAYED_COMMENTS, ctrl.getCaseComments().size());
		System.assertEquals(QUERY_LIMIT, ctrl.allCaseComments.size());
		//check if records are ordered ascending by created dated
		System.assertEquals(testCaseComments[0].Id, ctrl.allCaseComments[0].Id);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsShowAll
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCaseCommentsShowAll() {

		CaseCommentsController ctrl = defineController();
		ctrl.showAll = true;

		Test.startTest();
		System.assertEquals(QUERY_LIMIT, ctrl.getCaseComments().size());
		System.assertEquals(true, ctrl.showCountPanel, 'showCountPanel expected to be set to false');
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsDescOrder
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCaseCommentsDescOrder() {

		CaseCommentsController ctrl = defineController();
		ctrl.isDesc = true;

		Test.startTest();
		System.assertEquals(DISPLAYED_COMMENTS, ctrl.getCaseComments().size());
		System.assertEquals(QUERY_LIMIT, ctrl.allCaseComments.size());
		System.assertEquals(true, ctrl.showCountPanel, 'showCountPanel expected to be set to false');
		//check if records are ordered descending by created dated
		System.assertEquals(testCaseComments[0].Id, ctrl.allCaseComments[0].Id);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsOrderByParentId
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    			Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* Mantas Grigaliunas	06/02/2016   Removed assertion as it was failing randomly because it is using Created Date to order by
	*************************************************************************************/
	@isTest static void testGetCaseCommentsOrderByParentId() {

		CaseCommentsController ctrl = defineController();
		ctrl.orderBy = 'ParentId';

		Test.startTest();
		System.assertEquals(DISPLAYED_COMMENTS, ctrl.getCaseComments().size());
		System.assert(ApexPages.getMessages().size() == 0, String.valueOf(ApexPages.getMessages()));
		System.assertEquals(QUERY_LIMIT, ctrl.allCaseComments.size());
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsWrongOrderByField
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCaseCommentsWrongOrderByFieldParameter() {

		CaseCommentsController ctrl = defineController();
		ctrl.orderBy = 'Wrong field';

		Test.startTest();
		ctrl.getCaseComments();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),  Label.Wrong_Case_Comment_Field));
		System.assertEquals(true, ctrl.showMessage, 'showMessage expected to be set to true');
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsCatchedException
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCaseCommentsCatchedException() {

		Test.startTest();
		CaseCommentsController ctrl = new CaseCommentsController();
		ctrl.getCaseComments();
		System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(),  'Case Comments Exception'));
		System.assertEquals(true, ctrl.showMessage, 'showMessage expected to be set to true');
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testCreateNewComment
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCreateNewComment() {

		Test.startTest();
		CaseCommentsController ctrl = new CaseCommentsController();
		//check if initial values are not set
		System.assertEquals(false, ctrl.showNewComment);
		System.assertEquals(null, ctrl.newComment);

		ctrl.createNewComment();
		ctrl.getInitState();
		System.assert(true, ctrl.showNewComment);
		System.assertEquals(new CaseComment(), ctrl.newComment);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testSaveNewCommentNoComments
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveNewCommentNoComments() {

		final String COMMENT_BODY = 'testSaveNewCommentNoComments';

		CaseCommentsController ctrl = defineController();
		delete testCaseComments;
		//make sure there is no comments
		ctrl.getCaseComments();
		ctrl.CaseCommentTxt = COMMENT_BODY;
		System.assertEquals(0, ctrl.allCaseComments.size());
		System.assertEquals(false, ctrl.showCountPanel, 'showCountPanel expected to be set to false');
		//create new comment
		ctrl.createNewComment();
		Test.startTest();
		ctrl.saveNewComment();
		List<CaseComment> newCaseCommentList = [SELECT Id, ParentId, CreatedDate FROM CaseComment WHERE CommentBody = :COMMENT_BODY];
		System.assertEquals(1, newCaseCommentList.size());
		System.assertEquals(testCase[0].Id, newCaseCommentList[0].ParentId);
		System.assertEquals(ctrl.allCaseComments[0].Id, newCaseCommentList[0].Id);
		Test.stopTest();
	}


	/************************************************************************************
	Method Name  : testSaveNewComment
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveNewComment() {

		final String COMMENT_BODY = 'A testSaveNewComment';

		CaseCommentsController ctrl = defineController();
		//ordering by CommentBody as created date is the same for all the records in test context
		ctrl.orderBy = 'CommentBody';
		ctrl.getCaseComments();
		//create new comment
		ctrl.CaseCommentTxt = COMMENT_BODY;
		ctrl.createNewComment();
		ctrl.newComment.CommentBody = COMMENT_BODY;

		Test.startTest();
		ctrl.saveNewComment();
		List<CaseComment> newCaseCommentList = [SELECT Id, ParentId, CreatedDate FROM CaseComment WHERE CommentBody = :COMMENT_BODY];
		System.assertEquals(1, newCaseCommentList.size());
		System.assertEquals(testCase[0].Id, newCaseCommentList[0].ParentId);
		System.assertEquals(true, ctrl.showNewComment);
		System.assertEquals(ctrl.allCaseComments[0].Id, newCaseCommentList[0].Id);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testSaveNewCommentEmpty
	Author       : Pawel Chrzanowski
	Created Date : 21/10/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testSaveNewCommentEmpty() {
		CaseCommentsController ctrl = defineController();

		ctrl.createNewComment();
		ctrl.CaseCommentTxt = '';
		ctrl.saveNewComment();

		List<CaseComment> lstComments = [SELECT Id FROM CaseComment];
		System.assert(ctrl.showMessage);
		System.assertEquals(CASE_COMMENT_SIZE, lstComments.size());
	}

	/************************************************************************************
	Method Name  : testCancelSaveNewComment
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCancelSaveNewComment() {

		CaseCommentsController ctrl = new CaseCommentsController();
		System.assertEquals(false, ctrl.showNewComment);

		Test.startTest();
		ctrl.cancelSaveNewComment();
		ctrl.clearFlags();
		System.assertEquals(false, ctrl.showNewComment);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testGetCaseCommentsCount
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testGetCaseCommentsCount(){

		CaseCommentsController ctrl = defineController();
		ctrl.getCaseComments();

		Test.startTest();
		System.assertEquals('Showing ' + String.valueOf(DISPLAYED_COMMENTS) + ' out of ' + String.valueOf(QUERY_LIMIT) + ' | ',
			ctrl.getCommentsCount());
		Test.stopTest();

	}

	/************************************************************************************
	Method Name  : testShowHideAll
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testShowHideAll() {

		CaseCommentsController ctrl = new CaseCommentsController();
		System.assertEquals(false, ctrl.showAll);

		Test.startTest();
		ctrl.showHideAll();
		System.assertEquals(true, ctrl.showAll);
		ctrl.showHideAll();
		System.assertEquals(false, ctrl.showAll);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : testCommandLinkLabel
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@isTest static void testCommandLinkLabel() {

		CaseCommentsController ctrl = new CaseCommentsController();

		Test.startTest();
		System.assertEquals(Label.Show_More, ctrl.commandLinkLabel);
		ctrl.showAll = true;
		System.assertEquals(Label.Show_Less, ctrl.commandLinkLabel);
		Test.stopTest();
	}

	/************************************************************************************
	Method Name  : defineController
	Author       : Mantas Grigaliunas
	Created Date : 15/08/2016
	Function     : method used in tests to define default component variables
 	Change Log:
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
	* Developer    Date         Description
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	*************************************************************************************/
	@TestVisible
	private static CaseCommentsController defineController(){

		//checking if expected case exist in database
		testCase = new List<Case>([SELECT Id FROM Case]);
		System.assertEquals(CASE_SIZE, testCase.size());
		//checking if expected case comments exist in database
		testCaseComments = new List<CaseComment>([SELECT Id FROM CaseComment WHERE ParentId = :testCase[0].Id ORDER BY CreatedDate]);
		System.assertEquals(CASE_COMMENT_SIZE, testCaseComments.size());

		//define controller and required variables
		CaseCommentsController ctrl = new CaseCommentsController();
		ctrl.thisCaseId = testCase[0].Id;
		ctrl.numberOfCommentsToDisplay = DISPLAYED_COMMENTS;
		ctrl.maxNumberOfComments = QUERY_LIMIT;
		ctrl.orderBy = Constants.CASE_COMMENT_ORDERBY_DEFAULT_FIELD_NAME;
		ctrl.isDesc = false;

		return ctrl;
	}
}