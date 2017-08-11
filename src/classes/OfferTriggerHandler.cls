/**
* @author Wiktor Czykin
* @date 14/03/2017
* @description
*#############Change Log#############
*Modified by    Version     Change Date
**/
public class OfferTriggerHandler {

    public static OfferTriggerHandler instance;
    public Boolean isExecuting = false;
    private Id tmgSystemProfileId;
    private Id tmgWebApiProfileId;
    @TestVisible private Boolean bRunCoreApiCallouts = false;

    public static OfferTriggerHandler getInstance() {
        if (instance == null) instance = new OfferTriggerHandler();
        return instance;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 31/03/2017
    Function - constructor - init required params for execution
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public OfferTriggerHandler(){
        this.tmgSystemProfileId = Constants.getTMGSystemProfileId();
        this.tmgWebApiProfileId = Constants.getTMGWebApiProfileId();
        Application_Settings__c coreApiSetting = Application_Settings__c.getInstance(Constants.FIRE_CORE_API_OFFERS_CALLOUT);
        if(coreApiSetting != null && String.isNotBlank(coreApiSetting.Value__c) && Boolean.valueOf(coreApiSetting.Value__c)){
            this.bRunCoreApiCallouts = true;
        }
    }

    public void onBeforeInsert(List<Offer__c> lstNewRecords) {
        this.populateUniquenessCheck(lstNewRecords);
    }

    public void onBeforeUpdate(Map<Id, Offer__c> mapOldRecord, List<Offer__c> lstNewRecords) {
        this.populateUniquenessCheck(lstNewRecords);
    }

    public void onAfterInsert(List<Offer__c> lstNewRecords){
        if (!this.isExecuting) {
            this.isExecuting = true;
                if(this.bRunCoreApiCallouts){
                    this.sendApiNotification(Constants.NEW_RECORD_CREATED_ACTION_NAME, lstNewRecords);
                }
            this.isExecuting = false;
        }
    }

    public void onAfterUpdate(Map<Id, Offer__c> mapOldRecord, List<Offer__c> lstNewRecords){
        if (!this.isExecuting) {
            this.isExecuting = true;
                if(this.bRunCoreApiCallouts){
                    this.sendApiNotification(Constants.UPDATED_RECORD_ACTION_NAME, lstNewRecords);
                }
            this.isExecuting = false;
        }
    }

    public void onAfterDelete(List<Offer__c> lstOldRecords){
        if (!this.isExecuting) {
            this.isExecuting = true;
                if(this.bRunCoreApiCallouts){
                    this.sendApiNotification(Constants.DELETED_RECORD_ACTION_NAME, lstOldRecords);
                }
            this.isExecuting = false;
        }
    }

    public void onAfterUndelete(List<Offer__c> lstNewRecords){
        this.onAfterInsert(lstNewRecords);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 31/03/2017
    Function - populate unique field with uniqueness factor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void populateUniquenessCheck(List<Offer__c> lstOffers){
        for(Offer__c o : lstOffers){
            o.Offer_Name_Uniqueness__c = o.Name;
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 31/03/2017
    Function - populate unique field with uniqueness factor
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void sendApiNotification(String sAction, List<Offer__c> lstOffers){
        Set<Id> setIds = new Set<Id>();
        for(Offer__c offer : lstOffers){
            setIds.add(offer.Id);
        }
        Id userProfileId = UserInfo.getProfileId();
        if(userProfileId != this.tmgWebApiProfileId && userProfileId != this.tmgSystemProfileId){
            CoreAPICalloutUtility.sendBulkEvents(sAction, Offer__c.class.getName(), setIds);
        }
    }
}
