/**
* Author:       Michal Kwika (Accenture)
* Date:         11/11/2015
* Description:  this class is the cnotroller of the page NewAccountWizard
* ******************* Change Log *******************
* Modified by   Change Date     Version
* Michal Kwika  15/01/2016      1.1
* Michal Szewczyk  25/01/2016      1.2 - added birthdate
* Michal Kwika   17/02/2016     1.3 - changed redirection approach
* Michal Kwika   18/02/2016     1.4 - returnURL defect fix
* Michal Kwika   24/02/2016     1.5 - added new fields to query Account
* Wiktor Czykin  08/03/2016     1.6 - modified isMinimumDataNeededSet()
* Vishant Shah   11/08/2017  added subscription origin.
**/
public class Account_ConvertToRegistrantCtrl {

    public Account newAccountObj        {get; set;}
    public Boolean isAccountOptIn       {get; set;}
    public String strSelectedAccountId  {get; set;}
    public Boolean showNewAccoountForm  {get; set;}
    private Id tmgWebApiProfileId       {get; set;}

    //get the registrant record type id
    public String registrantRecordTypeId {
        get{
            return RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
        }
    }
    //get if the Title is required
    public Boolean isTitleRequired {
        get{
            if (newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
                return true;
            }
            return false;
        } set;
    }

    //get if State is required
    public Boolean isStateRequired {
        get{
            if (newAccountObj.PersonMailingCountry == Constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || newAccountObj.PersonMailingCountry == Constants.COUNTRY_CANADA_TWO_LETTERS_CODE) {
                return true;
            }
            return false;
        } set;
    }

    //get if the postal code is required
    public Boolean isPostalCodeRequired {
        get{
            if (newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
                return true;
            }
            return false;
        } set;
    }


