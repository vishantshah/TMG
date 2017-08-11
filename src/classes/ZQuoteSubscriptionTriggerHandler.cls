/**
* Author:       Sally ElGhoul (Tquila)
* Date:         9/07/2015
* Description:  Trigger handler for Zuora subscription Object
*
* ******************* Change Log *******************
* Modified by           Change Date
* Sally ElGhoul         30/03/2016  Catch exceptions to avoid sending ugly error messages to the administrator SUB-2988
* Wiktor Czykin         13/04/2016  //Changed OnAfterInsert - removed updateAccountMarketingPreferences()
* Lynette Lim           29/07/2016  //Workaround for Zuora 360 sync inconsistent behaviour to ensure Account status is sync with zSubscription status
* Wiktor Czykin         08/08/2016  //Modified account status update actions - made bulk safe. It also considers priority of statuses.
* Michal Szewczyk       22/08/2016  //Changed updateAccountDigitalStatus
*                                   But Account will still show wrong status if order of separate transactions does not match the order of subscription progress.
* Mantas Grigaliunas    10/10/2016  Modified OnAfterUpdate() and added new methods updateZuoraSubscriptionCampaignCode() and syncZuoraCampaignCode()
* Mantas Grigaliunas    01/12/2016  Added back updateAccountMarketingPreferences()
* Pawel Chrzanowski     08/02/2017  Added manageRestrictedOfferUsage()
* Wiktor Czykin         08/02/2017  Modified how account status is calculated - split into two methods as well so that we can call from other places
*                                   Also cleaned up and improved error handling
*                                   Mostly rewritten
* Pawel Chrzanowski     17/02/2017  Removed manageRestrictedOfferUsage() and added TMGUtil.createRestrictedOfferUsage()
* Wiktor Czykin         24/04/2017  Fix for upsert of logs exception
* Wiktor Czykin         09/06/2017  Added createSubscriptionIncentive() as afterInsert action
**/
public with sharing class ZQuoteSubscriptionTriggerHandler {

    private static ZQuoteSubscriptionTriggerHandler instance;
    private static List<WebService_Log__c> lstLogs = new List<WebService_Log__c>();
    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        09/07/2015
    Function    this function is called to return an instance of the trigger handler
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public static ZQuoteSubscriptionTriggerHandler getInstance() {
        if (instance == null) instance = new ZQuoteSubscriptionTriggerHandler();
        return instance;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        21/10/2015
    Function    //this function is called to handle on before insert
                //fill the subscription master and related to quote fields
                //this will be called just the first time because the field zqu__ZuoraSubscriptionID__c of the quote
                //has only value on new subscription qutoes, any amendments won't have this value
                //in case of amendments the related quote id will be updates from the send to zbilling code
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1            30/03/2016  Catch exceptions to avoid sending ugly error messages to the administrator SUB-2988
    ****************************************************************************************/
    public void onBeforeInsert(Zuora__Subscription__c[] newSubscriptions){
        this.linkSubscriptionsToQuotes(newSubscriptions);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        09/07/2015
    Function    this function is called to handle on after insert
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1         30/03/2016  Catch exceptions to avoid sending ugly error messages to the administrator SUB-2988
    Wiktor Czykin        1.2         13/04/2016  //removed marketing flags setting as cannot default them to true without customer consent
    Mantas Grigaliunas   1.3         01/12/2016  //added back the method updateAccountMarketingPreferences() call
    Pawel Chrzanowski    1.4         08/02/2017  Added manageRestrictedOfferUsage()
    Pawel Chrzanowski    1.5         17/02/2017  Removed manageRestrictedOfferUsage() and added TMGUtil.createRestrictedOfferUsage()
    Wiktor Czykin        1.6        24/03/2017  Added new insertLogs() method
    ****************************************************************************************/
    public void OnAfterInsert(Zuora__Subscription__c[] newSubscriptions, Map<Id, Zuora__Subscription__c> newSubscriptionsMap){
        this.updateAccountDigitalStatus(null, newSubscriptionsMap);
        this.updateAccountMarketingPreferences(newSubscriptions);
        TMGUtil.createRestrictedOfferUsage(newSubscriptionsMap.keySet());
        this.createSubscriptionIncentive(newSubscriptions);
        this.insertLogs();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        10/07/2015
    Function    this function is called to handle on after update
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul        1.1        30/03/2016  Catch exceptions to avoid sending ugly error messages to the administrator SUB-2988
    Mantas Grigaliunas   1.2        10/10/2016  Added syncZuoraCampaignCode() method call
    Wiktor Czykin        1.3        24/03/2017  Added new insertLogs() method
    ****************************************************************************************/
    public void OnAfterUpdate(Zuora__Subscription__c[] oldSubscriptions, Zuora__Subscription__c[] updatedSubscriptions, Map<ID, Zuora__Subscription__c> oldSubscriptionsMap, Map<ID, Zuora__Subscription__c> newSubscriptionsMap){
        this.clearMarketingPreferences(oldSubscriptionsMap, newSubscriptionsMap);
        this.syncZuoraCampaignCode(oldSubscriptionsMap, updatedSubscriptions);
        this.updateAccountDigitalStatus(oldSubscriptionsMap, newSubscriptionsMap);
        this.insertLogs();
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        27/07/2015
    Function    this function is called to handle on before update
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Sally ElGhoul       1.1         30/03/2016  Catch exceptions to avoid sending ugly error messages to the administrator SUB-2988
    Lynette Lim         1.2         29/07/2016  Workaround for Zuora 360 sync inconsistent behaviour to ensure Account Digital Status is sync with zSubscription Status
    ****************************************************************************************/
    public void OnBeforeUpdate(Zuora__Subscription__c[] oldSubscriptions, Zuora__Subscription__c[] updatedSubscriptions, Map<ID, Zuora__Subscription__c> oldSubscriptionsMap, Map<ID, Zuora__Subscription__c> newSubscriptionsMap){
        this.handleCancelledSubscriptionsFields(oldSubscriptionsMap, updatedSubscriptions);
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        10/07/2015
    Function    this function is called to clear the account marketing
    ******************* Change Log *******************
    Modified by         Change Date
    Wiktor Czykin       09/02/2017  //rewritten    
    Wiktor Czykin       24/03/2017  //moved logs insert to separate method     
    ****************************************************************************************/
    private void clearMarketingPreferences(Map<Id, Zuora__Subscription__c> mapOld, Map<Id, Zuora__Subscription__c> mapNew){
        List<Account> lstAccountsToUpdate = new List<Account>();
        Set<Id> setAccountIds = new Set<Id>();
        for(Zuora__Subscription__c sub : mapNew.values()){
            Zuora__Subscription__c oldSub = mapOld.get(sub.id);
            if(sub.Zuora__Status__c != oldSub.Zuora__Status__c && sub.Zuora__Status__c == Constants.SUBSCRIPTION_CANCELLED_STATUS && !setAccountIds.contains(sub.Zuora__Account__c)){
                lstAccountsToUpdate.add(new Account(Id = sub.Zuora__Account__c,
                                                    TMG_Loyalty_SMS__c = 0,
                                                    TMG_Loyalty_Email__c = 0,
                                                    TMG_Loyalty_Mail__c = 0,
                                                    TMG_Loyalty_Phone__c = 0
                ));
                setAccountIds.add(sub.Zuora__Account__c);
            }
        }
        Map<Id, String> mapFailedAccounts = new Map<Id, String>();
        try{
            update lstAccountsToUpdate;
        }catch(DmlException e){
            for(Integer i = 0; i < e.getNumDml(); i++){
                Id failedId = lstAccountsToUpdate[e.getDmlIndex(i)].Id;
                if(mapFailedAccounts.containsKey(failedId)){
                    mapFailedAccounts.put(failedId, mapFailedAccounts.get(failedId)+','+e.getDMLMessage(i));
                }else{
                    mapFailedAccounts.put(failedId, e.getDMLMessage(i));
                }
            }
        } 
        if(!mapFailedAccounts.isEmpty()){
            lstLogs.add(TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_INBOUND, Constants.LOG_TRIGGER_ENDPOINT, Constants.LOG_TRIGGER_ZUORA_SUBSCRIPTION_ERROR+'-marketing flags update', mapFailedAccounts, null, null, null));
            for(Zuora__Subscription__c sub : mapNew.values()){
                if(sub.Zuora__Account__c != null && mapFailedAccounts.containsKey(sub.Zuora__Account__c)){
                    sub.addError(Label.ZSubscription_Trigger_Account_update_failure + mapFailedAccounts.get(sub.Zuora__Account__c));
                }
            }
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        28/07/2015
    Function    this function is called to update the cancelled subscription fields
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void handleCancelledSubscriptionsFields(Map<Id,Zuora__Subscription__c> mapOldSubscriptions, list<Zuora__Subscription__c> lstNewSubscriptions){
        for(Zuora__Subscription__c subscriptionObj : lstNewSubscriptions){
            if(subscriptionObj.Zuora__Status__c != mapOldSubscriptions.get(subscriptionObj.Id).Zuora__Status__c && subscriptionObj.Zuora__Status__c == Constants.SUBSCRIPTION_CANCELLED_STATUS){
                //check that the effective date time string is not empty
                if(subscriptionObj.Cancellation_Effective_Date_time_String__c != null){
                    //fill the cancellation effecteve date time based on the cancellation effective date string value
                    subscriptionObj.Cancellation_Effective_Date_Time__c=Datetime.valueOf(subscriptionObj.Cancellation_Effective_Date_time_String__c);
                    //check if the cancellation effective date time is in the future change the subscription status from cancelled to pending cancellation
                    if(subscriptionObj.Cancellation_Effective_Date_Time__c>Datetime.now()){
                        subscriptionObj.Zuora__Status__c = Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS;
                    }
                }

                //fill the cancellation process date time field if empty and if the Cancellation_Process_Date_Time_String__c is not empty
                if(subscriptionObj.Cancellation_Process_Date_Time__c==null && subscriptionObj.Cancellation_Process_Date_Time_String__c!=null){
                    subscriptionObj.Cancellation_Process_Date_Time__c=Datetime.valueOf(subscriptionObj.Cancellation_Process_Date_Time_String__c);
                }
            }
        }
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Tquila)
    Date        5/08/2015
    Function    this function is called to update the account digital status based on the subscription status
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Wiktor Czykin       1.1         08/08/2016  //refactored to be actual action method
    Michal Szewczyk     1.2         22/08/2016  //Changed some Replatform Digital Statuses for Active
    Wiktor Czykin       1.3         08/02/2017  //Moved part of the logic to external method
    Wiktor Czykin       1.4         24/03/2017  //moved logs insert to separate method     
    ****************************************************************************************/
    private void updateAccountDigitalStatus(Map<Id,Zuora__Subscription__c> mapOldSubscriptions, Map<Id,Zuora__Subscription__c> mapNewSubscriptions){
       Set<Id> setEligibleForUpdate = new Set<Id>();
        if(mapOldSubscriptions == null){
            for(Zuora__Subscription__c subscription : mapNewSubscriptions.values()){
                if(String.isNotBlank(subscription.Zuora__Status__c) && subscription.Zuora__Account__c != null && subscription.Zuora__Version__c == 1){
                    setEligibleForUpdate.add(subscription.Zuora__Account__c);
                }
            }
        }else{
            for(Zuora__Subscription__c subscription : mapNewSubscriptions.values()){
                Zuora__Subscription__c oldSubscription = mapOldSubscriptions.get(subscription.Id);
                if(subscription.Zuora__Account__c != null && String.isNotBlank(subscription.Zuora__Status__c)
                    && (subscription.Zuora__Status__c != oldSubscription.Zuora__Status__c
                        || subscription.Subscription_Product__c != oldSubscription.Subscription_Product__c
                        || subscription.PromoCode__c != oldSubscription.PromoCode__c)){
                    setEligibleForUpdate.add(subscription.Zuora__Account__c);
                }
            }
        }
        if(!setEligibleForUpdate.isEmpty()){
            Map<Id, String> mapErrors = resyncAccountDigitalStatus(setEligibleForUpdate);
            if(!mapErrors.isEmpty()){
                lstLogs.add(TMGUtil.newLogWebServiceRequestSerialized(Constants.DIRECTION_INBOUND, Constants.LOG_TRIGGER_ENDPOINT, Constants.LOG_TRIGGER_ZUORA_SUBSCRIPTION_ERROR+'-digital status sync', mapErrors, null, null, null));
                for(Zuora__Subscription__c subscription : mapNewSubscriptions.values()){
                    if(subscription.Zuora__Account__c != null && mapErrors.containsKey(subscription.Zuora__Account__c)){
                        subscription.addError(Label.ZSubscription_Trigger_Account_update_failure + mapErrors.get(subscription.Zuora__Account__c));
                    }
                }
            }
        }
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        08/02/2017
    Function    this function is called to update the account digital status based on the subscriptions status
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    public Map<Id, String> resyncAccountDigitalStatus(Set<Id> setAccounts){
        if(setAccounts == null || setAccounts.isEmpty()) return null;
        List<Zuora__Subscription__c> lstSubs = [select Id, Zuora__Account__c, Zuora__Status__c from Zuora__Subscription__c where Zuora__Account__c in :setAccounts];
        Map<Id, Set<String>> mapAccountsToSubscriptionStatuses = new Map<Id, Set<String>>();
        for(Zuora__Subscription__c sub : lstSubs){
            Set<String> setLocal = mapAccountsToSubscriptionStatuses.get(sub.Zuora__Account__c);
            if(setLocal == null){
                setLocal = new Set<String>();
            }
            setLocal.add(sub.Zuora__Status__c);
            System.assert(!setLocal.isEmpty());
            mapAccountsToSubscriptionStatuses.put(sub.Zuora__Account__c, setLocal);
        }
        Map<Id, String> mapFailedAccounts = new  Map<Id, String>();
        if(!mapAccountsToSubscriptionStatuses.isEmpty()){
            List<Account> lstAccountsToUpdate = new List<Account>();
            for(Id accountId : mapAccountsToSubscriptionStatuses.keySet()){
                Set<String> setStatus = mapAccountsToSubscriptionStatuses.get(accountId);
                String sStatus = '';
                if(setStatus.contains(Constants.SUBSCRIPTION_ACTIVE_STATUS)){
                    sStatus = Constants.SUBSCRIBER_ACTIVE_STATUS;
                }else if(setStatus.contains(Constants.SUBSCRIPTION_PENDING_CANCELLATION_STATUS)){
                    sStatus = Constants.SUBSCRIBER_ACTIVE_STATUS;
                }else if(setStatus.contains(Constants.SUBSCRIPTION_CANCELLED_STATUS)){
                    sStatus = Constants.SUBSCRIBER_INACTIVE_STATUS;
                }else if(setStatus.contains(Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS)){
                    sStatus = Constants.SUBSCRIBER_ACTIVE_STATUS;
                }
                if(String.isNotBlank(sStatus)){
                    lstAccountsToUpdate.add(new Account(Id = accountId, Replatform_Digital_Status__c = sStatus));
                }
            }
            if(!lstAccountsToUpdate.isEmpty()){
                try{
                    update lstAccountsToUpdate;
                }catch(DmlException e){
                    for(Integer i = 0; i < e.getNumDml(); i++){
                        Id failedId = lstAccountsToUpdate[e.getDmlIndex(i)].Id;
                        if(mapFailedAccounts.containsKey(failedId)){
                            mapFailedAccounts.put(failedId, mapFailedAccounts.get(failedId)+','+e.getDMLMessage(i));
                        }else{
                            mapFailedAccounts.put(failedId, e.getDMLMessage(i));
                        }
                    }
                }
            }
        }
        return mapFailedAccounts;
    }

    /***************************************************************************************
    Developer   Sally ElGhoul (Accenture)
    Date        21/10/2015
    Function    this function is called to Link subscription record to quote record
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void linkSubscriptionsToQuotes(Zuora__Subscription__c[] lstSubscription){
        //set to save the subscription ids in Zuora
        Set<String> setZuoraSubscriptionIds = new Set<String>();
        //map to link ZuoraSubscription Id and Sf quote Id
        Map<String,Id> mapZuoraSubscriptionIdsQuoteIds = new Map<String, Id>();
        for(Zuora__Subscription__c zuoraSubscriptionObj : lstSubscription){
            if(zuoraSubscriptionObj.Zuora__Zuora_Id__c != null){
                setZuoraSubscriptionIds.add(zuoraSubscriptionObj.Zuora__Zuora_Id__c);
            }
        }

        //prepare the map between the quote id and zuora subscription id
        if(setZuoraSubscriptionIds.size()>0){
            for(zqu__Quote__c quoteObj : [select Id, zqu__ZuoraSubscriptionID__c from zqu__Quote__c where zqu__ZuoraSubscriptionID__c in :setZuoraSubscriptionIds]){
                if(!mapZuoraSubscriptionIdsQuoteIds.containsKey(quoteObj.zqu__ZuoraSubscriptionID__c)){
                    mapZuoraSubscriptionIdsQuoteIds.put(quoteObj.zqu__ZuoraSubscriptionID__c, quoteObj.Id);
                }
            }
        }

        //loop on subscriptions and fill the master quote and related to quote fields
        for(Zuora__Subscription__c zuoraSubscriptionObj : lstSubscription){
            if(mapZuoraSubscriptionIdsQuoteIds.containskey(zuoraSubscriptionObj.Zuora__Zuora_Id__c)){
                //this will be null only for the first time the subscription is created
                zuoraSubscriptionObj.Master_Quote__c=mapZuoraSubscriptionIdsQuoteIds.get(zuoraSubscriptionObj.Zuora__Zuora_Id__c);
                //relate the subscription to the coressponding quote
                zuoraSubscriptionObj.Related_Quote__c=mapZuoraSubscriptionIdsQuoteIds.get(zuoraSubscriptionObj.Zuora__Zuora_Id__c);
            }
        }
    }

    /*************************************************************************************** 
    Developer   Mantas Grigaliunas
    Date        09/10/2016
    Function    Check if Campaign Code changes and calls method to update it in Zuora 
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void syncZuoraCampaignCode(Map<Id, Zuora__Subscription__c> oldSubscriptionsMap, Zuora__Subscription__c[] updatedSubscriptions){
         Map<String, String> mapUpdatedSubsWithCampaignCode = new  Map<String, String>();

        for(Zuora__Subscription__c subscriptionObj : updatedSubscriptions){
            if(subscriptionObj.CampaignCode__c != oldSubscriptionsMap.get(subscriptionObj.Id).CampaignCode__c){
                mapUpdatedSubsWithCampaignCode.put(subscriptionObj.Zuora__Zuora_Id__c, subscriptionObj.CampaignCode__c);
            }
        }

        if(!mapUpdatedSubsWithCampaignCode.isEmpty()){
            updateZuoraSubscriptionCampaignCode(mapUpdatedSubsWithCampaignCode);
        }
    } 

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        09/06/2017
    Function    create relationship between subscription and incentive on subscription creation when:
                - subscription is active or pending activation
                - subscription has tcode and offer set
                - tcode and offer junction has only one related incentive that is Auto_Assign_for_Zuora_Subscription__c
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private void createSubscriptionIncentive(List<Zuora__Subscription__c> lstNew){
        General__c setting = General__c.getInstance(Constants.GENERAL_AUTO_ASSIGN_INCENTIVE_FOR_DIGITAL);
        if(setting == null || !setting.Value_Boolean__c) return;

        Set<String> setTcodeNames = new Set<String>();
        Set<String> setPromoCodes = new Set<String>();
        List<Zuora__Subscription__c> lstToProcess = new List<Zuora__Subscription__c>();

        for(Zuora__Subscription__c zs : lstNew){
            if(String.isNotBlank(zs.CampaignCode__c) && String.isNotBlank(zs.PromoCode__c) && 
                (zs.Zuora__Status__c == Constants.SUBSCRIPTION_ACTIVE_STATUS || zs.Zuora__Status__c == Constants.SUBSCRIPTION_PENDING_ACTIVATION_STATUS)){

                setTcodeNames.add(zs.CampaignCode__c);
                setPromoCodes.add(zs.PromoCode__c);
                lstToProcess.add(zs);
            }
        }
        
        Id recordTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_ZOFFER, TCode_Product__c.class.getName());


        List<TCode_Product__c> lstTCodeProducts = [SELECT   Id, 
                                                            Offer__c,
                                                            Offer__r.Name, 
                                                            TCodeManagement__c,
                                                            TCodeManagement__r.Name,
                                                            (SELECT Id, Incentive__c FROM TCode_Product_Incentives__r WHERE Auto_Assign_for_Zuora_Subscription__c = true limit 2) 
                                                        FROM TCode_Product__c
                                                        WHERE RecordTypeId = :recordTypeId
                                                        AND TCodeManagement__r.Name IN :setTcodeNames 
                                                        AND Offer__r.Name IN :setPromoCodes];

        Map<String, Id> mapTCodeOfferToIncentive = new Map<String, Id>();
        for(TCode_Product__c tp : lstTCodeProducts){
            if(tp.TCode_Product_Incentives__r.size() == 1){
                mapTCodeOfferToIncentive.put((''+tp.Offer__r.Name+tp.TCodeManagement__r.Name), tp.TCode_Product_Incentives__r[0].Incentive__c);
            }
        }
        if(mapTCodeOfferToIncentive.isEmpty()) return;

        List<SubscriptionIncentiveAssociation__c> lstToInsert = new List<SubscriptionIncentiveAssociation__c>();
        Date dToday = Date.today();
        for(Zuora__Subscription__c zs : lstToProcess){
            Id incentiveId = mapTCodeOfferToIncentive.get(zs.PromoCode__c+zs.CampaignCode__c);
            if(incentiveId != null){
                lstToInsert.add(new SubscriptionIncentiveAssociation__c(
                            Date_Requested__c = dToday,
                            Incentive__c = incentiveId,
                            Reason__c = Constants.INCENTIVE_REASON_ACQUISITION,
                            Subscriber__c = zs.Zuora__Account__c,
                            Zuora_Subscription__c = zs.Id
                    ));
            }
        }

        if(!lstToInsert.isEmpty()){
            Map<Id, String> mapErrors = new Map<Id, String>(); 
            try{
                insert lstToInsert;
            }catch(DmlException e){
                for(Integer i = 0; i < e.getNumDml(); i++) {
                    Id failedId = lstToInsert[e.getDmlIndex(i)].Zuora_Subscription__c;
                    if(mapErrors.containsKey(failedId)){
                        mapErrors.put(failedId, mapErrors.get(failedId)+','+e.getDMLMessage(i));
                    }else{
                        mapErrors.put(failedId, e.getDMLMessage(i));
                    }
                }
            }
            if(!mapErrors.isEmpty()){
                for(Zuora__Subscription__c zs : lstToProcess){
                    String sError = mapErrors.get(zs.Id);
                    if(String.isNotBlank(sError)){
                        zs.addError(sError);
                    }
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer   Mantas Grigaliunas
    Date        09/10/2016
    Function    Updates Campaign Codes on Zuora
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    @future(callout=true)
    public static void updateZuoraSubscriptionCampaignCode(Map<String, String> mapUpdatedSubsWithCampaignCode){
        String zlog = TMGUtil.newZuoraWebServiceLog('updateZuoraSubscriptionCampaignCode', 'ZQuoteSubscriptionTriggerHandler', mapUpdatedSubsWithCampaignCode);
        List<Zuora.zApi.SaveResult> results;
        Zuora.zApi zApi = new Zuora.zApi();

        try{
            List<Zuora.zObject> lstSubscription = new List<Zuora.zObject>();
            for(String zId : mapUpdatedSubsWithCampaignCode.keySet()){
                Zuora.zObject zuoraSub = new Zuora.zObject(Constants.ZUORA_ZBILLING_SUBSCRIPTION_OBJECT_NAME);
                zuoraSub.setValue(Constants.ZUORA_ZBILLING_SUBSCRIPTION_ID_FIELD_NAME, zId);
                zuoraSub.setValue(Constants.ZUORA_SUB_CAMPAIGN_CODE_FIELD_NAME, mapUpdatedSubsWithCampaignCode.get(zId));
                lstSubscription.add(zuoraSub);  
            }

            //Login to Zuora and update Subscriptions with new Campaign Code
            zApi.zlogin();

            List<String> errorsList = ZuoraUtilities.analyzeSaveResult(ZuoraUtilities.updateZuoraObjects(zApi, lstSubscription));
            if (!errorsList.isEmpty()) {
                TMGUtil.insertZuoraWebServiceLog(zlog, errorsList);
            }
            
        } catch(Exception e){
            //save server response log
            TMGUtil.insertZuoraWebServiceLog(zlog, e.getMessage(), e.getStackTraceString());
        }
    }

    /*************************************************************************************** 
    Developer   Sally ElGhoul (Tquila)
    Date        09/07/2015
    Function    this function is called to update the account marketing
    ******************* Change Log *******************
    Modified by         Version     Change Date
    Mantas Grigaliunas  1.1         01/12/2016  Added back and improved the method
    ****************************************************************************************/
    private void updateAccountMarketingPreferences(Zuora__Subscription__c[] newSubscriptions){
        Set<Id> setAccountIds = new Set<Id>();

        for(Zuora__Subscription__c subscriptionObj : newSubscriptions){
            if(!setAccountIds.contains(subscriptionObj.Zuora__Account__c) && subscriptionObj.Zuora__Version__c == 1){
                setAccountIds.add(subscriptionObj.Zuora__Account__c);
            }
        }

        if(setAccountIds.size() > 0){

            List<Account> lstAccounts = [ SELECT TMG_Loyalty_Email__c, TMG_Loyalty_Mail__c, TMG_Loyalty_Phone__c,
                TMG_Loyalty_SMS__c, PersonMobilePhone, PersonHomePhone, PersonEmail, PersonMailingStreet 
                FROM Account WHERE Id IN :setAccountIds];
            for(account accountObj : lstAccounts){
                //1. If the mobile number is entered on the account then the SMS tick box should be ticked
                if(!String.isEmpty(accountObj.PersonMobilePhone)){
                    accountObj.TMG_Loyalty_SMS__c = 1;
                }
                //2.Email and Post tick boxes should be ticked 
                if(!String.isEmpty(accountObj.PersonEmail)){
                    accountObj.TMG_Loyalty_Email__c = 1;
                }
                if(!String.isEmpty(accountObj.PersonMailingStreet)){
                    accountObj.TMG_Loyalty_Mail__c = 1;
                }
                //3. Phone tick box should be ticked if landline number is entered on the account
                if(!String.isEmpty(accountObj.PersonHomePhone)){
                    accountObj.TMG_Loyalty_Phone__c = 1;
                }
            }
            
            if(!lstAccounts.isEmpty()){
                Map<Id, String> mapFailedAccounts = new Map<Id, String>();
                try{
                    update lstAccounts;
                }catch(DmlException e){
                    for(Integer i = 0; i < e.getNumDml(); i++){
                        Id failedId = lstAccounts[e.getDmlIndex(i)].Id;
                        if(mapFailedAccounts.containsKey(failedId)){
                            mapFailedAccounts.put(failedId, mapFailedAccounts.get(failedId)+','+e.getDMLMessage(i));
                        }else{
                            mapFailedAccounts.put(failedId, e.getDMLMessage(i));
                        }
                    }
                }

                if(!mapFailedAccounts.isEmpty()){
                    for(Zuora__Subscription__c sub : newSubscriptions){
                        if(mapFailedAccounts.containsKey(sub.Zuora__Account__c)){
                            sub.addError(mapFailedAccounts.get(sub.Zuora__Account__c));
                        }
                    }
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer   Wiktor Czykin
    Date        24/03/2017
    Function    just insert webservice logs if any
    ******************* Change Log *******************
    Modified by     Change Date
    ****************************************************************************************/
    private void insertLogs(){
        if(!lstLogs.isEmpty()){
            for(WebService_Log__c wl : lstLogs){
                wl.Id = null;
            }
            insert lstLogs;
        }
    }
} 