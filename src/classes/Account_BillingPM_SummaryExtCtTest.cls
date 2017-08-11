/**
* Author:       Wiktor Czykin
* Date:         19/05/2017
* Description:  this class for testing Account_BillingPM_SummaryExtCt - totally replaced the old one
* ******************* Change Log *******************
* Modified by           Change Date
* Mantas Grigaliunas    22/06/2017 modified test methods after paypal payment functionality added on controller extension 
**/
@isTest
private class Account_BillingPM_SummaryExtCtTest {

    /***************************************************************************************
    Developer           Wiktor Czykin
    Date                22/05/2017
    Function            test failure on missing account for Id specified
    ******************* Change Log *******************
    Modified            by         Change Date
    ****************************************************************************************/
    private static testMethod void testInitFailureNoAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createRegistrants();
        PageReference pr = Page.Account_BillingPM_Summary;
        pr.getParameters().put('id', td.lstRegistrants[0].Id);
        Test.setCurrentPage(pr);
        delete td.lstRegistrants[0];

        Test.startTest();
            Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Manage_Subscription_No_account_or_product_for_id));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    test failure when there is no product on account record 
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testInitFailureNoProductOnAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZquotes();
        PageReference pr = Page.Account_BillingPM_Summary;
        pr.getParameters().put('id', td.lstRegistrants[0].Id);
        Test.setCurrentPage(pr);

        Test.startTest();
            Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Manage_Subscription_No_account_or_product_for_id));
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    test failure when there is no subscription related to the account
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testInitFailureNoSubscriptionOrBillingAccount(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZquotes();
        td.createZProduct(); 
        td.lstRegistrants[0].Product__c = td.lstZProducts[0].Id;
        update td.lstRegistrants;   
        PageReference pr = Page.Account_BillingPM_Summary;
        pr.getParameters().put('id', td.lstRegistrants[0].Id);
        Test.setCurrentPage(pr);

        Test.startTest();
            Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();
        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Manage_Subscription_No_billing_account_or_related_subscription));
        System.assertEquals(null, ctrl.subscription);
        System.assertEquals(null, ctrl.billingAccount);
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    test page load failure - not allowed to view page with the specific account state
    ******************* Change Log *******************
    Modified by         Change Date
    Mantas Grigaliunas  22/06/2017    changed constant
    ****************************************************************************************/
    private static testMethod void testInitNoActiveSubscriptionNotDaypassProduct(){
        TestDataUtility td = new TestDataUtility(1);
        td.createZProduct();
        td.createZSubscriptions();
        td.lstZuoraSubscriptions[0].Zuora__Status__c = Constants.SSTATUS_INACTIVE;
        update td.lstZuoraSubscriptions; 
        td.lstRegistrants[0].Product__c = td.lstZProducts[0].Id;
        update td.lstRegistrants;     
        PageReference pr = Page.Account_BillingPM_Summary;
        pr.getParameters().put('id', td.lstRegistrants[0].Id);
        Test.setCurrentPage(pr);

        Test.startTest();
            Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();

        Test.stopTest();
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.BillingAccount_AccountDoesNotMeetCriteria));
        System.assertNotEquals(null, ctrl.subscription);
        System.assertNotEquals(null, ctrl.billingAccount);
        System.assert(!ctrl.bIsProductDayPass);
        System.assert(!ctrl.hasAccountActiveSubscription);
    }

    /**************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    simple util method for positive init 
    ******************* Change Log *******************
    Modified by         Change Date
    ***************************************************************************************/
    private static void initPositive(TestDataUtility td){
        td.createZProduct();
        td.createZSubscriptions();
        td.lstRegistrants[0].Product__c = td.lstZProducts[0].Id;
        update td.lstRegistrants;
        PageReference pr = Page.Account_BillingPM_Summary;
        pr.getParameters().put('id', td.lstRegistrants[0].Id);
        Test.setCurrentPage(pr); 
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    test setAsDefault action - both failures and positive outcome
    ******************* Change Log *******************
    Modified by           Change Date
    Mantas Grigaliunas    22/06/2017    changed from list assignemnt to map assignment, added index assignment
    ****************************************************************************************/
    @isTest(seeAllData=true)
    private static void testSetAsDefault(){
        TestDataUtility td = new TestDataUtility(1);
        initPositive(td);

        Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();
        Test.startTest();
            System.assert(ctrl.hasAccountActiveSubscription);
            System.assertEquals(1, ctrl.paymentMap.size());
            ctrl.setAsDefault();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.BillingAccount_Error_NoPMSelected));
            
            ctrl.paymentMap.values()[0].paymentMethod.Zuora__DefaultPaymentMethod__c = true;
            ctrl.index = ctrl.paymentMap.values()[0].paymentMethod.Zuora__External_Id__c;
            ctrl.setAsDefault();
            System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.BillingAccount_Error_ThisPMisDefaultAlready));
            
            ctrl.paymentMap.values()[0].paymentMethod.Zuora__DefaultPaymentMethod__c = false;
            ctrl.setAsDefault();
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    test addNewPaymentMethod() action and goBack() action
    ******************* Change Log *******************
    Modified by         Change Date
    ****************************************************************************************/
    private static testMethod void testAddNewPaymentMethodAndGoBack(){
        TestDataUtility td = new TestDataUtility(1);
        initPositive(td);
        td.setApplicationConfigurations();

        Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();
        Test.startTest();
            System.assertNotEquals(null, ctrl.addNewPaymentMethod());
            PageReference pr = ctrl.goBack();
            System.assertNotEquals(null, pr, 'no page redirect returned');
            System.assert(pr.getUrl().contains(ctrl.accId),'page redirect to wrong account id');
        Test.stopTest();
    }

    /***************************************************************************************
    Developer   Wiktor Czykin
    Date        22/05/2017
    Function    test changeSelection() from non-daypass to daypass and removal if that payment method
    ******************* Change Log *******************
    Modified by         Change Date
    Mantas Grigaliunas  22/06/2017  changed from list assignemnt to map assignment, added index assignment
    ****************************************************************************************/
    @isTest(seeAllData=true)
    private static void testChangeSelectionAndRemove(){
        TestDataUtility td = new TestDataUtility(1);
        initPositive(td);
        Account_BillingPM_SummaryExtCt ctrl = new Account_BillingPM_SummaryExtCt();
        System.assert(!ctrl.bIsProductDayPass);
        System.assert(!ctrl.bIsRemovePaymentAvailable);
        td.createProductRatePlans();
        Zuora__Product__c product = new Zuora__Product__c(Name = td.lstZProducts[0].Name, Zuora__External_Id__c = '11111111');
        insert product;
        Zuora__SubscriptionProductCharge__c charge = TestDataUtility.newSubscriptionProductCharge(td.lstZuoraSubscriptions[0].Id, product.Id);
        charge.Zuora__Account__c = td.lstRegistrants[0].Id;
        insert charge;

        Test.startTest();
            ctrl.sfdcAccount.Card_Details_Stored__c = true;
            ctrl.bIsProductDayPass = true;
            ctrl.index = Constants.ZUORA_TEST_STRING;
            ctrl.changeSelection();
            System.assert(ctrl.bIsRemovePaymentAvailable);
            ctrl.removePaymentMethod();
        Test.stopTest();
        List<Account> lstAccount = [SELECT Id, Card_Details_Stored__c FROM Account WHERE Id = :ctrl.accId];
        System.assert(!lstAccount.isEmpty());
        System.assert(!lstAccount[0].Card_Details_Stored__c);
        System.assert(TestDataUtility.checkIfMessageExists(ApexPages.getMessages(), Label.Manage_Subscription_Payment_method_removed));
    }
}