    /***************************************************************************************
     Developer   Michal Kwika (Accenture)
     Date        22/10/2015
     Function    Constructor
     ******************* Change Log *******************
     Modified by         Version     Change Date
     Michal Kwika        1.1         17/11/2015
     Michal Kwika        1.2         15/01/2016
     Michal Szewczyk     1.3         25/01/2016
     Wiktor Czykin       1.4         11/03/2016 //modified handling of the hasAccountActiveSub() check
     ****************************************************************************************/
    public Account_ConvertToRegistrantCtrl() {
        //show the form
        this.showNewAccoountForm = true;
        //check if there is a DD parameter set
        if (ApexPages.currentPage().getParameters().containskey('id')) {
            this.strSelectedAccountId = ApexPages.currentPage().getParameters().get('id');
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Account));
            return;
        }

        if (!String.isEmpty(this.strSelectedAccountId) ) {
            List <Account> lTemps = [SELECT Id, 
                                            isPersonAccount, 
                                            FirstName, 
                                            LastName, 
                                            PersonMailingCountry, 
                                            Salutation, 
                                            Title__c, 
                                            PersonEmail, 
                                            PersonMailingPostalCode, 
                                            PersonMailingStreet, 
                                            PersonMailingCity, 
                                            PersonMailingState, 
                                            PersonMobilePhone, 
                                            PersonHomePhone, 
                                            RecordType.Name,
                                            RecordTypeId,
                                            DateofBirth__c, 
                                            Subscriber_Digital_Status__c, 
                                            Subscription_Status__c
                                     FROM Account 
                                     WHERE Id = :strSelectedAccountId 
                                     AND RecordTypeId != :registrantRecordTypeId LIMIT 1];
            if (!lTemps.isEmpty()) {
                this.newAccountObj = lTemps.get(0);
            }
        }

        //check the account
        if (newAccountObj == null) {
            this.showNewAccoountForm = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Convert_Account_Error_IsRegistrant));
            return;
        }

        //get status type based on account data
        String sStatusResult = AccountUtility.hasAccountActiveSub(newAccountObj);

        if (String.isBlank(sStatusResult) || sStatusResult == AccountUtility.STATUS_ACTIVE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Outbound_Digital_Acquisition_Account_Has_Active_Sub));
            this.showNewAccoountForm = false;
            return;
        }

        newAccountObj.RecordTypeId = this.registrantRecordTypeId;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        7/11/2015
    Function    this function is called to refresh the UI
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public PageReference RefreshUI() {
        newAccountObj.PersonMailingState = '';
        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        7/11/2015
    Function    this function is called to redirect the user to manage subscription screen
    ******************* Change Log *******************
    Modified by         Change Date
    Michal Kwika        17/02/2016
    Michal Kwika        18/02/2016 - returnURL defect fix
    Vishant Shah        11/08/2017  //added subscription origin.
    ****************************************************************************************/
    public PageReference redirectManageSubscription() {
        String retUrl = '/'+ this.strSelectedAccountId;

        PageReference PageRef = Page.zqu__CreateQuote;
        PageRef.getParameters().put('crmAccountId', strSelectedAccountId);
        PageRef.getParameters().put('quoteType', Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
        PageRef.getParameters().put('retUrl', retUrl);
        PageRef.getParameters().put('stepNumber', '1');

        if (ApexPages.currentPage().getParameters().containsKey('origin')) {
            String origin = ApexPages.currentPage().getParameters().get('origin');
            PageRef.getParameters().put('origin', origin);            
        }

        pageRef.setRedirect(true);
        return PageRef;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        7/11/2015
    Function    this function is called to get the list of countries
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public List<SelectOption> getCountries() {
        List<SelectOption> liOptions = new List<SelectOption>();
        liOptions.add(new SelectOption('', Constants.NONE_PICKLIST_VALUE));
        for (Country_Codes__c country : [SELECT name, Country_Name__c FROM Country_Codes__c ORDER BY Display_Order__c, Country_Name__c ASC]) {
            liOptions.add(new SelectOption(country.name, country.Country_Name__c));
        }
        return liOptions;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        7/11/2015
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
    Developer   Michal Kwika (Accenture)
    Date        7/11/2015
    Function    this function is called to save the new account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         17/11/2015
    ****************************************************************************************/
    public PageReference saveNewAccount() {
        try {
            //first we should validate that the user entered all the mandatory fields
            if(validAccountData()) {
                //change RT to Registrant and set that this Account was converted
                newAccountObj.Converted_Account__c = newAccountObj.RecordType.Name;

                //if the opt in checkbox is checked we need to check the two marketing preferences of 2nd party (email and post)
                if (isAccountOptIn) {
                    newAccountObj.isNewAccountOptIn__c = true;
                }
                update newAccountObj;

                //insert Account intoSAM
                Boolean callCoreApi = Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).Value__c);
                if (callCoreApi) {
                    AccountUtility.setTMGwebAPIprofileId(this.tmgWebApiProfileId);
                    if (UserInfo.getProfileId() != this.tmgWebApiProfileId) {
                        CoreAPICalloutUtility.SendObjectEvent(Constants.NEW_RECORD_CREATED_ACTION_NAME, Account.class.getName(), newAccountObj.id);
                    }
                }
                //redirect the user to the quote wizard creation page
                strSelectedAccountId = newAccountObj.Id;
                return redirectManageSubscription();
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.General_Contact_administrator_error));
        }
        return null;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        11/11/2015
    Function    this function is to validate that the user entered all the required fields of the new account
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         15/01/2016
    ****************************************************************************************/
    private Boolean validAccountData() {

        if (isMinimumDataNeededSet()) {

            //---Validation on email Account - needed also for Convert Account
            if (String.isNotEmpty(newAccountObj.PersonEmail)) {
                if (AccountUtility.checkIfOtherAccountWithThisEmailExistsInSF(newAccountObj.Id, newAccountObj.PersonEmail)) {
                    AccountUtility.isValidEmptyString('', Label.Email_Invalid_Other_Account_Exist);
                    return false;
                }
            }
            /* THIS PART IS COMMENTED but need in future - check SAM also during conversion
            //check also if this email address exists in SAM]
            Integer emailCounterSAM;
            if (!Test.isRunningTest()) {
                Boolean callCoreApi = Boolean.valueof(Application_Settings__c.getInstance(Constants.FIRE_CORE_API_CALL_FOR_ACCOUNT_CREATION).value__c);
                if (callCoreApi) {
                    emailCounterSAM = CoreAPICalloutUtility.getNumOfEmailsInSAM(newAccountObj.PersonEmail);
                } else {
                    emailCounterSAM = 0;
                }
            }
            // check value - if counter is set to -1; then there is no connection to SAM
            if (emailCounterSAM == -1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Message));
                return false;
            } else if (emailCounterSAM > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Other_Account_Exist_In_SAM));
                return false;
            }
            }*/
        } else {

            return false;
        }

        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        11/11/2015
    Function    this function is to check whether account has all values needed to convert
                account to Registrant
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         15/01/2016
    Michal Szewczyk     1.2         28/01/2016
    Wiktor Czykin       1.3         08/03/2016  //changed isEmpty to isBlank
    ****************************************************************************************/
    private Boolean isMinimumDataNeededSet() {
        //Check salutation
        if (String.isBlank(newAccountObj.Salutation) && String.isBlank(newAccountObj.Title__c) && newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            return false;
        }
        //Check salutation and Given Title
        if (!String.isBlank(newAccountObj.Salutation) && !String.isBlank(newAccountObj.Title__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            return false;
        }
        //check FirstName
        if (String.isBlank(newAccountObj.FirstName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Empty_First_Name_Error));
            return false;
        }

        //check Last Name
        if (String.isBlank(newAccountObj.LastName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Last_Name_Error_Message));
            return false;
        }

        if (!String.isBlank(newAccountObj.LastName.trim()) && newAccountObj.LastName.trim().length() < 2 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Account_LastName_Small));
            return false;
        }


        //Check Last Name format
        if (!String.isBlank(newAccountObj.LastName)) {
            // Checking that LastName is only Letters
            Pattern MyPattern = Pattern.compile(Constants.REG_EXPRESSION_LETTERS_ONLY);
            Matcher MyMatcher = MyPattern.matcher(newAccountObj.LastName);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Last_Name_Format));
                return false;
            }
        }

        //Check Email
        if (String.isBlank(newAccountObj.PersonEmail)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Email));
            return false;
        }

        //Check Mailing Street
        if (String.isBlank(newAccountObj.PersonMailingStreet)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Mailing_Street));
            return false;
        }

        //Check City
        if (String.isBlank(newAccountObj.PersonMailingCity)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Mailing_City));
            return false;
        }

        //Check Country
        if (String.isBlank(newAccountObj.PersonMailingCountry)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Mailing_Country));
            return false;
        }

        //check that postal code is mandadory if the country is UK
        if ((String.isBlank(newAccountObj.PersonMailingPostalCode)) && newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Postal_Code));
            return false;
        }

        //check state as it should be mandatory if the country is US or Canada
        if ((String.isBlank(newAccountObj.PersonMailingState)) && (newAccountObj.PersonMailingCountry == Constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || newAccountObj.PersonMailingCountry == Constants.COUNTRY_CANADA_TWO_LETTERS_CODE)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.State_Error_Message));
            return false;
        }

        //if the country is UK validate post code
        if ((!String.isBlank(newAccountObj.PersonMailingPostalCode)) && (newAccountObj.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE)) {
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
        if (!String.isBlank(newAccountObj.PersonMobilePhone)) {
            Matcher phoneMatcher = phonePattern.matcher(newAccountObj.PersonMobilePhone);
            if (!newAccountObj.PersonMobilePhone.startsWith('0') || !phoneMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.New_Account_Wizard_Mobile_Phone_Format_Error_Message));
                return false;
            }

        }

        //Validate the person Home Phone format
        if (!String.isBlank(newAccountObj.PersonHomePhone)) {
            Matcher phoneMatcher = phonePattern.matcher(newAccountObj.PersonHomePhone);
            if (!newAccountObj.PersonHomePhone.startsWith('0') || !phoneMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.New_Account_Wizard_Home_Phone_Format_Error_Message));
                return false;
            }
        }

        return true;
    }

}