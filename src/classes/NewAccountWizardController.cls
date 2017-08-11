/**
* Author:       Sally ElGhoul (Tquila)
* Date:         17/06/2015
* Description:  this class is the cnotroller of the page NewAccountWizard
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Szewczyk   28/01/2016   - changed ValidAccountData()
* Michal Kwika      17/02/2016   - changed redirection approach
* Michal Kwika      18/02/2016   - returnURL defect fix
* Wiktor Czykin     03/2016      - modified isValidSearchCriteria(), minor clean-up
* Gavin Palmer      02/06/2016   - added instantiation of samAccount to constructor
* Michal Szewczyk   20/06/2016   - changed findAccount()
* Gavin Palmer      22/06/2016   - added bulk logger functionality for callouts in class
* Pawel Chrzanowski 22/06/2016   - added Lite Accounts support
* Pawel Chrzanowski 10/04/2017   - added Marketing Preferences
* Wiktor Czykin     16/05/2017   - replaced constant with label
* Wiktor Czykin     19/07/2017   - modified getCountries()
**/
public class NewAccountWizardController {
    //Properties
    public String        strSearchSurname           {get; set;}
    public String        strSearchPostCode          {get; set;}
    public String        strSearchEmail             {get; set;}
    public String        strSearchTsNumber          {get; set;}
    public String        strSelectedAccountId       {get; set;}
    public Account       newAccountObj              {get; set;}
    public Contact       newContactObj              {get; set;}
    public Boolean       isShowResults              {get; set;}
    public Boolean       isNoResultFound            {get; set;}
    public Boolean       isShowNewAccountSection    {get; set;}
    public Boolean       isDigitalProductSelected   {get; set;}
    public Boolean       isAccountOptIn             {get; set;}
    public Boolean       tmgPromoEmail              {get; set;}
    public Boolean       tmgPromoPhone              {get; set;}
    public Boolean       tmgPromoPost               {get; set;}
    public Boolean       tmgPromoSms                {get; set;}
    public String        chosenNonRegId             {get; set;}

    //New property to sort it using character
    public String        sortCharacter              {get; set;}
    public List<String>  lAlphaList                 {get; set;}
    public Boolean       isNoResultAfterFilter      {get; set;} //property to show filter message
    public Integer       numberOfAccountsPerPage    {get; set;} //property to set number of Acc per page
    public Integer       noOfRecords                {get; set;} //number of found registrants
    public Integer       noOfOtherRecords           {get; set;} //number of found NONregistrants
    public ApexPages.StandardSetController setCon   {get; set;} //setCon for registrants
    public ApexPages.StandardSetController nonCon   {get; set;} //setCon for NONregistrants

    //notification from SAM
    private Map <Integer, String> mResponseWithId   {get; set;}
    public Account samAccount                       {get; set;}
    public Boolean checkEmailInSam                  {get; set;}
    public Boolean showNotifications                {get; set;}
    public String tempSamEmail                      {get; set;}

    //maximum number of records per page and get from query
    public static final Integer MAXRECPERPAGE = 20;
    public static final Integer MAXRECFROMSOQL= 10000;

    //Lite Accounts
    public Boolean showSearchPanel {get;set;}
    public String accountFormTitle {get;set;}
    public String liteAccountId {get;set;}
    public String liteAccountEmail {get;set;}

    //get the registrant record type id
    public String RegistrantRecordTypeId {
        get{
            return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
        }
    }

