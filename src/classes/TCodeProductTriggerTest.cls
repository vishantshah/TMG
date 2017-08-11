/**
* @author Gavin Palmer
* @date 26/05/2106
* @description unit tests for the TCode Product Trigger
*#############Change Log#############
*Modified by     Version     Change Date
*Wiktor Czykin   1.1         29/09/2016  //added testSuccessAndFailureOnUpdateWhenNoChange()
**/
@isTest
private class TCodeProductTriggerTest {

    private static final Integer MAX_COUNT = 5;
    private static final Double INVALID_PRICE = 400;

    /**
    * @author Gavin Palmer
    * @date 26/05/2016
    * @description setup test data for unit tests
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    @testSetup
    private static void testDataSetup(){
        TestDataUtility testUtility = new TestDataUtility(MAX_COUNT);
        testUtility.createTCodeProducts();
        testUtility.createProductPrice();
        TestDataUtility.enableProductPriceValidationSetting();
    }

    /**
    * @author Gavin Palmer
    * @date 26/05/2016
    * @description Test insert failure, this is testing an apex validation rule
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    @isTest
    private static void testInsertFailure(){
        TCode_Product__c tCodeProduct = TestDataUtility.newTCodeProduct(getZProduct().Id, getTCode().Id);
        tCodeProduct.Low_Start_Price__c = INVALID_PRICE;
        Test.startTest();
            Database.SaveResult results = Database.insert(tCodeProduct, false);
        Test.stopTest();

        System.assert(!results.isSuccess(), 'Validation rule has not fired');
        System.assert(TestDataUtility.checkIfErrorExists(results.getErrors(),Label.Product_Price_Validation_Low_Price), 'Correct validation has not fired');
    }

    /**
    * @author Gavin Palmer
    * @date 26/05/2016
    * @description test bulk update failure to see that the validation rule will work
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    @isTest
    private static void testBulkFailure(){
        List<TCode_Product__c> tCodeProducts = getTCodeProducts(200);
        for(TCode_Product__c product : tCodeProducts){
            product.Weekly_Price__c = INVALID_PRICE;
        }

        Test.startTest();
            Database.UpsertResult[] results = Database.upsert(tCodeProducts, false);
        Test.stopTest();

        System.assertEquals(MAX_COUNT, results.size(), 'Validation has missed some of the records');

        // I expect all the records to fail here
        for(Database.UpsertResult result : results){
            System.assert(!result.isSuccess(), 'Validation rule has not fired');
            System.assert(TestDataUtility.checkIfErrorExists(result.getErrors(), Label.Product_Price_Validation_Weekly_Price), 'Correct validation has not fired');
        }
    }

    /**
    * @author Gavin Palmer
    * @date 26/05/2016
    * @description test that the record will save with the correct price fields
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    @isTest
    private static void testSuccess(){
        List<TCode_Product__c> tCodeProduct = getTCodeProducts(1);

        Test.startTest();
                Database.SaveResult results = Database.update(tCodeProduct[0], false);
        Test.stopTest();

        System.debug(loggingLevel.Error, '*** results: ' + results);
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
        List<TCode_Product__c> tcodeProduct = getTCodeProducts(1);
        Decimal lsPriceBuffer = tcodeProduct[0].Low_Start_Price__c;
        Decimal wPriceBuffer = tcodeProduct[0].Weekly_Price__c;
        delete [select Id
                    from Product_Price__c
                    where Price__c = :lsPriceBuffer
                    or Price__c = :wPriceBuffer];

        Test.startTest();
            Database.SaveResult results = Database.update(tcodeProduct[0], false);
            System.assert(results.isSuccess(), 'Record unable to save.');

            tcodeProduct[0].Low_Start_Price__c = INVALID_PRICE;
            results = Database.update(tcodeProduct[0], false);
            System.assert(!results.isSuccess(), 'Record able to save.');

            tcodeProduct[0].Low_Start_Price__c = lsPriceBuffer;
            results = Database.update(tcodeProduct[0], false);
            System.assert(results.isSuccess(), 'Record unable to save.');

            tcodeProduct[0].Weekly_Price__c = INVALID_PRICE;
            results = Database.update(tcodeProduct[0], false);
            System.assert(!results.isSuccess(), 'Record able to save.');

            tcodeProduct[0].Weekly_Price__c = wPriceBuffer;
            results = Database.update(tcodeProduct[0], false);
            System.assert(results.isSuccess(), 'Record unable to save.');

            tcodeProduct[0].Low_Start_Price__c = INVALID_PRICE;
            tcodeProduct[0].Weekly_Price__c = INVALID_PRICE;
            results = Database.update(tcodeProduct[0], false);
            System.assert(!results.isSuccess(), 'Record able to save.');
        Test.stopTest();
    }

    /**
    * @author Gavin Palmer
    * @date 26/05/2016
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
    * @date 26/05/2016
    * @description utility method to get tCode
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    private static TCodeManagement__c getTCode(){
        List<TCodeManagement__c> tCodes = [
            SELECT Id
            FROM TCodeManagement__c
            LIMIT 1
        ];

        System.assert(!tCodes.isEmpty(), 'Error creating T Code test data');
        return tCodes[0];
    }

    /**
    * @author Gavin Palmer
    * @date 26/05/2016
    * @description utility method to get all the tcode products
    *#############Change Log#############
    *Modified by     Version     Change Date
    **/
    private static List<TCode_Product__c> getTCodeProducts(Integer limitValue){
        // include the filds that will fail in the soql
        return [
            SELECT Low_Start_Price__c, Weekly_Price__c
            FROM TCode_Product__c
            LIMIT :limitValue
        ];
    }
}
