/**
Name: TCodeProductWrapperTest
* @author Pawel Chrzanowski
* @date 24/05/2016
* @description Tests TCodeProductWrapper class
##########Change Log##########
Modified by       Version     Change Date
Wiktor Czykin     1.1         09/09/2016 //fix to tests after main class changes
Wiktor Czykin     1.2         19/10/2016 //added compareToTestWithRank()
Wiktor Czykin     1.3         04/11/2016 //increased test coverage
**/
@isTest
private class TCodeProductWrapperTest{

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 24/05/2016
    Function - test for TCodeProductWrapper() constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin     1.1       09/09/2016  //added missing field to query
    ****************************************************************************************/
    private static List<TCode_Product__c> fetchTCodeProducts(){
        return [select  Weekly_Price__c,
                        Low_Start_Price__c,
                        Digital_Monthly_Price__c,
                        Digital_Yearly_Price__c,
                        Product__c,
                        Product__r.Name,
                        Product__r.Print_Product__c,
                        Product__r.Voucher_Delivery_Type__c,
                        Product__r.Rank__c,
                        (select Incentive__c, Name, Incentive__r.Name, Incentive_Validity_Status__c, Is_Incentive_Valid_For_Renewal__c from TCode_Product_Incentives__r) 
                    from TCode_Product__c];
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 24/05/2016
    Function - test for TCodeProductWrapper() constructor
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin     1.1       09/09/2016  //added missing field to query
    ****************************************************************************************/
    static testMethod void tCodeProductWrapperTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createTCodeProducts();

        tdu.lstZproducts[0].Name = 'test';
        tdu.lstZproducts[0].Print_Product__c = true;
        update tdu.lstZproducts[0];

        TCode_Product__c tCodeProduct = fetchTCodeProducts()[0];

        TCodeProductWrapper tCodeProductWrapper = new TCodeProductWrapper(tCodeProduct);
        System.assertEquals(tdu.lstZproducts[0].Id, tCodeProductWrapper.productId);
        System.assertEquals('test', tCodeProductWrapper.sProductName);
        System.assertEquals(Label.Acqusition_Flow_No_Incentive, tCodeProductWrapper.incentives);
        System.assert(tCodeProductWrapper.isPrint);
        System.assertEquals(null, tCodeProductWrapper.selected);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 04/11/2016
    Function - test for TCodeProductWrapper() constructor - with incetive filter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void tCodeProductWrapperTestConstructorWithIncentiveFilterOn(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createTCodeProductIncentives();
        tdu.lstIncentives[0].Is_Valid_For_Renewal__c = true;
        update tdu.lstIncentives; 
        Test.startTest();
            TCode_Product__c tCodeProduct = fetchTCodeProducts()[0];
            TCodeProductWrapper tCodeProductWrapper = new TCodeProductWrapper(tCodeProduct, true);
        Test.stopTest();
        System.assertNotEquals(Label.Acqusition_Flow_No_Incentive, tCodeProductWrapper.incentives);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 04/11/2016
    Function - test for TCodeProductWrapper() constructor - with incetive filter
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void tCodeProductWrapperTestConstructorWithIncentiveFilterOnNoRecords(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createTCodeProductIncentives();
        Test.startTest();
            TCode_Product__c tCodeProduct = fetchTCodeProducts()[0];
            TCodeProductWrapper tCodeProductWrapper = new TCodeProductWrapper(tCodeProduct, true);
        Test.stopTest();
        System.assertEquals(Label.Acqusition_Flow_No_Incentive, tCodeProductWrapper.incentives);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 24/05/2016
    Function - test for addIncentive() method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin     1.1       09/09/2016  //added missing field to query
    ****************************************************************************************/
    static testMethod void addIncentiveTest(){
        TestDataUtility tdu = new TestDataUtility(1);
        tdu.createTCodeProducts();
        tdu.createIncentives();

        tdu.lstIncentives[0].Name = 'test';
        update tdu.lstIncentives[0];

        TCode_Product_Incentive__c tCodeProductIncentive = new TCode_Product_Incentive__c(Incentive__c=tdu.lstIncentives[0].Id, TCode_Product__c=tdu.lstTCodeProducts[0].Id);
        insert tCodeProductIncentive;

        TCode_Product__c tCodeProduct = fetchTCodeProducts()[0];
        TCodeProductWrapper tCodeProductWrapper = new TCodeProductWrapper(tCodeProduct);
        System.assertEquals('test', tCodeProductWrapper.incentives);

        tCodeProductWrapper.addIncentive('test');
        System.assertEquals('test, test', tCodeProductWrapper.incentives);
    }

    /***************************************************************************************
    Developer - Pawel Chrzanowski
    Date - 24/05/2016
    Function - test for compareTo() method
    #############Change Log#############
    Modified by     Version     Change Date
    Wiktor Czykin     1.1       09/09/2016  //added missing field to query
    ****************************************************************************************/
    static testMethod void compareToTest(){
        TestDataUtility tdu = new TestDataUtility(3);
        tdu.createTCodeProducts();

        tdu.lstZproducts[0].Name = 'a';
        tdu.lstZproducts[1].Name = 'c';
        tdu.lstZproducts[2].Name = 'b';
        update tdu.lstZproducts;

        List<TCodeProductWrapper> lstTCodeProductWrapper = new List<TCodeProductWrapper>();
        List<TCode_Product__c> lstTCodeProduct = fetchTCodeProducts();
        for(TCode_Product__c tCodeProduct : lstTCodeProduct){
            lstTCodeProductWrapper.add(new TCodeProductWrapper(tCodeProduct));
        }

        lstTCodeProductWrapper.sort();
        System.assertEquals('c', lstTCodeProductWrapper[2].sProductName);
    }

    /***************************************************************************************
    Developer - Wiktor Czykin
    Date - 19/10/2016
    Function - test for compareTo() method with Rank
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    static testMethod void compareToTestWithRank(){
        TestDataUtility tdu = new TestDataUtility(5);
        tdu.createTCodeProducts();
        tdu.lstZproducts[0].Name = 'a';
        tdu.lstZproducts[1].Name = 'c';
        tdu.lstZproducts[2].Name = 'b';
        tdu.lstZproducts[3].Name = 'd';
        tdu.lstZproducts[4].Name = 'e';

        tdu.lstZproducts[0].Rank__c = '3';
        tdu.lstZproducts[1].Rank__c = '2';
        tdu.lstZproducts[2].Rank__c = '2';
        tdu.lstZproducts[3].Rank__c = '1';
        tdu.lstZproducts[4].Rank__c = '5';

        update tdu.lstZproducts;

        List<TCodeProductWrapper> lstTCodeProductWrapper = new List<TCodeProductWrapper>();
        List<TCode_Product__c> lstTCodeProduct = [select Weekly_Price__c,
                                                         Low_Start_Price__c,
                                                         Digital_Monthly_Price__c,
                                                         Digital_Yearly_Price__c,
                                                         Product__c,
                                                         Product__r.Name,
                                                         Product__r.Print_Product__c,
                                                         Product__r.Voucher_Delivery_Type__c,
                                                         Product__r.Rank__c,
                                                         (select Incentive__c, Name, Incentive__r.Name from TCode_Product_Incentives__r) from TCode_Product__c];
        for(TCode_Product__c tCodeProduct : lstTCodeProduct){
            lstTCodeProductWrapper.add(new TCodeProductWrapper(tCodeProduct));
        }

        lstTCodeProductWrapper.sort();
        System.assertEquals('d', lstTCodeProductWrapper[0].sProductName);
        System.assertEquals('b', lstTCodeProductWrapper[1].sProductName);
        System.assertEquals('c', lstTCodeProductWrapper[2].sProductName);
        System.assertEquals('a', lstTCodeProductWrapper[3].sProductName);
        System.assertEquals('e', lstTCodeProductWrapper[4].sProductName);
    }

}