    //get the digital subscriber record type id
    public String  DigitalSubscriberRecordTypeId {
        get{
            return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_DIGITAL_RECORD_TYPE_NAME, Account.class.getName());
        }
    }

    //get the individual subscriber record type id
    public String  IndividualSubscriberRecordTypeId {
        get{
            return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAME, Account.class.getName());
        }
    }

    //get if the postal code is required
    public Boolean isPostalCodeRequired {
        get{
            if (newAccountObj.PersonMailingCountry == constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
                return true;
            }
            return false;
        } set;
    }

    //get if the Title is required
    public Boolean isTitleRequired {
        get{
            if (newAccountObj.PersonMailingCountry == constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
                return true;
            }
            return false;
        } set;
    }

    //get if State is required
    public Boolean isStateRequired {
        get{
            if (newAccountObj.PersonMailingCountry == constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || newAccountObj.PersonMailingCountry == constants.COUNTRY_CANADA_TWO_LETTERS_CODE) {
                return true;
            }
            return false;
        } set;
    }

    /***************************************************************************************
     Developer   Sally ElGhoul (Tquila)
     Date        22/06/2015
     Function    Constructor
     ******************* Change Log *******************
     Modified by         Version     Change Date
     Gavin Palmer        1.1         02/06/2016 - added instantiation of samAccount to stop null pointers from happening
     Pawel Chrzanowski   1.2         22/06/2016 - added Lite Accounts support
     ****************************************************************************************/
    public NewAccountWizardController(){
        isAccountOptIn = false;
        showSearchPanel = true;
        accountFormTitle = Label.Create_New_Account;

        //Lite Accounts
        if(ApexPages.currentPage().getParameters().containskey('id')){
            liteAccountId = ApexPages.currentPage().getParameters().get('id');
            List<Account> lstAcc = [select Salutation, Title__c, FirstName, LastName, DateofBirth__c, PersonEmail, PersonMailingPostalCode, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingCountry, PersonMobilePhone, PersonHomePhone, isNewAccountOptIn__c from Account where Digital_Status__c = :Constants.LITE_ACCOUNT_DIGITAL_STATUS and Id = :liteAccountId];
            if(!lstAcc.isEmpty()){
                showSearchPanel = false;
                accountFormTitle = 'Upgrade Lite Account';
                liteAccountEmail = lstAcc[0].PersonEmail;
                newAccountObj = lstAcc[0];
            }
        }

        //Initialize the Account
        if (newAccountObj == null) {
            newAccountObj = new Account();
            newAccountObj.RecordTypeId = RegistrantRecordTypeId;
            newAccountObj.PersonMailingCountry = Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE;
        }

        if(newAccountObj.isNewAccountOptIn__c){
            isAccountOptIn = true;
        }

        //initialize the Contact object
        //I am using the Contact object because the input field didn't appear on the page for the salutation and first name when I used the Account
        if (newContactObj == null) {
            newContactObj = new Contact();
        }

        newContactObj.Salutation = newAccountObj.Salutation;
        newContactObj.FirstName  = newAccountObj.FirstName;
        newContactObj.LastName   = newAccountObj.LastName;

        //Initialize to hide the search results section
        if (isShowResults == null) {
            isShowResults = false;
        }

        //Initialize to hide the message that no results was found
        if (isNoResultFound == null) {
            isNoResultFound = false;
        }

        //initialize to hide the new Account section
        if (isShowNewAccountSection == null) {
            isShowNewAccountSection = false;
        }

        //Initialize to hide the search section and show the product selection screen
        if (isDigitalProductSelected == null) {
            isDigitalProductSelected = false;
        }
        //initialize alphabet list
        this.lAlphaList = new list<String> {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
                                            'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'All'
                                           };

        //initialize filter value (at the start we are not filtering)
        this.isNoResultAfterFilter = false;
        //we are checking email in SAM
        this.checkEmailInSam = Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_SAM_KNOWN_USER_CONVERSION).value__c);
        this.showNotifications = false;

        samAccount = new Account();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called to search for accounts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.05       14/07/2015
    Michal Kwika        1.1        13/08/2015
    Michal Kwika        1.2        24/09/2015
    Michal Kwika        1.3        17/11/2015
    Michal Szewczyk     1.4        21/06/2016
    Gavin Palmer        1.5        22/06/2016 // added bulk logger functionality for the callouts
    ****************************************************************************************/
    public PageReference findAccount() {
        this.showNotifications = false;
        try {
            //check first that the search criteria is valid
            if (this.isValidSearchCriteria()) {
                List<Account> lstRetAccounts = AccountUtility.findAccounts(strSearchSurname, strSearchPostCode, strSearchEmail, strSearchTsNumber);
                //check is the list size is greater than zero so there search criteria returned values
                if (lstRetAccounts != null && lstRetAccounts.size() > 0) {
                    //Show the result outputPanel and hide the output pael of the no result message
                    isShowResults = true;
                    isNoResultFound = false;
                    this.sortCharacter = '';

                    //Added limit of query : max 10 000 records
                    if(lstRetAccounts.size() > MAXRECFROMSOQL){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.AutoSearchTooManyRecordsInfo));
                        isShowResults = false;
                        isNoResultFound = false;
                    } else {
                        //set registrants and nonregistrants for pagination
                        setPaginationOnSite();
                    }

                    //Default the new Account surname if not empty in the search
                    if (!String.isEmpty(strSearchSurname)) {
                        newContactObj.LastName = strSearchSurname.trim();
                    } else {
                        newContactObj.LastName = '';
                    }
                } else { //no Account found
                    //To Copy PostCode into form if you are searching by surname/postcode
                    if (!String.isEmpty(strSearchPostCode)) {
                        newAccountObj.PersonMailingPostalCode = strSearchPostCode.trim();
                    } else {
                        newAccountObj.PersonMailingPostalCode = '';
                    }

                    //Default the new Account surname if not empty in the search
                    if (!String.isEmpty(strSearchSurname)) {
                        newContactObj.LastName = strSearchSurname.trim();
                    } else {
                        newContactObj.LastName = '';
                    }

                    //default the new Account email if not empty in the search
                    if (!String.isEmpty(strSearchEmail)) {
                        CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
                        calloutUtility.bUseBulkLogging = true;

                        mResponseWithId = new Map <Integer, String>();
                        if (!Test.isRunningTest() && this.checkEmailInSam) {
                            Boolean callCoreApi=Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).value__c);
                            if(callCoreApi){
                                mResponseWithId = calloutUtility.getNumOfEmailsInSAM(strSearchEmail);
                                System.debug('### LOG map from SAM: ' + mResponseWithId);
                            }
                        }
                        // check value - if counter is set to -1; then there is no connection to SAM
                        if (mResponseWithId.containsKey(0)) {
                            //we will get only first found Account in SAM
                            samAccount = calloutUtility.getProfileFromSAM(mResponseWithId.get(0));
                            setNotificationsOnSite();
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Email_ExistsInSAM_Question));
                            //return null;
                        } else {
                            newAccountObj.PersonEmail = strSearchEmail.trim();
                        }
                        calloutUtility.saveLogBuffer();
                    }else {
                        newAccountObj.PersonEmail = '';
                    }

                    //Hide the results outputpanel
                    //Show the no results message
                    isShowResults = false;
                    isNoResultFound = true;
                }
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error));
        }
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called to check that the search criteria is valid
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         07/03/2016 //changed isEmpty to isBlank
    ****************************************************************************************/
    private Boolean isValidSearchCriteria() {

        //at least one search criteria should be entered
        //either suname  OR Post code OR Email OR Ts Number
        if (String.isBlank(strSearchSurname) && String.isBlank(strSearchPostCode) && String.isBlank(strSearchEmail) && String.isBlank(strSearchTsNumber)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Account_Search_Criteria));
            return false;
        }

        //validate that email address is in correct format
        if (!String.isBlank(strSearchEmail)) {
            strSearchEmail = strSearchEmail.trim();
            //check the email format
            Pattern emailPattern = Pattern.compile(Constants.REG_UPDATED_EMAIL_FORMAT);
            Matcher emailMatcher = emailPattern.matcher(strSearchEmail);

            if (!emailMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Format_Error));
                return null;
            }
        }

        //if surname is entered make sure that it is only characters
        if (!String.isBlank(strSearchSurname)) {
            strSearchSurname = strSearchSurname.trim();
            // Checking that LastName is only Letters
            Pattern MyPattern = Pattern.compile(Constants.REG_EXPRESSION_LETTERS_ONLY);
            Matcher MyMatcher = MyPattern.matcher(strSearchSurname);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Surname_Only_Letters));
                return null;
            }
        }

        if(String.isNotBlank(this.strSearchPostCode)){
            this.strSearchPostCode = this.strSearchPostCode.trim();
        }
        if(String.isNotBlank(this.strSearchTsNumber)){
            this.strSearchTsNumber = this.strSearchTsNumber.trim();
        }
        return true;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called when the user press on add new Account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference ShowNewAccountSection() {
        //show the new Account section
        isShowNewAccountSection = true;

        //hide the search result section
        isShowResults = false;

        //hide the no accounts found message section
        isNoResultFound = false;
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called to save the new Account
    ******************* Change Log *******************
    Modified by         Version     Change Date
	Pawel Chrzanowski   1.1         10/04/2017 - added Marketing Preferences
    ****************************************************************************************/
    public PageReference SaveNewAccount() {
        try{
            if (ValidAccountData()) {
                newAccountObj.Salutation = newContactObj.Salutation;
                newAccountObj.FirstName  = newContactObj.FirstName;
                newAccountObj.LastName   = newContactObj.LastName;

                newAccountObj.isNewAccountOptIn__c = isAccountOptIn;
                newAccountObj.TMG_Promo_Email__c = tmgPromoEmail == true ? 1 : 0;
                newAccountObj.TMG_Promo_Phone__c = tmgPromoPhone == true ? 1 : 0;
                newAccountObj.TMG_Promo_Post__c = tmgPromoPost == true ? 1 : 0;
                newAccountObj.TMG_Promo_SMS__c = tmgPromoSMS == true ? 1 : 0;

                upsert newAccountObj;

                //redirect the user to the quote wizard creation page
                strSelectedAccountId = newAccountObj.id;
                return redirectManageSubscription();
            }
        }catch(exception ex){
            system.debug(ex);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error); ApexPages.addMessage(myMsg);
        }
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is to validate that the user entered all the required fields of the new Account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    MIchal Kwika        1.1         24/07/2015
    Michal Szewczyk     1.2         28/01/2016
    Gavin Palmer        1.3        22/06/2016 // added bulk logger functionality for the callouts
    ****************************************************************************************/
    private Boolean ValidAccountData() {
        //don't show notifications
        this.showNotifications = false;
        //Check salutation
        if (String.isempty(newContactObj.Salutation) && String.isempty(newAccountObj.title__c) && newAccountObj.PersonMailingCountry == constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            return false;
        }
        //Check salutation and Given Title
        if (!String.isempty(newContactObj.Salutation) && !String.isempty(newAccountObj.title__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            return false;
        }

        //check FirstName
        if (String.isempty(newContactObj.FirstName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Empty_First_Name_Error));
            return false;
        }

        //check Last Name
        if (String.isempty(newContactObj.LastName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Last_Name_Error_Message));
            return false;
        }
        if (!String.isempty(newContactObj.LastName.trim()) && newContactObj.LastName.trim().length() < 2 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Account_LastName_Small));
            return false;
        }


        //Check Last Name format
        if (!String.isempty(newContactObj.LastName)) {
            // Checking that LastName is only Letters
            Pattern MyPattern = Pattern.compile(Constants.REG_EXPRESSION_LETTERS_ONLY);
            Matcher MyMatcher = MyPattern.matcher(newContactObj.LastName);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Last_Name_Format));
                return false;
            }
        }

        //Check Email
        if (String.isEmpty(newAccountObj.PersonEmail)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Email));
            return false;
        }

        //---Validation on email Account - check if there is any other Account with same email address
        if(!String.isEmpty(newAccountObj.PersonEmail) && (newAccountObj.PersonEmail != liteAccountEmail)){
            List <Account> lAccountsWithGivenEmail = AccountUtility.findAccounts('', '', newAccountObj.PersonEmail, '');
            if (lAccountsWithGivenEmail.size() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Other_Account_Exist));
                return false;
            }

            //check also if this email address exists in SAM
            if(tempSamEmail!=newAccountObj.PersonEmail){
                this.checkEmailInSam = Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_SAM_KNOWN_USER_CONVERSION).value__c);
            }
            Map <Integer, String> mResponseWithId = new Map <Integer, String>();
            CoreAPICalloutUtility calloutUtility = new CoreAPICalloutUtility();
            calloutUtility.bUseBulkLogging = true;
            if (!Test.isRunningTest() && this.checkEmailInSam) {
                Boolean callCoreApi=Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).value__c);
                if(callCoreApi){
                    mResponseWithId = calloutUtility.getNumOfEmailsInSAM(newAccountObj.PersonEmail);
                }
            }
            // check value - if counter is set to -1; then there is no connection to SAM
            if (mResponseWithId.containsKey(0)) {
                setNotificationsOnSite();
                //we will get only first found Account in SAM
                samAccount = calloutUtility.getProfileFromSAM(mResponseWithId.get(0));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Email_ExistsInSAM_Question));
                return false;
            }else if(mResponseWithId.containsKey(-1)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Message));
                return false;
            }
            calloutUtility.saveLogBuffer();
        }

        //Check Mailing Street
        if (String.isempty(newAccountObj.PersonMailingStreet)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Mailing_Street));
            return false;
        }

        //Check City
        if (String.isempty(newAccountObj.PersonMailingCity)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Mailing_City));
            return false;
        }

        //Check Country
        if (String.isempty(newAccountObj.PersonMailingCountry)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Mailing_Country));
            return false;
        }

        //check that postal code is mandadory if the country is UK
        if ((String.isempty(newAccountObj.PersonMailingPostalCode)) && newAccountObj.PersonMailingCountry == constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Postal_Code));
            return false;
        }

        //check state as it should be mandatory if the country is US or Canada
        if ((String.isempty(newAccountObj.PersonMailingState)) && (newAccountObj.PersonMailingCountry == constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || newAccountObj.PersonMailingCountry == constants.COUNTRY_CANADA_TWO_LETTERS_CODE)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.State_Error_Message));
            return false;
        }

        //Michal Kwika SUB-672 27/08/2015
        //if the country is UK validate post code
        if ((!String.isempty(newAccountObj.PersonMailingPostalCode)) && (newAccountObj.PersonMailingCountry == constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE)) {
            // Checking the format of British post code
            Pattern MyPattern = Pattern.compile(Constants.REG_GB_POSTCODE_FORMAT);
            Matcher MyMatcher = MyPattern.matcher(newAccountObj.PersonMailingPostalCode);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Post_Code_Invalid));
                return false;
            }
        }

        //validate the phone field formats
        //They should start with Zero and should only contain numbers
        Pattern phonePattern = Pattern.compile('[0-9\\s?]+');

        //Validate the Mobile Phone
        if(!String.isempty(newAccountObj.PersonMobilePhone)){
        	Matcher phoneMatcher = phonePattern.matcher(newAccountObj.PersonMobilePhone);
        	if(!newAccountObj.PersonMobilePhone.startsWith('0') || !phoneMatcher.matches()){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.New_Account_Wizard_Mobile_Phone_Format_Error_Message));
                return false;
        	}

        }

        //Validate the person Home Phone format
        if(!String.isempty(newAccountObj.PersonHomePhone)){
        	Matcher phoneMatcher = phonePattern.matcher(newAccountObj.PersonHomePhone);
        	if(!newAccountObj.PersonHomePhone.startsWith('0') || !phoneMatcher.matches()){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.New_Account_Wizard_Home_Phone_Format_Error_Message));
                return false;
        	}

        }
        return true;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called to get the list of countries
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       18/07/2017  //moved the actual implementation to common GlobalQueries class
    ****************************************************************************************/
    public List<SelectOption> getCountries() {
        return GlobalQueries.getCountries(true);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    this function is called to get the list of countries
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<SelectOption> getStates() {
        List<SelectOption> liOptions = new List<SelectOption>();
        liOptions.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
        for (State_Codes__c stateObj : [SELECT State_Name__c, Name FROM State_Codes__c where Country_Code__c = :newAccountObj.PersonMailingCountry ORDER BY Display_Order__c, State_Name__c ASC]) {
            liOptions.add(new SelectOption(stateObj.Name, stateObj.State_Name__c));
        }
        return liOptions;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        07/07/2015
    Function    this function is called to redict the user to the new Account wizard page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference redirectDigitalProduct() {
        isDigitalProductSelected = true;
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        07/07/2015
    Function    this function is called to redict the user to the print flow
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference redirectPrintProduct() {
        PageReference pageRef = Page.SubscriptionCallCentreInBoundTMG;
        pageRef.setRedirect(true);
        return pageRef;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        08/07/2015
    Function    this function is called to redict the user to product selection screen
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference redirectProductSelectionScreen() {
        isDigitalProductSelected = false;
        return null;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        08/07/2015
    Function    this function is called to redict the user to manage subscription screen
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         17/02/2016 - changed Redirect approach
    Michal Kwika        1.2         18/02/2016 - returnURL defect fix
    ****************************************************************************************/
    public PageReference redirectManageSubscription() {
        String retUrl = '/'+ this.strSelectedAccountId;

        PageReference PageRef = Page.zqu__CreateQuote;
        PageRef.getParameters().put('crmAccountId', strSelectedAccountId);
        PageRef.getParameters().put('quoteType', Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
        PageRef.getParameters().put('retUrl', retUrl);
        PageRef.getParameters().put('stepNumber', '1');
        pageRef.setredirect(true);
        return PageRef;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    this function is called to refresh the UI
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1       17/11/2015
    ****************************************************************************************/
    public PageReference RefreshUI() {
        newAccountObj.PersonMailingState = '';
        this.checkEmailInSam = Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_SAM_KNOWN_USER_CONVERSION).value__c);
        this.showNotifications = false;
        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        12/08/2015
    Function    this function is called to get sorted list of accounts based on char
                (Sorting by FirstName)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         25/08/2015
    ****************************************************************************************/
    public void getSortedAccountsByChar() {
        if (this.sortCharacter == null) {
            return;
        }

        //reset pagination
        setPaginationOnSite();

        //set variables
        if (setCon.getRecords().size() > 0 || nonCon.getRecords().size() > 0) {
            this.isNoResultAfterFilter = false;
        } else {
            this.isNoResultAfterFilter = true;
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        12/08/2015
    Function    helper method for getting sorted registrants/nonregistrants
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<Account> sortListAccBasedOnFirstName(List <Account> lAccountsToBeSorted) {
        //Temporary list to save accounts for a while
        List <Account> lTemporaryAccounts = new List<Account>();

        //get registrant accounts first and sort by char
        if (lAccountsToBeSorted != null && lAccountsToBeSorted.size() > 0) {
            for (Account regAcc : lAccountsToBeSorted) {
                if (regAcc.FirstName.substring(0, 1).equalsIgnoreCase(this.sortCharacter)) {
                    lTemporaryAccounts.add(regAcc);
                }
            }

            //sort them and assign to registrants
            lTemporaryAccounts.sort();
            lAccountsToBeSorted = lTemporaryAccounts;
        }

        return lAccountsToBeSorted;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        13/08/2015
    Function    invoke all methods needed to setPgination
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void setPaginationOnSite() {
        //init set controllers
        setPaginationController();
        setPaginationControllerOthers();
        //populate buffer lists based on prepared set controllers
        getRegistrants();
        getNonRegistrants();

        this.setCon.setPageNumber(1);
        this.nonCon.setPageNumber(1);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        13/08/2015
    Function    Initialize setController for Registrants
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void setPaginationController() {
        numberOfAccountsPerPage = MAXRECPERPAGE;
        setCon = new ApexPages.StandardSetController(Database.getQueryLocator(AccountUtility.createSOQLofAcc(strSearchSurname, strSearchPostCode, strSearchEmail, strSearchTsNumber, true, this.sortCharacter)));
        setCon.setPageSize(numberOfAccountsPerPage);
        noOfRecords = setCon.getResultSize();
        System.debug('xxx:noOfRecordAfterRequery:'+noOfRecords);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        13/08/2015
    Function    Initialize setController for NonRegistrants
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void setPaginationControllerOthers() {
        numberOfAccountsPerPage = MAXRECPERPAGE;
        this.nonCon = new ApexPages.StandardSetController(Database.getQueryLocator(AccountUtility.createSOQLofAcc(strSearchSurname, strSearchPostCode, strSearchEmail, strSearchTsNumber, false, this.sortCharacter)));
        this.nonCon.setPageSize(numberOfAccountsPerPage);
        this.noOfOtherRecords = this.nonCon.getResultSize();
        System.debug('xxx:noOfRecordAfterRequery other:'+noOfOtherRecords);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        13/08/2015
    Function    getRegistrants - new method to populate table
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<Account> getRegistrants() {
        List<Account> lTemp = new List<Account>();
        for (Account a : (List<Account>) setCon.getRecords()) {
            lTemp.add(a);
        }
        return lTemp;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        13/08/2015
    Function    getNonRegistrants - new method to populate table for nonregistrants
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<Account> getNonRegistrants() {
        List<Account> lTemp = new List<Account>();
        for (Account a : (List<Account>) this.nonCon.getRecords()) {
            lTemp.add(a);
        }
        return lTemp;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        11/11/2015
    Function    method used to redirect user to conversion page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         18/02/2016 - improvement to redireciton
    ****************************************************************************************/
    public PageReference goToAccountConversion(){
        PageReference pageRef = Page.Account_ConvertToRegistrant;
        pageRef.getParameters().put('id', chosenNonRegId);
        pageRef.setredirect(true);
        return pageRef;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        17/11/2015
    Function    set new Account based on data from SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference assignSAMaccountToNewAccount(){
        //clone Account
        System.debug('SAM ACCOUNT before cloning: ' + samAccount);
        newAccountObj = samAccount;
        //set rt to registrant
        newAccountObj.RecordTypeId = this.RegistrantRecordTypeId;
        //insert also form details
        newContactObj.FirstName = samAccount.FirstName;
        newContactObj.LastName = (String)samAccount.LastName;
        newContactObj.Salutation = samAccount.Salutation;

        if(String.isEmpty(newAccountObj.PersonMailingCountry )){
            newAccountObj.PersonMailingCountry = Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE;
        }
        //save current email which user entered and don't check next time
        tempSamEmail = samAccount.PersonEmail;
        this.checkEmailInSam = false;
        this.showNotifications = false;

        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        17/11/2015
    Function    set notifications
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public void setNotificationsOnSite(){
         //Init notification options for the notification component
        this.showNotifications = true;
    }
}
