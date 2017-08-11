/**
* @author Pawel Chrzanowski
* @date 26/01/2016
* @description CaseMassAmendmentController test class
#############Change Log#############
Modified by        Version     Change Date
Pawel Chrzanowski  1.1         04/02/2016
Pawel Chrzanowski  1.2         25/08/2016  //added test coverage
Pawel Chrzanowski  1.3         25/04/2017  //updated methods
**/
@isTest
private class CaseMassAmendmentControllerTest {

    private static final Integer PAGE_SIZE = 10;    
    private static final Integer CASE_AMOUNT = PAGE_SIZE * 3;
    private static final String CURRENT_PAGE = '/apex/casesearch';
    private static final String NEXT_PAGE = '/apex/casemassamendment';

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test constructor validations
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void constructorTest_amendmentNegative(){
        PageReference pr = Page.CaseMassAmendment;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Case>());
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Case_Search_No_Cases_Error));
    }

    static testMethod void constructorTest_emailNegative(){
        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Case>());
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Case_Search_No_Cases_Error));
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 19/01/2016
    Version - 1.0
    Function - test positive scenario of mass Case amendment after entering from Case List View
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void amendmentTest_positive(){
        String shortComment = 'this is a test short comment';
        String testTag = 'test tag';

        TestDataUtility tdu = new TestDataUtility(CASE_AMOUNT);
        tdu.createCase();

        PageReference pageRef = Page.CaseMassAmendment;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        ssc.setSelected(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        controller.dummyCaseAmendment.Reason = Constants.CASE_REASON_IPAD;
        controller.dummyCaseAmendment.Type_Of_Issue__c = Constants.CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING;
        controller.dummyCaseAmendment.Digital_Details__c = Constants.CASE_DIGITAL_DETAILS_IPAD_TROUBLESHOOTING_APPFEATURES;
        controller.dummyCaseAmendment.Digital_Details_2__c = Constants.CASE_DIGITAL_DETAILS_2_GALLERIES;
        controller.dummyCaseAmendment.Case_Tag__c = testTag;
        controller.dummyCaseAmendment.Priority = Constants.CASE_PRIORITY_NORMAL;        
        controller.caseComment.commentBody = shortComment;

        PageReference pr = controller.saveData();
        Test.stopTest();

        List<Case> closedCases = [select Id, Status, Reason, Type_Of_Issue__c, Digital_Details__c, Digital_Details_2__c, Case_Tag__c, Priority from Case];
        List<CaseComment> caseComments = [select ParentId, CommentBody from CaseComment];
        Set<String> closedCasesIds = new Set<String>();
        Set<String> commentsIds = new Set<String>();  

        //assert that Cases were closed     
        for(Case c : closedCases){
            System.assertEquals('Closed', c.Status);
            System.assertEquals(Constants.CASE_REASON_IPAD, c.Reason);
            System.assertEquals(Constants.CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING, c.Type_Of_Issue__c);
            System.assertEquals(Constants.CASE_DIGITAL_DETAILS_IPAD_TROUBLESHOOTING_APPFEATURES, c.Digital_Details__c);
            System.assertEquals(Constants.CASE_DIGITAL_DETAILS_2_GALLERIES, c.Digital_Details_2__c);
            System.assertEquals(testTag, c.Case_Tag__c);
            System.assertEquals(Constants.CASE_PRIORITY_NORMAL, c.Priority);            
            closedCasesIds.add(c.Id);
        }

        //assert that Comments were inserted
        for(CaseComment cc : caseComments){
            System.assertEquals(shortComment, cc.CommentBody);
            commentsIds.add(cc.ParentId);
        }

        //assert that each Case has a related Comment
        System.assert(closedCasesIds.containsAll(commentsIds));
        System.assert(String.isNotBlank(pr.getUrl()));
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 19/01/2016
    Version - 1.0
    Function - test negative scenario of mass Case amendment after entering from Case List View
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void amendmentTest_negative(){
        TestDataUtility tdu = new TestDataUtility(CASE_AMOUNT);
        tdu.createCase();

        String longComment = '';
        for(Integer i = 0; i < 4010; i++){
            longComment += 'a';
        }

        PageReference pageRef = Page.CaseMassAmendment;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        ssc.setSelected(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);    

        controller.dummyCaseAmendment.Reason = Constants.CASE_REASON_IPAD;
        controller.caseComment.commentBody = longComment;

        PageReference pr = controller.saveData();
        Test.stopTest();

        List<Case> casesNotClosed = [select Id, Status, Reason from Case];
        List<CaseComment> caseComments = [select ParentId from CaseComment];

        //assert that Cases were not closed
        for(Case c : casesNotClosed){
            System.assertNotEquals('Closed', c.Status);
            System.assertNotEquals(Constants.CASE_REASON_IPAD, c.Reason);
        }

        //assert that Comments were not inserted
        System.assert(caseComments.isEmpty());
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/01/2016
    Version - 1.0
    Function - test negative scenario of mass Case amendment after entering from Case List View with no Cases selected
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void amendmentTest_negativeEmpty(){
        PageReference pageRef = Page.CaseMassAmendment;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Case>());
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);    

        controller.dummyCaseAmendment.Reason = Constants.CASE_REASON_IPAD;

        PageReference pr = controller.saveData();
        Test.stopTest();

        //assert that 'no cases' error was added
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Case_Search_No_Cases_Error));
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 09/08/2016
    Version - 1.0
    Function - test positive scenario of mass Case Search, selection buttons and pagination
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void searchAndPaginationTest(){
        List<Case> lstCases = new List<Case>();
        for(Integer i=0; i<CASE_AMOUNT; i++){
            lstCases.add(new Case(Reason=Constants.CASE_REASON_IPAD, Status=Constants.CASE_STATUS_NEW, Subject='Subject ' + i));
        }
        insert lstCases;

        PageReference pageRef = Page.CaseSearch;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Case>());
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        //prepare SOSL results
        List<String> fixedSearchResults = new List<String>();
        for(Case c : lstCases){
            fixedSearchResults.add(c.Id);
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();

            controller.dummyCaseSearch.Reason = Constants.CASE_REASON_IPAD;
            controller.dummyCaseSearch.Status = Constants.CASE_STATUS_NEW;
            controller.dummyCaseSearch.Subject = 'subject';
            controller.searchText = 'subject';
            controller.selectedRecordType = [select RecordTypeId from Case limit 1].RecordTypeId;
            controller.pageSize = CASE_AMOUNT;
            controller.search();

            //assert that single-page search results have no pagination
            System.assertEquals(1, controller.currentPage);
            System.assertEquals(CASE_AMOUNT, controller.lstCsh.size());
            System.assertEquals(CASE_AMOUNT, controller.displayedCsh.size());
            System.assert(controller.isSearched);
            System.assert(!controller.hasPrevPage);
            System.assert(!controller.hasNextPage);

            //assert proper page refresh for single-page search results
            controller.pageSize = CASE_AMOUNT;
            controller.refreshPage();
            System.assertEquals(1, controller.currentPage);
            System.assertEquals(CASE_AMOUNT, controller.displayedCsh.size());
            System.assert(!controller.hasNextPage);
            System.assert(!controller.hasPrevPage);

            //PAGINATION
            controller.pageSize = PAGE_SIZE;
            controller.search();
            controller.nextPage();
            System.assertEquals(2, controller.currentPage);
            System.assertEquals(PAGE_SIZE, controller.displayedCsh.size());
            System.assert(controller.hasNextPage);
            System.assert(controller.hasPrevPage);

            controller.nextPage();
            System.assertEquals(3, controller.currentPage);
            System.assertEquals(PAGE_SIZE, controller.displayedCsh.size());
            System.assert(!controller.hasNextPage);
            System.assert(controller.hasPrevPage);

            controller.previousPage();
            System.assertEquals(2, controller.currentPage);
            System.assertEquals(PAGE_SIZE, controller.displayedCsh.size());
            System.assert(controller.hasNextPage);
            System.assert(controller.hasPrevPage);

            controller.previousPage();
            System.assertEquals(1, controller.currentPage);
            System.assertEquals(PAGE_SIZE, controller.displayedCsh.size());
            System.assert(controller.hasNextPage);
            System.assert(!controller.hasPrevPage);

            //assert proper page refresh for multi-page search results
            controller.pageSize = PAGE_SIZE;
            controller.refreshPage();
            System.assertEquals(1, controller.currentPage);
            System.assertEquals(PAGE_SIZE, controller.displayedCsh.size());
            System.assert(controller.hasNextPage);
            System.assert(!controller.hasPrevPage);

            //SELECTION
            //Select All
            controller.selectAll();
            Boolean allSelected = true;
            for(CaseMassAmendmentController.CaseSearchHelper csh : controller.lstCsh){
                if(!csh.isChecked) {
                    allSelected = false;
                }
            }
            System.assert(allSelected);

            //Select None
            controller.selectNone();
            Boolean noneSelected = true;
            for(CaseMassAmendmentController.CaseSearchHelper csh : controller.lstCsh){
                if(csh.isChecked) {
                    noneSelected = false;
                }
            }
            System.assert(noneSelected);

            //Invert Selection
            List<Boolean> checkboxSelection = new List<Boolean>();
            for(CaseMassAmendmentController.CaseSearchHelper csh : controller.lstCsh){
                checkboxSelection.add(csh.isChecked);
            }
            controller.invertSelection();
            Boolean invertedSelected = true;
            for(Integer i=0; i<controller.lstCsh.size(); i++){
                if(controller.lstCsh[i].isChecked == checkboxSelection[i]){
                    invertedSelected = false;
                }
            }
            System.assert(invertedSelected);

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/01/2016
    Function - test positive scenario of mass Case amendment after entering from Search Page
    #############Change Log#############
    Modified by       Version     Change Date
    Pawel Chrzanowski 1.2         09/08/2016  reworked for Custom Search
	Pawel Chrzanowski 1.3         25/04/2017  modified to include new column
    ****************************************************************************************/
    static testMethod void sortTest(){
        String shortDescription = 'this is a test short description';
        String contactLastName = 'Tester';
        String contactFirstNameAlbert = 'Albert';
        String contactFirstNameWilliam = 'William';

        String mediumDescription = '';
        for(Integer i=0; i<150; i++){
            mediumDescription += 'a ';
        }
        
        //create Account
        Account a = new Account(Name='TestAccount');
        insert a;

        //create Contacts
        List<Contact> lstContacts = new List<Contact>();
        lstContacts.add(new Contact(Firstname = contactFirstNameAlbert, Lastname = contactLastName, AccountId = a.Id));
        lstContacts.add(new Contact(Firstname = contactFirstNameWilliam, Lastname = contactLastName, AccountId = a.Id));
        insert lstContacts;

        //create Cases
        List<Case> lstCases = new List<Case>();
        for(Integer i=0; i<10; i++){
            lstCases.add(new Case(Reason=Constants.CASE_REASON_IPAD, Status=Constants.CASE_STATUS_NEW, Subject='Subject ' + i));
        }
        insert lstCases;

        lstCases[0].ContactId = lstContacts[0].Id;
        lstCases[1].ContactId = lstContacts[1].Id;
        lstCases[2].ContactId = lstContacts[0].Id;
        lstCases[5].ContactId = lstContacts[0].Id;

        lstCases[5].Status = Constants.CASE_STATUS_ESCALATED;
        lstCases[6].Status = Constants.CASE_STATUS_ESCALATED;

        lstCases[7].Reason = Constants.CASE_REASON_WEBSITE;

        lstCases[0].Type_Of_Issue__c = Constants.CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING;
        lstCases[1].Type_Of_Issue__c = Constants.CASE_TYPE_OF_ISSUE_WEBSITE_GENERALINFORMATION;
        lstCases[2].Type_Of_Issue__c = Constants.CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING;
        lstCases[9].Type_Of_Issue__c = Constants.CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING;

        lstCases[0].Digital_Details__c = Constants.CASE_DIGITAL_DETAILS_MODERATION;
        lstCases[1].Digital_Details__c = Constants.CASE_DIGITAL_DETAILS_IPAD_TROUBLESHOOTING_APPFEATURES;
        lstCases[2].Digital_Details__c = Constants.CASE_DIGITAL_DETAILS_MODERATION;

        lstCases[0].Digital_Details_2__c = Constants.CASE_DIGITAL_DETAILS_2_GALLERIES;
        lstCases[1].Digital_Details_2__c = Constants.CASE_DIGITAL_DETAILS_2_MODERATION_POLICY;
        lstCases[2].Digital_Details_2__c = Constants.CASE_DIGITAL_DETAILS_2_GALLERIES;

        lstCases[0].Description = shortDescription;
        lstCases[1].Description = mediumDescription;
        lstCases[2].Description = shortDescription;

        update lstCases;

        PageReference pageRef = Page.CaseSearch;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Case>());
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        Test.startTest();

            controller.dummyCaseSearch.Reason = Constants.CASE_REASON_IPAD;
            controller.dummyCaseSearch.Status = Constants.CASE_STATUS_NEW;
            controller.dummyCaseSearch.Subject = 'subject';
            controller.selectedRecordType = [select RecordTypeId from Case limit 1].RecordTypeId;
            controller.pageSize = PAGE_SIZE;
            controller.search();

            for(Integer i=0; i<10; i++){
                if(controller.lstCsh[i].subject == 'Subject 0'){
                    //test JS Remoting
                    System.assertEquals(controller.lstCsh[i].description, CaseMassAmendmentController.getCaseDescription(String.valueOf(controller.lstCsh[i].id))); 
                }
                if(controller.lstCsh[i].subject == 'Subject 1'){
                    //test description trim
                    System.assertEquals(controller.lstCsh[i].description.length(), lstCases[1].Description.indexOf(' ', CaseMassAmendmentController.DESCRIPTION_LIMIT));
                }
            }

            //SORTING
            //assert that CaseSearchHelper list was automatically sorted ascending by default column
            System.assertEquals(CaseMassAmendmentController.DEFAULT_SEARCH_COLUMN, controller.sortBy);
            System.assertEquals(CaseMassAmendmentController.DEFAULT_SEARCH_COLUMN, CaseMassAmendmentController.staticSortBy);
            System.assert(controller.sortColumnOrders[0]);
            System.assert(controller.sortAscending);
            System.assert(CaseMassAmendmentController.staticSortAscending);
            System.assert(Integer.valueOf(controller.lstCsh[0].caseNumber) < Integer.valueOf(controller.lstCsh[1].caseNumber));

            //assert that sorting again by caseNumber column reverses CaseSearchHelper list
            controller.pageSize = CASE_AMOUNT;
            controller.sortPage();
            System.assertEquals(CaseMassAmendmentController.DEFAULT_SEARCH_COLUMN, controller.sortBy);
            System.assertEquals(CaseMassAmendmentController.DEFAULT_SEARCH_COLUMN, CaseMassAmendmentController.staticSortBy);
            System.assert(!controller.sortColumnOrders[0]);
            System.assert(!controller.sortAscending);
            System.assert(!CaseMassAmendmentController.staticSortAscending);
            System.assert(Integer.valueOf(controller.lstCsh[0].caseNumber) > Integer.valueOf(controller.lstCsh[1].caseNumber));                
            System.assertEquals(10, controller.displayedCsh.size());

            //assert proper descending sorting by Contact Name (2nd) column
            controller.sortBy = controller.sortColumnNames[1];
            controller.sortColumnOrders[1] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].contactName, contactFirstNameWilliam + ' ' + contactLastName);
            System.assertEquals(controller.lstCsh[2].contactName, contactFirstNameAlbert + ' ' + contactLastName);        

            //assert proper ascending sorting by Status (3rd) column
            controller.sortBy = controller.sortColumnNames[2];
            controller.sortColumnOrders[2] = false;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].status, Constants.CASE_STATUS_ESCALATED);
            System.assertEquals(controller.lstCsh[2].status, Constants.CASE_STATUS_NEW);

            //assert proper descending sorting by Created Date (4th) column
            controller.sortBy = controller.sortColumnNames[3];
            controller.sortColumnOrders[3] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].createdDateTimeStamp, controller.lstCsh[1].createdDateTimeStamp);

            //assert proper descending sorting by Case Reason (5th) column
            controller.sortBy = controller.sortColumnNames[4];
            controller.sortColumnOrders[4] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].reason, Constants.CASE_REASON_WEBSITE);
            System.assertEquals(controller.lstCsh[2].reason, Constants.CASE_REASON_IPAD);

            //assert proper descending sorting by Type of Issue (6th) column
            controller.sortBy = controller.sortColumnNames[5];
            controller.sortColumnOrders[5] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].typeOfIssue, Constants.CASE_TYPE_OF_ISSUE_WEBSITE_GENERALINFORMATION);
            System.assertEquals(controller.lstCsh[2].typeOfIssue, Constants.CASE_TYPE_OF_ISSUE_IPAD_TROUBLESHOOTING);

            //assert proper descending sorting by Digital Details (7th) column
            controller.sortBy = controller.sortColumnNames[6];
            controller.sortColumnOrders[6] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].digitalDetails, Constants.CASE_DIGITAL_DETAILS_MODERATION);
            System.assertEquals(controller.lstCsh[2].digitalDetails, Constants.CASE_DIGITAL_DETAILS_IPAD_TROUBLESHOOTING_APPFEATURES);

            //assert proper descending sorting by Digital Details 2 (8th) column
            controller.sortBy = controller.sortColumnNames[7];
            controller.sortColumnOrders[7] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].digitalDetails2, Constants.CASE_DIGITAL_DETAILS_2_MODERATION_POLICY);
            System.assertEquals(controller.lstCsh[2].digitalDetails2, Constants.CASE_DIGITAL_DETAILS_2_GALLERIES);

            //assert proper ascending sorting by Subject (10th) column
            controller.sortBy = controller.sortColumnNames[9];
            controller.sortColumnOrders[9] = false;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].subject, 'Subject 0');

            //assert proper descending sorting by Description (11th) column
            controller.sortBy = controller.sortColumnNames[10];
            controller.sortColumnOrders[10] = true;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[0].description, shortDescription);
            System.assertEquals(controller.lstCsh[2].description, mediumDescription.substring(0, mediumDescription.indexOf(' ', CaseMassAmendmentController.DESCRIPTION_LIMIT)));

            //sort again to cover more conditions
            controller.sortBy = controller.sortColumnNames[0];
            controller.sortColumnOrders[0] = false;
            controller.sortPage();
            System.assert(Integer.valueOf(controller.lstCsh[0].caseNumber) < Integer.valueOf(controller.lstCsh[1].caseNumber)); 
            controller.sortBy = controller.sortColumnNames[1];
            controller.sortColumnOrders[1] = false;
            controller.sortPage();
            System.assertEquals(controller.lstCsh[controller.lstCsh.size() - 2].contactName, contactFirstNameAlbert + ' ' + contactLastName);
            System.assertEquals(controller.lstCsh[controller.lstCsh.size() - 1].contactName, contactFirstNameWilliam + ' ' + contactLastName);


            //AMENDMENT
            //assert that empty selection doesn't allow redirection to CaseMassAmendment page
            controller.selectNone();
            controller.sendSelectedCasesToAmendmentPage();
            System.assertEquals(CURRENT_PAGE, ApexPages.CurrentPage().getUrl());

            //assert that selected Cases are carried over to CaseMassAmendment page 
            controller.selectAll();
            controller.sendSelectedCasesToAmendmentPage();
            System.assertEquals(10, controller.selectedFromFoundCases.size());
            controller.saveData();
    		System.assertEquals(controller.selectedCases.size(), controller.selectedFromFoundCases.size());

        Test.stopTest();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test getters
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void gettersTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCase();

        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        System.assertEquals(String.valueOf(CaseMassAmendmentController.QUERY_LIMIT), controller.getQueryLimit());
        System.assertEquals(CaseMassAmendmentController.DESCRIPTION_LIMIT, controller.getDescriptionLimit());
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test changeEmailBody
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void changeEmailBodyTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCase();

        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        controller.selectedEmailBodyType = CaseMassAmendmentController.EMAIL_BODY_CUSTOM;
        controller.changeEmailBody();
        System.assert(!controller.showEmailTemplateSelector);

        controller.selectedEmailBodyType = CaseMassAmendmentController.EMAIL_BODY_TEMPLATE;
        controller.changeEmailBody();
        System.assert(controller.showEmailTemplateSelector);
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test prepareEmailData
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void prepareEmailDataTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCase();

        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        controller.prepareEmailData();
        System.assertEquals(CaseMassAmendmentController.EMAIL_BODY_CUSTOM, controller.selectedEmailBodyType);
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test previewEmailTemplate
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void previewEmailTemplateTest(){
        Contact con = new Contact(FirstName='first', LastName='last', Email='test@test.com');
        insert con;

        Case c = new Case(Reason=Constants.CASE_REASON_IPAD, Status=Constants.CASE_STATUS_NEW, Subject='sub', ContactId=con.Id);
        insert c;

        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Case>{c});
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u){
            Id folderId = [SELECT Id from Folder WHERE Name = :CaseMassAmendmentController.EMAIL_TEMPLATE_FOLDER LIMIT 1].Id;
            EmailTemplate et = new EmailTemplate(isActive=true, Name='n', DeveloperName='d', TemplateType='text', FolderId=folderId, Subject='sub', Body='text');
            insert et;
            controller.selectedTemplate = et.Id;
        }

        controller.emailMsg = new EmailMessage();
        controller.selectedCases = new List<Case>{c};
        controller.previewEmailTemplate();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test sendEmails negative
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void sendEmailsTest_negative(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCase();

        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        controller.selectedEmailBodyType = CaseMassAmendmentController.EMAIL_BODY_CUSTOM;
        controller.sendEmails();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Case_Send_Email_No_Subject_Body));
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 25/08/2016
    Function - test sendEmails positive
    #############Change Log#############
    Modified by       Version     Change Date
    ****************************************************************************************/
    static testMethod void sendEmailsTest_positive(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createCase();

        PageReference pr = Page.CaseCustomEmail;
        Test.setCurrentPage(pr);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tdu.lstCases);
        CaseMassAmendmentController controller = new CaseMassAmendmentController(ssc);

        controller.selectedCases = tdu.lstCases;
        controller.selectedOrgEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        controller.selectedEmailBodyType = CaseMassAmendmentController.EMAIL_BODY_CUSTOM;
        controller.emailCustomSubject = 'subject';
        controller.emailCustomBody = 'body';
        controller.sendEmails();
        System.assert(controller.isEmailSent);
    }

}