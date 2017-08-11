/**
* Author:       Wiktor Czykin
* Date:         25/07/2017
* Description:  Controller Extension for Home Deliver Voucher new button override page
* ******************* Change Log *******************
* Modified by           Change Date
**/
public with sharing class HomeDeliveryVoucherOverride {

    @TestVisible private static final String GENERAL_HOMEDELIVERYVOUCHER_ENTITY = 'Home Delivery Voucher Entity';
    @TestVisible private static final String PARAM_RECORDTYPE = 'RecordType';
    @TestVisible private static final String PARAM_RETURL = 'retURL';
    @TestVisible private static final String PAGE_RECORDTYPESELECT = '/setup/ui/recordtypeselect.jsp';
    @TestVisible private static final String PARAM_SAVENEWURL = 'save_new_url';
    
    private static final String PARAM_NOOVERRIDE = 'nooverride';
    private static final String PARAM_SAVENEW = 'save_new';
    private static final String PARAM_ENT = 'ent';
    private static final String PARAM_CACHING = 'scontrolCaching';
    private static final String PARAM_OVERRIDE = 'sfdc.override';


    public HomeDeliveryVoucherOverride(ApexPages.StandardController std){}

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/07/2017
    Description Redirects to new record creation page with extra parameters
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    public PageReference redirect(){
        Map<String, String> mapAllParams = ApexPages.currentPage().getParameters();
        String sPrefixHomeDeliveryVoucher = Home_Delivery_Voucher__c.sObjectType.getDescribe().getKeyPrefix(); 
        String editPage = '/' + sPrefixHomeDeliveryVoucher + '/e';
        String sReturnURL = mapAllParams.get(PARAM_RETURL);
        PageReference pr;
        
        if(String.isBlank(sReturnURL)){
            sReturnURL = '%2F' + sPrefixHomeDeliveryVoucher + '%2Fo';
        }
        General__c entitySetting = General__c.getInstance(GENERAL_HOMEDELIVERYVOUCHER_ENTITY);
        if(entitySetting == null || String.isBlank(entitySetting.Value__c)){
            throw new TelegraphApplicationException('Missing parameter: entity id.');
        }
        //if no record type, check if only one available
        String sRecordType = mapAllParams.get(PARAM_RECORDTYPE);
        if(String.isBlank(sRecordType)){
            Map<String, Schema.RecordTypeInfo> mapInfo = RecordTypeUtility.getRecordTypeInfoMapForObject(Home_Delivery_Voucher__c.SObjectType, Home_Delivery_Voucher__c.class.getName());
            Integer iCount = 0;
            Schema.RecordTypeInfo availableType;
            for(Schema.RecordTypeInfo info : mapInfo.values()){
                if(info.isAvailable()){
                    iCount++;
                }
                availableType = info;
            }
            if(iCount == 1 && availableType != null){
                sRecordType = availableType.getRecordTypeId();
            }
        }

        //if record type is found, either by param or via script above
        if(String.isNotBlank(sRecordType)){
            pr = new PageReference(editPage);
            pr.getParameters().put(PARAM_ENT, entitySetting.Value__c);
            pr.getParameters().put(PARAM_RETURL, sReturnURL);
            pr.getParameters().put(PARAM_RECORDTYPE, sRecordType);
            pr.getParameters().put(PARAM_NOOVERRIDE, '1');

            Id accountId;
            for(String key : mapAllParams.keySet()){
                String value = mapAllParams.get(key);
                if( String.isNotBlank(value) && key != PARAM_CACHING && key != PARAM_OVERRIDE && key != PARAM_SAVENEW && key != PARAM_RECORDTYPE){
                    pr.getParameters().put(key, value);
                    try{
                        accountId = (Id) value;
                        if(accountId.getSobjectType() == Account.SObjectType){
                            break;
                        }
                    }catch(Exception e){
                        System.debug('Value not of Id type.');
                    }
                }
            }

            Map<String, Home_Delivery_Fields_Mapping__c> mapValues = Home_Delivery_Fields_Mapping__c.getAll();
            if(!mapValues.isEmpty() && accountId != null){
                String sFields = String.join(new List<String>(mapValues.keySet()), ',');
                List<Account> lstAccount = Database.query('SELECT Id, '+sFields+' FROM Account WHERE Id =:accountId');
                if(lstAccount.size() == 1){
                    for(String sKey : mapValues.keySet()){
                        pr.getParameters().put(mapValues.get(sKey).Home_Delivery_Field_Id__c, String.valueOf(lstAccount[0].get(sKey)));
                    }
                }
            }
            return pr;
        }
        
        //else redirect User to Record Type selection page
        pr = new PageReference(PAGE_RECORDTYPESELECT);
        pr.getParameters().put(PARAM_ENT, entitySetting.Value__c);
        pr.getParameters().put(PARAM_RETURL, mapAllParams.get(PARAM_RETURL));

        PageReference prSaveNew = new PageReference(editPage);
        for(String key : mapAllParams.keySet()){
            if(String.isNotBlank(mapAllParams.get(key))){
                prSaveNew.getParameters().put(key, mapAllParams.get(key));
            }
        }
        pr.getParameters().put(PARAM_SAVENEWURL, prSaveNew.getUrl());
        return pr;
    }
}