/* ------------------------------------------------------------------------------
   Name:        SubscriptionStatusInRenewalBatch.cls
   Description: Batch class to update subscription status to In Renewal

   Date         Version Author              Summary of Changes
   -----------  ------- -----------------   -------------------------------------
   26/11/2015   1.1     Cristina Anghenie   update subscription status to in renewal
   24/05/2016   1.2     Pawel Chrzanowski   modified logic
   22/07/2016   1.3     Pawel Chrzanowski   failed DML record ID fix
   22/08/2016   1.4     Wiktor Czykin       modified execute
   03/01/2017   1.5     Wiktor Czykin       modified constructor
   27/01/2017   1.6     Pawel Chrzanowski   modified finish() to use multiple emails custom setting
--------------------------------------------------------------------------------- */
public class SubscriptionStatusInRenewalBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Map<Id, String> mapFailedRecords = new Map<Id, String>();
    public static final Integer ERROR_LIMIT = 800;
    public Integer successCount = 0;
    public Integer failCount = 0;
    public Integer totalCount = 0;
    public Date currentRenewalDate = System.today();
    private Boolean bSendMessage = true;
    @TestVisible private Boolean bFailTest = false;

    /************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 25/05/2016
    Version - 1.1
    Function - batch constructors
    #############Change Log#############
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         04/01/2017 //removed the >0 condition
    *************************************************************************************/
    public SubscriptionStatusInRenewalBatch(Integer daysOffset, Boolean bSendMessage){
        if(daysOffset != null){
            currentRenewalDate = currentRenewalDate.addDays(-daysOffset);
        }
        if(bSendMessage != null){
            this.bSendMessage = bSendMessage;
        }
    }

    public SubscriptionStatusInRenewalBatch(){}

    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 26/11/2015
    Version - 1.0
    Function - method that queries all records that need status update to in renewal
    #############Change Log#############
    Modified by         Version     Change Date
    *************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC){
        Id schooldRecordTypeId = RecordTypeUtility.getRecordTypeId(Subscription__c.SObjectType, Constants.RECTYPE_SUBSCRIPTION_SCHOOLS, Subscription__c.class.getName());
        Date pastRenewalDate = Date.newInstance(2009,05,27);
        String query = 'SELECT Id, IF_In_Renewal_Value__c, Subscription_Status__c '+
                       'FROM Subscription__c '+
                       'WHERE ((IF_11_Week_Renewal_Update_Date_Hidden__c =: currentRenewalDate '+
                               'AND isContinuous__c = false '+
                               'AND Payment_Type__c != \'' + Constants.SUB_PMETHOD_DD  + '\') ' +
                       'OR (IF_DD_D03_Extraction_Date__c =: currentRenewalDate '+
                           'AND IF_11_Week_Renewal_Update_Date_Hidden__c >: pastRenewalDate) '+
                       'OR (IF_CCA_Extraction_Date__c =: currentRenewalDate '+
                           'AND isContinuous__c = true '+
                           'AND Payment_Type__c = \'' + Constants.SUB_PMETHOD_CC + '\' ' +
                           'AND IF_11_Week_Renewal_Update_Date_Hidden__c >: pastRenewalDate)) '+
                       'AND Subscription_Status__c = \'' + Constants.SSTATUS_ACTIVE + '\' ' +
                       'AND recordTypeId != \'' + schooldRecordTypeId + '\'';

        return Database.getQueryLocator(query);
    }

    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 26/11/2015
    Version - 1.0
    Function - method that updates subscription status to in renewal
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         24/05/2016  modified error handling
    Pawel Chrzanowski   1.2         22/07/2016  failed DML record ID fix
    Wiktor Czykin       1.3         22/08/2016  removed setting of bRunAPI = true
    *************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Subscription__c> lstSubscriptions){
        totalCount += lstSubscriptions.size();

        for(Subscription__c sub : lstSubscriptions){
            sub.Subscription_Status__c = Constants.SSTATUS_IN_RENEWAL;
        }

        if(this.bFailTest && Test.isRunningTest()){
            lstSubscriptions[0].Delivery_Type__c = Constants.DELIVERYTYPE_OTC;
        }

        if(!lstSubscriptions.isEmpty()){
            SubscriptionTriggerHandler.getInstance().bRunAPI = false;
            AccountTriggerHandler.getInstance().bRunAPI = false;
			Set<Id> setFailed = new Set<Id>();
            try{
                update lstSubscriptions;
            }catch(DmlException e){
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    failCount++;
                    Id subId = lstSubscriptions[e.getDmlIndex(i)].Id;
                    this.mapFailedRecords.put( subId, e.getDMLMessage(i));
                    setFailed.add(subId);
                }
            }

            if(!setFailed.isEmpty()){
                for(Subscription__c item : lstSubscriptions){
                    if(!setFailed.contains(item.Id) && mapFailedRecords.size() <= ERROR_LIMIT){
                        this.mapFailedRecords.put(item.Id, 'Failure because of failure on other records within the same batch.');
                    }
                }
            }else{
                this.successCount += lstSubscriptions.size();
            }
        }
    }

    /************************************************************************************
    Developer - Cristina Anghenie
    Date - 26/11/2015
    Version - 1.0
    Function - method that sends an email with all records there were failing up update ccExpiryDate field
    #############Change Log#############
    Modified by         Version     Change Date
    Pawel Chrzanowski   1.1         24/05/2016  modified sHtml and email condition
    Pawel Chrzanowski   1.2         27/01/2017  added multiple emails custom setting
    *************************************************************************************/
    public void finish(Database.BatchableContext BC){
        if(successCount == 0 && failCount == 0 && !bSendMessage) return;

        List<String> lstExtraTo = new List<String>();
        String errorRows = '';

        General__c recipient = General__c.getInstance(Constants.SUBSCRIPTION_STATUS_BATCH_ERROR_EMAILS);
        if(recipient != null && String.isNotBlank(recipient.Value__c)){
            lstExtraTo.addAll(recipient.Value__c.replace(' ', '').split(','));
        }

        for(Id res : mapFailedRecords.keySet()){
            errorRows += '<tr><td>' + res + '</td><td>' + mapFailedRecords.get(res) + '</td></tr>';
        }
        if(String.isNotBlank(errorRows)){
            errorRows = '<table><tr><td>Subscription ID</td><td>Errors</td></tr>' + errorRows + '</table>';
        }

        String sHtml = String.format(Label.Subscription_Status_Batch_Finish_email_content, new List<String>{String.valueOf(successCount) + '/' + String.valueOf(totalCount), String.valueOf(failCount) + '/' + String.valueOf(totalCount), errorRows});

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(Label.Subscription_Status_Batch_Finish_Email_Subject);
        email.setTargetObjectId(System.UserInfo.getUserId());
        if(!lstExtraTo.isEmpty()){
            email.setToAddresses(lstExtraTo);
        }
        email.setHTMLBody(sHtml);
        email.setSaveAsActivity(false);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}
