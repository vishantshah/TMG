/**
* @author Pawel Chrzanowski
* @date 18/01/2016
* @description Custom Set Controller to mass amend Cases with additional reason
#############Change Log#############
Modified by        Version    Change Date
Pawel Chrzanowski  1.1        21/01/2016
Pawel Chrzanowski  1.2        01/02/2016  Rewrote most methods to implement sorting and JSRemoting
Pawel Chrzanowski  1.3        09/08/2016  Added Custom Case Search
Pawel Chrzanowski  1.4        16/08/2016  Added Mass Email
Pawel Chrzanowski  1.5        25/04/2017  Added more search fields
Pawel Chrzanowski  1.6        28/04/2017  Modified previewEmailTemplate()
**/
global with sharing class CaseMassAmendmentController{
    public ApexPages.StandardSetController ssc{get;set;}

    //searching
    public Boolean isSearched{get;set;}
    public Case dummyCaseSearch{get;set;}
    public Case dummyCaseSearch2{get;set;}
    public String searchText{get;set;}
    public String selectedBrowser{get;set;}
    public String selectedDetail1{get;set;}
    public String selectedDetail2{get;set;}
    public String selectedDetail3{get;set;}
    public String selectedDetail4{get;set;}
    public String selectedOperatingSystem{get;set;}
    public String selectedRecordType{get;set;}
    public String selectedReason{get;set;}
    public String selectedStatus{get;set;}
    public List<Case> foundCases{get;set;}
    public List<CaseSearchHelper> lstCsh{get;set;}
    public List<Case> selectedFromFoundCases{get;set;}
    public List<SelectOption> lstCaseBrowser{get;set;}
    public List<SelectOption> lstCaseDetail1{get;set;}
    public List<SelectOption> lstCaseDetail2{get;set;}
    public List<SelectOption> lstCaseDetail3{get;set;}
    public List<SelectOption> lstCaseDetail4{get;set;}
    public List<SelectOption> lstCaseOperatingSystem{get;set;}
    public List<SelectOption> lstCaseRecordTypes{get;set;}
    public List<SelectOption> lstCaseReason{get;set;}
    public List<SelectOption> lstCaseStatus{get;set;}
    @testvisible private static final String ANY_VALUE = '-- Any --';
    @testvisible private static final Integer QUERY_LIMIT = 1000;
    @testvisible private static final Integer DESCRIPTION_LIMIT = 70;
    @testvisible private static final Integer DESCRIPTION_LIMIT_BUFFER = 20;
    @testvisible private static final Integer APP_VERSION_LENGTH = 100;
    @testvisible private static final Integer OS_VERSION_LENGTH = 100;
    @testvisible private static final Integer SUBJECT_LENGTH = 255;

    //pagination
    public Integer currentPage{get;set;}
    public Integer pageSize{get;set;}
    public Boolean hasNextPage{get;set;}
    public Boolean hasPrevPage{get;set;}
    public List<CaseSearchHelper> displayedCsh{get;set;}
    public List<SelectOption> sizeOptions{get;set;}

    //sorting
    public String sortBy{get;set;}
    public Boolean sortAscending{get;set;}
    public List<String> sortColumnNames{get;set;}
    public List<Boolean> sortColumnOrders{get;set;}
    public static String staticSortBy;
    public static Boolean staticSortAscending;
    @testvisible private static final String DEFAULT_SEARCH_COLUMN = 'caseNumber';

    //amending
    public Case dummyCaseAmendment{get;set;}
    public CaseComment caseComment{get;set;}
    public List<Case> selectedCases{get;set;}
    public Boolean noCasesError{get;set;}
    private Boolean saveAndEmail{get;set;}

    //email
    public List<SelectOption> emailBodyOptions{get;set;}
    public List<SelectOption> orgEmailOptions{get;set;}
    public List<SelectOption> templateOptions{get;set;}
    public Boolean showEmailTemplateSelector{get;set;}
    public Boolean showEmailCustomBody{get;set;}
    public Boolean showEmailTemplate{get;set;}
    public Boolean isPreviewed{get;set;}
    public Boolean isEmailSent{get;set;}
    public EmailMessage emailMsg{get;set;}
    public String emailCustomSubject{get;set;}
    public String emailCustomBody{get;set;}
    public String emailHTMLBody{get;set;}
    public String selectedEmailBodyType{get;set;}
    public String selectedTemplate{get;set;}
    public String selectedOrgEmail{get;set;}
    public String exampleCaseNumber{get;set;}
    public static final String EMAIL_BODY_CUSTOM = 'Custom message';
    public static final String EMAIL_BODY_TEMPLATE = 'Template';
    @testvisible private static final String EMAIL_FOLDER_CS_NAME = 'Case Email Template Folder';
    @testvisible private static final String EMAIL_TEMPLATE_FOLDER;

    static{
        if(General__c.getValues(EMAIL_FOLDER_CS_NAME) != null && General__c.getValues(EMAIL_FOLDER_CS_NAME).value__c != null){
            EMAIL_TEMPLATE_FOLDER = General__c.getValues(EMAIL_FOLDER_CS_NAME).value__c;
        }else{
            EMAIL_TEMPLATE_FOLDER = 'Email From Case Templates';
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 03/02/2016
    Version - 1.0 
    Function - method for JS Remoting to view Case Description
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	@RemoteAction
	//setting JSRemoting as 'public' generates js alert after page forward:
	//"JS proxies were not generated for controller... may not use public remote methods inside an iframe"
	global static String getCaseDescription(String id) {
		List<Case> lstCases = [SELECT Description FROM Case WHERE Id = :id LIMIT 1];
		return lstCases.isEmpty() ? null : lstCases[0].Description;
	}

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski   1.1     15/02/2016 Added VF Error if no Cases are selected from List View
    Pawel Chrzanowski	1.2		09/08/2016 Added Custom Case Search
	Pawel Chrzanowski   1.3     25/04/2017 Added more search fields
    ****************************************************************************************/
    public CaseMassAmendmentController(ApexPages.StandardSetController controller){
        ssc = controller;

        //searching
        searchText = null;
        selectedBrowser = null;
        selectedDetail1 = null;
        selectedDetail2 = null;
        selectedDetail3 = null;
        selectedDetail4 = null;
        selectedOperatingSystem = null;
        selectedRecordType = null;
        selectedReason = null;
        selectedStatus = null;
        isSearched = false;
        foundCases = new List<Case>();
        lstCsh = new List<CaseSearchHelper>();
        selectedFromFoundCases = new List<Case>();
        dummyCaseSearch = new Case(Status = Constants.CASE_STATUS_NEW);
        dummyCaseSearch2 = new Case();

        lstCaseBrowser = new List<SelectOption>();
        lstCaseBrowser.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Browser__c.getDescribe().getPicklistValues()){
            lstCaseBrowser.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseDetail1 = new List<SelectOption>();
        lstCaseDetail1.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Type_Of_Issue__c.getDescribe().getPicklistValues()){
            lstCaseDetail1.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseDetail2 = new List<SelectOption>();
        lstCaseDetail2.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Digital_Details__c.getDescribe().getPicklistValues()){
            lstCaseDetail2.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseDetail3 = new List<SelectOption>();
        lstCaseDetail3.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Digital_Details_2__c.getDescribe().getPicklistValues()){
            lstCaseDetail3.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseDetail4 = new List<SelectOption>();
        lstCaseDetail4.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Digital_Details_3__c.getDescribe().getPicklistValues()){
            lstCaseDetail4.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseOperatingSystem = new List<SelectOption>();
        lstCaseOperatingSystem.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Operation_System__c.getDescribe().getPicklistValues()){
            lstCaseOperatingSystem.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseRecordTypes = new List<SelectOption>();
        lstCaseRecordTypes.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.RecordTypeInfo rti : Case.SObjectType.getDescribe().getRecordTypeInfos()){
            lstCaseRecordTypes.add(new SelectOption(rti.getRecordTypeId(), rti.getName()));
        }
        lstCaseReason = new List<SelectOption>();
        lstCaseReason.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Reason.getDescribe().getPicklistValues()){
            lstCaseReason.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        lstCaseStatus = new List<SelectOption>();
        lstCaseStatus.add(new SelectOption(ANY_VALUE, ANY_VALUE));
        for(Schema.PicklistEntry ple : Case.Status.getDescribe().getPicklistValues()){
            lstCaseStatus.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }

        //pagination
        currentPage = 1;
        hasNextPage = false;
        hasPrevPage = false;
        displayedCsh = new List<CaseSearchHelper>();
        sizeOptions = new List<SelectOption>();
        sizeOptions.add(new SelectOption('20', '20'));
        sizeOptions.add(new SelectOption('50', '50'));
        sizeOptions.add(new SelectOption('100', '100'));
        pageSize = 20;

        //for manual pagination testing
        //sizeOptions.add(new SelectOption('1', '1'));
        //sizeOptions.add(new SelectOption('2', '2'));
        //sizeOptions.add(new SelectOption('3', '3'));

        //sorting
        sortColumnNames = new List<String>{'caseNumber', 'contactName', 'status', 'createdDate', 'reason', 'typeOfIssue', 'digitalDetails', 'digitalDetails2', 'digitalDetails3', 'subject', 'description'};
        sortColumnOrders = new List<Boolean>{true, false, false, false, false, false, false, false, false, false, false};

        //amending
        dummyCaseAmendment = new Case(Status = Constants.CASE_STATUS_CLOSED);
        caseComment = new CaseComment();
        noCasesError = false;
        saveAndEmail = false;

        //show error if entered from list view with no Cases selected
        if(selectedFromFoundCases.isEmpty() && ssc.getSelected().isEmpty() && ApexPages.currentPage().getUrl().toLowerCase().indexOf('amendment')>0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Case_Search_No_Cases_Error));
            noCasesError = true;
        }

        //show error if entered directly to mass email page with no Cases
        if(selectedCases == null && ApexPages.currentPage().getUrl().toLowerCase().indexOf('email')>0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Case_Search_No_Cases_Error));
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Function - method to search Cases by Subject or Description
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski	1.1		15/02/2016
    Pawel Chrzanowski   1.2     09/08/2016  //added Custom Case Search
	Pawel Chrzanowski   1.3     25/04/2017  //added more search fields
    ****************************************************************************************/
    public void search(){
        currentPage = 1;
        hasPrevPage = false;
        isSearched = true;
        lstCsh = new List<CaseSearchHelper>();
        displayedCsh = new List<CaseSearchHelper>();
        selectedFromFoundCases = new List<Case>();

        List<Case> lstCasesSOQL = new List<Case>();
        List<Case> lstCasesSOSL = new List<Case>();
        DateTime dateFrom = dummyCaseSearch.Search_Date_Selector__c;
        DateTime dateTo = dummyCaseSearch2.Search_Date_Selector__c != null ? dummyCaseSearch2.Search_Date_Selector__c.addSeconds(59) : null;
        String subject = String.isNotBlank(dummyCaseSearch.Subject) ? '%' + dummyCaseSearch.Subject.trim().left(SUBJECT_LENGTH) + '%' : null;
        String searchAppVersion = String.isNotBlank(dummyCaseSearch.App_Version__c) ? dummyCaseSearch.App_Version__c.trim().left(APP_VERSION_LENGTH) : null;
        String searchBrowser = (selectedBrowser != null && selectedBrowser != ANY_VALUE) ? selectedBrowser : null;
        String searchDetail1 = (selectedDetail1 != null && selectedDetail1 != ANY_VALUE) ? selectedDetail1 : null;
        String searchDetail2 = (selectedDetail2 != null && selectedDetail2 != ANY_VALUE) ? selectedDetail2 : null;
        String searchDetail3 = (selectedDetail3 != null && selectedDetail3 != ANY_VALUE) ? selectedDetail3 : null;
        String searchDetail4 = (selectedDetail4 != null && selectedDetail4 != ANY_VALUE) ? selectedDetail4 : null;
        String searchOperatingSystem = (selectedOperatingSystem != null && selectedOperatingSystem != ANY_VALUE) ? selectedOperatingSystem : null;
        String searchOSVersion = String.isNotBlank(dummyCaseSearch.OS_Version__c) ? dummyCaseSearch.OS_Version__c.trim().left(OS_VERSION_LENGTH) : null;
        String searchRT = (selectedRecordType != null && selectedRecordType != ANY_VALUE) ? selectedRecordType : null;
        String searchReason = (selectedReason != null && selectedReason != ANY_VALUE) ? selectedReason : null;
        String searchStatus = (selectedStatus != null && selectedStatus != ANY_VALUE) ? selectedStatus : null;

        String query;
        List<String> queryElements = new List<String>();
        if(dateFrom != null) queryElements.add(' CreatedDate >= :dateFrom ');
        if(dateTo != null) queryElements.add(' CreatedDate <= :dateTo ');
        if(searchAppVersion != null) queryElements.add(' App_Version__c = :searchAppVersion ');
        if(searchBrowser != null) queryElements.add(' Browser__c = :searchBrowser ');
        if(searchDetail1 != null) queryElements.add(' Type_Of_Issue__c = :searchDetail1 ');
        if(searchDetail2 != null) queryElements.add(' Digital_Details__c = :searchDetail2 ');
        if(searchDetail3 != null) queryElements.add(' Digital_Details_2__c = :searchDetail3 ');
        if(searchDetail4 != null) queryElements.add(' Digital_Details_3__c = :searchDetail4 ');
        if(searchOperatingSystem != null) queryElements.add(' Operation_System__c = :searchOperatingSystem ');
        if(searchOSVersion != null) queryElements.add(' OS_Version__c = :searchOSVersion ');
        if(searchRT != null) queryElements.add(' RecordTypeId = :searchRT ');
        if(searchReason != null) queryElements.add(' Reason = :searchReason ');
        if(searchStatus != null) queryElements.add(' Status = :searchStatus ');
        if(subject != null) queryElements.add(' Subject LIKE :subject ');

        if(String.isNotBlank(searchText)){
            //SOSL search
            query = 'FIND \'' + searchText + '\' ' + 
                    'IN ALL FIELDS RETURNING Case(CaseNumber, Contact.Name, Status, CreatedDate, Reason, Type_Of_Issue__c, Digital_Details__c, Digital_Details_2__c, Digital_Details_3__c, Subject, Description' + 
                    (queryElements.isEmpty() ? '' : ' WHERE ' + String.join(queryElements, 'AND')) + 
                    ') LIMIT :QUERY_LIMIT';
            lstCasesSOSL = (List<Case>)Search.query(query)[0];
        }else{
            //SOQL search
            query = 'SELECT CaseNumber, Contact.Name, Status, CreatedDate, Reason, Type_Of_Issue__c, Digital_Details__c, Digital_Details_2__c, Digital_Details_3__c, Subject, Description ' + 
                    'FROM Case ' + 
                    (queryElements.isEmpty() ? '' : 'WHERE ' + String.join(queryElements, 'AND')) + 
                    ' LIMIT :QUERY_LIMIT';
            lstCasesSOQL = Database.query(query);
        }

        if(lstCasesSOQL.isEmpty() && lstCasesSOSL.isEmpty()){
            return;
        }

        foundCases.addAll(lstCasesSOQL);
        foundCases.addAll(lstCasesSOSL);
        for(Case c : foundCases){
            lstCsh.add(new CaseSearchHelper(
            	false, 
            	c.Id, 
            	c.CaseNumber, 
            	c.Contact.Name, 
            	c.Status, 
            	c.CreatedDate, 
            	c.Reason, 
            	c.Type_Of_Issue__c, 
            	c.Digital_Details__c, 
                c.Digital_Details_2__c, 
            	c.Digital_Details_3__c, 
            	c.Subject,
            	c.Description
            	));
        }

        //default sorting
        sortBy = DEFAULT_SEARCH_COLUMN;
        sortAscending = true;
        CaseMassAmendmentController.staticSortBy = DEFAULT_SEARCH_COLUMN;
        CaseMassAmendmentController.staticSortAscending = true;
        lstCsh.sort();

        if(foundCases.size() > pageSize){
            hasNextPage = true;
            for(Integer i = 0; i < pageSize; i++){
                displayedCsh.add(lstCsh[i]);
            }
        }else{
            displayedCsh = lstCsh;
            hasNextPage = false;
        }
        foundCases.clear();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to select all Cases
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void selectAll(){
        for(CaseSearchHelper csh : lstCsh){
            csh.isChecked = true;
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to deselect all Cases
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void selectNone(){
        for(CaseSearchHelper csh : lstCsh){
            csh.isChecked = false;
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to invert selection on Cases
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void invertSelection(){
        for(CaseSearchHelper csh : lstCsh){
            csh.isChecked = !csh.isChecked;
        }
    } 

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to display next page of search results
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski	1.1		03/02/2016
    ****************************************************************************************/
    public void nextPage(){
        displayedCsh = new List<CaseSearchHelper>();
        currentPage++;
        for(Integer i = (currentPage * pageSize) - pageSize; i < (currentPage * pageSize); i++){
            if(i < lstCsh.size()){
                displayedCsh.add(lstCsh[i]);
            }
        }
        hasPrevPage = true;
        if((lstCsh.size() - (currentPage * pageSize)) > 0){
            hasNextPage = true;
        }else{
            hasNextPage = false;
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to display previous page of search results
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski	1.1		03/02/2016
    ****************************************************************************************/
    public void previousPage(){
        displayedCsh = new List<CaseSearchHelper>();
        currentPage--;
        for(Integer i = (currentPage * pageSize) - pageSize; i < (currentPage * pageSize); i++){
            displayedCsh.add(lstCsh[i]);
        }
        hasNextPage = true;
        if(currentPage > 1){
            hasPrevPage = true;
        }else{
            hasPrevPage = false;
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to change the number of records displayed per page
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski	1.1		03/02/2016
    ****************************************************************************************/
    public void refreshPage(){
        displayedCsh = new List<CaseSearchHelper>();
        if(lstCsh.size() > pageSize){
            hasNextPage = true;
            for(Integer i = 0; i < pageSize; i++){
                displayedCsh.add(lstCsh[i]);
            }
        }else{
            displayedCsh = lstCsh;
            hasNextPage = false;            
        }
        currentPage = 1;
        hasPrevPage = false;
    }   

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 03/02/2016
    Version - 1.0 
    Function - method to refresh the page after sorting
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void refreshPageAfterSorting(){
        displayedCsh = new List<CaseSearchHelper>();
        for(Integer i = (currentPage * pageSize) - pageSize; i < (currentPage * pageSize); i++){
            if(i < lstCsh.size()){
                displayedCsh.add(lstCsh[i]);
            }
        }
    }  

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 01/02/2016
    Version - 1.0 
    Function - method to sort search results by columns
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
	public void sortPage(){
		for(Integer i = 0; i < sortColumnNames.size(); i++){
			if(sortBy == sortColumnNames[i]){
				setOtherToFalse(sortColumnOrders, i);
				sortColumnOrders[i] = !sortColumnOrders[i];
				sortAscending = sortColumnOrders[i];
			}
		}
		CaseMassAmendmentController.staticSortBy = sortBy;
		CaseMassAmendmentController.staticSortAscending = sortAscending;		
		lstCsh.sort();
		refreshPageAfterSorting();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 03/02/2016
    Version - 1.0 
    Function - method to set entire list to false except one index
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void setOtherToFalse(List<Boolean> lst, Integer z){
    	for(Integer i = 0; i < lst.size(); i++){
    		if(i != z) {
    			lst[i] = false;
    		}
    	}
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Version - 1.0 
    Function - method to send selected Cases to CaseMassAmendment page
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski   1.1     15/02/2016 Added VF Error if no Cases are selected
    Pawel Chrzanowski	1.2		09/08/2016 Added dummy Case reset
    ****************************************************************************************/
	public PageReference sendSelectedCasesToAmendmentPage(){
		List<Id> lstId = new List<Id>();
		for(CaseSearchHelper csh : lstCsh){
			if(csh.isChecked){
				lstId.add(csh.id);
			}
		}

		if(!lstId.isEmpty()){
            dummyCaseAmendment = new Case(Status = Constants.CASE_STATUS_CLOSED);
			selectedFromFoundCases = [SELECT Id FROM Case WHERE Id IN :lstId];
			PageReference pr = Page.CaseMassAmendment;
			pr.setRedirect(false);
			return pr;
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Case_Search_No_Cases_Error));
			return null;
		}
	}

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 21/01/2016
    Function - method to mass amend Cases and insert mass Case Comments
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski   1.1     08/02/2016
    Pawel Chrzanowski	1.2		16/02/2016  added mass email
    Pawel Chrzanowski   1.3     25/04/2017  added more search fields
	Pawel Chrzanowski   1.4     28/04/2017  added support for Case Web Email
    ****************************************************************************************/
    public PageReference saveData(){
        selectedCases = new List<Case>();

        if(selectedFromFoundCases != null && !selectedFromFoundCases.isEmpty()){
            //load selected Cases from previous CaseSearch page
            selectedCases = selectedFromFoundCases;
        }else{
            if(ssc.getSelected() != null && !ssc.getSelected().isEmpty()){
                //load selected Cases from previous List View
                selectedCases = ssc.getSelected();
            }else{
                //no Cases from List View
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Case_Search_No_Cases_Error));
                return null;
            }
        }

        if(!selectedCases.isEmpty()){
            //check related Web Email and Contact email
            if(saveAndEmail){
                List<Case> lstCases = [SELECT CaseNumber, SuppliedEmail, Contact.Email FROM Case WHERE Id IN :selectedCases];
                List<String> failedCaseNumbers = new List<String>();
                for(Case c : lstCases){
                    if(String.isBlank(c.SuppliedEmail) && String.isBlank(c.Contact.Email)){
                        failedCaseNumbers.add('<a href="/' + c.Id + '">' + c.CaseNumber + '</a>');
                    }
                }
                if(!failedCaseNumbers.isEmpty()){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.Case_Search_No_Contact_Email, new List<String>{String.join(failedCaseNumbers, ', ')})));
                    return null;
                }
            }

        	//assign user input to selected Cases
        	Set<Id> caseCommentParentIds = new Set<Id>();
        	List<CaseComment> caseComments = new List<CaseComment>();
            for(Case c : selectedCases){
                c.Status = dummyCaseAmendment.Status;
                c.Reason = dummyCaseAmendment.Reason;
                c.Type_Of_Issue__c = dummyCaseAmendment.Type_Of_Issue__c;
                c.Digital_Details__c = dummyCaseAmendment.Digital_Details__c;
                c.Digital_Details_2__c = dummyCaseAmendment.Digital_Details_2__c;
                c.Digital_Details_3__c = dummyCaseAmendment.Digital_Details_3__c;
                c.Case_Tag__c = dummyCaseAmendment.Case_Tag__c;
                c.Priority = dummyCaseAmendment.Priority;
                if(String.isNotBlank(caseComment.CommentBody)){
                    caseCommentParentIds.add(c.Id);
                }
            }

            Savepoint sp = Database.setSavepoint();

            //allow partial success
			Boolean noErrors = true;
			Map<Id, List<String>> failedCases = new Map<Id, List<String>>();
			List<Database.SaveResult> srList = Database.update(selectedCases, false);
			for(Integer i = 0; i < srList.size(); i++){
				if(!srList[i].isSuccess()){
            		noErrors = false;
            		caseCommentParentIds.remove(selectedCases[i].Id);
            		List<String> errorList = new List<String>();
            		for(Database.Error err : srList[i].getErrors()){
            			errorList.add(err.getMessage());
            		}
            		failedCases.put(selectedCases[i].Id, errorList);
            	}
			}

			//list failed Cases
			if(!noErrors){
				Map<Id, Case> mapCases = new Map<Id, Case>([SELECT CaseNumber FROM Case WHERE Id IN :failedCases.keySet()]);
                for(Id key : failedCases.keySet()){
                    Case c = mapCases.get(key);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Case Number: ' + (c != null ? c.CaseNumber : '- N/A -') + ' / ' + String.join(failedCases.get(key), ', ')));
                }
			}

			//save a Case Comment for each successful Case
            if(!caseCommentParentIds.isEmpty()){
                try{
                	for(Id pId : caseCommentParentIds){
                		caseComments.add(new CaseComment(ParentId = pId, CommentBody = caseComment.CommentBody)); 
                	}
                    insert caseComments;
                }catch(DmlException e){
                    ApexPages.addMessages(e);
                    Database.rollback(sp);
                    return null;
                }
            }

            if(noErrors){
                if(saveAndEmail){
                    prepareEmailData();
                    PageReference pr = Page.CaseCustomEmail;
                    pr.setRedirect(false);
                    return pr;
                }else{
                    return ssc.cancel();
                }
            }
        }
        return null; 
    }



    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to mass save Cases and redirect to email
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public PageReference saveAndEmail(){
        saveAndEmail = true;
        return saveData();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to get QUERY_LIMIT
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public String getQueryLimit(){
        return String.valueOf(QUERY_LIMIT);
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to get DESCRIPTION_LIMIT
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public Integer getDescriptionLimit(){
        return DESCRIPTION_LIMIT;
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to prepare Email data
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void prepareEmailData(){
        emailMsg = new EmailMessage();

        orgEmailOptions = new List<SelectOption>();
        for(OrgWideEmailAddress owea : [SELECT Address, DisplayName FROM OrgWideEmailAddress]){
            orgEmailOptions.add(new SelectOption(owea.Id, owea.DisplayName + ' (' + owea.Address + ')'));
        }

        templateOptions = new List<SelectOption>();
        List<Folder> lstFolder = [SELECT Id FROM Folder WHERE Name = :EMAIL_TEMPLATE_FOLDER];
        if(!lstFolder.isEmpty()){
            for(EmailTemplate et : [SELECT Name FROM EmailTemplate WHERE IsActive = true AND FolderId = :lstFolder[0].Id ORDER BY Name ASC]){
                templateOptions.add(new SelectOption(et.Id, et.Name));
            } 
        }

        emailBodyOptions = new List<SelectOption>();
        emailBodyOptions.add(new SelectOption(EMAIL_BODY_CUSTOM, EMAIL_BODY_CUSTOM));
        emailBodyOptions.add(new SelectOption(EMAIL_BODY_TEMPLATE, EMAIL_BODY_TEMPLATE));

        showEmailTemplateSelector = false;
        showEmailCustomBody = true;
        showEmailTemplate = false;

        selectedEmailBodyType = EMAIL_BODY_CUSTOM;
        selectedOrgEmail = null;
        selectedTemplate = null;
        exampleCaseNumber = null;
        emailCustomSubject = null;
        emailCustomBody = null;
        emailHTMLBody = null;
        isPreviewed = false;
        isEmailSent = false;
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to change email body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void changeEmailBody(){
        if(selectedEmailBodyType == EMAIL_BODY_CUSTOM){
            showEmailTemplateSelector = false;
            showEmailTemplate = false;
            showEmailCustomBody = true;
        }else{
            showEmailTemplateSelector = true;
            showEmailTemplate = isPreviewed;
            showEmailCustomBody = false;
        }
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to preview email template by merging fields, BrandTemplate (HTML letterhead) and body
    #############Change Log#############
    Modified by     Version     Change Date
    Pawel Chrzanowski   1.1     28/04/2017   modified to give Case Web Email priority over Contact Email
    ****************************************************************************************/
    public void previewEmailTemplate(){
        List<Case> lstCases = [SELECT CaseNumber, SuppliedEmail, Contact.FirstName, Contact.LastName, Contact.Email FROM Case WHERE Id = :selectedCases[0].Id];
        if(lstCases.isEmpty()) return;

        exampleCaseNumber = (String)lstCases[0].CaseNumber;
        showEmailTemplate = true;
        isPreviewed = true;

        Messaging.SingleEmailMessage dummyEmailMsg = new Messaging.SingleEmailMessage();
        dummyEmailMsg.setSaveAsActivity(false);
        dummyEmailMsg.setTemplateId(selectedTemplate);

        //send dummy email and rollback to populate merge fields
        Savepoint sp = Database.setSavepoint();

            Account dummyAcct = new Account(Name = 'dummy account');
            insert dummyAcct;

            Contact dummyContact = new Contact(AccountId = dummyAcct.Id);
            dummyContact.FirstName = lstCases[0].Contact.FirstName;
            dummyContact.LastName = lstCases[0].Contact.LastName;
            dummyContact.Email = String.isNotBlank(lstCases[0].SuppliedEmail) ? lstCases[0].SuppliedEmail : lstCases[0].Contact.Email;
            insert dummyContact;

            dummyEmailMsg.setTargetObjectId(dummyContact.Id);
            dummyEmailMsg.setWhatId(selectedCases[0].Id);
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{dummyEmailMsg});
            }

        Database.rollback(sp);

        emailMsg.Subject = dummyEmailMsg.getSubject();
        emailMsg.TextBody = dummyEmailMsg.getPlainTextBody();
        emailHTMLBody = dummyEmailMsg.getHtmlBody();
    }

    /*************************************************************************************** 
    Developer - Pawel Chrzanowski
    Date - 16/08/2016
    Version - 1.0 
    Function - method to send emails
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public void sendEmails(){
        if(selectedEmailBodyType == EMAIL_BODY_CUSTOM && (String.isBlank(emailCustomSubject) || String.isBlank(emailCustomBody))){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Case_Send_Email_No_Subject_Body));
            return;
        }

        System.enqueueJob(new CaseMassEmailQueueable(selectedCases, selectedOrgEmail, selectedEmailBodyType, emailCustomSubject, emailCustomBody, selectedTemplate, null, null, null));
        isEmailSent = true;
    }



    /**
    * @author Pawel Chrzanowski
    * @date 21/01/2016
    * @description  CaseSearchHelper inner class - helper class that wraps Cases and Checkboxes
    #############Change Log#############
    Modified by        Version     Change Date
    Pawel Chrzanowski  1.1	       02/02/2016
	Pawel Chrzanowski  1.2         25/04/2017  Added Detail 4
    **/    
	public class CaseSearchHelper implements Comparable{
		public Boolean isChecked{get;set;}
		public Id id{get;set;}
		public String caseNumber{get;set;}
		public String contactName{get;set;}
		public String status{get;set;}
        public String createdDateTimeStamp{get;set;}
        public String createdDateFormatted{get;set;}
		public String reason{get;set;}
		public String typeOfIssue{get;set;}
		public String digitalDetails{get;set;}
        public String digitalDetails2{get;set;}
		public String digitalDetails3{get;set;}
		public String subject{get;set;}
		public String description{get;set;}

		/*************************************************************************************** 
		Developer - Pawel Chrzanowski
		Date - 02/02/2016
		Version - 1.0 
		Function - constructor
		#############Change Log#############
		Modified by        Version     Change Date
		Pawel Chrzanowski  1.1         25/04/2017  Added Detail 4
		****************************************************************************************/
		public CaseSearchHelper(Boolean b, Id cid, String cnumber, String cname, String s, Datetime crd, String r, String t, String d, String d2, String d3, String sub, String dsc){
			isChecked = b;
			id = cid;
			caseNumber = cnumber;
			contactName = cname;
			status = s;
            createdDateTimeStamp = String.valueOf(crd.getTime()/1000);
            createdDateFormatted = crd.format('dd/MM/yyyy HH:mm');
			reason = r;
			typeOfIssue = t;
			digitalDetails = d;
            digitalDetails2 = d2;
			digitalDetails3 = d3;
			subject = sub;
			if(String.isNotBlank(dsc)){
				Integer firstSpaceIndex = (dsc.indexOf(' ', DESCRIPTION_LIMIT) < 0) ? DESCRIPTION_LIMIT : dsc.indexOf(' ', DESCRIPTION_LIMIT);
				description = (dsc.length() > DESCRIPTION_LIMIT) ? dsc.substring(0, firstSpaceIndex) : dsc;
                if(description.length() > DESCRIPTION_LIMIT + DESCRIPTION_LIMIT_BUFFER){
                    description = description.substring(0, DESCRIPTION_LIMIT);
                }
			}
		}

		/*************************************************************************************** 
		Developer - Pawel Chrzanowski
		Date - 02/02/2016
		Version - 1.0 
		Function - method to implement custom list sorting from Comparable interface
		#############Change Log#############
		Modified by        Version     Change Date
		Pawel Chrzanowski  1.1         25/04/2017  Added Detail 4
		****************************************************************************************/
		public Integer compareTo(Object objToCompare){
			CaseSearchHelper compareIt = (CaseSearchHelper) objToCompare;

			if(CaseMassAmendmentController.staticSortBy == 'caseNumber'){
				if(caseNumber > compareIt.caseNumber){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else {
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'contactName'){
				if(contactName > compareIt.contactName){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(contactName < compareIt.contactName){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'status'){
				if(status > compareIt.status){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(status < compareIt.status){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'createdDate'){
				if(createdDateTimeStamp > compareIt.createdDateTimeStamp){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(createdDateTimeStamp < compareIt.createdDateTimeStamp){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'reason'){
				if(reason > compareIt.reason){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(reason < compareIt.reason){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'typeOfIssue'){
				if(typeOfIssue > compareIt.typeOfIssue){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(typeOfIssue < compareIt.typeOfIssue){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'digitalDetails'){
				if(digitalDetails > compareIt.digitalDetails){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(digitalDetails < compareIt.digitalDetails){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'digitalDetails2'){
				if(digitalDetails2 > compareIt.digitalDetails2){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(digitalDetails2 < compareIt.digitalDetails2){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
            } else if(CaseMassAmendmentController.staticSortBy == 'digitalDetails3'){
                if(digitalDetails3 > compareIt.digitalDetails3){
                    return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
                } else if(digitalDetails3 < compareIt.digitalDetails3){
                    return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
                } else {
                    return 0;
                }
			} else if(CaseMassAmendmentController.staticSortBy == 'subject'){
				if(subject > compareIt.subject){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(subject < compareIt.subject){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			} else if(CaseMassAmendmentController.staticSortBy == 'description'){
				if(description > compareIt.description){
					return CaseMassAmendmentController.staticSortAscending ? 1 : -1;
				} else if(description < compareIt.description){
					return CaseMassAmendmentController.staticSortAscending ? -1 : 1;
				} else {
					return 0;
				}
			}
			return 0;
		}
	}

}