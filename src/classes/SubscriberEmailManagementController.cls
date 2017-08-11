/* -----------------------------------------------------------------------------------------------------------------------
   Name:        SubscriberEmailManagementController.cls
   Description: Controller for changing email address functionality

   Date         Version Author                      Summary of Changes 
   -----------  ------- -----------------   ------------------------------------------------------------------------------
   unknown      1.0     unknown             Intial Release
   05/10/2015   1.1     Cristina Anghenie   update functionality so that can be used for print subscribers as well as digital
   12/11/2015   1.2     Cristina Anghenie   update functionality to enable email deletion as well as update
   11/03/2016   1.3     Pawel Chrzanowski   modified updateAccountEmail() to not change entitlements
   15/03/2016   1.4     Pawel Chrzanowski   added iFrame functionality
   17/03/2016   1.5     Pawel Chrzanowski   removed isEmailUpdate and added adoption scenario
   19/05/2016   1.6     Pawel Chrzanowski   modified updateAccountEmail() to not use queueable
   28/10/2016   1.7     Michal Szewczzyk    modified updateAccountEmail()
   02/12/2016   1.8     Pawel Chrzanowski   added SAM error handler
   03/05/2017   1.9     Pawel Chrzanowski   removed unused Marketing Preferences
------------------------------------------------------------------------------------------------------------------------ */
public with sharing class SubscriberEmailManagementController {
    private ApexPages.StandardController stdCon;
    private Account acc;
    public Boolean displayPopUp { get;set; }
    public Boolean updateMPP    { get;set; }
    public String newEmail;
    public String oldEmail;
    public String existingSamAccountGuid;
    
    public SAMUtil.SAMAccountResult samResult;
    public MPPInterfaceHTTP.UserInfoResult mppResult;
    
    //iFrame
    public Boolean isIframe { get;set; }
    public Boolean isRequired { get;set; }
    public Boolean iFrameSuccess{ get;set; }
    
    public SubscriberEmailManagementController(ApexPages.StandardController con){
        this.stdCon = con;
        this.acc = (Account)con.getRecord();
        oldEmail = acc.PersonEmail;
        displayPopUp = true;
        
        //iFrame
        isIframe = false;
        isRequired = false;
        iFrameSuccess = false;
        if(ApexPages.currentPage().getParameters().get('isiframe') != null && ApexPages.currentPage().getParameters().get('isiframe') == 'true'){
            isIframe = true;
        }
        if(ApexPages.currentPage().getParameters().get('required') != null && ApexPages.currentPage().getParameters().get('required') == 'true'){
            isRequired = true;
        }
    }
    
    /************************************************************************************
    Developer - unknown
    Date - unknown
    Version - 1.0
    Function - method that gets called after email address has been added
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         05/10/2015  //method that saves the email changes
    Cristina Anghenie   1.2         29/10/2015  //inform user when sam password change is pending
    Pawel Chrzanowski   1.3         15/03/2016  //added iFrame functionality
    Pawel Chrzanowski   1.4         17/03/2016  //added adoption scenario
    Pawel Chrzanowski   1.5         02/12/2016  added SAM error handler
	Pawel Chrzanowski   1.6         03/05/2017  removed unused Marketing Preferences
    *************************************************************************************/
    public PageReference saveNewEmail(){
        List<Account> accs = new List<Account>();
        newEmail = acc.PersonEmail;
        
        //check if there is already a sam account linked to the existing email address
        Account currentAccInfo = [SELECT Id, Salutation, PersonEmail, FirstName, LastName, PersonMailingStreet, PersonMailingCity, recordTypeId, 
                                         PersonMailingPostalCode, PersonMailingCountry, PersonMailingState, Subscriber_Number__c, Guid__c, RecordType.Name,  
                                         TMG_Promo_Email__c, TMG_Promo_Phone__c, TMG_Promo_Post__c, TMG_Promo_SMS__c, 
                                         (SELECT Id FROM MPP_Transaction_Histories__r), Number_of_Subscriptions__c 
                                  FROM Account WHERE Id = : acc.Id];
                       


        //make email address mandatory and check if email is required
        if((String.isBlank(newEmail) && String.isBlank(currentAccInfo.PersonEmail)) || (isRequired && String.isBlank(newEmail))){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.EmailChange_NoEmail));
             return null;
        }
        
        SAMUtil samUtil = new SAMUtil();
        //check is there is a SAM account linked to the account we are editing
        if(!String.isBlank(oldEmail)){
            try{
                existingSamAccountGuid = samUtil.isExistingSamAccount(oldEmail);
            }catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        } else existingSamAccountGuid = null;
        //no changes if the email address is the same and sam guid matches salesforce guid 
        if(oldEmail == newEmail && existingSamAccountGuid == currentAccInfo.Guid__c && existingSamAccountGuid!=null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_NoChanges));
            return null;
        }
        
        //check if the new email already exists in SAM
        if (!String.isBlank(newEmail)){
            try{
                samResult = samUtil.getExistingSAMAccount(newEmail);
            }catch(WebserviceUtil.SamException e){
                if(e.getError().errorMessage.contains('ACCOUNT_LOCKED')) {
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EmailChange_SAMIsLocked));
                    return null;
                }
            }
            
            //check if the corresponding guid for the new email address doesn't already exist in SAM 
            if(TMGUtil.isDataValid(samResult.guid)){
                Account[] newGuidInSFDC = [SELECT Id FROM Account WHERE Guid__c =: samResult.guid];
                //check if corresponding guid for the new email address exist in SAM and is not the same as the current account guid
                if (!newGuidInSFDC.isEmpty() && currentAccInfo.Guid__c != samResult.guid){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_NewGuidInSFDC));
                    return null;
                }
            }
            
            //check for existing accounts linked to the new email address
            accs = [SELECT Id FROM Account WHERE PersonEmail =: newEmail AND PersonEmail != null];
            if(oldEmail != newEmail && !accs.isEmpty() && !TMGUtil.isDataValid(samResult.guid)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_NewEmailInSFDC));
                return null;
            }
        }
        
        //check if the old email exists in MPP so that we dont create a new MPP account
        //include adoption scenario when customer in MPP has no email (temporary system-generated email)
        MPPInterfaceHTTP mppHTTP = new MPPInterfaceHTTP();
        String oldEmailInMpp = String.isNotBlank(oldEmail) ? oldEmail : (Constants.DEFAULT_EMAIL_ADDRESS.substringBefore('@') + '+' + currentAccInfo.Subscriber_Number__c +'@'+ Constants.DEFAULT_EMAIL_ADDRESS.substringAfter('@'));
        try{
            updateMPP = (mppHTTP.callUserInfoByEmail(oldEmailInMpp)!=null) ? true : false;
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
            if(e.getErrorMessage().contains(Label.EmailChange_NoMPP)){
                updateMPP = false;
            }
        }
        System.debug('### SubscriberEmailManagementController.saveNewEmail -> updateMPP: ' + updateMPP);
        
        //check if the new email exists in MPP
        if(String.isNotBlank(newEmail)){
            try{
                mppResult = mppHTTP.callUserInfoByEmail(newEmail);
            }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e){
                if(e.getErrorMessage().contains(Label.EmailChange_NoMPP)){
                    mppResult = null;
                }else if(e.getErrorMessage().contains(Label.EmailChange_MultipleMPPAccsResponse)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EmailChange_MultipleMPPAccsError));
                    return null;
                }
            }
        }
        
        if(accs.isEmpty() && mppResult != null && String.isNotBlank(oldEmail)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_NewEmailInMPP));
            return null;
        }else if(!accs.isEmpty() && TMGUtil.isDataValid(samResult.guid) && oldEmail != newEmail){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_NewEmailInSfdcSAM));
            return null;
        }else if(accs.isEmpty() && (samResult !=null && TMGUtil.isDataValid(samResult.guid)) && existingSamAccountGuid!=null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_DecommissionSAM));
            return null;
        }else if (accs.isEmpty() && String.isBlank(newEmail) && existingSamAccountGuid!=null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.EmailChange_DeleteEmailDecommissionSAM));
            return null;
        }
        else {
            String productType = (currentAccInfo.RecordType.Name == Constants.RECTYPE_INDIVSUB) ? Constants.PRODUCT_PREMIUM : Constants.PRODUCT_DIGITAL;
            //update sam, mpp and salesforce account with the new email address
            updateAccountEmail(currentAccInfo, productType,  newEmail, oldEmail);
            if(!ApexPages.hasMessages(ApexPages.Severity.ERROR)){
                if(isIframe){
                    iFrameSuccess = true;
                    return null;
                }else{
                    PageReference url = stdCon.view();
                    url.setRedirect(true);
                    return url;
                }
            }
        }
        return null;
    }
    
    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 05/10/2015
    Version - 1.0
    Function - method that syncs SAM and MPP account with Salesforce 
    #############Change Log#############
    Modified by         Version     Change Date
    Cristina Anghenie   1.1         11/12/2015  //remove encoding for email and first and last name because the values are encoded in the MPPInterfaceHTTP.UserManagesSingleUpdate
    Pawel Chrzanowski   1.2         11/03/2016  //modified to not change entitlements
    Pawel Chrzanowski   1.3         17/03/2016  //removed isEmailUpdate 
    Pawel Chrzanowski   1.4         19/05/2016  //modified updateSamAccount() execution to not use queueable
    Michal Szewczzyk    1.5         28/10/2016  //added MPP callout for Registrant Subscriber
    *************************************************************************************/
  public void updateAccountEmail(Account acc, String productType, String email, String oldEmail){
        MPPInterfaceHTTP mppHTTP = new MPPInterfaceHTTP();
        SAMUtil samUtil = new SAMUtil();
        acc.PersonEmail = email;
        Id registrantRecTypeId = RecordTypeUtility.getRecordTypeId(Account.SObjectType, Constants.ACCOUNT_REGISTRANT_RECORD_TYPE_NAME, Account.class.getName());  
        //remove guid if the new email is null
        if (String.isBlank(acc.PersonEmail)){
            acc.Guid__c = null;
        }
        try{
            //upsert SAM and MPP if is digital account and has transaction histories or is print and has subscriptions
            if((!acc.MPP_Transaction_Histories__r.isEmpty() && acc.recordTypeId == Constants.DigitalSubscriberRecordType()) || acc.recordTypeId == registrantRecTypeId ||
                (acc.recordTypeId == Constants.IndivSubscriberRecordType() && acc.Number_of_Subscriptions__c > 0)){
                //if there isn't one create a new SAM account
                if(String.isBlank(existingSamAccountGuid) && (samResult != null && samResult.guid == null) && String.isNotBlank(email)){
                    //get the guid from the newly create SAM account
                    String newGuid = samUtil.createSamAccount(acc, acc.Subscriber_Number__c, productType.toLowerCase(), false, true);
                    //add new guid to the account
                    acc.Guid__c = newGuid;
                    updateMPP = true;
                //otherwise update existing SAM account
                }else if (!String.isBlank(existingSamAccountGuid)){
                    //update SAM with null Entitlements and without using queueable
                    samUtil.updateSamAccount(acc, acc.Subscriber_Number__c, existingSamAccountGuid, productType.toLowerCase(), false, false);
                    //update guid on the account if there isn't the same as in SAM 
                    acc.Guid__c = (acc.Guid__c != existingSamAccountGuid) ? existingSamAccountGuid : acc.Guid__c;
                }else if (samResult != null){
                    //update SAM with null Entitlements and without using queueable
                    samUtil.updateSamAccount(acc, acc.Subscriber_Number__c, samResult.guid, productType.toLowerCase(), false, false);
                    //update guid on the account if there isn't the same as in SAM 
                    acc.Guid__c = (acc.Guid__c != samResult.guid) ? samResult.guid : acc.Guid__c;
                }


                //update MPP account only if there is already an existing account
                if(updateMPP ||  acc.recordTypeId == registrantRecTypeId){
                    mppHTTP.UserManageSingleUpdate(acc.Subscriber_Number__c, email, oldEmail, acc.Salutation, acc.FirstName, acc.LastName, acc.Guid__c);
                }
            }
            
            //AccountTriggerHandler.getInstance().bRunAPI = false;
            //update account
            //let AccountTriggerHandler update SAM Entitlements using queueable
            update acc;
            //AccountTriggerHandler.getInstance().bRunAPI = true;
        }catch(WebserviceUtil.SamException e) {
            if(e.getError().errorMessage.contains(Constants.EMAILCHANGE_SAMPASSPENDING)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EmailChange_SAMPasswordPending));
            }else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getError().errorMessage));
        }catch(MPPInterfaceHTTP.MPPInterfaceHTTPException e) {
            acc.PersonEmail = oldEmail;
            samUtil.updateSamAccount(acc, acc.Subscriber_Number__c, existingSamAccountGuid, productType.toLowerCase(), false, false);
            if(e.getErrorMessage().contains(Label.EmailChange_MultipleMPPAccsResponse)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EmailChange_MultipleMPPAccsError));
            }else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getErrorMessage()));
        }catch(System.Exception e){
            ApexPages.addMessages(e);
        }
    }
}