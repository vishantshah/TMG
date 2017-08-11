/**
* Author:       Michal Kwika (Accenture)
* Date:         08/09/2015
* Description:  this class is controller to the page Zuora_RevokeCancellation
*
* ******************* Change Log *******************
* Modified by           Change Date
* Michal Kwika          09/10/2015
* Michal Kwika          16/01/2016
* Mantas Grigaliunas    02/05/2017 modified onLoad() method
**/
public with sharing class Zuora_RevokeCancellationController {

    public Zuora__Subscription__c subscriptionItem {get; set;}
    private Zuora__CustomerAccount__c billingAccount {get; set;}
    public boolean isError {get; set;}
    private String currentSubscriptionId;
    private String billingAccountId;
    /*Zuora API Instance for calling into Zuora directly */
    static Zuora.zApi zapi = new Zuora.zApi();

    /***************************************************************************************
    Developer   Michal Kwika
    Date        08/09/2015
    Function    this is the controller
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Zuora_RevokeCancellationController() {
        this.isError = false;
        //get subscription Id
        if (System.currentPageReference().getParameters().containsKey('id')) {
            this.currentSubscriptionId = ApexPages.currentPage().getParameters().get('id');
        }

        if (System.currentPageReference().getParameters().containsKey('accid')) {
            this.billingAccountId = ApexPages.currentPage().getParameters().get('accid');
        }

        if (!String.isEmpty(this.currentSubscriptionId) && !String.isEmpty(this.billingAccountId)) {
            //get subscription

            this.subscriptionItem = [SELECT Name, Zuora__External_Id__c, Subscription_Type__c, Cancellation_Reason__c, Cancellation_Effective_Date_Time__c, Cancellation_Effective_Date_Time_String__c,
                                     Cancellation_Process_Date_Time__c, Cancellation_Process_Date_Time_String__c, Zuora__Version__c, Sub_Cancellation_Reason__c
                                     FROM Zuora__Subscription__c WHERE Id = :currentSubscriptionId LIMIT 1];



            //get billingaccount
            this.billingAccount = [SELECT Name, Zuora__Zuora_Id__c FROM Zuora__CustomerAccount__c WHERE Id = :billingAccountId];

        }

    }

    /***************************************************************************************
    Developer   Michal Kwika
    Date        08/09/2015
    Function    this is the main method to invoke all queries and DMLs
    ******************* Change Log *******************
    Modified by         Change Date
    Mantas Grigaliunas  02/05/2017  Added validation isRefundAllowed
    ****************************************************************************************/
    public PageReference onLoad() {
        //check if we found subscription
        if (this.subscriptionItem != null) {

            //check if subscription is allowed for refund
            if(!ZuoraSubscriptionCanceller.isRefundAllowed(subscriptionItem.Id)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ZuoraSubscriptionCanceller.errorMessage));
                this.isError = true;
                return null;
            }

            //subscription needs to be Amended type
            if (this.subscriptionItem.Zuora__Version__c > 1) {
                //login to zuora and search for amendment - try to delete it
                Boolean deletionSuccess = findDeleteAmendment();
                //if delete is success - reset value on Subscription and go back
                if (deletionSuccess) {
                    ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.INFO, Label.Cancellation_Subscription_Revoke_Amendment_Deleted);
                    ApexPages.addMessage(message);

                    Boolean checkReset = resetCancellationFields(this.subscriptionItem);
                    if (!checkReset) {
                        ApexPages.Message message2 = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cancellation_SFDC_Error);
                        ApexPages.addMessage(message2);
                        this.isError = true;
                    }
                }
                //if it's not - throw another error
                else {
                    ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cancellation_Subscription_Revoke_Zuora_Error);
                    ApexPages.addMessage(message);
                    this.isError = true;
                }

            }

            else {
                ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cancellation_Subscription_Revoke_Subtype);
                ApexPages.addMessage(message);
                this.isError = true;
            }
        }

        else {
            ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cancellation_Subscription_Revoke_Cannot_Load_Sub);
            ApexPages.addMessage(message);
            this.isError = true;
        }

        return null;
    }


    /***************************************************************************************
    Developer   Michal Kwika
    Date        08/09/2015
    Function    this is method to query for correct amendment and delete it
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Boolean findDeleteAmendment() {
        Boolean resultOfDeletion = false;

        List<Zuora.zObject> amendmentSubscriptions = new List <Zuora.zObject>();
        List<Zuora.zObject> zSubscriptions = new List <Zuora.zObject>();
        //get zuora Ids
        String amendmentId = '';
        String zuoraAccId = this.billingAccount.Zuora__Zuora_Id__c;
        String zuoraId = this.subscriptionItem.Zuora__External_Id__c;
        String nameOfSub = this.subscriptionItem.Name;
        //Zuora version of amendment
        Integer correctVersion = (Integer)(this.subscriptionItem.Zuora__Version__c - 1);

        if (!Test.isRunningTest()) {
            //Login to Zuora
            zapi.zlogin();
        }

        else {
            //create zSubscriptions
            Zuora.zObject zsub = new Zuora.zObject('Subscription');
            zsub.setValue('Id', 'someId');
            zsub.setValue('Version', 2);
            zSubscriptions.add(zsub);
        }

        //Create ZOQL query
        String zoql = '';
        String zoql2 = 'select id,originalid, version,cancelledDate,accountId,name from subscription where accountID = \'' + zuoraAccId + '\' and name = \'' + nameOfSub + '\'';

        if (!Test.isRunningTest()) {
            //get all versions of current subscription and find cncellation one
            zSubscriptions = zapi.zquery(zoql2);
        }

        if (zSubscriptions.size() > 0) {
            //the second last of subscriptions should be cancellation amendment
            System.debug('### Number of subs versions: ' + zSubscriptions.size());

            for (Zuora.zObject o : zSubscriptions) {
                Integer i = (Integer)o.getValue('Version');
                if (i == correctVersion) {
                    //get Id of correctSubscription  -we need id to find amendment object
                    amendmentId = (String)o.getValue('Id');
                }
            }
            String cAmendType = Constants.SUBSCRIPTION_AMENDMENT_CANCELLATION_TYPE;
            //zoql for amendment
            zoql = 'select name, subscriptionId, id, createdDate, type from Amendment where subscriptionId=\'' + amendmentId + '\' and type = \'' + cAmendType + '\'';

        }

        //Query for payments from Zuora
        if (!String.isEmpty(zoql) && !Test.isRunningTest()) {
            //get amendment
            amendmentSubscriptions = zapi.zquery(zoql);
            System.debug('### zquery : ' + zoql);
            System.debug('### Zuora Id in soql' + amendmentId +  ' correctVersion is ' + correctVersion);
            System.debug('### Amendments for Subscription:  ' + amendmentSubscriptions);
        }

        else if (Test.isRunningTest()) {
            //create some data
            Zuora.zObject amendObj = new Zuora.zObject('Amendment');
            amendObj.setValue('Id', 'pId');
            amendObj.setValue('SubscriptionId', 'SubscriptionId');
            amendmentSubscriptions.add(amendObj);
        }

        if (amendmentSubscriptions.size() > 0) {
            //delete Cancellation amendment
            List <String> lZuoraIds = new List <String>();
            String cancellationAmendId = (String)amendmentSubscriptions.get(0).getValue('Id');
            lZuoraIds.add(cancellationAmendId);

            if (!Test.isRunningTest()) {
                resultOfDeletion =  Zuora_Utility.deleteZuoraRecords(lZuoraIds, Constants.SUBSCRIPTION_AMENDMENT_ZUORA_OBJECT_NAME, zapi);
            }

            else {
                resultOfDeletion = true;
            }

        }

        return resultOfDeletion;
    }



    /***************************************************************************************
    Developer   Michal Kwika
    Date        08/09/2015
    Function    this is method to reset the values on Subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         09/10/2015
    ****************************************************************************************/
    public Boolean resetCancellationFields(Zuora__Subscription__c subscription) {
        if (subscription != null) {
            //resetting fields of subscription

            subscription.Cancellation_Reason__c = null;
            subscription.Sub_Cancellation_Reason__c = '';
            subscription.Cancellation_Process_Date_Time_String__c = '';
            subscription.Cancellation_Process_Date_Time__c = null;
            subscription.Cancellation_Effective_Date_Time_String__c = '';
            subscription.Cancellation_Effective_Date_Time__c = null;

            //trying to update and return if success
            Database.SaveResult saveResult = Database.Update(subscription);
            return saveResult.isSuccess();

        }

        return false;
    }

    /***************************************************************************************
    Developer   Michal Kwika
    Date        08/09/2015
    Function    this is method to redirect back to record
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Michal Kwika        1.1         16/01
    ****************************************************************************************/
    public PageReference backToRecord () {
        PageReference pageRef;
        if (System.currentPageReference().getParameters().containsKey(Constants.SF_ACCOUNT_ID_QUERY_STRING)) {
            pageRef = Page.Zuora_ManageSubscriptionDecision;
            pageRef.getParameters().put(Constants.ID_QUERY_STRING, ApexPages.currentPage().getParameters().get(Constants.SF_ACCOUNT_ID_QUERY_STRING));

        } else {
            pageRef = new PageReference('/' + this.currentSubscriptionId);

        }
        pageRef.setRedirect(true);

        return pageRef;
    }
}