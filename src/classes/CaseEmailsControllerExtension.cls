/************************************************************************************
Class Name   : CaseEmailsControllerExtension
Author       : Mantas Grigaliunas
Created Date : 09/09/2016
Function     : Controller class for visualforce page 'CaseEmails' which is build to 
               replace standard Emails related list on Case object with additional functionality
Change Log:
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
* Developer             Date         Description
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Wiktor Czykin         11/07/2017   Added forward link support
*************************************************************************************/
global with sharing class CaseEmailsControllerExtension {

    public Case thisCase { get; set; }
    public Boolean autoResponse { get; set; }
    public List<EmailMsgWrapper> emailMsgWrapperList { get; set; }
    public List<EmailMessage> emailMessageList { get; set; }
    public Integer INITIAL_RECORDS_NUMBER {
        get{ return 5; }
        set{ INITIAL_RECORDS_NUMBER = value; }
    }
    private final Integer RECORD_INCREASE = 5;
    @TestVisible private Integer currentRecordsNumber;

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    *************************************************************************************/
    public CaseEmailsControllerExtension(ApexPages.StandardController stdController) {

        autoResponse = false;
        currentRecordsNumber = INITIAL_RECORDS_NUMBER;

        emailMessageList = new List<EmailMessage>();
        emailMsgWrapperList = new List<EmailMsgWrapper>();

        Case ctrlCase = (Case)stdController.getRecord();
        if(ctrlCase != new Case()){
            thisCase = [SELECT Id, CaseNumber, ContactId FROM Case WHERE Id = :ctrlCase.Id LIMIT 1];
            getEmailMessages(INITIAL_RECORDS_NUMBER);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'The page is accessed without passing record id'));
        }
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Method to query case related email messages, apply filters and define EmailMsgWrapper
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void getEmailMessages(){
        if(emailMsgWrapperList.size() < INITIAL_RECORDS_NUMBER) 
            currentRecordsNumber = INITIAL_RECORDS_NUMBER;
        getEmailMessages(currentRecordsNumber);
    }

    public void getEmailMessages(Integer recordsLimit){

        emailMessageList = new List<EmailMessage>();
        emailMsgWrapperList = new List<EmailMsgWrapper>();
        
        String emailMsgQuery = 'SELECT Id, Status, Subject, HasAttachment,'
        + ' FromAddress, TextBody, Incoming, MessageDate, ToAddress'
        + ' FROM EmailMessage' 
        + ' WHERE ParentId = \'' + thisCase.Id + '\'';

        if(!autoResponse){
            String emailAddress = getGeneralCustomSetting(Constants.CASE_AUTORESPONSE_EMAIL_ADDRESS_SETTING);
            if(emailAddress != null){
                List<String> autoResponseEmailsList = new List<String>(emailAddress.split(';'));
                emailMsgQuery += ' AND FromAddress NOT IN :autoResponseEmailsList';
            }
        }
        
        emailMsgQuery += ' ORDER BY MessageDate DESC LIMIT 100';

        emailMessageList = Database.query(emailMsgQuery);

        if(recordsLimit > emailMessageList.size()) 
            recordsLimit = emailMessageList.size();

        for(Integer i = 0; i < recordsLimit; i++){
            EmailMessage msg = emailMessageList[i];
            emailMsgWrapperList.add(new EmailMsgWrapper(msg));
        }
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Method invoked in the CaseEmails to delete selected message
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    @RemoteAction
    global static void deleteMessage(String msgId){
        delete [SELECT Id FROM EmailMessage WHERE Id = :msgId];
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Returns formated url from custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public String getSendEmailUrl(){
        if(thisCase != null){
           return String.format(getGeneralCustomSetting(Constants.CASE_SEND_EMAIL_URL_SETTING), 
              new List<String>{ thisCase.ContactId, Contact.sObjectType.getDescribe().getKeyPrefix(), thisCase.Id, thisCase.Id });
           } else return null;
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Returns url from custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public String getReplyUrl(){
        if(thisCase != null){
           return getGeneralCustomSetting(Constants.CASE_EMAIL_REPLY_URL_SETTING) + thisCase.Id;
           } else return null;
    }

    /************************************************************************************
    Author       : Wiktor Czykin
    Created Date : 09/09/2016
    Function     : Returns url from custom setting for for Forward action
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public String getForwardUrl(){
        if(thisCase != null){
            return getGeneralCustomSetting(Constants.CASE_EMAIL_FORWARD_URL_SETTING);
        }else return null;
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Method to display more email messages records on Show More button link click
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public void showMore(){
        currentRecordsNumber += RECORD_INCREASE;
        getEmailMessages(currentRecordsNumber);
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Returns url from custom setting
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    public String getShowAllUrl(){
        if(thisCase != null){
           return getGeneralCustomSetting(Constants.CASE_EMAIL_GOTOLIST_URL_SETTING) + thisCase.Id;
           } return null;
    }

    /************************************************************************************
    Author       : Mantas Grigaliunas
    Created Date : 09/09/2016
    Function     : Method to get the custom setting from General__c and display the error if it does not exist
    Change Log:
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    * Developer    Date         Description
    * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    *************************************************************************************/
    private String getGeneralCustomSetting(String name){

        General__c setting = General__c.getInstance(name);

        if(setting != null){
            return setting.Value__c;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                String.format(Label.Case_Emails_Missing_Custom_Setting, new List<String>{name})));
            return null;
        }
    }

    public class EmailMsgWrapper{

        public EmailMessage eMsg { get; set; }
        public String initialText { get; set; }

        public EmailMsgWrapper(EmailMessage eMsg){
            this.eMsg = eMsg;
            this.initialText = substringTextBody(eMsg.TextBody == null ? '' : eMsg.TextBody);             
        }

        /************************************************************************************
        Author       : Mantas Grigaliunas
        Created Date : 09/09/2016
        Function     : Method to truncate email message body text which is displayed below subject
        Change Log:
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        * Developer    Date         Description
        * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
        *************************************************************************************/
        private String substringTextBody(String bodyText){

            if(bodyText.length() > 77) return bodyText.substring(0, 77) + '...';
            else return bodyText;
        }
    }
}