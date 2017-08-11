/************************************************************************************
Class name   : SubscriberDetailController
Author       : Konrad Czykin
Created Date : 10/05/2017
Function     : Controller class for visualforce component SubscriberDetails.component
*************************************************************************************/
public class SubscriberDetailsController {

    public Id accountId {get; set{
        if((value != null && this.thisAccount == null) || (value != null && value != this.thisAccount.Id) ){
            this.accountId = value;
            this.initAccount();
            }
        }
    }

    public Account thisAccount {get; set;}
	public Case thisCase {get;set;}

	public Account accBeforeEdit;
	public Boolean accEditEnabled {get;set;}
	public Boolean showEmailIFrame {get;set;} 

	private static final Id RECID_RET_ACC = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.RECTYPE_INDIVSUB, Account.class.getName());

        //Page Message variables
    public Boolean subscriberDetailsMsg {get;set;} 
    public Boolean offeredSubscriptionMsg {get;set;}

        //Constants
    private ApexPages.Severity ERROR = ApexPages.Severity.ERROR;
    private ApexPages.Severity FATAL = ApexPages.Severity.FATAL;
    private String SUBSCRIBER_DETAILS_MSG = 'Subscriber Details';
    private String ACCOUNT_PERMISIONS_MSG = 'Permissions';
    
    /* ACCOUNT PERMISSIONS */
    public Boolean showAccountPermissions { get; set; } 
    public Boolean accountPermissionsMsg { get; set; }
    public Account accountPermissions;
    
    public Boolean p2ndEmail {
        get { return getBooleanFromInt('TMG_Promo_Email__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_Email__c'); }
    }

    public Boolean p2ndPhone {
        get { return getBooleanFromInt('TMG_Promo_Phone__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_Phone__c'); }
    }

    public Boolean p2ndPost {
        get { return getBooleanFromInt('TMG_Promo_Post__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_Post__c'); }
    }

    public Boolean p2ndSMS {
        get { return getBooleanFromInt('TMG_Promo_SMS__c'); }
        set { setAccountBoolean(value, 'TMG_Promo_SMS__c'); }
    }

    /************************************************************************************
    Method Name  : Controller Constructor 
    Author       : Konrad Czykin
    Created Date : 10/05/2017
    *************************************************************************************/
    public SubscriberDetailsController(){}
    
    /************************************************************************************
    Method Name  : displayChangeEmailIFrame
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : display add/change email iFrame
    *************************************************************************************/
    public void displayChangeEmailIFrame(){
        this.showEmailIFrame = true;
    }

    /************************************************************************************
    Method Name  : hideChangeEmailIFrame
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : hide add/change email iFrame
    *************************************************************************************/
    public void hideChangeEmailIFrame(){
        this.showEmailIFrame = false;
    }

    /************************************************************************************
    Method Name  : refetchSubscriberEmail
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : refetch subscriber email and close add/change email iFrame
    *************************************************************************************/
    public void refetchSubscriberEmail(){
        List<Account> lstAcc = [SELECT PersonEmail FROM Account WHERE Id = :thisAccount.Id];
        if(!lstAcc.isEmpty()){
            thisAccount.PersonEmail = lstAcc[0].PersonEmail;
            accBeforeEdit.PersonEmail = lstAcc[0].PersonEmail;
            showEmailIFrame = false;
        }else{
            addPageMessage(ACCOUNT_PERMISIONS_MSG, FATAL, Label.Offline_Acquisition_Account_refetch_error_update);
        }
    }

    /************************************************************************************
    Method Name  : getSubscriberAddress
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : get subscriber adress
    *************************************************************************************/
    public String getSubscriberAddress(){
        if(thisAccount  == null ) return '';
        return (thisAccount.PersonMailingStreet != null ? thisAccount.PersonMailingStreet : '')
               + (thisAccount.PersonMailingCity  != null ?
                 (thisAccount.PersonMailingStreet != null ? ', ' : '') + thisAccount.PersonMailingCity : '')
               + (thisAccount.PersonMailingState != null ?
                 (thisAccount.PersonMailingStreet != null || thisAccount.PersonMailingCity != null ? ', ' : '')
               + thisAccount.PersonMailingState : '')
               + (thisAccount.PersonMailingStreet == null && thisAccount.PersonMailingCity == null && thisAccount.PersonMailingState == null ?
                 thisAccount.PersonMailingPostalCode : ' ' + thisAccount.PersonMailingPostalCode);
    }

    /************************************************************************************
    Method Name  : getCountries
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Read Countries with code from Custom Settings
    *************************************************************************************/
    public List<SelectOption> getCountries(){
        List<SelectOption> liOptions = new List<SelectOption>();
        if(thisAccount == null) return liOptions;
        if(thisAccount.RecordTypeId == RECID_RET_ACC ){
            liOptions.add(new SelectOption(
                Constants.UNITED_KINGDOM_COUNTRY_TWO_CODE_VALUE,
                Constants.UNITED_KINGDOM_COUNTRY_NAME_VALUE
            ));
        }else{
            for(Country_Codes__c country: Country_Codes__c.getAll().values()){
                liOptions.add(new SelectOption(country.Name, country.Country_Name__c));
            }
        }
        return liOptions;
    }

    /************************************************************************************
    Method Name  : cancelAccountEdit
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Used in visualforce page to rerender subscriber details section on edit mode cancellation
    *************************************************************************************/
    public void cancelAccountEdit(){
        thisAccount = accBeforeEdit.clone(true);
        showEmailIFrame = false;
        accEditEnabled = false;
    }

    /************************************************************************************
    Method Name  : saveAccount
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Method to save subscriber record
    *************************************************************************************/
    public void saveAccount(){
        try{

            if(String.isNotBlank(this.thisAccount.Title__c)){
                this.thisAccount.Salutation = this.thisAccount.Title__c;
            }

             // Checking that First is only Letters (suggested to remove SUB-4355)
            Pattern MyPattern = Pattern.compile('^[^0-9!\"#&$%&()*+,./:;<=>?@\\[\\]\\^\\{|}_~]+$');
            Matcher MyMatcher = MyPattern.matcher(thisAccount.FirstName);
            if (!MyMatcher.matches()){
                addPageMessage(SUBSCRIBER_DETAILS_MSG, FATAL, Label.OC_First_Name_not_valid);
                return;
            }

            //update thisAccount
            Database.SaveResult result = Database.update(thisAccount, false);
            if (!result.isSuccess()){
                addPageMessage(SUBSCRIBER_DETAILS_MSG, FATAL, result.getErrors());
                return;
            }

            accBeforeEdit = thisAccount.clone(true);
            accEditEnabled = false;

        }catch(Exception e){
            addPageMessage(SUBSCRIBER_DETAILS_MSG, FATAL, Label.OC_Error, e.getMessage());
            return;
        }
    }

    /************************************************************************************
    Method Name  : enableEditAccount
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : Used in visualforce page to render subscriber details section on edit mode
    *************************************************************************************/
    public void enableEditAccount(){
        accEditEnabled = true;
    }

    /************************************************************************************
    Method Name  : getAccount
    Author       : Konrad Czykin
    Created Date : 10/05/2017
    Function     : Method to retrieve related Account record and decleare Account Marketing Permissions
    *************************************************************************************/
    private void initAccount(){

        List<Account> accLst = new List<Account>([
            SELECT Name,RecordTypeId,Subscriber_Number__c,PersonTitle, Title__c,
                Salutation, Preferred_Phone_Contact__pc, Phone, PersonMobilePhone,
                PersonHomePhone, Subscriber_Number_static__c, PersonContactId,
                LastName, FirstName, IsPersonAccount, PersonMailingStreet,
                PersonMailingCity, PersonMailingState, PersonMailingPostalCode,
                PersonEmail, PersonMailingCountry, Permissions_Last_Change_Date__c,
                TMG_Promo_SMS__c, TMG_Promo_Post__c, TMG_Promo_Phone__c, TMG_Promo_Email__c,
                TMG_Partner_Promo_SMS__c, TMG_Partner_Promo_Post__c, TMG_Partner_Promo_Phone__c,
                TMG_Partner_Promo_Email__c, TMG_Loyalty_SMS__c, TMG_Loyalty_Phone__c,
                TMG_Loyalty_Mail__c, TMG_Loyalty_Email__c, Do_Not_Contact__pc, Guid__c,
                Teleappended_Date__c
            FROM Account
            WHERE Id = :this.accountId
            LIMIT 1
        ]);

       if(accLst.isEmpty()){
            addPageMessage(SUBSCRIBER_DETAILS_MSG, ERROR, Label.Outbound_Calling_Subscription_Not_Found);
       } else {

            this.thisAccount = accLst[0];


            //Outbound_Calling_Subscription_Not_Found)

       		accountPermissions = new Account(Id                              = thisAccount.Id,
                                             Permissions_Last_Change_Date__c = thisAccount.Permissions_Last_Change_Date__c,
                                             TMG_Promo_SMS__c                = thisAccount.TMG_Promo_SMS__c,
                                             TMG_Promo_Post__c               = thisAccount.TMG_Promo_Post__c,
                                             TMG_Promo_Phone__c              = thisAccount.TMG_Promo_Phone__c,
                                             TMG_Promo_Email__c              = thisAccount.TMG_Promo_Email__c,
                                             Do_Not_Contact__pc              = thisAccount.Do_Not_Contact__pc,
                                             Guid__c                         = thisAccount.Guid__c
            );

            accBeforeEdit = this.thisAccount.clone(true);
        }
    }

    /************************************************************************************
    Method name   : addPageMessage
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : methods to add page message
    *************************************************************************************/

    /* @ addPageMessage Methods @ **/

    //generic error message passed as a string
    private void addPageMessage(String location, ApexPages.Severity severity, String errorMessage){
        setPageMessage(location);
        ApexPages.addMessage(new ApexPages.Message(severity, errorMessage));
    }

    //user friendly error message to be dispalyed and full error message to be logged in system debug passed as a string
    private void addPageMessage(String location, ApexPages.Severity severity, String pageMessage, String adminMessage){
        addSystemLogMessage(location, severity, adminMessage);
        addPageMessage(location, severity, pageMessage);
    }

    //generic error message passed as a string with additional parameters
    private void addPageMessage(String location, ApexPages.Severity severity, String errorMessage, List<String> errorMessageParameters){
        addPageMessage(location, severity, String.format(errorMessage , errorMessageParameters));
    }

    //user friendly error message full error message passed as a string with additional comments
    private void addPageMessage(String location, ApexPages.Severity severity, String errorMessage, List<String> errorMessageParameters, String adminMessage){
        addPageMessage(location, severity, String.format(errorMessage , errorMessageParameters), String.format(adminMessage , errorMessageParameters));
    }

    //DMLException error message passed and converted to the user friendly string message
    private void addPageMessage(String location, ApexPages.Severity severity, List<Database.Error> errorLst){
        for(Database.Error error : errorLst){
            addPageMessage(location, severity, String.valueOf(error.getMessage()), String.valueOf(error));
        }
    }

    /* @ addPageMessage Methods End @ **/

    /************************************************************************************
    Method name   : addSystemLogMessage
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : methods used to add system debug messages
    *************************************************************************************/
    private void addSystemLogMessage(String location, ApexPages.Severity severity, String errorMessage){
        System.debug('<TMG> OUTBOUND CALLING SALES IN ' + location + '. ' + String.valueOf(severity) + ' : ' + errorMessage);
    }

    /************************************************************************************
    Method name   : addSystemLogMessage
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : methods to set boolean flags for the page messages based on section name
    *************************************************************************************/
    private void setPageMessage(String sectionName){
     
        subscriberDetailsMsg = sectionName.equals(SUBSCRIBER_DETAILS_MSG);
        accountPermissionsMsg = sectionName.equals(ACCOUNT_PERMISIONS_MSG);
    }

    /************************************************************************************
    Method name   : clearPageMessage
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : calling setPageMessage with blank value to set all boolean flags to false
    *************************************************************************************/
    private void clearPageMessage(){
        setPageMessage('');
    }

    /************************************************************************************
    Method name   : getBooleanFromInt
    Refactored by: Konrad Czykin
    Change Date  : 10/05/2017
    Function     : METHODS FOR ACCOUNT PERMISSIONS LOGIC
    *************************************************************************************/
	private Boolean getBooleanFromInt(String fieldName){

        if(accountPermissions.get(fieldName) == null){
            accountPermissions.put(fieldName, 0);
        }

        if (accountPermissions.get(fieldName) == 1) 
            return true;
        
        return false;
    }

    /************************************************************************************
    Method name   : setAccountBoolean
    Author       : Vishant Shah
    Created Date : 08/05/2017
    Function     : set flags for account permissions
    *************************************************************************************/
    private void setAccountBoolean(Boolean booleanFlag, String fieldName){
        if (booleanFlag) 
            accountPermissions.put(fieldName, 1);
        else 
            accountPermissions.put(fieldName, 0);
    }

    /************************************************************************************
    Method name   : saveAccountPermissions
    Author       : Vishant Shah
    Created Date : 08/05/2017
    Function     : save Account Permissions
    *************************************************************************************/
    public void saveAccountPermissions(){
        accountPermissions.Permissions_Last_Change_Date__c = System.today();
        
        Database.SaveResult result = Database.update(accountPermissions, false);
        if (!result.isSuccess()) {
            addPageMessage(ACCOUNT_PERMISIONS_MSG, FATAL, result.getErrors());
        }
    }
}