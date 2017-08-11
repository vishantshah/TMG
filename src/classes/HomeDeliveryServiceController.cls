/**
* @author Wiktor Czykin 
* @date 17/07/2017
* @description Page to create new individual subscriber and related Home Delivery Voucher (of Home Delivery Service type)
*#############Change Log#############
*Modified by     Version     Change Date
*/
public with sharing class HomeDeliveryServiceController {
    
    public AccountCreateEditComponentController accEditController{get;set;}
    public Home_Delivery_Voucher__c homeDeliveryItem{get;set;}
    
    @TestVisible private static Boolean bForceSamCreation = false;

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - constructor - inits required objects instances
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public HomeDeliveryServiceController(ApexPages.StandardController stdCtrl) {
        this.accEditController = new AccountCreateEditComponentController();
        this.homeDeliveryItem = new Home_Delivery_Voucher__c(
            RecordTypeId = RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName())
        );
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - executes related account edit component save method and saves Home Delivery Voucher record
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public PageReference saveDetails(){
        String sEmail = this.accEditController.getAccount().PersonEmail;
        String sGuid;
        Boolean bCreateSAMAccount = false;
        String sSamError = '';

        if(String.isNotBlank(sEmail)){
            try{
                sGuid = SAMUtil.checkEmailInSAM(sEmail);
                if(String.isBlank(sGuid)){
                    bCreateSAMAccount = true;
                }
            }catch(Exception e){
                sSamError += e.getMessage();
                bCreateSAMAccount = false;
            }
        }

        this.accEditController.setGuid(sGuid);
        
        Savepoint sp = Database.setSavepoint();
        this.accEditController.saveAccount();
        if(this.accEditController.getAccount().Id == null){
            return null;
        }

        this.mapAccountToHomeDeliveryVoucher();
        try{
            insert this.homeDeliveryItem;
        }catch(DmlException e){
            ApexPages.addMessages(e);
            Database.rollback(sp);
            this.accEditController.getAccount().Id = null;  
            return null;
        }
        
        if(bCreateSAMAccount || (Test.isRunningTest() && bForceSamCreation)){
            SAMUtil.createSamAccount(this.accEditController.getAccount().Id);
        }
        if(String.isNotBlank(sSamError)){
            TMGUtil.logWebServiceRequestSerialized(Constants.DIRECTION_OUTBOUND, 'SAM', 'isExistingSAMAccount', this.accEditController.getAccount(), sSamError, this.homeDeliveryItem.Id, null);
        }
        return new PageReference('/'+this.homeDeliveryItem.Id);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - executes related account edit component save method and saves Home Delivery Voucher record
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    public PageReference saveDetailsAndNew(){
        PageReference pr = this.saveDetails();
        if(pr != null){
            pr = Page.HomeDeliveryService;
            pr.setRedirect(true);
        }
        return pr;
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/07/2017
    Function - maps all account fields and/or their dependencied to Home Delivery Record
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void mapAccountToHomeDeliveryVoucher(){
        Account acc = this.accEditController.getAccount();
        this.homeDeliveryItem.Account__c = acc.Id;
        this.homeDeliveryItem.Email__c = acc.PersonEmail;
        this.homeDeliveryItem.First_Name__c = acc.FirstName;
        this.homeDeliveryItem.Last_Name__c = acc.LastName;
        this.homeDeliveryItem.Mailing_Address__c = acc.PersonMailingStreet;
        this.homeDeliveryItem.Mailing_County__c = acc.PersonMailingState;
        this.homeDeliveryItem.Mailing_Postal_Code__c = acc.PersonMailingPostalCode.toUpperCase();
        this.homeDeliveryItem.Mailing_Town__c = acc.PersonMailingCity;
        this.homeDeliveryItem.Marketing_Preference_Email__c = acc.TMG_Promo_Email__c == 1?true:false;
        this.homeDeliveryItem.Marketing_Preference_Phone__c = acc.TMG_Promo_Phone__c == 1?true:false;
        this.homeDeliveryItem.Marketing_Preference_Post__c = acc.TMG_Promo_Post__c == 1?true:false;
        this.homeDeliveryItem.Marketing_Preference_SMS__c = acc.TMG_Promo_SMS__c == 1?true:false;
        this.homeDeliveryItem.Phone__c = acc.PersonHomePhone;
        

        List<Account> lstAccount = [SELECT Id, Subscriber_Number__c FROM Account WHERE Id = :acc.Id];
        if(!lstAccount.isEmpty()){
            this.homeDeliveryItem.Subscriber_Number__c = lstAccount[0].Subscriber_Number__c;
        }

        if(this.homeDeliveryItem.Retailer__c != null){
            List<Account> lstRetailer = [SELECT Id, 
                                                    Name, 
                                                    Shop_Name__c, 
                                                    BillingStreet, 
                                                    BillingPostalCode, 
                                                    BillingCity, 
                                                    Phone,
                                                    URN__c
                                                FROM Account
                                                WHERE Id = :this.homeDeliveryItem.Retailer__c];
            if(!lstRetailer.isEmpty()){
                this.homeDeliveryItem.Retailer_Id__c = lstRetailer[0].URN__c;
                this.homeDeliveryItem.Retailer_Name__c = lstRetailer[0].Shop_Name__c;
                this.homeDeliveryItem.Retailer_Phone__c = lstRetailer[0].Phone;
                this.homeDeliveryItem.Retailer_Post_Code__c = lstRetailer[0].BillingPostalCode;
                this.homeDeliveryItem.Retailer_Town__c = lstRetailer[0].BillingCity;
                this.homeDeliveryItem.Retailer_Address__c = lstRetailer[0].BillingStreet;
            } 
        }
    }
}