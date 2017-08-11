/**
* @author Gavin Palmer
* @date 31/05/2106
* @description unit tests for the Price Plan Trigger
*#############Change Log#############
*Modified by     Version     Change Date
*Wiktor Czykin   1.1         29/09/2016  //added testSuccessAndFailureOnUpdateWhenNoChange()
**/
@isTest
private class PricePlanTriggerHandlerTest {

    private static final Integer MAX_COUNT = 10;
    private static final Double INVALID_PRICE = 400;
    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description setup test data for unit tests
    *#############Change Log#############
    *Modified by     Version     Change Date
    *Wiktor Czykin   1.1         11/10/2017 //modified so that there are actually products checked and linked
    **/
    @testSetup
    private static void testDataSetup(){
        TestDataUtility td = new TestDataUtility(MAX_COUNT);
        td.createProductPrice();
        td.createPricePlans();

        List<Plan__c> lstPlansToUpdate = new List<Plan__c>();
        for(Price_Plan__c pp : td.lstPricePlans){
            pp.RecordTypeId = RecordTypeUtility.getRecordTypeId(Price_Plan__c.SObjectType, Constants.PRICE_PLAN_RECORDTYPE_PRINT, Price_Plan__c.class.getName());
            lstPlansToUpdate.add(new Plan__c(Id = pp.Plan__c, Product__c = pp.Product_To__c));
        }
        update lstPlansToUpdate;
        update td.lstPricePlans;
        TestDataUtility.enableProductPriceValidationSetting();
    }

    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description Test insert failure, this is testing an apex validation rule
    *#############Change Log#############
    *Modified by     Version     Change Date
    *Wiktor Czykin   1.1         11/10/2016  //set record type for the price plan
    **/
    @isTest
    private static void testInsertFailure(){
        ID recordTypeId = RecordTypeUtility.getRecordTypeId(Price_Plan__c.SObjectType, Constants.PRICE_PLAN_RECORDTYPE_PRINT, Price_Plan__c.class.getName());
        Price_Plan__c pricePlan = TestDataUtility.newPricePlan(getPlan().Id, getZProduct().Id, recordTypeId);
        pricePlan.Renewal_Price__c = INVALID_PRICE;

        Test.startTest();
            Database.SaveResult results = Database.insert(pricePlan, false);
        Test.stopTest();
        System.assert(!results.isSuccess(), 'Validation rule has not fired');
        System.assert(TestDataUtility.checkIfErrorExists(results.getErrors(), Label.Product_Price_Validation_Renewal_Price), 'Correct validation has not fired');
    }

    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description test bulk update failure to see that the validation rule will work
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    @isTest
    private static void testBulkFailure(){
        List<Price_Plan__c> pricePlans = getPricePlans(MAX_COUNT);
        for(Price_Plan__c pricePlan : pricePlans){
            pricePlan.Renewal_Price__c = 500;
        }

        Test.startTest();
            Database.UpsertResult[] results = Database.upsert(pricePlans, false);
        Test.stopTest();

        System.assertEquals(MAX_COUNT, results.size(), 'Validation has missed some of the records');

        // I expect all the records to fail here
        for(Database.UpsertResult result : results){
            System.assert(!result.isSuccess(), 'Validation rule has not fired');
            System.assert(TestDataUtility.checkIfErrorExists(result.getErrors(), Label.Product_Price_Validation_Renewal_Price), 'Correct validation has not fired:'+result.getErrors());
        }
    }

    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description test that the record will save with the correct price fields
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    @isTest
    private static void testSuccess(){
        List<Price_Plan__c> pricePlans = getPricePlans(1);
        Test.startTest();
            Database.SaveResult results = Database.update(pricePlans[0], false);
        Test.stopTest();
        System.assert(results.isSuccess(), 'Record unable to save');
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 29/09/2016
    Version - 1.0
    Function - added test that validation only works on update when validated price is changed
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    @isTest
    private static void testSuccessAndFailureOnUpdateWhenNoChange(){
        List<Price_Plan__c> pricePlans = getPricePlans(1);
        List<Product_Price__c> lstProductPricesToDelete = [select Id from Product_Price__c where Price__c = :pricePlans[0].Renewal_Price__c];
        delete lstProductPricesToDelete;

        Test.startTest();
            Database.SaveResult results = Database.update(pricePLans[0], false);
            System.assert(results.isSuccess(), 'Record unable to save.');
            pricePLans[0].Renewal_Price__c = INVALID_PRICE;
            results = Database.update(pricePLans[0], false);
            System.assert(!results.isSuccess(), 'Record unable to save.');
        Test.stopTest();
    }

    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description utility method to get zproduct
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    private static zqu__ZProduct__c getZProduct(){
        List<zqu__ZProduct__c> zProducts = [
            SELECT Id
            FROM zqu__ZProduct__c
            LIMIT 1
        ];

        System.assert(!zProducts.isEmpty(), 'Error creating z product test data');
        return zProducts[0];
    }

    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description utility method to get plan record
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    private static Plan__c getPlan(){
        List<Plan__c> plans = [
            SELECT Id
            FROM Plan__c
            LIMIT 1
        ];

        System.assert(!plans.isEmpty(), 'Error creating z product test data');
        return plans[0];
    }

    /**
    * @author Gavin Palmer
    * @date 31/05/2016
    * @description utility method to get all the price plans
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    private static List<Price_Plan__c> getPricePlans(Integer limitValue){
        return [
            SELECT Renewal_Price__c
            FROM Price_Plan__c
            LIMIT :limitValue
        ];
    }
}
