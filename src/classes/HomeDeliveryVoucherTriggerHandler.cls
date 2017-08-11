/**
* @author Wiktor Czykin
* @date 27/06/2017
* @description trigger handler class for Home_Delivery_Voucher__c object
*#############Change Log#############
*Modified by     Change Date
**/
public class HomeDeliveryVoucherTriggerHandler{

    public static HomeDeliveryVoucherTriggerHandler instance;
    public Boolean isExecuting = false;
    public Map<Id, Home_Delivery_Settings__c> mapRecordTypeToSetting;

    public static HomeDeliveryVoucherTriggerHandler getInstance() {
        if (instance == null) instance = new HomeDeliveryVoucherTriggerHandler();
        return instance;
    }

    public HomeDeliveryVoucherTriggerHandler(){
        Home_Delivery_Settings__c settingDeliverNewspaper = Home_Delivery_Settings__c.getInstance(Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME);
        Home_Delivery_Settings__c settingHomeDeliveryService = Home_Delivery_Settings__c.getInstance(Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME);
        this.mapRecordTypeToSetting = new Map<Id, Home_Delivery_Settings__c>{
            RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_DELIVERMYNEWSPAPER_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()) => settingDeliverNewspaper,
            RecordTypeUtility.getRecordTypeId(Home_Delivery_Voucher__c.SObjectType, Constants.HOMEDELIVERYVOUCHER_HOMEDELIVERYSERVICE_RECORD_TYPE_NAME, Home_Delivery_Voucher__c.class.getName()) => settingHomeDeliveryService
        };
    }

    public void onBeforeInsert(List<Home_Delivery_Voucher__c> lstNewRecords) {
        this.populateFieldsBasedOnSettings(null, lstNewRecords);
        this.populateDuplicateField(lstNewRecords);
    }

    public void onBeforeUpdate(Map<Id, Home_Delivery_Voucher__c> mapOldRecords, List<Home_Delivery_Voucher__c> lstNewRecords) {
        this.populateFieldsBasedOnSettings(mapOldRecords, lstNewRecords);
    }   

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 27/06/2017
    Function - populate Id Duplicate__c flag
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void populateDuplicateField(List<Home_Delivery_Voucher__c> lstNewRecords){
        Set<Id> setAccountIds = new Set<Id>();

        for(Home_Delivery_Voucher__c hdv : lstNewRecords){
            if(hdv.Account__c != null){
                setAccountIds.add(hdv.Account__c);
            }
        }

        Integer iLimit = [SELECT count() FROM RecordType WHERE SObjectType = :Home_Delivery_Voucher__c.class.getName()];
        List<Account> lstAccounts = Database.query('SELECT Id, (SELECT Id, RecordTypeId FROM Home_Delivery_Vouchers__r WHERE Is_Duplicate__c = false LIMIT :iLimit) FROM Account WHERE Id IN :setAccountIds');

        Map<Id, Set<Id>> mapRecordTypeIds = new Map<Id, Set<Id>>();
        for(Account acc : lstAccounts){
            Set<Id> setDeliveryRecordTypes = new Set<Id>();

            if(!acc.Home_Delivery_Vouchers__r.isEmpty()){
                for(Home_Delivery_Voucher__c hdv : acc.Home_Delivery_Vouchers__r){
                    setDeliveryRecordTypes.add(hdv.RecordTypeId);
                }
            }
            mapRecordTypeIds.put(acc.Id, setDeliveryRecordTypes);
        }

        for(Home_Delivery_Voucher__c hdv : lstNewRecords){
            if(hdv.Account__c != null){
                Set<Id> setRecordTypeIds = mapRecordTypeIds.get(hdv.Account__c);
                if(setRecordTypeIds != null && setRecordTypeIds.contains(hdv.RecordTypeId)){
                    hdv.Is_Duplicate__c = true;
                }
            }
        }
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 27/06/2017
    Function - populate fields on Home Delivery Voucher records based on custom settings configuration
    #############Change Log#############
    Modified by     Change Date
    ****************************************************************************************/
    private void populateFieldsBasedOnSettings(Map<Id, Home_Delivery_Voucher__c> mapOldRecords, List<Home_Delivery_Voucher__c> lstNewRecords){
        List<Home_Delivery_Voucher__c> lstToPopulateProduct = new List<Home_Delivery_Voucher__c>();
        Home_Delivery_Settings__c hds;
        if(mapOldRecords != null){
            for(Home_Delivery_Voucher__c hdv : lstNewRecords){
                Home_Delivery_Voucher__c oldRecord = mapOldRecords.get(hdv.Id);
                hds = this.mapRecordTypeToSetting.get(hdv.RecordTypeId);
                if(hds != null){
                    if(hdv.RecordTypeId != oldRecord.RecordTypeId){
                        hdv.Offer_Name__c = hds.Offer_Name__c;
                        hdv.Description__c = hds.Offer_Description__c;
                    }
                    if((hdv.RecordTypeId != oldRecord.RecordTypeId || hdv.Delivery_Days__c != oldRecord.Delivery_Days__c) && String.isNotBlank(hdv.Delivery_Days__c)){
                        lstToPopulateProduct.add(hdv);
                    }
                }
            }
        }else{
            for(Home_Delivery_Voucher__c hdv : lstNewRecords){
                hds = this.mapRecordTypeToSetting.get(hdv.RecordTypeId);
                if(hds != null){
                    hdv.Offer_Name__c = hds.Offer_Name__c;
                    hdv.Description__c = hds.Offer_Description__c;
                    if(String.isNotBlank(hdv.Delivery_Days__c)){
                        lstToPopulateProduct.add(hdv);
                    }
                }
            }
        }

        if(!lstToPopulateProduct.isEmpty()){
            Set<String> setFeatureDeliveryDays = new Set<String>();
            for(Home_Delivery_Voucher__c hdv : lstToPopulateProduct){
                String sConvertedDays = String.join(hdv.Delivery_Days__c.toUpperCase().split(';'), '-');
                setFeatureDeliveryDays.add(sConvertedDays);
            }
            Map<String, Set<Id>> mapActiveDaysToProducts = new Map<String, Set<Id>>();
            Set<Id> setBuffer;
            Set<Id> setValidBuffer;

            for(zqu__ZProductFeature__c pf : [SELECT    zqu__ZProduct__c,
                                                        zqu__ZFeature__r.Active_Days__c
                                                    FROM zqu__ZProductFeature__c 
                                                    WHERE zqu__ZFeature__r.Active_Days__c IN :setFeatureDeliveryDays]){
                setBuffer = mapActiveDaysToProducts.get(pf.zqu__ZFeature__r.Active_Days__c);
                if(setBuffer == null){
                    setBuffer = new Set<Id>();
                }
                setBuffer.add(pf.zqu__ZProduct__c);
                mapActiveDaysToProducts.put(pf.zqu__ZFeature__r.Active_Days__c, setBuffer);
            }
            
            if(mapActiveDaysToProducts.isEmpty()) return;
            for(Home_Delivery_Voucher__c hdv : lstToPopulateProduct){
                String sConvertedDaysForRecord = String.join(hdv.Delivery_Days__c.toUpperCase().split(';'), '-');
                hds = this.mapRecordTypeToSetting.get(hdv.RecordTypeId);
                if(String.isNotBlank(hds.Supported_Product_Ids__c)){
                    setValidBuffer = new Set<Id>((List<Id>)hds.Supported_Product_Ids__c.split(';'));
                }
                setBuffer = mapActiveDaysToProducts.get(sConvertedDaysForRecord);
                if(setBuffer != null && !setBuffer.isEmpty()){
                    for(Id productId : setBuffer){
                        if(setValidBuffer.contains(productId)){
                            hdv.Product__c = productId;
                        }
                    }
                }
            }
        }
    }
}