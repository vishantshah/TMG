/**
* Author:       Sally ElGhoul (Tquila)
* Date:         17/06/2015
* Description:  this class is the Account utility
* ******************* Change Log *******************
* Modified by       Change Date
* Michal Kwika      14/07/2015
* Michal Kwika      27/07/2015
* Michal Kwika      24/08/2015
* Michal Kwika      18/12/2015
* Michal Kwika      12/01/2016
* Michal Szewczyk   28/01/2016
* Michal Kwika      24/02/2016 - old world validation improvement
* Wiktor Czykin     07/03/2016 - modified findAccounts(), hasAccountActiveSub(). Added isPendingCancellationConversion()
* Lynette Lim       27/04/2016 - modified hasAccountActiveSub(). Added isInRenewalConversion()
**/
public class AccountUtility {

    public static final String STATUS_ACTIVE = 'active';
    public static final String STATUS_NOACTIVE = 'noactive';
    public static final String STATUS_PENDINGCANCELLATION_CONDITIONAL = 'pcconditional';
    public static final String STATUS_INRENEWAL_CONDITIONAL = 'irconditional';

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called to search for accounts using (surname and postcode) or (tsnumber)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.05        14/07/2015
    Michal Kwika        1.1         27/07/2015
    Michal Kwika        1.2         25/08/2015
    Michal Kwika        1.3         12/01/2016
    Wiktor Czykin       1.4         07/03/2016  //changed is empty to isBlank to prevent empty strings from passing in
    ****************************************************************************************/
    public static List<Account> findAccounts(String lastNameValue, String postalCodeValue, String emailValue, String tsNumberValue) {
        List<Account> lstAccountResults = new List<Account>();

        String whereClause = '';
        String formatedPostCode = '';
        //if agent is searching using only Name and PostCode we are using AND
        if (String.isNotBlank(lastNameValue) && String.isNotBlank(postalCodeValue) && String.isBlank(emailValue) && String.isBlank(tsNumberValue)) {
            lastNameValue = lastNameValue.trim();
            whereClause = String.format(Constants.SEARCH_ACCOUNT_LAST_NAME_CONDITION, new List<String>{AddSingleQuotes(lastNameValue)});
            formatedPostCode = SubscriberPortal.FormatPostCode(postalCodeValue.trim());
            whereClause += getConcatinationStringWithAndCondition(whereClause) + String.format(Constants.SEARCH_ACCOUNT_POSTAL_CODE_CONDITION_EXTENDED, new List<String> {AddSingleQuotes(postalCodeValue), AddSingleQuotes(formatedPostCode)});
        } else {
            //Trim the account Surname for better searching
            if (!String.isBlank(lastNameValue)) {
                lastNameValue = lastNameValue.trim();
                whereClause = String.format(Constants.SEARCH_ACCOUNT_LAST_NAME_CONDITION, new List<String> {AddSingleQuotes(lastNameValue)});
            }

            if (!String.isBlank(postalCodeValue)) {
                formatedPostCode = SubscriberPortal.FormatPostCode(postalCodeValue.trim());
                //We are searching now exact String and formatted postcode
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_POSTAL_CODE_CONDITION, new List<String> {AddSingleQuotes(postalCodeValue)});
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_POSTAL_CODE_CONDITION, new List<String> {AddSingleQuotes(formatedPostCode)});
            }

