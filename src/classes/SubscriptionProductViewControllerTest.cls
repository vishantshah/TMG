/**
* Author:       Wiktor Czykin
* Date:         26/10/2016
* Description:  
* ******************* Change Log *******************
* Modified by       Change Date
**/
@isTest
public class SubscriptionProductViewControllerTest {

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/10/2016
    Function    Test exception when no id is provided to access the page
    ******************* Change Log *******************

    Modified by         Version     Change Date11
    ****************************************************************************************/
    private static testMethod void testWrongNoIdEntry(){
        Test.startTest();
            try{
                SubscriptionProductViewController spv = new SubscriptionProductViewController(new ApexPages.StandardController(new Account()));
                System.assert(false);
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Account_Product_View_No_id_specified_error));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/10/2016
    Function    Test exception where there is no account for passed id
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testWrongNoAccountForIdEntry(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        Id accId = td.lstIndividualSubscribers[0].Id;
        delete td.lstIndividualSubscribers; 
        Test.startTest();
            try{
                SubscriptionProductViewController spv = new SubscriptionProductViewController(new ApexPages.StandardController(new Account(Id = accId)));
                System.assert(false);
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.Account_Product_View_No_account_for_specified_id_error));
            }
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/10/2016
    Function    Test retrieval for Account that has both subscriptions
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPositiveFullRetrieval(){
        TestDataUtility td = new TestDataUtility(2);
        td.createSubscriptions();
        Subscription__c sub = TestDataUtility.newSubscripiton(2, td.lstIndividualSubscribers[0].Id, td.lstRetailers[0].Id, null, td.lstZproducts[1].Id);
        sub.Start_Date__c = sub.Start_Date__c.addDays(390);
        insert sub;

        Test.startTest();
            SubscriptionProductViewController spv = new SubscriptionProductViewController(new ApexPages.StandardController(td.lstIndividualSubscribers[0]));
            System.assertEquals(td.lstZproducts[0].Id, spv.oldProduct.Product__c);
            System.assertEquals(td.lstZproducts[1].Id, spv.newestProduct.Product__c);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/10/2016
    Function    Test retrieval for Account that has one subscription
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPositiveHalfRetrieval(){
        TestDataUtility td = new TestDataUtility(1);
        td.createSubscriptions();
        Test.startTest();
            SubscriptionProductViewController spv = new SubscriptionProductViewController(new ApexPages.StandardController(td.lstIndividualSubscribers[0]));
            System.assertEquals(td.lstZproducts[0].Id, spv.newestProduct.Product__c);
            System.assertEquals(null, spv.oldProduct);
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        26/10/2016
    Function    Test retrieval for Account that has no subscriptions
    ******************* Change Log *******************
    Modified by         Version     Change Date
    ****************************************************************************************/
    private static testMethod void testPositiveNoSubscriptions(){
        TestDataUtility td = new TestDataUtility(1);
        td.createIndividualSubscribers();
        Test.startTest();
            SubscriptionProductViewController spv = new SubscriptionProductViewController(new ApexPages.StandardController(td.lstIndividualSubscribers[0]));
            System.assertEquals(null, spv.newestProduct);
            System.assertEquals(null, spv.oldProduct);
        Test.stopTest();
    }

}