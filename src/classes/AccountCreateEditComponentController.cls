/**
* @author Wiktor Czykin 
* @date 17/07/2017
* @description controller for AccountCreateEditComponent - currently only supports NEW 
*#############Change Log#############
*Modified by     Version     Change Date
*/
public with sharing class AccountCreateEditComponentController {

    public Account acc{get;set;}
    public Contact contact{get;set;}
    public Boolean tmgPromoEmail{get; set;}
    public Boolean tmgPromoPhone{get; set;}
    public Boolean tmgPromoPost{get; set;}
    public Boolean tmgPromoSms{get; set;}

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - constructor with account
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public AccountCreateEditComponentController(){
        this.acc = new Account(
            PersonMailingCountry = Constants.COUNTRY_CODE_GB,
            RecordTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_PERSONACCOUNT_INDIVIDUAL_SUBSCRIBER, Account.class.getName()),
            Origin__c = Constants.SUBSCRIBER_ORIGIN_FLOW_OFFLINE
        );
        this.contact = new Contact(FirstName = '', LastName = '', Salutation = '');
        this.tmgPromoEmail = false;
        this.tmgPromoPhone = false;
        this.tmgPromoPost = false;
        this.tmgPromoSms = false;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - constructor with account
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public AccountCreateEditComponentController(Account acc){
        if(acc == null){
            throw new TelegraphApplicationException('Null account cannot be passed to account new/edit component.');
        }
        this.acc = acc;
        this.tmgPromoEmail = acc.TMG_Promo_Email__c == 1?true:false;
        this.tmgPromoPhone = acc.TMG_Promo_Phone__c == 1?true:false;
        this.tmgPromoPost = acc.TMG_Promo_Post__c == 1?true:false;
        this.tmgPromoSms = acc.TMG_Promo_SMS__c == 1?true:false;
        this.contact = new Contact(FirstName = this.acc.FirstName, LastName = this.acc.LastName, Salutation = this.acc.Salutation);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - getter for instance account
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public Account getAccount(){
        if(this.acc == null){
            return new Account();
        }
        return this.acc;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - setter of guid on account instance 
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void setGuid(String sGuid){
        this.acc.Guid__c = sGuid;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - get countries for custom picklist
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public List<SelectOption> getCountries(){
        return GlobalQueries.getCountries(false);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - basic account validation - I still dont know why we cant agree on common rules in validation rules
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public Boolean validateAccount(){
        Pattern myPattern = Pattern.compile('^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$');
        Matcher myMatcher = MyPattern.matcher(this.acc.FirstName);
        Boolean bResult = true;

        if (String.isEmpty(this.acc.Salutation) && String.isEmpty(this.acc.Title__c) && this.acc.PersonMailingCountry == Constants.COUNTRY_CODE_GB){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Error_Empty_Salutation));
            bResult = false;
        }

        if (!myMatcher.matches()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_First_name_validation));
            bResult = false;
        }
        myMatcher = MyPattern.matcher(this.acc.LastName);
        if (!myMatcher.matches()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Last_name_validation));
            bResult = false;
        }
        myPattern = Pattern.compile('[0-9\\s?]+');

        if(String.isNotBlank(this.acc.PersonMobilePhone)){
            myMatcher = myPattern.matcher(this.acc.PersonMobilePhone);
            if(!this.acc.PersonMobilePhone.startsWith('0') || !myMatcher.matches()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Mobile_number_validation));
                bResult = false;
            }
        }

        if(String.isNotBlank(this.acc.PersonHomePhone)){
            myMatcher = myPattern.matcher(this.acc.PersonHomePhone);
            if(!this.acc.PersonHomePhone.startsWith('0') || !myMatcher.matches()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Phone_number_validation));
                bResult = false;
            }
        }

        if(String.isNotBlank(this.acc.PersonEmail)){
            List<Account> lstDuplicate = [SELECT Id FROM Account WHERE PersonEmail = :this.acc.PersonEmail];
            if(!lstDuplicate.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Offline_Acquisition_Email_duplicate_error));
                bResult = false;
            }
        }
        return bResult;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - maps proxy fields/variables to account fields
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void mapAccountFields(){
        this.acc.FirstName = this.contact.FirstName;
        this.acc.LastName = this.contact.LastName;
        this.acc.Salutation = this.contact.Salutation;
        this.acc.TMG_Promo_Email__c = this.tmgPromoEmail?1:0;
        this.acc.TMG_Promo_Phone__c = this.tmgPromoPhone?1:0;
        this.acc.TMG_Promo_Post__c = this.tmgPromoPost?1:0;
        this.acc.TMG_Promo_SMS__c = this.tmgPromoSms?1:0;

        if(String.isNotBlank(this.acc.Title__c)){
            this.acc.Salutation = this.acc.Title__c;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - just saves account
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public void saveAccount(){
        this.mapAccountFields();
        if(this.validateAccount()){
            try{
                insert acc;
            }catch(DmlException e){
                ApexPages.addMessages(e); 
            }
        }
    }
}