            //trim the email and build the where clause
            if (!String.isBlank(emailValue)) {
                emailValue = emailValue.trim();
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_EMAIL_CONDITION, new List<String> {AddSingleQuotes(emailValue)});
            }

            //trim the tsNumber and build the where clause
            if (!String.isBlank(tsNumberValue)) {
                tsNumberValue = tsNumberValue.trim();
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_TS_NUMBER_CONDITION, new List<String> {AddSingleQuotes(tsNumberValue)});
            }
        }

        //prepare the soql query
        String soqlQuery = String.format(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW, new List<String> {AddSingleQuotes(CONSTANTS.SUBSCRIPTION_STATUS_ACTIVE_VALUE), AddSingleQuotes(CONSTANTS.SUBSCRIPTION_STATUS_ACTIVE_VALUE), whereClause, ''});

        //loop on the accounts returned by the soql query and add them to the List of accounts to be returneds
        for (Account acc : Database.query(soqlQuery)) {
            lstAccountResults.add(acc);
        }

        return lstAccountResults;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        20/07/2015
    Function    this function is called to either retuen ' OR ' to concatinate the where clause or empty String
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.05        14/07/2015
    ****************************************************************************************/
    public static String getConcatinationString(String whereClause) {
        if (!String.isempty(whereClause)) {
            return ' OR ';
        } else {
            return '';
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        12/01/2016
    Function    this function is called to either retuen ' AND ' to concatinate the where clause
                or empty String
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String getConcatinationStringWithAndCondition(String whereClause) {
        if (String.isNotEmpty(whereClause)) {
            return ' AND ';
        } else {
            return '';
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        18/06/2015
    Function    this function is called to return the registrant accounts only from a List of accounts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static List<Account> getRegistrantAccounts(List<Account> lstAccounts) {

        List<Account> lstRegistrantAccounts = new List<Account>();

        //Get the registrant Account record type
        Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());

        for (Account accountObj : lstAccounts) {
            if (accountObj.RecordTypeId == registrantRecordTypeId) {
                lstRegistrantAccounts.add(accountObj);
            }
        }
        return lstRegistrantAccounts;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        18/06/2015
    Function    this function is called to return the non registrant accounts only from a List of accounts
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static List<Account> getNonRegistrantAccounts(List<Account> lstAccounts) {

        List<Account> lstNonRegistrantAccounts = new List<Account>();

        //Get the registrant Account record type
        Id registrantRecordTypeId   = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());

        for (Account accountObj : lstAccounts) {
            if (accountObj.RecordTypeId != registrantRecordTypeId) {
                lstNonRegistrantAccounts.add(accountObj);
            }
        }
        return lstNonRegistrantAccounts;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        17/06/2015
    Function    this function is called to add single quotes to the parameters used in the search query
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String AddSingleQuotes(String strParameter) {
        if (String.isempty(strParameter)) {
            return '\'\'';
        } else {
            return '\'' + String.escapeSingleQuotes(strParameter) + '\'';
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        25/08/2015
    Function    method used to create String query - used by queryLocator on page
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         12/01/2016
    Wiktor Czykin       1.2         07/03/2016 //replaced isEmpty with isBlank
    ****************************************************************************************/
    public static String createSOQLofAcc(String lastNameValue, String postalCodeValue, String emailValue, String tsNumberValue, Boolean isRegistrant, String character) {
        String whereClause = '';
        String soqlQuery = '';
        String recordTypeANDcondition = '';
        String registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
        String formatedPostCode = '';

        if (String.isNotBlank(lastNameValue) && String.isNotBlank(postalCodeValue) && String.isBlank(emailValue) && String.isBlank(tsNumberValue)) {
            lastNameValue = lastNameValue.trim();
            whereClause = String.format(Constants.SEARCH_ACCOUNT_LAST_NAME_CONDITION, new List<String> {AddSingleQuotes(lastNameValue)});
            formatedPostCode = SubscriberPortal.FormatPostCode(postalCodeValue);
            whereClause += getConcatinationStringWithAndCondition(whereClause) + String.format(Constants.SEARCH_ACCOUNT_POSTAL_CODE_CONDITION_EXTENDED, new List<String> {AddSingleQuotes(postalCodeValue), AddSingleQuotes(formatedPostCode)});

        } else {
            if (!String.isBlank(lastNameValue)){
                lastNameValue = lastNameValue.trim();
                whereClause = String.format(Constants.SEARCH_ACCOUNT_LAST_NAME_CONDITION, new List<String> {AddSingleQuotes(lastNameValue)});
            }

            //Format the postal code
            if (!String.isBlank(postalCodeValue)){
                formatedPostCode = SubscriberPortal.FormatPostCode(postalCodeValue.trim());
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_POSTAL_CODE_CONDITION, new List<String> {AddSingleQuotes(postalCodeValue)});
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_POSTAL_CODE_CONDITION, new List<String> {AddSingleQuotes(formatedPostCode)});
            }

            //trim the email and build the where clause
            if (!String.isBlank(emailValue)){
                emailValue = emailValue.trim();
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_EMAIL_CONDITION, new List<String> {AddSingleQuotes(emailValue)});
            }

            //trim the tsNumber and build the where clause
            if (!String.isBlank(tsNumberValue)){
                tsNumberValue = tsNumberValue.trim();
                whereClause += getConcatinationString(whereClause) + String.format(Constants.SEARCH_ACCOUNT_TS_NUMBER_CONDITION, new List<String> {AddSingleQuotes(tsNumberValue)});
            }
        }

        //AND it's registrant
        if (isRegistrant) {
            recordTypeANDcondition = String.format(Constants.SEARCH_ACCOUNT_RECORDTYPE_CONDITION, new List<String> {AddSingleQuotes(registrantRecordTypeId)});
        }
        //or if it's not
        else if (!isRegistrant) {
            recordTypeANDcondition = String.format(Constants.SEARCH_ACCOUNT_RECORDTYPE_CONDITION_NOT, new List<String> {AddSingleQuotes(registrantRecordTypeId)});
        }

        if (character == null || character == 'All' || character == '' || String.isEmpty(character)) {
            soqlQuery = String.format(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_ORDERBY_LASTNAME_10K, new List<String> {AddSingleQuotes(CONSTANTS.SUBSCRIPTION_STATUS_ACTIVE_VALUE), AddSingleQuotes(CONSTANTS.SUBSCRIPTION_STATUS_ACTIVE_VALUE), whereClause, recordTypeANDcondition, ''});
        }

        else if (character.length() == 1) {
            String likeCharCondition = character + '%';
            String specialCharacter = String.format(Constants.SEARCH_ACCOUNT_FIRST_LETTER_CONDITION, new List<String> {AddSingleQuotes(likeCharCondition)});
            soqlQuery = String.format(Constants.SEARCH_ACCOUNT_NEW_ACCOUNT_WIZARD_NEW_ORDERBY_LASTNAME_10K, new List<String> {AddSingleQuotes(CONSTANTS.SUBSCRIPTION_STATUS_ACTIVE_VALUE), AddSingleQuotes(CONSTANTS.SUBSCRIPTION_STATUS_ACTIVE_VALUE), whereClause, recordTypeANDcondition, specialCharacter});
        }

        system.debug('### soqlQuery build:' + soqlQuery);

        return soqlQuery;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        15/12/2015
    Function    universal method to make validations on Account creation/update/conversion
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         09/02/2016  //just merged 2 lines into 1
    ****************************************************************************************/
    public static Boolean isValidEmptyString(String valueToCheck, String errorMessage) {

        if (String.isEmpty(valueToCheck)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errorMessage));
            return false;
        }
        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        15/12/2015
    Function    validate phone for Account creation
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean isPhoneValid(String phoneNumber, String errorMessage) {
        //They should start with Zero and should only contain numbers
        Pattern phonePattern = Pattern.compile('[0-9\\s?]+');

        //Validate the Mobile Phone
        if (!String.isEmpty(phoneNumber)) {
            Matcher phoneMatcher = phonePattern.matcher(phoneNumber);
            if (!phoneNumber.startsWith('0') || !phoneMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errorMessage));
                return false;
            }

        }
        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/12/2015
    Function    validate 2 letters on String (lastname)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean isNameTwoLettersAtLeast(String accName) {
        if (!String.isEmpty(accName.trim()) && accName.trim().length() < 2 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Account_LastName_Small));
            return false;
        }

        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/12/2015
    Function    validate if String is built by letters only(lastname)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean hasLastNameOnlyLetters(String accName) {
        //Check Last Name format
        if (!String.isEmpty(accName)) {
            // Checking that LastName is only Letters
            Pattern MyPattern = Pattern.compile(Constants.REG_EXPRESSION_LETTERS_ONLY);
            Matcher MyMatcher = MyPattern.matcher(accName);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Last_Name_Format));
                return false;
            }
        }

        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/12/2015
    Function    validate postalcode for UK
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean isPostCodeValid(String accPostCode, String accCountry) {
        if ((String.isEmpty(accPostCode)) && accCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Postal_Code));
            return false;
        }

        //if the country is UK validate post code
        if ((!String.isEmpty(accPostCode)) && (accCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE)) {
            // Checking the format of British post code
            Pattern MyPattern = Pattern.compile(Constants.REG_GB_POSTCODE_FORMAT);
            Matcher MyMatcher = MyPattern.matcher(accPostCode);

            if (!MyMatcher.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Post_Code_Invalid));
                return false;
            }
        }

        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/12/2015
    Function    validate county/state for US and Canada
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean isStateNotNeeded(String accState, String accCountry) {
        if ((String.isEmpty(accState)) && (accCountry == Constants.COUNTRY_UNITED_STATES_TWO_LETTERS_CODE || accCountry == Constants.COUNTRY_CANADA_TWO_LETTERS_CODE)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.State_Error_Message));
            return false;
        }

        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        29/12/2015
    Function    Full validation of Person Account
                FirstName, LastName, Email, Address, Phone
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean isPersonAccountFullyValid(Account personAccount, Contact personContact, Boolean isNewAccountMode, Boolean isPhoneRequired) {
        //check title
        if (String.isEmpty(personContact.Salutation) && String.isEmpty(personAccount.title__c) && personAccount.PersonMailingCountry == Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            return false;
        }
        //check title or given name
        if (!String.isEmpty(personContact.Salutation) && !String.isEmpty(personAccount.title__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            return false;
        }
        //check FirstName
        if (!isValidEmptyString(personContact.FirstName, Label.Empty_First_Name_Error)) {
            return false;
        }

        //check Last Name
        if (!isValidEmptyString(personAccount.LastName, Label.Last_Name_Error_Message)) {
            return false;
        }

        if (!isNameTwoLettersAtLeast(personAccount.LastName)) {
            return false;
        }

        if (!hasLastNameOnlyLetters(personAccount.LastName)) {
            return false;
        }

        //Check Email
        if (!isValidEmptyString(personAccount.PersonEmail, Label.Error_Empty_Email)) {
            return false;
        }

        //Check Mailing Street
        if (!isValidEmptyString(personAccount.PersonMailingStreet, Label.Error_Empty_Mailing_Street)) {
            return false;
        }

        //Check City
        if (!isValidEmptyString(personAccount.PersonMailingCity, Label.Error_Empty_Mailing_City)) {
            return false;
        }

        //Check Country
        if (!isValidEmptyString(personAccount.PersonMailingCountry, Label.Error_Empty_Mailing_Country)) {
            return false;
        }

        //check that postal code is mandadory if the country is UK
        if (!isPostCodeValid(personAccount.PersonMailingPostalCode, personAccount.PersonMailingCountry)) {
            return false;
        }

        //check state as it should be mandatory if the country is US or Canada
        if (!isStateNotNeeded(personAccount.PersonMailingState, personAccount.PersonMailingCountry)) {
            return false;
        }
        //Phone Required
        if (isPhoneRequired) {
            //check if phone is there
            if (!isValidEmptyString(personAccount.PersonMobilePhone, Label.Outbound_Digital_Acquisition_PhoneNumber_Mobile_Required)) {
                return false;
            }

            //check if phone is there
            if (!isValidEmptyString(personAccount.PersonHomePhone, Label.Outbound_Digital_Acquisition_PhoneNumber_Home_Required)) {
                return false;
            }
        }

        //check phone numbers - PATTERN
        if (!isPhoneValid(personAccount.PersonMobilePhone, Label.New_Account_Wizard_Mobile_Phone_Format_Error_Message)) {
            return false;
        }

        if (!isPhoneValid(personAccount.PersonHomePhone, Label.New_Account_Wizard_Home_Phone_Format_Error_Message)) {
            return false;
        }

        //check if there is any other Account with same email address - for new Accounts only
        if (isNewAccountMode) {
            if (!String.isEmpty(personAccount.PersonEmail)) {
                List <Account> lAccountsWithGivenEmail = findAccounts('', '', personAccount.PersonEmail, '');
                if (lAccountsWithGivenEmail.size() > 0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Email_Invalid_Other_Account_Exist));
                    return false;
                }
            }
        }
        return true;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        29/12/2015
    Function    Check if Account has Active Subscription (old Sub or new Sub)
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         24/02/2016 - added improvements to old world validation
    Wiktor Czykin       1.2         09/03/2016 - modified the validation logic to also check old records for registrants (as record type might have been changed but validation should still be applicable)
    Lynette Lim         1.3         27/04/2016 - modified hasAccountActiveSub to exclude in-renewal subscriptions as active subscriptions
    ****************************************************************************************/
    public static String hasAccountActiveSub(Account sfAccount) {
        Date dt = Date.today();
        Id registrantRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());
        Id individualRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());
        Id digitalRecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_DIGISUB, Account.class.getName());
        Map<String, Integer> mapStatusesCount = new Map<String, Integer>{   STATUS_ACTIVE => 0,
                                                                            STATUS_PENDINGCANCELLATION_CONDITIONAL => 0,
                                                                            STATUS_INRENEWAL_CONDITIONAL => 0};
        Set<String> setActiveDigitalStatusesOnAcc = new Set<String>{Constants.SSTATUS_ACTIVE.toLowerCase(), Constants.SSTATUS_PENDING.toLowerCase()};
        Set<String> setActivePrintStatusesOnSubscription = new Set<String>{Constants.SSTATUS_ACTIVE.toLowerCase(), Constants.SSTATUS_PENDING.toLowerCase()};

        if(sfAccount.RecordTypeId == registrantRecordTypeId || sfAccount.RecordTypeId == individualRecordTypeId) {
         
            for(Subscription__c subscription : [SELECT   Id, 
                                                        Subscriber__c,
                                                        Subscription_Status__c
                                                    FROM Subscription__c
                                                    WHERE Subscriber__c = :sfAccount.Id
                                                    AND (
                                                        Subscription_Status__c = :Constants.SSTATUS_ACTIVE OR 
                                                        Subscription_Status__c = :Constants.SSTATUS_IN_RENEWAL OR 
                                                        Subscription_Status__c = :Constants.SSTATUS_PENDING  OR 
                                                        (Subscription_Status__c = :Constants.SSTATUS_PENDING_CANX AND Cancellation_Date__c >= :dt)
                                                    )]){
                if(setActivePrintStatusesOnSubscription.contains(subscription.Subscription_Status__c.toLowerCase())){
                    mapStatusesCount.put(STATUS_ACTIVE, mapStatusesCount.get(STATUS_ACTIVE)+1);
                }else if(subscription.Subscription_Status__c == Constants.SSTATUS_PENDING_CANX){
                    mapStatusesCount.put(STATUS_PENDINGCANCELLATION_CONDITIONAL, mapStatusesCount.get(STATUS_ACTIVE)+1);
                }else if(subscription.Subscription_Status__c == Constants.SSTATUS_IN_RENEWAL){
                    mapStatusesCount.put(STATUS_INRENEWAL_CONDITIONAL, mapStatusesCount.get(STATUS_ACTIVE)+1);
                }
            }
        } 
        
        if(sfAccount.RecordTypeId == registrantRecordTypeId || sfAccount.RecordTypeId == digitalRecordTypeId){
            if (String.isNotBlank(sfAccount.Subscriber_Digital_Status__c) && setActiveDigitalStatusesOnAcc.contains(sfAccount.Subscriber_Digital_Status__c.toLowerCase())) {
                mapStatusesCount.put(STATUS_ACTIVE, mapStatusesCount.get(STATUS_ACTIVE)+1);
            }
        }
 
        if(sfAccount.RecordTypeId == registrantRecordTypeId){
            List<Zuora__Subscription__c> lstZuoraSubsActive  = [SELECT Id 
                                                                    FROM Zuora__Subscription__c
                                                                    WHERE Zuora__Account__c = :sfAccount.Id
                                                                    AND (Zuora__Status__c = 'Active' OR Zuora__Status__c = 'Pending Cancellation' OR Zuora__Status__c = 'Pending Activation')
                                                                    LIMIT 1];
            if(!lstZuoraSubsActive.isEmpty()){
                mapStatusesCount.put(STATUS_ACTIVE, mapStatusesCount.get(STATUS_ACTIVE)+1);
            }
        }

        if(mapStatusesCount.get(STATUS_ACTIVE) > 0){
            return STATUS_ACTIVE;
        }else if(mapStatusesCount.get(STATUS_PENDINGCANCELLATION_CONDITIONAL) > 0){
            return STATUS_PENDINGCANCELLATION_CONDITIONAL;
        }else if(mapStatusesCount.get(STATUS_INRENEWAL_CONDITIONAL) > 0){
            return STATUS_INRENEWAL_CONDITIONAL;
        }
        return STATUS_NOACTIVE;
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        08/03/2016
    Function    Retrieve earliest cancellation date from existing pending cancellation print subscriptions
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Date isPendingCancellationConversion(Id accountId){
        if(accountId == null) return null;

        Date dEarliestDate = null;
        for(Subscription__c sub : [SELECT   Id,
                                            Subscriber__c,
                                            Cancellation_Date__c 
                                        FROM Subscription__c
                                        WHERE Subscriber__c = :accountId
                                        AND Subscription_Status__c = :Constants.SSTATUS_PENDING_CANX 
                                        AND Cancellation_Date__c != null
                                        AND Cancellation_Date__c > :Date.today()
                                        ]){
            if(dEarliestDate == null || dEarliestDate > sub.Cancellation_Date__c){
                dEarliestDate = sub.Cancellation_Date__c;
            }
        }

        return dEarliestDate;
    }

    /***************************************************************************************
    Developer   Lynette Lim
    Date        27/04/2016
    Function    Retrieve earliest start date of new subscription based on existing in-renewal print subscription end date
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Date isInRenewalConversion(Id accountId){
        if(accountId == null) return null;

        Date dEarliestDate = null;
        for(Subscription__c sub : [SELECT   Id,
                                            Subscriber__c,
                                            End_Date__c 
                                        FROM Subscription__c
                                        WHERE Subscriber__c = :accountId
                                        AND Subscription_Status__c = :Constants.SSTATUS_IN_RENEWAL 
                                        AND End_Date__c != null
                                        AND End_Date__c > :Date.today()
                                        ]){
            if(dEarliestDate == null || dEarliestDate > sub.End_Date__c){
                dEarliestDate = sub.End_Date__c;
            }
        }

        return dEarliestDate;
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        30/12/2015
    Function    this function is used to set tmgWebApiProfileId
                used when Account is not in SAM
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static void setTMGwebAPIprofileId(Id tmgWebApiProfileId) {
        //For registrant Account we should not call the Core API when the insert/update is
        //carried out via an inbound call to SFDC.Inbound calls will run using the Web Api profile
        if (tmgWebApiProfileId == null) {
            List<Profile> lstProfile = [select Id from Profile where Name = :Constants.PROFILE_WEB_API];
            if (!lstProfile.isEmpty()) {
                tmgWebApiProfileId = lstProfile[0].Id;
            }
        }
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        15/01/2016
    Function    this function is used check if there is other Account (except passed) that
                has same Email Address
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static Boolean checkIfOtherAccountWithThisEmailExistsInSF(String accountId, String accountEmail) {
        //trim the email and build the where clause
        if (String.isNotEmpty(accountEmail) && String.isNotEmpty(accountId)) {
            accountEmail = accountEmail.trim();
            //prepare the soql query
            String soqlQuery = String.format(Constants.SEARCH_ACCOUNT_EMAIL_CONDITION_WITH_ACC_ID, new List<String> {AddSingleQuotes(accountEmail), AddSingleQuotes(accountId)});
            List <Account> lAccs = Database.query(soqlQuery);
            if (lAccs.size() > 0) {
                return true;
            }
        }
        return false;
    }


    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/01/2016
    Function    this function is used get active Zuora Subscription based on Account Id
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         14/03/2016  //simplified the if
    ****************************************************************************************/
    public static Zuora__Subscription__c getActiveZuoraSubscriptionFromAccount(String sfAccountId) {

        List <Zuora__Subscription__c> lActiveZuoraSubs;
        if (String.isNotEmpty(sfAccountId)) {
            lActiveZuoraSubs = [SELECT Id, Zuora__CustomerAccount__c, Zuora__Status__c FROM Zuora__Subscription__c
                                WHERE Zuora__Account__c = :sfAccountId
                                        AND (Zuora__Status__c = :Constants.SUBSCRIPTION_ACTIVE_STATUS OR Zuora__Status__c = :Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS OR Zuora__Status__c = :Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS)
                                        LIMIT 1];
        }

        if (lActiveZuoraSubs == null || lActiveZuoraSubs.isEmpty()) {
            return null;
        }

        return lActiveZuoraSubs.get(0);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        18/01/2016
    Function    this function is used get active Zuora Subscription based on Account Id
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         14/03/2016  //simplified the if
    ****************************************************************************************/
    public static zqu__Quote__c getLatestActiveQuoteFromAccount(String sfAccountId) {

        List <zqu__Quote__c> lActiveZuoraQuotes;
        if (String.isNotEmpty(sfAccountId)) {
            lActiveZuoraQuotes = [SELECT Id FROM zqu__Quote__c WHERE zqu__Account__c = :sfAccountId AND zqu__Status__c = :Constants.CASE_STATUS_NEW
                                  ORDER BY LastModifiedDate DESC LIMIT 1];
        }

        if (lActiveZuoraQuotes == null || lActiveZuoraQuotes.isEmpty()) {
            return null;
        }

        return lActiveZuoraQuotes.get(0);
    }

    /***************************************************************************************
    Developer   Michal Kwika (Accenture)
    Date        19/01/2016
    Function    this function is used to get Account based on Zuora Account Id 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static String getAccountIdBasedOnZuoraBillingAccountId(String zuoraAccountId){
        List<Zuora__CustomerAccount__c> lTempAccs = [SELECT Zuora__Account__c FROM Zuora__CustomerAccount__c  WHERE Zuora__Zuora_Id__c =:zuoraAccountId];

        if(lTempAccs.size()>0){
            return lTempAccs.get(0).Zuora__Account__c;
        }
        
        return null;
    }
}