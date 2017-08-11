/**
* @author Gavin Palmer
* @date 26/05/2016
* @description Handler for the TCode_Product__c trigger
*#############Change Log#############
*Modified by    Change Date
*Wiktor Czykin  29/09/2016  //modified validateAgainstProductPrice()
*Wiktor Czykin  15/02/2017  //added populateUniquenessCheck()
*Wiktor Czykin  30/05/2017  //modified validateAgainstProductPrice()
**/
public class TCodeProductTriggerHandler {

    public static TCodeProductTriggerHandler instance;

    public static TCodeProductTriggerHandler getInstance() {
        if (instance == null) instance = new TCodeProductTriggerHandler();
        return instance;
    }

    public void onBeforeInsert(List<TCode_Product__c> lstNewRecords) {
        this.populateUniquenessCheck(lstNewRecords);
        this.validateAgainstProductPrice(null, lstNewRecords);
    }

    public void onBeforeUpdate(Map<Id, TCode_Product__c> mapOldRecord, List<TCode_Product__c> lstNewRecords) {
        this.populateUniquenessCheck(lstNewRecords);
        this.validateAgainstProductPrice(mapOldRecord, lstNewRecords);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 15/02/2017
    Version - 1.0
    Function - populate unique field with uniqueness factors
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    private void populateUniquenessCheck(List<TCode_Product__c> lstTCodeProduct){
        for(TCode_Product__c tcp : lstTCodeProduct){
            if(tcp.TCodeManagement__c != null && tcp.Product__c != null){
                tcp.Uniqueness_Check__c = ''+tcp.TCodeManagement__c + tcp.Product__c;
                if(tcp.Offer__c != null){
                    tcp.Uniqueness_Check__c += tcp.Offer__c;
                }
            }else{
                tcp.Uniqueness_Check__c = null;
            }
        }
    }

    /***************************************************************************************
    Developer - Gavin Palmer
    Date - 26/05/2016
    Function - validate the fields against the product price table
    #############Change Log#############
    Modified by     Change Date
    Wiktor Czykin   29/09/2016  //modified so that validation is only triggered if value is changed
    Wiktor Czykin   30/05/2017  //make it enabled only for old offers
    ****************************************************************************************/
    private void validateAgainstProductPrice(Map<Id, TCode_Product__c> mapOldTCodeProducts, List<TCode_Product__c> lstNewRecords){
        Id recTypeId = RecordTypeUtility.getRecordTypeId(TCode_Product__c.SObjectType, Constants.RECTYPE_TCODEPRODUCT_OFFER, TCode_Product__c.class.getName());
        List<TCode_Product__c> lstNew = new List<TCode_Product__c>();
        for(TCode_Product__c tp : lstNewRecords){
            if(tp.RecordTypeId == recTypeId){
                lstNew.add(tp);
            }
        }
        List<TCode_Product__c> lstOldRecords;
        if(mapOldTCodeProducts != null){
            lstOldRecords = new List<TCode_Product__c>();
            for(TCode_Product__c tp : lstNew){
                lstOldRecords.add(mapOldTCodeProducts.get(tp.Id));
            }
        }
        List<TMGUtil.FieldValidationWrapper> fieldsToValidate = new List<TMGUtil.FieldValidationWrapper>{
            new TMGUtil.FieldValidationWrapper(
                'Low_Start_Price__c',
                Label.Product_Price_Validation_Low_Price,
                Constants.PRODUCT_PRICE_AQUISITION
            ),
            new TMGUtil.FieldValidationWrapper(
                'Weekly_Price__c',
                Label.Product_Price_Validation_Weekly_Price,
                Constants.PRODUCT_PRICE_AQUISITION
            )
        };
        TMGUtil.validateAgainstProductPrice(lstNew, lstOldRecords, fieldsToValidate, 'Product__c');
    }
}
