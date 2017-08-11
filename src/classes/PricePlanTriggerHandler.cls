/**
* @author Gavin Palmer
* @date 26/05/2016
* @description Handler for the Price_Plan__c trigger
*#############Change Log#############
*Modified by     Version     Change Date
*Wiktor Czykin   1.1         29/09/2016 //modified validateAgainstProductPrice()
*Wiktor Czykin   1.2         11/10/2016 //modified validateAgainstProductPrice()
**/
public class PricePlanTriggerHandler {

    public static PricePlanTriggerHandler instance;

    public static PricePlanTriggerHandler getInstance() {
        if (instance == null) instance = new PricePlanTriggerHandler();
        return instance;
    }

    public void onBeforeInsert(List<Price_Plan__c> newPricePlans) {
        validateAgainstProductPrice(null, newPricePlans);
    }

    public void onBeforeUpdate(Map<Id, Price_Plan__c> mapOldRecord, List<Price_Plan__c> newPricePlans) {
        validateAgainstProductPrice(mapOldRecord, newPricePlans);
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 26/05/2016
    Version - 1.1
    Function - validate the fields against the product price table
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin   1.1         29/09/2016  //modified so that validation is only triggered if value is changed
    Wiktor Czykin   1.2         11/10/2016  //added logic so that validation only works for print price plans
    ****************************************************************************************/
    private void validateAgainstProductPrice(Map<Id, Price_Plan__c> mapOldPricePlans, List<Price_Plan__c> lstNewPricePlans){
        List<Price_Plan__c> lstOldRecords;
        List<Price_Plan__c> lstNewApplicableRecords = new List<Price_Plan__c>();
        for(Price_Plan__c pp : lstNewPricePlans){
            if(pp.RecordTypeId == RecordTypeUtility.getRecordTypeId(Price_Plan__c.SObjectType, Constants.PRICE_PLAN_RECORDTYPE_PRINT, Price_Plan__c.class.getName())){
                lstNewApplicableRecords.add(pp);
            }
        }
        if(mapOldPricePlans != null){
            lstOldRecords = new List<Price_Plan__c>();
            for(Price_Plan__c pp : lstNewApplicableRecords){
                lstOldRecords.add(mapOldPricePlans.get(pp.Id));
            }
        }
        
        List<TMGUtil.FieldValidationWrapper> fieldsToValidate = new List<TMGUtil.FieldValidationWrapper>{
            new TMGUtil.FieldValidationWrapper(
                'Renewal_Price__c',
                Label.Product_Price_Validation_Renewal_Price,
                Constants.PRODUCT_PRICE_RENEWAL
            )
        };

        TMGUtil.validateAgainstProductPrice(lstNewApplicableRecords, lstOldRecords, fieldsToValidate, 'Product_To__c');
    }
}
